//
//  NumberTheoryModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
import XCTest
@testable import LuaSwift

final class NumberTheoryModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        ModuleRegistry.installModules(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Module Registration

    func testModuleRegistered() throws {
        let result = try engine.evaluate("return type(luaswift.numtheory)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathNamespace() throws {
        let result = try engine.evaluate("return type(math.numtheory)")
        XCTAssertEqual(result.stringValue, "table")
    }

    // MARK: - Euler's Totient Function

    func testEulerPhi1() throws {
        let result = try engine.evaluate("return math.numtheory.euler_phi(1)")
        XCTAssertEqual(result.numberValue, 1)
    }

    func testEulerPhi12() throws {
        // Numbers coprime to 12: 1, 5, 7, 11
        let result = try engine.evaluate("return math.numtheory.euler_phi(12)")
        XCTAssertEqual(result.numberValue, 4)
    }

    func testEulerPhiPrime() throws {
        // φ(p) = p-1 for prime p
        let result = try engine.evaluate("return math.numtheory.euler_phi(13)")
        XCTAssertEqual(result.numberValue, 12)
    }

    func testEulerPhiPrimePower() throws {
        // φ(p^k) = p^(k-1) * (p-1)
        // φ(8) = φ(2^3) = 2^2 * 1 = 4
        let result = try engine.evaluate("return math.numtheory.euler_phi(8)")
        XCTAssertEqual(result.numberValue, 4)
    }

    func testPhiAlias() throws {
        let result = try engine.evaluate("return math.numtheory.phi(12)")
        XCTAssertEqual(result.numberValue, 4)
    }

    // MARK: - Divisor Sigma Function

    func testDivisorSigma0() throws {
        // σ_0(12) = number of divisors = 6 (1,2,3,4,6,12)
        let result = try engine.evaluate("return math.numtheory.divisor_sigma(12, 0)")
        XCTAssertEqual(result.numberValue, 6)
    }

    func testDivisorSigma1() throws {
        // σ_1(12) = sum of divisors = 1+2+3+4+6+12 = 28
        let result = try engine.evaluate("return math.numtheory.divisor_sigma(12, 1)")
        XCTAssertEqual(result.numberValue, 28)
    }

    func testDivisorSigma2() throws {
        // σ_2(6) = 1^2 + 2^2 + 3^2 + 6^2 = 1 + 4 + 9 + 36 = 50
        let result = try engine.evaluate("return math.numtheory.divisor_sigma(6, 2)")
        XCTAssertEqual(result.numberValue, 50)
    }

    func testSigmaAlias() throws {
        let result = try engine.evaluate("return math.numtheory.sigma(12, 1)")
        XCTAssertEqual(result.numberValue, 28)
    }

    // MARK: - Möbius Function

    func testMobius1() throws {
        let result = try engine.evaluate("return math.numtheory.mobius(1)")
        XCTAssertEqual(result.numberValue, 1)
    }

    func testMobiusPrime() throws {
        // μ(p) = -1 for prime p
        let result = try engine.evaluate("return math.numtheory.mobius(7)")
        XCTAssertEqual(result.numberValue, -1)
    }

    func testMobiusSquarefree() throws {
        // μ(30) = μ(2*3*5) = (-1)^3 = -1
        let result = try engine.evaluate("return math.numtheory.mobius(30)")
        XCTAssertEqual(result.numberValue, -1)
    }

    func testMobiusSquarefreeEven() throws {
        // μ(6) = μ(2*3) = (-1)^2 = 1
        let result = try engine.evaluate("return math.numtheory.mobius(6)")
        XCTAssertEqual(result.numberValue, 1)
    }

    func testMobiusSquared() throws {
        // μ(12) = μ(4*3) = 0 (has squared factor 4)
        let result = try engine.evaluate("return math.numtheory.mobius(12)")
        XCTAssertEqual(result.numberValue, 0)
    }

    func testMuAlias() throws {
        let result = try engine.evaluate("return math.numtheory.mu(6)")
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - Liouville Function

    func testLiouville1() throws {
        let result = try engine.evaluate("return math.numtheory.liouville(1)")
        XCTAssertEqual(result.numberValue, 1)
    }

    func testLiouvillePrime() throws {
        // λ(p) = -1 for any prime
        let result = try engine.evaluate("return math.numtheory.liouville(7)")
        XCTAssertEqual(result.numberValue, -1)
    }

    func testLiouvillePrimePower() throws {
        // λ(8) = λ(2^3) = (-1)^3 = -1
        let result = try engine.evaluate("return math.numtheory.liouville(8)")
        XCTAssertEqual(result.numberValue, -1)
    }

    func testLiouville12() throws {
        // 12 = 2^2 * 3, Ω(12) = 2 + 1 = 3, λ(12) = (-1)^3 = -1
        let result = try engine.evaluate("return math.numtheory.liouville(12)")
        XCTAssertEqual(result.numberValue, -1)
    }

    func testLiouville4() throws {
        // 4 = 2^2, Ω(4) = 2, λ(4) = (-1)^2 = 1
        let result = try engine.evaluate("return math.numtheory.liouville(4)")
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - Carmichael Function

    func testCarmichael1() throws {
        let result = try engine.evaluate("return math.numtheory.carmichael(1)")
        XCTAssertEqual(result.numberValue, 1)
    }

    func testCarmichaelPrime() throws {
        // λ(p) = p - 1 for prime p
        let result = try engine.evaluate("return math.numtheory.carmichael(7)")
        XCTAssertEqual(result.numberValue, 6)
    }

    func testCarmichael8() throws {
        // λ(8) = λ(2^3) = 2^(3-2) = 2
        let result = try engine.evaluate("return math.numtheory.carmichael(8)")
        XCTAssertEqual(result.numberValue, 2)
    }

    func testCarmichael12() throws {
        // 12 = 4 * 3 = 2^2 * 3
        // λ(4) = 2, λ(3) = 2
        // λ(12) = lcm(2, 2) = 2
        let result = try engine.evaluate("return math.numtheory.carmichael(12)")
        XCTAssertEqual(result.numberValue, 2)
    }

    // MARK: - Chebyshev Functions

    func testChebyshevTheta10() throws {
        // θ(10) = log(2) + log(3) + log(5) + log(7)
        let result = try engine.evaluate("return math.numtheory.chebyshev_theta(10)")
        let expected = log(2.0) + log(3.0) + log(5.0) + log(7.0)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-10)
    }

    func testChebyshevPsi10() throws {
        // ψ(10) = Σ Λ(n) for n ≤ 10
        // Prime powers: 2,3,4,5,7,8,9
        // Λ(2)=log2, Λ(3)=log3, Λ(4)=log2, Λ(5)=log5, Λ(7)=log7, Λ(8)=log2, Λ(9)=log3
        let result = try engine.evaluate("return math.numtheory.chebyshev_psi(10)")
        let expected = 3*log(2.0) + 2*log(3.0) + log(5.0) + log(7.0)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-10)
    }

    func testThetaAlias() throws {
        let result = try engine.evaluate("return math.numtheory.theta(10)")
        let expected = log(2.0) + log(3.0) + log(5.0) + log(7.0)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-10)
    }

    func testPsiAlias() throws {
        let result = try engine.evaluate("return math.numtheory.psi(10)")
        let expected = 3*log(2.0) + 2*log(3.0) + log(5.0) + log(7.0)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-10)
    }

    // MARK: - Von Mangoldt Function

    func testMangoldt1() throws {
        // Λ(1) = 0
        let result = try engine.evaluate("return math.numtheory.mangoldt(1)")
        XCTAssertEqual(result.numberValue, 0)
    }

    func testMangoldtPrime() throws {
        // Λ(p) = log(p)
        let result = try engine.evaluate("return math.numtheory.mangoldt(7)")
        XCTAssertEqual(result.numberValue!, log(7.0), accuracy: 1e-10)
    }

    func testMangoldtPrimePower() throws {
        // Λ(9) = Λ(3^2) = log(3)
        let result = try engine.evaluate("return math.numtheory.mangoldt(9)")
        XCTAssertEqual(result.numberValue!, log(3.0), accuracy: 1e-10)
    }

    func testMangoldtComposite() throws {
        // Λ(6) = 0 (6 = 2*3, not a prime power)
        let result = try engine.evaluate("return math.numtheory.mangoldt(6)")
        XCTAssertEqual(result.numberValue, 0)
    }

    func testLambdaAlias() throws {
        let result = try engine.evaluate("return math.numtheory.Lambda(7)")
        XCTAssertEqual(result.numberValue!, log(7.0), accuracy: 1e-10)
    }

    // MARK: - Prime Counting Function

    func testPrimePi10() throws {
        // π(10) = 4 (primes: 2,3,5,7)
        let result = try engine.evaluate("return math.numtheory.prime_pi(10)")
        XCTAssertEqual(result.numberValue, 4)
    }

    func testPrimePi100() throws {
        // π(100) = 25
        let result = try engine.evaluate("return math.numtheory.prime_pi(100)")
        XCTAssertEqual(result.numberValue, 25)
    }

    func testPrimePi1000() throws {
        // π(1000) = 168
        let result = try engine.evaluate("return math.numtheory.prime_pi(1000)")
        XCTAssertEqual(result.numberValue, 168)
    }

    func testPiAlias() throws {
        let result = try engine.evaluate("return math.numtheory.pi(100)")
        XCTAssertEqual(result.numberValue, 25)
    }

    // MARK: - Primality Testing

    func testIsPrime2() throws {
        let result = try engine.evaluate("return math.numtheory.is_prime(2)")
        XCTAssertTrue(result.boolValue!)
    }

    func testIsPrime7() throws {
        let result = try engine.evaluate("return math.numtheory.is_prime(7)")
        XCTAssertTrue(result.boolValue!)
    }

    func testIsPrime1() throws {
        let result = try engine.evaluate("return math.numtheory.is_prime(1)")
        XCTAssertFalse(result.boolValue!)
    }

    func testIsPrime4() throws {
        let result = try engine.evaluate("return math.numtheory.is_prime(4)")
        XCTAssertFalse(result.boolValue!)
    }

    func testIsPrimeLargePrime() throws {
        // 997 is prime
        let result = try engine.evaluate("return math.numtheory.is_prime(997)")
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Prime Factorization

    func testFactor12() throws {
        // 12 = 2^2 * 3
        let result = try engine.evaluate("return math.numtheory.factor(12)")
        let table = result.tableValue
        XCTAssertEqual(table?["2"]?.numberValue, 2)  // 2^2
        XCTAssertEqual(table?["3"]?.numberValue, 1)  // 3^1
    }

    func testFactorPrime() throws {
        let result = try engine.evaluate("return math.numtheory.factor(17)")
        let table = result.tableValue
        XCTAssertEqual(table?["17"]?.numberValue, 1)
    }

    func testFactor1() throws {
        let result = try engine.evaluate("return math.numtheory.factor(1)")
        let table = result.tableValue
        XCTAssertNotNil(table)
        XCTAssertTrue(table?.isEmpty ?? false)  // Empty table
    }

    // MARK: - Primes Up To

    func testPrimesUpTo10() throws {
        let result = try engine.evaluate("return math.numtheory.primes_up_to(10)")
        let primes = result.arrayValue?.compactMap { $0.numberValue }
        XCTAssertEqual(primes, [2, 3, 5, 7])
    }

    func testPrimesUpTo30() throws {
        let result = try engine.evaluate("return #math.numtheory.primes_up_to(30)")
        XCTAssertEqual(result.numberValue, 10)  // 2,3,5,7,11,13,17,19,23,29
    }

    func testPrimesUpTo1() throws {
        let result = try engine.evaluate("return #math.numtheory.primes_up_to(1)")
        XCTAssertEqual(result.numberValue, 0)
    }

    // MARK: - GCD and LCM

    func testGCD() throws {
        let result = try engine.evaluate("return math.numtheory.gcd(48, 18)")
        XCTAssertEqual(result.numberValue, 6)
    }

    func testGCDCoprime() throws {
        let result = try engine.evaluate("return math.numtheory.gcd(17, 13)")
        XCTAssertEqual(result.numberValue, 1)
    }

    func testLCM() throws {
        let result = try engine.evaluate("return math.numtheory.lcm(4, 6)")
        XCTAssertEqual(result.numberValue, 12)
    }

    func testLCMCoprime() throws {
        let result = try engine.evaluate("return math.numtheory.lcm(7, 11)")
        XCTAssertEqual(result.numberValue, 77)
    }

    // MARK: - Edge Cases

    func testEulerPhiNil() throws {
        let result = try engine.evaluate("return math.numtheory.euler_phi(0)")
        XCTAssertTrue(result.isNil)
    }

    func testMobiusNil() throws {
        let result = try engine.evaluate("return math.numtheory.mobius(-5)")
        XCTAssertTrue(result.isNil)
    }

    func testChebyshevThetaSmall() throws {
        let result = try engine.evaluate("return math.numtheory.chebyshev_theta(1)")
        XCTAssertEqual(result.numberValue, 0)
    }
}
#endif  // LUASWIFT_NUMERICSWIFT
