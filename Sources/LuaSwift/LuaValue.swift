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
/// `LuaValue` provides a type-safe representation of all Lua value types,
/// enabling seamless bidirectional conversion between Lua and Swift.
///
/// ## Overview
///
/// Lua has a small set of fundamental types: nil, boolean, number, string,
/// and table. This enum maps these types to Swift, with tables represented
/// as either dictionaries (``table(_:)``) or arrays (``array(_:)``).
///
/// ## Creating Values
///
/// You can create values explicitly or using Swift literals:
///
/// ```swift
/// // Explicit construction
/// let str = LuaValue.string("hello")
/// let num = LuaValue.number(42.5)
/// let flag = LuaValue.bool(true)
///
/// // Using Swift literals
/// let str2: LuaValue = "hello"
/// let num2: LuaValue = 42
/// let flag2: LuaValue = true
/// let arr: LuaValue = [1, 2, 3]
/// let dict: LuaValue = ["name": "Alice", "age": 30]
/// ```
///
/// ## Extracting Values
///
/// Use the convenience accessors to extract typed values:
///
/// ```swift
/// let result = try engine.evaluate("return 42")
///
/// if let num = result.numberValue {
///     print("Got number: \(num)")
/// }
///
/// // Or use pattern matching
/// switch result {
/// case .number(let n): print("Number: \(n)")
/// case .string(let s): print("String: \(s)")
/// default: print("Other type")
/// }
/// ```
///
/// ## Lua Truthiness
///
/// In Lua, only `nil` and `false` are considered falsy. Use ``isTruthy``
/// to check a value's boolean interpretation:
///
/// ```swift
/// LuaValue.nil.isTruthy       // false
/// LuaValue.bool(false).isTruthy  // false
/// LuaValue.number(0).isTruthy    // true (unlike some languages!)
/// LuaValue.string("").isTruthy   // true
/// ```
///
/// ## Topics
///
/// ### Value Cases
/// - ``string(_:)``
/// - ``number(_:)``
/// - ``bool(_:)``
/// - ``table(_:)``
/// - ``array(_:)``
/// - ``nil``
///
/// ### Extracting Values
/// - ``stringValue``
/// - ``numberValue``
/// - ``intValue``
/// - ``boolValue``
/// - ``tableValue``
/// - ``arrayValue``
///
/// ### Type Checking
/// - ``isNil``
/// - ``isTruthy``
public enum LuaValue: Equatable, Sendable {
    /// A string value.
    ///
    /// Lua strings can contain any bytes, including embedded nulls.
    /// In Swift, these are represented as UTF-8 `String` values.
    case string(String)

    /// A numeric value.
    ///
    /// Lua numbers are represented as double-precision floating-point.
    /// Integer values are stored as doubles but can be extracted with
    /// ``intValue`` if they have no fractional part.
    case number(Double)

    /// A boolean value.
    ///
    /// Note that in Lua, only `nil` and `false` are considered falsy.
    /// The number `0` and empty string `""` are truthy (unlike some languages).
    case bool(Bool)

    /// A table with string keys (dictionary).
    ///
    /// Represents a Lua table that has string keys. This is used when
    /// the table contains at least one non-integer key or when the
    /// integer keys don't form a contiguous sequence starting at 1.
    case table([String: LuaValue])

    /// A table with integer keys (array).
    ///
    /// Represents a Lua table with contiguous integer keys starting at 1.
    /// Lua arrays are 1-indexed, but the Swift array uses 0-based indexing.
    case array([LuaValue])

    /// Nil value.
    ///
    /// Represents Lua's `nil`, which indicates the absence of a value.
    /// Variables set to `nil` are effectively deleted from tables.
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
