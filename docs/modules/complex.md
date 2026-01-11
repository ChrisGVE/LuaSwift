# Complex Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.complex` | **Global:** `math.complex` (after extend_stdlib)

High-performance complex number arithmetic using Swift's native math library (Darwin). Provides comprehensive support for complex operations including trigonometric, hyperbolic, exponential, and logarithmic functions.

## Creating Complex Numbers

### `complex.new(re, im)`
Create a complex number from real and imaginary parts.

```lua
local complex = require("luaswift.complex")

local z1 = complex.new(3, 4)        -- 3+4i
local z2 = complex.new(5, -2)       -- 5-2i
local z3 = complex.new(7)           -- 7+0i (real number)
```

### `complex.from_polar(r, theta)`
Create a complex number from polar coordinates (magnitude and angle).

```lua
local z1 = complex.from_polar(5, math.pi/4)    -- 5∠45° = 3.5355+3.5355i
local z2 = complex.from_polar(1, math.pi)      -- 1∠180° = -1+0i
local z3 = complex.from_polar(2, 0)            -- 2∠0° = 2+0i
```

### Constants

```lua
complex.i  -- The imaginary unit (0+1i)
```

## Arithmetic Operations

Complex numbers support standard arithmetic operators with automatic type conversion for real numbers.

```lua
local z1 = complex.new(3, 4)
local z2 = complex.new(1, 2)

-- Addition
local sum = z1 + z2              -- (3+4i) + (1+2i) = 4+6i
local sum2 = z1 + 5              -- (3+4i) + 5 = 8+4i

-- Subtraction
local diff = z1 - z2             -- (3+4i) - (1+2i) = 2+2i
local diff2 = 10 - z1            -- 10 - (3+4i) = 7-4i

-- Multiplication
local prod = z1 * z2             -- (3+4i) * (1+2i) = -5+10i
local prod2 = z1 * 2             -- (3+4i) * 2 = 6+8i

-- Division
local quot = z1 / z2             -- (3+4i) / (1+2i) = 2.2+0.4i
local quot2 = z1 / 2             -- (3+4i) / 2 = 1.5+2i

-- Negation
local neg = -z1                  -- -(3+4i) = -3-4i
```

## Properties and Conversions

### `z:abs()`
Calculate the magnitude (absolute value) of a complex number.

```lua
local z = complex.new(3, 4)
print(z:abs())                   -- 5.0
```

### `z:arg()`
Calculate the argument (phase angle) in radians.

```lua
local z = complex.new(1, 1)
print(z:arg())                   -- 0.7854 (π/4 radians = 45°)
```

### `z:conj()`
Return the complex conjugate.

```lua
local z = complex.new(3, 4)
local conj = z:conj()            -- 3-4i
```

### `z:polar()`
Convert to polar form, returning `{magnitude, angle}`.

```lua
local z = complex.new(3, 4)
local r, theta = table.unpack(z:polar())
print(r, theta)                  -- 5.0, 0.9273 (radians)
```

## Powers and Roots

### `z:pow(n)`
Raise complex number to a power using De Moivre's formula.

```lua
local z = complex.new(1, 1)
local z2 = z:pow(2)              -- (1+1i)² = 0+2i
local z3 = z:pow(3)              -- (1+1i)³ = -2+2i

-- Fractional powers
local root = z:pow(0.5)          -- Square root via z^0.5
```

### `z:sqrt()`
Calculate the principal square root.

```lua
local z = complex.new(-1, 0)
local sqrt = z:sqrt()            -- √(-1) = 0+1i

local z2 = complex.new(3, 4)
print(z2:sqrt())                 -- 2.0000+1.0000i
```

## Exponential and Logarithmic

### `z:exp()`
Calculate e raised to the complex power.

```lua
local z = complex.new(0, math.pi)
local result = z:exp()           -- e^(iπ) = -1+0i (Euler's identity)

local z2 = complex.new(1, 1)
print(z2:exp())                  -- e^(1+i) = 1.4687+2.2874i
```

### `z:log()`
Calculate the natural logarithm (principal branch).

```lua
local z = complex.new(-1, 0)
local result = z:log()           -- ln(-1) = 0+πi

local z2 = complex.new(1, 1)
print(z2:log())                  -- 0.3466+0.7854i
```

## Trigonometric Functions

### `z:sin()`, `z:cos()`, `z:tan()`
Standard trigonometric functions extended to complex domain.

```lua
local z = complex.new(1, 1)

local sin_z = z:sin()            -- sin(1+i) = 1.2985+0.6350i
local cos_z = z:cos()            -- cos(1+i) = 0.8337-0.9889i
local tan_z = z:tan()            -- tan(1+i) = 0.2718+1.0840i
```

### `z:asin()`, `z:acos()`, `z:atan()`
Inverse trigonometric functions.

```lua
local z = complex.new(2, 0)

local asin_z = z:asin()          -- arcsin(2) = 1.5708-1.3170i
local acos_z = z:acos()          -- arccos(2) = 0.0000+1.3170i
local atan_z = z:atan()          -- arctan(2) = 1.1071+0.0000i
```

## Hyperbolic Functions

### `z:sinh()`, `z:cosh()`, `z:tanh()`
Hyperbolic functions extended to complex domain.

```lua
local z = complex.new(1, 1)

local sinh_z = z:sinh()          -- sinh(1+i) = 0.6350+1.2985i
local cosh_z = z:cosh()          -- cosh(1+i) = 0.8337+0.9889i
local tanh_z = z:tanh()          -- tanh(1+i) = 1.0840+0.2718i
```

## Utilities

### `z:clone()`
Create a copy of a complex number.

```lua
local z1 = complex.new(3, 4)
local z2 = z1:clone()            -- Independent copy
```

### String Representation

Complex numbers automatically format for display.

```lua
local z1 = complex.new(3, 4)
print(z1)                        -- "3.0000+4.0000i"

local z2 = complex.new(5, -2)
print(z2)                        -- "5.0000-2.0000i"
```

## Comparison

### Equality

```lua
local z1 = complex.new(3, 4)
local z2 = complex.new(3, 4)
local z3 = complex.new(3, 0)

print(z1 == z2)                  -- true
print(z1 == z3)                  -- false
print(z3 == 3)                   -- true (compares with real number)
```

## Examples

### Mandelbrot Set Point Test

```lua
local complex = require("luaswift.complex")

function in_mandelbrot(c, max_iter)
    local z = complex.new(0, 0)
    for i = 1, max_iter do
        z = z:pow(2) + c
        if z:abs() > 2 then
            return false
        end
    end
    return true
end

local c = complex.new(-0.5, 0.5)
print(in_mandelbrot(c, 100))     -- true (inside the set)
```

### Solving Quadratic Equations

```lua
local complex = require("luaswift.complex")

function solve_quadratic(a, b, c)
    local discriminant = b*b - 4*a*c
    local sqrt_disc = complex.new(discriminant, 0):sqrt()

    local x1 = (-b + sqrt_disc) / (2*a)
    local x2 = (-b - sqrt_disc) / (2*a)

    return x1, x2
end

-- Solve x² + 2x + 5 = 0
local x1, x2 = solve_quadratic(1, 2, 5)
print(x1)                        -- -1.0000+2.0000i
print(x2)                        -- -1.0000-2.0000i
```

### Verifying Euler's Identity

```lua
local complex = require("luaswift.complex")

local z = complex.new(0, math.pi)
local result = z:exp()           -- e^(iπ)
print(result + 1)                -- 0.0000+0.0000i (e^(iπ) + 1 = 0)
```

### Complex Frequency Analysis

```lua
local complex = require("luaswift.complex")

-- Create a complex sinusoid
function complex_sinusoid(t, freq, phase)
    local omega = 2 * math.pi * freq
    return complex.from_polar(1, omega * t + phase)
end

-- Sample at t = 0.1, frequency = 5 Hz, phase = π/4
local signal = complex_sinusoid(0.1, 5, math.pi/4)
print(signal)
print("Magnitude:", signal:abs())
print("Phase:", signal:arg())
```

## Function Reference

| Category | Function | Description |
|----------|----------|-------------|
| **Creation** | `new(re, im)` | Create from Cartesian coordinates |
| | `from_polar(r, theta)` | Create from polar coordinates |
| **Arithmetic** | `z1 + z2` | Addition |
| | `z1 - z2` | Subtraction |
| | `z1 * z2` | Multiplication |
| | `z1 / z2` | Division |
| | `-z` | Negation |
| **Properties** | `abs()` | Magnitude/absolute value |
| | `arg()` | Argument/phase angle |
| | `conj()` | Complex conjugate |
| | `polar()` | Convert to polar form |
| **Powers** | `pow(n)` | Raise to power |
| | `sqrt()` | Principal square root |
| **Exponential** | `exp()` | Exponential e^z |
| | `log()` | Natural logarithm |
| **Trigonometric** | `sin()` | Sine |
| | `cos()` | Cosine |
| | `tan()` | Tangent |
| | `asin()` | Arcsine |
| | `acos()` | Arccosine |
| | `atan()` | Arctangent |
| **Hyperbolic** | `sinh()` | Hyperbolic sine |
| | `cosh()` | Hyperbolic cosine |
| | `tanh()` | Hyperbolic tangent |
| **Utilities** | `clone()` | Create copy |
| **Comparison** | `z1 == z2` | Equality test |
| **Constants** | `i` | Imaginary unit (0+1i) |
