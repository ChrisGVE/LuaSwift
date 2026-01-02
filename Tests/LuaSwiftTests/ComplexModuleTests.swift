//
//  ComplexModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class ComplexModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        ComplexModule.register(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Basic Creation Tests

    func testComplexCreation() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(3, 4)
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, 3, accuracy: 1e-10)
        XCTAssertEqual(im, 4, accuracy: 1e-10)
    }

    func testComplexFromPolar() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.from_polar(5, math.pi / 4)
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, 5 * cos(Double.pi / 4), accuracy: 1e-10)
        XCTAssertEqual(im, 5 * sin(Double.pi / 4), accuracy: 1e-10)
    }

    func testComplexConstantI() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            return {re = complex.i.re, im = complex.i.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, 0, accuracy: 1e-10)
        XCTAssertEqual(im, 1, accuracy: 1e-10)
    }

    // MARK: - Arithmetic Tests

    func testComplexAddition() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z1 = complex.new(3, 4)
            local z2 = complex.new(1, 2)
            local sum = z1 + z2
            return {re = sum.re, im = sum.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, 4, accuracy: 1e-10)
        XCTAssertEqual(im, 6, accuracy: 1e-10)
    }

    func testComplexSubtraction() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z1 = complex.new(3, 4)
            local z2 = complex.new(1, 2)
            local diff = z1 - z2
            return {re = diff.re, im = diff.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, 2, accuracy: 1e-10)
        XCTAssertEqual(im, 2, accuracy: 1e-10)
    }

    func testComplexMultiplication() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z1 = complex.new(3, 4)
            local z2 = complex.new(1, 2)
            local prod = z1 * z2
            return {re = prod.re, im = prod.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // (3 + 4i)(1 + 2i) = 3 + 6i + 4i + 8i² = 3 + 10i - 8 = -5 + 10i
        XCTAssertEqual(re, -5, accuracy: 1e-10)
        XCTAssertEqual(im, 10, accuracy: 1e-10)
    }

    func testComplexDivision() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z1 = complex.new(3, 4)
            local z2 = complex.new(1, 2)
            local quot = z1 / z2
            return {re = quot.re, im = quot.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // (3 + 4i) / (1 + 2i) = (3 + 4i)(1 - 2i) / (1 + 4) = (3 - 6i + 4i - 8i²) / 5 = (11 - 2i) / 5
        XCTAssertEqual(re, 11.0 / 5.0, accuracy: 1e-10)
        XCTAssertEqual(im, -2.0 / 5.0, accuracy: 1e-10)
    }

    func testComplexNegation() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(3, 4)
            local neg = -z
            return {re = neg.re, im = neg.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, -3, accuracy: 1e-10)
        XCTAssertEqual(im, -4, accuracy: 1e-10)
    }

    // MARK: - Properties Tests

    func testComplexAbsolute() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(3, 4)
            return z:abs()
        """)

        guard let abs = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(abs, 5, accuracy: 1e-10)
    }

    func testComplexArgument() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(1, 1)
            return z:arg()
        """)

        guard let arg = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(arg, Double.pi / 4, accuracy: 1e-10)
    }

    func testComplexConjugate() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(3, 4)
            local conj = z:conj()
            return {re = conj.re, im = conj.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, 3, accuracy: 1e-10)
        XCTAssertEqual(im, -4, accuracy: 1e-10)
    }

    func testComplexPolar() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(3, 4)
            return z:polar()
        """)

        guard let array = result.arrayValue,
              array.count == 2,
              let r = array[0].numberValue,
              let theta = array[1].numberValue else {
            XCTFail("Expected array with 2 numbers")
            return
        }

        XCTAssertEqual(r, 5, accuracy: 1e-10)
        XCTAssertEqual(theta, atan2(4, 3), accuracy: 1e-10)
    }

    // MARK: - Power Tests

    func testComplexPower() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(1, 1)
            local z2 = z:pow(2)
            return {re = z2.re, im = z2.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // (1 + i)² = 1 + 2i + i² = 1 + 2i - 1 = 2i
        XCTAssertEqual(re, 0, accuracy: 1e-10)
        XCTAssertEqual(im, 2, accuracy: 1e-10)
    }

    func testComplexDeMoivre() throws {
        // Test De Moivre's formula: (cos θ + i sin θ)ⁿ = cos(nθ) + i sin(nθ)
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local theta = math.pi / 6
            local z = complex.new(math.cos(theta), math.sin(theta))
            local z5 = z:pow(5)
            return {re = z5.re, im = z5.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        let expectedTheta = 5 * Double.pi / 6
        XCTAssertEqual(re, cos(expectedTheta), accuracy: 1e-10)
        XCTAssertEqual(im, sin(expectedTheta), accuracy: 1e-10)
    }

    func testComplexSqrt() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(0, 1)  -- i
            local sqrt_z = z:sqrt()
            return {re = sqrt_z.re, im = sqrt_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // sqrt(i) = sqrt(2)/2 + i*sqrt(2)/2
        let expected = sqrt(2) / 2
        XCTAssertEqual(re, expected, accuracy: 1e-10)
        XCTAssertEqual(im, expected, accuracy: 1e-10)
    }

    // MARK: - Exponential and Logarithmic Tests

    func testComplexExp() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(0, math.pi)
            local exp_z = z:exp()
            return {re = exp_z.re, im = exp_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // exp(i*π) = -1
        XCTAssertEqual(re, -1, accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexLog() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(1, 0)
            local log_z = z:log()
            return {re = log_z.re, im = log_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // log(1) = 0
        XCTAssertEqual(re, 0, accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    // MARK: - Trigonometric Tests

    func testComplexSin() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(0, 1)  -- i
            local sin_z = z:sin()
            return {re = sin_z.re, im = sin_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // sin(i) = i*sinh(1)
        XCTAssertEqual(re, 0, accuracy: 1e-10)
        XCTAssertEqual(im, sinh(1), accuracy: 1e-10)
    }

    func testComplexCos() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(0, 1)  -- i
            local cos_z = z:cos()
            return {re = cos_z.re, im = cos_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // cos(i) = cosh(1)
        XCTAssertEqual(re, cosh(1), accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexTan() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(1, 0)
            local tan_z = z:tan()
            return {re = tan_z.re, im = tan_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // tan(1) is real
        XCTAssertEqual(re, tan(1), accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexAsin() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(0.5, 0)
            local asin_z = z:asin()
            return {re = asin_z.re, im = asin_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // asin(0.5) = π/6
        XCTAssertEqual(re, Double.pi / 6, accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexAcos() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(0.5, 0)
            local acos_z = z:acos()
            return {re = acos_z.re, im = acos_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // acos(0.5) = π/3
        XCTAssertEqual(re, Double.pi / 3, accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexAtan() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(1, 0)
            local atan_z = z:atan()
            return {re = atan_z.re, im = atan_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // atan(1) = π/4
        XCTAssertEqual(re, Double.pi / 4, accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    // MARK: - Hyperbolic Tests

    func testComplexSinh() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(1, 0)
            local sinh_z = z:sinh()
            return {re = sinh_z.re, im = sinh_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // sinh(1) is real
        XCTAssertEqual(re, sinh(1), accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexCosh() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(1, 0)
            local cosh_z = z:cosh()
            return {re = cosh_z.re, im = cosh_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // cosh(1) is real
        XCTAssertEqual(re, cosh(1), accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexTanh() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(1, 0)
            local tanh_z = z:tanh()
            return {re = tanh_z.re, im = tanh_z.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        // tanh(1) is real
        XCTAssertEqual(re, tanh(1), accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    // MARK: - Integration Tests

    func testComplexMixedOperations() throws {
        // Test: i² = -1
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local i = complex.i
            local i2 = i * i
            return {re = i2.re, im = i2.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, -1, accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexEulersFormula() throws {
        // Test: e^(iπ) + 1 = 0
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z = complex.new(0, math.pi)
            local exp_z = z:exp()
            local one = complex.new(1, 0)
            local sum = exp_z + one
            return {re = sum.re, im = sum.im}
        """)

        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table with re and im")
            return
        }

        XCTAssertEqual(re, 0, accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testComplexToString() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z1 = complex.new(3, 4)
            local z2 = complex.new(3, -4)
            return {pos = tostring(z1), neg = tostring(z2)}
        """)

        guard let table = result.tableValue,
              let pos = table["pos"]?.stringValue,
              let neg = table["neg"]?.stringValue else {
            XCTFail("Expected table with pos and neg strings")
            return
        }

        XCTAssertTrue(pos.contains("3.0000"))
        XCTAssertTrue(pos.contains("4.0000"))
        XCTAssertTrue(pos.contains("+"))

        XCTAssertTrue(neg.contains("3.0000"))
        XCTAssertTrue(neg.contains("-4.0000"))
    }

    func testComplexEquality() throws {
        let result = try engine.evaluate("""
            local complex = require("luaswift.complex")
            local z1 = complex.new(3, 4)
            local z2 = complex.new(3, 4)
            local z3 = complex.new(3, 5)
            return {eq = z1 == z2, neq = z1 == z3}
        """)

        guard let table = result.tableValue,
              let eq = table["eq"]?.boolValue,
              let neq = table["neq"]?.boolValue else {
            XCTFail("Expected table with eq and neq booleans")
            return
        }

        XCTAssertTrue(eq)
        XCTAssertFalse(neq)
    }
}
