# Special Functions Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.special` | **Global:** `math.special` (after extend_stdlib)

Advanced special mathematical functions for scientific and numerical computing, including error functions, gamma functions, Bessel functions, elliptic integrals, and the Riemann zeta function.

## Error Functions

```lua
local special = math.special

-- Error function
local e = special.erf(1.0)      -- 0.8427 (probability integral)
local ec = special.erfc(1.0)    -- 0.1573 (complementary error function)

-- Inverse error functions
local x = special.erfinv(0.5)   -- 0.4769 (erf(x) = 0.5)
local y = special.erfcinv(1.5)  -- -0.4769 (erfc(y) = 1.5)
```

The error function erf(x) appears in probability theory, statistics, and solutions to partial differential equations. It represents the probability that a normal random variable falls within [-x, x].

## Gamma Functions

```lua
-- Beta function: B(a,b) = Γ(a)Γ(b)/Γ(a+b)
local b = special.beta(2, 3)    -- 0.0833

-- Regularized incomplete beta: I_x(a,b)
local bi = special.betainc(2, 3, 0.5)  -- 0.6875

-- Digamma function: ψ(x) = d/dx ln(Γ(x))
local psi = special.digamma(5)  -- 1.5061
local psi2 = special.psi(5)     -- Same (alias)

-- Incomplete gamma functions
local p = special.gammainc(2, 3)   -- P(a,x) = γ(a,x)/Γ(a) = 0.8009
local q = special.gammaincc(2, 3)  -- Q(a,x) = Γ(a,x)/Γ(a) = 0.1991

-- Complex gamma functions
local cg = special.cgamma({re=0.5, im=1.0})  -- Γ(z) for complex z
local clg = special.clgamma({re=2, im=3})    -- ln(Γ(z)) for complex z
```

Gamma functions generalize factorials to continuous values and appear throughout mathematics, physics, and statistics.

## Bessel Functions

```lua
-- Bessel functions of the first kind: J_n(x)
local j0 = special.j0(1.0)      -- 0.7652
local j1 = special.j1(1.0)      -- 0.4401
local j2 = special.jn(2, 1.0)   -- 0.1149

-- Bessel functions of the second kind: Y_n(x)
local y0 = special.y0(1.0)      -- 0.0883
local y1 = special.y1(1.0)      -- -0.7812
local y2 = special.yn(2, 1.0)   -- -1.6507

-- Modified Bessel functions: I_n(x), K_n(x)
local i0 = special.besseli(0, 1.0)  -- 1.2661 (first kind)
local k0 = special.besselk(0, 1.0)  -- 0.4210 (second kind)
```

Bessel functions solve differential equations in cylindrical coordinates. Applications include wave propagation, heat conduction, vibrations of circular membranes, and electromagnetic theory.

## Elliptic Integrals

```lua
-- Complete elliptic integral of first kind: K(m)
local k = special.ellipk(0.5)   -- 1.8541

-- Complete elliptic integral of second kind: E(m)
local e = special.ellipe(0.5)   -- 1.3506
```

Elliptic integrals arise in calculating arc lengths of ellipses, pendulum motion, and orbital mechanics. The parameter m is the elliptic parameter (m = k² where k is the modulus).

## Zeta Functions

```lua
-- Riemann zeta function: ζ(s)
local z2 = special.zeta(2)      -- π²/6 = 1.6449
local z3 = special.zeta(3)      -- Apéry's constant = 1.2021

-- Complex zeta function
local cz = special.czeta({re=0.5, im=14.1347})  -- Near first zero
```

The Riemann zeta function connects number theory to complex analysis. The complex version is essential for studying prime number distribution and the Riemann hypothesis.

## Lambert W Function

```lua
-- Lambert W function: W(x) where W(x)·exp(W(x)) = x
local w0 = special.lambertw(1.0)     -- 0.5671
local w1 = special.lambertw(math.e)  -- 1.0

-- Solving equations like x*exp(x) = 2
local x = special.lambertw(2)        -- 0.8526
```

The Lambert W function (also called product logarithm) appears in delay differential equations, enzyme kinetics, quantum mechanics, and combinatorics.

## Practical Examples

### Probability and Statistics

```lua
-- Convert z-score to probability (cumulative normal distribution)
local function normal_cdf(z)
    return 0.5 * (1 + special.erf(z / math.sqrt(2)))
end

local prob = normal_cdf(1.96)  -- 0.975 (95% confidence)

-- Beta distribution cumulative distribution function
local function beta_cdf(x, alpha, beta_param)
    return special.betainc(alpha, beta_param, x)
end
```

### Chi-Squared Distribution

```lua
-- Chi-squared CDF using incomplete gamma
local function chisquare_cdf(x, k)
    return special.gammainc(k/2, x/2)
end

local p_value = 1 - chisquare_cdf(5.99, 2)  -- ~0.05
```

### Quantum Mechanics

```lua
-- Radial wave function for hydrogen atom
local function radial_wavefunction(n, l, r, a0)
    local rho = 2 * r / (n * a0)
    local norm = math.sqrt((2/(n*a0))^3 * math.factorial(n-l-1) /
                           (2*n*math.factorial(n+l)))
    return norm * math.exp(-rho/2) * rho^l *
           special.laguerre(n-l-1, 2*l+1, rho)  -- If available
end
```

### Electromagnetic Theory

```lua
-- Cylindrical wave propagation
local function bessel_wave(r, k, n)
    local kr = k * r
    return special.jn(n, kr)  -- Bessel function of order n
end

-- Mode amplitude in circular waveguide
local amplitude = bessel_wave(0.5, 10, 2)
```

## Function Reference

| Function | Description | Domain | Returns |
|----------|-------------|--------|---------|
| `erf(x)` | Error function | ℝ | [-1, 1] |
| `erfc(x)` | Complementary error function | ℝ | [0, 2] |
| `erfinv(x)` | Inverse error function | (-1, 1) | ℝ |
| `erfcinv(x)` | Inverse complementary error | (0, 2) | ℝ |
| `beta(a, b)` | Beta function | a,b > 0 | ℝ⁺ |
| `betainc(a, b, x)` | Regularized incomplete beta | a,b > 0, x ∈ [0,1] | [0, 1] |
| `digamma(x)` | Digamma function | x ≠ 0,-1,-2,... | ℝ |
| `psi(x)` | Alias for digamma | x ≠ 0,-1,-2,... | ℝ |
| `gammainc(a, x)` | Lower incomplete gamma | a > 0, x ≥ 0 | [0, 1] |
| `gammaincc(a, x)` | Upper incomplete gamma | a > 0, x ≥ 0 | [0, 1] |
| `j0(x)` | Bessel J₀(x) | ℝ | ℝ |
| `j1(x)` | Bessel J₁(x) | ℝ | ℝ |
| `jn(n, x)` | Bessel Jₙ(x) | n ∈ ℤ, x ∈ ℝ | ℝ |
| `y0(x)` | Bessel Y₀(x) | x > 0 | ℝ |
| `y1(x)` | Bessel Y₁(x) | x > 0 | ℝ |
| `yn(n, x)` | Bessel Yₙ(x) | n ∈ ℤ, x > 0 | ℝ |
| `besseli(n, x)` | Modified Bessel Iₙ(x) | n ∈ ℤ, x ∈ ℝ | ℝ |
| `besselk(n, x)` | Modified Bessel Kₙ(x) | n ∈ ℤ, x > 0 | ℝ⁺ |
| `ellipk(m)` | Complete elliptic K(m) | [0, 1) | ℝ⁺ |
| `ellipe(m)` | Complete elliptic E(m) | [0, 1] | ℝ⁺ |
| `zeta(s)` | Riemann zeta ζ(s) | s ≠ 1 | ℝ/ℂ |
| `lambertw(x)` | Lambert W function | x ≥ -1/e | ℝ |
| `cgamma(z)` | Complex gamma Γ(z) | ℂ | ℂ |
| `clgamma(z)` | Complex log-gamma ln(Γ(z)) | ℂ | ℂ |
| `czeta(s)` | Complex zeta ζ(s) | s ≠ 1 | ℂ |

## Notes

- **Complex Numbers**: Functions accepting complex arguments expect tables with `{re=..., im=...}` format and return the same format.
- **Accuracy**: Most functions use series expansions, continued fractions, or asymptotic approximations with ~15 digit accuracy.
- **Performance**: For repeated calls, consider caching results or using vectorized operations when available.
- **Boundary Behavior**: Functions return `-math.huge` or `math.huge` for undefined values (e.g., `y0(0)`).
- **Algorithm Sources**: Implementations follow scipy, DLMF (NIST Digital Library), and Numerical Recipes algorithms.
