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
}
