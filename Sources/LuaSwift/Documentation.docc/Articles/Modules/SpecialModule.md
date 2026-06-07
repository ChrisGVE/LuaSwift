# Special Functions Module

Advanced special mathematical functions including error, beta, Bessel, gamma, elliptic, zeta, and Lambert W functions.

> Important: This module requires the **NumericSwift** optional dependency. It is **off by default**. Enable it by setting `LUASWIFT_INCLUDE_NUMERICSWIFT=1` in your build environment or Swift Package Manager configuration before building.

## Overview

The Special Functions module provides scientifically accurate implementations of special mathematical functions
commonly used in statistics, physics, and engineering. All functions are available under `math.special` after
calling `luaswift.extend_stdlib()`.

Function groups:

- **Error functions** — `erf`, `erfc`, `erfinv`, `erfcinv`
- **Beta functions** — `beta`, `betainc`
- **Bessel functions (first kind)** — `j0`, `j1`, `jn`
- **Bessel functions (second kind)** — `y0`, `y1`, `yn`
- **Modified Bessel functions** — `besseli`, `besselk`
- **Gamma-related** — `digamma` / `psi`, `gammainc`, `gammaincc`
- **Elliptic integrals** — `ellipk`, `ellipe`
- **Riemann zeta** — `zeta`
- **Lambert W** — `lambertw`
- **Complex variants** — `cgamma`, `clgamma`, `czeta`

## Installation

```swift
// Install all modules (includes SpecialModule when LUASWIFT_NUMERICSWIFT is set)
try ModuleRegistry.install(in: engine)

// Or install just the Special Functions module
try SpecialModule.install(in: engine)
```

```lua
-- Wire math.special namespace
luaswift.extend_stdlib()
local special = math.special
```

## Error Functions

### special.erf(x)

Error function: `erf(x) = (2/√π) ∫₀ˣ exp(−t²) dt`.

```lua
print(special.erf(0))    -- 0.0
print(special.erf(1))    -- ~0.8427
print(special.erf(-1))   -- ~-0.8427
```

### special.erfc(x)

Complementary error function: `erfc(x) = 1 − erf(x)`.

```lua
print(special.erfc(0))   -- 1.0
print(special.erfc(1))   -- ~0.1573
```

### special.erfinv(x)

Inverse error function. Returns `y` such that `erf(y) = x`.

**Domain:** `x ∈ (−1, 1)` — raises an error outside this range.

```lua
print(special.erfinv(0))      -- 0.0
print(special.erfinv(0.8427)) -- ~1.0
```

### special.erfcinv(x)

Inverse complementary error function. Returns `y` such that `erfc(y) = x`.

**Domain:** `x ∈ (0, 2)` — raises an error outside this range.

```lua
print(special.erfcinv(1))     -- 0.0
print(special.erfcinv(0.1573)) -- ~1.0
```

## Beta Functions

### special.beta(a, b)

Beta function: `B(a, b) = Γ(a)·Γ(b) / Γ(a+b)`.

**Parameters:**
- `a` — positive real number
- `b` — positive real number

```lua
print(special.beta(2, 3))    -- ~0.0833
print(special.beta(0.5, 0.5)) -- π
```

### special.betainc(a, b, x)

Regularized incomplete beta function: `I_x(a, b) = B(x; a, b) / B(a, b)`.

**Parameters:**
- `a`, `b` — shape parameters (positive reals)
- `x` — evaluation point; **must be in `[0, 1]`** — raises an error outside this range

**Returns:** value in `[0, 1]`.

```lua
print(special.betainc(2, 3, 0.5))  -- ~0.6875
print(special.betainc(1, 1, 0.5))  -- 0.5 (uniform CDF)
```

## Bessel Functions — First Kind

### special.j0(x), special.j1(x)

Bessel functions of the first kind, orders 0 and 1: `J₀(x)` and `J₁(x)`.

```lua
print(special.j0(0))   -- 1.0
print(special.j1(0))   -- 0.0
print(special.j0(2.4)) -- ~0.0025 (near first zero)
```

### special.jn(n, x)

Bessel function of the first kind, integer order `n`: `J_n(x)`.

**Parameters:**
- `n` — integer order (passed as number, truncated to `Int32` internally)
- `x` — argument

```lua
print(special.jn(0, 0))   -- 1.0  (same as j0)
print(special.jn(2, 5))   -- ~0.0466
```

## Bessel Functions — Second Kind

### special.y0(x), special.y1(x)

Bessel functions of the second kind, orders 0 and 1: `Y₀(x)` and `Y₁(x)`.

**Domain:** `x > 0`. Returns `-math.huge` (−∞) for `x ≤ 0`.

```lua
print(special.y0(1))  -- ~0.0883
print(special.y1(1))  -- ~-0.7812
```

### special.yn(n, x)

Bessel function of the second kind, integer order `n`: `Y_n(x)`.

**Domain:** `x > 0`. Returns `-math.huge` (−∞) for `x ≤ 0`.

```lua
print(special.yn(0, 1))  -- ~0.0883  (same as y0)
print(special.yn(2, 5))  -- ~0.3675
```

## Modified Bessel Functions

### special.besseli(n, x)

Modified Bessel function of the first kind: `I_n(x)`.

**Parameters:**
- `n` — integer order
- `x` — argument (all real values accepted)

```lua
print(special.besseli(0, 0))  -- 1.0
print(special.besseli(1, 1))  -- ~0.5652
```

### special.besselk(n, x)

Modified Bessel function of the second kind: `K_n(x)`.

**Domain:** `x > 0`. Returns `+math.huge` (+∞) for `x ≤ 0`.

**Parameters:**
- `n` — integer order
- `x` — argument

```lua
print(special.besselk(0, 1))  -- ~0.4210
print(special.besselk(1, 1))  -- ~0.6019
```

## Gamma-Related Functions

### special.digamma(x) / special.psi(x)

Digamma function: `ψ(x) = d/dx ln Γ(x) = Γ′(x) / Γ(x)`.

`special.psi` is an alias for `special.digamma`.

```lua
print(special.digamma(1))   -- ~-0.5772 (negative Euler-Mascheroni constant)
print(special.digamma(2))   -- ~0.4228
print(special.psi(1))       -- same as digamma(1)
```

### special.gammainc(a, x)

Lower regularized incomplete gamma function: `P(a, x) = γ(a, x) / Γ(a)`.

**Constraints:** `a > 0`, `x ≥ 0` — raises an error otherwise.

**Returns:** value in `[0, 1]`.

```lua
print(special.gammainc(1, 1))   -- ~0.6321  (1 − 1/e)
print(special.gammainc(2, 1))   -- ~0.2642
```

### special.gammaincc(a, x)

Upper regularized incomplete gamma function: `Q(a, x) = Γ(a, x) / Γ(a) = 1 − P(a, x)`.

**Constraints:** `a > 0`, `x ≥ 0` — raises an error otherwise.

```lua
print(special.gammaincc(1, 1))  -- ~0.3679  (1/e, complement of gammainc)
print(special.gammaincc(1, 0))  -- 1.0
```

## Elliptic Integrals

The argument `m` is the **parameter** (m = k², where k is the modulus), not the modulus itself.

### special.ellipk(m)

Complete elliptic integral of the first kind: `K(m) = ∫₀^(π/2) 1/√(1 − m·sin²θ) dθ`.

**Domain:** `m ∈ [0, 1)` — raises an error for `m < 0` or `m ≥ 1`. Diverges to +∞ as m → 1⁻.

```lua
print(special.ellipk(0))    -- π/2 ≈ 1.5708
print(special.ellipk(0.5))  -- ~1.8541
print(special.ellipk(0.99)) -- ~3.3566 (large, approaching divergence)
```

### special.ellipe(m)

Complete elliptic integral of the second kind: `E(m) = ∫₀^(π/2) √(1 − m·sin²θ) dθ`.

**Domain:** `m ∈ [0, 1]` — raises an error for `m < 0` or `m > 1`.

```lua
print(special.ellipe(0))    -- π/2 ≈ 1.5708
print(special.ellipe(0.5))  -- ~1.3506
print(special.ellipe(1))    -- 1.0
```

## Riemann Zeta Function

### special.zeta(s)

Riemann zeta function: `ζ(s) = Σₙ₌₁^∞ 1/nˢ` for `s > 1`, analytically continued elsewhere.

```lua
print(special.zeta(2))   -- π²/6 ≈ 1.6449
print(special.zeta(4))   -- π⁴/90 ≈ 1.0823
print(special.zeta(0))   -- -0.5  (analytic continuation)
print(special.zeta(-1))  -- -1/12 (analytic continuation)
```

## Lambert W Function

### special.lambertw(x)

Principal branch `W₀(x)` of the Lambert W function: the inverse of `f(w) = w·exp(w)`.

**Domain:** `x ≥ −1/e ≈ −0.36788` — raises an error below this bound.

```lua
print(special.lambertw(0))    -- 0.0
print(special.lambertw(1))    -- ~0.5671  (Omega constant)
print(special.lambertw(math.exp(1)))  -- 1.0
```

## Complex Variants

These functions accept either a plain number or a complex table `{re = ..., im = ...}`.

### special.cgamma(z)

Complex gamma function `Γ(z)`. For positive real input, returns a plain number; for complex or non-positive real input, returns a complex table `{re = ..., im = ...}`.

```lua
print(special.cgamma(5))             -- 24.0  (= 4!)
local g = special.cgamma({re=0.5, im=1})
print(g.re, g.im)                    -- complex result
```

### special.clgamma(z)

Complex log-gamma function `log Γ(z)`. Always returns a complex table `{re = ..., im = ...}` using the principal branch.

```lua
local lg = special.clgamma(5)
print(lg.re)                         -- log(24) ≈ 3.1781
print(lg.im)                         -- 0.0

local lg2 = special.clgamma({re=0.5, im=1})
print(lg2.re, lg2.im)                -- complex result
```

### special.czeta(s)

Complex Riemann zeta function `ζ(s)`. For real input, returns a plain number. For complex input, returns a complex table `{re = ..., im = ...}`. Essential for studying Riemann zeros on the critical line `Re(s) = 0.5`.

```lua
print(special.czeta(2))                      -- π²/6 ≈ 1.6449 (real result)
local z = special.czeta({re=0.5, im=14.135}) -- near first non-trivial zero
print(z.re, z.im)                            -- near (0, 0)
```

## Applications

### Normal Distribution CDF

```lua
luaswift.extend_stdlib()

local function normal_cdf(x, mean, std)
    local z = (x - mean) / (std * math.sqrt(2))
    return 0.5 * (1 + math.special.erf(z))
end

print(normal_cdf(0, 0, 1))   -- 0.5 (standard normal at mean)
print(normal_cdf(1, 0, 1))   -- ~0.8413
```

### Chi-Squared p-value via Incomplete Gamma

```lua
luaswift.extend_stdlib()
local special = math.special

-- P(χ² > x | df) = gammaincc(df/2, x/2)
local function chi2_pvalue(x, df)
    return special.gammaincc(df / 2, x / 2)
end

print(chi2_pvalue(3.841, 1))  -- ~0.05 (95th percentile)
```

### Elliptic Period of a Pendulum

```lua
luaswift.extend_stdlib()

-- Period of a pendulum with amplitude theta_0 (radians)
-- T = 4 * sqrt(L/g) * K(sin²(theta_0/2))
local function pendulum_period(L, g, theta0)
    local m = math.sin(theta0 / 2) ^ 2
    return 4 * math.sqrt(L / g) * math.special.ellipk(m)
end

-- 1 m pendulum, small angle (≈ simple harmonic)
print(pendulum_period(1, 9.81, 0.1))  -- ~2.007 s
```

## See Also

- ``SpecialModule``
- <doc:DistributionsModule>
- <doc:MathXModule>
