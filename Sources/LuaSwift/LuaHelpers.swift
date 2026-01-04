//
//  LuaHelpers.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
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

/// Load and run a string (replaces luaL_dostring macro)
/// Returns 0 on success, non-zero on error
@inline(__always)
@discardableResult
func luaL_dostring(_ L: OpaquePointer?, _ s: String) -> Int32 {
    let loadResult = luaL_loadstring(L, s)
    if loadResult != 0 {
        return loadResult
    }
    return lua_pcall(L, 0, LUA_MULTRET, 0)
}
