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

    /// Booby-traps both the `json` and `regex` namespace keys so that two
    /// independent (non-prerequisite) module installs fail in one run.
    private let jsonAndRegexPoison = """
        luaswift = setmetatable({}, {
            __newindex = function(t, k, v)
                if k == "json" or k == "regex" then
                    error("poisoned: " .. k .. " namespace")
                end
                rawset(t, k, v)
            end
        })
        """

    // MARK: - install(in:) surfaces setup failures

    func testModuleInstallSurfacesSetupFailure() throws {
        let engine = try LuaEngine()
        try engine.run(jsonPoison)

        XCTAssertThrowsError(try JSONModule.install(in: engine)) { error in
            // The Lua runtime error from the poisoned namespace surfaces as a
            // LuaError rather than some opaque type.
            XCTAssertTrue(error is LuaError, "Expected LuaError, got \(type(of: error))")
        }
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

    /// The annotation silences deprecation diagnostics for the one test that
    /// deliberately exercises the deprecated swallowing entry point.
    @available(*, deprecated, message: "Deliberately exercises the deprecated installModules(in:) shim")
    func testDeprecatedInstallModulesSwallowsFailures() throws {
        let engine = try LuaEngine()
        try engine.run(jsonPoison)

        // Must neither throw nor crash, exactly like the pre-#12 behavior.
        ModuleRegistry.installModules(in: engine)

        // The failure is swallowed but the other modules are still installed.
        let mathx = try engine.evaluate("return type(luaswift.mathx)")
        XCTAssertEqual(mathx.stringValue, "table")
    }

    // MARK: - Multiple independent failures

    func testMultipleModuleFailuresCollected() throws {
        let engine = try LuaEngine()
        try engine.run(jsonAndRegexPoison)

        XCTAssertThrowsError(try ModuleRegistry.install(in: engine)) { error in
            guard let installError = error as? ModuleInstallError else {
                XCTFail("Expected ModuleInstallError, got \(error)")
                return
            }
            XCTAssertEqual(installError.failures.count, 2)
            let names = Set(installError.failures.map { $0.module })
            XCTAssertTrue(names.contains("JSONModule"))
            XCTAssertTrue(names.contains("RegexModule"))
            // errorDescription pluralizes when more than one module failed.
            XCTAssertTrue(
                installError.errorDescription?.contains("2 modules failed") == true,
                "Description should pluralize: \(installError.errorDescription ?? "nil")")
        }

        // A module unrelated to either poisoned namespace still installed.
        let stringx = try engine.evaluate("return type(luaswift.stringx)")
        XCTAssertEqual(stringx.stringValue, "table")
    }

    // MARK: - moduleName drives the registry

    func testModuleNameMatchesTypeName() {
        XCTAssertEqual(JSONModule.moduleName, "JSONModule")
        XCTAssertEqual(RegexModule.moduleName, "RegexModule")
        XCTAssertEqual(StringXModule.moduleName, "StringXModule")
    }

    // MARK: - extend_stdlib failure path

    /// `extend_stdlib` runs last in `ModuleRegistry.install(in:)` as a
    /// finalization step. If it fails, a `ModuleInstallError` is thrown and the
    /// failure record names `"extend_stdlib"`, not a module.
    ///
    /// Freezing the `luaswift` global before install forces the finalization
    /// Lua snippet to fail when it tries to write aliases into that table.
    func testExtendStdlibFailureSurfacesInModuleInstallError() throws {
        let engine = try LuaEngine()
        // Make the luaswift table read-only so the extend_stdlib Lua snippet
        // cannot set aliases (any write raises an error).
        try engine.run("""
            luaswift = setmetatable({}, {
                __newindex = function(_, k, _)
                    error("luaswift is frozen: cannot set " .. tostring(k))
                end
            })
            """)

        XCTAssertThrowsError(try ModuleRegistry.install(in: engine)) { error in
            guard let installError = error as? ModuleInstallError else {
                XCTFail("Expected ModuleInstallError, got \(error)")
                return
            }
            let names = installError.failures.map { $0.module }
            XCTAssertTrue(names.contains("extend_stdlib"),
                          "extend_stdlib failure must be reported; failures: \(names)")
        }
    }

    // MARK: - Idempotency

    /// Installing all modules twice on the same engine must not crash or corrupt
    /// state. The second install either succeeds silently or throws a
    /// `ModuleInstallError`; either way the modules installed on the first pass
    /// must still be functional afterwards.
    func testModuleInstallIsIdempotent() throws {
        let engine = try LuaEngine()

        // First install: must succeed.
        XCTAssertNoThrow(try ModuleRegistry.install(in: engine))
        let afterFirst = try engine.evaluate("return luaswift.json.encode({v=1})")
        XCTAssertNotNil(afterFirst.stringValue,
                        "JSON must be functional after first install")

        // Second install: allowed to succeed or throw, but must not crash.
        // If it throws, catch and ignore.
        _ = try? ModuleRegistry.install(in: engine)

        // The module installed in the first pass must still work.
        let afterSecond = try engine.evaluate("return luaswift.json.encode({v=2})")
        XCTAssertNotNil(afterSecond.stringValue,
                        "JSON must remain functional after a second install attempt")
    }

    // MARK: - Concrete error type assertion

    /// `ModuleRegistry.install(in:)` must throw `ModuleInstallError` — not a
    /// plain `LuaError` or opaque `Error` — when at least one module fails.
    /// Callers relying on the typed API must be able to pattern-match on it.
    func testThrownErrorIsConcreteModuleInstallError() throws {
        let engine = try LuaEngine()
        try engine.run(jsonPoison)

        do {
            try ModuleRegistry.install(in: engine)
            XCTFail("Expected ModuleInstallError to be thrown")
        } catch let installError as ModuleInstallError {
            // Correct type: confirm the failure is structurally useful.
            XCTAssertFalse(installError.failures.isEmpty,
                           "ModuleInstallError must carry at least one failure")
            XCTAssertNotNil(installError.errorDescription,
                            "ModuleInstallError must have a non-nil errorDescription")
        } catch {
            XCTFail("Expected ModuleInstallError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - Prerequisite cascade

    #if LUASWIFT_NUMERICSWIFT
        /// Poisons the `mathsci` namespace so MathSciModule fails; its
        /// dependents (MathExprModule, then SeriesModule) must be skipped with a
        /// prerequisite reason rather than installed against a broken state.
        private let mathsciPoison = """
            luaswift = setmetatable({}, {
                __newindex = function(t, k, v)
                    if k == "mathsci" then error("poisoned: mathsci namespace") end
                    rawset(t, k, v)
                end
            })
            """

        func testPrerequisiteCascadeSkipsDependents() throws {
            let engine = try LuaEngine()
            try engine.run(mathsciPoison)

            XCTAssertThrowsError(try ModuleRegistry.install(in: engine)) { error in
                guard let installError = error as? ModuleInstallError else {
                    XCTFail("Expected ModuleInstallError, got \(error)")
                    return
                }
                let byName = Dictionary(
                    installError.failures.map { ($0.module, $0.underlyingError) },
                    uniquingKeysWith: { first, _ in first })

                // The prerequisite itself failed for the poisoned reason.
                XCTAssertNotNil(byName["MathSciModule"])

                // Both dependents were skipped, not installed, carrying the
                // synthetic prerequisite error.
                for dependent in ["MathExprModule", "SeriesModule"] {
                    guard let underlying = byName[dependent] else {
                        XCTFail("\(dependent) should have been skipped")
                        continue
                    }
                    XCTAssertTrue(
                        underlying is ModulePrerequisiteError,
                        "\(dependent) should carry ModulePrerequisiteError, got \(type(of: underlying))")
                    XCTAssertTrue(
                        underlying.localizedDescription.contains("prerequisite"),
                        "\(dependent) reason should mention the prerequisite: \(underlying.localizedDescription)")
                }
            }

            // An unrelated module (no prerequisite) still installed fine.
            let mathx = try engine.evaluate("return type(luaswift.mathx)")
            XCTAssertEqual(mathx.stringValue, "table")
        }
    #endif
}
