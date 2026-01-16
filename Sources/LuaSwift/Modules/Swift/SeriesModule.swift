//
//  SeriesModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
import Foundation
import NumericSwift

/// Swift-backed Series evaluation module for LuaSwift.
///
/// Provides series summation, Taylor polynomial approximation, and convergence detection.
/// Supports both analytical (known functions) and numerical (arbitrary functions) approaches.
///
/// ## Usage
///
/// ```lua
/// local series = require("luaswift.series")
///
/// -- Series summation with convergence detection
/// local result = series.sum("1/n^2", {var="n", from=1, tol=1e-10})
///
/// -- Taylor polynomial for known functions (analytical)
/// local poly = series.taylor("sin", {at=0, terms=10})
///
/// -- Numerical Taylor approximation for arbitrary functions
/// local poly = series.approximate_taylor(f, {at=0, degree=10, scale=0.1})
///
/// -- Partial sums with convergence info
/// local info = series.partial_sums("1/2^n", {var="n", from=0, max_terms=20})
/// ```
public struct SeriesModule {

    // MARK: - Constants

    /// Default tolerance for convergence detection
    private static let defaultTolerance: Double = 1e-12

    /// Default maximum iterations to prevent infinite loops
    private static let defaultMaxIterations: Int = 10000

    // MARK: - Name Mapping

    /// Map Lua function names to NumericSwift function names
    private static let luaToNumericSwiftName: [String: String] = [
        "geometric_alt": "geometricAlt"
    ]

    // MARK: - Taylor Series Coefficients (Analytical)

    /// Known Taylor series coefficients at x=0 for common functions.
    /// Uses NumericSwift.factorial for computations.
    private static let taylorCoefficients: [String: (Int) -> Double] = [
        // sin(x) = x - x^3/3! + x^5/5! - ...
        // Coefficient of x^n: 0 if n even, (-1)^((n-1)/2) / n! if n odd
        "sin": { n in
            if n % 2 == 0 { return 0 }
            let sign = ((n - 1) / 2) % 2 == 0 ? 1.0 : -1.0
            return sign / NumericSwift.factorial(n)
        },

        // cos(x) = 1 - x^2/2! + x^4/4! - ...
        // Coefficient of x^n: 0 if n odd, (-1)^(n/2) / n! if n even
        "cos": { n in
            if n % 2 != 0 { return 0 }
            let sign = (n / 2) % 2 == 0 ? 1.0 : -1.0
            return sign / NumericSwift.factorial(n)
        },

        // exp(x) = 1 + x + x^2/2! + x^3/3! + ...
        // Coefficient of x^n: 1/n!
        "exp": { n in
            return 1.0 / NumericSwift.factorial(n)
        },

        // log(1+x) = x - x^2/2 + x^3/3 - x^4/4 + ...
        // Coefficient of x^n: 0 if n=0, (-1)^(n+1) / n if n > 0
        "log1p": { n in
            if n == 0 { return 0 }
            let sign = n % 2 == 1 ? 1.0 : -1.0
            return sign / Double(n)
        },

        // sinh(x) = x + x^3/3! + x^5/5! + ...
        // Coefficient of x^n: 0 if n even, 1/n! if n odd
        "sinh": { n in
            if n % 2 == 0 { return 0 }
            return 1.0 / NumericSwift.factorial(n)
        },

        // cosh(x) = 1 + x^2/2! + x^4/4! + ...
        // Coefficient of x^n: 0 if n odd, 1/n! if n even
        "cosh": { n in
            if n % 2 != 0 { return 0 }
            return 1.0 / NumericSwift.factorial(n)
        },

        // tan(x) = x + x^3/3 + 2x^5/15 + 17x^7/315 + ...
        // Uses Bernoulli numbers, only first few terms for practical use
        "tan": { n in
            // First few Taylor coefficients for tan(x) at x=0
            let coeffs: [Int: Double] = [
                0: 0, 1: 1, 2: 0, 3: 1.0/3.0, 4: 0,
                5: 2.0/15.0, 6: 0, 7: 17.0/315.0, 8: 0,
                9: 62.0/2835.0, 10: 0, 11: 1382.0/155925.0
            ]
            return coeffs[n] ?? 0
        },

        // atan(x) = x - x^3/3 + x^5/5 - x^7/7 + ...
        // Coefficient of x^n: 0 if n even, (-1)^((n-1)/2) / n if n odd
        "atan": { n in
            if n % 2 == 0 { return 0 }
            let sign = ((n - 1) / 2) % 2 == 0 ? 1.0 : -1.0
            return sign / Double(n)
        },

        // 1/(1-x) = 1 + x + x^2 + x^3 + ... (geometric series)
        "geometric": { _ in
            return 1.0
        },

        // 1/(1+x) = 1 - x + x^2 - x^3 + ... (alternating geometric)
        "geometric_alt": { n in
            return n % 2 == 0 ? 1.0 : -1.0
        },

        // sqrt(1+x) = 1 + x/2 - x^2/8 + x^3/16 - ...
        // Binomial series (1+x)^(1/2)
        "sqrt1p": { n in
            if n == 0 { return 1.0 }
            var coeff = 0.5
            for k in 1..<n {
                coeff *= (0.5 - Double(k)) / Double(k + 1)
            }
            return coeff
        },

        // (1+x)^(-1) = 1 - x + x^2 - x^3 + ...
        "inv1p": { n in
            return n % 2 == 0 ? 1.0 : -1.0
        }
    ]

    // MARK: - Public API

    /// Register the Series module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_series_sum", callback: seriesSumCallback)
        engine.registerFunction(name: "_luaswift_series_product", callback: seriesProductCallback)
        engine.registerFunction(name: "_luaswift_series_taylor", callback: taylorCallback)
        engine.registerFunction(name: "_luaswift_series_approximate_taylor", callback: approximateTaylorCallback)
        engine.registerFunction(name: "_luaswift_series_partial_sums", callback: partialSumsCallback)
        engine.registerFunction(name: "_luaswift_series_eval_poly", callback: evalPolyCallback)

        // Set up the Lua namespace
        do {
            try engine.run(seriesLuaWrapper)
        } catch {
            // Module setup failed - callbacks still registered
        }
    }

    // MARK: - Callbacks

    /// Series summation callback
    private static let seriesSumCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              case .table(let options) = args[1] else {
            throw LuaError.callbackError("series.sum requires (expression, options)")
        }

        let varName = options["var"]?.stringValue ?? "n"
        let from = options["from"]?.numberValue.map { Int($0) } ?? 1
        let to = options["to"]?.numberValue.map { Int($0) }
        let tol = options["tol"]?.numberValue ?? defaultTolerance
        let maxIter = options["max_iter"]?.numberValue.map { Int($0) } ?? defaultMaxIterations

        // Return parameters for Lua to do the actual evaluation loop
        // (Lua has the eval function, Swift doesn't have direct access)
        return .table([
            "expr": .string(expr),
            "var": .string(varName),
            "from": .number(Double(from)),
            "to": to.map { LuaValue.number(Double($0)) } ?? .nil,
            "tol": .number(tol),
            "max_iter": .number(Double(maxIter))
        ])
    }

    /// Series product callback
    private static let seriesProductCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              case .table(let options) = args[1] else {
            throw LuaError.callbackError("series.product requires (expression, options)")
        }

        let varName = options["var"]?.stringValue ?? "n"
        let from = options["from"]?.numberValue.map { Int($0) } ?? 1
        let to = options["to"]?.numberValue.map { Int($0) }
        let maxIter = options["max_iter"]?.numberValue.map { Int($0) } ?? defaultMaxIterations

        return .table([
            "expr": .string(expr),
            "var": .string(varName),
            "from": .number(Double(from)),
            "to": to.map { LuaValue.number(Double($0)) } ?? .nil,
            "max_iter": .number(Double(maxIter))
        ])
    }

    /// Taylor series callback (analytical for known functions)
    private static let taylorCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 1,
              let funcName = args[0].stringValue else {
            throw LuaError.callbackError("series.taylor requires function name")
        }

        var options: [String: LuaValue] = [:]
        if args.count >= 2, case .table(let opts) = args[1] {
            options = opts
        }

        let at = options["at"]?.numberValue ?? 0.0
        let terms = options["terms"]?.numberValue.map { Int($0) } ?? 10

        guard let coeffGenerator = taylorCoefficients[funcName] else {
            throw LuaError.callbackError("Unknown function for Taylor series: \(funcName). Available: \(taylorCoefficients.keys.sorted().joined(separator: ", "))")
        }

        // Generate coefficients
        var coeffs: [LuaValue] = []
        for n in 0..<terms {
            coeffs.append(.number(coeffGenerator(n)))
        }

        return .table([
            "coefficients": .array(coeffs),
            "center": .number(at),
            "terms": .number(Double(terms)),
            "function": .string(funcName)
        ])
    }

    /// Numerical Taylor approximation callback (SciPy-style)
    private static let approximateTaylorCallback: ([LuaValue]) throws -> LuaValue = { args in
        // This returns parameters for Lua to evaluate
        // Lua must provide function values, then Swift computes coefficients
        guard args.count >= 2,
              case .table(let options) = args[1] else {
            throw LuaError.callbackError("series.approximate_taylor requires (function, options)")
        }

        let at = options["at"]?.numberValue ?? 0.0
        let degree = options["degree"]?.numberValue.map { Int($0) } ?? 10
        let scale = options["scale"]?.numberValue ?? 0.1
        let order = options["order"]?.numberValue.map { Int($0) } ?? (degree + 5) // Extra for stability

        // Generate Chebyshev-like evaluation points using NumericSwift
        let n = order + 1
        let points = NumericSwift.chebyshevPoints(center: at, scale: scale, count: n)

        return .table([
            "points": .array(points.map { .number($0) }),
            "center": .number(at),
            "degree": .number(Double(degree)),
            "scale": .number(scale)
        ])
    }

    /// Partial sums callback
    private static let partialSumsCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              case .table(let options) = args[1] else {
            throw LuaError.callbackError("series.partial_sums requires (expression, options)")
        }

        let varName = options["var"]?.stringValue ?? "n"
        let from = options["from"]?.numberValue.map { Int($0) } ?? 0
        let maxTerms = options["max_terms"]?.numberValue.map { Int($0) } ?? 20

        return .table([
            "expr": .string(expr),
            "var": .string(varName),
            "from": .number(Double(from)),
            "max_terms": .number(Double(maxTerms))
        ])
    }

    /// Evaluate polynomial at a point using NumericSwift.polyval
    private static let evalPolyCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              case .array(let coeffsArray) = args[0] else {
            throw LuaError.callbackError("series.eval_poly requires (coefficients, x)")
        }

        let x = args[1].numberValue ?? 0.0
        let center = args.count >= 3 ? (args[2].numberValue ?? 0.0) : 0.0

        let coeffs = coeffsArray.compactMap { $0.numberValue }
        guard !coeffs.isEmpty else {
            return .number(0.0)
        }

        // Use NumericSwift's polyval with center support
        let result = NumericSwift.polyval(coeffs, at: x, center: center)
        return .number(result)
    }

    // MARK: - Lua Wrapper

    private static let seriesLuaWrapper = """
    -- Create series module
    if not luaswift then luaswift = {} end

    -- Store references to Swift functions
    local _series_sum = _luaswift_series_sum
    local _series_product = _luaswift_series_product
    local _series_taylor = _luaswift_series_taylor
    local _series_approximate_taylor = _luaswift_series_approximate_taylor
    local _series_partial_sums = _luaswift_series_partial_sums
    local _series_eval_poly = _luaswift_series_eval_poly

    local series = {}

    -- Get the eval module for expression evaluation
    local function get_eval()
        return luaswift.mathexpr or math.eval or error("MathExprModule not loaded")
    end

    -- Series summation with convergence detection
    -- series.sum("1/n^2", {var="n", from=1, to=100}) - finite sum
    -- series.sum("1/n^2", {var="n", from=1, tol=1e-10}) - converge until tolerance
    function series.sum(expr, options)
        options = options or {}
        local params = _series_sum(expr, options)

        local eval = get_eval()
        local sum = 0.0
        local prev_sum = math.huge
        local var_name = params.var
        local n = params.from

        if params.to then
            -- Finite sum
            while n <= params.to do
                local term = eval(expr, {[var_name] = n})
                sum = sum + term
                n = n + 1
            end
        else
            -- Convergence mode
            local iterations = 0
            while iterations < params.max_iter do
                local term = eval(expr, {[var_name] = n})
                sum = sum + term

                -- Check convergence
                if math.abs(term) < params.tol and math.abs(sum - prev_sum) < params.tol then
                    return sum, {
                        converged = true,
                        iterations = iterations + 1,
                        last_term = term
                    }
                end

                prev_sum = sum
                n = n + 1
                iterations = iterations + 1
            end

            return sum, {
                converged = false,
                iterations = iterations,
                last_term = eval(expr, {[var_name] = n - 1})
            }
        end

        return sum
    end

    -- Series product
    -- series.product("(1 - 1/n^2)", {var="n", from=2, to=100})
    function series.product(expr, options)
        options = options or {}
        local params = _series_product(expr, options)

        local eval = get_eval()
        local product = 1.0
        local var_name = params.var
        local n = params.from

        if params.to then
            while n <= params.to do
                local term = eval(expr, {[var_name] = n})
                product = product * term
                n = n + 1
            end
        else
            -- Until convergence (product stabilizes)
            local iterations = 0
            local prev_product = 0
            local tol = options.tol or 1e-12

            while iterations < params.max_iter do
                local term = eval(expr, {[var_name] = n})
                product = product * term

                if math.abs(product - prev_product) < tol * math.abs(product) then
                    return product, {
                        converged = true,
                        iterations = iterations + 1
                    }
                end

                prev_product = product
                n = n + 1
                iterations = iterations + 1
            end

            return product, {
                converged = false,
                iterations = iterations
            }
        end

        return product
    end

    -- Analytical Taylor series for known functions
    -- Returns polynomial object with coefficients
    function series.taylor(func_name, options)
        local result = _series_taylor(func_name, options)

        -- Create polynomial object with evaluation method
        local poly = {
            coefficients = result.coefficients,
            center = result.center,
            terms = result.terms,
            func_name = result["function"]
        }

        -- Evaluate polynomial at x
        function poly:eval(x)
            return _series_eval_poly(self.coefficients, x, self.center)
        end

        -- String representation
        function poly:tostring()
            local parts = {}
            local a = self.center
            for i, c in ipairs(self.coefficients) do
                if c ~= 0 then
                    local n = i - 1
                    local term
                    if n == 0 then
                        term = string.format("%.6g", c)
                    elseif n == 1 then
                        if a == 0 then
                            term = string.format("%.6g*x", c)
                        else
                            term = string.format("%.6g*(x-%.6g)", c, a)
                        end
                    else
                        if a == 0 then
                            term = string.format("%.6g*x^%d", c, n)
                        else
                            term = string.format("%.6g*(x-%.6g)^%d", c, a, n)
                        end
                    end
                    table.insert(parts, term)
                end
            end
            return table.concat(parts, " + "):gsub("%+ %-", "- ")
        end

        -- Callable
        setmetatable(poly, {
            __call = function(self, x) return self:eval(x) end,
            __tostring = function(self) return self:tostring() end
        })

        return poly
    end

    -- Numerical Taylor approximation for arbitrary functions
    -- Uses Chebyshev-like point distribution (SciPy-style)
    function series.approximate_taylor(f, options)
        local params = _series_approximate_taylor(nil, options)

        -- Evaluate function at Chebyshev points
        local ys = {}
        for _, x in ipairs(params.points) do
            table.insert(ys, f(x))
        end

        -- Use polynomial fitting to extract Taylor coefficients
        -- This is done via divided differences and derivative extraction
        local n = #params.points
        local xs = params.points
        local center = params.center
        local degree = math.floor(params.degree)

        -- Compute divided differences
        local dd = {}
        for i = 1, n do
            dd[i] = {}
            dd[i][1] = ys[i]
        end

        for j = 2, n do
            for i = 1, n - j + 1 do
                dd[i][j] = (dd[i+1][j-1] - dd[i][j-1]) / (xs[i+j-1] - xs[i])
            end
        end

        -- Extract coefficients (Newton form at center point)
        -- Convert to Taylor coefficients using numerical derivatives
        local coeffs = {}

        -- Simple approach: evaluate derivatives numerically
        local h = params.scale / 100

        for k = 0, degree do
            if k == 0 then
                coeffs[k+1] = f(center)
            else
                -- k-th derivative via finite differences
                local dk = 0
                for j = 0, k do
                    local sign = ((k - j) % 2 == 0) and 1 or -1
                    local binom = 1
                    for m = 1, j do
                        binom = binom * (k - m + 1) / m
                    end
                    dk = dk + sign * binom * f(center + j * h)
                end
                dk = dk / (h ^ k)
                coeffs[k+1] = dk / series._factorial(k)
            end
        end

        -- Create polynomial object
        local poly = {
            coefficients = coeffs,
            center = center,
            terms = degree + 1,
            approximate = true
        }

        function poly:eval(x)
            return _series_eval_poly(self.coefficients, x, self.center)
        end

        setmetatable(poly, {
            __call = function(self, x) return self:eval(x) end
        })

        return poly
    end

    -- Compute partial sums with convergence information
    -- Returns iterator (coroutine-based for memory efficiency)
    function series.partial_sums(expr, options)
        local params = _series_partial_sums(expr, options)
        local eval = get_eval()

        return coroutine.wrap(function()
            local sum = 0
            local var_name = params.var
            local n = params.from

            for i = 1, params.max_terms do
                local term = eval(expr, {[var_name] = n})
                sum = sum + term
                coroutine.yield(i, n, term, sum)
                n = n + 1
            end
        end)
    end

    -- Generate series terms as iterator (lazy evaluation)
    function series.terms(expr, options)
        options = options or {}
        local eval = get_eval()
        local var_name = options.var or "n"
        local from = options.from or 0

        return coroutine.wrap(function()
            local n = from
            while true do
                local term = eval(expr, {[var_name] = n})
                coroutine.yield(n, term)
                n = n + 1
            end
        end)
    end

    -- Factorial helper (cached in Lua for series operations)
    local fact_cache = {[0] = 1, [1] = 1}
    function series._factorial(n)
        if n < 0 then return 0/0 end -- NaN
        if n > 170 then return math.huge end
        if fact_cache[n] then return fact_cache[n] end
        local result = series._factorial(n - 1) * n
        fact_cache[n] = result
        return result
    end

    -- Binomial coefficient
    function series.binomial(n, k)
        if k < 0 or k > n then return 0 end
        if k == 0 or k == n then return 1 end
        return series._factorial(n) / (series._factorial(k) * series._factorial(n - k))
    end

    -- List available Taylor functions
    function series.available_functions()
        return {"sin", "cos", "exp", "log1p", "sinh", "cosh", "tan", "atan",
                "geometric", "geometric_alt", "sqrt1p", "inv1p"}
    end

    -- Register in namespace
    luaswift.series = series

    -- Also add to math namespace if extend_stdlib was called
    if math.series == nil then
        math.series = series
    end

    -- Clean up global namespace
    _luaswift_series_sum = nil
    _luaswift_series_product = nil
    _luaswift_series_taylor = nil
    _luaswift_series_approximate_taylor = nil
    _luaswift_series_partial_sums = nil
    _luaswift_series_eval_poly = nil
    """
}

#endif  // LUASWIFT_NUMERICSWIFT
