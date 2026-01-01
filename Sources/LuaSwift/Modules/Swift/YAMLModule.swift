//
//  YAMLModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Yams

/// Swift-backed YAML module for LuaSwift.
///
/// Provides YAML encoding and decoding functionality via the Yams library.
///
/// ## Lua API
///
/// ```lua
/// local yaml = require("luaswift.yaml")
///
/// -- Decode YAML string to Lua table
/// local tbl = yaml.decode("name: John\nage: 30")
///
/// -- Encode Lua table to YAML string
/// local str = yaml.encode({name="John", age=30})
///
/// -- Parse all documents from multi-document YAML
/// local docs = yaml.decode_all("---\nfoo: 1\n---\nbar: 2")
///
/// -- Encode multiple documents
/// local str = yaml.encode_all({{foo=1}, {bar=2}})
/// ```
public struct YAMLModule {
    /// Register the YAML module with a LuaEngine.
    ///
    /// This creates a global table `luaswift` with a nested `yaml` table containing:
    /// - `encode(value)`: Encode Lua value to YAML string
    /// - `decode(string)`: Decode YAML string to Lua value
    /// - `encode_all(array)`: Encode array of documents to multi-document YAML
    /// - `decode_all(string)`: Decode multi-document YAML to array of values
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register encode function
        engine.registerFunction(name: "_luaswift_yaml_encode", callback: encodeCallback)

        // Register decode function
        engine.registerFunction(name: "_luaswift_yaml_decode", callback: decodeCallback)

        // Register encode_all function
        engine.registerFunction(name: "_luaswift_yaml_encode_all", callback: encodeAllCallback)

        // Register decode_all function
        engine.registerFunction(name: "_luaswift_yaml_decode_all", callback: decodeAllCallback)

        // Set up the luaswift.yaml namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                luaswift.yaml = {
                    encode = _luaswift_yaml_encode,
                    decode = _luaswift_yaml_decode,
                    encode_all = _luaswift_yaml_encode_all,
                    decode_all = _luaswift_yaml_decode_all
                }
                _luaswift_yaml_encode = nil
                _luaswift_yaml_decode = nil
                _luaswift_yaml_encode_all = nil
                _luaswift_yaml_decode_all = nil
                """)
        } catch {
            // Silently fail if setup fails - callbacks are still registered
        }
    }

    // MARK: - Callbacks

    /// Encode callback: converts Lua value to YAML string
    private static func encodeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard !args.isEmpty else {
            throw LuaError.callbackError("yaml.encode requires at least one argument")
        }

        let value = args[0]

        do {
            let yamlString = try encode(value: value)
            return .string(yamlString)
        } catch {
            throw LuaError.callbackError("yaml.encode error: \(error.localizedDescription)")
        }
    }

    /// Decode callback: converts YAML string to Lua value
    private static func decodeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let yamlString = args.first?.stringValue else {
            throw LuaError.callbackError("yaml.decode requires a string argument")
        }

        do {
            return try decode(yamlString: yamlString)
        } catch {
            throw LuaError.callbackError("yaml.decode error: \(error.localizedDescription)")
        }
    }

    /// Encode all callback: converts array of Lua values to multi-document YAML string
    private static func encodeAllCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let documents = args.first?.arrayValue else {
            throw LuaError.callbackError("yaml.encode_all requires an array argument")
        }

        do {
            var yamlStrings: [String] = []
            for doc in documents {
                let yamlString = try encode(value: doc)
                yamlStrings.append(yamlString)
            }
            let result = yamlStrings.map { "---\n\($0)" }.joined()
            return .string(result)
        } catch {
            throw LuaError.callbackError("yaml.encode_all error: \(error.localizedDescription)")
        }
    }

    /// Decode all callback: converts multi-document YAML string to array of Lua values
    private static func decodeAllCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let yamlString = args.first?.stringValue else {
            throw LuaError.callbackError("yaml.decode_all requires a string argument")
        }

        do {
            return try decodeAll(yamlString: yamlString)
        } catch {
            throw LuaError.callbackError("yaml.decode_all error: \(error.localizedDescription)")
        }
    }

    // MARK: - Encoding

    /// Encode a LuaValue to YAML string
    private static func encode(value: LuaValue) throws -> String {
        let yamlValue = convertLuaToYAML(value)
        return try Yams.dump(object: yamlValue)
    }

    /// Convert LuaValue to Foundation types for YAML serialization
    private static func convertLuaToYAML(_ value: LuaValue) -> Any? {
        switch value {
        case .nil:
            return NSNull()

        case .bool(let b):
            return b

        case .number(let n):
            // Check if it's an integer
            if n.truncatingRemainder(dividingBy: 1) == 0 && n >= Double(Int.min) && n <= Double(Int.max) {
                return Int(n)
            }
            return n

        case .string(let s):
            return s

        case .array(let arr):
            return arr.map { convertLuaToYAML($0) }

        case .table(let dict):
            var yamlDict: [String: Any?] = [:]
            for (key, val) in dict {
                yamlDict[key] = convertLuaToYAML(val)
            }
            return yamlDict
        }
    }

    // MARK: - Decoding

    /// Decode a YAML string to LuaValue
    private static func decode(yamlString: String) throws -> LuaValue {
        guard let yamlObject = try Yams.load(yaml: yamlString) else {
            return .nil
        }
        return convertYAMLToLua(yamlObject)
    }

    /// Decode a multi-document YAML string to array of LuaValues
    private static func decodeAll(yamlString: String) throws -> LuaValue {
        var documents: [LuaValue] = []
        for document in try Yams.load_all(yaml: yamlString) {
            documents.append(convertYAMLToLua(document))
        }
        return .array(documents)
    }

    /// Convert YAML types to LuaValue
    private static func convertYAMLToLua(_ value: Any) -> LuaValue {
        if value is NSNull {
            return .nil
        }

        // Check for NSNumber with robust boolean detection
        if let number = value as? NSNumber {
            if CFGetTypeID(number as CFTypeRef) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            return .number(number.doubleValue)
        }

        if let bool = value as? Bool {
            return .bool(bool)
        }

        if let int = value as? Int {
            return .number(Double(int))
        }

        if let double = value as? Double {
            return .number(double)
        }

        if let string = value as? String {
            return .string(string)
        }

        if let array = value as? [Any] {
            let luaArray = array.map { convertYAMLToLua($0) }
            return .array(luaArray)
        }

        if let dict = value as? [String: Any] {
            var luaDict: [String: LuaValue] = [:]
            for (key, val) in dict {
                luaDict[key] = convertYAMLToLua(val)
            }
            return .table(luaDict)
        }

        // For Node types from Yams
        if let node = value as? Yams.Node {
            return convertNodeToLua(node)
        }

        // Unknown type, return nil
        return .nil
    }

    /// Convert Yams Node to LuaValue
    private static func convertNodeToLua(_ node: Yams.Node) -> LuaValue {
        switch node {
        case .scalar(let scalar):
            // Try to parse as different types
            if let bool = Bool(scalar.string) {
                return .bool(bool)
            }
            if let int = Int(scalar.string) {
                return .number(Double(int))
            }
            if let double = Double(scalar.string) {
                return .number(double)
            }
            if scalar.string == "null" || scalar.string == "~" || scalar.string.isEmpty {
                return .nil
            }
            return .string(scalar.string)

        case .sequence(let sequence):
            let luaArray = sequence.map { convertNodeToLua($0) }
            return .array(luaArray)

        case .mapping(let mapping):
            var luaDict: [String: LuaValue] = [:]
            for (key, val) in mapping {
                if case .scalar(let keyScalar) = key {
                    luaDict[keyScalar.string] = convertNodeToLua(val)
                }
            }
            return .table(luaDict)

        case .alias:
            // Aliases are resolved by Yams during parsing, return nil if encountered
            return .nil
        }
    }
}
