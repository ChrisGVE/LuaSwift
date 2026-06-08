//
//  LuaErrorHandler.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaErrorHandler.swift
//
//  Context: Structured runtime-error machinery (#19). Provides the
//  `lua_pcall` error handler and the Lua call-stack walker used to build
//  LuaRuntimeFailure values. Extracted from LuaHelpers.swift (which
//  retains only C-macro shims) so each file has a single concern.
//
//  ## How structured errors flow
//
//  Every `lua_pcall` call installs `runtimeErrorHandler` as the errfunc.
//  Lua invokes it with the error object on the stack while the failing Lua
//  stack is still intact. The handler:
//    1. Reads the raw error message (no metamethods).
//    2. Scans the stack for the first non-C frame to get the source line.
//    3. Builds a full traceback string (luaL_traceback on 5.2+; manual
//       walk on 5.1 which lacks the function).
//    4. Builds a structured frames array via walkLuaStack.
//    5. Stores a LuaRuntimeFailure in engine.pendingRuntimeFailure (via TLS).
//  After pcall returns, errorFromCode reads and clears the stash.
//
//  ## Pass-through rule
//
//  Cancellation and instruction-limit aborts use sentinel strings prefixed
//  with "__luaswift_". The handler detects these and the non-zero
//  engine.abortReason flag, then returns 1 unchanged so the sentinel
//  propagates to errorFromCode unmodified.
//
//  Neighbors:
//    LuaHelpers.swift          — C-macro shims (lua_pop, lua_tostring, …)
//    LuaEngine+Execution.swift — errorFromCode reads pendingRuntimeFailure
//    LuaEngine+Debug.swift     — inspector uses walkLuaStack for callStack
//    LuaEngine+TLS.swift       — currentEngine TLS key (engine recovery)
//

import Foundation
import CLua

// MARK: - Stack Walker

/// Walk the Lua call stack and return structured frame info.
///
/// Scans upward from `startLevel` calling `lua_getstack`/`lua_getinfo("Sln")`.
/// Stops when `lua_getstack` returns 0 (no more frames).
///
/// - Parameters:
///   - L: The Lua state to inspect.
///   - startLevel: The first level to examine (0 = innermost).
/// - Returns: Array of `LuaStackFrame` values, innermost first.
///
/// internal: shared by runtimeErrorHandler and DebugInspectorImpl.callStack
internal func walkLuaStack(_ L: OpaquePointer, startLevel: Int = 0) -> [LuaStackFrame] {
    var frames: [LuaStackFrame] = []
    var level = startLevel
    while true {
        var ar = lua_Debug()
        guard lua_getstack(L, Int32(level), &ar) != 0 else { break }
        // "S" = source/what/short_src  "l" = currentline  "n" = name/namewhat
        guard lua_getinfo(L, "Sln", &ar) != 0 else { break }

        let source: String = withUnsafeBytes(of: ar.short_src) { rawBuf in
            // short_src is a fixed-length C char array — read until the first NUL.
            guard let ptr = rawBuf.baseAddress?.assumingMemoryBound(to: CChar.self) else {
                return "?"
            }
            return String(cString: ptr)
        }

        let name: String? = ar.name.map { String(cString: $0) }
        let currentLine: Int? = (ar.currentline >= 0) ? Int(ar.currentline) : nil

        frames.append(LuaStackFrame(
            name: name,
            source: source,
            currentLine: currentLine,
            level: level - startLevel
        ))
        level += 1
    }
    return frames
}

// MARK: - Traceback Builder

/// Build a traceback string from the Lua call stack.
///
/// On Lua 5.2+ delegates to `luaL_traceback` (the standard implementation).
/// On Lua 5.1, which lacks `luaL_traceback`, performs a manual
/// `lua_getstack`/`lua_getinfo` walk and formats each frame in the same
/// `"chunk:line: in function 'name'"` style that `luaL_traceback` produces.
/// The result is always non-nil and non-empty (at minimum `"stack traceback:"`).
///
/// - Parameters:
///   - L: The Lua state to inspect.
///   - message: Optional message to prepend (mirrors the `msg` arg of `luaL_traceback`).
/// - Returns: The traceback string.
///
/// internal: called by runtimeErrorHandler
internal func buildTraceback(_ L: OpaquePointer, message: String?) -> String {
    #if LUA_VERSION_51
    return buildTracebackManual(L, message: message)
    #else
    return buildTracebackNative(L, message: message)
    #endif
}

/// Manual traceback walk for Lua 5.1 (luaL_traceback does not exist).
private func buildTracebackManual(_ L: OpaquePointer, message: String?) -> String {
    var parts: [String] = []
    if let msg = message { parts.append(msg) }
    parts.append("stack traceback:")
    var level = 1  // start at 1 to skip the C error builtin at 0
    while true {
        var ar = lua_Debug()
        guard lua_getstack(L, Int32(level), &ar) != 0 else { break }
        guard lua_getinfo(L, "Sln", &ar) != 0 else { break }

        let src: String = withUnsafeBytes(of: ar.short_src) { rawBuf in
            guard let ptr = rawBuf.baseAddress?.assumingMemoryBound(to: CChar.self) else {
                return "?"
            }
            return String(cString: ptr)
        }

        let lineStr = ar.currentline >= 0 ? "\(ar.currentline)" : "?"
        let nameStr: String
        if let n = ar.name.map({ String(cString: $0) }), !n.isEmpty {
            nameStr = "in function '\(n)'"
        } else {
            let whatStr = ar.what.map({ String(cString: $0) }) ?? "?"
            nameStr = whatStr == "main" ? "in main chunk" : "in ?"
        }
        parts.append("\t\(src):\(lineStr): \(nameStr)")
        level += 1
    }
    return parts.joined(separator: "\n")
}

/// Native traceback via luaL_traceback for Lua 5.2+.
private func buildTracebackNative(_ L: OpaquePointer, message: String?) -> String {
    // luaL_traceback(L, L1, msg, level) pushes a traceback string onto L.
    // L1 == L means we trace the same state. level=1 skips the error-handler
    // frame itself (same convention as the Lua standard library).
    let topBefore = lua_gettop(L)
    if let msg = message {
        msg.withCString { cStr in
            luaL_traceback(L, L, cStr, 1)
        }
    } else {
        luaL_traceback(L, L, nil, 1)
    }
    // The traceback string is now on top of the stack; capture and clean up.
    let result = lua_tostring(L, -1).map { String(cString: $0) } ?? "stack traceback: (unavailable)"
    lua_settop(L, topBefore)
    return result
}

// MARK: - Runtime Error Handler

/// The `lua_pcall` error handler for structured runtime errors (#19).
///
/// A free function (no captures) installed as the `errfunc` argument to every
/// `lua_pcall` call. Lua invokes it with the error object at stack index 1
/// **while the failing stack is still intact** — before `lua_pcall` unwinds it.
///
/// ## Pass-through rule (sentinel/abort)
///
/// If the engine's `abortReason` flag is non-zero (cancel or limit set by the
/// compositor hook), the handler returns immediately leaving the error object
/// unchanged (return 1). Belt-and-suspenders: also bail if the error string
/// carries a `__luaswift_` prefix.
///
/// ## Non-string error objects
///
/// Emits a typed placeholder `"<error: typename>"` via `lua_typename` ONLY.
/// Must **not** call `__tostring` or `luaL_tolstring` — doing so from inside
/// an error handler risks `LUA_ERRERR` and can re-enter the error path.
///
/// ## Line number
///
/// Scans upward from level 1 for the first frame whose `what != "C"`.
/// See ``extractErrorLocation`` for details.
///
/// ## Swift stash
///
/// Stores the result in `engine.pendingRuntimeFailure` via TLS, then returns
/// 1 leaving the error object unchanged. After `lua_pcall` returns,
/// `errorFromCode` reads and clears the stash.
///
/// internal: installed as errfunc in every lua_pcall call site
internal func runtimeErrorHandler(
    _ L: OpaquePointer?
) -> Int32 {
    guard let L = L else { return 1 }

    // Recover the owning engine via TLS (installed by setAsCurrentEngine()).
    guard let engine = LuaEngine.currentEngine else { return 1 }

    // SENTINEL PASS-THROUGH: compositor hook set abort reason — do not wrap.
    let abortReason = engine.abortReason.load(ordering: .relaxed)
    if abortReason != AbortReason.none { return 1 }

    // Belt-and-suspenders: sentinel string — pass through untouched.
    if lua_type(L, 1) == LUA_TSTRING,
       let cStr = lua_tostring(L, 1) {
        if String(cString: cStr).hasPrefix("__luaswift_") { return 1 }
    }

    let rawMessage = extractRawMessage(L)
    let (foundLine, foundShortSrc) = extractErrorLocation(L)
    let traceback = buildTraceback(L, message: nil)
    let frames = walkLuaStack(L, startLevel: 0)
    let strippedMessage = stripLocationPrefix(rawMessage, line: foundLine, source: foundShortSrc)

    engine.pendingRuntimeFailure = LuaRuntimeFailure(
        message: strippedMessage,
        rawMessage: rawMessage,
        line: foundLine,
        traceback: traceback,
        frames: frames.isEmpty ? nil : frames
    )

    return 1  // return error object unchanged so lua_pcall propagates it
}

// MARK: - runtimeErrorHandler private helpers

/// Read the error object at stack index 1 as a plain string, without
/// invoking any metamethods. Non-string objects produce a typed placeholder.
private func extractRawMessage(_ L: OpaquePointer) -> String {
    if lua_type(L, 1) == LUA_TSTRING {
        return lua_tostring(L, 1).map { String(cString: $0) } ?? "<error: string>"
    }
    // Non-string error object — type placeholder only, no __tostring call.
    let typeName = lua_typename(L, lua_type(L, 1)).map { String(cString: $0) } ?? "userdata"
    return "<error: \(typeName)>"
}

/// Scan the Lua stack upward from level 1 to find the first non-C frame.
///
/// For an explicit `error()` call, level 1 is the C `error` builtin
/// (currentline == -1) and the Lua caller is at level 2. For a VM-internal
/// error (e.g. `nil + 1`), the Lua frame is already at level 1. Both cases
/// produce the correct source line.
///
/// - Returns: `(line, shortSrc)` — `line` is nil when no Lua frame is found.
private func extractErrorLocation(_ L: OpaquePointer) -> (Int?, String) {
    var foundLine: Int? = nil
    var foundShortSrc: String = ""
    var scanLevel: Int32 = 1
    while true {
        var ar = lua_Debug()
        guard lua_getstack(L, scanLevel, &ar) != 0 else { break }
        guard lua_getinfo(L, "Sl", &ar) != 0 else { break }

        let what = ar.what.map { String(cString: $0) } ?? "C"
        if what != "C" {
            if ar.currentline >= 0 {
                foundLine = Int(ar.currentline)
            }
            foundShortSrc = withUnsafeBytes(of: ar.short_src) { rawBuf in
                guard let ptr = rawBuf.baseAddress?.assumingMemoryBound(to: CChar.self) else {
                    return ""
                }
                return String(cString: ptr)
            }
            break
        }
        scanLevel += 1
    }
    return (foundLine, foundShortSrc)
}

/// Strip the exact `"shortSrc:line: "` prefix from `message` if present.
///
/// Exact-prefix matching (not regex) is required because chunk names may
/// contain colons (e.g. `"config.yaml:$.scripts.init:3: msg"`), making
/// regex unreliable.
private func stripLocationPrefix(_ message: String, line: Int?, source: String) -> String {
    guard let line = line, !source.isEmpty else { return message }
    let prefix = "\(source):\(line): "
    return message.hasPrefix(prefix) ? String(message.dropFirst(prefix.count)) : message
}
