//
//  LuaEngine+Debug.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Debug.swift
//
//  Context: Public debug-hook API for LuaEngine (#20 / F5). Contains
//  the three entry points — setDebugHandler, runDebug (source overload),
//  runDebug (CompiledChunk overload) — and the internal armDebugHook that
//  all runDebug entry points call to arm the full LINE/CALL/RET/COUNT mask.
//
//  The implementation is spread across three sibling files:
//    LuaEngine+DebugStepping.swift  — step-state helpers + dispatchDebugEvent
//    LuaEngine+DebugInspector.swift — DebugInspectorImpl + materialiser
//
//  ## Concurrency model (synchronous handler + atomic isPaused)
//
//  The compositor hook fires on the VM thread (lock held by the active run).
//  When a debug handler is set and the current event passes the step check,
//  the hook:
//    1. Sets isPaused = true (ManagedAtomic, sequentially consistent).
//    2. Builds a DebugInspectorImpl (validity-scoped; only inert
//       LuaInspectedValue snapshots cross threads).
//    3. Calls handler(event, inspector) SYNCHRONOUSLY — the lock stays held.
//    4. Invalidates the inspector.
//    5. Sets isPaused = false.
//    6. Processes the returned LuaDebugCommand.
//
//  No deadlock: any call from another thread during a pause sees isPaused==true
//  BEFORE trying to acquire the lock and throws LuaError.enginePaused instead.
//
//  ## stop → LuaError.cancelled
//
//  The .stop command reuses the F1 cancellation unwind: sets abortReason=1
//  and raises lua_error with the cancelledSentinel. runDebug surfaces the
//  terminal state as LuaError.cancelled (documented choice — no separate case).
//
//  ## No-debug overhead guarantee
//
//  Plain run/evaluate with no debug handler arms ONLY LUA_MASKCOUNT (existing
//  behavior). armDebugHook is only called from runDebug; inside
//  compositorHookCallback the debug branch is guarded by
//  `engine.debugHandler != nil` — when nil the branch compiles away entirely
//  at -O (zero dead-code overhead). Non-debug tests remain unaffected.
//
//  Neighbors:
//    LuaEngine.swift                — stored state (debugHandler, isPaused, stepState)
//    LuaEngine+CompositorHook.swift — compositorHookCallback calls dispatchDebugEvent
//    LuaEngine+Execution.swift      — armCompositorHook (plain run/evaluate)
//

import Atomics
import Foundation
import CLua

// MARK: - Public Engine Extension

extension LuaEngine {

    // MARK: - setDebugHandler

    /// Set (or clear) the debug event handler.
    ///
    /// The handler is called synchronously on the VM thread at each line,
    /// call, and return event during a ``runDebug(_:chunkName:)`` or
    /// ``runDebug(_:)-7y0a2`` run. The handler receives a validity-scoped
    /// ``LuaDebugInspector`` and must return a ``LuaDebugCommand``.
    ///
    /// Pass `nil` to remove the handler. Removing the handler does not affect
    /// a run already in progress; the change takes effect on the next
    /// ``runDebug`` call.
    ///
    /// - Parameter handler: The handler closure, or `nil` to deregister.
    public func setDebugHandler(_ handler: LuaDebugHandler?) {
        lock.lock()
        defer { lock.unlock() }
        debugHandler = handler
    }

    // MARK: - runDebug (source)

    /// Execute Lua source code with the debug hook active.
    ///
    /// Identical to ``evaluate(_:chunkName:)`` except that it arms the
    /// compositor hook with the full `LUA_MASKLINE | LUA_MASKCALL |
    /// LUA_MASKRET | LUA_MASKCOUNT` mask so the registered
    /// ``LuaDebugHandler`` receives line/call/return events.
    ///
    /// A ``LuaDebugHandler`` must be installed via ``setDebugHandler(_:)``
    /// before calling this method; if no handler is set the hook still fires
    /// for cancellation/limit checks but no debug events are dispatched.
    ///
    /// ## Concurrency
    ///
    /// The handler is called synchronously on the calling thread while the
    /// engine lock is held. Any concurrent `LuaEngine` method that touches
    /// the Lua state will find ``isPaused`` set and throw
    /// ``LuaError/enginePaused`` immediately (before attempting to acquire
    /// the lock), preventing deadlocks and C-level UB.
    ///
    /// ## stop → LuaError.cancelled
    ///
    /// When the handler returns `.stop`, the VM is aborted via the
    /// cancellation unwind (``LuaError/cancelled``). MoonSwift's
    /// `DebugSession` knows it issued `.stop` and treats the resulting
    /// `.cancelled` as a debugger-stop — no separate error case is required.
    ///
    /// - Parameters:
    ///   - source: Lua source code to execute.
    ///   - chunkName: Optional chunk name for error messages and tracebacks.
    ///     Uses the same `"@" + chunkName` prefix convention as
    ///     ``run(_:chunkName:)``.
    /// - Returns: The last return value from the Lua code.
    /// - Throws: ``LuaError`` — including ``LuaError/cancelled`` when the
    ///   handler issues `.stop`.
    public func runDebug(_ source: String, chunkName: String? = nil) throws -> LuaValue {
        guard !isPaused.load(ordering: .sequentiallyConsistent) else {
            throw LuaError.enginePaused
        }
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else { throw LuaError.initializationFailed }

        resetRunState()

        let loadResult = loadSourceChunk(L, code: source, chunkName: chunkName)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        return try executeWithDebugHook(L)
    }

    // MARK: - runDebug (CompiledChunk)

    /// Execute a precompiled chunk with the debug hook active.
    ///
    /// Behaves like ``runDebug(_:chunkName:)`` but accepts a
    /// ``CompiledChunk`` previously produced by ``precompile(_:chunkName:)``.
    /// The chunk's embedded provenance metadata is validated exactly as in
    /// the plain ``run(_:)-8rxyt`` overload.
    ///
    /// - Parameter chunk: A ``CompiledChunk`` from ``precompile(_:chunkName:)``.
    /// - Returns: The last return value from the Lua code.
    /// - Throws: ``LuaError`` — including ``LuaError/cancelled`` on `.stop`.
    public func runDebug(_ chunk: CompiledChunk) throws -> LuaValue {
        guard !isPaused.load(ordering: .sequentiallyConsistent) else {
            throw LuaError.enginePaused
        }
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else { throw LuaError.initializationFailed }

        // Validate provenance and get the raw bytecode (same as Bytecode.swift).
        let bytecode = try chunk.validatedBytecode()

        resetRunState()

        // Load the bytecode onto the stack.
        let loadResult = bytecode.withUnsafeBytes { rawBuf -> Int32 in
            guard let baseAddr = rawBuf.baseAddress else { return LUA_ERRMEM }
            let ptr = baseAddr.assumingMemoryBound(to: CChar.self)
            // Binary chunks: load-time name is ignored by Lua (reads from
            // Proto.source embedded at precompile time). Pass a placeholder.
            let name = "=(compiled)"
            return name.withCString { nameCStr in
                luaL_loadbuffer_source(L, ptr, rawBuf.count, nameCStr)
            }
        }

        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.runtimeError("Failed to load compiled chunk: \(message)")
        }

        return try executeWithDebugHook(L)
    }

    // MARK: - Hook Arming (internal)

    /// Arm the compositor hook with the full debug mask on the given state.
    ///
    /// Extends ``armCompositorHook(on:)`` by adding `LUA_MASKLINE`,
    /// `LUA_MASKCALL`, and `LUA_MASKRET` to the standard `LUA_MASKCOUNT`.
    /// This enables line/call/return events while preserving the existing
    /// cancel/limit COUNT firing at the same interval.
    ///
    /// Must be called at the start of every ``runDebug`` entry point.
    ///
    /// internal: called from runDebug(_:chunkName:) and runDebug(_:chunk)
    internal func armDebugHook(on state: OpaquePointer) {
        let count: Int32
        if instructionLimit > 0 {
            count = Int32(min(hookInterval, instructionLimit))
        } else {
            count = Int32(hookInterval)
        }
        armedHookCount = Int(count)
        let mask = Int32(LUA_MASKCOUNT) | Int32(LUA_MASKLINE) | Int32(LUA_MASKCALL) | Int32(LUA_MASKRET)
        lua_sethook(state, compositorHookCallback, mask, count)
    }

    // MARK: - Private Helpers

    /// Reset per-run mutable state. Called at the top of every runDebug entry point.
    private func resetRunState() {
        abortReason.store(0, ordering: .releasing)
        instructionAccumulator = 0
        pendingRuntimeFailure = nil
        lastWriteError = nil
        stepState = nil
    }

    /// Arm the debug hook, execute the chunk on the stack via lua_pcall,
    /// and return the result. Handles error unwinding identically to evaluate().
    ///
    /// Precondition: the chunk function is already on the Lua stack.
    private func executeWithDebugHook(_ L: OpaquePointer) throws -> LuaValue {
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armDebugHook(on: L)

        // Push errfunc handler below the chunk (same pattern as evaluate).
        lua_pushcfunction(L, runtimeErrorHandler)
        lua_insert(L, 1)
        let handlerIdx: Int32 = 1

        let callResult = lua_pcall(L, 0, 1, handlerIdx)
        lua_remove(L, handlerIdx)

        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            #if DEBUG
            assert(lua_gettop(L) == 0, "Stack not clean after runDebug pcall abort: top=\(lua_gettop(L))")
            #endif

            if let writeError = lastWriteError {
                lastWriteError = nil
                throw writeError
            }
            throw errorFromCode(callResult, message: message)
        }

        let result = valueFromStack(at: -1)
        lua_pop(L, 1)
        return result
    }
}
