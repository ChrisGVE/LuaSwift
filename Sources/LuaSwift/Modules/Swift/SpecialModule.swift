//
//  SpecialModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Darwin

/// Swift-backed special mathematical functions module for LuaSwift.
///
/// Provides advanced special mathematical functions:
/// - Error functions: erf, erfc, erfinv, erfcinv
/// - Beta functions: beta, betainc
/// - Bessel functions: j0, j1, jn, y0, y1, yn
/// - Modified Bessel functions: besseli, besselk
/// - Gamma functions: digamma/psi, gammainc, gammaincc
/// - Elliptic integrals: ellipk, ellipe
/// - Riemann zeta function: zeta
/// - Lambert W function: lambertw
///
/// These functions are added to the `math.special` namespace.
///
/// ## Usage
///
/// ```lua
/// local special = math.special
///
/// -- Error functions
/// local e = special.erf(1.0)      -- ~0.8427
/// local ec = special.erfc(1.0)    -- ~0.1573
///
/// -- Beta function
/// local b = special.beta(2, 3)    -- 0.0833...
///
/// -- Incomplete beta
/// local bi = special.betainc(2, 3, 0.5)  -- regularized incomplete beta
///
/// -- Bessel functions
/// local j = special.j0(1.0)       -- ~0.7652
/// local y = special.y0(1.0)       -- ~0.0883
/// ```
public struct SpecialModule {

    /// Register the special functions module with a LuaEngine.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_special_erf", callback: erfCallback)
        engine.registerFunction(name: "_luaswift_special_erfc", callback: erfcCallback)
        engine.registerFunction(name: "_luaswift_special_beta", callback: betaCallback)
        engine.registerFunction(name: "_luaswift_special_betainc", callback: betaincCallback)
        engine.registerFunction(name: "_luaswift_special_j0", callback: j0Callback)
        engine.registerFunction(name: "_luaswift_special_j1", callback: j1Callback)
        engine.registerFunction(name: "_luaswift_special_jn", callback: jnCallback)
        engine.registerFunction(name: "_luaswift_special_y0", callback: y0Callback)
        engine.registerFunction(name: "_luaswift_special_y1", callback: y1Callback)
        engine.registerFunction(name: "_luaswift_special_yn", callback: ynCallback)

        // Modified Bessel functions
        engine.registerFunction(name: "_luaswift_special_besseli", callback: besseliCallback)
        engine.registerFunction(name: "_luaswift_special_besselk", callback: besselkCallback)

        // New special functions
        engine.registerFunction(name: "_luaswift_special_digamma", callback: digammaCallback)
        engine.registerFunction(name: "_luaswift_special_erfinv", callback: erfinvCallback)
        engine.registerFunction(name: "_luaswift_special_erfcinv", callback: erfcinvCallback)
        engine.registerFunction(name: "_luaswift_special_gammainc", callback: gammaincCallback)
        engine.registerFunction(name: "_luaswift_special_gammaincc", callback: gammainccCallback)

        // Elliptic integrals, zeta, and Lambert W
        engine.registerFunction(name: "_luaswift_special_ellipk", callback: ellipkCallback)
        engine.registerFunction(name: "_luaswift_special_ellipe", callback: ellipeCallback)
        engine.registerFunction(name: "_luaswift_special_zeta", callback: zetaCallback)
        engine.registerFunction(name: "_luaswift_special_lambertw", callback: lambertwCallback)

        // Complex-aware gamma functions
        engine.registerFunction(name: "_luaswift_special_cgamma", callback: cgammaCallback)
        engine.registerFunction(name: "_luaswift_special_clgamma", callback: clgammaCallback)

        // Set up Lua wrappers that add to math.special namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.special then luaswift.special = {} end

                local special = luaswift.special

                ----------------------------------------------------------------
                -- Error Function: erf(x)
                --
                -- Returns the error function erf(x) = (2/sqrt(pi)) * integral(0,x) exp(-t^2) dt
                ----------------------------------------------------------------
                function special.erf(x)
                    if type(x) ~= "number" then
                        error("erf: expected number, got " .. type(x), 2)
                    end
                    return _luaswift_special_erf(x)
                end

                ----------------------------------------------------------------
                -- Complementary Error Function: erfc(x)
                --
                -- Returns erfc(x) = 1 - erf(x)
                ----------------------------------------------------------------
                function special.erfc(x)
                    if type(x) ~= "number" then
                        error("erfc: expected number, got " .. type(x), 2)
                    end
                    return _luaswift_special_erfc(x)
                end

                ----------------------------------------------------------------
                -- Beta Function: beta(a, b)
                --
                -- Returns B(a,b) = gamma(a)*gamma(b)/gamma(a+b)
                ----------------------------------------------------------------
                function special.beta(a, b)
                    if type(a) ~= "number" or type(b) ~= "number" then
                        error("beta: expected two numbers", 2)
                    end
                    return _luaswift_special_beta(a, b)
                end

                ----------------------------------------------------------------
                -- Regularized Incomplete Beta Function: betainc(a, b, x)
                --
                -- Returns I_x(a,b), the regularized incomplete beta function.
                -- I_x(a,b) = B(x; a,b) / B(a,b)
                -- where B(x; a,b) = integral(0,x) t^(a-1) * (1-t)^(b-1) dt
                ----------------------------------------------------------------
                function special.betainc(a, b, x)
                    if type(a) ~= "number" or type(b) ~= "number" or type(x) ~= "number" then
                        error("betainc: expected three numbers", 2)
                    end
                    if x < 0 or x > 1 then
                        error("betainc: x must be in [0, 1]", 2)
                    end
                    return _luaswift_special_betainc(a, b, x)
                end

                ----------------------------------------------------------------
                -- Bessel Function of First Kind, Order 0: j0(x)
                --
                -- Returns J_0(x)
                ----------------------------------------------------------------
                function special.j0(x)
                    if type(x) ~= "number" then
                        error("j0: expected number, got " .. type(x), 2)
                    end
                    return _luaswift_special_j0(x)
                end

                ----------------------------------------------------------------
                -- Bessel Function of First Kind, Order 1: j1(x)
                --
                -- Returns J_1(x)
                ----------------------------------------------------------------
                function special.j1(x)
                    if type(x) ~= "number" then
                        error("j1: expected number, got " .. type(x), 2)
                    end
                    return _luaswift_special_j1(x)
                end

                ----------------------------------------------------------------
                -- Bessel Function of First Kind, Order n: jn(n, x)
                --
                -- Returns J_n(x) for integer n
                ----------------------------------------------------------------
                function special.jn(n, x)
                    if type(n) ~= "number" or type(x) ~= "number" then
                        error("jn: expected two numbers", 2)
                    end
                    return _luaswift_special_jn(n, x)
                end

                ----------------------------------------------------------------
                -- Bessel Function of Second Kind, Order 0: y0(x)
                --
                -- Returns Y_0(x). Note: Y_0(x) is undefined for x <= 0.
                ----------------------------------------------------------------
                function special.y0(x)
                    if type(x) ~= "number" then
                        error("y0: expected number, got " .. type(x), 2)
                    end
                    if x <= 0 then
                        return -math.huge  -- -inf for x <= 0
                    end
                    return _luaswift_special_y0(x)
                end

                ----------------------------------------------------------------
                -- Bessel Function of Second Kind, Order 1: y1(x)
                --
                -- Returns Y_1(x). Note: Y_1(x) is undefined for x <= 0.
                ----------------------------------------------------------------
                function special.y1(x)
                    if type(x) ~= "number" then
                        error("y1: expected number, got " .. type(x), 2)
                    end
                    if x <= 0 then
                        return -math.huge  -- -inf for x <= 0
                    end
                    return _luaswift_special_y1(x)
                end

                ----------------------------------------------------------------
                -- Bessel Function of Second Kind, Order n: yn(n, x)
                --
                -- Returns Y_n(x) for integer n. Note: Y_n(x) is undefined for x <= 0.
                ----------------------------------------------------------------
                function special.yn(n, x)
                    if type(n) ~= "number" or type(x) ~= "number" then
                        error("yn: expected two numbers", 2)
                    end
                    if x <= 0 then
                        return -math.huge  -- -inf for x <= 0
                    end
                    return _luaswift_special_yn(n, x)
                end

                ----------------------------------------------------------------
                -- Modified Bessel Function of First Kind: besseli(n, x)
                --
                -- Returns I_n(x), the modified Bessel function of the first kind.
                ----------------------------------------------------------------
                function special.besseli(n, x)
                    if type(n) ~= "number" or type(x) ~= "number" then
                        error("besseli: expected two numbers", 2)
                    end
                    return _luaswift_special_besseli(n, x)
                end

                ----------------------------------------------------------------
                -- Modified Bessel Function of Second Kind: besselk(n, x)
                --
                -- Returns K_n(x), the modified Bessel function of the second kind.
                -- Note: K_n(x) is undefined for x <= 0.
                ----------------------------------------------------------------
                function special.besselk(n, x)
                    if type(n) ~= "number" or type(x) ~= "number" then
                        error("besselk: expected two numbers", 2)
                    end
                    if x <= 0 then
                        return math.huge  -- +inf for x <= 0
                    end
                    return _luaswift_special_besselk(n, x)
                end

                ----------------------------------------------------------------
                -- Digamma Function: digamma(x) / psi(x)
                --
                -- Returns the digamma function ψ(x) = d/dx ln(Γ(x)) = Γ'(x)/Γ(x)
                ----------------------------------------------------------------
                function special.digamma(x)
                    if type(x) ~= "number" then
                        error("digamma: expected number, got " .. type(x), 2)
                    end
                    return _luaswift_special_digamma(x)
                end
                special.psi = special.digamma  -- alias

                ----------------------------------------------------------------
                -- Inverse Error Function: erfinv(x)
                --
                -- Returns y such that erf(y) = x. Domain: x ∈ (-1, 1)
                ----------------------------------------------------------------
                function special.erfinv(x)
                    if type(x) ~= "number" then
                        error("erfinv: expected number, got " .. type(x), 2)
                    end
                    if x <= -1 or x >= 1 then
                        error("erfinv: x must be in (-1, 1)", 2)
                    end
                    return _luaswift_special_erfinv(x)
                end

                ----------------------------------------------------------------
                -- Inverse Complementary Error Function: erfcinv(x)
                --
                -- Returns y such that erfc(y) = x. Domain: x ∈ (0, 2)
                ----------------------------------------------------------------
                function special.erfcinv(x)
                    if type(x) ~= "number" then
                        error("erfcinv: expected number, got " .. type(x), 2)
                    end
                    if x <= 0 or x >= 2 then
                        error("erfcinv: x must be in (0, 2)", 2)
                    end
                    return _luaswift_special_erfcinv(x)
                end

                ----------------------------------------------------------------
                -- Lower Regularized Incomplete Gamma: gammainc(a, x)
                --
                -- Returns P(a, x) = γ(a, x) / Γ(a)
                -- where γ(a, x) = integral(0, x) t^(a-1) * exp(-t) dt
                ----------------------------------------------------------------
                function special.gammainc(a, x)
                    if type(a) ~= "number" or type(x) ~= "number" then
                        error("gammainc: expected two numbers", 2)
                    end
                    if a <= 0 then
                        error("gammainc: a must be positive", 2)
                    end
                    if x < 0 then
                        error("gammainc: x must be non-negative", 2)
                    end
                    return _luaswift_special_gammainc(a, x)
                end

                ----------------------------------------------------------------
                -- Upper Regularized Incomplete Gamma: gammaincc(a, x)
                --
                -- Returns Q(a, x) = Γ(a, x) / Γ(a) = 1 - P(a, x)
                -- where Γ(a, x) = integral(x, ∞) t^(a-1) * exp(-t) dt
                ----------------------------------------------------------------
                function special.gammaincc(a, x)
                    if type(a) ~= "number" or type(x) ~= "number" then
                        error("gammaincc: expected two numbers", 2)
                    end
                    if a <= 0 then
                        error("gammaincc: a must be positive", 2)
                    end
                    if x < 0 then
                        error("gammaincc: x must be non-negative", 2)
                    end
                    return _luaswift_special_gammaincc(a, x)
                end

                ----------------------------------------------------------------
                -- Complete Elliptic Integral of First Kind: ellipk(m)
                --
                -- Returns K(m), where m is the parameter (not the modulus k).
                -- K(m) = integral(0, π/2) 1/sqrt(1 - m*sin²θ) dθ
                -- Domain: 0 <= m < 1
                ----------------------------------------------------------------
                function special.ellipk(m)
                    if type(m) ~= "number" then
                        error("ellipk: expected number, got " .. type(m), 2)
                    end
                    if m < 0 or m >= 1 then
                        error("ellipk: m must be in [0, 1)", 2)
                    end
                    return _luaswift_special_ellipk(m)
                end

                ----------------------------------------------------------------
                -- Complete Elliptic Integral of Second Kind: ellipe(m)
                --
                -- Returns E(m), where m is the parameter (not the modulus k).
                -- E(m) = integral(0, π/2) sqrt(1 - m*sin²θ) dθ
                -- Domain: 0 <= m <= 1
                ----------------------------------------------------------------
                function special.ellipe(m)
                    if type(m) ~= "number" then
                        error("ellipe: expected number, got " .. type(m), 2)
                    end
                    if m < 0 or m > 1 then
                        error("ellipe: m must be in [0, 1]", 2)
                    end
                    return _luaswift_special_ellipe(m)
                end

                ----------------------------------------------------------------
                -- Riemann Zeta Function: zeta(s)
                --
                -- Returns ζ(s) = sum_{n=1}^∞ 1/n^s for s > 1
                -- Uses analytic continuation for other values.
                ----------------------------------------------------------------
                function special.zeta(s)
                    if type(s) ~= "number" then
                        error("zeta: expected number, got " .. type(s), 2)
                    end
                    return _luaswift_special_zeta(s)
                end

                ----------------------------------------------------------------
                -- Lambert W Function: lambertw(x)
                --
                -- Returns W(x), the principal branch of the Lambert W function.
                -- W(x) is the inverse of f(w) = w*exp(w).
                -- Domain: x >= -1/e ≈ -0.36788
                ----------------------------------------------------------------
                function special.lambertw(x)
                    if type(x) ~= "number" then
                        error("lambertw: expected number, got " .. type(x), 2)
                    end
                    local minVal = -1 / math.exp(1)
                    if x < minVal then
                        error("lambertw: x must be >= -1/e", 2)
                    end
                    return _luaswift_special_lambertw(x)
                end

                ----------------------------------------------------------------
                -- Complex Gamma Function: cgamma(z)
                --
                -- Returns Gamma(z) for complex z = {re=a, im=b}
                -- Uses Lanczos approximation for complex arguments
                ----------------------------------------------------------------
                function special.cgamma(z)
                    if type(z) == "number" then
                        return math.gamma and math.gamma(z) or _luaswift_special_cgamma(z)
                    end
                    if type(z) ~= "table" or z.re == nil or z.im == nil then
                        error("cgamma: expected number or complex {re=, im=}", 2)
                    end
                    return _luaswift_special_cgamma(z)
                end

                ----------------------------------------------------------------
                -- Complex Log Gamma Function: clgamma(z)
                --
                -- Returns log(Gamma(z)) for complex z = {re=a, im=b}
                -- Returns complex result with principal branch
                ----------------------------------------------------------------
                function special.clgamma(z)
                    if type(z) == "number" then
                        return {re = math.lgamma and math.lgamma(z) or _luaswift_special_clgamma(z).re, im = 0}
                    end
                    if type(z) ~= "table" or z.re == nil or z.im == nil then
                        error("clgamma: expected number or complex {re=, im=}", 2)
                    end
                    return _luaswift_special_clgamma(z)
                end

                -- Add to math.special namespace
                if math and math.special then
                    math.special.erf = special.erf
                    math.special.erfc = special.erfc
                    math.special.beta = special.beta
                    math.special.betainc = special.betainc
                    math.special.j0 = special.j0
                    math.special.j1 = special.j1
                    math.special.jn = special.jn
                    math.special.y0 = special.y0
                    math.special.y1 = special.y1
                    math.special.yn = special.yn
                    math.special.besseli = special.besseli
                    math.special.besselk = special.besselk
                    math.special.digamma = special.digamma
                    math.special.psi = special.psi
                    math.special.erfinv = special.erfinv
                    math.special.erfcinv = special.erfcinv
                    math.special.gammainc = special.gammainc
                    math.special.gammaincc = special.gammaincc
                    math.special.ellipk = special.ellipk
                    math.special.ellipe = special.ellipe
                    math.special.zeta = special.zeta
                    math.special.lambertw = special.lambertw
                    math.special.cgamma = special.cgamma
                    math.special.clgamma = special.clgamma
                end
                """)
        } catch {
            // Silently fail if setup fails
        }
    }

    // MARK: - Swift Callbacks

    /// Error function erf(x)
    private static func erfCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("erf: expected number")
        }
        return .number(Darwin.erf(x))
    }

    /// Complementary error function erfc(x) = 1 - erf(x)
    private static func erfcCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("erfc: expected number")
        }
        return .number(Darwin.erfc(x))
    }

    /// Beta function B(a,b) = gamma(a)*gamma(b)/gamma(a+b)
    private static func betaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let a = args[0].numberValue,
              let b = args[1].numberValue else {
            throw LuaError.runtimeError("beta: expected two numbers")
        }
        // Use log-gamma for numerical stability
        let result = exp(lgamma(a) + lgamma(b) - lgamma(a + b))
        return .number(result)
    }

    /// Regularized incomplete beta function I_x(a,b)
    /// Uses continued fraction representation for computation
    private static func betaincCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3,
              let a = args[0].numberValue,
              let b = args[1].numberValue,
              let x = args[2].numberValue else {
            throw LuaError.runtimeError("betainc: expected three numbers")
        }

        // Handle boundary cases
        if x <= 0 { return .number(0) }
        if x >= 1 { return .number(1) }

        let result = regularizedIncompleteBeta(a: a, b: b, x: x)
        return .number(result)
    }

    /// Bessel function of the first kind, order 0
    private static func j0Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("j0: expected number")
        }
        return .number(Darwin.j0(x))
    }

    /// Bessel function of the first kind, order 1
    private static func j1Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("j1: expected number")
        }
        return .number(Darwin.j1(x))
    }

    /// Bessel function of the first kind, order n
    private static func jnCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let n = args[0].numberValue,
              let x = args[1].numberValue else {
            throw LuaError.runtimeError("jn: expected two numbers")
        }
        return .number(Darwin.jn(Int32(n), x))
    }

    /// Bessel function of the second kind, order 0
    private static func y0Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("y0: expected number")
        }
        if x <= 0 {
            return .number(-.infinity)
        }
        return .number(Darwin.y0(x))
    }

    /// Bessel function of the second kind, order 1
    private static func y1Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("y1: expected number")
        }
        if x <= 0 {
            return .number(-.infinity)
        }
        return .number(Darwin.y1(x))
    }

    /// Bessel function of the second kind, order n
    private static func ynCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let n = args[0].numberValue,
              let x = args[1].numberValue else {
            throw LuaError.runtimeError("yn: expected two numbers")
        }
        if x <= 0 {
            return .number(-.infinity)
        }
        return .number(Darwin.yn(Int32(n), x))
    }

    // MARK: - Modified Bessel Functions

    /// Modified Bessel function of the first kind I_n(x)
    private static func besseliCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let n = args[0].numberValue,
              let x = args[1].numberValue else {
            throw LuaError.runtimeError("besseli: expected two numbers")
        }
        return .number(besseli(Int(n), x))
    }

    /// Modified Bessel function of the second kind K_n(x)
    private static func besselkCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let n = args[0].numberValue,
              let x = args[1].numberValue else {
            throw LuaError.runtimeError("besselk: expected two numbers")
        }
        if x <= 0 {
            return .number(.infinity)
        }
        return .number(besselk(Int(n), x))
    }

    /// Compute I_n(x) - Modified Bessel function of the first kind
    /// Uses series expansion for small x and asymptotic expansion for large x
    private static func besseli(_ n: Int, _ x: Double) -> Double {
        let absN = abs(n)

        // Handle x = 0
        if x == 0 {
            return absN == 0 ? 1.0 : 0.0
        }

        let absX = abs(x)

        // Use series expansion for moderate x
        if absX <= 20.0 + Double(absN) {
            return besseliSeries(absN, absX)
        } else {
            // Asymptotic expansion for large x
            return besseliAsymptotic(absN, absX)
        }
    }

    /// Series expansion for I_n(x)
    /// I_n(x) = (x/2)^n * sum_{k=0}^∞ (x²/4)^k / (k! * (n+k)!)
    private static func besseliSeries(_ n: Int, _ x: Double) -> Double {
        let halfX = x / 2.0
        let quarterX2 = halfX * halfX
        let eps = 1.0e-15
        let maxIterations = 200

        // Start with the leading factor (x/2)^n
        var term = pow(halfX, Double(n)) / tgamma(Double(n) + 1.0)
        var sum = term

        for k in 1...maxIterations {
            term *= quarterX2 / (Double(k) * Double(n + k))
            sum += term
            if abs(term) < abs(sum) * eps {
                break
            }
        }

        return sum
    }

    /// Asymptotic expansion for I_n(x) for large x
    /// I_n(x) ≈ exp(x) / sqrt(2πx) * (1 - μ/(8x) + ...)
    /// where μ = 4n²
    private static func besseliAsymptotic(_ n: Int, _ x: Double) -> Double {
        let mu = 4.0 * Double(n * n)
        let x8 = 8.0 * x

        // First few terms of the asymptotic series
        var sum = 1.0
        var term = 1.0
        let eps = 1.0e-15

        for k in 1...10 {
            let k2m1 = Double(2 * k - 1)
            term *= -(mu - k2m1 * k2m1) / (Double(k) * x8)
            let newSum = sum + term
            if abs(term) < abs(sum) * eps {
                break
            }
            sum = newSum
        }

        return exp(x) / sqrt(2.0 * .pi * x) * sum
    }

    /// Compute K_n(x) - Modified Bessel function of the second kind
    private static func besselk(_ n: Int, _ x: Double) -> Double {
        let absN = abs(n)  // K_n = K_{-n}

        // Handle special cases
        if x <= 0 {
            return .infinity
        }

        // Use different methods based on x size
        if x <= 2.0 {
            return besselkSmall(absN, x)
        } else {
            return besselkAsymptotic(absN, x)
        }
    }

    /// K_n(x) for small x using the relationship with I_n
    /// K_0(x) = -ln(x/2)*I_0(x) + series
    /// K_n(x) computed via recurrence from K_0 and K_1
    private static func besselkSmall(_ n: Int, _ x: Double) -> Double {
        // Compute K_0(x) and K_1(x) first
        let k0 = besselk0Small(x)
        if n == 0 { return k0 }

        let k1 = besselk1Small(x)
        if n == 1 { return k1 }

        // Use upward recurrence: K_{n+1}(x) = K_{n-1}(x) + (2n/x)*K_n(x)
        var kPrev = k0
        var kCurr = k1
        for m in 1..<n {
            let kNext = kPrev + (2.0 * Double(m) / x) * kCurr
            kPrev = kCurr
            kCurr = kNext
        }

        return kCurr
    }

    /// K_0(x) for small x
    private static func besselk0Small(_ x: Double) -> Double {
        let halfX = x / 2.0
        let quarterX2 = halfX * halfX
        let gamma = 0.5772156649015329  // Euler-Mascheroni constant

        // K_0(x) = -ln(x/2)*I_0(x) + sum_{k=0}^∞ (x²/4)^k * ψ(k+1) / (k!)²
        // where ψ(k+1) = -γ + sum_{j=1}^k 1/j

        let i0 = besseliSeries(0, x)

        var sum = 0.0
        var term = 1.0
        var psi = -gamma

        sum += term * psi

        for k in 1...50 {
            psi += 1.0 / Double(k)
            term *= quarterX2 / Double(k * k)
            sum += term * psi
            if abs(term) < 1.0e-15 * abs(sum) {
                break
            }
        }

        return -log(halfX) * i0 + sum
    }

    /// K_1(x) for small x
    private static func besselk1Small(_ x: Double) -> Double {
        let halfX = x / 2.0
        let quarterX2 = halfX * halfX
        let gamma = 0.5772156649015329

        // K_1(x) = ln(x/2)*I_1(x) + (1/x) + series
        let i1 = besseliSeries(1, x)

        var sum = 0.0
        var term = halfX
        var psiK = -gamma
        var psiK1 = 1.0 - gamma

        sum += term * (psiK + psiK1) / 2.0

        for k in 1...50 {
            psiK += 1.0 / Double(k)
            psiK1 += 1.0 / Double(k + 1)
            term *= quarterX2 / (Double(k) * Double(k + 1))
            sum += term * (psiK + psiK1) / 2.0
            if abs(term) < 1.0e-15 * abs(sum) {
                break
            }
        }

        return log(halfX) * i1 + 1.0 / x - sum
    }

    /// Asymptotic expansion for K_n(x) for large x
    /// K_n(x) ≈ sqrt(π/(2x)) * exp(-x) * (1 + μ/(8x) + ...)
    private static func besselkAsymptotic(_ n: Int, _ x: Double) -> Double {
        let mu = 4.0 * Double(n * n)
        let x8 = 8.0 * x

        // Asymptotic series
        var sum = 1.0
        var term = 1.0
        let eps = 1.0e-15

        for k in 1...20 {
            let k2m1 = Double(2 * k - 1)
            term *= (mu - k2m1 * k2m1) / (Double(k) * x8)
            let newSum = sum + term
            if abs(term) < abs(sum) * eps {
                break
            }
            sum = newSum
        }

        return sqrt(.pi / (2.0 * x)) * exp(-x) * sum
    }

    // MARK: - Digamma and Gamma Functions

    /// Digamma function ψ(x) = d/dx ln(Γ(x))
    /// Uses asymptotic expansion for large x and recurrence for small x
    private static func digammaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("digamma: expected number")
        }
        return .number(digamma(x))
    }

    /// Compute the digamma function
    private static func digamma(_ x: Double) -> Double {
        var z = x
        var result = 0.0

        // Reflection formula for x < 0.5: ψ(1-x) - ψ(x) = π*cot(πx)
        // So: ψ(x) = ψ(1-x) - π*cot(πx)
        if z < 0.5 {
            return digamma(1.0 - z) - Double.pi / tan(Double.pi * z)
        }

        // Recurrence relation: ψ(x+1) = ψ(x) + 1/x
        // Use this to shift x to a larger value where asymptotic expansion is accurate
        while z < 6.0 {
            result -= 1.0 / z
            z += 1.0
        }

        // Asymptotic expansion for large z:
        // ψ(z) ≈ ln(z) - 1/(2z) - 1/(12z²) + 1/(120z⁴) - 1/(252z⁶) + ...
        result += log(z) - 0.5 / z

        let z2 = 1.0 / (z * z)
        // Bernoulli number coefficients: B₂/2 = 1/12, B₄/4 = -1/120, B₆/6 = 1/252, B₈/8 = -1/240
        result -= z2 * (1.0/12.0 - z2 * (1.0/120.0 - z2 * (1.0/252.0 - z2 * 1.0/240.0)))

        return result
    }

    /// Inverse error function erfinv(x)
    /// Uses rational approximation for high accuracy
    private static func erfinvCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("erfinv: expected number")
        }

        if x <= -1.0 || x >= 1.0 {
            throw LuaError.runtimeError("erfinv: x must be in (-1, 1)")
        }

        return .number(erfinv(x))
    }

    /// Compute inverse error function using rational approximation
    private static func erfinv(_ x: Double) -> Double {
        if x == 0 { return 0 }

        let a = abs(x)

        // For |x| <= 0.7, use central approximation
        if a <= 0.7 {
            let x2 = x * x
            let r = x * ((((-0.140543331 * x2 + 0.914624893) * x2 - 1.645349621) * x2 + 0.886226899))
            let s = (((0.012229801 * x2 - 0.329097515) * x2 + 1.442710462) * x2 - 2.118377725) * x2 + 1.0
            return r / s
        }

        // For |x| > 0.7, use tail approximation
        let y = sqrt(-log((1.0 - a) / 2.0))

        // Rational approximation for the tail
        let r: Double
        if y <= 5.0 {
            let t = y - 1.6
            r = ((((((0.00077454501427834 * t + 0.0227238449892691) * t + 0.24178072517745) * t +
                   1.27045825245237) * t + 3.64784832476320) * t + 5.76949722146069) * t + 4.63033784615655) /
                ((((((0.00080529518738563 * t + 0.02287663117085) * t + 0.23601290952344) * t +
                   1.21357729517684) * t + 3.34305755540406) * t + 4.77629303102970) * t + 1.0)
        } else {
            let t = y - 5.0
            r = ((((((0.0000100950558 * t + 0.000280756651) * t + 0.00326196717) * t +
                   0.0206706341) * t + 0.0783478783) * t + 0.169827922) * t + 0.161895932) /
                ((((((0.0000100950558 * t + 0.000280756651) * t + 0.00326196717) * t +
                   0.0206706341) * t + 0.0783478783) * t + 0.169827922) * t + 1.0)
        }

        return x >= 0 ? r : -r
    }

    /// Inverse complementary error function erfcinv(x)
    private static func erfcinvCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("erfcinv: expected number")
        }

        if x <= 0.0 || x >= 2.0 {
            throw LuaError.runtimeError("erfcinv: x must be in (0, 2)")
        }

        // erfcinv(x) = erfinv(1 - x)
        return .number(erfinv(1.0 - x))
    }

    /// Lower regularized incomplete gamma function P(a, x)
    private static func gammaincCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let a = args[0].numberValue,
              let x = args[1].numberValue else {
            throw LuaError.runtimeError("gammainc: expected two numbers")
        }

        if a <= 0 {
            throw LuaError.runtimeError("gammainc: a must be positive")
        }
        if x < 0 {
            throw LuaError.runtimeError("gammainc: x must be non-negative")
        }

        return .number(gammainc(a, x))
    }

    /// Upper regularized incomplete gamma function Q(a, x) = 1 - P(a, x)
    private static func gammainccCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let a = args[0].numberValue,
              let x = args[1].numberValue else {
            throw LuaError.runtimeError("gammaincc: expected two numbers")
        }

        if a <= 0 {
            throw LuaError.runtimeError("gammaincc: a must be positive")
        }
        if x < 0 {
            throw LuaError.runtimeError("gammaincc: x must be non-negative")
        }

        return .number(1.0 - gammainc(a, x))
    }

    /// Compute the lower regularized incomplete gamma function P(a, x)
    /// Uses series expansion for x < a+1, continued fraction for x >= a+1
    private static func gammainc(_ a: Double, _ x: Double) -> Double {
        if x == 0 { return 0 }
        if x < 0 { return 0 }

        // Choose method based on relative sizes of a and x
        if x < a + 1 {
            return gammaincSeries(a, x)
        } else {
            return 1.0 - gammaincCF(a, x)
        }
    }

    /// Series expansion for lower incomplete gamma
    /// P(a,x) = exp(-x) * x^a * sum_{n=0}^∞ x^n / Γ(a+n+1)
    private static func gammaincSeries(_ a: Double, _ x: Double) -> Double {
        let eps = 1.0e-15
        let maxIterations = 200

        var sum = 1.0 / a
        var term = 1.0 / a

        for n in 1...maxIterations {
            term *= x / (a + Double(n))
            sum += term
            if abs(term) < abs(sum) * eps {
                break
            }
        }

        return sum * exp(-x + a * log(x) - lgamma(a))
    }

    /// Continued fraction for upper incomplete gamma
    /// Q(a,x) = exp(-x) * x^a * CF / Γ(a)
    private static func gammaincCF(_ a: Double, _ x: Double) -> Double {
        let eps = 1.0e-15
        let maxIterations = 200

        // Lentz's algorithm
        var b = x + 1.0 - a
        var c = 1.0 / 1.0e-30
        var d = 1.0 / b
        var h = d

        for i in 1...maxIterations {
            let an = -Double(i) * (Double(i) - a)
            b += 2.0
            d = an * d + b
            if abs(d) < 1.0e-30 { d = 1.0e-30 }
            c = b + an / c
            if abs(c) < 1.0e-30 { c = 1.0e-30 }
            d = 1.0 / d
            let del = d * c
            h *= del
            if abs(del - 1.0) < eps {
                break
            }
        }

        return exp(-x + a * log(x) - lgamma(a)) * h
    }

    // MARK: - Helper Functions

    /// Compute the regularized incomplete beta function I_x(a,b)
    /// Uses the continued fraction representation for efficiency
    private static func regularizedIncompleteBeta(a: Double, b: Double, x: Double) -> Double {
        // For x > (a+1)/(a+b+2), use the symmetry relation:
        // I_x(a,b) = 1 - I_{1-x}(b,a)
        let symmetryPoint = (a + 1) / (a + b + 2)

        if x > symmetryPoint {
            return 1.0 - regularizedIncompleteBeta(a: b, b: a, x: 1.0 - x)
        }

        // Compute the continued fraction
        let bt: Double
        if x == 0 || x == 1 {
            bt = 0
        } else {
            // bt = exp(lgamma(a+b) - lgamma(a) - lgamma(b) + a*log(x) + b*log(1-x))
            bt = exp(lgamma(a + b) - lgamma(a) - lgamma(b) + a * log(x) + b * log(1 - x))
        }

        // Continued fraction using Lentz's method
        let eps = 1.0e-15
        let maxIterations = 200

        var c = 1.0
        var d = 1.0 - (a + b) * x / (a + 1)
        if abs(d) < 1.0e-30 { d = 1.0e-30 }
        d = 1.0 / d
        var h = d

        for m in 1...maxIterations {
            let m2 = 2 * m
            let dm = Double(m)
            let dm2 = Double(m2)

            // Even step
            var aa = dm * (b - dm) * x / ((a + dm2 - 1) * (a + dm2))
            d = 1.0 + aa * d
            if abs(d) < 1.0e-30 { d = 1.0e-30 }
            c = 1.0 + aa / c
            if abs(c) < 1.0e-30 { c = 1.0e-30 }
            d = 1.0 / d
            h *= d * c

            // Odd step
            aa = -(a + dm) * (a + b + dm) * x / ((a + dm2) * (a + dm2 + 1))
            d = 1.0 + aa * d
            if abs(d) < 1.0e-30 { d = 1.0e-30 }
            c = 1.0 + aa / c
            if abs(c) < 1.0e-30 { c = 1.0e-30 }
            d = 1.0 / d
            let del = d * c
            h *= del

            if abs(del - 1.0) < eps {
                break
            }
        }

        return bt * h / a
    }

    // MARK: - Elliptic Integrals

    /// Complete elliptic integral of the first kind K(m)
    /// Uses the AGM (Arithmetic-Geometric Mean) method
    private static func ellipkCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let m = args.first?.numberValue else {
            throw LuaError.runtimeError("ellipk: expected number")
        }

        if m < 0 || m >= 1 {
            throw LuaError.runtimeError("ellipk: m must be in [0, 1)")
        }

        return .number(ellipk(m))
    }

    /// Compute K(m) using AGM method
    /// K(m) = π / (2 * AGM(1, sqrt(1-m)))
    private static func ellipk(_ m: Double) -> Double {
        // Special case: m = 0 => K(0) = π/2
        if m == 0 {
            return .pi / 2
        }

        // AGM iteration
        var a = 1.0
        var g = sqrt(1.0 - m)
        let eps = 1.0e-15

        while abs(a - g) > eps * abs(a) {
            let aNew = (a + g) / 2
            g = sqrt(a * g)
            a = aNew
        }

        return .pi / (2 * a)
    }

    /// Complete elliptic integral of the second kind E(m)
    private static func ellipeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let m = args.first?.numberValue else {
            throw LuaError.runtimeError("ellipe: expected number")
        }

        if m < 0 || m > 1 {
            throw LuaError.runtimeError("ellipe: m must be in [0, 1]")
        }

        return .number(ellipe(m))
    }

    /// Compute E(m) using the AGM method and Legendre relation
    /// E(m) = K(m) * (1 - sum of c_n^2 * 2^(n-1))
    private static func ellipe(_ m: Double) -> Double {
        // Special cases
        if m == 0 {
            return .pi / 2
        }
        if m == 1 {
            return 1.0
        }

        // AGM iteration with tracking of c values
        var a = 1.0
        var g = sqrt(1.0 - m)
        var c = sqrt(m)
        var sum = c * c
        var power = 1.0
        let eps = 1.0e-15

        while abs(c) > eps {
            let aNew = (a + g) / 2
            c = (a - g) / 2
            g = sqrt(a * g)
            a = aNew
            power *= 2
            sum += power * c * c
        }

        let k = .pi / (2 * a)
        return k * (1.0 - sum / 2)
    }

    // MARK: - Riemann Zeta Function

    /// Riemann zeta function ζ(s)
    private static func zetaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.numberValue else {
            throw LuaError.runtimeError("zeta: expected number")
        }

        return .number(zeta(s))
    }

    /// Compute the Riemann zeta function
    /// Uses different methods depending on the value of s
    private static func zeta(_ s: Double) -> Double {
        // Special cases
        if s == 1 {
            return .infinity  // Pole at s = 1
        }
        if s == 0 {
            return -0.5  // ζ(0) = -1/2
        }

        // For s < 0, use reflection formula
        // ζ(s) = 2^s * π^(s-1) * sin(πs/2) * Γ(1-s) * ζ(1-s)
        if s < 0 {
            // Handle trivial zeros at negative even integers
            if s.truncatingRemainder(dividingBy: 2) == 0 {
                return 0
            }
            let t = 1.0 - s
            return pow(2, s) * pow(.pi, s - 1) * sin(.pi * s / 2) * tgamma(t) * zeta(t)
        }

        // For 0 < s < 1, use the functional equation differently
        // or continue to use the Dirichlet eta alternating series
        if s < 1 {
            // Use alternating series (Dirichlet eta function)
            // η(s) = (1 - 2^(1-s)) * ζ(s)
            // ζ(s) = η(s) / (1 - 2^(1-s))
            let eta = zetaEta(s)
            let factor = 1.0 - pow(2, 1 - s)
            return eta / factor
        }

        // For s > 1, use Dirichlet series with Euler-Maclaurin formula
        // ζ(s) = sum_{n=1}^N 1/n^s + 1/((s-1)*N^(s-1)) + 1/(2*N^s) + corrections
        if s < 10 {
            return zetaDirichlet(s)
        } else {
            // For large s, simple sum converges quickly
            var sum = 1.0
            for n in 2...100 {
                let term = pow(Double(n), -s)
                sum += term
                if term < 1e-15 * sum {
                    break
                }
            }
            return sum
        }
    }

    /// Dirichlet eta function (alternating zeta)
    /// η(s) = sum_{n=1}^∞ (-1)^(n-1) / n^s
    private static func zetaEta(_ s: Double) -> Double {
        // Use acceleration for alternating series
        // Borwein's algorithm for accelerated convergence
        let n = 50
        var d = Array(repeating: 0.0, count: n + 1)
        d[0] = 1.0

        for k in 1...n {
            d[k] = d[k - 1] + pow(Double(n + k - 1), Double(n)) *
                   pow(4, Double(k)) / (tgamma(Double(2 * k + 1)) /
                   (tgamma(Double(k + 1)) * tgamma(Double(k + 1))))
        }

        // Simplified: use direct summation with many terms
        var sum = 0.0
        var sign = 1.0
        for k in 1...200 {
            let term = sign / pow(Double(k), s)
            sum += term
            sign = -sign
            if abs(term) < 1e-15 * abs(sum) && k > 10 {
                break
            }
        }
        return sum
    }

    /// Dirichlet series for ζ(s) with Euler-Maclaurin summation
    /// Uses a larger N and more accurate correction terms
    private static func zetaDirichlet(_ s: Double) -> Double {
        let N = 100
        var sum = 0.0

        // Direct sum for first N terms
        for n in 1...N {
            sum += pow(Double(n), -s)
        }

        // Euler-Maclaurin formula:
        // ζ(s) ≈ Σ_{n=1}^N n^{-s} + N^{1-s}/(s-1) + 1/(2N^s)
        //        + Σ_{k=1}^K B_{2k}/(2k)! * s(s+1)...(s+2k-2) * N^{-(s+2k-1)}

        let Ns = pow(Double(N), s)
        let Ns1 = pow(Double(N), s - 1)

        // Integral term: ∫_N^∞ x^{-s} dx = N^{1-s}/(s-1)
        sum += 1.0 / ((s - 1) * Ns1)

        // First correction: 1/(2*N^s)
        sum += 0.5 / Ns

        // Bernoulli numbers B_{2k} for k = 1 to 10
        let bernoulli: [Double] = [
            1.0/6,              // B_2
            -1.0/30,            // B_4
            1.0/42,             // B_6
            -1.0/30,            // B_8
            5.0/66,             // B_10
            -691.0/2730,        // B_12
            7.0/6,              // B_14
            -3617.0/510,        // B_16
            43867.0/798,        // B_18
            -174611.0/330       // B_20
        ]

        // Add Bernoulli correction terms
        var Npow = Ns * Double(N)    // N^{s+1}

        for (i, b2k) in bernoulli.enumerated() {
            let k2 = 2 * (i + 1)  // 2, 4, 6, ...

            // Term: B_{2k} / (2k)! * s(s+1)...(s+2k-2) / N^{s+2k-1}
            // We build this incrementally

            // Factorial denominator: (2k)!
            var factorial: Double = 1
            for j in 1...k2 {
                factorial *= Double(j)
            }

            // Rising factorial numerator: s(s+1)...(s+2k-2)
            var rising: Double = 1
            for j in 0..<(k2 - 1) {
                rising *= (s + Double(j))
            }

            let term = b2k * rising / (factorial * Npow)
            sum += term

            if abs(term) < 1e-16 * abs(sum) {
                break
            }

            // Update for next iteration
            Npow *= Double(N) * Double(N)  // Increase power by 2
        }

        return sum
    }

    // MARK: - Lambert W Function

    /// Lambert W function W(x) - principal branch
    private static func lambertwCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("lambertw: expected number")
        }

        let minVal = -1.0 / Darwin.M_E
        if x < minVal {
            throw LuaError.runtimeError("lambertw: x must be >= -1/e")
        }

        return .number(lambertw(x))
    }

    /// Compute the principal branch of Lambert W function using Halley's method
    /// W(x) is the solution to w * exp(w) = x
    private static func lambertw(_ x: Double) -> Double {
        let minVal = -1.0 / Darwin.M_E

        // Special cases
        if x == 0 {
            return 0
        }
        if x == Darwin.M_E {
            return 1
        }
        if abs(x - minVal) < 1e-15 {
            return -1  // W(-1/e) = -1
        }

        // Initial guess
        var w: Double
        if x < -0.25 {
            // Near the branch point, use series expansion
            let p = sqrt(2.0 * (Darwin.M_E * x + 1.0))
            w = -1.0 + p - p * p / 3.0 + 11.0 * p * p * p / 72.0
        } else if x < 3 {
            w = 0.5 * log(1 + x)
            if w < 0 { w = 0 }
        } else {
            // For large x, use log(x) - log(log(x))
            let lnx = log(x)
            let lnlnx = log(lnx)
            w = lnx - lnlnx + lnlnx / lnx
        }

        // Halley's method iteration
        // w_{n+1} = w_n - (w*e^w - x) / (e^w*(w+1) - (w+2)*(w*e^w - x)/(2w+2))
        let eps = 1e-15
        let maxIterations = 50

        for _ in 0..<maxIterations {
            let ew = exp(w)
            let wew = w * ew
            let f = wew - x
            let fp = ew * (w + 1)

            // Halley's correction
            let correction = f * fp / (fp * fp - f * ew * (w + 2) / 2)
            w -= correction

            if abs(correction) < eps * (1 + abs(w)) {
                break
            }
        }

        return w
    }

    // MARK: - Complex Gamma Functions

    /// Lanczos coefficients for g=7, n=9 (accurate to ~15 digits)
    private static let lanczosCoeffs: [Double] = [
        0.99999999999980993,
        676.5203681218851,
        -1259.1392167224028,
        771.32342877765313,
        -176.61502916214059,
        12.507343278686905,
        -0.13857109526572012,
        9.9843695780195716e-6,
        1.5056327351493116e-7
    ]

    /// Complex gamma function callback
    private static func cgammaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.runtimeError("cgamma: expected argument")
        }

        // Handle real number input
        if let x = arg.numberValue {
            if x > 0 {
                return .number(Darwin.tgamma(x))
            }
            // For non-positive reals, compute via complex
            let (re, im) = complexGamma(x, 0)
            return ComplexHelper.toResult(re, im)
        }

        // Handle complex input
        guard let (re, im) = ComplexHelper.toComplex(arg) else {
            throw LuaError.runtimeError("cgamma: expected number or complex")
        }

        let (resultRe, resultIm) = complexGamma(re, im)
        return ComplexHelper.toResult(resultRe, resultIm)
    }

    /// Complex log-gamma function callback
    private static func clgammaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.runtimeError("clgamma: expected argument")
        }

        // Handle real number input
        if let x = arg.numberValue {
            if x > 0 {
                return ComplexHelper.toLua(Darwin.lgamma(x), 0)
            }
            // For non-positive reals, compute via complex
            let (re, im) = complexLogGamma(x, 0)
            return ComplexHelper.toLua(re, im)
        }

        // Handle complex input
        guard let (re, im) = ComplexHelper.toComplex(arg) else {
            throw LuaError.runtimeError("clgamma: expected number or complex")
        }

        let (resultRe, resultIm) = complexLogGamma(re, im)
        return ComplexHelper.toLua(resultRe, resultIm)
    }

    /// Compute complex gamma using Lanczos approximation
    /// Gamma(z) = sqrt(2*pi) * (z + g + 0.5)^(z+0.5) * exp(-(z+g+0.5)) * sum
    private static func complexGamma(_ re: Double, _ im: Double) -> (re: Double, im: Double) {
        // Use reflection formula for Re(z) < 0.5
        // Gamma(z) = pi / (sin(pi*z) * Gamma(1-z))
        if re < 0.5 {
            // sin(pi*z) for complex z
            // sin(a+bi) = sin(a)cosh(b) + i*cos(a)sinh(b)
            let sinRe = Darwin.sin(.pi * re) * Darwin.cosh(.pi * im)
            let sinIm = Darwin.cos(.pi * re) * Darwin.sinh(.pi * im)

            // Gamma(1-z)
            let (g1Re, g1Im) = complexGammaPositive(1 - re, -im)

            // pi / (sin(pi*z) * Gamma(1-z))
            let (denRe, denIm) = ComplexHelper.multiply(sinRe, sinIm, g1Re, g1Im)
            guard let (resultRe, resultIm) = ComplexHelper.divide(.pi, 0, denRe, denIm) else {
                return (.nan, .nan)
            }
            return (resultRe, resultIm)
        }

        return complexGammaPositive(re, im)
    }

    /// Lanczos approximation for Re(z) >= 0.5
    private static func complexGammaPositive(_ re: Double, _ im: Double) -> (re: Double, im: Double) {
        let g = 7.0
        let zRe = re - 1
        let zIm = im

        // Sum of Lanczos series
        var sumRe = lanczosCoeffs[0]
        var sumIm = 0.0

        for i in 1..<lanczosCoeffs.count {
            // 1 / (z + i)
            let denomRe = zRe + Double(i)
            let denomIm = zIm
            guard let (invRe, invIm) = ComplexHelper.divide(1, 0, denomRe, denomIm) else {
                return (.nan, .nan)
            }
            sumRe += lanczosCoeffs[i] * invRe
            sumIm += lanczosCoeffs[i] * invIm
        }

        // t = z + g + 0.5
        let tRe = zRe + g + 0.5
        let tIm = zIm

        // t^(z + 0.5)
        let expRe = zRe + 0.5
        let expIm = zIm
        let (powRe, powIm) = complexPow(tRe, tIm, expRe, expIm)

        // exp(-t)
        let (expNegRe, expNegIm) = ComplexHelper.exp(-tRe, -tIm)

        // sqrt(2*pi) * t^(z+0.5) * exp(-t) * sum
        let sqrt2pi = sqrt(2 * .pi)

        var (resultRe, resultIm) = ComplexHelper.multiply(powRe, powIm, expNegRe, expNegIm)
        (resultRe, resultIm) = ComplexHelper.multiply(resultRe, resultIm, sumRe, sumIm)
        resultRe *= sqrt2pi
        resultIm *= sqrt2pi

        return (resultRe, resultIm)
    }

    /// Complex log-gamma using Lanczos approximation
    private static func complexLogGamma(_ re: Double, _ im: Double) -> (re: Double, im: Double) {
        // Use reflection formula for Re(z) < 0.5
        if re < 0.5 {
            // log(Gamma(z)) = log(pi) - log(sin(pi*z)) - log(Gamma(1-z))
            // sin(pi*z)
            let sinRe = Darwin.sin(.pi * re) * Darwin.cosh(.pi * im)
            let sinIm = Darwin.cos(.pi * re) * Darwin.sinh(.pi * im)

            // log(sin(pi*z))
            guard let (logSinRe, logSinIm) = ComplexHelper.log(sinRe, sinIm) else {
                return (.nan, .nan)
            }

            // log(Gamma(1-z))
            let (lgRe, lgIm) = complexLogGammaPositive(1 - re, -im)

            // log(pi) - log(sin(pi*z)) - log(Gamma(1-z))
            return (Darwin.log(.pi) - logSinRe - lgRe, -logSinIm - lgIm)
        }

        return complexLogGammaPositive(re, im)
    }

    /// Lanczos log-gamma for Re(z) >= 0.5
    private static func complexLogGammaPositive(_ re: Double, _ im: Double) -> (re: Double, im: Double) {
        let g = 7.0
        let zRe = re - 1
        let zIm = im

        // Sum of Lanczos series
        var sumRe = lanczosCoeffs[0]
        var sumIm = 0.0

        for i in 1..<lanczosCoeffs.count {
            let denomRe = zRe + Double(i)
            let denomIm = zIm
            guard let (invRe, invIm) = ComplexHelper.divide(1, 0, denomRe, denomIm) else {
                return (.nan, .nan)
            }
            sumRe += lanczosCoeffs[i] * invRe
            sumIm += lanczosCoeffs[i] * invIm
        }

        // t = z + g + 0.5
        let tRe = zRe + g + 0.5
        let tIm = zIm

        // log(sqrt(2*pi)) + (z + 0.5) * log(t) - t + log(sum)
        let halfLog2pi = 0.5 * Darwin.log(2 * .pi)

        // log(t)
        guard let (logTRe, logTIm) = ComplexHelper.log(tRe, tIm) else {
            return (.nan, .nan)
        }

        // (z + 0.5) * log(t)
        let (termRe, termIm) = ComplexHelper.multiply(zRe + 0.5, zIm, logTRe, logTIm)

        // log(sum)
        guard let (logSumRe, logSumIm) = ComplexHelper.log(sumRe, sumIm) else {
            return (.nan, .nan)
        }

        // halfLog2pi + termRe - tRe + logSumRe
        let resultRe = halfLog2pi + termRe - tRe + logSumRe
        let resultIm = termIm - tIm + logSumIm

        return (resultRe, resultIm)
    }

    /// Complex power: (a+bi)^(c+di) = exp((c+di) * log(a+bi))
    private static func complexPow(_ aRe: Double, _ aIm: Double, _ cRe: Double, _ cIm: Double) -> (re: Double, im: Double) {
        guard let (logRe, logIm) = ComplexHelper.log(aRe, aIm) else {
            return (.nan, .nan)
        }
        let (prodRe, prodIm) = ComplexHelper.multiply(cRe, cIm, logRe, logIm)
        return ComplexHelper.exp(prodRe, prodIm)
    }
}
