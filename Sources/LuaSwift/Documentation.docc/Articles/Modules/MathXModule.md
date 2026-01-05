# MathX Module

Extended math functions beyond Lua's standard math library.

## Overview

The MathX module provides comprehensive mathematical functions including hyperbolic functions, advanced rounding, statistics, special functions, coordinate conversions, and additional constants. These extend Lua's built-in `math` library with Swift-powered implementations.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the MathX module
ModuleRegistry.installMathModule(in: engine)
```

## Basic Usage

```lua
local mathx = require("luaswift.mathx")

-- Or use the global alias
print(mathx.sinh(1))           -- 1.1752011936438

-- Statistics on arrays
local data = {1, 2, 3, 4, 5}
print(mathx.mean(data))        -- 3
print(mathx.stddev(data))      -- 1.4142135623731

-- Extend standard math library
mathx.import()
print(math.sinh(1))            -- Now available on math table
```

## Extending the Standard Math Library

Call `mathx.import()` to add all MathX functions to Lua's standard `math` table:

```lua
mathx.import()

-- Now use directly on math
print(math.sinh(1))
print(math.mean({1, 2, 3}))
print(math.factorial(5))
```

## API Reference

### Hyperbolic Functions

#### sinh(x)
Hyperbolic sine.

```lua
mathx.sinh(0)    -- 0
mathx.sinh(1)    -- 1.1752011936438
```

#### cosh(x)
Hyperbolic cosine.

```lua
mathx.cosh(0)    -- 1
mathx.cosh(1)    -- 1.5430806348152
```

#### tanh(x)
Hyperbolic tangent.

```lua
mathx.tanh(0)    -- 0
mathx.tanh(1)    -- 0.76159415595576
```

#### asinh(x)
Inverse hyperbolic sine (area hyperbolic sine).

```lua
mathx.asinh(0)                  -- 0
mathx.asinh(mathx.sinh(1))      -- 1
```

#### acosh(x)
Inverse hyperbolic cosine. Requires x >= 1.

```lua
mathx.acosh(1)                  -- 0
mathx.acosh(mathx.cosh(2))      -- 2
```

#### atanh(x)
Inverse hyperbolic tangent. Requires -1 < x < 1.

```lua
mathx.atanh(0)                  -- 0
mathx.atanh(0.5)                -- 0.54930614433405
```

### Rounding Functions

#### round(x, decimals?)
Rounds to nearest integer, or to specified decimal places.

```lua
mathx.round(3.7)        -- 4
mathx.round(3.2)        -- 3
mathx.round(-2.5)       -- -2 (rounds toward positive infinity)

-- With decimal places
mathx.round(3.14159, 2)  -- 3.14
mathx.round(3.14159, 4)  -- 3.1416
mathx.round(1234.5, -2)  -- 1200 (negative decimals)
```

#### trunc(x)
Truncates toward zero (removes decimal part).

```lua
mathx.trunc(3.7)     -- 3
mathx.trunc(-3.7)    -- -3 (toward zero, not floor)
mathx.trunc(3.2)     -- 3
```

#### sign(x)
Returns the sign of a number: 1, -1, or 0.

```lua
mathx.sign(42)      -- 1
mathx.sign(-17)     -- -1
mathx.sign(0)       -- 0
```

### Logarithm Functions

#### log10(x)
Base-10 logarithm. Requires x > 0.

```lua
mathx.log10(10)      -- 1
mathx.log10(100)     -- 2
mathx.log10(1000)    -- 3
mathx.log10(1)       -- 0
```

#### log2(x)
Base-2 logarithm. Requires x > 0.

```lua
mathx.log2(2)        -- 1
mathx.log2(8)        -- 3
mathx.log2(1024)     -- 10
mathx.log2(1)        -- 0
```

### Statistics Functions

All statistics functions take an array of numbers as their first argument.

#### sum(array)
Sum of all elements.

```lua
mathx.sum({1, 2, 3, 4, 5})     -- 15
mathx.sum({10, 20, 30})        -- 60
mathx.sum({-1, 1})             -- 0
```

#### mean(array)
Arithmetic mean (average).

```lua
mathx.mean({1, 2, 3, 4, 5})    -- 3
mathx.mean({10, 20})           -- 15
mathx.mean({2, 4, 6, 8})       -- 5
```

#### median(array)
Middle value when sorted. For even-length arrays, returns average of middle two.

```lua
mathx.median({1, 2, 3, 4, 5})  -- 3
mathx.median({1, 2, 3, 4})     -- 2.5 (average of 2 and 3)
mathx.median({7, 1, 3})        -- 3 (sorted: 1, 3, 7)
```

#### variance(array)
Population variance (mean of squared deviations from mean).

```lua
mathx.variance({1, 2, 3, 4, 5})   -- 2
mathx.variance({2, 4, 4, 4, 5, 5, 7, 9})  -- 4
```

#### stddev(array)
Population standard deviation (square root of variance).

```lua
mathx.stddev({1, 2, 3, 4, 5})     -- 1.4142135623731
mathx.stddev({2, 4, 4, 4, 5, 5, 7, 9})   -- 2
```

#### percentile(array, p)
Returns the p-th percentile (0-100) using linear interpolation.

```lua
local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

mathx.percentile(data, 0)      -- 1 (minimum)
mathx.percentile(data, 50)     -- 5.5 (median)
mathx.percentile(data, 100)    -- 10 (maximum)
mathx.percentile(data, 25)     -- 3.25 (first quartile)
mathx.percentile(data, 75)     -- 7.75 (third quartile)
```

### Special Functions

#### factorial(n)
Factorial of non-negative integer. Maximum n is 20.

```lua
mathx.factorial(0)     -- 1
mathx.factorial(1)     -- 1
mathx.factorial(5)     -- 120 (5! = 5*4*3*2*1)
mathx.factorial(10)    -- 3628800
mathx.factorial(20)    -- 2432902008176640000
```

#### gamma(x)
Gamma function. For positive integers, gamma(n) = (n-1)!

```lua
mathx.gamma(1)         -- 1
mathx.gamma(5)         -- 24 (same as 4!)
mathx.gamma(0.5)       -- 1.7724538509055 (sqrt(pi))
```

#### lgamma(x)
Natural logarithm of the absolute value of the gamma function.

```lua
mathx.lgamma(1)        -- 0
mathx.lgamma(5)        -- 3.1780538303479 (ln(24))
mathx.lgamma(100)      -- 359.13420536958
```

### Coordinate Conversions

#### polar_to_cart(r, theta)
Converts polar coordinates (r, θ) to Cartesian (x, y).

**Parameters:**
- `r` - Radius (distance from origin)
- `theta` - Angle in radians (from positive x-axis)

**Returns:** Array `{x, y}`

```lua
local result = mathx.polar_to_cart(5, math.pi/4)
-- result[1] ≈ 3.536 (x)
-- result[2] ≈ 3.536 (y)

local xy = mathx.polar_to_cart(1, 0)
-- {1, 0} -- unit vector along x-axis
```

#### cart_to_polar(x, y)
Converts Cartesian coordinates (x, y) to polar (r, θ).

**Returns:** Array `{r, theta}` where theta is in radians (-π to π)

```lua
local result = mathx.cart_to_polar(3, 4)
-- result[1] = 5 (r)
-- result[2] ≈ 0.927 (theta, about 53°)

local polar = mathx.cart_to_polar(1, 1)
-- {1.414..., 0.785...} -- r=√2, θ=π/4
```

#### spherical_to_cart(r, theta, phi)
Converts spherical coordinates to 3D Cartesian.

**Parameters:**
- `r` - Radius (distance from origin)
- `theta` - Azimuthal angle in radians (from x-axis in xy-plane)
- `phi` - Polar angle in radians (from z-axis)

**Returns:** Array `{x, y, z}`

```lua
local result = mathx.spherical_to_cart(1, 0, math.pi/2)
-- {1, 0, 0} -- on x-axis

local xyz = mathx.spherical_to_cart(1, math.pi/2, math.pi/2)
-- {0, 1, 0} -- on y-axis
```

#### cart_to_spherical(x, y, z)
Converts 3D Cartesian to spherical coordinates.

**Returns:** Array `{r, theta, phi}`

```lua
local result = mathx.cart_to_spherical(1, 0, 0)
-- {1, 0, π/2} -- r=1, on x-axis

local sph = mathx.cart_to_spherical(0, 0, 5)
-- {5, 0, 0} -- r=5, on z-axis (phi=0)
```

### Constants

#### phi
The golden ratio (φ ≈ 1.618033988749895).

```lua
print(mathx.phi)                    -- 1.618033988749895
print(1 / mathx.phi)                -- 0.618... (φ - 1)
print(mathx.phi * mathx.phi)        -- 2.618... (φ + 1)
```

#### inf
Positive infinity.

```lua
print(mathx.inf)           -- inf
print(mathx.inf + 1)       -- inf
print(1 / mathx.inf)       -- 0
print(mathx.inf > 1e308)   -- true
```

#### nan
Not a Number (NaN).

```lua
print(mathx.nan)           -- nan
print(mathx.nan == mathx.nan)  -- false (NaN never equals itself)
```

## Common Patterns

### Data Analysis

```lua
local scores = {85, 90, 78, 92, 88, 76, 95, 89}

print("Count:", #scores)
print("Sum:", mathx.sum(scores))
print("Mean:", mathx.mean(scores))
print("Median:", mathx.median(scores))
print("Std Dev:", mathx.stddev(scores))
print("Min (P0):", mathx.percentile(scores, 0))
print("Q1 (P25):", mathx.percentile(scores, 25))
print("Q3 (P75):", mathx.percentile(scores, 75))
print("Max (P100):", mathx.percentile(scores, 100))
```

### Coordinate Transformations

```lua
-- Convert point from polar to Cartesian
local angle = math.rad(45)  -- 45 degrees
local distance = 10
local cart = mathx.polar_to_cart(distance, angle)
print(string.format("x=%.2f, y=%.2f", cart[1], cart[2]))

-- Round-trip conversion
local polar = mathx.cart_to_polar(cart[1], cart[2])
print(string.format("r=%.2f, theta=%.2f rad", polar[1], polar[2]))
```

### Scientific Calculations

```lua
-- Combinations: C(n,k) = n! / (k! * (n-k)!)
local function combinations(n, k)
    return mathx.factorial(n) /
           (mathx.factorial(k) * mathx.factorial(n - k))
end

print(combinations(10, 3))  -- 120

-- Using gamma for non-integer factorials
print(mathx.gamma(4.5))  -- Γ(4.5) ≈ 11.63
```

## See Also

- ``MathXModule``
- ``ComplexModule``
- ``LinAlgModule``
- ``ArrayModule``
