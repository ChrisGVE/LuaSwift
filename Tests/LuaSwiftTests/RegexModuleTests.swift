//
//  RegexModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class RegexModuleTests: XCTestCase {

    // MARK: - Setup

    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installRegexModule(in: engine)
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Basic Tests

    func testCompileSimplePattern() throws {
        let result = try engine.evaluate("""
            local re = luaswift.regex.compile("\\\\d+")
            return re ~= nil
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testQuickMatchFound() throws {
        let result = try engine.evaluate("""
            local match = luaswift.regex.match("hello world", "\\\\w+")
            return match.text
            """)

        XCTAssertEqual(result.stringValue, "hello")
    }

    func testModuleNamespace() throws {
        try engine.run("""
            assert(luaswift ~= nil)
            assert(luaswift.regex ~= nil)
            assert(type(luaswift.regex.compile) == "function")
            assert(type(luaswift.regex.match) == "function")
            """)
    }
}
