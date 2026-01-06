//
//  OptimizeModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed optimization module for LuaSwift.
///
/// Provides numerical optimization functions including scalar minimization,
/// root finding, and multivariate optimization. Since these algorithms need
/// to call user-provided Lua functions, the algorithms are implemented in Lua
/// for natural function calling.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- Scalar minimization (Golden section / Brent's method)
/// local result = math.optimize.minimize_scalar(function(x) return (x-2)^2 end, {bracket={0,4}})
/// print(result.x, result.fun, result.success)
///
/// -- Root finding (scalar) - Bisection, Newton, Secant methods
/// local result = math.optimize.root_scalar(function(x) return x^2 - 4 end, {bracket={0,5}})
/// print(result.root, result.converged)
///
/// -- Multivariate minimization (Nelder-Mead)
/// local result = math.optimize.minimize(
///     function(x) return (x[1]-1)^2 + (x[2]-2)^2 end,
///     {0, 0}
/// )
/// print(result.x[1], result.x[2], result.fun)
///
/// -- Root finding for systems (Newton's method)
/// local result = math.optimize.root(
///     function(x) return {x[1]^2 + x[2] - 1, x[1] - x[2]^2 + 1} end,
///     {0.5, 0.5}
/// )
/// print(result.x[1], result.x[2])
/// ```
public struct OptimizeModule {

    // MARK: - Registration

    /// Register the optimization module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // All optimization algorithms implemented in Lua for natural function calling
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.optimize then luaswift.optimize = {} end

                local optimize = {}

                -- Default tolerances
                local DEFAULT_XTOL = 1e-8
                local DEFAULT_FTOL = 1e-8
                local DEFAULT_MAXITER = 500

                -- Golden ratio for golden section search
                local PHI = (1 + math.sqrt(5)) / 2
                local RESPHI = 2 - PHI  -- ≈ 0.382

                ----------------------------------------------------------------
                -- minimize_scalar: Scalar function minimization
                -- Methods: "golden" (golden section), "brent" (Brent's method)
                ----------------------------------------------------------------
                function optimize.minimize_scalar(func, options)
                    options = options or {}
                    local method = (options.method or "brent"):lower()
                    local bracket = options.bracket
                    local bounds = options.bounds
                    local xtol = options.xtol or DEFAULT_XTOL
                    local maxiter = options.maxiter or DEFAULT_MAXITER

                    -- Default bracket if not provided
                    if not bracket and not bounds then
                        bracket = {-10, 10}
                    end

                    local a, b
                    if bracket then
                        a, b = bracket[1], bracket[2]
                        if #bracket >= 3 then
                            -- 3-point bracket: (a, mid, b) where f(mid) < f(a) and f(mid) < f(b)
                            a, b = bracket[1], bracket[3]
                        end
                    elseif bounds then
                        a, b = bounds[1], bounds[2]
                    end

                    local nfev = 0
                    local nit = 0

                    local function f(x)
                        nfev = nfev + 1
                        return func(x)
                    end

                    local x_min, f_min, success, message

                    if method == "golden" then
                        -- Golden section search
                        local c = b - (b - a) / PHI
                        local d = a + (b - a) / PHI
                        local fc, fd = f(c), f(d)

                        while math.abs(b - a) > xtol and nit < maxiter do
                            nit = nit + 1
                            if fc < fd then
                                b = d
                                d = c
                                fd = fc
                                c = b - (b - a) / PHI
                                fc = f(c)
                            else
                                a = c
                                c = d
                                fc = fd
                                d = a + (b - a) / PHI
                                fd = f(d)
                            end
                        end

                        x_min = (a + b) / 2
                        f_min = f(x_min)
                        success = math.abs(b - a) <= xtol
                        message = success and "Optimization converged" or "Maximum iterations reached"

                    elseif method == "brent" then
                        -- Brent's method (parabolic interpolation with golden section fallback)
                        local CGOLD = 0.3819660  -- Golden ratio complement
                        local ZEPS = 1e-10

                        local x = a + CGOLD * (b - a)  -- Initial guess
                        local w, v = x, x
                        local fx = f(x)
                        local fw, fv = fx, fx
                        local e = 0  -- Distance moved on step before last

                        for iter = 1, maxiter do
                            nit = iter
                            local xm = 0.5 * (a + b)
                            local tol1 = xtol * math.abs(x) + ZEPS
                            local tol2 = 2 * tol1

                            -- Check convergence
                            if math.abs(x - xm) <= (tol2 - 0.5 * (b - a)) then
                                x_min = x
                                f_min = fx
                                success = true
                                message = "Optimization converged"
                                break
                            end

                            local d_step
                            if math.abs(e) > tol1 then
                                -- Try parabolic interpolation
                                local r = (x - w) * (fx - fv)
                                local q = (x - v) * (fx - fw)
                                local p = (x - v) * q - (x - w) * r
                                q = 2 * (q - r)
                                if q > 0 then p = -p else q = -q end

                                local etemp = e
                                e = d_step or 0

                                -- Check if parabolic step is acceptable
                                if math.abs(p) < math.abs(0.5 * q * etemp) and
                                   p > q * (a - x) and p < q * (b - x) then
                                    d_step = p / q
                                    local u = x + d_step
                                    if (u - a) < tol2 or (b - u) < tol2 then
                                        d_step = (xm >= x) and tol1 or -tol1
                                    end
                                else
                                    -- Golden section step
                                    e = (x >= xm) and (a - x) or (b - x)
                                    d_step = CGOLD * e
                                end
                            else
                                -- Golden section step
                                e = (x >= xm) and (a - x) or (b - x)
                                d_step = CGOLD * e
                            end

                            -- Ensure step is at least tol1
                            local u
                            if math.abs(d_step) >= tol1 then
                                u = x + d_step
                            else
                                u = x + ((d_step >= 0) and tol1 or -tol1)
                            end

                            local fu = f(u)

                            -- Update interval
                            if fu <= fx then
                                if u >= x then a = x else b = x end
                                v, w, x = w, x, u
                                fv, fw, fx = fw, fx, fu
                            else
                                if u < x then a = u else b = u end
                                if fu <= fw or w == x then
                                    v, w = w, u
                                    fv, fw = fw, fu
                                elseif fu <= fv or v == x or v == w then
                                    v = u
                                    fv = fu
                                end
                            end
                        end

                        if not success then
                            x_min = x
                            f_min = fx
                            success = false
                            message = "Maximum iterations reached"
                        end
                    else
                        return {
                            x = 0, fun = 0, success = false,
                            message = "Unknown method: " .. method,
                            nfev = nfev, nit = nit
                        }
                    end

                    return {
                        x = x_min,
                        fun = f_min,
                        success = success,
                        message = message,
                        nfev = nfev,
                        nit = nit
                    }
                end

                ----------------------------------------------------------------
                -- root_scalar: Scalar root finding
                -- Methods: "bisect", "newton", "secant", "brentq"
                ----------------------------------------------------------------
                function optimize.root_scalar(func, options)
                    options = options or {}
                    local method = (options.method or "brentq"):lower()
                    local bracket = options.bracket
                    local x0 = options.x0
                    local x1 = options.x1
                    local fprime = options.fprime  -- Derivative for Newton's method
                    local xtol = options.xtol or DEFAULT_XTOL
                    local ftol = options.ftol or DEFAULT_FTOL
                    local maxiter = options.maxiter or DEFAULT_MAXITER

                    local nfev = 0
                    local nit = 0

                    local function f(x)
                        nfev = nfev + 1
                        return func(x)
                    end

                    local root, converged, message

                    if method == "bisect" then
                        -- Bisection method
                        if not bracket or #bracket < 2 then
                            return {
                                root = nil, converged = false,
                                message = "Bisection requires bracket=[a,b]",
                                iterations = 0, function_calls = 0
                            }
                        end

                        local a, b = bracket[1], bracket[2]
                        local fa, fb = f(a), f(b)

                        if fa * fb > 0 then
                            return {
                                root = nil, converged = false,
                                message = "f(a) and f(b) must have opposite signs",
                                iterations = 0, function_calls = nfev
                            }
                        end

                        for iter = 1, maxiter do
                            nit = iter
                            local c = (a + b) / 2
                            local fc = f(c)

                            if math.abs(fc) < ftol or (b - a) / 2 < xtol then
                                root = c
                                converged = true
                                message = "Root found"
                                break
                            end

                            if fa * fc < 0 then
                                b, fb = c, fc
                            else
                                a, fa = c, fc
                            end
                        end

                        if not converged then
                            root = (a + b) / 2
                            converged = false
                            message = "Maximum iterations reached"
                        end

                    elseif method == "newton" then
                        -- Newton-Raphson method
                        if not x0 then
                            return {
                                root = nil, converged = false,
                                message = "Newton's method requires x0 (initial guess)",
                                iterations = 0, function_calls = 0
                            }
                        end
                        if not fprime then
                            -- Use numerical derivative
                            local h = 1e-8
                            fprime = function(x)
                                return (f(x + h) - f(x - h)) / (2 * h)
                            end
                        end

                        local x = x0
                        for iter = 1, maxiter do
                            nit = iter
                            local fx = f(x)
                            if math.abs(fx) < ftol then
                                root = x
                                converged = true
                                message = "Root found"
                                break
                            end

                            local dfx = fprime(x)
                            if math.abs(dfx) < 1e-15 then
                                root = x
                                converged = false
                                message = "Derivative too small"
                                break
                            end

                            local x_new = x - fx / dfx
                            if math.abs(x_new - x) < xtol then
                                root = x_new
                                converged = true
                                message = "Root found"
                                break
                            end
                            x = x_new
                        end

                        if not converged and not root then
                            root = x
                            converged = false
                            message = "Maximum iterations reached"
                        end

                    elseif method == "secant" then
                        -- Secant method
                        if not x0 then x0 = 0 end
                        if not x1 then x1 = x0 + 0.1 end

                        local x_prev, x_curr = x0, x1
                        local f_prev = f(x_prev)

                        for iter = 1, maxiter do
                            nit = iter
                            local f_curr = f(x_curr)

                            if math.abs(f_curr) < ftol then
                                root = x_curr
                                converged = true
                                message = "Root found"
                                break
                            end

                            if math.abs(f_curr - f_prev) < 1e-15 then
                                root = x_curr
                                converged = false
                                message = "Division by zero in secant"
                                break
                            end

                            local x_new = x_curr - f_curr * (x_curr - x_prev) / (f_curr - f_prev)

                            if math.abs(x_new - x_curr) < xtol then
                                root = x_new
                                converged = true
                                message = "Root found"
                                break
                            end

                            x_prev, f_prev = x_curr, f_curr
                            x_curr = x_new
                        end

                        if not converged and not root then
                            root = x_curr
                            converged = false
                            message = "Maximum iterations reached"
                        end

                    elseif method == "brentq" then
                        -- Brent's method for root finding
                        if not bracket or #bracket < 2 then
                            return {
                                root = nil, converged = false,
                                message = "Brent's method requires bracket=[a,b]",
                                iterations = 0, function_calls = 0
                            }
                        end

                        local a, b = bracket[1], bracket[2]
                        local fa, fb = f(a), f(b)

                        if fa * fb > 0 then
                            return {
                                root = nil, converged = false,
                                message = "f(a) and f(b) must have opposite signs",
                                iterations = 0, function_calls = nfev
                            }
                        end

                        -- Ensure |f(a)| >= |f(b)|
                        if math.abs(fa) < math.abs(fb) then
                            a, b = b, a
                            fa, fb = fb, fa
                        end

                        local c, fc = a, fa
                        local mflag = true
                        local d = 0

                        for iter = 1, maxiter do
                            nit = iter

                            if math.abs(fb) < ftol or math.abs(b - a) < xtol then
                                root = b
                                converged = true
                                message = "Root found"
                                break
                            end

                            local s
                            if fa ~= fc and fb ~= fc then
                                -- Inverse quadratic interpolation
                                s = a * fb * fc / ((fa - fb) * (fa - fc)) +
                                    b * fa * fc / ((fb - fa) * (fb - fc)) +
                                    c * fa * fb / ((fc - fa) * (fc - fb))
                            else
                                -- Secant method
                                s = b - fb * (b - a) / (fb - fa)
                            end

                            -- Conditions for bisection
                            local cond1 = s < (3 * a + b) / 4 or s > b
                            local cond2 = mflag and math.abs(s - b) >= math.abs(b - c) / 2
                            local cond3 = not mflag and math.abs(s - b) >= math.abs(c - d) / 2
                            local cond4 = mflag and math.abs(b - c) < xtol
                            local cond5 = not mflag and math.abs(c - d) < xtol

                            if cond1 or cond2 or cond3 or cond4 or cond5 then
                                s = (a + b) / 2
                                mflag = true
                            else
                                mflag = false
                            end

                            local fs = f(s)
                            d = c
                            c, fc = b, fb

                            if fa * fs < 0 then
                                b, fb = s, fs
                            else
                                a, fa = s, fs
                            end

                            -- Ensure |f(a)| >= |f(b)|
                            if math.abs(fa) < math.abs(fb) then
                                a, b = b, a
                                fa, fb = fb, fa
                            end
                        end

                        if not converged then
                            root = b
                            converged = false
                            message = "Maximum iterations reached"
                        end
                    else
                        return {
                            root = nil, converged = false,
                            message = "Unknown method: " .. method,
                            iterations = 0, function_calls = 0
                        }
                    end

                    return {
                        root = root,
                        converged = converged,
                        message = message,
                        iterations = nit,
                        function_calls = nfev
                    }
                end

                ----------------------------------------------------------------
                -- minimize: Multivariate minimization
                -- Method: "nelder-mead" (Nelder-Mead simplex algorithm)
                ----------------------------------------------------------------
                function optimize.minimize(func, x0, options)
                    options = options or {}
                    local method = (options.method or "nelder-mead"):lower()
                    local xtol = options.xtol or DEFAULT_XTOL
                    local ftol = options.ftol or DEFAULT_FTOL
                    local maxiter = options.maxiter or DEFAULT_MAXITER * #x0

                    local nfev = 0
                    local nit = 0

                    local function f(x)
                        nfev = nfev + 1
                        return func(x)
                    end

                    if method ~= "nelder-mead" then
                        return {
                            x = x0, fun = 0, success = false,
                            message = "Only nelder-mead method is currently supported",
                            nfev = 0, nit = 0
                        }
                    end

                    -- Nelder-Mead simplex algorithm
                    local n = #x0
                    local alpha = 1.0   -- Reflection coefficient
                    local gamma = 2.0   -- Expansion coefficient
                    local rho = 0.5     -- Contraction coefficient
                    local sigma = 0.5   -- Shrink coefficient

                    -- Initialize simplex with n+1 vertices
                    local simplex = {}
                    local fvals = {}

                    -- First vertex is initial guess
                    simplex[1] = {}
                    for i = 1, n do simplex[1][i] = x0[i] end
                    fvals[1] = f(simplex[1])

                    -- Other vertices: perturb each dimension
                    for i = 1, n do
                        simplex[i + 1] = {}
                        for j = 1, n do
                            if j == i then
                                local step = (x0[j] ~= 0) and (x0[j] * 0.05) or 0.00025
                                simplex[i + 1][j] = x0[j] + step
                            else
                                simplex[i + 1][j] = x0[j]
                            end
                        end
                        fvals[i + 1] = f(simplex[i + 1])
                    end

                    -- Helper functions
                    local function centroid(exclude_idx)
                        local c = {}
                        for j = 1, n do c[j] = 0 end
                        local count = 0
                        for i = 1, n + 1 do
                            if i ~= exclude_idx then
                                count = count + 1
                                for j = 1, n do
                                    c[j] = c[j] + simplex[i][j]
                                end
                            end
                        end
                        for j = 1, n do c[j] = c[j] / count end
                        return c
                    end

                    local function add_scaled(a, b, scale)
                        local result = {}
                        for j = 1, n do
                            result[j] = a[j] + scale * (a[j] - b[j])
                        end
                        return result
                    end

                    local function sort_simplex()
                        -- Bubble sort by function value
                        for i = 1, n + 1 do
                            for j = i + 1, n + 1 do
                                if fvals[j] < fvals[i] then
                                    simplex[i], simplex[j] = simplex[j], simplex[i]
                                    fvals[i], fvals[j] = fvals[j], fvals[i]
                                end
                            end
                        end
                    end

                    local function converged_check()
                        -- Check if simplex has converged
                        local fmax, fmin = fvals[1], fvals[1]
                        for i = 2, n + 1 do
                            if fvals[i] > fmax then fmax = fvals[i] end
                            if fvals[i] < fmin then fmin = fvals[i] end
                        end
                        if math.abs(fmax - fmin) < ftol then return true end

                        -- Check vertex spread
                        local spread = 0
                        for i = 2, n + 1 do
                            for j = 1, n do
                                spread = spread + math.abs(simplex[i][j] - simplex[1][j])
                            end
                        end
                        return spread < xtol * n
                    end

                    -- Main iteration
                    for iter = 1, maxiter do
                        nit = iter
                        sort_simplex()

                        if converged_check() then
                            return {
                                x = simplex[1],
                                fun = fvals[1],
                                success = true,
                                message = "Optimization converged",
                                nfev = nfev,
                                nit = nit
                            }
                        end

                        local c = centroid(n + 1)  -- Centroid excluding worst point

                        -- Reflection
                        local xr = {}
                        for j = 1, n do
                            xr[j] = c[j] + alpha * (c[j] - simplex[n + 1][j])
                        end
                        local fr = f(xr)

                        if fr < fvals[n] and fr >= fvals[1] then
                            -- Accept reflection
                            simplex[n + 1] = xr
                            fvals[n + 1] = fr
                        elseif fr < fvals[1] then
                            -- Try expansion
                            local xe = {}
                            for j = 1, n do
                                xe[j] = c[j] + gamma * (xr[j] - c[j])
                            end
                            local fe = f(xe)
                            if fe < fr then
                                simplex[n + 1] = xe
                                fvals[n + 1] = fe
                            else
                                simplex[n + 1] = xr
                                fvals[n + 1] = fr
                            end
                        else
                            -- Contraction
                            local xc = {}
                            if fr < fvals[n + 1] then
                                -- Outside contraction
                                for j = 1, n do
                                    xc[j] = c[j] + rho * (xr[j] - c[j])
                                end
                            else
                                -- Inside contraction
                                for j = 1, n do
                                    xc[j] = c[j] + rho * (simplex[n + 1][j] - c[j])
                                end
                            end
                            local fc = f(xc)

                            if fc < fvals[n + 1] and fc < fr then
                                simplex[n + 1] = xc
                                fvals[n + 1] = fc
                            else
                                -- Shrink
                                for i = 2, n + 1 do
                                    for j = 1, n do
                                        simplex[i][j] = simplex[1][j] + sigma * (simplex[i][j] - simplex[1][j])
                                    end
                                    fvals[i] = f(simplex[i])
                                end
                            end
                        end
                    end

                    sort_simplex()
                    return {
                        x = simplex[1],
                        fun = fvals[1],
                        success = false,
                        message = "Maximum iterations reached",
                        nfev = nfev,
                        nit = nit
                    }
                end

                ----------------------------------------------------------------
                -- root: Root finding for systems of equations
                -- Method: "hybr" (Newton with line search fallback)
                ----------------------------------------------------------------
                function optimize.root(func, x0, options)
                    options = options or {}
                    local xtol = options.xtol or DEFAULT_XTOL
                    local ftol = options.ftol or DEFAULT_FTOL
                    local maxiter = options.maxiter or DEFAULT_MAXITER
                    local jac = options.jac  -- Optional Jacobian function

                    local nfev = 0
                    local nit = 0
                    local n = #x0

                    local function f(x)
                        nfev = nfev + 1
                        return func(x)
                    end

                    -- Compute numerical Jacobian if not provided
                    local function compute_jacobian(x)
                        local h = 1e-8
                        local fx = f(x)
                        local m = #fx
                        local J = {}
                        for i = 1, m do
                            J[i] = {}
                            for j = 1, n do J[i][j] = 0 end
                        end

                        for j = 1, n do
                            local x_plus = {}
                            for k = 1, n do x_plus[k] = x[k] end
                            x_plus[j] = x_plus[j] + h
                            local fx_plus = f(x_plus)
                            for i = 1, m do
                                J[i][j] = (fx_plus[i] - fx[i]) / h
                            end
                        end
                        return J, fx
                    end

                    -- Solve Jx = b using Gaussian elimination (for small systems)
                    local function solve_linear(J, b)
                        local m = #J
                        -- Augmented matrix
                        local A = {}
                        for i = 1, m do
                            A[i] = {}
                            for j = 1, m do A[i][j] = J[i][j] end
                            A[i][m + 1] = b[i]
                        end

                        -- Forward elimination with partial pivoting
                        for k = 1, m do
                            -- Find pivot
                            local max_val, max_idx = math.abs(A[k][k]), k
                            for i = k + 1, m do
                                if math.abs(A[i][k]) > max_val then
                                    max_val = math.abs(A[i][k])
                                    max_idx = i
                                end
                            end
                            if max_val < 1e-15 then
                                return nil  -- Singular matrix
                            end
                            if max_idx ~= k then
                                A[k], A[max_idx] = A[max_idx], A[k]
                            end

                            -- Eliminate
                            for i = k + 1, m do
                                local factor = A[i][k] / A[k][k]
                                for j = k, m + 1 do
                                    A[i][j] = A[i][j] - factor * A[k][j]
                                end
                            end
                        end

                        -- Back substitution
                        local x = {}
                        for i = m, 1, -1 do
                            x[i] = A[i][m + 1]
                            for j = i + 1, m do
                                x[i] = x[i] - A[i][j] * x[j]
                            end
                            x[i] = x[i] / A[i][i]
                        end
                        return x
                    end

                    -- Vector norm
                    local function norm(v)
                        local s = 0
                        for i = 1, #v do s = s + v[i] * v[i] end
                        return math.sqrt(s)
                    end

                    -- Newton iteration
                    local x = {}
                    for i = 1, n do x[i] = x0[i] end

                    for iter = 1, maxiter do
                        nit = iter
                        local J, fx
                        if jac then
                            J = jac(x)
                            fx = f(x)
                        else
                            J, fx = compute_jacobian(x)
                        end

                        local fn = norm(fx)
                        if fn < ftol then
                            return {
                                x = x,
                                fun = fx,
                                success = true,
                                message = "Root found",
                                nfev = nfev,
                                nit = nit
                            }
                        end

                        -- Solve J * dx = -fx
                        local neg_fx = {}
                        for i = 1, #fx do neg_fx[i] = -fx[i] end
                        local dx = solve_linear(J, neg_fx)

                        if not dx then
                            return {
                                x = x,
                                fun = fx,
                                success = false,
                                message = "Jacobian is singular",
                                nfev = nfev,
                                nit = nit
                            }
                        end

                        -- Line search (simple backtracking)
                        local alpha_ls = 1.0
                        local x_new = {}
                        for trial = 1, 10 do
                            for i = 1, n do
                                x_new[i] = x[i] + alpha_ls * dx[i]
                            end
                            local fx_new = f(x_new)
                            local fn_new = norm(fx_new)
                            if fn_new < fn then
                                break
                            end
                            alpha_ls = alpha_ls * 0.5
                        end

                        -- Check convergence by step size
                        local dx_norm = 0
                        for i = 1, n do
                            dx_norm = dx_norm + (x_new[i] - x[i])^2
                        end
                        dx_norm = math.sqrt(dx_norm)

                        x = x_new
                        if dx_norm < xtol then
                            local fx_final = f(x)
                            return {
                                x = x,
                                fun = fx_final,
                                success = norm(fx_final) < ftol,
                                message = "Step size below tolerance",
                                nfev = nfev,
                                nit = nit
                            }
                        end
                    end

                    local fx_final = f(x)
                    return {
                        x = x,
                        fun = fx_final,
                        success = false,
                        message = "Maximum iterations reached",
                        nfev = nfev,
                        nit = nit
                    }
                end

                -- Store the module
                luaswift.optimize = optimize

                -- Also update math.optimize if math table exists
                if math and type(math.optimize) == "table" then
                    for k, v in pairs(optimize) do
                        math.optimize[k] = v
                    end
                end
                """)
        } catch {
            // Silently fail
        }
    }
}
