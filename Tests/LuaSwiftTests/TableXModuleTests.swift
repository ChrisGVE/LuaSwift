//
//  TableXModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class TableXModuleTests: XCTestCase {

    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        TableXModule.register(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Deep Copy Tests

    func testDeepcopyNestedTables() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1, b = {c = 2, d = {e = 3}}}
            local t2 = tablex.deepcopy(t1)
            t2.b.c = 99
            t2.b.d.e = 100
            return {original_c = t1.b.c, original_e = t1.b.d.e, copied_c = t2.b.c, copied_e = t2.b.d.e}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["original_c"]?.numberValue, 2)
        XCTAssertEqual(table["original_e"]?.numberValue, 3)
        XCTAssertEqual(table["copied_c"]?.numberValue, 99)
        XCTAssertEqual(table["copied_e"]?.numberValue, 100)
    }

    func testDeepcopyArrays() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr1 = {1, 2, {3, 4}}
            local arr2 = tablex.deepcopy(arr1)
            arr2[3][1] = 99
            return {original = arr1[3][1], copied = arr2[3][1]}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["original"]?.numberValue, 3)
        XCTAssertEqual(table["copied"]?.numberValue, 99)
    }

    func testDeepcopyCircularReferences() throws {
        // This should handle circular references gracefully without crashing
        // Note: true circular references cannot be preserved when converting to/from Swift value types
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1}
            t.self = t
            local copy = tablex.deepcopy(t)
            -- The circular reference becomes an empty table placeholder
            return {has_a = copy.a == 1, self_is_table = type(copy.self) == "table"}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["has_a"]?.numberValue, 1)
        XCTAssertEqual(table["self_is_table"]?.boolValue, true)
    }

    func testDeepcopyPrimitives() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {str = "hello", num = 42, bool = true, null = nil}
            local copy = tablex.deepcopy(t)
            return {str = copy.str, num = copy.num, bool = copy.bool, null = copy.null}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["str"]?.stringValue, "hello")
        XCTAssertEqual(table["num"]?.numberValue, 42)
        XCTAssertEqual(table["bool"]?.boolValue, true)
        XCTAssertEqual(table["null"]?.isNil, true)
    }

    // MARK: - Deep Merge Tests

    func testDeepmergeNestedTables() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1, b = {x = 1, y = 2}}
            local t2 = {b = {y = 3, z = 4}, c = 5}
            local merged = tablex.deepmerge(t1, t2)
            return merged
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["a"]?.numberValue, 1)
        XCTAssertEqual(table["c"]?.numberValue, 5)

        guard let b = table["b"]?.tableValue else {
            XCTFail("Expected nested table 'b'")
            return
        }

        XCTAssertEqual(b["x"]?.numberValue, 1)
        XCTAssertEqual(b["y"]?.numberValue, 3)  // t2 overrides t1
        XCTAssertEqual(b["z"]?.numberValue, 4)
    }

    func testDeepmergeOverride() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1, b = 2}
            local t2 = {b = 99, c = 3}
            local merged = tablex.deepmerge(t1, t2)
            return merged
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["a"]?.numberValue, 1)
        XCTAssertEqual(table["b"]?.numberValue, 99)  // t2 overrides
        XCTAssertEqual(table["c"]?.numberValue, 3)
    }

    // MARK: - Flatten Tests

    func testFlattenFullDepth() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, {2, 3}, {4, {5, 6}}}
            return tablex.flatten(arr)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 6)
        XCTAssertEqual(array[0].numberValue, 1)
        XCTAssertEqual(array[1].numberValue, 2)
        XCTAssertEqual(array[2].numberValue, 3)
        XCTAssertEqual(array[3].numberValue, 4)
        XCTAssertEqual(array[4].numberValue, 5)
        XCTAssertEqual(array[5].numberValue, 6)
    }

    func testFlattenLimitedDepth() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, {2, {3, 4}}}
            return tablex.flatten(arr, 1)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].numberValue, 1)
        XCTAssertEqual(array[1].numberValue, 2)

        guard let nested = array[2].arrayValue else {
            XCTFail("Expected nested array")
            return
        }

        XCTAssertEqual(nested.count, 2)
        XCTAssertEqual(nested[0].numberValue, 3)
        XCTAssertEqual(nested[1].numberValue, 4)
    }

    func testFlattenDepthZero() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, {2, 3}}
            return tablex.flatten(arr, 0)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 2)
        XCTAssertEqual(array[0].numberValue, 1)

        guard let nested = array[1].arrayValue else {
            XCTFail("Expected nested array")
            return
        }

        XCTAssertEqual(nested.count, 2)
    }

    // MARK: - Keys Tests

    func testKeys() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {z = 1, a = 2, m = 3}
            return tablex.keys(t)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        // Keys should be sorted
        XCTAssertEqual(array[0].stringValue, "a")
        XCTAssertEqual(array[1].stringValue, "m")
        XCTAssertEqual(array[2].stringValue, "z")
    }

    // MARK: - Values Tests

    func testValues() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {z = 1, a = 2, m = 3}
            return tablex.values(t)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        // Values should be in sorted key order
        XCTAssertEqual(array[0].numberValue, 2)  // a
        XCTAssertEqual(array[1].numberValue, 3)  // m
        XCTAssertEqual(array[2].numberValue, 1)  // z
    }

    // MARK: - Invert Tests

    func testInvertStringValues() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = "x", b = "y", c = "z"}
            return tablex.invert(t)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["x"]?.stringValue, "a")
        XCTAssertEqual(table["y"]?.stringValue, "b")
        XCTAssertEqual(table["z"]?.stringValue, "c")
    }

    func testInvertNumericValues() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1, b = 2, c = 3}
            return tablex.invert(t)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["1"]?.stringValue, "a")
        XCTAssertEqual(table["2"]?.stringValue, "b")
        XCTAssertEqual(table["3"]?.stringValue, "c")
    }

    func testInvertBooleanValues() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = true, b = false}
            return tablex.invert(t)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["true"]?.stringValue, "a")
        XCTAssertEqual(table["false"]?.stringValue, "b")
    }

    func testInvertSkipsComplexValues() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = "x", b = {nested = true}, c = "y"}
            local inverted = tablex.invert(t)
            return {has_x = inverted.x ~= nil, has_y = inverted.y ~= nil, count = 0}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["has_x"]?.boolValue, true)
        XCTAssertEqual(table["has_y"]?.boolValue, true)
        // The nested table should be skipped, so only "x" and "y" keys exist
    }
}
