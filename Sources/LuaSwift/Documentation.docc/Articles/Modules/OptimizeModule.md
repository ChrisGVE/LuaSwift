# Optimize Module

Numerical optimization and root-finding algorithms.

## Overview

The Optimize module provides algorithms for finding minima, maxima, and roots of functions. Available under `math.optimize` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local opt = math.optimize
```

## Minimization

### opt.minimize(f, x0, options?)
Find the minimum of a scalar function.

```lua
-- Minimize f(x) = (x - 3)^2
local function f(x)
    return (x - 3)^2
end

local result = opt.minimize(f, 0)  -- Start at x=0
print("Minimum at:", result.x)      -- ~3
print("Function value:", result.fun) -- ~0
print("Iterations:", result.nit)
print("Success:", result.success)
```

### Options

```lua
local result = opt.minimize(f, x0, {
    tol = 1e-6,      -- Tolerance
    maxiter = 100,   -- Maximum iterations
    method = "brent" -- Algorithm choice
})
```

## Root Finding

### opt.root(f, x0, options?)
Find a root of f(x) = 0.

```lua
-- Find root of x^2 - 4 = 0
local function f(x)
    return x^2 - 4
end

local result = opt.root(f, 1)  -- Start at x=1
print("Root at:", result.x)     -- ~2
```

### opt.bisect(f, a, b, options?)
Bisection method for root finding (f must change sign between a and b).

```lua
local result = opt.bisect(f, 0, 5)  -- Search in [0, 5]
print("Root at:", result.x)
```

## Curve Fitting

### opt.curve_fit(f, xdata, ydata, p0?)
Fit a function to data.

```lua
-- Fit exponential: y = a * exp(b * x)
local function model(x, params)
    local a, b = params[1], params[2]
    return a * math.exp(b * x)
end

local xdata = {0, 1, 2, 3, 4}
local ydata = {1.0, 2.7, 7.4, 20.1, 54.6}
local p0 = {1, 1}  -- Initial guess for [a, b]

local result = opt.curve_fit(model, xdata, ydata, p0)
print("Parameters:", result.params[1], result.params[2])
```

## Multidimensional Optimization

### opt.minimize_nd(f, x0, options?)
Minimize a function of multiple variables.

```lua
-- Rosenbrock function: (1-x)^2 + 100(y-x^2)^2
local function rosenbrock(x)
    local a, b = x[1], x[2]
    return (1 - a)^2 + 100 * (b - a^2)^2
end

local x0 = {0, 0}  -- Start at origin
local result = opt.minimize_nd(rosenbrock, x0)
print("Minimum at:", result.x[1], result.x[2])  -- ~[1, 1]
```

## Constrained Optimization

### opt.minimize_bounded(f, bounds, x0?, options?)
Minimize with box constraints.

```lua
local function f(x)
    return (x - 5)^2
end

-- Constrain to [0, 3]
local bounds = {0, 3}
local result = opt.minimize_bounded(f, bounds)
print("Minimum at:", result.x)  -- 3 (boundary)
```

## Examples

### Fit a Polynomial

```lua
local opt = math.optimize
local array = require("luaswift.array")

-- Generate noisy data
local x = array.linspace(0, 10, 50)
local y_true = 2 * x^2 - 3 * x + 1
local noise = array.random.randn({50}) * 2
local y = y_true + noise

-- Fit polynomial: a*x^2 + b*x + c
local function polynomial(x_val, params)
    local a, b, c = params[1], params[2], params[3]
    return a * x_val^2 + b * x_val + c
end

local xdata = x:tolist()
local ydata = y:tolist()
local p0 = {1, 1, 1}  -- Initial guess

local result = opt.curve_fit(polynomial, xdata, ydata, p0)
print("Coefficients:", table.unpack(result.params))
-- Should recover [2, -3, 1]
```

### Maximum Likelihood Estimation

```lua
-- Estimate parameters of normal distribution
local function neg_log_likelihood(params, data)
    local mean, std = params[1], params[2]
    if std <= 0 then return 1e10 end  -- Invalid

    local n = #data
    local sum_sq = 0
    for i = 1, n do
        sum_sq = sum_sq + (data[i] - mean)^2
    end

    return n * math.log(std) + sum_sq / (2 * std^2)
end

local data = {1.2, 1.5, 1.8, 1.4, 1.6}
local function f(params)
    return neg_log_likelihood(params, data)
end

local result = opt.minimize_nd(f, {1, 1})
print("Mean:", result.x[1])
print("Std:", result.x[2])
```

### Find Intersection

```lua
-- Find where f(x) = g(x)
local function f(x) return x^2 end
local function g(x) return 2*x + 3 end

local function difference(x)
    return f(x) - g(x)
end

local result = opt.root(difference, 0)
print("Intersection at x =", result.x)
```

## Algorithm Notes

- **Brent's method**: Default for 1D minimization, combines golden section and parabolic interpolation
- **Nelder-Mead**: Default for multidimensional minimization, derivative-free
- **Newton-Raphson**: Available for root finding when derivatives can be approximated
- **Levenberg-Marquardt**: Used for curve fitting

## See Also

- ``OptimizeModule``
- <doc:Modules/IntegrateModule>
- <doc:Modules/InterpolateModule>
