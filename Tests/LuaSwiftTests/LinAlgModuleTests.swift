//
//  LinAlgModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

#if LUASWIFT_NUMERICSWIFT
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

    func testSVDDiagonalMatrix() throws {
        // Default behavior: S is diagonal matrix (rows x cols)
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            local U, S, V = m:svd()
            return {S:rows(), S:cols()}
            """)

        let arr = result.arrayValue!
        XCTAssertEqual(arr[0].numberValue, 2)  // rows
        XCTAssertEqual(arr[1].numberValue, 2)  // cols
    }

    func testSVD1DSingularValues() throws {
        // With return1D=true: S is 1D vector (min(rows,cols) x 1)
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4}})
            local U, S, V = m:svd(true)
            return {S:rows(), S:cols(), S:size()}
            """)

        let arr = result.arrayValue!
        XCTAssertEqual(arr[0].numberValue, 2)  // rows = min(2,2) = 2
        XCTAssertEqual(arr[1].numberValue, 1)  // cols = 1 (1D vector)
        XCTAssertEqual(arr[2].numberValue, 2)  // size = 2 singular values
    }

    func testSVD1DRectangular() throws {
        // Test with rectangular matrix (3x2)
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{3,4},{5,6}})
            local U, S, V = m:svd(true)
            return {S:rows(), S:cols(), S:get(1,1), S:get(2,1)}
            """)

        let arr = result.arrayValue!
        XCTAssertEqual(arr[0].numberValue, 2)  // min(3,2) = 2 singular values
        XCTAssertEqual(arr[1].numberValue, 1)  // 1D vector
        // Singular values should be positive
        XCTAssertTrue(arr[2].numberValue! > 0)
        XCTAssertTrue(arr[3].numberValue! > 0)
        // First should be larger than second (sorted descending)
        XCTAssertTrue(arr[2].numberValue! > arr[3].numberValue!)
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

    // MARK: - Edge Cases: 1x1 Matrices

    func testOneByOneMatrixDet() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{5}})
            return m:det()
            """)

        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testOneByOneMatrixInv() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{4}})
            local inv = m:inv()
            return inv:get(1,1)
            """)

        XCTAssertEqual(result.numberValue!, 0.25, accuracy: 1e-10)
    }

    func testOneByOneMatrixEigen() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{7}})
            local vals, vecs = m:eigen()
            return vals:get(1,1)
            """)

        XCTAssertEqual(result.numberValue!, 7.0, accuracy: 1e-10)
    }

    func testOneByOneMatrixSVD() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{3}})
            local U, S, V = m:svd(true)
            return S:get(1,1)
            """)

        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    // MARK: - Edge Cases: Singular Matrices

    func testSingularMatrixDetIsZero() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{2,4}})
            return math.abs(m:det()) < 1e-10
            """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSingularMatrixRank() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{2,4,6},{3,6,9}})
            return m:rank()
            """)

        XCTAssertEqual(result.numberValue, 1)  // All rows are multiples of first
    }

    func testSingularMatrixCond() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2},{2,4}})
            return m:cond()
            """)

        XCTAssertTrue(result.numberValue!.isInfinite)
    }

    // MARK: - Edge Cases: Identity Matrix Properties

    func testIdentityMatrixDet() throws {
        let result = try engine.evaluate("""
            local m = luaswift.linalg.eye(4)
            return m:det()
            """)

        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testIdentityMatrixInverse() throws {
        // Inverse of identity is identity
        let result = try engine.evaluate("""
            local m = luaswift.linalg.eye(3)
            local inv = m:inv()
            return inv:get(1,1) + inv:get(2,2) + inv:get(3,3)
            """)

        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)  // Trace = 3
    }

    func testIdentityMatrixEigen() throws {
        // All eigenvalues of identity are 1
        let result = try engine.evaluate("""
            local m = luaswift.linalg.eye(3)
            local vals, vecs = m:eigen()
            return vals:get(1,1) + vals:get(2,1) + vals:get(3,1)
            """)

        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)  // Sum of eigenvalues = 3
    }

    // MARK: - Edge Cases: Diagonal Matrices

    func testDiagonalMatrixDet() throws {
        // Determinant is product of diagonal elements
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{2,0,0},{0,3,0},{0,0,4}})
            return m:det()
            """)

        XCTAssertEqual(result.numberValue!, 24.0, accuracy: 1e-10)
    }

    func testDiagonalMatrixInverse() throws {
        // Inverse diagonal has reciprocal elements
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{2,0},{0,4}})
            local inv = m:inv()
            return inv:get(1,1) * inv:get(2,2)
            """)

        XCTAssertEqual(result.numberValue!, 0.125, accuracy: 1e-10)  // 0.5 * 0.25
    }

    // MARK: - Edge Cases: Solve with Singular/Near-Singular

    func testSolveIdentity() throws {
        // Solving Ix = b should give x = b
        let result = try engine.evaluate("""
            local I = luaswift.linalg.eye(3)
            local b = luaswift.linalg.vector({1, 2, 3})
            local x = luaswift.linalg.solve(I, b)
            return x:get(1,1) + x:get(2,1) + x:get(3,1)
            """)

        XCTAssertEqual(result.numberValue!, 6.0, accuracy: 1e-10)
    }

    // MARK: - Edge Cases: Transpose Properties

    func testTransposeOfTranspose() throws {
        // (A^T)^T = A
        let result = try engine.evaluate("""
            local m = luaswift.linalg.matrix({{1,2,3},{4,5,6}})
            local tt = m:transpose():transpose()
            return tt:get(1,1) + tt:get(2,3)
            """)

        XCTAssertEqual(result.numberValue!, 7.0, accuracy: 1e-10)  // 1 + 6
    }

    // MARK: - Edge Cases: Norm Properties

    func testNormZeroVector() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.zeros(5)
            return v:norm()
            """)

        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testNormUnitVector() throws {
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({1, 0, 0, 0})
            return v:norm()
            """)

        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    // MARK: - Edge Cases: Dot Product Properties

    func testDotProductOrthogonal() throws {
        // Orthogonal vectors have dot product 0
        let result = try engine.evaluate("""
            local v1 = luaswift.linalg.vector({1, 0, 0})
            local v2 = luaswift.linalg.vector({0, 1, 0})
            return v1:dot(v2)
            """)

        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testDotProductParallel() throws {
        // Parallel vectors: v·v = ||v||^2
        let result = try engine.evaluate("""
            local v = luaswift.linalg.vector({3, 4})
            return v:dot(v)
            """)

        XCTAssertEqual(result.numberValue!, 25.0, accuracy: 1e-10)  // 3^2 + 4^2
    }

    // MARK: - Complex Linear Algebra

    func testCsolveSimple() throws {
        // Solve (1+i)*x = 2+2i, should give x = 1
        let result = try engine.evaluate("""
            local A = {rows = 1, cols = 1, real = {1}, imag = {1}}
            local b = {rows = 1, cols = 1, real = {2}, imag = {2}}
            local x = luaswift.linalg.csolve(A, b)
            return {re = x.real[1], im = x.imag[1]}
            """)

        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, 2.0, accuracy: 1e-10)
        XCTAssertEqual(table["im"]!.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testCsolve2x2() throws {
        // Solve a 2x2 complex system
        // [[1, i], [i, 1]] * [x, y] = [1+i, 1+i]
        // Solution: x = 1, y = 1
        let result = try engine.evaluate("""
            local A = {rows = 2, cols = 2, real = {1, 0, 0, 1}, imag = {0, 1, 1, 0}}
            local b = {rows = 2, cols = 1, real = {1, 1}, imag = {1, 1}}
            local x = luaswift.linalg.csolve(A, b)
            -- Check x[1] and x[2] are approximately 1
            return {x1_re = x.real[1], x1_im = x.imag[1], x2_re = x.real[2], x2_im = x.imag[2]}
            """)

        let table = result.tableValue!
        XCTAssertEqual(table["x1_re"]!.numberValue!, 1.0, accuracy: 1e-10)
        XCTAssertEqual(table["x1_im"]!.numberValue!, 0.0, accuracy: 1e-10)
        XCTAssertEqual(table["x2_re"]!.numberValue!, 1.0, accuracy: 1e-10)
        XCTAssertEqual(table["x2_im"]!.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testCsolveIdentity() throws {
        // Solving I*x = b should give x = b for complex matrices
        let result = try engine.evaluate("""
            local A = {rows = 2, cols = 2, real = {1, 0, 0, 1}, imag = {0, 0, 0, 0}}
            local b = {rows = 2, cols = 1, real = {3, 5}, imag = {4, 6}}
            local x = luaswift.linalg.csolve(A, b)
            return {x1_re = x.real[1], x1_im = x.imag[1], x2_re = x.real[2], x2_im = x.imag[2]}
            """)

        let table = result.tableValue!
        XCTAssertEqual(table["x1_re"]!.numberValue!, 3.0, accuracy: 1e-10)
        XCTAssertEqual(table["x1_im"]!.numberValue!, 4.0, accuracy: 1e-10)
        XCTAssertEqual(table["x2_re"]!.numberValue!, 5.0, accuracy: 1e-10)
        XCTAssertEqual(table["x2_im"]!.numberValue!, 6.0, accuracy: 1e-10)
    }

    func testCsvd2x2() throws {
        // SVD of a simple complex matrix
        let result = try engine.evaluate("""
            local A = {rows = 2, cols = 2, real = {1, 0, 0, 1}, imag = {0, 1, 1, 0}}
            local U, S, Vt = luaswift.linalg.csvd(A)
            -- Check singular values (should be 2 and 0 for this matrix: [[1,i],[i,1]])
            -- Actually for [[1,i],[i,1]], eigenvalues are 1+i and 1-i, singular values are sqrt(2) and sqrt(2)
            return S.data[1] + S.data[2]
            """)

        // For [[1,i],[i,1]], singular values are sqrt(2), sqrt(2)
        XCTAssertEqual(result.numberValue!, 2 * sqrt(2), accuracy: 1e-10)
    }

    func testCsvdIdentity() throws {
        // SVD of complex identity matrix
        let result = try engine.evaluate("""
            local A = {rows = 2, cols = 2, real = {1, 0, 0, 1}, imag = {0, 0, 0, 0}}
            local U, S, Vt = luaswift.linalg.csvd(A)
            -- Singular values of identity should be 1, 1
            return S.data[1] + S.data[2]
            """)

        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testCsvdReturnsComplexU() throws {
        // Check that U has complex structure
        let result = try engine.evaluate("""
            local A = {rows = 2, cols = 2, real = {1, 0, 0, 1}, imag = {0, 1, 1, 0}}
            local U, S, Vt = luaswift.linalg.csvd(A)
            return U.dtype
            """)

        XCTAssertEqual(result.stringValue, "complex128")
    }

    func testCsvdReturnsComplexVt() throws {
        // Check that Vt has complex structure
        let result = try engine.evaluate("""
            local A = {rows = 2, cols = 2, real = {1, 0, 0, 1}, imag = {0, 1, 1, 0}}
            local U, S, Vt = luaswift.linalg.csvd(A)
            return Vt.dtype
            """)

        XCTAssertEqual(result.stringValue, "complex128")
    }

    // MARK: - Complex Eigenvalues (ceig)

    func testCeigDiagonal() throws {
        // Eigenvalues of diagonal complex matrix are the diagonal entries
        let result = try engine.evaluate("""
            local A = {
                rows = 2, cols = 2,
                shape = {2, 2},
                dtype = "complex128",
                real = {{1, 0}, {0, 2}},
                imag = {{1, 0}, {0, -1}}
            }
            local vals, vecs = luaswift.linalg.ceig(A)
            -- Eigenvalues are returned as flat arrays
            local re1 = vals.real[1]
            local im1 = vals.imag[1]
            local re2 = vals.real[2]
            local im2 = vals.imag[2]
            return {re1, im1, re2, im2}
            """)

        let list = result.arrayValue!.compactMap { $0.numberValue }
        // Eigenvalues should be 1+i and 2-i (order may vary)
        let eigenvalues = [(list[0], list[1]), (list[2], list[3])]

        // Check that we have both eigenvalues (order may vary)
        var found1 = false
        var found2 = false
        for (re, im) in eigenvalues {
            if abs(re - 1.0) < 1e-10 && abs(im - 1.0) < 1e-10 { found1 = true }
            if abs(re - 2.0) < 1e-10 && abs(im - (-1.0)) < 1e-10 { found2 = true }
        }
        XCTAssertTrue(found1 && found2, "Expected eigenvalues 1+i and 2-i")
    }

    func testCeigvalsRotation() throws {
        // 90-degree rotation matrix [[0,-1],[1,0]] has eigenvalues ±i
        let result = try engine.evaluate("""
            local A = {
                rows = 2, cols = 2,
                shape = {2, 2},
                dtype = "complex128",
                real = {{0, -1}, {1, 0}},
                imag = {{0, 0}, {0, 0}}
            }
            local vals = luaswift.linalg.ceigvals(A)
            -- Eigenvalues are returned as flat arrays
            local re1 = vals.real[1]
            local im1 = vals.imag[1]
            local re2 = vals.real[2]
            local im2 = vals.imag[2]
            -- Eigenvalues should be +i and -i
            return math.abs(re1) + math.abs(re2) + math.abs(im1) + math.abs(im2)
            """)

        // Sum of |re| should be ~0, sum of |im| should be 2 (1 + 1)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testCeigReturnsComplexVectors() throws {
        // Verify eigenvectors have complex dtype
        let result = try engine.evaluate("""
            local A = {
                rows = 2, cols = 2,
                shape = {2, 2},
                dtype = "complex128",
                real = {{1, 0}, {0, 1}},
                imag = {{0, 1}, {1, 0}}
            }
            local vals, vecs = luaswift.linalg.ceig(A)
            return vecs.dtype
            """)

        XCTAssertEqual(result.stringValue, "complex128")
    }

    // MARK: - Complex Determinant Tests

    func testCdetDiagonal() throws {
        // Determinant of diagonal matrix is product of diagonal entries
        // det([[2+i, 0], [0, 3-i]]) = (2+i)(3-i) = 6 - 2i + 3i - i² = 6 + i + 1 = 7 + i
        let result = try engine.evaluate("""
            local A = {
                shape = {2, 2},
                dtype = "complex128",
                real = {{2, 0}, {0, 3}},
                imag = {{1, 0}, {0, -1}}
            }
            local d = luaswift.linalg.cdet(A)
            return tostring(math.floor(d.re + 0.5)) .. "," .. tostring(math.floor(d.im + 0.5))
        """)
        XCTAssertEqual(result.stringValue, "7,1")
    }

    func testCdetSingular() throws {
        // Determinant of singular matrix is 0
        // [[1+i, 2+2i], [1, 2]] - second column is twice first (in real parts)
        let result = try engine.evaluate("""
            local A = {
                shape = {2, 2},
                dtype = "complex128",
                real = {{1, 2}, {1, 2}},
                imag = {{1, 2}, {0, 0}}
            }
            local d = luaswift.linalg.cdet(A)
            return d.re == 0 and d.im == 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Complex Inverse Tests

    func testCinvDiagonal() throws {
        // Inverse of diagonal matrix has reciprocals on diagonal
        // [[2, 0], [0, 2i]]^(-1) = [[0.5, 0], [0, -0.5i]]
        let result = try engine.evaluate("""
            local A = {
                shape = {2, 2},
                dtype = "complex128",
                real = {{2, 0}, {0, 0}},
                imag = {{0, 0}, {0, 2}}
            }
            local inv = luaswift.linalg.cinv(A)
            -- Flat array: element (i,j) is at index i*cols+j+1 (1-based)
            -- (0,0) -> 1, (1,1) -> 4
            local re00 = inv.real[1]
            local im00 = inv.imag[1]
            local re11 = inv.real[4]
            local im11 = inv.imag[4]
            -- Entry (0,0): 1/2 = 0.5 + 0i
            -- Entry (1,1): 1/(2i) = -i/2 = 0 - 0.5i
            local ok00 = math.abs(re00 - 0.5) < 1e-10 and math.abs(im00) < 1e-10
            local ok11 = math.abs(re11) < 1e-10 and math.abs(im11 + 0.5) < 1e-10
            return ok00 and ok11
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testCinvMulOriginal() throws {
        // A^(-1) * A = I for a complex matrix
        let result = try engine.evaluate("""
            local A = {
                shape = {2, 2},
                dtype = "complex128",
                real = {{1, 2}, {3, 4}},
                imag = {{0.5, -0.5}, {0.5, -0.5}}
            }
            local invA = luaswift.linalg.cinv(A)

            -- Flat array indexing: (i,j) -> i*2+j+1 for 2x2
            -- inv: (0,0)->1, (0,1)->2, (1,0)->3, (1,1)->4
            -- A uses nested arrays: A.real[row][col]

            -- Manual complex matrix multiplication for I = invA * A
            -- I[0,0] = invA[0,0]*A[0,0] + invA[0,1]*A[1,0]
            local I_re_00 = invA.real[1]*A.real[1][1] - invA.imag[1]*A.imag[1][1]
                          + invA.real[2]*A.real[2][1] - invA.imag[2]*A.imag[2][1]
            local I_im_00 = invA.real[1]*A.imag[1][1] + invA.imag[1]*A.real[1][1]
                          + invA.real[2]*A.imag[2][1] + invA.imag[2]*A.real[2][1]
            -- I[1,1] = invA[1,0]*A[0,1] + invA[1,1]*A[1,1]
            local I_re_11 = invA.real[3]*A.real[1][2] - invA.imag[3]*A.imag[1][2]
                          + invA.real[4]*A.real[2][2] - invA.imag[4]*A.imag[2][2]
            local I_im_11 = invA.real[3]*A.imag[1][2] + invA.imag[3]*A.real[1][2]
                          + invA.real[4]*A.imag[2][2] + invA.imag[4]*A.real[2][2]

            -- Identity should have 1s on diagonal with 0 imaginary
            local ok = math.abs(I_re_00 - 1) < 1e-10 and math.abs(I_im_00) < 1e-10
                   and math.abs(I_re_11 - 1) < 1e-10 and math.abs(I_im_11) < 1e-10
            return ok
        """)
        XCTAssertEqual(result.boolValue, true)
    }
}
#endif  // LUASWIFT_NUMERICSWIFT
