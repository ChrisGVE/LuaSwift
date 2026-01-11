# Number Theory Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.numtheory` | **Global:** `math.numtheory`

The Number Theory module provides number-theoretic arithmetic functions including primality testing, factorization, divisor functions, and classical arithmetic functions used in analytic number theory.

## Function Reference

| Function | Description |
|----------|-------------|
| [is_prime(n)](#is_prime) | Test if n is prime |
| [primes_up_to(n)](#primes_up_to) | Generate all primes up to n |
| [prime_pi(x)](#prime_pi) | Count primes up to x (π(x) function) |
| [pi(x)](#pi) | Alias for prime_pi |
| [factor(n)](#factor) | Prime factorization |
| [gcd(a, b)](#gcd) | Greatest common divisor |
| [lcm(a, b)](#lcm) | Least common multiple |
| [euler_phi(n)](#euler_phi) | Euler's totient function φ(n) |
| [phi(n)](#phi) | Alias for euler_phi |
| [divisor_sigma(n, k)](#divisor_sigma) | Sum of k-th powers of divisors |
| [sigma(n, k?)](#sigma) | Alias for divisor_sigma (k defaults to 1) |
| [mobius(n)](#mobius) | Möbius function μ(n) |
| [mu(n)](#mu) | Alias for mobius |
| [liouville(n)](#liouville) | Liouville function λ(n) |
| [carmichael(n)](#carmichael) | Carmichael function λ(n) |
| [chebyshev_theta(x)](#chebyshev_theta) | Chebyshev θ(x) function |
| [theta(x)](#theta) | Alias for chebyshev_theta |
| [chebyshev_psi(x)](#chebyshev_psi) | Chebyshev ψ(x) function |
| [psi(x)](#psi) | Alias for chebyshev_psi |
| [mangoldt(n)](#mangoldt) | Von Mangoldt function Λ(n) |
| [Lambda(n)](#Lambda) | Alias for mangoldt |

## Type Mapping

| Mathematical Notation | Lua Representation |
|-----------------------|--------------------|
| Prime factors of n | Table `{[prime]=exponent}` |
| Set of primes | Array `{2, 3, 5, 7, ...}` |
| φ(n), σ(n), μ(n), λ(n) | Number |

---

## is_prime

```
is_prime(n) -> boolean
```

Test if n is prime using trial division.

**Parameters:**
- `n` - Integer to test

```lua
local nt = math.numtheory

print(nt.is_prime(17))     -- true
print(nt.is_prime(18))     -- false
print(nt.is_prime(2))      -- true (smallest prime)
print(nt.is_prime(1))      -- false (1 is not prime)
```

**Algorithm:** Trial division checking factors up to √n. Efficient for n < 10^9.

---

## primes_up_to

```
primes_up_to(n) -> array
```

Generate all primes up to n using the Sieve of Eratosthenes.

**Parameters:**
- `n` - Upper bound (inclusive)

**Returns:** Array of primes in ascending order

```lua
local primes = nt.primes_up_to(30)
-- {2, 3, 5, 7, 11, 13, 17, 19, 23, 29}

local small_primes = nt.primes_up_to(10)
-- {2, 3, 5, 7}
```

**Note:** Memory usage is O(n).

---

## prime_pi

```
prime_pi(x) -> number
```

Count primes up to x (the π(x) function from number theory).

**Parameters:**
- `x` - Upper bound

**Returns:** Number of primes ≤ x

```lua
print(nt.prime_pi(100))    -- 25
print(nt.prime_pi(10))     -- 4  (primes: 2, 3, 5, 7)
print(nt.prime_pi(1))      -- 0  (no primes ≤ 1)
```

---

## pi

```
pi(x) -> number
```

Alias for `prime_pi(x)`.

```lua
print(nt.pi(100))          -- 25
```

---

## factor

```
factor(n) -> table
```

Prime factorization of n.

**Parameters:**
- `n` - Integer to factor

**Returns:** Table `{[prime]=exponent}` representing n = p₁^e₁ × p₂^e₂ × ...

```lua
local factors = nt.factor(360)
-- {["2"] = 3, ["3"] = 2, ["5"] = 1}
-- Represents 360 = 2³ × 3² × 5¹

-- Iterate over factors
for prime, exponent in pairs(factors) do
    print(string.format("%s^%d", prime, exponent))
end

local factors12 = nt.factor(12)
-- {["2"] = 2, ["3"] = 1}
-- Represents 12 = 2² × 3¹
```

**Algorithm:** Trial division up to √n.

---

## gcd

```
gcd(a, b) -> number
```

Greatest common divisor using Euclidean algorithm.

**Parameters:**
- `a` - First integer
- `b` - Second integer

```lua
print(nt.gcd(48, 18))      -- 6
print(nt.gcd(100, 35))     -- 5
print(nt.gcd(17, 19))      -- 1  (coprime)
```

---

## lcm

```
lcm(a, b) -> number
```

Least common multiple.

**Parameters:**
- `a` - First integer
- `b` - Second integer

```lua
print(nt.lcm(12, 18))      -- 36
print(nt.lcm(4, 6))        -- 12
print(nt.lcm(7, 5))        -- 35  (coprime: lcm = product)
```

---

## euler_phi

```
euler_phi(n) -> number
```

Euler's totient function φ(n): counts integers 1 ≤ k ≤ n that are coprime to n.

**Parameters:**
- `n` - Integer

```lua
print(nt.euler_phi(12))    -- 4  (1, 5, 7, 11 are coprime to 12)
print(nt.euler_phi(9))     -- 6  (1, 2, 4, 5, 7, 8)
print(nt.euler_phi(7))     -- 6  (prime: φ(p) = p-1)
```

**Formula:** φ(n) = n × Π(1 - 1/p) for prime factors p

---

## phi

```
phi(n) -> number
```

Alias for `euler_phi(n)`.

```lua
print(nt.phi(12))          -- 4
```

---

## divisor_sigma

```
divisor_sigma(n, k) -> number
```

Sum of k-th powers of divisors: σₖ(n) = Σ(d^k) for all divisors d of n.

**Parameters:**
- `n` - Integer
- `k` - Power (0 for count, 1 for sum, 2 for sum of squares, etc.)

```lua
print(nt.divisor_sigma(12, 0))  -- 6   (count of divisors: 1,2,3,4,6,12)
print(nt.divisor_sigma(12, 1))  -- 28  (sum: 1+2+3+4+6+12)
print(nt.divisor_sigma(12, 2))  -- 210 (sum of squares: 1+4+9+16+36+144)
```

**Formula:** σₖ(n) = Π((p^(k(e+1)) - 1)/(p^k - 1)) for prime factors p^e

---

## sigma

```
sigma(n, k?) -> number
```

Alias for `divisor_sigma(n, k)`. Default k=1 (sum of divisors).

```lua
print(nt.sigma(12))        -- 28  (sum of divisors)
print(nt.sigma(12, 0))     -- 6   (count of divisors)
```

---

## mobius

```
mobius(n) -> number
```

Möbius function μ(n): detects square-free integers with sign based on prime factor count.

**Returns:**
- `1` if n = 1
- `(-1)^k` if n is product of k distinct primes
- `0` if n has a squared prime factor

**Parameters:**
- `n` - Integer

```lua
print(nt.mobius(1))        -- 1   (special case)
print(nt.mobius(6))        -- 1   (2 × 3: two distinct primes, (-1)²)
print(nt.mobius(30))       -- -1  (2 × 3 × 5: three primes, (-1)³)
print(nt.mobius(12))       -- 0   (2² × 3 has squared factor)
```

---

## mu

```
mu(n) -> number
```

Alias for `mobius(n)`.

```lua
print(nt.mu(30))           -- -1
```

---

## liouville

```
liouville(n) -> number
```

Liouville function λ(n): sign based on total prime factor count with multiplicity.

**Returns:** `(-1)^Ω(n)` where Ω(n) counts prime factors with multiplicity

**Parameters:**
- `n` - Integer

```lua
print(nt.liouville(1))     -- 1   (no factors)
print(nt.liouville(4))     -- 1   (2² has 2 factors: (-1)²)
print(nt.liouville(8))     -- -1  (2³ has 3 factors: (-1)³)
print(nt.liouville(30))    -- -1  (2×3×5 has 3 factors)
```

---

## carmichael

```
carmichael(n) -> number
```

Carmichael function λ(n): smallest exponent m such that a^m ≡ 1 (mod n) for all a coprime to n.

**Parameters:**
- `n` - Integer

```lua
print(nt.carmichael(12))   -- 2   (smaller than φ(12) = 4)
print(nt.carmichael(15))   -- 4
print(nt.carmichael(16))   -- 8
```

**Note:** Also called the reduced totient function. Always divides φ(n).

---

## chebyshev_theta

```
chebyshev_theta(x) -> number
```

Chebyshev θ(x) function: sum of log(p) for all primes p ≤ x.

**Parameters:**
- `x` - Upper bound

```lua
print(nt.chebyshev_theta(10))   -- log(2) + log(3) + log(5) + log(7)
```

**Usage:** Analytic number theory, studying prime distribution.

---

## theta

```
theta(x) -> number
```

Alias for `chebyshev_theta(x)`.

```lua
print(nt.theta(10))             -- Same as chebyshev_theta(10)
```

---

## chebyshev_psi

```
chebyshev_psi(x) -> number
```

Chebyshev ψ(x) function: sum of Λ(n) for all n ≤ x (where Λ is the von Mangoldt function).

**Parameters:**
- `x` - Upper bound

```lua
print(nt.chebyshev_psi(10))
```

**Usage:** Analytic number theory, prime number theorem.

---

## psi

```
psi(x) -> number
```

Alias for `chebyshev_psi(x)`.

```lua
print(nt.psi(10))               -- Same as chebyshev_psi(10)
```

---

## mangoldt

```
mangoldt(n) -> number
```

Von Mangoldt function Λ(n): returns log(p) if n is a prime power p^k, otherwise 0.

**Parameters:**
- `n` - Integer

**Returns:**
- `log(p)` if n = p^k for some prime p and k ≥ 1
- `0` otherwise

```lua
print(nt.mangoldt(2))      -- log(2) ≈ 0.693
print(nt.mangoldt(8))      -- log(2) ≈ 0.693 (8 = 2³)
print(nt.mangoldt(9))      -- log(3) ≈ 1.099 (9 = 3²)
print(nt.mangoldt(6))      -- 0 (not a prime power)
```

---

## Lambda

```
Lambda(n) -> number
```

Alias for `mangoldt(n)`.

```lua
print(nt.Lambda(8))        -- log(2) ≈ 0.693
```

---

## Examples

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

---

## Performance Notes

**Primality Testing**: Trial division checking factors up to √n. Efficient for n < 10^9.

**Sieve of Eratosthenes**: Used for bulk prime generation. Memory usage is O(n).

**Prime Factorization**: Trial division up to √n. Returns factors as {[prime]=exponent}.

**Arithmetic Functions**: All computed via prime factorization using multiplicative formulas.

**Range**: Suitable for integers up to 10^9. For larger values or cryptographic applications, consider specialized libraries.
