//
//  SeriesModulePower.swift
//  LuaSwift
//
//  Power-series object (math.series.power) and symbolic series dispatchers
//  (math.series.taylor_symbolic, .laurent, .puiseux).
//
//  The power-series object and all arithmetic callbacks are pure Swift/Lua with
//  no optional dependencies.  The symbolic dispatchers delegate to math.cas.*
//  when compiled with LUASWIFT_THALES; in DEFAULT mode they provide graceful
//  fallback behaviour documented in the function body.
//
//  SPDX-License-Identifier: Apache-2.0
//

#if LUASWIFT_NUMERICSWIFT
import Foundation
import NumericSwift

/// Swift callbacks and Lua extensions for the power-series object and
/// symbolic series dispatchers.
///
/// Separated from `SeriesModule` to keep file sizes within the 400-line limit.
enum SeriesModulePower {

    // MARK: - Registration

    static func registerCallbacks(in engine: LuaEngine) {
        engine.registerFunction(
            name: "_luaswift_series_power_add", callback: powerAddCallback)
        engine.registerFunction(
            name: "_luaswift_series_power_mul", callback: powerMulCallback)
        engine.registerFunction(
            name: "_luaswift_series_power_truncate", callback: powerTruncateCallback)
        engine.registerFunction(
            name: "_luaswift_series_power_eval", callback: powerEvalCallback)
    }

    // MARK: - Power Series Callbacks

    /// Add two power series (term-by-term addition).
    ///
    /// Both series must have the same center.  Coefficients of the shorter
    /// series are zero-padded to match the length of the longer.
    static let powerAddCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2 else {
            throw LuaError.callbackError("series.power:add requires two power-series tables")
        }
        let (coeffsA, centerA) = try extractPowerSeries(args[0], label: "first")
        let (coeffsB, centerB) = try extractPowerSeries(args[1], label: "second")

        guard centerA == centerB else {
            throw LuaError.callbackError(
                "series.power:add — centers must match (\(centerA) ≠ \(centerB))")
        }

        let len = max(coeffsA.count, coeffsB.count)
        var result = [Double](repeating: 0, count: len)
        for i in 0..<len {
            let a = i < coeffsA.count ? coeffsA[i] : 0
            let b = i < coeffsB.count ? coeffsB[i] : 0
            result[i] = a + b
        }

        return makePowerSeriesTable(coefficients: result, center: centerA)
    }

    /// Multiply two power series via Cauchy product (truncated to shorter length).
    static let powerMulCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2 else {
            throw LuaError.callbackError("series.power:multiply requires two power-series tables")
        }
        let (coeffsA, centerA) = try extractPowerSeries(args[0], label: "first")
        let (coeffsB, centerB) = try extractPowerSeries(args[1], label: "second")

        guard centerA == centerB else {
            throw LuaError.callbackError(
                "series.power:multiply — centers must match (\(centerA) ≠ \(centerB))")
        }

        // Cauchy product truncated to min(|A|, |B|) - 1 terms
        let n = min(coeffsA.count, coeffsB.count)
        var result = [Double](repeating: 0, count: n)
        for k in 0..<n {
            for j in 0...k where j < coeffsA.count && (k - j) < coeffsB.count {
                result[k] += coeffsA[j] * coeffsB[k - j]
            }
        }

        return makePowerSeriesTable(coefficients: result, center: centerA)
    }

    /// Truncate a power series to `n` terms (keep coefficients 0..n-1).
    static let powerTruncateCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2, let n = args[1].numberValue.map({ Int($0) }) else {
            throw LuaError.callbackError("series.power:truncate requires (power_series, n)")
        }
        let (coeffs, center) = try extractPowerSeries(args[0], label: "series")
        let truncated = Array(coeffs.prefix(max(0, n)))
        return makePowerSeriesTable(coefficients: truncated, center: center)
    }

    /// Evaluate a power series at a point using Horner's method.
    static let powerEvalCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2, let x = args[1].numberValue else {
            throw LuaError.callbackError("series.power:eval requires (power_series, x)")
        }
        let (coeffs, center) = try extractPowerSeries(args[0], label: "series")
        guard !coeffs.isEmpty else { return .number(0.0) }
        let result = NumericSwift.polyval(coeffs, at: x, center: center)
        return .number(result)
    }

    // MARK: - Helpers

    private static func extractPowerSeries(
        _ value: LuaValue, label: String
    ) throws -> ([Double], Double) {
        guard case .table(let tbl) = value else {
            throw LuaError.callbackError(
                "series.power — \(label) must be a power-series table")
        }
        let center = tbl["center"]?.numberValue ?? 0.0
        var coeffs: [Double] = []

        if let arr = tbl["coefficients"], case .array(let luaArr) = arr {
            coeffs = luaArr.compactMap { $0.numberValue }
        } else if let tableCoeffs = tbl["coefficients"], case .table(let t) = tableCoeffs {
            var i = 1
            while let v = t[String(i)]?.numberValue {
                coeffs.append(v)
                i += 1
            }
        }

        if coeffs.isEmpty {
            throw LuaError.callbackError(
                "series.power — \(label) has no valid coefficients")
        }
        return (coeffs, center)
    }

    private static func makePowerSeriesTable(
        coefficients: [Double], center: Double
    ) -> LuaValue {
        .table([
            "coefficients": .array(coefficients.map { .number($0) }),
            "center": .number(center),
            "__is_power_series": .bool(true)
        ])
    }

    // MARK: - Lua Extensions

    /// Lua code that adds `series.power(...)` constructor and `series.taylor_symbolic`,
    /// `series.laurent`, `series.puiseux` dispatchers.
    ///
    /// The symbolic dispatchers use `#if`-switched runtime detection: when Thales
    /// is available `math.cas` exists at runtime; when it's not the dispatchers
    /// either fall back to numerical methods (taylor_symbolic for known functions)
    /// or raise a clear error.
    // swiftlint:disable:next function_body_length
    static let luaExtensions = """
    -- Power series object constructor and helpers
    local _power_add = _luaswift_series_power_add
    local _power_mul = _luaswift_series_power_mul
    local _power_truncate = _luaswift_series_power_truncate
    local _power_eval = _luaswift_series_power_eval

    -- Clean up global namespace immediately
    _luaswift_series_power_add = nil
    _luaswift_series_power_mul = nil
    _luaswift_series_power_truncate = nil
    _luaswift_series_power_eval = nil

    local series = luaswift.series

    --- Create a power series object from coefficients.
    -- @param opts table: {coefficients={...}, center=number, variable="x"}
    -- @return power series object with :add, :multiply, :truncate, :eval methods
    function series.power(opts)
        opts = opts or {}
        local coefficients = opts.coefficients or {}
        local center = opts.center or 0
        local variable = opts.variable or "x"

        local ps = {
            coefficients = coefficients,
            center = center,
            variable = variable,
            __is_power_series = true,
        }

        function ps:add(other)
            local result = _power_add(self, other)
            return series.power({
                coefficients = result.coefficients,
                center = result.center,
                variable = self.variable
            })
        end

        function ps:multiply(other)
            local result = _power_mul(self, other)
            return series.power({
                coefficients = result.coefficients,
                center = result.center,
                variable = self.variable
            })
        end

        function ps:truncate(n)
            local result = _power_truncate(self, n)
            return series.power({
                coefficients = result.coefficients,
                center = result.center,
                variable = self.variable
            })
        end

        function ps:eval(x)
            return _power_eval(self, x)
        end

        setmetatable(ps, {
            __call = function(self, x) return self:eval(x) end,
            __tostring = function(self)
                local parts = {}
                local a = self.center
                local v = self.variable or "x"
                for i, c in ipairs(self.coefficients) do
                    if c ~= 0 then
                        local n = i - 1
                        if n == 0 then
                            table.insert(parts, string.format("%.6g", c))
                        elseif n == 1 then
                            if a == 0 then
                                table.insert(parts, string.format("%.6g*%s", c, v))
                            else
                                table.insert(parts, string.format("%.6g*(%s-%.6g)", c, v, a))
                            end
                        else
                            if a == 0 then
                                table.insert(parts, string.format("%.6g*%s^%d", c, v, n))
                            else
                                table.insert(parts, string.format("%.6g*(%s-%.6g)^%d", c, v, a, n))
                            end
                        end
                    end
                end
                if #parts == 0 then return "0" end
                return table.concat(parts, " + "):gsub("%+ %-", "- ")
            end
        })

        return ps
    end

    --- Symbolic Taylor series expansion.
    -- When Thales CAS is available (math.cas exists), delegates to math.cas.taylor.
    -- For known functions (sin, cos, exp, ...) falls back to the numerical
    -- series.taylor when Thales is unavailable.
    -- For unknown expressions without Thales, raises a clear error.
    -- @param expr  string expression or function name
    -- @param opts  table {variable="x", around=0, terms=5}
    function series.taylor_symbolic(expr, opts)
        opts = opts or {}
        if math.cas then
            -- Thales CAS available: use symbolic expansion
            local variable = opts.variable or opts.var or "x"
            local around   = opts.around or opts.at or 0
            local terms    = opts.terms or 5
            return math.cas.taylor(expr, variable, around, terms)
        else
            -- Thales not available: attempt numerical fallback for known functions
            local known = {sin=true, cos=true, exp=true, log1p=true, sinh=true,
                           cosh=true, tan=true, atan=true, geometric=true,
                           geometric_alt=true, sqrt1p=true, inv1p=true}
            if known[expr] then
                return series.taylor(expr, opts)
            end
            error(
                "series.taylor_symbolic: symbolic expansion of '" .. tostring(expr) ..
                "' requires the Thales CAS backend. " ..
                "Build with LUASWIFT_INCLUDE_THALES=1, or use series.taylor() " ..
                "for known functions (sin, cos, exp, ...).", 2)
        end
    end

    --- Laurent series expansion.
    -- Requires Thales CAS (LUASWIFT_INCLUDE_THALES=1). Raises a clear error otherwise.
    -- @param expr  string expression
    -- @param opts  table {variable="x", center=0, neg_order=3, pos_order=3}
    function series.laurent(expr, opts)
        if math.cas then
            opts = opts or {}
            local variable  = opts.variable or opts.var or "x"
            local center    = opts.center or 0
            local neg_order = opts.neg_order or 3
            local pos_order = opts.pos_order or 3
            return math.cas.laurent(expr, variable, center, neg_order, pos_order)
        end
        error(
            "series.laurent requires the Thales CAS backend. " ..
            "Build with LUASWIFT_INCLUDE_THALES=1.", 2)
    end

    --- Puiseux series expansion (fractional-power Laurent).
    -- Requires Thales CAS (LUASWIFT_INCLUDE_THALES=1). Raises a clear error otherwise.
    -- @param expr  string expression
    -- @param opts  table {variable="x", center=0, order=5}
    function series.puiseux(expr, opts)
        if math.cas then
            opts = opts or {}
            local variable = opts.variable or opts.var or "x"
            local center   = opts.center or 0
            local order    = opts.order or opts.terms or 5
            return math.cas.puiseux(expr, variable, center, order)
        end
        error(
            "series.puiseux requires the Thales CAS backend. " ..
            "Build with LUASWIFT_INCLUDE_THALES=1.", 2)
    end

    -- Update namespace alias so math.series picks up the new functions
    math.series = series
    luaswift.series = series
    """
}

#endif  // LUASWIFT_NUMERICSWIFT
