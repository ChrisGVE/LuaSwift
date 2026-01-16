//
//  InterpolateModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
import Foundation
import NumericSwift

/// Swift-backed interpolation module for LuaSwift.
///
/// Provides interpolation functions including 1D interpolation, cubic splines,
/// PCHIP, Akima, Lagrange, and barycentric interpolation. All algorithms
/// implemented in NumericSwift library, with thin Lua bindings here.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- 1D interpolation
/// local x = {0, 1, 2, 3, 4}
/// local y = {0, 1, 4, 9, 16}
/// local f = math.interpolate.interp1d(x, y, "linear")
/// print(f(1.5))  -- 2.5
///
/// -- Cubic spline
/// local cs = math.interpolate.CubicSpline(x, y)
/// print(cs(1.5))  -- interpolated value
/// print(cs.derivative(1.5))  -- first derivative
/// ```
public struct InterpolateModule {

    // MARK: - Helper Functions

    /// Convert boundary condition string to enum
    private static func bcFromString(_ str: String) -> SplineBoundaryCondition {
        switch str.lowercased() {
        case "natural":
            return .natural
        case "clamped":
            return .clamped
        default:
            return .notAKnot
        }
    }

    /// Convert interpolation kind string to enum
    private static func kindFromString(_ str: String) -> InterpolationKind {
        switch str.lowercased() {
        case "nearest":
            return .nearest
        case "previous":
            return .previous
        case "next":
            return .next
        case "cubic":
            return .cubic
        default:
            return .linear
        }
    }

    // MARK: - Registration

    /// Register the interpolation module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_interp_spline_coeffs", callback: makeSplineCoeffsCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_spline", callback: makeEvalSplineCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_spline_deriv", callback: makeEvalSplineDerivCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_integrate_spline", callback: makeIntegrateSplineCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_pchip_derivs", callback: makePchipDerivsCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_pchip", callback: makeEvalPchipCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_akima_coeffs", callback: makeAkimaCoeffsCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_akima", callback: makeEvalAkimaCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_lagrange", callback: makeEvalLagrangeCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_barycentric_weights", callback: makeBarycentricWeightsCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_barycentric", callback: makeEvalBarycentricCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_interp1d", callback: makeInterp1dCallback(engine))

        // Set up Lua namespace with thin wrappers
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.interpolate then luaswift.interpolate = {} end

                local interpolate = {}

                ----------------------------------------------------------------
                -- Helper: Binary search to find interval containing x
                ----------------------------------------------------------------
                local function find_interval(xs, x)
                    local lo, hi = 1, #xs
                    while hi - lo > 1 do
                        local mid = math.floor((lo + hi) / 2)
                        if xs[mid] > x then
                            hi = mid
                        else
                            lo = mid
                        end
                    end
                    return lo
                end

                ----------------------------------------------------------------
                -- Complex number helpers
                ----------------------------------------------------------------
                local function is_complex(v)
                    return type(v) == "table" and v.re ~= nil and v.im ~= nil
                end

                local function has_complex(arr)
                    for i = 1, #arr do
                        if is_complex(arr[i]) then return true end
                    end
                    return false
                end

                local function get_real_parts(arr)
                    local result = {}
                    for i = 1, #arr do
                        result[i] = is_complex(arr[i]) and arr[i].re or arr[i]
                    end
                    return result
                end

                local function get_imag_parts(arr)
                    local result = {}
                    for i = 1, #arr do
                        result[i] = is_complex(arr[i]) and arr[i].im or 0
                    end
                    return result
                end

                ----------------------------------------------------------------
                -- interp1d: 1D interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.interp1d(x, y, kind, options)
                    options = options or {}
                    kind = kind or "linear"
                    local fill_value = options.fill_value or (0/0)
                    local bounds_error = options.bounds_error or false

                    local n = #x
                    if n < 2 then error("interp1d: need at least 2 data points") end
                    if n ~= #y then error("interp1d: x and y must have same length") end

                    local xs, ys = {}, {}
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local is_complex_data = has_complex(ys)
                    local coeffs_re, coeffs_im = nil, nil

                    if kind == "cubic" then
                        if is_complex_data then
                            coeffs_re = _luaswift_interp_spline_coeffs(xs, get_real_parts(ys), "natural")
                            coeffs_im = _luaswift_interp_spline_coeffs(xs, get_imag_parts(ys), "natural")
                        else
                            coeffs_re = _luaswift_interp_spline_coeffs(xs, ys, "natural")
                        end
                    end

                    return function(x_new)
                        if type(x_new) == "table" and not is_complex(x_new) then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._interp1d_single(xs, ys, xi, kind, fill_value, bounds_error, coeffs_re, coeffs_im, is_complex_data)
                            end
                            return result
                        end
                        return interpolate._interp1d_single(xs, ys, x_new, kind, fill_value, bounds_error, coeffs_re, coeffs_im, is_complex_data)
                    end
                end

                function interpolate._interp1d_single(xs, ys, x_new, kind, fill_value, bounds_error, coeffs_re, coeffs_im, is_complex_data)
                    local n = #xs
                    if x_new < xs[1] or x_new > xs[n] then
                        if bounds_error then error("interp1d: value outside range") end
                        return fill_value
                    end
                    if x_new == xs[1] then return ys[1] end
                    if x_new == xs[n] then return ys[n] end

                    local i = find_interval(xs, x_new)

                    if kind == "nearest" then
                        return math.abs(x_new - xs[i]) <= math.abs(x_new - xs[i+1]) and ys[i] or ys[i+1]
                    elseif kind == "previous" then
                        return ys[i]
                    elseif kind == "next" then
                        return ys[i+1]
                    elseif kind == "cubic" then
                        if is_complex_data then
                            local re = _luaswift_interp_eval_spline(xs, coeffs_re, x_new, true)
                            local im = _luaswift_interp_eval_spline(xs, coeffs_im, x_new, true)
                            return {re = re, im = im}
                        else
                            return _luaswift_interp_eval_spline(xs, coeffs_re, x_new, true)
                        end
                    else
                        -- Linear (or default)
                        local t = (x_new - xs[i]) / (xs[i+1] - xs[i])
                        local y1, y2 = ys[i], ys[i+1]
                        if is_complex(y1) or is_complex(y2) then
                            local r1 = is_complex(y1) and y1.re or y1
                            local i1 = is_complex(y1) and y1.im or 0
                            local r2 = is_complex(y2) and y2.re or y2
                            local i2 = is_complex(y2) and y2.im or 0
                            return {re = r1 + t * (r2 - r1), im = i1 + t * (i2 - i1)}
                        else
                            return y1 + t * (y2 - y1)
                        end
                    end
                end

                ----------------------------------------------------------------
                -- CubicSpline: Cubic spline interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.CubicSpline(x, y, options)
                    options = options or {}
                    local bc_type = options.bc_type or "not-a-knot"
                    local extrapolate = options.extrapolate
                    if extrapolate == nil then extrapolate = true end

                    local n = #x
                    if n < 2 then error("CubicSpline: need at least 2 data points") end
                    if n ~= #y then error("CubicSpline: x and y must have same length") end

                    local xs, ys = {}, {}
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local is_complex_data = has_complex(ys)
                    local coeffs, coeffs_re, coeffs_im

                    if is_complex_data then
                        coeffs_re = _luaswift_interp_spline_coeffs(xs, get_real_parts(ys), bc_type)
                        coeffs_im = _luaswift_interp_spline_coeffs(xs, get_imag_parts(ys), bc_type)
                    else
                        coeffs = _luaswift_interp_spline_coeffs(xs, ys, bc_type)
                    end

                    local spline = {x = xs, y = ys, extrapolate = extrapolate, is_complex = is_complex_data}

                    local function evaluate(x_new)
                        if type(x_new) == "table" and not is_complex(x_new) then
                            local result = {}
                            for i, xi in ipairs(x_new) do result[i] = evaluate(xi) end
                            return result
                        end

                        if is_complex_data then
                            local re = _luaswift_interp_eval_spline(xs, coeffs_re, x_new, extrapolate)
                            local im = _luaswift_interp_eval_spline(xs, coeffs_im, x_new, extrapolate)
                            return {re = re, im = im}
                        else
                            return _luaswift_interp_eval_spline(xs, coeffs, x_new, extrapolate)
                        end
                    end

                    function spline.derivative(x_new, nu)
                        nu = nu or 1
                        if type(x_new) == "table" and not is_complex(x_new) then
                            local result = {}
                            for i, xi in ipairs(x_new) do result[i] = spline.derivative(xi, nu) end
                            return result
                        end
                        if is_complex_data then
                            local re = _luaswift_interp_eval_spline_deriv(xs, coeffs_re, x_new, nu)
                            local im = _luaswift_interp_eval_spline_deriv(xs, coeffs_im, x_new, nu)
                            return {re = re, im = im}
                        else
                            return _luaswift_interp_eval_spline_deriv(xs, coeffs, x_new, nu)
                        end
                    end

                    function spline.integrate(a, b)
                        if is_complex_data then
                            local re = _luaswift_interp_integrate_spline(xs, coeffs_re, a, b)
                            local im = _luaswift_interp_integrate_spline(xs, coeffs_im, a, b)
                            return {re = re, im = im}
                        else
                            return _luaswift_interp_integrate_spline(xs, coeffs, a, b)
                        end
                    end

                    setmetatable(spline, {__call = function(_, x_new) return evaluate(x_new) end})
                    return spline
                end

                ----------------------------------------------------------------
                -- PchipInterpolator: PCHIP interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.PchipInterpolator(x, y)
                    local n = #x
                    if n < 2 then error("PchipInterpolator: need at least 2 data points") end
                    if n ~= #y then error("PchipInterpolator: x and y must have same length") end

                    local xs, ys = {}, {}
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local d = _luaswift_interp_pchip_derivs(xs, ys)

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = _luaswift_interp_eval_pchip(xs, ys, d, xi)
                            end
                            return result
                        end
                        return _luaswift_interp_eval_pchip(xs, ys, d, x_new)
                    end
                end

                ----------------------------------------------------------------
                -- Akima1DInterpolator: Akima interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.Akima1DInterpolator(x, y)
                    local n = #x
                    if n < 2 then error("Akima1DInterpolator: need at least 2 data points") end
                    if n ~= #y then error("Akima1DInterpolator: x and y must have same length") end

                    local xs, ys = {}, {}
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local coeffs = _luaswift_interp_akima_coeffs(xs, ys)

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = _luaswift_interp_eval_akima(xs, coeffs, xi)
                            end
                            return result
                        end
                        return _luaswift_interp_eval_akima(xs, coeffs, x_new)
                    end
                end

                ----------------------------------------------------------------
                -- lagrange: Lagrange polynomial interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.lagrange(x, y)
                    local n = #x
                    if n ~= #y then error("lagrange: x and y must have same length") end

                    local xs, ys = {}, {}
                    local is_complex_data = has_complex(y)
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._eval_lagrange(xs, ys, xi, is_complex_data)
                            end
                            return result
                        end
                        return interpolate._eval_lagrange(xs, ys, x_new, is_complex_data)
                    end
                end

                function interpolate._eval_lagrange(xs, ys, x_new, is_complex_data)
                    if is_complex_data then
                        local ys_re = get_real_parts(ys)
                        local ys_im = get_imag_parts(ys)
                        local re = _luaswift_interp_eval_lagrange(xs, ys_re, x_new)
                        local im = _luaswift_interp_eval_lagrange(xs, ys_im, x_new)
                        return {re = re, im = im}
                    else
                        return _luaswift_interp_eval_lagrange(xs, ys, x_new)
                    end
                end

                ----------------------------------------------------------------
                -- BarycentricInterpolator: Barycentric interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.BarycentricInterpolator(x, y)
                    local n = #x
                    if n ~= #y then error("BarycentricInterpolator: x and y must have same length") end

                    local xs, ys = {}, {}
                    local is_complex_data = has_complex(y)
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local w = _luaswift_interp_barycentric_weights(xs)

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._eval_barycentric(xs, ys, w, xi, is_complex_data)
                            end
                            return result
                        end
                        return interpolate._eval_barycentric(xs, ys, w, x_new, is_complex_data)
                    end
                end

                function interpolate._eval_barycentric(xs, ys, w, x_new, is_complex_data)
                    -- Check for exact match
                    for i = 1, #xs do
                        if x_new == xs[i] then return ys[i] end
                    end

                    if is_complex_data then
                        local ys_re = get_real_parts(ys)
                        local ys_im = get_imag_parts(ys)
                        local re = _luaswift_interp_eval_barycentric(xs, ys_re, w, x_new)
                        local im = _luaswift_interp_eval_barycentric(xs, ys_im, w, x_new)
                        return {re = re, im = im}
                    else
                        return _luaswift_interp_eval_barycentric(xs, ys, w, x_new)
                    end
                end

                -- Store the module
                luaswift.interpolate = interpolate

                -- Also update math.interpolate
                if math then
                    if not math.interpolate then math.interpolate = {} end
                    for k, v in pairs(interpolate) do
                        math.interpolate[k] = v
                    end
                end
                """)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Callbacks

    /// Callback for computing spline coefficients
    private static func makeSplineCoeffsCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue else {
                throw LuaError.runtimeError("spline_coeffs: expected x and y arrays")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }
            let bcStr = args.count > 2 ? args[2].stringValue ?? "not-a-knot" : "not-a-knot"
            let bc = bcFromString(bcStr)

            let coeffs = NumericSwift.computeSplineCoeffs(x: x, y: y, bc: bc)

            // Return as array of {a, b, c, d} tables
            let result = coeffs.map { c -> LuaValue in
                .array([.number(c.a), .number(c.b), .number(c.c), .number(c.d)])
            }
            return .array(result)
        }
    }

    /// Callback for evaluating spline
    private static func makeEvalSplineCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  let xTable = args[0].arrayValue,
                  let coeffsTable = args[1].arrayValue,
                  let xNew = args[2].numberValue else {
                throw LuaError.runtimeError("eval_spline: expected x, coeffs, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let extrapolate = args.count > 3 ? (args[3].boolValue ?? true) : true

            // Parse coefficients
            var coeffs = [CubicCoeffs]()
            for c in coeffsTable {
                if let arr = c.arrayValue, arr.count >= 4,
                   let a = arr[0].numberValue,
                   let b = arr[1].numberValue,
                   let cc = arr[2].numberValue,
                   let d = arr[3].numberValue {
                    coeffs.append(CubicCoeffs(a: a, b: b, c: cc, d: d))
                }
            }

            let result = NumericSwift.evalCubicSpline(x: x, coeffs: coeffs, xNew: xNew, extrapolate: extrapolate)
            return .number(result)
        }
    }

    /// Callback for evaluating spline derivative
    private static func makeEvalSplineDerivCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  let xTable = args[0].arrayValue,
                  let coeffsTable = args[1].arrayValue,
                  let xNew = args[2].numberValue else {
                throw LuaError.runtimeError("eval_spline_deriv: expected x, coeffs, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let order = args.count > 3 ? Int(args[3].numberValue ?? 1) : 1

            var coeffs = [CubicCoeffs]()
            for c in coeffsTable {
                if let arr = c.arrayValue, arr.count >= 4,
                   let a = arr[0].numberValue,
                   let b = arr[1].numberValue,
                   let cc = arr[2].numberValue,
                   let d = arr[3].numberValue {
                    coeffs.append(CubicCoeffs(a: a, b: b, c: cc, d: d))
                }
            }

            let result = NumericSwift.evalCubicSplineDerivative(x: x, coeffs: coeffs, xNew: xNew, order: order)
            return .number(result)
        }
    }

    /// Callback for integrating spline
    private static func makeIntegrateSplineCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  let xTable = args[0].arrayValue,
                  let coeffsTable = args[1].arrayValue,
                  let a = args[2].numberValue,
                  let b = args[3].numberValue else {
                throw LuaError.runtimeError("integrate_spline: expected x, coeffs, a, b")
            }

            let x = xTable.compactMap { $0.numberValue }

            var coeffs = [CubicCoeffs]()
            for c in coeffsTable {
                if let arr = c.arrayValue, arr.count >= 4,
                   let aa = arr[0].numberValue,
                   let bb = arr[1].numberValue,
                   let cc = arr[2].numberValue,
                   let dd = arr[3].numberValue {
                    coeffs.append(CubicCoeffs(a: aa, b: bb, c: cc, d: dd))
                }
            }

            let result = NumericSwift.integrateCubicSpline(x: x, coeffs: coeffs, a: a, b: b)
            return .number(result)
        }
    }

    /// Callback for computing PCHIP derivatives
    private static func makePchipDerivsCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue else {
                throw LuaError.runtimeError("pchip_derivs: expected x and y arrays")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }

            let d = NumericSwift.computePchipDerivatives(x: x, y: y)
            return .array(d.map { .number($0) })
        }
    }

    /// Callback for evaluating PCHIP
    private static func makeEvalPchipCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue,
                  let dTable = args[2].arrayValue,
                  let xNew = args[3].numberValue else {
                throw LuaError.runtimeError("eval_pchip: expected x, y, d, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }
            let d = dTable.compactMap { $0.numberValue }

            let result = NumericSwift.evalPchip(x: x, y: y, d: d, xNew: xNew)
            return .number(result)
        }
    }

    /// Callback for computing Akima coefficients
    private static func makeAkimaCoeffsCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue else {
                throw LuaError.runtimeError("akima_coeffs: expected x and y arrays")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }

            let coeffs = NumericSwift.computeAkimaCoeffs(x: x, y: y)
            let result = coeffs.map { c -> LuaValue in
                .array([.number(c.a), .number(c.b), .number(c.c), .number(c.d)])
            }
            return .array(result)
        }
    }

    /// Callback for evaluating Akima
    private static func makeEvalAkimaCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  let xTable = args[0].arrayValue,
                  let coeffsTable = args[1].arrayValue,
                  let xNew = args[2].numberValue else {
                throw LuaError.runtimeError("eval_akima: expected x, coeffs, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }

            var coeffs = [CubicCoeffs]()
            for c in coeffsTable {
                if let arr = c.arrayValue, arr.count >= 4,
                   let a = arr[0].numberValue,
                   let b = arr[1].numberValue,
                   let cc = arr[2].numberValue,
                   let d = arr[3].numberValue {
                    coeffs.append(CubicCoeffs(a: a, b: b, c: cc, d: d))
                }
            }

            let result = NumericSwift.evalAkima(x: x, coeffs: coeffs, xNew: xNew)
            return .number(result)
        }
    }

    /// Callback for evaluating Lagrange
    private static func makeEvalLagrangeCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue,
                  let xNew = args[2].numberValue else {
                throw LuaError.runtimeError("eval_lagrange: expected x, y, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }

            let result = NumericSwift.evalLagrange(x: x, y: y, xNew: xNew)
            return .number(result)
        }
    }

    /// Callback for computing barycentric weights
    private static func makeBarycentricWeightsCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 1,
                  let xTable = args[0].arrayValue else {
                throw LuaError.runtimeError("barycentric_weights: expected x array")
            }

            let x = xTable.compactMap { $0.numberValue }
            let w = NumericSwift.computeBarycentricWeights(x: x)
            return .array(w.map { .number($0) })
        }
    }

    /// Callback for evaluating barycentric
    private static func makeEvalBarycentricCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue,
                  let wTable = args[2].arrayValue,
                  let xNew = args[3].numberValue else {
                throw LuaError.runtimeError("eval_barycentric: expected x, y, w, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }
            let w = wTable.compactMap { $0.numberValue }

            let result = NumericSwift.evalBarycentric(x: x, y: y, w: w, xNew: xNew)
            return .number(result)
        }
    }

    /// Callback for simple interp1d (non-cubic)
    private static func makeInterp1dCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue,
                  let xNew = args[2].numberValue,
                  let kindStr = args[3].stringValue else {
                throw LuaError.runtimeError("interp1d: expected x, y, xNew, kind")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }
            let fillValue = args.count > 4 ? args[4].numberValue ?? Double.nan : Double.nan
            let boundsError = args.count > 5 ? args[5].boolValue ?? false : false

            let kind = kindFromString(kindStr)

            let result = NumericSwift.interp1d(x: x, y: y, xNew: xNew, kind: kind, fillValue: fillValue, boundsError: boundsError, coeffs: nil)
            return .number(result)
        }
    }
}

#endif  // LUASWIFT_NUMERICSWIFT
