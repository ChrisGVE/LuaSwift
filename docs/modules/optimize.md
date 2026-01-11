# Optimization Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.optimize` | **Global:** `math.optimize` (after extend_stdlib)

Numerical optimization functions including scalar minimization, root finding, multivariate optimization, and curve fitting. Implements algorithms equivalent to scipy.optimize.

## Scalar Minimization

Find the minimum of a univariate function.

```lua
local opt = require("luaswift.optimize")

-- Minimize (x-2)^2 using Brent's method (default)
local result = opt.minimize_scalar(function(x) return (x-2)^2 end, {bracket={0,4}})
print(result.x)        -- 2.0
print(result.fun)      -- 0.0
print(result.success)  -- true

-- Golden section search
local result = opt.minimize_scalar(function(x) return x^4 - 2*x^2 + 1 end, {
  method = "golden",
  bracket = {-2, 2}
})
```

### minimize_scalar Options

- `method`: `"brent"` (default) or `"golden"`
- `bracket`: 2-element array `{a, b}` or 3-element `{a, mid, b}` for bracketing
- `bounds`: `{a, b}` for bounded minimization
- `xtol`: parameter tolerance (default: 1e-8)
- `maxiter`: maximum iterations (default: 500)

Returns: `{x, fun, success, message, nfev, nit}`

## Scalar Root Finding

Find roots of scalar equations.

```lua
-- Find root of x^2 - 4 = 0 using Brent's method (default)
local result = opt.root_scalar(function(x) return x^2 - 4 end, {bracket={0,5}})
print(result.root)      -- 2.0
print(result.converged) -- true

-- Bisection method
local result = opt.root_scalar(function(x) return math.cos(x) - x end, {
  method = "bisect",
  bracket = {0, 1}
})

-- Newton's method with analytical derivative
local result = opt.root_scalar(function(x) return x^2 - 4 end, {
  method = "newton",
  x0 = 1,
  fprime = function(x) return 2*x end
})

-- Secant method (no derivative needed)
local result = opt.root_scalar(function(x) return x^3 - 2*x - 5 end, {
  method = "secant",
  x0 = 2,
  x1 = 2.5
})
```

### root_scalar Methods

- `"brentq"`: Brent's method (default, requires bracket)
- `"bisect"`: Bisection (requires bracket)
- `"newton"`: Newton-Raphson (requires x0, optionally fprime)
- `"secant"`: Secant method (requires x0, optionally x1)

### root_scalar Options

- `method`: root-finding algorithm
- `bracket`: `{a, b}` where f(a) and f(b) have opposite signs
- `x0`: initial guess (Newton, Secant)
- `x1`: second point for Secant (default: x0 + 0.1)
- `fprime`: derivative function (Newton, optional)
- `xtol`: parameter tolerance (default: 1e-8)
- `ftol`: function value tolerance (default: 1e-8)
- `maxiter`: maximum iterations (default: 500)

Returns: `{root, converged, message, iterations, function_calls}`

## Multivariate Minimization

Minimize functions of multiple variables using the Nelder-Mead simplex algorithm.

```lua
-- Minimize Rosenbrock function: (1-x)^2 + 100(y-x^2)^2
local function rosenbrock(params)
  local x, y = params[1], params[2]
  return (1 - x)^2 + 100 * (y - x^2)^2
end

local result = opt.minimize(rosenbrock, {0, 0})
print(result.x[1], result.x[2])  -- 1.0, 1.0
print(result.fun)                -- ~0
print(result.success)            -- true

-- Simple quadratic
local result = opt.minimize(
  function(x) return (x[1]-1)^2 + (x[2]-2)^2 end,
  {0, 0},
  {xtol = 1e-6, maxiter = 1000}
)
```

### minimize Options

- `method`: `"nelder-mead"` (only method currently supported)
- `xtol`: parameter tolerance (default: 1e-8)
- `ftol`: function value tolerance (default: 1e-8)
- `maxiter`: maximum iterations (default: 500 * n_params)

Returns: `{x, fun, success, message, nfev, nit}`

## System Root Finding

Find roots of systems of equations using Newton's method with line search.

```lua
-- Solve system:
--   x^2 + y - 1 = 0
--   x - y^2 + 1 = 0
local function system(params)
  local x, y = params[1], params[2]
  return {
    x^2 + y - 1,
    x - y^2 + 1
  }
end

local result = opt.root(system, {0.5, 0.5})
print(result.x[1], result.x[2])  -- solution
print(result.success)            -- true

-- With analytical Jacobian
local function jacobian(params)
  local x, y = params[1], params[2]
  return {
    {2*x, 1},
    {1, -2*y}
  }
end

local result = opt.root(system, {0.5, 0.5}, {jac = jacobian})
```

### root Options

- `jac`: Jacobian function (optional, computed numerically if not provided)
- `xtol`: parameter tolerance (default: 1e-8)
- `ftol`: function value tolerance (default: 1e-8)
- `maxiter`: maximum iterations (default: 500)

Returns: `{x, fun, success, message, nfev, nit}`

## Nonlinear Least Squares

Solve nonlinear least squares problems using Levenberg-Marquardt algorithm.

```lua
-- Fit exponential decay: y = a * exp(-b * x) + c
local function residuals(params)
  local a, b, c = params[1], params[2], params[3]
  local r = {}
  for i = 1, #xdata do
    local y_pred = a * math.exp(-b * xdata[i]) + c
    r[i] = ydata[i] - y_pred
  end
  return r
end

local result = opt.least_squares(residuals, {1, 1, 0}, {
  ftol = 1e-8,
  xtol = 1e-8,
  max_nfev = 1000
})

print(result.x[1], result.x[2], result.x[3])  -- fitted parameters
print(result.cost)                            -- final ||residuals||^2 / 2
print(result.success)                         -- true
```

### least_squares Options

- `jac`: Jacobian function (optional, computed numerically if not provided)
- `ftol`: function tolerance (default: 1e-8)
- `xtol`: parameter tolerance (default: 1e-8)
- `gtol`: gradient tolerance (default: 1e-8)
- `max_nfev`: max function evaluations (default: 100 * n_params)
- `bounds`: `{lower={...}, upper={...}}` for parameter bounds
- `verbose`: verbosity level (default: 0)

Returns: `{x, cost, fun, jac, success, message, nfev, njev}`

## Curve Fitting

Fit a model function to data points.

```lua
-- Fit linear model: y = a*x + b
local function linear(x, params)
  return params[1] * x + params[2]
end

local xdata = {0, 1, 2, 3, 4}
local ydata = {1.1, 2.9, 5.2, 7.0, 8.9}

local popt, pcov, info = opt.curve_fit(linear, xdata, ydata, {1, 1})
print(popt[1], popt[2])  -- fitted slope and intercept
print(info.success)      -- true

-- Fit with parameter bounds
local function gaussian(x, params)
  local a, mu, sigma = params[1], params[2], params[3]
  return a * math.exp(-0.5 * ((x - mu) / sigma)^2)
end

local popt, pcov, info = opt.curve_fit(
  gaussian,
  xdata,
  ydata,
  {1, 0, 1},  -- initial guess
  {
    bounds = {
      lower = {0, -10, 0.1},
      upper = {10, 10, 5}
    }
  }
)

-- With uncertainties
local sigma = {0.1, 0.1, 0.2, 0.15, 0.1}
local popt, pcov, info = opt.curve_fit(linear, xdata, ydata, {1, 1}, {
  sigma = sigma,
  absolute_sigma = true
})

-- Extract parameter uncertainties from covariance
local a_err = math.sqrt(pcov[1][1])
local b_err = math.sqrt(pcov[2][2])
```

### curve_fit Options

- `sigma`: uncertainties in ydata (optional)
- `absolute_sigma`: if true, sigma is absolute (default: false)
- `bounds`: `{lower={...}, upper={...}}` for parameter bounds
- `method`: optimization method (default: "lm")
- `maxfev`: max function evaluations (default: 1000)
- `ftol`, `xtol`: tolerances

Returns: `popt, pcov, info`
- `popt`: optimal parameters (array)
- `pcov`: covariance matrix (approximate)
- `info`: `{success, message, nfev, cost}`

The model function can be called as `f(x, params)` or `f(x, p1, p2, ...)` (both forms are tried).

## Function Reference

| Function | Description |
|----------|-------------|
| `minimize_scalar(func, options)` | Find minimum of scalar function |
| `root_scalar(func, options)` | Find root of scalar equation |
| `minimize(func, x0, options)` | Minimize multivariate function |
| `root(func, x0, options)` | Solve system of equations |
| `least_squares(fun, x0, options)` | Nonlinear least squares optimization |
| `curve_fit(f, xdata, ydata, p0, options)` | Fit function to data |

All functions return result tables with convergence information (`success`/`converged`, `message`, function evaluations, iterations).
