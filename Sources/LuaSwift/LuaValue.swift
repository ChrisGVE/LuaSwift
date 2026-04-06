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

    /// A complex number value.
    ///
    /// Complex numbers have a real and imaginary component, both stored
    /// as double-precision floating-point. In Lua, complex numbers are
    /// represented as tables with `re` and `im` fields plus a metatable
    /// for arithmetic operations.
    ///
    /// ```swift
    /// let z = LuaValue.complex(re: 3.0, im: 4.0)  // 3+4i
    /// ```
    case complex(re: Double, im: Double)

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
    ///
    /// - Important: **Numeric Key Conversion**: When Lua tables are converted
    ///   to Swift, numeric keys are cast to `Int`. This has two implications:
    ///   1. **Fractional keys are truncated**: A Lua key of `1.5` becomes `1`
    ///   2. **Large keys may overflow**: Keys outside `Int` range may wrap
    ///
    ///   If you need to preserve non-integer numeric keys, use string keys
    ///   in your Lua code (e.g., `t["1.5"] = value` instead of `t[1.5] = value`).
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

    /// A Lua function reference.
    ///
    /// Stores a reference to a Lua function in the registry. This allows
    /// Swift callbacks to receive and call Lua functions passed as arguments.
    /// The reference is an index in the Lua registry.
    ///
    /// - Important: This case should only be created by `LuaEngine` when converting
    ///   from the Lua stack. Use ``LuaEngine/callLuaFunction(ref:args:)`` to call it.
    ///
    /// ## Memory Management
    ///
    /// Function references must be explicitly released when no longer needed to
    /// prevent memory leaks. Use one of these approaches:
    ///
    /// - **Manual release**: Call ``LuaEngine/releaseLuaFunction(ref:)`` when done
    /// - **Auto-release**: Use ``LuaEngine/withLuaFunction(_:args:action:)`` or
    ///   ``LuaEngine/callAndReleaseLuaFunction(_:args:)`` for one-shot calls
    ///
    /// ```swift
    /// // Manual (retain for later use)
    /// guard case .luaFunction(let ref) = funcValue else { return }
    /// // ... use ref multiple times ...
    /// engine.releaseLuaFunction(ref: ref)
    ///
    /// // Auto-release (one-shot call)
    /// let result = try engine.callAndReleaseLuaFunction(funcValue, args: [.number(1)])
    /// ```
    case luaFunction(Int32)

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

    /// Returns the integer value if this is a number with no fractional part, nil otherwise.
    ///
    /// Returns `nil` if:
    /// - The value is not a number
    /// - The number has a fractional component (e.g., 1.5)
    ///
    /// ```swift
    /// LuaValue.number(42.0).intValue  // 42
    /// LuaValue.number(1.5).intValue   // nil (has fractional part)
    /// LuaValue.number(-3.0).intValue  // -3
    /// ```
    public var intValue: Int? {
        guard case .number(let value) = self else { return nil }
        // Return nil if the number has a fractional component
        guard value.truncatingRemainder(dividingBy: 1) == 0 else { return nil }
        return Int(value)
    }

    /// Returns the complex value if this is a complex number, nil otherwise.
    ///
    /// ```swift
    /// let z = LuaValue.complex(re: 3.0, im: 4.0)
    /// if let (re, im) = z.complexValue {
    ///     print("Real: \(re), Imaginary: \(im)")
    /// }
    /// ```
    public var complexValue: (re: Double, im: Double)? {
        if case .complex(let re, let im) = self { return (re, im) }
        return nil
    }

    /// Returns true if this value is a complex number.
    public var isComplex: Bool {
        if case .complex = self { return true }
        return false
    }

    /// Returns true if this value is a scalar (real number or complex number).
    ///
    /// Scalars are the building blocks for vectors and arrays.
    public var isScalar: Bool {
        switch self {
        case .number, .complex:
            return true
        default:
            return false
        }
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
        case .complex(let re, let im):
            if im >= 0 {
                return "\(re)+\(im)i"
            } else {
                return "\(re)\(im)i"
            }
        case .bool(let value):
            return value ? "true" : "false"
        case .table:
            return "[table]"
        case .array:
            return "[array]"
        case .nil:
            return ""
        case .luaFunction(let ref):
            return "[function:\(ref)]"
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
        case .complex(let re, let im):
            if im >= 0 {
                return "\(re)+\(im)i"
            } else {
                return "\(re)\(im)i"
            }
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
        case .luaFunction(let ref):
            return "function:\(ref)"
        }
    }
}
