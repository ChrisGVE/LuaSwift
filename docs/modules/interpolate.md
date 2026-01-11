# Interpolation Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.interpolate` | **Global:** `math.interpolate` (after extend_stdlib)

Provides comprehensive 1D interpolation functions including linear, cubic spline, PCHIP, Akima, Lagrange, and barycentric methods. All interpolators support both real and complex-valued data, and handle scalar or array inputs seamlessly.

## Quick Start

```lua
luaswift.extend_stdlib()

-- Create sample data
local x = {0, 1, 2, 3, 4}
local y = {0, 1, 4, 9, 16}

-- Linear interpolation
local f = math.interpolate.interp1d(x, y, "linear")
print(f(1.5))  -- 2.5

-- Cubic spline with derivatives and integration
local cs = math.interpolate.CubicSpline(x, y)
print(cs(1.5))               -- interpolated value
print(cs.derivative(1.5))    -- first derivative
print(cs.integrate(0, 4))    -- definite integral
```

## General Purpose Interpolation

### interp1d

Creates a 1D interpolation function with multiple interpolation kinds.

```lua
f = math.interpolate.interp1d(x, y, kind, options)
```

**Parameters:**
- `x`: array of x coordinates (must be strictly increasing)
- `y`: array of y values (real or complex)
- `kind`: interpolation type (default: `"linear"`)
  - `"linear"`: linear interpolation
  - `"nearest"`: nearest neighbor
  - `"cubic"`: natural cubic spline
  - `"previous"`: previous value (step function)
  - `"next"`: next value (step function)
- `options`: optional table with:
  - `fill_value`: value for extrapolation (default: NaN)
  - `bounds_error`: if true, raises error on extrapolation (default: false)

**Returns:** function `f(x_new)` that accepts scalar or array input

**Examples:**

```lua
-- Linear interpolation
local x = {0, 1, 2, 3}
local y = {0, 2, 4, 6}
local f = math.interpolate.interp1d(x, y, "linear")
print(f(1.5))  -- 3.0

-- Cubic interpolation with custom fill value
local f_cubic = math.interpolate.interp1d(x, y, "cubic", {fill_value = 0})
print(f_cubic(5))  -- 0 (outside bounds)

-- Nearest neighbor
local f_nearest = math.interpolate.interp1d(x, y, "nearest")
print(f_nearest(1.4))  -- 2 (closer to x[2]=1)
print(f_nearest(1.6))  -- 4 (closer to x[3]=2)

-- Complex-valued interpolation
local y_complex = {{re=1, im=0}, {re=0, im=1}, {re=-1, im=0}}
local f_cplx = math.interpolate.interp1d({0, 1, 2}, y_complex, "linear")
local result = f_cplx(0.5)  -- {re=0.5, im=0.5}

-- Array input
local x_new = {0.5, 1.5, 2.5}
local y_new = f(x_new)  -- {1.0, 3.0, 5.0}

-- Bounds error
local f_strict = math.interpolate.interp1d(x, y, "linear", {bounds_error = true})
-- f_strict(5)  -- raises error: outside interpolation range
```

## Cubic Spline Interpolation

### CubicSpline

Creates a cubic spline interpolator with support for derivatives and integration.

```lua
spline = math.interpolate.CubicSpline(x, y, options)
```

**Parameters:**
- `x`: array of x coordinates (must be strictly increasing)
- `y`: array of y values (real or complex)
- `options`: optional table with:
  - `bc_type`: boundary condition type (default: `"not-a-knot"`)
    - `"natural"`: second derivative is zero at endpoints
    - `"clamped"`: first derivative is zero at endpoints
    - `"not-a-knot"`: third derivative continuous at second and penultimate points
  - `extrapolate`: if true, extrapolate linearly outside bounds (default: true)

**Returns:** spline object with methods:
- `spline(x_new)`: evaluate at x_new (scalar or array)
- `spline.derivative(x_new, nu)`: nu-th derivative (nu=1,2,3; default: 1)
- `spline.integrate(a, b)`: definite integral from a to b

**Examples:**

```lua
-- Basic cubic spline
local x = {0, 1, 2, 3, 4}
local y = {0, 1, 4, 9, 16}
local cs = math.interpolate.CubicSpline(x, y)
print(cs(1.5))  -- smooth interpolated value

-- Natural boundary conditions
local cs_natural = math.interpolate.CubicSpline(x, y, {bc_type = "natural"})

-- Derivatives
print(cs.derivative(2))      -- first derivative at x=2
print(cs.derivative(2, 2))   -- second derivative at x=2
print(cs.derivative(2, 3))   -- third derivative at x=2 (constant for cubic)

-- Integration
print(cs.integrate(0, 4))    -- ∫f(x)dx from 0 to 4

-- Disable extrapolation
local cs_no_extrap = math.interpolate.CubicSpline(x, y, {extrapolate = false})
print(cs_no_extrap(5))  -- NaN (outside bounds)

-- Complex-valued spline
local y_c = {{re=0,im=1}, {re=1,im=0}, {re=0,im=-1}, {re=-1,im=0}}
local cs_complex = math.interpolate.CubicSpline({0, 1, 2, 3}, y_c)
local val = cs_complex(1.5)  -- {re=..., im=...}
local deriv = cs_complex.derivative(1.5)  -- complex derivative
local integral = cs_complex.integrate(0, 3)  -- complex integral
```

## Monotonic Interpolation

### PchipInterpolator

Piecewise Cubic Hermite Interpolating Polynomial. Preserves monotonicity of data and avoids overshoots.

```lua
f = math.interpolate.PchipInterpolator(x, y)
```

**Parameters:**
- `x`: array of x coordinates (must be strictly increasing)
- `y`: array of y values

**Returns:** interpolation function `f(x_new)` with linear extrapolation

**Example:**

```lua
-- Monotonic data
local x = {0, 1, 2, 3, 4}
local y = {0, 1, 3, 5, 6}
local pchip = math.interpolate.PchipInterpolator(x, y)

-- PCHIP preserves monotonicity (no overshoots)
for i = 0, 40 do
    local xi = i * 0.1
    print(xi, pchip(xi))
end

-- Compare with cubic spline (may overshoot)
local cs = math.interpolate.CubicSpline(x, y)
-- cs may produce values > 6 or < 0 in some intervals
```

### Akima1DInterpolator

Akima interpolation. Smooth interpolation that avoids overshoots using weighted differences.

```lua
f = math.interpolate.Akima1DInterpolator(x, y)
```

**Parameters:**
- `x`: array of x coordinates (must be strictly increasing)
- `y`: array of y values

**Returns:** interpolation function `f(x_new)` with linear extrapolation

**Example:**

```lua
-- Data with sharp features
local x = {0, 1, 2, 3, 4, 5}
local y = {0, 0, 1, 1, 0, 0}
local akima = math.interpolate.Akima1DInterpolator(x, y)

-- Akima produces smooth curves without excessive oscillation
print(akima(1.5))  -- smooth transition
print(akima(2.5))  -- smooth transition

-- Array evaluation
local x_fine = {}
for i = 0, 50 do x_fine[i+1] = i * 0.1 end
local y_fine = akima(x_fine)
```

## Polynomial Interpolation

### lagrange

Lagrange polynomial interpolation. Exact for polynomials of degree ≤ n-1.

```lua
f = math.interpolate.lagrange(x, y)
```

**Parameters:**
- `x`: array of x coordinates
- `y`: array of y values (real or complex)

**Returns:** polynomial interpolation function

**Warning:** Numerically unstable for large n (>10 points). Use `BarycentricInterpolator` for better stability.

**Example:**

```lua
-- Interpolate through 4 points with a cubic polynomial
local x = {0, 1, 2, 3}
local y = {1, 3, 2, 5}
local poly = math.interpolate.lagrange(x, y)

-- Exact at data points
print(poly(1))   -- 3.0

-- Interpolated between points
print(poly(1.5)) -- polynomial evaluation

-- Complex polynomial
local y_c = {{re=1,im=0}, {re=0,im=1}, {re=-1,im=0}}
local poly_c = math.interpolate.lagrange({0, 1, 2}, y_c)
print(poly_c(0.5).re, poly_c(0.5).im)
```

### BarycentricInterpolator

Barycentric Lagrange interpolation. More numerically stable than standard Lagrange for large n.

```lua
f = math.interpolate.BarycentricInterpolator(x, y)
```

**Parameters:**
- `x`: array of x coordinates
- `y`: array of y values (real or complex)

**Returns:** interpolation function with improved numerical stability

**Example:**

```lua
-- Large number of points
local x = {}
local y = {}
for i = 1, 20 do
    x[i] = i
    y[i] = math.sin(i)
end

-- Barycentric is more stable than Lagrange
local f_bary = math.interpolate.BarycentricInterpolator(x, y)
print(f_bary(10.5))

-- Standard Lagrange may have numerical issues with 20 points
local f_lag = math.interpolate.lagrange(x, y)
-- f_lag(10.5) may be less accurate due to roundoff
```

## Complex-Valued Interpolation

All interpolation methods support complex numbers:

```lua
-- Complex data
local x = {0, 1, 2, 3}
local y = {
    {re = 1, im = 0},
    {re = 0, im = 1},
    {re = -1, im = 0},
    {re = 0, im = -1}
}

-- All methods work with complex data
local f_linear = math.interpolate.interp1d(x, y, "linear")
local f_cubic = math.interpolate.interp1d(x, y, "cubic")
local f_pchip = math.interpolate.PchipInterpolator(x, y)
local f_akima = math.interpolate.Akima1DInterpolator(x, y)
local f_lagrange = math.interpolate.lagrange(x, y)
local f_bary = math.interpolate.BarycentricInterpolator(x, y)

-- Evaluate
local val = f_linear(1.5)  -- {re = -0.5, im = 0.5}

-- Cubic spline with complex derivatives
local cs = math.interpolate.CubicSpline(x, y)
local val = cs(1.5)              -- complex value
local deriv = cs.derivative(1.5) -- complex derivative
local integ = cs.integrate(0, 3) -- complex integral
```

## Choosing an Interpolation Method

| Method | Best For | Smoothness | Monotonicity | Overshoot | Performance |
|--------|----------|------------|--------------|-----------|-------------|
| `linear` | Simple, fast interpolation | C⁰ | Preserved | None | Fastest |
| `nearest` | Step-wise data | Discontinuous | N/A | None | Fastest |
| `cubic` | Smooth curves | C² | Not preserved | Possible | Fast |
| `PchipInterpolator` | Monotonic data | C¹ | Preserved | None | Medium |
| `Akima1DInterpolator` | Smooth without overshoot | C¹ | Not strictly preserved | Minimal | Medium |
| `lagrange` | Few points (<10), exact polynomial | C^∞ | Not preserved | High | Slow, unstable |
| `BarycentricInterpolator` | More points (10-20), exact polynomial | C^∞ | Not preserved | High | Medium, more stable |

**Recommendations:**
- **General purpose:** Use `interp1d` with `kind="linear"` or `"cubic"`
- **Monotonic data:** Use `PchipInterpolator` or `Akima1DInterpolator`
- **Smooth derivatives needed:** Use `CubicSpline` with appropriate boundary conditions
- **Exact polynomial fit:** Use `BarycentricInterpolator` for better stability than `lagrange`
- **Complex-valued functions:** All methods support complex numbers transparently

## Function Reference

| Function | Description |
|----------|-------------|
| `interp1d(x, y, kind, options)` | General 1D interpolation with multiple methods |
| `CubicSpline(x, y, options)` | Cubic spline with derivatives and integration |
| `PchipInterpolator(x, y)` | Monotonic piecewise cubic Hermite interpolation |
| `Akima1DInterpolator(x, y)` | Smooth Akima interpolation without overshoots |
| `lagrange(x, y)` | Lagrange polynomial interpolation |
| `BarycentricInterpolator(x, y)` | Numerically stable barycentric interpolation |
