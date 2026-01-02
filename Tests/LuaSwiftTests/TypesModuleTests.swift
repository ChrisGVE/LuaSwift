//
//  TypesModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class TypesModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        // Install all modules since types module depends on other modules for conversions
        ModuleRegistry.installModules(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - typeof Tests

    func testTypeofNumber() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.typeof(42)
        """)

        XCTAssertEqual(result.stringValue, "number")
    }

    func testTypeofString() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.typeof("hello")
        """)

        XCTAssertEqual(result.stringValue, "string")
    }

    func testTypeofBoolean() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.typeof(true)
        """)

        XCTAssertEqual(result.stringValue, "boolean")
    }

    func testTypeofNil() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.typeof(nil)
        """)

        XCTAssertEqual(result.stringValue, "nil")
    }

    func testTypeofFunction() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.typeof(function() end)
        """)

        XCTAssertEqual(result.stringValue, "function")
    }

    func testTypeofPlainTable() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.typeof({a = 1, b = 2})
        """)

        XCTAssertEqual(result.stringValue, "table")
    }

    func testTypeofComplex() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local c = luaswift.complex.new(1, 2)
            return types.typeof(c)
        """)

        XCTAssertEqual(result.stringValue, "complex")
    }

    func testTypeofVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.geometry.vec2(3, 4)
            return types.typeof(v)
        """)

        XCTAssertEqual(result.stringValue, "vec2")
    }

    func testTypeofVec3() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.geometry.vec3(1, 2, 3)
            return types.typeof(v)
        """)

        XCTAssertEqual(result.stringValue, "vec3")
    }

    func testTypeofQuaternion() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local q = luaswift.geometry.quaternion.identity()
            return types.typeof(q)
        """)

        XCTAssertEqual(result.stringValue, "quaternion")
    }

    func testTypeofTransform3d() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local t = luaswift.geometry.transform3d()
            return types.typeof(t)
        """)

        XCTAssertEqual(result.stringValue, "transform3d")
    }

    func testTypeofLinalgVector() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.linalg.vector({1, 2, 3})
            return types.typeof(v)
        """)

        XCTAssertEqual(result.stringValue, "linalg.vector")
    }

    func testTypeofLinalgMatrix() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local m = luaswift.linalg.matrix({{1, 2}, {3, 4}})
            return types.typeof(m)
        """)

        XCTAssertEqual(result.stringValue, "linalg.matrix")
    }

    func testTypeofArray() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local a = luaswift.array.array({1, 2, 3, 4})
            return types.typeof(a)
        """)

        XCTAssertEqual(result.stringValue, "array")
    }

    // MARK: - is() Tests

    func testIsComplex() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local c = luaswift.complex.new(1, 2)
            return types.is(c, "complex")
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsNotComplex() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is(42, "complex")
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testIsVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.geometry.vec2(1, 2)
            return types.is(v, "vec2")
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsNumber() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is(42, "number")
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - is_luaswift() Tests

    func testIsLuaswiftComplex() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local c = luaswift.complex.new(1, 2)
            return types.is_luaswift(c)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsLuaswiftNumber() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_luaswift(42)
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testIsLuaswiftPlainTable() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_luaswift({a = 1})
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testIsLuaswiftVec3() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.geometry.vec3(1, 2, 3)
            return types.is_luaswift(v)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsLuaswiftArray() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local a = luaswift.array.array({1, 2, 3})
            return types.is_luaswift(a)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - is_numeric() Tests

    func testIsNumericNumber() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_numeric(42)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsNumericComplex() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local c = luaswift.complex.new(1, 2)
            return types.is_numeric(c)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsNumericString() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_numeric("42")
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testIsNumericVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_numeric(luaswift.geometry.vec2(1, 2))
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - is_vector() Tests

    func testIsVectorVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_vector(luaswift.geometry.vec2(1, 2))
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsVectorVec3() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_vector(luaswift.geometry.vec3(1, 2, 3))
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsVectorLinalgVector() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_vector(luaswift.linalg.vector({1, 2, 3}))
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsVectorArray() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_vector(luaswift.array.array({1, 2, 3}))
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - is_matrix() Tests

    func testIsMatrixLinalgMatrix() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_matrix(luaswift.linalg.matrix({{1, 2}, {3, 4}}))
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsMatrixArray() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_matrix(luaswift.array.array({1, 2, 3}))
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsMatrixVec3() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_matrix(luaswift.geometry.vec3(1, 2, 3))
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - is_geometry() Tests

    func testIsGeometryVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_geometry(luaswift.geometry.vec2(1, 2))
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsGeometryVec3() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_geometry(luaswift.geometry.vec3(1, 2, 3))
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsGeometryQuaternion() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_geometry(luaswift.geometry.quaternion.identity())
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsGeometryTransform3d() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_geometry(luaswift.geometry.transform3d())
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsGeometryComplex() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.is_geometry(luaswift.complex.new(1, 2))
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - to_array() Tests

    func testToArrayFromVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.geometry.vec2(3, 4)
            local arr = types.to_array(v)
            return {types.typeof(arr), arr:tolist()}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let typeStr = arr[0].stringValue,
              let list = arr[1].arrayValue else {
            XCTFail("Expected array with type and list")
            return
        }

        XCTAssertEqual(typeStr, "array")
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].numberValue, 3)
        XCTAssertEqual(list[1].numberValue, 4)
    }

    func testToArrayFromVec3() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.geometry.vec3(1, 2, 3)
            local arr = types.to_array(v)
            return arr:tolist()
        """)

        guard let list = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list[0].numberValue, 1)
        XCTAssertEqual(list[1].numberValue, 2)
        XCTAssertEqual(list[2].numberValue, 3)
    }

    func testToArrayFromLinalgVector() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.linalg.vector({5, 6, 7})
            local arr = types.to_array(v)
            return arr:tolist()
        """)

        guard let list = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list[0].numberValue, 5)
        XCTAssertEqual(list[1].numberValue, 6)
        XCTAssertEqual(list[2].numberValue, 7)
    }

    func testToArrayFromTable() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local arr = types.to_array({10, 20, 30})
            return arr:tolist()
        """)

        guard let list = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list[0].numberValue, 10)
        XCTAssertEqual(list[1].numberValue, 20)
        XCTAssertEqual(list[2].numberValue, 30)
    }

    func testToArrayFromArrayReturnsItself() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local a = luaswift.array.array({1, 2, 3})
            local b = types.to_array(a)
            return a == b
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - to_vec2() Tests

    func testToVec2FromArray() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local a = luaswift.array.array({3, 4})
            local v = types.to_vec2(a)
            return {types.typeof(v), v.x, v.y}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 3,
              let typeStr = arr[0].stringValue,
              let x = arr[1].numberValue,
              let y = arr[2].numberValue else {
            XCTFail("Expected array with type and coordinates")
            return
        }

        XCTAssertEqual(typeStr, "vec2")
        XCTAssertEqual(x, 3, accuracy: 1e-10)
        XCTAssertEqual(y, 4, accuracy: 1e-10)
    }

    func testToVec2FromLinalgVector() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local lv = luaswift.linalg.vector({5, 6})
            local v = types.to_vec2(lv)
            return {v.x, v.y}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let x = arr[0].numberValue,
              let y = arr[1].numberValue else {
            XCTFail("Expected array with coordinates")
            return
        }

        XCTAssertEqual(x, 5, accuracy: 1e-10)
        XCTAssertEqual(y, 6, accuracy: 1e-10)
    }

    func testToVec2FromTable() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = types.to_vec2({7, 8})
            return {v.x, v.y}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let x = arr[0].numberValue,
              let y = arr[1].numberValue else {
            XCTFail("Expected array with coordinates")
            return
        }

        XCTAssertEqual(x, 7, accuracy: 1e-10)
        XCTAssertEqual(y, 8, accuracy: 1e-10)
    }

    func testToVec2FromVec2ReturnsItself() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v1 = luaswift.geometry.vec2(1, 2)
            local v2 = types.to_vec2(v1)
            return v1 == v2
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - to_vec3() Tests

    func testToVec3FromVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v2 = luaswift.geometry.vec2(1, 2)
            local v3 = types.to_vec3(v2)
            return {v3.x, v3.y, v3.z}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 3,
              let x = arr[0].numberValue,
              let y = arr[1].numberValue,
              let z = arr[2].numberValue else {
            XCTFail("Expected array with coordinates")
            return
        }

        XCTAssertEqual(x, 1, accuracy: 1e-10)
        XCTAssertEqual(y, 2, accuracy: 1e-10)
        XCTAssertEqual(z, 0, accuracy: 1e-10)
    }

    func testToVec3FromArray() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local a = luaswift.array.array({3, 4, 5})
            local v = types.to_vec3(a)
            return {v.x, v.y, v.z}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 3,
              let x = arr[0].numberValue,
              let y = arr[1].numberValue,
              let z = arr[2].numberValue else {
            XCTFail("Expected array with coordinates")
            return
        }

        XCTAssertEqual(x, 3, accuracy: 1e-10)
        XCTAssertEqual(y, 4, accuracy: 1e-10)
        XCTAssertEqual(z, 5, accuracy: 1e-10)
    }

    func testToVec3FromLinalgVector() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local lv = luaswift.linalg.vector({7, 8, 9})
            local v = types.to_vec3(lv)
            return {v.x, v.y, v.z}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 3,
              let x = arr[0].numberValue,
              let y = arr[1].numberValue,
              let z = arr[2].numberValue else {
            XCTFail("Expected array with coordinates")
            return
        }

        XCTAssertEqual(x, 7, accuracy: 1e-10)
        XCTAssertEqual(y, 8, accuracy: 1e-10)
        XCTAssertEqual(z, 9, accuracy: 1e-10)
    }

    func testToVec3FromTableWith2Elements() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = types.to_vec3({1, 2})
            return {v.x, v.y, v.z}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 3,
              let x = arr[0].numberValue,
              let y = arr[1].numberValue,
              let z = arr[2].numberValue else {
            XCTFail("Expected array with coordinates")
            return
        }

        XCTAssertEqual(x, 1, accuracy: 1e-10)
        XCTAssertEqual(y, 2, accuracy: 1e-10)
        XCTAssertEqual(z, 0, accuracy: 1e-10)
    }

    func testToVec3FromVec3ReturnsItself() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v1 = luaswift.geometry.vec3(1, 2, 3)
            local v2 = types.to_vec3(v1)
            return v1 == v2
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - to_complex() Tests

    func testToComplexFromNumber() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local c = types.to_complex(5)
            return {c.re, c.im}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let re = arr[0].numberValue,
              let im = arr[1].numberValue else {
            XCTFail("Expected array with re and im")
            return
        }

        XCTAssertEqual(re, 5, accuracy: 1e-10)
        XCTAssertEqual(im, 0, accuracy: 1e-10)
    }

    func testToComplexFromVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v = luaswift.geometry.vec2(3, 4)
            local c = types.to_complex(v)
            return {c.re, c.im}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let re = arr[0].numberValue,
              let im = arr[1].numberValue else {
            XCTFail("Expected array with re and im")
            return
        }

        XCTAssertEqual(re, 3, accuracy: 1e-10)
        XCTAssertEqual(im, 4, accuracy: 1e-10)
    }

    func testToComplexFromComplexReturnsItself() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local c1 = luaswift.complex.new(1, 2)
            local c2 = types.to_complex(c1)
            return c1 == c2
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - to_vector() Tests

    func testToVectorFromVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v2 = luaswift.geometry.vec2(3, 4)
            local lv = types.to_vector(v2)
            return {types.typeof(lv), lv:toarray()}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let typeStr = arr[0].stringValue,
              let data = arr[1].arrayValue else {
            XCTFail("Expected array with type and data")
            return
        }

        XCTAssertEqual(typeStr, "linalg.vector")
        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(data[0].numberValue, 3)
        XCTAssertEqual(data[1].numberValue, 4)
    }

    func testToVectorFromVec3() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v3 = luaswift.geometry.vec3(1, 2, 3)
            local lv = types.to_vector(v3)
            return lv:toarray()
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr.count, 3)
        XCTAssertEqual(arr[0].numberValue, 1)
        XCTAssertEqual(arr[1].numberValue, 2)
        XCTAssertEqual(arr[2].numberValue, 3)
    }

    func testToVectorFromArray() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local a = luaswift.array.array({5, 6, 7, 8})
            local lv = types.to_vector(a)
            return lv:toarray()
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr.count, 4)
        XCTAssertEqual(arr[0].numberValue, 5)
        XCTAssertEqual(arr[1].numberValue, 6)
        XCTAssertEqual(arr[2].numberValue, 7)
        XCTAssertEqual(arr[3].numberValue, 8)
    }

    func testToVectorFromTable() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local lv = types.to_vector({10, 20, 30})
            return lv:toarray()
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(arr.count, 3)
        XCTAssertEqual(arr[0].numberValue, 10)
        XCTAssertEqual(arr[1].numberValue, 20)
        XCTAssertEqual(arr[2].numberValue, 30)
    }

    func testToVectorFromVectorReturnsItself() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v1 = luaswift.linalg.vector({1, 2, 3})
            local v2 = types.to_vector(v1)
            return v1 == v2
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - to_matrix() Tests

    func testToMatrixFromTable() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local m = types.to_matrix({{1, 2}, {3, 4}})
            return {types.typeof(m), m:get(1, 1), m:get(1, 2), m:get(2, 1), m:get(2, 2)}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 5,
              let typeStr = arr[0].stringValue,
              let m11 = arr[1].numberValue,
              let m12 = arr[2].numberValue,
              let m21 = arr[3].numberValue,
              let m22 = arr[4].numberValue else {
            XCTFail("Expected array with values")
            return
        }

        XCTAssertEqual(typeStr, "linalg.matrix")
        XCTAssertEqual(m11, 1, accuracy: 1e-10)
        XCTAssertEqual(m12, 2, accuracy: 1e-10)
        XCTAssertEqual(m21, 3, accuracy: 1e-10)
        XCTAssertEqual(m22, 4, accuracy: 1e-10)
    }

    func testToMatrixFromMatrixReturnsItself() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local m1 = luaswift.linalg.matrix({{1, 2}, {3, 4}})
            local m2 = types.to_matrix(m1)
            return m1 == m2
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - clone() Tests

    func testCloneComplex() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local c1 = luaswift.complex.new(3, 4)
            local c2 = types.clone(c1)
            c1.re = 100  -- Modify original
            return {c2.re, c2.im}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let re = arr[0].numberValue,
              let im = arr[1].numberValue else {
            XCTFail("Expected array with values")
            return
        }

        XCTAssertEqual(re, 3, accuracy: 1e-10)  // Clone unchanged
        XCTAssertEqual(im, 4, accuracy: 1e-10)
    }

    func testCloneVec2() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v1 = luaswift.geometry.vec2(5, 6)
            local v2 = types.clone(v1)
            v1.x = 100  -- Modify original
            return {v2.x, v2.y}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let x = arr[0].numberValue,
              let y = arr[1].numberValue else {
            XCTFail("Expected array with coordinates")
            return
        }

        XCTAssertEqual(x, 5, accuracy: 1e-10)  // Clone unchanged
        XCTAssertEqual(y, 6, accuracy: 1e-10)
    }

    func testCloneVec3() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v1 = luaswift.geometry.vec3(1, 2, 3)
            local v2 = types.clone(v1)
            return {types.typeof(v2), v2.x, v2.y, v2.z}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 4,
              let typeStr = arr[0].stringValue,
              let x = arr[1].numberValue,
              let y = arr[2].numberValue,
              let z = arr[3].numberValue else {
            XCTFail("Expected array with values")
            return
        }

        XCTAssertEqual(typeStr, "vec3")
        XCTAssertEqual(x, 1, accuracy: 1e-10)
        XCTAssertEqual(y, 2, accuracy: 1e-10)
        XCTAssertEqual(z, 3, accuracy: 1e-10)
    }

    func testCloneQuaternion() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local q1 = luaswift.geometry.quaternion.from_axis_angle(luaswift.geometry.vec3(0, 1, 0), math.pi / 4)
            local q2 = types.clone(q1)
            return {types.typeof(q2), q2.w, q2.x, q2.y, q2.z}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 5,
              let typeStr = arr[0].stringValue,
              let w = arr[1].numberValue,
              let x = arr[2].numberValue,
              let y = arr[3].numberValue,
              let z = arr[4].numberValue else {
            XCTFail("Expected array with values")
            return
        }

        XCTAssertEqual(typeStr, "quaternion")
        // Verify the values match expected quaternion for 45-degree rotation about Y
        let angle = Double.pi / 4
        XCTAssertEqual(w, cos(angle / 2), accuracy: 1e-10)
        XCTAssertEqual(x, 0, accuracy: 1e-10)
        XCTAssertEqual(y, sin(angle / 2), accuracy: 1e-10)
        XCTAssertEqual(z, 0, accuracy: 1e-10)
    }

    func testCloneTransform3d() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local t1 = luaswift.geometry.transform3d()
            t1 = t1:translate(1, 2, 3)
            local t2 = types.clone(t1)
            return types.typeof(t2)
        """)

        XCTAssertEqual(result.stringValue, "transform3d")
    }

    func testCloneArray() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local a1 = luaswift.array.array({1, 2, 3})
            local a2 = types.clone(a1)
            a1:set(1, 100)  -- Modify original
            return a2:tolist()
        """)

        guard let list = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list[0].numberValue, 1)  // Clone unchanged
        XCTAssertEqual(list[1].numberValue, 2)
        XCTAssertEqual(list[2].numberValue, 3)
    }

    func testCloneLinalgVector() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local v1 = luaswift.linalg.vector({4, 5, 6})
            local v2 = types.clone(v1)
            return {types.typeof(v2), v2:toarray()}
        """)

        guard let arr = result.arrayValue,
              arr.count >= 2,
              let typeStr = arr[0].stringValue,
              let data = arr[1].arrayValue else {
            XCTFail("Expected array with type and data")
            return
        }

        XCTAssertEqual(typeStr, "linalg.vector")
        XCTAssertEqual(data.count, 3)
        XCTAssertEqual(data[0].numberValue, 4)
        XCTAssertEqual(data[1].numberValue, 5)
        XCTAssertEqual(data[2].numberValue, 6)
    }

    func testClonePlainTable() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local t1 = {a = 1, b = 2}
            local t2 = types.clone(t1)
            t1.a = 100  -- Modify original
            return t2.a
        """)

        XCTAssertEqual(result.numberValue, 1)  // Clone unchanged
    }

    func testClonePrimitive() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            local n = 42
            local cloned = types.clone(n)
            return cloned
        """)

        XCTAssertEqual(result.numberValue, 42)
    }

    // MARK: - all_types() Tests

    func testAllTypes() throws {
        let result = try engine.evaluate("""
            local types = luaswift.types
            return types.all_types()
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }

        let typeStrings = arr.compactMap { $0.stringValue }
        XCTAssertTrue(typeStrings.contains("complex"))
        XCTAssertTrue(typeStrings.contains("vec2"))
        XCTAssertTrue(typeStrings.contains("vec3"))
        XCTAssertTrue(typeStrings.contains("quaternion"))
        XCTAssertTrue(typeStrings.contains("transform3d"))
        XCTAssertTrue(typeStrings.contains("linalg.vector"))
        XCTAssertTrue(typeStrings.contains("linalg.matrix"))
        XCTAssertTrue(typeStrings.contains("array"))
    }

    // MARK: - Error Cases

    func testToArrayFromNumberError() throws {
        do {
            _ = try engine.evaluate("""
                local types = luaswift.types
                return types.to_array(42)
            """)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(String(describing: error).contains("Cannot convert"))
        }
    }

    func testToVec2FromNumberError() throws {
        do {
            _ = try engine.evaluate("""
                local types = luaswift.types
                return types.to_vec2(42)
            """)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(String(describing: error).contains("Cannot convert"))
        }
    }

    func testToVec3FromStringError() throws {
        do {
            _ = try engine.evaluate("""
                local types = luaswift.types
                return types.to_vec3("hello")
            """)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(String(describing: error).contains("Cannot convert"))
        }
    }

    func testToComplexFromVec3Error() throws {
        do {
            _ = try engine.evaluate("""
                local types = luaswift.types
                return types.to_complex(luaswift.geometry.vec3(1, 2, 3))
            """)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(String(describing: error).contains("Cannot convert"))
        }
    }

    func testToVectorFromNumberError() throws {
        do {
            _ = try engine.evaluate("""
                local types = luaswift.types
                return types.to_vector(42)
            """)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(String(describing: error).contains("Cannot convert"))
        }
    }

    func testToMatrixFromNumberError() throws {
        do {
            _ = try engine.evaluate("""
                local types = luaswift.types
                return types.to_matrix(42)
            """)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(String(describing: error).contains("Cannot convert"))
        }
    }

    // MARK: - require() Tests

    func testRequireTypesModule() throws {
        let result = try engine.evaluate("""
            local types = require("luaswift.types")
            return types.typeof(42)
        """)

        XCTAssertEqual(result.stringValue, "number")
    }
}
