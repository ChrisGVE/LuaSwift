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

    // MARK: - Modified Bessel Function Tests (I_n and K_n)

    @Test("besseli function exists")
    func testBesseliExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.besseli)")
        #expect(result == .string("function"))
    }

    @Test("besseli(0, 0) = 1")
    func testBesseliZeroZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besseli(0, 0)")
        #expect(result.numberValue! == 1.0)
    }

    @Test("besseli(1, 0) = 0")
    func testBesseliOneZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besseli(1, 0)")
        #expect(result.numberValue! == 0.0)
    }

    @Test("besseli(0, 1) ≈ 1.2661")
    func testBesseliZeroOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besseli(0, 1)")
        // I_0(1) ≈ 1.2660658777520082
        #expect(abs(result.numberValue! - 1.2660658777520082) < 1e-8)
    }

    @Test("besseli(1, 1) ≈ 0.5652")
    func testBesseliOneOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besseli(1, 1)")
        // I_1(1) ≈ 0.5651591039924851
        #expect(abs(result.numberValue! - 0.5651591039924851) < 1e-8)
    }

    @Test("besseli(2, 2) ≈ 0.6889")
    func testBesseliTwoTwo() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besseli(2, 2)")
        // I_2(2) ≈ 0.6889484476987382
        #expect(abs(result.numberValue! - 0.6889484476987382) < 1e-8)
    }

    @Test("besselk function exists")
    func testBesselkExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.besselk)")
        #expect(result == .string("function"))
    }

    @Test("besselk(0, 1) ≈ 0.4210")
    func testBesselkZeroOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besselk(0, 1)")
        // K_0(1) ≈ 0.42102443824070834
        #expect(abs(result.numberValue! - 0.42102443824070834) < 1e-6)
    }

    @Test("besselk(1, 1) ≈ 0.6019")
    func testBesselkOneOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besselk(1, 1)")
        // K_1(1) ≈ 0.6019072301972346
        #expect(abs(result.numberValue! - 0.6019072301972346) < 1e-6)
    }

    @Test("besselk(2, 2) ≈ 0.2538")
    func testBesselkTwoTwo() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besselk(2, 2)")
        // K_2(2) ≈ 0.25375975456605045
        #expect(abs(result.numberValue! - 0.25375975456605045) < 1e-6)
    }

    @Test("besselk(x <= 0) returns +inf")
    func testBesselkNonPositive() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besselk(0, 0)")
        #expect(result.numberValue!.isInfinite)
    }

    @Test("besseli(0, 5) ≈ 27.2399")
    func testBesseliLargeX() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besseli(0, 5)")
        // I_0(5) ≈ 27.239871823604445
        #expect(abs(result.numberValue! - 27.239871823604445) < 1e-4)
    }

    @Test("besselk(0, 5) ≈ 0.003691")
    func testBesselkLargeX() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.besselk(0, 5)")
        // K_0(5) ≈ 0.0036910982720826034
        #expect(abs(result.numberValue! - 0.0036910982720826034) < 1e-6)
    }

    @Test("besseli recurrence: I_{n+1}(x) = I_{n-1}(x) - (2n/x)*I_n(x)")
    func testBesseliRecurrence() throws {
        let engine = try createEngine()
        // Test at x = 2: I_2(2) should satisfy the recurrence
        // Actually recurrence is: I_{n-1}(x) - I_{n+1}(x) = (2n/x) * I_n(x)
        // So: I_0 - I_2 ≈ (2*1/2) * I_1 = I_1
        let result = try engine.evaluate("""
            local i0 = math.special.besseli(0, 2)
            local i1 = math.special.besseli(1, 2)
            local i2 = math.special.besseli(2, 2)
            -- Recurrence: I_{n-1}(x) - I_{n+1}(x) = (2n/x) * I_n(x)
            local lhs = i0 - i2
            local rhs = (2 * 1 / 2) * i1
            return math.abs(lhs - rhs)
        """)
        #expect(result.numberValue! < 1e-8)
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

    // MARK: - Digamma Function Tests

    @Test("digamma function exists")
    func testDigammaExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.digamma)")
        #expect(result == .string("function"))
    }

    @Test("psi is alias for digamma")
    func testPsiAlias() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.psi == math.special.digamma")
        #expect(result == .bool(true))
    }

    @Test("digamma(1) ≈ -0.5772 (negative Euler-Mascheroni)")
    func testDigammaOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.digamma(1)")
        // ψ(1) = -γ ≈ -0.5772156649015329
        #expect(abs(result.numberValue! - (-0.5772156649015329)) < 1e-9)
    }

    @Test("digamma(2) = digamma(1) + 1 (recurrence)")
    func testDigammaRecurrence() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local d1 = math.special.digamma(1)
            local d2 = math.special.digamma(2)
            return math.abs(d2 - (d1 + 1)) < 1e-10
            """)
        #expect(result == .bool(true))
    }

    @Test("digamma(0.5) ≈ -1.9635")
    func testDigammaHalf() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.digamma(0.5)")
        // ψ(0.5) = -γ - 2*ln(2) ≈ -1.9635100260214235
        #expect(abs(result.numberValue! - (-1.9635100260214235)) < 1e-10)
    }

    @Test("digamma(5) ≈ 1.5061")
    func testDigammaFive() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.digamma(5)")
        // ψ(5) = 1 + 1/2 + 1/3 + 1/4 - γ ≈ 1.5061176684318
        #expect(abs(result.numberValue! - 1.5061176684318) < 1e-9)
    }

    // MARK: - Inverse Error Function Tests

    @Test("erfinv function exists")
    func testErfinvExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.erfinv)")
        #expect(result == .string("function"))
    }

    @Test("erfinv(0) = 0")
    func testErfinvZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erfinv(0)")
        #expect(result.numberValue! == 0.0)
    }

    @Test("erfinv(erf(x)) ≈ x round-trip")
    func testErfinvRoundTrip() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local x = 0.5
            local y = math.special.erf(x)
            local xBack = math.special.erfinv(y)
            return math.abs(xBack - x) < 1e-6
            """)
        #expect(result == .bool(true))
    }

    @Test("erfinv(0.5) ≈ 0.4769")
    func testErfinvHalf() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erfinv(0.5)")
        #expect(abs(result.numberValue! - 0.4769362762044699) < 1e-4)
    }

    @Test("erfcinv function exists")
    func testErfcinvExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.erfcinv)")
        #expect(result == .string("function"))
    }

    @Test("erfcinv(1) = 0")
    func testErfcinvOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.erfcinv(1)")
        #expect(abs(result.numberValue!) < 1e-10)
    }

    @Test("erfcinv(erfc(x)) ≈ x round-trip")
    func testErfcinvRoundTrip() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local x = 0.5
            local y = math.special.erfc(x)
            local xBack = math.special.erfcinv(y)
            return math.abs(xBack - x) < 1e-6
            """)
        #expect(result == .bool(true))
    }

    // MARK: - Incomplete Gamma Function Tests

    @Test("gammainc function exists")
    func testGammaincExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.gammainc)")
        #expect(result == .string("function"))
    }

    @Test("gammaincc function exists")
    func testGammainccExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.gammaincc)")
        #expect(result == .string("function"))
    }

    @Test("gammainc(1, 1) ≈ 0.6321 (1 - exp(-1))")
    func testGammaincOneOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.gammainc(1, 1)")
        // P(1, 1) = 1 - e^(-1) ≈ 0.6321205588285577
        #expect(abs(result.numberValue! - 0.6321205588285577) < 1e-10)
    }

    @Test("gammaincc(1, 1) ≈ 0.3679 (exp(-1))")
    func testGammainccOneOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.gammaincc(1, 1)")
        // Q(1, 1) = e^(-1) ≈ 0.3678794411714423
        #expect(abs(result.numberValue! - 0.3678794411714423) < 1e-10)
    }

    @Test("gammainc + gammaincc = 1 identity")
    func testGammaincIdentity() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local a, x = 2.5, 3.0
            local p = math.special.gammainc(a, x)
            local q = math.special.gammaincc(a, x)
            return math.abs((p + q) - 1) < 1e-10
            """)
        #expect(result == .bool(true))
    }

    @Test("gammainc(a, 0) = 0")
    func testGammaincZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.gammainc(2, 0)")
        #expect(result.numberValue! == 0.0)
    }

    @Test("gammainc(0.5, 1) ≈ 0.8427 (related to erf)")
    func testGammaincHalfOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.gammainc(0.5, 1)")
        // P(0.5, 1) = erf(1) ≈ 0.8427007929497148
        #expect(abs(result.numberValue! - 0.8427007929497148) < 1e-6)
    }

    // MARK: - Elliptic Integral Tests

    @Test("ellipk function exists")
    func testEllipkExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.ellipk)")
        #expect(result == .string("function"))
    }

    @Test("ellipk(0) = π/2")
    func testEllipkZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.ellipk(0)")
        #expect(abs(result.numberValue! - Double.pi / 2) < 1e-10)
    }

    @Test("ellipk(0.5) ≈ 1.8541")
    func testEllipkHalf() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.ellipk(0.5)")
        // K(0.5) ≈ 1.8540746773013719
        #expect(abs(result.numberValue! - 1.8540746773013719) < 1e-8)
    }

    @Test("ellipk(0.99) ≈ 3.6956")
    func testEllipkNearOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.ellipk(0.99)")
        // K(0.99) ≈ 3.6956373629898746
        #expect(abs(result.numberValue! - 3.6956373629898746) < 1e-5)
    }

    @Test("ellipk throws for m >= 1")
    func testEllipkRangeError() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("return math.special.ellipk(1)")
        }
    }

    @Test("ellipe function exists")
    func testEllipeExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.ellipe)")
        #expect(result == .string("function"))
    }

    @Test("ellipe(0) = π/2")
    func testEllipeZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.ellipe(0)")
        #expect(abs(result.numberValue! - Double.pi / 2) < 1e-10)
    }

    @Test("ellipe(1) = 1")
    func testEllipeOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.ellipe(1)")
        #expect(abs(result.numberValue! - 1.0) < 1e-10)
    }

    @Test("ellipe(0.5) ≈ 1.3506")
    func testEllipeHalf() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.ellipe(0.5)")
        // E(0.5) ≈ 1.3506438810476755
        #expect(abs(result.numberValue! - 1.3506438810476755) < 1e-8)
    }

    @Test("Legendre relation: K(m)*E(1-m) + E(m)*K(1-m) - K(m)*K(1-m) = π/2")
    func testLegendreRelation() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local m = 0.3
            local Km = math.special.ellipk(m)
            local Em = math.special.ellipe(m)
            local K1m = math.special.ellipk(1 - m)
            local E1m = math.special.ellipe(1 - m)
            local lhs = Km * E1m + Em * K1m - Km * K1m
            return math.abs(lhs - math.pi / 2)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    // MARK: - Riemann Zeta Function Tests

    @Test("zeta function exists")
    func testZetaExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.zeta)")
        #expect(result == .string("function"))
    }

    @Test("zeta(2) = π²/6")
    func testZetaTwo() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.zeta(2)")
        // ζ(2) = π²/6 ≈ 1.6449340668482264
        #expect(abs(result.numberValue! - Double.pi * Double.pi / 6) < 1e-4)
    }

    @Test("zeta(4) = π⁴/90")
    func testZetaFour() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.zeta(4)")
        // ζ(4) = π⁴/90 ≈ 1.0823232337111381
        let expected = pow(Double.pi, 4) / 90
        #expect(abs(result.numberValue! - expected) < 1e-6)
    }

    @Test("zeta(0) = -1/2")
    func testZetaZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.zeta(0)")
        #expect(abs(result.numberValue! - (-0.5)) < 1e-10)
    }

    @Test("zeta(1) = infinity (pole)")
    func testZetaOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.zeta(1)")
        #expect(result.numberValue!.isInfinite)
    }

    @Test("zeta(-2) = 0 (trivial zero)")
    func testZetaNegTwo() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.zeta(-2)")
        #expect(abs(result.numberValue!) < 1e-10)
    }

    @Test("zeta(3) ≈ 1.2021 (Apéry's constant)")
    func testZetaThree() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.zeta(3)")
        // ζ(3) ≈ 1.202056903159594 (Apéry's constant)
        #expect(abs(result.numberValue! - 1.202056903159594) < 1e-5)
    }

    // MARK: - Lambert W Function Tests

    @Test("lambertw function exists")
    func testLambertwExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.lambertw)")
        #expect(result == .string("function"))
    }

    @Test("lambertw(0) = 0")
    func testLambertwZero() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.lambertw(0)")
        #expect(abs(result.numberValue!) < 1e-10)
    }

    @Test("lambertw(e) = 1")
    func testLambertwE() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.lambertw(math.exp(1))")
        #expect(abs(result.numberValue! - 1.0) < 1e-10)
    }

    @Test("lambertw(1) ≈ 0.5671")
    func testLambertwOne() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.lambertw(1)")
        // W(1) ≈ 0.5671432904097839
        #expect(abs(result.numberValue! - 0.5671432904097839) < 1e-8)
    }

    @Test("W(x) * exp(W(x)) = x identity")
    func testLambertwIdentity() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local x = 2.5
            local w = math.special.lambertw(x)
            return math.abs(w * math.exp(w) - x)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("lambertw(-1/e) = -1")
    func testLambertwBranchPoint() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.lambertw(-1 / math.exp(1))")
        #expect(abs(result.numberValue! - (-1.0)) < 1e-8)
    }

    @Test("lambertw throws for x < -1/e")
    func testLambertwRangeError() throws {
        let engine = try createEngine()
        #expect(throws: Error.self) {
            try engine.evaluate("return math.special.lambertw(-1)")
        }
    }

    @Test("lambertw(100) ≈ 3.3856")
    func testLambertwLarge() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.lambertw(100)")
        // W(100) ≈ 3.3856301402900502
        #expect(abs(result.numberValue! - 3.3856301402900502) < 1e-6)
    }

    // MARK: - Complex Gamma Function Tests (Task 184)

    @Test("cgamma function exists")
    func testCgammaExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.cgamma)")
        #expect(result == .string("function"))
    }

    @Test("cgamma(5) = 4! = 24")
    func testCgammaRealPositiveInteger() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.cgamma(5)")
        #expect(abs(result.numberValue! - 24.0) < 1e-10)
    }

    @Test("cgamma(0.5) = sqrt(pi)")
    func testCgammaHalf() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return math.special.cgamma(0.5)")
        let sqrtPi = 1.7724538509055159  // sqrt(pi)
        #expect(abs(result.numberValue! - sqrtPi) < 1e-10)
    }

    @Test("cgamma(1+i) - complex result")
    func testCgammaComplexInput() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local z = {re = 1, im = 1}
            local g = math.special.cgamma(z)
            return g
            """)
        // Gamma(1+i) ≈ 0.498015668 - 0.154949828i
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            Issue.record("Expected complex result")
            return
        }
        #expect(abs(re - 0.498015668) < 1e-6)
        #expect(abs(im - (-0.154949828)) < 1e-6)
    }

    @Test("cgamma satisfies Gamma(z+1) = z*Gamma(z)")
    func testCgammaRecurrence() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local z = {re = 2.5, im = 1.3}
            local gz = math.special.cgamma(z)
            local gz1 = math.special.cgamma({re = z.re + 1, im = z.im})
            -- Check if gz1 ≈ z * gz
            local expected_re = z.re * gz.re - z.im * gz.im
            local expected_im = z.re * gz.im + z.im * gz.re
            local err_re = math.abs(gz1.re - expected_re)
            local err_im = math.abs(gz1.im - expected_im)
            return math.max(err_re, err_im)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("cgamma(i) - pure imaginary input")
    func testCgammaPureImaginary() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local g = math.special.cgamma({re = 0, im = 1})
            return g
            """)
        // Gamma(i) ≈ -0.1549498283 - 0.498015668i
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            Issue.record("Expected complex result")
            return
        }
        #expect(abs(re - (-0.1549498283)) < 1e-6)
        #expect(abs(im - (-0.498015668)) < 1e-6)
    }

    @Test("clgamma function exists")
    func testClgammaExists() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("return type(math.special.clgamma)")
        #expect(result == .string("function"))
    }

    @Test("clgamma(5) = log(24)")
    func testClgammaRealPositive() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local lg = math.special.clgamma(5)
            return lg.re
            """)
        let expected = log(24.0)
        #expect(abs(result.numberValue! - expected) < 1e-10)
    }

    @Test("clgamma satisfies exp(clgamma(z)) = cgamma(z)")
    func testClgammaExpRelation() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local z = {re = 2.0, im = 1.5}
            local g = math.special.cgamma(z)
            local lg = math.special.clgamma(z)
            -- exp(lg) should equal g
            local exp_re = math.exp(lg.re) * math.cos(lg.im)
            local exp_im = math.exp(lg.re) * math.sin(lg.im)
            local err_re = math.abs(exp_re - g.re)
            local err_im = math.abs(exp_im - g.im)
            return math.max(err_re, err_im)
            """)
        #expect(result.numberValue! < 1e-10)
    }

    @Test("clgamma(1+i) - complex input")
    func testClgammaComplexInput() throws {
        let engine = try createEngine()
        let result = try engine.evaluate("""
            local z = {re = 1, im = 1}
            local lg = math.special.clgamma(z)
            return lg
            """)
        // log(Gamma(1+i)) - verify it returns a complex result
        guard let table = result.tableValue,
              table["re"]?.numberValue != nil,
              table["im"]?.numberValue != nil else {
            Issue.record("Expected complex result with re and im")
            return
        }
    }
}
