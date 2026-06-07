# Interpolate Module

Spline and polynomial interpolation methods modelled after `scipy.interpolate`.

## Overview

The Interpolate module provides 1D interpolation, cubic splines, PCHIP, Akima, Lagrange, and barycentric interpolation. All heavy computation is performed in Swift via the NumericSwift library; the Lua layer is a thin binding.

Functions are available under `math.interpolate` (and also `luaswift.interpolate`) after calling `luaswift.extend_stdlib()`.

> Important: This module requires the **NumericSwift** optional dependency. It is **disabled by default**. To enable it, build with the `LUASWIFT_INCLUDE_NUMERICSWIFT=1` environment variable:
> ```sh
> LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build
> LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift test
> ```
> If NumericSwift is not included, `math.interpolate` will not be populated and calls to its functions will raise a Lua error.

## Installation

```swift
// Install all modules (includes interpolate when NumericSwift is present)
try ModuleRegistry.install(in: engine)

// Or install the math module group explicitly
try MathXModule.install(in: engine)
```

```lua
luaswift.extend_stdlib()
local interp = math.interpolate
```

## API Reference

### interp1d(x, y, kind?, options?)

Creates a 1D interpolation function from data points. Mirrors `scipy.interpolate.interp1d`.

**Parameters:**
- `x` (array) - Strictly increasing x-coordinates (at least 2 points)
- `y` (array) - Corresponding y-values; may contain complex numbers `{re=..., im=...}`
- `kind` (string, optional) - Interpolation kind: `"linear"` (default), `"nearest"`, `"previous"`, `"next"`, `"cubic"`
- `options` (table, optional):
  - `fill_value` (number) - Value returned outside the data range (default: `NaN`)
  - `bounds_error` (boolean) - If `true`, raise an error when `x_new` is out of range (default: `false`)

**Returns:** A callable function `f(x_new)` where `x_new` may be a number or an array of numbers.

**Example:**

```lua
local interp = math.interpolate

local x = {0, 1, 2, 3, 4}
local y = {0, 1, 4, 9, 16}  -- x^2

-- Linear interpolation (default)
local f = interp.interp1d(x, y)
print(f(1.5))    -- 2.5

-- Nearest-neighbour
local fn = interp.interp1d(x, y, "nearest")
print(fn(1.4))   -- 1

-- Cubic interpolation
local fc = interp.interp1d(x, y, "cubic")
print(fc(2.5))   -- ~6.25

-- Vectorised evaluation
local vals = f({0.5, 1.5, 2.5})  -- returns array

-- Out-of-range behaviour
local fe = interp.interp1d(x, y, "linear", {fill_value = -1, bounds_error = false})
print(fe(5))     -- -1
```

---

### CubicSpline(x, y, options?)

Creates a cubic spline interpolator with configurable boundary conditions. Mirrors `scipy.interpolate.CubicSpline`.

**Parameters:**
- `x` (array) - Strictly increasing x-coordinates (at least 2 points)
- `y` (array) - Corresponding y-values; complex values supported
- `options` (table, optional):
  - `bc_type` (string) - Boundary condition: `"not-a-knot"` (default), `"natural"`, `"clamped"`
  - `extrapolate` (boolean) - Whether to extrapolate outside the data range (default: `true`)

**Returns:** A spline object that is callable and exposes `.derivative()` and `.integrate()`.

#### Spline object methods

| Method | Description |
|--------|-------------|
| `spline(x_new)` | Evaluate the spline at `x_new` (number or array) |
| `spline.derivative(x_new, nu?)` | Evaluate the `nu`-th derivative (default `nu = 1`) |
| `spline.integrate(a, b)` | Definite integral from `a` to `b` |

**Example:**

```lua
local interp = math.interpolate

local x = {0, 1, 2, 3, 4}
local y = {0, 1, 4, 9, 16}  -- x^2

-- Default (not-a-knot) boundary conditions
local cs = interp.CubicSpline(x, y)
print(cs(1.5))               -- ~2.25
print(cs.derivative(2.0))    -- ~4.0  (first derivative of x^2 is 2x)
print(cs.derivative(2.0, 2)) -- ~2.0  (second derivative is 2)
print(cs.integrate(0, 4))    -- ~21.3

-- Natural spline (second derivative = 0 at endpoints)
local nat = interp.CubicSpline(x, y, {bc_type = "natural"})

-- Clamped spline (first derivative fixed at endpoints)
local clamped = interp.CubicSpline(x, y, {bc_type = "clamped"})

-- Vectorised evaluation
local ys = cs({1.0, 1.5, 2.0, 2.5})  -- returns array

-- Disable extrapolation
local cs_noext = interp.CubicSpline(x, y, {extrapolate = false})
```

---

### PchipInterpolator(x, y)

Piecewise Cubic Hermite Interpolating Polynomial (PCHIP). Preserves monotonicity and avoids overshoot. Mirrors `scipy.interpolate.PchipInterpolator`.

**Parameters:**
- `x` (array) - Strictly increasing x-coordinates (at least 2 points)
- `y` (array) - Corresponding y-values

**Returns:** A callable function `f(x_new)` where `x_new` may be a number or an array.

**Example:**

```lua
local interp = math.interpolate

local x = {0, 1, 2, 3, 4}
local y = {0, 2, 2, 3, 3}  -- Monotone plateau

local f = interp.PchipInterpolator(x, y)
print(f(0.5))        -- Stays monotone, no overshoot
print(f(1.5))        -- ~2.0

-- Vectorised
local vals = f({0.25, 0.75, 1.25})
```

---

### Akima1DInterpolator(x, y)

Akima spline interpolation, which is less sensitive to outliers than a standard cubic spline. Mirrors `scipy.interpolate.Akima1DInterpolator`.

**Parameters:**
- `x` (array) - Strictly increasing x-coordinates (at least 2 points)
- `y` (array) - Corresponding y-values

**Returns:** A callable function `f(x_new)` where `x_new` may be a number or an array.

**Example:**

```lua
local interp = math.interpolate

local time  = {0, 3, 6, 9, 12, 15, 18, 21, 24}
local temp  = {15, 14, 13, 16, 22, 25, 21, 18, 16}

local f = interp.Akima1DInterpolator(time, temp)
print(f(10.5))   -- Smooth estimate at 10:30

-- Vectorised
local t_dense = {}
for i = 0, 240 do t_dense[i+1] = i / 10 end
local t_smooth = f(t_dense)
```

---

### lagrange(x, y)

Lagrange polynomial interpolation through all supplied points. Mirrors `scipy.interpolate.lagrange`. Complex y-values are supported.

> Warning: High-degree polynomials exhibit Runge's phenomenon (oscillation near the edges). For more than a handful of points, prefer `CubicSpline`, `PchipInterpolator`, or `BarycentricInterpolator`.

**Parameters:**
- `x` (array) - x-coordinates
- `y` (array) - Corresponding y-values; complex values `{re=..., im=...}` supported

**Returns:** A callable function `f(x_new)` where `x_new` may be a number or an array.

**Example:**

```lua
local interp = math.interpolate

local x = {-1, 0, 1}
local y = {1, 0, 1}   -- x^2

local poly = interp.lagrange(x, y)
print(poly(0.5))   -- 0.25

-- Vectorised
local vals = poly({-0.5, 0, 0.5})
```

---

### BarycentricInterpolator(x, y)

Numerically stable barycentric form of polynomial interpolation. Mirrors `scipy.interpolate.BarycentricInterpolator`. Complex y-values are supported.

**Parameters:**
- `x` (array) - x-coordinates
- `y` (array) - Corresponding y-values; complex values `{re=..., im=...}` supported

**Returns:** A callable function `f(x_new)` where `x_new` may be a number or an array.

**Example:**

```lua
local interp = math.interpolate

local x = {0, 0.2, 0.4, 0.6, 0.8, 1.0}
local y = {1, 0.96, 0.84, 0.64, 0.36, 0}

local f = interp.BarycentricInterpolator(x, y)
print(f(0.3))    -- Interpolated value at 0.3

-- Vectorised
local dense_x = {}
for i = 0, 100 do dense_x[i+1] = i / 100 end
local dense_y = f(dense_x)
```

## Interpolation Method Guide

| Method | Best For | Continuity | Notes |
|--------|----------|------------|-------|
| `interp1d("linear")` | Fast piecewise lookup | C0 | First-order; no smoothing |
| `interp1d("nearest")` | Step functions | C−1 | Returns value of nearest knot |
| `interp1d("previous")` | Zero-order hold (left) | C−1 | Returns left-knot value |
| `interp1d("next")` | Zero-order hold (right) | C−1 | Returns right-knot value |
| `interp1d("cubic")` | Smooth curves (quick) | C2 | Natural BC; no derivative access |
| `CubicSpline` | Smooth curves (full) | C2 | Configurable BC, derivative, integral |
| `PchipInterpolator` | Monotonic / plateau data | C1 | No overshoot |
| `Akima1DInterpolator` | Data with outliers | C1 | Reduced oscillation |
| `lagrange` | ≤ 5–6 points | C∞ | Runge's phenomenon for many points |
| `BarycentricInterpolator` | Many polynomial points | C∞ | Stable form of Lagrange |

## Applications

### Smooth Curve for Plotting

```lua
local interp = math.interpolate

local x = {0, 1, 2, 3, 4, 5}
local y = {1, 3, 2, 4, 3, 5}

local cs = interp.CubicSpline(x, y)

local x_fine, y_fine = {}, {}
for i = 0, 100 do
    local xi = i * 0.05
    x_fine[i+1] = xi
    y_fine[i+1] = cs(xi)
end
```

### Resampling a Signal

```lua
local interp = math.interpolate

local t_orig  = {0, 10, 20, 30, 40}
local sig     = {5, 15, 10, 20, 18}

local f = interp.PchipInterpolator(t_orig, sig)

-- Resample to 1-unit grid
local t_new, s_new = {}, {}
for i = 0, 40 do
    t_new[i+1] = i
    s_new[i+1] = f(i)
end
```

### Sensor Data with Outlier Resistance

```lua
local interp = math.interpolate

local t    = {0, 1, 2, 3, 4, 5, 6}
local data = {0.1, 0.9, 4.1, 8.8, 16.2, 25.0, 36.1}

-- Akima is robust when a few knots deviate from the trend
local f = interp.Akima1DInterpolator(t, data)
print(f(2.5))
```

### Spline Derivative and Integral

```lua
local interp = math.interpolate

local x = {0, 1, 2, 3, 4}
local y = {0, 1, 4, 9, 16}   -- approximately x^2

local cs = interp.CubicSpline(x, y)

-- First and second derivatives
print(cs.derivative(2.0, 1))  -- ~4.0  (2x at x=2)
print(cs.derivative(2.0, 2))  -- ~2.0  (constant 2 for x^2)

-- Definite integral  ∫₀⁴ x² dx ≈ 21.33
print(cs.integrate(0, 4))
```

## Performance Notes

- Interpolator construction is O(n) for all methods.
- Evaluation uses binary search and is O(log n) per query.
- Pass an array to `f({...})` rather than calling `f` in a loop; the vectorised path avoids repeated Lua-to-Swift crossings.
- Reuse the interpolator object; do not reconstruct it inside tight loops.

## Error Handling

```lua
local interp = math.interpolate

local ok, err = pcall(function()
    -- Requires at least 2 points
    interp.CubicSpline({1}, {1})
end)
if not ok then print("Error:", err) end

-- Out-of-range with bounds_error = true
local f = interp.interp1d({0,1,2}, {0,1,4}, "linear", {bounds_error = true})
local ok2, err2 = pcall(function() return f(5) end)
if not ok2 then print("Range error:", err2) end
```

## See Also

- ``InterpolateModule``
- <doc:IntegrateModule>
- <doc:ArrayModule>
