//
//  MathExprModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-04.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class MathExprModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        MathExprModule.register(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Tokenizer Tests

    func testTokenizeSimpleNumber() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("42")
            return {count = #tokens, type = tokens[1].type, value = tokens[1].value}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["count"]?.numberValue, 1)
        XCTAssertEqual(table["type"]?.stringValue, "number")
        XCTAssertEqual(table["value"]?.numberValue, 42)
    }

    func testTokenizeDecimalNumber() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("3.14159")
            return {count = #tokens, value = tokens[1].value}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["count"]?.numberValue, 1)
        XCTAssertEqual(table["value"]?.numberValue ?? 0, 3.14159, accuracy: 1e-10)
    }

    func testTokenizeScientificNotation() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("1.5e-3")
            return {count = #tokens, value = tokens[1].value}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["count"]?.numberValue, 1)
        XCTAssertEqual(table["value"]?.numberValue ?? 0, 0.0015, accuracy: 1e-10)
    }

    func testTokenizeSimpleExpression() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("2+3")
            return #tokens
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testTokenizeOperators() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("a+b-c*d/e^f")
            local ops = {}
            for _, t in ipairs(tokens) do
                if t.type == "operator" then
                    table.insert(ops, t.value)
                end
            end
            return ops
        """)

        guard let ops = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(ops.count, 5)
        XCTAssertEqual(ops[0].stringValue, "+")
        XCTAssertEqual(ops[1].stringValue, "-")
        XCTAssertEqual(ops[2].stringValue, "*")
        XCTAssertEqual(ops[3].stringValue, "/")
        XCTAssertEqual(ops[4].stringValue, "^")
    }

    func testTokenizeParentheses() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("(a+b)*c")
            local types = {}
            for _, t in ipairs(tokens) do
                table.insert(types, t.type)
            end
            return types
        """)

        guard let types = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(types.count, 7)
        XCTAssertEqual(types[0].stringValue, "lparen")
        XCTAssertEqual(types[4].stringValue, "rparen")
    }

    func testTokenizeFunctions() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("sin(x)")
            return {
                func_type = tokens[1].type,
                func_name = tokens[1].value,
                var_type = tokens[3].type,
                var_name = tokens[3].value
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["func_type"]?.stringValue, "function")
        XCTAssertEqual(table["func_name"]?.stringValue, "sin")
        XCTAssertEqual(table["var_type"]?.stringValue, "variable")
        XCTAssertEqual(table["var_name"]?.stringValue, "x")
    }

    func testTokenizeConstants() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("pi*r^2")
            return {
                const_type = tokens[1].type,
                const_name = tokens[1].value
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["const_type"]?.stringValue, "constant")
        XCTAssertEqual(table["const_name"]?.stringValue, "pi")
    }

    func testTokenizeAllKnownFunctions() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local funcs = {"sin", "cos", "tan", "sqrt", "abs", "log", "exp"}
            local all_ok = true
            for _, f in ipairs(funcs) do
                local tokens = mathexpr.tokenize(f .. "(x)")
                if tokens[1].type ~= "function" then
                    all_ok = false
                end
            end
            return all_ok
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testTokenizeWhitespace() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local t1 = mathexpr.tokenize("2+3")
            local t2 = mathexpr.tokenize("2 + 3")
            local t3 = mathexpr.tokenize("  2  +  3  ")
            return {#t1, #t2, #t3}
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr[0].numberValue, 3)
        XCTAssertEqual(arr[1].numberValue, 3)
        XCTAssertEqual(arr[2].numberValue, 3)
    }

    // MARK: - Parser Tests

    func testParseSimpleAddition() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("2+3")
            local ast = mathexpr.parse(tokens)
            return {
                type = ast.type,
                op = ast.op,
                left_value = ast.left.value,
                right_value = ast.right.value
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["type"]?.stringValue, "binop")
        XCTAssertEqual(table["op"]?.stringValue, "+")
        XCTAssertEqual(table["left_value"]?.numberValue, 2)
        XCTAssertEqual(table["right_value"]?.numberValue, 3)
    }

    func testParseOperatorPrecedence() throws {
        // 2+3*4 should be parsed as 2+(3*4)
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("2+3*4")
            local ast = mathexpr.parse(tokens)
            return {
                outer_op = ast.op,
                left_val = ast.left.value,
                inner_op = ast.right.op,
                inner_left = ast.right.left.value,
                inner_right = ast.right.right.value
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["outer_op"]?.stringValue, "+")
        XCTAssertEqual(table["left_val"]?.numberValue, 2)
        XCTAssertEqual(table["inner_op"]?.stringValue, "*")
    }

    func testParseFunctionCall() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("sin(x)")
            local ast = mathexpr.parse(tokens)
            return {
                type = ast.type,
                name = ast.name,
                arg_type = ast.args[1].type,
                arg_name = ast.args[1].name
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["type"]?.stringValue, "call")
        XCTAssertEqual(table["name"]?.stringValue, "sin")
        XCTAssertEqual(table["arg_type"]?.stringValue, "variable")
        XCTAssertEqual(table["arg_name"]?.stringValue, "x")
    }

    // MARK: - Evaluation Tests

    func testEvalSimpleExpression() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("2+3")
        """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testEvalWithVariable() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("x+5", {x = 10})
        """)

        XCTAssertEqual(result.numberValue, 15)
    }

    func testEvalQuadraticFormula() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("x^2 + 2*x + 1", {x = 3})
        """)

        XCTAssertEqual(result.numberValue, 16) // 9 + 6 + 1
    }

    func testEvalWithConstants() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("2*pi")
        """)

        XCTAssertEqual(result.numberValue ?? 0, 2 * Double.pi, accuracy: 1e-10)
    }

    func testEvalSinFunction() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("sin(pi/2)")
        """)

        XCTAssertEqual(result.numberValue ?? 0, 1, accuracy: 1e-10)
    }

    func testEvalCosFunction() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("cos(0)")
        """)

        XCTAssertEqual(result.numberValue ?? 0, 1, accuracy: 1e-10)
    }

    func testEvalSqrtFunction() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("sqrt(16)")
        """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testEvalPowerOperator() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("2^10")
        """)

        XCTAssertEqual(result.numberValue, 1024)
    }

    func testEvalNegativeNumber() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("-5")
        """)

        XCTAssertEqual(result.numberValue, -5)
    }

    func testEvalUnaryMinus() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("-x", {x = 3})
        """)

        XCTAssertEqual(result.numberValue, -3)
    }

    func testEvalComplexExpression() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("(a+b)*(c-d)", {a=1, b=2, c=10, d=3})
        """)

        XCTAssertEqual(result.numberValue, 21) // (1+2) * (10-3) = 3 * 7
    }

    // MARK: - Compile Tests

    func testCompileFunction() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local f = mathexpr.compile("x^2")
            return {f(0), f(1), f(2), f(3)}
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr[0].numberValue, 0)
        XCTAssertEqual(arr[1].numberValue, 1)
        XCTAssertEqual(arr[2].numberValue, 4)
        XCTAssertEqual(arr[3].numberValue, 9)
    }

    func testCompileSinFunction() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local f = mathexpr.compile("sin(x)")
            return {f(0), f(math.pi/2), f(math.pi)}
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr[0].numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(arr[1].numberValue ?? 0, 1, accuracy: 1e-10)
        XCTAssertEqual(arr[2].numberValue ?? 0, 0, accuracy: 1e-10)
    }

    func testCompileWithVariableTable() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local f = mathexpr.compile("a*x + b")
            return f({x=5, a=2, b=3})
        """)

        XCTAssertEqual(result.numberValue, 13) // 2*5 + 3
    }

    // MARK: - Constants Tests

    func testConstantPi() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("pi")
        """)

        XCTAssertEqual(result.numberValue ?? 0, Double.pi, accuracy: 1e-10)
    }

    func testConstantE() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("e")
        """)

        XCTAssertEqual(result.numberValue ?? 0, M_E, accuracy: 1e-10)
    }

    // MARK: - Module Availability Tests

    func testRequireMathExpr() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testTopLevelAlias() throws {
        let result = try engine.evaluate("""
            return mathexpr_module ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }
}
