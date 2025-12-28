//
//  LuaEngineTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//

import XCTest
@testable import LuaSwift

final class LuaEngineTests: XCTestCase {

    // MARK: - Initialization Tests

    func testEngineCreation() throws {
        let engine = try LuaEngine()
        XCTAssertNotNil(engine)
    }

    func testEngineWithDefaultConfig() throws {
        let engine = try LuaEngine(configuration: .default)
        XCTAssertTrue(engine.configuration.sandboxed)
    }

    func testEngineWithUnrestrictedConfig() throws {
        let engine = try LuaEngine(configuration: .unrestricted)
        XCTAssertFalse(engine.configuration.sandboxed)
    }

    // MARK: - Basic Execution Tests

    func testReturnNumber() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return 42")
        XCTAssertEqual(result.numberValue, 42)
    }

    func testReturnString() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return 'hello'")
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testReturnBoolean() throws {
        let engine = try LuaEngine()

        let trueResult = try engine.execute("return true")
        XCTAssertEqual(trueResult.boolValue, true)

        let falseResult = try engine.execute("return false")
        XCTAssertEqual(falseResult.boolValue, false)
    }

    func testReturnNil() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return nil")
        XCTAssertTrue(result.isNil)
    }

    // MARK: - Arithmetic Tests

    func testAddition() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return 1 + 2")
        XCTAssertEqual(result.numberValue, 3)
    }

    func testMultiplication() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return 6 * 7")
        XCTAssertEqual(result.numberValue, 42)
    }

    func testFloatArithmetic() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return 3.14 * 2")
        XCTAssertEqual(result.numberValue!, 6.28, accuracy: 0.001)
    }

    // MARK: - String Operations

    func testStringConcatenation() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return 'hello' .. ' ' .. 'world'")
        XCTAssertEqual(result.stringValue, "hello world")
    }

    func testStringLength() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return #'hello'")
        XCTAssertEqual(result.numberValue, 5)
    }

    // MARK: - Table Tests

    func testReturnSimpleTable() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return { name = 'John', age = 30 }")

        XCTAssertNotNil(result.tableValue)
        XCTAssertEqual(result.tableValue?["name"]?.stringValue, "John")
        XCTAssertEqual(result.tableValue?["age"]?.numberValue, 30)
    }

    func testReturnArray() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return { 1, 2, 3, 4, 5 }")

        XCTAssertNotNil(result.arrayValue)
        XCTAssertEqual(result.arrayValue?.count, 5)
        XCTAssertEqual(result.arrayValue?[0].numberValue, 1)
        XCTAssertEqual(result.arrayValue?[4].numberValue, 5)
    }

    func testExecuteForTable() throws {
        let engine = try LuaEngine()
        let result = try engine.executeForTable("return { x = 10, y = 20 }")

        XCTAssertEqual(result["x"]?.numberValue, 10)
        XCTAssertEqual(result["y"]?.numberValue, 20)
    }

    func testExecuteForArray() throws {
        let engine = try LuaEngine()
        let result = try engine.executeForArray("return { 'a', 'b', 'c' }")

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].stringValue, "a")
        XCTAssertEqual(result[2].stringValue, "c")
    }

    // MARK: - Math Library Tests

    func testMathSqrt() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return math.sqrt(16)")
        XCTAssertEqual(result.numberValue, 4)
    }

    func testMathSin() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return math.sin(0)")
        XCTAssertEqual(result.numberValue!, 0, accuracy: 0.0001)
    }

    func testMathPi() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("return math.pi")
        XCTAssertEqual(result.numberValue!, 3.14159265, accuracy: 0.00001)
    }

    // MARK: - Random Seeding Tests

    func testRandomSeedReproducibility() throws {
        let engine1 = try LuaEngine()
        try engine1.seed(12345)
        let result1 = try engine1.execute("return math.random()")

        let engine2 = try LuaEngine()
        try engine2.seed(12345)
        let result2 = try engine2.execute("return math.random()")

        XCTAssertEqual(result1.numberValue, result2.numberValue)
    }

    func testRandomRange() throws {
        let engine = try LuaEngine()
        try engine.seed(42)
        let result = try engine.execute("return math.random(1, 100)")

        XCTAssertNotNil(result.numberValue)
        XCTAssertGreaterThanOrEqual(result.numberValue!, 1)
        XCTAssertLessThanOrEqual(result.numberValue!, 100)
    }

    // MARK: - Sandbox Tests

    func testSandboxBlocksOsExecute() throws {
        let engine = try LuaEngine(configuration: .default)

        XCTAssertThrowsError(try engine.execute("os.execute('echo test')")) { error in
            guard case LuaError.runtimeError = error else {
                XCTFail("Expected runtime error")
                return
            }
        }
    }

    func testSandboxBlocksIo() throws {
        let engine = try LuaEngine(configuration: .default)

        XCTAssertThrowsError(try engine.execute("io.open('test.txt')")) { error in
            guard case LuaError.runtimeError = error else {
                XCTFail("Expected runtime error")
                return
            }
        }
    }

    func testSandboxAllowsMath() throws {
        let engine = try LuaEngine(configuration: .default)
        let result = try engine.execute("return math.abs(-5)")
        XCTAssertEqual(result.numberValue, 5)
    }

    func testSandboxAllowsString() throws {
        let engine = try LuaEngine(configuration: .default)
        let result = try engine.execute("return string.upper('hello')")
        XCTAssertEqual(result.stringValue, "HELLO")
    }

    func testSandboxAllowsTable() throws {
        let engine = try LuaEngine(configuration: .default)
        let result = try engine.execute("""
            local t = {3, 1, 4, 1, 5}
            table.sort(t)
            return t[1]
        """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - Error Tests

    func testSyntaxError() throws {
        let engine = try LuaEngine()

        XCTAssertThrowsError(try engine.execute("return 1 +")) { error in
            guard case LuaError.syntaxError = error else {
                XCTFail("Expected syntax error")
                return
            }
        }
    }

    func testRuntimeError() throws {
        let engine = try LuaEngine()

        XCTAssertThrowsError(try engine.execute("return undefined_variable.method()")) { error in
            guard case LuaError.runtimeError = error else {
                XCTFail("Expected runtime error")
                return
            }
        }
    }

    func testTypeErrorForTable() throws {
        let engine = try LuaEngine()

        XCTAssertThrowsError(try engine.executeForTable("return 42")) { error in
            guard case LuaError.typeError = error else {
                XCTFail("Expected type error")
                return
            }
        }
    }

    // MARK: - Complex Script Tests

    func testLocalVariables() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("""
            local x = 10
            local y = 20
            return x + y
        """)
        XCTAssertEqual(result.numberValue, 30)
    }

    func testFunctionDefinitionAndCall() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("""
            local function square(n)
                return n * n
            end
            return square(7)
        """)
        XCTAssertEqual(result.numberValue, 49)
    }

    func testForLoop() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("""
            local sum = 0
            for i = 1, 10 do
                sum = sum + i
            end
            return sum
        """)
        XCTAssertEqual(result.numberValue, 55)
    }

    func testWhileLoop() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("""
            local n = 1
            while n < 1000 do
                n = n * 2
            end
            return n
        """)
        XCTAssertEqual(result.numberValue, 1024)
    }

    func testConditionals() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("""
            local x = 42
            if x > 50 then
                return 'big'
            elseif x > 20 then
                return 'medium'
            else
                return 'small'
            end
        """)
        XCTAssertEqual(result.stringValue, "medium")
    }

    func testRecursion() throws {
        let engine = try LuaEngine()
        let result = try engine.execute("""
            local function factorial(n)
                if n <= 1 then
                    return 1
                else
                    return n * factorial(n - 1)
                end
            end
            return factorial(10)
        """)
        XCTAssertEqual(result.numberValue, 3628800)
    }

    // MARK: - Problem Generation Simulation

    func testProblemGeneratorPattern() throws {
        let engine = try LuaEngine()
        try engine.seed(42)

        let result = try engine.executeForTable("""
            local a = math.random(1, 10)
            local b = math.random(1, 10)
            return {
                question = a .. " + " .. b .. " = ?",
                answer = a + b,
                operands = { a, b }
            }
        """)

        XCTAssertNotNil(result["question"]?.stringValue)
        XCTAssertNotNil(result["answer"]?.numberValue)
        XCTAssertNotNil(result["operands"]?.arrayValue)
    }
}
