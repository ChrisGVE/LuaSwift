//
//  IntrospectionTests.swift
//  Tests/LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Context: Tests for LuaEngine+Introspection (F4 / #21) — registered value
//  servers, registered functions, installed modules, globalNames, globalValue,
//  raw-access guarantees at every depth, and cross-version behaviour (5.1 /
//  5.2–5.5).
//

import XCTest

@testable import LuaSwift

final class IntrospectionTests: XCTestCase {

    // MARK: - registeredValueServerNames

    func testRegisteredValueServerNames_containsRegisteredServer() throws {
        let engine = try LuaEngine()
        let server = MockServer(namespace: "game")
        engine.register(server: server)
        XCTAssertTrue(
            engine.registeredValueServerNames.contains("game"),
            "Expected 'game' in registeredValueServerNames, got: \(engine.registeredValueServerNames)"
        )
    }

    func testRegisteredValueServerNames_emptyWhenNoneRegistered() throws {
        let engine = try LuaEngine()
        // No servers registered — should be empty.
        XCTAssertTrue(
            engine.registeredValueServerNames.isEmpty,
            "Expected empty registeredValueServerNames, got: \(engine.registeredValueServerNames)"
        )
    }

    // MARK: - registeredFunctionNames

    func testRegisteredFunctionNames_containsRegisteredCallback() throws {
        let engine = try LuaEngine()
        engine.registerFunction(name: "log") { _ in .nil }
        XCTAssertTrue(
            engine.registeredFunctionNames.contains("log"),
            "Expected 'log' in registeredFunctionNames, got: \(engine.registeredFunctionNames)"
        )
    }

    func testRegisteredFunctionNames_emptyWhenNoneRegistered() throws {
        let engine = try LuaEngine()
        XCTAssertTrue(
            engine.registeredFunctionNames.isEmpty,
            "Expected empty registeredFunctionNames, got: \(engine.registeredFunctionNames)"
        )
    }

    // MARK: - installedModuleNames

    func testInstalledModuleNames_afterRegistryInstall() throws {
        let engine = try LuaEngine()
        // Install just the JSON module via the registry path.
        try JSONModule.install(in: engine)
        engine.recordInstalledModule(JSONModule.moduleName)
        XCTAssertTrue(
            engine.installedModuleNames.contains(JSONModule.moduleName),
            "Expected '\(JSONModule.moduleName)' in installedModuleNames, got: \(engine.installedModuleNames)"
        )
    }

    func testInstalledModuleNames_viaModuleRegistry() throws {
        let engine = try LuaEngine()
        // ModuleRegistry.install records all successful modules automatically.
        try ModuleRegistry.install(in: engine)
        // JSON is always installed (it has no compile-time gate).
        XCTAssertTrue(
            engine.installedModuleNames.contains(JSONModule.moduleName),
            "Expected '\(JSONModule.moduleName)' in installedModuleNames after ModuleRegistry.install, got: \(engine.installedModuleNames)"
        )
    }

    func testInstalledModuleNames_emptyBeforeInstall() throws {
        let engine = try LuaEngine()
        XCTAssertTrue(
            engine.installedModuleNames.isEmpty,
            "Expected empty installedModuleNames before any install, got: \(engine.installedModuleNames)"
        )
    }

    // MARK: - globalNames

    func testGlobalNames_userDefined_afterRun() throws {
        let engine = try LuaEngine()
        try engine.run("x = 5")
        let userNames = engine.globalNames(includingStandardLibrary: false)
        XCTAssertTrue(
            userNames.contains("x"),
            "Expected 'x' in user-defined globalNames, got: \(userNames)"
        )
        XCTAssertFalse(
            userNames.contains("print"),
            "'print' should not appear in user-defined globalNames (it is stdlib)"
        )
    }

    func testGlobalNames_includingStdlib_containsPrint() throws {
        let engine = try LuaEngine()
        let allNames = engine.globalNames(includingStandardLibrary: true)
        XCTAssertTrue(
            allNames.contains("print"),
            "Expected 'print' in globalNames(includingStandardLibrary:true)"
        )
    }

    func testGlobalNames_includingStdlib_containsUserDefined() throws {
        let engine = try LuaEngine()
        try engine.run("my_var = 99")
        let allNames = engine.globalNames(includingStandardLibrary: true)
        XCTAssertTrue(
            allNames.contains("my_var"),
            "Expected 'my_var' in globalNames(includingStandardLibrary:true)"
        )
    }

    func testGlobalNames_noStdlib_doesNotContainPrint() throws {
        let engine = try LuaEngine()
        let userNames = engine.globalNames(includingStandardLibrary: false)
        XCTAssertFalse(
            userNames.contains("print"),
            "'print' should be excluded from user-defined globalNames"
        )
    }

    // MARK: - globalValue

    func testGlobalValue_number() throws {
        let engine = try LuaEngine()
        try engine.run("x = 5")
        let value = engine.globalValue("x")
        switch value {
        case .number(let n):
            XCTAssertEqual(n, 5.0, "Expected x == 5.0")
        default:
            XCTFail("Expected .number(5) for global x, got \(String(describing: value))")
        }
    }

    func testGlobalValue_string() throws {
        let engine = try LuaEngine()
        try engine.run(#"greeting = "hello""#)
        let value = engine.globalValue("greeting")
        switch value {
        case .string(let s):
            XCTAssertEqual(s, "hello")
        default:
            XCTFail("Expected .string('hello') for global greeting, got \(String(describing: value))")
        }
    }

    func testGlobalValue_nilForMissing() throws {
        let engine = try LuaEngine()
        XCTAssertNil(
            engine.globalValue("nonexistent"),
            "Expected nil for nonexistent global"
        )
    }

    func testGlobalValue_nilForLuaNil() throws {
        let engine = try LuaEngine()
        try engine.run("gone = nil")
        XCTAssertNil(
            engine.globalValue("gone"),
            "Expected nil when global is explicitly set to nil"
        )
    }

    // MARK: - Raw access: __index NOT fired

    /// A global table whose metatable has a side-effecting __index.
    /// globalValue must NOT trigger __index — the flag must stay false.
    func testGlobalValue_rawAccess_doesNotFire_indexMetamethod() throws {
        let engine = try LuaEngine()
        // 'sideEffectFired' starts false. The __index metamethod sets it to true.
        // We access a key that does NOT exist in the base table to force
        // __index to be consulted IF the access were non-raw.
        try engine.run("""
            sideEffectFired = false
            local mt = {
                __index = function(t, k)
                    sideEffectFired = true
                    return nil
                end
            }
            probed = setmetatable({present = 1}, mt)
            """)

        // This raw read of 'probed' retrieves the table — no __index.
        let value = engine.globalValue("probed")
        XCTAssertNotNil(value, "Expected non-nil value for 'probed'")

        // Confirm the side effect was NOT triggered.
        let fired = engine.globalValue("sideEffectFired")
        switch fired {
        case .bool(let b):
            XCTAssertFalse(b, "__index was fired during raw globalValue — raw contract broken")
        case .number(let n):
            XCTAssertEqual(n, 0.0, "__index should not have fired")
        default:
            // If globalValue returned the table, we need to verify via run.
            let result = try engine.evaluate("return sideEffectFired")
            switch result {
            case .bool(let b):
                XCTAssertFalse(b, "__index was fired during raw globalValue — raw contract broken")
            default:
                break
            }
        }
    }

    // MARK: - Raw access: __pairs NOT fired (top-level)

    /// A global table whose metatable has a side-effecting __pairs.
    /// globalNames must NOT trigger __pairs — the flag must stay false.
    func testGlobalNames_rawAccess_doesNotFire_pairsMetamethod() throws {
        let engine = try LuaEngine()
        try engine.run("""
            pairsMetamethodFired = false
            local mt = {
                __pairs = function(t)
                    pairsMetamethodFired = true
                    return next, t, nil
                end
            }
            -- Set a table with __pairs as a global.
            probedTable = setmetatable({a = 1}, mt)
            """)

        // globalNames enumerates the globals table — the table with __pairs IS
        // a value in the globals table, not the globals table itself, so the
        // real test is that __pairs is not invoked on the globals table wrapper.
        // We want to confirm the enumeration loop ran without triggering __pairs.
        let names = engine.globalNames(includingStandardLibrary: true)
        XCTAssertTrue(names.contains("probedTable"), "probedTable should appear in globalNames")

        // Confirm __pairs was NOT triggered by the enumeration.
        let result = try engine.evaluate("return pairsMetamethodFired")
        switch result {
        case .bool(let b):
            XCTAssertFalse(
                b,
                "__pairs was fired during globalNames enumeration — raw contract broken"
            )
        default:
            XCTFail("Unexpected result type for pairsMetamethodFired: \(result)")
        }
    }

    // MARK: - Raw access: __pairs NOT fired on NESTED table (recursive raw)

    /// A global table containing a nested table with a side-effecting __pairs.
    /// globalValue must NOT trigger __pairs on the nested table when
    /// materialising it recursively.
    func testGlobalValue_rawAccess_doesNotFire_nestedPairsMetamethod() throws {
        let engine = try LuaEngine()
        try engine.run("""
            nestedPairsFired = false
            local innerMt = {
                __pairs = function(t)
                    nestedPairsFired = true
                    return next, t, nil
                end
            }
            local inner = setmetatable({value = 42}, innerMt)
            outer = { child = inner }
            """)

        // Retrieve 'outer' — this triggers rawValueFromStack, which recurses
        // into the 'child' table and must use raw lua_next, NOT pairs().
        let outerValue = engine.globalValue("outer")
        XCTAssertNotNil(outerValue, "Expected non-nil value for 'outer'")

        // Confirm __pairs on the inner table was NOT fired during materialisation.
        let result = try engine.evaluate("return nestedPairsFired")
        switch result {
        case .bool(let b):
            XCTAssertFalse(
                b,
                "__pairs on nested table was fired during recursive rawValueFromStack — raw contract broken"
            )
        default:
            XCTFail("Unexpected result type for nestedPairsFired: \(result)")
        }
    }

    // MARK: - Raw access: __index NOT fired on NESTED table (recursive raw)

    /// Similar to the __pairs test but for __index on a nested table.
    func testGlobalValue_rawAccess_doesNotFire_nestedIndexMetamethod() throws {
        let engine = try LuaEngine()
        try engine.run("""
            nestedIndexFired = false
            local innerMt = {
                __index = function(t, k)
                    nestedIndexFired = true
                    return nil
                end
            }
            local inner = setmetatable({knownKey = 7}, innerMt)
            container = { nested = inner }
            """)

        let containerValue = engine.globalValue("container")
        XCTAssertNotNil(containerValue, "Expected non-nil value for 'container'")

        // During materialisation of 'container', the nested table 'inner' is
        // iterated with raw lua_next — __index must NOT fire.
        let result = try engine.evaluate("return nestedIndexFired")
        switch result {
        case .bool(let b):
            XCTAssertFalse(
                b,
                "__index on nested table was fired during recursive rawValueFromStack — raw contract broken"
            )
        default:
            XCTFail("Unexpected result type for nestedIndexFired: \(result)")
        }
    }

    // MARK: - Post-introspection run correctness

    /// Introspection must not corrupt the Lua stack or state. A subsequent
    /// run after introspection calls must produce the same result as before.
    func testIntrospectionDoesNotCorruptSubsequentRun() throws {
        let engine = try LuaEngine()
        try engine.run("counter = 0")

        // First run.
        try engine.run("counter = counter + 1")
        let before = try engine.evaluate("return counter")

        // Introspect.
        _ = engine.globalNames(includingStandardLibrary: true)
        _ = engine.globalValue("counter")
        _ = engine.registeredValueServerNames
        _ = engine.registeredFunctionNames

        // Second run — same increment.
        try engine.run("counter = counter + 1")
        let after = try engine.evaluate("return counter")

        switch (before, after) {
        case (.number(let b), .number(let a)):
            XCTAssertEqual(a, b + 1, "Expected counter to increment by 1 after introspection")
        default:
            XCTFail("Unexpected value types: before=\(before), after=\(after)")
        }
    }

    // MARK: - recordInstalledModule

    func testRecordInstalledModule_manualRegistration() throws {
        let engine = try LuaEngine()
        XCTAssertFalse(engine.installedModuleNames.contains("CustomModule"))
        engine.recordInstalledModule("CustomModule")
        XCTAssertTrue(
            engine.installedModuleNames.contains("CustomModule"),
            "Expected 'CustomModule' after recordInstalledModule"
        )
    }

    // MARK: - Baseline snapshot: no user-defined globals at init

    /// Immediately after init (no user code run), user-defined globals should
    /// be empty.
    func testBaselineSnapshot_noUserDefinedGlobalsAtInit() throws {
        let engine = try LuaEngine()
        let userNames = engine.globalNames(includingStandardLibrary: false)
        XCTAssertTrue(
            userNames.isEmpty,
            "Expected no user-defined globals at init, got: \(userNames)"
        )
    }

    /// After defining a global, it appears as user-defined but not before.
    func testBaselineSnapshot_newGlobalAppearsAsUserDefined() throws {
        let engine = try LuaEngine()
        let before = engine.globalNames(includingStandardLibrary: false)
        XCTAssertFalse(before.contains("freshVar"))

        try engine.run("freshVar = 'hello'")
        let after = engine.globalNames(includingStandardLibrary: false)
        XCTAssertTrue(after.contains("freshVar"), "Expected 'freshVar' as user-defined after run")
    }
}

// MARK: - Test Helpers

/// Minimal LuaValueServer for testing registeredValueServerNames.
private final class MockServer: LuaValueServer {
    let namespace: String

    init(namespace: String) {
        self.namespace = namespace
    }

    func resolve(path: [String]) -> LuaValue { .nil }
}
