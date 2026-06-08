//
//  LuaEngine+Coroutines.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Coroutines.swift
//
//  Context: Coroutine concern of LuaEngine. Creates Lua threads pinned
//  in the registry (tracked by the engine's coroutines map), resumes
//  them through CoroutineHandle (CoroutineHandle.swift), and reports
//  status/destruction. Each resume re-arms the compositor hook
//  (armCompositorHook, LuaEngine+Execution.swift) on the coroutine's
//  own lua_State and consults abortReason to surface .cancelled or
//  .instructionLimitExceeded. The private thread-stack push/extract
//  helpers mirror the engine-state bridging in LuaEngine+Bridging.swift
//  but target the coroutine's own lua_State;
//  convertToArrayIfContiguous is shared from there.
//

import Foundation
import CLua

extension LuaEngine {

    // MARK: - Coroutines

    /// Create a new coroutine from Lua code.
    ///
    /// The coroutine starts in a suspended state. Use `resume(_:with:)` to begin
    /// execution. The coroutine can yield values using `coroutine.yield()` in Lua.
    ///
    /// - Parameters:
    ///   - code: The Lua source code to execute in the coroutine.
    ///   - chunkName: An optional name for this chunk, used in error messages
    ///     and tracebacks produced during coroutine execution. Applies the same
    ///     `"@" + chunkName` prefix convention as ``run(_:chunkName:)`` — see
    ///     that method for the full `LUA_IDSIZE` truncation behavior. When `nil`,
    ///     the source text itself is used as the name, preserving the existing
    ///     `[string "…"]` traceback form with no behavior change.
    /// - Returns: A handle to the coroutine
    /// - Throws: `LuaError` if the code cannot be loaded
    ///
    /// ## Example
    ///
    /// ```swift
    /// let handle = try engine.createCoroutine(code: """
    ///     local x = coroutine.yield(1)
    ///     local y = coroutine.yield(x + 1)
    ///     return y * 2
    /// """)
    /// ```
    public func createCoroutine(code: String, chunkName: String? = nil) throws -> CoroutineHandle {
        guard !isPaused.load(ordering: .sequentiallyConsistent) else {
            throw LuaError.enginePaused
        }
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Create a new Lua thread
        guard let thread = lua_newthread(L) else {
            throw LuaError.coroutineError("Failed to create thread")
        }

        // Load the code into the thread — same name-prefix convention as run/evaluate.
        // luaL_loadstring is equivalent to luaL_loadbuffer with the source as name,
        // so passing nil here preserves the existing default behavior exactly.
        let loadResult = loadSourceChunk(thread, code: code, chunkName: chunkName)
        if loadResult != LUA_OK {
            let message = lua_tostring(thread, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)  // Pop the thread from main state
            throw LuaError.syntaxError(message)
        }

        // Store the thread in the registry to prevent garbage collection
        // Thread is on top of main state stack
        let ref = luaL_ref(L, LUA_REGISTRYINDEX)

        let id = UUID()
        coroutines[id] = ref

        return CoroutineHandle(id: id, thread: thread)
    }

    /// Resume a suspended coroutine.
    ///
    /// Call this to start a new coroutine or continue one that yielded.
    ///
    /// - Parameters:
    ///   - handle: The coroutine handle from `createCoroutine`
    ///   - values: Optional values to pass to the coroutine. On first resume,
    ///             these become the function arguments. On subsequent resumes,
    ///             they become the return values of `coroutine.yield()`.
    /// - Returns: The result of the resume operation
    ///
    /// ## Example
    ///
    /// ```swift
    /// // First resume starts the coroutine
    /// let result1 = try engine.resume(handle)
    /// // result1 == .yielded([.number(1.0)])
    ///
    /// // Pass a value back into the coroutine
    /// let result2 = try engine.resume(handle, with: [.number(10.0)])
    /// // result2 == .yielded([.number(11.0)])
    /// ```
    public func resume(_ handle: CoroutineHandle, with values: [LuaValue] = []) throws -> CoroutineResult {
        guard !isPaused.load(ordering: .sequentiallyConsistent) else {
            throw LuaError.enginePaused
        }
        lock.lock()
        defer { lock.unlock() }

        guard coroutines[handle.id] != nil else {
            throw LuaError.coroutineError("Coroutine not found or already destroyed")
        }

        let thread = handle.threadPointer

        // Reset per-run state so a prior cancel/limit abort does not persist.
        abortReason.store(AbortReason.none, ordering: .releasing)
        instructionAccumulator = 0

        // Push values onto the thread's stack
        for value in values {
            pushValueOnThread(thread, value)
        }

        // Arm the compositor hook on the coroutine thread so code inside the
        // coroutine is bounded too (hooks are per-lua_State in 5.4+; each
        // coroutine thread needs its own hook installation).
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armCompositorHook(on: thread)

        // Resume the coroutine
        var nresults: Int32 = 0
        let status = lua_resume(thread, L, Int32(values.count), &nresults)

        switch status {
        case LUA_OK:
            // Coroutine completed normally
            let result = valueFromThread(thread, at: -1)
            if nresults > 0 {
                lua_pop(thread, nresults)
            }
            return .completed(result)

        case LUA_YIELD:
            // Coroutine yielded
            var yieldedValues: [LuaValue] = []
            if nresults > 0 {
                // Read from bottom of result section to top: -nresults, ..., -1
                for i in 0..<nresults {
                    yieldedValues.append(valueFromThread(thread, at: -nresults + i))
                }
                lua_pop(thread, nresults)
            }
            return .yielded(yieldedValues)

        default:
            // Error occurred. Consult abortReason first (authoritative), then
            // fall back to string-sentinel matching for belt-and-suspenders.
            let message = lua_tostring(thread, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(thread, 1)

            let reason = abortReason.load(ordering: .acquiring)
            if reason == AbortReason.cancelled { return .error(.cancelled) }
            if reason == AbortReason.instructionLimitExceeded { return .error(.instructionLimitExceeded) }

            // Belt-and-suspenders sentinel matching — gated behind abortReason != .none
            // so an untrusted coroutine calling error("__luaswift_cancelled__") does not
            // manufacture a spurious .cancelled (same guard as errorFromCode in +Execution).
            if reason != AbortReason.none {
                if message.contains(cancelledSentinel) {
                    return .error(.cancelled)
                }
                if message.contains(instructionLimitSentinel) {
                    return .error(.instructionLimitExceeded)
                }
            }
            return .error(LuaError.coroutineError(message))
        }
    }

    /// Get the status of a coroutine.
    ///
    /// - Parameter handle: The coroutine handle
    /// - Returns: The current status of the coroutine
    public func coroutineStatus(_ handle: CoroutineHandle) -> CoroutineStatus {
        lock.lock()
        defer { lock.unlock() }

        guard coroutines[handle.id] != nil else {
            return .dead
        }

        let thread = handle.threadPointer
        let status = lua_status(thread)

        switch status {
        case LUA_OK:
            // Need to check if it's dead (finished) or suspended
            // A thread with status OK is either new (suspended) or dead (finished)
            // We check the stack: if empty and status OK after a resume, it's dead
            let top = lua_gettop(thread)
            if top == 0 {
                // Check if there's a function to run
                return .dead
            }
            return .suspended

        case LUA_YIELD:
            return .suspended

        default:
            return .dead
        }
    }

    /// Destroy a coroutine and release its resources.
    ///
    /// After calling this, the handle is no longer valid. It's safe to call
    /// this on an already-destroyed or completed coroutine.
    ///
    /// - Parameter handle: The coroutine handle to destroy
    public func destroy(_ handle: CoroutineHandle) {
        // destroy touches the Lua registry (luaL_unref) — guard against pause.
        // This is a non-throwing method so we skip the guard if paused to avoid
        // a breaking API change; callers that destroy during pause will block on
        // the lock (which the VM thread holds) and wait for the pause to end.
        // In practice MoonSwift never destroys coroutines during a debug pause.
        lock.lock()
        defer { lock.unlock() }

        guard let L = L, let ref = coroutines[handle.id] else {
            return
        }

        // Remove from registry (allows garbage collection)
        luaL_unref(L, LUA_REGISTRYINDEX, ref)
        coroutines.removeValue(forKey: handle.id)
    }

    // MARK: - Private Coroutine Helpers

    private func pushValueOnThread(_ thread: OpaquePointer, _ value: LuaValue) {
        switch value {
        case .string(let str):
            lua_pushstring_binary(thread, str)
        case .number(let num):
            lua_pushnumber(thread, num)
        case .complex(let re, let im):
            // Push complex as table with marker - metatable will be set if complex module is loaded
            pushComplexOnThread(thread, re: re, im: im)
        case .bool(let b):
            lua_pushboolean(thread, b ? 1 : 0)
        case .nil:
            lua_pushnil(thread)
        case .table(let dict):
            lua_newtable(thread)
            for (k, v) in dict {
                lua_pushstring_binary(thread, k)
                pushValueOnThread(thread, v)
                lua_settable(thread, -3)
            }
        case .array(let arr):
            lua_newtable(thread)
            for (i, v) in arr.enumerated() {
                pushValueOnThread(thread, v)
                lua_rawseti(thread, -2, lua_Integer(i + 1))
            }
        case .luaFunction(let ref):
            // Push the function from the registry
            _ = lua_rawgeti(thread, LUA_REGISTRYINDEX, lua_Integer(ref))
        }
    }

    private func pushComplexOnThread(_ thread: OpaquePointer, re: Double, im: Double) {
        // Try to use complex.new if available for proper metatable support
        lua_getglobal(thread, "complex")
        if lua_istable(thread, -1) {
            lua_getfield(thread, -1, "new")
            if lua_isfunction(thread, -1) {
                lua_pushnumber(thread, re)
                lua_pushnumber(thread, im)
                if lua_pcall(thread, 2, 1, 0) == LUA_OK {
                    // Remove the 'complex' table, keep the result
                    lua_remove(thread, -2)
                    return
                }
                // pcall failed, pop error and fall through
                lua_pop(thread, 1)
            } else {
                lua_pop(thread, 1)  // pop non-function
            }
        }
        lua_pop(thread, 1)  // pop complex table or nil

        // Fallback: create table without metatable
        lua_newtable(thread)
        lua_pushnumber(thread, re)
        lua_setfield(thread, -2, "re")
        lua_pushnumber(thread, im)
        lua_setfield(thread, -2, "im")
        lua_pushstring(thread, "complex")
        lua_setfield(thread, -2, "__luaswift_type")
    }

    private func valueFromThread(_ thread: OpaquePointer, at index: Int32) -> LuaValue {
        let type = lua_type(thread, index)

        switch type {
        case LUA_TNIL:
            return .nil

        case LUA_TBOOLEAN:
            return .bool(lua_toboolean(thread, index) != 0)

        case LUA_TNUMBER:
            return .number(lua_tonumber(thread, index))

        case LUA_TSTRING:
            guard let str = lua_getstring(thread, index) else { return .nil }
            return .string(str)

        case LUA_TTABLE:
            return tableFromThread(thread, at: index)

        default:
            return .nil
        }
    }

    private func tableFromThread(_ thread: OpaquePointer, at index: Int32) -> LuaValue {
        var dict: [String: LuaValue] = [:]
        var intKeyedValues: [Int: LuaValue] = [:]
        var hasStringKeys = false

        // Normalize index to absolute
        let absIndex = index < 0 ? lua_gettop(thread) + index + 1 : index

        lua_pushnil(thread)
        while lua_next(thread, absIndex) != 0 {
            let keyType = lua_type(thread, -2)
            let value = valueFromThread(thread, at: -1)

            if keyType == LUA_TNUMBER {
                let keyNum = Int(lua_tonumber(thread, -2))
                intKeyedValues[keyNum] = value
            } else if keyType == LUA_TSTRING {
                hasStringKeys = true
                if let key = lua_getstring(thread, -2) {
                    dict[key] = value
                }
            }

            lua_pop(thread, 1)
        }

        // Check for complex number (has __luaswift_type = "complex")
        if let typeMarker = dict["__luaswift_type"]?.stringValue, typeMarker == "complex",
           let re = dict["re"]?.numberValue,
           let im = dict["im"]?.numberValue {
            return .complex(re: re, im: im)
        }

        // Check if integer keys form a contiguous array starting at 1
        if !hasStringKeys, let arr = convertToArrayIfContiguous(intKeyedValues) {
            return .array(arr)
        }

        // Not a pure array - merge all values into dict
        if !intKeyedValues.isEmpty || !dict.isEmpty {
            for (key, val) in intKeyedValues {
                dict[String(key)] = val
            }
            return .table(dict)
        }

        return .table([:])
    }
}
