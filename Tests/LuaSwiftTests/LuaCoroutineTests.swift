//
//  LuaCoroutineTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class LuaCoroutineTests: XCTestCase {

    // MARK: - Basic Coroutine Tests

    func testCreateCoroutine() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: "return 42")
        XCTAssertNotNil(handle)

        engine.destroy(handle)
    }

    func testSimpleCoroutineCompletion() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: "return 42")
        let result = try engine.resume(handle)

        switch result {
        case .completed(let value):
            XCTAssertEqual(value.numberValue, 42.0)
        case .yielded:
            XCTFail("Expected completion, got yield")
        case .error(let error):
            XCTFail("Expected completion, got error: \(error)")
        }

        engine.destroy(handle)
    }

    func testCoroutineWithStringReturn() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: "return 'hello'")
        let result = try engine.resume(handle)

        switch result {
        case .completed(let value):
            XCTAssertEqual(value.stringValue, "hello")
        default:
            XCTFail("Expected completion with string")
        }

        engine.destroy(handle)
    }

    // MARK: - Yield Tests

    func testSingleYield() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield(1)
            return 2
        """)

        // First resume should yield
        let result1 = try engine.resume(handle)
        switch result1 {
        case .yielded(let values):
            XCTAssertEqual(values.count, 1)
            XCTAssertEqual(values[0].numberValue, 1.0)
        default:
            XCTFail("Expected yield")
        }

        // Second resume should complete
        let result2 = try engine.resume(handle)
        switch result2 {
        case .completed(let value):
            XCTAssertEqual(value.numberValue, 2.0)
        default:
            XCTFail("Expected completion")
        }

        engine.destroy(handle)
    }

    func testMultipleYields() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield('first')
            coroutine.yield('second')
            coroutine.yield('third')
            return 'done'
        """)

        let result1 = try engine.resume(handle)
        if case .yielded(let values) = result1 {
            XCTAssertEqual(values[0].stringValue, "first")
        } else {
            XCTFail("Expected yield 'first'")
        }

        let result2 = try engine.resume(handle)
        if case .yielded(let values) = result2 {
            XCTAssertEqual(values[0].stringValue, "second")
        } else {
            XCTFail("Expected yield 'second'")
        }

        let result3 = try engine.resume(handle)
        if case .yielded(let values) = result3 {
            XCTAssertEqual(values[0].stringValue, "third")
        } else {
            XCTFail("Expected yield 'third'")
        }

        let result4 = try engine.resume(handle)
        if case .completed(let value) = result4 {
            XCTAssertEqual(value.stringValue, "done")
        } else {
            XCTFail("Expected completion")
        }

        engine.destroy(handle)
    }

    func testYieldMultipleValues() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield(1, 2, 3)
            return 'done'
        """)

        let result = try engine.resume(handle)
        switch result {
        case .yielded(let values):
            XCTAssertEqual(values.count, 3)
            XCTAssertEqual(values[0].numberValue, 1.0)
            XCTAssertEqual(values[1].numberValue, 2.0)
            XCTAssertEqual(values[2].numberValue, 3.0)
        default:
            XCTFail("Expected yield with multiple values")
        }

        engine.destroy(handle)
    }

    // MARK: - Passing Values to Resume

    func testPassValueToYield() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            local x = coroutine.yield()
            return x * 2
        """)

        // First resume - coroutine yields waiting for a value
        let result1 = try engine.resume(handle)
        if case .yielded = result1 {
            // Expected
        } else {
            XCTFail("Expected yield")
        }

        // Second resume - pass value 21
        let result2 = try engine.resume(handle, with: [.number(21)])
        if case .completed(let value) = result2 {
            XCTAssertEqual(value.numberValue, 42.0)
        } else {
            XCTFail("Expected completion with 42")
        }

        engine.destroy(handle)
    }

    func testPassMultipleValuesToYield() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            local a, b = coroutine.yield()
            return a + b
        """)

        _ = try engine.resume(handle)
        let result = try engine.resume(handle, with: [.number(10), .number(32)])

        if case .completed(let value) = result {
            XCTAssertEqual(value.numberValue, 42.0)
        } else {
            XCTFail("Expected completion with 42")
        }

        engine.destroy(handle)
    }

    func testYieldAndReceiveChain() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            local x = coroutine.yield(1)
            local y = coroutine.yield(x + 1)
            return y * 2
        """)

        // First resume: yields 1
        let r1 = try engine.resume(handle)
        if case .yielded(let v) = r1 {
            XCTAssertEqual(v[0].numberValue, 1.0)
        }

        // Second resume: pass 10, yields 11
        let r2 = try engine.resume(handle, with: [.number(10)])
        if case .yielded(let v) = r2 {
            XCTAssertEqual(v[0].numberValue, 11.0)
        }

        // Third resume: pass 5, returns 10
        let r3 = try engine.resume(handle, with: [.number(5)])
        if case .completed(let v) = r3 {
            XCTAssertEqual(v.numberValue, 10.0)
        }

        engine.destroy(handle)
    }

    // MARK: - Table/Array Yields

    func testYieldTable() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield({name = 'test', value = 42})
            return 'done'
        """)

        let result = try engine.resume(handle)
        if case .yielded(let values) = result {
            let table = values[0].tableValue
            XCTAssertNotNil(table)
            XCTAssertEqual(table?["name"]?.stringValue, "test")
            XCTAssertEqual(table?["value"]?.numberValue, 42.0)
        } else {
            XCTFail("Expected yield with table")
        }

        engine.destroy(handle)
    }

    func testYieldArray() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield({1, 2, 3, 4, 5})
            return 'done'
        """)

        let result = try engine.resume(handle)
        if case .yielded(let values) = result {
            let array = values[0].arrayValue
            XCTAssertNotNil(array)
            XCTAssertEqual(array?.count, 5)
            XCTAssertEqual(array?[0].numberValue, 1.0)
            XCTAssertEqual(array?[4].numberValue, 5.0)
        } else {
            XCTFail("Expected yield with array")
        }

        engine.destroy(handle)
    }

    // MARK: - Status Tests

    func testCoroutineStatusSuspended() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield(1)
            return 2
        """)

        // Before first resume, status should be suspended
        XCTAssertEqual(engine.coroutineStatus(handle), .suspended)

        engine.destroy(handle)
    }

    func testCoroutineStatusAfterYield() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield(1)
            return 2
        """)

        _ = try engine.resume(handle)

        // After yield, status should be suspended
        XCTAssertEqual(engine.coroutineStatus(handle), .suspended)

        engine.destroy(handle)
    }

    func testCoroutineStatusAfterDestroy() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: "return 1")
        engine.destroy(handle)

        // After destroy, status should be dead
        XCTAssertEqual(engine.coroutineStatus(handle), .dead)
    }

    // MARK: - Error Handling

    func testCoroutineSyntaxError() throws {
        let engine = try LuaEngine()

        XCTAssertThrowsError(try engine.createCoroutine(code: "invalid lua code ~~~")) { error in
            if let luaError = error as? LuaError {
                switch luaError {
                case .syntaxError:
                    // Expected
                    break
                default:
                    XCTFail("Expected syntax error, got \(luaError)")
                }
            } else {
                XCTFail("Expected LuaError, got \(error)")
            }
        }
    }

    func testCoroutineRuntimeError() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield(1)
            error('test error')
            return 2
        """)

        // First resume should yield
        _ = try engine.resume(handle)

        // Second resume should error
        let result = try engine.resume(handle)
        switch result {
        case .error(let error):
            if case .coroutineError(let message) = error {
                XCTAssertTrue(message.contains("test error"))
            } else {
                XCTFail("Expected coroutine error, got \(error)")
            }
        default:
            XCTFail("Expected error result")
        }

        engine.destroy(handle)
    }

    func testResumeDestroyedCoroutine() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: "return 1")
        engine.destroy(handle)

        XCTAssertThrowsError(try engine.resume(handle)) { error in
            if let luaError = error as? LuaError {
                switch luaError {
                case .coroutineError(let message):
                    XCTAssertTrue(message.contains("not found") || message.contains("destroyed"))
                default:
                    XCTFail("Expected coroutine error, got \(luaError)")
                }
            } else {
                XCTFail("Expected LuaError, got \(error)")
            }
        }
    }

    // MARK: - Multiple Coroutines

    func testMultipleCoroutines() throws {
        let engine = try LuaEngine()

        let handle1 = try engine.createCoroutine(code: """
            coroutine.yield('a')
            return 'A'
        """)

        let handle2 = try engine.createCoroutine(code: """
            coroutine.yield('b')
            return 'B'
        """)

        // Resume first coroutine
        let r1 = try engine.resume(handle1)
        if case .yielded(let v) = r1 {
            XCTAssertEqual(v[0].stringValue, "a")
        }

        // Resume second coroutine
        let r2 = try engine.resume(handle2)
        if case .yielded(let v) = r2 {
            XCTAssertEqual(v[0].stringValue, "b")
        }

        // Complete first coroutine
        let r3 = try engine.resume(handle1)
        if case .completed(let v) = r3 {
            XCTAssertEqual(v.stringValue, "A")
        }

        // Complete second coroutine
        let r4 = try engine.resume(handle2)
        if case .completed(let v) = r4 {
            XCTAssertEqual(v.stringValue, "B")
        }

        engine.destroy(handle1)
        engine.destroy(handle2)
    }

    // MARK: - Handle Equality

    func testHandleEquality() throws {
        let engine = try LuaEngine()

        let handle1 = try engine.createCoroutine(code: "return 1")
        let handle2 = try engine.createCoroutine(code: "return 2")

        XCTAssertEqual(handle1, handle1)
        XCTAssertNotEqual(handle1, handle2)

        engine.destroy(handle1)
        engine.destroy(handle2)
    }

    func testHandleHashable() throws {
        let engine = try LuaEngine()

        let handle1 = try engine.createCoroutine(code: "return 1")
        let handle2 = try engine.createCoroutine(code: "return 2")

        var set: Set<CoroutineHandle> = []
        set.insert(handle1)
        set.insert(handle2)
        set.insert(handle1)  // Duplicate

        XCTAssertEqual(set.count, 2)

        engine.destroy(handle1)
        engine.destroy(handle2)
    }

    // MARK: - Loop Yields

    func testLoopWithYields() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            for i = 1, 3 do
                coroutine.yield(i)
            end
            return 'done'
        """)

        var results: [Double] = []

        for _ in 1...3 {
            let result = try engine.resume(handle)
            if case .yielded(let values) = result {
                results.append(values[0].numberValue ?? 0)
            }
        }

        XCTAssertEqual(results, [1.0, 2.0, 3.0])

        let finalResult = try engine.resume(handle)
        if case .completed(let value) = finalResult {
            XCTAssertEqual(value.stringValue, "done")
        }

        engine.destroy(handle)
    }

    // MARK: - Generator Pattern

    func testGeneratorPattern() throws {
        let engine = try LuaEngine()

        // Fibonacci generator
        let handle = try engine.createCoroutine(code: """
            local a, b = 0, 1
            while true do
                coroutine.yield(a)
                a, b = b, a + b
            end
        """)

        var fibs: [Double] = []
        for _ in 1...10 {
            let result = try engine.resume(handle)
            if case .yielded(let values) = result {
                fibs.append(values[0].numberValue ?? 0)
            }
        }

        XCTAssertEqual(fibs, [0, 1, 1, 2, 3, 5, 8, 13, 21, 34])

        engine.destroy(handle)
    }

    // MARK: - Destroy Safety

    func testDoubleDestroy() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: "return 1")

        // Should not crash
        engine.destroy(handle)
        engine.destroy(handle)
    }

    func testDestroyWithoutResume() throws {
        let engine = try LuaEngine()

        let handle = try engine.createCoroutine(code: """
            coroutine.yield(1)
            return 2
        """)

        // Destroy without ever resuming - should not crash
        engine.destroy(handle)
    }
}
