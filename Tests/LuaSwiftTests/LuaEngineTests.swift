//
//  LuaEngineTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//

import XCTest
@testable import LuaSwift

// MARK: - Test Value Server

/// A test value server with both read and write support
final class TestValueServer: LuaValueServer {
    let namespace = "Test"

    // Read-only data
    private let userData: [String: LuaValue] = [
        "name": .string("John"),
        "age": .number(30)
    ]

    // Writable storage
    var cache: [String: LuaValue] = [:]

    func resolve(path: [String]) -> LuaValue {
        guard !path.isEmpty else { return .nil }

        switch path[0] {
        case "User":
            // Return .nil for intermediate paths so proxy tables are created
            // This allows __newindex to be called for read-only protection
            guard path.count > 1 else { return .nil }
            return userData[path[1]] ?? .nil

        case "Cache":
            // Return .nil for intermediate paths so proxy tables are created
            // This allows __newindex to be called for writes
            guard path.count > 1 else { return .nil }
            let key = path.dropFirst().joined(separator: ".")
            return cache[key] ?? .nil

        default:
            return .nil
        }
    }

    func canWrite(path: [String]) -> Bool {
        // Only Cache is writable
        return path.first == "Cache"
    }

    func write(path: [String], value: LuaValue) throws {
        guard path.first == "Cache", path.count >= 2 else {
            throw LuaError.readOnlyAccess(path: "Test.\(path.joined(separator: "."))")
        }
        let key = path.dropFirst().joined(separator: ".")
        cache[key] = value
    }
}

// MARK: - Engine Tests

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

    // MARK: - Basic Evaluate Tests

    func testEvaluateNumber() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return 42")
        XCTAssertEqual(result.numberValue, 42)
    }

    func testEvaluateString() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return 'hello'")
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testEvaluateBoolean() throws {
        let engine = try LuaEngine()

        let trueResult = try engine.evaluate("return true")
        XCTAssertEqual(trueResult.boolValue, true)

        let falseResult = try engine.evaluate("return false")
        XCTAssertEqual(falseResult.boolValue, false)
    }

    func testEvaluateNil() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return nil")
        XCTAssertTrue(result.isNil)
    }

    // MARK: - Run Tests

    func testRunNoReturn() throws {
        let engine = try LuaEngine()
        // Should not throw
        try engine.run("local x = 1 + 2")
    }

    func testRunIgnoresReturnValue() throws {
        let engine = try LuaEngine()
        // This would return 42, but run() discards it
        try engine.run("return 42")
    }

    func testRunWithSideEffect() throws {
        let engine = try LuaEngine()
        // Set a global variable
        try engine.run("testVar = 42")
        // Verify it was set
        let result = try engine.evaluate("return testVar")
        XCTAssertEqual(result.numberValue, 42)
    }

    // MARK: - Arithmetic Tests

    func testAddition() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return 1 + 2")
        XCTAssertEqual(result.numberValue, 3)
    }

    func testMultiplication() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return 6 * 7")
        XCTAssertEqual(result.numberValue, 42)
    }

    func testFloatArithmetic() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return 3.14 * 2")
        XCTAssertEqual(result.numberValue!, 6.28, accuracy: 0.001)
    }

    // MARK: - String Operations

    func testStringConcatenation() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return 'hello' .. ' ' .. 'world'")
        XCTAssertEqual(result.stringValue, "hello world")
    }

    func testStringLength() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return #'hello'")
        XCTAssertEqual(result.numberValue, 5)
    }

    // MARK: - Table Tests

    func testEvaluateTable() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return { name = 'John', age = 30 }")

        XCTAssertNotNil(result.tableValue)
        XCTAssertEqual(result.tableValue?["name"]?.stringValue, "John")
        XCTAssertEqual(result.tableValue?["age"]?.numberValue, 30)
    }

    func testEvaluateArray() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return { 1, 2, 3, 4, 5 }")

        XCTAssertNotNil(result.arrayValue)
        XCTAssertEqual(result.arrayValue?.count, 5)
        XCTAssertEqual(result.arrayValue?[0].numberValue, 1)
        XCTAssertEqual(result.arrayValue?[4].numberValue, 5)
    }

    func testTableValueAccessor() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return { x = 10, y = 20 }")
        let table = result.tableValue

        XCTAssertNotNil(table)
        XCTAssertEqual(table?["x"]?.numberValue, 10)
        XCTAssertEqual(table?["y"]?.numberValue, 20)
    }

    func testArrayValueAccessor() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return { 'a', 'b', 'c' }")
        let array = result.arrayValue

        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 3)
        XCTAssertEqual(array?[0].stringValue, "a")
        XCTAssertEqual(array?[2].stringValue, "c")
    }

    // MARK: - Math Library Tests

    func testMathSqrt() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return math.sqrt(16)")
        XCTAssertEqual(result.numberValue, 4)
    }

    func testMathSin() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return math.sin(0)")
        XCTAssertEqual(result.numberValue!, 0, accuracy: 0.0001)
    }

    func testMathPi() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return math.pi")
        XCTAssertEqual(result.numberValue!, 3.14159265, accuracy: 0.00001)
    }

    // MARK: - Random Seeding Tests

    func testRandomSeedReproducibility() throws {
        let engine1 = try LuaEngine()
        try engine1.seed(12345)
        let result1 = try engine1.evaluate("return math.random()")

        let engine2 = try LuaEngine()
        try engine2.seed(12345)
        let result2 = try engine2.evaluate("return math.random()")

        XCTAssertEqual(result1.numberValue, result2.numberValue)
    }

    func testRandomRange() throws {
        let engine = try LuaEngine()
        try engine.seed(42)
        let result = try engine.evaluate("return math.random(1, 100)")

        XCTAssertNotNil(result.numberValue)
        XCTAssertGreaterThanOrEqual(result.numberValue!, 1)
        XCTAssertLessThanOrEqual(result.numberValue!, 100)
    }

    // MARK: - Sandbox Tests

    func testSandboxBlocksOsExecute() throws {
        let engine = try LuaEngine(configuration: .default)

        XCTAssertThrowsError(try engine.evaluate("os.execute('echo test')")) { error in
            guard case LuaError.runtimeError = error else {
                XCTFail("Expected runtime error")
                return
            }
        }
    }

    func testSandboxBlocksIo() throws {
        let engine = try LuaEngine(configuration: .default)

        XCTAssertThrowsError(try engine.evaluate("io.open('test.txt')")) { error in
            guard case LuaError.runtimeError = error else {
                XCTFail("Expected runtime error")
                return
            }
        }
    }

    func testSandboxAllowsMath() throws {
        let engine = try LuaEngine(configuration: .default)
        let result = try engine.evaluate("return math.abs(-5)")
        XCTAssertEqual(result.numberValue, 5)
    }

    func testSandboxAllowsString() throws {
        let engine = try LuaEngine(configuration: .default)
        let result = try engine.evaluate("return string.upper('hello')")
        XCTAssertEqual(result.stringValue, "HELLO")
    }

    func testSandboxAllowsTable() throws {
        let engine = try LuaEngine(configuration: .default)
        let result = try engine.evaluate("""
            local t = {3, 1, 4, 1, 5}
            table.sort(t)
            return t[1]
        """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - Error Tests

    func testSyntaxError() throws {
        let engine = try LuaEngine()

        XCTAssertThrowsError(try engine.evaluate("return 1 +")) { error in
            guard case LuaError.syntaxError = error else {
                XCTFail("Expected syntax error")
                return
            }
        }
    }

    func testRuntimeError() throws {
        let engine = try LuaEngine()

        XCTAssertThrowsError(try engine.evaluate("return undefined_variable.method()")) { error in
            guard case LuaError.runtimeError = error else {
                XCTFail("Expected runtime error")
                return
            }
        }
    }

    func testRunSyntaxError() throws {
        let engine = try LuaEngine()

        XCTAssertThrowsError(try engine.run("local x =")) { error in
            guard case LuaError.syntaxError = error else {
                XCTFail("Expected syntax error")
                return
            }
        }
    }

    // MARK: - Complex Script Tests

    func testLocalVariables() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("""
            local x = 10
            local y = 20
            return x + y
        """)
        XCTAssertEqual(result.numberValue, 30)
    }

    func testFunctionDefinitionAndCall() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("""
            local function square(n)
                return n * n
            end
            return square(7)
        """)
        XCTAssertEqual(result.numberValue, 49)
    }

    func testForLoop() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("""
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
        let result = try engine.evaluate("""
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
        let result = try engine.evaluate("""
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
        let result = try engine.evaluate("""
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

    // MARK: - Value Server Tests

    func testValueServerRead() throws {
        let engine = try LuaEngine()
        let server = TestValueServer()
        engine.register(server: server)

        let name = try engine.evaluate("return Test.User.name")
        XCTAssertEqual(name.stringValue, "John")

        let age = try engine.evaluate("return Test.User.age")
        XCTAssertEqual(age.numberValue, 30)
    }

    func testValueServerWrite() throws {
        let engine = try LuaEngine()
        let server = TestValueServer()
        engine.register(server: server)

        // Write to cache
        try engine.run("Test.Cache.result = 42")

        // Verify it was written to the server
        XCTAssertEqual(server.cache["result"]?.numberValue, 42)

        // Read it back through Lua
        let result = try engine.evaluate("return Test.Cache.result")
        XCTAssertEqual(result.numberValue, 42)
    }

    func testValueServerWriteString() throws {
        let engine = try LuaEngine()
        let server = TestValueServer()
        engine.register(server: server)

        try engine.run("Test.Cache.message = 'Hello, World!'")

        XCTAssertEqual(server.cache["message"]?.stringValue, "Hello, World!")
    }

    func testValueServerWriteTable() throws {
        let engine = try LuaEngine()
        let server = TestValueServer()
        engine.register(server: server)

        try engine.run("Test.Cache.data = { x = 10, y = 20 }")

        let data = server.cache["data"]
        XCTAssertNotNil(data?.tableValue)
        XCTAssertEqual(data?.tableValue?["x"]?.numberValue, 10)
        XCTAssertEqual(data?.tableValue?["y"]?.numberValue, 20)
    }

    func testValueServerReadOnlyProtection() throws {
        let engine = try LuaEngine()
        let server = TestValueServer()
        engine.register(server: server)

        // Attempting to write to read-only User should fail
        XCTAssertThrowsError(try engine.run("Test.User.name = 'Jane'")) { error in
            guard case LuaError.readOnlyAccess(let path) = error else {
                XCTFail("Expected readOnlyAccess error, got: \(error)")
                return
            }
            XCTAssertEqual(path, "Test.User.name")
        }
    }

    func testValueServerUnregister() throws {
        let engine = try LuaEngine()
        let server = TestValueServer()
        engine.register(server: server)

        // Should work
        let _ = try engine.evaluate("return Test.User.name")

        // Unregister
        engine.unregister(namespace: "Test")

        // Should now fail (Test is nil)
        let result = try engine.evaluate("return Test")
        XCTAssertTrue(result.isNil)
    }

    // MARK: - Problem Generation Simulation

    func testProblemGeneratorPattern() throws {
        let engine = try LuaEngine()
        try engine.seed(42)

        let result = try engine.evaluate("""
            local a = math.random(1, 10)
            local b = math.random(1, 10)
            return {
                question = a .. " + " .. b .. " = ?",
                answer = a + b,
                operands = { a, b }
            }
        """)

        let table = result.tableValue
        XCTAssertNotNil(table?["question"]?.stringValue)
        XCTAssertNotNil(table?["answer"]?.numberValue)
        XCTAssertNotNil(table?["operands"]?.arrayValue)
    }

    func testProblemGeneratorWithPlaceholders() throws {
        let engine = try LuaEngine()
        let server = TestValueServer()
        engine.register(server: server)
        try engine.seed(42)

        // Simulate generating a problem and storing placeholders
        try engine.run("""
            local a = math.random(1, 10)
            local b = math.random(1, 10)
            Test.Cache.operand_a = a
            Test.Cache.operand_b = b
            Test.Cache.answer = a + b
        """)

        // Verify placeholders were stored
        XCTAssertNotNil(server.cache["operand_a"]?.numberValue)
        XCTAssertNotNil(server.cache["operand_b"]?.numberValue)
        XCTAssertNotNil(server.cache["answer"]?.numberValue)

        // Verify math is correct
        let a = server.cache["operand_a"]!.numberValue!
        let b = server.cache["operand_b"]!.numberValue!
        let answer = server.cache["answer"]!.numberValue!
        XCTAssertEqual(a + b, answer)
    }
}
