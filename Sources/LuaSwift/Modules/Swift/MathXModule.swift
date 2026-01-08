//
//  MathXModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed extended math module for LuaSwift.
///
/// Provides comprehensive math functions beyond the standard Lua math library,
/// including hyperbolic functions, extended rounding, statistics, special functions,
/// and coordinate conversions.
///
/// ## Lua API
///
/// ```lua
/// local mathx = require("luaswift.math")
///
/// -- Hyperbolic functions
/// local y = mathx.sinh(1.5)
/// local x = mathx.asinh(y)
///
/// -- Rounding
/// local rounded = mathx.round(3.14159, 2)  -- 3.14
/// local truncated = mathx.trunc(-3.7)      -- -3
/// local sign = mathx.sign(-5)              -- -1
///
/// -- Logarithms
/// local lg = mathx.log10(100)              -- 2.0
/// local lb = mathx.log2(8)                 -- 3.0
///
/// -- Statistics
/// local total = mathx.sum({1, 2, 3, 4})    -- 10
/// local avg = mathx.mean({1, 2, 3, 4})     -- 2.5
/// local med = mathx.median({1, 2, 3, 4})   -- 2.5
///
/// -- Special functions
/// local fact = mathx.factorial(5)          -- 120
/// local gamma_val = mathx.gamma(5)         -- 24 (same as 4!)
///
/// -- Constants
/// local phi = mathx.phi                    -- 1.618...
/// local inf = mathx.inf                    -- Infinity
///
/// -- Coordinate conversions
/// local x, y = mathx.polar_to_cart(5, math.pi/4)
/// local r, theta = mathx.cart_to_polar(3, 4)
/// ```
public struct MathXModule {

    /// Register the math extension module with a LuaEngine.
    ///
    /// This creates a global table `luaswift` with a nested `math` table containing
    /// extended math functions and constants.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register all functions
        engine.registerFunction(name: "_luaswift_math_sinh", callback: sinhCallback)
        engine.registerFunction(name: "_luaswift_math_cosh", callback: coshCallback)
        engine.registerFunction(name: "_luaswift_math_tanh", callback: tanhCallback)
        engine.registerFunction(name: "_luaswift_math_asinh", callback: asinhCallback)
        engine.registerFunction(name: "_luaswift_math_acosh", callback: acoshCallback)
        engine.registerFunction(name: "_luaswift_math_atanh", callback: atanhCallback)

        engine.registerFunction(name: "_luaswift_math_round", callback: roundCallback)
        engine.registerFunction(name: "_luaswift_math_trunc", callback: truncCallback)
        engine.registerFunction(name: "_luaswift_math_sign", callback: signCallback)

        engine.registerFunction(name: "_luaswift_math_log10", callback: log10Callback)
        engine.registerFunction(name: "_luaswift_math_log2", callback: log2Callback)

        engine.registerFunction(name: "_luaswift_math_sum", callback: sumCallback)
        engine.registerFunction(name: "_luaswift_math_mean", callback: meanCallback)
        engine.registerFunction(name: "_luaswift_math_median", callback: medianCallback)
        engine.registerFunction(name: "_luaswift_math_variance", callback: varianceCallback)
        engine.registerFunction(name: "_luaswift_math_stddev", callback: stddevCallback)
        engine.registerFunction(name: "_luaswift_math_percentile", callback: percentileCallback)
        engine.registerFunction(name: "_luaswift_math_gmean", callback: gmeanCallback)
        engine.registerFunction(name: "_luaswift_math_hmean", callback: hmeanCallback)
        engine.registerFunction(name: "_luaswift_math_mode", callback: modeCallback)

        engine.registerFunction(name: "_luaswift_math_factorial", callback: factorialCallback)
        engine.registerFunction(name: "_luaswift_math_gamma", callback: gammaCallback)
        engine.registerFunction(name: "_luaswift_math_lgamma", callback: lgammaCallback)

        engine.registerFunction(name: "_luaswift_math_polar_to_cart", callback: polarToCartCallback)
        engine.registerFunction(name: "_luaswift_math_cart_to_polar", callback: cartToPolarCallback)
        engine.registerFunction(name: "_luaswift_math_spherical_to_cart", callback: sphericalToCartCallback)
        engine.registerFunction(name: "_luaswift_math_cart_to_spherical", callback: cartToSphericalCallback)

        engine.registerFunction(name: "_luaswift_math_perm", callback: permCallback)
        engine.registerFunction(name: "_luaswift_math_comb", callback: combCallback)
        engine.registerFunction(name: "_luaswift_math_binomial", callback: combCallback)  // alias for comb

        // Set up the luaswift.mathx namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Store references before cleanup
                local sinh_fn = _luaswift_math_sinh
                local cosh_fn = _luaswift_math_cosh
                local tanh_fn = _luaswift_math_tanh
                local asinh_fn = _luaswift_math_asinh
                local acosh_fn = _luaswift_math_acosh
                local atanh_fn = _luaswift_math_atanh
                local round_fn = _luaswift_math_round
                local trunc_fn = _luaswift_math_trunc
                local sign_fn = _luaswift_math_sign
                local log10_fn = _luaswift_math_log10
                local log2_fn = _luaswift_math_log2
                local sum_fn = _luaswift_math_sum
                local mean_fn = _luaswift_math_mean
                local median_fn = _luaswift_math_median
                local variance_fn = _luaswift_math_variance
                local stddev_fn = _luaswift_math_stddev
                local percentile_fn = _luaswift_math_percentile
                local gmean_fn = _luaswift_math_gmean
                local hmean_fn = _luaswift_math_hmean
                local mode_fn = _luaswift_math_mode
                local factorial_fn = _luaswift_math_factorial
                local gamma_fn = _luaswift_math_gamma
                local lgamma_fn = _luaswift_math_lgamma
                local polar_to_cart_fn = _luaswift_math_polar_to_cart
                local cart_to_polar_fn = _luaswift_math_cart_to_polar
                local spherical_to_cart_fn = _luaswift_math_spherical_to_cart
                local cart_to_spherical_fn = _luaswift_math_cart_to_spherical
                local perm_fn = _luaswift_math_perm
                local comb_fn = _luaswift_math_comb
                local binomial_fn = _luaswift_math_binomial

                luaswift.mathx = {
                    -- Hyperbolic functions
                    sinh = sinh_fn,
                    cosh = cosh_fn,
                    tanh = tanh_fn,
                    asinh = asinh_fn,
                    acosh = acosh_fn,
                    atanh = atanh_fn,

                    -- Rounding
                    round = round_fn,
                    trunc = trunc_fn,
                    sign = sign_fn,

                    -- Logarithms
                    log10 = log10_fn,
                    log2 = log2_fn,

                    -- Statistics
                    sum = sum_fn,
                    mean = mean_fn,
                    median = median_fn,
                    variance = variance_fn,
                    stddev = stddev_fn,
                    percentile = percentile_fn,
                    gmean = gmean_fn,
                    hmean = hmean_fn,
                    mode = mode_fn,

                    -- Special functions
                    factorial = factorial_fn,
                    gamma = gamma_fn,
                    lgamma = lgamma_fn,

                    -- Combinatorics
                    perm = perm_fn,
                    comb = comb_fn,
                    binomial = binomial_fn,

                    -- Constants
                    phi = 1.618033988749895,
                    inf = math.huge,
                    nan = 0/0,

                    -- Coordinate conversions
                    polar_to_cart = polar_to_cart_fn,
                    cart_to_polar = cart_to_polar_fn,
                    spherical_to_cart = spherical_to_cart_fn,
                    cart_to_spherical = cart_to_spherical_fn,

                    -- import() extends the math table
                    import = function()
                        math.sinh = sinh_fn
                        math.cosh = cosh_fn
                        math.tanh = tanh_fn
                        math.asinh = asinh_fn
                        math.acosh = acosh_fn
                        math.atanh = atanh_fn
                        math.round = round_fn
                        math.trunc = trunc_fn
                        math.sign = sign_fn
                        math.log10 = log10_fn
                        math.log2 = log2_fn
                        math.sum = sum_fn
                        math.mean = mean_fn
                        math.median = median_fn
                        math.variance = variance_fn
                        math.stddev = stddev_fn
                        math.percentile = percentile_fn
                        math.gmean = gmean_fn
                        math.hmean = hmean_fn
                        math.mode = mode_fn
                        math.factorial = factorial_fn
                        math.gamma = gamma_fn
                        math.lgamma = lgamma_fn
                        math.perm = perm_fn
                        math.comb = comb_fn
                        math.binomial = binomial_fn
                        math.phi = 1.618033988749895
                        math.polar_to_cart = polar_to_cart_fn
                        math.cart_to_polar = cart_to_polar_fn
                        math.spherical_to_cart = spherical_to_cart_fn
                        math.cart_to_spherical = cart_to_spherical_fn
                    end
                }

                -- Create top-level global alias
                mathx = luaswift.mathx

                -- Also keep luaswift.math as alias for backward compatibility
                luaswift.math = luaswift.mathx

                -- Clean up temporary globals
                _luaswift_math_sinh = nil
                _luaswift_math_cosh = nil
                _luaswift_math_tanh = nil
                _luaswift_math_asinh = nil
                _luaswift_math_acosh = nil
                _luaswift_math_atanh = nil
                _luaswift_math_round = nil
                _luaswift_math_trunc = nil
                _luaswift_math_sign = nil
                _luaswift_math_log10 = nil
                _luaswift_math_log2 = nil
                _luaswift_math_sum = nil
                _luaswift_math_mean = nil
                _luaswift_math_median = nil
                _luaswift_math_variance = nil
                _luaswift_math_stddev = nil
                _luaswift_math_percentile = nil
                _luaswift_math_gmean = nil
                _luaswift_math_hmean = nil
                _luaswift_math_mode = nil
                _luaswift_math_factorial = nil
                _luaswift_math_gamma = nil
                _luaswift_math_lgamma = nil
                _luaswift_math_polar_to_cart = nil
                _luaswift_math_cart_to_polar = nil
                _luaswift_math_spherical_to_cart = nil
                _luaswift_math_cart_to_spherical = nil
                _luaswift_math_perm = nil
                _luaswift_math_comb = nil
                _luaswift_math_binomial = nil
                """)
        } catch {
            // Silently fail if setup fails - callbacks are still registered
        }
    }

    // MARK: - Hyperbolic Functions

    private static func sinhCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("sinh requires a numeric argument")
        }
        return .number(Darwin.sinh(x))
    }

    private static func coshCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("cosh requires a numeric argument")
        }
        return .number(Darwin.cosh(x))
    }

    private static func tanhCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("tanh requires a numeric argument")
        }
        return .number(Darwin.tanh(x))
    }

    private static func asinhCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("asinh requires a numeric argument")
        }
        return .number(Darwin.asinh(x))
    }

    private static func acoshCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("acosh requires a numeric argument")
        }
        guard x >= 1.0 else {
            throw LuaError.callbackError("acosh requires argument >= 1")
        }
        return .number(Darwin.acosh(x))
    }

    private static func atanhCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("atanh requires a numeric argument")
        }
        guard abs(x) < 1.0 else {
            throw LuaError.callbackError("atanh requires argument in (-1, 1)")
        }
        return .number(Darwin.atanh(x))
    }

    // MARK: - Rounding Functions

    private static func roundCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("round requires a numeric argument")
        }

        // Optional second argument for decimal places
        if args.count > 1, let n = args[1].intValue {
            let multiplier = pow(10.0, Double(n))
            return .number(Darwin.round(x * multiplier) / multiplier)
        }

        return .number(Darwin.round(x))
    }

    private static func truncCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("trunc requires a numeric argument")
        }
        return .number(Darwin.trunc(x))
    }

    private static func signCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("sign requires a numeric argument")
        }

        if x > 0 {
            return .number(1)
        } else if x < 0 {
            return .number(-1)
        } else {
            return .number(0)
        }
    }

    // MARK: - Logarithm Functions

    private static func log10Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("log10 requires a numeric argument")
        }
        guard x > 0 else {
            throw LuaError.callbackError("log10 requires positive argument")
        }
        return .number(Darwin.log10(x))
    }

    private static func log2Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("log2 requires a numeric argument")
        }
        guard x > 0 else {
            throw LuaError.callbackError("log2 requires positive argument")
        }
        return .number(Darwin.log2(x))
    }

    // MARK: - Statistics Functions

    private static func sumCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("sum requires an array argument")
        }

        let numbers = try extractNumbers(from: array, functionName: "sum")
        let total = numbers.reduce(0.0, +)
        return .number(total)
    }

    private static func meanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("mean requires an array argument")
        }

        let numbers = try extractNumbers(from: array, functionName: "mean")
        guard !numbers.isEmpty else {
            throw LuaError.callbackError("mean requires non-empty array")
        }

        let total = numbers.reduce(0.0, +)
        return .number(total / Double(numbers.count))
    }

    private static func medianCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("median requires an array argument")
        }

        let numbers = try extractNumbers(from: array, functionName: "median")
        guard !numbers.isEmpty else {
            throw LuaError.callbackError("median requires non-empty array")
        }

        let sorted = numbers.sorted()
        let count = sorted.count

        if count % 2 == 0 {
            // Even number of elements - average the middle two
            let mid = count / 2
            return .number((sorted[mid - 1] + sorted[mid]) / 2.0)
        } else {
            // Odd number of elements - take the middle one
            return .number(sorted[count / 2])
        }
    }

    private static func varianceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("variance requires an array argument")
        }

        let numbers = try extractNumbers(from: array, functionName: "variance")
        guard numbers.count > 0 else {
            throw LuaError.callbackError("variance requires non-empty array")
        }

        // Optional ddof (delta degrees of freedom) parameter
        // ddof=0: population variance (default), ddof=1: sample variance
        let ddof = args.count > 1 ? (args[1].intValue ?? 0) : 0
        let divisor = numbers.count - ddof
        guard divisor > 0 else {
            throw LuaError.callbackError("variance: ddof must be less than array length")
        }

        let mean = numbers.reduce(0.0, +) / Double(numbers.count)
        let squaredDiffs = numbers.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0.0, +) / Double(divisor)

        return .number(variance)
    }

    private static func stddevCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("stddev requires an array argument")
        }

        let numbers = try extractNumbers(from: array, functionName: "stddev")
        guard numbers.count > 0 else {
            throw LuaError.callbackError("stddev requires non-empty array")
        }

        // Optional ddof (delta degrees of freedom) parameter
        // ddof=0: population stddev (default), ddof=1: sample stddev
        let ddof = args.count > 1 ? (args[1].intValue ?? 0) : 0
        let divisor = numbers.count - ddof
        guard divisor > 0 else {
            throw LuaError.callbackError("stddev: ddof must be less than array length")
        }

        let mean = numbers.reduce(0.0, +) / Double(numbers.count)
        let squaredDiffs = numbers.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0.0, +) / Double(divisor)

        return .number(Darwin.sqrt(variance))
    }

    private static func percentileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("percentile requires array and percentile arguments")
        }

        guard let array = args[0].arrayValue else {
            throw LuaError.callbackError("percentile requires an array as first argument")
        }

        guard let p = args[1].numberValue else {
            throw LuaError.callbackError("percentile requires a numeric second argument")
        }

        guard p >= 0 && p <= 100 else {
            throw LuaError.callbackError("percentile must be in range [0, 100]")
        }

        let numbers = try extractNumbers(from: array, functionName: "percentile")
        guard !numbers.isEmpty else {
            throw LuaError.callbackError("percentile requires non-empty array")
        }

        let sorted = numbers.sorted()

        // Use linear interpolation method
        let rank = p / 100.0 * Double(sorted.count - 1)
        let lowerIndex = Int(Darwin.floor(rank))
        let upperIndex = Int(Darwin.ceil(rank))

        if lowerIndex == upperIndex {
            return .number(sorted[lowerIndex])
        }

        let weight = rank - Double(lowerIndex)
        let value = sorted[lowerIndex] * (1.0 - weight) + sorted[upperIndex] * weight
        return .number(value)
    }

    /// Geometric mean: nth root of product of n values
    /// gmean([a, b, c]) = (a * b * c)^(1/n)
    private static func gmeanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("gmean requires an array argument")
        }

        let numbers = try extractNumbers(from: array, functionName: "gmean")
        guard !numbers.isEmpty else {
            throw LuaError.callbackError("gmean requires non-empty array")
        }

        // Check for non-positive values (geometric mean undefined)
        for num in numbers {
            if num <= 0 {
                throw LuaError.callbackError("gmean requires all positive values")
            }
        }

        // Use log-sum-exp for numerical stability: exp(mean(log(x)))
        let logSum = numbers.reduce(0.0) { $0 + Darwin.log($1) }
        let logMean = logSum / Double(numbers.count)
        return .number(Darwin.exp(logMean))
    }

    /// Harmonic mean: n / sum(1/x_i)
    /// hmean([a, b, c]) = 3 / (1/a + 1/b + 1/c)
    private static func hmeanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("hmean requires an array argument")
        }

        let numbers = try extractNumbers(from: array, functionName: "hmean")
        guard !numbers.isEmpty else {
            throw LuaError.callbackError("hmean requires non-empty array")
        }

        // Check for zero or negative values (harmonic mean undefined)
        for num in numbers {
            if num <= 0 {
                throw LuaError.callbackError("hmean requires all positive values")
            }
        }

        let reciprocalSum = numbers.reduce(0.0) { $0 + 1.0 / $1 }
        return .number(Double(numbers.count) / reciprocalSum)
    }

    /// Mode: most frequently occurring value(s)
    /// Returns the smallest mode if there are ties
    private static func modeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let array = args.first?.arrayValue else {
            throw LuaError.callbackError("mode requires an array argument")
        }

        let numbers = try extractNumbers(from: array, functionName: "mode")
        guard !numbers.isEmpty else {
            throw LuaError.callbackError("mode requires non-empty array")
        }

        // Count occurrences
        var counts: [Double: Int] = [:]
        for num in numbers {
            counts[num, default: 0] += 1
        }

        // Find max count
        let maxCount = counts.values.max() ?? 0

        // Find all values with max count, return smallest (scipy behavior)
        let modes = counts.filter { $0.value == maxCount }.keys.sorted()
        return .number(modes.first ?? numbers[0])
    }

    // MARK: - Special Functions

    private static func factorialCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let n = args.first?.intValue else {
            throw LuaError.callbackError("factorial requires an integer argument")
        }

        guard n >= 0 else {
            throw LuaError.callbackError("factorial requires non-negative integer")
        }

        // For n <= 20, use exact integer multiplication
        // For n > 20, use lgamma for approximate result
        if n <= 20 {
            var result: Double = 1.0
            for i in 2...max(2, n) {
                result *= Double(i)
            }
            return .number(result)
        } else {
            // factorial(n) = gamma(n+1) = exp(lgamma(n+1))
            return .number(exp(Darwin.lgamma(Double(n) + 1)))
        }
    }

    /// Permutations P(n, k) = n! / (n-k)!
    private static func permCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("perm requires two arguments: n and k")
        }

        guard let n = args[0].intValue else {
            throw LuaError.callbackError("perm requires integer n")
        }

        guard let k = args[1].intValue else {
            throw LuaError.callbackError("perm requires integer k")
        }

        guard n >= 0 else {
            throw LuaError.callbackError("perm requires non-negative n")
        }

        guard k >= 0 else {
            throw LuaError.callbackError("perm requires non-negative k")
        }

        // P(n, k) where k > n is 0
        if k > n {
            return .number(0)
        }

        // P(n, 0) = 1
        if k == 0 {
            return .number(1)
        }

        // For small values, use exact multiplication
        if n <= 20 {
            var result: Double = 1.0
            for i in (n - k + 1)...n {
                result *= Double(i)
            }
            return .number(result)
        }

        // For large values, use lgamma: P(n,k) = exp(lgamma(n+1) - lgamma(n-k+1))
        let result = exp(Darwin.lgamma(Double(n) + 1) - Darwin.lgamma(Double(n - k) + 1))
        return .number(result)
    }

    /// Combinations C(n, k) = n! / (k! * (n-k)!)
    private static func combCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("comb requires two arguments: n and k")
        }

        guard let n = args[0].intValue else {
            throw LuaError.callbackError("comb requires integer n")
        }

        guard let k = args[1].intValue else {
            throw LuaError.callbackError("comb requires integer k")
        }

        guard n >= 0 else {
            throw LuaError.callbackError("comb requires non-negative n")
        }

        guard k >= 0 else {
            throw LuaError.callbackError("comb requires non-negative k")
        }

        // C(n, k) where k > n is 0
        if k > n {
            return .number(0)
        }

        // C(n, 0) = C(n, n) = 1
        if k == 0 || k == n {
            return .number(1)
        }

        // Use symmetry: C(n, k) = C(n, n-k), choose smaller k for efficiency
        let kUse = min(k, n - k)

        // For small values, use exact multiplication with cancellation
        if n <= 20 {
            var result: Double = 1.0
            for i in 0..<kUse {
                result = result * Double(n - i) / Double(i + 1)
            }
            return .number(Darwin.round(result))  // Round to avoid floating point errors
        }

        // For large values, use lgamma: C(n,k) = exp(lgamma(n+1) - lgamma(k+1) - lgamma(n-k+1))
        let result = exp(
            Darwin.lgamma(Double(n) + 1) -
            Darwin.lgamma(Double(kUse) + 1) -
            Darwin.lgamma(Double(n - kUse) + 1)
        )
        return .number(Darwin.round(result))
    }

    private static func gammaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("gamma requires a numeric argument")
        }
        return .number(Darwin.tgamma(x))
    }

    private static func lgammaCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let x = args.first?.numberValue else {
            throw LuaError.callbackError("lgamma requires a numeric argument")
        }
        return .number(Darwin.lgamma(x))
    }

    // MARK: - Coordinate Conversions

    private static func polarToCartCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("polar_to_cart requires r and theta arguments")
        }

        guard let r = args[0].numberValue else {
            throw LuaError.callbackError("polar_to_cart requires numeric r")
        }

        guard let theta = args[1].numberValue else {
            throw LuaError.callbackError("polar_to_cart requires numeric theta")
        }

        let x = r * Darwin.cos(theta)
        let y = r * Darwin.sin(theta)

        // Return as array [x, y]
        return .array([.number(x), .number(y)])
    }

    private static func cartToPolarCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("cart_to_polar requires x and y arguments")
        }

        guard let x = args[0].numberValue else {
            throw LuaError.callbackError("cart_to_polar requires numeric x")
        }

        guard let y = args[1].numberValue else {
            throw LuaError.callbackError("cart_to_polar requires numeric y")
        }

        let r = Darwin.sqrt(x * x + y * y)
        let theta = Darwin.atan2(y, x)

        // Return as array [r, theta]
        return .array([.number(r), .number(theta)])
    }

    private static func sphericalToCartCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("spherical_to_cart requires r, theta, and phi arguments")
        }

        guard let r = args[0].numberValue else {
            throw LuaError.callbackError("spherical_to_cart requires numeric r")
        }

        guard let theta = args[1].numberValue else {
            throw LuaError.callbackError("spherical_to_cart requires numeric theta")
        }

        guard let phi = args[2].numberValue else {
            throw LuaError.callbackError("spherical_to_cart requires numeric phi")
        }

        // Using physics/mathematics convention:
        // theta = azimuthal angle (from x-axis in xy-plane)
        // phi = polar angle (from z-axis)
        let x = r * Darwin.sin(phi) * Darwin.cos(theta)
        let y = r * Darwin.sin(phi) * Darwin.sin(theta)
        let z = r * Darwin.cos(phi)

        // Return as array [x, y, z]
        return .array([.number(x), .number(y), .number(z)])
    }

    private static func cartToSphericalCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("cart_to_spherical requires x, y, and z arguments")
        }

        guard let x = args[0].numberValue else {
            throw LuaError.callbackError("cart_to_spherical requires numeric x")
        }

        guard let y = args[1].numberValue else {
            throw LuaError.callbackError("cart_to_spherical requires numeric y")
        }

        guard let z = args[2].numberValue else {
            throw LuaError.callbackError("cart_to_spherical requires numeric z")
        }

        let r = Darwin.sqrt(x * x + y * y + z * z)
        let theta = Darwin.atan2(y, x)
        let phi = r > 0 ? Darwin.acos(z / r) : 0

        // Return as array [r, theta, phi]
        return .array([.number(r), .number(theta), .number(phi)])
    }

    // MARK: - Helper Functions

    /// Extract numeric values from a Lua array, throwing if any non-numeric values are found
    private static func extractNumbers(from array: [LuaValue], functionName: String) throws -> [Double] {
        var numbers: [Double] = []
        numbers.reserveCapacity(array.count)

        for (index, value) in array.enumerated() {
            guard let number = value.numberValue else {
                throw LuaError.callbackError("\(functionName) requires all array elements to be numbers (element \(index + 1) is not)")
            }
            numbers.append(number)
        }

        return numbers
    }
}
