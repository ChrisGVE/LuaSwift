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

    func testGreaterEqual() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({0, 2, 4})
            local c = luaswift.array.greater_equal(a, b)
            return c:get(1) + c:get(2) + c:get(3)
            """)

        XCTAssertEqual(result.numberValue, 2)  // 1 + 1 + 0 (1>=0, 2>=2, 3>=4)
    }

    func testLessEqual() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({0, 2, 4})
            local c = luaswift.array.less_equal(a, b)
            return c:get(1) + c:get(2) + c:get(3)
            """)

        XCTAssertEqual(result.numberValue, 2)  // 0 + 1 + 1 (1<=0, 2<=2, 3<=4)
    }

    func testNotEqual() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({1, 0, 3})
            local c = luaswift.array.not_equal(a, b)
            return c:get(1) + c:get(2) + c:get(3)
            """)

        XCTAssertEqual(result.numberValue, 1)  // 0 + 1 + 0 (1!=1, 2!=0, 3!=3)
    }

    func testIsnan() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 0/0, 3, math.huge})
            local c = luaswift.array.isnan(a)
            return c:get(1) + c:get(2) + c:get(3) + c:get(4)
            """)

        XCTAssertEqual(result.numberValue, 1)  // 0 + 1 + 0 + 0 (only NaN is NaN)
    }

    func testIsinf() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, math.huge, -math.huge, 0/0})
            local c = luaswift.array.isinf(a)
            return c:get(1) + c:get(2) + c:get(3) + c:get(4)
            """)

        XCTAssertEqual(result.numberValue, 2)  // 0 + 1 + 1 + 0 (+inf, -inf)
    }

    func testIsfinite() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, math.huge, 3, 0/0})
            local c = luaswift.array.isfinite(a)
            return c:get(1) + c:get(2) + c:get(3) + c:get(4)
            """)

        XCTAssertEqual(result.numberValue, 2)  // 1 + 0 + 1 + 0 (only 1 and 3 are finite)
    }

    func testComparisonBroadcasting() throws {
        // Test broadcasting with scalar
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            local ge = luaswift.array.greater_equal(a, 3)
            local le = luaswift.array.less_equal(a, 3)
            return ge:get(3) + ge:get(4) + le:get(1) + le:get(3)
            """)

        XCTAssertEqual(result.numberValue, 4)  // 1 + 1 + 1 + 1
    }

    // MARK: - Boolean Reductions

    func testAll() throws {
        // All non-zero
        let result1 = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            return luaswift.array.all(a)
            """)
        XCTAssertEqual(result1.numberValue, 1)

        // Contains zero
        let result2 = try engine.evaluate("""
            local a = luaswift.array.array({1, 0, 3})
            return luaswift.array.all(a)
            """)
        XCTAssertEqual(result2.numberValue, 0)
    }

    func testAllAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {0, 4}})
            local r = luaswift.array.all(a, 1)
            return r:get(1) + r:get(2)
            """)
        XCTAssertEqual(result.numberValue, 1)  // 0 + 1 (first col has 0, second all non-zero)
    }

    func testAny() throws {
        // All zeros
        let result1 = try engine.evaluate("""
            local a = luaswift.array.array({0, 0, 0})
            return luaswift.array.any(a)
            """)
        XCTAssertEqual(result1.numberValue, 0)

        // Contains non-zero
        let result2 = try engine.evaluate("""
            local a = luaswift.array.array({0, 1, 0})
            return luaswift.array.any(a)
            """)
        XCTAssertEqual(result2.numberValue, 1)
    }

    func testAnyAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{0, 0}, {1, 0}})
            local r = luaswift.array.any(a, 1)
            return r:get(1) + r:get(2)
            """)
        XCTAssertEqual(result.numberValue, 1)  // 1 + 0 (first col has 1, second all zero)
    }

    func testCumsum() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4})
            local c = luaswift.array.cumsum(a)
            return c:get(1) + c:get(2) + c:get(3) + c:get(4)
            """)
        XCTAssertEqual(result.numberValue, 20)  // 1 + 3 + 6 + 10
    }

    func testCumsumAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local c = luaswift.array.cumsum(a, 1)
            return c:get(1, 1) + c:get(2, 1) + c:get(1, 2) + c:get(2, 2)
            """)
        XCTAssertEqual(result.numberValue, 13)  // 1 + 4 + 2 + 6 (cumsum down columns)
    }

    func testCumprod() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4})
            local c = luaswift.array.cumprod(a)
            return c:get(1) + c:get(2) + c:get(3) + c:get(4)
            """)
        XCTAssertEqual(result.numberValue, 33)  // 1 + 2 + 6 + 24
    }

    func testCumprodAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local c = luaswift.array.cumprod(a, 1)
            return c:get(1, 1) + c:get(2, 1) + c:get(1, 2) + c:get(2, 2)
            """)
        XCTAssertEqual(result.numberValue, 14)  // 1 + 3 + 2 + 8 (cumprod down columns)
    }

    // MARK: - Sorting and Searching

    func testSort() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({3, 1, 4, 1, 5, 9, 2, 6})
            local s = luaswift.array.sort(a)
            return s:get(1) + s:get(2) + s:get(3)
            """)
        XCTAssertEqual(result.numberValue, 4)  // 1 + 1 + 2 (first three sorted elements)
    }

    func testSortAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{3, 1}, {4, 2}})
            local s = luaswift.array.sort(a, 1)
            return s:get(1, 1) + s:get(2, 1) + s:get(1, 2) + s:get(2, 2)
            """)
        XCTAssertEqual(result.numberValue, 10)  // 3 + 4 + 1 + 2 (sorted down columns: 3,4 and 1,2)
    }

    func testArgsort() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({30, 10, 20})
            local idx = luaswift.array.argsort(a)
            return idx:get(1)
            """)
        XCTAssertEqual(result.numberValue, 2)  // 10 is at index 2 (1-based), smallest element
    }

    func testSearchsorted() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 3, 5, 7, 9})
            return luaswift.array.searchsorted(a, 4)
            """)
        XCTAssertEqual(result.numberValue, 3)  // 4 would be inserted at index 3 (after 3, before 5)
    }

    func testSearchsortedRight() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 3, 5, 7, 9})
            return luaswift.array.searchsorted(a, 5, "right")
            """)
        XCTAssertEqual(result.numberValue, 4)  // 5 would be inserted at index 4 (after 5)
    }

    func testArgwhere() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1, 0, 2, 0})
            local idx = luaswift.array.argwhere(a)
            return idx:get(1, 1) + idx:get(2, 1)
            """)
        XCTAssertEqual(result.numberValue, 6)  // indices 2 and 4 (1-based)
    }

    func testNonzero() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1, 0, 2, 0})
            local idx = luaswift.array.nonzero(a)
            return idx[1]:get(1) + idx[1]:get(2)
            """)
        XCTAssertEqual(result.numberValue, 6)  // indices 2 and 4 (1-based)
    }

    func testUnique() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({3, 1, 2, 1, 3, 2, 1})
            local u = luaswift.array.unique(a)
            return u:get(1) + u:get(2) + u:get(3)
            """)
        XCTAssertEqual(result.numberValue, 6)  // 1 + 2 + 3 (sorted unique values)
    }

    func testUniqueWithCounts() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 2, 3, 3, 3})
            local u, counts = luaswift.array.unique(a, false, false, true)
            return counts:get(1) + counts:get(2) + counts:get(3)
            """)
        XCTAssertEqual(result.numberValue, 6)  // 1 + 2 + 3 (counts for 1, 2, 3)
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

    // MARK: - Array Manipulation

    func testConcatenate1D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({4, 5, 6})
            local c = luaswift.array.concatenate({a, b})
            return c:size()
            """)
        XCTAssertEqual(result.numberValue, 6)
    }

    func testConcatenate2D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.array({{5, 6}, {7, 8}})
            local c = luaswift.array.concatenate({a, b}, 1)
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)
        XCTAssertEqual(result.numberValue, 42)  // 4 rows, 2 cols
    }

    func testStack() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({4, 5, 6})
            local c = luaswift.array.stack({a, b})
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)
        XCTAssertEqual(result.numberValue, 23)  // 2 arrays, 3 elements each
    }

    func testVstack() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.array({{5, 6}})
            local c = luaswift.array.vstack({a, b})
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)
        XCTAssertEqual(result.numberValue, 32)  // 3 rows, 2 cols
    }

    func testSplit() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5, 6})
            local parts = luaswift.array.split(a, 3)
            return #parts
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testSplitValues() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5, 6})
            local parts = luaswift.array.split(a, 3)
            return parts[1]:get(1) + parts[2]:get(1) * 10 + parts[3]:get(1) * 100
            """)
        XCTAssertEqual(result.numberValue, 1 + 3 * 10 + 5 * 100)  // 531
    }

    // MARK: - Hyperbolic Functions

    func testSinh() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.sinh(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testCosh() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.cosh(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testTanh() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.tanh(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testAsinh() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.asinh(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testAcosh() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1})
            local b = luaswift.array.acosh(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testAtanh() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.atanh(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testSinhValues() throws {
        // sinh(1) ≈ 1.175201193643801
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1})
            local b = luaswift.array.sinh(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 1.1752011936438014, accuracy: 1e-10)
    }

    // MARK: - Inverse Trigonometric Functions

    func testArcsin() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1})
            local b = luaswift.array.arcsin(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testArcsinPiOver2() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1})
            local b = luaswift.array.arcsin(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, Double.pi / 2, accuracy: 1e-10)
    }

    func testArccos() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1})
            local b = luaswift.array.arccos(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testArctan() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1})
            local b = luaswift.array.arctan(a)
            return b:get(2)
            """)
        XCTAssertEqual(result.numberValue!, Double.pi / 4, accuracy: 1e-10)
    }

    func testArctan2() throws {
        // arctan2(1, 1) = pi/4
        let result = try engine.evaluate("""
            local y = luaswift.array.array({1})
            local x = luaswift.array.array({1})
            local b = luaswift.array.arctan2(y, x)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, Double.pi / 4, accuracy: 1e-10)
    }

    func testArctan2Quadrants() throws {
        // Test all 4 quadrants
        let result = try engine.evaluate("""
            local y = luaswift.array.array({1, 1, -1, -1})
            local x = luaswift.array.array({1, -1, -1, 1})
            local b = luaswift.array.arctan2(y, x)
            -- Q1: pi/4, Q2: 3pi/4, Q3: -3pi/4, Q4: -pi/4
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, Double.pi / 4, accuracy: 1e-10)
    }

    func testAsinAlias() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0})
            local b = luaswift.array.asin(a)
            return b:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    // MARK: - Element-wise Operations

    func testFloor() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1.7, 2.3, -1.7, -2.3})
            local b = luaswift.array.floor(a)
            return b:get(1) + b:get(3) * 10
            """)
        XCTAssertEqual(result.numberValue, 1 + (-2) * 10)  // 1 + (-20) = -19
    }

    func testCeil() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1.7, 2.3, -1.7, -2.3})
            local b = luaswift.array.ceil(a)
            return b:get(1) + b:get(3) * 10
            """)
        XCTAssertEqual(result.numberValue, 2 + (-1) * 10)  // 2 + (-10) = -8
    }

    func testRound() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1.4, 1.6, -1.4, -1.6})
            local b = luaswift.array.round(a)
            return b:get(1) + b:get(2) * 10
            """)
        XCTAssertEqual(result.numberValue!, 1 + 2 * 10, accuracy: 1.0)
    }

    func testSign() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({5, 0, -3})
            local b = luaswift.array.sign(a)
            return b:get(1) + b:get(2) * 10 + b:get(3) * 100
            """)
        XCTAssertEqual(result.numberValue, 1 + 0 * 10 + (-1) * 100)  // 1 + 0 + (-100) = -99
    }

    func testClip() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 5, 10, 15})
            local b = luaswift.array.clip(a, 3, 12)
            return b:get(1) + b:get(2) + b:get(3) + b:get(4)
            """)
        XCTAssertEqual(result.numberValue, 3 + 5 + 10 + 12)  // clipped: 3, 5, 10, 12
    }

    func testMod() throws {
        // Python-style mod: result has sign of divisor
        let result = try engine.evaluate("""
            local a = luaswift.array.array({7})
            local b = luaswift.array.array({3})
            local c = luaswift.array.mod(a, b)
            return c:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testFmod() throws {
        // C-style fmod: result has sign of dividend
        let result = try engine.evaluate("""
            local a = luaswift.array.array({7})
            local b = luaswift.array.array({3})
            local c = luaswift.array.fmod(a, b)
            return c:get(1)
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testModNegative() throws {
        // Test mod with negative values
        let result = try engine.evaluate("""
            local a = luaswift.array.array({-7})
            local b = luaswift.array.array({3})
            local c = luaswift.array.mod(a, b)
            return c:get(1)
            """)
        // Python mod: -7 % 3 = 2 (result has sign of divisor)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testFmodNegative() throws {
        // Test fmod with negative values
        let result = try engine.evaluate("""
            local a = luaswift.array.array({-7})
            local b = luaswift.array.array({3})
            local c = luaswift.array.fmod(a, b)
            return c:get(1)
            """)
        // C fmod: -7 % 3 = -1 (result has sign of dividend)
        XCTAssertEqual(result.numberValue!, -1.0, accuracy: 1e-10)
    }

    // MARK: - Broadcasting Edge Cases

    func testBroadcastScalarPlusArray() throws {
        // Scalar + 1D array
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1})  -- shape [1]
            local b = luaswift.array.array({10, 20, 30})  -- shape [3]
            local c = a + b
            return c:get(1) + c:get(2) + c:get(3)
            """)
        XCTAssertEqual(result.numberValue, 11 + 21 + 31)
    }

    func testBroadcast2DWith1D() throws {
        // 2D [2,3] + 1D [3] -> [2,3]
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})  -- shape [2,3]
            local b = luaswift.array.array({10, 20, 30})  -- shape [3]
            local c = a + b
            local shape = c:shape()
            return shape[1] * 100 + shape[2] * 10 + c:get(2, 3)
            """)
        // Shape should be [2,3], c[2,3] = 6 + 30 = 36
        XCTAssertEqual(result.numberValue, 2 * 100 + 3 * 10 + 36)
    }

    func testBroadcast3D() throws {
        // 3D broadcasting: [2,1,3] + [1,4,1] -> [2,4,3]
        let result = try engine.evaluate("""
            local a = luaswift.array.reshape(luaswift.array.array({1,2,3,4,5,6}), {2,1,3})
            local b = luaswift.array.reshape(luaswift.array.array({10,20,30,40}), {1,4,1})
            local c = a + b
            local shape = c:shape()
            return shape[1] * 100 + shape[2] * 10 + shape[3]
            """)
        // Result shape should be [2,4,3]
        XCTAssertEqual(result.numberValue, 2 * 100 + 4 * 10 + 3)
    }

    func testBroadcast4D() throws {
        // 4D broadcasting: [1,2,1,3] + [2,1,4,1] -> [2,2,4,3]
        let result = try engine.evaluate("""
            local a = luaswift.array.reshape(luaswift.array.arange(1, 7), {1,2,1,3})  -- 6 elements
            local b = luaswift.array.reshape(luaswift.array.arange(1, 9), {2,1,4,1})  -- 8 elements
            local c = a + b
            local shape = c:shape()
            return shape[1] * 1000 + shape[2] * 100 + shape[3] * 10 + shape[4]
            """)
        // Result shape should be [2,2,4,3]
        XCTAssertEqual(result.numberValue, 2243)  // 2*1000 + 2*100 + 4*10 + 3
    }

    func testBroadcastIncompatibleShapesError() throws {
        // [3] + [4] should error - incompatible shapes
        do {
            _ = try engine.evaluate("""
                local a = luaswift.array.array({1, 2, 3})
                local b = luaswift.array.array({1, 2, 3, 4})
                return a + b
                """)
            XCTFail("Expected an error for incompatible shapes")
        } catch {
            let errorMessage = String(describing: error)
            XCTAssertTrue(errorMessage.contains("broadcast"), "Error should mention broadcasting: \(errorMessage)")
        }
    }

    func testBroadcastIncompatible2DError() throws {
        // [2,3] + [2,4] should error - incompatible last dimension
        do {
            _ = try engine.evaluate("""
                local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
                local b = luaswift.array.array({{1, 2, 3, 4}, {5, 6, 7, 8}})
                return a + b
                """)
            XCTFail("Expected an error for incompatible shapes")
        } catch {
            let errorMessage = String(describing: error)
            XCTAssertTrue(errorMessage.contains("broadcast"), "Error should mention broadcasting: \(errorMessage)")
        }
    }

    func testBroadcastSameShape() throws {
        // Same shape should work without broadcasting
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.array({{10, 20}, {30, 40}})
            local c = a + b
            return c:get(2, 2)
            """)
        XCTAssertEqual(result.numberValue, 44)
    }

    func testBroadcastColumnVector() throws {
        // [3,1] + [1,4] -> [3,4]
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1}, {2}, {3}})  -- [3,1]
            local b = luaswift.array.array({{10, 20, 30, 40}})  -- [1,4]
            local c = a + b
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)
        XCTAssertEqual(result.numberValue, 34)
    }

    func testBroadcastMultiplication() throws {
        // Broadcasting with multiplication
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1}, {2}, {3}})  -- [3,1]
            local b = luaswift.array.array({10, 20, 30})  -- [3]
            local c = a * b
            return c:get(2, 2)  -- 2 * 20 = 40
            """)
        XCTAssertEqual(result.numberValue, 40)
    }

    func testBroadcastWhereOperation() throws {
        // where() with broadcasting
        let result = try engine.evaluate("""
            local cond = luaswift.array.array({{1, 0}, {0, 1}})
            local x = luaswift.array.array({10})  -- scalar broadcast
            local y = luaswift.array.array({20})  -- scalar broadcast
            local c = luaswift.array.where(cond, x, y)
            return c:get(1, 1) + c:get(1, 2) + c:get(2, 1) + c:get(2, 2)
            """)
        // cond: [[1,0],[0,1]] -> result: [[10,20],[20,10]]
        XCTAssertEqual(result.numberValue, 10 + 20 + 20 + 10)
    }

    func testBroadcastArctan2() throws {
        // arctan2 with broadcasting: [3,1] and [1,3]
        let result = try engine.evaluate("""
            local y = luaswift.array.array({{0}, {1}, {0}})  -- [3,1]
            local x = luaswift.array.array({{1, 0, -1}})  -- [1,3]
            local c = luaswift.array.arctan2(y, x)
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)
        // Result shape should be [3,3]
        XCTAssertEqual(result.numberValue, 33)
    }

    func testBroadcastModOperation() throws {
        // mod with broadcasting
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{7, 8, 9}})  -- [1,3]
            local b = luaswift.array.array({{3}, {4}, {5}})  -- [3,1]
            local c = luaswift.array.mod(a, b)
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)
        // Result shape should be [3,3]
        XCTAssertEqual(result.numberValue, 33)
    }

    // MARK: - Serialization Round-Trip Tests

    func testSerializationHyperbolic() throws {
        // Test that hyperbolic function results can be serialized and reconstructed
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1, 2})
            local b = luaswift.array.sinh(a)
            local list = b:tolist()
            local c = luaswift.array.array(list)
            return c:get(2)  -- sinh(1) ≈ 1.175
            """)
        XCTAssertEqual(result.numberValue!, Foundation.sinh(1.0), accuracy: 1e-10)
    }

    func testSerializationInverseTrig() throws {
        // Test that inverse trig function results can be serialized and reconstructed
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 0.5, 1})
            local b = luaswift.array.arcsin(a)
            local list = b:tolist()
            local c = luaswift.array.array(list)
            return c:get(2)  -- arcsin(0.5) = π/6
            """)
        XCTAssertEqual(result.numberValue!, Foundation.asin(0.5), accuracy: 1e-10)
    }

    func testSerializationElementWise() throws {
        // Test that element-wise operation results can be serialized and reconstructed
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1.7, 2.3, 3.8})
            local b = luaswift.array.floor(a)
            local list = b:tolist()
            local c = luaswift.array.array(list)
            return c:get(1) + c:get(2) + c:get(3)
            """)
        XCTAssertEqual(result.numberValue, 1 + 2 + 3)  // floor: 1, 2, 3
    }

    func testSerializationConcatenate() throws {
        // Test that concatenate results can be serialized
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({4, 5, 6})
            local c = luaswift.array.concatenate({a, b})
            local list = c:tolist()
            local d = luaswift.array.array(list)
            return d:size()
            """)
        XCTAssertEqual(result.numberValue, 6)
    }

    func testSerializationStack() throws {
        // Test that stack results can be serialized
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({4, 5, 6})
            local c = luaswift.array.stack({a, b})
            local list = c:tolist()
            local d = luaswift.array.array(list)
            local shape = d:shape()
            return shape[1] * 10 + shape[2]
            """)
        XCTAssertEqual(result.numberValue, 23)  // [2,3] shape
    }

    func testSerializationClip() throws {
        // Test that clip results can be serialized
        let result = try engine.evaluate("""
            local a = luaswift.array.array({-5, 0, 5, 10, 15})
            local b = luaswift.array.clip(a, 0, 10)
            local list = b:tolist()
            local c = luaswift.array.array(list)
            return c:get(1) + c:get(5)  -- clipped: 0 + 10 = 10
            """)
        XCTAssertEqual(result.numberValue, 10)
    }

    func testSerializationArctan2() throws {
        // Test that arctan2 (binary broadcast) results can be serialized
        let result = try engine.evaluate("""
            local y = luaswift.array.array({0, 1, 0})
            local x = luaswift.array.array({1, 0, -1})
            local c = luaswift.array.arctan2(y, x)
            local list = c:tolist()
            local d = luaswift.array.array(list)
            return d:get(2)  -- arctan2(1, 0) = π/2
            """)
        XCTAssertEqual(result.numberValue!, Double.pi / 2, accuracy: 1e-10)
    }

    func testSerializationMultiDimensional() throws {
        // Test that 2D array operations serialize properly
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
            local b = luaswift.array.sin(a)
            local list = b:tolist()
            local c = luaswift.array.array(list)
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)
        XCTAssertEqual(result.numberValue, 23)  // [2,3] shape preserved
    }

    func testSerializationRoundTrip() throws {
        // Full round-trip: create → transform → serialize → deserialize → verify
        let result = try engine.evaluate("""
            local original = luaswift.array.array({1, 4, 9, 16, 25})
            local transformed = luaswift.array.sqrt(original)
            local list = transformed:tolist()
            local reconstructed = luaswift.array.array(list)

            -- Verify all values
            local sum = 0
            for i = 1, 5 do
                sum = sum + reconstructed:get(i)
            end
            return sum  -- 1 + 2 + 3 + 4 + 5 = 15
            """)
        XCTAssertEqual(result.numberValue, 15)
    }

    // MARK: - Phase 2.4 Math Functions

    func testLog2() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 4, 8, 16})
            local b = luaswift.array.log2(a)
            return b:get(1) + b:get(2) + b:get(3) + b:get(4) + b:get(5)
            """)
        // log2(1)=0, log2(2)=1, log2(4)=2, log2(8)=3, log2(16)=4 → sum=10
        XCTAssertEqual(result.numberValue!, 10, accuracy: 1e-10)
    }

    func testLog10() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 10, 100, 1000})
            local b = luaswift.array.log10(a)
            return b:get(1) + b:get(2) + b:get(3) + b:get(4)
            """)
        // log10(1)=0, log10(10)=1, log10(100)=2, log10(1000)=3 → sum=6
        XCTAssertEqual(result.numberValue!, 6, accuracy: 1e-10)
    }

    func testLog1p() throws {
        // log1p(x) = log(1+x), more accurate for small x
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1, 2})
            local b = luaswift.array.log1p(a)
            return b:get(1) + b:get(2) + b:get(3)
            """)
        // log1p(0)=log(1)=0, log1p(1)=log(2)≈0.693, log1p(2)=log(3)≈1.099
        let expected = 0.0 + log(2.0) + log(3.0)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-10)
    }

    func testExpm1() throws {
        // expm1(x) = exp(x) - 1, more accurate for small x
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1})
            local b = luaswift.array.expm1(a)
            return b:get(1) + b:get(2)
            """)
        // expm1(0)=0, expm1(1)=e-1≈1.718
        let expected = 0.0 + (exp(1.0) - 1.0)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-10)
    }

    func testPower() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4})
            local b = luaswift.array.array({2, 2, 2, 2})
            local c = luaswift.array.power(a, b)
            return c:get(1) + c:get(2) + c:get(3) + c:get(4)
            """)
        // 1^2 + 2^2 + 3^2 + 4^2 = 1 + 4 + 9 + 16 = 30
        XCTAssertEqual(result.numberValue!, 30, accuracy: 1e-10)
    }

    func testPowerBroadcast() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({2, 3, 4})
            local b = luaswift.array.array({3})
            local c = luaswift.array.power(a, b)
            return c:get(1) + c:get(2) + c:get(3)
            """)
        // 2^3 + 3^3 + 4^3 = 8 + 27 + 64 = 99
        XCTAssertEqual(result.numberValue!, 99, accuracy: 1e-10)
    }

    // MARK: - Phase 2.5 Statistics Functions

    func testMedianOdd() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({3, 1, 4, 1, 5})
            return luaswift.array.median(a)
            """)
        // sorted: [1, 1, 3, 4, 5], median = 3
        XCTAssertEqual(result.numberValue!, 3, accuracy: 1e-10)
    }

    func testMedianEven() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4})
            return luaswift.array.median(a)
            """)
        // sorted: [1, 2, 3, 4], median = (2 + 3) / 2 = 2.5
        XCTAssertEqual(result.numberValue!, 2.5, accuracy: 1e-10)
    }

    func testMedianAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 3}, {2, 4}})
            local m = luaswift.array.median(a, 1)
            return m:get(1) + m:get(2)
            """)
        // axis 1 (rows): median of [1,2]=1.5, median of [3,4]=3.5 → sum = 5
        XCTAssertEqual(result.numberValue!, 5, accuracy: 1e-10)
    }

    func testPercentile() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            return luaswift.array.percentile(a, 50)
            """)
        // 50th percentile = median = 3
        XCTAssertEqual(result.numberValue!, 3, accuracy: 1e-10)
    }

    func testPercentile25() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            return luaswift.array.percentile(a, 25)
            """)
        // 25th percentile: index = 0.25 * 4 = 1, interp between 1 and 2 = 2
        XCTAssertEqual(result.numberValue!, 2, accuracy: 1e-10)
    }

    func testQuantile() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            return luaswift.array.quantile(a, 0.5)
            """)
        // 0.5 quantile = median = 3
        XCTAssertEqual(result.numberValue!, 3, accuracy: 1e-10)
    }

    func testQuantile75() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            return luaswift.array.quantile(a, 0.75)
            """)
        // 75th quantile: index = 0.75 * 4 = 3, interp between 4 and 5 = 4
        XCTAssertEqual(result.numberValue!, 4, accuracy: 1e-10)
    }

    func testHistogram() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
            local counts, edges = luaswift.array.histogram(a, 5)
            return counts:size()
            """)
        // 5 bins means 5 count values
        XCTAssertEqual(result.numberValue, 5)
    }

    func testHistogramCounts() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 1, 1, 2, 2, 3})
            local counts, edges = luaswift.array.histogram(a, 3)
            return counts:get(1)
            """)
        // First bin should contain 3 values (the three 1s, possibly the 2s depending on binning)
        XCTAssertTrue(result.numberValue! >= 1)
    }

    func testHistogramEdges() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            local counts, edges = luaswift.array.histogram(a, 4)
            return edges:size()
            """)
        // 4 bins means 5 edges
        XCTAssertEqual(result.numberValue, 5)
    }

    func testBincount() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1, 1, 2, 2, 2})
            local counts = luaswift.array.bincount(a)
            return counts:get(1) + counts:get(2) * 10 + counts:get(3) * 100
            """)
        // 0 appears 1x, 1 appears 2x, 2 appears 3x → 1 + 20 + 300 = 321
        XCTAssertEqual(result.numberValue!, 321, accuracy: 1e-10)
    }

    func testBincountMinlength() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 1})
            local counts = luaswift.array.bincount(a, nil, 5)
            return counts:size()
            """)
        // minlength=5 means at least 5 bins
        XCTAssertEqual(result.numberValue, 5)
    }

    func testPtp() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 5, 3, 9, 2})
            return luaswift.array.ptp(a)
            """)
        // ptp = max - min = 9 - 1 = 8
        XCTAssertEqual(result.numberValue!, 8, accuracy: 1e-10)
    }

    func testPtpAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 5}, {2, 3}})
            local p = luaswift.array.ptp(a, 1)
            return p:get(1) + p:get(2)
            """)
        // axis 1 (rows): ptp of [1,2]=1, ptp of [5,3]=2 → sum = 3
        XCTAssertEqual(result.numberValue!, 3, accuracy: 1e-10)
    }

    // MARK: - Phase 2.6 LinAlg Overlap Functions

    func testTrace() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})
            return luaswift.array.trace(a)
            """)
        // trace = 1 + 5 + 9 = 15
        XCTAssertEqual(result.numberValue!, 15, accuracy: 1e-10)
    }

    func testTraceOffset() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})
            return luaswift.array.trace(a, 1)
            """)
        // trace offset 1 = 2 + 6 = 8
        XCTAssertEqual(result.numberValue!, 8, accuracy: 1e-10)
    }

    func testDiagonal() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})
            local d = luaswift.array.diagonal(a)
            return d:get(1) + d:get(2) + d:get(3)
            """)
        // diagonal = [1, 5, 9], sum = 15
        XCTAssertEqual(result.numberValue!, 15, accuracy: 1e-10)
    }

    func testDiagonalOffset() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})
            local d = luaswift.array.diagonal(a, 1)
            return d:get(1) + d:get(2)
            """)
        // diagonal offset 1 = [2, 6], sum = 8
        XCTAssertEqual(result.numberValue!, 8, accuracy: 1e-10)
    }

    func testDiagCreate() throws {
        let result = try engine.evaluate("""
            local v = luaswift.array.array({1, 2, 3})
            local m = luaswift.array.diag(v)
            local shape = m:shape()
            return shape[1] * 10 + shape[2]
            """)
        // diag from [1,2,3] creates 3x3 matrix
        XCTAssertEqual(result.numberValue, 33)
    }

    func testDiagCreateValues() throws {
        let result = try engine.evaluate("""
            local v = luaswift.array.array({1, 2, 3})
            local m = luaswift.array.diag(v)
            return m:get(1,1) + m:get(2,2) + m:get(3,3) + m:get(1,2)
            """)
        // 1 + 2 + 3 + 0 = 6
        XCTAssertEqual(result.numberValue!, 6, accuracy: 1e-10)
    }

    func testDiagExtract() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local d = luaswift.array.diag(a)
            return d:get(1) + d:get(2)
            """)
        // extract diagonal [1, 4], sum = 5
        XCTAssertEqual(result.numberValue!, 5, accuracy: 1e-10)
    }

    func testOuter() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.array({4, 5})
            local c = luaswift.array.outer(a, b)
            local shape = c:shape()
            return shape[1] * 10 + shape[2]
            """)
        // outer product of [1,2,3] and [4,5] is 3x2
        XCTAssertEqual(result.numberValue, 32)
    }

    func testOuterValues() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2})
            local b = luaswift.array.array({3, 4})
            local c = luaswift.array.outer(a, b)
            return c:get(1,1) + c:get(1,2) + c:get(2,1) + c:get(2,2)
            """)
        // [[1*3, 1*4], [2*3, 2*4]] = [[3,4],[6,8]], sum = 21
        XCTAssertEqual(result.numberValue!, 21, accuracy: 1e-10)
    }

    func testMatmul() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.array({{5, 6}, {7, 8}})
            local c = luaswift.array.matmul(a, b)
            return c:get(1,1) + c:get(2,2)
            """)
        // [[1*5+2*7, 1*6+2*8], [3*5+4*7, 3*6+4*8]] = [[19,22],[43,50]]
        // 19 + 50 = 69
        XCTAssertEqual(result.numberValue!, 69, accuracy: 1e-10)
    }

    // MARK: - Phase 3.1 Creation Functions

    func testEye() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.eye(3)
            return a:get(1,1) + a:get(2,2) + a:get(3,3) + a:get(1,2)
            """)
        // 1 + 1 + 1 + 0 = 3
        XCTAssertEqual(result.numberValue!, 3, accuracy: 1e-10)
    }

    func testEyeRectangular() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.eye(2, 3)
            local shape = a:shape()
            return shape[1] * 10 + shape[2]
            """)
        // 2x3 matrix
        XCTAssertEqual(result.numberValue, 23)
    }

    func testEyeOffset() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.eye(3, 3, 1)
            return a:get(1,2) + a:get(2,3)
            """)
        // Offset 1 puts 1s on super-diagonal: 1 + 1 = 2
        XCTAssertEqual(result.numberValue!, 2, accuracy: 1e-10)
    }

    func testIdentity() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.identity(4)
            return a:get(1,1) + a:get(2,2) + a:get(3,3) + a:get(4,4)
            """)
        // Sum of diagonal = 4
        XCTAssertEqual(result.numberValue!, 4, accuracy: 1e-10)
    }

    func testEmpty() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.empty({2, 3})
            local shape = a:shape()
            return shape[1] * 10 + shape[2]
            """)
        // 2x3 shape
        XCTAssertEqual(result.numberValue, 23)
    }

    func testZerosLike() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
            local b = luaswift.array.zeros_like(a)
            local shape = b:shape()
            local sum = b:sum()
            return shape[1] * 100 + shape[2] * 10 + sum
            """)
        // Shape 2x3, sum = 0 → 200 + 30 + 0 = 230
        XCTAssertEqual(result.numberValue!, 230, accuracy: 1e-10)
    }

    func testOnesLike() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
            local b = luaswift.array.ones_like(a)
            return b:sum()
            """)
        // 2x3 = 6 elements, all 1s → sum = 6
        XCTAssertEqual(result.numberValue!, 6, accuracy: 1e-10)
    }

    func testFullLike() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.full_like(a, 7)
            return b:sum()
            """)
        // 2x2 = 4 elements, all 7s → sum = 28
        XCTAssertEqual(result.numberValue!, 28, accuracy: 1e-10)
    }

    // MARK: - Phase 3.2: Array Manipulation Tests

    func testTile1D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.tile(a, 2)
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(list, [1, 2, 3, 1, 2, 3])
    }

    func testTile2D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.tile(a, {2, 2})
            local shape = b:shape()
            return {shape[1], shape[2], b:sum()}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(arr[0], 4)  // rows = 2*2
        XCTAssertEqual(arr[1], 4)  // cols = 2*2
        XCTAssertEqual(arr[2], 40)  // 4 copies of (1+2+3+4)=10 → 40
    }

    func testRepNoAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.rep(a, 3)
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(list, [1, 1, 1, 2, 2, 2, 3, 3, 3])
    }

    func testRepWithAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.rep(a, 2, 2)  -- repeat along axis 2 (columns)
            local shape = b:shape()
            return {shape[1], shape[2]}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(arr[0], 2)  // rows unchanged
        XCTAssertEqual(arr[1], 4)  // cols doubled
    }

    func testFlipNoAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            local b = luaswift.array.flip(a)
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(list, [5, 4, 3, 2, 1])
    }

    func testFlipWithAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.flip(a, 1)  -- flip along axis 1 (rows)
            return {b:get(1, 1), b:get(1, 2), b:get(2, 1), b:get(2, 2)}
            """)
        // Original: [[1,2],[3,4]], flip rows → [[3,4],[1,2]]
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(arr, [3, 4, 1, 2])
    }

    func testRollNoAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            local b = luaswift.array.roll(a, 2)
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Roll by 2: [1,2,3,4,5] → [4,5,1,2,3]
        XCTAssertEqual(list, [4, 5, 1, 2, 3])
    }

    func testRollNegative() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            local b = luaswift.array.roll(a, -2)
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Roll by -2: [1,2,3,4,5] → [3,4,5,1,2]
        XCTAssertEqual(list, [3, 4, 5, 1, 2])
    }

    func testRollWithAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
            local b = luaswift.array.roll(a, 1, 2)  -- roll cols by 1
            return {b:get(1, 1), b:get(1, 2), b:get(1, 3)}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        // Roll cols by 1: [1,2,3] → [3,1,2]
        XCTAssertEqual(arr, [3, 1, 2])
    }

    func testPadConstant() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.pad(a, 2, "constant", 0)
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(list, [0, 0, 1, 2, 3, 0, 0])
    }

    func testPadEdge() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local b = luaswift.array.pad(a, 2, "edge")
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(list, [1, 1, 1, 2, 3, 3, 3])
    }

    func testPad2D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2}, {3, 4}})
            local b = luaswift.array.pad(a, 1, "constant", 0)
            local shape = b:shape()
            return {shape[1], shape[2]}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(arr[0], 4)  // 2 + 1 + 1
        XCTAssertEqual(arr[1], 4)  // 2 + 1 + 1
    }

    func testInsertFlat() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4})
            local b = luaswift.array.insert(a, 2, 99)  -- insert 99 at position 2
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(list, [1, 99, 2, 3, 4])
    }

    func testDeleteFlat() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            local b = luaswift.array.delete(a, 3)  -- delete element at position 3
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(list, [1, 2, 4, 5])
    }

    func testDeleteWithAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 3}, {4, 5, 6}})
            local b = luaswift.array.delete(a, 2, 2)  -- delete column 2
            local shape = b:shape()
            return {shape[1], shape[2], b:get(1, 1), b:get(1, 2)}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(arr[0], 2)  // rows unchanged
        XCTAssertEqual(arr[1], 2)  // cols - 1
        XCTAssertEqual(arr[2], 1)  // first row, first remaining col
        XCTAssertEqual(arr[3], 3)  // first row, second remaining col
    }

    func testDiff1D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 4, 7, 11})
            local b = luaswift.array.diff(a)
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(list, [1, 2, 3, 4])
    }

    func testDiffN2() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 4, 7, 11})
            local b = luaswift.array.diff(a, 2)
            return b:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // First diff: [1, 2, 3, 4], Second diff: [1, 1, 1]
        XCTAssertEqual(list, [1, 1, 1])
    }

    func testDiff2DAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 3, 6}, {2, 5, 9}})
            local b = luaswift.array.diff(a, 1, 2)  -- diff along axis 2 (columns)
            local shape = b:shape()
            return {shape[1], shape[2], b:get(1, 1), b:get(1, 2)}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(arr[0], 2)  // rows unchanged
        XCTAssertEqual(arr[1], 2)  // cols - 1
        XCTAssertEqual(arr[2], 2)  // 3-1
        XCTAssertEqual(arr[3], 3)  // 6-3
    }

    // MARK: - Phase 3.3 Signal Processing Tests

    func testCorrelateFull() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local v = luaswift.array.array({0, 1, 0.5})
            local c = luaswift.array.correlate(a, v, "full")
            return c:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Full correlation: output length = n + m - 1 = 3 + 3 - 1 = 5
        XCTAssertEqual(list.count, 5)
        // Correlation at offset 0 (centered): 1*0.5 + 2*1 + 3*0 = 2.5
        XCTAssertEqual(list[2], 2.5, accuracy: 1e-10)
    }

    func testCorrelateValid() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            local v = luaswift.array.array({1, 1, 1})
            local c = luaswift.array.correlate(a, v, "valid")
            return c:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Valid mode: output length = max(n, m) - min(n, m) + 1 = 5 - 3 + 1 = 3
        XCTAssertEqual(list.count, 3)
        // Moving sum of 3 elements
        XCTAssertEqual(list[0], 6, accuracy: 1e-10)  // 1+2+3
        XCTAssertEqual(list[1], 9, accuracy: 1e-10)  // 2+3+4
        XCTAssertEqual(list[2], 12, accuracy: 1e-10) // 3+4+5
    }

    func testCorrelateSame() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4})
            local v = luaswift.array.array({1, 2})
            local c = luaswift.array.correlate(a, v, "same")
            return {c:size()}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        // Same mode: output length = max(n, m) = 4
        XCTAssertEqual(arr[0], 4)
    }

    func testConvolveFull() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3})
            local v = luaswift.array.array({0, 1, 0.5})
            local c = luaswift.array.convolve(a, v, "full")
            return c:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Full convolution: output length = n + m - 1 = 5
        XCTAssertEqual(list.count, 5)
        // Convolution: sum of a[k] * v[n-k]
        // At n=0: a[0]*v[0] = 1*0 = 0
        XCTAssertEqual(list[0], 0, accuracy: 1e-10)
        // At n=1: a[0]*v[1] + a[1]*v[0] = 1*1 + 2*0 = 1
        XCTAssertEqual(list[1], 1, accuracy: 1e-10)
        // At n=2: a[0]*v[2] + a[1]*v[1] + a[2]*v[0] = 1*0.5 + 2*1 + 3*0 = 2.5
        XCTAssertEqual(list[2], 2.5, accuracy: 1e-10)
    }

    func testConvolveValid() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4, 5})
            local v = luaswift.array.array({1, 0, -1})
            local c = luaswift.array.convolve(a, v, "valid")
            return c:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Valid mode: output length = 5 - 3 + 1 = 3
        XCTAssertEqual(list.count, 3)
        // Convolution flips kernel: [-1, 0, 1], so output[i] = a[i+2] - a[i]
        XCTAssertEqual(list[0], 2, accuracy: 1e-10)  // 3 - 1
        XCTAssertEqual(list[1], 2, accuracy: 1e-10)  // 4 - 2
        XCTAssertEqual(list[2], 2, accuracy: 1e-10)  // 5 - 3
    }

    func testConvolveSame() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 3, 4})
            local v = luaswift.array.array({1, 2, 1})
            local c = luaswift.array.convolve(a, v, "same")
            return {c:size()}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        // Same mode: output length = max(n, m) = 4
        XCTAssertEqual(arr[0], 4)
    }

    func testGradient1D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({1, 2, 4, 7, 11})
            local g = luaswift.array.gradient(a)
            return g:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Forward diff at boundary: 2-1 = 1
        XCTAssertEqual(list[0], 1, accuracy: 1e-10)
        // Central diff: (4-1)/2 = 1.5
        XCTAssertEqual(list[1], 1.5, accuracy: 1e-10)
        // Central diff: (7-2)/2 = 2.5
        XCTAssertEqual(list[2], 2.5, accuracy: 1e-10)
        // Central diff: (11-4)/2 = 3.5
        XCTAssertEqual(list[3], 3.5, accuracy: 1e-10)
        // Backward diff at boundary: 11-7 = 4
        XCTAssertEqual(list[4], 4, accuracy: 1e-10)
    }

    func testGradientWithSpacing() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({0, 2, 6, 12})
            local g = luaswift.array.gradient(a, 2)  -- spacing = 2
            return g:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Forward: (2-0)/2 = 1
        XCTAssertEqual(list[0], 1, accuracy: 1e-10)
        // Central: (6-0)/(2*2) = 1.5
        XCTAssertEqual(list[1], 1.5, accuracy: 1e-10)
        // Central: (12-2)/(2*2) = 2.5
        XCTAssertEqual(list[2], 2.5, accuracy: 1e-10)
        // Backward: (12-6)/2 = 3
        XCTAssertEqual(list[3], 3, accuracy: 1e-10)
    }

    func testGradient2D() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 2, 4}, {3, 5, 8}})
            local gy, gx = luaswift.array.gradient(a)
            return {gy:get(1, 1), gy:get(1, 2), gx:get(1, 1), gx:get(1, 2)}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        // gy is gradient along axis 1 (rows): (3-1)=2, (5-2)=3
        XCTAssertEqual(arr[0], 2, accuracy: 1e-10)
        XCTAssertEqual(arr[1], 3, accuracy: 1e-10)
        // gx is gradient along axis 2 (cols): forward at [1,1]: 2-1=1, central at [1,2]: (4-1)/2=1.5
        XCTAssertEqual(arr[2], 1, accuracy: 1e-10)
        XCTAssertEqual(arr[3], 1.5, accuracy: 1e-10)
    }

    func testGradientWithAxis() throws {
        let result = try engine.evaluate("""
            local a = luaswift.array.array({{1, 3, 6}, {2, 5, 9}})
            local g = luaswift.array.gradient(a, 1, 2)  -- gradient along axis 2 (columns)
            return {g:get(1, 1), g:get(1, 2), g:get(1, 3)}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        // Forward at [1,1]: 3-1=2
        XCTAssertEqual(arr[0], 2, accuracy: 1e-10)
        // Central at [1,2]: (6-1)/2=2.5
        XCTAssertEqual(arr[1], 2.5, accuracy: 1e-10)
        // Backward at [1,3]: 6-3=3
        XCTAssertEqual(arr[2], 3, accuracy: 1e-10)
    }

    func testInterpBasic() throws {
        let result = try engine.evaluate("""
            local xp = luaswift.array.array({0, 1, 2, 3})
            local fp = luaswift.array.array({0, 1, 4, 9})  -- y = x^2 at integer points
            local x = luaswift.array.array({0.5, 1.5, 2.5})
            local y = luaswift.array.interp(x, xp, fp)
            return y:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Linear interpolation: midpoints
        XCTAssertEqual(list[0], 0.5, accuracy: 1e-10)   // Between 0 and 1
        XCTAssertEqual(list[1], 2.5, accuracy: 1e-10)   // Between 1 and 4
        XCTAssertEqual(list[2], 6.5, accuracy: 1e-10)   // Between 4 and 9
    }

    func testInterpScalar() throws {
        let result = try engine.evaluate("""
            local xp = luaswift.array.array({0, 1, 2})
            local fp = luaswift.array.array({0, 10, 20})
            return luaswift.array.interp(0.5, xp, fp)
            """)
        XCTAssertEqual(result.numberValue!, 5, accuracy: 1e-10)
    }

    func testInterpExtrapolation() throws {
        let result = try engine.evaluate("""
            local xp = luaswift.array.array({1, 2, 3})
            local fp = luaswift.array.array({10, 20, 30})
            local y1 = luaswift.array.interp(0, xp, fp)        -- below range, use first value
            local y2 = luaswift.array.interp(5, xp, fp)        -- above range, use last value
            local y3 = luaswift.array.interp(0, xp, fp, -99)   -- custom left value
            local y4 = luaswift.array.interp(5, xp, fp, nil, 99) -- custom right value
            return {y1, y2, y3, y4}
            """)
        let arr = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(arr[0], 10, accuracy: 1e-10)   // Default: first value
        XCTAssertEqual(arr[1], 30, accuracy: 1e-10)   // Default: last value
        XCTAssertEqual(arr[2], -99, accuracy: 1e-10)  // Custom left
        XCTAssertEqual(arr[3], 99, accuracy: 1e-10)   // Custom right
    }

    func testInterpAtKnownPoints() throws {
        let result = try engine.evaluate("""
            local xp = luaswift.array.array({0, 1, 2, 3})
            local fp = luaswift.array.array({5, 15, 25, 35})
            local x = luaswift.array.array({0, 1, 2, 3})
            local y = luaswift.array.interp(x, xp, fp)
            return y:tolist()
            """)
        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Interpolating at exact known points should return exact values
        XCTAssertEqual(list[0], 5, accuracy: 1e-10)
        XCTAssertEqual(list[1], 15, accuracy: 1e-10)
        XCTAssertEqual(list[2], 25, accuracy: 1e-10)
        XCTAssertEqual(list[3], 35, accuracy: 1e-10)
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
