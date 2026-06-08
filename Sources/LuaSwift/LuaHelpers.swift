//
//  LuaHelpers.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Swift wrappers for Lua C macros that cannot be imported directly.
//

import Foundation
import CLua

// MARK: - Constants

/// Maximum stack size (from luaconf.h LUAI_MAXSTACK)
/// Lua 5.1: 8000, Lua 5.2-5.4: 1,000,000, Lua 5.5: INT_MAX/2
#if LUA_VERSION_55
let LUAI_MAXSTACK: Int32 = Int32.max / 2
#elseif LUA_VERSION_51
let LUAI_MAXSTACK: Int32 = 8000
#else
let LUAI_MAXSTACK: Int32 = 1_000_000
#endif

/// Pseudo-index for the registry (replaces LUA_REGISTRYINDEX macro)
/// Lua 5.1: -10000 (fixed), Lua 5.2-5.4: -LUAI_MAXSTACK - 1000, Lua 5.5: -(INT_MAX/2 + 1000)
#if LUA_VERSION_55
let LUA_REGISTRYINDEX: Int32 = -(Int32.max / 2 + 1000)
#elseif LUA_VERSION_51
let LUA_REGISTRYINDEX: Int32 = -10000
#else
let LUA_REGISTRYINDEX: Int32 = -LUAI_MAXSTACK - 1000
#endif

/// Global table pseudo-index (Lua 5.1 only)
#if LUA_VERSION_51
let LUA_GLOBALSINDEX: Int32 = -10002
#endif

/// Registry index for globals table (Lua 5.2+)
#if !LUA_VERSION_51
let LUA_RIDX_GLOBALS: lua_Integer = 2
#endif

// MARK: - Lua 5.1/5.2 Compatibility Shims

#if LUA_VERSION_51
/// LUA_OK doesn't exist in Lua 5.1 (success = 0)
let LUA_OK: Int32 = 0
#endif

#if LUA_VERSION_51
/// Shim for lua_tonumberx (Lua 5.1 doesn't have the extended version)
@inline(__always)
func lua_tonumberx(_ L: OpaquePointer?, _ index: Int32, _ isnum: UnsafeMutablePointer<Int32>?) -> lua_Number {
    let t = lua_type(L, index)
    if let isnum = isnum {
        isnum.pointee = (t == LUA_TNUMBER) ? 1 : 0
    }
    return CLua.lua_tonumber(L, index)
}

/// Shim for lua_tointegerx (Lua 5.1 doesn't have the extended version)
@inline(__always)
func lua_tointegerx(_ L: OpaquePointer?, _ index: Int32, _ isnum: UnsafeMutablePointer<Int32>?) -> lua_Integer {
    let t = lua_type(L, index)
    if let isnum = isnum {
        isnum.pointee = (t == LUA_TNUMBER) ? 1 : 0
    }
    return CLua.lua_tointeger(L, index)
}

/// Shim for lua_rawlen (Lua 5.1 uses lua_objlen)
@inline(__always)
func lua_rawlen(_ L: OpaquePointer?, _ index: Int32) -> Int {
    return Int(lua_objlen(L, index))
}

/// Shim for lua_pcallk (Lua 5.1 doesn't support continuations)
@inline(__always)
func lua_pcallk(_ L: OpaquePointer?, _ nargs: Int32, _ nresults: Int32, _ errfunc: Int32, _ ctx: lua_KContext, _ k: lua_KFunction?) -> Int32 {
    // Ignore continuation parameters - Lua 5.1 doesn't support them
    return CLua.lua_pcall(L, nargs, nresults, errfunc)
}

/// Shim for lua_callk (Lua 5.1 doesn't support continuations)
@inline(__always)
func lua_callk(_ L: OpaquePointer?, _ nargs: Int32, _ nresults: Int32, _ ctx: lua_KContext, _ k: lua_KFunction?) {
    // Ignore continuation parameters - Lua 5.1 doesn't support them
    CLua.lua_call(L, nargs, nresults)
}

/// Type aliases for continuation support (not used in 5.1 but needed for compilation)
typealias lua_KContext = Int
typealias lua_KFunction = @convention(c) (OpaquePointer?, Int32, lua_KContext) -> Int32

/// Shim for lua_copy (Lua 5.1 doesn't have this)
@inline(__always)
func lua_copy(_ L: OpaquePointer?, _ fromidx: Int32, _ toidx: Int32) {
    let absTo = toidx > 0 ? toidx : lua_gettop(L) + toidx + 1
    lua_pushvalue(L, fromidx)
    lua_replace_51(L, absTo)
}

/// Internal lua_replace for 5.1 (without lua_copy dependency)
@inline(__always)
private func lua_replace_51(_ L: OpaquePointer?, _ index: Int32) {
    CLua.lua_replace(L, index)
}

/// Shim for lua_setglobal (macro in Lua 5.1)
@inline(__always)
func lua_setglobal(_ L: OpaquePointer?, _ name: String) {
    lua_setfield(L, LUA_GLOBALSINDEX, name)
}

/// Shim for lua_getglobal (macro in Lua 5.1)
@inline(__always)
func lua_getglobal(_ L: OpaquePointer?, _ name: String) {
    lua_getfield(L, LUA_GLOBALSINDEX, name)
}

/// Shim for lua_rawseti (uses Int32 index in 5.1, lua_Integer in 5.2+)
@inline(__always)
func lua_rawseti(_ L: OpaquePointer?, _ idx: Int32, _ n: lua_Integer) {
    CLua.lua_rawseti(L, idx, Int32(n))
}

/// Shim for lua_rawgeti (uses Int32 index in 5.1, lua_Integer in 5.2+)
@inline(__always)
func lua_rawgeti(_ L: OpaquePointer?, _ idx: Int32, _ n: lua_Integer) -> Int32 {
    CLua.lua_rawgeti(L, idx, Int32(n))
    return lua_type(L, -1)  // 5.1 doesn't return type, compute it
}

/// Shim for lua_resume (5.1 signature: (L, narg), 5.4+ signature: (L, from, narg, nres))
@inline(__always)
func lua_resume(_ L: OpaquePointer?, _ from: OpaquePointer?, _ narg: Int32, _ nres: UnsafeMutablePointer<Int32>?) -> Int32 {
    // Lua 5.1: ignore 'from' and 'nres' parameters
    let result = CLua.lua_resume(L, narg)
    if let nres = nres {
        nres.pointee = lua_gettop(L)  // Approximate result count
    }
    return result
}

/// Shim for lua_rotate (Lua 5.1 doesn't have this)
/// Only handles n=1 (insert) and n=-1 (remove) cases using native functions
@inline(__always)
func lua_rotate(_ L: OpaquePointer?, _ idx: Int32, _ n: Int32) {
    // For Lua 5.1, lua_insert and lua_remove use native functions
    // This shim is rarely needed, but handle common cases
    if n == 1 {
        CLua.lua_insert(L, idx)
    } else if n == -1 {
        // For n=-1, we'd need to move idx element to top
        // This is rarely used directly, but implement for completeness
        let top = lua_gettop(L)
        let absIdx = idx > 0 ? idx : top + idx + 1
        if absIdx < top {
            lua_pushvalue(L, absIdx)
            for i in absIdx..<top {
                lua_pushvalue(L, i + 1)
                CLua.lua_replace(L, i)
            }
            CLua.lua_replace(L, top)
            lua_pop(L, 1)
        }
    }
    // Other rotation values are not supported in this shim
}
#endif

#if LUA_VERSION_52
/// Shim for lua_rawseti (uses Int32 index in 5.2, lua_Integer in 5.3+)
@inline(__always)
func lua_rawseti(_ L: OpaquePointer?, _ idx: Int32, _ n: lua_Integer) {
    CLua.lua_rawseti(L, idx, Int32(n))
}

/// Shim for lua_rawgeti (uses Int32 index in 5.2, lua_Integer in 5.3+)
@inline(__always)
func lua_rawgeti(_ L: OpaquePointer?, _ idx: Int32, _ n: lua_Integer) -> Int32 {
    CLua.lua_rawgeti(L, idx, Int32(n))
    return lua_type(L, -1)  // 5.2 doesn't return type, compute it
}

/// Shim for lua_resume (5.2 signature: (L, from, narg), 5.4+ signature: (L, from, narg, nres))
@inline(__always)
func lua_resume(_ L: OpaquePointer?, _ from: OpaquePointer?, _ narg: Int32, _ nres: UnsafeMutablePointer<Int32>?) -> Int32 {
    // Lua 5.2: ignore 'nres' parameter
    let result = CLua.lua_resume(L, from, narg)
    if let nres = nres {
        nres.pointee = lua_gettop(L)  // Approximate result count
    }
    return result
}

/// Shim for lua_rotate (Lua 5.2 doesn't have this)
/// Only handles n=1 (insert) and n=-1 (remove) cases using native functions
@inline(__always)
func lua_rotate(_ L: OpaquePointer?, _ idx: Int32, _ n: Int32) {
    if n == 1 {
        CLua.lua_insert(L, idx)
    } else if n == -1 {
        let top = lua_gettop(L)
        let absIdx = idx > 0 ? idx : top + idx + 1
        if absIdx < top {
            lua_pushvalue(L, absIdx)
            for i in absIdx..<top {
                lua_copy(L, i + 1, i)
            }
            lua_copy(L, -1, top)
            lua_pop(L, 1)
        }
    }
}
#endif

#if LUA_VERSION_53
/// Shim for lua_resume (5.3 signature: (L, from, narg), 5.4+ signature: (L, from, narg, nres))
@inline(__always)
func lua_resume(_ L: OpaquePointer?, _ from: OpaquePointer?, _ narg: Int32, _ nres: UnsafeMutablePointer<Int32>?) -> Int32 {
    // Lua 5.3: ignore 'nres' parameter
    let result = CLua.lua_resume(L, from, narg)
    if let nres = nres {
        nres.pointee = lua_gettop(L)  // Approximate result count
    }
    return result
}
#endif

/// Multiple return values (replaces LUA_MULTRET macro)
let LUA_MULTRET: Int32 = -1

/// Thread status: coroutine yielded (from lua.h)
let LUA_YIELD: Int32 = 1

/// Thread type constant (from lua.h)
let LUA_TTHREAD: Int32 = 8

// MARK: - Stack Manipulation

/// Pop n elements from the stack (replaces lua_pop macro)
@inline(__always)
func lua_pop(_ L: OpaquePointer?, _ n: Int32) {
    lua_settop(L, -(n) - 1)
}

/// Create a new empty table (replaces lua_newtable macro)
@inline(__always)
func lua_newtable(_ L: OpaquePointer?) {
    lua_createtable(L, 0, 0)
}

// MARK: - Type Conversion

/// Get a string from the stack (replaces lua_tostring macro)
@inline(__always)
func lua_tostring(_ L: OpaquePointer?, _ index: Int32) -> UnsafePointer<CChar>? {
    return lua_tolstring(L, index, nil)
}

/// Convert to number without isnum check (replaces lua_tonumber macro)
@inline(__always)
func lua_tonumber(_ L: OpaquePointer?, _ index: Int32) -> lua_Number {
    return lua_tonumberx(L, index, nil)
}

/// Convert to integer without isnum check (replaces lua_tointeger macro)
@inline(__always)
func lua_tointeger(_ L: OpaquePointer?, _ index: Int32) -> lua_Integer {
    return lua_tointegerx(L, index, nil)
}

// MARK: - Type Checking

/// Check if value at index is nil (replaces lua_isnil macro)
@inline(__always)
func lua_isnil(_ L: OpaquePointer?, _ index: Int32) -> Bool {
    return lua_type(L, index) == LUA_TNIL
}

/// Check if value at index is a table (replaces lua_istable macro)
@inline(__always)
func lua_istable(_ L: OpaquePointer?, _ index: Int32) -> Bool {
    return lua_type(L, index) == LUA_TTABLE
}

/// Check if value at index is a string (replaces lua_isstring macro)
@inline(__always)
func lua_isstring(_ L: OpaquePointer?, _ index: Int32) -> Int32 {
    let t = lua_type(L, index)
    return (t == LUA_TSTRING || t == LUA_TNUMBER) ? 1 : 0
}

/// Check if value at index is a number (replaces lua_isnumber macro)
@inline(__always)
func lua_isnumber(_ L: OpaquePointer?, _ index: Int32) -> Int32 {
    return lua_type(L, index) == LUA_TNUMBER ? 1 : 0
}

/// Check if value at index is a boolean (replaces lua_isboolean macro)
@inline(__always)
func lua_isboolean(_ L: OpaquePointer?, _ index: Int32) -> Bool {
    return lua_type(L, index) == LUA_TBOOLEAN
}

/// Check if value at index is a function (replaces lua_isfunction macro)
@inline(__always)
func lua_isfunction(_ L: OpaquePointer?, _ index: Int32) -> Bool {
    return lua_type(L, index) == LUA_TFUNCTION
}

/// Check if value at index is light userdata (replaces lua_islightuserdata macro)
@inline(__always)
func lua_islightuserdata(_ L: OpaquePointer?, _ index: Int32) -> Int32 {
    return lua_type(L, index) == LUA_TLIGHTUSERDATA ? 1 : 0
}

/// Check if value at index is a thread (replaces lua_isthread macro)
@inline(__always)
func lua_isthread(_ L: OpaquePointer?, _ index: Int32) -> Bool {
    return lua_type(L, index) == LUA_TTHREAD
}

// MARK: - Function Calls

/// Call a function with error handling (replaces lua_pcall macro)
@inline(__always)
func lua_pcall(_ L: OpaquePointer?, _ nargs: Int32, _ nresults: Int32, _ errfunc: Int32) -> Int32 {
    return lua_pcallk(L, nargs, nresults, errfunc, 0, nil)
}

/// Call a function (replaces lua_call macro)
@inline(__always)
func lua_call(_ L: OpaquePointer?, _ nargs: Int32, _ nresults: Int32) {
    lua_callk(L, nargs, nresults, 0, nil)
}

// MARK: - Global Table Access

/// Push the global environment table (replaces lua_pushglobaltable macro)
@inline(__always)
func lua_pushglobaltable(_ L: OpaquePointer?) {
    #if LUA_VERSION_51
    // Lua 5.1: globals are at LUA_GLOBALSINDEX pseudo-index
    lua_pushvalue(L, LUA_GLOBALSINDEX)
    #else
    // Lua 5.2+: globals are in the registry at LUA_RIDX_GLOBALS
    _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(LUA_RIDX_GLOBALS))
    #endif
}

// MARK: - C Function Registration

/// Push a C closure with no upvalues (replaces lua_pushcfunction macro)
@inline(__always)
func lua_pushcfunction(_ L: OpaquePointer?, _ fn: lua_CFunction?) {
    lua_pushcclosure(L, fn, 0)
}

/// Register a global function (replaces lua_register macro)
@inline(__always)
func lua_register(_ L: OpaquePointer?, _ name: String, _ fn: lua_CFunction?) {
    lua_pushcfunction(L, fn)
    lua_setglobal(L, name)
}

// MARK: - Insertion/Removal

/// Insert value at index (replaces lua_insert macro)
@inline(__always)
func lua_insert(_ L: OpaquePointer?, _ index: Int32) {
    #if LUA_VERSION_51 || LUA_VERSION_52
    // Lua 5.1/5.2 have native lua_insert
    CLua.lua_insert(L, index)
    #else
    // Lua 5.3+ use lua_rotate
    lua_rotate(L, index, 1)
    #endif
}

/// Remove value at index (replaces lua_remove macro)
@inline(__always)
func lua_remove(_ L: OpaquePointer?, _ index: Int32) {
    #if LUA_VERSION_51 || LUA_VERSION_52
    // Lua 5.1/5.2 have native lua_remove
    CLua.lua_remove(L, index)
    #else
    // Lua 5.3+ use lua_rotate
    lua_rotate(L, index, -1)
    lua_pop(L, 1)
    #endif
}

/// Replace value at index with top of stack (replaces lua_replace macro)
@inline(__always)
func lua_replace(_ L: OpaquePointer?, _ index: Int32) {
    #if LUA_VERSION_51
    // Lua 5.1 has native lua_replace
    CLua.lua_replace(L, index)
    #else
    // Lua 5.2+ use lua_copy
    lua_copy(L, -1, index)
    lua_pop(L, 1)
    #endif
}

// MARK: - Upvalue Access

/// Get upvalue index (replaces lua_upvalueindex macro)
/// Lua 5.1: LUA_GLOBALSINDEX - i
/// Lua 5.2+: LUA_REGISTRYINDEX - i
@inline(__always)
func lua_upvalueindex(_ i: Int32) -> Int32 {
    #if LUA_VERSION_51
    return LUA_GLOBALSINDEX - i
    #else
    return LUA_REGISTRYINDEX - i
    #endif
}

// MARK: - Auxiliary Library Macros

/// Open all standard libraries (replaces luaL_openlibs macro)
/// In Lua 5.5+, luaL_openlibs became a macro calling luaL_openselectedlibs
@inline(__always)
func luaL_openlibs(_ L: OpaquePointer?) {
    #if LUA_VERSION_55
    // Lua 5.5: luaL_openlibs is a macro, call the underlying function
    luaL_openselectedlibs(L, ~0, 0)
    #else
    // Lua 5.1-5.4: luaL_openlibs is a function
    CLua.luaL_openlibs(L)
    #endif
}

/// Load a Lua source chunk with an explicit name parameter (Swift wrapper).
///
/// `luaL_loadbuffer` is a C macro defined as
/// `luaL_loadbufferx(L,s,sz,n,NULL)` and cannot be imported into Swift
/// directly. This wrapper expands it for source text (mode = nil / "t")
/// across all supported Lua versions (5.1–5.5).
///
/// - Parameters:
///   - L: Lua state.
///   - buf: Pointer to the source bytes.
///   - sz: Byte count of the source.
///   - name: Chunk name for error messages and tracebacks. Follows Lua's
///     prefix conventions: `@name` for file-like tail-truncation,
///     `=name` for verbatim head-truncation, bare for source-snippet form.
/// - Returns: Lua status code (`LUA_OK` on success).
@inline(__always)
func luaL_loadbuffer_source(
    _ L: OpaquePointer?,
    _ buf: UnsafePointer<CChar>,
    _ sz: Int,
    _ name: UnsafePointer<CChar>
) -> Int32 {
    // On Lua 5.1, luaL_loadbuffer is a real function (not a macro).
    // On 5.2–5.5, luaL_loadbufferx is the underlying function;
    // passing NULL as mode tells the loader to accept both text and binary,
    // which matches what the macro expansion does.
    #if LUA_VERSION_51
    return CLua.luaL_loadbuffer(L, buf, sz, name)
    #else
    return luaL_loadbufferx(L, buf, sz, name, nil)
    #endif
}

/// Load and run a string (replaces luaL_dostring macro)
///
/// Passes the source string as its own chunk name — exactly equivalent to
/// `luaL_loadstring` (which is defined as `luaL_loadbuffer(L,s,strlen(s),s)`).
/// This preserves the `[string "…"]` traceback form that internal callers
/// rely on.
///
/// - Returns: 0 on success, non-zero on error.
@inline(__always)
@discardableResult
func luaL_dostring(_ L: OpaquePointer?, _ s: String) -> Int32 {
    // Pass the source as its own name — same as luaL_loadstring.
    let loadResult = s.withCString { codeCStr in
        luaL_loadbuffer_source(L, codeCStr, s.utf8.count, codeCStr)
    }
    if loadResult != 0 {
        return loadResult
    }
    return lua_pcall(L, 0, LUA_MULTRET, 0)
}

// MARK: - Binary-Safe String Operations

/// Get a string from the stack preserving embedded NUL bytes
/// Uses lua_tolstring to get the actual length instead of stopping at NUL
/// - Parameters:
///   - L: Lua state
///   - index: Stack index
/// - Returns: Swift String or nil if not a string, with embedded NULs preserved
@inline(__always)
func lua_getstring(_ L: OpaquePointer?, _ index: Int32) -> String? {
    var len: Int = 0
    guard let ptr = lua_tolstring(L, index, &len) else { return nil }
    // Create Data from the raw bytes, then convert to String
    // This preserves embedded NUL characters
    let data = Data(bytes: ptr, count: len)
    return String(data: data, encoding: .utf8)
}

/// Push a string to the Lua stack preserving embedded NUL bytes
/// Uses lua_pushlstring to push the exact byte count instead of stopping at NUL
/// - Parameters:
///   - L: Lua state
///   - str: Swift String to push
@inline(__always)
func lua_pushstring_binary(_ L: OpaquePointer?, _ str: String) {
    str.withCString { ptr in
        // Get the UTF-8 byte count (not character count)
        let len = str.utf8.count
        lua_pushlstring(L, ptr, len)
    }
}

// MARK: - Structured Error Handler (#19)

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
/// internal: shared by runtimeErrorHandler and any future stack-inspection code
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
    // Lua 5.1: manual walk — luaL_traceback does not exist.
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
    #else
    // Lua 5.2+: luaL_traceback is available and covers all edge cases.
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
    #endif
}

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
/// unchanged (return 1). This ensures `LuaError.cancelled` and
/// `.instructionLimitExceeded` survive and are not wrapped in `.runtimeFailure`.
/// Belt-and-suspenders: also bail if the error string carries a `__luaswift_`
/// prefix (the sentinel used by the compositor hook).
///
/// ## Non-string error objects
///
/// When the error object is not a string (e.g. `error({table})`), the handler
/// emits a typed placeholder `"<error: typename>"` via `lua_typename` ONLY.
/// It must **not** call `__tostring`, `luaL_tolstring`, or any other metamethod
/// — doing so from inside an error handler risks `LUA_ERRERR`, blows the
/// cancellation instruction budget, and can re-enter the error path.
///
/// ## Line number: first-non-C-frame scan
///
/// Scans upward from level 1 to find the **first frame whose `what != "C"`**.
/// For an explicit `error()` call, level 1 is the C `error` builtin
/// (currentline == -1) and the Lua caller is at level 2. For a VM-internal
/// error (e.g. `nil + 1`), the Lua frame is already at level 1. Both cases
/// produce the correct source line.
///
/// ## Swift stash
///
/// Stores the result in `engine.pendingRuntimeFailure` via the TLS
/// `currentEngine` key (installed by `setAsCurrentEngine()` before the pcall),
/// then returns 1 leaving the error object unchanged. After `lua_pcall` returns,
/// `errorFromCode` reads and clears the stash to produce `.runtimeFailure`.
///
/// ## Coroutines (out of scope)
///
/// Coroutine `resume` uses `lua_resume` (no errfunc) — this handler is NOT
/// called for coroutine errors. Structured errors for coroutines are out of
/// scope for #19; the existing `.coroutineError` path handles them.
internal func runtimeErrorHandler(
    _ L: OpaquePointer?
) -> Int32 {
    guard let L = L else { return 1 }

    // Recover the owning engine via TLS (installed by setAsCurrentEngine()).
    guard let engine = LuaEngine.currentEngine else { return 1 }

    // SENTINEL PASS-THROUGH: compositor hook set abort reason — do not wrap.
    // abortReason: 0=none, 1=cancelled, 2=instructionLimit.
    let abortReason = engine.abortReason.load(ordering: .relaxed)
    if abortReason != 0 { return 1 }

    // Belt-and-suspenders: sentinel string — pass through untouched.
    if lua_type(L, 1) == LUA_TSTRING {
        if let cStr = lua_tostring(L, 1) {
            let msg = String(cString: cStr)
            if msg.hasPrefix("__luaswift_") { return 1 }
        }
    }

    // RAW MESSAGE: read from the stack without invoking any metamethod.
    let rawMessage: String
    if lua_type(L, 1) == LUA_TSTRING {
        rawMessage = lua_tostring(L, 1).map { String(cString: $0) } ?? "<error: string>"
    } else {
        // Non-string error object — type placeholder only, no __tostring call.
        let typeName = lua_typename(L, lua_type(L, 1)).map { String(cString: $0) } ?? "userdata"
        rawMessage = "<error: \(typeName)>"
    }

    // LINE NUMBER: scan upward from level 1 for the first non-C frame.
    // Level 1 when called from error() is the C `error` builtin; the Lua
    // caller is at level 2. For VM-internal errors the Lua frame is at level 1.
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

    // TRACEBACK: always non-nil (manual walk on 5.1, luaL_traceback on 5.2+).
    let traceback = buildTraceback(L, message: nil)

    // FRAMES: full walk from level 0 for the structured frames array.
    let frames = walkLuaStack(L, startLevel: 0)

    // STRIPPED MESSAGE: remove exact "shortSrc:line: " prefix if present.
    // Exact-prefix matching is required because chunk names may contain colons
    // (e.g. "config.yaml:$.scripts.init:3: msg"), making regex unreliable.
    let strippedMessage: String
    if let line = foundLine, !foundShortSrc.isEmpty {
        let prefix = "\(foundShortSrc):\(line): "
        if rawMessage.hasPrefix(prefix) {
            strippedMessage = String(rawMessage.dropFirst(prefix.count))
        } else {
            strippedMessage = rawMessage
        }
    } else {
        strippedMessage = rawMessage
    }

    // STASH: store for errorFromCode to read after pcall returns.
    engine.pendingRuntimeFailure = LuaRuntimeFailure(
        message: strippedMessage,
        rawMessage: rawMessage,
        line: foundLine,
        traceback: traceback,
        frames: frames.isEmpty ? nil : frames
    )

    return 1  // return error object unchanged so lua_pcall propagates it
}
