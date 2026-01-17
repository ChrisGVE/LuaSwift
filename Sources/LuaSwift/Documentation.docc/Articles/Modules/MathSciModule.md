# Math Sci Module

Scientific computing namespace coordinator.

## Overview

The MathSci module serves as the central coordinator for all scientific computing modules under the `math` namespace. After calling `luaswift.extend_stdlib()`, it organizes submodules into a coherent hierarchy.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
-- All math.* submodules are now available
```

## Namespace Organization

The `math` namespace is extended with the following submodules:

### Core Extensions
- `math.sign(x)` - Sign function
- `math.round(x)` - Round to nearest integer
- `math.trunc(x)` - Truncate to integer
- `math.factorial(n)` - Factorial function
- `math.gamma(x)` - Gamma function

### Submodules

```lua
-- Linear Algebra
local m = math.linalg.matrix({{1, 2}, {3, 4}})

-- Complex Numbers
local z = math.complex.new(3, 4)

-- Geometry
local v = math.geo.vec3(1, 2, 3)

-- Special Functions
local g = math.special.gamma(5)

-- Statistics
local avg = math.stats.mean({1, 2, 3, 4, 5})

-- Distributions
local norm = math.distributions.normal()

-- Optimization
local result = math.optimize.minimize(f, x0)

-- Integration
local integral = math.integrate.quad(f, 0, 1)

-- Interpolation
local spline = math.interpolate.cubicspline(x, y)

-- Clustering
local clusters = math.cluster.kmeans(data, 3)

-- Spatial
local tree = math.spatial.kdtree(points)

-- Regression
local model = math.regress.ols(y, X)

-- Series
local sum = math.series.sum(term_func, 1)

-- Expression Evaluation
local result = math.eval("sin(x)^2 + cos(x)^2", {x = 1})

-- Constants
local c = math.constants.c  -- Speed of light

-- Number Theory
local primes = math.numtheory.primes(100)
```

## Extended Math Functions

The base `math` table receives these extensions:

### Rounding Functions

```lua
print(math.round(3.7))      -- 4
print(math.round(3.2))      -- 3
print(math.trunc(3.7))      -- 3
print(math.trunc(-3.7))     -- -3
```

### Sign Function

```lua
print(math.sign(5))         -- 1
print(math.sign(-3))        -- -1
print(math.sign(0))         -- 0
```

### Hyperbolic Functions

```lua
print(math.sinh(1))
print(math.cosh(1))
print(math.tanh(1))
```

### Extended Logarithms

```lua
print(math.log2(8))         -- 3
print(math.log10(1000))     -- 3
print(math.log1p(0.1))      -- log(1 + x), more accurate for small x
```

### Factorial and Gamma

```lua
print(math.factorial(5))    -- 120
print(math.gamma(6))        -- 120 (gamma(n) = (n-1)!)
```

## Complete Scientific Workflow

```lua
luaswift.extend_stdlib()

-- 1. Generate data
local array = require("luaswift.array")
local x = array.linspace(0, 10, 100)
local y_true = 2 * x^2 - 3 * x + 1
local noise = array.random.randn(x:shape()) * 5
local y = y_true + noise

-- 2. Fit polynomial
local xdata = x:tolist()
local ydata = y:tolist()

local function poly(x_val, params)
    local a, b, c = params[1], params[2], params[3]
    return a * x_val^2 + b * x_val + c
end

local fit = math.optimize.curve_fit(poly, xdata, ydata, {1, 1, 1})
print("Coefficients:", table.unpack(fit.params))

-- 3. Create interpolator for smooth curve
local y_fit = {}
for i, xi in ipairs(xdata) do
    y_fit[i] = poly(xi, fit.params)
end

local interp = math.interpolate.cubicspline(xdata, y_fit)

-- 4. Plot results
local plot = require("luaswift.plot")
local fig = plot.figure(800, 600)
local ax = fig:subplot(1, 1, 1)

ax:scatter(xdata, ydata, {label = "Data", alpha = 0.5})
ax:plot(xdata, y_fit, {label = "Fit", color = "red"})
ax:legend()
ax:set_title("Polynomial Regression")

local svg = fig:render()

-- 5. Save results
local io = require("luaswift.iox")
io.write_file("analysis.svg", svg)

local json = require("luaswift.json")
local results = {
    coefficients = fit.params,
    rsquared = fit.rsquared
}
io.write_file("results.json", json.encode(results))
```

## Integration with Other Modules

The math namespace seamlessly integrates with:

- **Array Module**: Many functions accept/return arrays
- **Plot Module**: Visualize mathematical results
- **JSON/TOML**: Serialize mathematical structures
- **IO Module**: Save/load data and models

## See Also

- ``MathSciModule``
- <doc:MathXModule>
- <doc:ArrayModule>
- All math submodule documentation
