//
//  RegexModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed Regex module for LuaSwift.
///
/// Provides full regular expression support using ICU regex syntax via NSRegularExpression.
///
/// ## Lua API
///
/// ```lua
/// local regex = require("luaswift.regex")
///
/// -- Compile pattern
/// local re = regex.compile("\\b\\w+@\\w+\\.\\w+\\b", "i")  -- case insensitive
///
/// -- Match operations
/// local match = re:match("Contact: user@example.com")
/// -- Returns: {start=10, stop=26, text="user@example.com", groups={}}
///
/// local matches = re:find_all(text)
/// local ok = re:test(text)
///
/// -- Replace operations
/// local result = re:replace(text, "REDACTED")
/// local result = re:replace_all(text, "[$0]")  -- $0 = full match
///
/// -- Split
/// local parts = re:split("a,b,,c")
///
/// -- Quick match (no compile)
/// local match = regex.match(text, pattern)
/// ```
public struct RegexModule {

    /// Register the Regex module with a LuaEngine.
    ///
    /// This creates a global table `luaswift` with a nested `regex` table containing:
    /// - `compile(pattern, flags?)`: Compile regex pattern
    /// - `match(text, pattern)`: Quick one-shot match without compilation
    ///
    /// Compiled regex objects have methods:
    /// - `match(text)`: First match
    /// - `find_all(text)`: All matches
    /// - `test(text)`: Boolean test
    /// - `replace(text, replacement)`: Replace first
    /// - `replace_all(text, replacement)`: Replace all
    /// - `split(text)`: Split by pattern
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register compile function
        engine.registerFunction(name: "_luaswift_regex_compile", callback: compileCallback)

        // Register quick match function
        engine.registerFunction(name: "_luaswift_regex_match", callback: quickMatchCallback)

        // Register methods for compiled regex objects
        engine.registerFunction(name: "_luaswift_regex_match_method", callback: matchMethodCallback)
        engine.registerFunction(name: "_luaswift_regex_find_all", callback: findAllCallback)
        engine.registerFunction(name: "_luaswift_regex_test", callback: testCallback)
        engine.registerFunction(name: "_luaswift_regex_replace", callback: replaceCallback)
        engine.registerFunction(name: "_luaswift_regex_replace_all", callback: replaceAllCallback)
        engine.registerFunction(name: "_luaswift_regex_split", callback: splitCallback)

        // Set up the luaswift.regex namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Store references to C functions before clearing globals
                local compile_fn = _luaswift_regex_compile
                local quick_match_fn = _luaswift_regex_match
                local match_method_fn = _luaswift_regex_match_method
                local find_all_fn = _luaswift_regex_find_all
                local test_fn = _luaswift_regex_test
                local replace_fn = _luaswift_regex_replace
                local replace_all_fn = _luaswift_regex_replace_all
                local split_fn = _luaswift_regex_split

                -- Registry to store compiled regex patterns
                local regex_registry = {}

                -- Metatable for compiled regex objects
                local regex_mt = {
                    __index = {
                        match = function(self, text)
                            return match_method_fn(self._id, text)
                        end,
                        find_all = function(self, text)
                            return find_all_fn(self._id, text)
                        end,
                        test = function(self, text)
                            return test_fn(self._id, text)
                        end,
                        replace = function(self, text, replacement)
                            return replace_fn(self._id, text, replacement)
                        end,
                        replace_all = function(self, text, replacement)
                            return replace_all_fn(self._id, text, replacement)
                        end,
                        split = function(self, text)
                            return split_fn(self._id, text)
                        end
                    },
                    __tostring = function(self)
                        return "Regex(" .. self._pattern .. ")"
                    end
                }

                -- Compile function
                local function compile(pattern, flags)
                    local id = compile_fn(pattern, flags or "")
                    local pattern_str = pattern
                    if flags and flags ~= "" then
                        pattern_str = pattern_str .. " [" .. flags .. "]"
                    end
                    local obj = {
                        _id = id,
                        _pattern = pattern_str
                    }
                    regex_registry[id] = pattern
                    return setmetatable(obj, regex_mt)
                end

                luaswift.regex = {
                    compile = compile,
                    match = quick_match_fn
                }

                -- Clean up global namespace
                _luaswift_regex_compile = nil
                _luaswift_regex_match = nil
                _luaswift_regex_match_method = nil
                _luaswift_regex_find_all = nil
                _luaswift_regex_test = nil
                _luaswift_regex_replace = nil
                _luaswift_regex_replace_all = nil
                _luaswift_regex_split = nil
                """)
        } catch {
            #if DEBUG
            print("[LuaSwift] RegexModule setup failed: \(error)")
            #endif
        }
    }

    // MARK: - Shared State

    /// Registry to store compiled NSRegularExpression objects
    /// Key is the regex ID, value is the NSRegularExpression instance
    private static var regexRegistry: [Int: NSRegularExpression] = [:]
    private static var nextRegexId = 1
    private static let registryLock = NSLock()

    // MARK: - Callbacks

    /// Compile callback: creates a compiled regex and returns its ID
    private static func compileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let pattern = args.first?.stringValue else {
            throw LuaError.callbackError("regex.compile requires a pattern string")
        }

        let flags = args.count > 1 ? (args[1].stringValue ?? "") : ""

        do {
            let regex = try createRegex(pattern: pattern, flags: flags)
            let id = storeRegex(regex)
            return .number(Double(id))
        } catch {
            throw LuaError.callbackError("regex.compile error: \(error.localizedDescription)")
        }
    }

    /// Quick match callback: one-shot match without compilation
    private static func quickMatchCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let text = args[0].stringValue,
              let pattern = args[1].stringValue else {
            throw LuaError.callbackError("regex.match requires text and pattern strings")
        }

        do {
            let regex = try createRegex(pattern: pattern, flags: "")
            return performMatch(regex: regex, text: text)
        } catch {
            throw LuaError.callbackError("regex.match error: \(error.localizedDescription)")
        }
    }

    /// Match method callback: match on compiled regex
    private static func matchMethodCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let regexId = args[0].intValue,
              let text = args[1].stringValue else {
            throw LuaError.callbackError("regex:match requires text string")
        }

        guard let regex = getRegex(id: regexId) else {
            throw LuaError.callbackError("Invalid regex ID")
        }

        return performMatch(regex: regex, text: text)
    }

    /// Find all callback: find all matches
    private static func findAllCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let regexId = args[0].intValue,
              let text = args[1].stringValue else {
            throw LuaError.callbackError("regex:find_all requires text string")
        }

        guard let regex = getRegex(id: regexId) else {
            throw LuaError.callbackError("Invalid regex ID")
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        let results = matches.map { match -> LuaValue in
            convertMatchToLua(match: match, text: nsText)
        }

        return .array(results)
    }

    /// Test callback: returns boolean indicating if pattern matches
    private static func testCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let regexId = args[0].intValue,
              let text = args[1].stringValue else {
            throw LuaError.callbackError("regex:test requires text string")
        }

        guard let regex = getRegex(id: regexId) else {
            throw LuaError.callbackError("Invalid regex ID")
        }

        let nsText = text as NSString
        let range = regex.rangeOfFirstMatch(in: text, range: NSRange(location: 0, length: nsText.length))
        return .bool(range.location != NSNotFound)
    }

    /// Replace callback: replace first match
    private static func replaceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3,
              let regexId = args[0].intValue,
              let text = args[1].stringValue,
              let replacement = args[2].stringValue else {
            throw LuaError.callbackError("regex:replace requires text and replacement strings")
        }

        guard let regex = getRegex(id: regexId) else {
            throw LuaError.callbackError("Invalid regex ID")
        }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let result = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)

        // Only replace first match - need to find first match and replace only that
        if let match = regex.firstMatch(in: text, range: range) {
            let replaced = regex.replacementString(for: match, in: text, offset: 0, template: replacement)
            let mutableString = NSMutableString(string: text)
            mutableString.replaceCharacters(in: match.range, with: replaced)
            return .string(mutableString as String)
        }

        return .string(text)
    }

    /// Replace all callback: replace all matches
    private static func replaceAllCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3,
              let regexId = args[0].intValue,
              let text = args[1].stringValue,
              let replacement = args[2].stringValue else {
            throw LuaError.callbackError("regex:replace_all requires text and replacement strings")
        }

        guard let regex = getRegex(id: regexId) else {
            throw LuaError.callbackError("Invalid regex ID")
        }

        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let result = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)

        return .string(result)
    }

    /// Split callback: split text by pattern
    private static func splitCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let regexId = args[0].intValue,
              let text = args[1].stringValue else {
            throw LuaError.callbackError("regex:split requires text string")
        }

        guard let regex = getRegex(id: regexId) else {
            throw LuaError.callbackError("Invalid regex ID")
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        var parts: [LuaValue] = []
        var lastEnd = 0

        for match in matches {
            let part = nsText.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))
            parts.append(.string(part))
            lastEnd = match.range.location + match.range.length
        }

        // Add remaining text
        if lastEnd < nsText.length {
            let part = nsText.substring(from: lastEnd)
            parts.append(.string(part))
        } else if lastEnd == nsText.length && !matches.isEmpty {
            // If pattern matched at end, add empty string
            parts.append(.string(""))
        }

        // If no matches, return original text as single element
        if matches.isEmpty {
            parts.append(.string(text))
        }

        return .array(parts)
    }

    // MARK: - Helper Methods

    /// Create NSRegularExpression from pattern and flags
    private static func createRegex(pattern: String, flags: String) throws -> NSRegularExpression {
        var options: NSRegularExpression.Options = []

        for char in flags {
            switch char {
            case "i":
                options.insert(.caseInsensitive)
            case "m":
                options.insert(.anchorsMatchLines)
            case "s":
                options.insert(.dotMatchesLineSeparators)
            default:
                throw RegexError.invalidFlag(String(char))
            }
        }

        do {
            return try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            throw RegexError.compilationFailed(error.localizedDescription)
        }
    }

    /// Store a compiled regex and return its ID
    private static func storeRegex(_ regex: NSRegularExpression) -> Int {
        registryLock.lock()
        defer { registryLock.unlock() }

        let id = nextRegexId
        nextRegexId += 1
        regexRegistry[id] = regex
        return id
    }

    /// Retrieve a stored regex by ID
    private static func getRegex(id: Int) -> NSRegularExpression? {
        registryLock.lock()
        defer { registryLock.unlock() }

        return regexRegistry[id]
    }

    /// Perform a match and return the first result
    private static func performMatch(regex: NSRegularExpression, text: String) -> LuaValue {
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) else {
            return .nil
        }

        return convertMatchToLua(match: match, text: nsText)
    }

    /// Convert NSTextCheckingResult to Lua table
    private static func convertMatchToLua(match: NSTextCheckingResult, text: NSString) -> LuaValue {
        var result: [String: LuaValue] = [:]

        // Full match (Lua uses 1-based indexing)
        result["start"] = .number(Double(match.range.location + 1))
        result["stop"] = .number(Double(match.range.location + match.range.length))
        result["text"] = .string(text.substring(with: match.range))

        // Capture groups
        var groups: [LuaValue] = []
        for i in 1..<match.numberOfRanges {
            let range = match.range(at: i)
            if range.location != NSNotFound {
                groups.append(.string(text.substring(with: range)))
            } else {
                groups.append(.nil)
            }
        }
        result["groups"] = .array(groups)

        return .table(result)
    }
}

// MARK: - Errors

private enum RegexError: Error, LocalizedError {
    case invalidFlag(String)
    case compilationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFlag(let flag):
            return "Invalid regex flag: \(flag). Valid flags are: i (case insensitive), m (multiline), s (dotall)"
        case .compilationFailed(let message):
            return "Regex compilation failed: \(message)"
        }
    }
}
