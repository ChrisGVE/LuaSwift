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
/// local lines = stringx.splitlines("a\nb\nc")    -- {"a", "b", "c"}
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
///
/// -- Case conversion
/// local s = stringx.capitalize("hello world")     -- "Hello world"
/// local s = stringx.title("hello world")          -- "Hello World"
///
/// -- Padding
/// local s = stringx.lpad("hi", 5)                 -- "   hi"
/// local s = stringx.rpad("hi", 5)                 -- "hi   "
/// local s = stringx.center("hi", 6)               -- "  hi  "
/// local s = stringx.lpad("hi", 5, "0")            -- "000hi"
///
/// -- Character classification
/// local ok = stringx.isalpha("hello")             -- true
/// local ok = stringx.isdigit("123")               -- true
/// local ok = stringx.isalnum("abc123")            -- true
/// local ok = stringx.isspace("   ")               -- true
/// local ok = stringx.isempty("")                  -- true
/// local ok = stringx.isblank("  ")                -- true
///
/// -- Text processing
/// local s = stringx.wrap("long text here", 10)    -- word wrapped
/// local s = stringx.truncate("long text", 7)      -- "long..."
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
        engine.registerFunction(name: "_luaswift_stringx_capitalize", callback: capitalizeCallback)
        engine.registerFunction(name: "_luaswift_stringx_title", callback: titleCallback)
        engine.registerFunction(name: "_luaswift_stringx_lpad", callback: lpadCallback)
        engine.registerFunction(name: "_luaswift_stringx_rpad", callback: rpadCallback)
        engine.registerFunction(name: "_luaswift_stringx_center", callback: centerCallback)
        engine.registerFunction(name: "_luaswift_stringx_isalpha", callback: isalphaCallback)
        engine.registerFunction(name: "_luaswift_stringx_isdigit", callback: isdigitCallback)
        engine.registerFunction(name: "_luaswift_stringx_isalnum", callback: isalnumCallback)
        engine.registerFunction(name: "_luaswift_stringx_isspace", callback: isspaceCallback)
        engine.registerFunction(name: "_luaswift_stringx_isempty", callback: isemptyCallback)
        engine.registerFunction(name: "_luaswift_stringx_isblank", callback: isblankCallback)
        engine.registerFunction(name: "_luaswift_stringx_splitlines", callback: splitlinesCallback)
        engine.registerFunction(name: "_luaswift_stringx_wrap", callback: wrapCallback)
        engine.registerFunction(name: "_luaswift_stringx_truncate", callback: truncateCallback)

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
                local capitalize_fn = _luaswift_stringx_capitalize
                local title_fn = _luaswift_stringx_title
                local lpad_fn = _luaswift_stringx_lpad
                local rpad_fn = _luaswift_stringx_rpad
                local center_fn = _luaswift_stringx_center
                local isalpha_fn = _luaswift_stringx_isalpha
                local isdigit_fn = _luaswift_stringx_isdigit
                local isalnum_fn = _luaswift_stringx_isalnum
                local isspace_fn = _luaswift_stringx_isspace
                local isempty_fn = _luaswift_stringx_isempty
                local isblank_fn = _luaswift_stringx_isblank
                local splitlines_fn = _luaswift_stringx_splitlines
                local wrap_fn = _luaswift_stringx_wrap
                local truncate_fn = _luaswift_stringx_truncate

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
                    count = count_fn,
                    capitalize = capitalize_fn,
                    title = title_fn,
                    lpad = lpad_fn,
                    rpad = rpad_fn,
                    center = center_fn,
                    isalpha = isalpha_fn,
                    isdigit = isdigit_fn,
                    isalnum = isalnum_fn,
                    isspace = isspace_fn,
                    isempty = isempty_fn,
                    isblank = isblank_fn,
                    splitlines = splitlines_fn,
                    wrap = wrap_fn,
                    truncate = truncate_fn,

                    -- import() extends the string table and metatable
                    import = function()
                        -- Add functions to string table
                        string.strip = strip_fn
                        string.lstrip = lstrip_fn
                        string.rstrip = rstrip_fn
                        string.split = split_fn
                        string.replace = replace_fn
                        string.join = join_fn
                        string.startswith = startswith_fn
                        string.endswith = endswith_fn
                        string.contains = contains_fn
                        string.count = count_fn
                        string.capitalize = capitalize_fn
                        string.title = title_fn
                        string.lpad = lpad_fn
                        string.rpad = rpad_fn
                        string.center = center_fn
                        string.isalpha = isalpha_fn
                        string.isdigit = isdigit_fn
                        string.isalnum = isalnum_fn
                        string.isspace = isspace_fn
                        string.isempty = isempty_fn
                        string.isblank = isblank_fn
                        string.splitlines = splitlines_fn
                        string.wrap = wrap_fn
                        string.truncate = truncate_fn

                        -- Add to string metatable for s:method() syntax
                        local mt = getmetatable("")
                        if mt and mt.__index then
                            local idx = mt.__index
                            if type(idx) == "table" then
                                idx.strip = strip_fn
                                idx.lstrip = lstrip_fn
                                idx.rstrip = rstrip_fn
                                idx.split = split_fn
                                idx.replace = replace_fn
                                idx.startswith = startswith_fn
                                idx.endswith = endswith_fn
                                idx.contains = contains_fn
                                idx.count = count_fn
                                idx.capitalize = capitalize_fn
                                idx.title = title_fn
                                idx.lpad = lpad_fn
                                idx.rpad = rpad_fn
                                idx.center = center_fn
                                idx.isalpha = isalpha_fn
                                idx.isdigit = isdigit_fn
                                idx.isalnum = isalnum_fn
                                idx.isspace = isspace_fn
                                idx.isempty = isempty_fn
                                idx.isblank = isblank_fn
                                idx.splitlines = splitlines_fn
                                idx.wrap = wrap_fn
                                idx.truncate = truncate_fn
                            end
                        end
                    end
                }

                -- Create top-level global alias
                stringx = luaswift.stringx

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
                _luaswift_stringx_capitalize = nil
                _luaswift_stringx_title = nil
                _luaswift_stringx_lpad = nil
                _luaswift_stringx_rpad = nil
                _luaswift_stringx_center = nil
                _luaswift_stringx_isalpha = nil
                _luaswift_stringx_isdigit = nil
                _luaswift_stringx_isalnum = nil
                _luaswift_stringx_isspace = nil
                _luaswift_stringx_isempty = nil
                _luaswift_stringx_isblank = nil
                _luaswift_stringx_splitlines = nil
                _luaswift_stringx_wrap = nil
                _luaswift_stringx_truncate = nil
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

    // MARK: - Case Conversion Callbacks

    /// Capitalize first letter, lowercase rest
    private static func capitalizeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.capitalize requires a string argument")
        }

        if s.isEmpty {
            return .string("")
        }

        let first = s.prefix(1).uppercased()
        let rest = s.dropFirst().lowercased()
        return .string(first + rest)
    }

    /// Title case (capitalize first letter of each word)
    private static func titleCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.title requires a string argument")
        }

        if s.isEmpty {
            return .string("")
        }

        // Use Swift's capitalized for proper Unicode handling
        return .string(s.capitalized)
    }

    // MARK: - Padding Callbacks

    /// Left pad string to width with character (default space)
    private static func lpadCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let width = args[1].intValue else {
            throw LuaError.callbackError("stringx.lpad requires string and width arguments")
        }

        let padChar: Character
        if args.count > 2, let charStr = args[2].stringValue, !charStr.isEmpty {
            padChar = charStr.first!
        } else {
            padChar = " "
        }

        let currentLength = s.count
        if currentLength >= width {
            return .string(s)
        }

        let padding = String(repeating: padChar, count: width - currentLength)
        return .string(padding + s)
    }

    /// Right pad string to width with character (default space)
    private static func rpadCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let width = args[1].intValue else {
            throw LuaError.callbackError("stringx.rpad requires string and width arguments")
        }

        let padChar: Character
        if args.count > 2, let charStr = args[2].stringValue, !charStr.isEmpty {
            padChar = charStr.first!
        } else {
            padChar = " "
        }

        let currentLength = s.count
        if currentLength >= width {
            return .string(s)
        }

        let padding = String(repeating: padChar, count: width - currentLength)
        return .string(s + padding)
    }

    /// Center pad string to width with character (default space)
    private static func centerCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let width = args[1].intValue else {
            throw LuaError.callbackError("stringx.center requires string and width arguments")
        }

        let padChar: Character
        if args.count > 2, let charStr = args[2].stringValue, !charStr.isEmpty {
            padChar = charStr.first!
        } else {
            padChar = " "
        }

        let currentLength = s.count
        if currentLength >= width {
            return .string(s)
        }

        let totalPadding = width - currentLength
        let leftPadding = totalPadding / 2
        let rightPadding = totalPadding - leftPadding

        let left = String(repeating: padChar, count: leftPadding)
        let right = String(repeating: padChar, count: rightPadding)
        return .string(left + s + right)
    }

    // MARK: - Character Classification Callbacks

    /// Check if all characters are letters
    private static func isalphaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.isalpha requires a string argument")
        }

        if s.isEmpty {
            return .bool(false)
        }

        return .bool(s.allSatisfy { $0.isLetter })
    }

    /// Check if all characters are digits
    private static func isdigitCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.isdigit requires a string argument")
        }

        if s.isEmpty {
            return .bool(false)
        }

        // Use isWholeNumber for standard digit check (0-9)
        return .bool(s.allSatisfy { $0.isWholeNumber })
    }

    /// Check if all characters are alphanumeric
    private static func isalnumCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.isalnum requires a string argument")
        }

        if s.isEmpty {
            return .bool(false)
        }

        return .bool(s.allSatisfy { $0.isLetter || $0.isWholeNumber })
    }

    /// Check if all characters are whitespace
    private static func isspaceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.isspace requires a string argument")
        }

        if s.isEmpty {
            return .bool(false)
        }

        return .bool(s.allSatisfy { $0.isWhitespace })
    }

    /// Check if string is empty
    private static func isemptyCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.isempty requires a string argument")
        }

        return .bool(s.isEmpty)
    }

    /// Check if string is empty or only whitespace
    private static func isblankCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.isblank requires a string argument")
        }

        return .bool(s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Text Processing Callbacks

    /// Split string on newlines (handles \n, \r\n, \r)
    private static func splitlinesCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.stringValue else {
            throw LuaError.callbackError("stringx.splitlines requires a string argument")
        }

        if s.isEmpty {
            return .array([])
        }

        // Use unicodeScalars to properly handle CR-LF as separate characters
        // Swift's Character type treats CR-LF as a single grapheme cluster
        var lines: [String] = []
        var currentLine = ""
        let scalars = Array(s.unicodeScalars)
        var i = 0

        while i < scalars.count {
            let scalar = scalars[i]

            if scalar == "\r" {
                lines.append(currentLine)
                currentLine = ""

                // Check for \r\n
                if i + 1 < scalars.count && scalars[i + 1] == "\n" {
                    i += 1  // Skip the \n in CR-LF pair
                }
            } else if scalar == "\n" {
                lines.append(currentLine)
                currentLine = ""
            } else {
                currentLine.append(Character(scalar))
            }

            i += 1
        }

        // Add the last line if there's content or if string ended with newline
        lines.append(currentLine)

        return .array(lines.map { .string($0) })
    }

    /// Word wrap text to specified width
    private static func wrapCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let width = args[1].intValue else {
            throw LuaError.callbackError("stringx.wrap requires string and width arguments")
        }

        if s.isEmpty || width <= 0 {
            return .string(s)
        }

        var result: [String] = []
        let words = s.split(separator: " ", omittingEmptySubsequences: false)
        var currentLine = ""

        for word in words {
            let wordStr = String(word)

            if currentLine.isEmpty {
                // Start a new line
                if wordStr.count > width {
                    // Word is longer than width, need to break it
                    var remaining = wordStr
                    while remaining.count > width {
                        let breakPoint = remaining.index(remaining.startIndex, offsetBy: width)
                        result.append(String(remaining[..<breakPoint]))
                        remaining = String(remaining[breakPoint...])
                    }
                    currentLine = remaining
                } else {
                    currentLine = wordStr
                }
            } else {
                // Check if word fits on current line
                let testLine = currentLine + " " + wordStr
                if testLine.count <= width {
                    currentLine = testLine
                } else {
                    // Word doesn't fit, start a new line
                    result.append(currentLine)

                    if wordStr.count > width {
                        // Word is longer than width, need to break it
                        var remaining = wordStr
                        while remaining.count > width {
                            let breakPoint = remaining.index(remaining.startIndex, offsetBy: width)
                            result.append(String(remaining[..<breakPoint]))
                            remaining = String(remaining[breakPoint...])
                        }
                        currentLine = remaining
                    } else {
                        currentLine = wordStr
                    }
                }
            }
        }

        // Add the last line
        if !currentLine.isEmpty {
            result.append(currentLine)
        }

        return .string(result.joined(separator: "\n"))
    }

    /// Truncate string to width with suffix (default "...")
    private static func truncateCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let s = args[0].stringValue,
              let width = args[1].intValue else {
            throw LuaError.callbackError("stringx.truncate requires string and width arguments")
        }

        let suffix: String
        if args.count > 2, let suffixStr = args[2].stringValue {
            suffix = suffixStr
        } else {
            suffix = "..."
        }

        if s.count <= width {
            return .string(s)
        }

        let truncateLength = width - suffix.count
        if truncateLength <= 0 {
            // If suffix is longer than or equal to width, just return truncated suffix
            return .string(String(suffix.prefix(width)))
        }

        let truncated = String(s.prefix(truncateLength))
        return .string(truncated + suffix)
    }
}
