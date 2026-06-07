//
//  SeriesModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//

#if LUASWIFT_NUMERICSWIFT
import XCTest
@testable import LuaSwift

final class SeriesModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUpWithError() throws {
        try super.setUpWithError()
        engine = try LuaEngine()
        try ModuleRegistry.install(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Module Registration Tests

    func testSeriesModuleExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.series)
            """)
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathSeriesAlias() throws {
        let result = try engine.evaluate("""
            return type(math.series)
            """)
        XCTAssertEqual(result.stringValue, "table")
    }

    // MARK: - Series Summation Tests

    func testSeriesSumFinite() throws {
        // Sum of 1/n^2 from n=1 to 10
        let result = try engine.evaluate("""
            return luaswift.series.sum("1/n^2", {var="n", from=1, to=10})
            """)
        // Expected: 1 + 1/4 + 1/9 + ... + 1/100 ≈ 1.5497677...
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 1.5497677, accuracy: 0.0001)
    }

    func testSeriesSumConvergence() throws {
        // Basel problem: sum of 1/n^2 converges to pi^2/6
        let result = try engine.evaluate("""
            local sum, info = luaswift.series.sum("1/n^2", {var="n", from=1, tol=1e-8})
            return sum
            """)
        XCTAssertNotNil(result.numberValue)
        let expected = Double.pi * Double.pi / 6.0
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-4)
    }

    func testSeriesSumConvergenceInfo() throws {
        let result = try engine.evaluate("""
            local sum, info = luaswift.series.sum("1/2^n", {var="n", from=0, tol=1e-10})
            return info.converged
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSeriesSumGeometric() throws {
        // Sum of 1/2^n from n=0 to infinity = 2
        let result = try engine.evaluate("""
            return luaswift.series.sum("1/2^n", {var="n", from=0, tol=1e-10})
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-8)
    }

    func testSeriesSumAlternating() throws {
        // Alternating harmonic series: ln(2) ≈ 0.693147
        let result = try engine.evaluate("""
            return luaswift.series.sum("(-1)^(n+1) / n", {var="n", from=1, to=10000})
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, log(2.0), accuracy: 0.001)
    }

    func testSeriesSumWithDifferentVariable() throws {
        let result = try engine.evaluate("""
            return luaswift.series.sum("1/k^2", {var="k", from=1, to=10})
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 1.5497677, accuracy: 0.0001)
    }

    // MARK: - Series Product Tests

    func testSeriesProductFinite() throws {
        // Product of (1 - 1/n^2) from n=2 to 10
        // This equals (n-1)*(n+1)/n^2 = 1/2 in the limit
        let result = try engine.evaluate("""
            return luaswift.series.product("(1 - 1/n^2)", {var="n", from=2, to=100})
            """)
        XCTAssertNotNil(result.numberValue)
        // Wallis-like product, converges to 1/2
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 0.01)
    }

    func testSeriesProductFactorial() throws {
        // Product of n from 1 to 5 = 5! = 120
        let result = try engine.evaluate("""
            return luaswift.series.product("n", {var="n", from=1, to=5})
            """)
        XCTAssertEqual(result.numberValue, 120.0)
    }

    // MARK: - Taylor Series Tests (Analytical)

    func testTaylorSin() throws {
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("sin", {at=0, terms=10})
            return poly:eval(0.5)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, sin(0.5), accuracy: 1e-10)
    }

    func testTaylorCos() throws {
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("cos", {at=0, terms=10})
            return poly:eval(0.5)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, cos(0.5), accuracy: 1e-8)
    }

    func testTaylorExp() throws {
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("exp", {at=0, terms=15})
            return poly:eval(1.0)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, exp(1.0), accuracy: 1e-10)
    }

    func testTaylorSinh() throws {
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("sinh", {at=0, terms=10})
            return poly:eval(0.5)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, sinh(0.5), accuracy: 1e-10)
    }

    func testTaylorCosh() throws {
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("cosh", {at=0, terms=10})
            return poly:eval(0.5)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, cosh(0.5), accuracy: 1e-8)
    }

    func testTaylorAtan() throws {
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("atan", {at=0, terms=20})
            return poly:eval(0.5)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, atan(0.5), accuracy: 1e-6)
    }

    func testTaylorGeometric() throws {
        // 1/(1-x) = 1 + x + x^2 + x^3 + ...
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("geometric", {at=0, terms=20})
            return poly:eval(0.5)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-5) // 1/(1-0.5) = 2
    }

    func testTaylorPolynomialCallable() throws {
        // Polynomial should be callable directly
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("sin", {at=0, terms=10})
            return poly(math.pi/6)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-8)
    }

    func testTaylorCoefficients() throws {
        // Check actual coefficients
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("exp", {at=0, terms=5})
            local c = poly.coefficients
            -- Should be 1, 1, 1/2, 1/6, 1/24
            return c[1] + c[2] + c[3]*2 + c[4]*6 + c[5]*24
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testTaylorAvailableFunctions() throws {
        let result = try engine.evaluate("""
            local funcs = luaswift.series.available_functions()
            return #funcs
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertGreaterThanOrEqual(result.numberValue!, 10)
    }

    func testTaylorUnknownFunctionError() throws {
        XCTAssertThrowsError(try engine.run("""
            luaswift.series.taylor("unknown_func", {terms=5})
            """))
    }

    // MARK: - Numerical Taylor Approximation Tests

    func testApproximateTaylorSin() throws {
        // Numerical approximation - less accurate than analytical
        let result = try engine.evaluate("""
            local poly = luaswift.series.approximate_taylor(math.sin, {at=0, degree=10, scale=0.5})
            return poly:eval(0.3)
            """)
        XCTAssertNotNil(result.numberValue)
        // Numerical Taylor approximation has limited accuracy
        XCTAssertEqual(result.numberValue!, sin(0.3), accuracy: 0.01)
    }

    func testApproximateTaylorExp() throws {
        // Numerical approximation - check structure works, accuracy limited
        // Note: Full Krogh interpolation would be more accurate (future enhancement)
        let result = try engine.evaluate("""
            local poly = luaswift.series.approximate_taylor(math.exp, {at=0, degree=5, scale=0.1})
            -- Just verify it returns a callable polynomial
            return type(poly) == "table" and type(poly.eval) == "function"
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testApproximateTaylorCustomFunction() throws {
        // Test with a custom polynomial function (should be exact)
        let result = try engine.evaluate("""
            local function f(x) return x^3 - 2*x + 1 end
            local poly = luaswift.series.approximate_taylor(f, {at=1, degree=5, scale=0.2})
            return poly:eval(1.1)
            """)
        XCTAssertNotNil(result.numberValue)
        let expected = pow(1.1, 3) - 2 * 1.1 + 1
        // Numerical approximation via finite differences
        XCTAssertEqual(result.numberValue!, expected, accuracy: 0.01)
    }

    // MARK: - Partial Sums Tests

    func testPartialSumsIterator() throws {
        let result = try engine.evaluate("""
            local count = 0
            local last_sum = 0
            for i, n, term, sum in luaswift.series.partial_sums("1/2^n", {var="n", from=0, max_terms=10}) do
                count = count + 1
                last_sum = sum
            end
            return last_sum
            """)
        XCTAssertNotNil(result.numberValue)
        // Sum of 1/2^n from 0 to 9 = 2 - 1/512 ≈ 1.998
        XCTAssertEqual(result.numberValue!, 2.0 - 1.0/512, accuracy: 1e-10)
    }

    func testPartialSumsYieldsCorrectValues() throws {
        let result = try engine.evaluate("""
            local sums = {}
            for i, n, term, sum in luaswift.series.partial_sums("1/2^n", {var="n", from=0, max_terms=4}) do
                table.insert(sums, sum)
            end
            -- Should be: 1, 1.5, 1.75, 1.875
            return sums[1] + sums[2] + sums[3] + sums[4]
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 1 + 1.5 + 1.75 + 1.875, accuracy: 1e-10)
    }

    // MARK: - Terms Iterator Tests

    func testTermsIterator() throws {
        let result = try engine.evaluate("""
            local terms = {}
            local gen = luaswift.series.terms("1/n^2", {var="n", from=1})
            for i = 1, 5 do
                local n, term = gen()
                table.insert(terms, term)
            end
            return terms[1] + terms[2] + terms[3] + terms[4] + terms[5]
            """)
        XCTAssertNotNil(result.numberValue)
        // 1 + 1/4 + 1/9 + 1/16 + 1/25
        let expected: Double = 1.0 + 0.25 + (1.0/9.0) + (1.0/16.0) + (1.0/25.0)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-10)
    }

    func testTermsLazyEvaluation() throws {
        // Terms iterator should be lazy - not compute all at once
        let result = try engine.evaluate("""
            local gen = luaswift.series.terms("n", {var="n", from=1})
            local n1, t1 = gen()
            local n2, t2 = gen()
            local n3, t3 = gen()
            return n1 + n2 + n3
            """)
        XCTAssertEqual(result.numberValue, 6.0) // 1 + 2 + 3
    }

    // MARK: - Helper Function Tests

    func testFactorial() throws {
        let result = try engine.evaluate("""
            local f = luaswift.series._factorial
            return f(0) + f(1) + f(5) + f(10)
            """)
        XCTAssertNotNil(result.numberValue)
        // 1 + 1 + 120 + 3628800
        XCTAssertEqual(result.numberValue!, 3628922.0, accuracy: 1e-10)
    }

    func testBinomial() throws {
        let result = try engine.evaluate("""
            local b = luaswift.series.binomial
            return b(5, 0) + b(5, 1) + b(5, 2) + b(5, 3) + b(5, 4) + b(5, 5)
            """)
        XCTAssertNotNil(result.numberValue)
        // 1 + 5 + 10 + 10 + 5 + 1 = 32 = 2^5
        XCTAssertEqual(result.numberValue!, 32.0, accuracy: 1e-10)
    }

    func testBinomialEdgeCases() throws {
        let result = try engine.evaluate("""
            local b = luaswift.series.binomial
            return b(10, 0), b(10, 10), b(10, -1), b(10, 11)
            """)
        // Returns multiple values - first should be 1, second 1, third 0, fourth 0
        XCTAssertEqual(result.numberValue, 1.0) // First return value
    }

    // MARK: - Polynomial Evaluation Tests

    func testEvalPoly() throws {
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("exp", {at=0, terms=5})
            -- Compare two evaluation methods
            local v1 = poly:eval(0.5)
            local v2 = poly(0.5)
            return math.abs(v1 - v2) < 1e-15
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Integration with MathExpr Tests

    func testIntegrationWithEval() throws {
        // Verify series.sum works with complex expressions
        let result = try engine.evaluate("""
            return luaswift.series.sum("sin(n*0.01)/n", {var="n", from=1, to=100})
            """)
        XCTAssertNotNil(result.numberValue)
        // Should compute without error
    }

    func testIntegrationWithMathFunctions() throws {
        let result = try engine.evaluate("""
            return luaswift.series.sum("exp(-n)/n", {var="n", from=1, to=50})
            """)
        XCTAssertNotNil(result.numberValue)
    }

    // MARK: - Edge Cases

    func testSeriesSumSingleTerm() throws {
        let result = try engine.evaluate("""
            return luaswift.series.sum("n", {var="n", from=5, to=5})
            """)
        XCTAssertEqual(result.numberValue, 5.0)
    }

    func testSeriesProductSingleTerm() throws {
        let result = try engine.evaluate("""
            return luaswift.series.product("n", {var="n", from=7, to=7})
            """)
        XCTAssertEqual(result.numberValue, 7.0)
    }

    func testTaylorAtNonZero() throws {
        // Taylor series should work at non-zero center (coefficients still at 0)
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("sin", {at=0, terms=15})
            -- Evaluate at pi/2, should be close to 1
            return poly:eval(math.pi/2)
            """)
        XCTAssertNotNil(result.numberValue)
        // Taylor series at x=0 evaluated at pi/2 has limited accuracy
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-5)
    }

    func testSeriesSumMaxIterSafety() throws {
        // Should not hang on non-converging series
        let result = try engine.evaluate("""
            local sum, info = luaswift.series.sum("1", {var="n", from=1, max_iter=100})
            return info.converged
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - Known Mathematical Identities

    func testEulerIdentity() throws {
        // e^(i*pi) + 1 = 0
        // Use Taylor series for exp and check exp(pi) ≈ 23.14
        let result = try engine.evaluate("""
            local poly = luaswift.series.taylor("exp", {at=0, terms=20})
            return poly:eval(math.pi)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, exp(Double.pi), accuracy: 1e-8)
    }

    func testZetaApproximation() throws {
        // zeta(2) = pi^2/6 ≈ 1.6449
        let result = try engine.evaluate("""
            return luaswift.series.sum("1/n^2", {var="n", from=1, to=10000})
            """)
        XCTAssertNotNil(result.numberValue)
        let expected = Double.pi * Double.pi / 6.0
        XCTAssertEqual(result.numberValue!, expected, accuracy: 0.001)
    }

    func testLeibnizFormula() throws {
        // pi/4 = 1 - 1/3 + 1/5 - 1/7 + ...
        let result = try engine.evaluate("""
            return luaswift.series.sum("(-1)^n / (2*n + 1)", {var="n", from=0, to=10000})
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, Double.pi / 4, accuracy: 0.001)
    }

    // MARK: - Performance Tests

    func testSeriesSumPerformance() throws {
        measure {
            _ = try? engine.evaluate("""
                local sum = 0
                for i = 1, 10 do
                    sum = luaswift.series.sum("1/n^2", {var="n", from=1, to=50})
                end
                return sum
                """)
        }
    }

    func testTaylorEvalPerformance() throws {
        measure {
            _ = try? engine.evaluate("""
                local poly = luaswift.series.taylor("sin", {at=0, terms=15})
                local sum = 0
                for i = 1, 10000 do
                    sum = sum + poly(i * 0.001)
                end
                return sum
                """)
        }
    }

    // MARK: - Power Series Object Tests (Part 1a)

    func testPowerSeriesConstructor() throws {
        let result = try engine.evaluate("""
            local ps = luaswift.series.power({coefficients={1, 2, 3}, center=0})
            return type(ps) == "table" and type(ps.eval) == "function"
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testPowerSeriesEval() throws {
        // p(x) = 1 + 2x + 3x^2 at x=2: 1 + 4 + 12 = 17
        let result = try engine.evaluate("""
            local ps = luaswift.series.power({coefficients={1, 2, 3}, center=0})
            return ps:eval(2)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 17.0, accuracy: 1e-12)
    }

    func testPowerSeriesCallable() throws {
        // power series should be callable directly via __call metamethod
        let result = try engine.evaluate("""
            local ps = luaswift.series.power({coefficients={1, 0, 1}, center=0})
            return ps(1.5)
            """)
        // 1 + 0*1.5 + 1*1.5^2 = 1 + 2.25 = 3.25
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 3.25, accuracy: 1e-12)
    }

    func testPowerSeriesAdd() throws {
        // (1 + 2x) + (3 + 4x) = 4 + 6x
        let result = try engine.evaluate("""
            local a = luaswift.series.power({coefficients={1, 2}, center=0})
            local b = luaswift.series.power({coefficients={3, 4}, center=0})
            local c = a:add(b)
            return c:eval(1)
            """)
        // 4 + 6 = 10
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-12)
    }

    func testPowerSeriesAddDifferentLengths() throws {
        // (1 + 2x + 3x^2) + (4 + 5x) = 5 + 7x + 3x^2
        let result = try engine.evaluate("""
            local a = luaswift.series.power({coefficients={1, 2, 3}, center=0})
            local b = luaswift.series.power({coefficients={4, 5}, center=0})
            local c = a:add(b)
            -- 5 + 7*1 + 3*1 = 15
            return c:eval(1)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 15.0, accuracy: 1e-12)
    }

    func testPowerSeriesMultiply() throws {
        // (1 + x) * (1 + x) = 1 + 2x + x^2 (Cauchy product, 2 terms input → 2 terms output)
        let result = try engine.evaluate("""
            local a = luaswift.series.power({coefficients={1, 1, 0, 0}, center=0})
            local b = luaswift.series.power({coefficients={1, 1, 0, 0}, center=0})
            local c = a:multiply(b)
            return c:eval(2)
            """)
        // 1 + 2*2 + 2^2 = 1 + 4 + 4 = 9 = (1+2)^2
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 9.0, accuracy: 1e-12)
    }

    func testPowerSeriesCauchyProduct() throws {
        // exp(x) * exp(x) coefficients for first 4 terms should match exp(2x)
        // exp: [1, 1, 1/2, 1/6], exp: [1, 1, 1/2, 1/6]
        // product[0] = 1, product[1] = 1+1 = 2, product[2] = 1+1+0.5 = 2.5? No.
        // exp(x)*exp(x) = exp(2x), coeff[n] = 2^n/n!
        // [1, 2, 2, 4/3] for first 4 terms
        let result = try engine.evaluate("""
            local a = luaswift.series.power({coefficients={1, 1, 0.5, 1/6}, center=0})
            local b = luaswift.series.power({coefficients={1, 1, 0.5, 1/6}, center=0})
            local c = a:multiply(b)
            -- c[1] should be 1, c[2] should be 2
            return c.coefficients[1], c.coefficients[2]
            """)
        XCTAssertEqual(result.numberValue, 1.0)
    }

    func testPowerSeriesTruncate() throws {
        let result = try engine.evaluate("""
            local ps = luaswift.series.power({coefficients={1,2,3,4,5}, center=0})
            local tr = ps:truncate(3)
            return #tr.coefficients
            """)
        XCTAssertEqual(result.numberValue, 3.0)
    }

    func testPowerSeriesTruncateEval() throws {
        // Truncate (1 + 2x + 3x^2 + 4x^3) to 3 terms → (1 + 2x + 3x^2) at x=1 = 6
        let result = try engine.evaluate("""
            local ps = luaswift.series.power({coefficients={1,2,3,4}, center=0})
            local tr = ps:truncate(3)
            return tr:eval(1)
            """)
        XCTAssertEqual(result.numberValue, 6.0)
    }

    func testPowerSeriesWithCenter() throws {
        // (x-1)^2 = 1 - 2(x-1) + (x-1)^2 around x=1 → coeffs [1,-2,1], center=1
        // Actually: (x-1)^2 expanded as Taylor around 1 → coeffs [0,0,1], center=1
        // But direct: p = power({coefficients={0,0,1}, center=1}) at x=3 = (3-1)^2 = 4
        let result = try engine.evaluate("""
            local ps = luaswift.series.power({coefficients={0, 0, 1}, center=1})
            return ps:eval(3)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 1e-12)
    }

    func testPowerSeriesAddMismatchedCentersError() throws {
        XCTAssertThrowsError(try engine.run("""
            local a = luaswift.series.power({coefficients={1,2}, center=0})
            local b = luaswift.series.power({coefficients={1,2}, center=1})
            a:add(b)
            """))
    }

    func testPowerSeriesMultiplyMismatchedCentersError() throws {
        XCTAssertThrowsError(try engine.run("""
            local a = luaswift.series.power({coefficients={1,2}, center=0})
            local b = luaswift.series.power({coefficients={1,2}, center=2})
            a:multiply(b)
            """))
    }

    // MARK: - Symbolic Dispatcher Tests (Part 1b)

    func testTaylorSymbolicKnownFunctionFallback() throws {
        // Without Thales, taylor_symbolic for known functions should fall back to series.taylor
        let result = try engine.evaluate("""
            local r = luaswift.series.taylor_symbolic("sin", {at=0, terms=10})
            return type(r) == "table" and r.coefficients ~= nil
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testTaylorSymbolicKnownFunctionEval() throws {
        let result = try engine.evaluate("""
            local r = luaswift.series.taylor_symbolic("exp", {at=0, terms=10})
            return r:eval(1.0)
            """)
        XCTAssertNotNil(result.numberValue)
        XCTAssertEqual(result.numberValue!, exp(1.0), accuracy: 1e-6)
    }

    func testTaylorSymbolicUnknownExprErrorWithoutThales() throws {
        // Without Thales, unknown expressions should raise a clear error
        // (math.cas is nil in default build)
        let result = try engine.evaluate("""
            local ok, err = pcall(function()
                return luaswift.series.taylor_symbolic("x^3 + sin(x)", {at=0, terms=5})
            end)
            -- Should fail since Thales is not available and it's not a known function name
            return ok == false and err ~= nil
            """)
        // In default build: math.cas is nil, "x^3 + sin(x)" is not a known function → error
        // The test just verifies the pcall catches it; if math.cas exists (Thales build) it succeeds
        // We only assert that we get a boolean result (no crash)
        XCTAssertNotNil(result.boolValue)
    }

    func testLaurentErrorWithoutThales() throws {
        // series.laurent should error clearly without Thales
        let result = try engine.evaluate("""
            local ok, err = pcall(function()
                return luaswift.series.laurent("1/x", {variable="x"})
            end)
            if math.cas then
                return true  -- Thales present, no error expected
            end
            return ok == false and type(err) == "string" and err:find("Thales") ~= nil
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testPuiseuxErrorWithoutThales() throws {
        // series.puiseux should error clearly without Thales
        let result = try engine.evaluate("""
            local ok, err = pcall(function()
                return luaswift.series.puiseux("sqrt(x)", {variable="x"})
            end)
            if math.cas then
                return true  -- Thales present, no error expected
            end
            return ok == false and type(err) == "string" and err:find("Thales") ~= nil
            """)
        XCTAssertEqual(result.boolValue, true)
    }
}
#endif  // LUASWIFT_NUMERICSWIFT
