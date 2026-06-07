# Number Theory Module

Prime numbers, factorization, and classical number-theoretic functions.

## Overview

> Important: This module requires the **NumericSwift** optional dependency, which is **off by default**. Build with `LUASWIFT_INCLUDE_NUMERICSWIFT=1` to enable it.

The Number Theory module exposes number-theoretic arithmetic functions under the `math.numtheory` namespace (also accessible as `luaswift.numtheory`). Functions cover primality testing, prime generation, factorization, multiplicative arithmetic functions, and analytic number theory tools.

## Installation

```swift
// Requires LUASWIFT_INCLUDE_NUMERICSWIFT=1 at build time
try NumberTheoryModule.install(in: engine)

// Or install all modules (only activates when NumericSwift is present)
try ModuleRegistry.install(in: engine)
```

```lua
local nt = math.numtheory
-- Also available as: luaswift.numtheory
```

## Primality

### nt.is_prime(n)

Returns `true` if `n` is prime, `false` otherwise. Returns `nil` for invalid input.

```lua
print(nt.is_prime(17))   -- true
print(nt.is_prime(18))   -- false
print(nt.is_prime(97))   -- true
print(nt.is_prime(1))    -- false
```

### nt.prime_pi(x)  · alias: nt.pi

Prime counting function π(x): number of primes ≤ x.

```lua
print(nt.prime_pi(100))   -- 25
print(nt.prime_pi(1000))  -- 168
print(nt.pi(100))         -- 25  (alias)
```

### nt.primes_up_to(n)

Returns a 1-indexed Lua array of all primes up to and including `n`. Returns an empty array when `n < 2`.

```lua
local p = nt.primes_up_to(30)
-- {2, 3, 5, 7, 11, 13, 17, 19, 23, 29}

for i, prime in ipairs(p) do
    io.write(prime .. " ")
end
```

## Factorization

### nt.factor(n)

Prime factorization of `n`. Returns a **string-keyed table** mapping each prime factor (as a string) to its exponent. Returns `nil` when `n < 1`.

```lua
local f = nt.factor(60)
-- f["2"] == 2, f["3"] == 1, f["5"] == 1
-- Means: 60 = 2² × 3¹ × 5¹

for prime_str, exp in pairs(f) do
    print(prime_str .. "^" .. exp)
end
-- Output (order unspecified):
-- 2^2
-- 3^1
-- 5^1
```

> Note: Keys are **strings**, not numbers. Use `tonumber(prime_str)` when numeric ordering matters.

```lua
-- Reconstruct the value from its factorization
local function from_factors(t)
    local result = 1
    for p_str, e in pairs(t) do
        result = result * tonumber(p_str)^e
    end
    return result
end

print(from_factors(nt.factor(360)))  -- 360
```

## GCD and LCM

### nt.gcd(a, b)

Greatest common divisor of two integers. Returns `nil` if fewer than two valid integers are supplied.

```lua
print(nt.gcd(48, 18))  -- 6
print(nt.gcd(17, 19))  -- 1  (coprime)
```

### nt.lcm(a, b)

Least common multiple of two integers.

```lua
print(nt.lcm(12, 18))  -- 36
print(nt.lcm(7, 5))    -- 35
```

## Multiplicative Functions

### nt.euler_phi(n)  · alias: nt.phi

Euler's totient φ(n): count of integers 1 ≤ k ≤ n that are coprime to n.

```lua
print(nt.euler_phi(9))   -- 6  (1,2,4,5,7,8)
print(nt.euler_phi(10))  -- 4  (1,3,7,9)
print(nt.euler_phi(12))  -- 4
print(nt.phi(12))        -- 4  (alias)
```

### nt.divisor_sigma(n, k)  · alias: nt.sigma

Divisor sigma function σ_k(n): sum of the k-th powers of the divisors of n. When `k` is omitted it defaults to 1.

| k | Meaning |
|---|---------|
| 0 | Number of divisors τ(n) |
| 1 | Sum of divisors σ(n) (default) |
| 2 | Sum of squares of divisors |

```lua
print(nt.divisor_sigma(12, 0))  -- 6  (divisors: 1,2,3,4,6,12)
print(nt.divisor_sigma(12, 1))  -- 28 (1+2+3+4+6+12)
print(nt.divisor_sigma(12))     -- 28 (k defaults to 1)
print(nt.sigma(12, 0))          -- 6  (alias)
```

### nt.mobius(n)  · alias: nt.mu

Möbius function μ(n).

- μ(n) = 1 if n = 1 or n is a product of an even number of distinct primes
- μ(n) = −1 if n is a product of an odd number of distinct primes
- μ(n) = 0 if n has a squared prime factor

```lua
print(nt.mobius(1))   -- 1
print(nt.mobius(6))   -- 1   (2×3, two distinct primes)
print(nt.mobius(30))  -- -1  (2×3×5, three distinct primes)
print(nt.mobius(4))   -- 0   (2², squared factor)
print(nt.mu(30))      -- -1  (alias)
```

### nt.liouville(n)

Liouville function λ(n) = (−1)^Ω(n), where Ω(n) is the total number of prime factors counted with multiplicity.

```lua
print(nt.liouville(1))   -- 1
print(nt.liouville(4))   -- 1   (4 = 2², Ω=2)
print(nt.liouville(6))   -- 1   (6 = 2×3, Ω=2)
print(nt.liouville(12))  -- 1   (12 = 2²×3, Ω=3 → -1)
```

### nt.carmichael(n)

Carmichael (reduced totient) function λ(n): the smallest positive integer m such that a^m ≡ 1 (mod n) for every a coprime to n.

```lua
print(nt.carmichael(1))   -- 1
print(nt.carmichael(8))   -- 2
print(nt.carmichael(15))  -- 4
```

## Analytic Number Theory

### nt.chebyshev_theta(x)  · alias: nt.theta

First Chebyshev function θ(x) = Σ log(p) for all primes p ≤ x.

```lua
print(nt.chebyshev_theta(10))   -- ~7.61 (log2+log3+log5+log7)
print(nt.theta(100))            -- ~94.0 (alias)
```

### nt.chebyshev_psi(x)  · alias: nt.psi

Second Chebyshev function ψ(x) = Σ Λ(n) for n ≤ x, where Λ is the von Mangoldt function.

```lua
print(nt.chebyshev_psi(10))   -- ~10.07
print(nt.psi(100))            -- ~98.7 (alias)
```

### nt.mangoldt(n)  · alias: nt.Lambda

Von Mangoldt function Λ(n).

- Λ(n) = log(p) if n = p^k for some prime p and k ≥ 1
- Λ(n) = 0 otherwise

```lua
print(nt.mangoldt(1))   -- 0
print(nt.mangoldt(2))   -- ~0.693 (log 2)
print(nt.mangoldt(4))   -- ~0.693 (4 = 2², log 2)
print(nt.mangoldt(6))   -- 0      (not a prime power)
print(nt.Lambda(7))     -- ~1.946 (log 7, alias)
```

## Function Aliases

The module exposes shorter aliases for notation familiar from analytic number theory:

| Long form | Alias |
|-----------|-------|
| `euler_phi` | `phi` |
| `divisor_sigma` | `sigma` |
| `mobius` | `mu` |
| `mangoldt` | `Lambda` |
| `prime_pi` | `pi` |
| `chebyshev_theta` | `theta` |
| `chebyshev_psi` | `psi` |

## Applications

### Checking Multiplicativity

```lua
-- φ is multiplicative: φ(mn) = φ(m)φ(n) when gcd(m,n)=1
local m, n = 4, 9
if nt.gcd(m, n) == 1 then
    assert(nt.euler_phi(m * n) == nt.euler_phi(m) * nt.euler_phi(n))
    print("multiplicativity holds for", m, n)
end
```

### Factorization Display

```lua
-- Pretty-print the prime factorization of a number
local function factorization(n)
    local parts = {}
    for p_str, e in pairs(nt.factor(n)) do
        local p = tonumber(p_str)
        if e == 1 then
            table.insert(parts, p_str)
        else
            table.insert(parts, p_str .. "^" .. e)
        end
    end
    -- Sort for deterministic output
    table.sort(parts, function(a, b)
        return tonumber(a:match("^%d+")) < tonumber(b:match("^%d+"))
    end)
    return n .. " = " .. table.concat(parts, " × ")
end

print(factorization(360))  -- 360 = 2^3 × 3^2 × 5
print(factorization(2310)) -- 2310 = 2 × 3 × 5 × 7 × 11
```

### Coprimality with GCD

```lua
-- Numbers coprime to 12 in [1, 20]  (should be φ(12)=4 per period)
local coprimes = {}
for i = 1, 20 do
    if nt.gcd(i, 12) == 1 then
        table.insert(coprimes, i)
    end
end
-- {1, 5, 7, 11, 13, 17, 19}
print(#coprimes)  -- 7
```

### Goldbach Conjecture Verification

```lua
local function verify_goldbach(n)
    assert(n % 2 == 0 and n > 2, "n must be even and > 2")
    local primes = nt.primes_up_to(n)
    for _, p in ipairs(primes) do
        if nt.is_prime(n - p) then
            return p, n - p
        end
    end
end

local p1, p2 = verify_goldbach(100)
print("100 = " .. p1 .. " + " .. p2)  -- 100 = 3 + 97
```

### Chebyshev Prime Number Theorem Approximation

```lua
-- θ(x) / x → 1 as x → ∞ (Prime Number Theorem)
for _, x in ipairs({100, 1000, 10000}) do
    local ratio = nt.chebyshev_theta(x) / x
    print(string.format("θ(%d)/x = %.4f", x, ratio))
end
```

## Performance Notes

- `primes_up_to` uses a sieve; `prime_pi` and Chebyshev functions iterate over sieve output.
- `factor` delegates to NumericSwift's factorization; performance depends on the NumericSwift version linked.
- All functions that accept integers return `nil` (not an error) for out-of-range or invalid input.

## See Also

- ``NumberTheoryModule``
- <doc:MathXModule>
- <doc:SpecialModule>
