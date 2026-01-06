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
/// - Error functions: erf, erfc
/// - Beta functions: beta, betainc
/// - Bessel functions: j0, j1, jn, y0, y1, yn
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

        // New special functions
        engine.registerFunction(name: "_luaswift_special_digamma", callback: digammaCallback)
        engine.registerFunction(name: "_luaswift_special_erfinv", callback: erfinvCallback)
        engine.registerFunction(name: "_luaswift_special_erfcinv", callback: erfcinvCallback)
        engine.registerFunction(name: "_luaswift_special_gammainc", callback: gammaincCallback)
        engine.registerFunction(name: "_luaswift_special_gammaincc", callback: gammainccCallback)

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
                    math.special.digamma = special.digamma
                    math.special.psi = special.psi
                    math.special.erfinv = special.erfinv
                    math.special.erfcinv = special.erfcinv
                    math.special.gammainc = special.gammainc
                    math.special.gammaincc = special.gammaincc
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
}
