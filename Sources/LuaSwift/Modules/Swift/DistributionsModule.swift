//
//  DistributionsModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed probability distributions module for LuaSwift.
///
/// Implements scipy.stats-compatible probability distributions with
/// pdf, cdf, ppf, rvs, mean, var, std methods for each distribution.
///
/// ## Supported Distributions
///
/// - `norm` - Normal (Gaussian) distribution
/// - `uniform` - Uniform distribution
/// - `expon` - Exponential distribution
/// - `t` - Student's t distribution
/// - `chi2` - Chi-squared distribution
/// - `f` - F distribution
/// - `gamma_dist` - Gamma distribution (named to avoid conflict with gamma function)
/// - `beta_dist` - Beta distribution (named to avoid conflict with beta function)
///
/// ## Usage
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- Normal distribution
/// local x = math.stats.norm.pdf(0)         -- ~0.3989
/// local p = math.stats.norm.cdf(1.96)      -- ~0.975
/// local q = math.stats.norm.ppf(0.975)     -- ~1.96
/// local samples = math.stats.norm.rvs(100) -- 100 random samples
///
/// -- With loc/scale parameters
/// local mu, sigma = 5, 2
/// local y = math.stats.norm.pdf(5, mu, sigma)
/// ```
public struct DistributionsModule {

    // MARK: - Mathematical Helper Functions

    /// Error function approximation using Horner form of Abramowitz and Stegun 7.1.26
    private static func erf(_ x: Double) -> Double {
        let a1 =  0.254829592
        let a2 = -0.284496736
        let a3 =  1.421413741
        let a4 = -1.453152027
        let a5 =  1.061405429
        let p  =  0.3275911

        let sign = x < 0 ? -1.0 : 1.0
        let absX = abs(x)

        let t = 1.0 / (1.0 + p * absX)
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX)

        return sign * y
    }

    /// Complementary error function
    private static func erfc(_ x: Double) -> Double {
        return 1.0 - erf(x)
    }

    /// Inverse error function using Winitzki approximation
    private static func erfinv(_ x: Double) -> Double {
        guard x > -1 && x < 1 else {
            if x == -1 { return -.infinity }
            if x == 1 { return .infinity }
            return .nan
        }

        let a = 0.147
        let ln1mx2 = log(1.0 - x * x)
        let term1 = 2.0 / (Double.pi * a) + ln1mx2 / 2.0
        let term2 = ln1mx2 / a

        let sign = x < 0 ? -1.0 : 1.0
        return sign * sqrt(sqrt(term1 * term1 - term2) - term1)
    }

    /// Gamma function using Lanczos approximation
    private static func gamma(_ x: Double) -> Double {
        if x <= 0 && x == floor(x) {
            return .infinity // Poles at non-positive integers
        }

        // Reflection formula for negative values
        if x < 0.5 {
            return Double.pi / (sin(Double.pi * x) * gamma(1.0 - x))
        }

        // Lanczos approximation coefficients
        let g = 7.0
        let c = [
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

        let z = x - 1.0
        var sum = c[0]
        for i in 1..<c.count {
            sum += c[i] / (z + Double(i))
        }

        let t = z + g + 0.5
        return sqrt(2.0 * Double.pi) * pow(t, z + 0.5) * exp(-t) * sum
    }

    /// Log gamma function
    private static func lgamma(_ x: Double) -> Double {
        return log(gamma(x))
    }

    /// Lower incomplete gamma function P(a, x) = γ(a,x)/Γ(a)
    /// Uses series expansion for small x, continued fraction for large x
    private static func gammainc(_ a: Double, _ x: Double) -> Double {
        if x < 0 || a <= 0 { return .nan }
        if x == 0 { return 0.0 }

        // Use series expansion if x < a + 1
        if x < a + 1.0 {
            return gammaincSeries(a, x)
        } else {
            // Use continued fraction for x >= a + 1
            return 1.0 - gammaincCF(a, x)
        }
    }

    /// Series expansion for lower incomplete gamma
    private static func gammaincSeries(_ a: Double, _ x: Double) -> Double {
        let maxIterations = 200
        let epsilon = 1e-15

        var sum = 1.0 / a
        var term = sum

        for n in 1..<maxIterations {
            term *= x / (a + Double(n))
            sum += term
            if abs(term) < abs(sum) * epsilon {
                break
            }
        }

        return sum * exp(-x + a * log(x) - lgamma(a))
    }

    /// Continued fraction for upper incomplete gamma
    private static func gammaincCF(_ a: Double, _ x: Double) -> Double {
        let maxIterations = 200
        let epsilon = 1e-15

        var b = x + 1.0 - a
        var c = 1.0 / 1e-30
        var d = 1.0 / b
        var h = d

        for i in 1..<maxIterations {
            let an = -Double(i) * (Double(i) - a)
            b += 2.0
            d = an * d + b
            if abs(d) < 1e-30 { d = 1e-30 }
            c = b + an / c
            if abs(c) < 1e-30 { c = 1e-30 }
            d = 1.0 / d
            let del = d * c
            h *= del
            if abs(del - 1.0) < epsilon {
                break
            }
        }

        return exp(-x + a * log(x) - lgamma(a)) * h
    }

    /// Regularized incomplete beta function I_x(a, b)
    private static func betainc(_ a: Double, _ b: Double, _ x: Double) -> Double {
        if x < 0 || x > 1 { return .nan }
        if x == 0 { return 0.0 }
        if x == 1 { return 1.0 }

        // Use symmetry relation if x > (a+1)/(a+b+2)
        if x > (a + 1.0) / (a + b + 2.0) {
            return 1.0 - betainc(b, a, 1.0 - x)
        }

        let bt = exp(lgamma(a + b) - lgamma(a) - lgamma(b) + a * log(x) + b * log(1.0 - x))
        return bt * betaincCF(a, b, x) / a
    }

    /// Continued fraction for incomplete beta
    private static func betaincCF(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let maxIterations = 200
        let epsilon = 1e-15

        let qab = a + b
        let qap = a + 1.0
        let qam = a - 1.0

        var c = 1.0
        var d = 1.0 - qab * x / qap
        if abs(d) < 1e-30 { d = 1e-30 }
        d = 1.0 / d
        var h = d

        for m in 1..<maxIterations {
            let m2 = 2 * m
            var aa = Double(m) * (b - Double(m)) * x / ((qam + Double(m2)) * (a + Double(m2)))
            d = 1.0 + aa * d
            if abs(d) < 1e-30 { d = 1e-30 }
            c = 1.0 + aa / c
            if abs(c) < 1e-30 { c = 1e-30 }
            d = 1.0 / d
            h *= d * c

            aa = -(a + Double(m)) * (qab + Double(m)) * x / ((a + Double(m2)) * (qap + Double(m2)))
            d = 1.0 + aa * d
            if abs(d) < 1e-30 { d = 1e-30 }
            c = 1.0 + aa / c
            if abs(c) < 1e-30 { c = 1e-30 }
            d = 1.0 / d
            let del = d * c
            h *= del
            if abs(del - 1.0) < epsilon {
                break
            }
        }

        return h
    }

    /// Beta function B(a, b) = Γ(a)Γ(b)/Γ(a+b)
    private static func beta(_ a: Double, _ b: Double) -> Double {
        return exp(lgamma(a) + lgamma(b) - lgamma(a + b))
    }

    /// Box-Muller transform for normal random variates
    private static func randomNormal() -> Double {
        let u1 = Double.random(in: Double.ulpOfOne..<1.0)
        let u2 = Double.random(in: 0..<1.0)
        return sqrt(-2.0 * log(u1)) * cos(2.0 * Double.pi * u2)
    }

    /// Generate gamma random variate using Marsaglia and Tsang's method
    private static func randomGamma(_ shape: Double) -> Double {
        if shape < 1 {
            // For shape < 1, use shape + 1 and transform
            return randomGamma(shape + 1) * pow(Double.random(in: 0..<1), 1.0 / shape)
        }

        let d = shape - 1.0 / 3.0
        let c = 1.0 / sqrt(9.0 * d)

        while true {
            var x: Double
            var v: Double

            repeat {
                x = randomNormal()
                v = 1.0 + c * x
            } while v <= 0

            v = v * v * v
            let u = Double.random(in: 0..<1)

            if u < 1.0 - 0.0331 * (x * x) * (x * x) {
                return d * v
            }

            if log(u) < 0.5 * x * x + d * (1.0 - v + log(v)) {
                return d * v
            }
        }
    }

    // MARK: - Registration

    /// Register the distributions module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.distributions then luaswift.distributions = {} end

                -- Ensure math.stats exists
                if not math.stats then math.stats = {} end
                """)

            // Register all distribution callbacks
            registerNorm(in: engine)
            registerUniform(in: engine)
            registerExpon(in: engine)
            registerT(in: engine)
            registerChi2(in: engine)
            registerF(in: engine)
            registerGammaDist(in: engine)
            registerBetaDist(in: engine)

        } catch {
            // Silently fail
        }
    }

    // MARK: - Normal Distribution

    private static func registerNorm(in engine: LuaEngine) {
        // norm.pdf(x, loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_pdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            let pdf = exp(-0.5 * z * z) / (scale * sqrt(2.0 * Double.pi))
            return .number(pdf)
        }

        // norm.cdf(x, loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_cdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            let cdf = 0.5 * (1.0 + erf(z / sqrt(2.0)))
            return .number(cdf)
        }

        // norm.ppf(p, loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_ppf") { args in
            guard let p = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            let ppf = loc + scale * sqrt(2.0) * erfinv(2.0 * p - 1.0)
            return .number(ppf)
        }

        // norm.rvs(size=1, loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_rvs") { args in
            let size = args.first?.intValue ?? 1
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            if size == 1 {
                return .number(loc + scale * randomNormal())
            }

            var samples: [LuaValue] = []
            for _ in 0..<size {
                samples.append(.number(loc + scale * randomNormal()))
            }
            return .array(samples)
        }

        // norm.mean(loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_mean") { args in
            let loc = args.first?.numberValue ?? 0.0
            return .number(loc)
        }

        // norm.var(loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_var") { args in
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : (args.first?.numberValue ?? 1.0)
            return .number(scale * scale)
        }

        // norm.std(loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_std") { args in
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : (args.first?.numberValue ?? 1.0)
            return .number(scale)
        }

        // Set up Lua wrapper
        do {
            try engine.run("""
                math.stats.norm = {
                    pdf = function(x, loc, scale) return _dist_norm_pdf(x, loc or 0, scale or 1) end,
                    cdf = function(x, loc, scale) return _dist_norm_cdf(x, loc or 0, scale or 1) end,
                    ppf = function(p, loc, scale) return _dist_norm_ppf(p, loc or 0, scale or 1) end,
                    rvs = function(size, loc, scale) return _dist_norm_rvs(size or 1, loc or 0, scale or 1) end,
                    mean = function(loc, scale) return _dist_norm_mean(loc or 0, scale or 1) end,
                    var = function(loc, scale) return _dist_norm_var(loc or 0, scale or 1) end,
                    std = function(loc, scale) return _dist_norm_std(loc or 0, scale or 1) end
                }
                luaswift.distributions.norm = math.stats.norm
                """)
        } catch {}
    }

    // MARK: - Uniform Distribution

    private static func registerUniform(in engine: LuaEngine) {
        // uniform.pdf(x, loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_pdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            if x >= loc && x <= loc + scale {
                return .number(1.0 / scale)
            }
            return .number(0.0)
        }

        // uniform.cdf(x, loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_cdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            if x < loc { return .number(0.0) }
            if x > loc + scale { return .number(1.0) }
            return .number((x - loc) / scale)
        }

        // uniform.ppf(p, loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_ppf") { args in
            guard let p = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            return .number(loc + scale * p)
        }

        // uniform.rvs(size=1, loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_rvs") { args in
            let size = args.first?.intValue ?? 1
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            if size == 1 {
                return .number(loc + scale * Double.random(in: 0..<1))
            }

            var samples: [LuaValue] = []
            for _ in 0..<size {
                samples.append(.number(loc + scale * Double.random(in: 0..<1)))
            }
            return .array(samples)
        }

        // uniform.mean(loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_mean") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            return .number(loc + scale / 2.0)
        }

        // uniform.var(loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_var") { args in
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : (args.first?.numberValue ?? 1.0)
            return .number(scale * scale / 12.0)
        }

        // uniform.std(loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_std") { args in
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : (args.first?.numberValue ?? 1.0)
            return .number(scale / sqrt(12.0))
        }

        do {
            try engine.run("""
                math.stats.uniform = {
                    pdf = function(x, loc, scale) return _dist_uniform_pdf(x, loc or 0, scale or 1) end,
                    cdf = function(x, loc, scale) return _dist_uniform_cdf(x, loc or 0, scale or 1) end,
                    ppf = function(p, loc, scale) return _dist_uniform_ppf(p, loc or 0, scale or 1) end,
                    rvs = function(size, loc, scale) return _dist_uniform_rvs(size or 1, loc or 0, scale or 1) end,
                    mean = function(loc, scale) return _dist_uniform_mean(loc or 0, scale or 1) end,
                    var = function(loc, scale) return _dist_uniform_var(loc or 0, scale or 1) end,
                    std = function(loc, scale) return _dist_uniform_std(loc or 0, scale or 1) end
                }
                luaswift.distributions.uniform = math.stats.uniform
                """)
        } catch {}
    }

    // MARK: - Exponential Distribution

    private static func registerExpon(in engine: LuaEngine) {
        // expon.pdf(x, loc=0, scale=1) where scale = 1/lambda
        engine.registerFunction(name: "_dist_expon_pdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            let z = x - loc
            if z < 0 { return .number(0.0) }
            return .number(exp(-z / scale) / scale)
        }

        // expon.cdf(x, loc=0, scale=1)
        engine.registerFunction(name: "_dist_expon_cdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            let z = x - loc
            if z < 0 { return .number(0.0) }
            return .number(1.0 - exp(-z / scale))
        }

        // expon.ppf(p, loc=0, scale=1)
        engine.registerFunction(name: "_dist_expon_ppf") { args in
            guard let p = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            return .number(loc - scale * log(1.0 - p))
        }

        // expon.rvs(size=1, loc=0, scale=1)
        engine.registerFunction(name: "_dist_expon_rvs") { args in
            let size = args.first?.intValue ?? 1
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

            if size == 1 {
                return .number(loc - scale * log(Double.random(in: Double.ulpOfOne..<1.0)))
            }

            var samples: [LuaValue] = []
            for _ in 0..<size {
                samples.append(.number(loc - scale * log(Double.random(in: Double.ulpOfOne..<1.0))))
            }
            return .array(samples)
        }

        // expon.mean/var/std
        engine.registerFunction(name: "_dist_expon_mean") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            return .number(loc + scale)
        }

        engine.registerFunction(name: "_dist_expon_var") { args in
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : (args.first?.numberValue ?? 1.0)
            return .number(scale * scale)
        }

        engine.registerFunction(name: "_dist_expon_std") { args in
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : (args.first?.numberValue ?? 1.0)
            return .number(scale)
        }

        do {
            try engine.run("""
                math.stats.expon = {
                    pdf = function(x, loc, scale) return _dist_expon_pdf(x, loc or 0, scale or 1) end,
                    cdf = function(x, loc, scale) return _dist_expon_cdf(x, loc or 0, scale or 1) end,
                    ppf = function(p, loc, scale) return _dist_expon_ppf(p, loc or 0, scale or 1) end,
                    rvs = function(size, loc, scale) return _dist_expon_rvs(size or 1, loc or 0, scale or 1) end,
                    mean = function(loc, scale) return _dist_expon_mean(loc or 0, scale or 1) end,
                    var = function(loc, scale) return _dist_expon_var(loc or 0, scale or 1) end,
                    std = function(loc, scale) return _dist_expon_std(loc or 0, scale or 1) end
                }
                luaswift.distributions.expon = math.stats.expon
                """)
        } catch {}
    }

    // MARK: - Student's t Distribution

    private static func registerT(in engine: LuaEngine) {
        // t.pdf(x, df, loc=0, scale=1)
        engine.registerFunction(name: "_dist_t_pdf") { args in
            guard let x = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            let coef = gamma((df + 1) / 2.0) / (sqrt(df * Double.pi) * gamma(df / 2.0))
            let pdf = coef * pow(1.0 + z * z / df, -(df + 1) / 2.0) / scale
            return .number(pdf)
        }

        // t.cdf(x, df, loc=0, scale=1) using incomplete beta
        engine.registerFunction(name: "_dist_t_cdf") { args in
            guard let x = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            let t2 = z * z
            let p = betainc(df / 2.0, 0.5, df / (df + t2))

            if z >= 0 {
                return .number(1.0 - 0.5 * p)
            } else {
                return .number(0.5 * p)
            }
        }

        // t.ppf - using Newton-Raphson iteration
        engine.registerFunction(name: "_dist_t_ppf") { args in
            guard let p = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            // Use normal approximation as starting point
            var x = sqrt(2.0) * erfinv(2.0 * p - 1.0)

            // Newton-Raphson iteration
            for _ in 0..<50 {
                let t2 = x * x
                let cdfVal = 0.5 + 0.5 * (1.0 - betainc(df / 2.0, 0.5, df / (df + t2))) * (x >= 0 ? 1 : -1)
                let coef = gamma((df + 1) / 2.0) / (sqrt(df * Double.pi) * gamma(df / 2.0))
                let pdfVal = coef * pow(1.0 + t2 / df, -(df + 1) / 2.0)

                let dx = (cdfVal - p) / pdfVal
                x -= dx
                if abs(dx) < 1e-10 { break }
            }

            return .number(loc + scale * x)
        }

        // t.rvs - using ratio of normal and chi-squared
        engine.registerFunction(name: "_dist_t_rvs") { args in
            let size = args.first?.intValue ?? 1
            guard let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            func randomT() -> Double {
                let z = randomNormal()
                let chi2 = randomGamma(df / 2.0) * 2.0
                return z / sqrt(chi2 / df)
            }

            if size == 1 {
                return .number(loc + scale * randomT())
            }

            var samples: [LuaValue] = []
            for _ in 0..<size {
                samples.append(.number(loc + scale * randomT()))
            }
            return .array(samples)
        }

        // t.mean/var/std
        engine.registerFunction(name: "_dist_t_mean") { args in
            guard let df = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            if df > 1 { return .number(loc) }
            return .number(Double.nan)
        }

        engine.registerFunction(name: "_dist_t_var") { args in
            guard let df = args.first?.numberValue else { return .nil }
            // Args are (df, loc, scale) - scale is at index 2
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            if df > 2 {
                return .number(scale * scale * df / (df - 2))
            } else if df > 1 {
                return .number(Double.infinity)
            }
            return .number(Double.nan)
        }

        engine.registerFunction(name: "_dist_t_std") { args in
            guard let df = args.first?.numberValue else { return .nil }
            // Args are (df, loc, scale) - scale is at index 2
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            if df > 2 {
                return .number(scale * sqrt(df / (df - 2)))
            } else if df > 1 {
                return .number(Double.infinity)
            }
            return .number(Double.nan)
        }

        do {
            try engine.run("""
                math.stats.t = {
                    pdf = function(x, df, loc, scale) return _dist_t_pdf(x, df, loc or 0, scale or 1) end,
                    cdf = function(x, df, loc, scale) return _dist_t_cdf(x, df, loc or 0, scale or 1) end,
                    ppf = function(p, df, loc, scale) return _dist_t_ppf(p, df, loc or 0, scale or 1) end,
                    rvs = function(size, df, loc, scale) return _dist_t_rvs(size or 1, df, loc or 0, scale or 1) end,
                    mean = function(df, loc, scale) return _dist_t_mean(df, loc or 0, scale or 1) end,
                    var = function(df, loc, scale) return _dist_t_var(df, loc or 0, scale or 1) end,
                    std = function(df, loc, scale) return _dist_t_std(df, loc or 0, scale or 1) end
                }
                luaswift.distributions.t = math.stats.t
                """)
        } catch {}
    }

    // MARK: - Chi-squared Distribution

    private static func registerChi2(in engine: LuaEngine) {
        // chi2.pdf(x, df, loc=0, scale=1)
        engine.registerFunction(name: "_dist_chi2_pdf") { args in
            guard let x = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            if z <= 0 { return .number(0.0) }

            let k2 = df / 2.0
            let pdf = pow(z, k2 - 1) * exp(-z / 2.0) / (pow(2.0, k2) * gamma(k2)) / scale
            return .number(pdf)
        }

        // chi2.cdf(x, df, loc=0, scale=1)
        engine.registerFunction(name: "_dist_chi2_cdf") { args in
            guard let x = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            if z <= 0 { return .number(0.0) }

            return .number(gammainc(df / 2.0, z / 2.0))
        }

        // chi2.ppf - Newton-Raphson
        engine.registerFunction(name: "_dist_chi2_ppf") { args in
            guard let p = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            // Wilson-Hilferty approximation as starting point
            var x = df * pow(1.0 - 2.0 / (9.0 * df) + sqrt(2.0) * erfinv(2.0 * p - 1.0) * sqrt(2.0 / (9.0 * df)), 3)
            if x < 0.01 { x = 0.01 }

            // Newton-Raphson
            let k2 = df / 2.0
            for _ in 0..<50 {
                let cdfVal = gammainc(k2, x / 2.0)
                let pdfVal = pow(x, k2 - 1) * exp(-x / 2.0) / (pow(2.0, k2) * gamma(k2))

                let dx = (cdfVal - p) / pdfVal
                x -= dx
                if x < 0.001 { x = 0.001 }
                if abs(dx) < 1e-10 { break }
            }

            return .number(loc + scale * x)
        }

        // chi2.rvs
        engine.registerFunction(name: "_dist_chi2_rvs") { args in
            let size = args.first?.intValue ?? 1
            guard let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            if size == 1 {
                return .number(loc + scale * randomGamma(df / 2.0) * 2.0)
            }

            var samples: [LuaValue] = []
            for _ in 0..<size {
                samples.append(.number(loc + scale * randomGamma(df / 2.0) * 2.0))
            }
            return .array(samples)
        }

        // chi2.mean/var/std
        engine.registerFunction(name: "_dist_chi2_mean") { args in
            guard let df = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            return .number(loc + scale * df)
        }

        engine.registerFunction(name: "_dist_chi2_var") { args in
            guard let df = args.first?.numberValue else { return .nil }
            // Args are (df, loc, scale) - scale is at index 2
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            return .number(scale * scale * 2 * df)
        }

        engine.registerFunction(name: "_dist_chi2_std") { args in
            guard let df = args.first?.numberValue else { return .nil }
            // Args are (df, loc, scale) - scale is at index 2
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            return .number(scale * sqrt(2 * df))
        }

        do {
            try engine.run("""
                math.stats.chi2 = {
                    pdf = function(x, df, loc, scale) return _dist_chi2_pdf(x, df, loc or 0, scale or 1) end,
                    cdf = function(x, df, loc, scale) return _dist_chi2_cdf(x, df, loc or 0, scale or 1) end,
                    ppf = function(p, df, loc, scale) return _dist_chi2_ppf(p, df, loc or 0, scale or 1) end,
                    rvs = function(size, df, loc, scale) return _dist_chi2_rvs(size or 1, df, loc or 0, scale or 1) end,
                    mean = function(df, loc, scale) return _dist_chi2_mean(df, loc or 0, scale or 1) end,
                    var = function(df, loc, scale) return _dist_chi2_var(df, loc or 0, scale or 1) end,
                    std = function(df, loc, scale) return _dist_chi2_std(df, loc or 0, scale or 1) end
                }
                luaswift.distributions.chi2 = math.stats.chi2
                """)
        } catch {}
    }

    // MARK: - F Distribution

    private static func registerF(in engine: LuaEngine) {
        // f.pdf(x, dfn, dfd, loc=0, scale=1)
        engine.registerFunction(name: "_dist_f_pdf") { args in
            guard let x = args.first?.numberValue,
                  let dfn = args.count > 1 ? args[1].numberValue : nil,
                  let dfd = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            if z <= 0 { return .number(0.0) }

            let num = pow(dfn * z, dfn / 2.0) * pow(dfd, dfd / 2.0)
            let den = pow(dfn * z + dfd, (dfn + dfd) / 2.0)
            let coef = 1.0 / (z * beta(dfn / 2.0, dfd / 2.0))

            return .number(coef * num / den / scale)
        }

        // f.cdf(x, dfn, dfd, loc=0, scale=1)
        engine.registerFunction(name: "_dist_f_cdf") { args in
            guard let x = args.first?.numberValue,
                  let dfn = args.count > 1 ? args[1].numberValue : nil,
                  let dfd = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            if z <= 0 { return .number(0.0) }

            let u = dfn * z / (dfn * z + dfd)
            return .number(betainc(dfn / 2.0, dfd / 2.0, u))
        }

        // f.ppf - Newton-Raphson
        engine.registerFunction(name: "_dist_f_ppf") { args in
            guard let p = args.first?.numberValue,
                  let dfn = args.count > 1 ? args[1].numberValue : nil,
                  let dfd = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0

            // Starting point: use median approximation
            var x = dfd / (dfd - 2) * (dfn > 2 ? (dfn - 2) / dfn : 1.0)
            if x < 0.01 { x = 0.01 }

            // Newton-Raphson
            for _ in 0..<100 {
                let u = dfn * x / (dfn * x + dfd)
                let cdfVal = betainc(dfn / 2.0, dfd / 2.0, u)

                let num = pow(dfn * x, dfn / 2.0) * pow(dfd, dfd / 2.0)
                let den = pow(dfn * x + dfd, (dfn + dfd) / 2.0)
                let pdfVal = num / den / (x * beta(dfn / 2.0, dfd / 2.0))

                if pdfVal < 1e-30 { break }
                let dx = (cdfVal - p) / pdfVal
                x -= dx
                if x < 0.001 { x = 0.001 }
                if abs(dx) < 1e-10 { break }
            }

            return .number(loc + scale * x)
        }

        // f.rvs
        engine.registerFunction(name: "_dist_f_rvs") { args in
            let size = args.first?.intValue ?? 1
            guard let dfn = args.count > 1 ? args[1].numberValue : nil,
                  let dfd = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0

            func randomF() -> Double {
                let chi1 = randomGamma(dfn / 2.0) * 2.0
                let chi2 = randomGamma(dfd / 2.0) * 2.0
                return (chi1 / dfn) / (chi2 / dfd)
            }

            if size == 1 {
                return .number(loc + scale * randomF())
            }

            var samples: [LuaValue] = []
            for _ in 0..<size {
                samples.append(.number(loc + scale * randomF()))
            }
            return .array(samples)
        }

        // f.mean/var/std
        engine.registerFunction(name: "_dist_f_mean") { args in
            guard let dfd = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            if dfd > 2 {
                return .number(loc + scale * dfd / (dfd - 2))
            }
            return .number(Double.nan)
        }

        engine.registerFunction(name: "_dist_f_var") { args in
            guard let dfn = args.first?.numberValue,
                  let dfd = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            // Args are (dfn, dfd, loc, scale) - scale is at index 3
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            if dfd > 4 {
                let num = 2 * dfd * dfd * (dfn + dfd - 2)
                let den = dfn * (dfd - 2) * (dfd - 2) * (dfd - 4)
                return .number(scale * scale * num / den)
            }
            return .number(Double.nan)
        }

        engine.registerFunction(name: "_dist_f_std") { args in
            guard let dfn = args.first?.numberValue,
                  let dfd = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            // Args are (dfn, dfd, loc, scale) - scale is at index 3
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            if dfd > 4 {
                let num = 2 * dfd * dfd * (dfn + dfd - 2)
                let den = dfn * (dfd - 2) * (dfd - 2) * (dfd - 4)
                return .number(scale * sqrt(num / den))
            }
            return .number(Double.nan)
        }

        do {
            try engine.run("""
                math.stats.f = {
                    pdf = function(x, dfn, dfd, loc, scale) return _dist_f_pdf(x, dfn, dfd, loc or 0, scale or 1) end,
                    cdf = function(x, dfn, dfd, loc, scale) return _dist_f_cdf(x, dfn, dfd, loc or 0, scale or 1) end,
                    ppf = function(p, dfn, dfd, loc, scale) return _dist_f_ppf(p, dfn, dfd, loc or 0, scale or 1) end,
                    rvs = function(size, dfn, dfd, loc, scale) return _dist_f_rvs(size or 1, dfn, dfd, loc or 0, scale or 1) end,
                    mean = function(dfn, dfd, loc, scale) return _dist_f_mean(dfn, dfd, loc or 0, scale or 1) end,
                    var = function(dfn, dfd, loc, scale) return _dist_f_var(dfn, dfd, loc or 0, scale or 1) end,
                    std = function(dfn, dfd, loc, scale) return _dist_f_std(dfn, dfd, loc or 0, scale or 1) end
                }
                luaswift.distributions.f = math.stats.f
                """)
        } catch {}
    }

    // MARK: - Gamma Distribution

    private static func registerGammaDist(in engine: LuaEngine) {
        // gamma_dist.pdf(x, a, loc=0, scale=1) where a is shape parameter
        engine.registerFunction(name: "_dist_gamma_pdf") { args in
            guard let x = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            if z <= 0 { return .number(0.0) }

            let pdf = pow(z, a - 1) * exp(-z) / gamma(a) / scale
            return .number(pdf)
        }

        // gamma_dist.cdf(x, a, loc=0, scale=1)
        engine.registerFunction(name: "_dist_gamma_cdf") { args in
            guard let x = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            if z <= 0 { return .number(0.0) }

            return .number(gammainc(a, z))
        }

        // gamma_dist.ppf - Newton-Raphson
        engine.registerFunction(name: "_dist_gamma_ppf") { args in
            guard let p = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            // Starting point
            var x = a // Mean as starting point
            if x < 0.1 { x = 0.1 }

            // Newton-Raphson
            for _ in 0..<100 {
                let cdfVal = gammainc(a, x)
                let pdfVal = pow(x, a - 1) * exp(-x) / gamma(a)

                if pdfVal < 1e-30 { break }
                let dx = (cdfVal - p) / pdfVal
                x -= dx
                if x < 0.001 { x = 0.001 }
                if abs(dx) < 1e-10 { break }
            }

            return .number(loc + scale * x)
        }

        // gamma_dist.rvs
        engine.registerFunction(name: "_dist_gamma_rvs") { args in
            let size = args.first?.intValue ?? 1
            guard let a = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            if size == 1 {
                return .number(loc + scale * randomGamma(a))
            }

            var samples: [LuaValue] = []
            for _ in 0..<size {
                samples.append(.number(loc + scale * randomGamma(a)))
            }
            return .array(samples)
        }

        // gamma_dist.mean/var/std
        engine.registerFunction(name: "_dist_gamma_mean") { args in
            guard let a = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            return .number(loc + scale * a)
        }

        engine.registerFunction(name: "_dist_gamma_var") { args in
            guard let a = args.first?.numberValue else { return .nil }
            // Args are (a, loc, scale) - scale is at index 2
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            return .number(scale * scale * a)
        }

        engine.registerFunction(name: "_dist_gamma_std") { args in
            guard let a = args.first?.numberValue else { return .nil }
            // Args are (a, loc, scale) - scale is at index 2
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            return .number(scale * sqrt(a))
        }

        do {
            try engine.run("""
                math.stats.gamma_dist = {
                    pdf = function(x, a, loc, scale) return _dist_gamma_pdf(x, a, loc or 0, scale or 1) end,
                    cdf = function(x, a, loc, scale) return _dist_gamma_cdf(x, a, loc or 0, scale or 1) end,
                    ppf = function(p, a, loc, scale) return _dist_gamma_ppf(p, a, loc or 0, scale or 1) end,
                    rvs = function(size, a, loc, scale) return _dist_gamma_rvs(size or 1, a, loc or 0, scale or 1) end,
                    mean = function(a, loc, scale) return _dist_gamma_mean(a, loc or 0, scale or 1) end,
                    var = function(a, loc, scale) return _dist_gamma_var(a, loc or 0, scale or 1) end,
                    std = function(a, loc, scale) return _dist_gamma_std(a, loc or 0, scale or 1) end
                }
                luaswift.distributions.gamma_dist = math.stats.gamma_dist
                """)
        } catch {}
    }

    // MARK: - Beta Distribution

    private static func registerBetaDist(in engine: LuaEngine) {
        // beta_dist.pdf(x, a, b, loc=0, scale=1)
        engine.registerFunction(name: "_dist_beta_pdf") { args in
            guard let x = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil,
                  let b = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            if z <= 0 || z >= 1 { return .number(0.0) }

            let pdf = pow(z, a - 1) * pow(1 - z, b - 1) / beta(a, b) / scale
            return .number(pdf)
        }

        // beta_dist.cdf(x, a, b, loc=0, scale=1)
        engine.registerFunction(name: "_dist_beta_cdf") { args in
            guard let x = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil,
                  let b = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0

            let z = (x - loc) / scale
            if z <= 0 { return .number(0.0) }
            if z >= 1 { return .number(1.0) }

            return .number(betainc(a, b, z))
        }

        // beta_dist.ppf - Newton-Raphson
        engine.registerFunction(name: "_dist_beta_ppf") { args in
            guard let p = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil,
                  let b = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0

            // Starting point: use mean
            var x = a / (a + b)

            // Newton-Raphson
            for _ in 0..<100 {
                let cdfVal = betainc(a, b, x)
                let pdfVal = pow(x, a - 1) * pow(1 - x, b - 1) / beta(a, b)

                if pdfVal < 1e-30 { break }
                let dx = (cdfVal - p) / pdfVal
                x -= dx
                if x < 0.001 { x = 0.001 }
                if x > 0.999 { x = 0.999 }
                if abs(dx) < 1e-10 { break }
            }

            return .number(loc + scale * x)
        }

        // beta_dist.rvs - using gamma ratio
        engine.registerFunction(name: "_dist_beta_rvs") { args in
            let size = args.first?.intValue ?? 1
            guard let a = args.count > 1 ? args[1].numberValue : nil,
                  let b = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0

            func randomBeta() -> Double {
                let g1 = randomGamma(a)
                let g2 = randomGamma(b)
                return g1 / (g1 + g2)
            }

            if size == 1 {
                return .number(loc + scale * randomBeta())
            }

            var samples: [LuaValue] = []
            for _ in 0..<size {
                samples.append(.number(loc + scale * randomBeta()))
            }
            return .array(samples)
        }

        // beta_dist.mean/var/std
        engine.registerFunction(name: "_dist_beta_mean") { args in
            guard let a = args.first?.numberValue,
                  let b = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            return .number(loc + scale * a / (a + b))
        }

        engine.registerFunction(name: "_dist_beta_var") { args in
            guard let a = args.first?.numberValue,
                  let b = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            // Args are (a, b, loc, scale) - scale is at index 3
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let apb = a + b
            return .number(scale * scale * a * b / (apb * apb * (apb + 1)))
        }

        engine.registerFunction(name: "_dist_beta_std") { args in
            guard let a = args.first?.numberValue,
                  let b = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            // Args are (a, b, loc, scale) - scale is at index 3
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let apb = a + b
            return .number(scale * sqrt(a * b / (apb * apb * (apb + 1))))
        }

        do {
            try engine.run("""
                math.stats.beta_dist = {
                    pdf = function(x, a, b, loc, scale) return _dist_beta_pdf(x, a, b, loc or 0, scale or 1) end,
                    cdf = function(x, a, b, loc, scale) return _dist_beta_cdf(x, a, b, loc or 0, scale or 1) end,
                    ppf = function(p, a, b, loc, scale) return _dist_beta_ppf(p, a, b, loc or 0, scale or 1) end,
                    rvs = function(size, a, b, loc, scale) return _dist_beta_rvs(size or 1, a, b, loc or 0, scale or 1) end,
                    mean = function(a, b, loc, scale) return _dist_beta_mean(a, b, loc or 0, scale or 1) end,
                    var = function(a, b, loc, scale) return _dist_beta_var(a, b, loc or 0, scale or 1) end,
                    std = function(a, b, loc, scale) return _dist_beta_std(a, b, loc or 0, scale or 1) end
                }
                luaswift.distributions.beta_dist = math.stats.beta_dist
                """)
        } catch {}
    }
}
