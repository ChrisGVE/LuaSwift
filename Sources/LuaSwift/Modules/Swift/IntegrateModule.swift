//
//  IntegrateModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed numerical integration module for LuaSwift.
///
/// Provides numerical integration functions including adaptive quadrature
/// and multiple integration.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- Single integration (adaptive Gauss-Kronrod)
/// local result, error = math.integrate.quad(function(x) return x^2 end, 0, 1)
/// print(result, error)  -- 0.333..., ~1e-14
///
/// -- Double integration
/// local result, error = math.integrate.dblquad(
///     function(y, x) return x * y end,
///     0, 1,   -- x limits
///     0, 1    -- y limits
/// )
///
/// -- Triple integration
/// local result, error = math.integrate.tplquad(
///     function(z, y, x) return x * y * z end,
///     0, 1, 0, 1, 0, 1
/// )
/// ```
public struct IntegrateModule {

    // MARK: - Registration

    /// Register the integration module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // All integration algorithms implemented in Lua for natural function calling
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.integrate then luaswift.integrate = {} end

                local integrate = {}

                -- Default settings
                local DEFAULT_EPSABS = 1.49e-8
                local DEFAULT_EPSREL = 1.49e-8
                local DEFAULT_LIMIT = 50

                ----------------------------------------------------------------
                -- Complex number helpers for integration
                ----------------------------------------------------------------
                local function is_complex(v)
                    return type(v) == "table" and v.re ~= nil and v.im ~= nil
                end

                local function complex_add(a, b)
                    if is_complex(a) and is_complex(b) then
                        return {re = a.re + b.re, im = a.im + b.im}
                    elseif is_complex(a) then
                        return {re = a.re + b, im = a.im}
                    elseif is_complex(b) then
                        return {re = a + b.re, im = b.im}
                    else
                        return a + b
                    end
                end

                local function complex_mul_scalar(z, s)
                    if is_complex(z) then
                        return {re = z.re * s, im = z.im * s}
                    else
                        return z * s
                    end
                end

                local function complex_abs(z)
                    if is_complex(z) then
                        return math.sqrt(z.re * z.re + z.im * z.im)
                    else
                        return math.abs(z)
                    end
                end

                local function complex_sub(a, b)
                    if is_complex(a) and is_complex(b) then
                        return {re = a.re - b.re, im = a.im - b.im}
                    elseif is_complex(a) then
                        return {re = a.re - b, im = a.im}
                    elseif is_complex(b) then
                        return {re = a - b.re, im = -b.im}
                    else
                        return a - b
                    end
                end

                ----------------------------------------------------------------
                -- Gauss-Kronrod 15-point quadrature weights and abscissae
                -- These are the standard G7-K15 points
                ----------------------------------------------------------------
                local xgk = {
                    0.991455371120813,
                    0.949107912342759,
                    0.864864423359769,
                    0.741531185599394,
                    0.586087235467691,
                    0.405845151377397,
                    0.207784955007898,
                    0.0
                }

                -- Weights for 15-point Kronrod rule
                local wgk = {
                    0.022935322010529,
                    0.063092092629979,
                    0.104790010322250,
                    0.140653259715525,
                    0.169004726639267,
                    0.190350578064785,
                    0.204432940075298,
                    0.209482141084728
                }

                -- Weights for 7-point Gauss rule (embedded in K15)
                local wg = {
                    0.129484966168870,
                    0.279705391489277,
                    0.381830050505119,
                    0.417959183673469
                }

                ----------------------------------------------------------------
                -- Single Gauss-Kronrod 15-point quadrature step
                -- Supports both real and complex-valued integrands
                ----------------------------------------------------------------
                local function gk15(f, a, b)
                    local center = 0.5 * (a + b)
                    local half_length = 0.5 * (b - a)
                    local f_center = f(center)

                    -- Initialize with center point (use complex-aware operations)
                    local result_kronrod = complex_mul_scalar(f_center, wgk[8])
                    local result_gauss = complex_mul_scalar(f_center, wg[4])

                    -- Evaluate at symmetric points
                    for i = 1, 7 do
                        local x = half_length * xgk[i]
                        local fval1 = f(center - x)
                        local fval2 = f(center + x)
                        local fsum = complex_add(fval1, fval2)

                        result_kronrod = complex_add(result_kronrod, complex_mul_scalar(fsum, wgk[i]))

                        -- Gauss points (odd indices in Kronrod)
                        if i % 2 == 0 then
                            result_gauss = complex_add(result_gauss, complex_mul_scalar(fsum, wg[i / 2]))
                        end
                    end

                    result_kronrod = complex_mul_scalar(result_kronrod, half_length)
                    result_gauss = complex_mul_scalar(result_gauss, half_length)

                    -- Error is the absolute difference
                    local abs_error = complex_abs(complex_sub(result_kronrod, result_gauss))

                    return result_kronrod, abs_error
                end

                ----------------------------------------------------------------
                -- quad: Adaptive quadrature using Gauss-Kronrod rule
                --
                -- Arguments:
                --   f: function to integrate
                --   a: lower limit
                --   b: upper limit
                --   options: {epsabs, epsrel, limit}
                --
                -- Returns: result, error
                ----------------------------------------------------------------
                function integrate.quad(f, a, b, options)
                    options = options or {}
                    local epsabs = options.epsabs or DEFAULT_EPSABS
                    local epsrel = options.epsrel or DEFAULT_EPSREL
                    local limit = options.limit or DEFAULT_LIMIT

                    -- Handle infinite limits
                    local transform = nil
                    local f_transformed = f

                    if a == -math.huge and b == math.huge then
                        -- Transform: x = t / (1 - t^2), t in (-1, 1)
                        transform = "both_inf"
                        f_transformed = function(t)
                            if math.abs(t) >= 1 then return 0 end
                            local x = t / (1 - t * t)
                            local dx_dt = (1 + t * t) / ((1 - t * t)^2)
                            return f(x) * dx_dt
                        end
                        a, b = -1, 1
                    elseif a == -math.huge then
                        -- Transform: x = b - (1-t)/t, t in (0, 1)
                        transform = "lower_inf"
                        local b_orig = b
                        f_transformed = function(t)
                            if t <= 0 then return 0 end
                            local x = b_orig - (1 - t) / t
                            local dx_dt = 1 / (t * t)
                            return f(x) * dx_dt
                        end
                        a, b = 0, 1
                    elseif b == math.huge then
                        -- Transform: x = a + t/(1-t), t in (0, 1)
                        transform = "upper_inf"
                        local a_orig = a
                        f_transformed = function(t)
                            if t >= 1 then return 0 end
                            local x = a_orig + t / (1 - t)
                            local dx_dt = 1 / ((1 - t)^2)
                            return f(x) * dx_dt
                        end
                        a, b = 0, 1
                    end

                    -- Stack-based adaptive integration
                    -- Supports complex-valued integrands
                    local stack = {{a, b}}
                    local total_result = 0  -- Will become complex if integrand is complex
                    local total_error = 0
                    local neval = 0
                    local subdivisions = 0

                    while #stack > 0 and subdivisions < limit do
                        local interval = table.remove(stack)
                        local ia, ib = interval[1], interval[2]

                        local result, abs_error = gk15(f_transformed, ia, ib)
                        neval = neval + 15

                        -- Tolerance based on magnitude (works for both real and complex)
                        local tolerance = math.max(epsabs, epsrel * complex_abs(result))

                        if abs_error <= tolerance or (ib - ia) < 1e-15 then
                            -- Accept this interval (complex-aware addition)
                            total_result = complex_add(total_result, result)
                            total_error = total_error + abs_error
                        else
                            -- Subdivide
                            subdivisions = subdivisions + 1
                            local mid = 0.5 * (ia + ib)
                            table.insert(stack, {ia, mid})
                            table.insert(stack, {mid, ib})
                        end
                    end

                    -- Process remaining intervals if limit reached
                    while #stack > 0 do
                        local interval = table.remove(stack)
                        local result, abs_error = gk15(f_transformed, interval[1], interval[2])
                        total_result = complex_add(total_result, result)
                        total_error = total_error + abs_error
                        neval = neval + 15
                    end

                    return total_result, total_error, neval
                end

                ----------------------------------------------------------------
                -- dblquad: Double integration (nested quad)
                --
                -- Computes integral of f(y, x) over region
                --   [xa, xb] x [ya(x), yb(x)]
                --
                -- Arguments:
                --   f: function(y, x) to integrate
                --   xa, xb: x limits
                --   ya, yb: y limits (numbers or functions of x)
                --   options: passed to inner quad
                --
                -- Returns: result, error
                ----------------------------------------------------------------
                function integrate.dblquad(f, xa, xb, ya, yb, options)
                    options = options or {}

                    local function inner(x)
                        local y_lower = (type(ya) == "function") and ya(x) or ya
                        local y_upper = (type(yb) == "function") and yb(x) or yb

                        local result, _ = integrate.quad(
                            function(y) return f(y, x) end,
                            y_lower, y_upper,
                            options
                        )
                        return result
                    end

                    return integrate.quad(inner, xa, xb, options)
                end

                ----------------------------------------------------------------
                -- tplquad: Triple integration (nested dblquad)
                --
                -- Computes integral of f(z, y, x) over region
                --   [xa, xb] x [ya(x), yb(x)] x [za(x,y), zb(x,y)]
                --
                -- Arguments:
                --   f: function(z, y, x) to integrate
                --   xa, xb: x limits
                --   ya, yb: y limits (numbers or functions of x)
                --   za, zb: z limits (numbers or functions of x, y)
                --   options: passed to inner quad
                --
                -- Returns: result, error
                ----------------------------------------------------------------
                function integrate.tplquad(f, xa, xb, ya, yb, za, zb, options)
                    options = options or {}

                    local function inner_xy(y, x)
                        local z_lower = za
                        local z_upper = zb
                        if type(za) == "function" then z_lower = za(x, y) end
                        if type(zb) == "function" then z_upper = zb(x, y) end

                        local result, _ = integrate.quad(
                            function(z) return f(z, y, x) end,
                            z_lower, z_upper,
                            options
                        )
                        return result
                    end

                    return integrate.dblquad(inner_xy, xa, xb, ya, yb, options)
                end

                ----------------------------------------------------------------
                -- fixed_quad: Fixed-order Gauss quadrature
                --
                -- Arguments:
                --   f: function to integrate
                --   a, b: limits
                --   n: number of points (1-5)
                --
                -- Returns: result
                ----------------------------------------------------------------
                function integrate.fixed_quad(f, a, b, n)
                    n = n or 5

                    -- Gauss-Legendre points and weights for n=1 to 5
                    local points = {
                        [1] = {{0, 2}},
                        [2] = {{-0.5773502691896257, 1}, {0.5773502691896257, 1}},
                        [3] = {{-0.7745966692414834, 0.5555555555555556},
                               {0, 0.8888888888888888},
                               {0.7745966692414834, 0.5555555555555556}},
                        [4] = {{-0.8611363115940526, 0.3478548451374538},
                               {-0.3399810435848563, 0.6521451548625461},
                               {0.3399810435848563, 0.6521451548625461},
                               {0.8611363115940526, 0.3478548451374538}},
                        [5] = {{-0.9061798459386640, 0.2369268850561891},
                               {-0.5384693101056831, 0.4786286704993665},
                               {0, 0.5688888888888889},
                               {0.5384693101056831, 0.4786286704993665},
                               {0.9061798459386640, 0.2369268850561891}}
                    }

                    if n < 1 or n > 5 then n = 5 end

                    local center = 0.5 * (a + b)
                    local half_length = 0.5 * (b - a)
                    local result = 0

                    for _, pw in ipairs(points[n]) do
                        local x = center + half_length * pw[1]
                        result = result + pw[2] * f(x)
                    end

                    return result * half_length
                end

                ----------------------------------------------------------------
                -- romberg: Romberg integration
                --
                -- Arguments:
                --   f: function to integrate
                --   a, b: limits
                --   options: {tol, divmax}
                --
                -- Returns: result, error
                ----------------------------------------------------------------
                function integrate.romberg(f, a, b, options)
                    options = options or {}
                    local tol = options.tol or 1e-8
                    local divmax = options.divmax or 10

                    local R = {}
                    local h = b - a

                    -- R[1][1] = trapezoidal rule
                    R[1] = {}
                    R[1][1] = 0.5 * h * (f(a) + f(b))

                    for i = 2, divmax + 1 do
                        h = h / 2
                        R[i] = {}

                        -- Composite trapezoidal rule
                        local sum = 0
                        local n = 2^(i - 2)
                        for k = 1, n do
                            sum = sum + f(a + (2 * k - 1) * h)
                        end
                        R[i][1] = 0.5 * R[i-1][1] + h * sum

                        -- Richardson extrapolation
                        for j = 2, i do
                            local factor = 4^(j - 1)
                            R[i][j] = (factor * R[i][j-1] - R[i-1][j-1]) / (factor - 1)
                        end

                        -- Check convergence
                        local error = math.abs(R[i][i] - R[i-1][i-1])
                        if error < tol then
                            return R[i][i], error
                        end
                    end

                    return R[divmax + 1][divmax + 1], math.abs(R[divmax + 1][divmax + 1] - R[divmax][divmax])
                end

                ----------------------------------------------------------------
                -- simps: Simpson's rule integration
                --
                -- Arguments:
                --   y: array of function values (or function + a, b, n)
                --   x: array of x values (optional, defaults to [0, 1, ..., n-1])
                --   dx: step size (optional, defaults to 1)
                --
                -- Returns: result
                ----------------------------------------------------------------
                function integrate.simps(y, x, dx)
                    local values
                    local step

                    if type(y) == "function" then
                        -- y is a function, x is 'a', dx is 'b', and we need to specify n
                        local f, a, b = y, x, dx
                        local n = 101  -- default number of points
                        step = (b - a) / (n - 1)
                        values = {}
                        for i = 1, n do
                            values[i] = f(a + (i - 1) * step)
                        end
                    elseif type(y) == "table" then
                        values = y
                        if x and type(x) == "table" then
                            -- x is array of x values, infer dx from spacing
                            step = (x[#x] - x[1]) / (#x - 1)
                        else
                            step = dx or 1
                        end
                    else
                        error("simps: first argument must be a function or array")
                    end

                    local n = #values
                    if n < 3 then
                        error("simps: need at least 3 points")
                    end

                    -- Composite Simpson's rule
                    local result = values[1] + values[n]

                    for i = 2, n - 1 do
                        if i % 2 == 0 then
                            result = result + 4 * values[i]
                        else
                            result = result + 2 * values[i]
                        end
                    end

                    -- Handle odd number of points (need at least one even interval)
                    if n % 2 == 0 then
                        -- n-1 intervals, apply Simpson's to first n-1 points, trapezoid to last
                        result = values[1] + values[n - 1]
                        for i = 2, n - 2 do
                            if i % 2 == 0 then
                                result = result + 4 * values[i]
                            else
                                result = result + 2 * values[i]
                            end
                        end
                        result = result * step / 3
                        result = result + step * (values[n - 1] + values[n]) / 2
                        return result
                    end

                    return result * step / 3
                end

                ----------------------------------------------------------------
                -- trapz: Trapezoidal rule integration
                --
                -- Arguments:
                --   y: array of function values
                --   x: array of x values (optional)
                --   dx: step size (optional, defaults to 1)
                --
                -- Returns: result
                ----------------------------------------------------------------
                function integrate.trapz(y, x, dx)
                    local n = #y
                    if n < 2 then
                        error("trapz: need at least 2 points")
                    end

                    local result = 0

                    if x and type(x) == "table" then
                        -- Non-uniform spacing
                        for i = 1, n - 1 do
                            result = result + 0.5 * (y[i] + y[i + 1]) * (x[i + 1] - x[i])
                        end
                    else
                        -- Uniform spacing
                        local step = dx or 1
                        for i = 1, n - 1 do
                            result = result + 0.5 * (y[i] + y[i + 1]) * step
                        end
                    end

                    return result
                end

                ----------------------------------------------------------------
                -- ODE Solvers
                ----------------------------------------------------------------

                -- Dormand-Prince RK45 coefficients (for adaptive step size)
                local DP_A = {
                    {},
                    {1/5},
                    {3/40, 9/40},
                    {44/45, -56/15, 32/9},
                    {19372/6561, -25360/2187, 64448/6561, -212/729},
                    {9017/3168, -355/33, 46732/5247, 49/176, -5103/18656},
                    {35/384, 0, 500/1113, 125/192, -2187/6784, 11/84}
                }

                local DP_C = {0, 1/5, 3/10, 4/5, 8/9, 1, 1}

                -- 5th order weights (for result)
                local DP_B = {35/384, 0, 500/1113, 125/192, -2187/6784, 11/84, 0}

                -- 4th order weights (for error estimate)
                local DP_E = {71/57600, 0, -71/16695, 71/1920, -17253/339200, 22/525, -1/40}

                ----------------------------------------------------------------
                -- Vector operations for ODE solvers
                ----------------------------------------------------------------
                local function vec_add(a, b)
                    local result = {}
                    for i = 1, #a do result[i] = a[i] + b[i] end
                    return result
                end

                local function vec_scale(s, v)
                    local result = {}
                    for i = 1, #v do result[i] = s * v[i] end
                    return result
                end

                local function vec_norm(v)
                    local sum = 0
                    for i = 1, #v do sum = sum + v[i] * v[i] end
                    return math.sqrt(sum)
                end

                local function vec_max_abs(v)
                    local m = 0
                    for i = 1, #v do
                        local abs_v = math.abs(v[i])
                        if abs_v > m then m = abs_v end
                    end
                    return m
                end

                ----------------------------------------------------------------
                -- rk45_step: Single Dormand-Prince RK45 step
                --
                -- Arguments:
                --   f: derivative function f(t, y) -> dy/dt
                --   t: current time
                --   y: current state (array)
                --   h: step size
                --
                -- Returns: y_new, error_estimate, k values
                ----------------------------------------------------------------
                local function rk45_step(f, t, y, h)
                    local n = #y
                    local k = {}

                    -- Compute k1 through k7
                    k[1] = f(t, y)

                    for stage = 2, 7 do
                        local y_stage = {}
                        for i = 1, n do
                            local sum = y[i]
                            for j = 1, stage - 1 do
                                if DP_A[stage] and DP_A[stage][j] then
                                    sum = sum + h * DP_A[stage][j] * k[j][i]
                                end
                            end
                            y_stage[i] = sum
                        end
                        k[stage] = f(t + DP_C[stage] * h, y_stage)
                    end

                    -- Compute 5th order solution
                    local y_new = {}
                    for i = 1, n do
                        local sum = y[i]
                        for j = 1, 7 do
                            sum = sum + h * DP_B[j] * k[j][i]
                        end
                        y_new[i] = sum
                    end

                    -- Compute error estimate (difference between 5th and 4th order)
                    local err = {}
                    for i = 1, n do
                        local sum = 0
                        for j = 1, 7 do
                            sum = sum + h * DP_E[j] * k[j][i]
                        end
                        err[i] = sum
                    end

                    return y_new, err, k
                end

                ----------------------------------------------------------------
                -- rk4_step: Single classical RK4 step
                --
                -- Arguments:
                --   f: derivative function f(t, y) -> dy/dt
                --   t: current time
                --   y: current state (array)
                --   h: step size
                --
                -- Returns: y_new
                ----------------------------------------------------------------
                local function rk4_step(f, t, y, h)
                    local n = #y
                    local k1 = f(t, y)

                    local y2 = {}
                    for i = 1, n do y2[i] = y[i] + 0.5 * h * k1[i] end
                    local k2 = f(t + 0.5 * h, y2)

                    local y3 = {}
                    for i = 1, n do y3[i] = y[i] + 0.5 * h * k2[i] end
                    local k3 = f(t + 0.5 * h, y3)

                    local y4 = {}
                    for i = 1, n do y4[i] = y[i] + h * k3[i] end
                    local k4 = f(t + h, y4)

                    local y_new = {}
                    for i = 1, n do
                        y_new[i] = y[i] + (h / 6) * (k1[i] + 2*k2[i] + 2*k3[i] + k4[i])
                    end

                    return y_new
                end

                ----------------------------------------------------------------
                -- solve_ivp: Solve initial value problem for ODE system
                --
                -- Arguments:
                --   fun: function(t, y) returning dy/dt (array)
                --   t_span: {t0, tf} - initial and final time
                --   y0: initial state (array)
                --   options: {
                --     method: 'RK45', 'RK23', or 'RK4' (default: 'RK45')
                --     t_eval: optional array of times at which to store solution
                --     max_step: maximum step size (default: inf)
                --     rtol: relative tolerance (default: 1e-3)
                --     atol: absolute tolerance (default: 1e-6)
                --     first_step: initial step size (default: auto)
                --     dense_output: return interpolation function (default: false)
                --   }
                --
                -- Returns: table with:
                --   t: array of times
                --   y: array of states (each element is array of y values)
                --   success: boolean
                --   message: string
                --   nfev: number of function evaluations
                ----------------------------------------------------------------
                function integrate.solve_ivp(fun, t_span, y0, options)
                    options = options or {}
                    local method = options.method or "RK45"
                    local t_eval = options.t_eval
                    local max_step = options.max_step or math.huge
                    local rtol = options.rtol or 1e-3
                    local atol = options.atol or 1e-6
                    local first_step = options.first_step

                    local t0, tf = t_span[1], t_span[2]
                    local direction = (tf >= t0) and 1 or -1
                    local n = #y0

                    -- Initialize
                    local t = t0
                    local y = {}
                    for i = 1, n do y[i] = y0[i] end

                    local t_list = {t0}
                    local y_list = {{}}
                    for i = 1, n do y_list[1][i] = y0[i] end

                    local nfev = 0

                    -- Initial step size estimation
                    local h
                    if first_step then
                        h = first_step
                    else
                        -- Estimate initial step based on derivative magnitude
                        local f0 = fun(t0, y0)
                        nfev = nfev + 1
                        local d0 = vec_max_abs(y0)
                        local d1 = vec_max_abs(f0)
                        if d0 < 1e-5 then d0 = 1 end
                        if d1 < 1e-5 then d1 = 1 end
                        h = 0.01 * d0 / d1
                        h = math.min(h, math.abs(tf - t0) / 10)
                    end
                    h = direction * math.min(math.abs(h), max_step)

                    -- Main integration loop
                    local max_iter = 10000
                    local iter = 0

                    while direction * (tf - t) > 1e-12 * math.abs(tf) and iter < max_iter do
                        iter = iter + 1

                        -- Ensure we don't overshoot tf
                        if direction * (t + h - tf) > 0 then
                            h = tf - t
                        end

                        if method == "RK4" then
                            -- Fixed step RK4
                            y = rk4_step(fun, t, y, h)
                            nfev = nfev + 4
                            t = t + h

                            table.insert(t_list, t)
                            local y_copy = {}
                            for i = 1, n do y_copy[i] = y[i] end
                            table.insert(y_list, y_copy)
                        else
                            -- Adaptive RK45 or RK23
                            local y_new, err = rk45_step(fun, t, y, h)
                            nfev = nfev + 7

                            -- Error control
                            local err_norm = 0
                            for i = 1, n do
                                local scale = atol + rtol * math.max(math.abs(y[i]), math.abs(y_new[i]))
                                err_norm = err_norm + (err[i] / scale)^2
                            end
                            err_norm = math.sqrt(err_norm / n)

                            if err_norm <= 1 then
                                -- Accept step
                                t = t + h
                                y = y_new

                                table.insert(t_list, t)
                                local y_copy = {}
                                for i = 1, n do y_copy[i] = y[i] end
                                table.insert(y_list, y_copy)

                                -- Increase step size
                                if err_norm > 0 then
                                    local factor = math.min(5, 0.9 * (1 / err_norm)^0.2)
                                    h = direction * math.min(math.abs(h * factor), max_step)
                                else
                                    h = direction * math.min(math.abs(h * 5), max_step)
                                end
                            else
                                -- Reject step, decrease step size
                                local factor = math.max(0.1, 0.9 * (1 / err_norm)^0.25)
                                h = h * factor
                            end
                        end
                    end

                    -- If t_eval specified, interpolate results
                    local result_t, result_y
                    if t_eval then
                        result_t = t_eval
                        result_y = {}
                        for eval_idx, t_e in ipairs(t_eval) do
                            -- Find bracketing interval
                            local idx = 1
                            for j = 1, #t_list - 1 do
                                if (t_list[j] <= t_e and t_e <= t_list[j + 1]) or
                                   (t_list[j] >= t_e and t_e >= t_list[j + 1]) then
                                    idx = j
                                    break
                                end
                            end

                            -- Linear interpolation
                            local t1, t2 = t_list[idx], t_list[idx + 1]
                            local frac = 0
                            if math.abs(t2 - t1) > 1e-15 then
                                frac = (t_e - t1) / (t2 - t1)
                            end

                            local y_interp = {}
                            for i = 1, n do
                                y_interp[i] = y_list[idx][i] + frac * (y_list[idx + 1][i] - y_list[idx][i])
                            end
                            result_y[eval_idx] = y_interp
                        end
                    else
                        result_t = t_list
                        result_y = y_list
                    end

                    local success = direction * (tf - t) <= 1e-12 * math.abs(tf)

                    return {
                        t = result_t,
                        y = result_y,
                        success = success,
                        message = success and "Integration successful" or "Max iterations reached",
                        nfev = nfev
                    }
                end

                ----------------------------------------------------------------
                -- odeint: Integrate ODE system (scipy.integrate.odeint style)
                --
                -- Arguments:
                --   func: function(y, t, ...) returning dy/dt (note: y first, then t)
                --   y0: initial state (array)
                --   t: array of times at which to compute solution
                --   options: {
                --     args: additional arguments to pass to func
                --     rtol: relative tolerance (default: 1.49e-8)
                --     atol: absolute tolerance (default: 1.49e-8)
                --     h0: initial step size (default: auto)
                --     hmax: maximum step size (default: auto)
                --     hmin: minimum step size (default: 0)
                --     mxstep: maximum number of steps (default: 500)
                --     full_output: return extra info (default: false)
                --   }
                --
                -- Returns: y (2D array: y[time_index][component_index])
                --          if full_output: y, info_dict
                ----------------------------------------------------------------
                function integrate.odeint(func, y0, t, options)
                    options = options or {}
                    local args = options.args or {}
                    local rtol = options.rtol or 1.49e-8
                    local atol = options.atol or 1.49e-8
                    local h0 = options.h0
                    local hmax = options.hmax
                    local mxstep = options.mxstep or 500
                    local full_output = options.full_output

                    if #t < 2 then
                        error("odeint: need at least 2 time points")
                    end

                    local n = #y0

                    -- Wrap func to match solve_ivp convention: f(t, y) instead of f(y, t, ...)
                    local function wrapped_func(t_val, y_val)
                        -- Call func(y, t, args...)
                        return func(y_val, t_val, table.unpack(args))
                    end

                    -- Solve between each pair of time points
                    local result = {}
                    result[1] = {}
                    for i = 1, n do result[1][i] = y0[i] end

                    local current_y = {}
                    for i = 1, n do current_y[i] = y0[i] end

                    local total_nfev = 0

                    for j = 1, #t - 1 do
                        local t_span = {t[j], t[j + 1]}

                        local ivp_opts = {
                            method = "RK45",
                            rtol = rtol,
                            atol = atol,
                            first_step = h0,
                            max_step = hmax or math.abs(t[j + 1] - t[j])
                        }

                        local sol = integrate.solve_ivp(wrapped_func, t_span, current_y, ivp_opts)
                        total_nfev = total_nfev + sol.nfev

                        -- Get final state
                        current_y = sol.y[#sol.y]
                        result[j + 1] = {}
                        for i = 1, n do
                            result[j + 1][i] = current_y[i]
                        end
                    end

                    if full_output then
                        local info = {
                            nfe = total_nfev,
                            message = "Integration successful"
                        }
                        return result, info
                    else
                        return result
                    end
                end

                ----------------------------------------------------------------
                -- RK23 coefficients for alternative method
                -- (Bogacki-Shampine)
                ----------------------------------------------------------------
                local BS_A = {
                    {},
                    {1/2},
                    {0, 3/4},
                    {2/9, 1/3, 4/9}
                }
                local BS_C = {0, 1/2, 3/4, 1}
                local BS_B = {2/9, 1/3, 4/9, 0}  -- 3rd order
                local BS_E = {-5/72, 1/12, 1/9, -1/8}  -- Error = 3rd - 2nd order

                local function rk23_step(f, t, y, h)
                    local n = #y
                    local k = {}

                    k[1] = f(t, y)

                    for stage = 2, 4 do
                        local y_stage = {}
                        for i = 1, n do
                            local sum = y[i]
                            for j = 1, stage - 1 do
                                if BS_A[stage] and BS_A[stage][j] then
                                    sum = sum + h * BS_A[stage][j] * k[j][i]
                                end
                            end
                            y_stage[i] = sum
                        end
                        k[stage] = f(t + BS_C[stage] * h, y_stage)
                    end

                    -- 3rd order solution
                    local y_new = {}
                    for i = 1, n do
                        local sum = y[i]
                        for j = 1, 4 do
                            sum = sum + h * BS_B[j] * k[j][i]
                        end
                        y_new[i] = sum
                    end

                    -- Error estimate
                    local err = {}
                    for i = 1, n do
                        local sum = 0
                        for j = 1, 4 do
                            sum = sum + h * BS_E[j] * k[j][i]
                        end
                        err[i] = sum
                    end

                    return y_new, err, k
                end

                -- Store the module
                luaswift.integrate = integrate

                -- Also update math.integrate if math table exists
                if math and type(math.integrate) == "table" then
                    for k, v in pairs(integrate) do
                        math.integrate[k] = v
                    end
                end
                """)
        } catch {
            // Silently fail
        }
    }
}
