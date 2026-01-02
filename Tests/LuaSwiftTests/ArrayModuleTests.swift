//
//  ArrayModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class ArrayModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installArrayModule(in: engine)
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Array Creation

    func testArrayCreate1D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            return a:size()
            """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testArrayCreate2D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
            local shape = a:shape()
            return shape[1] * 10 + shape[2]
            """)

        XCTAssertEqual(result.numberValue, 23)
    }

    func testZeros() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({2, 3})
            return a:get(1, 2)
            """)

        XCTAssertEqual(result.numberValue, 0)
    }

    func testOnes() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.ones({3, 4})
            return a:get(2, 3)
            """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testFull() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.full({2, 2}, 7)
            return a:get(1, 1)
            """)

        XCTAssertEqual(result.numberValue, 7)
    }

    func testArange() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.arange(0, 10, 2)
            return a:size()
            """)

        XCTAssertEqual(result.numberValue, 5)  // 0, 2, 4, 6, 8
    }

    func testLinspace() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.linspace(0, 1, 5)
            return a:get(3)
            """)

        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
    }

    func testRand() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.random.rand({10})
            local v = a:get(1)
            return v >= 0 and v < 1
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testRandn() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.random.randn({100})
            return a:size()
            """)

        XCTAssertEqual(result.numberValue, 100)
    }

    // MARK: - Shape and Properties

    func testShape() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({2, 3, 4})
            local shape = a:shape()
            return shape[1] * 100 + shape[2] * 10 + shape[3]
            """)

        XCTAssertEqual(result.numberValue, 234)
    }

    func testNdim() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({2, 3, 4})
            return a:ndim()
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testSize() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({2, 3, 4})
            return a:size()
            """)

        XCTAssertEqual(result.numberValue, 24)
    }

    // MARK: - Indexing

    func testGetSet() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({2, 3})
            a:set(1, 2, 42)
            return a:get(1, 2)
            """)

        XCTAssertEqual(result.numberValue, 42)
    }

    // MARK: - Reshaping

    func testReshape() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.arange(1, 7, 1)
            local b = a:reshape({2, 3})
            return b:get(2, 1)
            """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testFlatten() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = a:flatten()
            return b:ndim()
            """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testSqueeze() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({1, 3, 1, 4})
            local b = a:squeeze()
            return b:ndim()
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    func testExpandDims() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({3, 4})
            local b = a:expand_dims(1)
            return b:ndim()
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testTranspose() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
            local b = a:T()
            local shape = b:shape()
            return shape[1] * 10 + shape[2]
            """)

        XCTAssertEqual(result.numberValue, 32)
    }

    // MARK: - Arithmetic Operations

    func testAdd() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({4, 5, 6})
            local c = a + b
            return c:get(2)
            """)

        XCTAssertEqual(result.numberValue, 7)
    }

    func testAddScalar() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = a + 10
            return b:get(1)
            """)

        XCTAssertEqual(result.numberValue, 11)
    }

    func testSub() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({5, 6, 7})
            local b = luaswift.array.array({1, 2, 3})
            local c = a - b
            return c:get(3)
            """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testMul() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({2, 3, 4})
            local b = luaswift.array.array({5, 6, 7})
            local c = a * b
            return c:get(2)
            """)

        XCTAssertEqual(result.numberValue, 18)
    }

    func testDiv() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({10, 20, 30})
            local b = a / 5
            return b:get(2)
            """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testPow() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({2, 3, 4})
            local b = a ^ 2
            return b:get(3)
            """)

        XCTAssertEqual(result.numberValue, 16)
    }

    func testNeg() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, -2, 3})
            local b = -a
            return b:get(2)
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    // MARK: - Broadcasting

    func testBroadcast() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1}, {2}, {3}})
            local b = luaswift.array.array({10, 20, 30})
            local c = a + b
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)

        XCTAssertEqual(result.numberValue, 33)
    }

    // MARK: - Math Functions

    func testAbs() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({-1, 2, -3})
            local b = luaswift.array.abs(a)
            return b:get(1) + b:get(3)
            """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testSqrt() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 4, 9, 16})
            local b = luaswift.array.sqrt(a)
            return b:get(4)
            """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testExp() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.exp(a)
            return b:get(1)
            """)

        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testLog() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2.718281828})
            local b = luaswift.array.log(a)
            return b:get(1)
            """)

        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testSin() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.sin(a)
            return b:get(1)
            """)

        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testCos() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.cos(a)
            return b:get(1)
            """)

        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    // MARK: - Reductions

    func testSum() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            return luaswift.array.sum(a)
            """)

        XCTAssertEqual(result.numberValue, 15)
    }

    func testSumAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
            local b = a:sum(1)
            return b:get(2)
            """)

        XCTAssertEqual(result.numberValue, 7)  // 2 + 5
    }

    func testMean() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            return luaswift.array.mean(a)
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testStd() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({2, 4, 4, 4, 5, 5, 7, 9})
            local s = luaswift.array.std(a)
            return s
            """)

        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 0.01)
    }

    func testVar() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({2, 4, 4, 4, 5, 5, 7, 9})
            local v = luaswift.array.var(a)
            return v
            """)

        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 0.01)
    }

    func testMin() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({3, 1, 4, 1, 5, 9})
            return luaswift.array.min(a)
            """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testMax() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({3, 1, 4, 1, 5, 9})
            return luaswift.array.max(a)
            """)

        XCTAssertEqual(result.numberValue, 9)
    }

    func testArgmin() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({3, 1, 4, 1, 5, 9})
            return luaswift.array.argmin(a)
            """)

        XCTAssertEqual(result.numberValue, 2)  // 1-indexed
    }

    func testArgmax() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({3, 1, 4, 1, 5, 9})
            return luaswift.array.argmax(a)
            """)

        XCTAssertEqual(result.numberValue, 6)  // 1-indexed
    }

    func testProd() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4})
            return luaswift.array.prod(a)
            """)

        XCTAssertEqual(result.numberValue, 24)
    }

    // MARK: - Comparison

    func testEqual() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({1, 0, 3})
            local c = luaswift.array.equal(a, b)
            return c:get(1) + c:get(2) + c:get(3)
            """)

        XCTAssertEqual(result.numberValue, 2)  // 1 + 0 + 1
    }

    func testGreater() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({0, 2, 4})
            local c = luaswift.array.greater(a, b)
            return c:get(1) + c:get(2) + c:get(3)
            """)

        XCTAssertEqual(result.numberValue, 1)  // 1 + 0 + 0
    }

    func testLess() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({0, 2, 4})
            local c = luaswift.array.less(a, b)
            return c:get(1) + c:get(2) + c:get(3)
            """)

        XCTAssertEqual(result.numberValue, 1)  // 0 + 0 + 1
    }

    func testWhere() throws {
        let result = try engine.evaluate("""
            local cond = luaswift.array.array({1, 0, 1})
            local x = luaswift.array.array({10, 20, 30})
            local y = luaswift.array.array({-10, -20, -30})
            local z = luaswift.array.where(cond, x, y)
            return z:get(1) + z:get(2) + z:get(3)
            """)

        XCTAssertEqual(result.numberValue, 20)  // 10 + (-20) + 30
    }

    // MARK: - Dot Product

    func testDotVectors() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({4, 5, 6})
            return luaswift.array.dot(a, b)
            """)

        XCTAssertEqual(result.numberValue, 32)  // 1*4 + 2*5 + 3*6
    }

    func testDotMatrix() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.array({{5, 6}, {7, 8}})
            local c = luaswift.array.dot(a, b)
            return c:get(1, 1)
            """)

        XCTAssertEqual(result.numberValue, 19)  // 1*5 + 2*7
    }

    // MARK: - Utility

    func testTolist() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local list = a:tolist()
            return list[2]
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    func testCopy() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = a:copy()
            b:set(1, 100)
            return a:get(1)
            """)

        XCTAssertEqual(result.numberValue, 1)  // Original unchanged
    }

    func testToString() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({2, 3})
            return tostring(a)
            """)

        XCTAssertEqual(result.stringValue, "array(2, 3)")
    }

    // MARK: - Type Marker

    func testTypeMarkerArray() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            return a.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "array")
    }

    func testTypeMarkerZeros() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({2, 3})
            return a.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "array")
    }

    // MARK: - DataServer Integration Tests

    func testDataServerArrayIntegration() throws {
        // Create a data server that returns array data
        let dataServer = ArrayDataServer()
        try engine.register(server: dataServer)

        // Test 1: Pass 1D array data directly to array module
        let result1D = try engine.evaluate("""
            local data = Data.numbers1D
            local a = luaswift.array.array(data)
            return a:sum()
            """)

        XCTAssertEqual(result1D.numberValue, 15)  // 1+2+3+4+5 = 15
    }

    func testDataServerNestedArrayIntegration() throws {
        let dataServer = ArrayDataServer()
        try engine.register(server: dataServer)

        // Test 2: Pass 2D array data directly to array module
        let result2D = try engine.evaluate("""
            local data = Data.numbers2D
            local a = luaswift.array.array(data)
            local shape = a:shape()
            return shape[1] * 10 + shape[2]
            """)

        XCTAssertEqual(result2D.numberValue, 23)  // 2 rows, 3 cols
    }

    func testDataServerArrayOperations() throws {
        let dataServer = ArrayDataServer()
        try engine.register(server: dataServer)

        // Test 3: Perform operations on DataServer-sourced array
        let result = try engine.evaluate("""
            local data = Data.numbers1D
            local a = luaswift.array.array(data)
            local b = a * 2
            return b:mean()
            """)

        XCTAssertEqual(result.numberValue!, 6.0, accuracy: 1e-10)  // mean of {2,4,6,8,10} = 6
    }

    func testDataServerFloatArrayIntegration() throws {
        let dataServer = ArrayDataServer()
        try engine.register(server: dataServer)

        // Test 4: Float data from DataServer
        let result = try engine.evaluate("""
            local data = Data.floats
            local a = luaswift.array.array(data)
            return a:sum()
            """)

        XCTAssertEqual(result.numberValue!, 3.6, accuracy: 1e-10)  // 0.1+0.5+1.0+2.0 = 3.6
    }
}

// MARK: - Test DataServer for Array Integration

/// A DataServer that provides array-compatible data for testing
final class ArrayDataServer: LuaValueServer {
    let namespace = "Data"

    func resolve(path: [String]) -> LuaValue {
        guard let first = path.first else { return .nil }

        switch first {
        case "numbers1D":
            // Return a 1D array of numbers
            return .array([.number(1), .number(2), .number(3), .number(4), .number(5)])

        case "numbers2D":
            // Return a 2D array (nested arrays)
            return .array([
                .array([.number(1), .number(2), .number(3)]),
                .array([.number(4), .number(5), .number(6)])
            ])

        case "floats":
            // Return floating-point data
            return .array([.number(0.1), .number(0.5), .number(1.0), .number(2.0)])

        case "empty":
            return .array([])

        case "mixed":
            // Return a table-style array
            return .table([
                "1": .number(10),
                "2": .number(20),
                "3": .number(30)
            ])

        default:
            return .nil
        }
    }
}
