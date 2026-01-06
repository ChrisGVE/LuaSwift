//
//  IntegrateModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class IntegrateModuleTests: XCTestCase {
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

    // MARK: - quad Tests

    func testQuadPolynomial() throws {
        // Integral of x^2 from 0 to 1 = 1/3
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return x^2 end, 0, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0/3.0, accuracy: 1e-10)
    }

    func testQuadSin() throws {
        // Integral of sin(x) from 0 to pi = 2
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return math.sin(x) end, 0, math.pi)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testQuadExp() throws {
        // Integral of e^x from 0 to 1 = e - 1
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return math.exp(x) end, 0, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, exp(1) - 1, accuracy: 1e-10)
    }

    func testQuadGaussian() throws {
        // Integral of e^(-x^2) from -1 to 1 ≈ 1.4936
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return math.exp(-x^2) end, -1, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.4936482656248540, accuracy: 1e-8)
    }

    func testQuadOscillatory() throws {
        // Integral of cos(10*x) from 0 to pi = 0
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return math.cos(10*x) end, 0, math.pi)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-6)
    }

    func testQuadErrorEstimate() throws {
        // Error estimate should be small for smooth functions
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return x^2 end, 0, 1)
            return err
            """)
        XCTAssertLessThan(result.numberValue!, 1e-10)
    }

    func testQuadInfiniteUpperLimit() throws {
        // Integral of e^(-x) from 0 to inf = 1
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return math.exp(-x) end, 0, math.huge)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-4)
    }

    func testQuadInfiniteLowerLimit() throws {
        // Integral of e^x from -inf to 0 = 1
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return math.exp(x) end, -math.huge, 0)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-4)
    }

    // MARK: - dblquad Tests

    func testDblquadConstant() throws {
        // Integral of 1 over [0,1]x[0,1] = 1
        let result = try engine.evaluate("""
            local result, err = math.integrate.dblquad(function(y, x) return 1 end, 0, 1, 0, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-8)
    }

    func testDblquadProduct() throws {
        // Integral of x*y over [0,1]x[0,1] = 1/4
        let result = try engine.evaluate("""
            local result, err = math.integrate.dblquad(function(y, x) return x * y end, 0, 1, 0, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 0.25, accuracy: 1e-8)
    }

    func testDblquadCircle() throws {
        // Integral of 1 over unit circle quadrant = pi/4
        let result = try engine.evaluate("""
            local function f(y, x)
                if x^2 + y^2 <= 1 then return 1 else return 0 end
            end
            local result, err = math.integrate.dblquad(f, 0, 1, 0, 1)
            return result
            """)
        // This is tricky due to discontinuity, use relaxed tolerance
        XCTAssertEqual(result.numberValue!, Double.pi / 4, accuracy: 0.1)
    }

    func testDblquadPolynomial() throws {
        // Integral of x^2 + y^2 over [0,1]x[0,1] = 2/3
        let result = try engine.evaluate("""
            local result, err = math.integrate.dblquad(function(y, x) return x^2 + y^2 end, 0, 1, 0, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 2.0/3.0, accuracy: 1e-8)
    }

    // MARK: - tplquad Tests

    func testTplquadConstant() throws {
        // Integral of 1 over [0,1]^3 = 1
        let result = try engine.evaluate("""
            local result, err = math.integrate.tplquad(
                function(z, y, x) return 1 end,
                0, 1, 0, 1, 0, 1
            )
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-6)
    }

    func testTplquadProduct() throws {
        // Integral of x*y*z over [0,1]^3 = 1/8
        let result = try engine.evaluate("""
            local result, err = math.integrate.tplquad(
                function(z, y, x) return x * y * z end,
                0, 1, 0, 1, 0, 1
            )
            return result
            """)
        XCTAssertEqual(result.numberValue!, 0.125, accuracy: 1e-6)
    }

    func testTplquadSum() throws {
        // Integral of x + y + z over [0,1]^3 = 3/2
        let result = try engine.evaluate("""
            local result, err = math.integrate.tplquad(
                function(z, y, x) return x + y + z end,
                0, 1, 0, 1, 0, 1
            )
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.5, accuracy: 1e-6)
    }

    // MARK: - fixed_quad Tests

    func testFixedQuadPolynomial() throws {
        // Fixed 5-point quadrature for x^2 from 0 to 1
        let result = try engine.evaluate("""
            local result = math.integrate.fixed_quad(function(x) return x^2 end, 0, 1, 5)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0/3.0, accuracy: 1e-10)
    }

    func testFixedQuadLinear() throws {
        // 1-point Gauss quadrature is exact for linear functions
        let result = try engine.evaluate("""
            local result = math.integrate.fixed_quad(function(x) return 2*x + 1 end, 0, 1, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testFixedQuadCubic() throws {
        // 2-point Gauss quadrature is exact for cubic polynomials
        let result = try engine.evaluate("""
            local result = math.integrate.fixed_quad(function(x) return x^3 end, 0, 1, 2)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 0.25, accuracy: 1e-10)
    }

    // MARK: - romberg Tests

    func testRombergPolynomial() throws {
        let result = try engine.evaluate("""
            local result, err = math.integrate.romberg(function(x) return x^2 end, 0, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0/3.0, accuracy: 1e-8)
    }

    func testRombergSin() throws {
        let result = try engine.evaluate("""
            local result, err = math.integrate.romberg(function(x) return math.sin(x) end, 0, math.pi)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-8)
    }

    func testRombergConvergence() throws {
        let result = try engine.evaluate("""
            local result, err = math.integrate.romberg(function(x) return math.exp(x) end, 0, 1)
            return err
            """)
        XCTAssertLessThan(result.numberValue!, 1e-6)
    }

    // MARK: - simps Tests

    func testSimpsArray() throws {
        // Simpson's rule for y = x^2 sampled at 0, 0.5, 1
        let result = try engine.evaluate("""
            local y = {0, 0.25, 1}  -- x^2 at x = 0, 0.5, 1
            local result = math.integrate.simps(y, nil, 0.5)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0/3.0, accuracy: 1e-10)
    }

    func testSimpsWithXArray() throws {
        let result = try engine.evaluate("""
            local x = {0, 0.5, 1}
            local y = {0, 0.25, 1}
            local result = math.integrate.simps(y, x)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0/3.0, accuracy: 1e-10)
    }

    func testSimpsFivePoints() throws {
        // More points for better accuracy
        let result = try engine.evaluate("""
            local y = {0, 0.0625, 0.25, 0.5625, 1}  -- x^2 at x = 0, 0.25, 0.5, 0.75, 1
            local result = math.integrate.simps(y, nil, 0.25)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0/3.0, accuracy: 1e-10)
    }

    // MARK: - trapz Tests

    func testTrapzArray() throws {
        // Trapezoidal rule for y = x sampled at 0, 1
        let result = try engine.evaluate("""
            local y = {0, 1}
            local result = math.integrate.trapz(y, nil, 1)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
    }

    func testTrapzWithXArray() throws {
        let result = try engine.evaluate("""
            local x = {0, 0.5, 1}
            local y = {0, 0.5, 1}  -- y = x
            local result = math.integrate.trapz(y, x)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
    }

    func testTrapzNonUniform() throws {
        let result = try engine.evaluate("""
            local x = {0, 0.25, 1}  -- Non-uniform spacing
            local y = {0, 0.25, 1}  -- y = x
            local result = math.integrate.trapz(y, x)
            return result
            """)
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
    }

    // MARK: - Namespace Tests

    func testMathIntegrateNamespace() throws {
        let result = try engine.evaluate("return type(math.integrate)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathIntegrateQuadExists() throws {
        let result = try engine.evaluate("return type(math.integrate.quad)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathIntegrateDblquadExists() throws {
        let result = try engine.evaluate("return type(math.integrate.dblquad)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathIntegrateTplquadExists() throws {
        let result = try engine.evaluate("return type(math.integrate.tplquad)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathIntegrateRombergExists() throws {
        let result = try engine.evaluate("return type(math.integrate.romberg)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathIntegrateSimpsExists() throws {
        let result = try engine.evaluate("return type(math.integrate.simps)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathIntegrateTrapzExists() throws {
        let result = try engine.evaluate("return type(math.integrate.trapz)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLuaswiftIntegrateNamespace() throws {
        let result = try engine.evaluate("return type(luaswift.integrate)")
        XCTAssertEqual(result.stringValue, "table")
    }

    // MARK: - Known Integrals

    func testKnownIntegralSinSquared() throws {
        // Integral of sin^2(x) from 0 to pi = pi/2
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return math.sin(x)^2 end, 0, math.pi)
            return result
            """)
        XCTAssertEqual(result.numberValue!, Double.pi / 2, accuracy: 1e-8)
    }

    func testKnownIntegralOneOverX() throws {
        // Integral of 1/x from 1 to e = 1
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return 1/x end, 1, math.exp(1))
            return result
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-8)
    }

    func testKnownIntegralSqrtOneMinusX2() throws {
        // Integral of sqrt(1-x^2) from -1 to 1 = pi/2 (area of semicircle)
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(
                function(x) return math.sqrt(1 - x^2) end, -1, 1
            )
            return result
            """)
        XCTAssertEqual(result.numberValue!, Double.pi / 2, accuracy: 1e-6)
    }
}
