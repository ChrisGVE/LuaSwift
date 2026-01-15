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
import NumericSwift

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

    // MARK: - Helper Functions

    /// Inverse error function using Winitzki approximation.
    /// NumericSwift erfinv has bugs in the tail region, so we use this local version.
    private static func erfinvLocal(_ x: Double) -> Double {
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
            let dist = NormalDistribution(loc: loc, scale: scale)
            return .number(dist.pdf(x))
        }

        // norm.cdf(x, loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_cdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = NormalDistribution(loc: loc, scale: scale)
            return .number(dist.cdf(x))
        }

        // norm.ppf(p, loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_ppf") { args in
            guard let p = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            // Use local erfinv for correct ppf calculation
            let ppf = loc + scale * sqrt(2.0) * erfinvLocal(2.0 * p - 1.0)
            return .number(ppf)
        }

        // norm.rvs(size=1, loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_rvs") { args in
            let size = args.first?.intValue ?? 1
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = NormalDistribution(loc: loc, scale: scale)

            if size == 1 {
                return .number(dist.rvs())
            }
            return .array(dist.rvs(size).map { .number($0) })
        }

        // norm.mean(loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_mean") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = NormalDistribution(loc: loc, scale: scale)
            return .number(dist.mean)
        }

        // norm.var(loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_var") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = NormalDistribution(loc: loc, scale: scale)
            return .number(dist.variance)
        }

        // norm.std(loc=0, scale=1)
        engine.registerFunction(name: "_dist_norm_std") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = NormalDistribution(loc: loc, scale: scale)
            return .number(dist.std)
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
            let dist = UniformDistribution(loc: loc, scale: scale)
            return .number(dist.pdf(x))
        }

        // uniform.cdf(x, loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_cdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = UniformDistribution(loc: loc, scale: scale)
            return .number(dist.cdf(x))
        }

        // uniform.ppf(p, loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_ppf") { args in
            guard let p = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = UniformDistribution(loc: loc, scale: scale)
            return .number(dist.ppf(p))
        }

        // uniform.rvs(size=1, loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_rvs") { args in
            let size = args.first?.intValue ?? 1
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = UniformDistribution(loc: loc, scale: scale)

            if size == 1 {
                return .number(dist.rvs())
            }
            return .array(dist.rvs(size).map { .number($0) })
        }

        // uniform.mean(loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_mean") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = UniformDistribution(loc: loc, scale: scale)
            return .number(dist.mean)
        }

        // uniform.var(loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_var") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = UniformDistribution(loc: loc, scale: scale)
            return .number(dist.variance)
        }

        // uniform.std(loc=0, scale=1)
        engine.registerFunction(name: "_dist_uniform_std") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = UniformDistribution(loc: loc, scale: scale)
            return .number(dist.std)
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
            let dist = ExponentialDistribution(loc: loc, scale: scale)
            return .number(dist.pdf(x))
        }

        // expon.cdf(x, loc=0, scale=1)
        engine.registerFunction(name: "_dist_expon_cdf") { args in
            guard let x = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = ExponentialDistribution(loc: loc, scale: scale)
            return .number(dist.cdf(x))
        }

        // expon.ppf(p, loc=0, scale=1)
        engine.registerFunction(name: "_dist_expon_ppf") { args in
            guard let p = args.first?.numberValue else {
                return .nil
            }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = ExponentialDistribution(loc: loc, scale: scale)
            return .number(dist.ppf(p))
        }

        // expon.rvs(size=1, loc=0, scale=1)
        engine.registerFunction(name: "_dist_expon_rvs") { args in
            let size = args.first?.intValue ?? 1
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = ExponentialDistribution(loc: loc, scale: scale)

            if size == 1 {
                return .number(dist.rvs())
            }
            return .array(dist.rvs(size).map { .number($0) })
        }

        // expon.mean/var/std
        engine.registerFunction(name: "_dist_expon_mean") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = ExponentialDistribution(loc: loc, scale: scale)
            return .number(dist.mean)
        }

        engine.registerFunction(name: "_dist_expon_var") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = ExponentialDistribution(loc: loc, scale: scale)
            return .number(dist.variance)
        }

        engine.registerFunction(name: "_dist_expon_std") { args in
            let loc = args.first?.numberValue ?? 0.0
            let scale = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
            let dist = ExponentialDistribution(loc: loc, scale: scale)
            return .number(dist.std)
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
            let dist = TDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.pdf(x))
        }

        // t.cdf(x, df, loc=0, scale=1)
        engine.registerFunction(name: "_dist_t_cdf") { args in
            guard let x = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = TDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.cdf(x))
        }

        // t.ppf - using Newton-Raphson with correct erfinv for starting point
        engine.registerFunction(name: "_dist_t_ppf") { args in
            guard let p = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            // Use normal approximation as starting point (with correct erfinv)
            var x = sqrt(2.0) * erfinvLocal(2.0 * p - 1.0)

            // Newton-Raphson iteration
            for _ in 0..<50 {
                let t2 = x * x
                let cdfVal = 0.5 + 0.5 * (1.0 - NumericSwift.betainc(df / 2.0, 0.5, df / (df + t2))) * (x >= 0 ? 1 : -1)
                let coef = Darwin.tgamma((df + 1) / 2.0) / (sqrt(df * .pi) * Darwin.tgamma(df / 2.0))
                let pdfVal = coef * pow(1.0 + t2 / df, -(df + 1) / 2.0)

                let dx = (cdfVal - p) / pdfVal
                x -= dx
                if abs(dx) < 1e-10 { break }
            }

            return .number(loc + scale * x)
        }

        // t.rvs
        engine.registerFunction(name: "_dist_t_rvs") { args in
            let size = args.first?.intValue ?? 1
            guard let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = TDistribution(df: df, loc: loc, scale: scale)

            if size == 1 {
                return .number(dist.rvs())
            }
            return .array(dist.rvs(size).map { .number($0) })
        }

        // t.mean/var/std
        engine.registerFunction(name: "_dist_t_mean") { args in
            guard let df = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = TDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.mean)
        }

        engine.registerFunction(name: "_dist_t_var") { args in
            guard let df = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = TDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.variance)
        }

        engine.registerFunction(name: "_dist_t_std") { args in
            guard let df = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = TDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.std)
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
            let dist = ChiSquaredDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.pdf(x))
        }

        // chi2.cdf(x, df, loc=0, scale=1)
        engine.registerFunction(name: "_dist_chi2_cdf") { args in
            guard let x = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = ChiSquaredDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.cdf(x))
        }

        // chi2.ppf - using Newton-Raphson with correct erfinv for starting point
        engine.registerFunction(name: "_dist_chi2_ppf") { args in
            guard let p = args.first?.numberValue,
                  let df = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0

            // Wilson-Hilferty approximation as starting point (with correct erfinv)
            var x = df * pow(1.0 - 2.0 / (9.0 * df) + sqrt(2.0) * erfinvLocal(2.0 * p - 1.0) * sqrt(2.0 / (9.0 * df)), 3)
            if x < 0.01 { x = 0.01 }

            // Newton-Raphson iteration
            let k2 = df / 2.0
            for _ in 0..<50 {
                let cdfVal = NumericSwift.gammainc(k2, x / 2.0)
                let pdfVal = pow(x, k2 - 1) * exp(-x / 2.0) / (pow(2.0, k2) * Darwin.tgamma(k2))

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
            let dist = ChiSquaredDistribution(df: df, loc: loc, scale: scale)

            if size == 1 {
                return .number(dist.rvs())
            }
            return .array(dist.rvs(size).map { .number($0) })
        }

        // chi2.mean/var/std
        engine.registerFunction(name: "_dist_chi2_mean") { args in
            guard let df = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = ChiSquaredDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.mean)
        }

        engine.registerFunction(name: "_dist_chi2_var") { args in
            guard let df = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = ChiSquaredDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.variance)
        }

        engine.registerFunction(name: "_dist_chi2_std") { args in
            guard let df = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = ChiSquaredDistribution(df: df, loc: loc, scale: scale)
            return .number(dist.std)
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
            let dist = FDistribution(dfn: dfn, dfd: dfd, loc: loc, scale: scale)
            return .number(dist.pdf(x))
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
            let dist = FDistribution(dfn: dfn, dfd: dfd, loc: loc, scale: scale)
            return .number(dist.cdf(x))
        }

        // f.ppf
        engine.registerFunction(name: "_dist_f_ppf") { args in
            guard let p = args.first?.numberValue,
                  let dfn = args.count > 1 ? args[1].numberValue : nil,
                  let dfd = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0
            let dist = FDistribution(dfn: dfn, dfd: dfd, loc: loc, scale: scale)
            return .number(dist.ppf(p))
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
            let dist = FDistribution(dfn: dfn, dfd: dfd, loc: loc, scale: scale)

            if size == 1 {
                return .number(dist.rvs())
            }
            return .array(dist.rvs(size).map { .number($0) })
        }

        // f.mean/var/std
        engine.registerFunction(name: "_dist_f_mean") { args in
            guard let dfn = args.first?.numberValue,
                  let dfd = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = FDistribution(dfn: dfn, dfd: dfd, loc: loc, scale: scale)
            return .number(dist.mean)
        }

        engine.registerFunction(name: "_dist_f_var") { args in
            guard let dfn = args.first?.numberValue,
                  let dfd = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = FDistribution(dfn: dfn, dfd: dfd, loc: loc, scale: scale)
            return .number(dist.variance)
        }

        engine.registerFunction(name: "_dist_f_std") { args in
            guard let dfn = args.first?.numberValue,
                  let dfd = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = FDistribution(dfn: dfn, dfd: dfd, loc: loc, scale: scale)
            return .number(dist.std)
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
            let dist = GammaDistribution(shape: a, loc: loc, scale: scale)
            return .number(dist.pdf(x))
        }

        // gamma_dist.cdf(x, a, loc=0, scale=1)
        engine.registerFunction(name: "_dist_gamma_cdf") { args in
            guard let x = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = GammaDistribution(shape: a, loc: loc, scale: scale)
            return .number(dist.cdf(x))
        }

        // gamma_dist.ppf
        engine.registerFunction(name: "_dist_gamma_ppf") { args in
            guard let p = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = GammaDistribution(shape: a, loc: loc, scale: scale)
            return .number(dist.ppf(p))
        }

        // gamma_dist.rvs
        engine.registerFunction(name: "_dist_gamma_rvs") { args in
            let size = args.first?.intValue ?? 1
            guard let a = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = GammaDistribution(shape: a, loc: loc, scale: scale)

            if size == 1 {
                return .number(dist.rvs())
            }
            return .array(dist.rvs(size).map { .number($0) })
        }

        // gamma_dist.mean/var/std
        engine.registerFunction(name: "_dist_gamma_mean") { args in
            guard let a = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = GammaDistribution(shape: a, loc: loc, scale: scale)
            return .number(dist.mean)
        }

        engine.registerFunction(name: "_dist_gamma_var") { args in
            guard let a = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = GammaDistribution(shape: a, loc: loc, scale: scale)
            return .number(dist.variance)
        }

        engine.registerFunction(name: "_dist_gamma_std") { args in
            guard let a = args.first?.numberValue else { return .nil }
            let loc = args.count > 1 ? (args[1].numberValue ?? 0.0) : 0.0
            let scale = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0
            let dist = GammaDistribution(shape: a, loc: loc, scale: scale)
            return .number(dist.std)
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
            let dist = BetaDistribution(a: a, b: b, loc: loc, scale: scale)
            return .number(dist.pdf(x))
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
            let dist = BetaDistribution(a: a, b: b, loc: loc, scale: scale)
            return .number(dist.cdf(x))
        }

        // beta_dist.ppf
        engine.registerFunction(name: "_dist_beta_ppf") { args in
            guard let p = args.first?.numberValue,
                  let a = args.count > 1 ? args[1].numberValue : nil,
                  let b = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0
            let dist = BetaDistribution(a: a, b: b, loc: loc, scale: scale)
            return .number(dist.ppf(p))
        }

        // beta_dist.rvs
        engine.registerFunction(name: "_dist_beta_rvs") { args in
            let size = args.first?.intValue ?? 1
            guard let a = args.count > 1 ? args[1].numberValue : nil,
                  let b = args.count > 2 ? args[2].numberValue : nil else {
                return .nil
            }
            let loc = args.count > 3 ? (args[3].numberValue ?? 0.0) : 0.0
            let scale = args.count > 4 ? (args[4].numberValue ?? 1.0) : 1.0
            let dist = BetaDistribution(a: a, b: b, loc: loc, scale: scale)

            if size == 1 {
                return .number(dist.rvs())
            }
            return .array(dist.rvs(size).map { .number($0) })
        }

        // beta_dist.mean/var/std
        engine.registerFunction(name: "_dist_beta_mean") { args in
            guard let a = args.first?.numberValue,
                  let b = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = BetaDistribution(a: a, b: b, loc: loc, scale: scale)
            return .number(dist.mean)
        }

        engine.registerFunction(name: "_dist_beta_var") { args in
            guard let a = args.first?.numberValue,
                  let b = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = BetaDistribution(a: a, b: b, loc: loc, scale: scale)
            return .number(dist.variance)
        }

        engine.registerFunction(name: "_dist_beta_std") { args in
            guard let a = args.first?.numberValue,
                  let b = args.count > 1 ? args[1].numberValue : nil else { return .nil }
            let loc = args.count > 2 ? (args[2].numberValue ?? 0.0) : 0.0
            let scale = args.count > 3 ? (args[3].numberValue ?? 1.0) : 1.0
            let dist = BetaDistribution(a: a, b: b, loc: loc, scale: scale)
            return .number(dist.std)
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
        // ttest_1samp(sample, popmean) -> statistic, pvalue
        engine.registerFunction(name: "_stats_ttest_1samp") { args in
            guard let sampleTable = args.first?.arrayValue,
                  let popmean = args.count > 1 ? args[1].numberValue : nil else {
                return .nil
            }

            let sample = sampleTable.compactMap { $0.numberValue }
            guard let result = NumericSwift.ttest1Sample(sample, popmean: popmean) else {
                return .nil
            }

            return .table([
                "statistic": .number(result.statistic),
                "pvalue": .number(result.pvalue)
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

            guard let result = NumericSwift.ttestIndependent(sample1, sample2, equalVariance: equalVar) else {
                return .nil
            }

            return .table([
                "statistic": .number(result.statistic),
                "pvalue": .number(result.pvalue)
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

            guard let result = NumericSwift.pearsonr(x, y) else {
                return .nil
            }

            return .table([
                "correlation": .number(result.statistic),
                "pvalue": .number(result.pvalue)
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

            guard let result = NumericSwift.spearmanr(x, y) else {
                return .nil
            }

            return .table([
                "correlation": .number(result.statistic),
                "pvalue": .number(result.pvalue)
            ])
        }

        // describe(data) -> {nobs, min, max, mean, variance, skewness, kurtosis}
        engine.registerFunction(name: "_stats_describe") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }

            let data = dataTable.compactMap { $0.numberValue }

            guard let result = NumericSwift.describe(data) else {
                return .nil
            }

            return .table([
                "nobs": .number(Double(result.nobs)),
                "min": .number(result.min),
                "max": .number(result.max),
                "mean": .number(result.mean),
                "variance": .number(result.variance),
                "skewness": .number(result.skewness),
                "kurtosis": .number(result.kurtosis)
            ])
        }

        // zscore(data) -> array of z-scores
        engine.registerFunction(name: "_stats_zscore") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }
            let ddof = args.count > 1 ? Int(args[1].numberValue ?? 0) : 0

            let data = dataTable.compactMap { $0.numberValue }
            let zscores = NumericSwift.zscore(data, ddof: ddof)

            return .array(zscores.map { .number($0) })
        }

        // skew(data) -> skewness
        engine.registerFunction(name: "_stats_skew") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }

            let data = dataTable.compactMap { $0.numberValue }
            return .number(NumericSwift.skew(data))
        }

        // kurtosis(data, fisher=true) -> kurtosis
        engine.registerFunction(name: "_stats_kurtosis") { args in
            guard let dataTable = args.first?.arrayValue else { return .nil }
            let fisher = args.count > 1 ? (args[1].boolValue ?? true) : true

            let data = dataTable.compactMap { $0.numberValue }
            return .number(NumericSwift.kurtosis(data, fisher: fisher))
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
