# Interpolate Module

Spline and polynomial interpolation.

## Overview

The Interpolate module provides various interpolation methods for constructing continuous functions from discrete data points. Available under `math.interpolate` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local interp = math.interpolate
```

## Linear Interpolation

### interp.linear(x, y)
Create a piecewise linear interpolator.

```lua
local x = {0, 1, 2, 3, 4}
local y = {0, 2, 1, 3, 2}

local f = interp.linear(x, y)

print(f(0.5))   -- 1.0 (midpoint between 0 and 2)
print(f(1.5))   -- 1.5 (midpoint between 2 and 1)
```

## Cubic Spline Interpolation

### interp.cubicspline(x, y, options?)
Create a cubic spline interpolator.

```lua
local x = {0, 1, 2, 3, 4}
local y = {0, 1, 4, 9, 16}  -- x^2

local spline = interp.cubicspline(x, y)

-- Smooth interpolation
print(spline(1.5))  -- ~2.25
print(spline(2.7))  -- ~7.29
```

### Boundary Conditions

```lua
-- Natural spline (second derivative = 0 at endpoints)
local spline = interp.cubicspline(x, y, {boundary = "natural"})

-- Clamped spline (specify derivatives at endpoints)
local spline = interp.cubicspline(x, y, {
    boundary = "clamped",
    bc_left = 0,   -- f'(x[1]) = 0
    bc_right = 8   -- f'(x[n]) = 8
})
```

## PCHIP (Piecewise Cubic Hermite)

### interp.pchip(x, y)
Monotonicity-preserving cubic interpolation.

```lua
local x = {0, 1, 2, 3, 4}
local y = {0, 2, 2, 3, 3}  -- Monotonic increasing

local f = interp.pchip(x, y)
-- Preserves monotonicity (no overshoot)
```

## Akima Spline

### interp.akima(x, y)
Akima subspline (less oscillatory than cubic spline).

```lua
local x = {0, 1, 2, 3, 4, 5}
local y = {0, 1, 0, 1, 0, 1}  -- Oscillating data

local f = interp.akima(x, y)
-- Smooth with reduced oscillation
```

## Polynomial Interpolation

### interp.polynomial(x, y)
Lagrange polynomial interpolation.

```lua
local x = {-1, 0, 1}
local y = {1, 0, 1}  -- Parabola

local poly = interp.polynomial(x, y)
print(poly(0.5))  -- Evaluate polynomial
```

**Warning**: High-degree polynomials can oscillate (Runge's phenomenon). Prefer splines for many points.

## Barycentric Interpolation

### interp.barycentric(x, y)
Numerically stable polynomial interpolation.

```lua
local x = {0, 0.2, 0.4, 0.6, 0.8, 1.0}
local y = {1, 0.96, 0.84, 0.64, 0.36, 0}

local f = interp.barycentric(x, y)
```

## 2D Interpolation

### interp.interp2d(x, y, z, method?)
Bivariate interpolation.

```lua
local x = {0, 1, 2}
local y = {0, 1, 2}
local z = {
    {0, 1, 4},
    {1, 2, 5},
    {4, 5, 8}
}

local f = interp.interp2d(x, y, z, "linear")

print(f(0.5, 0.5))  -- Interpolate at (0.5, 0.5)
```

## Applications

### Smooth Curve Through Points

```lua
local interp = math.interpolate

-- Data points
local x = {0, 1, 2, 3, 4, 5}
local y = {1, 3, 2, 4, 3, 5}

-- Create smooth spline
local spline = interp.cubicspline(x, y)

-- Generate dense curve for plotting
local x_smooth = {}
local y_smooth = {}
for i = 0, 100 do
    local xi = i * 0.05
    x_smooth[i+1] = xi
    y_smooth[i+1] = spline(xi)
end
```

### Resample Data

```lua
-- Original data
local x_old = {0, 10, 20, 30, 40}
local y_old = {5, 15, 10, 20, 18}

local f = interp.pchip(x_old, y_old)

-- Resample to new grid
local x_new = {}
local y_new = {}
for i = 0, 40 do
    x_new[i+1] = i
    y_new[i+1] = f(i)
end
```

### Temperature Profile

```lua
-- Temperature measurements at specific times
local time = {0, 3, 6, 9, 12, 15, 18, 21, 24}  -- hours
local temp = {15, 14, 13, 16, 22, 25, 21, 18, 16}  -- Celsius

local temp_func = interp.akima(time, temp)

-- Predict temperature at any time
print("Temp at 10:30 AM:", temp_func(10.5))
print("Temp at 7:45 PM:", temp_func(19.75))
```

### Lookup Table Replacement

```lua
-- Instead of large lookup tables, use interpolation
local rpm = {1000, 2000, 3000, 4000, 5000}
local torque = {100, 150, 180, 170, 140}  -- N⋅m

local torque_curve = interp.pchip(rpm, torque)

-- Get torque at any RPM
print("Torque at 2500 RPM:", torque_curve(2500))
```

### Signal Upsampling

```lua
local array = require("luaswift.array")
local interp = math.interpolate

-- Low-resolution signal
local t_low = array.linspace(0, 1, 10)
local signal = array.sin(2 * math.pi * t_low)

local f = interp.cubicspline(t_low:tolist(), signal:tolist())

-- Upsample to high resolution
local t_high = array.linspace(0, 1, 100)
local upsampled = {}
for i = 1, 100 do
    upsampled[i] = f(t_high:get(i))
end
```

## Interpolation Method Selection

| Method | Best For | Characteristics |
|--------|----------|-----------------|
| Linear | Fast, simple | First-order continuity, piecewise |
| Cubic Spline | Smooth curves | Second-order continuity, may overshoot |
| PCHIP | Monotonic data | Preserves monotonicity, no overshoot |
| Akima | Reduced oscillation | Less sensitivity to outliers |
| Polynomial | Few points | Simple, but oscillates for many points |
| Barycentric | Many points | Numerically stable polynomial |

## Performance Notes

- Spline construction is O(n)
- Evaluation is O(log n) using binary search
- Cache interpolator if evaluating multiple times
- For regular grids, use specialized methods

## See Also

- ``InterpolateModule``
- <doc:Modules/IntegrateModule>
- <doc:ArrayModule>
