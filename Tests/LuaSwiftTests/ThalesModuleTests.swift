//
//  ThalesModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-04-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_THALES
  import XCTest
  @testable import LuaSwift

  final class ThalesModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      engine = try! LuaEngine()
      ModuleRegistry.installThalesModule(in: engine)
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    // MARK: - Module Loading

    func testRequireThales() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        return cas ~= nil
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    func testRequireLuaswiftCas() throws {
      let result = try engine.evaluate(
        """
        local cas = require("luaswift.cas")
        return cas ~= nil
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    func testMathCasNamespace() throws {
      let result = try engine.evaluate(
        """
        return math.cas ~= nil and math.cas.available == true
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Simplification

    func testSimplify() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.simplify("x + x + x")
        return r.expression
        """)
      XCTAssertNotNil(result.stringValue)
      // Thales should simplify x + x + x to 3*x or equivalent
      let expr = result.stringValue!
      XCTAssertTrue(expr.contains("3") && expr.contains("x"),
                     "Expected simplified form containing 3 and x, got: \(expr)")
    }

    func testSimplifyReturnsTable() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.simplify("2*x + 3*x")
        return type(r) == "table" and r.original ~= nil and r.expression ~= nil and r.latex ~= nil
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    func testSimplifyTrig() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.simplify_trig("sin(x)^2 + cos(x)^2")
        return r.expression
        """)
      XCTAssertNotNil(result.stringValue)
    }

    // MARK: - Equation Solving

    func testSolveLinear() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        return cas.solve("2*x + 5 = 13", "x")
        """)
      XCTAssertNotNil(result.stringValue)
    }

    func testSolveDefaultVariable() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        return cas.solve("x + 1 = 3")
        """)
      XCTAssertNotNil(result.stringValue)
    }

    func testSolveWithValues() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.solve("F = m * a", "a", {F = 100, m = 20})
        return type(r) == "table" and r.success == true
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    func testSolveNumerically() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.solve_numerically("x^2 - 2 = 0", "x", 1.0)
        return r
        """)
      XCTAssertNotNil(result.numberValue)
      let root = result.numberValue!
      XCTAssertEqual(root, sqrt(2.0), accuracy: 1e-6)
    }

    func testSolveSystem() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.solve_system({"x + y = 10", "x - y = 4"})
        return r
        """)
      XCTAssertNotNil(result.stringValue)
    }

    func testSolveInequality() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.solve_inequality("2*x + 1 > 5", "x")
        return r
        """)
      XCTAssertNotNil(result.stringValue)
    }

    // MARK: - Calculus

    func testDifferentiate() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.differentiate("x^3", "x")
        return type(r) == "table" and r.expression ~= nil and r.latex ~= nil
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    func testDiffAlias() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        return cas.diff == cas.differentiate
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    func testNthDerivative() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.nth_derivative("x^4", "x", 2)
        return r.expression
        """)
      XCTAssertNotNil(result.stringValue)
    }

    func testIntegrate() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.integrate("2*x", "x")
        return type(r) == "table" and r.expression ~= nil and r.success ~= nil
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    func testDefiniteIntegral() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.definite_integral("x^2", "x", 0, 1)
        return r.numeric_value
        """)
      XCTAssertNotNil(result.numberValue)
      XCTAssertEqual(result.numberValue!, 1.0 / 3.0, accuracy: 1e-6)
    }

    func testLimit() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.limit("sin(x)/x", "x", 0)
        return r.expression
        """)
      XCTAssertNotNil(result.stringValue)
    }

    func testLimitToInfinity() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.limit_to_infinity("1/x", "x")
        return r.expression
        """)
      XCTAssertNotNil(result.stringValue)
    }

    func testGradient() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.gradient("x^2 + y^2", {"x", "y"})
        return r
        """)
      XCTAssertNotNil(result.stringValue)
    }

    // MARK: - Series

    func testTaylor() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.taylor("sin(x)", "x", 0, 5)
        return type(r) == "table" and r.expression ~= nil and r.center ~= nil
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    func testMaclaurin() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.maclaurin("exp(x)", "x", 4)
        return r.expression
        """)
      XCTAssertNotNil(result.stringValue)
    }

    func testLaurent() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.laurent("1/x + x", "x", 0, 1, 2)
        return type(r) == "table" and r.expression ~= nil
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Formatting

    func testToLatex() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        return cas.to_latex("x^2 + 1")
        """)
      XCTAssertNotNil(result.stringValue)
    }

    func testParseLatex() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        return cas.parse_latex("\\\\frac{x}{2}")
        """)
      XCTAssertNotNil(result.stringValue)
    }

    // MARK: - Evaluation

    func testEvaluate() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        return cas.evaluate("x^2 + 1", {x = 3})
        """)
      XCTAssertNotNil(result.numberValue)
      XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    func testEvaluateNoValues() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        return cas.evaluate("2 + 3")
        """)
      XCTAssertNotNil(result.numberValue)
      XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    // MARK: - ODE

    func testSolveODE() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.solve_ode("y", "y", "x")
        return type(r) == "table" and r.solution ~= nil and r.method ~= nil
        """)
      XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Partial Fractions

    func testPartialFractions() throws {
      let result = try engine.evaluate(
        """
        local cas = require("thales")
        local r = cas.partial_fractions("1", "x^2 - 1", "x")
        return r
        """)
      XCTAssertNotNil(result.stringValue)
    }

    // MARK: - Error Handling

    func testSimplifyErrorOnBadInput() throws {
      do {
        _ = try engine.evaluate(
          """
          local cas = require("thales")
          return cas.simplify()
          """)
        XCTFail("Expected error for missing argument")
      } catch {
        // Expected — callback should throw on missing argument
      }
    }

    func testSolveErrorOnBadInput() throws {
      do {
        _ = try engine.evaluate(
          """
          local cas = require("thales")
          return cas.solve()
          """)
        XCTFail("Expected error for missing argument")
      } catch {
        // Expected
      }
    }
  }
#endif  // LUASWIFT_THALES
