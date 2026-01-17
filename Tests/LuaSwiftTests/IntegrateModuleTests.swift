//
//  IntegrateModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

#if LUASWIFT_NUMERICSWIFT
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

    // MARK: - solve_ivp Tests

    func testSolveIvpExponentialDecay() throws {
        // dy/dt = -y, y(0) = 1 => y(t) = e^(-t)
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-y[1]} end,
                {0, 1},
                {1}
            )
            return sol.y[#sol.y][1]
            """)
        // y(1) = e^(-1) ≈ 0.3679
        XCTAssertEqual(result.numberValue!, exp(-1), accuracy: 1e-4)
    }

    func testSolveIvpSuccess() throws {
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-y[1]} end,
                {0, 1},
                {1}
            )
            return sol.success
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSolveIvpSimpleOscillator() throws {
        // Simple harmonic oscillator: y'' = -y
        // System: y' = v, v' = -y
        // y(0) = 1, v(0) = 0 => y(t) = cos(t), v(t) = -sin(t)
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y)
                    return {y[2], -y[1]}
                end,
                {0, math.pi},
                {1, 0}
            )
            return sol.y[#sol.y][1]
            """)
        // y(pi) = cos(pi) = -1
        XCTAssertEqual(result.numberValue!, -1.0, accuracy: 1e-3)
    }

    func testSolveIvpOscillatorVelocity() throws {
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y)
                    return {y[2], -y[1]}
                end,
                {0, math.pi/2},
                {1, 0}
            )
            return sol.y[#sol.y][2]
            """)
        // v(pi/2) = -sin(pi/2) = -1
        XCTAssertEqual(result.numberValue!, -1.0, accuracy: 1e-3)
    }

    func testSolveIvpWithTEval() throws {
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-y[1]} end,
                {0, 1},
                {1},
                {t_eval = {0, 0.5, 1}}
            )
            return #sol.t
            """)
        XCTAssertEqual(result.numberValue!, 3)
    }

    func testSolveIvpTEvalValues() throws {
        // Use tighter tolerances to force smaller steps for better interpolation
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-y[1]} end,
                {0, 1},
                {1},
                {t_eval = {0, 0.5, 1}, rtol = 1e-6, atol = 1e-9}
            )
            return sol.y[2][1]
            """)
        // y(0.5) = e^(-0.5) ≈ 0.6065
        // Linear interpolation has some inherent error, use relaxed tolerance
        XCTAssertEqual(result.numberValue!, exp(-0.5), accuracy: 0.05)
    }

    func testSolveIvpRK4Method() throws {
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-y[1]} end,
                {0, 1},
                {1},
                {method = "RK4"}
            )
            return sol.y[#sol.y][1]
            """)
        XCTAssertEqual(result.numberValue!, exp(-1), accuracy: 1e-4)
    }

    func testSolveIvpLotkaVolterra() throws {
        // Classic predator-prey model
        // dx/dt = ax - bxy, dy/dt = -cy + dxy
        let result = try engine.evaluate("""
            local function lotka_volterra(t, y)
                local a, b, c, d = 1.5, 1, 3, 1
                return {
                    a * y[1] - b * y[1] * y[2],
                    -c * y[2] + d * y[1] * y[2]
                }
            end
            local sol = math.integrate.solve_ivp(
                lotka_volterra,
                {0, 2},
                {10, 5}
            )
            return sol.success
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSolveIvpBackwardIntegration() throws {
        // Backward integration: from t=1 to t=0
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-y[1]} end,
                {1, 0},
                {math.exp(-1)}
            )
            return sol.y[#sol.y][1]
            """)
        // Going backward from y(1)=e^(-1), should get y(0)=1
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-3)
    }

    func testSolveIvpNfev() throws {
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-y[1]} end,
                {0, 1},
                {1}
            )
            return sol.nfev
            """)
        // Should have positive number of function evaluations
        XCTAssertGreaterThan(result.numberValue!, 0)
    }

    // MARK: - odeint Tests

    func testOdeintExponentialDecay() throws {
        // dy/dt = -y, y(0) = 1 => y(t) = e^(-t)
        // Note: odeint uses f(y, t) convention
        let result = try engine.evaluate("""
            local function f(y, t)
                return {-y[1]}
            end
            local t = {0, 0.5, 1}
            local y = math.integrate.odeint(f, {1}, t)
            return y[3][1]
            """)
        // y(1) = e^(-1)
        XCTAssertEqual(result.numberValue!, exp(-1), accuracy: 1e-4)
    }

    func testOdeintMidpoint() throws {
        let result = try engine.evaluate("""
            local function f(y, t)
                return {-y[1]}
            end
            local t = {0, 0.5, 1}
            local y = math.integrate.odeint(f, {1}, t)
            return y[2][1]
            """)
        // y(0.5) = e^(-0.5)
        XCTAssertEqual(result.numberValue!, exp(-0.5), accuracy: 1e-4)
    }

    func testOdeintInitialCondition() throws {
        let result = try engine.evaluate("""
            local function f(y, t)
                return {-y[1]}
            end
            local t = {0, 1}
            local y = math.integrate.odeint(f, {1}, t)
            return y[1][1]
            """)
        // y(0) = 1 (initial condition preserved)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testOdeintHarmonicOscillator() throws {
        // y'' = -y => system: y' = v, v' = -y
        let result = try engine.evaluate("""
            local function f(y, t)
                return {y[2], -y[1]}
            end
            local t = {}
            for i = 0, 100 do
                t[i + 1] = i * math.pi / 100
            end
            local y = math.integrate.odeint(f, {1, 0}, t)
            return y[#y][1]
            """)
        // y(pi) = cos(pi) = -1
        XCTAssertEqual(result.numberValue!, -1.0, accuracy: 1e-3)
    }

    func testOdeintLinearGrowth() throws {
        // dy/dt = 1, y(0) = 0 => y(t) = t
        let result = try engine.evaluate("""
            local function f(y, t)
                return {1}
            end
            local t = {0, 1, 2, 3}
            local y = math.integrate.odeint(f, {0}, t)
            return y[4][1]
            """)
        // y(3) = 3
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-6)
    }

    func testOdeintFullOutput() throws {
        let result = try engine.evaluate("""
            local function f(y, t)
                return {-y[1]}
            end
            local t = {0, 1}
            local y, info = math.integrate.odeint(f, {1}, t, {full_output = true})
            return info.nfe
            """)
        // Should have positive number of function evaluations
        XCTAssertGreaterThan(result.numberValue!, 0)
    }

    func testOdeintWithArgs() throws {
        // dy/dt = k*y, with k passed as additional argument
        let result = try engine.evaluate("""
            local function f(y, t, k)
                return {k * y[1]}
            end
            local t = {0, 1}
            local y = math.integrate.odeint(f, {1}, t, {args = {-2}})
            return y[2][1]
            """)
        // y(1) = e^(-2) ≈ 0.1353
        XCTAssertEqual(result.numberValue!, exp(-2), accuracy: 1e-4)
    }

    func testOdeintVanDerPol() throws {
        // Van der Pol oscillator: x'' - mu(1-x^2)x' + x = 0
        // System: x' = y, y' = mu(1-x^2)y - x
        let result = try engine.evaluate("""
            local mu = 0.5
            local function f(y, t)
                return {y[2], mu * (1 - y[1]^2) * y[2] - y[1]}
            end
            local t = {}
            for i = 0, 100 do
                t[i + 1] = i * 0.1
            end
            local y = math.integrate.odeint(f, {2, 0}, t)
            -- Just verify it completes without error and returns values
            return #y
            """)
        XCTAssertEqual(result.numberValue!, 101)
    }

    // MARK: - ODE Namespace Tests

    func testMathIntegrateSolveIvpExists() throws {
        let result = try engine.evaluate("return type(math.integrate.solve_ivp)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathIntegrateOdeintExists() throws {
        let result = try engine.evaluate("return type(math.integrate.odeint)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLuaswiftIntegrateSolveIvpExists() throws {
        let result = try engine.evaluate("return type(luaswift.integrate.solve_ivp)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLuaswiftIntegrateOdeintExists() throws {
        let result = try engine.evaluate("return type(luaswift.integrate.odeint)")
        XCTAssertEqual(result.stringValue, "function")
    }

    // MARK: - ODE Edge Cases

    func testSolveIvpStiffSystem() throws {
        // A mildly stiff system to verify solver handles it
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-15 * y[1]} end,
                {0, 1},
                {1},
                {rtol = 1e-6, atol = 1e-9}
            )
            return sol.y[#sol.y][1]
            """)
        // y(1) = e^(-15) ≈ 3.06e-7
        XCTAssertEqual(result.numberValue!, exp(-15), accuracy: 1e-6)
    }

    func testSolveIvpMaxStep() throws {
        let result = try engine.evaluate("""
            local sol = math.integrate.solve_ivp(
                function(t, y) return {-y[1]} end,
                {0, 1},
                {1},
                {max_step = 0.1}
            )
            -- With max_step=0.1, should have at least 10 steps
            return #sol.t
            """)
        XCTAssertGreaterThanOrEqual(result.numberValue!, 10)
    }

    func testOdeintManyTimePoints() throws {
        let result = try engine.evaluate("""
            local function f(y, t)
                return {-y[1]}
            end
            local t = {}
            for i = 0, 1000 do
                t[i + 1] = i / 1000
            end
            local y = math.integrate.odeint(f, {1}, t)
            return y[1001][1]
            """)
        // y(1) = e^(-1)
        XCTAssertEqual(result.numberValue!, exp(-1), accuracy: 1e-4)
    }

    // MARK: - Complex Integration Tests

    func testQuadComplexExponential() throws {
        // Integral of e^(ix) from 0 to π
        // ∫₀^π e^(ix) dx = [e^(ix)/i]₀^π = (e^(iπ) - 1)/i = (-1 - 1)/i = -2/i = 2i
        let result = try engine.evaluate("""
            local function f(x)
                -- e^(ix) = cos(x) + i*sin(x)
                return {re = math.cos(x), im = math.sin(x)}
            end
            local result, err = math.integrate.quad(f, 0, math.pi)
            return result
            """)
        // Should return complex {re ≈ 0, im ≈ 2}
        guard let table = result.tableValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(table["re"]?.numberValue ?? 999, 0, accuracy: 1e-8)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 2, accuracy: 1e-8)
    }

    func testQuadComplexPolynomial() throws {
        // Integral of (1 + ix) from 0 to 1
        // ∫₀¹ (1 + ix) dx = [x + ix²/2]₀¹ = 1 + i/2
        let result = try engine.evaluate("""
            local function f(x)
                return {re = 1, im = x}
            end
            local result, err = math.integrate.quad(f, 0, 1)
            return result
            """)
        guard let table = result.tableValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(table["re"]?.numberValue ?? 0, 1.0, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 0.5, accuracy: 1e-10)
    }

    func testQuadComplexSine() throws {
        // Integral of sin(x) + i*cos(x) from 0 to π/2
        // ∫₀^(π/2) sin(x) dx = 1, ∫₀^(π/2) cos(x) dx = 1
        // Result: 1 + i
        let result = try engine.evaluate("""
            local function f(x)
                return {re = math.sin(x), im = math.cos(x)}
            end
            local result, err = math.integrate.quad(f, 0, math.pi/2)
            return result
            """)
        guard let table = result.tableValue else {
            XCTFail("Expected complex result")
            return
        }
        XCTAssertEqual(table["re"]?.numberValue ?? 0, 1.0, accuracy: 1e-8)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 1.0, accuracy: 1e-8)
    }

    func testQuadRealIntegrandStillWorks() throws {
        // Verify real integrands still return real numbers
        let result = try engine.evaluate("""
            local result, err = math.integrate.quad(function(x) return x^2 end, 0, 1)
            return type(result)
            """)
        XCTAssertEqual(result.stringValue, "number")
    }
}
#endif  // LUASWIFT_NUMERICSWIFT
