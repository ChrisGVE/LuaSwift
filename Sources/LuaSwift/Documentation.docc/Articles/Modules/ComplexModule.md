# Complex Module

Complex number arithmetic with full mathematical function support.

## Overview

The Complex module provides high-performance complex number operations using Swift's native math libraries. It supports standard arithmetic, polar form conversions, exponential and logarithmic functions, trigonometric functions, and hyperbolic functions. Complex numbers have proper operator support, allowing natural mathematical expressions.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the Complex module
ModuleRegistry.installComplexModule(in: engine)
```

## Basic Usage

```lua
local complex = require("luaswift.complex")

-- Create complex numbers
local z1 = complex.new(3, 4)          -- 3 + 4i
local z2 = complex.from_polar(5, math.pi/4)

-- Arithmetic with operators
local sum = z1 + z2
local product = z1 * z2
local quotient = z1 / z2

-- Methods
print(z1:abs())          -- 5 (magnitude)
print(z1:arg())          -- 0.927... (angle in radians)
print(z1:conj())         -- 3 - 4i

-- Functions
print(z1:exp())          -- e^z
print(z1:sqrt())         -- principal square root
```

## API Reference

### Creation

#### new(re, im?)
Creates a complex number from rectangular coordinates.

```lua
local z = complex.new(3, 4)      -- 3 + 4i
local real = complex.new(5)       -- 5 + 0i (purely real)
local zero = complex.new()        -- 0 + 0i
```

#### from_polar(r, theta)
Creates a complex number from polar coordinates.

**Parameters:**
- `r` - Magnitude (radius)
- `theta` - Angle in radians

```lua
local z = complex.from_polar(5, math.pi/4)
-- Approximately 3.536 + 3.536i

local unit = complex.from_polar(1, math.pi)
-- -1 + 0i

-- Create roots of unity
local n = 4
for k = 0, n-1 do
    local root = complex.from_polar(1, 2*math.pi*k/n)
    print(root)
end
```

### Constants

#### i
The imaginary unit.

```lua
local i = complex.i               -- 0 + 1i
local z = 3 + 4*i                 -- 3 + 4i (with scalar multiplication)
```

### Arithmetic Operators

Complex numbers support standard arithmetic operators.

#### Addition (+)
```lua
local z1 = complex.new(1, 2)
local z2 = complex.new(3, 4)
local sum = z1 + z2              -- 4 + 6i

-- Mixed with scalars
local z = complex.new(1, 2) + 5  -- 6 + 2i
local z = 5 + complex.new(1, 2)  -- 6 + 2i
```

#### Subtraction (-)
```lua
local diff = z1 - z2             -- -2 - 2i
local z = complex.new(5, 3) - 2  -- 3 + 3i
```

#### Multiplication (*)
```lua
local z1 = complex.new(1, 2)
local z2 = complex.new(3, 4)
local prod = z1 * z2             -- -5 + 10i

-- Scalar multiplication
local scaled = z1 * 3            -- 3 + 6i
```

#### Division (/)
```lua
local quot = z1 / z2             -- 0.44 + 0.08i
local z = complex.new(4, 2) / 2  -- 2 + 1i
```

#### Negation (-)
```lua
local z = complex.new(3, 4)
local neg = -z                   -- -3 - 4i
```

#### Equality (==)
```lua
local z1 = complex.new(3, 4)
local z2 = complex.new(3, 4)
print(z1 == z2)                  -- true
print(z1 == complex.new(3, 5))   -- false

-- Compare with scalars
print(complex.new(5, 0) == 5)    -- true
```

### Properties

#### z:abs()
Returns the magnitude (absolute value) of the complex number.

```lua
local z = complex.new(3, 4)
print(z:abs())                   -- 5

local z = complex.new(1, 1)
print(z:abs())                   -- 1.414... (√2)
```

#### z:arg()
Returns the argument (angle) in radians, in the range (-π, π].

```lua
local z = complex.new(1, 1)
print(z:arg())                   -- 0.785... (π/4)

local z = complex.new(-1, 0)
print(z:arg())                   -- 3.14159... (π)

local z = complex.new(0, -1)
print(z:arg())                   -- -1.5707... (-π/2)
```

#### z:conj()
Returns the complex conjugate.

```lua
local z = complex.new(3, 4)
print(z:conj())                  -- 3 - 4i

-- Property: z * conj(z) = |z|²
local product = z * z:conj()
print(product.re)                -- 25 (= 3² + 4²)
```

#### z:polar()
Returns polar coordinates as an array {r, theta}.

```lua
local z = complex.new(3, 4)
local r, theta = table.unpack(z:polar())
print(r)                         -- 5
print(theta)                     -- 0.927... (radians)
```

#### z:clone()
Creates a deep copy of the complex number.

```lua
local z1 = complex.new(3, 4)
local z2 = z1:clone()
z2.re = 99
print(z1.re)                     -- 3 (unchanged)
```

### Powers and Roots

#### z:pow(n)
Raises to a power using De Moivre's formula.

```lua
local z = complex.new(1, 1)
print(z:pow(2))                  -- 0 + 2i (i.e., 2i)
print(z:pow(4))                  -- -4 + 0i

-- Fractional powers
local z = complex.new(0, 1)
print(z:pow(0.5))                -- Principal square root of i
```

#### z:sqrt()
Returns the principal square root.

```lua
local z = complex.new(-1, 0)
print(z:sqrt())                  -- 0 + 1i (i)

local z = complex.new(0, 1)
print(z:sqrt())                  -- 0.707... + 0.707...i

local z = complex.new(3, 4)
print(z:sqrt())                  -- 2 + 1i
```

### Exponential and Logarithmic Functions

#### z:exp()
Complex exponential (e^z).

```lua
local z = complex.new(0, math.pi)
print(z:exp())                   -- -1 + 0i (Euler's identity: e^(iπ) = -1)

local z = complex.new(1, 0)
print(z:exp())                   -- e + 0i ≈ 2.718...

local z = complex.new(0, math.pi/2)
print(z:exp())                   -- 0 + 1i (e^(iπ/2) = i)
```

#### z:log()
Principal value of natural logarithm.

```lua
local z = complex.new(math.exp(1), 0)
print(z:log())                   -- 1 + 0i

local z = complex.new(-1, 0)
print(z:log())                   -- 0 + 3.14159...i (0 + πi)

local z = complex.new(0, 1)
print(z:log())                   -- 0 + 1.5707...i (0 + π/2·i)
```

### Trigonometric Functions

#### z:sin()
Complex sine.

```lua
local z = complex.new(0, 1)
print(z:sin())                   -- 0 + 1.175...i (i·sinh(1))

local z = complex.new(math.pi/2, 0)
print(z:sin())                   -- 1 + 0i
```

#### z:cos()
Complex cosine.

```lua
local z = complex.new(0, 1)
print(z:cos())                   -- 1.543... + 0i (cosh(1))

local z = complex.new(0, 0)
print(z:cos())                   -- 1 + 0i
```

#### z:tan()
Complex tangent.

```lua
local z = complex.new(0, 1)
print(z:tan())                   -- 0 + 0.761...i
```

### Inverse Trigonometric Functions

#### z:asin()
Complex arcsine.

```lua
local z = complex.new(0, 2)
print(z:asin())

local z = complex.new(1, 0)
print(z:asin())                  -- π/2 + 0i
```

#### z:acos()
Complex arccosine.

```lua
local z = complex.new(1, 0)
print(z:acos())                  -- 0 + 0i
```

#### z:atan()
Complex arctangent.

```lua
local z = complex.new(1, 0)
print(z:atan())                  -- π/4 + 0i
```

### Hyperbolic Functions

#### z:sinh()
Complex hyperbolic sine.

```lua
local z = complex.new(1, 0)
print(z:sinh())                  -- 1.175... + 0i

local z = complex.new(0, math.pi/2)
print(z:sinh())                  -- 0 + 1i (i·sin(π/2) = i)
```

#### z:cosh()
Complex hyperbolic cosine.

```lua
local z = complex.new(0, 0)
print(z:cosh())                  -- 1 + 0i

local z = complex.new(0, math.pi)
print(z:cosh())                  -- -1 + 0i (cos(π) = -1)
```

#### z:tanh()
Complex hyperbolic tangent.

```lua
local z = complex.new(1, 0)
print(z:tanh())                  -- 0.761... + 0i
```

## Common Patterns

### Solving Quadratic Equations

```lua
local function solve_quadratic(a, b, c)
    local discriminant = complex.new(b*b - 4*a*c, 0)
    local sqrt_disc = discriminant:sqrt()
    local neg_b = complex.new(-b, 0)
    local two_a = complex.new(2*a, 0)

    local x1 = (neg_b + sqrt_disc) / two_a
    local x2 = (neg_b - sqrt_disc) / two_a
    return x1, x2
end

-- x² + 1 = 0 (no real roots)
local x1, x2 = solve_quadratic(1, 0, 1)
print(x1)  -- 0 + 1i
print(x2)  -- 0 - 1i
```

### Roots of Unity

```lua
local function roots_of_unity(n)
    local roots = {}
    for k = 0, n-1 do
        local angle = 2 * math.pi * k / n
        roots[k+1] = complex.from_polar(1, angle)
    end
    return roots
end

local cube_roots = roots_of_unity(3)
for i, root in ipairs(cube_roots) do
    print(i, root)
end
```

### Signal Processing

```lua
-- Discrete Fourier Transform element
local function dft_element(signal, k)
    local N = #signal
    local result = complex.new(0, 0)
    for n = 1, N do
        local angle = -2 * math.pi * (k-1) * (n-1) / N
        local twiddle = complex.from_polar(1, angle)
        result = result + signal[n] * twiddle
    end
    return result
end
```

### Complex Polynomial Evaluation

```lua
local function eval_poly(coeffs, z)
    local result = complex.new(0, 0)
    local power = complex.new(1, 0)
    for _, c in ipairs(coeffs) do
        if type(c) == "number" then
            c = complex.new(c, 0)
        end
        result = result + c * power
        power = power * z
    end
    return result
end

-- Evaluate z² + 2z + 1 at z = 1+i
local coeffs = {1, 2, 1}  -- 1 + 2z + z²
local z = complex.new(1, 1)
print(eval_poly(coeffs, z))
```

### Mandelbrot Set Test

```lua
local function in_mandelbrot(c, max_iter)
    local z = complex.new(0, 0)
    for i = 1, max_iter do
        z = z*z + c
        if z:abs() > 2 then
            return false, i
        end
    end
    return true, max_iter
end

local c = complex.new(-0.5, 0.5)
local inside, iterations = in_mandelbrot(c, 100)
print(inside, iterations)
```

## Representation

Complex numbers are displayed in the format `a+bi` or `a-bi`:

```lua
print(complex.new(3, 4))         -- "3.0000+4.0000i"
print(complex.new(3, -4))        -- "3.0000-4.0000i"
print(complex.new(0, 1))         -- "0.0000+1.0000i"
print(complex.new(-2, 0))        -- "-2.0000+0.0000i"
```

## Accessing Components

The real and imaginary parts can be accessed directly:

```lua
local z = complex.new(3, 4)
print(z.re)                      -- 3
print(z.im)                      -- 4
```

## See Also

- ``ComplexModule``
- ``MathXModule``
- ``LinAlgModule``
