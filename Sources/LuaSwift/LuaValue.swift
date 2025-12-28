//
//  LuaValue.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Represents a Lua value in Swift.
///
/// This enum provides a type-safe representation of all Lua value types,
/// enabling seamless conversion between Lua and Swift.
public enum LuaValue: Equatable, Sendable {
    /// A string value
    case string(String)

    /// A numeric value (Lua numbers are always doubles)
    case number(Double)

    /// A boolean value
    case bool(Bool)

    /// A table with string keys (dictionary)
    case table([String: LuaValue])

    /// A table with integer keys (array)
    case array([LuaValue])

    /// Nil value
    case `nil`

    // MARK: - Convenience Accessors

    /// Returns the string value if this is a string, nil otherwise.
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    /// Returns the numeric value if this is a number, nil otherwise.
    public var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    /// Returns the integer value if this is a number, nil otherwise.
    public var intValue: Int? {
        if case .number(let value) = self { return Int(value) }
        return nil
    }

    /// Returns the boolean value if this is a bool, nil otherwise.
    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    /// Returns the table value if this is a table, nil otherwise.
    public var tableValue: [String: LuaValue]? {
        if case .table(let value) = self { return value }
        return nil
    }

    /// Returns the array value if this is an array, nil otherwise.
    public var arrayValue: [LuaValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    /// Returns true if this value is nil.
    public var isNil: Bool {
        if case .nil = self { return true }
        return false
    }

    /// Returns the value as a string, converting if necessary.
    public var asString: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(value))
            }
            return String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .table:
            return "[table]"
        case .array:
            return "[array]"
        case .nil:
            return ""
        }
    }

    /// Returns the Lua truthiness of this value.
    /// In Lua, only nil and false are falsy; everything else is truthy.
    public var isTruthy: Bool {
        switch self {
        case .nil:
            return false
        case .bool(let value):
            return value
        default:
            return true
        }
    }
}

// MARK: - ExpressibleBy Protocols

extension LuaValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension LuaValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension LuaValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension LuaValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension LuaValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: LuaValue...) {
        self = .array(elements)
    }
}

extension LuaValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, LuaValue)...) {
        self = .table(Dictionary(uniqueKeysWithValues: elements))
    }
}

// MARK: - CustomStringConvertible

extension LuaValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string(let value):
            return "\"\(value)\""
        case .number(let value):
            return String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .table(let dict):
            let pairs = dict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return "{\(pairs)}"
        case .array(let arr):
            let items = arr.map { $0.description }.joined(separator: ", ")
            return "[\(items)]"
        case .nil:
            return "nil"
        }
    }
}
