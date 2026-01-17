# Special Functions Module

Special mathematical functions including gamma, beta, Bessel, and error functions.

## Overview

The Special Functions module provides scientifically accurate implementations of special mathematical functions commonly used in statistics, physics, and engineering. Available under `math.special` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local special = math.special
```

## Gamma Functions

### special.gamma(x)
Gamma function Γ(x).

```lua
print(special.gamma(5))      -- 24 (same as 4!)
print(special.gamma(0.5))    -- √π ≈ 1.772
```

### special.loggamma(x)
Natural logarithm of gamma function.

```lua
print(special.loggamma(100))  -- More stable for large x
```

### special.digamma(x)
Digamma function ψ(x) = d/dx ln Γ(x).

```lua
print(special.digamma(1))     -- -γ (Euler-Mascheroni constant)
```

## Beta Functions

### special.beta(a, b)
Beta function B(a,b) = Γ(a)Γ(b) / Γ(a+b).

```lua
print(special.beta(2, 3))
```

### special.logbeta(a, b)
Natural logarithm of beta function.

```lua
print(special.logbeta(100, 200))
```

## Error Functions

### special.erf(x)
Error function.

```lua
print(special.erf(0))        -- 0
print(special.erf(1))        -- ~0.8427
```

### special.erfc(x)
Complementary error function (1 - erf(x)).

```lua
print(special.erfc(0))       -- 1
```

### special.erfinv(y)
Inverse error function.

```lua
print(special.erfinv(0.8427))  -- ~1
```

## Bessel Functions

### special.j0(x), special.j1(x)
Bessel functions of the first kind, orders 0 and 1.

```lua
print(special.j0(0))         -- 1
print(special.j1(0))         -- 0
```

### special.jn(n, x)
Bessel function of the first kind, order n.

```lua
print(special.jn(2, 5))
```

### special.y0(x), special.y1(x)
Bessel functions of the second kind, orders 0 and 1.

```lua
print(special.y0(1))
print(special.y1(1))
```

### special.yn(n, x)
Bessel function of the second kind, order n.

```lua
print(special.yn(2, 5))
```

## Elliptic Integrals

### special.ellipk(m)
Complete elliptic integral of the first kind.

```lua
print(special.ellipk(0.5))
```

### special.ellipe(m)
Complete elliptic integral of the second kind.

```lua
print(special.ellipe(0.5))
```

## Applications

### Normal Distribution CDF

```lua
-- Using erf to compute normal CDF
local function normal_cdf(x, mean, std)
    local z = (x - mean) / (std * math.sqrt(2))
    return 0.5 * (1 + math.special.erf(z))
end

print(normal_cdf(0, 0, 1))   -- 0.5 (standard normal at 0)
```

### Factorial Approximation

```lua
-- For large n, use gamma
local function factorial(n)
    return math.special.gamma(n + 1)
end

print(factorial(10))  -- 3628800
```

## See Also

- ``SpecialModule``
- <doc:Modules/DistributionsModule>
- <doc:MathXModule>
