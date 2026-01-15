//
//  NumberTheoryModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import NumericSwift

/// Swift-backed number theory module for LuaSwift.
///
/// Provides number-theoretic arithmetic functions:
/// - Euler's totient function: euler_phi(n)
/// - Divisor/sigma function: divisor_sigma(n, k)
/// - Möbius function: mobius(n)
/// - Liouville function: liouville(n)
/// - Carmichael function: carmichael(n)
/// - Chebyshev functions: chebyshev_theta(x), chebyshev_psi(x)
/// - Von Mangoldt function: mangoldt(n)
/// - Prime counting function: prime_pi(x)
/// - Primality testing: is_prime(n)
/// - Prime factorization: factor(n)
///
/// These functions are added to the `math.numtheory` namespace.
///
/// ## Usage
///
/// ```lua
/// local nt = math.numtheory
///
/// -- Euler's totient: count of integers 1..n coprime to n
/// local phi = nt.euler_phi(12)  -- 4
///
/// -- Divisor sigma: sum of k-th powers of divisors
/// local sigma0 = nt.divisor_sigma(12, 0)  -- 6 (number of divisors)
/// local sigma1 = nt.divisor_sigma(12, 1)  -- 28 (sum of divisors)
///
/// -- Möbius function
/// local mu = nt.mobius(30)  -- -1
///
/// -- Prime counting
/// local pi = nt.prime_pi(100)  -- 25
/// ```
public struct NumberTheoryModule {

    /// Register the number theory module with a LuaEngine.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_numtheory_euler_phi", callback: eulerPhiCallback)
        engine.registerFunction(name: "_luaswift_numtheory_divisor_sigma", callback: divisorSigmaCallback)
        engine.registerFunction(name: "_luaswift_numtheory_mobius", callback: mobiusCallback)
        engine.registerFunction(name: "_luaswift_numtheory_liouville", callback: liouvilleCallback)
        engine.registerFunction(name: "_luaswift_numtheory_carmichael", callback: carmichaelCallback)
        engine.registerFunction(name: "_luaswift_numtheory_chebyshev_theta", callback: chebyshevThetaCallback)
        engine.registerFunction(name: "_luaswift_numtheory_chebyshev_psi", callback: chebyshevPsiCallback)
        engine.registerFunction(name: "_luaswift_numtheory_mangoldt", callback: mangoldtCallback)
        engine.registerFunction(name: "_luaswift_numtheory_prime_pi", callback: primePiCallback)
        engine.registerFunction(name: "_luaswift_numtheory_is_prime", callback: isPrimeCallback)
        engine.registerFunction(name: "_luaswift_numtheory_factor", callback: factorCallback)
        engine.registerFunction(name: "_luaswift_numtheory_primes_up_to", callback: primesUpToCallback)
        engine.registerFunction(name: "_luaswift_numtheory_gcd", callback: gcdCallback)
        engine.registerFunction(name: "_luaswift_numtheory_lcm", callback: lcmCallback)

        // Create Lua wrapper
        do {
            try engine.run(numberTheoryLuaWrapper)
        } catch {
            // Silently ignore registration errors
        }
    }

    // MARK: - Callbacks
    // All helper functions are now provided by NumericSwift

    /// Euler's totient function φ(n): count of integers 1 ≤ k ≤ n coprime to n
    private static let eulerPhiCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue,
              let result = NumericSwift.eulerPhi(n) else {
            return .nil
        }
        return .number(Double(result))
    }

    /// Divisor sigma function σ_k(n): sum of k-th powers of divisors of n
    private static let divisorSigmaCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue else {
            return .nil
        }
        let k = args.count > 1 ? (args[1].intValue ?? 1) : 1
        guard let result = NumericSwift.divisorSigma(n, k: k) else {
            return .nil
        }
        return .number(result)
    }

    /// Möbius function μ(n)
    /// μ(n) = (-1)^k if n is product of k distinct primes
    /// μ(n) = 0 if n has a squared prime factor
    private static let mobiusCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue,
              let result = NumericSwift.mobius(n) else {
            return .nil
        }
        return .number(Double(result))
    }

    /// Liouville function λ(n) = (-1)^Ω(n)
    /// where Ω(n) is the number of prime factors with multiplicity
    private static let liouvilleCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue,
              let result = NumericSwift.liouville(n) else {
            return .nil
        }
        return .number(Double(result))
    }

    /// Carmichael function λ(n): smallest positive m such that a^m ≡ 1 (mod n) for all a coprime to n
    private static let carmichaelCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue,
              let result = NumericSwift.carmichael(n) else {
            return .nil
        }
        return .number(Double(result))
    }

    /// Chebyshev theta function θ(x) = Σ log(p) for primes p ≤ x
    private static let chebyshevThetaCallback: ([LuaValue]) -> LuaValue = { args in
        guard let x = args.first?.numberValue else {
            return .number(0)
        }
        return .number(NumericSwift.chebyshevTheta(x))
    }

    /// Chebyshev psi function ψ(x) = Σ Λ(n) for n ≤ x
    /// where Λ(n) is the von Mangoldt function
    private static let chebyshevPsiCallback: ([LuaValue]) -> LuaValue = { args in
        guard let x = args.first?.numberValue else {
            return .number(0)
        }
        return .number(NumericSwift.chebyshevPsi(x))
    }

    /// Von Mangoldt function callback
    private static let mangoldtCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue else {
            return .nil
        }
        return .number(NumericSwift.vonMangoldt(n))
    }

    /// Prime counting function π(x): number of primes ≤ x
    private static let primePiCallback: ([LuaValue]) -> LuaValue = { args in
        guard let x = args.first?.numberValue else {
            return .number(0)
        }
        return .number(Double(NumericSwift.primePi(x)))
    }

    /// Primality test callback
    private static let isPrimeCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue else {
            return .nil
        }
        return .bool(NumericSwift.isPrime(n))
    }

    /// Prime factorization callback
    private static let factorCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 1 else {
            return .nil
        }

        let factors = NumericSwift.primeFactors(n)
        var result: [String: LuaValue] = [:]

        for (prime, exp) in factors {
            result[String(prime)] = .number(Double(exp))
        }

        return .table(result)
    }

    /// Generate primes up to n callback
    private static let primesUpToCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 2 else {
            return .array([])
        }

        let primes = NumericSwift.primesUpTo(n)
        return .array(primes.map { .number(Double($0)) })
    }

    /// GCD callback
    private static let gcdCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let a = args[0].intValue,
              let b = args[1].intValue else {
            return .nil
        }
        return .number(Double(NumericSwift.gcd(a, b)))
    }

    /// LCM callback
    private static let lcmCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let a = args[0].intValue,
              let b = args[1].intValue else {
            return .nil
        }
        return .number(Double(NumericSwift.lcm(a, b)))
    }

    // MARK: - Lua Wrapper

    private static let numberTheoryLuaWrapper = """
    if not luaswift then luaswift = {} end

    local numtheory = {}

    -- Euler's totient function φ(n)
    numtheory.euler_phi = _luaswift_numtheory_euler_phi

    -- Divisor sigma function σ_k(n)
    numtheory.divisor_sigma = _luaswift_numtheory_divisor_sigma

    -- Möbius function μ(n)
    numtheory.mobius = _luaswift_numtheory_mobius

    -- Liouville function λ(n)
    numtheory.liouville = _luaswift_numtheory_liouville

    -- Carmichael function λ(n) (reduced totient)
    numtheory.carmichael = _luaswift_numtheory_carmichael

    -- Chebyshev theta function θ(x)
    numtheory.chebyshev_theta = _luaswift_numtheory_chebyshev_theta

    -- Chebyshev psi function ψ(x)
    numtheory.chebyshev_psi = _luaswift_numtheory_chebyshev_psi

    -- Von Mangoldt function Λ(n)
    numtheory.mangoldt = _luaswift_numtheory_mangoldt

    -- Prime counting function π(x)
    numtheory.prime_pi = _luaswift_numtheory_prime_pi

    -- Primality test
    numtheory.is_prime = _luaswift_numtheory_is_prime

    -- Prime factorization
    numtheory.factor = _luaswift_numtheory_factor

    -- Generate primes up to n
    numtheory.primes_up_to = _luaswift_numtheory_primes_up_to

    -- GCD and LCM
    numtheory.gcd = _luaswift_numtheory_gcd
    numtheory.lcm = _luaswift_numtheory_lcm

    -- Aliases for common notation
    numtheory.phi = numtheory.euler_phi
    numtheory.sigma = numtheory.divisor_sigma
    numtheory.mu = numtheory.mobius
    numtheory.Lambda = numtheory.mangoldt
    numtheory.pi = numtheory.prime_pi
    numtheory.theta = numtheory.chebyshev_theta
    numtheory.psi = numtheory.chebyshev_psi

    -- Register in luaswift namespace
    luaswift.numtheory = numtheory

    -- Add to math namespace if math.numtheory doesn't exist
    if math and not math.numtheory then
        math.numtheory = numtheory
    end

    -- Clean up globals
    _luaswift_numtheory_euler_phi = nil
    _luaswift_numtheory_divisor_sigma = nil
    _luaswift_numtheory_mobius = nil
    _luaswift_numtheory_liouville = nil
    _luaswift_numtheory_carmichael = nil
    _luaswift_numtheory_chebyshev_theta = nil
    _luaswift_numtheory_chebyshev_psi = nil
    _luaswift_numtheory_mangoldt = nil
    _luaswift_numtheory_prime_pi = nil
    _luaswift_numtheory_is_prime = nil
    _luaswift_numtheory_factor = nil
    _luaswift_numtheory_primes_up_to = nil
    _luaswift_numtheory_gcd = nil
    _luaswift_numtheory_lcm = nil
    """
}
