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
    /// - `decode(string)`: Decode JSON string to Lua value
    /// - `null`: Sentinel value for JSON null
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register encode function
        engine.registerFunction(name: "_luaswift_json_encode", callback: encodeCallback)

        // Register decode function
        engine.registerFunction(name: "_luaswift_json_decode", callback: decodeCallback)

        // Set up the luaswift.json namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                luaswift.json = {
                    encode = _luaswift_json_encode,
                    decode = _luaswift_json_decode,
                    null = setmetatable({}, {
                        __tostring = function() return "null" end,
                        __type = "json.null"
                    })
                }
                _luaswift_json_encode = nil
                _luaswift_json_decode = nil
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

        do {
            return try decode(jsonString: jsonString)
        } catch {
            throw LuaError.callbackError("json.decode error: \(error.localizedDescription)")
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

    /// Convert Foundation JSON types to LuaValue
    private static func convertJSONToLua(_ value: Any) -> LuaValue {
        if value is NSNull {
            return .nil
        }

        if let bool = value as? Bool {
            return .bool(bool)
        }

        if let number = value as? NSNumber {
            // NSNumber can represent both integers and floats
            // Check if it's a boolean first (NSNumber can also represent Bool)
            let objCType = String(cString: number.objCType)
            if objCType == "c" || objCType == "B" {
                // Boolean type
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
