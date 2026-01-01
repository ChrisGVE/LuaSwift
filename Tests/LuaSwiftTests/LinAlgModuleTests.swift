//
//  LinAlgModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class LinAlgModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installLinAlgModule(in: engine)
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Vector Creation

    func testVectorCreation() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({1, 2, 3, 4})
            return v:size()
            """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testVectorShape() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({1, 2, 3})
            local shape = v:shape()
            return shape[1]
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testZerosVector() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.zeros(5)
            local arr = v:toarray()
            return arr[3]
            """)

        XCTAssertEqual(result.numberValue, 0)
    }

    func testOnesVector() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.ones(4)
            local arr = v:toarray()
            return arr[2]
            """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testRange() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.range(1, 5, 1)
            return v:size()
            """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testLinspace() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.linspace(0, 1, 5)
            local arr = v:toarray()
            return arr[3]
            """)

        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
    }

    // MARK: - Matrix Creation

    func testMatrixCreation() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            return m:rows() * 10 + m:cols()
            """)

        XCTAssertEqual(result.numberValue, 22)
    }

    func testMatrixGet() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{4,5,6}})
            return m:get(2, 3)
            """)

        XCTAssertEqual(result.numberValue, 6)
    }

    func testMatrixSet() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            m:set(1, 2, 10)
            return m:get(1, 2)
            """)

        XCTAssertEqual(result.numberValue, 10)
    }

    func testZerosMatrix() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.zeros(3, 4)
            return m:rows() * 10 + m:cols()
            """)

        XCTAssertEqual(result.numberValue, 34)
    }

    func testOnesMatrix() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.ones(2, 3)
            return m:get(2, 3)
            """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testEye() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.eye(3)
            local diag = m:get(2, 2)
            local offdiag = m:get(1, 2)
            return diag * 10 + offdiag
            """)

        XCTAssertEqual(result.numberValue, 10)
    }

    func testDiag() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.diag({1, 2, 3})
            return m:get(2, 2)
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    // MARK: - Transpose

    func testTranspose() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{4,5,6}})
            local t = m:transpose()
            return t:rows() * 10 + t:cols()
            """)

        XCTAssertEqual(result.numberValue, 32)
    }

    func testTransposeValues() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            local t = m:transpose()
            return t:get(1, 2)
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    // MARK: - Arithmetic

    func testMatrixAdd() throws {
        let result = try engine.evaluate("""
            local m1 = luaswift.linalg.matrix({{1,2},{3,4}})
            local m2 = luaswift.linalg.matrix({{5,6},{7,8}})
            local m3 = m1 + m2
            return m3:get(2, 2)
            """)

        XCTAssertEqual(result.numberValue, 12)
    }

    func testMatrixSub() throws {
        let result = try engine.evaluate("""
            local m1 = luaswift.linalg.matrix({{5,6},{7,8}})
            local m2 = luaswift.linalg.matrix({{1,2},{3,4}})
            local m3 = m1 - m2
            return m3:get(1, 1)
            """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testMatrixScalarMul() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            local m2 = m * 2
            return m2:get(2, 2)
            """)

        XCTAssertEqual(result.numberValue, 8)
    }

    func testMatrixDiv() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{4,6},{8,10}})
            local m2 = m / 2
            return m2:get(1, 2)
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testVectorDot() throws {
        let result = try engine.evaluate("""
            local v1 = luaswift.linalg.vector({1, 2, 3})
            local v2 = luaswift.linalg.vector({4, 5, 6})
            return v1:dot(v2)
            """)

        XCTAssertEqual(result.numberValue, 32)  // 1*4 + 2*5 + 3*6
    }

    func testMatrixDot() throws {
        let result = try engine.evaluate("""
            local m1 = luaswift.linalg.matrix({{1,2},{3,4}})
            local m2 = luaswift.linalg.matrix({{5,6},{7,8}})
            local m3 = m1:dot(m2)
            return m3:get(1, 1)
            """)

        XCTAssertEqual(result.numberValue, 19)  // 1*5 + 2*7
    }

    func testHadamard() throws {
        let result = try engine.evaluate("""
            local m1 = luaswift.linalg.matrix({{1,2},{3,4}})
            local m2 = luaswift.linalg.matrix({{2,3},{4,5}})
            local m3 = m1:hadamard(m2)
            return m3:get(2, 2)
            """)

        XCTAssertEqual(result.numberValue, 20)  // 4*5
    }

    // MARK: - Linear Algebra Operations

    func testDeterminant() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            return m:det()
            """)

        XCTAssertEqual(result.numberValue!, -2, accuracy: 1e-10)
    }

    func testTrace() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            return m:trace()
            """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testInverse() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{4,7},{2,6}})
            local inv = m:inv()
            local product = m:dot(inv)
            return product:get(1, 1)
            """)

        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testNormVector() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({3, 4})
            return v:norm(2)
            """)

        XCTAssertEqual(result.numberValue, 5)  // sqrt(9 + 16)
    }

    func testNormL1() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({1, -2, 3})
            return v:norm(1)
            """)

        XCTAssertEqual(result.numberValue, 6)
    }

    func testRank() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{4,5,6},{7,8,9}})
            return m:rank()
            """)

        XCTAssertEqual(result.numberValue, 2)  // Rank-deficient matrix
    }

    // MARK: - Decompositions

    func testLU() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{2,1},{4,3}})
            local L, U, P = m:lu()
            return L:get(2, 1)
            """)

        XCTAssertNotNil(result.numberValue)
    }

    func testQR() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4},{5,6}})
            local Q, R = m:qr()
            return Q:rows()
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testSVD() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            local U, S, V = m:svd()
            return U:rows()
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    func testEig() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,0},{0,2}})
            local vals, vecs = m:eig()
            return vals:size()
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    func testCholesky() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{4,2},{2,5}})
            local L = m:chol()
            return L:get(1, 1)
            """)

        XCTAssertEqual(result.numberValue!, 2, accuracy: 1e-10)  // sqrt(4)
    }

    // MARK: - Solvers

    func testSolve() throws {
        let result = try engine.evaluate("""
            local A = luaswift.linalg.matrix({{3,1},{1,2}})
            local b = luaswift.linalg.vector({9, 8})
            local x = luaswift.linalg.solve(A, b)
            return x:get(1)
            """)

        XCTAssertEqual(result.numberValue!, 2, accuracy: 1e-10)
    }

    func testLstSq() throws {
        let result = try engine.evaluate("""
            local A = luaswift.linalg.matrix({{1,1},{1,2},{1,3}})
            local b = luaswift.linalg.vector({1, 2, 2})
            local x = luaswift.linalg.lstsq(A, b)
            return x:size()
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    // MARK: - Row and Column extraction

    func testRowExtraction() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{4,5,6}})
            local r = m:row(2)
            local arr = r:toarray()
            return arr[1][2]
            """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testColExtraction() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{4,5,6}})
            local c = m:col(2)
            local arr = c:toarray()
            return arr[2]
            """)

        XCTAssertEqual(result.numberValue, 5)
    }

    // MARK: - Metatable operations

    func testToString() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            return tostring(m)
            """)

        XCTAssertEqual(result.stringValue, "matrix(2x2)")
    }

    func testVectorToString() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({1, 2, 3})
            return tostring(v)
            """)

        XCTAssertEqual(result.stringValue, "vector(3)")
    }

    func testUnaryMinus() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            local neg = -m
            return neg:get(1, 1)
            """)

        XCTAssertEqual(result.numberValue, -1)
    }

    // MARK: - toarray

    func testToArray2D() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            local arr = m:toarray()
            return arr[2][1]
            """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testToArray1D() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({10, 20, 30})
            local arr = v:toarray()
            return arr[2]
            """)

        XCTAssertEqual(result.numberValue, 20)
    }
}
