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
//  Context: Public debug-hook API for LuaEngine (#20 / F5).
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
//  This diverges from the PRD's literal "release the lock and block on a
//  semaphore" wording but satisfies the same safety contract:
//  - No deadlock: any call from another thread during a pause sees
//    isPaused == true BEFORE trying to acquire the lock and throws
//    LuaError.enginePaused instead. The lock is never acquired by a second
//    thread while paused.
//  - No UB: the VM is not executing instructions during the handler call
//    (the compositor hook suspends it); only inert snapshot values — never
//    the live inspector or L pointer — can escape the handler scope.
//  - MoonSwift's blocking UI round-trip is its own concern: it drives the
//    engine on a dedicated thread and the handler blocks that thread until
//    the user issues a command. The LuaSwift lock stays held on that thread
//    throughout (same as any other run), so no other thread can concurrently
//    access the engine anyway.
//
//  ## stop → LuaError.cancelled
//
//  The .stop command reuses the F1 cancellation unwind: sets abortReason=1
//  and raises lua_error with the cancelledSentinel. runDebug surfaces the
//  terminal state as LuaError.cancelled. MoonSwift's DebugSession
//  distinguishes debugger-stop from a UI-cancel by knowing it issued .stop
//  to runDebug — no separate LuaError case is needed (documented choice).
//
//  ## No-debug overhead guarantee
//
//  Plain run/evaluate with no debug handler arms ONLY LUA_MASKCOUNT (existing
//  behavior). armDebugHook is only called from runDebug; armCompositorHook is
//  unchanged. Inside compositorHookCallback, the debug branch is guarded by
//  `engine.debugHandler != nil` — when nil the branch compiles away entirely
//  at -O (zero dead-code overhead). Non-debug tests remain unaffected.
//
//  ## Inspector validity token
//
//  DebugInspectorImpl.isValid is true during the handler call; invalidate()
//  flips it false after the handler returns. Every public method on the
//  inspector calls precondition(isValid, ...) so use-after-callback traps
//  deterministically at the programming-error call site.
//
//  ## Eager snapshot / depth cap / cycle detection
//
//  Table children are materialised with raw lua_next (no __index/__pairs,
//  per F4 discipline) up to maxInspectionDepth (64) levels. A table seen
//  more than once via raw lua_topointer yields
//  .reference(kind:.table, preview:"<cycle>", children: nil).
//
//  ## lua_getlocal / lua_getupvalue
//
//  Both are real functions (not macros) on 5.1–5.5 and imported directly
//  from CLua. No shim is needed (verified in LuaHelpers.swift cross-check).
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

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Reset per-run state (same as evaluate).
        abortReason.store(0, ordering: .releasing)
        instructionAccumulator = 0
        pendingRuntimeFailure = nil
        lastWriteError = nil
        stepState = nil

        let loadResult = loadSourceChunk(L, code: source, chunkName: chunkName)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Arm the debug-capable hook (full mask) and install TLS.
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

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Validate provenance and get the raw bytecode (same as Bytecode.swift).
        let bytecode = try chunk.validatedBytecode()

        // Reset per-run state.
        abortReason.store(0, ordering: .releasing)
        instructionAccumulator = 0
        pendingRuntimeFailure = nil
        lastWriteError = nil
        stepState = nil

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

        // Arm debug hook and TLS.
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armDebugHook(on: L)

        lua_pushcfunction(L, runtimeErrorHandler)
        lua_insert(L, 1)
        let handlerIdx: Int32 = 1

        let callResult = lua_pcall(L, 0, 1, handlerIdx)
        lua_remove(L, handlerIdx)

        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            #if DEBUG
            assert(lua_gettop(L) == 0, "Stack not clean after runDebug(chunk) pcall abort: top=\(lua_gettop(L))")
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
}

// MARK: - Stepping Helpers (internal free functions)

/// Compute the current Lua call-stack depth by counting frames via
/// `lua_getstack`.
///
/// Walks upward from level 0 until `lua_getstack` returns 0. This measures
/// the ACTUAL stack depth at any point and is the reference used by
/// `shouldPauseForStep` for all stepping decisions.
///
/// Using live depth-counting (rather than incrementing/decrementing a counter
/// on CALL/RET events) sidesteps the tail-call event divergence between
/// Lua versions:
/// - 5.1: HOOKCALL + HOOKTAILRET for tail calls (HOOKTAILRET fires for the
///        tail callee, but no HOOKTAILRET fires for the tail caller's return).
/// - 5.2+: HOOKCALL + HOOKTAILCALL for tail calls (HOOKTAILCALL is the call
///         event for the tail callee; no matching return event fires).
///
/// By re-reading the actual depth from `lua_getstack` at each LINE event, we
/// bypass the ambiguity entirely.
///
/// internal: called by compositorHookCallback
internal func currentStackLevel(_ L: OpaquePointer) -> Int {
    var level: Int32 = 0
    var ar = lua_Debug()
    while lua_getstack(L, level, &ar) != 0 {
        level += 1
    }
    return Int(level)
}

/// Decide whether to pause based on the current step state and stack depth.
///
/// - Parameters:
///   - event: The raw Lua hook event (e.g. `LUA_HOOKLINE`).
///   - currentLevel: The live stack depth from ``currentStackLevel``.
///   - state: The current ``StepState``, or `nil` for breakpoint mode.
/// - Returns: `true` if the VM should pause and the handler should be called.
///
/// ## Semantics
///
/// | stepState          | pauses when                              |
/// |--------------------|------------------------------------------|
/// | nil (breakpoint)   | every LINE event                         |
/// | .stepInto          | next LINE event                          |
/// | .stepOver(from)    | LINE when currentLevel <= from           |
/// | .stepOut(from)     | LINE when currentLevel < from            |
///
/// The `<`/`<=` comparisons handle tail calls: when `f` tail-calls `g` and
/// `g` returns, the depth drops from `from` (inside `g`) to `from - 1`
/// (inside `f`'s caller) — both `<` and `<=` fire correctly. A non-tail
/// call from `f` increases depth by 1; `<=` then keeps `stepOver` parked
/// until that callee returns and depth drops back to `from`.
///
/// internal: called by compositorHookCallback
internal func shouldPauseForStep(
    event: Int32,
    currentLevel: Int,
    state: StepState?
) -> Bool {
    guard event == LUA_HOOKLINE else { return false }
    switch state {
    case nil:
        return true  // breakpoint mode: handler decides via .continueRun/.stop
    case .stepInto:
        return true  // any LINE
    case .stepOver(let fromLevel):
        return currentLevel <= fromLevel
    case .stepOut(let fromLevel):
        return currentLevel < fromLevel
    }
}

// MARK: - Debug Inspector Implementation (internal)

/// Concrete implementation of ``LuaDebugInspector``.
///
/// Created inside the compositor hook, valid only while the handler callback
/// executes. All methods `precondition(isValid)` so use-after-invalidation
/// traps at the call site rather than silently reading stale state.
///
/// Snapshots are taken lazily per-call but always from inside the valid
/// callback window — the `lua_State` is parked (not executing instructions)
/// and the stack layout is stable for the duration.
internal final class DebugInspectorImpl: LuaDebugInspector {
    private let L: OpaquePointer
    private var valid: Bool = true

    internal init(L: OpaquePointer) {
        self.L = L
    }

    internal func invalidate() {
        valid = false
    }

    // MARK: LuaDebugInspector

    public var isValid: Bool { valid }

    public var callStack: [LuaStackFrame] {
        precondition(valid, "LuaDebugInspector used after callback returned")
        return walkLuaStack(L, startLevel: 0)
    }

    public func locals(frameLevel: Int) -> [(name: String, value: LuaInspectedValue)] {
        precondition(valid, "LuaDebugInspector used after callback returned")
        var result: [(name: String, value: LuaInspectedValue)] = []
        var ar = lua_Debug()
        guard lua_getstack(L, Int32(frameLevel), &ar) != 0 else { return result }

        var idx: Int32 = 1
        while true {
            guard let rawName = lua_getlocal(L, &ar, idx) else { break }
            let name = String(cString: rawName)
            // Skip internal Lua temporaries (names starting with '(')
            if !name.hasPrefix("(") {
                let value = inspectedValueFromStack(L, at: -1, visited: &visitedTables)
                result.append((name: name, value: value))
            }
            lua_pop(L, 1)
            idx += 1
        }
        visitedTables.removeAll()
        return result
    }

    public func upvalues(frameLevel: Int) -> [(name: String, value: LuaInspectedValue)] {
        precondition(valid, "LuaDebugInspector used after callback returned")
        var result: [(name: String, value: LuaInspectedValue)] = []

        // Get the function at frameLevel via lua_getinfo("f").
        var ar = lua_Debug()
        guard lua_getstack(L, Int32(frameLevel), &ar) != 0 else { return result }
        guard lua_getinfo(L, "f", &ar) != 0 else { return result }
        // lua_getinfo("f") pushes the function at top; stack: [..., fn]
        let funcIdx = lua_gettop(L)

        var idx: Int32 = 1
        while true {
            guard let rawName = lua_getupvalue(L, funcIdx, idx) else { break }
            let name = String(cString: rawName)
            let value = inspectedValueFromStack(L, at: -1, visited: &visitedTables)
            result.append((name: name, value: value))
            lua_pop(L, 1)
            idx += 1
        }
        // Pop the function itself.
        lua_pop(L, 1)
        visitedTables.removeAll()
        return result
    }

    public func globals() -> [(name: String, value: LuaInspectedValue)] {
        precondition(valid, "LuaDebugInspector used after callback returned")
        var result: [(name: String, value: LuaInspectedValue)] = []

        // Push the globals table (same helper as Introspection).
        pushGlobalsTableForDebug(L)
        let globalsIdx = lua_gettop(L)

        lua_pushnil(L)
        while lua_next(L, globalsIdx) != 0 {
            // stack: [globals, key, value]
            if lua_type(L, -2) == LUA_TSTRING,
               let key = lua_getstring(L, -2) {
                let value = inspectedValueFromStack(L, at: -1, visited: &visitedTables)
                result.append((name: key, value: value))
            }
            lua_pop(L, 1)  // pop value, keep key
        }
        lua_pop(L, 1)  // pop globals table
        visitedTables.removeAll()
        return result
    }

    // MARK: - Private scratch

    /// Set of raw table pointers already visited in the current snapshot walk
    /// (cycle detection). Reset after each public method call.
    private var visitedTables: Set<UnsafeRawPointer> = []
}

// MARK: - Globals table push (local helper for inspector)

/// Push the engine's globals table onto the Lua stack.
/// Identical to `pushGlobalsTable` in LuaEngine+Introspection.swift but
/// accessible from inside this file without importing that private function.
@inline(__always)
private func pushGlobalsTableForDebug(_ L: OpaquePointer) {
    #if LUA_VERSION_51
    lua_pushvalue(L, LUA_GLOBALSINDEX)
    #else
    _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(LUA_RIDX_GLOBALS))
    #endif
}

// MARK: - LuaInspectedValue materialiser (internal)

/// Convert the Lua value at `index` to a ``LuaInspectedValue`` snapshot.
///
/// - Scalars (nil/bool/number/string) → `.scalar(LuaValue)`.
/// - Tables → `.reference(kind:.table, preview:, children:)` with raw
///   `lua_next` recursion up to ``LuaInspectedValue/maxInspectionDepth``
///   levels. A repeated raw pointer → `<cycle>` with `children: nil`.
/// - Functions/userdata/threads → `.reference(kind:, preview:, children: nil)`.
///
/// Uses `lua_topointer` for cycle detection — the pointer is stable for
/// the lifetime of the GC object and unique within the state.
///
/// - Parameters:
///   - L: The Lua state (must be mid-debug-pause; no instructions executing).
///   - index: Stack index of the value.
///   - visited: In-out set of already-visited table pointers (cycle detection).
///   - depth: Current nesting depth (starts at 0 for the outermost call).
/// - Returns: The materialised ``LuaInspectedValue``.
///
/// internal: called by DebugInspectorImpl methods
internal func inspectedValueFromStack(
    _ L: OpaquePointer,
    at index: Int32,
    visited: inout Set<UnsafeRawPointer>,
    depth: Int = 0
) -> LuaInspectedValue {
    let type = lua_type(L, index)
    // Absolute index so it stays valid while we push/pop during table walk.
    let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index

    switch type {
    case LUA_TNIL:
        return .scalar(.nil)

    case LUA_TBOOLEAN:
        return .scalar(.bool(lua_toboolean(L, absIndex) != 0))

    case LUA_TNUMBER:
        // LuaValue.number(Double) covers all numeric types on all versions.
        return .scalar(.number(lua_tonumber(L, absIndex)))

    case LUA_TSTRING:
        if let str = lua_getstring(L, absIndex) {
            return .scalar(.string(str))
        }
        return .scalar(.nil)

    case LUA_TTABLE:
        guard let ptr = lua_topointer(L, absIndex) else {
            return .reference(kind: .table, preview: "table: (unknown)", children: nil)
        }
        let rawPtr = UnsafeRawPointer(ptr)

        // Cycle detection.
        if visited.contains(rawPtr) {
            return .reference(kind: .table, preview: "<cycle>", children: nil)
        }

        // Depth cap.
        if depth >= LuaInspectedValue.maxInspectionDepth {
            return .reference(kind: .table, preview: "<depth limit>", children: nil)
        }

        let preview = "table: \(String(format: "%p", UInt(bitPattern: rawPtr)))"
        visited.insert(rawPtr)
        defer { visited.remove(rawPtr) }

        var children: [(key: String, value: LuaInspectedValue)] = []
        lua_pushnil(L)
        while lua_next(L, absIndex) != 0 {
            // stack: [absIndex=table, ..., key@-2, value@-1]
            let keyStr: String
            let keyType = lua_type(L, -2)
            if keyType == LUA_TSTRING, let k = lua_getstring(L, -2) {
                keyStr = k
            } else if keyType == LUA_TNUMBER {
                keyStr = "\(lua_tonumber(L, -2))"
            } else {
                // Skip non-string/number keys (uncommon, but safe to omit).
                lua_pop(L, 1)
                continue
            }
            let val = inspectedValueFromStack(L, at: -1, visited: &visited, depth: depth + 1)
            children.append((key: keyStr, value: val))
            lua_pop(L, 1)  // pop value, keep key
        }
        return .reference(kind: .table, preview: preview, children: children)

    case LUA_TFUNCTION:
        let ptr = lua_topointer(L, absIndex)
        let addrStr = ptr.map { String(format: "%p", UInt(bitPattern: UnsafeRawPointer($0))) } ?? "?"
        return .reference(kind: .function, preview: "function: \(addrStr)", children: nil)

    case LUA_TUSERDATA, LUA_TLIGHTUSERDATA:
        let ptr = lua_topointer(L, absIndex)
        let addrStr = ptr.map { String(format: "%p", UInt(bitPattern: UnsafeRawPointer($0))) } ?? "?"
        return .reference(kind: .userdata, preview: "userdata: \(addrStr)", children: nil)

    case LUA_TTHREAD:
        let ptr = lua_topointer(L, absIndex)
        let addrStr = ptr.map { String(format: "%p", UInt(bitPattern: UnsafeRawPointer($0))) } ?? "?"
        return .reference(kind: .thread, preview: "thread: \(addrStr)", children: nil)

    default:
        return .scalar(.nil)
    }
}

// MARK: - Compositor Hook Extension (debug dispatch)
//
// The compositor hook callback is defined as a free function in
// LuaEngine+Execution.swift. To add debug dispatch without duplicating the
// hook body, we provide a separate internal function that the compositor
// calls at the appropriate step.

/// Dispatch a debug event from inside the compositor hook.
///
/// Called by `compositorHookCallback` after the cancel/limit checks, only
/// when `engine.debugHandler != nil` and the event is LINE, CALL, or RET.
///
/// Responsibilities:
/// 1. Determine whether to pause (via `shouldPauseForStep`).
/// 2. If pausing: build the event, create the inspector, set isPaused=true,
///    call the handler synchronously, invalidate the inspector, set
///    isPaused=false, process the command.
/// 3. Commands: .continueRun clears stepState; .stepInto/.stepOver/.stepOut
///    set a new stepState; .stop aborts via cancellation unwind.
///
/// internal: called only from compositorHookCallback
internal func dispatchDebugEvent(
    _ L: OpaquePointer,
    ar: UnsafeMutablePointer<lua_Debug>,
    engine: LuaEngine
) {
    let rawEvent = ar.pointee.event

    // Only dispatch on LINE, CALL, RET (and tail-call variants).
    let isLine = rawEvent == LUA_HOOKLINE
    let isCall = rawEvent == LUA_HOOKCALL
    #if LUA_VERSION_51
    let isTail = rawEvent == LUA_HOOKTAILRET
    #else
    let isTail = rawEvent == LUA_HOOKTAILCALL
    #endif
    let isRet  = rawEvent == LUA_HOOKRET

    guard isLine || isCall || isTail || isRet else { return }

    // Compute live stack depth for stepping decisions.
    // For CALL events we also need it to set the fromLevel on new step commands.
    let currentLevel = currentStackLevel(L)

    // Line events: check step state.
    if isLine {
        guard shouldPauseForStep(event: rawEvent, currentLevel: currentLevel, state: engine.stepState) else {
            return
        }
    }
    // For CALL/RET events in breakpoint mode (nil stepState): do not pause —
    // only LINE events produce pauses. CALL/RET are consumed for bookkeeping
    // only (the frame snapshot in the .call event is built on CALL).
    // Exception: if stepState is not nil, do not pause on CALL/RET either;
    // stepping decisions are always LINE-based (see shouldPauseForStep).
    if isCall || isTail || isRet {
        // Build the event (for handler awareness of calls/returns) but only
        // if the handler wants to be notified on non-line events.
        // Per the PRD and design: the handler is notified on CALL/RET only
        // when in breakpoint mode (stepState == nil). In step mode, only
        // LINE events pause.
        guard engine.stepState == nil else { return }
    }

    // Populate the debug record with source/line/name info.
    guard lua_getinfo(L, "nSl", ar) != 0 else { return }

    // Build the LuaDebugEvent.
    let event: LuaDebugEvent
    if isLine {
        event = .line(Int(ar.pointee.currentline))
    } else if isCall || isTail {
        let source: String = withUnsafeBytes(of: ar.pointee.short_src) { rawBuf in
            guard let ptr = rawBuf.baseAddress?.assumingMemoryBound(to: CChar.self) else { return "?" }
            return String(cString: ptr)
        }
        let name: String? = ar.pointee.name.map { String(cString: $0) }
        let currentLine: Int? = ar.pointee.currentline >= 0 ? Int(ar.pointee.currentline) : nil
        let frame = LuaStackFrame(name: name, source: source, currentLine: currentLine, level: 0)
        event = .call(frame)
    } else {
        event = .ret
    }

    // --- Synchronous handler call ---
    //
    // The engine lock is already held by the active run on this thread.
    // isPaused prevents any other thread from acquiring the lock while we
    // are inside the handler (they throw .enginePaused instead).
    engine.isPaused.store(true, ordering: .sequentiallyConsistent)

    let inspector = DebugInspectorImpl(L: L)
    let command = engine.debugHandler!(event, inspector)
    inspector.invalidate()

    engine.isPaused.store(false, ordering: .sequentiallyConsistent)

    // Process command.
    switch command {
    case .continueRun:
        engine.stepState = nil

    case .stepInto:
        engine.stepState = .stepInto

    case .stepOver:
        engine.stepState = .stepOver(fromLevel: currentLevel)

    case .stepOut:
        engine.stepState = .stepOut(fromLevel: currentLevel)

    case .stop:
        // Reuse the F1 cancellation unwind — identical path as
        // requestCancellation() firing in the compositor hook.
        engine.abortReason.store(1, ordering: .releasing)
        lua_pushstring(L, cancelledSentinel)
        _ = lua_error(L)
        // lua_error does not return (longjmp to pcall boundary).
    }
}
