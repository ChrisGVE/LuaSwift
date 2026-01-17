# Number Theory Module

Prime numbers, factorization, and number-theoretic functions.

## Overview

The Number Theory module provides algorithms for working with integers including primality testing, factorization, and number-theoretic functions. Available under `math.numtheory` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local nt = math.numtheory
```

## Prime Numbers

### nt.is_prime(n)
Test if n is prime.

```lua
print(nt.is_prime(17))   -- true
print(nt.is_prime(18))   -- false
print(nt.is_prime(97))   -- true
```

### nt.primes(n)
Generate all primes up to n.

```lua
local primes = nt.primes(30)
-- {2, 3, 5, 7, 11, 13, 17, 19, 23, 29}

for _, p in ipairs(primes) do
    print(p)
end
```

### nt.nth_prime(n)
Get the nth prime number.

```lua
print(nt.nth_prime(1))    -- 2
print(nt.nth_prime(10))   -- 29
print(nt.nth_prime(100))  -- 541
```

### nt.prime_count(n)
Count primes ≤ n (π(n)).

```lua
print(nt.prime_count(100))  -- 25
print(nt.prime_count(1000)) -- 168
```

## Factorization

### nt.factor(n)
Prime factorization of n.

```lua
local factors = nt.factor(60)
-- {{2, 2}, {3, 1}, {5, 1}}
-- Means: 60 = 2² × 3¹ × 5¹

for _, pair in ipairs(factors) do
    local prime, exponent = pair[1], pair[2]
    print(prime .. "^" .. exponent)
end
```

### nt.divisors(n)
All divisors of n.

```lua
local divs = nt.divisors(12)
-- {1, 2, 3, 4, 6, 12}
```

### nt.num_divisors(n)
Count of divisors (τ(n)).

```lua
print(nt.num_divisors(12))  -- 6
```

### nt.sum_divisors(n)
Sum of divisors (σ(n)).

```lua
print(nt.sum_divisors(12))  -- 28 (1+2+3+4+6+12)
```

## GCD and LCM

### nt.gcd(a, b)
Greatest common divisor.

```lua
print(nt.gcd(48, 18))  -- 6
print(nt.gcd(17, 19))  -- 1 (coprime)
```

### nt.lcm(a, b)
Least common multiple.

```lua
print(nt.lcm(12, 18))  -- 36
```

### nt.extended_gcd(a, b)
Extended Euclidean algorithm: returns gcd, x, y where ax + by = gcd.

```lua
local g, x, y = nt.extended_gcd(48, 18)
print("gcd:", g)        -- 6
print("48*" .. x .. " + 18*" .. y .. " = " .. g)
```

## Modular Arithmetic

### nt.mod_pow(base, exp, mod)
Modular exponentiation: base^exp mod mod.

```lua
print(nt.mod_pow(2, 10, 1000))  -- 24 (2^10 mod 1000)
print(nt.mod_pow(3, 100, 7))    -- 4
```

### nt.mod_inverse(a, m)
Modular multiplicative inverse: find x where ax ≡ 1 (mod m).

```lua
local inv = nt.mod_inverse(3, 11)
print(inv)              -- 4 (because 3*4 = 12 ≡ 1 mod 11)
```

## Totient and Möbius

### nt.euler_phi(n)
Euler's totient function φ(n): count of numbers ≤ n coprime to n.

```lua
print(nt.euler_phi(9))   -- 6 (1,2,4,5,7,8 are coprime to 9)
print(nt.euler_phi(10))  -- 4 (1,3,7,9)
```

### nt.mobius(n)
Möbius function μ(n).

```lua
print(nt.mobius(6))   -- 1  (two distinct prime factors)
print(nt.mobius(4))   -- 0  (squared prime factor)
print(nt.mobius(30))  -- -1 (three distinct prime factors)
```

## Perfect Numbers

### nt.is_perfect(n)
Check if n equals the sum of its proper divisors.

```lua
print(nt.is_perfect(6))    -- true (1+2+3 = 6)
print(nt.is_perfect(28))   -- true (1+2+4+7+14 = 28)
print(nt.is_perfect(12))   -- false
```

## Applications

### RSA Key Generation

```lua
-- Simplified RSA demonstration
local p = 61  -- Prime 1
local q = 53  -- Prime 2
local n = p * q  -- 3233

-- Compute φ(n)
local phi = (p - 1) * (q - 1)  -- 3120

-- Choose e coprime to φ(n)
local e = 17
assert(nt.gcd(e, phi) == 1, "e must be coprime to φ(n)")

-- Compute d (private key)
local d = nt.mod_inverse(e, phi)

print("Public key: (e=" .. e .. ", n=" .. n .. ")")
print("Private key: (d=" .. d .. ", n=" .. n .. ")")

-- Encrypt message m
local m = 123
local c = nt.mod_pow(m, e, n)
print("Ciphertext:", c)

-- Decrypt
local decrypted = nt.mod_pow(c, d, n)
print("Decrypted:", decrypted)  -- 123
```

### Checking Coprimality

```lua
-- Find numbers coprime to 12 in range [1, 20]
local coprimes = {}
for i = 1, 20 do
    if nt.gcd(i, 12) == 1 then
        table.insert(coprimes, i)
    end
end
-- {1, 5, 7, 11, 13, 17, 19}
```

### Prime Gaps

```lua
-- Find gaps between consecutive primes
local primes = nt.primes(100)
for i = 2, #primes do
    local gap = primes[i] - primes[i-1]
    print("Gap between " .. primes[i-1] .. " and " .. primes[i] .. ": " .. gap)
end
```

### Goldbach Conjecture Verification

```lua
-- Verify: every even number > 2 is sum of two primes
local function verify_goldbach(n)
    assert(n % 2 == 0 and n > 2, "n must be even and > 2")

    for i = 2, n/2 do
        if nt.is_prime(i) and nt.is_prime(n - i) then
            return i, n - i
        end
    end
    return nil
end

local p1, p2 = verify_goldbach(100)
print("100 = " .. p1 .. " + " .. p2)  -- 100 = 3 + 97 (or other)
```

### Collatz Sequence

```lua
-- Generate Collatz sequence
local function collatz_length(n)
    local length = 0
    while n ~= 1 do
        if n % 2 == 0 then
            n = n / 2
        else
            n = 3 * n + 1
        end
        length = length + 1
    end
    return length
end

-- Find number with longest sequence up to 100
local max_len, max_n = 0, 0
for i = 1, 100 do
    local len = collatz_length(i)
    if len > max_len then
        max_len, max_n = len, i
    end
end
print("Longest sequence: " .. max_n .. " (length " .. max_len .. ")")
```

## Performance Notes

- Uses Miller-Rabin primality test for large numbers
- Sieve of Eratosthenes for generating primes
- Trial division for small factorizations
- Pollard's rho for large factorizations

## See Also

- ``NumberTheoryModule``
- <doc:MathXModule>
- <doc:Modules/SpecialModule>
