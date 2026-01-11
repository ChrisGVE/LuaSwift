# Optimization Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.optimize` | **Global:** `math.optimize` (after extend_stdlib)

Numerical optimization functions including scalar minimization, root finding, multivariate optimization, and curve fitting. Implements algorithms equivalent to scipy.optimize.

## Function Reference

| Function | Description |
|----------|-------------|
| [minimize_scalar(func, options)](#minimize_scalar) | Find minimum of scalar function |
| [root_scalar(func, options)](#root_scalar) | Find root of scalar equation |
| [minimize(func, x0, options)](#minimize) | Minimize multivariate function |
| [root(func, x0, options)](#root) | Solve system of equations |
| [least_squares(fun, x0, options)](#least_squares) | Nonlinear least squares optimization |
| [curve_fit(f, xdata, ydata, p0, options)](#curve_fit) | Fit function to data |

---

## minimize_scalar

```
optimize.minimize_scalar(func, options) -> result
```

Find the minimum of a univariate function using Brent's method or golden section search.

**Parameters:**
- `func` - Function to minimize (takes single number, returns number)
- `options` - Table with optimization options:
  - `method` (string): `"brent"` (default) or `"golden"`
  - `bracket` (array): 2-element `{a, b}` or 3-element `{a, mid, b}` for bracketing
  - `bounds` (table): `{a, b}` for bounded minimization
  - `xtol` (number): parameter tolerance (default: 1e-8)
  - `maxiter` (number): maximum iterations (default: 500)

**Returns:** Table with:
- `x` - location of minimum
- `fun` - function value at minimum
- `success` - convergence status (boolean)
- `message` - convergence message
- `nfev` - number of function evaluations
- `nit` - number of iterations

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

---

## root_scalar

```
optimize.root_scalar(func, options) -> result
```

Find roots of scalar equations using bracketing or derivative-based methods.

**Parameters:**
- `func` - Function whose root to find (takes number, returns number)
- `options` - Table with method options:
  - `method` (string): `"brentq"` (default), `"bisect"`, `"newton"`, or `"secant"`
  - `bracket` (array): `{a, b}` where f(a) and f(b) have opposite signs (for brentq/bisect)
  - `x0` (number): initial guess (for newton/secant)
  - `x1` (number): second point for secant method (default: x0 + 0.1)
  - `fprime` (function): derivative function (optional, for newton)
  - `xtol` (number): parameter tolerance (default: 1e-8)
  - `ftol` (number): function value tolerance (default: 1e-8)
  - `maxiter` (number): maximum iterations (default: 500)

**Returns:** Table with:
- `root` - location of root
- `converged` - convergence status (boolean)
- `message` - convergence message
- `iterations` - number of iterations
- `function_calls` - number of function evaluations

```lua
local opt = require("luaswift.optimize")

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

---

## minimize

```
optimize.minimize(func, x0, options?) -> result
```

Minimize functions of multiple variables using the Nelder-Mead simplex algorithm.

**Parameters:**
- `func` - Function to minimize (takes array of parameters, returns number)
- `x0` - Initial parameter guess (array)
- `options` (optional) - Table with optimization options:
  - `method` (string): `"nelder-mead"` (only method currently supported)
  - `xtol` (number): parameter tolerance (default: 1e-8)
  - `ftol` (number): function value tolerance (default: 1e-8)
  - `maxiter` (number): maximum iterations (default: 500 * n_params)

**Returns:** Table with:
- `x` - optimal parameters (array)
- `fun` - function value at optimum
- `success` - convergence status (boolean)
- `message` - convergence message
- `nfev` - number of function evaluations
- `nit` - number of iterations

```lua
local opt = require("luaswift.optimize")

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

---

## root

```
optimize.root(func, x0, options?) -> result
```

Find roots of systems of equations using Newton's method with line search.

**Parameters:**
- `func` - Function returning residuals (takes array of params, returns array of residuals)
- `x0` - Initial parameter guess (array)
- `options` (optional) - Table with solver options:
  - `jac` (function): Jacobian function (optional, computed numerically if not provided)
  - `xtol` (number): parameter tolerance (default: 1e-8)
  - `ftol` (number): function value tolerance (default: 1e-8)
  - `maxiter` (number): maximum iterations (default: 500)

**Returns:** Table with:
- `x` - solution parameters (array)
- `fun` - residuals at solution (array)
- `success` - convergence status (boolean)
- `message` - convergence message
- `nfev` - number of function evaluations
- `nit` - number of iterations

```lua
local opt = require("luaswift.optimize")

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

---

## least_squares

```
optimize.least_squares(fun, x0, options?) -> result
```

Solve nonlinear least squares problems using Levenberg-Marquardt algorithm.

**Parameters:**
- `fun` - Residual function (takes array of params, returns array of residuals)
- `x0` - Initial parameter guess (array)
- `options` (optional) - Table with solver options:
  - `jac` (function): Jacobian function (optional, computed numerically if not provided)
  - `ftol` (number): function tolerance (default: 1e-8)
  - `xtol` (number): parameter tolerance (default: 1e-8)
  - `gtol` (number): gradient tolerance (default: 1e-8)
  - `max_nfev` (number): max function evaluations (default: 100 * n_params)
  - `bounds` (table): `{lower={...}, upper={...}}` for parameter bounds
  - `verbose` (number): verbosity level (default: 0)

**Returns:** Table with:
- `x` - optimal parameters (array)
- `cost` - final ||residuals||^2 / 2
- `fun` - residuals at optimum (array)
- `jac` - Jacobian at optimum (2D array)
- `success` - convergence status (boolean)
- `message` - convergence message
- `nfev` - number of function evaluations
- `njev` - number of Jacobian evaluations

```lua
local opt = require("luaswift.optimize")

-- Fit exponential decay: y = a * exp(-b * x) + c
local xdata = {0, 1, 2, 3, 4}
local ydata = {5.2, 3.1, 2.0, 1.5, 1.2}

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

---

## curve_fit

```
optimize.curve_fit(f, xdata, ydata, p0, options?) -> popt, pcov, info
```

Fit a model function to data points using nonlinear least squares.

**Parameters:**
- `f` - Model function (can be `f(x, params)` or `f(x, p1, p2, ...)`)
- `xdata` - Independent variable data (array)
- `ydata` - Dependent variable data (array)
- `p0` - Initial parameter guess (array)
- `options` (optional) - Table with fitting options:
  - `sigma` (array): uncertainties in ydata (optional)
  - `absolute_sigma` (boolean): if true, sigma is absolute (default: false)
  - `bounds` (table): `{lower={...}, upper={...}}` for parameter bounds
  - `method` (string): optimization method (default: "lm")
  - `maxfev` (number): max function evaluations (default: 1000)
  - `ftol` (number): function tolerance
  - `xtol` (number): parameter tolerance

**Returns:** Three values:
- `popt` - optimal parameters (array)
- `pcov` - covariance matrix (2D array, approximate)
- `info` - convergence info table: `{success, message, nfev, cost}`

```lua
local opt = require("luaswift.optimize")

-- Fit linear model: y = a*x + b
local function linear(x, params)
  return params[1] * x + params[2]
end

local xdata = {0, 1, 2, 3, 4}
local ydata = {1.1, 2.9, 5.2, 7.0, 8.9}

local popt, pcov, info = opt.curve_fit(linear, xdata, ydata, {1, 1})
print(popt[1], popt[2])  -- fitted slope and intercept
print(info.success)      -- true

-- Extract parameter uncertainties from covariance
local a_err = math.sqrt(pcov[1][1])
local b_err = math.sqrt(pcov[2][2])
```

---

## Examples

### Fitting with Parameter Bounds

```lua
local opt = require("luaswift.optimize")

local function gaussian(x, params)
  local a, mu, sigma = params[1], params[2], params[3]
  return a * math.exp(-0.5 * ((x - mu) / sigma)^2)
end

local xdata = {-2, -1, 0, 1, 2}
local ydata = {0.4, 0.9, 1.0, 0.9, 0.4}

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
```

### Weighted Fitting with Uncertainties

```lua
local function linear(x, params)
  return params[1] * x + params[2]
end

local xdata = {0, 1, 2, 3, 4}
local ydata = {1.1, 2.9, 5.2, 7.0, 8.9}
local sigma = {0.1, 0.1, 0.2, 0.15, 0.1}

local popt, pcov, info = opt.curve_fit(linear, xdata, ydata, {1, 1}, {
  sigma = sigma,
  absolute_sigma = true
})

-- Extract parameter uncertainties
local a_err = math.sqrt(pcov[1][1])
local b_err = math.sqrt(pcov[2][2])
print(string.format("slope: %.3f ± %.3f", popt[1], a_err))
print(string.format("intercept: %.3f ± %.3f", popt[2], b_err))
```
