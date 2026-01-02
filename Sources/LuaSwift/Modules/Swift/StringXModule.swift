//
//  StringXModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed StringX module for LuaSwift.
///
/// Provides optimized string utilities using Swift's native String handling.
///
/// ## Lua API
///
/// ```lua
/// local stringx = require("luaswift.stringx")
///
/// -- Trimming
/// local s = stringx.strip("  hello  ")           -- "hello"
/// local s = stringx.lstrip("  hello  ")          -- "hello  "
/// local s = stringx.rstrip("  hello  ")          -- "  hello"
/// local s = stringx.strip("xxhelloxx", "x")      -- "hello"
///
/// -- Splitting and joining
/// local parts = stringx.split("a,b,c", ",")      -- {"a", "b", "c"}
/// local s = stringx.join({"a", "b", "c"}, ",")   -- "a,b,c"
///
/// -- Replacement
/// local s = stringx.replace("hello world", "world", "Swift")  -- "hello Swift"
/// local s = stringx.replace("aaa", "a", "b", 2)              -- "bba"
///
/// -- Pattern matching
/// local ok = stringx.startswith("hello", "hel")   -- true
/// local ok = stringx.endswith("hello", "lo")      -- true
/// local ok = stringx.contains("hello", "ell")     -- true
/// local n = stringx.count("hello", "l")           -- 2
/// ```
public struct StringXModule {

    /// Register the StringX module with a LuaEngine.
    ///
    /// This creates a global table `luaswift` with a nested `stringx` table containing
    /// string utility functions.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_stringx_strip", callback: stripCallback)
        engine.registerFunction(name: "_luaswift_stringx_lstrip", callback: lstripCallback)
        engine.registerFunction(name: "_luaswift_stringx_rstrip", callback: rstripCallback)
        engine.registerFunction(name: "_luaswift_stringx_split", callback: splitCallback)
        engine.registerFunction(name: "_luaswift_stringx_replace", callback: replaceCallback)
        engine.registerFunction(name: "_luaswift_stringx_join", callback: joinCallback)
        engine.registerFunction(name: "_luaswift_stringx_startswith", callback: startswithCallback)
        engine.registerFunction(name: "_luaswift_stringx_endswith", callback: endswithCallback)
        engine.registerFunction(name: "_luaswift_stringx_contains", callback: containsCallback)
        engine.registerFunction(name: "_luaswift_stringx_count", callback: countCallback)

        // Set up the luaswift.stringx namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Store references to C functions before clearing globals
                local strip_fn = _luaswift_stringx_strip
                local lstrip_fn = _luaswift_stringx_lstrip
                local rstrip_fn = _luaswift_stringx_rstrip
                local split_fn = _luaswift_stringx_split
                local replace_fn = _luaswift_stringx_replace
                local join_fn = _luaswift_stringx_join
                local startswith_fn = _luaswift_stringx_startswith
                local endswith_fn = _luaswift_stringx_endswith
                local contains_fn = _luaswift_stringx_contains
                local count_fn = _luaswift_stringx_count

                luaswift.stringx = {
                    strip = strip_fn,
                    lstrip = lstrip_fn,
                    rstrip = rstrip_fn,
                    split = split_fn,
                    replace = replace_fn,
                    join = join_fn,
                    startswith = startswith_fn,
                    endswith = endswith_fn,
                    contains = contains_fn,
                    count = count_fn
                }

                -- Clean up global namespace
                _luaswift_stringx_strip = nil
                _luaswift_stringx_lstrip = nil
                _luaswift_stringx_rstrip = nil
                _luaswift_stringx_split = nil
                _luaswift_stringx_replace = nil
                _luaswift_stringx_join = nil
                _luaswift_stringx_startswith = nil
                _luaswift_stringx_endswith = nil
                _luaswift_stringx_contains = nil
                _luaswift_stringx_count = nil
                """)
        } catch {
            // Silently fail if setup fails - callbacks are still registered
        }
    }

    // MARK: - Callbacks

    /// Strip (trim) leading and trailing characters
    private static func stripCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.strip requires a string argument")
        }

        if args.count > 1, let chars = args[1].stringValue {
            let charSet = CharacterSet(charactersIn: chars)
            return .string(s.trimmingCharacters(in: charSet))
        }

        return .string(s.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Strip (trim) leading characters only
    private static func lstripCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.lstrip requires a string argument")
        }

        let charSet = args.count > 1 && args[1].stringValue != nil
            ? CharacterSet(charactersIn: args[1].stringValue!)
            : .whitespacesAndNewlines

        var result = s
        while let first = result.first, charSet.contains(first.unicodeScalars.first!) {
            result.removeFirst()
        }

        return .string(result)
    }

    /// Strip (trim) trailing characters only
    private static func rstripCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.rstrip requires a string argument")
        }

        let charSet = args.count > 1 && args[1].stringValue != nil
            ? CharacterSet(charactersIn: args[1].stringValue!)
            : .whitespacesAndNewlines

        var result = s
        while let last = result.last, charSet.contains(last.unicodeScalars.first!) {
            result.removeLast()
        }

        return .string(result)
    }

    /// Split string by separator
    private static func splitCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let sep = args[1].stringValue else {
            throw LuaError.callbackError("stringx.split requires string and separator arguments")
        }

        if sep.isEmpty {
            // Split into individual characters
            let chars = s.map { LuaValue.string(String($0)) }
            return .array(chars)
        }

        let parts = s.components(separatedBy: sep)
        return .array(parts.map { .string($0) })
    }

    /// Replace occurrences of old string with new string
    private static func replaceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3,
              let s = args[0].stringValue,
              let old = args[1].stringValue,
              let new = args[2].stringValue else {
            throw LuaError.callbackError("stringx.replace requires string, old, and new arguments")
        }

        if old.isEmpty {
            return .string(s)
        }

        // Optional count limit
        let count = args.count > 3 ? args[3].intValue : nil

        var result = s
        if let maxReplacements = count {
            var replaced = 0
            var searchStartIndex = result.startIndex

            while replaced < maxReplacements,
                  let range = result.range(of: old, range: searchStartIndex..<result.endIndex) {
                result.replaceSubrange(range, with: new)
                replaced += 1

                // Move search position forward
                let newStartOffset = result.distance(from: result.startIndex, to: range.lowerBound) + new.count
                searchStartIndex = result.index(result.startIndex, offsetBy: newStartOffset)

                if searchStartIndex >= result.endIndex {
                    break
                }
            }
        } else {
            result = result.replacingOccurrences(of: old, with: new)
        }

        return .string(result)
    }

    /// Join array elements with separator
    private static func joinCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let sep = args[1].stringValue else {
            throw LuaError.callbackError("stringx.join requires array and separator arguments")
        }

        // Handle both array and table (for empty tables)
        let array: [LuaValue]
        if let arrayValue = args[0].arrayValue {
            array = arrayValue
        } else if let tableValue = args[0].tableValue, tableValue.isEmpty {
            // Empty table is treated as empty array
            array = []
        } else {
            throw LuaError.callbackError("stringx.join requires array and separator arguments")
        }

        let strings = array.compactMap { $0.stringValue }
        return .string(strings.joined(separator: sep))
    }

    /// Check if string starts with prefix
    private static func startswithCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let prefix = args[1].stringValue else {
            throw LuaError.callbackError("stringx.startswith requires string and prefix arguments")
        }

        return .bool(s.hasPrefix(prefix))
    }

    /// Check if string ends with suffix
    private static func endswithCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let suffix = args[1].stringValue else {
            throw LuaError.callbackError("stringx.endswith requires string and suffix arguments")
        }

        return .bool(s.hasSuffix(suffix))
    }

    /// Check if string contains substring
    private static func containsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let substring = args[1].stringValue else {
            throw LuaError.callbackError("stringx.contains requires string and substring arguments")
        }

        // Empty substring is always contained in any string
        if substring.isEmpty {
            return .bool(true)
        }

        return .bool(s.contains(substring))
    }

    /// Count occurrences of pattern in string
    private static func countCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let pattern = args[1].stringValue else {
            throw LuaError.callbackError("stringx.count requires string and pattern arguments")
        }

        if pattern.isEmpty {
            return .number(0)
        }

        var count = 0
        var searchRange = s.startIndex..<s.endIndex

        while let range = s.range(of: pattern, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<s.endIndex

            if searchRange.isEmpty {
                break
            }
        }

        return .number(Double(count))
    }
}
