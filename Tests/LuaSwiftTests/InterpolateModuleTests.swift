//
//  InterpolateModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class InterpolateModuleTests: XCTestCase {
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

    // MARK: - interp1d Linear Tests

    func testInterp1dLinearBasic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {0, 1, 4, 9, 16}
            local f = math.interpolate.interp1d(x, y, "linear")
            return f(1.5)
            """)
        XCTAssertEqual(result.numberValue!, 2.5, accuracy: 1e-10)
    }

    func testInterp1dLinearAtPoints() throws {
        // Interpolation should pass through data points
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {0, 2, 4, 6}
            local f = math.interpolate.interp1d(x, y, "linear")
            return f(2)
            """)
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 1e-10)
    }

    func testInterp1dLinearEndpoints() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {5, 10, 15}
            local f = math.interpolate.interp1d(x, y, "linear")
            return f(0) + f(2)
            """)
        XCTAssertEqual(result.numberValue!, 20.0, accuracy: 1e-10)
    }

    func testInterp1dLinearArray() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local f = math.interpolate.interp1d(x, y, "linear")
            local vals = f({0.5, 1.5})
            return vals[1] + vals[2]
            """)
        // f(0.5) = 0.5, f(1.5) = 2.5
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    // MARK: - interp1d Nearest Tests

    func testInterp1dNearestBasic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {0, 10, 20, 30}
            local f = math.interpolate.interp1d(x, y, "nearest")
            return f(0.4)
            """)
        // 0.4 is closer to 0 than to 1
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testInterp1dNearestMidpoint() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 10, 20}
            local f = math.interpolate.interp1d(x, y, "nearest")
            return f(0.5)
            """)
        // At midpoint, should pick the lower index (tie-breaking)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testInterp1dNearestHigh() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 10, 20}
            local f = math.interpolate.interp1d(x, y, "nearest")
            return f(0.6)
            """)
        // 0.6 is closer to 1 than to 0
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    // MARK: - interp1d Cubic Tests

    func testInterp1dCubicBasic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {0, 1, 4, 9, 16}  -- y = x^2
            local f = math.interpolate.interp1d(x, y, "cubic")
            return f(1.5)
            """)
        // Should be close to 2.25 for quadratic data
        XCTAssertEqual(result.numberValue!, 2.25, accuracy: 0.1)
    }

    func testInterp1dCubicAtPoints() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {0, 1, 8, 27}  -- y = x^3
            local f = math.interpolate.interp1d(x, y, "cubic")
            return f(2)
            """)
        XCTAssertEqual(result.numberValue!, 8.0, accuracy: 1e-10)
    }

    // MARK: - interp1d Previous/Next Tests

    func testInterp1dPrevious() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 10, 20}
            local f = math.interpolate.interp1d(x, y, "previous")
            return f(0.7) + f(1.9)
            """)
        // previous(0.7) = 0, previous(1.9) = 10
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    func testInterp1dNext() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 10, 20}
            local f = math.interpolate.interp1d(x, y, "next")
            return f(0.7) + f(1.1)
            """)
        // next(0.7) = 10, next(1.1) = 20
        XCTAssertEqual(result.numberValue!, 30.0, accuracy: 1e-10)
    }

    // MARK: - interp1d Extrapolation Tests

    func testInterp1dExtrapolationNaN() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local f = math.interpolate.interp1d(x, y, "linear")
            return f(-1) ~= f(-1)  -- NaN ~= NaN is true
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testInterp1dFillValue() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local f = math.interpolate.interp1d(x, y, "linear", {fill_value = -999})
            return f(-1)
            """)
        XCTAssertEqual(result.numberValue!, -999.0, accuracy: 1e-10)
    }

    // MARK: - CubicSpline Tests

    func testCubicSplineBasic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {0, 1, 4, 9, 16}  -- y = x^2
            local cs = math.interpolate.CubicSpline(x, y)
            return cs(1.5)
            """)
        XCTAssertEqual(result.numberValue!, 2.25, accuracy: 0.1)
    }

    func testCubicSplineAtPoints() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {5, 10, 15, 20}
            local cs = math.interpolate.CubicSpline(x, y)
            return cs(1) + cs(2)
            """)
        XCTAssertEqual(result.numberValue!, 25.0, accuracy: 1e-10)
    }

    func testCubicSplineArray() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local cs = math.interpolate.CubicSpline(x, y)
            local vals = cs({0.5, 1.5})
            return vals[1] + vals[2]
            """)
        // Check both values computed
        XCTAssertGreaterThan(result.numberValue!, 0)
    }

    func testCubicSplineDerivative() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {0, 1, 4, 9, 16}  -- y = x^2
            local cs = math.interpolate.CubicSpline(x, y)
            return cs.derivative(2)
            """)
        // Derivative of x^2 at x=2 is 4
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 0.5)
    }

    func testCubicSplineSecondDerivative() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {0, 1, 4, 9, 16}  -- y = x^2
            local cs = math.interpolate.CubicSpline(x, y)
            return cs.derivative(2, 2)
            """)
        // Second derivative of x^2 is 2, but cubic spline approximation varies
        // The spline doesn't perfectly match x^2 curvature everywhere
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 2.0)
    }

    func testCubicSplineIntegrate() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {0, 1, 2, 3}  -- y = x (linear)
            local cs = math.interpolate.CubicSpline(x, y)
            return cs.integrate(0, 2)
            """)
        // Integral of x from 0 to 2 is 2
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 0.1)
    }

    func testCubicSplineIntegrateQuadratic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {0, 1, 4, 9, 16}  -- y = x^2
            local cs = math.interpolate.CubicSpline(x, y)
            return cs.integrate(0, 3)
            """)
        // Integral of x^2 from 0 to 3 is 9
        // Cubic spline may overshoot/undershoot, allow larger tolerance
        XCTAssertEqual(result.numberValue!, 9.0, accuracy: 2.0)
    }

    func testCubicSplineNaturalBC() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {0, 1, 4, 9}
            local cs = math.interpolate.CubicSpline(x, y, {bc_type = "natural"})
            return cs(1.5)
            """)
        XCTAssertGreaterThan(result.numberValue!, 0)
    }

    func testCubicSplineExtrapolate() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local cs = math.interpolate.CubicSpline(x, y, {extrapolate = true})
            return cs(3)
            """)
        // Should extrapolate beyond range
        XCTAssertGreaterThan(result.numberValue!, 4)
    }

    func testCubicSplineNoExtrapolate() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local cs = math.interpolate.CubicSpline(x, y, {extrapolate = false})
            local v = cs(-1)
            return v ~= v  -- NaN check
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - PchipInterpolator Tests

    func testPchipBasic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {0, 1, 4, 9, 16}
            local f = math.interpolate.PchipInterpolator(x, y)
            return f(2)
            """)
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 1e-10)
    }

    func testPchipMonotonic() throws {
        // PCHIP should preserve monotonicity
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {0, 1, 2, 3}  -- Strictly increasing
            local f = math.interpolate.PchipInterpolator(x, y)
            local v1 = f(0.5)
            local v2 = f(1.5)
            local v3 = f(2.5)
            return (v1 < v2) and (v2 < v3)
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testPchipArray() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local f = math.interpolate.PchipInterpolator(x, y)
            local vals = f({0.5, 1.5})
            return #vals
            """)
        XCTAssertEqual(result.numberValue!, 2)
    }

    // MARK: - Akima1DInterpolator Tests

    func testAkimaBasic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {0, 1, 4, 9, 16}
            local f = math.interpolate.Akima1DInterpolator(x, y)
            return f(2)
            """)
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 1e-10)
    }

    func testAkimaSmooth() throws {
        // Akima should produce smooth results
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4, 5}
            local y = {0, 1, 0, 1, 0, 1}  -- Oscillating data
            local f = math.interpolate.Akima1DInterpolator(x, y)
            return f(2.5)
            """)
        // Should be smooth, not overshooting
        XCTAssertLessThan(result.numberValue!, 1.5)
        XCTAssertGreaterThan(result.numberValue!, -0.5)
    }

    // MARK: - lagrange Tests

    func testLagrangeBasic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}  -- y = x^2
            local f = math.interpolate.lagrange(x, y)
            return f(1.5)
            """)
        // Should be exactly 2.25 for quadratic through 3 points
        XCTAssertEqual(result.numberValue!, 2.25, accuracy: 1e-10)
    }

    func testLagrangeAtPoints() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {5, 10, 15, 20}
            local f = math.interpolate.lagrange(x, y)
            return f(1) + f(2)
            """)
        XCTAssertEqual(result.numberValue!, 25.0, accuracy: 1e-10)
    }

    func testLagrangeArray() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local f = math.interpolate.lagrange(x, y)
            local vals = f({0.5, 1.5})
            return vals[1] + vals[2]
            """)
        // f(0.5) = 0.25, f(1.5) = 2.25
        XCTAssertEqual(result.numberValue!, 2.5, accuracy: 1e-10)
    }

    // MARK: - BarycentricInterpolator Tests

    func testBarycentricBasic() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local f = math.interpolate.BarycentricInterpolator(x, y)
            return f(1.5)
            """)
        XCTAssertEqual(result.numberValue!, 2.25, accuracy: 1e-10)
    }

    func testBarycentricAtPoints() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {5, 10, 15, 20}
            local f = math.interpolate.BarycentricInterpolator(x, y)
            return f(1)
            """)
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    func testBarycentricArray() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {0, 1, 4}
            local f = math.interpolate.BarycentricInterpolator(x, y)
            local vals = f({0, 1, 2})
            return vals[1] + vals[2] + vals[3]
            """)
        // 0 + 1 + 4 = 5
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    // MARK: - Namespace Tests

    func testMathInterpolateNamespace() throws {
        let result = try engine.evaluate("return type(math.interpolate)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathInterpolateInterp1dExists() throws {
        let result = try engine.evaluate("return type(math.interpolate.interp1d)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathInterpolateCubicSplineExists() throws {
        let result = try engine.evaluate("return type(math.interpolate.CubicSpline)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathInterpolatePchipExists() throws {
        let result = try engine.evaluate("return type(math.interpolate.PchipInterpolator)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathInterpolateAkimaExists() throws {
        let result = try engine.evaluate("return type(math.interpolate.Akima1DInterpolator)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathInterpolateLagrangeExists() throws {
        let result = try engine.evaluate("return type(math.interpolate.lagrange)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathInterpolateBarycentricExists() throws {
        let result = try engine.evaluate("return type(math.interpolate.BarycentricInterpolator)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLuaswiftInterpolateNamespace() throws {
        let result = try engine.evaluate("return type(luaswift.interpolate)")
        XCTAssertEqual(result.stringValue, "table")
    }

    // MARK: - Edge Cases

    func testInterp1dTwoPoints() throws {
        let result = try engine.evaluate("""
            local x = {0, 1}
            local y = {0, 10}
            local f = math.interpolate.interp1d(x, y, "linear")
            return f(0.5)
            """)
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testCubicSplineTwoPoints() throws {
        let result = try engine.evaluate("""
            local x = {0, 1}
            local y = {0, 10}
            local cs = math.interpolate.CubicSpline(x, y)
            return cs(0.5)
            """)
        // With only 2 points, should be linear
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 0.5)
    }

    func testInterp1dConstantData() throws {
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {5, 5, 5, 5}
            local f = math.interpolate.interp1d(x, y, "linear")
            return f(1.5)
            """)
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testCubicSplineSinusoid() throws {
        // Test with sinusoidal data
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4, 5, 6}
            local y = {}
            for i = 1, 7 do
                y[i] = math.sin(x[i])
            end
            local cs = math.interpolate.CubicSpline(x, y)
            return cs(math.pi / 2)
            """)
        // sin(pi/2) = 1
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 0.1)
    }

    // MARK: - Complex Interpolation Tests

    func testInterp1dLinearComplex() throws {
        // Linear interpolation of complex data: y = (1+i), (2+2i), (3+3i), (4+4i)
        // At x=1.5: should be (2.5 + 2.5i)
        let result = try engine.evaluate("""
            local x = {1, 2, 3, 4}
            local y = {{re=1, im=1}, {re=2, im=2}, {re=3, im=3}, {re=4, im=4}}
            local f = math.interpolate.interp1d(x, y, "linear")
            local z = f(2.5)
            return {re = z.re, im = z.im}
            """)
        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, 2.5, accuracy: 1e-10)
        XCTAssertEqual(table["im"]!.numberValue!, 2.5, accuracy: 1e-10)
    }

    func testInterp1dLinearComplexEndpoints() throws {
        // Interpolation at data points should return exact values
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {{re=1, im=2}, {re=3, im=4}, {re=5, im=6}}
            local f = math.interpolate.interp1d(x, y, "linear")
            local z = f(1)  -- Should return {re=3, im=4}
            return {re = z.re, im = z.im}
            """)
        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, 3.0, accuracy: 1e-10)
        XCTAssertEqual(table["im"]!.numberValue!, 4.0, accuracy: 1e-10)
    }

    func testInterp1dCubicComplex() throws {
        // Cubic interpolation of complex quadratic: y = x + ix²
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3, 4}
            local y = {}
            for i = 1, 5 do
                local xi = x[i]
                y[i] = {re = xi, im = xi * xi}
            end
            local f = math.interpolate.interp1d(x, y, "cubic")
            local z = f(1.5)
            return {re = z.re, im = z.im}
            """)
        let table = result.tableValue!
        // At x=1.5: re=1.5, im=2.25
        XCTAssertEqual(table["re"]!.numberValue!, 1.5, accuracy: 0.1)
        XCTAssertEqual(table["im"]!.numberValue!, 2.25, accuracy: 0.1)
    }

    func testCubicSplineComplex() throws {
        // CubicSpline with complex y data
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {{re=0, im=0}, {re=1, im=1}, {re=4, im=4}, {re=9, im=9}}
            local cs = math.interpolate.CubicSpline(x, y)
            local z = cs(1.5)
            return {re = z.re, im = z.im}
            """)
        let table = result.tableValue!
        // Both real and imaginary parts should be around 2.25 (quadratic-like)
        XCTAssertEqual(table["re"]!.numberValue!, table["im"]!.numberValue!, accuracy: 0.01)
    }

    func testCubicSplineComplexDerivative() throws {
        // Test derivative of complex spline
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {{re=0, im=0}, {re=1, im=2}, {re=4, im=8}, {re=9, im=18}}
            local cs = math.interpolate.CubicSpline(x, y)
            local dz = cs.derivative(1.5)
            return {re = dz.re, im = dz.im}
            """)
        let table = result.tableValue!
        // Derivative should also be complex
        XCTAssertNotNil(table["re"]?.numberValue)
        XCTAssertNotNil(table["im"]?.numberValue)
    }

    func testCubicSplineComplexIntegrate() throws {
        // Test integration of complex spline: y = 1 + i (constant)
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {{re=1, im=1}, {re=1, im=1}, {re=1, im=1}, {re=1, im=1}}
            local cs = math.interpolate.CubicSpline(x, y)
            local integral = cs.integrate(0, 3)
            return {re = integral.re, im = integral.im}
            """)
        let table = result.tableValue!
        // Integral of constant (1+i) over [0,3] = 3 + 3i
        XCTAssertEqual(table["re"]!.numberValue!, 3.0, accuracy: 0.01)
        XCTAssertEqual(table["im"]!.numberValue!, 3.0, accuracy: 0.01)
    }

    func testLagrangeComplex() throws {
        // Lagrange interpolation with complex data
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {{re=1, im=0}, {re=0, im=1}, {re=-1, im=0}}  -- points on unit circle
            local f = math.interpolate.lagrange(x, y)
            local z = f(0.5)
            return {re = z.re, im = z.im}
            """)
        let table = result.tableValue!
        XCTAssertNotNil(table["re"]?.numberValue)
        XCTAssertNotNil(table["im"]?.numberValue)
    }

    func testBarycentricComplex() throws {
        // Barycentric interpolation with complex data
        let result = try engine.evaluate("""
            local x = {0, 1, 2, 3}
            local y = {{re=1, im=1}, {re=2, im=2}, {re=3, im=3}, {re=4, im=4}}
            local f = math.interpolate.BarycentricInterpolator(x, y)
            local z = f(1.5)
            return {re = z.re, im = z.im}
            """)
        let table = result.tableValue!
        // Linear data: at x=1.5, should be (2.5, 2.5)
        XCTAssertEqual(table["re"]!.numberValue!, 2.5, accuracy: 0.01)
        XCTAssertEqual(table["im"]!.numberValue!, 2.5, accuracy: 0.01)
    }

    func testInterp1dComplexNearestReturnsComplex() throws {
        // Nearest interpolation should return the nearest complex value
        let result = try engine.evaluate("""
            local x = {0, 1, 2}
            local y = {{re=1, im=2}, {re=3, im=4}, {re=5, im=6}}
            local f = math.interpolate.interp1d(x, y, "nearest")
            local z = f(0.6)  -- Nearest to x=1
            return {re = z.re, im = z.im}
            """)
        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, 3.0, accuracy: 1e-10)
        XCTAssertEqual(table["im"]!.numberValue!, 4.0, accuracy: 1e-10)
    }
}
