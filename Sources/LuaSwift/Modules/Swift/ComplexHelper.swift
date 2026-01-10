//
//  ComplexHelper.swift
//  LuaSwift
//
//  Created by Claude on 2026-01-10.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Shared complex number utilities used across math modules.
///
/// This enum provides helper functions for detecting, extracting, and creating
/// complex numbers in Lua format. Used by MathXModule, SpecialModule, and other
/// modules that need polymorphic dispatch on real/complex inputs.
///
/// ## Complex Number Representation
///
/// Complex numbers are represented in Lua as tables with `re` and `im` keys:
/// ```lua
/// local z = {re = 3.0, im = 4.0}  -- represents 3 + 4i
/// ```
///
/// ## Usage
///
/// ```swift
/// // Check if a LuaValue is complex
/// if ComplexHelper.isComplex(arg) {
///     guard let (a, b) = ComplexHelper.toComplex(arg) else { ... }
///     // Perform complex computation
///     let result = ComplexHelper.toLua(resultRe, resultIm)
/// }
/// ```
public enum ComplexHelper {

    // MARK: - Type Detection

    /// Check if a Lua value represents a complex number.
    ///
    /// A value is considered complex if it's a table with both `re` and `im` keys
    /// containing numeric values.
    ///
    /// - Parameter value: The Lua value to check
    /// - Returns: `true` if the value is a complex number table
    public static func isComplex(_ value: LuaValue) -> Bool {
        guard let table = value.tableValue else { return false }
        return table["re"]?.numberValue != nil && table["im"]?.numberValue != nil
    }

    // MARK: - Extraction

    /// Extract complex number components from a Lua value.
    ///
    /// This function handles both complex tables and real scalars:
    /// - Complex table `{re=a, im=b}` returns `(a, b)`
    /// - Real scalar `x` returns `(x, 0)`
    /// - Invalid input returns `nil`
    ///
    /// - Parameter value: The Lua value to extract from
    /// - Returns: A tuple of (real, imaginary) parts, or nil if invalid
    public static func toComplex(_ value: LuaValue) -> (re: Double, im: Double)? {
        // Try complex table first
        if let table = value.tableValue,
           let re = table["re"]?.numberValue,
           let im = table["im"]?.numberValue {
            return (re, im)
        }
        // Try real scalar (treat as complex with im=0)
        if let x = value.numberValue {
            return (x, 0)
        }
        return nil
    }

    // MARK: - Creation

    /// Create a Lua complex number table from real and imaginary parts.
    ///
    /// - Parameters:
    ///   - re: The real part
    ///   - im: The imaginary part
    /// - Returns: A Lua table value with `re` and `im` keys
    public static func toLua(_ re: Double, _ im: Double) -> LuaValue {
        return .table(["re": .number(re), "im": .number(im)])
    }

    /// Create an appropriate Lua result, returning real if imaginary is negligible.
    ///
    /// This function returns a real number if the imaginary part is smaller than
    /// the given tolerance, otherwise returns a complex table. Useful for functions
    /// like sqrt where sqrt(4) should return 2 (real) not 2+0i (complex).
    ///
    /// - Parameters:
    ///   - re: The real part
    ///   - im: The imaginary part
    ///   - tolerance: Maximum absolute value of imaginary part to consider negligible (default: 1e-15)
    /// - Returns: A real number if `|im| < tolerance`, otherwise a complex table
    public static func toResult(_ re: Double, _ im: Double, tolerance: Double = 1e-15) -> LuaValue {
        if abs(im) < tolerance {
            return .number(re)
        }
        return toLua(re, im)
    }

    // MARK: - Complex Arithmetic Helpers

    /// Compute complex multiplication: (a + bi) * (c + di)
    ///
    /// - Parameters:
    ///   - a: Real part of first operand
    ///   - b: Imaginary part of first operand
    ///   - c: Real part of second operand
    ///   - d: Imaginary part of second operand
    /// - Returns: Tuple of (real, imaginary) parts of the product
    public static func multiply(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> (re: Double, im: Double) {
        // (a + bi)(c + di) = (ac - bd) + (ad + bc)i
        return (a * c - b * d, a * d + b * c)
    }

    /// Compute complex division: (a + bi) / (c + di)
    ///
    /// - Parameters:
    ///   - a: Real part of numerator
    ///   - b: Imaginary part of numerator
    ///   - c: Real part of denominator
    ///   - d: Imaginary part of denominator
    /// - Returns: Tuple of (real, imaginary) parts of the quotient, or nil if denominator is zero
    public static func divide(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> (re: Double, im: Double)? {
        // (a + bi)/(c + di) = [(ac + bd) + (bc - ad)i] / (c² + d²)
        let denom = c * c + d * d
        guard denom != 0 else { return nil }
        return ((a * c + b * d) / denom, (b * c - a * d) / denom)
    }

    /// Compute complex square root using polar form.
    ///
    /// Returns the principal square root (non-negative real part when possible).
    ///
    /// - Parameters:
    ///   - a: Real part
    ///   - b: Imaginary part
    /// - Returns: Tuple of (real, imaginary) parts of sqrt(a + bi)
    public static func sqrt(_ a: Double, _ b: Double) -> (re: Double, im: Double) {
        let r = hypot(a, b)
        let theta = atan2(b, a)
        let sqrtR = Darwin.sqrt(r)
        let halfTheta = theta / 2
        return (sqrtR * cos(halfTheta), sqrtR * sin(halfTheta))
    }

    /// Compute complex natural logarithm.
    ///
    /// log(a + bi) = log(|z|) + i * arg(z)
    ///
    /// - Parameters:
    ///   - a: Real part
    ///   - b: Imaginary part
    /// - Returns: Tuple of (real, imaginary) parts of log(a + bi), or nil if input is zero
    public static func log(_ a: Double, _ b: Double) -> (re: Double, im: Double)? {
        let r = hypot(a, b)
        guard r > 0 else { return nil }
        let theta = atan2(b, a)
        return (Darwin.log(r), theta)
    }

    /// Compute complex exponential.
    ///
    /// exp(a + bi) = exp(a) * (cos(b) + i*sin(b))
    ///
    /// - Parameters:
    ///   - a: Real part
    ///   - b: Imaginary part
    /// - Returns: Tuple of (real, imaginary) parts of exp(a + bi)
    public static func exp(_ a: Double, _ b: Double) -> (re: Double, im: Double) {
        let expA = Darwin.exp(a)
        return (expA * cos(b), expA * sin(b))
    }

    /// Compute complex power: z^n where n is real.
    ///
    /// Uses De Moivre's formula: z^n = r^n * (cos(n*theta) + i*sin(n*theta))
    ///
    /// - Parameters:
    ///   - a: Real part of base
    ///   - b: Imaginary part of base
    ///   - n: Real exponent
    /// - Returns: Tuple of (real, imaginary) parts of (a + bi)^n
    public static func pow(_ a: Double, _ b: Double, _ n: Double) -> (re: Double, im: Double) {
        let r = hypot(a, b)
        let theta = atan2(b, a)
        let rn = Darwin.pow(r, n)
        let ntheta = n * theta
        return (rn * cos(ntheta), rn * sin(ntheta))
    }
}
