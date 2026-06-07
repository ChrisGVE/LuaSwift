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
//  for Lua source strings, plus the instruction-count limit shared by
//  every execution entry point: armInstructionHook is called before each
//  protected call here and in LuaEngine+Bytecode.swift,
//  LuaEngine+FunctionCalls.swift, and LuaEngine+Coroutines.swift.
//  errorFromCode maps Lua status codes (and the instruction-limit
//  sentinel raised by the hook) to LuaError (LuaError.swift). Results
//  are converted via valueFromStack (LuaEngine+Bridging.swift).
//

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

    /// Arm (or disarm, when the limit is 0) the instruction-count hook on the
    /// given Lua state. Called before every protected call so the limit applies
    /// to every execution entry point, including coroutine threads. Centralized
    /// here so no entry point can silently omit it.
    /// internal: shared with the bytecode, function-call, and coroutine paths
    internal func armInstructionHook(on state: OpaquePointer) {
        if instructionLimit > 0 {
            lua_sethook(state, instructionHook, Int32(LUA_MASKCOUNT), Int32(instructionLimit))
        } else {
            lua_sethook(state, nil, 0, 0)
        }
    }

    // MARK: - Execution

    /// Execute Lua code without returning a result.
    ///
    /// Use this when you don't need the return value. Any return values
    /// from the Lua code are discarded.
    ///
    /// - Parameter code: The Lua code to execute
    /// - Throws: `LuaError` if execution fails
    public func run(_ code: String) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Clear any previous write error
        lastWriteError = nil

        // Load the code
        let loadResult = luaL_loadstring(L, code)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Arm instruction-count hook (or disarm if limit is 0)
        armInstructionHook(on: L)

        // Execute with nresults=0 (discard any return values)
        let callResult = lua_pcall(L, 0, 0, 0)
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

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
    /// - Throws: `LuaError` if execution fails
    public func evaluate(_ code: String) throws -> LuaValue {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Clear any previous write error
        lastWriteError = nil

        // Load the code
        let loadResult = luaL_loadstring(L, code)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Arm instruction-count hook (or disarm if limit is 0)
        armInstructionHook(on: L)

        // Execute with nresults=1 (expect one return value)
        let callResult = lua_pcall(L, 0, 1, 0)
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            // Check if this was a write error we generated
            if let writeError = lastWriteError {
                lastWriteError = nil
                throw writeError
            }

            throw errorFromCode(callResult, message: message)
        }

        // Convert result
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
    /// internal: shared with the bytecode and function-call paths
    internal func errorFromCode(_ code: Int32, message: String) -> LuaError {
        // The instruction-count hook raises a runtime error carrying this sentinel.
        if code == LUA_ERRRUN && message.contains(instructionLimitSentinel) {
            return .instructionLimitExceeded
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

// MARK: - Instruction Count Hook

/// Lua debug hook fired when the instruction count limit is reached.
///
/// Called by the Lua VM every N instructions (set via `lua_sethook` with
/// `LUA_MASKCOUNT`).  Raises a Lua runtime error that `pcall` catches and
/// surfaces as ``LuaError/instructionLimitExceeded``.
private func instructionHook(_ L: OpaquePointer?, _ ar: UnsafeMutablePointer<lua_Debug>?) -> Void {
    guard let L = L else { return }
    // Private sentinel (not a human-facing string) so detection cannot collide
    // with user Lua code calling `error("instruction limit exceeded")`.
    lua_pushstring(L, instructionLimitSentinel)
    _ = lua_error(L)
}

/// Internal marker raised by ``instructionHook`` and matched in ``errorFromCode``.
/// Deliberately unlikely to be produced by user Lua code.
/// internal: also matched by coroutine resume in LuaEngine+Coroutines.swift
internal let instructionLimitSentinel = "__luaswift_instruction_limit_exceeded__"
