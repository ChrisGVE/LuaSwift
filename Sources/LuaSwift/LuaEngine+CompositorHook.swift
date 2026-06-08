//
//  LuaEngine+CompositorHook.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+CompositorHook.swift
//
//  Context: The single periodic count hook multiplexed across cooperative
//  cancellation, the instruction-count limit, and debug-event dispatch.
//  Extracted from LuaEngine+Execution.swift (#20 delivery refactor) so that
//  the hook machinery lives apart from the source-execution concern.
//
//  Neighbors:
//    LuaEngine+Execution.swift   — run/evaluate; calls armCompositorHook
//    LuaEngine+Debug.swift       — armDebugHook; dispatchDebugEvent called here
//    LuaEngine.swift             — stored state (abortReason, cancellationRequested…)
//

import Atomics
import Foundation
import CLua

// MARK: - Abort Reason Constants (CR-108)

/// Named constants for the ``LuaEngine/abortReason`` atomic field.
///
/// Using named constants eliminates bare `0`/`1`/`2` literals across
/// +CompositorHook, +Execution, and +Coroutines and makes every comparison
/// self-documenting.
internal enum AbortReason {
    /// No abort in progress.
    static let none:                  UInt8 = 0
    /// Abort caused by ``LuaEngine/requestCancellation()``.
    static let cancelled:             UInt8 = 1
    /// Abort caused by exceeding ``LuaEngine/setInstructionLimit(_:)``.
    static let instructionLimitExceeded: UInt8 = 2
}

// MARK: - Sentinel Constants

/// Internal marker raised by the compositor hook for a cancel abort.
/// Deliberately unlikely to be produced by user Lua code. The out-of-band
/// ``LuaEngine/abortReason`` flag is the authoritative signal; this string
/// is a belt-and-suspenders fallback for ``errorFromCode``.
/// internal: matched by errorFromCode in LuaEngine+Execution.swift
internal let cancelledSentinel = "__luaswift_cancelled__"

/// Internal marker raised by the compositor hook when the instruction limit
/// is reached. Deliberately unlikely to be produced by user Lua code.
/// internal: also matched by coroutine resume in LuaEngine+Coroutines.swift
internal let instructionLimitSentinel = "__luaswift_instruction_limit_exceeded__"

// MARK: - Compositor Hook Callback

/// The single periodic count hook multiplexed across cooperative cancellation
/// and the instruction limit.
///
/// Fires every `armedHookCount` Lua VM instructions (set by ``armCompositorHook``
/// via `lua_sethook` with `LUA_MASKCOUNT`). On each fire, in order:
///
/// 1. Reads the atomic ``cancellationRequested`` flag. If set, stores reason=1 in
///    ``abortReason`` and raises `lua_error` with ``cancelledSentinel``.
/// 2. Accumulates `armedHookCount` into ``instructionAccumulator``. If
///    ``instructionLimit`` is nonzero and the accumulator has reached or exceeded
///    it, stores reason=2 and raises `lua_error` with ``instructionLimitSentinel``.
///
/// Engine recovery uses LuaSwift's existing TLS pattern
/// (``LuaEngine/currentEngine``) — `lua_sethook` provides no user-data slot, and
/// `lua_getextraspace` is absent on 5.1/5.2.
///
/// Abort is always `lua_error` (longjmp to the enclosing `pcall` boundary) — the
/// same proven mechanism as the old instruction hook. `lua_yield` is NOT used: it
/// cannot unwind through `pcall`, and 5.1 has no yieldable hooks.
internal func compositorHookCallback(
    _ L: OpaquePointer?,
    _ ar: UnsafeMutablePointer<lua_Debug>?
) {
    guard let L = L else { return }
    guard let engine = LuaEngine.currentEngine else { return }
    guard let ar = ar else { return }

    // Step 1: cooperative cancellation check (lock-free atomic read).
    // Check here first — even during a debug session, a cancel issued via
    // requestCancellation() while NOT paused must be honoured.
    if engine.cancellationRequested.load(ordering: .acquiring) {
        engine.abortReason.store(AbortReason.cancelled, ordering: .releasing)
        lua_pushstring(L, cancelledSentinel)
        _ = lua_error(L)
        return  // unreachable; lua_error does not return
    }

    // Step 2: instruction-limit accumulation (COUNT events only).
    // Only accumulate on COUNT fires to avoid inflating the count on
    // LINE/CALL/RET fires that the debug hook arms additionally.
    if ar.pointee.event == LUA_HOOKCOUNT {
        engine.instructionAccumulator += engine.armedHookCount
        if engine.instructionLimit > 0,
           engine.instructionAccumulator >= engine.instructionLimit {
            engine.abortReason.store(AbortReason.instructionLimitExceeded, ordering: .releasing)
            lua_pushstring(L, instructionLimitSentinel)
            _ = lua_error(L)
            return  // unreachable
        }
    }

    // Step 3: debug event dispatch (only when a handler is installed).
    // The branch is a nil-check so it compiles to a single conditional move
    // with no overhead when no handler is set (plain run/evaluate paths).
    if engine.debugHandler != nil {
        dispatchDebugEvent(L, ar: ar, engine: engine)
    }
}
