//
//  SandboxTests.swift
//  LuaSwift
//
//  Created on 2026-01-20.
//
//  Tests for sandbox security guarantees - verifying that sandboxed mode
//  properly blocks access to dangerous functionality and prevents bypass attempts.
//

import XCTest
@testable import LuaSwift

final class SandboxTests: XCTestCase {

    // MARK: - require() Bypass Tests

    func testRequireIoBlockedInSandbox() throws {
        // In sandboxed mode, require('io') should fail because
        // we cleared package.loaded.io
        let engine = try LuaEngine()  // sandboxed by default

        let result = try engine.evaluate("""
            local success, result = pcall(function()
                return require('io')
            end)
            return success
        """)

        // The require should fail (success = false)
        XCTAssertEqual(result.boolValue, false, "require('io') should fail in sandboxed mode")
    }

    func testRequireDebugBlockedInSandbox() throws {
        // In sandboxed mode, require('debug') should fail because
        // we cleared package.loaded.debug
        let engine = try LuaEngine()

        let result = try engine.evaluate("""
            local success, result = pcall(function()
                return require('debug')
            end)
            return success
        """)

        XCTAssertEqual(result.boolValue, false, "require('debug') should fail in sandboxed mode")
    }

    func testPackageLoadedIoIsNil() throws {
        // Verify package.loaded.io is nil after sandbox is applied
        let engine = try LuaEngine()

        let result = try engine.evaluate("return package.loaded.io == nil")
        XCTAssertEqual(result.boolValue, true, "package.loaded.io should be nil in sandboxed mode")
    }

    func testPackageLoadedDebugIsNil() throws {
        // Verify package.loaded.debug is nil after sandbox is applied
        let engine = try LuaEngine()

        let result = try engine.evaluate("return package.loaded.debug == nil")
        XCTAssertEqual(result.boolValue, true, "package.loaded.debug should be nil in sandboxed mode")
    }

    // MARK: - package.loadlib Tests

    func testPackageLoadlibIsNil() throws {
        // package.loadlib should be disabled for App Store compliance
        let engine = try LuaEngine()

        let result = try engine.evaluate("return package.loadlib == nil")
        XCTAssertEqual(result.boolValue, true, "package.loadlib should be nil in sandboxed mode")
    }

    func testPackageCpathIsEmpty() throws {
        // package.cpath should be empty to prevent C library loading
        let engine = try LuaEngine()

        let result = try engine.evaluate("return package.cpath == ''")
        XCTAssertEqual(result.boolValue, true, "package.cpath should be empty in sandboxed mode")
    }

    // MARK: - package.searchers Tests

    func testPackageSearchersOnlyHasPreloadWhenNoPackagePath() throws {
        // Without packagePath config, only the preload searcher should remain (index 1)
        // This prevents loading any .lua files from disk
        let engine = try LuaEngine()  // No packagePath

        // Lua 5.2+ uses package.searchers, Lua 5.1 uses package.loaders
        let result = try engine.evaluate("""
            local searchers = package.searchers or package.loaders
            return #searchers
        """)

        XCTAssertEqual(result.intValue, 1, "Only preload searcher should remain when no packagePath configured")
    }

    func testPackageSearchersKeptWhenPackagePathSet() throws {
        // With packagePath config, file searchers are kept so modules can be loaded
        // from the explicitly allowed directory
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: "/some/test/path",
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        // Lua 5.2+ uses package.searchers, Lua 5.1 uses package.loaders
        let result = try engine.evaluate("""
            local searchers = package.searchers or package.loaders
            return #searchers
        """)

        // Should have more than just the preload searcher
        XCTAssertGreaterThan(result.intValue ?? 0, 1, "File searchers should be kept when packagePath is configured")
    }

    func testPackagePathIsEmpty() throws {
        // package.path should be empty (unless packagePath config is set)
        let engine = try LuaEngine()

        let result = try engine.evaluate("return package.path == ''")
        XCTAssertEqual(result.boolValue, true, "package.path should be empty in default sandboxed mode")
    }

    // MARK: - Safe Functions Still Work

    func testSafeOsFunctionsWork() throws {
        // Safe os functions should still be available
        let engine = try LuaEngine()

        // os.time should work
        let timeResult = try engine.evaluate("return type(os.time()) == 'number'")
        XCTAssertEqual(timeResult.boolValue, true, "os.time() should work")

        // os.date should work
        let dateResult = try engine.evaluate("return type(os.date()) == 'string'")
        XCTAssertEqual(dateResult.boolValue, true, "os.date() should work")

        // os.clock should work
        let clockResult = try engine.evaluate("return type(os.clock()) == 'number'")
        XCTAssertEqual(clockResult.boolValue, true, "os.clock() should work")

        // os.difftime should work
        let diffResult = try engine.evaluate("""
            local t1 = os.time()
            local t2 = os.time()
            return type(os.difftime(t2, t1)) == 'number'
        """)
        XCTAssertEqual(diffResult.boolValue, true, "os.difftime() should work")
    }

    func testDangerousOsFunctionsBlocked() throws {
        // Dangerous os functions should be nil
        let engine = try LuaEngine()

        let checks = [
            ("os.execute", "os.execute == nil"),
            ("os.exit", "os.exit == nil"),
            ("os.remove", "os.remove == nil"),
            ("os.rename", "os.rename == nil"),
            ("os.tmpname", "os.tmpname == nil"),
            ("os.getenv", "os.getenv == nil"),
            ("os.setlocale", "os.setlocale == nil")
        ]

        for (name, check) in checks {
            let result = try engine.evaluate("return \(check)")
            XCTAssertEqual(result.boolValue, true, "\(name) should be nil in sandboxed mode")
        }
    }

    func testSafeLibrariesAvailable() throws {
        // Math, string, table, coroutine should be available
        // utf8 is only available in Lua 5.3+
        let engine = try LuaEngine()

        let libraries = ["math", "string", "table", "coroutine"]
        for lib in libraries {
            let result = try engine.evaluate("return type(\(lib)) == 'table'")
            XCTAssertEqual(result.boolValue, true, "\(lib) library should be available")
        }

        // utf8 library is only in Lua 5.3+
        #if LUA_VERSION_51 || LUA_VERSION_52
        let utf8Result = try engine.evaluate("return utf8 == nil")
        XCTAssertEqual(utf8Result.boolValue, true, "utf8 should not exist in Lua 5.1/5.2")
        #else
        let utf8Result = try engine.evaluate("return type(utf8) == 'table'")
        XCTAssertEqual(utf8Result.boolValue, true, "utf8 library should be available in Lua 5.3+")
        #endif
    }

    func testLoadFunctionsBlocked() throws {
        // load, loadfile, dofile, loadstring should all be nil
        let engine = try LuaEngine()

        let functions = ["load", "loadfile", "dofile", "loadstring"]
        for fn in functions {
            let result = try engine.evaluate("return \(fn) == nil")
            XCTAssertEqual(result.boolValue, true, "\(fn) should be nil in sandboxed mode")
        }
    }

    // MARK: - Non-Sandboxed Mode Tests

    func testNonSandboxedHasIo() throws {
        // In non-sandboxed mode, io should be available
        let engine = try LuaEngine(configuration: .unrestricted)

        let result = try engine.evaluate("return type(io) == 'table'")
        XCTAssertEqual(result.boolValue, true, "io should be available in non-sandboxed mode")
    }

    func testNonSandboxedHasDebug() throws {
        // In non-sandboxed mode, debug should be available
        let engine = try LuaEngine(configuration: .unrestricted)

        let result = try engine.evaluate("return type(debug) == 'table'")
        XCTAssertEqual(result.boolValue, true, "debug should be available in non-sandboxed mode")
    }

    func testNonSandboxedRequireWorks() throws {
        // In non-sandboxed mode, require should work for built-in modules
        let engine = try LuaEngine(configuration: .unrestricted)

        let result = try engine.evaluate("""
            local io = require('io')
            return type(io) == 'table'
        """)
        XCTAssertEqual(result.boolValue, true, "require('io') should work in non-sandboxed mode")
    }

    // MARK: - Package Path Configuration Tests

    func testPackagePathCanBeSet() throws {
        // Even in sandboxed mode, packagePath config should set the path
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: "/some/test/path",
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        let result = try engine.evaluate("return package.path")
        XCTAssertEqual(result.stringValue, "/some/test/path/?.lua",
                       "packagePath should set package.path")
    }

    // MARK: - Preload Searcher Still Works

    func testPreloadSearcherWorks() throws {
        // package.preload should still work for registering modules
        let engine = try LuaEngine()

        let result = try engine.evaluate("""
            -- Register a module via preload
            package.preload['mymodule'] = function()
                return { value = 42 }
            end
            -- Now require it
            local mod = require('mymodule')
            return mod.value
        """)

        XCTAssertEqual(result.intValue, 42, "Preloaded modules should be loadable via require")
    }
}
