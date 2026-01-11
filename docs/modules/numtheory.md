# Number Theory Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.numtheory` | **Global:** `math.numtheory`

The Number Theory module provides number-theoretic arithmetic functions including primality testing, factorization, divisor functions, and classical arithmetic functions used in analytic number theory.

## Overview

Number theory operations cover:
- **Primes**: Primality testing, prime generation, prime counting
- **Factorization**: Prime factorization, GCD, LCM
- **Arithmetic functions**: Euler's totient, divisor sigma, Möbius, Liouville, Carmichael
- **Analytic functions**: Chebyshev theta/psi, von Mangoldt

All functions use trial division and the Sieve of Eratosthenes for efficient computation.

## Basic Operations

### Primality Testing

```lua
local nt = math.numtheory

-- Check if number is prime
print(nt.is_prime(17))     -- true
print(nt.is_prime(18))     -- false
print(nt.is_prime(2))      -- true
print(nt.is_prime(1))      -- false
```

### Prime Generation

```lua
-- Generate all primes up to 30
local primes = nt.primes_up_to(30)
-- {2, 3, 5, 7, 11, 13, 17, 19, 23, 29}

-- Count primes up to 100 (π(x) function)
print(nt.prime_pi(100))    -- 25
print(nt.pi(100))          -- 25 (alias)
```

### Prime Factorization

```lua
-- Factorize into prime powers
local factors = nt.factor(360)
-- {["2"] = 3, ["3"] = 2, ["5"] = 1}
-- Represents 360 = 2³ × 3² × 5¹

-- Iterate over factors
for prime, exponent in pairs(factors) do
    print(string.format("%s^%d", prime, exponent))
end
```

### GCD and LCM

```lua
-- Greatest common divisor
print(nt.gcd(48, 18))      -- 6
print(nt.gcd(100, 35))     -- 5

-- Least common multiple
print(nt.lcm(12, 18))      -- 36
print(nt.lcm(4, 6))        -- 12
```

## Arithmetic Functions

### Euler's Totient Function

Counts integers 1 ≤ k ≤ n that are coprime to n.

```lua
-- φ(n) = count of numbers coprime to n
print(nt.euler_phi(12))    -- 4  (1,5,7,11 are coprime to 12)
print(nt.phi(12))          -- 4  (alias)
print(nt.euler_phi(9))     -- 6  (1,2,4,5,7,8)
print(nt.euler_phi(7))     -- 6  (prime: φ(p) = p-1)
```

### Divisor Sigma Function

Sum of k-th powers of divisors.

```lua
-- σ_k(n) = sum of k-th powers of divisors
print(nt.divisor_sigma(12, 0))  -- 6   (count of divisors)
print(nt.divisor_sigma(12, 1))  -- 28  (sum of divisors: 1+2+3+4+6+12)
print(nt.divisor_sigma(12, 2))  -- 210 (sum of squares: 1+4+9+16+36+144)

-- Default k=1
print(nt.sigma(12))        -- 28
```

### Möbius Function

Detects square-free integers with sign based on prime factor count.

```lua
-- μ(n) = (-1)^k if n is product of k distinct primes
--      = 0 if n has squared prime factor
print(nt.mobius(1))        -- 1   (special case)
print(nt.mobius(6))        -- 1   (2 × 3, two distinct primes: (-1)²)
print(nt.mobius(30))       -- -1  (2 × 3 × 5, three primes: (-1)³)
print(nt.mobius(12))       -- 0   (2² × 3 has squared factor)
print(nt.mu(30))           -- -1  (alias)
```

### Liouville Function

Sign based on total prime factor count (with multiplicity).

```lua
-- λ(n) = (-1)^Ω(n) where Ω(n) counts prime factors with multiplicity
print(nt.liouville(1))     -- 1   (no factors)
print(nt.liouville(4))     -- 1   (2² has 2 factors: (-1)²)
print(nt.liouville(8))     -- -1  (2³ has 3 factors: (-1)³)
print(nt.liouville(30))    -- -1  (2×3×5 has 3 factors)
```

### Carmichael Function

Smallest exponent m such that a^m ≡ 1 (mod n) for all a coprime to n.

```lua
-- λ(n) = Carmichael reduced totient function
print(nt.carmichael(12))   -- 2   (smaller than φ(12) = 4)
print(nt.carmichael(15))   -- 4
print(nt.carmichael(16))   -- 8
```

## Analytic Functions

### Chebyshev Functions

Used in analytic number theory for studying prime distribution.

```lua
-- θ(x) = sum of log(p) for all primes p ≤ x
print(nt.chebyshev_theta(10))   -- log(2) + log(3) + log(5) + log(7)
print(nt.theta(10))             -- alias

-- ψ(x) = sum of Λ(n) for all n ≤ x (see von Mangoldt below)
print(nt.chebyshev_psi(10))
print(nt.psi(10))               -- alias
```

### Von Mangoldt Function

Returns log(p) if n is a prime power, 0 otherwise.

```lua
-- Λ(n) = log(p) if n = p^k for prime p, else 0
print(nt.mangoldt(2))      -- log(2) ≈ 0.693
print(nt.mangoldt(8))      -- log(2) ≈ 0.693 (8 = 2³)
print(nt.mangoldt(6))      -- 0 (not a prime power)
print(nt.Lambda(9))        -- log(3) ≈ 1.099 (alias)
```

## Practical Examples

### Finding Perfect Numbers

Numbers equal to the sum of their proper divisors.

```lua
local nt = math.numtheory

-- Perfect number: σ(n) - n = n → σ(n) = 2n
for n = 2, 10000 do
    if nt.divisor_sigma(n, 1) == 2 * n then
        print("Perfect number:", n)
    end
end
-- Output: 6, 28, 496, 8128
```

### Goldbach Conjecture Testing

Every even integer > 2 is the sum of two primes.

```lua
local nt = math.numtheory

local function verify_goldbach(n)
    for i = 2, n/2 do
        if nt.is_prime(i) and nt.is_prime(n - i) then
            return i, n - i
        end
    end
    return nil
end

-- Test even numbers
for n = 4, 100, 2 do
    local p1, p2 = verify_goldbach(n)
    if p1 then
        print(string.format("%d = %d + %d", n, p1, p2))
    end
end
```

### Prime Gaps Analysis

```lua
local nt = math.numtheory

local primes = nt.primes_up_to(1000)
local max_gap = 0
local gap_start = 0

for i = 1, #primes - 1 do
    local gap = primes[i+1] - primes[i]
    if gap > max_gap then
        max_gap = gap
        gap_start = primes[i]
    end
end

print(string.format("Largest gap: %d (after prime %d)", max_gap, gap_start))
```

### RSA Key Parameter Validation

```lua
local nt = math.numtheory

local function validate_rsa_primes(p, q)
    -- Both must be prime
    if not (nt.is_prime(p) and nt.is_prime(q)) then
        return false, "p and q must be prime"
    end

    -- Must be distinct
    if p == q then
        return false, "p and q must be distinct"
    end

    local n = p * q
    local phi_n = (p - 1) * (q - 1)

    -- Common e = 65537
    local e = 65537
    if nt.gcd(e, phi_n) ~= 1 then
        return false, "e and φ(n) must be coprime"
    end

    return true, n, phi_n
end

-- Example with small primes
local ok, n, phi = validate_rsa_primes(61, 53)
print(ok, n, phi)  -- true, 3233, 3120
```

### Dirichlet Series Evaluation

```lua
local nt = math.numtheory

-- Evaluate Σ μ(n)/n^s for small s
local function dirichlet_mu(s, max_n)
    local sum = 0
    for n = 1, max_n do
        sum = sum + nt.mobius(n) / n^s
    end
    return sum
end

-- Should approach 1/ζ(s) as max_n → ∞
print(dirichlet_mu(2, 1000))    -- ≈ 0.608 (1/ζ(2) = 6/π² ≈ 0.608)
```

## Algorithm Notes

**Primality Testing**: Trial division checking factors up to √n. Efficient for n < 10^9.

**Sieve of Eratosthenes**: Used for bulk prime generation. Memory usage is O(n).

**Prime Factorization**: Trial division up to √n. Returns factors as {[prime]=exponent}.

**Arithmetic Functions**: All computed via prime factorization using multiplicative formulas:
- φ(n) = n × Π(1 - 1/p) for prime factors p
- σ_k(n) = Π((p^(k(e+1)) - 1)/(p^k - 1)) for factors p^e

**Performance**: Suitable for integers up to 10^9. For larger values or cryptographic applications, consider specialized libraries.

## Function Reference

| Function | Description | Example |
|----------|-------------|---------|
| `is_prime(n)` | Test if n is prime | `is_prime(17) → true` |
| `primes_up_to(n)` | Generate primes ≤ n | `primes_up_to(20) → {2,3,5,7,11,13,17,19}` |
| `prime_pi(x)` / `pi(x)` | Count primes ≤ x | `pi(100) → 25` |
| `factor(n)` | Prime factorization | `factor(12) → {["2"]=2, ["3"]=1}` |
| `gcd(a, b)` | Greatest common divisor | `gcd(48, 18) → 6` |
| `lcm(a, b)` | Least common multiple | `lcm(12, 18) → 36` |
| `euler_phi(n)` / `phi(n)` | Euler's totient φ(n) | `phi(12) → 4` |
| `divisor_sigma(n, k)` / `sigma(n, k)` | Sum of k-th powers of divisors | `sigma(12, 0) → 6` |
| `mobius(n)` / `mu(n)` | Möbius function μ(n) | `mu(30) → -1` |
| `liouville(n)` | Liouville function λ(n) | `liouville(8) → -1` |
| `carmichael(n)` | Carmichael function λ(n) | `carmichael(12) → 2` |
| `chebyshev_theta(x)` / `theta(x)` | Chebyshev θ(x) | `theta(10) → ~4.187` |
| `chebyshev_psi(x)` / `psi(x)` | Chebyshev ψ(x) | `psi(10) → ~6.161` |
| `mangoldt(n)` / `Lambda(n)` | Von Mangoldt Λ(n) | `Lambda(8) → log(2)` |
