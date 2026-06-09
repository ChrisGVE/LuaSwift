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

    func testPackagePathWithSingleQuote() throws {
        // A single quote in the path must not break package.path setup
        // (issue #16: path was interpolated into a Lua string literal)
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: "/tmp/it's-a-dir",
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        let result = try engine.evaluate("return package.path")
        XCTAssertEqual(result.stringValue, "/tmp/it's-a-dir/?.lua",
                       "packagePath containing a single quote should be set verbatim")
    }

    func testPackagePathWithLuaMeaningfulSequences() throws {
        // Lua-meaningful sequences in the path must end up verbatim in
        // package.path and never be executed as code (issue #16)
        let maliciousPath = "/tmp/x']..os.exit()..['"
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: maliciousPath,
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        let result = try engine.evaluate("return package.path")
        XCTAssertEqual(result.stringValue, "\(maliciousPath)/?.lua",
                       "packagePath must be treated as data, never as Lua code")
    }

    // MARK: - warn Removal Tests (CR-015)

    func testSandboxedEngineHasNoWarn() throws {
        // The `warn` global (Lua 5.4+) must be removed under the sandbox so a
        // script cannot enable warnings and flood stderr. On 5.1-5.3 `warn`
        // never existed, so `warn == nil` holds on every version.
        let engine = try LuaEngine()  // sandboxed by default

        let result = try engine.evaluate("return warn == nil")
        XCTAssertEqual(result.boolValue, true,
                       "warn should be nil in sandboxed mode on all Lua versions")
    }

    func testNonSandboxedHasWarnOn54Plus() throws {
        // Sanity check that the removal is meaningful: on the versions that ship
        // `warn` (5.4+), an unsandboxed engine still exposes it. Versions without
        // `warn` have nothing to assert, so the check is gated.
        #if LUA_VERSION_54 || LUA_VERSION_55
        let engine = try LuaEngine(configuration: .unrestricted)
        let result = try engine.evaluate("return type(warn) == 'function'")
        XCTAssertEqual(result.boolValue, true,
                       "warn should exist in non-sandboxed Lua 5.4/5.5")
        #else
        // Lua 5.1-5.3 have no warn; nothing to verify.
        throw XCTSkip("warn is only present in Lua 5.4+")
        #endif
    }

    // MARK: - Sandbox Install Failure Surfaces (CR-003)

    func testApplySandboxOnHealthyEngineDoesNotThrow() throws {
        // Happy-path coverage of the now-throwing applySandbox: a healthy state
        // installs the sandbox without throwing, and dangerous globals are gone.
        // This does NOT exercise the throw-on-failure branch — a deterministic
        // install failure cannot be triggered without injecting a failing
        // snippet into production code. The tiny-vmMemoryLimit path in
        // VMMemoryLimitTests.testTinyLimitInitThrowsCleanlyOrSucceeds exercises
        // that branch opportunistically (init throws a LuaError rather than
        // crashing when the sandbox Lua cannot allocate).
        let engine = try LuaEngine()  // sandboxed init ran applySandbox successfully

        // Re-running the sandbox on the healthy state must not throw.
        XCTAssertNoThrow(try engine.applySandbox(hasPackagePath: false))

        // And the guarantees still hold afterwards.
        let removed = try engine.evaluate("return os.execute == nil and load == nil")
        XCTAssertEqual(removed.boolValue, true,
                       "dangerous globals remain removed after sandbox install")
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

    // MARK: - Long-bracket injection in packagePath (CR-024)

    /// A `packagePath` value containing the long-bracket-close sequence `]]`
    /// must not break out of any Lua string context. `setPackagePath` uses the
    /// C API (`lua_pushstring` + `lua_setfield`) which treats the path as raw
    /// data rather than interpolating it into a Lua source string, so `]]`
    /// cannot close an imaginary bracket level.
    ///
    /// This tests the contract: `package.path` must equal the raw value with
    /// `/?.lua` appended, byte-for-byte, regardless of how many `]]` sequences
    /// it contains.
    func testPackagePathWithLongBracketCloseIsSetVerbatim() throws {
        // A path whose name contains the two-character sequence ]] — the only
        // sequence that closes a Lua long-bracket string of level 0.
        let maliciousPath = "/tmp/dir]]evil"
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: maliciousPath,
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        let result = try engine.evaluate("return package.path")
        XCTAssertEqual(result.stringValue, "\(maliciousPath)/?.lua",
                       "packagePath with ]] must be set verbatim, not interpreted as bracket close")
    }

    /// A `packagePath` containing `]]` in a deeply nested form (e.g. `]===]`)
    /// must also be stored verbatim. The C-API path is data-safe for all
    /// such sequences, not just level-0 long-brackets.
    func testPackagePathWithNestedBracketSequenceIsSetVerbatim() throws {
        let trickyPath = "/tmp/x]=]y"
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: trickyPath,
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        let result = try engine.evaluate("return package.path")
        XCTAssertEqual(result.stringValue, "\(trickyPath)/?.lua",
                       "packagePath with ]=] must be set verbatim")
    }

    // MARK: - compat.bit32 on unsandboxed path

    /// The `compat` Lua module provides a `bit32` shim on all Lua versions.
    /// The existing tests exercise it via a sandboxed engine whose `packagePath`
    /// is set to the LuaModules directory. This test verifies the shim is
    /// equally functional on an **unsandboxed** engine (`.unrestricted`), where
    /// `load()` is available and the 5.3+ bitwise-operator implementation path
    /// inside `compat.lua` can use it rather than falling back to a stub.
    func testCompatBit32WorksOnUnsandboxedEngine() throws {
        // Build the path to LuaModules relative to this test file, matching
        // the pattern from LuaModuleTests.createEngineWithLuaModules().
        let sourceRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()   // LuaSwiftTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // project root
        let modulesPath = sourceRoot
            .appendingPathComponent("Sources")
            .appendingPathComponent("LuaSwift")
            .appendingPathComponent("LuaModules")
            .path

        guard FileManager.default.fileExists(atPath: modulesPath) else {
            throw XCTSkip("LuaModules directory not found; skipping unsandboxed compat test")
        }

        // Unsandboxed engine with load() and io available — the richer code
        // path inside compat.lua for 5.3+ is exercised because load() exists.
        let config = LuaEngineConfiguration(
            sandboxed: false,
            packagePath: modulesPath,
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        // Spot-check several bit32 functions to confirm the shim is complete.
        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                band  = b.band(0xFF, 0x0F),
                bor   = b.bor(0xF0, 0x0F),
                bxor  = b.bxor(0xFF, 0x0F),
                lsh   = b.lshift(1, 4),
                rsh   = b.rshift(16, 4),
            }
        """)
        let t = result.tableValue
        XCTAssertEqual(t?["band"]?.numberValue, 0x0F,  "bit32.band on unsandboxed engine")
        XCTAssertEqual(t?["bor"]?.numberValue,  0xFF,  "bit32.bor on unsandboxed engine")
        XCTAssertEqual(t?["bxor"]?.numberValue, 0xF0,  "bit32.bxor on unsandboxed engine")
        XCTAssertEqual(t?["lsh"]?.numberValue,  16.0,  "bit32.lshift on unsandboxed engine")
        XCTAssertEqual(t?["rsh"]?.numberValue,  1.0,   "bit32.rshift on unsandboxed engine")
    }

    // MARK: - package.preload writability under sandbox (CR-902)

    /// Documents the current behavior of `package.preload` under the sandbox:
    /// it is writable — a sandboxed Lua script can register new preload entries
    /// and `require` them. This is intentional (the preload mechanism is the
    /// safe, sandbox-approved module registration path), and the existing
    /// `testPreloadSearcherWorks` already verifies the happy path.
    ///
    /// This test additionally asserts that a second write (overwriting an
    /// existing preload entry) also succeeds — confirming that `package.preload`
    /// is a plain writable table, not a locked metatable.
    ///
    /// SECURITY NOTE: `package.preload` being writable means a sandboxed script
    /// can shadow any preloaded module with its own factory. This is acceptable
    /// for the current LuaSwift use model (Swift modules are registered via the
    /// C API into `package.loaded` and do not rely on the preload path), but
    /// callers who register modules via `package.preload` from Swift should be
    /// aware that sandboxed Lua code can overwrite those entries.
    func testPackagePreloadIsWritableUnderSandbox() throws {
        let engine = try LuaEngine()  // sandboxed by default

        // First write: register a new module.
        let firstResult = try engine.evaluate("""
            package.preload['sandboxmod'] = function() return {x = 10} end
            local m = require('sandboxmod')
            return m.x
        """)
        XCTAssertEqual(firstResult.intValue, 10,
                       "First preload write must succeed in sandboxed mode")

        // Second write: overwrite an existing preload entry.
        let secondResult = try engine.evaluate("""
            package.preload['sandboxmod'] = function() return {x = 99} end
            package.loaded['sandboxmod'] = nil  -- clear the cache so require re-runs
            local m = require('sandboxmod')
            return m.x
        """)
        XCTAssertEqual(secondResult.intValue, 99,
                       "Overwriting a preload entry must also succeed (preload table is writable)")
    }

    /// In sandboxed mode, `package.preload` itself must exist as a table (not
    /// nil) so that the preload mechanism remains functional for safe module
    /// registration.
    func testPackagePreloadExistsAsSandboxedTable() throws {
        let engine = try LuaEngine()  // sandboxed by default

        let result = try engine.evaluate("return type(package.preload)")
        XCTAssertEqual(result.stringValue, "table",
                       "package.preload must be a table in sandboxed mode")
    }
}
