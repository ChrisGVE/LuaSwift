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
let LUAI_MAXSTACK: Int32 = 1_000_000

/// Pseudo-index for the registry (replaces LUA_REGISTRYINDEX macro)
let LUA_REGISTRYINDEX: Int32 = -LUAI_MAXSTACK - 1000

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
    _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(LUA_RIDX_GLOBALS))
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
    lua_rotate(L, index, 1)
}

/// Remove value at index (replaces lua_remove macro)
@inline(__always)
func lua_remove(_ L: OpaquePointer?, _ index: Int32) {
    lua_rotate(L, index, -1)
    lua_pop(L, 1)
}

/// Replace value at index with top of stack (replaces lua_replace macro)
@inline(__always)
func lua_replace(_ L: OpaquePointer?, _ index: Int32) {
    lua_copy(L, -1, index)
    lua_pop(L, 1)
}

// MARK: - Upvalue Access

/// Get upvalue index (replaces lua_upvalueindex macro)
@inline(__always)
func lua_upvalueindex(_ i: Int32) -> Int32 {
    return LUA_REGISTRYINDEX - i
}

// MARK: - Auxiliary Library Macros

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
