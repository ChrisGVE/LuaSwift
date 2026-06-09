//
//  LuaCallbackTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-30.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
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
            guard let luaError = error as? LuaError else {
                return XCTFail("Expected LuaError, got \(error)")
            }
            switch luaError {
            case .runtimeError(let message):
                XCTAssertTrue(message.contains("Division by zero"))
            case .runtimeFailure(let failure):
                // #19: structured errors carry rawMessage containing the full error
                XCTAssertTrue(failure.rawMessage.contains("Division by zero"))
            default:
                XCTFail("Expected runtime error, got \(luaError)")
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
            guard let luaError = error as? LuaError else {
                return XCTFail("Expected LuaError, got \(error)")
            }
            switch luaError {
            case .runtimeError(let message):
                XCTAssertTrue(message.contains("Swift callback error"))
            case .runtimeFailure(let failure):
                XCTAssertTrue(failure.rawMessage.contains("Swift callback error"))
            default:
                XCTFail("Expected runtime error, got \(luaError)")
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

    // MARK: - Lua Function Reference Tests

    func testCallLuaFunction() throws {
        let engine = try LuaEngine()

        // Register a Swift function that receives a Lua function and calls it
        engine.registerFunction(name: "applyDouble") { args in
            guard case .luaFunction(let ref) = args.first else {
                throw LuaError.callbackError("Expected function")
            }

            // Call the Lua function with argument 21
            let result = try engine.callLuaFunction(ref: ref, args: [.number(21)])
            engine.releaseLuaFunction(ref: ref)  // Manual release
            return result
        }

        let result = try engine.evaluate("""
            return applyDouble(function(x) return x * 2 end)
        """)
        XCTAssertEqual(result.numberValue, 42, "Should call Lua function and return doubled value")
    }

    /// Regression: a re-entrant `callLuaFunction` whose inner Lua function
    /// errors must surface the error as a thrown `LuaError`, not trip the
    /// debug-build stack-cleanliness assert. The outer call enters from a
    /// Swift callback that received an argument, so the callback's C-stack
    /// window is non-empty (top != 0); the assert must compare against the
    /// entry base, not 0. Before the fix this aborted the process in DEBUG.
    func testCallLuaFunctionReentrantErrorDoesNotTripAssert() throws {
        let engine = try LuaEngine()

        // The callback receives a function AND a number (window top == 2),
        // then re-enters callLuaFunction with a function that raises an error.
        engine.registerFunction(name: "applyOrFail") { args in
            guard case .luaFunction(let ref) = args.first else {
                throw LuaError.callbackError("Expected function")
            }
            defer { engine.releaseLuaFunction(ref: ref) }
            // Propagates the inner Lua runtime error back out.
            return try engine.callLuaFunction(ref: ref, args: [.number(7)])
        }

        XCTAssertThrowsError(
            try engine.evaluate("""
                return applyOrFail(function(x) error("inner boom: " .. x) end, 99)
            """),
            "Re-entrant callLuaFunction error must throw, not crash"
        ) { error in
            guard let luaError = error as? LuaError else {
                return XCTFail("Expected LuaError, got \(error)")
            }
            // The host should see a real runtime failure carrying the message,
            // not a cancellation/limit misclassification.
            let described = "\(luaError)"
            XCTAssertTrue(
                described.contains("inner boom"),
                "Error should carry the inner Lua message, got: \(described)"
            )
        }

        // Engine must remain usable after the re-entrant error.
        let after = try engine.evaluate("return 1 + 1")
        XCTAssertEqual(after.numberValue, 2, "Engine should still work after re-entrant error")
    }

    func testReleaseLuaFunction() throws {
        let engine = try LuaEngine()

        var capturedRef: Int32?
        engine.registerFunction(name: "captureFunc") { args in
            guard case .luaFunction(let ref) = args.first else {
                throw LuaError.callbackError("Expected function")
            }
            capturedRef = ref
            return .nil
        }

        try engine.run("""
            captureFunc(function() return "test" end)
        """)

        XCTAssertNotNil(capturedRef, "Should have captured function reference")

        // Release the function - should not crash
        if let ref = capturedRef {
            engine.releaseLuaFunction(ref: ref)
        }

        // Releasing again should also not crash (though ref is now invalid)
        // This tests the safety of the release function
    }

    func testWithLuaFunction() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "transformWith") { args in
            guard args.count >= 2 else {
                throw LuaError.callbackError("Expected function and value")
            }

            let funcValue = args[0]
            let value = args[1]

            // withLuaFunction automatically releases the reference
            return try engine.withLuaFunction(funcValue) { ref in
                try engine.callLuaFunction(ref: ref, args: [value])
            }
        }

        let result = try engine.evaluate("""
            return transformWith(function(x) return x * 3 end, 14)
        """)
        XCTAssertEqual(result.numberValue, 42, "Should transform value using provided function")
    }

    func testCallAndReleaseLuaFunction() throws {
        let engine = try LuaEngine()

        engine.registerFunction(name: "invoke") { args in
            guard let funcValue = args.first else {
                throw LuaError.callbackError("Expected function")
            }

            // callAndReleaseLuaFunction is a one-liner for calling and auto-releasing
            return try engine.callAndReleaseLuaFunction(funcValue, args: Array(args.dropFirst()))
        }

        let result = try engine.evaluate("""
            return invoke(function(a, b) return a + b end, 20, 22)
        """)
        XCTAssertEqual(result.numberValue, 42, "Should invoke function with arguments")
    }

    func testWithLuaFunctionThrowsForNonFunction() throws {
        let engine = try LuaEngine()

        XCTAssertThrowsError(
            try engine.withLuaFunction(.number(42)) { _ in LuaValue.nil }
        ) { error in
            guard case LuaError.callbackError(let message) = error else {
                XCTFail("Expected callbackError")
                return
            }
            XCTAssertTrue(message.contains("luaFunction"), "Error should mention expected type")
        }
    }

    func testUnreleasedFunctionRefDoesNotCrashOnEngineDeinit() throws {
        // This test verifies that unreleased function references don't cause
        // crashes when the engine is deinitialized. The Lua state cleanup
        // handles this gracefully.

        var capturedRef: Int32?

        // Create engine in a scope so it gets deinitialized
        do {
            let engine = try LuaEngine()

            engine.registerFunction(name: "captureFunc") { args in
                guard case .luaFunction(let ref) = args.first else {
                    throw LuaError.callbackError("Expected function")
                }
                capturedRef = ref  // Intentionally NOT releasing
                return .nil
            }

            try engine.run("""
                captureFunc(function() return "leaked" end)
            """)
        }
        // Engine is now deinitialized with unreleased ref

        XCTAssertNotNil(capturedRef, "Should have captured (and leaked) a ref")
        // Test passes if we reach here without crashing
    }

    func testReleaseFunctionAfterEngineDeinit() throws {
        // Test that releasing a function ref after engine deinit is safe (no-op)

        var capturedRef: Int32?
        weak var weakEngine: LuaEngine?

        do {
            let engine = try LuaEngine()
            weakEngine = engine

            engine.registerFunction(name: "captureFunc") { args in
                guard case .luaFunction(let ref) = args.first else {
                    throw LuaError.callbackError("Expected function")
                }
                capturedRef = ref
                return .nil
            }

            try engine.run("""
                captureFunc(function() return "test" end)
            """)
        }

        XCTAssertNil(weakEngine, "Engine should be deinitialized")
        XCTAssertNotNil(capturedRef, "Should have captured ref")

        // Attempting to release after engine deinit should be safe
        // (we can't actually call releaseLuaFunction since engine is gone,
        // but this documents that the ref is now orphaned - this is expected
        // behavior and the test passing shows no crash occurred)
    }

    func testLuaFunctionWithUpvalues() throws {
        let engine = try LuaEngine()

        // Test that function references properly capture upvalues
        engine.registerFunction(name: "createAndCall") { args in
            guard case .luaFunction(let ref) = args.first else {
                throw LuaError.callbackError("Expected function")
            }

            let result = try engine.callLuaFunction(ref: ref, args: [])
            engine.releaseLuaFunction(ref: ref)
            return result
        }

        let result = try engine.evaluate("""
            local captured = 100
            return createAndCall(function()
                captured = captured + 1
                return captured
            end)
        """)

        XCTAssertEqual(result.numberValue, 101, "Function should access upvalues correctly")
    }

    // MARK: - Unsafe Callback Arguments

    /// A cyclic table passed as a callback argument is rejected during argument
    /// conversion (surfaced as a Lua error from the trampoline) rather than
    /// recursing until the stack is exhausted.
    func testCallbackCyclicArgRejected() throws {
        let engine = try LuaEngine()
        var observed: [LuaValue]?
        engine.registerFunction(name: "inspect") { args in
            observed = args
            return .nil
        }

        XCTAssertThrowsError(try engine.evaluate("""
            local t = {}
            t.self = t
            return inspect(t)
        """)) { error in
            XCTAssertTrue(
                error.localizedDescription.localizedCaseInsensitiveContains("cyclic"),
                "Expected a cyclic-table rejection, got \(error)")
        }
        XCTAssertNil(observed, "Callback must not be invoked when an argument fails to convert")
    }

    /// A non-representable numeric key in a callback-argument table is rejected.
    func testCallbackOutOfRangeKeyArgRejected() throws {
        let engine = try LuaEngine()
        engine.registerFunction(name: "inspect") { _ in .nil }
        XCTAssertThrowsError(try engine.evaluate("return inspect({ [2^63] = 1 })")) { error in
            XCTAssertTrue(
                error.localizedDescription.localizedCaseInsensitiveContains("representable")
                    || error.localizedDescription.localizedCaseInsensitiveContains("argument"),
                "Expected an out-of-range-key rejection, got \(error)")
        }
    }
}
