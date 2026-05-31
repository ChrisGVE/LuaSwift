//
//  ModuleRequireTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-05-31.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import LuaSwift

/// Verifies that each module registers a requireable name in `package.loaded`
/// so that `require("luaswift.X")` returns the module table (in addition to the
/// global-table access style). Regression coverage for the previously-broken
/// `require()` paths.
final class ModuleRequireTests: XCTestCase {

    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    /// Assert that `require(name)` returns a table exposing `member` as the
    /// given Lua type.
    private func assertRequireExposes(
        _ name: String,
        member: String,
        ofType luaType: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let result = try engine.evaluate(
            """
            local m = require("\(name)")
            return type(m) .. "/" .. type(m.\(member))
            """)
        XCTAssertEqual(
            result.stringValue, "table/\(luaType)",
            "require(\"\(name)\") should return a table whose '\(member)' is a \(luaType)",
            file: file, line: line)
    }

    func testJSONRequire() throws {
        ModuleRegistry.installJSONModule(in: engine)
        try assertRequireExposes("luaswift.json", member: "encode", ofType: "function")
        try assertRequireExposes("luaswift.json", member: "decode", ofType: "function")
    }

    func testYAMLRequire() throws {
        ModuleRegistry.installYAMLModule(in: engine)
        try assertRequireExposes("luaswift.yaml", member: "encode", ofType: "function")
    }

    func testRegexRequire() throws {
        ModuleRegistry.installRegexModule(in: engine)
        try assertRequireExposes("luaswift.regex", member: "compile", ofType: "function")
    }

    func testMathXRequire() throws {
        ModuleRegistry.installMathModule(in: engine)
        try assertRequireExposes("luaswift.mathx", member: "round", ofType: "function")
        // Backward-compatibility alias.
        try assertRequireExposes("luaswift.math", member: "round", ofType: "function")
    }

    func testUTF8XRequire() throws {
        ModuleRegistry.installUTF8XModule(in: engine)
        try assertRequireExposes("luaswift.utf8x", member: "width", ofType: "function")
    }

    func testStringXRequire() throws {
        ModuleRegistry.installStringXModule(in: engine)
        try assertRequireExposes("luaswift.stringx", member: "split", ofType: "function")
    }

    func testTableXRequire() throws {
        ModuleRegistry.installTableXModule(in: engine)
        try assertRequireExposes("luaswift.tablex", member: "deepcopy", ofType: "function")
    }

    #if DEBUG
        func testDebugRequire() throws {
            ModuleRegistry.installDebugModule(in: engine)
            try assertRequireExposes("luaswift.debug", member: "log", ofType: "table")
        }
    #endif
}
