//
//  LuaHelpers+CMacros.swift
//  LuaSwift
//
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Swift wrappers for Lua C macros that cannot be imported directly — the
//  version-agnostic half: stack manipulation, type conversion/checking,
//  function calls, global-table access, registration, insertion/removal,
//  upvalues, auxiliary-library macros, and binary-safe string helpers.
//
//  The version-gated constants and the 5.1/5.2 compatibility shims live in
//  LuaHelpers.swift.
//

import Foundation
import CLua

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
