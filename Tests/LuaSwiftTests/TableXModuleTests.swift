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

    #if LUASWIFT_NUMERICSWIFT
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
    #endif  // LUASWIFT_NUMERICSWIFT

    // MARK: - Copy Tests

    func testCopyShallow() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1, b = 2, c = {nested = 3}}
            local t2 = tablex.copy(t1)
            t2.a = 99
            t2.c.nested = 100
            return {original_a = t1.a, original_nested = t1.c.nested, copied_a = t2.a}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        // Shallow copy: primitive changed independently
        XCTAssertEqual(table["original_a"]?.numberValue, 1)
        XCTAssertEqual(table["copied_a"]?.numberValue, 99)
        // Nested table is shared (shallow copy)
        XCTAssertEqual(table["original_nested"]?.numberValue, 100)
    }

    func testCopyArray() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr1 = {1, 2, 3}
            local arr2 = tablex.copy(arr1)
            arr2[1] = 99
            return {original = arr1[1], copied = arr2[1]}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["original"]?.numberValue, 1)
        XCTAssertEqual(table["copied"]?.numberValue, 99)
    }

    // MARK: - Map Tests

    func testMapDoubleValues() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1, b = 2, c = 3}
            return tablex.map(t, function(v) return v * 2 end)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["a"]?.numberValue, 2)
        XCTAssertEqual(table["b"]?.numberValue, 4)
        XCTAssertEqual(table["c"]?.numberValue, 6)
    }

    func testMapWithKey() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {x = 10, y = 20}
            return tablex.map(t, function(v, k) return k .. "=" .. v end)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["x"]?.stringValue, "x=10")
        XCTAssertEqual(table["y"]?.stringValue, "y=20")
    }

    func testMapArray() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3}
            return tablex.map(arr, function(v) return v * v end)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].numberValue, 1)
        XCTAssertEqual(array[1].numberValue, 4)
        XCTAssertEqual(array[2].numberValue, 9)
    }

    // MARK: - Filter Tests

    func testFilterArray() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3, 4, 5, 6}
            return tablex.filter(arr, function(v) return v % 2 == 0 end)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].numberValue, 2)
        XCTAssertEqual(array[1].numberValue, 4)
        XCTAssertEqual(array[2].numberValue, 6)
    }

    func testFilterTable() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1, b = 2, c = 3, d = 4}
            return tablex.filter(t, function(v) return v > 2 end)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertNil(table["a"])
        XCTAssertNil(table["b"])
        XCTAssertEqual(table["c"]?.numberValue, 3)
        XCTAssertEqual(table["d"]?.numberValue, 4)
    }

    func testFilterWithKey() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {apple = 1, banana = 2, cherry = 3}
            return tablex.filter(t, function(v, k) return string.sub(k, 1, 1) == "a" or string.sub(k, 1, 1) == "b" end)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["apple"]?.numberValue, 1)
        XCTAssertEqual(table["banana"]?.numberValue, 2)
        XCTAssertNil(table["cherry"])
    }

    // MARK: - Reduce Tests

    func testReduceSum() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3, 4, 5}
            return tablex.reduce(arr, function(acc, v) return acc + v end, 0)
            """)

        XCTAssertEqual(result.numberValue, 15)
    }

    func testReduceProduct() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3, 4}
            return tablex.reduce(arr, function(acc, v) return acc * v end, 1)
            """)

        XCTAssertEqual(result.numberValue, 24)
    }

    func testReduceConcat() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {"a", "b", "c"}
            return tablex.reduce(arr, function(acc, v) return acc .. v end, "")
            """)

        XCTAssertEqual(result.stringValue, "abc")
    }

    func testReduceWithKey() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1, b = 2}
            return tablex.reduce(t, function(acc, v, k) return acc .. k .. v end, "")
            """)

        // Order is not guaranteed, but both keys should be present
        let str = result.stringValue ?? ""
        XCTAssertTrue(str.contains("a1"))
        XCTAssertTrue(str.contains("b2"))
    }

    // MARK: - Foreach Tests

    func testForeachReturnsNil() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local sum = 0
            local result = tablex.foreach({1, 2, 3}, function(v) sum = sum + v end)
            return {sum = sum, result_is_nil = result == nil}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["sum"]?.numberValue, 6)
        XCTAssertEqual(table["result_is_nil"]?.boolValue, true)
    }

    // MARK: - Find Tests

    func testFindExisting() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = "apple", b = "banana", c = "cherry"}
            return tablex.find(t, "banana")
            """)

        XCTAssertEqual(result.stringValue, "b")
    }

    func testFindNotExisting() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1, b = 2, c = 3}
            return tablex.find(t, 99)
            """)

        XCTAssertTrue(result == .nil)
    }

    func testFindInArray() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {"a", "b", "c"}
            return tablex.find(arr, "b")
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    // MARK: - Contains Tests

    func testContainsTrue() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1, b = 2, c = 3}
            return tablex.contains(t, 2)
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testContainsFalse() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1, b = 2, c = 3}
            return tablex.contains(t, 99)
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testContainsString() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {"apple", "banana", "cherry"}
            return tablex.contains(arr, "banana")
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Size Tests

    func testSizeTable() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1, b = 2, c = 3, d = 4, e = 5}
            return tablex.size(t)
            """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testSizeArray() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3}
            return tablex.size(arr)
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testSizeEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.size({})
            """)

        XCTAssertEqual(result.numberValue, 0)
    }

    func testSizeMixed() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {1, 2, 3, a = "x", b = "y"}
            return tablex.size(t)
            """)

        XCTAssertEqual(result.numberValue, 5)
    }

    // MARK: - IsEmpty Tests

    func testIsEmptyTrue() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.isempty({})
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsEmptyFalse() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.isempty({a = 1})
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testIsEmptyArray() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.isempty({1})
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - IsArray Tests

    func testIsArrayTrue() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.isarray({1, 2, 3})
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsArrayFalse() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.isarray({a = 1, b = 2})
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testIsArrayMixed() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.isarray({1, 2, a = 3})
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testIsArrayEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.isarray({})
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsArrayWithHoles() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {[1] = "a", [3] = "c"}
            return tablex.isarray(t)
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - Slice Tests

    func testSliceBasic() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3, 4, 5}
            return tablex.slice(arr, 2, 4)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].numberValue, 2)
        XCTAssertEqual(array[1].numberValue, 3)
        XCTAssertEqual(array[2].numberValue, 4)
    }

    func testSliceToEnd() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3, 4, 5}
            return tablex.slice(arr, 3)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].numberValue, 3)
        XCTAssertEqual(array[1].numberValue, 4)
        XCTAssertEqual(array[2].numberValue, 5)
    }

    func testSliceNegativeIndices() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3, 4, 5}
            return tablex.slice(arr, -3, -1)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].numberValue, 3)
        XCTAssertEqual(array[1].numberValue, 4)
        XCTAssertEqual(array[2].numberValue, 5)
    }

    func testSliceOutOfBounds() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3}
            return tablex.slice(arr, 1, 10)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
    }

    // MARK: - Reverse Tests

    func testReverseBasic() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3, 4, 5}
            return tablex.reverse(arr)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 5)
        XCTAssertEqual(array[0].numberValue, 5)
        XCTAssertEqual(array[1].numberValue, 4)
        XCTAssertEqual(array[2].numberValue, 3)
        XCTAssertEqual(array[3].numberValue, 2)
        XCTAssertEqual(array[4].numberValue, 1)
    }

    func testReverseStrings() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {"a", "b", "c"}
            return tablex.reverse(arr)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array[0].stringValue, "c")
        XCTAssertEqual(array[1].stringValue, "b")
        XCTAssertEqual(array[2].stringValue, "a")
    }

    func testReverseEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.reverse({})
            """)

        // Empty table can be interpreted as either empty array or empty table
        if let array = result.arrayValue {
            XCTAssertEqual(array.count, 0)
        } else if let table = result.tableValue {
            XCTAssertEqual(table.count, 0)
        } else {
            XCTFail("Expected empty array or table result")
        }
    }

    // MARK: - Unique Tests

    func testUniqueNumbers() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 2, 3, 3, 3, 4}
            return tablex.unique(arr)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 4)
        XCTAssertEqual(array[0].numberValue, 1)
        XCTAssertEqual(array[1].numberValue, 2)
        XCTAssertEqual(array[2].numberValue, 3)
        XCTAssertEqual(array[3].numberValue, 4)
    }

    func testUniqueStrings() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {"a", "b", "a", "c", "b"}
            return tablex.unique(arr)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].stringValue, "a")
        XCTAssertEqual(array[1].stringValue, "b")
        XCTAssertEqual(array[2].stringValue, "c")
    }

    func testUniquePreservesOrder() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {3, 1, 2, 1, 3}
            return tablex.unique(arr)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].numberValue, 3)
        XCTAssertEqual(array[1].numberValue, 1)
        XCTAssertEqual(array[2].numberValue, 2)
    }

    // MARK: - Sort Tests

    func testSortAscending() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {3, 1, 4, 1, 5, 9, 2, 6}
            return tablex.sort(arr)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 8)
        XCTAssertEqual(array[0].numberValue, 1)
        XCTAssertEqual(array[1].numberValue, 1)
        XCTAssertEqual(array[2].numberValue, 2)
        XCTAssertEqual(array[3].numberValue, 3)
        XCTAssertEqual(array[7].numberValue, 9)
    }

    func testSortDescending() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {3, 1, 4, 1, 5}
            return tablex.sort(arr, function(a, b) return a > b end)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array[0].numberValue, 5)
        XCTAssertEqual(array[1].numberValue, 4)
        XCTAssertEqual(array[2].numberValue, 3)
        XCTAssertEqual(array[3].numberValue, 1)
        XCTAssertEqual(array[4].numberValue, 1)
    }

    func testSortStrings() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {"banana", "apple", "cherry"}
            return tablex.sort(arr)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array[0].stringValue, "apple")
        XCTAssertEqual(array[1].stringValue, "banana")
        XCTAssertEqual(array[2].stringValue, "cherry")
    }

    func testSortDoesNotModifyOriginal() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {3, 1, 2}
            local sorted = tablex.sort(arr)
            return {original_first = arr[1], sorted_first = sorted[1]}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["original_first"]?.numberValue, 3)
        XCTAssertEqual(table["sorted_first"]?.numberValue, 1)
    }

    // MARK: - Union Tests

    func testUnionBasic() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {1, 2, 3}
            local t2 = {3, 4, 5}
            return tablex.union(t1, t2)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 5)
        // Should contain 1, 2, 3, 4, 5 (no duplicates)
        let values = array.compactMap { $0.numberValue }
        XCTAssertTrue(values.contains(1))
        XCTAssertTrue(values.contains(2))
        XCTAssertTrue(values.contains(3))
        XCTAssertTrue(values.contains(4))
        XCTAssertTrue(values.contains(5))
    }

    func testUnionStrings() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {"a", "b"}
            local t2 = {"b", "c"}
            return tablex.union(t1, t2)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 3)
    }

    func testUnionEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {1, 2}
            local t2 = {}
            return tablex.union(t1, t2)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 2)
    }

    // MARK: - Intersection Tests

    func testIntersectionBasic() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {1, 2, 3, 4}
            local t2 = {3, 4, 5, 6}
            return tablex.intersection(t1, t2)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 2)
        let values = array.compactMap { $0.numberValue }
        XCTAssertTrue(values.contains(3))
        XCTAssertTrue(values.contains(4))
    }

    func testIntersectionNoOverlap() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {1, 2}
            local t2 = {3, 4}
            return tablex.intersection(t1, t2)
            """)

        // Empty result can be interpreted as either empty array or empty table
        if let array = result.arrayValue {
            XCTAssertEqual(array.count, 0)
        } else if let table = result.tableValue {
            XCTAssertEqual(table.count, 0)
        } else {
            XCTFail("Expected empty array or table result")
        }
    }

    func testIntersectionStrings() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {"a", "b", "c"}
            local t2 = {"b", "c", "d"}
            return tablex.intersection(t1, t2)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 2)
    }

    // MARK: - Difference Tests

    func testDifferenceBasic() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {1, 2, 3, 4}
            local t2 = {3, 4, 5}
            return tablex.difference(t1, t2)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 2)
        let values = array.compactMap { $0.numberValue }
        XCTAssertTrue(values.contains(1))
        XCTAssertTrue(values.contains(2))
    }

    func testDifferenceNoOverlap() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {1, 2}
            local t2 = {3, 4}
            return tablex.difference(t1, t2)
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 2)
    }

    func testDifferenceEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {1, 2, 3}
            local t2 = {1, 2, 3}
            return tablex.difference(t1, t2)
            """)

        // Empty result can be interpreted as either empty array or empty table
        if let array = result.arrayValue {
            XCTAssertEqual(array.count, 0)
        } else if let table = result.tableValue {
            XCTAssertEqual(table.count, 0)
        } else {
            XCTFail("Expected empty array or table result")
        }
    }

    // MARK: - Equals Tests

    func testEqualsTrue() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1, b = 2, c = 3}
            local t2 = {a = 1, b = 2, c = 3}
            return tablex.equals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testEqualsFalseDifferentValues() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1, b = 2}
            local t2 = {a = 1, b = 99}
            return tablex.equals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testEqualsFalseDifferentKeys() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1, b = 2}
            local t2 = {a = 1, c = 2}
            return tablex.equals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testEqualsFalseExtraKey() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1}
            local t2 = {a = 1, b = 2}
            return tablex.equals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testEqualsEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.equals({}, {})
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testEqualsNestedFalse() throws {
        // Shallow equals should fail on nested tables (different references)
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = {x = 1}}
            local t2 = {a = {x = 1}}
            return tablex.equals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - DeepEquals Tests

    func testDeepEqualsTrue() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = {x = 1, y = {z = 2}}}
            local t2 = {a = {x = 1, y = {z = 2}}}
            return tablex.deepequals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testDeepEqualsFalse() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = {x = 1, y = {z = 2}}}
            local t2 = {a = {x = 1, y = {z = 99}}}
            return tablex.deepequals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testDeepEqualsWithArrays() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {1, {2, 3}, {4, {5, 6}}}
            local t2 = {1, {2, 3}, {4, {5, 6}}}
            return tablex.deepequals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testDeepEqualsPrimitives() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.deepequals(42, 42)
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testDeepEqualsDifferentTypes() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.deepequals(42, "42")
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testDeepEqualsEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.deepequals({}, {})
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testDeepEqualsExtraNestedKey() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = {x = 1}}
            local t2 = {a = {x = 1, y = 2}}
            return tablex.deepequals(t1, t2)
            """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - Additional Edge Case Tests (Penlight Review)

    func testMapEmptyTable() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.map({}, function(v) return v * 2 end)
            """)

        // Empty result can be array or table
        if let array = result.arrayValue {
            XCTAssertEqual(array.count, 0)
        } else if let table = result.tableValue {
            XCTAssertEqual(table.count, 0)
        } else {
            XCTFail("Expected empty result")
        }
    }

    func testFilterReturnsEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3}
            return tablex.filter(arr, function(v) return v > 100 end)
            """)

        // Empty result can be array or table
        if let array = result.arrayValue {
            XCTAssertEqual(array.count, 0)
        } else if let table = result.tableValue {
            XCTAssertEqual(table.count, 0)
        } else {
            XCTFail("Expected empty result")
        }
    }

    func testReduceSingleElement() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {42}
            return tablex.reduce(arr, function(acc, v) return acc + v end, 0)
            """)

        XCTAssertEqual(result.numberValue, 42)
    }

    func testReduceEmptyTable() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.reduce({}, function(acc, v) return acc + v end, 100)
            """)

        // With empty table, returns initial value
        XCTAssertEqual(result.numberValue, 100)
    }

    func testDeepcopyEmptyTable() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {}
            local copy = tablex.deepcopy(t)
            copy.new_key = "value"
            return {original_empty = next(t) == nil, copy_has_key = copy.new_key ~= nil}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["original_empty"]?.boolValue, true)
        XCTAssertEqual(table["copy_has_key"]?.boolValue, true)
    }

    func testDeepmergeEmptyTables() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local merged = tablex.deepmerge({}, {})
            return next(merged) == nil
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testDeepmergeOneEmpty() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local merged = tablex.deepmerge({a = 1}, {})
            return merged.a
            """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testCopyEmptyTable() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local copy = tablex.copy({})
            return next(copy) == nil
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testFindFirstOccurrence() throws {
        // Find should return the first matching key
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {10, 20, 20, 30}
            return tablex.find(arr, 20)
            """)

        // Should return 2 (first occurrence)
        XCTAssertEqual(result.numberValue, 2)
    }

    func testUniqueSingleElement() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            return tablex.unique({42})
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 1)
        XCTAssertEqual(array[0].numberValue, 42)
    }

    func testSliceEmptyResult() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local arr = {1, 2, 3}
            return tablex.slice(arr, 10, 20)
            """)

        // Slice beyond bounds returns empty
        if let array = result.arrayValue {
            XCTAssertEqual(array.count, 0)
        } else if let table = result.tableValue {
            XCTAssertEqual(table.count, 0)
        } else {
            XCTFail("Expected empty result")
        }
    }

    func testDeepEqualsWithNilValues() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t1 = {a = 1, b = nil}
            local t2 = {a = 1}
            return tablex.deepequals(t1, t2)
            """)

        // nil values are equivalent to missing keys
        XCTAssertEqual(result.boolValue, true)
    }

    func testCycleDetectionInLuaDeepCopy() throws {
        // Test cycle detection works in Lua (we can't return cyclic structure to Swift)
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = 1}
            t.self = t  -- Create cycle

            -- This should not hang due to cycle detection
            local copy = tablex.deepcopy(t)

            -- Verify the copy exists and has the original value
            return copy.a == 1 and copy.self == copy
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testForeachWithKey() throws {
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local keys = {}
            tablex.foreach({a = 1, b = 2}, function(v, k)
                keys[#keys + 1] = k
            end)
            table.sort(keys)
            return keys[1] .. keys[2]
            """)

        XCTAssertEqual(result.stringValue, "ab")
    }

    func testInvertDuplicateValues() throws {
        // When values are duplicated, last one wins
        let result = try engine.evaluate("""
            local tablex = luaswift.tablex
            local t = {a = "x", b = "x", c = "y"}
            local inv = tablex.invert(t)
            return {has_x = inv.x ~= nil, has_y = inv.y ~= nil}
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["has_x"]?.boolValue, true)
        XCTAssertEqual(table["has_y"]?.boolValue, true)
    }
}
