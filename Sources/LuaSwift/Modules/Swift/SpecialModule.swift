//
//  SpecialModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
import Foundation
import Darwin
import NumericSwift

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

        // Complex-aware zeta function
        engine.registerFunction(name: "_luaswift_special_czeta", callback: czetaCallback)

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

                ----------------------------------------------------------------
                -- Complex Zeta Function: czeta(s)
                --
                -- Returns ζ(s) for complex s = {re=σ, im=t}
                -- Essential for studying Riemann zeros on critical line Re(s) = 0.5
                ----------------------------------------------------------------
                function special.czeta(s)
                    if type(s) == "number" then
                        return _luaswift_special_czeta(s)
                    end
                    if type(s) ~= "table" or s.re == nil or s.im == nil then
                        error("czeta: expected number or complex {re=, im=}", 2)
                    end
                    return _luaswift_special_czeta(s)
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
                    math.special.czeta = special.czeta
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

    /// Beta function B(a,b) = gamma(a)*gamma(b)/gamma(a+b) using NumericSwift
    private static func betaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let a = args[0].numberValue,
              let b = args[1].numberValue else {
            throw LuaError.runtimeError("beta: expected two numbers")
        }
        return .number(NumericSwift.beta(a, b))
    }

    /// Regularized incomplete beta function I_x(a,b) using NumericSwift
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

        return .number(NumericSwift.betainc(a, b, x))
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

    /// Modified Bessel function of the first kind I_n(x) using NumericSwift
    private static func besseliCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let n = args[0].numberValue,
              let x = args[1].numberValue else {
            throw LuaError.runtimeError("besseli: expected two numbers")
        }
        return .number(NumericSwift.besseli(Int(n), x))
    }

    /// Modified Bessel function of the second kind K_n(x) using NumericSwift
    private static func besselkCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let n = args[0].numberValue,
              let x = args[1].numberValue else {
            throw LuaError.runtimeError("besselk: expected two numbers")
        }
        if x <= 0 {
            return .number(.infinity)
        }
        return .number(NumericSwift.besselk(Int(n), x))
    }

    // MARK: - Digamma and Gamma Functions

    /// Digamma function ψ(x) = d/dx ln(Γ(x)) using NumericSwift
    private static func digammaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("digamma: expected number")
        }
        return .number(NumericSwift.digamma(x))
    }

    /// Inverse error function erfinv(x) using NumericSwift
    private static func erfinvCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("erfinv: expected number")
        }

        if x <= -1.0 || x >= 1.0 {
            throw LuaError.runtimeError("erfinv: x must be in (-1, 1)")
        }

        return .number(NumericSwift.erfinv(x))
    }

    /// Inverse complementary error function erfcinv(x) using NumericSwift
    private static func erfcinvCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("erfcinv: expected number")
        }

        if x <= 0.0 || x >= 2.0 {
            throw LuaError.runtimeError("erfcinv: x must be in (0, 2)")
        }

        return .number(NumericSwift.erfcinv(x))
    }

    /// Lower regularized incomplete gamma function P(a, x) using NumericSwift
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

        return .number(NumericSwift.gammainc(a, x))
    }

    /// Upper regularized incomplete gamma function Q(a, x) = 1 - P(a, x) using NumericSwift
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

        return .number(NumericSwift.gammaincc(a, x))
    }

    // MARK: - Elliptic Integrals

    /// Complete elliptic integral of the first kind K(m) using NumericSwift
    private static func ellipkCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let m = args.first?.numberValue else {
            throw LuaError.runtimeError("ellipk: expected number")
        }

        if m < 0 || m >= 1 {
            throw LuaError.runtimeError("ellipk: m must be in [0, 1)")
        }

        return .number(NumericSwift.ellipk(m))
    }

    /// Complete elliptic integral of the second kind E(m) using NumericSwift
    private static func ellipeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let m = args.first?.numberValue else {
            throw LuaError.runtimeError("ellipe: expected number")
        }

        if m < 0 || m > 1 {
            throw LuaError.runtimeError("ellipe: m must be in [0, 1]")
        }

        return .number(NumericSwift.ellipe(m))
    }

    // MARK: - Riemann Zeta Function

    /// Riemann zeta function ζ(s) using NumericSwift
    private static func zetaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let s = args.first?.numberValue else {
            throw LuaError.runtimeError("zeta: expected number")
        }

        return .number(NumericSwift.zeta(s))
    }

    // MARK: - Lambert W Function

    /// Lambert W function W(x) - principal branch using NumericSwift
    private static func lambertwCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.runtimeError("lambertw: expected number")
        }

        let minVal = -1.0 / Darwin.M_E
        if x < minVal {
            throw LuaError.runtimeError("lambertw: x must be >= -1/e")
        }

        return .number(NumericSwift.lambertw(x))
    }

    // MARK: - Complex Gamma Functions

    /// Complex gamma function callback using NumericSwift
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
            let result = NumericSwift.cgamma(Complex(x))
            return ComplexHelper.toResult(result.re, result.im)
        }

        // Handle complex input
        guard let (re, im) = ComplexHelper.toComplex(arg) else {
            throw LuaError.runtimeError("cgamma: expected number or complex")
        }

        let result = NumericSwift.cgamma(Complex(re: re, im: im))
        return ComplexHelper.toResult(result.re, result.im)
    }

    /// Complex log-gamma function callback using NumericSwift
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
            let result = NumericSwift.clgamma(Complex(x))
            return ComplexHelper.toLua(result.re, result.im)
        }

        // Handle complex input
        guard let (re, im) = ComplexHelper.toComplex(arg) else {
            throw LuaError.runtimeError("clgamma: expected number or complex")
        }

        let result = NumericSwift.clgamma(Complex(re: re, im: im))
        return ComplexHelper.toLua(result.re, result.im)
    }

    // MARK: - Complex Zeta Function

    /// Complex Riemann zeta function callback using NumericSwift
    /// czeta(s) computes ζ(s) for complex s
    private static func czetaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.runtimeError("czeta: expected argument")
        }

        // Handle real number input
        if let s = arg.numberValue {
            return .number(NumericSwift.zeta(s))
        }

        // Handle complex input
        guard let (re, im) = ComplexHelper.toComplex(arg) else {
            throw LuaError.runtimeError("czeta: expected number or complex")
        }

        // Pure real case optimization
        if abs(im) < 1e-15 {
            return .number(NumericSwift.zeta(re))
        }

        let result = NumericSwift.czeta(Complex(re: re, im: im))
        return ComplexHelper.toResult(result.re, result.im)
    }

}

#endif  // LUASWIFT_NUMERICSWIFT
