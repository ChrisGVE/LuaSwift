//
//  LuaEngine+DebugStepping.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+DebugStepping.swift
//
//  Context: Stepping logic for the debug-hook system (#20 / F5).
//  Contains the step-state helpers (currentStackLevel, shouldPauseForStep)
//  and the full debug-event dispatcher (dispatchDebugEvent) that the
//  compositor hook calls on every LINE/CALL/RET event when a debug handler
//  is installed. StepState (the enum) is defined in LuaEngine.swift with
//  the other stored state.
//
//  ## Stepping semantics
//
//  | stepState          | pauses when                              |
//  |--------------------|------------------------------------------|
//  | nil (breakpoint)   | every LINE event                         |
//  | .stepInto          | next LINE event                          |
//  | .stepOver(from)    | LINE when currentLevel <= from           |
//  | .stepOut(from)     | LINE when currentLevel < from            |
//
//  currentStackLevel reads the live call depth on every LINE event by
//  walking lua_getstack. This sidesteps the tail-call event divergence
//  between Lua 5.1 (HOOKTAILRET) and 5.2+ (HOOKTAILCALL).
//
//  Neighbors:
//    LuaEngine.swift                — StepState enum, stepState stored property
//    LuaEngine+CompositorHook.swift — calls dispatchDebugEvent
//    LuaEngine+Debug.swift          — public API, armDebugHook
//    LuaEngine+DebugInspector.swift — DebugInspectorImpl used in dispatchDebugEvent
//

import Foundation
import CLua

// MARK: - Stack Depth Measurement

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
/// internal: called by compositorHookCallback via dispatchDebugEvent
internal func currentStackLevel(_ L: OpaquePointer) -> Int {
    var level: Int32 = 0
    var ar = lua_Debug()
    while lua_getstack(L, level, &ar) != 0 {
        level += 1
    }
    return Int(level)
}

// MARK: - Step Decision

/// Decide whether to pause based on the current step state and stack depth.
///
/// - Parameters:
///   - event: The raw Lua hook event (e.g. `LUA_HOOKLINE`).
///   - currentLevel: The live stack depth from ``currentStackLevel``.
///   - state: The current ``StepState``, or `nil` for breakpoint mode.
/// - Returns: `true` if the VM should pause and the handler should be called.
///
/// The `<`/`<=` comparisons handle tail calls: when `f` tail-calls `g` and
/// `g` returns, the depth drops from `from` (inside `g`) to `from - 1`
/// (inside `f`'s caller) — both `<` and `<=` fire correctly. A non-tail
/// call from `f` increases depth by 1; `<=` then keeps `stepOver` parked
/// until that callee returns and depth drops back to `from`.
///
/// internal: called by dispatchDebugEvent
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

// MARK: - Debug Event Dispatcher

/// Dispatch a debug event from inside the compositor hook.
///
/// Called by `compositorHookCallback` after the cancel/limit checks, only
/// when `engine.debugHandler != nil` and the event is LINE, CALL, or RET.
///
/// Responsibilities:
/// 1. Filter to LINE/CALL/RET events; ignore all others.
/// 2. For LINE: decide whether to pause (via `shouldPauseForStep`).
/// 3. For CALL/RET in step mode: skip (stepping is LINE-only).
/// 4. If pausing: build the event, create the inspector, set isPaused=true,
///    call the handler synchronously, invalidate the inspector, clear isPaused.
/// 5. Process the returned ``LuaDebugCommand``.
///
/// internal: called only from compositorHookCallback
internal func dispatchDebugEvent(
    _ L: OpaquePointer,
    ar: UnsafeMutablePointer<lua_Debug>,
    engine: LuaEngine
) {
    let rawEvent = ar.pointee.event

    // Classify the event — only LINE/CALL/RET are relevant for debug dispatch.
    let isLine = rawEvent == LUA_HOOKLINE
    let isCall = rawEvent == LUA_HOOKCALL
    #if LUA_VERSION_51
    let isTail = rawEvent == LUA_HOOKTAILRET
    #else
    let isTail = rawEvent == LUA_HOOKTAILCALL
    #endif
    let isRet  = rawEvent == LUA_HOOKRET

    guard isLine || isCall || isTail || isRet else { return }

    // Compute live stack depth for stepping decisions (and to set fromLevel).
    let currentLevel = currentStackLevel(L)

    if isLine {
        // LINE: apply step filter — may skip this event entirely.
        guard shouldPauseForStep(event: rawEvent, currentLevel: currentLevel,
                                 state: engine.stepState) else { return }
    } else {
        // CALL/RET: pause only in breakpoint mode (stepState == nil).
        // In step mode, stepping decisions are always LINE-based.
        guard engine.stepState == nil else { return }
    }

    // Populate the debug record with source/line/name info.
    guard lua_getinfo(L, "nSl", ar) != 0 else { return }

    let event = buildDebugEvent(ar: ar, isLine: isLine, isCall: isCall, isTail: isTail)
    processDebugPause(L: L, ar: ar, engine: engine, event: event, currentLevel: currentLevel)
}

// MARK: - dispatchDebugEvent private helpers

/// Build a LuaDebugEvent from the populated debug record.
private func buildDebugEvent(
    ar: UnsafeMutablePointer<lua_Debug>,
    isLine: Bool,
    isCall: Bool,
    isTail: Bool
) -> LuaDebugEvent {
    if isLine {
        return .line(Int(ar.pointee.currentline))
    } else if isCall || isTail {
        let source: String = withUnsafeBytes(of: ar.pointee.short_src) { rawBuf in
            guard let ptr = rawBuf.baseAddress?.assumingMemoryBound(to: CChar.self) else {
                return "?"
            }
            return String(cString: ptr)
        }
        let name: String? = ar.pointee.name.map { String(cString: $0) }
        let currentLine: Int? = ar.pointee.currentline >= 0 ? Int(ar.pointee.currentline) : nil
        let frame = LuaStackFrame(name: name, source: source, currentLine: currentLine, level: 0)
        return .call(frame)
    } else {
        return .ret
    }
}

/// Invoke the debug handler synchronously and process its command.
///
/// Sets isPaused=true, calls the handler, invalidates the inspector, clears
/// isPaused, then dispatches the returned LuaDebugCommand.
///
/// `.stop` reuses the F1 cancellation unwind: sets abortReason=1 and raises
/// lua_error with the cancelledSentinel. lua_error does not return (longjmp).
private func processDebugPause(
    L: OpaquePointer,
    ar: UnsafeMutablePointer<lua_Debug>,
    engine: LuaEngine,
    event: LuaDebugEvent,
    currentLevel: Int
) {
    // The engine lock is already held by the active run on this thread.
    // isPaused prevents any other thread from acquiring the lock while we
    // are inside the handler (they throw .enginePaused instead).
    engine.isPaused.store(true, ordering: .releasing)

    let inspector = DebugInspectorImpl(L: L)
    let command = engine.debugHandler!(event, inspector)
    inspector.invalidate()

    engine.isPaused.store(false, ordering: .releasing)

    // Apply the returned command.
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
        engine.abortReason.store(AbortReason.cancelled, ordering: .releasing)
        lua_pushstring(L, cancelledSentinel)
        _ = lua_error(L)
        // lua_error does not return (longjmp to pcall boundary).
    }
}
