//
//  ModuleInstallTests.swift
//  Tests/LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Context: Covers the throwing module-install API (issue #12) — the
//  LuaSwiftModule.install(in:) entry points, ModuleRegistry.install(in:)
//  failure collection via ModuleInstallError, and the behavior-preserving
//  deprecated register/installModules shims. Complements the per-module
//  functional test files, which exercise the installed Lua APIs.
//

import XCTest

@testable import LuaSwift

final class ModuleInstallTests: XCTestCase {

    /// Lua that booby-traps the shared `luaswift` namespace for the `json`
    /// key only: JSONModule's setup fails while every other module still
    /// installs, letting tests separate fail-fast from collection semantics.
    private let jsonPoison = """
        luaswift = setmetatable({}, {
            __newindex = function(t, k, v)
                if k == "json" then error("poisoned: json namespace") end
                rawset(t, k, v)
            end
        })
        """

    // MARK: - install(in:) surfaces setup failures

    func testModuleInstallSurfacesSetupFailure() throws {
        let engine = try LuaEngine()
        try engine.run(jsonPoison)

        XCTAssertThrowsError(try JSONModule.install(in: engine))
    }

    func testModuleInstallSucceedsOnFreshEngine() throws {
        let engine = try LuaEngine()

        XCTAssertNoThrow(try JSONModule.install(in: engine))

        let encoded = try engine.evaluate("""
            return luaswift.json.encode({a = 1})
            """)
        XCTAssertEqual(encoded.stringValue, #"{"a":1}"#)
    }

    // MARK: - ModuleRegistry.install(in:) collects failures

    func testRegistryInstallCollectsFailuresAndContinues() throws {
        let engine = try LuaEngine()
        try engine.run(jsonPoison)

        XCTAssertThrowsError(try ModuleRegistry.install(in: engine)) { error in
            guard let installError = error as? ModuleInstallError else {
                XCTFail("Expected ModuleInstallError, got \(error)")
                return
            }
            XCTAssertFalse(installError.failures.isEmpty)
            XCTAssertEqual(installError.failures.map { $0.module }, ["JSONModule"])
            XCTAssertNotNil(installError.errorDescription)
            XCTAssertTrue(
                installError.errorDescription?.contains("JSONModule") == true,
                "Description should name the failed module")
        }

        // Collection semantics: modules listed after the failing one were
        // still installed rather than being skipped fail-fast.
        let mathx = try engine.evaluate("return type(luaswift.mathx)")
        XCTAssertEqual(mathx.stringValue, "table")
        let stringx = try engine.evaluate("return type(luaswift.stringx)")
        XCTAssertEqual(stringx.stringValue, "table")
    }

    func testRegistryInstallHappyPath() throws {
        let engine = try LuaEngine()

        XCTAssertNoThrow(try ModuleRegistry.install(in: engine))

        // Spot-check a couple of installed namespaces actually work.
        let decoded = try engine.evaluate("""
            return luaswift.json.decode('{"name":"chris"}').name
            """)
        XCTAssertEqual(decoded.stringValue, "chris")

        let capitalized = try engine.evaluate("""
            return luaswift.stringx.capitalize("hello")
            """)
        XCTAssertEqual(capitalized.stringValue, "Hello")
    }

    // MARK: - Deprecated shims preserve swallowing behavior

    func testDeprecatedInstallModulesSwallowsFailures() throws {
        let engine = try LuaEngine()
        try engine.run(jsonPoison)

        // Must neither throw nor crash, exactly like the pre-#12 behavior.
        ModuleRegistry.installModules(in: engine)

        // The failure is swallowed but the other modules are still installed.
        let mathx = try engine.evaluate("return type(luaswift.mathx)")
        XCTAssertEqual(mathx.stringValue, "table")
    }
}
