# MathX Module

Extended math functions beyond Lua's standard math library.

## Overview

The MathX module provides comprehensive mathematical functions including hyperbolic functions, advanced rounding, statistics, special functions, combinatorics, coordinate conversions, complex-dispatch transcendentals, and additional constants. These extend Lua's built-in `math` library with Swift-powered implementations.

## Installation

```swift
// Install all modules
try ModuleRegistry.install(in: engine)

// Or install just the MathX module
try MathXModule.install(in: engine)
```

The MathX module is included in the default build and requires no opt-in flags.

## Basic Usage

```lua
local mathx = require("luaswift.mathx")
-- Alias: require("luaswift.math") is also valid

-- Hyperbolic functions
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
print(math.comb(10, 3))
```

## API Reference

### Hyperbolic Functions

All hyperbolic functions accept real or complex inputs. For complex `z = a + bi`, the appropriate complex formula is applied and a complex table `{re=..., im=...}` is returned.

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
Inverse hyperbolic cosine. For real `x >= 1`, returns a real result. For real `x < 1`, returns a complex result `{re=0, im=acos(x)}`.

```lua
mathx.acosh(1)                  -- 0
mathx.acosh(mathx.cosh(2))      -- 2
```

#### atanh(x)
Inverse hyperbolic tangent. For real `|x| < 1`, returns a real result. For `x = 1` returns `inf`, for `x = -1` returns `-inf`. For `|x| > 1`, returns a complex result.

```lua
mathx.atanh(0)                  -- 0
mathx.atanh(0.5)                -- 0.54930614433405
```

### Complex-Dispatch Transcendentals

These functions accept both real numbers and complex tables `{re=..., im=...}`. When passed a real number they return a real number. When passed a complex value they return a complex table.

#### sin(x)
Sine with complex dispatch. `sin(a+bi) = sin(a)cosh(b) + i·cos(a)sinh(b)`

```lua
mathx.sin(0)            -- 0
mathx.sin(math.pi / 2)  -- 1
```

#### cos(x)
Cosine with complex dispatch. `cos(a+bi) = cos(a)cosh(b) - i·sin(a)sinh(b)`

```lua
mathx.cos(0)            -- 1
mathx.cos(math.pi)      -- -1
```

#### tan(x)
Tangent with complex dispatch.

```lua
mathx.tan(0)            -- 0
mathx.tan(math.pi / 4)  -- 1
```

#### exp(x)
Exponential with complex dispatch. `exp(a+bi) = e^a·(cos(b) + i·sin(b))`

```lua
mathx.exp(0)   -- 1
mathx.exp(1)   -- 2.718281828459 (e)
```

#### log(x)
Natural logarithm with complex dispatch. `log(z) = ln|z| + i·arg(z)`

```lua
mathx.log(1)   -- 0
mathx.log(math.exp(1))  -- 1
```

#### sqrt(x)
Square root with complex dispatch. Returns a complex table when given a complex input; returns a real number for non-negative real input.

```lua
mathx.sqrt(4)   -- 2
mathx.sqrt(9)   -- 3
```

### Rounding Functions

#### round(x, decimals?)
Rounds to the nearest integer, or to the specified number of decimal places. Uses **round-half-away-from-zero** (standard C `round` semantics): 0.5 rounds to 1, -0.5 rounds to -1, -2.5 rounds to -3.

```lua
mathx.round(3.7)        -- 4
mathx.round(3.2)        -- 3
mathx.round(-2.5)       -- -3 (half rounds away from zero)

-- With decimal places
mathx.round(3.14159, 2)  -- 3.14
mathx.round(3.14159, 4)  -- 3.1416
mathx.round(1234.5, -2)  -- 1200 (negative decimals round to hundreds)
```

#### trunc(x)
Truncates toward zero (removes the decimal part).

```lua
mathx.trunc(3.7)     -- 3
mathx.trunc(-3.7)    -- -3 (toward zero, not floor)
mathx.trunc(3.2)     -- 3
```

#### sign(x)
Returns the sign of a number: `1`, `-1`, or `0`.

```lua
mathx.sign(42)      -- 1
mathx.sign(-17)     -- -1
mathx.sign(0)       -- 0
```

### Logarithm Functions

#### log10(x)
Base-10 logarithm. For negative real input, returns a complex result.

```lua
mathx.log10(10)      -- 1
mathx.log10(100)     -- 2
mathx.log10(1000)    -- 3
mathx.log10(1)       -- 0
```

#### log2(x)
Base-2 logarithm. For negative real input, returns a complex result.

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
Middle value when sorted. For even-length arrays, returns the average of the two middle values.

```lua
mathx.median({1, 2, 3, 4, 5})  -- 3
mathx.median({1, 2, 3, 4})     -- 2.5 (average of 2 and 3)
mathx.median({7, 1, 3})        -- 3 (sorted: 1, 3, 7)
```

#### variance(array, ddof?)
Population variance by default (`ddof=0`). Pass `ddof=1` for sample variance (Bessel's correction).

**Parameters:**
- `array` - Array of numbers
- `ddof` (optional, default `0`) - Delta degrees of freedom. `0` = population variance, `1` = sample variance.

```lua
-- Population variance (ddof=0, default)
mathx.variance({1, 2, 3, 4, 5})       -- 2.0
mathx.variance({2, 4, 4, 4, 5, 5, 7, 9})  -- 4.0

-- Sample variance (ddof=1)
mathx.variance({1, 2, 3, 4, 5}, 1)    -- 2.5
```

#### stddev(array, ddof?)
Population standard deviation by default (`ddof=0`). Pass `ddof=1` for sample standard deviation.

**Parameters:**
- `array` - Array of numbers
- `ddof` (optional, default `0`) - Delta degrees of freedom. `0` = population stddev, `1` = sample stddev.

```lua
-- Population stddev (ddof=0, default): sqrt(variance) = sqrt(2) ≈ 1.4142
mathx.stddev({1, 2, 3, 4, 5})         -- 1.4142135623731
mathx.stddev({2, 4, 4, 4, 5, 5, 7, 9})    -- 2.0

-- Sample stddev (ddof=1): sqrt(2.5) ≈ 1.5811
mathx.stddev({1, 2, 3, 4, 5}, 1)      -- 1.5811388300842
```

#### percentile(array, p)
Returns the p-th percentile (0–100) using linear interpolation.

```lua
local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

mathx.percentile(data, 0)      -- 1   (minimum)
mathx.percentile(data, 50)     -- 5.5 (median)
mathx.percentile(data, 100)    -- 10  (maximum)
mathx.percentile(data, 25)     -- 3.25 (first quartile)
mathx.percentile(data, 75)     -- 7.75 (third quartile)
```

#### gmean(array)
Geometric mean: the nth root of the product of n positive values. All values must be strictly positive.

```lua
mathx.gmean({1, 2, 4})        -- 2.0  (∛8 = 2)
mathx.gmean({1, 10, 100})     -- 10.0
```

#### hmean(array)
Harmonic mean: `n / Σ(1/xᵢ)`. All values must be strictly positive.

```lua
mathx.hmean({1, 2, 4})        -- 1.7142857142857 (3 / (1 + 0.5 + 0.25))
mathx.hmean({60, 40})         -- 48.0
```

#### mode(array)
Most frequently occurring value. If there is a tie, returns the smallest tied value.

```lua
mathx.mode({1, 2, 2, 3, 4})   -- 2
mathx.mode({1, 1, 2, 2, 3})   -- 1 (tie: smallest returned)
mathx.mode({5})               -- 5
```

### Combinatorics

#### perm(n, k)
Permutations P(n, k) = n! / (n−k)!  — the number of ordered selections of k items from n.

**Parameters:**
- `n` - Total number of items (non-negative integer)
- `k` - Number to select (non-negative integer ≤ n)

```lua
mathx.perm(5, 2)    -- 20  (5 * 4)
mathx.perm(10, 3)   -- 720 (10 * 9 * 8)
mathx.perm(5, 0)    -- 1
mathx.perm(3, 5)    -- 0   (k > n)
```

#### comb(n, k)
Combinations C(n, k) = n! / (k! · (n−k)!)  — the number of unordered selections of k items from n. Also available as `binomial(n, k)`.

**Parameters:**
- `n` - Total number of items (non-negative integer)
- `k` - Number to select (non-negative integer ≤ n)

```lua
mathx.comb(5, 2)     -- 10
mathx.comb(10, 3)    -- 120
mathx.comb(5, 0)     -- 1
mathx.comb(5, 5)     -- 1
mathx.comb(3, 5)     -- 0   (k > n)

-- binomial is an alias for comb
mathx.binomial(6, 3) -- 20
```

### Special Functions

#### factorial(n)
Factorial of a non-negative integer. For `n <= 20`, computed exactly. For `n > 20`, computed via `exp(lgamma(n+1))`.

```lua
mathx.factorial(0)     -- 1
mathx.factorial(1)     -- 1
mathx.factorial(5)     -- 120
mathx.factorial(10)    -- 3628800
mathx.factorial(20)    -- 2432902008176640000
mathx.factorial(25)    -- 1.5511210043331e+25 (approximate for n > 20)
```

#### gamma(x)
Gamma function. For positive integers, `gamma(n) = (n-1)!`

```lua
mathx.gamma(1)         -- 1
mathx.gamma(5)         -- 24  (= 4!)
mathx.gamma(0.5)       -- 1.7724538509055 (√π)
```

#### lgamma(x)
Natural logarithm of the absolute value of the gamma function.

```lua
mathx.lgamma(1)        -- 0
mathx.lgamma(5)        -- 3.1780538303479 (ln 24)
mathx.lgamma(100)      -- 359.13420536958
```

### Complex-Only Functions

These functions always return a complex table `{re=..., im=...}` regardless of input type.

#### csqrt(z)
Complex square root that always returns a complex table. For positive real `x`, returns `{re=√x, im=0}`. For negative real `x`, returns `{re=0, im=√|x|}`.

```lua
local c = require("luaswift.complex")

local z = mathx.csqrt(-4)    -- {re=0, im=2}
local w = mathx.csqrt(c.new(0, 1))  -- sqrt(i)
```

#### clog(z)
Complex natural logarithm that always returns a complex table. `clog(z) = ln|z| + i·arg(z)`. For negative real `x`, returns `{re=ln|x|, im=π}`.

```lua
local lnNeg = mathx.clog(-1)   -- {re=0, im=π}
local lnPos = mathx.clog(1)    -- {re=0, im=0}
```

### Coordinate Conversions

#### polar_to_cart(r, theta)
Converts polar coordinates (r, θ) to Cartesian (x, y).

**Parameters:**
- `r` - Radius (distance from origin)
- `theta` - Angle in radians (from positive x-axis)

**Returns:** Array `{x, y}`

```lua
local result = mathx.polar_to_cart(5, math.pi / 4)
-- result[1] ≈ 3.536 (x)
-- result[2] ≈ 3.536 (y)

local xy = mathx.polar_to_cart(1, 0)
-- {1, 0}  -- unit vector along x-axis
```

#### cart_to_polar(x, y)
Converts Cartesian coordinates (x, y) to polar (r, θ).

**Returns:** Array `{r, theta}` where theta is in radians (−π to π)

```lua
local result = mathx.cart_to_polar(3, 4)
-- result[1] = 5       (r)
-- result[2] ≈ 0.927   (theta, about 53°)

local polar = mathx.cart_to_polar(1, 1)
-- {1.4142..., 0.7854...}  -- r=√2, θ=π/4
```

#### spherical_to_cart(r, theta, phi)
Converts spherical coordinates to 3D Cartesian using the physics/mathematics convention: theta is the azimuthal angle (from the x-axis in the xy-plane) and phi is the polar angle (from the z-axis).

**Parameters:**
- `r` - Radius (distance from origin)
- `theta` - Azimuthal angle in radians (from x-axis in xy-plane)
- `phi` - Polar angle in radians (from z-axis)

**Returns:** Array `{x, y, z}`

```lua
local result = mathx.spherical_to_cart(1, 0, math.pi / 2)
-- {1, 0, 0}   -- on x-axis

local xyz = mathx.spherical_to_cart(1, math.pi / 2, math.pi / 2)
-- {0, 1, 0}   -- on y-axis
```

#### cart_to_spherical(x, y, z)
Converts 3D Cartesian to spherical coordinates.

**Returns:** Array `{r, theta, phi}`

```lua
local result = mathx.cart_to_spherical(1, 0, 0)
-- {1, 0, π/2}  -- r=1, on x-axis

local sph = mathx.cart_to_spherical(0, 0, 5)
-- {5, 0, 0}    -- r=5, on z-axis (phi=0)
```

### Constants

#### phi
The golden ratio (φ ≈ 1.618033988749895).

```lua
print(mathx.phi)              -- 1.618033988749895
print(1 / mathx.phi)          -- 0.618... (φ − 1)
print(mathx.phi * mathx.phi)  -- 2.618... (φ + 1)
```

#### inf
Positive infinity.

```lua
print(mathx.inf)             -- inf
print(mathx.inf + 1)         -- inf
print(1 / mathx.inf)         -- 0
print(mathx.inf > 1e308)     -- true
```

#### nan
Not a Number (NaN).

```lua
print(mathx.nan)                    -- nan
print(mathx.nan == mathx.nan)       -- false (NaN never equals itself)
```

## Common Patterns

### Data Analysis

```lua
local scores = {85, 90, 78, 92, 88, 76, 95, 89}

print("Count:", #scores)
print("Sum:", mathx.sum(scores))
print("Mean:", mathx.mean(scores))
print("Median:", mathx.median(scores))
print("Std Dev (population):", mathx.stddev(scores))
print("Std Dev (sample):", mathx.stddev(scores, 1))
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

### Combinatorics and Probability

```lua
-- Combinations and permutations
print(mathx.comb(52, 5))    -- 2598960 (poker hands)
print(mathx.perm(10, 3))    -- 720 (ordered selections)

-- Geometric and harmonic means
local growth = {1.10, 1.05, 1.08, 1.12}
print(mathx.gmean(growth))  -- compound growth factor

-- Mode for categorical data
local responses = {3, 5, 3, 4, 3, 5, 2}
print(mathx.mode(responses))  -- 3 (most frequent)
```

### Scientific Calculations

```lua
-- Using gamma for non-integer factorials
print(mathx.gamma(4.5))   -- Γ(4.5) ≈ 11.6317

-- Large factorials via lgamma to avoid overflow
local log_n_fact = mathx.lgamma(1001)  -- ln(1000!)
print(log_n_fact)

-- Hyperbolic and complex dispatch
local c = require("luaswift.complex")
local z = c.new(1, 2)     -- 1 + 2i
print(mathx.sin(z).re)    -- real part of sin(1+2i)
print(mathx.exp(z).re)    -- real part of e^(1+2i)
```

## See Also

- ``MathXModule``
- ``ComplexModule``
- ``LinAlgModule``
- ``ArrayModule``
