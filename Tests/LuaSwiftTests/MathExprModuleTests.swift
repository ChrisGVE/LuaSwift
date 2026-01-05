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

    // MARK: - Extended Functions Tests

    func testEvalAsinh() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("asinh(0)")
        """)

        XCTAssertEqual(result.numberValue ?? 0, 0, accuracy: 1e-10)
    }

    func testEvalAcosh() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("acosh(1)")
        """)

        XCTAssertEqual(result.numberValue ?? 0, 0, accuracy: 1e-10)
    }

    func testEvalAtanh() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("atanh(0)")
        """)

        XCTAssertEqual(result.numberValue ?? 0, 0, accuracy: 1e-10)
    }

    func testEvalTrunc() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return {
                mathexpr.eval("trunc(3.7)"),
                mathexpr.eval("trunc(-3.7)")
            }
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr[0].numberValue, 3)
        XCTAssertEqual(arr[1].numberValue, -3)
    }

    // MARK: - Multi-Argument Function Tests

    func testEvalAtan2() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("atan2(1, 1)")
        """)

        XCTAssertEqual(result.numberValue ?? 0, Double.pi / 4, accuracy: 1e-10)
    }

    func testEvalPow() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("pow(2, 10)")
        """)

        XCTAssertEqual(result.numberValue, 1024)
    }

    func testEvalMin() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("min(5, 3)")
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testEvalMax() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("max(5, 3)")
        """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testEvalClamp() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return {
                mathexpr.eval("clamp(5, 0, 10)"),
                mathexpr.eval("clamp(-5, 0, 10)"),
                mathexpr.eval("clamp(15, 0, 10)")
            }
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr[0].numberValue, 5)   // Within range
        XCTAssertEqual(arr[1].numberValue, 0)   // Below min
        XCTAssertEqual(arr[2].numberValue, 10)  // Above max
    }

    func testEvalLerp() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return {
                mathexpr.eval("lerp(0, 10, 0)"),
                mathexpr.eval("lerp(0, 10, 0.5)"),
                mathexpr.eval("lerp(0, 10, 1)")
            }
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr[0].numberValue, 0)   // t=0 returns a
        XCTAssertEqual(arr[1].numberValue, 5)   // t=0.5 returns midpoint
        XCTAssertEqual(arr[2].numberValue, 10)  // t=1 returns b
    }

    func testEvalNestedMultiArgFunctions() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("clamp(lerp(0, 20, 0.75), 5, 10)")
        """)

        // lerp(0, 20, 0.75) = 15, clamp(15, 5, 10) = 10
        XCTAssertEqual(result.numberValue, 10)
    }

    func testTokenizeNewFunctions() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local funcs = {"asinh", "acosh", "atanh", "trunc", "clamp", "lerp"}
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

    // MARK: - Solve Tests

    func testSolveWithoutSteps() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.solve("(2+3)*4")
        """)

        XCTAssertEqual(result.numberValue, 20)
    }

    func testSolveWithStepsSimple() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local steps = mathexpr.solve("2+3", {show_steps = true})
            return {
                count = #steps,
                first_op = steps[1].operation,
                second_op = steps[2].operation,
                third_op = steps[3].operation,
                result = steps[3].result
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["count"]?.numberValue, 3)
        XCTAssertEqual(table["first_op"]?.stringValue, "initial")
        XCTAssertEqual(table["second_op"]?.stringValue, "binop")
        XCTAssertEqual(table["third_op"]?.stringValue, "result")
        XCTAssertEqual(table["result"]?.numberValue, 5)
    }

    func testSolveWithStepsComplex() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local steps = mathexpr.solve("(2+3)*4", {show_steps = true})
            return {
                count = #steps,
                add_desc = steps[2].description,
                add_result = steps[2].result,
                mul_desc = steps[3].description,
                mul_result = steps[3].result,
                final_result = steps[4].result
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["count"]?.numberValue, 4)
        XCTAssertEqual(table["add_desc"]?.stringValue, "2 + 3")
        XCTAssertEqual(table["add_result"]?.numberValue, 5)
        XCTAssertEqual(table["mul_desc"]?.stringValue, "5 × 4")
        XCTAssertEqual(table["mul_result"]?.numberValue, 20)
        XCTAssertEqual(table["final_result"]?.numberValue, 20)
    }

    func testSolveWithVariables() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local steps = mathexpr.solve("x^2 + 2*x", {
                show_steps = true,
                variables = {x = 3}
            })
            return {
                count = #steps,
                final_result = steps[#steps].result
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertTrue((table["count"]?.numberValue ?? 0) > 2)
        XCTAssertEqual(table["final_result"]?.numberValue, 15)
    }

    func testSolveWithFunction() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local steps = mathexpr.solve("sqrt(16)", {show_steps = true})
            local func_step = steps[2]
            return {
                count = #steps,
                operation = func_step.operation,
                description = func_step.description,
                result = func_step.result,
                final_result = steps[#steps].result
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["count"]?.numberValue, 3)
        XCTAssertEqual(table["operation"]?.stringValue, "call")
        XCTAssertEqual(table["description"]?.stringValue, "sqrt(16)")
        XCTAssertEqual(table["result"]?.numberValue, 4)
        XCTAssertEqual(table["final_result"]?.numberValue, 4)
    }

    func testSolveStepOperands() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local steps = mathexpr.solve("10-3", {show_steps = true})
            local binop_step = steps[2]
            return {
                operand1 = binop_step.operands[1],
                operand2 = binop_step.operands[2],
                result = binop_step.result
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["operand1"]?.numberValue, 10)
        XCTAssertEqual(table["operand2"]?.numberValue, 3)
        XCTAssertEqual(table["result"]?.numberValue, 7)
    }

    func testSolveWithPrecision() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local steps = mathexpr.solve("1/3", {
                show_steps = true,
                significantDigits = 2
            })
            return {
                final_subexpr = steps[#steps].subexpression
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["final_subexpr"]?.stringValue, "0.33")
    }

    func testSolveSubexpression() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local steps = mathexpr.solve("2*3+4", {show_steps = true})
            return {
                initial_subexpr = steps[1].subexpression,
                mul_subexpr = steps[2].subexpression,
                add_subexpr = steps[3].subexpression
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["initial_subexpr"]?.stringValue, "2*3+4")
        XCTAssertEqual(table["mul_subexpr"]?.stringValue, "2 * 3")
        XCTAssertEqual(table["add_subexpr"]?.stringValue, "6 + 4")
    }
}
