//
//  SpecialModuleTests.swift
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

/// Tests for the Special Functions module (erf, beta, bessel).
@Suite("Special Functions Module Tests")
struct SpecialModuleTests {

    // MARK: - Setup

    private func createEngine() throws -> LuaEngine {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)
        return engine
    }

    // MARK: - Namespace Tests

    @Test("luaswift.special namespace exists")
    func testLuaswiftSpecialNamespace() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(luaswift.special)")
        #expect(result == .string("table"))
    }

    @Test("math.special namespace exists")
    func testMathSpecialNamespace() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special)")
        #expect(result == .string("table"))
    }

    // MARK: - Error Function Tests

    @Test("erf function exists")
    func testErfExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.erf)")
        #expect(result == .string("function"))
    }

    @Test("erf(0) = 0")
    func testErfZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erf(0)")
        #expect(result.numberValue! == 0.0)
    }

    @Test("erf(1) ≈ 0.8427")
    func testErfOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erf(1)")
        #expect(abs(result.numberValue! - 0.8427007929497148) < 1e-10)
    }

    @Test("erf(-1) ≈ -0.8427 (odd function)")
    func testErfNegOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erf(-1)")
        #expect(abs(result.numberValue! - (-0.8427007929497148)) < 1e-10)
    }

    @Test("erf(2) ≈ 0.9953")
    func testErfTwo() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erf(2)")
        #expect(abs(result.numberValue! - 0.9953222650189527) < 1e-10)
    }

    @Test("erfc function exists")
    func testErfcExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.erfc)")
        #expect(result == .string("function"))
    }

    @Test("erfc(0) = 1")
    func testErfcZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erfc(0)")
        #expect(result.numberValue! == 1.0)
    }

    @Test("erfc(1) ≈ 0.1573")
    func testErfcOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erfc(1)")
        #expect(abs(result.numberValue! - 0.15729920705028513) < 1e-10)
    }

    @Test("erf(x) + erfc(x) = 1 identity")
    func testErfErfcIdentity() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local x = 1.5
            return math.special.erf(x) + math.special.erfc(x)
            """)
        #expect(abs(result.numberValue! - 1.0) < 1e-14)
    }

    // MARK: - Beta Function Tests

    @Test("beta function exists")
    func testBetaExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.beta)")
        #expect(result == .string("function"))
    }

    @Test("beta(1, 1) = 1")
    func testBetaOneOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.beta(1, 1)")
        #expect(abs(result.numberValue! - 1.0) < 1e-10)
    }

    @Test("beta(2, 3) = 1/12")
    func testBetaTwoThree() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.beta(2, 3)")
        #expect(abs(result.numberValue! - 1.0/12.0) < 1e-10)
    }

    @Test("beta(a, b) = beta(b, a) symmetry")
    func testBetaSymmetry() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local a, b = 3.5, 2.7
            return math.abs(math.special.beta(a, b) - math.special.beta(b, a))
            """)
        #expect(result.numberValue! < 1e-14)
    }

    @Test("beta(n, 1) = 1/n")
    func testBetaNOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local n = 5
            return math.abs(math.special.beta(n, 1) - 1/n)
            """)
        #expect(result.numberValue! < 1e-14)
    }

    @Test("beta(0.5, 0.5) = pi")
    func testBetaHalfHalf() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.beta(0.5, 0.5)")
        #expect(abs(result.numberValue! - Double.pi) < 1e-10)
    }

    // MARK: - Incomplete Beta Tests

    @Test("betainc function exists")
    func testBetaincExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.betainc)")
        #expect(result == .string("function"))
    }

    @Test("betainc(a, b, 0) = 0")
    func testBetaincZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.betainc(2, 3, 0)")
        #expect(result.numberValue! == 0.0)
    }

    @Test("betainc(a, b, 1) = 1")
    func testBetaincOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.betainc(2, 3, 1)")
        #expect(result.numberValue! == 1.0)
    }

    @Test("betainc(1, 1, x) = x")
    func testBetaincOneOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.betainc(1, 1, 0.7)")
        #expect(abs(result.numberValue! - 0.7) < 1e-10)
    }

    @Test("betainc(2, 3, 0.5) ≈ 0.6875")
    func testBetaincTwoThree() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.betainc(2, 3, 0.5)")
        // I_0.5(2,3) = 0.6875
        #expect(abs(result.numberValue! - 0.6875) < 1e-6)
    }

    @Test("betainc symmetry: I_x(a,b) = 1 - I_{1-x}(b,a)")
    func testBetaincSymmetry() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local a, b, x = 2.5, 3.7, 0.4
            local lhs = math.special.betainc(a, b, x)
            local rhs = 1 - math.special.betainc(b, a, 1 - x)
            return math.abs(lhs - rhs)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    // MARK: - Bessel First Kind Tests

    @Test("j0 function exists")
    func testJ0Exists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.j0)")
        #expect(result == .string("function"))
    }

    @Test("j0(0) = 1")
    func testJ0Zero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.j0(0)")
        #expect(abs(result.numberValue! - 1.0) < 1e-10)
    }

    @Test("j0(1) ≈ 0.7652")
    func testJ0One() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.j0(1)")
        #expect(abs(result.numberValue! - 0.7651976865579666) < 1e-10)
    }

    @Test("j0(2.4048) ≈ 0 (first zero)")
    func testJ0FirstZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.j0(2.4048255576957727)")
        #expect(abs(result.numberValue!) < 1e-10)
    }

    @Test("j1 function exists")
    func testJ1Exists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.j1)")
        #expect(result == .string("function"))
    }

    @Test("j1(0) = 0")
    func testJ1Zero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.j1(0)")
        #expect(abs(result.numberValue!) < 1e-10)
    }

    @Test("j1(1) ≈ 0.4401")
    func testJ1One() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.j1(1)")
        #expect(abs(result.numberValue! - 0.44005058574493355) < 1e-10)
    }

    @Test("jn function exists")
    func testJnExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.jn)")
        #expect(result == .string("function"))
    }

    @Test("jn(0, x) = j0(x)")
    func testJnZeroEqualsJ0() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local x = 1.5
            return math.abs(math.special.jn(0, x) - math.special.j0(x))
            """)
        #expect(result.numberValue! < 1e-14)
    }

    @Test("jn(1, x) = j1(x)")
    func testJnOneEqualsJ1() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local x = 1.5
            return math.abs(math.special.jn(1, x) - math.special.j1(x))
            """)
        #expect(result.numberValue! < 1e-14)
    }

    @Test("jn(2, 3) ≈ 0.4861")
    func testJnTwoThree() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.jn(2, 3)")
        #expect(abs(result.numberValue! - 0.48609126058589107) < 1e-10)
    }

    @Test("Bessel recurrence: J_{n-1}(x) + J_{n+1}(x) = (2n/x) * J_n(x)")
    func testBesselRecurrence() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local n, x = 3, 2.0
            local lhs = math.special.jn(n-1, x) + math.special.jn(n+1, x)
            local rhs = (2*n/x) * math.special.jn(n, x)
            return math.abs(lhs - rhs)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    // MARK: - Bessel Second Kind Tests

    @Test("y0 function exists")
    func testY0Exists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.y0)")
        #expect(result == .string("function"))
    }

    @Test("y0(1) ≈ 0.0883")
    func testY0One() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.y0(1)")
        #expect(abs(result.numberValue! - 0.08825696421567697) < 1e-10)
    }

    @Test("y0(0.8936) ≈ 0 (first zero)")
    func testY0FirstZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.y0(0.8935769662791675)")
        #expect(abs(result.numberValue!) < 1e-6)
    }

    @Test("y0(x <= 0) returns -inf")
    func testY0NonPositive() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.y0(0)")
        #expect(result.numberValue! == -.infinity)
    }

    @Test("y1 function exists")
    func testY1Exists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.y1)")
        #expect(result == .string("function"))
    }

    @Test("y1(1) ≈ -0.7812")
    func testY1One() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.y1(1)")
        #expect(abs(result.numberValue! - (-0.7812128213002887)) < 1e-10)
    }

    @Test("yn function exists")
    func testYnExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.yn)")
        #expect(result == .string("function"))
    }

    @Test("yn(0, x) = y0(x)")
    func testYnZeroEqualsY0() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local x = 1.5
            return math.abs(math.special.yn(0, x) - math.special.y0(x))
            """)
        #expect(result.numberValue! < 1e-14)
    }

    @Test("yn(1, x) = y1(x)")
    func testYnOneEqualsY1() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local x = 1.5
            return math.abs(math.special.yn(1, x) - math.special.y1(x))
            """)
        #expect(result.numberValue! < 1e-14)
    }

    @Test("yn(2, 3) ≈ -0.1604")
    func testYnTwoThree() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.yn(2, 3)")
        #expect(abs(result.numberValue! - (-0.16040039348492377)) < 1e-10)
    }

    // MARK: - Existing Special Functions Tests

    @Test("math.special.gamma exists (re-exported from mathx)")
    func testGammaExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.gamma)")
        #expect(result == .string("function"))
    }

    @Test("math.special.gamma(5) = 24 (4!)")
    func testGammaFive() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.gamma(5)")
        #expect(abs(result.numberValue! - 24.0) < 1e-10)
    }

    @Test("math.special.lgamma exists (re-exported from mathx)")
    func testLgammaExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.lgamma)")
        #expect(result == .string("function"))
    }

    @Test("math.special.gammaln exists (alias for lgamma)")
    func testGammalnExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.gammaln)")
        #expect(result == .string("function"))
    }

    @Test("math.special.factorial exists (re-exported from mathx)")
    func testFactorialExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.factorial)")
        #expect(result == .string("function"))
    }

    // MARK: - Error Handling Tests

    @Test("erf throws on non-number")
    func testErfErrorHandling() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("return math.special.erf('string')")
        }
    }

    @Test("beta throws on non-numbers")
    func testBetaErrorHandling() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("return math.special.beta('a', 'b')")
        }
    }

    @Test("betainc throws on x out of range")
    func testBetaincRangeError() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("return math.special.betainc(2, 3, 1.5)")
        }
    }

    @Test("jn throws on missing arguments")
    func testJnErrorHandling() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("return math.special.jn(2)")
        }
    }
}
