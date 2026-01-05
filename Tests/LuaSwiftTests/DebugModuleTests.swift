//
//  DebugModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-05.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if DEBUG

import XCTest
@testable import LuaSwift

final class DebugModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        ModuleRegistry.installDebugModule(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Module Registration Tests

    func testDebugModuleExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug)
            """)
        XCTAssertEqual(result.stringValue, "table")
    }

    func testDebugModuleAlias() throws {
        let result = try engine.evaluate("""
            return type(debug_module)
            """)
        XCTAssertEqual(result.stringValue, "table")
    }

    func testDebugModuleAliasPointsToSameTable() throws {
        let result = try engine.evaluate("""
            return luaswift.debug == debug_module
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Log Tests

    func testLogDebugExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.log.debug)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLogInfoExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.log.info)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLogWarnExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.log.warn)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLogErrorExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.log.error)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLogSetLevelExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.log.setLevel)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testLogDebugMessage() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.log.debug("Debug message")
            """)
    }

    func testLogInfoMessage() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.log.info("Info message")
            """)
    }

    func testLogWarnMessage() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.log.warn("Warning message")
            """)
    }

    func testLogErrorMessage() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.log.error("Error message")
            """)
    }

    func testLogSetLevelValid() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.log.setLevel("INFO")
            """)
    }

    func testLogSetLevelInvalid() throws {
        // Should throw for invalid level
        XCTAssertThrowsError(try engine.run("""
            luaswift.debug.log.setLevel("INVALID")
            """))
    }

    func testLogSetLevelCaseInsensitive() throws {
        // Should accept lowercase
        try engine.run("""
            luaswift.debug.log.setLevel("debug")
            """)

        // Should accept mixed case
        try engine.run("""
            luaswift.debug.log.setLevel("WaRn")
            """)
    }

    func testLogMissingArgument() throws {
        // Should throw when message is missing
        XCTAssertThrowsError(try engine.run("""
            luaswift.debug.log.debug()
            """))
    }

    // MARK: - Console Print Tests

    func testConsolePrintExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.console.print)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testConsolePrintSingleArg() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.print("Hello")
            """)
    }

    func testConsolePrintMultipleArgs() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.print("Hello", "World", 123, true)
            """)
    }

    func testConsolePrintNoArgs() throws {
        // Should not throw (prints empty line)
        try engine.run("""
            luaswift.debug.console.print()
            """)
    }

    // MARK: - Console Inspect Tests

    func testConsoleInspectExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.console.inspect)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testConsoleInspectString() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.inspect("Hello")
            """)
    }

    func testConsoleInspectNumber() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.inspect(123.45)
            """)
    }

    func testConsoleInspectBoolean() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.inspect(true)
            """)
    }

    func testConsoleInspectNil() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.inspect(nil)
            """)
    }

    func testConsoleInspectTable() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.inspect({key = "value", num = 42})
            """)
    }

    func testConsoleInspectArray() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.inspect({1, 2, 3, 4, 5})
            """)
    }

    func testConsoleInspectNestedTable() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.inspect({
                outer = {
                    inner = {
                        deep = "value"
                    }
                }
            })
            """)
    }

    func testConsoleInspectEmptyTable() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.inspect({})
            """)
    }

    // MARK: - Console Trace Tests

    func testConsoleTraceExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.console.trace)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testConsoleTrace() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.trace()
            """)
    }

    // MARK: - Console Timer Tests

    func testConsoleTimeExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.console.time)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testConsoleTimeEndExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.console.timeEnd)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testConsoleTimeAndTimeEnd() throws {
        // Should not throw
        try engine.run("""
            luaswift.debug.console.time("test")
            -- Simulate some work
            local x = 0
            for i = 1, 1000 do
                x = x + i
            end
            luaswift.debug.console.timeEnd("test")
            """)
    }

    func testConsoleTimeMultipleTimers() throws {
        // Should support multiple concurrent timers
        try engine.run("""
            luaswift.debug.console.time("timer1")
            luaswift.debug.console.time("timer2")
            luaswift.debug.console.timeEnd("timer1")
            luaswift.debug.console.timeEnd("timer2")
            """)
    }

    func testConsoleTimeEndWithoutStart() throws {
        // Should not throw, just print warning
        try engine.run("""
            luaswift.debug.console.timeEnd("nonexistent")
            """)
    }

    func testConsoleTimeMissingLabel() throws {
        // Should throw when label is missing
        XCTAssertThrowsError(try engine.run("""
            luaswift.debug.console.time()
            """))
    }

    func testConsoleTimeEndMissingLabel() throws {
        // Should throw when label is missing
        XCTAssertThrowsError(try engine.run("""
            luaswift.debug.console.timeEnd()
            """))
    }

    // MARK: - Console Assert Tests

    func testConsoleAssertExists() throws {
        let result = try engine.evaluate("""
            return type(luaswift.debug.console.assert)
            """)
        XCTAssertEqual(result.stringValue, "function")
    }

    func testConsoleAssertTrue() throws {
        // Should not throw or print anything for true condition
        try engine.run("""
            luaswift.debug.console.assert(true)
            """)
    }

    func testConsoleAssertTrueWithMessage() throws {
        // Should not throw or print for true condition
        try engine.run("""
            luaswift.debug.console.assert(true, "This should not print")
            """)
    }

    func testConsoleAssertFalse() throws {
        // Should print assertion failure but not throw
        try engine.run("""
            luaswift.debug.console.assert(false)
            """)
    }

    func testConsoleAssertFalseWithMessage() throws {
        // Should print custom message but not throw
        try engine.run("""
            luaswift.debug.console.assert(false, "Custom assertion message")
            """)
    }

    func testConsoleAssertExpression() throws {
        // Should work with expressions
        try engine.run("""
            local x = 10
            luaswift.debug.console.assert(x > 5, "x should be greater than 5")
            luaswift.debug.console.assert(x < 5, "x should be less than 5")
            """)
    }

    func testConsoleAssertMissingCondition() throws {
        // Should throw when condition is missing
        XCTAssertThrowsError(try engine.run("""
            luaswift.debug.console.assert()
            """))
    }

    // MARK: - Integration Tests

    func testAllLogLevels() throws {
        // Test all log levels in sequence
        try engine.run("""
            luaswift.debug.log.debug("Debug level message")
            luaswift.debug.log.info("Info level message")
            luaswift.debug.log.warn("Warning level message")
            luaswift.debug.log.error("Error level message")
            """)
    }

    func testLogLevelFiltering() throws {
        // Set level to WARN and verify DEBUG/INFO don't cause errors
        try engine.run("""
            luaswift.debug.log.setLevel("WARN")
            luaswift.debug.log.debug("This should be filtered")
            luaswift.debug.log.info("This should also be filtered")
            luaswift.debug.log.warn("This should appear")
            luaswift.debug.log.error("This should also appear")
            """)
    }

    func testLogLevelOff() throws {
        // Set level to OFF and verify no logs appear
        try engine.run("""
            luaswift.debug.log.setLevel("OFF")
            luaswift.debug.log.debug("Filtered")
            luaswift.debug.log.info("Filtered")
            luaswift.debug.log.warn("Filtered")
            luaswift.debug.log.error("Filtered")
            """)
    }

    func testComplexDebuggingScenario() throws {
        // Realistic debugging scenario
        try engine.run("""
            luaswift.debug.log.setLevel("DEBUG")
            luaswift.debug.log.info("Starting complex operation")

            luaswift.debug.console.time("operation")

            local data = {
                name = "Test",
                values = {1, 2, 3, 4, 5},
                metadata = {
                    created = "2026-01-05",
                    version = 1
                }
            }

            luaswift.debug.console.inspect(data)

            local sum = 0
            for i, v in ipairs(data.values) do
                sum = sum + v
                luaswift.debug.log.debug("Processing value: " .. v)
            end

            luaswift.debug.console.assert(sum == 15, "Sum should be 15")

            luaswift.debug.console.timeEnd("operation")
            luaswift.debug.log.info("Operation completed successfully")
            """)
    }

    func testViaTopLevelAlias() throws {
        // Test using debug_module alias
        try engine.run("""
            debug_module.log.info("Using top-level alias")
            debug_module.console.print("This works too")
            """)
    }
}

#endif
