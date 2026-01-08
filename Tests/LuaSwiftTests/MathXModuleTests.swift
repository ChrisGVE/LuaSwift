//
//  MathXModuleTests.swift
//  LuaSwiftTests
//
//  Created by Claude on 2026-01-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class MathXModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installModules(in: engine)
            try engine.run("luaswift.extend_stdlib()")
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Hyperbolic Functions

    func testSinh() throws {
        let result = try engine.evaluate("return mathx.sinh(0)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testCosh() throws {
        let result = try engine.evaluate("return mathx.cosh(0)")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testTanh() throws {
        let result = try engine.evaluate("return mathx.tanh(0)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testAsinh() throws {
        let result = try engine.evaluate("return mathx.asinh(0)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testAcosh() throws {
        let result = try engine.evaluate("return mathx.acosh(1)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testAtanh() throws {
        let result = try engine.evaluate("return mathx.atanh(0)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    // MARK: - Rounding Functions

    func testRound() throws {
        let result = try engine.evaluate("return mathx.round(2.5)")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)  // Rounds half away from zero
    }

    func testRoundUp() throws {
        let result = try engine.evaluate("return mathx.round(2.7)")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testTrunc() throws {
        let result = try engine.evaluate("return mathx.trunc(2.9)")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testTruncNegative() throws {
        let result = try engine.evaluate("return mathx.trunc(-2.9)")
        XCTAssertEqual(result.numberValue!, -2.0, accuracy: 1e-10)
    }

    func testSign() throws {
        let result = try engine.evaluate("return mathx.sign(-5)")
        XCTAssertEqual(result.numberValue!, -1.0, accuracy: 1e-10)
    }

    func testSignZero() throws {
        let result = try engine.evaluate("return mathx.sign(0)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testSignPositive() throws {
        let result = try engine.evaluate("return mathx.sign(5)")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    // MARK: - Logarithm Functions

    func testLog10() throws {
        let result = try engine.evaluate("return mathx.log10(100)")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testLog2() throws {
        let result = try engine.evaluate("return mathx.log2(8)")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testLog10Zero() throws {
        let result = try engine.evaluate("return mathx.log10(0)")
        XCTAssertEqual(result.numberValue!, -.infinity)
    }

    func testLog10Negative() throws {
        let result = try engine.evaluate("return mathx.log10(-1)")
        XCTAssertTrue(result.numberValue!.isNaN)
    }

    func testLog2Zero() throws {
        let result = try engine.evaluate("return mathx.log2(0)")
        XCTAssertEqual(result.numberValue!, -.infinity)
    }

    func testLog2Negative() throws {
        let result = try engine.evaluate("return mathx.log2(-1)")
        XCTAssertTrue(result.numberValue!.isNaN)
    }

    // MARK: - Statistics Functions

    func testSum() throws {
        let result = try engine.evaluate("return mathx.sum({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, 15.0, accuracy: 1e-10)
    }

    func testMean() throws {
        let result = try engine.evaluate("return mathx.mean({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testMedianOdd() throws {
        let result = try engine.evaluate("return mathx.median({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testMedianEven() throws {
        let result = try engine.evaluate("return mathx.median({1, 2, 3, 4})")
        XCTAssertEqual(result.numberValue!, 2.5, accuracy: 1e-10)
    }

    func testVariancePopulation() throws {
        // Population variance: [(1-3)^2 + (2-3)^2 + (3-3)^2 + (4-3)^2 + (5-3)^2] / 5 = 2
        let result = try engine.evaluate("return mathx.variance({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testVarianceSample() throws {
        // Sample variance: [(1-3)^2 + (2-3)^2 + (3-3)^2 + (4-3)^2 + (5-3)^2] / 4 = 2.5
        let result = try engine.evaluate("return mathx.variance({1, 2, 3, 4, 5}, 1)")
        XCTAssertEqual(result.numberValue!, 2.5, accuracy: 1e-10)
    }

    func testStddevPopulation() throws {
        let result = try engine.evaluate("return mathx.stddev({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, sqrt(2.0), accuracy: 1e-10)
    }

    func testStddevSample() throws {
        let result = try engine.evaluate("return mathx.stddev({1, 2, 3, 4, 5}, 1)")
        XCTAssertEqual(result.numberValue!, sqrt(2.5), accuracy: 1e-10)
    }

    func testPercentile() throws {
        let result = try engine.evaluate("return mathx.percentile({1, 2, 3, 4, 5}, 50)")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    // MARK: - Geometric Mean

    func testGmeanSimple() throws {
        // gmean([1, 2, 4]) = (1 * 2 * 4)^(1/3) = 8^(1/3) = 2
        let result = try engine.evaluate("return mathx.gmean({1, 2, 4})")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testGmeanPowers() throws {
        // gmean([2, 8]) = (16)^(1/2) = 4
        let result = try engine.evaluate("return mathx.gmean({2, 8})")
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 1e-10)
    }

    func testGmeanSingleValue() throws {
        let result = try engine.evaluate("return mathx.gmean({5})")
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    // MARK: - Harmonic Mean

    func testHmeanSimple() throws {
        // hmean([1, 2]) = 2 / (1/1 + 1/2) = 2 / 1.5 = 4/3
        let result = try engine.evaluate("return mathx.hmean({1, 2})")
        XCTAssertEqual(result.numberValue!, 4.0/3.0, accuracy: 1e-10)
    }

    func testHmeanEqual() throws {
        // hmean([5, 5, 5]) = 5
        let result = try engine.evaluate("return mathx.hmean({5, 5, 5})")
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testHmeanSingleValue() throws {
        let result = try engine.evaluate("return mathx.hmean({3})")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    // MARK: - Mode

    func testModeSimple() throws {
        let result = try engine.evaluate("return mathx.mode({1, 2, 2, 3})")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testModeTieReturnsSmallest() throws {
        // Tie between 1, 2, 3 - should return smallest (1)
        let result = try engine.evaluate("return mathx.mode({1, 2, 3})")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testModeMultipleOccurrences() throws {
        let result = try engine.evaluate("return mathx.mode({1, 2, 2, 3, 3, 3})")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testModeSingleValue() throws {
        let result = try engine.evaluate("return mathx.mode({7})")
        XCTAssertEqual(result.numberValue!, 7.0, accuracy: 1e-10)
    }

    // MARK: - Special Functions

    func testFactorial() throws {
        let result = try engine.evaluate("return mathx.factorial(5)")
        XCTAssertEqual(result.numberValue!, 120.0, accuracy: 1e-10)
    }

    func testFactorialZero() throws {
        let result = try engine.evaluate("return mathx.factorial(0)")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testGamma() throws {
        // gamma(5) = 4! = 24
        let result = try engine.evaluate("return mathx.gamma(5)")
        XCTAssertEqual(result.numberValue!, 24.0, accuracy: 1e-10)
    }

    func testLgamma() throws {
        // lgamma(5) = log(4!) = log(24)
        let result = try engine.evaluate("return mathx.lgamma(5)")
        XCTAssertEqual(result.numberValue!, log(24.0), accuracy: 1e-10)
    }

    // MARK: - Combinatorics

    func testPerm() throws {
        // P(5,2) = 5! / 3! = 20
        let result = try engine.evaluate("return mathx.perm(5, 2)")
        XCTAssertEqual(result.numberValue!, 20.0, accuracy: 1e-10)
    }

    func testComb() throws {
        // C(5,2) = 5! / (2! * 3!) = 10
        let result = try engine.evaluate("return mathx.comb(5, 2)")
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    func testBinomial() throws {
        // binomial is alias for comb
        let result = try engine.evaluate("return mathx.binomial(5, 2)")
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    // MARK: - Coordinate Conversions

    func testPolarToCartX() throws {
        let result = try engine.evaluate("""
            local result = mathx.polar_to_cart(1, 0)
            return result[1]
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testPolarToCartY() throws {
        let result = try engine.evaluate("""
            local result = mathx.polar_to_cart(1, math.pi/2)
            return result[2]
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testCartToPolarR() throws {
        let result = try engine.evaluate("""
            local result = mathx.cart_to_polar(3, 4)
            return result[1]
            """)
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testCartToPolarTheta() throws {
        let result = try engine.evaluate("""
            local result = mathx.cart_to_polar(1, 0)
            return result[2]
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    // MARK: - Math Import

    func testMathImportAddsGmean() throws {
        try engine.run("mathx.import()")
        let result = try engine.evaluate("return math.gmean({1, 2, 4})")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testMathImportAddsHmean() throws {
        try engine.run("mathx.import()")
        let result = try engine.evaluate("return math.hmean({5, 5, 5})")
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testMathImportAddsMode() throws {
        try engine.run("mathx.import()")
        let result = try engine.evaluate("return math.mode({1, 2, 2, 3})")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    // MARK: - Namespace Access

    func testLuaswiftMathxNamespace() throws {
        let result = try engine.evaluate("return type(luaswift.mathx)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathxGlobalAlias() throws {
        let result = try engine.evaluate("return type(mathx)")
        XCTAssertEqual(result.stringValue, "table")
    }

    // MARK: - Standard Lua Math Constants Verification (Task 154)

    func testMathPiConstant() throws {
        // Verify math.pi is available in standard Lua
        let result = try engine.evaluate("return math.pi")
        XCTAssertEqual(result.numberValue!, Double.pi, accuracy: 1e-15)
    }

    func testMathHugeConstant() throws {
        // Verify math.huge (infinity) is available
        let result = try engine.evaluate("return math.huge")
        XCTAssertTrue(result.numberValue!.isInfinite)
    }

    func testMathMaxIntegerConstant() throws {
        // Verify math.maxinteger is available (Lua 5.3+)
        let result = try engine.evaluate("return math.maxinteger")
        XCTAssertNotNil(result.numberValue)
    }

    func testMathMinIntegerConstant() throws {
        // Verify math.mininteger is available (Lua 5.3+)
        let result = try engine.evaluate("return math.mininteger")
        XCTAssertNotNil(result.numberValue)
    }
}
