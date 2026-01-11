# Series Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.series` | **Global:** `math.series` (after extend_stdlib)

The Series module provides infinite series evaluation, Taylor polynomial approximation, and convergence detection. It supports both analytical (known functions) and numerical (arbitrary functions) approaches.

## Function Reference

| Function | Description |
|----------|-------------|
| [sum(expr, opts)](#sum) | Sum series with convergence detection |
| [product(expr, opts)](#product) | Infinite/finite product |
| [taylor(func, opts)](#taylor) | Analytical Taylor polynomial for known functions |
| [approximate_taylor(f, opts)](#approximate_taylor) | Numerical Taylor approximation |
| [partial_sums(expr, opts)](#partial_sums) | Iterator over partial sums |
| [terms(expr, opts)](#terms) | Iterator over individual terms |
| [binomial(n, k)](#binomial) | Binomial coefficient C(n,k) |
| [available_functions()](#available_functions) | List supported Taylor functions |
| [_factorial(n)](#_factorial) | Cached factorial computation |

## Type Mapping

### Polynomial Object Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `poly:eval(x)` | Evaluate polynomial at x | `number` |
| `poly(x)` | Callable shorthand for eval | `number` |
| `tostring(poly)` | String representation | `string` |

### Polynomial Object Fields

| Field | Type | Description |
|-------|------|-------------|
| `coefficients` | `table` | Array of Taylor coefficients [c₀, c₁, c₂, ...] |
| `center` | `number` | Expansion point (a in (x-a)ⁿ) |
| `terms` | `number` | Number of terms in polynomial |
| `func_name` | `string` | Function name (analytical only) |
| `approximate` | `boolean` | True if numerically approximated |

### Taylor Series Formulas

| Function | Formula | Radius of Convergence |
|----------|---------|----------------------|
| `sin` | x - x³/3! + x⁵/5! - ... | ∞ |
| `cos` | 1 - x²/2! + x⁴/4! - ... | ∞ |
| `exp` | 1 + x + x²/2! + x³/3! + ... | ∞ |
| `log1p` | x - x²/2 + x³/3 - x⁴/4 + ... | (-1, 1] |
| `sinh` | x + x³/3! + x⁵/5! + ... | ∞ |
| `cosh` | 1 + x²/2! + x⁴/4! + ... | ∞ |
| `tan` | x + x³/3 + 2x⁵/15 + 17x⁷/315 + ... | (-π/2, π/2) |
| `atan` | x - x³/3 + x⁵/5 - x⁷/7 + ... | [-1, 1] |
| `geometric` | 1 + x + x² + x³ + ... | (-1, 1) |
| `geometric_alt` | 1 - x + x² - x³ + ... | (-1, 1) |
| `sqrt1p` | 1 + x/2 - x²/8 + x³/16 - ... | (-1, 1] |
| `inv1p` | 1 - x + x² - x³ + ... | (-1, 1) |

---

## sum

```
series.sum(expr, opts) -> number[, info]
```

Sum series with convergence detection.

**Parameters:**
- `expr` (string) - Mathematical expression (e.g., "1/n^2")
- `opts` (table) - Options:
  - `var` (string): Variable name (default: "n")
  - `from` (number): Start index (default: 1)
  - `to` (number): End index (nil = convergence mode)
  - `tol` (number): Convergence tolerance (default: 1e-12)
  - `max_iter` (number): Maximum iterations (default: 10000)

**Returns:** `number` (sum), and optionally `info` table with fields:
- `converged` (boolean): Whether series converged
- `iterations` (number): Number of terms evaluated
- `last_term` (number): Magnitude of final term

```lua
-- Infinite series with convergence (Basel problem: π²/6)
local sum, info = series.sum("1/n^2", {
    var = "n",
    from = 1,
    tol = 1e-12
})
print(sum)                -- 1.6449340668...
print(info.converged)     -- true
print(info.iterations)    -- Number of terms needed

-- Finite series
local finite = series.sum("1/n^2", {from=1, to=100})

-- Alternating harmonic series (converges to ln(2))
local ln2 = series.sum("(-1)^(n+1)/n", {from=1, tol=1e-10})

-- Exponential series (e ≈ 2.718281828)
local e = series.sum("1/factorial(n)", {from=0, tol=1e-15})
```

**Errors:** Throws if expression is invalid or series diverges (exceeds max_iter).

---

## product

```
series.product(expr, opts) -> number[, info]
```

Compute infinite or finite product.

**Parameters:**
- `expr` (string) - Mathematical expression for product terms
- `opts` (table) - Options (same as `sum`):
  - `var` (string): Variable name (default: "n")
  - `from` (number): Start index (default: 1)
  - `to` (number): End index (nil = convergence mode)
  - `tol` (number): Convergence tolerance (default: 1e-12)
  - `max_iter` (number): Maximum iterations (default: 10000)

**Returns:** `number` (product), and optionally `info` table

```lua
-- Finite product
local prod = series.product("(1 - 1/n^2)", {
    var = "n",
    from = 2,
    to = 100
})

-- Wallis product for π/2
local wallis, info = series.product("(2*n)^2/((2*n-1)*(2*n+1))", {
    var = "n",
    from = 1,
    tol = 1e-10
})
print(wallis * 2)  -- Approximates π
```

---

## taylor

```
series.taylor(func, opts) -> polynomial
```

Generate analytical Taylor polynomial for known functions.

**Parameters:**
- `func` (string) - Function name (see available_functions)
- `opts` (table) - Options:
  - `at` (number): Expansion point (default: 0)
  - `terms` (number): Number of terms (default: 10)

**Returns:** Polynomial object (callable)

```lua
-- Taylor polynomial for cos(x) at x=0 with 12 terms
local cosine = series.taylor("cos", {at=0, terms=12})

-- Evaluate at specific points
print(cosine(0))         -- 1.0
print(cosine(math.pi))   -- -1.0

-- String representation
print(tostring(cosine))  -- "1 - 0.5*x^2 + 0.0416667*x^4 - ..."

-- Access coefficients
for i, coeff in ipairs(cosine.coefficients) do
    print(string.format("x^%d: %.10f", i-1, coeff))
end

-- Taylor series for sin(x) at shifted center
local sine_shifted = series.taylor("sin", {at=math.pi/4, terms=15})
print(sine_shifted(math.pi/3))  -- Accurate near π/4
```

**Available Functions:** Use `available_functions()` to see supported functions. Includes: sin, cos, exp, log1p, sinh, cosh, tan, atan, geometric, geometric_alt, sqrt1p, inv1p.

---

## approximate_taylor

```
series.approximate_taylor(f, opts) -> polynomial
```

Numerical Taylor approximation for arbitrary functions.

**Parameters:**
- `f` (function) - Lua function to approximate
- `opts` (table) - Options:
  - `at` (number): Expansion point (default: 0)
  - `degree` (number): Polynomial degree (default: 10)
  - `scale` (number): Evaluation region scale (default: 0.1)
  - `order` (number): Internal interpolation order (default: degree+5)

**Returns:** Polynomial object with `approximate=true` flag

```lua
-- Approximate unknown function
local f = function(x)
    return math.sin(x) * math.exp(-x*x)
end

local poly = series.approximate_taylor(f, {
    at = 0,
    degree = 10,
    scale = 0.1
})

print(poly(0.5))        -- Approximates f(0.5)
print(poly.approximate) -- true

-- Comparison: analytical vs numerical for sin(x)
local analytical = series.taylor("sin", {terms=11})
local numerical = series.approximate_taylor(math.sin, {degree=10, scale=0.2})

local x = 0.5
print("Analytical:", analytical(x))   -- 0.4794255386...
print("Numerical:", numerical(x))     -- ~0.4794... (close match)
print("Actual:", math.sin(x))         -- 0.4794255386...
```

**Scale Parameter:** Controls sampling region around expansion point:
- Smaller scale (0.01-0.1): Better accuracy near center, narrower validity
- Larger scale (0.5-1.0): Wider validity, but may lose accuracy near center
- Rule of thumb: Use `scale ≈ 0.1 × expected_evaluation_range`

---

## partial_sums

```
series.partial_sums(expr, opts) -> iterator
```

Iterator over partial sums for convergence analysis.

**Parameters:**
- `expr` (string) - Mathematical expression
- `opts` (table) - Options:
  - `var` (string): Variable name (default: "n")
  - `from` (number): Start index (default: 0)
  - `max_terms` (number): Maximum terms to generate (default: 20)

**Returns:** Iterator function returning `(index, n_value, term, partial_sum)`

```lua
-- Track convergence behavior
for i, n, term, sum in series.partial_sums("1/n^2", {from=1, max_terms=10}) do
    print(string.format("S_%d (n=%d): term=%.6f, sum=%.6f", i, n, term, sum))
end

-- Output:
-- S_1 (n=1): term=1.000000, sum=1.000000
-- S_2 (n=2): term=0.250000, sum=1.250000
-- S_3 (n=3): term=0.111111, sum=1.361111
-- ...

-- Collect sums for visualization
local sums = {}
for i, n, term, sum in series.partial_sums("(-1)^n/n", {from=1, max_terms=50}) do
    sums[i] = sum
end
```

---

## terms

```
series.terms(expr, opts) -> iterator
```

Generate individual terms of a series lazily.

**Parameters:**
- `expr` (string) - Mathematical expression
- `opts` (table) - Options:
  - `var` (string): Variable name (default: "n")
  - `from` (number): Start index (default: 0)

**Returns:** Iterator function returning `(n_value, term)`

```lua
-- Infinite iterator (use with care!)
local iter = series.terms("1/n^2", {var="n", from=1})

-- Take first 10 terms
for i = 1, 10 do
    local n, term = iter()
    print(string.format("n=%d: %.6f", n, term))
end
```

**Warning:** This creates an infinite iterator. Always use with explicit loop limits or break conditions.

---

## binomial

```
series.binomial(n, k) -> number
```

Compute binomial coefficient C(n,k) = n! / (k! × (n-k)!).

**Parameters:**
- `n` (number) - Total items
- `k` (number) - Items to choose

**Returns:** Number of combinations

```lua
-- Standard binomial coefficients
print(series.binomial(10, 3))   -- 120
print(series.binomial(52, 5))   -- 2598960 (poker hands)

-- Edge cases
print(series.binomial(5, 0))    -- 1
print(series.binomial(5, 5))    -- 1
print(series.binomial(5, 6))    -- 0 (k > n, invalid)
```

---

## available_functions

```
series.available_functions() -> table
```

List functions supported by `taylor()` for analytical series.

**Returns:** Array of function name strings

```lua
local funcs = series.available_functions()
-- Returns: {"sin", "cos", "exp", "log1p", "sinh", "cosh", "tan", "atan",
--           "geometric", "geometric_alt", "sqrt1p", "inv1p"}

for _, name in ipairs(funcs) do
    print(name)
end
```

---

## _factorial

```
series._factorial(n) -> number
```

Cached factorial computation. Internal function, but publicly exposed.

**Parameters:**
- `n` (number) - Non-negative integer

**Returns:** n! (factorial)

```lua
local fact = series._factorial(10)  -- 3628800

-- Special values
print(series._factorial(0))     -- 1
print(series._factorial(170))   -- 7.257e+306 (largest before infinity)
print(series._factorial(171))   -- inf (overflow)
print(series._factorial(-1))    -- nan (invalid)
```

**Performance:** First call for a value is O(n), subsequent calls are O(1) due to caching. Cache persists across series operations.

---

## Examples

### Computing π

```lua
-- Leibniz formula: π/4 = 1 - 1/3 + 1/5 - 1/7 + ...
local pi_over_4 = series.sum("(-1)^n/(2*n+1)", {from=0, tol=1e-10})
print(pi_over_4 * 4)  -- 3.14159...

-- Faster: π²/6 = 1 + 1/4 + 1/9 + 1/16 + ...
local pi_sq_over_6 = series.sum("1/n^2", {from=1, tol=1e-12})
print(math.sqrt(pi_sq_over_6 * 6))  -- 3.14159...
```

### Riemann Zeta Function

```lua
-- ζ(s) = Σ(1/n^s) for s > 1
local function zeta(s)
    return series.sum("1/n^"..s, {from=1, tol=1e-12})
end

print(zeta(2))  -- π²/6 ≈ 1.6449340668
print(zeta(4))  -- π⁴/90 ≈ 1.0823232337
```

### Approximating Integrals

```lua
-- ∫₀¹ e^(-x²) dx using Taylor series
local result = 0
local poly = series.taylor("exp", {terms=20})
for i, coeff in ipairs(poly.coefficients) do
    local n = i - 1
    -- ∫₀¹ (-x²)^n dx = (-1)^n/(2n+1)
    result = result + coeff * ((-1)^n / (2*n + 1))
end
print(result)  -- ≈ 0.7468241328
```

### Integration with Array Module

```lua
-- Evaluate Taylor polynomial on array
local x = array.linspace(-1, 1, 100)
local poly = series.taylor("exp", {terms=15})

local y = array.map(x, function(xi) return poly(xi) end)
```

### Integration with Plot Module

```lua
-- Visualize series convergence
local sums = {}
for i, n, term, sum in series.partial_sums("1/n^2", {max_terms=50}) do
    sums[i] = sum
end

plot.plot(sums, {title="Convergence to π²/6"})
plot.axhline(math.pi^2/6, {linestyle="--", label="π²/6"})
plot.show()
```

### Error Handling

```lua
-- Unknown function
local ok, err = pcall(function()
    series.taylor("unknown_func", {terms=10})
end)
-- err: "Unknown function for Taylor series: unknown_func. Available: ..."

-- Missing expression
local ok, err = pcall(function()
    series.sum(nil, {from=1})
end)
-- err: "series.sum requires (expression, options)"
```

---

## Performance Considerations

1. **Convergence tolerance**: Smaller tolerance = more iterations
   - `1e-6`: Fast, good for visualization
   - `1e-12`: Balanced accuracy (default)
   - `1e-15`: High precision, slower

2. **Taylor polynomial degree**: More terms = better accuracy but slower evaluation
   - Degree 5-10: Fast, sufficient for smooth functions
   - Degree 15-20: Balanced for most applications
   - Degree 30+: High precision, use only when necessary

3. **Numerical approximation scale**: Affects stability
   - Too small: Numerical errors dominate
   - Too large: Function variations not captured
   - Sweet spot: 0.05-0.2 depending on function

4. **Factorial caching**: Both Swift and Lua cache factorial values
   - First call to `factorial(n)`: O(n)
   - Subsequent calls: O(1)
   - Cache persists across series operations

---

## Integration with Other Modules

### MathExpr Module (Required)

The Series module requires MathExprModule for expression evaluation.

```lua
-- Automatically uses luaswift.mathexpr or math.eval
series.sum("sin(n*pi/4)/n", {from=1, to=20})
```
