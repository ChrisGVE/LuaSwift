//
//  LuaCallbackTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-30.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class LuaCallbackTests: XCTestCase {

    // MARK: - Basic Callback Tests

    func testRegisterAndCallSimpleCallback() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "add") { args in
            guard args.count == 2,
                  let a = args[0].numberValue,
                  let b = args[1].numberValue else {
                return .nil
            }
            return .number(a + b)
        }

        let result = try engine.evaluate("return add(5, 3)")
        XCTAssertEqual(result.numberValue, 8.0)
    }

    func testCallbackWithStringReturn() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "greet") { args in
            guard let name = args.first?.stringValue else {
                return "Hello, stranger!"
            }
            return .string("Hello, \(name)!")
        }

        let result = try engine.evaluate("return greet('World')")
        XCTAssertEqual(result.stringValue, "Hello, World!")
    }

    func testCallbackWithBoolReturn() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "isEven") { args in
            guard let num = args.first?.numberValue else {
                return false
            }
            return .bool(Int(num) % 2 == 0)
        }

        let result1 = try engine.evaluate("return isEven(4)")
        XCTAssertEqual(result1.boolValue, true)

        let result2 = try engine.evaluate("return isEven(7)")
        XCTAssertEqual(result2.boolValue, false)
    }

    // MARK: - Multiple Arguments

    func testCallbackWithMultipleArguments() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "concat") { args in
            let strings = args.compactMap { $0.stringValue }
            return .string(strings.joined(separator: " "))
        }

        let result = try engine.evaluate("return concat('Hello', 'from', 'Swift')")
        XCTAssertEqual(result.stringValue, "Hello from Swift")
    }

    func testCallbackWithNoArguments() throws {
        let engine = try LuaEngine()

        var callCount = 0
        engine.registerFunction(name: "increment") { _ in
            callCount += 1
            return .number(Double(callCount))
        }

        let result1 = try engine.evaluate("return increment()")
        XCTAssertEqual(result1.numberValue, 1.0)

        let result2 = try engine.evaluate("return increment()")
        XCTAssertEqual(result2.numberValue, 2.0)
    }

    // MARK: - Table Returns

    func testCallbackReturningTable() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "makeTable") { _ in
            return .table([
                "name": "Swift",
                "version": "5.9",
                "year": 2023
            ])
        }

        let result = try engine.evaluate("local t = makeTable(); return t.name")
        XCTAssertEqual(result.stringValue, "Swift")

        let result2 = try engine.evaluate("local t = makeTable(); return t.year")
        XCTAssertEqual(result2.numberValue, 2023.0)
    }

    func testCallbackReturningArray() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "getNumbers") { _ in
            return .array([1, 2, 3, 4, 5])
        }

        let result = try engine.evaluate("local arr = getNumbers(); return arr[3]")
        XCTAssertEqual(result.numberValue, 3.0)

        let result2 = try engine.evaluate("local arr = getNumbers(); return #arr")
        XCTAssertEqual(result2.numberValue, 5.0)
    }

    // MARK: - Error Handling

    func testCallbackThrowingError() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "divide") { args in
            guard args.count == 2,
                  let a = args[0].numberValue,
                  let b = args[1].numberValue else {
                throw LuaError.callbackError("Invalid arguments")
            }

            guard b != 0 else {
                throw LuaError.callbackError("Division by zero")
            }

            return .number(a / b)
        }

        // Successful division
        let result = try engine.evaluate("return divide(10, 2)")
        XCTAssertEqual(result.numberValue, 5.0)

        // Division by zero should propagate error
        XCTAssertThrowsError(try engine.evaluate("return divide(10, 0)")) { error in
            if let luaError = error as? LuaError {
                switch luaError {
                case .runtimeError(let message):
                    XCTAssertTrue(message.contains("Division by zero"))
                default:
                    XCTFail("Expected runtime error, got \(luaError)")
                }
            } else {
                XCTFail("Expected LuaError, got \(error)")
            }
        }
    }

    func testCallbackGenericError() throws {
        struct CustomError: Error {}

        let engine = try LuaEngine()

        engine.registerFunction(name: "fail") { _ in
            throw CustomError()
        }

        XCTAssertThrowsError(try engine.evaluate("return fail()")) { error in
            if let luaError = error as? LuaError {
                switch luaError {
                case .runtimeError(let message):
                    XCTAssertTrue(message.contains("Swift callback error"))
                default:
                    XCTFail("Expected runtime error, got \(luaError)")
                }
            } else {
                XCTFail("Expected LuaError, got \(error)")
            }
        }
    }

    // MARK: - Unregister

    func testUnregisterFunction() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "test") { _ in
            return "registered"
        }

        // Verify it works
        let result1 = try engine.evaluate("return test()")
        XCTAssertEqual(result1.stringValue, "registered")

        // Unregister
        engine.unregisterFunction(name: "test")

        // Should now fail
        XCTAssertThrowsError(try engine.evaluate("return test()")) { error in
            if let luaError = error as? LuaError {
                switch luaError {
                case .runtimeError(let message):
                    XCTAssertTrue(message.contains("nil"))
                default:
                    break
                }
            }
        }
    }

    // MARK: - Integration with Lua

    func testCallbackInLuaFunction() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "double") { args in
            guard let num = args.first?.numberValue else {
                return .nil
            }
            return .number(num * 2)
        }

        try engine.run("""
            function quadruple(n)
                return double(double(n))
            end
        """)

        let result = try engine.evaluate("return quadruple(5)")
        XCTAssertEqual(result.numberValue, 20.0)
    }

    func testMultipleCallbacksInScript() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "add") { args in
            guard args.count == 2,
                  let a = args[0].numberValue,
                  let b = args[1].numberValue else {
                return .nil
            }
            return .number(a + b)
        }

        engine.registerFunction(name: "multiply") { args in
            guard args.count == 2,
                  let a = args[0].numberValue,
                  let b = args[1].numberValue else {
                return .nil
            }
            return .number(a * b)
        }

        let result = try engine.evaluate("return multiply(add(2, 3), 4)")
        XCTAssertEqual(result.numberValue, 20.0)
    }

    // MARK: - Complex Table Arguments

    func testCallbackReceivingTable() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "sumTable") { args in
            guard let table = args.first?.tableValue else {
                return 0
            }

            var sum = 0.0
            for (_, value) in table {
                if let num = value.numberValue {
                    sum += num
                }
            }
            return .number(sum)
        }

        let result = try engine.evaluate("""
            return sumTable({a = 10, b = 20, c = 30})
        """)
        XCTAssertEqual(result.numberValue, 60.0)
    }

    func testCallbackReceivingArray() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "sumArray") { args in
            guard let array = args.first?.arrayValue else {
                return 0
            }

            var sum = 0.0
            for value in array {
                if let num = value.numberValue {
                    sum += num
                }
            }
            return .number(sum)
        }

        let result = try engine.evaluate("""
            return sumArray({1, 2, 3, 4, 5})
        """)
        XCTAssertEqual(result.numberValue, 15.0)
    }

    // MARK: - State Preservation

    func testCallbackStatePreservation() throws {
        let engine = try LuaEngine()

        var counter = 0
        engine.registerFunction(name: "getNext") { _ in
            counter += 1
            return .number(Double(counter))
        }

        let result1 = try engine.evaluate("return getNext()")
        XCTAssertEqual(result1.numberValue, 1.0)

        let result2 = try engine.evaluate("return getNext() + getNext()")
        XCTAssertEqual(result2.numberValue, 5.0) // 2 + 3 = 5
    }
}
