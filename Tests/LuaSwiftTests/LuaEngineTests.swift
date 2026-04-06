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

    // MARK: - Numeric Table Key Behavior (Known Limitations)

    /// Documents that fractional numeric keys are truncated to Int.
    ///
    /// This is a known limitation: Lua allows any numeric value as a table key,
    /// but when converting to Swift, numeric keys are cast to Int, truncating
    /// any fractional part. Key 1.5 becomes key 1, potentially overwriting values.
    func testNumericKeyFractionalTruncation() throws {
        let engine = try LuaEngine()
        // Create table with fractional key 1.5 and integer key 1
        let result = try engine.evaluate("""
            local t = {}
            t[1] = "integer-one"
            t[1.5] = "fractional-one-point-five"
            return t
        """)

        // Due to truncation, both keys map to Int(1), and the second overwrites the first
        // This documents current behavior, not necessarily desired behavior
        // With only integer key (after truncation), it becomes a 1-element array
        if let array = result.arrayValue {
            // The table becomes a single-element array since 1.5 truncates to 1
            XCTAssertEqual(array.count, 1, "Fractional key 1.5 truncates to 1, overwriting")
            XCTAssertEqual(array[0].stringValue, "fractional-one-point-five")
        } else if let table = result.tableValue {
            XCTAssertEqual(table.count, 1, "Fractional key 1.5 truncates to 1, overwriting")
        } else {
            XCTFail("Expected table or array")
        }
    }

    /// Documents that integer numeric keys work correctly.
    func testNumericKeyIntegerWorks() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("""
            local t = {}
            t[1] = "one"
            t[2] = "two"
            t[100] = "hundred"
            return t
        """)

        // Non-contiguous integer keys (1, 2, 100) become a table with string keys
        // because they don't form a contiguous array starting at 1
        guard result.tableValue != nil || result.arrayValue != nil else {
            XCTFail("Expected table or array")
            return
        }
        // The values should be accessible via the appropriate accessor
        if let table = result.tableValue {
            XCTAssertEqual(table["1"]?.stringValue, "one")
            XCTAssertEqual(table["2"]?.stringValue, "two")
            XCTAssertEqual(table["100"]?.stringValue, "hundred")
        }
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

    // MARK: - Binary-Safe String Tests (Embedded NUL)

    func testStringWithEmbeddedNulRoundTrip() throws {
        let engine = try LuaEngine()

        // Create a string with embedded NUL in Lua and return it
        let result = try engine.evaluate("""
            local s = "hello\\0world"
            return s
        """)

        // The string should preserve the embedded NUL
        XCTAssertEqual(result.stringValue, "hello\0world")
        XCTAssertEqual(result.stringValue?.count, 11)  // 5 + 1 + 5
    }

    func testStringWithEmbeddedNulInTable() throws {
        let engine = try LuaEngine()

        // Create a table with a string value containing embedded NUL
        let result = try engine.evaluate("""
            return { data = "ab\\0cd" }
        """)

        XCTAssertEqual(result.tableValue?["data"]?.stringValue, "ab\0cd")
        XCTAssertEqual(result.tableValue?["data"]?.stringValue?.count, 5)
    }

    func testStringWithMultipleEmbeddedNuls() throws {
        let engine = try LuaEngine()

        let result = try engine.evaluate("""
            return "a\\0b\\0c\\0d"
        """)

        let expected = "a\0b\0c\0d"
        XCTAssertEqual(result.stringValue, expected)
        XCTAssertEqual(result.stringValue?.count, 7)  // a + NUL + b + NUL + c + NUL + d
    }

    func testCallbackReceivesStringWithEmbeddedNul() throws {
        let engine = try LuaEngine()

        var receivedString: String?
        engine.registerFunction(name: "checkString") { args in
            receivedString = args.first?.stringValue
            return .number(Double(receivedString?.count ?? 0))
        }

        let result = try engine.evaluate("""
            local s = "test\\0data"
            return checkString(s)
        """)

        XCTAssertEqual(receivedString, "test\0data")
        XCTAssertEqual(result.numberValue, 9.0)  // 4 + 1 + 4
    }

    func testCallbackReturnsStringWithEmbeddedNul() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "makeString") { _ in
            return .string("prefix\0suffix")
        }

        let result = try engine.evaluate("return makeString()")

        XCTAssertEqual(result.stringValue, "prefix\0suffix")
        XCTAssertEqual(result.stringValue?.count, 13)  // 6 + 1 + 6
    }

    func testTableKeyWithEmbeddedNul() throws {
        let engine = try LuaEngine()

        // Create a table with a key containing embedded NUL
        let result = try engine.evaluate("""
            local t = {}
            t["key\\0name"] = "value"
            return t
        """)

        // The key should preserve the embedded NUL
        XCTAssertEqual(result.tableValue?["key\0name"]?.stringValue, "value")
    }

    func testValueServerWriteStringWithEmbeddedNul() throws {
        let engine = try LuaEngine()
        let server = TestValueServer()
        engine.register(server: server)

        try engine.run("Test.Cache.binary = 'data\\0with\\0nuls'")

        XCTAssertEqual(server.cache["binary"]?.stringValue, "data\0with\0nuls")
        XCTAssertEqual(server.cache["binary"]?.stringValue?.count, 14)  // 4 + 1 + 4 + 1 + 4
    }

    func testCoroutineStringWithEmbeddedNul() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            local function gen()
                coroutine.yield("hello\\0world")
                return "done\\0!"
            end
            return gen()
        """)

        let result1 = try engine.resume(handle)
        if case .yielded(let values) = result1 {
            XCTAssertEqual(values.first?.stringValue, "hello\0world")
        } else {
            XCTFail("Expected yielded result")
        }

        let result2 = try engine.resume(handle)
        if case .completed(let value) = result2 {
            XCTAssertEqual(value.stringValue, "done\0!")
        } else {
            XCTFail("Expected completed result")
        }
    }

}
