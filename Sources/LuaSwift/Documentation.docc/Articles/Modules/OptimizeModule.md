# Optimize Module

Numerical optimization, root-finding, and curve-fitting algorithms (scipy.optimize-inspired).

> Important: This module requires the **NumericSwift** optional dependency.
> It is **off by default**. Enable it at build time:
> ```
> LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build
> ```
> Without this flag the module is not compiled and `math.optimize` / `luaswift.optimize` are not available.

## Overview

The Optimize module provides scalar and multivariate minimization, scalar and multivariate root-finding, nonlinear least-squares fitting, and curve fitting. Functions are available under two equivalent namespaces after calling `luaswift.extend_stdlib()`:

- `math.optimize.<function>`
- `luaswift.optimize.<function>`

All algorithms are implemented in the **NumericSwift** library; this module provides thin Lua bindings.

## Installation

```swift
// Install all modules (NumericSwift must be enabled at compile time)
ModuleRegistry.installModules(in: engine)

// Or install just the optimize module
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local opt = math.optimize
```

## API Reference

### minimize_scalar(func, options?)

Finds the minimum of a scalar function of one variable. Uses Brent's method (default) or Golden section search.

**Parameters:**
- `func` - Function `f(x) -> number`
- `options` (optional) - Table with fields:
  - `method` (string) - `"brent"` (default) or `"golden"`
  - `bracket` (array) - `{a, b}` search interval (default: `{-10, 10}`)
  - `xtol` (number) - Tolerance (default: `1e-8`)
  - `maxiter` (number) - Maximum iterations (default: 500)

**Returns:** Table with fields:
- `x` (number) - Location of the minimum
- `fun` (number) - Function value at the minimum
- `nfev` (number) - Number of function evaluations
- `nit` (number) - Number of iterations
- `success` (boolean) - Whether the solver converged
- `message` (string) - Convergence message

**Examples:**

```lua
local opt = math.optimize

-- Minimize f(x) = (x - 2)^2
local result = opt.minimize_scalar(function(x) return (x - 2)^2 end,
    {bracket = {0, 4}})
print(result.x)       -- ~2.0
print(result.fun)     -- ~0.0
print(result.success) -- true

-- Golden section method
local result2 = opt.minimize_scalar(
    function(x) return x^4 - 3*x^2 + x end,
    {method = "golden", bracket = {-2, 0}})
print(result2.x)
```

---

### root_scalar(func, options?)

Finds a root of a scalar function (finds `x` such that `f(x) = 0`). Supports Bisection/Brentq, Newton, and Secant methods.

**Parameters:**
- `func` - Function `f(x) -> number`
- `options` (optional) - Table with fields:
  - `method` (string) - `"bisect"` / `"brentq"` (default), `"newton"`, or `"secant"`
  - `bracket` (array) - `{a, b}` for bracket methods; `f(a)` and `f(b)` must have opposite signs
  - `x0` (number) - Initial guess for Newton/Secant
  - `x1` (number) - Second point for Secant method
  - `xtol` (number) - Tolerance (default: `1e-8`)
  - `maxiter` (number) - Maximum iterations (default: 100)

**Returns:** Table with fields:
- `root` (number) - Location of the root
- `iterations` (number) - Number of iterations taken
- `function_calls` (number) - Number of function evaluations
- `converged` (boolean) - Whether the solver converged
- `message` (string) - Convergence message
- `flag` (string) - Convergence flag (same as `message`, kept for compatibility)

**Examples:**

```lua
local opt = math.optimize

-- Bisection: find root of x^2 - 4 = 0 in [0, 5]
local result = opt.root_scalar(function(x) return x^2 - 4 end,
    {bracket = {0, 5}})
print(result.root)      -- ~2.0
print(result.converged) -- true

-- Newton's method from an initial guess
local result2 = opt.root_scalar(function(x) return math.cos(x) - x end,
    {method = "newton", x0 = 1.0})
print(result2.root) -- ~0.7390851...

-- Secant method
local result3 = opt.root_scalar(function(x) return x^3 - x - 2 end,
    {method = "secant", x0 = 1.0, x1 = 2.0})
print(result3.root)
```

---

### minimize(func, x0, options?)

Finds the minimum of a multivariate function using the Nelder-Mead simplex algorithm (derivative-free).

**Parameters:**
- `func` - Function `f(x) -> number` where `x` is a 1-indexed array
- `x0` (array) - Initial guess, e.g. `{0, 0}`
- `options` (optional) - Table with fields:
  - `method` (string) - Algorithm (default: `"Nelder-Mead"`)
  - `xtol` (number) - Parameter tolerance (default: `1e-8`)
  - `ftol` (number) - Function value tolerance (default: `1e-8`)
  - `maxiter` (number) - Maximum iterations (default: none)

**Returns:** Table with fields:
- `x` (array) - Parameter values at the minimum
- `fun` (number) - Function value at the minimum
- `nfev` (number) - Number of function evaluations
- `nit` (number) - Number of iterations
- `success` (boolean) - Whether the solver converged
- `message` (string) - Convergence message

**Examples:**

```lua
local opt = math.optimize

-- Minimize a simple bowl: f(x,y) = (x-1)^2 + (y-2)^2
local result = opt.minimize(
    function(x) return (x[1] - 1)^2 + (x[2] - 2)^2 end,
    {0, 0})
print(result.x[1], result.x[2]) -- ~1.0, ~2.0
print(result.fun)                -- ~0.0
print(result.success)            -- true

-- Rosenbrock function
local function rosenbrock(x)
    return (1 - x[1])^2 + 100 * (x[2] - x[1]^2)^2
end
local result2 = opt.minimize(rosenbrock, {0, 0},
    {xtol = 1e-10, ftol = 1e-10})
print(result2.x[1], result2.x[2]) -- ~1.0, ~1.0
```

---

### root(func, x0, options?)

Finds a root of a multivariate vector function (finds `x` such that `f(x) = 0` for all components). Uses Newton's method for systems of equations.

**Parameters:**
- `func` - Function `f(x) -> array` where both `x` and the return value are 1-indexed arrays of equal length
- `x0` (array) - Initial guess
- `options` (optional) - Table with fields:
  - `method` (string) - Algorithm (default: `"hybr"`)
  - `tol` (number) - Tolerance (default: `1e-8`)
  - `maxiter` (number) - Maximum iterations (default: 500)

**Returns:** Table with fields:
- `x` (array) - Solution vector
- `fun` (array) - Residuals at the solution
- `success` (boolean) - Whether the solver converged
- `message` (string) - Convergence message
- `nfev` (number) - Number of function evaluations
- `nit` (number) - Number of iterations

**Example:**

```lua
local opt = math.optimize

-- Solve the 2×2 system:
--   x^2 + y^2 = 1
--   x - y     = 0
-- => solutions: (±1/√2, ±1/√2)
local function system(v)
    local x, y = v[1], v[2]
    return {x^2 + y^2 - 1, x - y}
end

local result = opt.root(system, {0.5, 0.5})
print(result.x[1], result.x[2]) -- ~0.707, ~0.707
print(result.success)            -- true
```

---

### least_squares(residuals, x0, options?)

Solves a nonlinear least-squares problem using the Levenberg-Marquardt / projected Levenberg-Marquardt algorithm. Supports optional box constraints.

**Parameters:**
- `residuals` - Function `r(x) -> array` returning the residual vector
- `x0` (array) - Initial guess for the parameters
- `options` (optional) - Table with fields:
  - `ftol` (number) - Function tolerance (default: `1e-8`)
  - `xtol` (number) - Parameter tolerance (default: `1e-8`)
  - `maxiter` (number) - Maximum iterations (default: 100)
  - `bounds` (table) - Box constraints with sub-fields:
    - `lower` (array) - Lower bounds for each parameter
    - `upper` (array) - Upper bounds for each parameter

**Returns:** Table with fields:
- `x` (array) - Optimal parameters
- `cost` (number) - `0.5 * sum(residuals^2)` at the solution
- `fun` (array) - Residuals at the solution
- `jac` (array) - Jacobian placeholder (empty in current implementation)
- `nfev` (number) - Number of residual evaluations
- `njev` (number) - Number of Jacobian evaluations
- `success` (boolean) - Whether the solver converged
- `message` (string) - Convergence message

**Examples:**

```lua
local opt = math.optimize

-- Fit y = a * exp(b * x) using least squares
local xdata = {0, 1, 2, 3}
local ydata = {1.0, 2.7, 7.4, 20.1}  -- approx e^x

local function residuals(params)
    local a, b = params[1], params[2]
    local res = {}
    for i = 1, #xdata do
        res[i] = ydata[i] - a * math.exp(b * xdata[i])
    end
    return res
end

local result = opt.least_squares(residuals, {1, 1})
print(result.x[1], result.x[2]) -- ~1.0, ~1.0
print(result.success)            -- true

-- With box constraints (both parameters must be positive)
local result2 = opt.least_squares(residuals, {0.5, 0.5}, {
    bounds = {lower = {0, 0}, upper = {10, 10}}
})
print(result2.x[1], result2.x[2])
```

---

### curve_fit(func, xdata, ydata, p0, options?)

Fits a model function to observed data. Returns **three separate values**: optimal parameters, covariance matrix, and fit info. The model function may use either calling convention (expanded parameters or array).

**Parameters:**
- `func` - Model function. Two calling conventions are supported:
  - Expanded: `f(x, a, b, c, ...)` — each parameter is a separate argument
  - Array: `f(x, params)` — parameters passed as array (tried as fallback)
- `xdata` (array) - Independent variable values
- `ydata` (array) - Observed dependent variable values (`#xdata == #ydata` required)
- `p0` (array) - Initial parameter guess
- `options` (optional) - Table with fields:
  - `ftol` (number) - Function tolerance (default: `1e-8`)
  - `xtol` (number) - Parameter tolerance (default: `1e-8`)
  - `maxiter` (number) - Maximum iterations (default: 100)

**Returns:** Three values in order:
1. `popt` (array) - Optimal parameters
2. `pcov` (array of arrays) - Estimated covariance matrix of `popt` (n × n)
3. `info` (table) - Fit diagnostics:
   - `x` (array) - Optimal parameters (same as `popt`)
   - `cost` (number) - Final cost
   - `fun` (array) - Final residuals
   - `nfev` (number) - Function evaluations
   - `njev` (number) - Jacobian evaluations
   - `success` (boolean)
   - `message` (string)

> Important: `curve_fit` returns **three separate Lua values**, not a single table with a `params` field. Assign them individually as shown below.

**Examples:**

```lua
local opt = math.optimize

-- Fit y = a * exp(b * x) — expanded parameter form
local function model(x, a, b)
    return a * math.exp(b * x)
end

local xdata = {0, 1, 2, 3, 4}
local ydata = {1.0, 2.7, 7.4, 20.1, 54.6}
local p0 = {1, 1}

local popt, pcov, info = opt.curve_fit(model, xdata, ydata, p0)
print("a =", popt[1])     -- ~1.0
print("b =", popt[2])     -- ~1.0
print("success:", info.success)

-- Access covariance (2×2 matrix)
print("var(a) =", pcov[1][1])
print("var(b) =", pcov[2][2])

-- Array parameter form also works
local function model2(x, params)
    return params[1] * math.exp(params[2] * x)
end
local popt2, pcov2, info2 = opt.curve_fit(model2, xdata, ydata, p0)

-- Polynomial fit: y = a*x^2 + b*x + c
local function poly(x, a, b, c)
    return a * x^2 + b * x + c
end

local xp = {0, 1, 2, 3, 4, 5}
local yp = {1, -1, -3, -1, 5, 15}  -- approx 2x^2 - 6x + 1

local popt3, pcov3, info3 = opt.curve_fit(poly, xp, yp, {1, 1, 1})
print(string.format("y = %.2f*x^2 + %.2f*x + %.2f",
    popt3[1], popt3[2], popt3[3]))
```

## Examples

### Maximum Likelihood Estimation

```lua
local opt = math.optimize

-- Estimate mean and std of a normal distribution
local data = {1.2, 1.5, 1.8, 1.4, 1.6, 1.3, 1.7}

local function neg_log_likelihood(params)
    local mean, std = params[1], params[2]
    if std <= 0 then return 1e10 end
    local n = #data
    local sum_sq = 0
    for i = 1, n do
        sum_sq = sum_sq + (data[i] - mean)^2
    end
    return n * math.log(std) + sum_sq / (2 * std^2)
end

local result = opt.minimize(neg_log_likelihood, {1, 1})
print("Mean:", result.x[1])
print("Std: ", result.x[2])
print("Success:", result.success)
```

### Finding Function Intersections

```lua
local opt = math.optimize

-- Find where f(x) = g(x)  =>  f(x) - g(x) = 0
local function f(x) return x^2 end
local function g(x) return 2*x + 3 end

local result = opt.root_scalar(function(x) return f(x) - g(x) end,
    {bracket = {-2, 4}})
print("Intersection at x =", result.root) -- ~3.0
```

### Bounded Parameter Estimation

```lua
local opt = math.optimize

-- Fit decay curve with positivity constraint on parameters
local tdata = {0, 1, 2, 3, 4, 5}
local adata = {10.0, 6.1, 3.7, 2.2, 1.4, 0.8}  -- ~10 * exp(-0.5 * t)

local function decay_residuals(params)
    local A, k = params[1], params[2]
    local res = {}
    for i = 1, #tdata do
        res[i] = adata[i] - A * math.exp(-k * tdata[i])
    end
    return res
end

local result = opt.least_squares(decay_residuals, {5, 0.3}, {
    bounds = {lower = {0, 0}, upper = {100, 10}}
})
print(string.format("A = %.4f, k = %.4f", result.x[1], result.x[2]))
```

## Algorithm Notes

| Function | Default Algorithm | Notes |
|---|---|---|
| `minimize_scalar` | Brent's method | Golden section also available |
| `root_scalar` | Bisection / Brentq | Newton and Secant available |
| `minimize` | Nelder-Mead | Derivative-free; robust for non-smooth functions |
| `root` | Newton (multivariate) | Requires the function to be locally differentiable |
| `least_squares` | Levenberg-Marquardt | Projected variant supports box constraints |
| `curve_fit` | Levenberg-Marquardt | Wraps `least_squares`; supports both parameter calling conventions |

## See Also

- ``OptimizeModule``
- <doc:IntegrateModule>
- <doc:InterpolateModule>
