//
//  LuaError.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaError.swift
//
//  Context: Error taxonomy for LuaEngine. Every execution entry point
//  (LuaEngine+Execution.swift, +Bytecode.swift, +FunctionCalls.swift,
//  +Coroutines.swift) maps Lua status codes to these cases via
//  errorFromCode. The .cancelled case is set out-of-band via an atomic
//  abortReason flag (LuaEngine.swift) so an errfunc (F2/#19) cannot
//  repackage the sentinel as a runtime error. The .runtimeFailure case
//  carries a LuaRuntimeFailure captured by the errfunc message handler
//  installed on every lua_pcall path (#19).
//

import Foundation

// MARK: - Structured Error Types (#19)

/// A single frame in a Lua call stack.
///
/// Produced by the errfunc message handler installed on every `lua_pcall` path.
/// The handler walks `lua_getstack`/`lua_getinfo` while the failing stack is
/// still intact — by the time `lua_pcall` returns the stack is unwound.
///
/// - `level` 0 is the innermost (most-recent) frame; higher levels are outer callers.
/// - `source` uses the chunk name from `Proto.source`, which reflects the `chunkName`
///   supplied to `run`/`evaluate`/`precompile`/`createCoroutine` (#23).
/// - `currentLine` is `nil` when Lua reports `currentline == -1` (C frames,
///   tail calls, or chunks whose debug info was stripped).
public struct LuaStackFrame: Sendable, Equatable {
    /// Function name if known (`nil` for anonymous functions and the main chunk).
    public let name: String?
    /// Chunk source identifier (from `Proto.source`, reflects `#23` chunk names).
    public let source: String
    /// Current line within the source chunk, or `nil` for C/tail/stripped frames.
    public let currentLine: Int?
    /// Stack level: 0 = innermost frame, increasing toward outer callers.
    public let level: Int
}

/// Structured runtime error payload captured by the `lua_pcall` error handler.
///
/// Delivered exclusively wrapped in ``LuaError/runtimeFailure(_:)`` — it is
/// **not** `: Error` itself, so it cannot be thrown standalone and cannot slip
/// a `catch … as LuaError` guard in callers.
///
/// ## Field contract
///
/// - `message`: the Lua error string with the `chunkname:line:` prefix stripped.
///   MoonSwift renders location information itself and expects the bare message.
/// - `rawMessage`: the original string with the prefix intact (fallback).
/// - `line`: 1-based source line in the raising chunk. Read from the **first
///   frame whose `lua_getinfo("S")` `what != "C"`**, scanning upward from
///   level 1. This yields the correct line for both an explicit `error()` call
///   (level 1 is the C builtin; the Lua caller is at level 2) and a VM-internal
///   error such as `nil + 1` (the Lua frame is already at level 1). `nil` when
///   no Lua frame exists — e.g. an error raised inside a registered Swift
///   function, or `error(msg, 0)`.
/// - `traceback`: full traceback string, newest frame first, non-nil on all
///   versions. On Lua 5.2+ this is produced by `luaL_traceback`; on 5.1 (which
///   lacks `luaL_traceback`) a manual `lua_getstack`/`lua_getinfo` walk is used.
/// - `frames`: structured frames from the same walk used to build `traceback`.
///   `nil` only when the stack walk is empty (no Lua frames active).
///
/// ## Non-string errors
///
/// When the Lua program calls `error(obj)` with a non-string object, the
/// handler emits a typed placeholder such as `"<error: table>"` using
/// `lua_typename` **without** calling `__tostring` or any other metamethod.
/// Invoking a metamethod from inside an error handler risks `LUA_ERRERR`
/// (handler error), can blow the cancellation instruction budget, or re-enter
/// the error path.
///
/// ## Sentinel pass-through
///
/// Cancel and instruction-limit raises (``LuaError/cancelled``,
/// ``LuaError/instructionLimitExceeded``) are detected via the out-of-band
/// ``LuaEngine/abortReason`` atomic before `pendingRuntimeFailure` is
/// consulted, so they are never wrapped in `runtimeFailure`.
public struct LuaRuntimeFailure: Sendable, Equatable {
    /// Lua error message with `chunkname:line:` prefix stripped.
    public let message: String
    /// Original Lua error message with the prefix intact.
    public let rawMessage: String
    /// 1-based source line in the raising chunk, or `nil` for C-level errors.
    public let line: Int?
    /// Full traceback string, newest frame first. Non-nil on all Lua versions.
    public let traceback: String
    /// Structured stack frames from the same walk used to build `traceback`.
    /// `nil` only when no Lua frames were active at error time.
    public let frames: [LuaStackFrame]?
}

// MARK: - LuaError

/// Errors that can occur during Lua execution.
public enum LuaError: Error, LocalizedError {
    /// Failed to create the Lua state
    case initializationFailed

    /// Lua syntax error during parsing
    case syntaxError(String)

    /// Runtime error during execution
    case runtimeError(String)

    /// Memory allocation error
    case memoryError(String)

    /// Error in error handler
    case errorHandlerError(String)

    /// Type conversion error
    case typeError(expected: String, actual: String)

    /// Value server path resolution error
    case pathResolutionError(path: String)

    /// Attempted to use a prohibited function
    case prohibitedFunction(name: String)

    /// Attempted to write to a read-only path
    case readOnlyAccess(path: String)

    /// Error occurred in Swift callback
    case callbackError(String)

    /// Error related to coroutine operations
    case coroutineError(String)

    /// Instruction count limit exceeded — possible infinite loop
    case instructionLimitExceeded

    /// Execution aborted by ``LuaEngine/requestCancellation()``.
    ///
    /// The engine is safe to reuse after calling ``LuaEngine/resetCancellation()``.
    case cancelled

    /// Structured runtime error with parsed location, stripped message, and traceback.
    ///
    /// Produced when the `lua_pcall` error handler successfully captures and
    /// parses the error. See ``LuaRuntimeFailure`` for the full field contract.
    ///
    /// The existing ``runtimeError(_:)`` case is preserved for source
    /// compatibility (MoonSwift matches it) and is used when no structured data
    /// is available (e.g. the handler was not installed or returned unexpectedly).
    case runtimeFailure(LuaRuntimeFailure)

    /// Sandbox installation failed — a dangerous global may still be live
    case sandboxInstallationFailed(String)

    /// A Lua table could not be converted to a ``LuaValue`` because it contains
    /// a reference cycle (a table reachable from itself).
    ///
    /// Ordinary table materialization (`run`/`evaluate` results, callback
    /// arguments, coroutine yields, introspection) walks the table graph
    /// recursively. A cyclic table — e.g. `t = {}; t.self = t` — would recurse
    /// until the Swift stack is exhausted, so the walk tracks visited tables by
    /// identity (`lua_topointer`) and raises this error on the back-edge instead
    /// of crashing. The debug inspector uses the same cycle-detection model.
    case cyclicTable

    /// A numeric Lua table key was not representable as a Swift `Int` and was
    /// therefore rejected during conversion.
    ///
    /// Lua numeric keys are double-precision. Keys that are fractional, NaN,
    /// infinite, or outside the `Int` range cannot be losslessly represented and
    /// previously either truncated silently or trapped. Conversion now validates
    /// with `Int(exactly:)` and raises this error instead. Use string keys in
    /// Lua (e.g. `t["1.5"] = v`) when a non-integer numeric key is intended.
    case numericKeyOutOfRange(Double)

    /// Attempted to call a state-touching method while the engine is paused
    /// at a debug hook event.
    ///
    /// While a ``LuaDebugHandler`` callback is executing, the VM thread holds
    /// the Lua state mid-execution and the engine's `NSRecursiveLock` is held.
    /// Any public method that would call back into the same `lua_State` would
    /// produce C-level undefined behavior. LuaSwift fences this off with a
    /// `ManagedAtomic<Bool>` `isPaused` flag: every state-touching public
    /// method checks the flag **before** acquiring the lock and throws this
    /// error when `isPaused` is `true`.
    ///
    /// The ``LuaDebugInspector`` provided to the handler is the ONLY
    /// sanctioned interaction with engine state while paused.
    case enginePaused

    /// Unknown error
    case unknown(code: Int, message: String?)

    public var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize Lua state"
        case .syntaxError(let message):
            return "Lua syntax error: \(message)"
        case .runtimeError(let message):
            return "Lua runtime error: \(message)"
        case .memoryError(let message):
            return "Lua memory error: \(message)"
        case .errorHandlerError(let message):
            return "Lua error handler error: \(message)"
        case .typeError(let expected, let actual):
            return "Type error: expected \(expected), got \(actual)"
        case .pathResolutionError(let path):
            return "Failed to resolve path: \(path)"
        case .prohibitedFunction(let name):
            return "Attempted to use prohibited function: \(name)"
        case .readOnlyAccess(let path):
            return "Attempted to write to read-only path: \(path)"
        case .callbackError(let message):
            return "Swift callback error: \(message)"
        case .coroutineError(let message):
            return "Lua coroutine error: \(message)"
        case .instructionLimitExceeded:
            return "Instruction limit exceeded (possible infinite loop)"
        case .cancelled:
            return "Execution cancelled by requestCancellation()"
        case .runtimeFailure(let failure):
            if let line = failure.line {
                return "Lua runtime error at line \(line): \(failure.message)"
            }
            return "Lua runtime error: \(failure.message)"
        case .sandboxInstallationFailed(let message):
            return "Sandbox installation failed: \(message)"
        case .cyclicTable:
            return "Cyclic Lua table cannot be converted to a LuaValue"
        case .numericKeyOutOfRange(let key):
            return "Lua numeric table key \(key) is not representable as an Int"
        case .enginePaused:
            return "Cannot call LuaEngine methods while a debug handler is executing; use the inspector instead"
        case .unknown(let code, let message):
            if let message = message {
                return "Lua error (code \(code)): \(message)"
            }
            return "Unknown Lua error (code \(code))"
        }
    }
}
