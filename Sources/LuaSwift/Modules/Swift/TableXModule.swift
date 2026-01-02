//
//  TableXModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed optimized table utilities module for LuaSwift.
///
/// Provides efficient table operations including deep copying with cycle detection,
/// recursive merging, array flattening, and key/value manipulation.
///
/// ## Lua API
///
/// ```lua
/// local tablex = require("luaswift.tablex")
///
/// -- Deep copy with cycle detection
/// local t1 = {a = 1, b = {c = 2}}
/// local t2 = tablex.deepcopy(t1)
///
/// -- Recursive merge
/// local merged = tablex.deepmerge({a = 1, b = {x = 1}}, {b = {y = 2}, c = 3})
/// -- Result: {a = 1, b = {x = 1, y = 2}, c = 3}
///
/// -- Flatten nested arrays
/// local flat = tablex.flatten({1, {2, 3}, {4, {5, 6}}})  -- {1, 2, 3, 4, 5, 6}
/// local partial = tablex.flatten({1, {2, {3, 4}}}, 1)     -- {1, 2, {3, 4}}
///
/// -- Extract keys and values
/// local k = tablex.keys({a = 1, b = 2})      -- {"a", "b"}
/// local v = tablex.values({a = 1, b = 2})    -- {1, 2}
///
/// -- Invert table
/// local inv = tablex.invert({a = "x", b = "y"})  -- {x = "a", y = "b"}
///
/// -- Functional utilities
/// local copy = tablex.copy(t)                        -- Shallow copy
/// local doubled = tablex.map(t, function(v) return v * 2 end)
/// local evens = tablex.filter(t, function(v) return v % 2 == 0 end)
/// local sum = tablex.reduce(t, function(acc, v) return acc + v end, 0)
/// tablex.foreach(t, print)                           -- Side effects only
/// local key = tablex.find(t, value)                  -- Find key for value
/// local has = tablex.contains(t, value)              -- Check if value exists
/// local n = tablex.size(t)                           -- Count all elements
/// local empty = tablex.isempty(t)                    -- Check if empty
/// local arr = tablex.isarray(t)                      -- Check if array-like
/// local sub = tablex.slice(t, 2, 4)                  -- Array slice
/// local rev = tablex.reverse(t)                      -- Reverse array
/// local uniq = tablex.unique(t)                      -- Remove duplicates
/// local sorted = tablex.sort(t, comp)                -- Sort with optional comparator
/// local u = tablex.union(t1, t2)                     -- Set union
/// local i = tablex.intersection(t1, t2)              -- Set intersection
/// local d = tablex.difference(t1, t2)                -- Set difference
/// local eq = tablex.equals(t1, t2)                   -- Shallow equality
/// local deq = tablex.deepequals(t1, t2)              -- Deep equality
/// ```
public struct TableXModule {

    /// Register the table utilities module with a LuaEngine.
    ///
    /// This creates a global table `luaswift` with a nested `tablex` table containing
    /// optimized table manipulation functions.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register all functions
        engine.registerFunction(name: "_luaswift_tablex_deepcopy", callback: deepcopyCallback)
        engine.registerFunction(name: "_luaswift_tablex_deepmerge", callback: deepmergeCallback)
        engine.registerFunction(name: "_luaswift_tablex_flatten", callback: flattenCallback)
        engine.registerFunction(name: "_luaswift_tablex_keys", callback: keysCallback)
        engine.registerFunction(name: "_luaswift_tablex_values", callback: valuesCallback)
        engine.registerFunction(name: "_luaswift_tablex_invert", callback: invertCallback)

        // Set up the luaswift.tablex namespace with type-aware wrappers
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Store Swift-backed functions locally
                local _swift_deepcopy = _luaswift_tablex_deepcopy
                local _swift_deepmerge = _luaswift_tablex_deepmerge
                local _swift_flatten = _luaswift_tablex_flatten
                local _swift_keys = _luaswift_tablex_keys
                local _swift_values = _luaswift_tablex_values
                local _swift_invert = _luaswift_tablex_invert

                luaswift.tablex = {}

                -- Type-aware deepcopy that preserves LuaSwift typed objects
                function luaswift.tablex.deepcopy(t, seen)
                    if type(t) ~= "table" then return t end

                    -- Handle LuaSwift typed objects - use types.clone if available
                    local luaswift_type = rawget(t, "__luaswift_type")
                    if luaswift_type then
                        if luaswift and luaswift.types and luaswift.types.clone then
                            return luaswift.types.clone(t)
                        end
                        -- Fallback: return reference for typed objects if types module not loaded
                        return t
                    end

                    seen = seen or {}
                    if seen[t] then return seen[t] end

                    local copy = {}
                    seen[t] = copy
                    for k, v in pairs(t) do
                        copy[luaswift.tablex.deepcopy(k, seen)] = luaswift.tablex.deepcopy(v, seen)
                    end
                    return setmetatable(copy, getmetatable(t))
                end

                -- Type-aware deepmerge that doesn't merge into typed objects
                function luaswift.tablex.deepmerge(t1, t2)
                    if type(t1) ~= "table" or type(t2) ~= "table" then
                        return t2
                    end

                    -- If t2 is a typed object, replace rather than merge
                    local t2_type = rawget(t2, "__luaswift_type")
                    if t2_type then
                        if luaswift and luaswift.types and luaswift.types.clone then
                            return luaswift.types.clone(t2)
                        end
                        return t2
                    end

                    -- If t1 is a typed object, it gets replaced by t2
                    local t1_type = rawget(t1, "__luaswift_type")
                    if t1_type then
                        return luaswift.tablex.deepcopy(t2)
                    end

                    -- Regular table merge
                    local result = {}
                    for k, v in pairs(t1) do
                        result[k] = v
                    end
                    for k, v2 in pairs(t2) do
                        local v1 = result[k]
                        if type(v1) == "table" and type(v2) == "table" then
                            -- Check if either is a typed object
                            local v1_type = rawget(v1, "__luaswift_type")
                            local v2_type = rawget(v2, "__luaswift_type")
                            if v2_type then
                                -- v2 is typed - replace
                                if luaswift and luaswift.types and luaswift.types.clone then
                                    result[k] = luaswift.types.clone(v2)
                                else
                                    result[k] = v2
                                end
                            elseif v1_type then
                                -- v1 is typed but v2 is not - replace with copy of v2
                                result[k] = luaswift.tablex.deepcopy(v2)
                            else
                                -- Both are regular tables - merge recursively
                                result[k] = luaswift.tablex.deepmerge(v1, v2)
                            end
                        else
                            result[k] = v2
                        end
                    end
                    return result
                end

                -- Simple wrappers for Swift-backed functions
                luaswift.tablex.flatten = _swift_flatten
                luaswift.tablex.keys = _swift_keys
                luaswift.tablex.values = _swift_values
                luaswift.tablex.invert = _swift_invert

                -- Clean up temporary globals
                _luaswift_tablex_deepcopy = nil
                _luaswift_tablex_deepmerge = nil
                _luaswift_tablex_flatten = nil
                _luaswift_tablex_keys = nil
                _luaswift_tablex_values = nil
                _luaswift_tablex_invert = nil

                -- Shallow copy (one level only)
                function luaswift.tablex.copy(t)
                    local result = {}
                    for k, v in pairs(t) do
                        result[k] = v
                    end
                    return result
                end

                -- Map function over values, return new table
                function luaswift.tablex.map(t, f)
                    local result = {}
                    for k, v in pairs(t) do
                        result[k] = f(v, k)
                    end
                    return result
                end

                -- Filter by predicate, return new table
                function luaswift.tablex.filter(t, f)
                    local result = {}
                    local i = 1
                    for k, v in pairs(t) do
                        if f(v, k) then
                            if type(k) == "number" then
                                result[i] = v
                                i = i + 1
                            else
                                result[k] = v
                            end
                        end
                    end
                    return result
                end

                -- Reduce/fold left
                function luaswift.tablex.reduce(t, f, init)
                    local acc = init
                    for k, v in pairs(t) do
                        acc = f(acc, v, k)
                    end
                    return acc
                end

                -- Iterate with side effects, return nil
                function luaswift.tablex.foreach(t, f)
                    for k, v in pairs(t) do
                        f(v, k)
                    end
                    return nil
                end

                -- Find key for value, return key or nil
                function luaswift.tablex.find(t, value)
                    for k, v in pairs(t) do
                        if v == value then
                            return k
                        end
                    end
                    return nil
                end

                -- Check if table contains value
                function luaswift.tablex.contains(t, value)
                    for _, v in pairs(t) do
                        if v == value then
                            return true
                        end
                    end
                    return false
                end

                -- Count all elements (not just array part)
                function luaswift.tablex.size(t)
                    local count = 0
                    for _ in pairs(t) do
                        count = count + 1
                    end
                    return count
                end

                -- Check if table has no elements
                function luaswift.tablex.isempty(t)
                    return next(t) == nil
                end

                -- Check if table is array-like (sequential integer keys from 1)
                function luaswift.tablex.isarray(t)
                    local count = 0
                    for _ in pairs(t) do
                        count = count + 1
                    end
                    -- Check if all keys are sequential integers from 1 to count
                    for i = 1, count do
                        if t[i] == nil then
                            return false
                        end
                    end
                    return true
                end

                -- Array slice from i to j (default to end)
                function luaswift.tablex.slice(t, i, j)
                    local len = #t
                    j = j or len
                    -- Handle negative indices
                    if i < 0 then i = len + i + 1 end
                    if j < 0 then j = len + j + 1 end
                    -- Clamp to valid range
                    if i < 1 then i = 1 end
                    if j > len then j = len end
                    local result = {}
                    for idx = i, j do
                        result[#result + 1] = t[idx]
                    end
                    return result
                end

                -- Reverse array, return new table
                function luaswift.tablex.reverse(t)
                    local result = {}
                    local len = #t
                    for i = len, 1, -1 do
                        result[#result + 1] = t[i]
                    end
                    return result
                end

                -- Remove duplicates, return new array
                function luaswift.tablex.unique(t)
                    local seen = {}
                    local result = {}
                    for _, v in ipairs(t) do
                        -- Convert to string for table key lookup
                        local key = tostring(v)
                        if type(v) == "table" then
                            -- For tables, use a reference-based approach
                            key = v
                        end
                        if not seen[key] then
                            seen[key] = true
                            result[#result + 1] = v
                        end
                    end
                    return result
                end

                -- Sort array, return new sorted table (optional comparator)
                function luaswift.tablex.sort(t, comp)
                    local result = {}
                    for i, v in ipairs(t) do
                        result[i] = v
                    end
                    table.sort(result, comp)
                    return result
                end

                -- Set union (values as keys)
                function luaswift.tablex.union(t1, t2)
                    local result = {}
                    local idx = 1
                    local seen = {}
                    for _, v in ipairs(t1) do
                        local key = tostring(v)
                        if not seen[key] then
                            seen[key] = true
                            result[idx] = v
                            idx = idx + 1
                        end
                    end
                    for _, v in ipairs(t2) do
                        local key = tostring(v)
                        if not seen[key] then
                            seen[key] = true
                            result[idx] = v
                            idx = idx + 1
                        end
                    end
                    return result
                end

                -- Set intersection
                function luaswift.tablex.intersection(t1, t2)
                    local set2 = {}
                    for _, v in ipairs(t2) do
                        set2[tostring(v)] = true
                    end
                    local result = {}
                    local seen = {}
                    for _, v in ipairs(t1) do
                        local key = tostring(v)
                        if set2[key] and not seen[key] then
                            seen[key] = true
                            result[#result + 1] = v
                        end
                    end
                    return result
                end

                -- Set difference (t1 - t2)
                function luaswift.tablex.difference(t1, t2)
                    local set2 = {}
                    for _, v in ipairs(t2) do
                        set2[tostring(v)] = true
                    end
                    local result = {}
                    local seen = {}
                    for _, v in ipairs(t1) do
                        local key = tostring(v)
                        if not set2[key] and not seen[key] then
                            seen[key] = true
                            result[#result + 1] = v
                        end
                    end
                    return result
                end

                -- Shallow equality check
                function luaswift.tablex.equals(t1, t2)
                    -- Check all keys in t1 exist in t2 with same values
                    for k, v in pairs(t1) do
                        if t2[k] ~= v then
                            return false
                        end
                    end
                    -- Check all keys in t2 exist in t1
                    for k, _ in pairs(t2) do
                        if t1[k] == nil then
                            return false
                        end
                    end
                    return true
                end

                -- Deep equality check
                function luaswift.tablex.deepequals(t1, t2)
                    if type(t1) ~= type(t2) then
                        return false
                    end
                    if type(t1) ~= "table" then
                        return t1 == t2
                    end
                    -- Check all keys in t1 exist in t2 with same values
                    for k, v in pairs(t1) do
                        if not luaswift.tablex.deepequals(v, t2[k]) then
                            return false
                        end
                    end
                    -- Check all keys in t2 exist in t1
                    for k, _ in pairs(t2) do
                        if t1[k] == nil then
                            return false
                        end
                    end
                    return true
                end

                -- import() extends the table library
                function luaswift.tablex.import()
                    table.deepcopy = luaswift.tablex.deepcopy
                    table.deepmerge = luaswift.tablex.deepmerge
                    table.flatten = luaswift.tablex.flatten
                    table.keys = luaswift.tablex.keys
                    table.values = luaswift.tablex.values
                    table.invert = luaswift.tablex.invert
                    table.copy = luaswift.tablex.copy
                    table.map = luaswift.tablex.map
                    table.filter = luaswift.tablex.filter
                    table.reduce = luaswift.tablex.reduce
                    table.foreach = luaswift.tablex.foreach
                    table.find = luaswift.tablex.find
                    table.contains = luaswift.tablex.contains
                    table.size = luaswift.tablex.size
                    table.isempty = luaswift.tablex.isempty
                    table.isarray = luaswift.tablex.isarray
                    table.slice = luaswift.tablex.slice
                    table.reverse = luaswift.tablex.reverse
                    table.unique = luaswift.tablex.unique
                    table.union = luaswift.tablex.union
                    table.intersection = luaswift.tablex.intersection
                    table.difference = luaswift.tablex.difference
                    table.equals = luaswift.tablex.equals
                    table.deepequals = luaswift.tablex.deepequals
                    -- Note: we don't override table.sort as it exists in Lua stdlib
                end

                -- Create top-level global alias
                tablex = luaswift.tablex
                """)
        } catch {
            // Silently fail if setup fails - callbacks are still registered
        }
    }

    // MARK: - Deep Copy

    private static func deepcopyCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let value = args.first else {
            throw LuaError.callbackError("deepcopy requires a table argument")
        }

        var seen: [ObjectIdentifier: LuaValue] = [:]
        return deepcopy(value, seen: &seen)
    }

    private static func deepcopy(_ value: LuaValue, seen: inout [ObjectIdentifier: LuaValue]) -> LuaValue {
        switch value {
        case .table(let dict):
            // Recursively copy all entries
            var copy: [String: LuaValue] = [:]
            for (k, v) in dict {
                copy[k] = deepcopy(v, seen: &seen)
            }
            return .table(copy)

        case .array(let arr):
            // Recursively copy all elements
            let copy = arr.map { deepcopy($0, seen: &seen) }
            return .array(copy)

        default:
            // Primitive values (string, number, bool, nil) are copied by value
            return value
        }
    }

    // MARK: - Deep Merge

    private static func deepmergeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("deepmerge requires two table arguments")
        }

        guard let t1 = args[0].tableValue else {
            throw LuaError.callbackError("deepmerge requires first argument to be a table")
        }

        guard let t2 = args[1].tableValue else {
            throw LuaError.callbackError("deepmerge requires second argument to be a table")
        }

        let merged = deepmerge(t1, t2)
        return .table(merged)
    }

    private static func deepmerge(_ t1: [String: LuaValue], _ t2: [String: LuaValue]) -> [String: LuaValue] {
        var result = t1

        for (key, value2) in t2 {
            if let value1 = result[key],
               case .table(let dict1) = value1,
               case .table(let dict2) = value2 {
                // Both values are tables - merge recursively
                result[key] = .table(deepmerge(dict1, dict2))
            } else {
                // Otherwise, t2 value overrides t1 value
                result[key] = value2
            }
        }

        return result
    }

    // MARK: - Flatten

    private static func flattenCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("flatten requires an array argument")
        }

        // Optional depth parameter (default: Int.max for full flatten)
        let depth: Int
        if args.count > 1, let d = args[1].intValue {
            guard d >= 0 else {
                throw LuaError.callbackError("flatten depth must be non-negative")
            }
            depth = d
        } else {
            depth = Int.max
        }

        let flattened = flatten(array, depth: depth)
        return .array(flattened)
    }

    private static func flatten(_ array: [LuaValue], depth: Int) -> [LuaValue] {
        guard depth > 0 else {
            return array
        }

        var result: [LuaValue] = []
        for element in array {
            if case .array(let nested) = element {
                // Recursively flatten nested arrays
                result.append(contentsOf: flatten(nested, depth: depth - 1))
            } else {
                result.append(element)
            }
        }
        return result
    }

    // MARK: - Keys

    private static func keysCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let table = args.first?.tableValue else {
            throw LuaError.callbackError("keys requires a table argument")
        }

        let keys = table.keys.sorted().map { LuaValue.string($0) }
        return .array(keys)
    }

    // MARK: - Values

    private static func valuesCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let table = args.first?.tableValue else {
            throw LuaError.callbackError("values requires a table argument")
        }

        // Sort by keys to ensure consistent ordering
        let sortedKeys = table.keys.sorted()
        let values = sortedKeys.map { table[$0]! }
        return .array(values)
    }

    // MARK: - Invert

    private static func invertCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let table = args.first?.tableValue else {
            throw LuaError.callbackError("invert requires a table argument")
        }

        var inverted: [String: LuaValue] = [:]
        for (key, value) in table {
            // Convert the value to a string key
            let newKey: String
            switch value {
            case .string(let s):
                newKey = s
            case .number(let n):
                // Convert numbers to strings
                newKey = n.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(n))
                    : String(n)
            case .bool(let b):
                newKey = b ? "true" : "false"
            default:
                // Skip non-primitive values
                continue
            }

            inverted[newKey] = .string(key)
        }

        return .table(inverted)
    }
}
