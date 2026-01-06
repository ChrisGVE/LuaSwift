//
//  InterpolateModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed interpolation module for LuaSwift.
///
/// Provides interpolation functions including 1D interpolation and cubic splines.
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

    // MARK: - Registration

    /// Register the interpolation module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // All interpolation algorithms implemented in Lua for natural function calling
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
                -- interp1d: 1D interpolation
                --
                -- Arguments:
                --   x: array of x coordinates (must be strictly increasing)
                --   y: array of y values
                --   kind: "linear", "nearest", "cubic", "previous", "next"
                --         (default: "linear")
                --   options: {
                --     fill_value: value for extrapolation (default: nan)
                --     bounds_error: if true, raise error on extrapolation (default: false)
                --   }
                --
                -- Returns: interpolation function f(x_new)
                ----------------------------------------------------------------
                function interpolate.interp1d(x, y, kind, options)
                    options = options or {}
                    kind = kind or "linear"
                    local fill_value = options.fill_value or (0/0)  -- NaN
                    local bounds_error = options.bounds_error or false

                    local n = #x
                    if n < 2 then
                        error("interp1d: need at least 2 data points")
                    end
                    if n ~= #y then
                        error("interp1d: x and y must have same length")
                    end

                    -- Copy arrays
                    local xs, ys = {}, {}
                    for i = 1, n do
                        xs[i] = x[i]
                        ys[i] = y[i]
                    end

                    -- For cubic interpolation, precompute spline coefficients
                    local coeffs = nil
                    if kind == "cubic" then
                        -- Use natural cubic spline
                        coeffs = interpolate._compute_spline_coeffs(xs, ys, "natural")
                    end

                    -- Return interpolation function
                    return function(x_new)
                        -- Handle array input
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._interp1d_single(
                                    xs, ys, xi, kind, fill_value, bounds_error, coeffs
                                )
                            end
                            return result
                        else
                            return interpolate._interp1d_single(
                                xs, ys, x_new, kind, fill_value, bounds_error, coeffs
                            )
                        end
                    end
                end

                -- Single point interpolation helper
                function interpolate._interp1d_single(xs, ys, x_new, kind, fill_value, bounds_error, coeffs)
                    local n = #xs

                    -- Check bounds
                    if x_new < xs[1] or x_new > xs[n] then
                        if bounds_error then
                            error("interp1d: value " .. x_new .. " is outside interpolation range")
                        end
                        return fill_value
                    end

                    -- Handle exact boundary values
                    if x_new == xs[1] then return ys[1] end
                    if x_new == xs[n] then return ys[n] end

                    local i = find_interval(xs, x_new)

                    if kind == "nearest" then
                        -- Nearest neighbor
                        local d1 = math.abs(x_new - xs[i])
                        local d2 = math.abs(x_new - xs[i + 1])
                        return d1 <= d2 and ys[i] or ys[i + 1]

                    elseif kind == "previous" then
                        return ys[i]

                    elseif kind == "next" then
                        return ys[i + 1]

                    elseif kind == "cubic" then
                        -- Cubic spline evaluation
                        local dx = x_new - xs[i]
                        local a, b, c, d = coeffs[i][1], coeffs[i][2], coeffs[i][3], coeffs[i][4]
                        return a + b * dx + c * dx^2 + d * dx^3

                    else  -- "linear" or default
                        -- Linear interpolation
                        local t = (x_new - xs[i]) / (xs[i + 1] - xs[i])
                        return ys[i] + t * (ys[i + 1] - ys[i])
                    end
                end

                ----------------------------------------------------------------
                -- Compute cubic spline coefficients
                --
                -- For spline S_i(x) = a_i + b_i(x-x_i) + c_i(x-x_i)^2 + d_i(x-x_i)^3
                -- Returns array of {a, b, c, d} for each interval
                ----------------------------------------------------------------
                function interpolate._compute_spline_coeffs(x, y, bc_type)
                    local n = #x
                    bc_type = bc_type or "natural"

                    -- Compute intervals h_i = x_{i+1} - x_i
                    local h = {}
                    for i = 1, n - 1 do
                        h[i] = x[i + 1] - x[i]
                    end

                    -- Set up tridiagonal system for second derivatives (c values)
                    -- Natural spline: c_0 = c_{n-1} = 0
                    -- Not-a-knot: continuity of third derivative at second and second-to-last knots

                    -- System: A * c = rhs
                    -- where c = [c_0, c_1, ..., c_{n-1}]

                    local diag = {}      -- diagonal
                    local off_diag = {}  -- off-diagonal (same for super and sub)
                    local rhs = {}       -- right-hand side

                    if bc_type == "natural" then
                        -- Natural boundary: c_0 = 0, c_{n-1} = 0
                        -- Interior equations
                        for i = 2, n - 1 do
                            diag[i] = 2 * (h[i - 1] + h[i])
                            off_diag[i - 1] = h[i - 1]
                            rhs[i] = 3 * ((y[i + 1] - y[i]) / h[i] - (y[i] - y[i - 1]) / h[i - 1])
                        end

                        -- Boundary conditions
                        diag[1] = 1
                        rhs[1] = 0
                        diag[n] = 1
                        rhs[n] = 0
                        off_diag[0] = 0
                        off_diag[n - 1] = 0

                    elseif bc_type == "clamped" then
                        -- Clamped: specify first derivatives at endpoints (default to 0)
                        local fp0 = 0  -- f'(x_0)
                        local fpn = 0  -- f'(x_{n-1})

                        diag[1] = 2 * h[1]
                        rhs[1] = 3 * ((y[2] - y[1]) / h[1] - fp0)
                        off_diag[0] = h[1]

                        for i = 2, n - 1 do
                            diag[i] = 2 * (h[i - 1] + h[i])
                            off_diag[i - 1] = h[i - 1]
                            rhs[i] = 3 * ((y[i + 1] - y[i]) / h[i] - (y[i] - y[i - 1]) / h[i - 1])
                        end

                        diag[n] = 2 * h[n - 1]
                        rhs[n] = 3 * (fpn - (y[n] - y[n - 1]) / h[n - 1])
                        off_diag[n - 1] = h[n - 1]

                    else  -- "not-a-knot" - most similar to scipy default
                        -- For n >= 4, not-a-knot conditions
                        if n >= 4 then
                            -- First equation: continuity of third derivative at x_1
                            diag[1] = h[2]
                            off_diag[0] = -(h[1] + h[2])
                            rhs[1] = 3 * ((y[3] - y[2]) / h[2] - (y[2] - y[1]) / h[1])

                            -- Interior equations
                            for i = 2, n - 1 do
                                diag[i] = 2 * (h[i - 1] + h[i])
                                off_diag[i - 1] = h[i - 1]
                                rhs[i] = 3 * ((y[i + 1] - y[i]) / h[i] - (y[i] - y[i - 1]) / h[i - 1])
                            end

                            -- Last equation: continuity of third derivative at x_{n-2}
                            diag[n] = h[n - 2]
                            off_diag[n - 1] = -(h[n - 2] + h[n - 1])
                            rhs[n] = 3 * ((y[n] - y[n - 1]) / h[n - 1] - (y[n - 1] - y[n - 2]) / h[n - 2])
                        else
                            -- Fall back to natural for n < 4
                            return interpolate._compute_spline_coeffs(x, y, "natural")
                        end
                    end

                    -- Solve tridiagonal system using Thomas algorithm
                    local c = interpolate._solve_tridiagonal(diag, off_diag, rhs, n)

                    -- Compute a, b, d coefficients
                    local coeffs = {}
                    for i = 1, n - 1 do
                        local a = y[i]
                        local b = (y[i + 1] - y[i]) / h[i] - h[i] * (2 * c[i] + c[i + 1]) / 3
                        local d = (c[i + 1] - c[i]) / (3 * h[i])
                        coeffs[i] = {a, b, c[i], d}
                    end

                    return coeffs
                end

                ----------------------------------------------------------------
                -- Solve tridiagonal system using Thomas algorithm
                ----------------------------------------------------------------
                function interpolate._solve_tridiagonal(diag, off_diag, rhs, n)
                    -- Forward elimination
                    local c_prime = {}
                    local d_prime = {}

                    c_prime[1] = (off_diag[0] or 0) / diag[1]
                    d_prime[1] = rhs[1] / diag[1]

                    for i = 2, n do
                        local m = diag[i] - (off_diag[i - 1] or 0) * c_prime[i - 1]
                        c_prime[i] = (off_diag[i - 1] or 0) / m
                        d_prime[i] = (rhs[i] - (off_diag[i - 1] or 0) * d_prime[i - 1]) / m
                    end

                    -- Back substitution
                    local x = {}
                    x[n] = d_prime[n]
                    for i = n - 1, 1, -1 do
                        x[i] = d_prime[i] - c_prime[i] * x[i + 1]
                    end

                    return x
                end

                ----------------------------------------------------------------
                -- CubicSpline: Cubic spline interpolation
                --
                -- Arguments:
                --   x: array of x coordinates (must be strictly increasing)
                --   y: array of y values
                --   options: {
                --     bc_type: "natural", "clamped", "not-a-knot" (default: "not-a-knot")
                --     extrapolate: if true, extrapolate outside bounds (default: true)
                --   }
                --
                -- Returns: spline object with methods:
                --   __call(x_new): evaluate spline at x_new
                --   derivative(x_new, nu): evaluate nu-th derivative (default nu=1)
                --   integrate(a, b): definite integral from a to b
                ----------------------------------------------------------------
                function interpolate.CubicSpline(x, y, options)
                    options = options or {}
                    local bc_type = options.bc_type or "not-a-knot"
                    local extrapolate = options.extrapolate
                    if extrapolate == nil then extrapolate = true end

                    local n = #x
                    if n < 2 then
                        error("CubicSpline: need at least 2 data points")
                    end
                    if n ~= #y then
                        error("CubicSpline: x and y must have same length")
                    end

                    -- Copy arrays
                    local xs, ys = {}, {}
                    for i = 1, n do
                        xs[i] = x[i]
                        ys[i] = y[i]
                    end

                    -- Compute spline coefficients
                    local coeffs = interpolate._compute_spline_coeffs(xs, ys, bc_type)

                    -- Create spline object
                    local spline = {
                        x = xs,
                        y = ys,
                        coeffs = coeffs,
                        extrapolate = extrapolate
                    }

                    -- Evaluate spline at point(s)
                    local function evaluate(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = evaluate(xi)
                            end
                            return result
                        end

                        -- Check bounds
                        if x_new < xs[1] then
                            if not extrapolate then return 0/0 end
                            -- Linear extrapolation using first segment
                            local dx = x_new - xs[1]
                            local b = coeffs[1][2]
                            return ys[1] + b * dx
                        end
                        if x_new > xs[n] then
                            if not extrapolate then return 0/0 end
                            -- Linear extrapolation using last segment
                            local h = xs[n] - xs[n - 1]
                            local a, b, c, d = coeffs[n - 1][1], coeffs[n - 1][2], coeffs[n - 1][3], coeffs[n - 1][4]
                            local slope = b + 2 * c * h + 3 * d * h^2
                            return ys[n] + slope * (x_new - xs[n])
                        end

                        -- Find interval and evaluate
                        local i = find_interval(xs, x_new)
                        local dx = x_new - xs[i]
                        local a, b, c, d = coeffs[i][1], coeffs[i][2], coeffs[i][3], coeffs[i][4]
                        return a + b * dx + c * dx^2 + d * dx^3
                    end

                    -- Evaluate derivative
                    function spline.derivative(x_new, nu)
                        nu = nu or 1

                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = spline.derivative(xi, nu)
                            end
                            return result
                        end

                        -- Clamp to domain for derivatives
                        local x_eval = math.max(xs[1], math.min(x_new, xs[n]))
                        local i = find_interval(xs, x_eval)
                        if i >= n then i = n - 1 end

                        local dx = x_eval - xs[i]
                        local a, b, c, d = coeffs[i][1], coeffs[i][2], coeffs[i][3], coeffs[i][4]

                        if nu == 1 then
                            return b + 2 * c * dx + 3 * d * dx^2
                        elseif nu == 2 then
                            return 2 * c + 6 * d * dx
                        elseif nu == 3 then
                            return 6 * d
                        else
                            return 0  -- Higher derivatives of cubic are 0
                        end
                    end

                    -- Integrate over interval
                    function spline.integrate(a, b)
                        -- Clamp to spline domain
                        local x0 = math.max(xs[1], math.min(a, xs[n]))
                        local x1 = math.max(xs[1], math.min(b, xs[n]))

                        if x0 > x1 then
                            return -spline.integrate(b, a)
                        end

                        local total = 0
                        local i0 = find_interval(xs, x0)
                        local i1 = find_interval(xs, x1)

                        -- Helper to integrate polynomial on [0, dx]
                        -- integral of a + bx + cx^2 + dx^3 from 0 to dx
                        local function integrate_poly(a, b, c, d, dx)
                            return a * dx + b * dx^2 / 2 + c * dx^3 / 3 + d * dx^4 / 4
                        end

                        if i0 == i1 then
                            -- Same interval
                            local aa, bb, cc, dd = coeffs[i0][1], coeffs[i0][2], coeffs[i0][3], coeffs[i0][4]
                            local dx0 = x0 - xs[i0]
                            local dx1 = x1 - xs[i0]
                            total = integrate_poly(aa, bb, cc, dd, dx1) - integrate_poly(aa, bb, cc, dd, dx0)
                        else
                            -- First partial interval
                            local aa, bb, cc, dd = coeffs[i0][1], coeffs[i0][2], coeffs[i0][3], coeffs[i0][4]
                            local dx0 = x0 - xs[i0]
                            local dx1 = xs[i0 + 1] - xs[i0]
                            total = integrate_poly(aa, bb, cc, dd, dx1) - integrate_poly(aa, bb, cc, dd, dx0)

                            -- Full intervals
                            for i = i0 + 1, i1 - 1 do
                                aa, bb, cc, dd = coeffs[i][1], coeffs[i][2], coeffs[i][3], coeffs[i][4]
                                local h = xs[i + 1] - xs[i]
                                total = total + integrate_poly(aa, bb, cc, dd, h)
                            end

                            -- Last partial interval
                            if i1 <= n - 1 then
                                aa, bb, cc, dd = coeffs[i1][1], coeffs[i1][2], coeffs[i1][3], coeffs[i1][4]
                                dx1 = x1 - xs[i1]
                                total = total + integrate_poly(aa, bb, cc, dd, dx1)
                            end
                        end

                        return total
                    end

                    -- Make spline callable
                    setmetatable(spline, {
                        __call = function(_, x_new)
                            return evaluate(x_new)
                        end
                    })

                    return spline
                end

                ----------------------------------------------------------------
                -- PchipInterpolator: Piecewise Cubic Hermite Interpolating Polynomial
                --
                -- Monotonic interpolation that preserves monotonicity of data.
                -- Arguments:
                --   x: array of x coordinates (must be strictly increasing)
                --   y: array of y values
                --
                -- Returns: interpolation function
                ----------------------------------------------------------------
                function interpolate.PchipInterpolator(x, y)
                    local n = #x
                    if n < 2 then
                        error("PchipInterpolator: need at least 2 data points")
                    end
                    if n ~= #y then
                        error("PchipInterpolator: x and y must have same length")
                    end

                    -- Copy arrays
                    local xs, ys = {}, {}
                    for i = 1, n do
                        xs[i] = x[i]
                        ys[i] = y[i]
                    end

                    -- Compute slopes
                    local h = {}
                    local delta = {}
                    for i = 1, n - 1 do
                        h[i] = xs[i + 1] - xs[i]
                        delta[i] = (ys[i + 1] - ys[i]) / h[i]
                    end

                    -- Compute PCHIP derivatives at each point
                    local d = {}
                    if n == 2 then
                        d[1] = delta[1]
                        d[2] = delta[1]
                    else
                        -- Endpoints
                        d[1] = interpolate._pchip_edge_deriv(h[1], h[2], delta[1], delta[2])
                        d[n] = interpolate._pchip_edge_deriv(h[n - 1], h[n - 2], delta[n - 1], delta[n - 2])

                        -- Interior points
                        for i = 2, n - 1 do
                            if delta[i - 1] * delta[i] > 0 then
                                -- Both slopes same sign - use weighted harmonic mean
                                local w1 = 2 * h[i] + h[i - 1]
                                local w2 = h[i] + 2 * h[i - 1]
                                d[i] = (w1 + w2) / (w1 / delta[i - 1] + w2 / delta[i])
                            else
                                d[i] = 0
                            end
                        end
                    end

                    -- Return interpolation function using Hermite basis
                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._pchip_eval(xs, ys, d, xi)
                            end
                            return result
                        end
                        return interpolate._pchip_eval(xs, ys, d, x_new)
                    end
                end

                -- PCHIP edge derivative
                function interpolate._pchip_edge_deriv(h1, h2, d1, d2)
                    local deriv = ((2 * h1 + h2) * d1 - h1 * d2) / (h1 + h2)
                    if deriv * d1 < 0 then
                        return 0
                    elseif d1 * d2 < 0 and math.abs(deriv) > 3 * math.abs(d1) then
                        return 3 * d1
                    end
                    return deriv
                end

                -- PCHIP evaluation
                function interpolate._pchip_eval(xs, ys, d, x_new)
                    local n = #xs

                    -- Handle extrapolation with linear extension
                    if x_new <= xs[1] then
                        return ys[1] + d[1] * (x_new - xs[1])
                    end
                    if x_new >= xs[n] then
                        return ys[n] + d[n] * (x_new - xs[n])
                    end

                    local i = find_interval(xs, x_new)
                    local h = xs[i + 1] - xs[i]
                    local t = (x_new - xs[i]) / h

                    -- Hermite basis functions
                    local t2 = t * t
                    local t3 = t2 * t
                    local h00 = 2 * t3 - 3 * t2 + 1
                    local h10 = t3 - 2 * t2 + t
                    local h01 = -2 * t3 + 3 * t2
                    local h11 = t3 - t2

                    return h00 * ys[i] + h10 * h * d[i] + h01 * ys[i + 1] + h11 * h * d[i + 1]
                end

                ----------------------------------------------------------------
                -- Akima1DInterpolator: Akima interpolation
                --
                -- Smooth interpolation that avoids overshoots.
                -- Arguments:
                --   x: array of x coordinates (must be strictly increasing)
                --   y: array of y values
                --
                -- Returns: interpolation function
                ----------------------------------------------------------------
                function interpolate.Akima1DInterpolator(x, y)
                    local n = #x
                    if n < 2 then
                        error("Akima1DInterpolator: need at least 2 data points")
                    end
                    if n ~= #y then
                        error("Akima1DInterpolator: x and y must have same length")
                    end

                    -- Copy arrays
                    local xs, ys = {}, {}
                    for i = 1, n do
                        xs[i] = x[i]
                        ys[i] = y[i]
                    end

                    -- Compute slopes between points
                    local m = {}
                    for i = 1, n - 1 do
                        m[i] = (ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i])
                    end

                    -- Extend slopes at boundaries
                    m[0] = 2 * m[1] - (m[2] or m[1])
                    m[-1] = 2 * m[0] - m[1]
                    m[n] = 2 * m[n - 1] - (m[n - 2] or m[n - 1])
                    m[n + 1] = 2 * m[n] - m[n - 1]

                    -- Compute Akima weights and slopes at each point
                    local d = {}
                    for i = 1, n do
                        local w1 = math.abs(m[i] - m[i - 1])
                        local w2 = math.abs(m[i - 2] - m[i - 1])

                        if w1 + w2 == 0 then
                            d[i] = (m[i - 1] + m[i]) / 2
                        else
                            d[i] = (w1 * m[i - 1] + w2 * m[i]) / (w1 + w2)
                        end
                    end

                    -- Compute spline coefficients
                    local coeffs = {}
                    for i = 1, n - 1 do
                        local h = xs[i + 1] - xs[i]
                        local a = ys[i]
                        local b = d[i]
                        local c = (3 * m[i] - 2 * d[i] - d[i + 1]) / h
                        local dd = (d[i] + d[i + 1] - 2 * m[i]) / (h * h)
                        coeffs[i] = {a, b, c, dd}
                    end

                    -- Return interpolation function
                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._eval_akima(xs, ys, coeffs, xi)
                            end
                            return result
                        end
                        return interpolate._eval_akima(xs, ys, coeffs, x_new)
                    end
                end

                function interpolate._eval_akima(xs, ys, coeffs, x_new)
                    local n = #xs

                    -- Extrapolation
                    if x_new <= xs[1] then
                        local dx = x_new - xs[1]
                        local a, b = coeffs[1][1], coeffs[1][2]
                        return a + b * dx
                    end
                    if x_new >= xs[n] then
                        local dx = x_new - xs[n - 1]
                        local a, b, c, d = coeffs[n - 1][1], coeffs[n - 1][2], coeffs[n - 1][3], coeffs[n - 1][4]
                        return a + b * dx + c * dx^2 + d * dx^3
                    end

                    local i = find_interval(xs, x_new)
                    local dx = x_new - xs[i]
                    local a, b, c, d = coeffs[i][1], coeffs[i][2], coeffs[i][3], coeffs[i][4]
                    return a + b * dx + c * dx^2 + d * dx^3
                end

                ----------------------------------------------------------------
                -- lagrange: Lagrange polynomial interpolation
                --
                -- Arguments:
                --   x: array of x coordinates
                --   y: array of y values
                --
                -- Returns: polynomial interpolation function
                ----------------------------------------------------------------
                function interpolate.lagrange(x, y)
                    local n = #x
                    if n ~= #y then
                        error("lagrange: x and y must have same length")
                    end

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._eval_lagrange(x, y, xi)
                            end
                            return result
                        end
                        return interpolate._eval_lagrange(x, y, x_new)
                    end
                end

                function interpolate._eval_lagrange(x, y, x_new)
                    local n = #x
                    local result = 0

                    for i = 1, n do
                        local term = y[i]
                        for j = 1, n do
                            if i ~= j then
                                term = term * (x_new - x[j]) / (x[i] - x[j])
                            end
                        end
                        result = result + term
                    end

                    return result
                end

                ----------------------------------------------------------------
                -- BarycentricInterpolator: Barycentric polynomial interpolation
                --
                -- More numerically stable than standard Lagrange for large n.
                -- Arguments:
                --   x: array of x coordinates
                --   y: array of y values
                --
                -- Returns: interpolation function
                ----------------------------------------------------------------
                function interpolate.BarycentricInterpolator(x, y)
                    local n = #x
                    if n ~= #y then
                        error("BarycentricInterpolator: x and y must have same length")
                    end

                    -- Copy arrays
                    local xs, ys = {}, {}
                    for i = 1, n do
                        xs[i] = x[i]
                        ys[i] = y[i]
                    end

                    -- Compute barycentric weights
                    local w = {}
                    for i = 1, n do
                        w[i] = 1
                        for j = 1, n do
                            if i ~= j then
                                w[i] = w[i] / (xs[i] - xs[j])
                            end
                        end
                    end

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._eval_barycentric(xs, ys, w, xi)
                            end
                            return result
                        end
                        return interpolate._eval_barycentric(xs, ys, w, x_new)
                    end
                end

                function interpolate._eval_barycentric(xs, ys, w, x_new)
                    local n = #xs

                    -- Check for exact match
                    for i = 1, n do
                        if x_new == xs[i] then
                            return ys[i]
                        end
                    end

                    local num = 0
                    local den = 0
                    for i = 1, n do
                        local term = w[i] / (x_new - xs[i])
                        num = num + term * ys[i]
                        den = den + term
                    end

                    return num / den
                end

                -- Store the module
                luaswift.interpolate = interpolate

                -- Also update math.interpolate if math table exists
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
}
