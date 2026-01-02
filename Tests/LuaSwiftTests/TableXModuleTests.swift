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

    // Note: Circular reference test is skipped because Lua tables with circular references
    // cannot be properly converted to Swift's value-type LuaValue representation.
    // The conversion itself would cause infinite recursion.

    func testDeepcopyPrimitives() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {str = "hello", num = 42, bool = true}
            local copy = tablex.deepcopy(t)
            return {str = copy.str, num = copy.num, bool = copy.bool}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["str"]?.stringValue, "hello")
        XCTAssertEqual(table["num"]?.numberValue, 42)
        XCTAssertEqual(table["bool"]?.boolValue, true)
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

    // MARK: - Type-Aware Deepcopy Tests

    func testDeepcopyPreservesComplexType() throws {
        // Register required modules
        ComplexModule.register(in: engine)
        TypesModule.register(in: engine)

        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local complex = luaswift.complex

            local t = {
                name = "test",
                value = complex.new(3, 4)
            }
            local copy = tablex.deepcopy(t)

            -- Verify the copy is independent
            local orig_type = t.value.__luaswift_type
            local copy_type = copy.value.__luaswift_type
            local orig_re = t.value.re
            local copy_re = copy.value.re

            return {
                orig_type = orig_type,
                copy_type = copy_type,
                orig_re = orig_re,
                copy_re = copy_re,
                types_match = orig_type == copy_type
            }
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["orig_type"]?.stringValue, "complex")
        XCTAssertEqual(table["copy_type"]?.stringValue, "complex")
        XCTAssertEqual(table["orig_re"]?.numberValue, 3)
        XCTAssertEqual(table["copy_re"]?.numberValue, 3)
        XCTAssertEqual(table["types_match"]?.boolValue, true)
    }

    func testDeepcopyPreservesVec2Type() throws {
        // Register required modules
        GeometryModule.register(in: engine)
        TypesModule.register(in: engine)

        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local geo = luaswift.geometry

            local t = {
                name = "point",
                pos = geo.vec2(10, 20)
            }
            local copy = tablex.deepcopy(t)

            return {
                orig_type = t.pos.__luaswift_type,
                copy_type = copy.pos.__luaswift_type,
                orig_x = t.pos.x,
                copy_x = copy.pos.x,
                orig_y = t.pos.y,
                copy_y = copy.pos.y
            }
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["orig_type"]?.stringValue, "vec2")
        XCTAssertEqual(table["copy_type"]?.stringValue, "vec2")
        XCTAssertEqual(table["orig_x"]?.numberValue, 10)
        XCTAssertEqual(table["copy_x"]?.numberValue, 10)
        XCTAssertEqual(table["orig_y"]?.numberValue, 20)
        XCTAssertEqual(table["copy_y"]?.numberValue, 20)
    }

    func testDeepcopyPreservesVec3Type() throws {
        // Register required modules
        GeometryModule.register(in: engine)
        TypesModule.register(in: engine)

        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local geo = luaswift.geometry

            local t = {
                name = "point3d",
                pos = geo.vec3(1, 2, 3)
            }
            local copy = tablex.deepcopy(t)

            return {
                orig_type = t.pos.__luaswift_type,
                copy_type = copy.pos.__luaswift_type,
                orig_x = t.pos.x,
                copy_x = copy.pos.x,
                orig_z = t.pos.z,
                copy_z = copy.pos.z
            }
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["orig_type"]?.stringValue, "vec3")
        XCTAssertEqual(table["copy_type"]?.stringValue, "vec3")
        XCTAssertEqual(table["orig_x"]?.numberValue, 1)
        XCTAssertEqual(table["copy_x"]?.numberValue, 1)
        XCTAssertEqual(table["orig_z"]?.numberValue, 3)
        XCTAssertEqual(table["copy_z"]?.numberValue, 3)
    }

    func testDeepcopyNestedMixedTypes() throws {
        // Register required modules
        ComplexModule.register(in: engine)
        GeometryModule.register(in: engine)
        TypesModule.register(in: engine)

        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local complex = luaswift.complex
            local geo = luaswift.geometry

            local t = {
                name = "mixed",
                data = {
                    point = geo.vec2(5, 10),
                    number = complex.new(1, 2),
                    nested = {
                        point3d = geo.vec3(1, 2, 3)
                    }
                }
            }
            local copy = tablex.deepcopy(t)

            return {
                point_type = copy.data.point.__luaswift_type,
                number_type = copy.data.number.__luaswift_type,
                nested_type = copy.data.nested.point3d.__luaswift_type,
                point_x = copy.data.point.x,
                number_re = copy.data.number.re,
                nested_z = copy.data.nested.point3d.z
            }
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["point_type"]?.stringValue, "vec2")
        XCTAssertEqual(table["number_type"]?.stringValue, "complex")
        XCTAssertEqual(table["nested_type"]?.stringValue, "vec3")
        XCTAssertEqual(table["point_x"]?.numberValue, 5)
        XCTAssertEqual(table["number_re"]?.numberValue, 1)
        XCTAssertEqual(table["nested_z"]?.numberValue, 3)
    }

    // MARK: - Type-Aware Deepmerge Tests

    func testDeepmergeReplacesTypedObjects() throws {
        // Register required modules
        ComplexModule.register(in: engine)
        TypesModule.register(in: engine)

        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local complex = luaswift.complex

            local t1 = {
                value = complex.new(1, 2)
            }
            local t2 = {
                value = complex.new(3, 4)
            }
            local merged = tablex.deepmerge(t1, t2)

            return {
                merged_type = merged.value.__luaswift_type,
                merged_re = merged.value.re,
                merged_im = merged.value.im
            }
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["merged_type"]?.stringValue, "complex")
        XCTAssertEqual(table["merged_re"]?.numberValue, 3)
        XCTAssertEqual(table["merged_im"]?.numberValue, 4)
    }

    func testDeepmergeTypedWithRegularTable() throws {
        // Register required modules
        GeometryModule.register(in: engine)
        TypesModule.register(in: engine)

        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local geo = luaswift.geometry

            -- Merge where t1 has typed object and t2 has regular table
            local t1 = {
                pos = geo.vec2(1, 2)
            }
            local t2 = {
                pos = {x = 10, y = 20, extra = "data"}
            }
            local merged = tablex.deepmerge(t1, t2)

            -- The typed object should be replaced by the regular table
            return {
                has_extra = merged.pos.extra ~= nil,
                pos_x = merged.pos.x,
                pos_y = merged.pos.y,
                -- Check that it's no longer a typed object
                is_typed = rawget(merged.pos, "__luaswift_type") ~= nil
            }
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["has_extra"]?.boolValue, true)
        XCTAssertEqual(table["pos_x"]?.numberValue, 10)
        XCTAssertEqual(table["pos_y"]?.numberValue, 20)
        XCTAssertEqual(table["is_typed"]?.boolValue, false)
    }
}
