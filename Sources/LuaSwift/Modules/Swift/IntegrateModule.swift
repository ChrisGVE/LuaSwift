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
                ----------------------------------------------------------------
                local function gk15(f, a, b)
                    local center = 0.5 * (a + b)
                    local half_length = 0.5 * (b - a)
                    local f_center = f(center)

                    -- Initialize with center point
                    local result_kronrod = f_center * wgk[8]
                    local result_gauss = f_center * wg[4]

                    -- Evaluate at symmetric points
                    for i = 1, 7 do
                        local x = half_length * xgk[i]
                        local fval1 = f(center - x)
                        local fval2 = f(center + x)
                        local fsum = fval1 + fval2

                        result_kronrod = result_kronrod + fsum * wgk[i]

                        -- Gauss points (odd indices in Kronrod)
                        if i % 2 == 0 then
                            result_gauss = result_gauss + fsum * wg[i / 2]
                        end
                    end

                    result_kronrod = result_kronrod * half_length
                    result_gauss = result_gauss * half_length

                    local abs_error = math.abs(result_kronrod - result_gauss)

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
                    local stack = {{a, b}}
                    local total_result = 0
                    local total_error = 0
                    local neval = 0
                    local subdivisions = 0

                    while #stack > 0 and subdivisions < limit do
                        local interval = table.remove(stack)
                        local ia, ib = interval[1], interval[2]

                        local result, abs_error = gk15(f_transformed, ia, ib)
                        neval = neval + 15

                        local tolerance = math.max(epsabs, epsrel * math.abs(result))

                        if abs_error <= tolerance or (ib - ia) < 1e-15 then
                            -- Accept this interval
                            total_result = total_result + result
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
                        total_result = total_result + result
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
