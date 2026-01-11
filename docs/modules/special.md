# Special Functions Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.special` | **Global:** `math.special` (after extend_stdlib)

Advanced special mathematical functions for scientific and numerical computing, including error functions, gamma functions, Bessel functions, elliptic integrals, and the Riemann zeta function.

## Function Reference

| Function | Description |
|----------|-------------|
| [erf(x)](#erf) | Error function |
| [erfc(x)](#erfc) | Complementary error function |
| [erfinv(x)](#erfinv) | Inverse error function |
| [erfcinv(x)](#erfcinv) | Inverse complementary error function |
| [beta(a, b)](#beta) | Beta function |
| [betainc(a, b, x)](#betainc) | Regularized incomplete beta function |
| [digamma(x)](#digamma) | Digamma function |
| [psi(x)](#psi) | Alias for digamma function |
| [gammainc(a, x)](#gammainc) | Lower regularized incomplete gamma function |
| [gammaincc(a, x)](#gammaincc) | Upper regularized incomplete gamma function |
| [cgamma(z)](#cgamma) | Complex gamma function |
| [clgamma(z)](#clgamma) | Complex log-gamma function |
| [j0(x)](#j0) | Bessel function of the first kind, order 0 |
| [j1(x)](#j1) | Bessel function of the first kind, order 1 |
| [jn(n, x)](#jn) | Bessel function of the first kind, order n |
| [y0(x)](#y0) | Bessel function of the second kind, order 0 |
| [y1(x)](#y1) | Bessel function of the second kind, order 1 |
| [yn(n, x)](#yn) | Bessel function of the second kind, order n |
| [besseli(n, x)](#besseli) | Modified Bessel function of the first kind |
| [besselk(n, x)](#besselk) | Modified Bessel function of the second kind |
| [ellipk(m)](#ellipk) | Complete elliptic integral of the first kind |
| [ellipe(m)](#ellipe) | Complete elliptic integral of the second kind |
| [zeta(s)](#zeta) | Riemann zeta function |
| [czeta(s)](#czeta) | Complex Riemann zeta function |
| [lambertw(x)](#lambertw) | Lambert W function (product logarithm) |

---

## erf

```
special.erf(x) -> number
```

Error function. Represents the probability that a normal random variable falls within [-x, x].

**Parameters:**
- `x` (number): Input value, any real number

**Returns:** Number in range [-1, 1]

```lua
local e = special.erf(1.0)  -- 0.8427
local e2 = special.erf(0)   -- 0.0
local e3 = special.erf(-1)  -- -0.8427
```

The error function appears in probability theory, statistics, and solutions to partial differential equations.

---

## erfc

```
special.erfc(x) -> number
```

Complementary error function: erfc(x) = 1 - erf(x).

**Parameters:**
- `x` (number): Input value, any real number

**Returns:** Number in range [0, 2]

```lua
local ec = special.erfc(1.0)  -- 0.1573
local ec2 = special.erfc(0)   -- 1.0
```

---

## erfinv

```
special.erfinv(x) -> number
```

Inverse error function. Finds x such that erf(x) = y.

**Parameters:**
- `x` (number): Input value in range (-1, 1)

**Returns:** Real number

```lua
local x = special.erfinv(0.5)  -- 0.4769
local verify = special.erf(x)  -- 0.5
```

---

## erfcinv

```
special.erfcinv(x) -> number
```

Inverse complementary error function. Finds x such that erfc(x) = y.

**Parameters:**
- `x` (number): Input value in range (0, 2)

**Returns:** Real number

```lua
local y = special.erfcinv(1.5)  -- -0.4769
local verify = special.erfc(y)  -- 1.5
```

---

## beta

```
special.beta(a, b) -> number
```

Beta function: B(a,b) = Γ(a)Γ(b)/Γ(a+b).

**Parameters:**
- `a` (number): First parameter, must be > 0
- `b` (number): Second parameter, must be > 0

**Returns:** Positive real number

```lua
local b = special.beta(2, 3)  -- 0.0833
local b2 = special.beta(1, 1) -- 1.0
```

The beta function appears in probability distributions (beta distribution) and combinatorics.

---

## betainc

```
special.betainc(a, b, x) -> number
```

Regularized incomplete beta function: I_x(a,b).

**Parameters:**
- `a` (number): First parameter, must be > 0
- `b` (number): Second parameter, must be > 0
- `x` (number): Upper limit of integration, must be in [0, 1]

**Returns:** Number in range [0, 1]

```lua
local bi = special.betainc(2, 3, 0.5)  -- 0.6875
local bi2 = special.betainc(2, 3, 0)   -- 0.0
local bi3 = special.betainc(2, 3, 1)   -- 1.0
```

Used as the cumulative distribution function of the beta distribution.

---

## digamma

```
special.digamma(x) -> number
```

Digamma function: ψ(x) = d/dx ln(Γ(x)).

**Parameters:**
- `x` (number): Input value, must not be 0, -1, -2, ...

**Returns:** Real number

```lua
local psi = special.digamma(5)  -- 1.5061
local psi2 = special.digamma(1) -- -0.5772 (Euler-Mascheroni constant)
```

The digamma function is the logarithmic derivative of the gamma function.

---

## psi

```
special.psi(x) -> number
```

Alias for [digamma(x)](#digamma).

```lua
local psi = special.psi(5)  -- 1.5061 (same as digamma)
```

---

## gammainc

```
special.gammainc(a, x) -> number
```

Lower regularized incomplete gamma function: P(a,x) = γ(a,x)/Γ(a).

**Parameters:**
- `a` (number): Shape parameter, must be > 0
- `x` (number): Upper limit of integration, must be ≥ 0

**Returns:** Number in range [0, 1]

```lua
local p = special.gammainc(2, 3)  -- 0.8009
local p2 = special.gammainc(2, 0) -- 0.0
```

Used in chi-squared and gamma distributions.

---

## gammaincc

```
special.gammaincc(a, x) -> number
```

Upper regularized incomplete gamma function: Q(a,x) = Γ(a,x)/Γ(a) = 1 - P(a,x).

**Parameters:**
- `a` (number): Shape parameter, must be > 0
- `x` (number): Lower limit of integration, must be ≥ 0

**Returns:** Number in range [0, 1]

```lua
local q = special.gammaincc(2, 3)  -- 0.1991
-- Verify: P(a,x) + Q(a,x) = 1
local p = special.gammainc(2, 3)
print(p + q)  -- 1.0
```

---

## cgamma

```
special.cgamma(z) -> complex
```

Complex gamma function: Γ(z) for complex z.

**Parameters:**
- `z` (table): Complex number as `{re=..., im=...}`

**Returns:** Complex number as `{re=..., im=...}`

```lua
local cg = special.cgamma({re=0.5, im=1.0})
print(cg.re, cg.im)  -- Real and imaginary parts

local real_gamma = special.cgamma({re=5, im=0})  -- Same as math.gamma(5)
```

---

## clgamma

```
special.clgamma(z) -> complex
```

Complex log-gamma function: ln(Γ(z)) for complex z.

**Parameters:**
- `z` (table): Complex number as `{re=..., im=...}`

**Returns:** Complex number as `{re=..., im=...}`

```lua
local clg = special.clgamma({re=2, im=3})
print(clg.re, clg.im)  -- Real and imaginary parts
```

More numerically stable than taking the logarithm of cgamma for large arguments.

---

## j0

```
special.j0(x) -> number
```

Bessel function of the first kind, order 0: J₀(x).

**Parameters:**
- `x` (number): Input value, any real number

**Returns:** Real number

```lua
local j = special.j0(1.0)  -- 0.7652
local j2 = special.j0(0)   -- 1.0
```

Bessel functions solve differential equations in cylindrical coordinates. Applications include wave propagation and vibrations.

---

## j1

```
special.j1(x) -> number
```

Bessel function of the first kind, order 1: J₁(x).

**Parameters:**
- `x` (number): Input value, any real number

**Returns:** Real number

```lua
local j = special.j1(1.0)  -- 0.4401
local j2 = special.j1(0)   -- 0.0
```

---

## jn

```
special.jn(n, x) -> number
```

Bessel function of the first kind, order n: Jₙ(x).

**Parameters:**
- `n` (integer): Order of the Bessel function
- `x` (number): Input value, any real number

**Returns:** Real number

```lua
local j2 = special.jn(2, 1.0)  -- 0.1149
local j0 = special.jn(0, 1.0)  -- Same as j0(1.0)
local j1 = special.jn(1, 1.0)  -- Same as j1(1.0)
```

---

## y0

```
special.y0(x) -> number
```

Bessel function of the second kind, order 0: Y₀(x).

**Parameters:**
- `x` (number): Input value, must be > 0

**Returns:** Real number (may be -math.huge for x = 0)

```lua
local y = special.y0(1.0)  -- 0.0883
```

Bessel functions of the second kind have a singularity at x = 0.

---

## y1

```
special.y1(x) -> number
```

Bessel function of the second kind, order 1: Y₁(x).

**Parameters:**
- `x` (number): Input value, must be > 0

**Returns:** Real number

```lua
local y = special.y1(1.0)  -- -0.7812
```

---

## yn

```
special.yn(n, x) -> number
```

Bessel function of the second kind, order n: Yₙ(x).

**Parameters:**
- `n` (integer): Order of the Bessel function
- `x` (number): Input value, must be > 0

**Returns:** Real number

```lua
local y2 = special.yn(2, 1.0)  -- -1.6507
local y0 = special.yn(0, 1.0)  -- Same as y0(1.0)
```

---

## besseli

```
special.besseli(n, x) -> number
```

Modified Bessel function of the first kind: Iₙ(x).

**Parameters:**
- `n` (integer): Order of the Bessel function
- `x` (number): Input value, any real number

**Returns:** Real number

```lua
local i0 = special.besseli(0, 1.0)  -- 1.2661
local i1 = special.besseli(1, 1.0)  -- 0.5652
```

Modified Bessel functions arise in problems with cylindrical symmetry involving exponential behavior.

---

## besselk

```
special.besselk(n, x) -> number
```

Modified Bessel function of the second kind: Kₙ(x).

**Parameters:**
- `n` (integer): Order of the Bessel function
- `x` (number): Input value, must be > 0

**Returns:** Positive real number

```lua
local k0 = special.besselk(0, 1.0)  -- 0.4210
local k1 = special.besselk(1, 1.0)  -- 0.6019
```

---

## ellipk

```
special.ellipk(m) -> number
```

Complete elliptic integral of the first kind: K(m).

**Parameters:**
- `m` (number): Elliptic parameter (m = k² where k is the modulus), must be in [0, 1)

**Returns:** Positive real number

```lua
local k = special.ellipk(0.5)  -- 1.8541
local k2 = special.ellipk(0)   -- π/2 = 1.5708
```

Elliptic integrals arise in calculating arc lengths of ellipses and orbital mechanics.

---

## ellipe

```
special.ellipe(m) -> number
```

Complete elliptic integral of the second kind: E(m).

**Parameters:**
- `m` (number): Elliptic parameter (m = k² where k is the modulus), must be in [0, 1]

**Returns:** Positive real number

```lua
local e = special.ellipe(0.5)  -- 1.3506
local e2 = special.ellipe(0)   -- π/2 = 1.5708
local e3 = special.ellipe(1)   -- 1.0
```

---

## zeta

```
special.zeta(s) -> number
```

Riemann zeta function: ζ(s).

**Parameters:**
- `s` (number): Input value, must not equal 1

**Returns:** Real number or complex (depending on input)

```lua
local z2 = special.zeta(2)  -- π²/6 = 1.6449
local z3 = special.zeta(3)  -- Apéry's constant = 1.2021
```

The Riemann zeta function connects number theory to complex analysis.

---

## czeta

```
special.czeta(s) -> complex
```

Complex Riemann zeta function: ζ(s) for complex s.

**Parameters:**
- `s` (table): Complex number as `{re=..., im=...}`, must not equal 1

**Returns:** Complex number as `{re=..., im=...}`

```lua
local cz = special.czeta({re=0.5, im=14.1347})  -- Near first zero
print(cz.re, cz.im)
```

Essential for studying prime number distribution and the Riemann hypothesis.

---

## lambertw

```
special.lambertw(x) -> number
```

Lambert W function (product logarithm): W(x) where W(x)·exp(W(x)) = x.

**Parameters:**
- `x` (number): Input value, must be ≥ -1/e (approximately -0.3679)

**Returns:** Real number

```lua
local w0 = special.lambertw(1.0)     -- 0.5671
local w1 = special.lambertw(math.e)  -- 1.0

-- Solving equations like x*exp(x) = 2
local x = special.lambertw(2)        -- 0.8526
local verify = x * math.exp(x)       -- 2.0
```

The Lambert W function appears in delay differential equations, enzyme kinetics, and quantum mechanics.

---

## Examples

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

---

## Notes

- **Complex Numbers**: Functions accepting complex arguments expect tables with `{re=..., im=...}` format and return the same format.
- **Accuracy**: Most functions use series expansions, continued fractions, or asymptotic approximations with ~15 digit accuracy.
- **Performance**: For repeated calls, consider caching results or using vectorized operations when available.
- **Boundary Behavior**: Functions return `-math.huge` or `math.huge` for undefined values (e.g., `y0(0)`).
- **Algorithm Sources**: Implementations follow scipy, DLMF (NIST Digital Library), and Numerical Recipes algorithms.
