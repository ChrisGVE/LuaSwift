import XCTest
@testable import LuaSwift

/// Tests that run the pure Lua test suite.
/// These tests execute Lua test files using the Lua test runner,
/// validating that the Lua modules work correctly.
final class LuaTestRunnerTests: XCTestCase {

    /// Path to the LuaTests directory
    private var luaTestsPath: String {
        // In the source tree, LuaTests is at Tests/LuaTests
        let thisFile = #file
        let testsDir = (thisFile as NSString).deletingLastPathComponent
        return (testsDir as NSString).deletingLastPathComponent + "/LuaTests"
    }

    /// Path to the LuaModules directory
    private var modulesPath: String {
        let thisFile = #file
        let testsDir = (thisFile as NSString).deletingLastPathComponent
        let projectDir = ((testsDir as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
        return projectDir + "/Sources/LuaSwift/LuaModules"
    }

    /// Creates an engine configured to find both test and module Lua files
    /// Note: Uses unsandboxed mode because dofile is needed to load test files
    private func createTestEngine() throws -> LuaEngine {
        let packagePath = "\(luaTestsPath)/?.lua;\(modulesPath)/?.lua"
        let config = LuaEngineConfiguration(
            sandboxed: false,  // Need dofile for test loading
            packagePath: packagePath,
            memoryLimit: 0
        )
        return try LuaEngine(configuration: config)
    }

    // MARK: - Test Runner Tests

    func testLuaTestRunnerLoads() throws {
        let engine = try createTestEngine()

        let result = try engine.evaluate("""
            local T = require("run_tests")
            return type(T) == "table" and type(T.test) == "function"
        """)

        XCTAssertTrue(result.boolValue ?? false, "Test runner should load successfully")
    }

    func testLuaTestRunnerBasicTest() throws {
        let engine = try createTestEngine()

        let result = try engine.evaluate("""
            local T = require("run_tests")
            T.reset()

            T.test("passing test", function()
                T.assert_true(true)
            end)

            T.test("failing test", function()
                T.assert_true(false)
            end)

            local s = T.summary()
            return {passed = s.passed, failed = s.failed}
        """)

        XCTAssertEqual(result.tableValue?["passed"]?.intValue, 1)
        XCTAssertEqual(result.tableValue?["failed"]?.intValue, 1)
    }

    // MARK: - Compat Module Lua Tests

    func testCompatLuaTestSuite() throws {
        let engine = try createTestEngine()

        let result = try engine.evaluate("""
            -- Set up package path to find modules
            package.path = "\(luaTestsPath)/?.lua;\(modulesPath)/?.lua;" .. package.path

            local T = require("run_tests")
            T.reset()

            -- Run compat tests
            dofile("\(luaTestsPath)/test_compat.lua")

            local s = T.summary()
            return {
                total = s.total,
                passed = s.passed,
                failed = s.failed,
                errors = s.errors
            }
        """)

        let total = result.tableValue?["total"]?.intValue ?? 0
        let passed = result.tableValue?["passed"]?.intValue ?? 0
        let failed = result.tableValue?["failed"]?.intValue ?? 0

        // Report any failures
        if failed > 0 {
            if let errors = result.tableValue?["errors"]?.arrayValue {
                for error in errors {
                    if let errorTable = error.tableValue {
                        let name = errorTable["name"]?.stringValue ?? "unknown"
                        let msg = errorTable["error"]?.stringValue ?? "unknown error"
                        print("FAILED: \(name): \(msg)")
                    }
                }
            }
        }

        XCTAssertGreaterThan(total, 0, "Should have run some tests")
        XCTAssertEqual(failed, 0, "All compat tests should pass (\(passed)/\(total) passed)")
    }

    // MARK: - Serialize Module Lua Tests

    func testSerializeLuaTestSuite() throws {
        let engine = try createTestEngine()

        let result = try engine.evaluate("""
            -- Set up package path to find modules
            package.path = "\(luaTestsPath)/?.lua;\(modulesPath)/?.lua;" .. package.path

            local T = require("run_tests")
            T.reset()

            -- Run serialize tests
            dofile("\(luaTestsPath)/test_serialize.lua")

            local s = T.summary()
            return {
                total = s.total,
                passed = s.passed,
                failed = s.failed,
                errors = s.errors
            }
        """)

        let total = result.tableValue?["total"]?.intValue ?? 0
        let passed = result.tableValue?["passed"]?.intValue ?? 0
        let failed = result.tableValue?["failed"]?.intValue ?? 0

        // Report any failures
        if failed > 0 {
            if let errors = result.tableValue?["errors"]?.arrayValue {
                for error in errors {
                    if let errorTable = error.tableValue {
                        let name = errorTable["name"]?.stringValue ?? "unknown"
                        let msg = errorTable["error"]?.stringValue ?? "unknown error"
                        print("FAILED: \(name): \(msg)")
                    }
                }
            }
        }

        XCTAssertGreaterThan(total, 0, "Should have run some tests")
        XCTAssertEqual(failed, 0, "All serialize tests should pass (\(passed)/\(total) passed)")
    }

    // MARK: - All Lua Tests

    func testAllLuaTestSuites() throws {
        let engine = try createTestEngine()

        let result = try engine.evaluate("""
            -- Set up package path to find modules
            package.path = "\(luaTestsPath)/?.lua;\(modulesPath)/?.lua;" .. package.path

            local T = require("run_tests")
            T.reset()

            -- Run all test files
            dofile("\(luaTestsPath)/test_compat.lua")
            dofile("\(luaTestsPath)/test_serialize.lua")

            local s = T.summary()
            return {
                total = s.total,
                passed = s.passed,
                failed = s.failed,
                errors = s.errors
            }
        """)

        let total = result.tableValue?["total"]?.intValue ?? 0
        let passed = result.tableValue?["passed"]?.intValue ?? 0
        let failed = result.tableValue?["failed"]?.intValue ?? 0

        // Report any failures
        if failed > 0 {
            if let errors = result.tableValue?["errors"]?.arrayValue {
                for error in errors {
                    if let errorTable = error.tableValue {
                        let name = errorTable["name"]?.stringValue ?? "unknown"
                        let msg = errorTable["error"]?.stringValue ?? "unknown error"
                        print("FAILED: \(name): \(msg)")
                    }
                }
            }
        }

        print("Lua Test Results: \(passed)/\(total) passed, \(failed) failed")
        XCTAssertGreaterThan(total, 0, "Should have run some tests")
        XCTAssertEqual(failed, 0, "All Lua tests should pass")
    }
}
