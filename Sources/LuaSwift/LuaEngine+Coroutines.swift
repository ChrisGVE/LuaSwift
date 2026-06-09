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
//  .instructionLimitExceeded. Resume arguments are pushed with the shared
//  pushSimpleValue (LuaEngine+Bridging.swift), which already takes an
//  explicit lua_State. The thread-targeted READ helpers (valueFromThread/
//  tableFromThread) stay local because they intentionally differ from the
//  engine-state readers; convertToArrayIfContiguous is shared from Bridging.
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
        guard !isPaused.load(ordering: .acquiring) else {
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
            // Remove the error message from the thread's stack before the thread
            // itself is popped from the main state. Failing to pop here leaves the
            // thread's stack non-empty, inconsistent with every other error path.
            lua_pop(thread, 1)  // pop error message from thread stack
            #if DEBUG
            assert(lua_gettop(thread) == 0,
                   "createCoroutine: thread stack not empty after syntax-error cleanup")
            #endif
            lua_pop(L, 1)  // pop the thread object from main state
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
        guard !isPaused.load(ordering: .acquiring) else {
            throw LuaError.enginePaused
        }
        lock.lock()
        defer { lock.unlock() }

        guard coroutines[handle.id] != nil else {
            throw LuaError.coroutineError("Coroutine not found or already destroyed")
        }

        let thread = handle.threadPointer
        resetResumeState()

        // Push the resume arguments onto the thread's own stack.
        for value in values {
            pushSimpleValue(thread, value)
        }

        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armResumeHooks(on: thread)
        defer { if let L = L { removeCoroutineDebugShims(on: L) } }

        var nresults: Int32 = 0
        let status = lua_resume(thread, L, Int32(values.count), &nresults)

        switch status {
        case LUA_OK:
            // Coroutine completed normally — return ALL of its return values.
            return .completed(collectThreadResults(thread, count: nresults))

        case LUA_YIELD:
            // Coroutine yielded — return every yielded value.
            return .yielded(collectThreadResults(thread, count: nresults))

        default:
            return classifyResumeError(thread)
        }
    }

    /// Reset the per-run mutable state shared with every other entry point
    /// (run/evaluate/callLuaFunction/runDebug) so a prior cancel/limit abort or a
    /// stale structured-error stash does not leak into this resume.
    private func resetResumeState() {
        abortReason.store(AbortReason.none, ordering: .releasing)
        instructionAccumulator = 0
        pendingRuntimeFailure = nil
    }

    /// Arm the hook for a resume on the coroutine's own `lua_State` (hooks are
    /// per-`lua_State` in 5.4+, so each thread needs its own installation).
    ///
    /// With a debug session active, arm the full LINE/CALL/RET mask so the
    /// debugger steps *into* the coroutine body, and install the in-Lua
    /// coroutine shims on the main state so coroutines this body creates are
    /// stepped into as well (#26); the coroutine starts each resume in breakpoint
    /// mode (`stepState = nil`). With no session, arm the COUNT-only compositor
    /// hook exactly as a plain run does. Pairs with the `removeCoroutineDebugShims`
    /// cleanup in `resume`'s defer.
    private func armResumeHooks(on thread: OpaquePointer) {
        if debugHandler != nil {
            stepState = nil
            armDebugHook(on: thread)
            if let L = L { installCoroutineDebugShims(on: L) }
        } else {
            armCompositorHook(on: thread)
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

    /// Classify a non-`OK`/`YIELD` `lua_resume` status into a
    /// `CoroutineResult.error`, popping the error message off the thread stack.
    ///
    /// `abortReason` is authoritative (consulted first). String-sentinel
    /// matching is a belt-and-suspenders fallback, gated behind
    /// `abortReason != .none` so an untrusted coroutine calling
    /// `error("__luaswift_cancelled__")` cannot manufacture a spurious
    /// `.cancelled` (same guard as `errorFromCode` in LuaEngine+Execution.swift).
    private func classifyResumeError(_ thread: OpaquePointer) -> CoroutineResult {
        let message = lua_tostring(thread, -1).map { String(cString: $0) } ?? "Unknown error"
        lua_pop(thread, 1)

        let reason = abortReason.load(ordering: .acquiring)
        if reason == AbortReason.cancelled { return .error(.cancelled) }
        if reason == AbortReason.instructionLimitExceeded { return .error(.instructionLimitExceeded) }

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

    /// Read `nresults` values from the top of the thread's stack in
    /// bottom-to-top order (`-nresults, …, -1`) and pop them all. Returns an
    /// empty array when `nresults <= 0`. Shared by the completed and yielded
    /// resume paths so both surface every value the coroutine produced.
    private func collectThreadResults(_ thread: OpaquePointer, count nresults: Int32) -> [LuaValue] {
        guard nresults > 0 else { return [] }
        var values: [LuaValue] = []
        values.reserveCapacity(Int(nresults))
        for i in 0..<nresults {
            values.append(valueFromThread(thread, at: -nresults + i))
        }
        lua_pop(thread, nresults)
        return values
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
