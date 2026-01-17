# Series Module

Taylor series, infinite series summation, and infinite products.

## Overview

The Series module provides tools for working with Taylor series expansions, computing infinite series, and evaluating infinite products. Available under `math.series` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local series = math.series
```

## Taylor Series

### series.taylor(f, x0, n)
Compute Taylor series coefficients.

```lua
-- Taylor series for sin(x) around x=0
local function f(x) return math.sin(x) end

local coeffs = series.taylor(f, 0, 5)
-- coeffs[1] = f(0)
-- coeffs[2] = f'(0)
-- coeffs[3] = f''(0)/2!
-- etc.
```

### series.taylor_eval(coeffs, x, x0?)
Evaluate Taylor series at x.

```lua
local coeffs = {0, 1, 0, -1/6, 0, 1/120}  -- sin(x)
local result = series.taylor_eval(coeffs, 0.5, 0)
print(result)  -- ≈ sin(0.5)
```

## Infinite Series

### series.sum(f, start, options?)
Compute infinite series Σf(n) from n=start to infinity.

```lua
-- Sum of 1/n^2 (converges to π²/6)
local function term(n)
    return 1 / (n * n)
end

local result = series.sum(term, 1, {tol = 1e-10, maxiter = 10000})
print(result)  -- ≈ 1.6449... (π²/6)
```

### Options

```lua
local result = series.sum(f, start, {
    tol = 1e-8,      -- Convergence tolerance
    maxiter = 1000,  -- Maximum terms
    method = "kahan" -- Summation algorithm
})
```

## Partial Sums

### series.partial_sum(f, start, n)
Compute sum of first n terms.

```lua
-- Sum of geometric series: Σr^n for n=0 to 9
local function term(n)
    local r = 0.5
    return r^n
end

local s = series.partial_sum(term, 0, 10)
-- For geometric: s = (1 - r^10) / (1 - r)
```

## Infinite Products

### series.product(f, start, options?)
Compute infinite product Πf(n) from n=start to infinity.

```lua
-- Wallis product for π/2: Π(4n²/(4n²-1))
local function term(n)
    local num = 4 * n * n
    local den = num - 1
    return num / den
end

local result = series.product(term, 1, {tol = 1e-10})
print(result * 2)  -- ≈ π
```

## Acceleration Methods

### series.shanks(sequence)
Apply Shanks transformation for faster convergence.

```lua
-- Slowly converging alternating series
local terms = {}
for n = 1, 20 do
    terms[n] = (-1)^(n+1) / n  -- ln(2)
end

local improved = series.shanks(terms)
-- Converges faster to ln(2)
```

### series.richardson(f, x, h, n?)
Richardson extrapolation.

```lua
-- Improve numerical derivative estimate
local function f(x) return math.sin(x) end

local derivative = series.richardson(f, 0, 0.1, 4)
print(derivative)  -- ≈ cos(0) = 1
```

## Special Series

### series.exp_series(x, n?)
Exponential series: e^x = Σx^n/n!

```lua
local result = series.exp_series(1, 20)  -- e^1
print(result)  -- ≈ 2.71828...
```

### series.sin_series(x, n?)
Sine series: sin(x) = Σ(-1)^n * x^(2n+1) / (2n+1)!

```lua
local result = series.sin_series(math.pi/2, 15)
print(result)  -- ≈ 1
```

### series.cos_series(x, n?)
Cosine series: cos(x) = Σ(-1)^n * x^(2n) / (2n)!

```lua
local result = series.cos_series(0, 10)
print(result)  -- 1
```

## Applications

### Compute Mathematical Constants

```lua
-- Compute π using Leibniz series: π/4 = Σ(-1)^n/(2n+1)
local function term(n)
    return (-1)^n / (2*n + 1)
end

local pi_over_4 = series.sum(term, 0, {tol = 1e-10})
print("π ≈", pi_over_4 * 4)

-- Compute e: e = Σ1/n!
local function factorial_term(n)
    local fact = 1
    for i = 1, n do
        fact = fact * i
    end
    return 1 / fact
end

local e = series.sum(factorial_term, 0, {maxiter = 20})
print("e ≈", e)
```

### Custom Function Evaluation

```lua
-- Evaluate function using Taylor series
local function my_exp(x)
    local function term(n)
        local fact = 1
        for i = 1, n do
            fact = fact * i
        end
        return x^n / fact
    end
    return series.sum(term, 0, {tol = 1e-12})
end

print(my_exp(1))  -- ≈ e
```

### Numerical Integration Alternative

```lua
-- Integrate using series expansion
-- ∫exp(-x²)dx from 0 to 1 (error function related)

local function integrand_series(x, n)
    -- exp(-x²) = Σ(-1)^k * x^(2k) / k!
    local sum = 0
    local term = 1
    for k = 0, n do
        sum = sum + term
        term = term * (-x*x) / (k + 1)
    end
    return sum
end

-- Integrate term by term
local result = 0
for k = 0, 20 do
    local coeff = (-1)^k / (1 + 2*k)
    local factorial = 1
    for i = 1, k do factorial = factorial * i end
    result = result + coeff / factorial
end
print("Integral ≈", result)
```

### Convergence Testing

```lua
-- Test if series converges using ratio test
local function ratio_test(f, n)
    local current = f(n)
    local next = f(n + 1)
    return math.abs(next / current)
end

local function term(n)
    return 1 / (2^n)
end

local ratio = ratio_test(term, 100)
print("Ratio:", ratio)  -- < 1 means convergence
```

## Performance Notes

- For alternating series, use Shanks transformation
- Kahan summation reduces floating-point errors
- Richardson extrapolation accelerates convergence
- Cache factorial values for repeated computations

## See Also

- ``SeriesModule``
- <doc:MathExprModule>
- <doc:Modules/IntegrateModule>
