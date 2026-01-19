//
//  MathExprModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-04.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
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

    // MARK: - Equation Solving Tests

    func testSolveLinearEquation() throws {
        // solve("2*x + 3 = 7") should find x = 2
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("2*x + 3 = 7")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 2, accuracy: 1e-10)
    }

    func testSolveLinearEquationNegativeSolution() throws {
        // solve("3*x + 9 = 0") should find x = -3
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("3*x + 9 = 0")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, -3, accuracy: 1e-10)
    }

    func testSolveEquationWithKnownVariables() throws {
        // solve("a*x + b = c", {a = 2, b = 3, c = 7}) should find x = 2
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("a*x + b = c", {a = 2, b = 3, c = 7})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 2, accuracy: 1e-10)
    }

    func testSolveEquationVariablesAsSecondArg() throws {
        // Clean API: solve("x + y = 10", {y = 3}) should find x = 7
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("x + y = 10", {y = 3})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 7, accuracy: 1e-10)
    }

    func testSolveEquationVariableOnRightSide() throws {
        // solve("10 = x + 3") should find x = 7
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("10 = x + 3")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 7, accuracy: 1e-10)
    }

    func testSolveEquationVariableBothSides() throws {
        // solve("2*x + 5 = x + 10") should find x = 5
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("2*x + 5 = x + 10")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 5, accuracy: 1e-10)
    }

    func testSolveQuadraticEquation() throws {
        // solve("x^2 = 4") should find x = 2 (or -2, depending on initial guess)
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("x^2 = 4", nil, {initial_guess = 1})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 2, accuracy: 1e-6)
    }

    func testSolveQuadraticEquationNegativeRoot() throws {
        // solve("x^2 = 4", nil, {initial_guess = -1}) should find x = -2
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("x^2 = 4", nil, {initial_guess = -1})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, -2, accuracy: 1e-6)
    }

    func testSolveTrigEquation() throws {
        // solve("sin(x) = 0.5") should find x = pi/6 ~ 0.5236 (with appropriate initial guess)
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("sin(x) = 0.5", nil, {initial_guess = 0.5})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, Double.pi / 6, accuracy: 1e-6)
    }

    func testSolveEquationWithFunctions() throws {
        // solve("sqrt(x) = 3") should find x = 9
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("sqrt(x) = 3", nil, {initial_guess = 5})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 9, accuracy: 1e-6)
    }

    func testSolveSystemTwoEquations() throws {
        // solve({"x + y = 5", "x - y = 1"}) should find x = 3, y = 2
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve({"x + y = 5", "x - y = 1"})
            return {x = solution.x, y = solution.y}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["x"]?.numberValue ?? 0, 3, accuracy: 1e-10)
        XCTAssertEqual(table["y"]?.numberValue ?? 0, 2, accuracy: 1e-10)
    }

    func testSolveSystemWithKnownVariable() throws {
        // solve({"x + y + z = 10", "x - y = 2"}, {z = 1}) should find x, y given z = 1
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve({"x + y + z = 10", "x - y = 2"}, {z = 1})
            return {x = solution.x, y = solution.y}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // x + y + 1 = 10 => x + y = 9
        // x - y = 2
        // Adding: 2x = 11 => x = 5.5, y = 3.5
        XCTAssertEqual(table["x"]?.numberValue ?? 0, 5.5, accuracy: 1e-10)
        XCTAssertEqual(table["y"]?.numberValue ?? 0, 3.5, accuracy: 1e-10)
    }

    func testSolveVerifyEquation() throws {
        // When no unknowns, solve should verify the equation
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local result = mathexpr.solve("2 + 3 = 5")
            return result.satisfied
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSolveVerifyEquationFalse() throws {
        // When no unknowns and equation is false
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local result = mathexpr.solve("2 + 3 = 6")
            return result.satisfied
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testSolveWithSolveForOption() throws {
        // solve_for option to specify which variable to solve for
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("a*x + b = 0", {x = 2, b = 4}, {solve_for = "a"})
            return solution.a
        """)

        // 2a + 4 = 0 => a = -2
        XCTAssertEqual(result.numberValue ?? 0, -2, accuracy: 1e-10)
    }

    func testSolveWithDivision() throws {
        // solve("x/2 = 5") should find x = 10
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("x/2 = 5")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 10, accuracy: 1e-10)
    }

    func testSolveWithMultiplication() throws {
        // solve("3*x = 15") should find x = 5
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("3*x = 15")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 5, accuracy: 1e-10)
    }

    func testSolveWithConstants() throws {
        // solve("x = 2*pi") should find x = 2*pi
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("x = 2*pi")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 2 * Double.pi, accuracy: 1e-10)
    }

    func testSolveEquationNoSolution() throws {
        // solve("0*x = 5") has no solution (contradiction)
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("0*x = 5")
            return solution.error or "no error"
        """)

        XCTAssertEqual(result.stringValue, "no solution (contradiction)")
    }

    func testSolveEquationInfiniteSolutions() throws {
        // solve("0*x = 0") has infinite solutions (identity)
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("0*x = 0")
            return solution.error or "no error"
        """)

        XCTAssertEqual(result.stringValue, "infinite solutions (identity)")
    }

    func testSolveMultipleUnknownsError() throws {
        // solve("x + y = 5") with two unknowns should error
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local ok, err = pcall(function()
                return mathexpr.solve("x + y = 5")
            end)
            if ok then
                return "no error"
            else
                return err:match("multiple unknowns") ~= nil
            end
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSolveReservedOptionsNotTreatedAsVariables() throws {
        // Ensure initial_guess is not treated as a variable named "initial_guess"
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("x^2 = 9", {initial_guess = 2})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 3, accuracy: 1e-6)
    }

    func testSolveComplexLinearExpression() throws {
        // solve("2*(x + 3) - 4 = x + 5") => 2x + 6 - 4 = x + 5 => 2x + 2 = x + 5 => x = 3
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("2*(x + 3) - 4 = x + 5")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 3, accuracy: 1e-10)
    }

    func testSolveWithNegativeCoefficient() throws {
        // solve("-x + 5 = 2") should find x = 3
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("-x + 5 = 2")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 3, accuracy: 1e-10)
    }

    func testSolveExponentialEquation() throws {
        // solve("exp(x) = e") should find x = 1
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("exp(x) = e", nil, {initial_guess = 0.5})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 1, accuracy: 1e-6)
    }

    func testSolveLogarithmicEquation() throws {
        // solve("log(x) = 0") should find x = 1
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local solution = mathexpr.solve("log(x) = 0", nil, {initial_guess = 0.5})
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 1, accuracy: 1e-6)
    }

    // MARK: - math.eval Callable API Tests

    func testMathEvalCallable() throws {
        // Test that math.eval is callable via __call
        // First register MathSciModule to create the namespace
        MathSciModule.register(in: engine)

        let result = try engine.evaluate("""
            -- math.eval should be callable
            return math.eval("2 + 3")
        """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testMathEvalCallableWithVariables() throws {
        MathSciModule.register(in: engine)

        let result = try engine.evaluate("""
            return math.eval("x^2 + 1", {x = 3})
        """)

        XCTAssertEqual(result.numberValue, 10)
    }

    func testMathEvalDotSolve() throws {
        MathSciModule.register(in: engine)

        let result = try engine.evaluate("""
            local solution = math.eval.solve("2*x = 6")
            return solution.x
        """)

        XCTAssertEqual(result.numberValue ?? 0, 3, accuracy: 1e-10)
    }

    // MARK: - Nested Scoping Tests

    func testNestedScopingSimple() throws {
        // "x + y" with x having its own y scope
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("x + y", {
                x = {"exp(y)", {y = "ln(3)"}},
                y = 6
            })
        """)

        // x = exp(ln(3)) = 3, y = 6, so x + y = 9
        XCTAssertEqual(result.numberValue ?? 0, 9, accuracy: 1e-10)
    }

    func testNestedScopingDeep() throws {
        // Deep nesting: a = b^2 where b = c + 1 where c = 2
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("a", {
                a = {"b^2", {
                    b = {"c + 1", {c = 2}}
                }}
            })
        """)

        // c=2, b=3, a=9
        XCTAssertEqual(result.numberValue ?? 0, 9, accuracy: 1e-10)
    }

    func testSameLevelIndependentVariables() throws {
        // Variables at same level are independent - both use same y
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("x + y", {x = "exp(y)", y = "ln(3)"})
        """)

        // Both x and y use y=ln(3), so exp(ln(3)) + ln(3) = 3 + ln(3)
        let expected = 3 + log(3.0)
        XCTAssertEqual(result.numberValue ?? 0, expected, accuracy: 1e-10)
    }

    // MARK: - Symbolic Substitution Tests

    func testSubstituteSimple() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local ast = mathexpr.parse(mathexpr.tokenize("x^2"))
            local sub_ast = mathexpr.substitute(ast, {x = "ln(3)"})
            return mathexpr.to_string(sub_ast)
        """)

        XCTAssertEqual(result.stringValue, "ln(3) ^ 2")
    }

    func testSubstitutePartial() throws {
        // Variable y remains unsubstituted
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local ast = mathexpr.parse(mathexpr.tokenize("x + y"))
            local sub_ast = mathexpr.substitute(ast, {x = "sin(z)"})
            return mathexpr.to_string(sub_ast)
        """)

        XCTAssertEqual(result.stringValue, "sin(z) + y")
    }

    func testSubstituteWithNumber() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local ast = mathexpr.parse(mathexpr.tokenize("x + 1"))
            local sub_ast = mathexpr.substitute(ast, {x = 5})
            return mathexpr.to_string(sub_ast)
        """)

        XCTAssertEqual(result.stringValue, "5 + 1")
    }

    // MARK: - AST to_string Tests

    func testToStringSimple() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local ast = mathexpr.parse(mathexpr.tokenize("x + y"))
            return mathexpr.to_string(ast)
        """)

        XCTAssertEqual(result.stringValue, "x + y")
    }

    func testToStringWithFunction() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local ast = mathexpr.parse(mathexpr.tokenize("sin(x)"))
            return mathexpr.to_string(ast)
        """)

        XCTAssertEqual(result.stringValue, "sin(x)")
    }

    func testToStringWithPrecedence() throws {
        // Test that precedence is handled correctly
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local ast = mathexpr.parse(mathexpr.tokenize("(a + b) * c"))
            return mathexpr.to_string(ast)
        """)

        // Parentheses should be added for lower precedence on left of *
        XCTAssertEqual(result.stringValue, "(a + b) * c")
    }

    func testRoundTrip() throws {
        // Test expr → AST → string → AST → eval
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local original = "sin(x)^2 + cos(x)^2"
            local ast = mathexpr.parse(mathexpr.tokenize(original))
            local reconstructed = mathexpr.to_string(ast)
            return mathexpr.eval(reconstructed, {x = 1.5})
        """)

        // sin(x)^2 + cos(x)^2 = 1 (trig identity)
        XCTAssertEqual(result.numberValue ?? 0, 1, accuracy: 1e-10)
    }

    // MARK: - Swift-backed Function Tests (NumericSwift MathExpr)

    func testParseSwift() throws {
        // Test Swift-backed parse function
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("x + 2")
            local ast = mathexpr.parse_swift(tokens)
            return {type = ast.type, op = ast.op,
                    left_type = ast.left.type, right_type = ast.right.type}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }
        XCTAssertEqual(table["type"]?.stringValue, "binop")
        XCTAssertEqual(table["op"]?.stringValue, "+")
        XCTAssertEqual(table["left_type"]?.stringValue, "variable")
        XCTAssertEqual(table["right_type"]?.stringValue, "number")
    }

    func testEvaluateSwift() throws {
        // Test Swift-backed evaluate function
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("x^2 + 2*x + 1")
            local ast = mathexpr.parse_swift(tokens)
            return mathexpr.evaluate_swift(ast, {x = 3})
        """)

        // (3)^2 + 2*(3) + 1 = 9 + 6 + 1 = 16
        XCTAssertEqual(result.numberValue, 16)
    }

    func testToStringSwift() throws {
        // Test Swift-backed to_string function
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("sin(x)")
            local ast = mathexpr.parse_swift(tokens)
            return mathexpr.to_string_swift(ast)
        """)

        XCTAssertEqual(result.stringValue, "sin(x)")
    }

    func testSubstituteSwift() throws {
        // Test Swift-backed substitute function
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("x + y")
            local ast = mathexpr.parse_swift(tokens)
            local new_ast = mathexpr.substitute_swift(ast, {x = 5})
            return mathexpr.to_string_swift(new_ast)
        """)

        XCTAssertEqual(result.stringValue, "5 + y")
    }

    func testSubstituteSwiftWithExpression() throws {
        // Test substitute with expression string
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("x + y")
            local ast = mathexpr.parse_swift(tokens)
            local new_ast = mathexpr.substitute_swift(ast, {x = "2*z"})
            return mathexpr.to_string_swift(new_ast)
        """)

        XCTAssertEqual(result.stringValue, "2 * z + y")
    }

    func testFindVariablesSwift() throws {
        // Test Swift-backed find_variables function
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("x^2 + y*z + x")
            local ast = mathexpr.parse_swift(tokens)
            local vars = mathexpr.find_variables_swift(ast)
            return {count = #vars, v1 = vars[1], v2 = vars[2], v3 = vars[3]}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }
        XCTAssertEqual(table["count"]?.numberValue, 3)
        // Variables are returned sorted: x, y, z
        XCTAssertEqual(table["v1"]?.stringValue, "x")
        XCTAssertEqual(table["v2"]?.stringValue, "y")
        XCTAssertEqual(table["v3"]?.stringValue, "z")
    }

    func testEvalSwiftConvenience() throws {
        // Test Swift-backed convenience eval function
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval_swift("sin(x)^2 + cos(x)^2", {x = 0.5})
        """)

        // sin(x)^2 + cos(x)^2 = 1 (trig identity)
        XCTAssertEqual(result.numberValue ?? 0, 1, accuracy: 1e-10)
    }

    func testEvalSwiftWithConstants() throws {
        // Test Swift evaluation with mathematical constants
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval_swift("2*pi + e")
        """)

        // 2*pi + e ≈ 6.283 + 2.718 ≈ 9.001
        XCTAssertEqual(result.numberValue ?? 0, 2 * Double.pi + M_E, accuracy: 1e-10)
    }

    func testSwiftRoundTrip() throws {
        // Test complete round-trip through Swift functions
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("sqrt(x^2 + y^2)")
            local ast = mathexpr.parse_swift(tokens)
            local str = mathexpr.to_string_swift(ast)
            -- Parse again and evaluate
            local tokens2 = mathexpr.tokenize(str)
            local ast2 = mathexpr.parse_swift(tokens2)
            return mathexpr.evaluate_swift(ast2, {x = 3, y = 4})
        """)

        // sqrt(3^2 + 4^2) = sqrt(9 + 16) = sqrt(25) = 5
        XCTAssertEqual(result.numberValue ?? 0, 5, accuracy: 1e-10)
    }

    // MARK: - AST Validation Tests

    func testInvalidASTNodeType() throws {
        // Malformed AST should be rejected
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local bad_ast = {type = "badtype"}
            local ok, err = pcall(function() return mathexpr.compile(bad_ast) end)
            return {ok = ok, has_error = err ~= nil}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }
        XCTAssertEqual(table["ok"]?.boolValue, false)
        XCTAssertEqual(table["has_error"]?.boolValue, true)
    }

    func testInvalidASTUnknownFunction() throws {
        // Unknown function in AST should be rejected
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local bad_ast = {type = "call", name = "evil_function", args = {{type = "number", value = 1}}}
            local ok, err = pcall(function() return mathexpr.compile(bad_ast) end)
            return ok
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - Compile from AST Tests

    func testCompileFromAST() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("x^2")
            local ast = mathexpr.parse(tokens)
            local f = mathexpr.compile(ast)
            return f({x = 4})
        """)

        XCTAssertEqual(result.numberValue ?? 0, 16, accuracy: 1e-10)
    }

    func testCompileFromTokens() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("x + 1")
            local f = mathexpr.compile(tokens)
            return f({x = 9})
        """)

        XCTAssertEqual(result.numberValue ?? 0, 10, accuracy: 1e-10)
    }

    // MARK: - LaTeX Summation Notation Tests

    func testLaTeXSummationGeometricSeries() throws {
        // Register series module for LaTeX summation support
        SeriesModule.register(in: engine)

        // Sum of geometric series: sum_{n=0}^{10} 1/2^n ≈ 2 - 1/2^10 ≈ 1.999
        let result = try engine.evaluate(#"""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("\\sum_{n=0}^{10} \\frac{1}{2^n}")
        """#)

        // Geometric series sum = (1 - (1/2)^11) / (1 - 1/2) = 2 - 1/1024 ≈ 1.999
        XCTAssertEqual(result.numberValue ?? 0, 2.0 - 1.0/1024.0, accuracy: 1e-10)
    }

    func testLaTeXProductFactorial() throws {
        // Register series module for LaTeX product support
        SeriesModule.register(in: engine)

        // Product: prod_{i=1}^{5} i = 5! = 120
        let result = try engine.evaluate(#"""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("\\prod_{i=1}^{5} i")
        """#)

        XCTAssertEqual(result.numberValue ?? 0, 120, accuracy: 1e-10)
    }

    func testLaTeXSummationWithExpression() throws {
        // Register series module for LaTeX summation support
        SeriesModule.register(in: engine)

        // Sum of squares: sum_{k=1}^{4} k^2 = 1 + 4 + 9 + 16 = 30
        let result = try engine.evaluate(#"""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("\\sum_{k=1}^{4} k^2")
        """#)

        XCTAssertEqual(result.numberValue ?? 0, 30, accuracy: 1e-10)
    }

    func testLaTeXProductWithFraction() throws {
        // Register series module for LaTeX product support
        SeriesModule.register(in: engine)

        // Product: prod_{n=2}^{4} (n+1)/n = 3/2 * 4/3 * 5/4 = 5/2 = 2.5
        let result = try engine.evaluate(#"""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("\\prod_{n=2}^{4} \\frac{n+1}{n}")
        """#)

        XCTAssertEqual(result.numberValue ?? 0, 2.5, accuracy: 1e-10)
    }

    func testLaTeXSummationSimple() throws {
        // Register series module for LaTeX summation support
        SeriesModule.register(in: engine)

        // Sum: sum_{i=1}^{5} i = 1 + 2 + 3 + 4 + 5 = 15
        let result = try engine.evaluate(#"""
            local mathexpr = require("luaswift.mathexpr")
            return mathexpr.eval("\\sum_{i=1}^{5} i")
        """#)

        XCTAssertEqual(result.numberValue ?? 0, 15, accuracy: 1e-10)
    }

    // MARK: - Complex Number Literal Tests

    func testTokenizeImaginaryLiteral() throws {
        // Test that 5i is tokenized as imaginary literal
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("5i")
            return {count = #tokens, type = tokens[1].type, value = tokens[1].value}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["count"]?.numberValue, 1)
        XCTAssertEqual(table["type"]?.stringValue, "imaginary")
        XCTAssertEqual(table["value"]?.numberValue, 5)
    }

    func testEvalPureImaginary() throws {
        // Test eval("5i") returns {re=0, im=5}
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("5i")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue, 0)
        XCTAssertEqual(table["im"]?.numberValue, 5)
    }

    func testEvalComplexLiteral() throws {
        // Test eval("2+3i") returns {re=2, im=3}
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("2+3i")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue, 2)
        XCTAssertEqual(table["im"]?.numberValue, 3)
    }

    func testEvalComplexSubtraction() throws {
        // Test eval("5-2i") returns {re=5, im=-2}
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("5-2i")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue, 5)
        XCTAssertEqual(table["im"]?.numberValue, -2)
    }

    func testEvalImaginaryUnit() throws {
        // Test that '1i' syntax for pure imaginary unit works
        // Note: standalone 'i' is NOT a constant to avoid conflicts with loop variables
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("1i")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue, 0)
        XCTAssertEqual(table["im"]?.numberValue, 1)
    }

    func testEvalComplexMultiplication() throws {
        // Test (2+i)*(1+i) = 2 + 2i + i + i^2 = 2 + 3i - 1 = 1 + 3i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("(2+1i)*(1+1i)")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, 1, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 3, accuracy: 1e-10)
    }

    func testEvalComplexISquared() throws {
        // Test i^2 = -1 (fundamental property of imaginary unit)
        // Using 1i syntax since standalone 'i' is not a constant
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("1i^2")
            if type(z) == "table" then
                return z.re
            else
                return z
            end
        """)

        XCTAssertEqual(result.numberValue ?? 0, -1, accuracy: 1e-10, "(1i)^2 should equal -1")
    }

    // MARK: - Complex Literal Edge Cases

    func testTokenizeDecimalImaginary() throws {
        // Test decimal imaginary: 2.5i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("2.5i")
            return {type = tokens[1].type, value = tokens[1].value}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["type"]?.stringValue, "imaginary")
        XCTAssertEqual(table["value"]?.numberValue ?? 0, 2.5, accuracy: 1e-10)
    }

    func testTokenizeScientificImaginary() throws {
        // Test scientific notation imaginary: 1e-3i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local tokens = mathexpr.tokenize("1e-3i")
            return {type = tokens[1].type, value = tokens[1].value}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["type"]?.stringValue, "imaginary")
        XCTAssertEqual(table["value"]?.numberValue ?? 0, 0.001, accuracy: 1e-15)
    }

    func testEvalComplexDivision() throws {
        // (1+2i)/(1+1i) = (1+2i)(1-1i)/((1+1i)(1-1i)) = (1-1i+2i-2i^2)/(1-i^2) = (3+1i)/2 = 1.5+0.5i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("(1+2i)/(1+1i)")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, 1.5, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 0.5, accuracy: 1e-10)
    }

    func testEvalImaginaryTimesImaginary() throws {
        // 2i * 3i = 6i^2 = -6 (pure real result)
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("2i * 3i")
            if type(z) == "table" then
                return z.re
            else
                return z
            end
        """)

        XCTAssertEqual(result.numberValue ?? 0, -6, accuracy: 1e-10)
    }

    func testEvalComplexConjugateProduct() throws {
        // (3+4i)*(3-4i) = 9 - 16i^2 = 9 + 16 = 25 (modulus squared)
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("(3+4i)*(3-4i)")
            if type(z) == "table" then
                return z.re
            else
                return z
            end
        """)

        XCTAssertEqual(result.numberValue ?? 0, 25, accuracy: 1e-10)
    }

    func testEvalNegativeImaginary() throws {
        // Test negative imaginary: -3i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("-3i")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, -3, accuracy: 1e-10)
    }

    func testEvalComplexSquare() throws {
        // (1+2i)^2 = 1 + 4i + 4i^2 = 1 + 4i - 4 = -3 + 4i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("(1+2i)^2")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, -3, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 4, accuracy: 1e-10)
    }

    func testEvalComplexCube() throws {
        // (1+1i)^3 = ((1+1i)^2)*(1+1i) = (2i)*(1+1i) = 2i + 2i^2 = -2 + 2i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("(1+1i)^3")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, -2, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 2, accuracy: 1e-10)
    }

    func testEvalComplexDivisionByReal() throws {
        // (4+6i)/2 = 2+3i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("(4+6i)/2")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, 2, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 3, accuracy: 1e-10)
    }

    func testEvalRealTimesComplex() throws {
        // 3 * (2+1i) = 6+3i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("3 * (2+1i)")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, 6, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 3, accuracy: 1e-10)
    }
}
#endif  // LUASWIFT_NUMERICSWIFT
