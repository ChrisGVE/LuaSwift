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

        // Set up the luaswift.tablex namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                luaswift.tablex = {
                    deepcopy = _luaswift_tablex_deepcopy,
                    deepmerge = _luaswift_tablex_deepmerge,
                    flatten = _luaswift_tablex_flatten,
                    keys = _luaswift_tablex_keys,
                    values = _luaswift_tablex_values,
                    invert = _luaswift_tablex_invert,
                }

                -- Clean up temporary globals
                _luaswift_tablex_deepcopy = nil
                _luaswift_tablex_deepmerge = nil
                _luaswift_tablex_flatten = nil
                _luaswift_tablex_keys = nil
                _luaswift_tablex_values = nil
                _luaswift_tablex_invert = nil
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
