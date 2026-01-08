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

    func testDiagonal() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.diagonal({1, 2, 3})
            return m:get(2, 2)
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    func testDiagAlias() throws {
        // Verify legacy alias still works
        let result = try engine.evaluate("""
            local m1 = luaswift.linalg.diagonal({1, 2, 3})
            local m2 = luaswift.linalg.diag({1, 2, 3})
            return m1:get(2, 2) == m2:get(2, 2)
            """)

        XCTAssertEqual(result.boolValue, true)
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

    // MARK: - Condition Number

    func testCondWellConditioned() throws {
        // Identity matrix has condition number 1
        let result = try engine.evaluate("""
            local m = luaswift.linalg.eye(3)
            return m:cond()
            """)

        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testCondModerateCondition() throws {
        // Diagonal matrix with known condition number
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{10,0},{0,1}})
            return m:cond()
            """)

        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    func testCondNearSingular() throws {
        // Matrix that's nearly singular should have very high condition number
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{4,5,6},{7,8,9.00001}})
            return m:cond()
            """)

        // Should be very large but not infinite
        XCTAssertTrue(result.numberValue! > 1e6)
        XCTAssertTrue(result.numberValue!.isFinite)
    }

    func testCondSingularMatrix() throws {
        // Singular matrix has very high (or infinite) condition number
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{4,5,6},{7,8,9}})
            return m:cond()
            """)

        let cond = result.numberValue!
        // Due to floating point, might not be exactly infinite but should be very large
        // In practice, the rank-deficient matrix has condition number > 1e15
        XCTAssertTrue(cond > 1e14 || cond.isInfinite, "Expected cond > 1e14 or inf, got \(cond)")
    }

    func testCondNamespaceFunction() throws {
        // Test namespace access
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{4,0},{0,2}})
            return luaswift.linalg.cond(m)
            """)

        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    // MARK: - Pseudo-inverse

    func testPinvSquareMatrix() throws {
        // For invertible square matrix, pinv should equal inv
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            local pinv_m = m:pinv()
            local inv_m = m:inv()
            -- Check if all elements are approximately equal
            local max_diff = 0
            for i = 1, 2 do
                for j = 1, 2 do
                    local diff = math.abs(pinv_m:get(i,j) - inv_m:get(i,j))
                    if diff > max_diff then max_diff = diff end
                end
            end
            return max_diff
            """)

        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testPinvRectangularTall() throws {
        // For tall rectangular matrix (more rows than cols)
        // A+ * A should be identity (cols x cols)
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,0},{0,1},{0,0}})
            local pinv_m = m:pinv()
            -- pinv should be 2x3
            return {pinv_m:rows(), pinv_m:cols()}
            """)

        let arr = result.arrayValue!
        XCTAssertEqual(arr[0].numberValue, 2)  // rows
        XCTAssertEqual(arr[1].numberValue, 3)  // cols
    }

    func testPinvRectangularWide() throws {
        // For wide rectangular matrix (more cols than rows)
        // A * A+ should be identity (rows x rows)
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,0,0},{0,1,0}})
            local pinv_m = m:pinv()
            -- pinv should be 3x2
            return {pinv_m:rows(), pinv_m:cols()}
            """)

        let arr = result.arrayValue!
        XCTAssertEqual(arr[0].numberValue, 3)  // rows
        XCTAssertEqual(arr[1].numberValue, 2)  // cols
    }

    func testPinvMoorePenroseProperty() throws {
        // Test one of the Moore-Penrose conditions: A * A+ * A = A
        let result = try engine.evaluate("""
            local A = luaswift.linalg.matrix({{1,2},{3,4},{5,6}})
            local Ap = A:pinv()
            local AApA = A:dot(Ap):dot(A)
            -- Check if A and AApA are approximately equal
            local diff = 0
            for i = 1, A:rows() do
                for j = 1, A:cols() do
                    diff = diff + math.abs(A:get(i,j) - AApA:get(i,j))
                end
            end
            return diff
            """)

        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testPinvNamespaceFunction() throws {
        // Test namespace access
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,0},{0,2}})
            local pinv_m = luaswift.linalg.pinv(m)
            return pinv_m:get(2,2)
            """)

        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
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

    func testEigen() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,0},{0,2}})
            local vals, vecs = m:eigen()
            return vals:size()
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    func testEigAlias() throws {
        // Verify legacy alias still works
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,0},{0,2}})
            local vals1, _ = m:eigen()
            local vals2, _ = m:eig()
            return vals1:get(1) == vals2:get(1)
            """)

        XCTAssertEqual(result.boolValue, true)
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

    func testLeastSquares() throws {
        let result = try engine.evaluate("""
            local A = luaswift.linalg.matrix({{1,1},{1,2},{1,3}})
            local b = luaswift.linalg.vector({1, 2, 2})
            local x = luaswift.linalg.least_squares(A, b)
            return x:size()
            """)

        XCTAssertEqual(result.numberValue, 2)
    }

    func testLstSqAlias() throws {
        // Verify legacy alias still works
        let result = try engine.evaluate("""
            local A = luaswift.linalg.matrix({{1,1},{1,2},{1,3}})
            local b = luaswift.linalg.vector({1, 2, 2})
            local x1 = luaswift.linalg.least_squares(A, b)
            local x2 = luaswift.linalg.lstsq(A, b)
            return x1:get(1) == x2:get(1)
            """)

        XCTAssertEqual(result.boolValue, true)
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

    // MARK: - Type Markers

    func testVectorTypeMarker() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({1, 2, 3})
            return v.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.vector")
    }

    func testMatrixTypeMarker() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1, 2}, {3, 4}})
            return m.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.matrix")
    }

    func testZerosVectorTypeMarker() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.zeros(5)
            return v.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.vector")
    }

    func testZerosMatrixTypeMarker() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.zeros(3, 3)
            return m.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.matrix")
    }

    func testOnesVectorTypeMarker() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.ones(4)
            return v.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.vector")
    }

    func testOnesMatrixTypeMarker() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.ones(2, 3)
            return m.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.matrix")
    }

    func testEyeTypeMarker() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.eye(3)
            return m.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.matrix")
    }

    func testDiagonalTypeMarker() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.diagonal({1, 2, 3})
            return m.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.matrix")
    }

    func testRangeTypeMarker() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.range(1, 10, 2)
            return v.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.vector")
    }

    func testLinspaceTypeMarker() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.linspace(0, 1, 5)
            return v.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.vector")
    }

    func testTransposePreservesMatrixType() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1, 2, 3}, {4, 5, 6}})
            local t = m:transpose()
            return t.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.matrix")
    }

    func testInversePreservesMatrixType() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{4, 7}, {2, 6}})
            local inv = m:inv()
            return inv.__luaswift_type
            """)

        XCTAssertEqual(result.stringValue, "linalg.matrix")
    }
}
