//
//  JSONModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed JSON module for LuaSwift.
///
/// Provides JSON encoding and decoding functionality via Swift's JSONEncoder/JSONDecoder.
///
/// ## Lua API
///
/// ```lua
/// local json = require("luaswift.json")
///
/// -- Decode JSON string to Lua table
/// local tbl = json.decode('{"name":"John","age":30}')
///
/// -- Encode Lua table to JSON string
/// local str = json.encode({name="John", age=30})
///
/// -- Pretty printing
/// local pretty = json.encode(tbl, {pretty=true, indent=2})
///
/// -- Null sentinel value
/// local null = json.null
/// ```
public struct JSONModule {
    /// Sentinel value for JSON null
    public static let null = JSONNull()

    /// Register the JSON module with a LuaEngine.
    ///
    /// This creates a global table `luaswift` with a nested `json` table containing:
    /// - `encode(value, options?)`: Encode Lua value to JSON string
    /// - `decode(string, options?)`: Decode JSON string to Lua value
    /// - `decode_jsonc(string)`: Decode JSONC (JSON with Comments) string
    /// - `decode_json5(string)`: Decode JSON5 (relaxed JSON) string
    /// - `null`: Sentinel value for JSON null
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register encode function
        engine.registerFunction(name: "_luaswift_json_encode", callback: encodeCallback)

        // Register decode function
        engine.registerFunction(name: "_luaswift_json_decode", callback: decodeCallback)

        // Register decode_jsonc function
        engine.registerFunction(name: "_luaswift_json_decode_jsonc", callback: decodeJSONCCallback)

        // Register decode_json5 function
        engine.registerFunction(name: "_luaswift_json_decode_json5", callback: decodeJSON5Callback)

        // Set up the luaswift.json namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                luaswift.json = {
                    encode = _luaswift_json_encode,
                    decode = _luaswift_json_decode,
                    decode_jsonc = _luaswift_json_decode_jsonc,
                    decode_json5 = _luaswift_json_decode_json5,
                    null = setmetatable({}, {
                        __tostring = function() return "null" end,
                        __type = "json.null"
                    })
                }
                _luaswift_json_encode = nil
                _luaswift_json_decode = nil
                _luaswift_json_decode_jsonc = nil
                _luaswift_json_decode_json5 = nil
                """)
        } catch {
            // Silently fail if setup fails - callbacks are still registered
        }
    }

    // MARK: - Callbacks

    /// Encode callback: converts Lua value to JSON string
    private static func encodeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard !args.isEmpty else {
            throw LuaError.callbackError("json.encode requires at least one argument")
        }

        let value = args[0]
        var pretty = false
        var indent = 2

        // Parse options table if provided
        if args.count > 1, let options = args[1].tableValue {
            if let prettyValue = options["pretty"]?.boolValue {
                pretty = prettyValue
            }
            if let indentValue = options["indent"]?.intValue {
                indent = indentValue
            }
        }

        do {
            let jsonString = try encode(value: value, pretty: pretty, indent: indent)
            return .string(jsonString)
        } catch {
            throw LuaError.callbackError("json.encode error: \(error.localizedDescription)")
        }
    }

    /// Decode callback: converts JSON string to Lua value
    private static func decodeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let jsonString = args.first?.stringValue else {
            throw LuaError.callbackError("json.decode requires a string argument")
        }

        // Check for options
        var format = "json"
        if args.count > 1, let options = args[1].tableValue {
            if let formatValue = options["format"]?.stringValue {
                format = formatValue.lowercased()
            }
            // Also support {comments = true} as shorthand for JSONC
            if let commentsValue = options["comments"]?.boolValue, commentsValue {
                format = "jsonc"
            }
        }

        do {
            switch format {
            case "jsonc":
                return try decodeJSONC(jsonString: jsonString)
            case "json5":
                return try decodeJSON5(jsonString: jsonString)
            default:
                return try decode(jsonString: jsonString)
            }
        } catch {
            throw LuaError.callbackError("json.decode error: \(error.localizedDescription)")
        }
    }

    /// Decode JSONC callback: converts JSONC (JSON with Comments) string to Lua value
    private static func decodeJSONCCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let jsonString = args.first?.stringValue else {
            throw LuaError.callbackError("json.decode_jsonc requires a string argument")
        }

        do {
            return try decodeJSONC(jsonString: jsonString)
        } catch {
            throw LuaError.callbackError("json.decode_jsonc error: \(error.localizedDescription)")
        }
    }

    /// Decode JSON5 callback: converts JSON5 string to Lua value
    private static func decodeJSON5Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let jsonString = args.first?.stringValue else {
            throw LuaError.callbackError("json.decode_json5 requires a string argument")
        }

        do {
            return try decodeJSON5(jsonString: jsonString)
        } catch {
            throw LuaError.callbackError("json.decode_json5 error: \(error.localizedDescription)")
        }
    }

    // MARK: - Encoding

    /// Encode a LuaValue to JSON string
    private static func encode(value: LuaValue, pretty: Bool, indent: Int) throws -> String {
        let jsonData = try encodeValue(value, pretty: pretty, indent: indent)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw JSONError.encodingFailed("Failed to convert JSON data to UTF-8 string")
        }
        return jsonString
    }

    /// Encode a LuaValue to JSON Data
    private static func encodeValue(_ value: LuaValue, pretty: Bool, indent: Int) throws -> Data {
        let jsonValue = try convertLuaToJSON(value)

        // NSJSONSerialization requires top-level object to be array or dictionary
        // For scalars, wrap in array, then extract the scalar representation
        let needsWrapping = !(jsonValue is [Any]) && !(jsonValue is [String: Any])
        let objectToSerialize = needsWrapping ? [jsonValue] : jsonValue

        let data = try JSONSerialization.data(withJSONObject: objectToSerialize, options: pretty ? [.prettyPrinted, .sortedKeys] : [])

        if needsWrapping {
            // Remove the array wrapping: trim [ ] from start/end
            var jsonString = String(data: data, encoding: .utf8) ?? ""
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            if jsonString.hasPrefix("[") && jsonString.hasSuffix("]") {
                jsonString.removeFirst()
                jsonString.removeLast()
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return jsonString.data(using: .utf8) ?? data
        }

        return data
    }

    /// Convert LuaValue to Foundation JSON types
    private static func convertLuaToJSON(_ value: LuaValue) throws -> Any {
        switch value {
        case .nil:
            return NSNull()

        case .bool(let b):
            return b

        case .number(let n):
            return n

        case .complex(let re, let im):
            // Serialize complex as object with type marker
            return ["__type": "complex", "re": re, "im": im] as [String: Any]

        case .string(let s):
            return s

        case .array(let arr):
            return try arr.map { try convertLuaToJSON($0) }

        case .table(let dict):
            var jsonDict: [String: Any] = [:]
            for (key, val) in dict {
                jsonDict[key] = try convertLuaToJSON(val)
            }
            return jsonDict

        case .luaFunction:
            throw LuaError.runtimeError("Cannot serialize function to JSON")
        }
    }

    // MARK: - Decoding

    /// Decode a JSON string to LuaValue
    private static func decode(jsonString: String) throws -> LuaValue {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw JSONError.decodingFailed("Invalid UTF-8 string")
        }

        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        return convertJSONToLua(jsonObject)
    }

    /// Decode a JSONC (JSON with Comments) string to LuaValue
    ///
    /// JSONC supports:
    /// - Single-line comments: `// comment`
    /// - Block comments: `/* comment */`
    private static func decodeJSONC(jsonString: String) throws -> LuaValue {
        let stripped = stripJSONComments(jsonString)
        return try decode(jsonString: stripped)
    }

    /// Decode a JSON5 string to LuaValue
    ///
    /// JSON5 supports:
    /// - Single and block comments (`//` and `/* */`)
    /// - Trailing commas in arrays and objects
    /// - Unquoted object keys (identifiers)
    /// - Single-quoted strings
    /// - Hexadecimal numbers (`0x1A`)
    /// - Leading/trailing decimal points (`.5`, `5.`)
    /// - Infinity and NaN
    /// - Escaped newlines in strings
    private static func decodeJSON5(jsonString: String) throws -> LuaValue {
        let normalized = try normalizeJSON5(jsonString)
        return try decode(jsonString: normalized)
    }

    // MARK: - JSONC Support

    /// Strip comments from JSONC string, respecting string boundaries
    private static func stripJSONComments(_ input: String) -> String {
        var result = ""
        var i = input.startIndex
        let end = input.endIndex

        while i < end {
            let char = input[i]

            // Check for string start
            if char == "\"" {
                result.append(char)
                i = input.index(after: i)
                // Skip string contents, handling escapes
                while i < end {
                    let strChar = input[i]
                    result.append(strChar)
                    if strChar == "\\" && input.index(after: i) < end {
                        // Skip escaped character
                        i = input.index(after: i)
                        result.append(input[i])
                    } else if strChar == "\"" {
                        break
                    }
                    i = input.index(after: i)
                }
                if i < end {
                    i = input.index(after: i)
                }
                continue
            }

            // Check for single-line comment
            if char == "/" && input.index(after: i) < end && input[input.index(after: i)] == "/" {
                // Skip to end of line
                i = input.index(after: input.index(after: i))
                while i < end && input[i] != "\n" && input[i] != "\r" {
                    i = input.index(after: i)
                }
                continue
            }

            // Check for block comment
            if char == "/" && input.index(after: i) < end && input[input.index(after: i)] == "*" {
                // Skip to end of block comment
                i = input.index(after: input.index(after: i))
                while i < end {
                    if input[i] == "*" && input.index(after: i) < end && input[input.index(after: i)] == "/" {
                        i = input.index(after: input.index(after: i))
                        break
                    }
                    i = input.index(after: i)
                }
                continue
            }

            // Regular character
            result.append(char)
            i = input.index(after: i)
        }

        return result
    }

    // MARK: - JSON5 Support

    /// Normalize JSON5 to standard JSON
    private static func normalizeJSON5(_ input: String) throws -> String {
        // First strip comments (JSON5 supports both // and /* */)
        let noComments = stripJSONComments(input)

        var result = ""
        var i = noComments.startIndex
        let end = noComments.endIndex

        while i < end {
            let char = noComments[i]

            // Handle double-quoted strings (pass through)
            if char == "\"" {
                result.append(char)
                i = noComments.index(after: i)
                while i < end {
                    let strChar = noComments[i]
                    result.append(strChar)
                    if strChar == "\\" && noComments.index(after: i) < end {
                        i = noComments.index(after: i)
                        result.append(noComments[i])
                    } else if strChar == "\"" {
                        break
                    }
                    i = noComments.index(after: i)
                }
                if i < end {
                    i = noComments.index(after: i)
                }
                continue
            }

            // Handle single-quoted strings (convert to double-quoted)
            if char == "'" {
                result.append("\"")
                i = noComments.index(after: i)
                while i < end {
                    let strChar = noComments[i]
                    if strChar == "\\" && noComments.index(after: i) < end {
                        let nextChar = noComments[noComments.index(after: i)]
                        if nextChar == "'" {
                            // Convert \' to '
                            result.append("'")
                            i = noComments.index(after: noComments.index(after: i))
                            continue
                        } else {
                            result.append(strChar)
                            i = noComments.index(after: i)
                            result.append(noComments[i])
                        }
                    } else if strChar == "\"" {
                        // Escape unescaped double quotes inside single-quoted string
                        result.append("\\\"")
                    } else if strChar == "'" {
                        break
                    } else {
                        result.append(strChar)
                    }
                    i = noComments.index(after: i)
                }
                result.append("\"")
                if i < end {
                    i = noComments.index(after: i)
                }
                continue
            }

            // Handle unquoted keys and identifiers (identifier after { or ,)
            if isIdentifierStart(char) {
                // Look back through result to find last non-whitespace character
                let lastNonSpace = findLastNonWhitespace(in: result)

                // Collect the identifier first
                var identifier = String(char)
                i = noComments.index(after: i)
                while i < end && isIdentifierContinue(noComments[i]) {
                    identifier.append(noComments[i])
                    i = noComments.index(after: i)
                }

                // Skip whitespace to check for colon
                var checkI = i
                while checkI < end && noComments[checkI].isWhitespace {
                    checkI = noComments.index(after: checkI)
                }

                // Check if this is an unquoted key (identifier followed by colon, after { or ,)
                let isKeyPosition = lastNonSpace == "{" || lastNonSpace == ","
                let followedByColon = checkI < end && noComments[checkI] == ":"

                if isKeyPosition && followedByColon {
                    // It's an unquoted key, quote it
                    result.append("\"\(identifier)\"")
                } else if let converted = convertJSON5Literal(identifier) {
                    // It's a literal (true, false, null, Infinity, NaN)
                    result.append(converted)
                } else {
                    // Unknown identifier, pass through
                    result.append(identifier)
                }
                continue
            }

            // Handle -Infinity specifically (minus followed by Infinity identifier)
            if char == "-" {
                // Check if followed by Infinity
                var checkI = noComments.index(after: i)
                while checkI < end && noComments[checkI].isWhitespace {
                    checkI = noComments.index(after: checkI)
                }
                if checkI < end && isIdentifierStart(noComments[checkI]) {
                    // Collect the identifier
                    var identifier = ""
                    var identEnd = checkI
                    while identEnd < end && isIdentifierContinue(noComments[identEnd]) {
                        identifier.append(noComments[identEnd])
                        identEnd = noComments.index(after: identEnd)
                    }
                    if identifier == "Infinity" {
                        // JSON doesn't support -Infinity, convert to null
                        result.append("null")
                        i = identEnd
                        continue
                    }
                }
            }

            // Handle hexadecimal numbers
            if char == "0" && noComments.index(after: i) < end {
                let nextChar = noComments[noComments.index(after: i)]
                if nextChar == "x" || nextChar == "X" {
                    // Parse hex number
                    var hexStr = "0x"
                    i = noComments.index(after: noComments.index(after: i))
                    while i < end && noComments[i].isHexDigit {
                        hexStr.append(noComments[i])
                        i = noComments.index(after: i)
                    }
                    if let value = Int(hexStr.dropFirst(2), radix: 16) {
                        result.append(String(value))
                    } else {
                        result.append(hexStr)
                    }
                    continue
                }
            }

            // Handle leading decimal point (.5 -> 0.5)
            if char == "." && noComments.index(after: i) < end && noComments[noComments.index(after: i)].isNumber {
                let lastChar = findLastNonWhitespace(in: result)
                if lastChar == nil || lastChar == "," || lastChar == "[" || lastChar == ":" || lastChar == "{" {
                    result.append("0")
                }
            }

            // Handle trailing commas (remove comma before ] or })
            if char == "," {
                // Look ahead for ] or }
                var checkI = noComments.index(after: i)
                while checkI < end && noComments[checkI].isWhitespace {
                    checkI = noComments.index(after: checkI)
                }
                if checkI < end && (noComments[checkI] == "]" || noComments[checkI] == "}") {
                    // Skip this trailing comma
                    i = noComments.index(after: i)
                    continue
                }
            }

            result.append(char)
            i = noComments.index(after: i)
        }

        return result
    }

    /// Find the last non-whitespace character in a string
    private static func findLastNonWhitespace(in string: String) -> Character? {
        for char in string.reversed() {
            if !char.isWhitespace {
                return char
            }
        }
        return nil
    }

    /// Check if character can start an identifier
    private static func isIdentifierStart(_ char: Character) -> Bool {
        return char.isLetter || char == "_" || char == "$"
    }

    /// Check if character can continue an identifier
    private static func isIdentifierContinue(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || char == "_" || char == "$"
    }

    /// Convert JSON5 literals to JSON equivalents
    private static func convertJSON5Literal(_ identifier: String) -> String? {
        switch identifier {
        case "Infinity", "NaN":
            // JSON doesn't support Infinity or NaN, convert to null
            return "null"
        case "true", "false", "null":
            return identifier  // These are valid JSON
        default:
            return nil
        }
    }

    /// Convert Foundation JSON types to LuaValue
    private static func convertJSONToLua(_ value: Any) -> LuaValue {
        if value is NSNull {
            return .nil
        }

        // Check for NSNumber first with robust boolean detection
        // Note: `value as? Bool` would incorrectly match NSNumber(1) as true
        if let number = value as? NSNumber {
            // Use CFBooleanGetTypeID to reliably detect JSON booleans
            // JSONSerialization creates CFBoolean for true/false, not NSNumber
            if CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            return .number(number.doubleValue)
        }

        if let string = value as? String {
            return .string(string)
        }

        if let array = value as? [Any] {
            let luaArray = array.map { convertJSONToLua($0) }
            return .array(luaArray)
        }

        if let dict = value as? [String: Any] {
            var luaDict: [String: LuaValue] = [:]
            for (key, val) in dict {
                luaDict[key] = convertJSONToLua(val)
            }
            return .table(luaDict)
        }

        // Unknown type, return nil
        return .nil
    }
}

// MARK: - JSON Null Sentinel

/// Sentinel type for JSON null values.
///
/// This allows Lua code to distinguish between absent values and explicit nulls.
public struct JSONNull: Equatable, Sendable {
    public init() {}
}

// MARK: - Errors

private enum JSONError: Error, LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let message):
            return "JSON encoding failed: \(message)"
        case .decodingFailed(let message):
            return "JSON decoding failed: \(message)"
        }
    }
}
