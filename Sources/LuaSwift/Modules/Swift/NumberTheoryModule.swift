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

    // MARK: - Helper Functions

    /// Check if a number is prime using trial division
    private static func isPrime(_ n: Int) -> Bool {
        if n < 2 { return false }
        if n == 2 { return true }
        if n % 2 == 0 { return false }
        if n == 3 { return true }
        if n % 3 == 0 { return false }
        var i = 5
        while i * i <= n {
            if n % i == 0 || n % (i + 2) == 0 { return false }
            i += 6
        }
        return true
    }

    /// Get prime factorization of n as [(prime, exponent)]
    private static func primeFactors(_ n: Int) -> [(prime: Int, exponent: Int)] {
        guard n > 1 else { return [] }
        var result: [(Int, Int)] = []
        var remaining = n

        // Factor out 2s
        var count = 0
        while remaining % 2 == 0 {
            count += 1
            remaining /= 2
        }
        if count > 0 { result.append((2, count)) }

        // Factor out odd primes
        var factor = 3
        while factor * factor <= remaining {
            count = 0
            while remaining % factor == 0 {
                count += 1
                remaining /= factor
            }
            if count > 0 { result.append((factor, count)) }
            factor += 2
        }

        // Remaining is prime if > 1
        if remaining > 1 {
            result.append((remaining, 1))
        }

        return result
    }

    /// Generate primes up to n using Sieve of Eratosthenes
    private static func sieveOfEratosthenes(_ n: Int) -> [Int] {
        guard n >= 2 else { return [] }
        var sieve = [Bool](repeating: true, count: n + 1)
        sieve[0] = false
        sieve[1] = false

        var i = 2
        while i * i <= n {
            if sieve[i] {
                var j = i * i
                while j <= n {
                    sieve[j] = false
                    j += i
                }
            }
            i += 1
        }

        return sieve.enumerated().compactMap { $0.element ? $0.offset : nil }
    }

    // MARK: - Callbacks

    /// Euler's totient function φ(n): count of integers 1 ≤ k ≤ n coprime to n
    private static let eulerPhiCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 1 else {
            return .nil
        }
        if n == 1 { return .number(1) }

        // φ(n) = n * Π(1 - 1/p) for all prime factors p of n
        var result = n
        let factors = primeFactors(n)
        for (prime, _) in factors {
            result = result / prime * (prime - 1)
        }
        return .number(Double(result))
    }

    /// Divisor sigma function σ_k(n): sum of k-th powers of divisors of n
    private static let divisorSigmaCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 1 else {
            return .nil
        }
        let k = args.count > 1 ? (args[1].intValue ?? 1) : 1

        if n == 1 { return .number(1) }

        // σ_k(n) = Π((p^(k*(e+1)) - 1)/(p^k - 1)) for prime factors p^e
        // For k=0: σ_0(n) = Π(e+1) (number of divisors)
        let factors = primeFactors(n)

        if k == 0 {
            // Number of divisors
            var result = 1
            for (_, exp) in factors {
                result *= (exp + 1)
            }
            return .number(Double(result))
        } else {
            // Sum of k-th powers of divisors
            var result = 1.0
            for (prime, exp) in factors {
                let pk = pow(Double(prime), Double(k))
                let numerator = pow(pk, Double(exp + 1)) - 1
                let denominator = pk - 1
                result *= numerator / denominator
            }
            return .number(result)
        }
    }

    /// Möbius function μ(n)
    /// μ(n) = (-1)^k if n is product of k distinct primes
    /// μ(n) = 0 if n has a squared prime factor
    private static let mobiusCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 1 else {
            return .nil
        }
        if n == 1 { return .number(1) }

        let factors = primeFactors(n)

        // Check for squared factors
        for (_, exp) in factors {
            if exp > 1 { return .number(0) }
        }

        // All exponents are 1, return (-1)^k
        return .number(factors.count % 2 == 0 ? 1 : -1)
    }

    /// Liouville function λ(n) = (-1)^Ω(n)
    /// where Ω(n) is the number of prime factors with multiplicity
    private static let liouvilleCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 1 else {
            return .nil
        }
        if n == 1 { return .number(1) }

        let factors = primeFactors(n)
        let omega = factors.reduce(0) { $0 + $1.exponent }
        return .number(omega % 2 == 0 ? 1 : -1)
    }

    /// Carmichael function λ(n): smallest positive m such that a^m ≡ 1 (mod n) for all a coprime to n
    private static let carmichaelCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 1 else {
            return .nil
        }
        if n == 1 { return .number(1) }

        let factors = primeFactors(n)
        var result = 1

        for (prime, exp) in factors {
            var lambda: Int
            if prime == 2 {
                // λ(2^k) = 2^(k-2) for k ≥ 3, otherwise φ(2^k)
                if exp >= 3 {
                    lambda = 1 << (exp - 2)  // 2^(exp-2)
                } else {
                    lambda = 1 << max(0, exp - 1)  // φ(2^exp)
                }
            } else {
                // λ(p^k) = φ(p^k) = p^(k-1) * (p-1)
                lambda = Int(pow(Double(prime), Double(exp - 1))) * (prime - 1)
            }
            // lcm
            result = result / gcd(result, lambda) * lambda
        }

        return .number(Double(result))
    }

    /// GCD helper
    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 {
            let t = b
            b = a % b
            a = t
        }
        return a
    }

    /// Chebyshev theta function θ(x) = Σ log(p) for primes p ≤ x
    private static let chebyshevThetaCallback: ([LuaValue]) -> LuaValue = { args in
        guard let x = args.first?.numberValue, x >= 2 else {
            return .number(0)
        }

        let primes = sieveOfEratosthenes(Int(x))
        var result = 0.0
        for p in primes {
            result += log(Double(p))
        }
        return .number(result)
    }

    /// Chebyshev psi function ψ(x) = Σ Λ(n) for n ≤ x
    /// where Λ(n) is the von Mangoldt function
    private static let chebyshevPsiCallback: ([LuaValue]) -> LuaValue = { args in
        guard let x = args.first?.numberValue, x >= 2 else {
            return .number(0)
        }

        var result = 0.0
        for n in 2...Int(x) {
            let lambda = vonMangoldt(n)
            result += lambda
        }
        return .number(result)
    }

    /// Von Mangoldt function Λ(n)
    /// Λ(n) = log(p) if n = p^k for some prime p and k ≥ 1
    /// Λ(n) = 0 otherwise
    private static func vonMangoldt(_ n: Int) -> Double {
        if n < 2 { return 0 }

        let factors = primeFactors(n)

        // n must be a prime power (exactly one distinct prime factor)
        if factors.count == 1 {
            return log(Double(factors[0].prime))
        }
        return 0
    }

    /// Von Mangoldt function callback
    private static let mangoldtCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 1 else {
            return .nil
        }
        return .number(vonMangoldt(n))
    }

    /// Prime counting function π(x): number of primes ≤ x
    private static let primePiCallback: ([LuaValue]) -> LuaValue = { args in
        guard let x = args.first?.numberValue, x >= 2 else {
            return .number(0)
        }

        let primes = sieveOfEratosthenes(Int(x))
        return .number(Double(primes.count))
    }

    /// Primality test callback
    private static let isPrimeCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue else {
            return .nil
        }
        return .bool(isPrime(n))
    }

    /// Prime factorization callback
    private static let factorCallback: ([LuaValue]) -> LuaValue = { args in
        guard let n = args.first?.intValue, n >= 1 else {
            return .nil
        }

        let factors = primeFactors(n)
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

        let primes = sieveOfEratosthenes(n)
        return .array(primes.map { .number(Double($0)) })
    }

    /// GCD callback
    private static let gcdCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let a = args[0].intValue,
              let b = args[1].intValue else {
            return .nil
        }
        return .number(Double(gcd(abs(a), abs(b))))
    }

    /// LCM callback
    private static let lcmCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let a = args[0].intValue,
              let b = args[1].intValue else {
            return .nil
        }
        let absA = abs(a)
        let absB = abs(b)
        if absA == 0 || absB == 0 { return .number(0) }
        return .number(Double(absA / gcd(absA, absB) * absB))
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
