//
//  TOMLModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import TOMLKit

/// Swift-backed TOML module for LuaSwift.
///
/// Provides TOML encoding and decoding functionality via the TOMLKit library.
///
/// ## Lua API
///
/// ```lua
/// local toml = require("luaswift.toml")
///
/// -- Decode TOML string to Lua table
/// local tbl = toml.decode([[
/// [database]
/// server = "192.168.1.1"
/// ports = [8001, 8002]
/// enabled = true
/// ]])
///
/// -- Encode Lua table to TOML string
/// local str = toml.encode({
///     database = {
///         server = "192.168.1.1",
///         ports = {8001, 8002},
///         enabled = true
///     }
/// })
/// ```
public struct TOMLModule {
    /// Register the TOML module with a LuaEngine.
    ///
    /// This creates a global table `luaswift` with a nested `toml` table containing:
    /// - `encode(value)`: Encode Lua value to TOML string
    /// - `decode(string)`: Decode TOML string to Lua value
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register encode function
        engine.registerFunction(name: "_luaswift_toml_encode", callback: encodeCallback)

        // Register decode function
        engine.registerFunction(name: "_luaswift_toml_decode", callback: decodeCallback)

        // Set up the luaswift.toml namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                luaswift.toml = {
                    encode = _luaswift_toml_encode,
                    decode = _luaswift_toml_decode
                }
                _luaswift_toml_encode = nil
                _luaswift_toml_decode = nil
                """)
        } catch {
            // Silently fail if setup fails - callbacks are still registered
        }
    }

    // MARK: - Callbacks

    /// Encode callback: converts Lua value to TOML string
    private static func encodeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard !args.isEmpty else {
            throw LuaError.callbackError("toml.encode requires at least one argument")
        }

        let value = args[0]

        // TOML only supports tables as root
        guard case .table = value else {
            throw LuaError.callbackError("toml.encode requires a table as root value")
        }

        do {
            let tomlString = try encode(value: value)
            return .string(tomlString)
        } catch {
            throw LuaError.callbackError("toml.encode error: \(error.localizedDescription)")
        }
    }

    /// Decode callback: converts TOML string to Lua value
    private static func decodeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let tomlString = args.first?.stringValue else {
            throw LuaError.callbackError("toml.decode requires a string argument")
        }

        do {
            return try decode(tomlString: tomlString)
        } catch let error as TOMLParseError {
            throw LuaError.callbackError("toml.decode parse error at line \(error.source.begin.line): \(error.localizedDescription)")
        } catch {
            throw LuaError.callbackError("toml.decode error: \(error.localizedDescription)")
        }
    }

    // MARK: - Encoding

    /// Encode a LuaValue to TOML string
    private static func encode(value: LuaValue) throws -> String {
        let tomlTable = try convertLuaToTOML(value)
        return tomlTable.convert(to: .toml)
    }

    /// Convert LuaValue to TOMLTable
    private static func convertLuaToTOML(_ value: LuaValue) throws -> TOMLTable {
        guard case .table(let dict) = value else {
            throw TOMLError.encodingFailed("TOML requires a table as root value")
        }

        let tomlTable = TOMLTable()
        for (key, val) in dict {
            tomlTable[key] = try convertLuaValueToTOMLValue(val)
        }
        return tomlTable
    }

    /// Convert individual LuaValue to TOML-compatible value
    private static func convertLuaValueToTOMLValue(_ value: LuaValue) throws -> TOMLValueConvertible {
        switch value {
        case .nil:
            // TOML doesn't have null, throw error
            throw TOMLError.encodingFailed("TOML does not support null values")

        case .bool(let b):
            return b

        case .number(let n):
            // Check if it's an integer
            if n.truncatingRemainder(dividingBy: 1) == 0 && n >= Double(Int64.min) && n <= Double(Int64.max) {
                return Int64(n)
            }
            return n

        case .string(let s):
            return s

        case .array(let arr):
            let tomlArray = TOMLArray()
            for item in arr {
                tomlArray.append(try convertLuaValueToTOMLValue(item))
            }
            return tomlArray

        case .table(let dict):
            let nestedTable = TOMLTable()
            for (key, val) in dict {
                nestedTable[key] = try convertLuaValueToTOMLValue(val)
            }
            return nestedTable

        case .complex(let re, let im):
            // TOML doesn't have native complex support, encode as table
            let complexTable = TOMLTable()
            complexTable["__type"] = "complex"
            complexTable["re"] = re
            complexTable["im"] = im
            return complexTable
        }
    }

    // MARK: - Decoding

    /// Decode a TOML string to LuaValue
    private static func decode(tomlString: String) throws -> LuaValue {
        let tomlTable = try TOMLTable(string: tomlString)
        return convertTOMLToLua(tomlTable)
    }

    /// Convert TOMLTable to LuaValue
    private static func convertTOMLToLua(_ table: TOMLTable) -> LuaValue {
        var luaDict: [String: LuaValue] = [:]
        for (key, value) in table {
            luaDict[key] = convertTOMLValueToLua(value)
        }
        return .table(luaDict)
    }

    /// Convert TOML value to LuaValue
    private static func convertTOMLValueToLua(_ value: TOMLValueConvertible) -> LuaValue {
        // Get the underlying TOML type
        let tomlValue = value.tomlValue

        switch tomlValue.type {
        case .bool:
            if let b = tomlValue.bool {
                return .bool(b)
            }
        case .int:
            if let i = tomlValue.int {
                return .number(Double(i))
            }
        case .double:
            if let d = tomlValue.double {
                return .number(d)
            }
        case .string:
            if let s = tomlValue.string {
                return .string(s)
            }
        case .array:
            if let arr = tomlValue.array {
                var luaArray: [LuaValue] = []
                for item in arr {
                    luaArray.append(convertTOMLValueToLua(item))
                }
                return .array(luaArray)
            }
        case .table:
            if let tbl = tomlValue.table {
                return convertTOMLToLua(tbl)
            }
        case .date:
            if let d = tomlValue.date {
                return .string(String(describing: d))
            }
        case .time:
            if let t = tomlValue.time {
                return .string(String(describing: t))
            }
        case .dateTime:
            if let dt = tomlValue.dateTime {
                return .string(String(describing: dt))
            }
        }

        // Fallback
        return .nil
    }
}

// MARK: - Errors

private enum TOMLError: Error, LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let message):
            return "TOML encoding failed: \(message)"
        case .decodingFailed(let message):
            return "TOML decoding failed: \(message)"
        }
    }
}
