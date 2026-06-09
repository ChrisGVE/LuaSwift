//
//  LuaEngine+FunctionCalls.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+FunctionCalls.swift
//
//  Context: Swift-calls-Lua concern of LuaEngine. Lua functions that
//  reach Swift callbacks arrive as LuaValue.luaFunction registry
//  references (created in LuaEngine+Bridging.swift); this file calls
//  them (callLuaFunction) and manages their registry lifetime
//  (releaseLuaFunction, withLuaFunction, callAndReleaseLuaFunction).
//  Calls are bounded by the compositor hook (armCompositorHook) and
//  classified via errorFromCode (both LuaEngine+Execution.swift). The
//  inverse direction — Lua calling Swift — lives in +Callbacks.swift.
//

import Foundation
import CLua

extension LuaEngine {

    // MARK: - Lua Function Calls

    /// Call a Lua function by its registry reference.
    ///
    /// This allows Swift code to call Lua functions that were passed as arguments
    /// to Swift callbacks. The function reference comes from a `LuaValue.luaFunction`
    /// case created when receiving function arguments.
    ///
    /// - Parameters:
    ///   - ref: The registry reference from `LuaValue.luaFunction`
    ///   - args: Arguments to pass to the Lua function
    /// - Returns: The return value from the Lua function
    /// - Throws: `LuaError` if the call fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// engine.registerFunction(name: "map") { args in
    ///     guard case .luaFunction(let funcRef) = args[0],
    ///           let arr = args[1].arrayValue else {
    ///         throw LuaError.callbackError("Expected function and array")
    ///     }
    ///     var result: [LuaValue] = []
    ///     for item in arr {
    ///         let mapped = try engine.callLuaFunction(ref: funcRef, args: [item])
    ///         result.append(mapped)
    ///     }
    ///     return .array(result)
    /// }
    /// ```
    public func callLuaFunction(ref: Int32, args: [LuaValue]) throws -> LuaValue {
        guard !isPaused.load(ordering: .acquiring) else {
            throw LuaError.enginePaused
        }
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Capture the entry stack top. callLuaFunction is designed to be called
        // re-entrantly from inside a Swift callback (see the `map` example above),
        // where the recursive lock is already held and the callback's C-stack
        // window is non-empty. All stack discipline below is therefore relative
        // to this base, not absolute — the post-call cleanliness check compares
        // against `entryTop`, not 0.
        let entryTop = lua_gettop(L)

        // Reset per-run state so a prior cancel/limit or structured-error stash
        // does not persist into this call.
        abortReason.store(AbortReason.none, ordering: .releasing)
        instructionAccumulator = 0
        pendingRuntimeFailure = nil

        let handlerIdx = try pushLuaCallFrame(L, ref: ref, args: args)

        // Arm the compositor hook and install TLS.
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armCompositorHook(on: L)

        // Stack layout entering pcall: [... handler, function, arg0, ..., argN]
        let callResult = lua_pcall(L, Int32(args.count), 1, handlerIdx)
        lua_remove(L, handlerIdx)  // remove handler unconditionally
        return try finishLuaCall(L, callResult: callResult, entryTop: entryTop)
    }

    /// Push the structured-error handler, then the function `ref` and its `args`,
    /// in the layout `[… handler, function, arg0, …, argN]` for a protected call.
    ///
    /// The handler is pushed FIRST so its absolute stack index stays stable after
    /// the function and arguments are pushed. Returns that handler index. Throws
    /// (after cleaning up both the handler and the non-function value) when `ref`
    /// does not resolve to a function.
    private func pushLuaCallFrame(_ L: OpaquePointer, ref: Int32, args: [LuaValue]) throws -> Int32 {
        lua_pushcfunction(L, runtimeErrorHandler)
        let handlerIdx = lua_gettop(L)

        _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(ref))
        if lua_type(L, -1) != LUA_TFUNCTION {
            lua_pop(L, 1)              // pop the non-function
            lua_remove(L, handlerIdx)  // pop the handler
            throw LuaError.runtimeError("Invalid function reference")
        }

        for arg in args {
            pushSimpleValue(L, arg)
        }
        return handlerIdx
    }

    /// Interpret a ``callLuaFunction(ref:args:)`` pcall result. On failure,
    /// classify via ``errorFromCode(_:message:)`` (which reads `abortReason`
    /// first, then the structured-error stash) and throw, asserting in debug that
    /// the stack unwound back to `entryTop`. On success, pop and return the single
    /// result value.
    private func finishLuaCall(_ L: OpaquePointer, callResult: Int32, entryTop: Int32) throws -> LuaValue {
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            #if DEBUG
            assert(lua_gettop(L) == entryTop,
                "Stack not restored to entry base after callLuaFunction abort: "
                + "top=\(lua_gettop(L)), entryTop=\(entryTop)")
            #endif

            throw errorFromCode(callResult, message: message)
        }

        let result = try valueFromStack(at: -1)
        lua_pop(L, 1)
        return result
    }

    /// Release a Lua function reference.
    ///
    /// Call this when you're done with a function reference to allow
    /// the Lua garbage collector to reclaim the function.
    ///
    /// - Parameter ref: The registry reference to release
    ///
    /// ## Memory Management
    ///
    /// When a Lua function is passed to a Swift callback, it's stored in the Lua
    /// registry to prevent garbage collection. This creates a reference that must
    /// be explicitly released when no longer needed.
    ///
    /// **Important**: Failing to release function references will cause memory leaks
    /// in long-running applications. Each unreleased reference keeps the Lua function
    /// and its upvalues alive in memory.
    ///
    /// For one-shot function calls, consider using ``withLuaFunction(_:args:action:)``
    /// which automatically releases the reference after use.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Store a function reference for later use
    /// var storedRef: Int32?
    ///
    /// engine.registerFunction(name: "storeCallback") { args in
    ///     guard case .luaFunction(let ref) = args.first else {
    ///         throw LuaError.callbackError("Expected function")
    ///     }
    ///     storedRef = ref
    ///     return .nil
    /// }
    ///
    /// // Later, when done with the callback:
    /// if let ref = storedRef {
    ///     engine.releaseLuaFunction(ref: ref)
    ///     storedRef = nil
    /// }
    /// ```
    ///
    /// - Note: It is safe to release references even after the engine is deinitialized;
    ///   the call will simply have no effect.
    public func releaseLuaFunction(ref: Int32) {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else { return }
        luaL_unref(L, LUA_REGISTRYINDEX, ref)
    }

    /// Execute an action with a Lua function, automatically releasing the reference afterward.
    ///
    /// This is a convenience method for one-shot function calls where you don't need
    /// to retain the function reference. The reference is automatically released when
    /// the action completes (whether by normal return or by throwing an error).
    ///
    /// - Parameters:
    ///   - funcValue: A `LuaValue.luaFunction` value containing the function reference
    ///   - args: Arguments to pass to the Lua function
    ///   - action: A closure that receives the function reference and can call it
    /// - Returns: The result of the action closure
    /// - Throws: `LuaError.callbackError` if `funcValue` is not a function,
    ///   or any error thrown by the action closure
    ///
    /// ## Example
    ///
    /// ```swift
    /// engine.registerFunction(name: "applyToValue") { args in
    ///     guard args.count >= 2 else {
    ///         throw LuaError.callbackError("Expected function and value")
    ///     }
    ///
    ///     let funcValue = args[0]
    ///     let value = args[1]
    ///
    ///     // Function reference is automatically released after this block
    ///     return try engine.withLuaFunction(funcValue, args: [value]) { ref in
    ///         return try engine.callLuaFunction(ref: ref, args: [value])
    ///     }
    /// }
    /// ```
    ///
    /// ## Comparison with Manual Management
    ///
    /// ```swift
    /// // Manual management (error-prone):
    /// guard case .luaFunction(let ref) = funcValue else { throw ... }
    /// defer { engine.releaseLuaFunction(ref: ref) }
    /// let result = try engine.callLuaFunction(ref: ref, args: args)
    ///
    /// // Using withLuaFunction (safer):
    /// let result = try engine.withLuaFunction(funcValue, args: args) { ref in
    ///     try engine.callLuaFunction(ref: ref, args: args)
    /// }
    /// ```
    @discardableResult
    public func withLuaFunction<T>(
        _ funcValue: LuaValue,
        args: [LuaValue] = [],
        action: (Int32) throws -> T
    ) throws -> T {
        guard case .luaFunction(let ref) = funcValue else {
            throw LuaError.callbackError("Expected LuaValue.luaFunction, got \(funcValue)")
        }

        defer { releaseLuaFunction(ref: ref) }
        return try action(ref)
    }

    /// Call a Lua function and automatically release its reference.
    ///
    /// This is a convenience overload that calls the function and returns its result
    /// in one step, automatically releasing the function reference afterward.
    ///
    /// - Parameters:
    ///   - funcValue: A `LuaValue.luaFunction` value containing the function reference
    ///   - args: Arguments to pass to the Lua function
    /// - Returns: The return value from the Lua function
    /// - Throws: `LuaError.callbackError` if `funcValue` is not a function,
    ///   `LuaError.instructionLimitExceeded` if an instruction limit is set and
    ///   tripped, or `LuaError.runtimeError` if the function call otherwise fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// engine.registerFunction(name: "runCallback") { args in
    ///     guard args.count >= 1 else {
    ///         throw LuaError.callbackError("Expected callback function")
    ///     }
    ///
    ///     // Call the function with some arguments and auto-release
    ///     return try engine.callAndReleaseLuaFunction(args[0], args: [.number(42)])
    /// }
    /// ```
    public func callAndReleaseLuaFunction(_ funcValue: LuaValue, args: [LuaValue] = []) throws -> LuaValue {
        try withLuaFunction(funcValue, args: args) { ref in
            try callLuaFunction(ref: ref, args: args)
        }
    }
}
