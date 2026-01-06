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

            // Register statistical tests
            registerStatisticalTests(in: engine)

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

    // MARK: - Statistical Tests

    private static func registerStatisticalTests(in engine: LuaEngine) {
        // Helper: compute mean of array
        func mean(_ arr: [Double]) -> Double {
            guard !arr.isEmpty else { return .nan }
            return arr.reduce(0, +) / Double(arr.count)
        }

        // Helper: compute variance of array (sample variance, ddof=1)
        func variance(_ arr: [Double], ddof: Int = 1) -> Double {
            guard arr.count > ddof else { return .nan }
            let m = mean(arr)
            let sumSq = arr.reduce(0.0) { $0 + ($1 - m) * ($1 - m) }
            return sumSq / Double(arr.count - ddof)
        }

        // Helper: compute standard deviation
        func std(_ arr: [Double], ddof: Int = 1) -> Double {
            return sqrt(variance(arr, ddof: ddof))
        }

        // Helper: t-distribution CDF using betainc
        func tCdf(_ t: Double, _ df: Double) -> Double {
            if t == 0 { return 0.5 }
            let x = df / (df + t * t)
            let p = 0.5 * betainc(df / 2.0, 0.5, x)
            return t > 0 ? 1.0 - p : p
        }

        // ttest_1samp(sample, popmean) -> statistic, pvalue
        engine.registerFunction(name: "_stats_ttest_1samp") { args in
            guard let sampleTable = args.first?.arrayValue,
                  let popmean = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }

            let sample = sampleTable.compactMap { $0.numberValue }
            guard sample.count >= 2 else { return .nil }

            let n = Double(sample.count)
            let sampleMean = mean(sample)
            let sampleStd = std(sample, ddof: 1)
            let se = sampleStd / sqrt(n)

            guard se > 0 else { return .table(["statistic": .number(.nan), "pvalue": .number(.nan)]) }

            let tStat = (sampleMean - popmean) / se
            let df = n - 1

            // Two-tailed p-value
            let pvalue = 2.0 * (1.0 - tCdf(abs(tStat), df))

            return .table([
                "statistic": .number(tStat),
                "pvalue": .number(pvalue)
            ])
        }

        // ttest_ind(sample1, sample2, equal_var=true) -> statistic, pvalue
        engine.registerFunction(name: "_stats_ttest_ind") { args in
            guard let sample1Table = args.first?.arrayValue,
                  let sample2Table = args.count > 1 ? args[1].arrayValue : nil else {
                return .nil
            }
            let equalVar = args.count > 2 ? (args[2].boolValue ?? true) : true

            let sample1 = sample1Table.compactMap { $0.numberValue }
            let sample2 = sample2Table.compactMap { $0.numberValue }

            guard sample1.count >= 2, sample2.count >= 2 else { return .nil }

            let n1 = Double(sample1.count)
            let n2 = Double(sample2.count)
            let mean1 = mean(sample1)
            let mean2 = mean(sample2)
            let var1 = variance(sample1, ddof: 1)
            let var2 = variance(sample2, ddof: 1)

            let tStat: Double
            let df: Double

            if equalVar {
                // Pooled variance
                let sp2 = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2)
                let se = sqrt(sp2 * (1/n1 + 1/n2))
                guard se > 0 else { return .table(["statistic": .number(.nan), "pvalue": .number(.nan)]) }
                tStat = (mean1 - mean2) / se
                df = n1 + n2 - 2
            } else {
                // Welch's t-test
                let se = sqrt(var1/n1 + var2/n2)
                guard se > 0 else { return .table(["statistic": .number(.nan), "pvalue": .number(.nan)]) }
                tStat = (mean1 - mean2) / se
                // Welch-Satterthwaite degrees of freedom
                let num = pow(var1/n1 + var2/n2, 2)
                let den = pow(var1/n1, 2)/(n1-1) + pow(var2/n2, 2)/(n2-1)
                df = num / den
            }

            let pvalue = 2.0 * (1.0 - tCdf(abs(tStat), df))

            return .table([
                "statistic": .number(tStat),
                "pvalue": .number(pvalue)
            ])
        }

        // pearsonr(x, y) -> correlation, pvalue
        engine.registerFunction(name: "_stats_pearsonr") { args in
            guard let xTable = args.first?.arrayValue,
                  let yTable = args.count > 1 ? args[1].arrayValue : nil else {
                return .nil
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }

            guard x.count == y.count, x.count >= 3 else { return .nil }

            let n = Double(x.count)
            let meanX = mean(x)
            let meanY = mean(y)

            var sumXY = 0.0
            var sumX2 = 0.0
            var sumY2 = 0.0

            for i in 0..<x.count {
                let dx = x[i] - meanX
                let dy = y[i] - meanY
                sumXY += dx * dy
                sumX2 += dx * dx
                sumY2 += dy * dy
            }

            guard sumX2 > 0, sumY2 > 0 else {
                return .table(["correlation": .number(.nan), "pvalue": .number(.nan)])
            }

            let r = sumXY / sqrt(sumX2 * sumY2)

            // t-statistic for correlation
            let t = r * sqrt((n - 2) / (1 - r * r))
            let df = n - 2
            let pvalue = 2.0 * (1.0 - tCdf(abs(t), df))

            return .table([
                "correlation": .number(r),
                "pvalue": .number(pvalue)
            ])
        }

        // spearmanr(x, y) -> correlation, pvalue
        engine.registerFunction(name: "_stats_spearmanr") { args in
            guard let xTable = args.first?.arrayValue,
                  let yTable = args.count > 1 ? args[1].arrayValue : nil else {
                return .nil
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }

            guard x.count == y.count, x.count >= 3 else { return .nil }

            // Compute ranks
            func rank(_ arr: [Double]) -> [Double] {
                let indexed = arr.enumerated().map { ($0.offset, $0.element) }
                let sorted = indexed.sorted { $0.1 < $1.1 }

                var ranks = [Double](repeating: 0, count: arr.count)
                var i = 0
                while i < sorted.count {
                    var j = i
                    // Find ties
                    while j < sorted.count - 1 && sorted[j].1 == sorted[j + 1].1 {
                        j += 1
                    }
                    // Average rank for ties
                    let avgRank = Double(i + j + 2) / 2.0
                    for k in i...j {
                        ranks[sorted[k].0] = avgRank
                    }
                    i = j + 1
                }
                return ranks
            }

            let rankX = rank(x)
            let rankY = rank(y)

            // Compute Pearson correlation on ranks
            let n = Double(x.count)
            let meanRankX = mean(rankX)
            let meanRankY = mean(rankY)

            var sumXY = 0.0
            var sumX2 = 0.0
            var sumY2 = 0.0

            for i in 0..<x.count {
                let dx = rankX[i] - meanRankX
                let dy = rankY[i] - meanRankY
                sumXY += dx * dy
                sumX2 += dx * dx
                sumY2 += dy * dy
            }

            guard sumX2 > 0, sumY2 > 0 else {
                return .table(["correlation": .number(.nan), "pvalue": .number(.nan)])
            }

            let rho = sumXY / sqrt(sumX2 * sumY2)

            // t-statistic for correlation
            let t = rho * sqrt((n - 2) / (1 - rho * rho))
            let df = n - 2
            let pvalue = 2.0 * (1.0 - tCdf(abs(t), df))

            return .table([
                "correlation": .number(rho),
                "pvalue": .number(pvalue)
            ])
        }

        // describe(data) -> {nobs, min, max, mean, variance, skewness, kurtosis}
        engine.registerFunction(name: "_stats_describe") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }

            let data = dataTable.compactMap { $0.numberValue }
            guard !data.isEmpty else { return .nil }

            let n = Double(data.count)
            let dataMean = mean(data)
            let dataVar = variance(data, ddof: 1)
            let dataStd = sqrt(dataVar)

            // Skewness (Fisher's definition)
            var m3 = 0.0
            for x in data {
                m3 += pow(x - dataMean, 3)
            }
            m3 /= n
            let skewness = n > 2 && dataStd > 0 ? m3 / pow(dataStd * sqrt((n-1)/n), 3) * sqrt(n*(n-1)) / (n-2) : .nan

            // Kurtosis (Fisher's definition, excess kurtosis)
            var m4 = 0.0
            for x in data {
                m4 += pow(x - dataMean, 4)
            }
            m4 /= n
            let kurtosis: Double
            if n > 3 && dataVar > 0 {
                let m2 = dataVar * (n - 1) / n
                let g2 = m4 / (m2 * m2) - 3
                kurtosis = (n - 1) / ((n - 2) * (n - 3)) * ((n + 1) * g2 + 6)
            } else {
                kurtosis = .nan
            }

            return .table([
                "nobs": .number(n),
                "min": .number(data.min()!),
                "max": .number(data.max()!),
                "mean": .number(dataMean),
                "variance": .number(dataVar),
                "skewness": .number(skewness),
                "kurtosis": .number(kurtosis)
            ])
        }

        // zscore(data) -> array of z-scores
        engine.registerFunction(name: "_stats_zscore") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }
            let ddof = args.count > 1 ? Int(args[1].numberValue ?? 0) : 0

            let data = dataTable.compactMap { $0.numberValue }
            guard data.count > ddof else { return .nil }

            let dataMean = mean(data)
            let dataStd = std(data, ddof: ddof)

            guard dataStd > 0 else {
                return .array(data.map { _ in LuaValue.number(.nan) })
            }

            let zscores = data.map { ($0 - dataMean) / dataStd }
            return .array(zscores.map { .number($0) })
        }

        // skew(data) -> skewness
        engine.registerFunction(name: "_stats_skew") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }

            let data = dataTable.compactMap { $0.numberValue }
            guard data.count >= 3 else { return .number(.nan) }

            let n = Double(data.count)
            let dataMean = mean(data)
            let dataStd = std(data, ddof: 1)

            guard dataStd > 0 else { return .number(.nan) }

            var m3 = 0.0
            for x in data {
                m3 += pow(x - dataMean, 3)
            }
            m3 /= n

            // Fisher's skewness
            let skewness = m3 / pow(dataStd * sqrt((n-1)/n), 3) * sqrt(n*(n-1)) / (n-2)
            return .number(skewness)
        }

        // kurtosis(data, fisher=true) -> kurtosis
        engine.registerFunction(name: "_stats_kurtosis") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }
            let fisher = args.count > 1 ? (args[1].boolValue ?? true) : true

            let data = dataTable.compactMap { $0.numberValue }
            guard data.count >= 4 else { return .number(.nan) }

            let n = Double(data.count)
            let dataMean = mean(data)
            let dataVar = variance(data, ddof: 1)

            guard dataVar > 0 else { return .number(.nan) }

            var m4 = 0.0
            for x in data {
                m4 += pow(x - dataMean, 4)
            }
            m4 /= n

            let m2 = dataVar * (n - 1) / n
            let g2 = m4 / (m2 * m2) - 3
            let kurtosis = (n - 1) / ((n - 2) * (n - 3)) * ((n + 1) * g2 + 6)

            return .number(fisher ? kurtosis : kurtosis + 3)
        }

        // mode(data) -> mode value (most frequent)
        engine.registerFunction(name: "_stats_mode") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }

            let data = dataTable.compactMap { $0.numberValue }
            guard !data.isEmpty else { return .nil }

            var counts: [Double: Int] = [:]
            for x in data {
                counts[x, default: 0] += 1
            }

            let modeValue = counts.max { $0.value < $1.value }!.key
            let modeCount = counts[modeValue]!

            return .table([
                "mode": .number(modeValue),
                "count": .number(Double(modeCount))
            ])
        }

        // Register Lua wrappers
        do {
            try engine.run("""
                -- Statistical tests
                math.stats.ttest_1samp = function(sample, popmean)
                    local result = _stats_ttest_1samp(sample, popmean)
                    if result then
                        return result.statistic, result.pvalue
                    end
                    return nil, nil
                end

                math.stats.ttest_ind = function(sample1, sample2, equal_var)
                    if equal_var == nil then equal_var = true end
                    local result = _stats_ttest_ind(sample1, sample2, equal_var)
                    if result then
                        return result.statistic, result.pvalue
                    end
                    return nil, nil
                end

                math.stats.pearsonr = function(x, y)
                    local result = _stats_pearsonr(x, y)
                    if result then
                        return result.correlation, result.pvalue
                    end
                    return nil, nil
                end

                math.stats.spearmanr = function(x, y)
                    local result = _stats_spearmanr(x, y)
                    if result then
                        return result.correlation, result.pvalue
                    end
                    return nil, nil
                end

                math.stats.describe = function(data)
                    return _stats_describe(data)
                end

                math.stats.zscore = function(data, ddof)
                    return _stats_zscore(data, ddof or 0)
                end

                math.stats.skew = function(data)
                    return _stats_skew(data)
                end

                math.stats.kurtosis = function(data, fisher)
                    if fisher == nil then fisher = true end
                    return _stats_kurtosis(data, fisher)
                end

                math.stats.mode = function(data)
                    return _stats_mode(data)
                end

                -- Also expose via luaswift.distributions
                luaswift.distributions.ttest_1samp = math.stats.ttest_1samp
                luaswift.distributions.ttest_ind = math.stats.ttest_ind
                luaswift.distributions.pearsonr = math.stats.pearsonr
                luaswift.distributions.spearmanr = math.stats.spearmanr
                luaswift.distributions.describe = math.stats.describe
                luaswift.distributions.zscore = math.stats.zscore
                luaswift.distributions.skew = math.stats.skew
                luaswift.distributions.kurtosis = math.stats.kurtosis
                luaswift.distributions.mode = math.stats.mode
                """)
        } catch {}
    }
}
