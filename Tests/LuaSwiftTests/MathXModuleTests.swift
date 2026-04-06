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

    func testLog10NegativeReturnsComplex() throws {
        // With complex support, log10(-1) returns complex: {re=0, im=pi/log(10)}
        let result = try engine.evaluate("return mathx.log10(-1)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result for log10(-1)")
            return
        }
        XCTAssertEqual(re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(im, Double.pi / log(10.0), accuracy: 1e-10)
    }

    func testLog2Zero() throws {
        let result = try engine.evaluate("return mathx.log2(0)")
        XCTAssertEqual(result.numberValue!, -.infinity)
    }

    func testLog2NegativeReturnsComplex() throws {
        // With complex support, log2(-1) returns complex: {re=0, im=pi/log(2)}
        let result = try engine.evaluate("return mathx.log2(-1)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result for log2(-1)")
            return
        }
        XCTAssertEqual(re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(im, Double.pi / log(2.0), accuracy: 1e-10)
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
        // math.maxinteger is only available in Lua 5.3+
        #if LUA_VERSION_51 || LUA_VERSION_52
        // Not available in Lua 5.1/5.2
        let result = try engine.evaluate("return math.maxinteger")
        XCTAssertNil(result.numberValue, "math.maxinteger should not exist in Lua 5.1/5.2")
        #else
        let result = try engine.evaluate("return math.maxinteger")
        XCTAssertNotNil(result.numberValue)
        #endif
    }

    func testMathMinIntegerConstant() throws {
        // math.mininteger is only available in Lua 5.3+
        #if LUA_VERSION_51 || LUA_VERSION_52
        // Not available in Lua 5.1/5.2
        let result = try engine.evaluate("return math.mininteger")
        XCTAssertNil(result.numberValue, "math.mininteger should not exist in Lua 5.1/5.2")
        #else
        let result = try engine.evaluate("return math.mininteger")
        XCTAssertNotNil(result.numberValue)
        #endif
    }

    // MARK: - Complex Number Support Tests (Task 184)

    // MARK: Complex sinh
    func testComplexSinhPureImaginary() throws {
        // sinh(i*pi/2) = i
        let result = try engine.evaluate("""
            local z = {re = 0, im = math.pi/2}
            local r = mathx.sinh(z)
            return r
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(im, 1.0, accuracy: 1e-10)
    }

    func testComplexSinhGeneral() throws {
        // sinh(1+i) - verify against known value
        // sinh(1+i) = sinh(1)cos(1) + i*cosh(1)sin(1)
        let result = try engine.evaluate("""
            local z = {re = 1, im = 1}
            local r = mathx.sinh(z)
            return r
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        let expectedRe = sinh(1.0) * cos(1.0)
        let expectedIm = cosh(1.0) * sin(1.0)
        XCTAssertEqual(re, expectedRe, accuracy: 1e-10)
        XCTAssertEqual(im, expectedIm, accuracy: 1e-10)
    }

    // MARK: Complex cosh
    func testComplexCoshPureImaginary() throws {
        // cosh(i*pi) = -1 (real)
        let result = try engine.evaluate("""
            local z = {re = 0, im = math.pi}
            return mathx.cosh(z)
            """)
        // cosh(0+i*pi) = cosh(0)*cos(pi) = 1*(-1) = -1, and sinh(0)*sin(pi) = 0
        // Should return real -1
        XCTAssertEqual(result.numberValue!, -1.0, accuracy: 1e-10)
    }

    func testComplexCoshGeneral() throws {
        // cosh(1+i) = cosh(1)cos(1) + i*sinh(1)sin(1)
        let result = try engine.evaluate("""
            local z = {re = 1, im = 1}
            local r = mathx.cosh(z)
            return r
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        let expectedRe = cosh(1.0) * cos(1.0)
        let expectedIm = sinh(1.0) * sin(1.0)
        XCTAssertEqual(re, expectedRe, accuracy: 1e-10)
        XCTAssertEqual(im, expectedIm, accuracy: 1e-10)
    }

    // MARK: Complex tanh
    func testComplexTanhZero() throws {
        // tanh(0+0i) = 0
        let result = try engine.evaluate("""
            local z = {re = 0, im = 0}
            return mathx.tanh(z)
            """)
        // Should return real 0
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testComplexTanhGeneral() throws {
        // tanh(1+i) - verify the formula works
        let result = try engine.evaluate("""
            local z = {re = 1, im = 1}
            local r = mathx.tanh(z)
            return r
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        // tanh(a+bi) = [sinh(2a) + i*sin(2b)] / [cosh(2a) + cos(2b)]
        let sinh2a = sinh(2.0)
        let sin2b = sin(2.0)
        let cosh2a = cosh(2.0)
        let cos2b = cos(2.0)
        let denom = cosh2a + cos2b
        let expectedRe = sinh2a / denom
        let expectedIm = sin2b / denom
        XCTAssertEqual(re, expectedRe, accuracy: 1e-10)
        XCTAssertEqual(im, expectedIm, accuracy: 1e-10)
    }

    // MARK: Complex asinh
    func testComplexAsinhRoundtrip() throws {
        // asinh(sinh(1+i)) should give back approximately 1+i
        let result = try engine.evaluate("""
            local z = {re = 1, im = 1}
            local s = mathx.sinh(z)
            local r = mathx.asinh(s)
            return r
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 1.0, accuracy: 1e-10)
        XCTAssertEqual(im, 1.0, accuracy: 1e-10)
    }

    // MARK: Complex acosh
    func testComplexAcoshRoundtrip() throws {
        // acosh(cosh(1+i)) should give back approximately 1+i
        let result = try engine.evaluate("""
            local z = {re = 1, im = 1}
            local c = mathx.cosh(z)
            local r = mathx.acosh(c)
            return r
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 1.0, accuracy: 1e-10)
        XCTAssertEqual(im, 1.0, accuracy: 1e-10)
    }

    func testComplexAcoshRealLessThanOne() throws {
        // acosh(0.5) for real < 1 should return complex
        let result = try engine.evaluate("return mathx.acosh(0.5)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        // acosh(0.5) = i * acos(0.5) = i * pi/3
        XCTAssertEqual(re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(im, acos(0.5), accuracy: 1e-10)
    }

    // MARK: Complex atanh
    func testComplexAtanhRoundtrip() throws {
        // atanh(tanh(0.5+0.5i)) should give back approximately 0.5+0.5i
        let result = try engine.evaluate("""
            local z = {re = 0.5, im = 0.5}
            local t = mathx.tanh(z)
            local r = mathx.atanh(t)
            return r
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 0.5, accuracy: 1e-10)
        XCTAssertEqual(im, 0.5, accuracy: 1e-10)
    }

    func testComplexAtanhRealGreaterThanOne() throws {
        // atanh(2) for |x| > 1 should return complex
        let result = try engine.evaluate("return mathx.atanh(2)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        // For |x| > 1: re = 0.5 * log(|(x+1)/(x-1)|), im = -pi/2 for x > 1
        let expectedRe = 0.5 * log(abs((2.0 + 1) / (2.0 - 1)))
        let expectedIm = -Double.pi / 2
        XCTAssertEqual(re, expectedRe, accuracy: 1e-10)
        XCTAssertEqual(im, expectedIm, accuracy: 1e-10)
    }

    // MARK: Complex log10
    func testComplexLog10() throws {
        // log10({re=10, im=0}) should equal 1
        let result = try engine.evaluate("""
            local z = {re = 10, im = 0}
            return mathx.log10(z)
            """)
        // Should return real 1.0 (imaginary part is negligible)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testComplexLog10Negative() throws {
        // log10(-10) should return complex with im = pi/log(10)
        let result = try engine.evaluate("return mathx.log10(-10)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 1.0, accuracy: 1e-10)  // log10(10) = 1
        XCTAssertEqual(im, Double.pi / log(10.0), accuracy: 1e-10)
    }

    // MARK: Complex log2
    func testComplexLog2() throws {
        // log2({re=8, im=0}) should equal 3
        let result = try engine.evaluate("""
            local z = {re = 8, im = 0}
            return mathx.log2(z)
            """)
        // Should return real 3.0 (imaginary part is negligible)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testComplexLog2Negative() throws {
        // log2(-8) should return complex with im = pi/log(2)
        let result = try engine.evaluate("return mathx.log2(-8)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 3.0, accuracy: 1e-10)  // log2(8) = 3
        XCTAssertEqual(im, Double.pi / log(2.0), accuracy: 1e-10)
    }

    // MARK: csqrt function
    func testCsqrtPositiveReal() throws {
        // csqrt(4) should return {re=2, im=0}
        let result = try engine.evaluate("return mathx.csqrt(4)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 2.0, accuracy: 1e-10)
        XCTAssertEqual(im, 0.0, accuracy: 1e-10)
    }

    func testCsqrtNegativeReal() throws {
        // csqrt(-4) should return {re=0, im=2} (principal sqrt)
        let result = try engine.evaluate("return mathx.csqrt(-4)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(im, 2.0, accuracy: 1e-10)
    }

    func testCsqrtComplex() throws {
        // csqrt(3+4i) should satisfy result^2 = 3+4i
        let result = try engine.evaluate("""
            local z = {re = 3, im = 4}
            local r = mathx.csqrt(z)
            -- Verify r^2 = z
            local r2_re = r.re * r.re - r.im * r.im
            local r2_im = 2 * r.re * r.im
            return {re = r2_re, im = r2_im}
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 3.0, accuracy: 1e-10)
        XCTAssertEqual(im, 4.0, accuracy: 1e-10)
    }

    // MARK: clog function
    func testClogPositiveReal() throws {
        // clog(e) should return {re=1, im=0}
        let result = try engine.evaluate("""
            return mathx.clog(math.exp(1))
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 1.0, accuracy: 1e-10)
        XCTAssertEqual(im, 0.0, accuracy: 1e-10)
    }

    func testClogNegativeReal() throws {
        // clog(-1) should return {re=0, im=pi}
        let result = try engine.evaluate("return mathx.clog(-1)")
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(im, Double.pi, accuracy: 1e-10)
    }

    func testClogComplex() throws {
        // clog(e^(1+i)) should return approximately 1+i
        let result = try engine.evaluate("""
            -- e^(1+i) = e * (cos(1) + i*sin(1))
            local e = math.exp(1)
            local z = {re = e * math.cos(1), im = e * math.sin(1)}
            local r = mathx.clog(z)
            return r
            """)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(re, 1.0, accuracy: 1e-10)
        XCTAssertEqual(im, 1.0, accuracy: 1e-10)
    }

    // MARK: Real function backward compatibility
    func testRealSinhStillWorks() throws {
        let result = try engine.evaluate("return mathx.sinh(1)")
        XCTAssertEqual(result.numberValue!, sinh(1.0), accuracy: 1e-10)
    }

    func testRealCoshStillWorks() throws {
        let result = try engine.evaluate("return mathx.cosh(1)")
        XCTAssertEqual(result.numberValue!, cosh(1.0), accuracy: 1e-10)
    }

    func testRealTanhStillWorks() throws {
        let result = try engine.evaluate("return mathx.tanh(0.5)")
        XCTAssertEqual(result.numberValue!, tanh(0.5), accuracy: 1e-10)
    }
}
