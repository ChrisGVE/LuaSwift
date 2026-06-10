//
//  LuaEngine+Bridging.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Bridging.swift
//
//  Context: Value-bridging concern of LuaEngine — converting between
//  LuaValue (LuaValue.swift) and values on a Lua stack. The engine
//  methods read from the engine's own state; the file-scope functions
//  take an explicit lua_State so C callbacks can use them
//  (LuaEngine+Callbacks.swift, LuaEngine+ValueServer.swift) and so can
//  every execution path that returns results (LuaEngine+Execution.swift,
//  LuaEngine+Bytecode.swift, LuaEngine+FunctionCalls.swift). Coroutine
//  bridging keeps thread-local variants in LuaEngine+Coroutines.swift
//  but shares convertToArrayIfContiguous from here.
//

import Foundation
import CLua

// MARK: - Table-conversion safety guards

/// Maximum table-nesting depth materialised before conversion aborts.
///
/// A genuine reference cycle is caught earlier by the visited set
/// (table identity via `lua_topointer`); this depth cap is only a secondary
/// stack-safety backstop for pathologically deep *acyclic* tables that would
/// otherwise overflow the Swift call stack. It is set far above any realistic
/// data shape, so legitimate tables are never rejected. Reaching it is treated
/// as a probable cycle and surfaced as ``LuaError/cyclicTable``.
internal let luaMaxTableConversionDepth = 1000

/// Validate a numeric Lua table key, rejecting any value not representable as a
/// Swift `Int` (fractional, NaN, infinite, or out of `Int` range).
///
/// `Int(exactly:)` is the single source of truth for representability. See
/// ``LuaError/numericKeyOutOfRange(_:)`` for the rationale and the
/// string-key workaround.
@inline(__always)
internal func luaIntegerKey(_ value: Double) throws -> Int {
    guard let key = Int(exactly: value) else {
        throw LuaError.numericKeyOutOfRange(value)
    }
    return key
}

/// Enter the table at `absIndex` for cycle/depth-guarded recursion.
///
/// Returns the table's identity pointer after recording it in `visited`. Throws
/// ``LuaError/cyclicTable`` when the table is already on the current descent
/// path (a back-edge) or when `depth` has reached
/// ``luaMaxTableConversionDepth``. The caller MUST `visited.remove(_:)` the
/// returned pointer when it finishes the table (use `defer`), so sibling tables
/// sharing structure are not misreported as cycles.
@inline(__always)
internal func enterLuaTable(
    _ L: OpaquePointer,
    absIndex: Int32,
    visited: inout Set<UnsafeRawPointer>,
    depth: Int
) throws -> UnsafeRawPointer? {
    guard let ptr = lua_topointer(L, absIndex) else { return nil }
    let raw = UnsafeRawPointer(ptr)
    if visited.contains(raw) || depth >= luaMaxTableConversionDepth {
        throw LuaError.cyclicTable
    }
    visited.insert(raw)
    return raw
}

// MARK: - Engine-state conversion

extension LuaEngine {

    /// Convert the value at `index` on the engine's own stack to a
    /// ``LuaValue``. Functions are stored in the registry and returned as
    /// ``LuaValue/luaFunction(_:)`` references.
    ///
    /// Throws ``LuaError/cyclicTable`` for self-referential tables and
    /// ``LuaError/numericKeyOutOfRange(_:)`` for non-representable numeric keys.
    /// internal: shared across LuaEngine extension files
    internal func valueFromStack(at index: Int32) throws -> LuaValue {
        guard let L = L else { return .nil }
        var visited = Set<UnsafeRawPointer>()
        return try valueFromStack(L, at: index, visited: &visited, depth: 0)
    }

    private func valueFromStack(
        _ L: OpaquePointer,
        at index: Int32,
        visited: inout Set<UnsafeRawPointer>,
        depth: Int
    ) throws -> LuaValue {
        let type = lua_type(L, index)

        switch type {
        case LUA_TNIL:
            return .nil

        case LUA_TBOOLEAN:
            return .bool(lua_toboolean(L, index) != 0)

        case LUA_TNUMBER:
            return .number(lua_tonumber(L, index))

        case LUA_TSTRING:
            guard let str = lua_getstring(L, index) else { return .nil }
            return .string(str)

        case LUA_TTABLE:
            return try tableFromStack(L, at: index, visited: &visited, depth: depth)

        case LUA_TFUNCTION:
            // Store function in registry and return reference
            lua_pushvalue(L, index)  // Push copy of function
            let ref = luaL_ref(L, LUA_REGISTRYINDEX)
            return .luaFunction(ref)

        default:
            return .nil
        }
    }

    private func tableFromStack(
        _ L: OpaquePointer,
        at index: Int32,
        visited: inout Set<UnsafeRawPointer>,
        depth: Int
    ) throws -> LuaValue {
        // Normalize index to absolute
        let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index

        let token = try enterLuaTable(L, absIndex: absIndex, visited: &visited, depth: depth)
        defer { if let token = token { visited.remove(token) } }

        var dict: [String: LuaValue] = [:]
        var intKeyedValues: [Int: LuaValue] = [:]
        var hasStringKeys = false

        // Restore the stack to here if a nested rejection unwinds mid-traversal,
        // so the engine remains reusable after a cyclic/bad-key error.
        let savedTop = lua_gettop(L)
        lua_pushnil(L)  // First key
        do {
            while lua_next(L, absIndex) != 0 {
                // Key is at -2, value is at -1
                let keyType = lua_type(L, -2)
                let value = try valueFromStack(L, at: -1, visited: &visited, depth: depth + 1)

                if keyType == LUA_TNUMBER {
                    let keyNum = try luaIntegerKey(lua_tonumber(L, -2))
                    intKeyedValues[keyNum] = value
                } else if keyType == LUA_TSTRING {
                    hasStringKeys = true
                    if let key = lua_getstring(L, -2) {
                        dict[key] = value
                    }
                }

                lua_pop(L, 1)  // Pop value, keep key for next iteration
            }
        } catch {
            lua_settop(L, savedTop)  // discard any leftover key/value
            throw error
        }

        // Check if integer keys form a contiguous array starting at 1
        if !hasStringKeys, let arr = convertToArrayIfContiguous(intKeyedValues) {
            return .array(arr)
        }

        // Not a pure array - merge all values into dict
        if !intKeyedValues.isEmpty || !dict.isEmpty {
            for (key, val) in intKeyedValues {
                dict[String(key)] = val
            }
            return .table(dict)
        }

        return .table([:])
    }
}

// MARK: - Explicit-state conversion (for C callbacks)

/// Get a LuaValue from the Lua stack (static version for use in callbacks).
///
/// Throws ``LuaError/cyclicTable`` / ``LuaError/numericKeyOutOfRange(_:)`` on
/// unsafe tables. C-callback trampolines that cannot throw across the C boundary
/// (LuaEngine+Callbacks.swift, LuaEngine+ValueServer.swift) catch and convert to
/// `lua_error`.
/// internal: shared across LuaEngine extension files
internal func valueFromLuaStack(_ L: OpaquePointer, at index: Int32) throws -> LuaValue {
    var visited = Set<UnsafeRawPointer>()
    return try valueFromLuaStack(L, at: index, visited: &visited, depth: 0)
}

private func valueFromLuaStack(
    _ L: OpaquePointer,
    at index: Int32,
    visited: inout Set<UnsafeRawPointer>,
    depth: Int
) throws -> LuaValue {
    let type = lua_type(L, index)

    switch type {
    case LUA_TNIL:
        return .nil

    case LUA_TBOOLEAN:
        return .bool(lua_toboolean(L, index) != 0)

    case LUA_TNUMBER:
        return .number(lua_tonumber(L, index))

    case LUA_TSTRING:
        guard let str = lua_getstring(L, index) else { return .nil }
        return .string(str)

    case LUA_TTABLE:
        return try tableFromLuaStack(L, at: index, visited: &visited, depth: depth)

    case LUA_TFUNCTION:
        // Store function in registry and return reference
        lua_pushvalue(L, index)  // Push copy of function
        let ref = luaL_ref(L, LUA_REGISTRYINDEX)
        return .luaFunction(ref)

    default:
        return .nil
    }
}

// MARK: - File-scope Table Conversion Helpers

/// Convert integer-keyed values to a contiguous array if possible.
/// Uses O(n) min/max check instead of O(n log n) sorting.
/// internal: shared with the thread variants in LuaEngine+Coroutines.swift
@inline(__always)
internal func convertToArrayIfContiguous(_ intKeyedValues: [Int: LuaValue]) -> [LuaValue]? {
    guard !intKeyedValues.isEmpty else { return nil }

    // O(n) check: find min and max, verify contiguity
    var minKey = Int.max
    var maxKey = Int.min
    for key in intKeyedValues.keys {
        if key < minKey { minKey = key }
        if key > maxKey { maxKey = key }
    }

    // Must start at 1 and be contiguous
    guard minKey == 1 && maxKey == intKeyedValues.count else { return nil }

    // Build array in order (O(n))
    var result = [LuaValue]()
    result.reserveCapacity(intKeyedValues.count)
    for i in 1...maxKey {
        guard let value = intKeyedValues[i] else { return nil }
        result.append(value)
    }
    return result
}

/// Get a table from the Lua stack (static version for use in callbacks)
private func tableFromLuaStack(
    _ L: OpaquePointer,
    at index: Int32,
    visited: inout Set<UnsafeRawPointer>,
    depth: Int
) throws -> LuaValue {
    // Normalize index to absolute
    let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index

    let token = try enterLuaTable(L, absIndex: absIndex, visited: &visited, depth: depth)
    defer { if let token = token { visited.remove(token) } }

    var dict: [String: LuaValue] = [:]
    var intKeyedValues: [Int: LuaValue] = [:]
    var hasStringKeys = false

    let savedTop = lua_gettop(L)
    lua_pushnil(L)  // First key
    do {
        while lua_next(L, absIndex) != 0 {
            // Key is at -2, value is at -1
            let keyType = lua_type(L, -2)
            let value = try valueFromLuaStack(L, at: -1, visited: &visited, depth: depth + 1)

            if keyType == LUA_TNUMBER {
                let keyNum = try luaIntegerKey(lua_tonumber(L, -2))
                intKeyedValues[keyNum] = value
            } else if keyType == LUA_TSTRING {
                hasStringKeys = true
                if let key = lua_getstring(L, -2) {
                    dict[key] = value
                }
            }

            lua_pop(L, 1)  // Pop value, keep key for next iteration
        }
    } catch {
        lua_settop(L, savedTop)  // discard any leftover key/value
        throw error
    }

    // Check for complex number (has __luaswift_type = "complex")
    if let typeMarker = dict["__luaswift_type"]?.stringValue, typeMarker == "complex",
       let re = dict["re"]?.numberValue,
       let im = dict["im"]?.numberValue {
        return .complex(re: re, im: im)
    }

    // Check if integer keys form a contiguous array starting at 1
    if !hasStringKeys, let arr = convertToArrayIfContiguous(intKeyedValues) {
        return .array(arr)
    }

    // Not a pure array - merge all values into dict
    if !intKeyedValues.isEmpty || !dict.isEmpty {
        for (key, val) in intKeyedValues {
            dict[String(key)] = val
        }
        return .table(dict)
    }

    return .table([:])
}

/// Push a simple LuaValue (no proxy tables)
/// internal: shared across LuaEngine extension files
internal func pushSimpleValue(_ L: OpaquePointer, _ value: LuaValue) {
    switch value {
    case .string(let str):
        lua_pushstring_binary(L, str)
    case .number(let num):
        lua_pushnumber(L, num)
    case .complex(let re, let im):
        pushComplexValue(L, re: re, im: im)
    case .bool(let b):
        lua_pushboolean(L, b ? 1 : 0)
    case .nil:
        lua_pushnil(L)
    case .table(let dict):
        lua_newtable(L)
        for (k, v) in dict {
            lua_pushstring_binary(L, k)
            pushSimpleValue(L, v)
            lua_settable(L, -3)
        }
    case .array(let arr):
        lua_newtable(L)
        for (i, v) in arr.enumerated() {
            pushSimpleValue(L, v)
            lua_rawseti(L, -2, lua_Integer(i + 1))
        }
    case .luaFunction(let ref):
        // Push the function from the registry
        _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(ref))
    case .opaqueReference:
        // Non-re-injectable introspection placeholder — it carries no referent,
        // so there is nothing to push. Materialise as nil.
        lua_pushnil(L)
    }
}

/// Push a complex number onto the Lua stack
/// internal: shared with the proxy push in LuaEngine+ValueServer.swift
internal func pushComplexValue(_ L: OpaquePointer, re: Double, im: Double) {
    // Try to use complex.new if available for proper metatable support
    lua_getglobal(L, "complex")
    if lua_istable(L, -1) {
        lua_getfield(L, -1, "new")
        if lua_isfunction(L, -1) {
            lua_pushnumber(L, re)
            lua_pushnumber(L, im)
            if lua_pcall(L, 2, 1, 0) == LUA_OK {
                // Remove the 'complex' table, keep the result
                lua_remove(L, -2)
                return
            }
            // pcall failed, pop error and fall through
            lua_pop(L, 1)
        } else {
            lua_pop(L, 1)  // pop non-function
        }
    }
    lua_pop(L, 1)  // pop complex table or nil

    // Fallback: create table without metatable
    lua_newtable(L)
    lua_pushnumber(L, re)
    lua_setfield(L, -2, "re")
    lua_pushnumber(L, im)
    lua_setfield(L, -2, "im")
    lua_pushstring(L, "complex")
    lua_setfield(L, -2, "__luaswift_type")
}
