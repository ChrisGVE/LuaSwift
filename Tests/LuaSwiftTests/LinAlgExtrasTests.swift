//
//  LinAlgExtrasTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Testing
@testable import LuaSwift

/// Tests for the LinAlg module extensions (solve_triangular, cho_solve, lu_solve, expm).
@Suite("LinAlg Extras Tests")
struct LinAlgExtrasTests {

    // MARK: - Setup

    private func createEngine() throws -> LuaEngine {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)
        return engine
    }

    // MARK: - solve_triangular Tests

    @Test("solve_triangular function exists")
    func testSolveTriangularExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(luaswift.linalg.solve_triangular)")
        #expect(result == .string("function"))
    }

    @Test("solve_triangular lower triangular system")
    func testSolveTriangularLower() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- L * x = b, L is lower triangular
            local L = linalg.matrix({{2, 0, 0}, {1, 3, 0}, {4, 5, 6}})
            local b = linalg.vector({4, 10, 49})
            local x = linalg.solve_triangular(L, b, {lower = true})
            -- Verify L * x = b
            local Lx = L:dot(x)
            return math.abs(Lx:get(1, 1) - 4) + math.abs(Lx:get(2, 1) - 10) + math.abs(Lx:get(3, 1) - 49)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("solve_triangular upper triangular system")
    func testSolveTriangularUpper() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- U * x = b, U is upper triangular
            local U = linalg.matrix({{2, 1, 4}, {0, 3, 5}, {0, 0, 6}})
            local b = linalg.vector({20, 31, 18})
            local x = linalg.solve_triangular(U, b, {lower = false})
            -- Verify U * x = b
            local Ux = U:dot(x)
            return math.abs(Ux:get(1, 1) - 20) + math.abs(Ux:get(2, 1) - 31) + math.abs(Ux:get(3, 1) - 18)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("solve_triangular transposed system")
    func testSolveTriangularTransposed() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- L^T * x = b
            local L = linalg.matrix({{2, 0, 0}, {1, 3, 0}, {4, 5, 6}})
            local b = linalg.vector({9, 27, 18})
            local x = linalg.solve_triangular(L, b, {lower = true, trans = true})
            -- Verify L^T * x = b
            local Lt = L:transpose()
            local Ltx = Lt:dot(x)
            return math.abs(Ltx:get(1, 1) - 9) + math.abs(Ltx:get(2, 1) - 27) + math.abs(Ltx:get(3, 1) - 18)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("solve_triangular default is lower")
    func testSolveTriangularDefaultLower() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local L = linalg.matrix({{1, 0}, {2, 1}})
            local b = linalg.vector({3, 8})
            local x = linalg.solve_triangular(L, b)  -- no options, defaults to lower
            return math.abs(x:get(1, 1) - 3) + math.abs(x:get(2, 1) - 2)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    // MARK: - cho_solve Tests

    @Test("cho_solve function exists")
    func testChoSolveExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(luaswift.linalg.cho_solve)")
        #expect(result == .string("function"))
    }

    @Test("cho_solve with Cholesky factor")
    func testChoSolveBasic() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- A = L * L^T (positive definite)
            -- A = {{4, 2}, {2, 10}}
            local A = linalg.matrix({{4, 2}, {2, 10}})
            local L = A:chol()  -- Get Cholesky factor
            local b = linalg.vector({10, 26})
            local x = linalg.cho_solve(L, b)
            -- Verify A * x = b
            local Ax = A:dot(x)
            return math.abs(Ax:get(1, 1) - 10) + math.abs(Ax:get(2, 1) - 26)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("cho_solve 3x3 system")
    func testChoSolve3x3() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- Positive definite matrix
            local A = linalg.matrix({{4, 2, 2}, {2, 10, 7}, {2, 7, 21}})
            local L = A:chol()
            local b = linalg.vector({8, 19, 30})
            local x = linalg.cho_solve(L, b)
            -- Verify solution
            local Ax = A:dot(x)
            return math.abs(Ax:get(1, 1) - 8) + math.abs(Ax:get(2, 1) - 19) + math.abs(Ax:get(3, 1) - 30)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    // MARK: - lu_solve Tests

    @Test("lu_solve function exists")
    func testLuSolveExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(luaswift.linalg.lu_solve)")
        #expect(result == .string("function"))
    }

    @Test("lu_solve with simple system")
    func testLuSolveBasic() throws {
        let engine = try createEngine()
        // Test with identity-like matrix where LU is trivial
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- Use a simple diagonal matrix for testing
            local A = linalg.diagonal({2, 3, 4})
            local L, U, P = A:lu()
            local b = linalg.vector({2, 6, 12})
            local x = linalg.lu_solve(L, U, P, b)
            -- Solution should be {1, 2, 3}
            return math.abs(x:get(1, 1) - 1) + math.abs(x:get(2, 1) - 2) + math.abs(x:get(3, 1) - 3)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("lu_solve 2x2 system")
    func testLuSolve2x2() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- Simple 2x2 system
            local A = linalg.matrix({{2, 0}, {0, 3}})
            local L, U, P = A:lu()
            local b = linalg.vector({4, 9})
            local x = linalg.lu_solve(L, U, P, b)
            -- Solution should be {2, 3}
            return math.abs(x:get(1, 1) - 2) + math.abs(x:get(2, 1) - 3)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    // MARK: - expm Tests

    @Test("expm function exists")
    func testExpmExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(luaswift.linalg.expm)")
        #expect(result == .string("function"))
    }

    @Test("expm method exists on matrix")
    func testExpmMethodExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.matrix({{1, 0}, {0, 1}})
            return type(A.expm)
            """)
        #expect(result == .string("function"))
    }

    @Test("expm of zero matrix is identity")
    func testExpmZeroMatrix() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local Z = linalg.zeros(3, 3)
            local E = Z:expm()
            local I = linalg.eye(3)
            -- exp(0) should be I
            local diff = 0
            for i = 1, 3 do
                for j = 1, 3 do
                    diff = diff + math.abs(E:get(i, j) - I:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("expm of identity matrix")
    func testExpmIdentity() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local I = linalg.eye(2)
            local E = I:expm()
            -- exp(I) = e * I
            local e = math.exp(1)
            return math.abs(E:get(1, 1) - e) + math.abs(E:get(1, 2)) +
                   math.abs(E:get(2, 1)) + math.abs(E:get(2, 2) - e)
            """)
        #expect(result.numberValue! < 1e-5)
    }

    @Test("expm of diagonal matrix")
    func testExpmDiagonal() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local D = linalg.diagonal({1, 2, 3})
            local E = D:expm()
            -- exp(diag(a, b, c)) = diag(e^a, e^b, e^c)
            local e1, e2, e3 = math.exp(1), math.exp(2), math.exp(3)
            return math.abs(E:get(1, 1) - e1) + math.abs(E:get(2, 2) - e2) + math.abs(E:get(3, 3) - e3) +
                   math.abs(E:get(1, 2)) + math.abs(E:get(1, 3)) +
                   math.abs(E:get(2, 1)) + math.abs(E:get(2, 3)) +
                   math.abs(E:get(3, 1)) + math.abs(E:get(3, 2))
            """)
        #expect(result.numberValue! < 1e-3)
    }

    @Test("expm nilpotent matrix")
    func testExpmNilpotent() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- N is nilpotent: N^2 = 0
            -- exp(N) = I + N
            local N = linalg.matrix({{0, 1}, {0, 0}})
            local E = N:expm()
            -- Expected: {{1, 1}, {0, 1}}
            return math.abs(E:get(1, 1) - 1) + math.abs(E:get(1, 2) - 1) +
                   math.abs(E:get(2, 1) - 0) + math.abs(E:get(2, 2) - 1)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("expm rotation matrix")
    func testExpmRotation() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- A generates rotation: exp(theta * J) where J = {{0, -1}, {1, 0}}
            local theta = math.pi / 4  -- 45 degrees
            local J = linalg.matrix({{0, -theta}, {theta, 0}})
            local R = J:expm()
            -- Expected: rotation matrix {{cos(theta), -sin(theta)}, {sin(theta), cos(theta)}}
            local c, s = math.cos(theta), math.sin(theta)
            return math.abs(R:get(1, 1) - c) + math.abs(R:get(1, 2) + s) +
                   math.abs(R:get(2, 1) - s) + math.abs(R:get(2, 2) - c)
            """)
        #expect(result.numberValue! < 1e-6)
    }

    @Test("expm scaling property: exp(s*A) = exp(A)^s for s=2")
    func testExpmScaling() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.matrix({{0.1, 0.2}, {0.3, 0.4}})
            -- exp(2*A) should equal exp(A) * exp(A)
            local E_2A = (A * 2):expm()
            local E_A = A:expm()
            local E_A_squared = E_A:dot(E_A)

            local diff = 0
            for i = 1, 2 do
                for j = 1, 2 do
                    diff = diff + math.abs(E_2A:get(i, j) - E_A_squared:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-8)
    }

    // MARK: - Error Handling Tests

    @Test("solve_triangular error on non-square")
    func testSolveTriangularNonSquare() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("""
                local linalg = luaswift.linalg
                local A = linalg.matrix({{1, 2, 3}, {4, 5, 6}})
                local b = linalg.vector({1, 2})
                return linalg.solve_triangular(A, b)
                """)
        }
    }

    @Test("cho_solve error on non-square")
    func testChoSolveNonSquare() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("""
                local linalg = luaswift.linalg
                local L = linalg.matrix({{1, 2}, {3, 4}, {5, 6}})
                local b = linalg.vector({1, 2, 3})
                return linalg.cho_solve(L, b)
                """)
        }
    }

    @Test("expm error on non-square")
    func testExpmNonSquare() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("""
                local linalg = luaswift.linalg
                local A = linalg.matrix({{1, 2, 3}, {4, 5, 6}})
                return A:expm()
                """)
        }
    }

    // MARK: - logm Tests

    @Test("logm function exists")
    func testLogmExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(luaswift.linalg.logm)")
        #expect(result == .string("function"))
    }

    @Test("logm method exists on matrix")
    func testLogmMethodExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.matrix({{1, 0}, {0, 1}})
            return type(A.logm)
            """)
        #expect(result == .string("function"))
    }

    @Test("logm of identity is zero")
    func testLogmIdentity() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local I = linalg.eye(3)
            local L = I:logm()
            -- log(I) should be zero matrix
            local diff = 0
            for i = 1, 3 do
                for j = 1, 3 do
                    diff = diff + math.abs(L:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("logm of e*I is I")
    func testLogmScaledIdentity() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local e = math.exp(1)
            local eI = linalg.diagonal({e, e, e})
            local L = eI:logm()
            -- log(e*I) = I
            local diff = 0
            for i = 1, 3 do
                for j = 1, 3 do
                    local expected = (i == j) and 1 or 0
                    diff = diff + math.abs(L:get(i, j) - expected)
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-6)
    }

    @Test("logm(expm(A)) = A for symmetric matrix")
    func testLogmExpmInverse() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- Use a symmetric positive definite matrix
            local A = linalg.matrix({{0.1, 0.05}, {0.05, 0.1}})
            local E = A:expm()
            local L = E:logm()
            -- L should approximately equal A
            local diff = 0
            for i = 1, 2 do
                for j = 1, 2 do
                    diff = diff + math.abs(L:get(i, j) - A:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-6)
    }

    // MARK: - sqrtm Tests

    @Test("sqrtm function exists")
    func testSqrtmExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(luaswift.linalg.sqrtm)")
        #expect(result == .string("function"))
    }

    @Test("sqrtm of identity is identity")
    func testSqrtmIdentity() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local I = linalg.eye(3)
            local S = I:sqrtm()
            -- sqrt(I) should be I
            local diff = 0
            for i = 1, 3 do
                for j = 1, 3 do
                    diff = diff + math.abs(S:get(i, j) - I:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("sqrtm(A) squared equals A")
    func testSqrtmSquared() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- Use a diagonal matrix with positive entries
            local A = linalg.diagonal({4, 9, 16})
            local S = A:sqrtm()
            local S2 = S:dot(S)
            -- S^2 should equal A
            local diff = 0
            for i = 1, 3 do
                for j = 1, 3 do
                    diff = diff + math.abs(S2:get(i, j) - A:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-8)
    }

    @Test("sqrtm of 4*I is 2*I")
    func testSqrtmScaledIdentity() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.diagonal({4, 4})
            local S = A:sqrtm()
            -- sqrt(4*I) = 2*I
            return math.abs(S:get(1, 1) - 2) + math.abs(S:get(2, 2) - 2) +
                   math.abs(S:get(1, 2)) + math.abs(S:get(2, 1))
            """)
        #expect(result.numberValue! < 1e-10)
    }

    // MARK: - funm Tests

    @Test("funm function exists")
    func testFunmExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(luaswift.linalg.funm)")
        #expect(result == .string("function"))
    }

    @Test("funm exp equals expm")
    func testFunmExp() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.diagonal({0.1, 0.2, 0.3})
            local E1 = A:expm()
            local E2 = A:funm("exp")
            -- Both should be equal
            local diff = 0
            for i = 1, 3 do
                for j = 1, 3 do
                    diff = diff + math.abs(E1:get(i, j) - E2:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-6)
    }

    @Test("funm log equals logm")
    func testFunmLog() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.diagonal({2, 3, 4})
            local L1 = A:logm()
            local L2 = A:funm("log")
            -- Both should be equal
            local diff = 0
            for i = 1, 3 do
                for j = 1, 3 do
                    diff = diff + math.abs(L1:get(i, j) - L2:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("funm sqrt equals sqrtm")
    func testFunmSqrt() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.diagonal({4, 9, 16})
            local S1 = A:sqrtm()
            local S2 = A:funm("sqrt")
            -- Both should be equal
            local diff = 0
            for i = 1, 3 do
                for j = 1, 3 do
                    diff = diff + math.abs(S1:get(i, j) - S2:get(i, j))
                end
            end
            return diff
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("funm sin on diagonal matrix")
    func testFunmSin() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.diagonal({0, math.pi/2, math.pi})
            local S = A:funm("sin")
            -- sin(diag(0, pi/2, pi)) = diag(0, 1, 0)
            return math.abs(S:get(1, 1) - 0) + math.abs(S:get(2, 2) - 1) + math.abs(S:get(3, 3) - 0)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("funm cos on diagonal matrix")
    func testFunmCos() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = linalg.diagonal({0, math.pi/2, math.pi})
            local C = A:funm("cos")
            -- cos(diag(0, pi/2, pi)) = diag(1, 0, -1)
            return math.abs(C:get(1, 1) - 1) + math.abs(C:get(2, 2) - 0) + math.abs(C:get(3, 3) + 1)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("funm with unsupported function throws error")
    func testFunmUnsupported() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("""
                local linalg = luaswift.linalg
                local A = linalg.eye(2)
                return A:funm("unknown_function")
                """)
        }
    }

    @Test("logm error on non-positive eigenvalues")
    func testLogmNonPositive() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("""
                local linalg = luaswift.linalg
                local A = linalg.diagonal({1, -1})  -- Has negative eigenvalue
                return A:logm()
                """)
        }
    }

    @Test("sqrtm error on negative eigenvalues")
    func testSqrtmNegative() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("""
                local linalg = luaswift.linalg
                local A = linalg.diagonal({4, -9})  -- Has negative eigenvalue
                return A:sqrtm()
                """)
        }
    }
}
