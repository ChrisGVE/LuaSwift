//
//  LuaEngine+Execution.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Execution.swift
//
//  Context: Source-execution concern of LuaEngine — run(_:)/evaluate(_:)
//  for Lua source strings. The periodic compositor hook (armCompositorHook)
//  is the single lua_sethook slot shared by cooperative cancellation (#22)
//  and the instruction-count limit. It is called before every protected
//  call here and in LuaEngine+Bytecode.swift, LuaEngine+FunctionCalls.swift,
//  and LuaEngine+Coroutines.swift. errorFromCode reads the out-of-band
//  abortReason flag first (before string matching) so cancel/limit are
//  detected correctly even when a future errfunc (#19) reshapes the message.
//  Results are converted via valueFromStack (LuaEngine+Bridging.swift).
//

import Atomics
import Foundation
import CLua

extension LuaEngine {

    // MARK: - Instruction Limit

    /// Set the maximum number of Lua VM instructions per `run`/`evaluate` call.
    ///
    /// When the running chunk executes more than `count` instructions, a
    /// ``LuaError/instructionLimitExceeded`` error is thrown.  This provides a
    /// deterministic way to abort runaway Lua code (e.g. infinite loops) without
    /// relying on OS-level timeouts or threads.
    ///
    /// The limit is re-applied before every `pcall`, so it applies equally to
    /// each individual `run` and `evaluate` invocation.
    ///
    /// The limit is enforced on every execution entry point — `run`, `evaluate`
    /// (both the source and `CompiledChunk` overloads), the deprecated
    /// `runBytecode`/`evaluateBytecode`, `callLuaFunction`, and coroutine `resume`.
    ///
    /// - Note: The count is **per call**, not a lifetime budget. For coroutines the
    ///   count is reset to the full limit on every `resume`, so a coroutine that
    ///   yields can execute up to `count` instructions between each resume. Do not
    ///   treat the limit as a total instruction ceiling for adversarial code that can
    ///   call `coroutine.yield()`; if you need a hard sandbox, also restrict or remove
    ///   the `coroutine` library.
    ///
    /// - Important: The instruction limit is a **CPU-bound control only**. The
    ///   count hook fires between VM instructions, so a *single* instruction
    ///   that calls a C function — `string.rep('A', 1e9)`, pathological
    ///   `string.find`/`string.gsub` patterns, long-running Swift callbacks —
    ///   runs to completion uninterrupted and is free to allocate unbounded
    ///   memory. Pair the instruction limit with
    ///   ``LuaEngineConfiguration/vmMemoryLimit`` to also bound Lua VM memory.
    ///
    /// - Parameter count: Maximum instruction count per call. Pass `0` to disable
    ///   the hook entirely (the default). Negative values are treated as `0`.
    ///   Values above `Int32.max` are clamped to `Int32.max` (the hook count is a
    ///   C `int`), avoiding a runtime overflow trap.
    public func setInstructionLimit(_ count: Int) {
        lock.lock()
        defer { lock.unlock() }
        instructionLimit = max(0, min(count, Int(Int32.max)))
    }

    /// Arm the periodic compositor hook on the given Lua state.
    ///
    /// The compositor fires every `min(hookInterval, instructionLimit)` instructions
    /// (or every `hookInterval` when no limit is set). On each fire it checks the
    /// cancellation flag first, then the instruction accumulator against the limit.
    /// Using `min` prevents overshooting a limit that is smaller than `hookInterval`.
    ///
    /// Must be called at the start of every run entry point so cancellation and
    /// the instruction limit apply to source execution, bytecode execution,
    /// stored-function calls, and coroutine resumes alike.
    ///
    /// **TLS side-effect:** Installs this engine as the TLS current engine
    /// (``setAsCurrentEngine()``) so the C compositor callback can recover it
    /// without a global map. Callers must pair this with a restore on exit.
    ///
    /// internal: shared with +Bytecode, +FunctionCalls, +Coroutines
    internal func armCompositorHook(on state: OpaquePointer) {
        // Arm count: use min(hookInterval, limit) when a limit is active so the
        // first fire cannot overshoot a limit smaller than hookInterval.
        // Store the armed count so the hook can accumulate exactly that many
        // instructions per fire regardless of which branch was taken.
        let count: Int32
        if instructionLimit > 0 {
            count = Int32(min(hookInterval, instructionLimit))
        } else {
            count = Int32(hookInterval)
        }
        armedHookCount = Int(count)
        lua_sethook(state, compositorHookCallback, Int32(LUA_MASKCOUNT), count)
    }

    // MARK: - Execution

    /// Execute Lua code without returning a result.
    ///
    /// Use this when you don't need the return value. Any return values
    /// from the Lua code are discarded.
    ///
    /// - Parameter code: The Lua code to execute
    /// - Throws: `LuaError` if execution fails, ``LuaError/cancelled`` if
    ///   ``requestCancellation()`` was called from another thread during execution
    public func run(_ code: String) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Reset per-run state. abortReason and accumulator must be clean so a
        // stale value from a prior cancelled/limit run does not fire spuriously.
        abortReason.store(0, ordering: .releasing)
        instructionAccumulator = 0

        // Clear any previous write error
        lastWriteError = nil

        // Load the code
        let loadResult = luaL_loadstring(L, code)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Arm the compositor hook and install TLS so the C callback can find us.
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armCompositorHook(on: L)

        // Execute with nresults=0 (discard any return values)
        let callResult = lua_pcall(L, 0, 0, 0)
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            #if DEBUG
            // After an abort the stack must be back at the pcall base (0 args,
            // 0 results requested). A non-zero top here means a stack leak.
            assert(lua_gettop(L) == 0, "Stack not clean after pcall abort: top=\(lua_gettop(L))")
            #endif

            // Check if this was a write error we generated
            if let writeError = lastWriteError {
                lastWriteError = nil
                throw writeError
            }

            throw errorFromCode(callResult, message: message)
        }
    }

    /// Execute Lua code and return the result.
    ///
    /// - Parameter code: The Lua code to execute
    /// - Returns: The result of the execution as a `LuaValue`
    /// - Throws: `LuaError` if execution fails, ``LuaError/cancelled`` if
    ///   ``requestCancellation()`` was called from another thread during execution
    public func evaluate(_ code: String) throws -> LuaValue {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Reset per-run state (same reasoning as run(_:) above)
        abortReason.store(0, ordering: .releasing)
        instructionAccumulator = 0

        // Clear any previous write error
        lastWriteError = nil

        // Load the code
        let loadResult = luaL_loadstring(L, code)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Arm the compositor hook and install TLS
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armCompositorHook(on: L)

        // Execute with nresults=1 (expect one return value)
        let callResult = lua_pcall(L, 0, 1, 0)
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            #if DEBUG
            assert(lua_gettop(L) == 0, "Stack not clean after pcall abort: top=\(lua_gettop(L))")
            #endif

            // Check if this was a write error we generated
            if let writeError = lastWriteError {
                lastWriteError = nil
                throw writeError
            }

            throw errorFromCode(callResult, message: message)
        }

        // Convert result and pop it
        let result = valueFromStack(at: -1)
        lua_pop(L, 1)
        return result
    }

    // MARK: - Random Seeding

    /// Set the random seed for math.random().
    ///
    /// Use a fixed seed for reproducible tests.
    ///
    /// - Parameter seed: The seed value
    public func seed(_ seed: Int) throws {
        try run("math.randomseed(\(seed))")
    }

    // MARK: - Error Classification

    /// Map a Lua status code (and error message) to the matching ``LuaError``.
    ///
    /// Checks the out-of-band ``abortReason`` atomic flag FIRST so cancel/limit
    /// are detected correctly even when a future errfunc (#19) reshapes the
    /// error message before `pcall` returns. Falls back to string-sentinel
    /// matching for the current (no-errfunc) case as a belt-and-suspenders.
    ///
    /// internal: shared with the bytecode and function-call paths
    internal func errorFromCode(_ code: Int32, message: String) -> LuaError {
        // Out-of-band reason set by the compositor hook — authoritative.
        let reason = abortReason.load(ordering: .acquiring)
        if reason == 1 { return .cancelled }
        if reason == 2 { return .instructionLimitExceeded }

        // Belt-and-suspenders: string sentinel still matches in case the hook
        // fires but the atomic write races the pcall return on very old hardware.
        if code == LUA_ERRRUN && message.contains(instructionLimitSentinel) {
            return .instructionLimitExceeded
        }
        if code == LUA_ERRRUN && message.contains(cancelledSentinel) {
            return .cancelled
        }
        // Lua 5.3's luaL_Buffer reports an allocation failure (e.g. a denial
        // by the vmMemoryLimit allocator during string.rep) as a *runtime*
        // error with this exact lauxlib.c message instead of LUA_ERRMEM.
        // Normalize it so memory exhaustion is .memoryError on every version.
        if code == LUA_ERRRUN && message.contains("not enough memory for buffer allocation") {
            return .memoryError(message)
        }
        switch code {
        case LUA_ERRSYNTAX:
            return .syntaxError(message)
        case LUA_ERRRUN:
            return .runtimeError(message)
        case LUA_ERRMEM:
            return .memoryError(message)
        case LUA_ERRERR:
            return .errorHandlerError(message)
        default:
            return .unknown(code: Int(code), message: message)
        }
    }
}

// MARK: - Compositor Hook

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
private func compositorHookCallback(
    _ L: OpaquePointer?,
    _ ar: UnsafeMutablePointer<lua_Debug>?
) {
    guard let L = L else { return }
    guard let engine = LuaEngine.currentEngine else { return }

    // Step 1: cooperative cancellation check (lock-free atomic read).
    if engine.cancellationRequested.load(ordering: .acquiring) {
        engine.abortReason.store(1, ordering: .releasing)
        lua_pushstring(L, cancelledSentinel)
        _ = lua_error(L)
        return  // unreachable; lua_error does not return
    }

    // Step 2: instruction-limit accumulation.
    // Accumulate by the actually-armed count (not always hookInterval) so the
    // first fire does not count more than was armed when limit < hookInterval.
    engine.instructionAccumulator += engine.armedHookCount
    if engine.instructionLimit > 0,
       engine.instructionAccumulator >= engine.instructionLimit {
        engine.abortReason.store(2, ordering: .releasing)
        lua_pushstring(L, instructionLimitSentinel)
        _ = lua_error(L)
    }
}

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
