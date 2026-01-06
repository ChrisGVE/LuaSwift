//
//  OptimizeModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class OptimizeModuleTests: XCTestCase {
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

    // MARK: - minimize_scalar Tests

    func testMinimizeScalarGoldenQuadratic() throws {
        // f(x) = (x-2)^2 has minimum at x=2
        let result = try engine.evaluate("""
            local result = math.optimize.minimize_scalar(
                function(x) return (x - 2)^2 end,
                {method = "golden", bracket = {0, 4}}
            )
            return result.x
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-6)
    }

    func testMinimizeScalarBrentQuadratic() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.minimize_scalar(
                function(x) return (x - 3)^2 end,
                {method = "brent", bracket = {0, 6}}
            )
            return result.x
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-6)
    }

    func testMinimizeScalarBrentSin() throws {
        // sin(x) has minimum at x = 3π/2 ≈ 4.71 in [0, 2π]
        let result = try engine.evaluate("""
            local result = math.optimize.minimize_scalar(
                function(x) return math.sin(x) end,
                {method = "brent", bracket = {3, 6}}
            )
            return result.x
            """)
        XCTAssertEqual(result.numberValue!, 3 * Double.pi / 2, accuracy: 1e-5)
    }

    func testMinimizeScalarConvergence() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.minimize_scalar(
                function(x) return (x - 5)^2 end,
                {bracket = {0, 10}}
            )
            return result.success and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testMinimizeScalarFunctionValue() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.minimize_scalar(
                function(x) return (x - 2)^2 + 1 end,
                {bracket = {0, 4}}
            )
            return result.fun
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-6)
    }

    // MARK: - root_scalar Tests

    func testRootScalarBisectSquareRoot() throws {
        // Find sqrt(2): x^2 - 2 = 0
        let result = try engine.evaluate("""
            local result = math.optimize.root_scalar(
                function(x) return x^2 - 2 end,
                {method = "bisect", bracket = {1, 2}}
            )
            return result.root
            """)
        XCTAssertEqual(result.numberValue!, sqrt(2), accuracy: 1e-6)
    }

    func testRootScalarNewton() throws {
        // Find cube root of 8: x^3 - 8 = 0
        let result = try engine.evaluate("""
            local result = math.optimize.root_scalar(
                function(x) return x^3 - 8 end,
                {method = "newton", x0 = 3}
            )
            return result.root
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-6)
    }

    func testRootScalarSecant() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.root_scalar(
                function(x) return x^2 - 9 end,
                {method = "secant", x0 = 2, x1 = 4}
            )
            return result.root
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-6)
    }

    func testRootScalarBrentq() throws {
        // Find root of cos(x) - x = 0 (Dottie number ≈ 0.739)
        let result = try engine.evaluate("""
            local result = math.optimize.root_scalar(
                function(x) return math.cos(x) - x end,
                {method = "brentq", bracket = {0, 1}}
            )
            return result.root
            """)
        XCTAssertEqual(result.numberValue!, 0.7390851332151607, accuracy: 1e-6)
    }

    func testRootScalarConverged() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.root_scalar(
                function(x) return x^2 - 4 end,
                {bracket = {0, 5}}
            )
            return result.converged and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testRootScalarNoSignChange() throws {
        // Should fail if bracket doesn't contain root
        let result = try engine.evaluate("""
            local result = math.optimize.root_scalar(
                function(x) return x^2 + 1 end,
                {method = "bisect", bracket = {0, 5}}
            )
            return result.converged and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 0)
    }

    // MARK: - minimize Tests (Nelder-Mead)

    func testMinimizeQuadratic2D() throws {
        // f(x) = (x1 - 1)^2 + (x2 - 2)^2 has minimum at (1, 2)
        let result = try engine.evaluate("""
            local result = math.optimize.minimize(
                function(x) return (x[1] - 1)^2 + (x[2] - 2)^2 end,
                {0, 0}
            )
            return result.x[1] + result.x[2]
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-4)
    }

    func testMinimizeRosenbrock() throws {
        // Rosenbrock function: f(x,y) = (a-x)^2 + b(y-x^2)^2, minimum at (a,a^2)
        // With a=1, b=100, minimum is at (1,1)
        let result = try engine.evaluate("""
            local result = math.optimize.minimize(
                function(x)
                    local a, b = 1, 100
                    return (a - x[1])^2 + b * (x[2] - x[1]^2)^2
                end,
                {0, 0},
                {maxiter = 5000}
            )
            return result.x[1]
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 0.1)  // Rosenbrock is hard, relax tolerance
    }

    func testMinimize3D() throws {
        // f(x) = x1^2 + x2^2 + x3^2 has minimum at origin
        let result = try engine.evaluate("""
            local result = math.optimize.minimize(
                function(x) return x[1]^2 + x[2]^2 + x[3]^2 end,
                {1, 2, 3}
            )
            return result.fun
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-6)
    }

    func testMinimizeConvergence() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.minimize(
                function(x) return x[1]^2 + x[2]^2 end,
                {5, 5}
            )
            return result.success and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testMinimizeFunctionValue() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.minimize(
                function(x) return (x[1] - 1)^2 + (x[2] - 2)^2 + 10 end,
                {0, 0}
            )
            return result.fun
            """)
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-4)
    }

    // MARK: - root Tests (Systems)

    func testRootLinearSystem() throws {
        // Solve: x1 + x2 = 3, x1 - x2 = 1
        // Solution: x1 = 2, x2 = 1
        let result = try engine.evaluate("""
            local result = math.optimize.root(
                function(x) return {x[1] + x[2] - 3, x[1] - x[2] - 1} end,
                {0, 0}
            )
            return result.x[1] + result.x[2]
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-6)
    }

    func testRootNonlinearSystem() throws {
        // Solve: x^2 + y^2 = 1, x - y = 0
        // Solution: x = y = 1/sqrt(2)
        let result = try engine.evaluate("""
            local result = math.optimize.root(
                function(x) return {x[1]^2 + x[2]^2 - 1, x[1] - x[2]} end,
                {0.5, 0.5}
            )
            return result.x[1]
            """)
        let expected = 1.0 / sqrt(2)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-6)
    }

    func testRootConvergence() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.root(
                function(x) return {x[1] - 1, x[2] - 2} end,
                {0, 0}
            )
            return result.success and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testRootResidual() throws {
        // Check that the function value at the root is close to zero
        let result = try engine.evaluate("""
            local result = math.optimize.root(
                function(x) return {x[1]^2 - 4, x[2] - 3} end,
                {1, 1}
            )
            return math.abs(result.fun[1]) + math.abs(result.fun[2])
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-6)
    }

    // MARK: - Namespace Tests

    func testMathOptimizeNamespace() throws {
        let result = try engine.evaluate("return type(math.optimize)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathOptimizeMinimizeScalarExists() throws {
        let result = try engine.evaluate("return type(math.optimize.minimize_scalar)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathOptimizeRootScalarExists() throws {
        let result = try engine.evaluate("return type(math.optimize.root_scalar)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathOptimizeMinimizeExists() throws {
        let result = try engine.evaluate("return type(math.optimize.minimize)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testMathOptimizeRootExists() throws {
        let result = try engine.evaluate("return type(math.optimize.root)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLuaswiftOptimizeNamespace() throws {
        let result = try engine.evaluate("return type(luaswift.optimize)")
        XCTAssertEqual(result.stringValue, "table")
    }

    // MARK: - Result Fields Tests

    func testMinimizeScalarResultFields() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.minimize_scalar(
                function(x) return x^2 end,
                {bracket = {-1, 1}}
            )
            return (result.x ~= nil and result.fun ~= nil and
                    result.success ~= nil and result.message ~= nil and
                    result.nfev ~= nil and result.nit ~= nil) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testRootScalarResultFields() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.root_scalar(
                function(x) return x end,
                {bracket = {-1, 1}}
            )
            return (result.root ~= nil and result.converged ~= nil and
                    result.message ~= nil and result.iterations ~= nil and
                    result.function_calls ~= nil) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testMinimizeResultFields() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.minimize(
                function(x) return x[1]^2 end,
                {1}
            )
            return (result.x ~= nil and result.fun ~= nil and
                    result.success ~= nil and result.message ~= nil and
                    result.nfev ~= nil and result.nit ~= nil) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testRootResultFields() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.root(
                function(x) return {x[1]} end,
                {1}
            )
            return (result.x ~= nil and result.fun ~= nil and
                    result.success ~= nil and result.message ~= nil and
                    result.nfev ~= nil and result.nit ~= nil) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - Edge Cases

    func testMinimizeScalarAtBoundary() throws {
        // Minimum of x^2 at boundary of [0, 10] should be at 0
        let result = try engine.evaluate("""
            local result = math.optimize.minimize_scalar(
                function(x) return x^2 end,
                {bracket = {0, 10}}
            )
            return result.x
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-6)
    }

    func testRootScalarTightBracket() throws {
        let result = try engine.evaluate("""
            local result = math.optimize.root_scalar(
                function(x) return x - 1 end,
                {method = "bisect", bracket = {0.9, 1.1}}
            )
            return result.root
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-6)
    }

    // MARK: - least_squares Tests

    func testLeastSquaresLinearResiduals() throws {
        // Fit y = a*x + b to data points
        // Residuals: r_i = y_i - (a*x_i + b)
        // Data: (0,1), (1,3), (2,5) -> perfect fit with a=2, b=1
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2}
            local ydata = {1, 3, 5}

            local function residuals(p)
                local r = {}
                for i = 1, #xdata do
                    r[i] = ydata[i] - (p[1] * xdata[i] + p[2])
                end
                return r
            end

            local result = math.optimize.least_squares(residuals, {0, 0})
            return result.x[1] + result.x[2]  -- a + b = 2 + 1 = 3
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-4)
    }

    func testLeastSquaresQuadraticResiduals() throws {
        // Fit y = a*x^2 to data points
        let result = try engine.evaluate("""
            local xdata = {1, 2, 3, 4}
            local ydata = {1, 4, 9, 16}  -- y = x^2, so a = 1

            local function residuals(p)
                local r = {}
                for i = 1, #xdata do
                    r[i] = ydata[i] - p[1] * xdata[i]^2
                end
                return r
            end

            local result = math.optimize.least_squares(residuals, {0.5})
            return result.x[1]
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-4)
    }

    func testLeastSquaresExponentialResiduals() throws {
        // Fit y = a * exp(b*x) to data
        // y = 2 * exp(0.5*x)
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2, 3}
            local ydata = {2, 2*math.exp(0.5), 2*math.exp(1), 2*math.exp(1.5)}

            local function residuals(p)
                local r = {}
                for i = 1, #xdata do
                    r[i] = ydata[i] - p[1] * math.exp(p[2] * xdata[i])
                end
                return r
            end

            local result = math.optimize.least_squares(residuals, {1, 0.3})
            return result.x[1]  -- Should be close to 2
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 0.1)
    }

    func testLeastSquaresNoisyData() throws {
        // Fit y = a*x + b with noisy data
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2, 3, 4, 5}
            -- True: y = 2x + 1, with small noise
            local ydata = {1.1, 2.9, 5.1, 6.9, 9.1, 10.9}

            local function residuals(p)
                local r = {}
                for i = 1, #xdata do
                    r[i] = ydata[i] - (p[1] * xdata[i] + p[2])
                end
                return r
            end

            local result = math.optimize.least_squares(residuals, {0, 0})
            return result.x[1]  -- Should be close to 2
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 0.2)
    }

    func testLeastSquaresConvergence() throws {
        let result = try engine.evaluate("""
            local function residuals(p)
                return {p[1] - 1, p[2] - 2}
            end
            local result = math.optimize.least_squares(residuals, {0, 0})
            return result.success and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testLeastSquaresResultFields() throws {
        let result = try engine.evaluate("""
            local function residuals(p)
                return {p[1] - 1}
            end
            local result = math.optimize.least_squares(residuals, {0})
            return (result.x ~= nil and result.cost ~= nil and
                    result.fun ~= nil and result.jac ~= nil and
                    result.success ~= nil and result.message ~= nil and
                    result.nfev ~= nil and result.njev ~= nil) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testLeastSquaresCost() throws {
        // Cost should be sum of squared residuals / 2
        let result = try engine.evaluate("""
            local function residuals(p)
                return {p[1] - 1, p[2] - 2}
            end
            local result = math.optimize.least_squares(residuals, {1, 2})
            -- At optimal point, residuals are 0, so cost is 0
            return result.cost
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testLeastSquaresWithBounds() throws {
        // Fit with bounds - constrain a to be positive
        let result = try engine.evaluate("""
            local function residuals(p)
                return {p[1] + 5}  -- Wants p[1] = -5, but bounded to >= 0
            end
            local result = math.optimize.least_squares(residuals, {1}, {
                bounds = {lower = {0}, upper = {10}}
            })
            return result.x[1]  -- Should be at lower bound: 0
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-4)
    }

    func testLeastSquaresNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.optimize.least_squares)")
        XCTAssertEqual(result.stringValue, "function")
    }

    // MARK: - curve_fit Tests

    func testCurveFitLinear() throws {
        // Fit y = a*x + b
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2, 3, 4}
            local ydata = {1, 3, 5, 7, 9}  -- y = 2x + 1

            local function f(x, params)
                return params[1] * x + params[2]
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {0, 0})
            return popt[1] + popt[2]  -- a + b = 2 + 1 = 3
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 0.1)
    }

    func testCurveFitQuadratic() throws {
        // Fit y = a*x^2 + b*x + c
        let result = try engine.evaluate("""
            local xdata = {-2, -1, 0, 1, 2}
            local ydata = {4, 1, 0, 1, 4}  -- y = x^2

            local function f(x, params)
                return params[1] * x^2 + params[2] * x + params[3]
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {0.5, 0, 0})
            return popt[1]  -- Should be 1
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 0.1)
    }

    func testCurveFitExponential() throws {
        // Fit y = a * exp(b*x)
        let result = try engine.evaluate("""
            local xdata = {0, 0.5, 1, 1.5, 2}
            -- y = 3 * exp(0.5 * x)
            local ydata = {}
            for i, x in ipairs(xdata) do
                ydata[i] = 3 * math.exp(0.5 * x)
            end

            local function f(x, params)
                return params[1] * math.exp(params[2] * x)
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {1, 0.3})
            return popt[1]  -- Should be close to 3
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 0.2)
    }

    func testCurveFitSinusoidal() throws {
        // Fit y = a * sin(b*x + c)
        let result = try engine.evaluate("""
            local xdata = {}
            local ydata = {}
            -- y = 2 * sin(x) -- amplitude=2, frequency=1, phase=0
            for i = 1, 20 do
                local x = (i - 1) * 0.3
                xdata[i] = x
                ydata[i] = 2 * math.sin(x)
            end

            local function f(x, params)
                return params[1] * math.sin(params[2] * x)
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {1.5, 0.8})
            return popt[1]  -- Should be close to 2
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 0.3)
    }

    func testCurveFitGaussian() throws {
        // Fit y = a * exp(-(x-mu)^2 / (2*sigma^2))
        let result = try engine.evaluate("""
            local xdata = {}
            local ydata = {}
            -- Gaussian with a=5, mu=2, sigma=1
            for i = 1, 21 do
                local x = (i - 1) * 0.25
                xdata[i] = x
                ydata[i] = 5 * math.exp(-(x - 2)^2 / 2)
            end

            local function f(x, params)
                local a, mu, sigma = params[1], params[2], params[3]
                return a * math.exp(-(x - mu)^2 / (2 * sigma^2))
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {3, 1.5, 0.8})
            return popt[2]  -- mu, should be close to 2
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 0.3)
    }

    func testCurveFitReturnsPcov() throws {
        // Verify covariance matrix is returned
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2, 3, 4}
            local ydata = {1, 3, 5, 7, 9}

            local function f(x, params)
                return params[1] * x + params[2]
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {0, 0})
            -- Check pcov is a 2x2 matrix
            return (type(pcov) == "table" and type(pcov[1]) == "table" and
                    type(pcov[2]) == "table" and #pcov == 2) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testCurveFitReturnsInfo() throws {
        // Verify info table is returned with expected fields
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2, 3}
            local ydata = {0, 1, 2, 3}

            local function f(x, params)
                return params[1] * x
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {0.5})
            return (info.success ~= nil and info.message ~= nil and
                    info.nfev ~= nil) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testCurveFitConvergence() throws {
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2}
            local ydata = {0, 1, 2}

            local function f(x, params)
                return params[1] * x
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {0.5})
            return info.success and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testCurveFitExpandedForm() throws {
        // Test calling f(x, p1, p2, ...) instead of f(x, params)
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2, 3}
            local ydata = {1, 3, 5, 7}  -- y = 2x + 1

            local function f(x, a, b)
                return a * x + b
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {0, 0})
            return popt[1]  -- Should be 2
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 0.1)
    }

    func testCurveFitWithNoisyData() throws {
        // Fitting with noisy data
        let result = try engine.evaluate("""
            local xdata = {0, 1, 2, 3, 4, 5}
            -- True: y = 3*x, with noise
            local ydata = {0.2, 2.8, 6.1, 9.2, 11.8, 15.1}

            local function f(x, params)
                return params[1] * x
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {1})
            return popt[1]  -- Should be close to 3
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 0.3)
    }

    func testCurveFitNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.optimize.curve_fit)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testCurveFitPolynomial() throws {
        // Fit cubic polynomial y = a*x^3 + b*x^2 + c*x + d
        let result = try engine.evaluate("""
            local xdata = {-2, -1, 0, 1, 2}
            -- y = x^3 - 2x^2 + x + 1
            -- Correct values: -17, -3, 1, 1, 3
            local ydata = {-17, -3, 1, 1, 3}

            local function f(x, params)
                return params[1]*x^3 + params[2]*x^2 + params[3]*x + params[4]
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {0.5, -1, 0.5, 0.5})
            return popt[4]  -- d constant term, should be 1
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 0.3)
    }

    func testCurveFitPowerLaw() throws {
        // Fit y = a * x^b
        let result = try engine.evaluate("""
            local xdata = {1, 2, 3, 4, 5}
            -- y = 2 * x^1.5
            local ydata = {}
            for i, x in ipairs(xdata) do
                ydata[i] = 2 * x^1.5
            end

            local function f(x, params)
                return params[1] * x^params[2]
            end

            local popt, pcov, info = math.optimize.curve_fit(f, xdata, ydata, {1, 1})
            return popt[1]  -- Should be close to 2
            """)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 0.2)
    }
}
