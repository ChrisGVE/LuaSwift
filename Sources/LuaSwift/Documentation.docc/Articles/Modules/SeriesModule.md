# Series Module

Taylor series, infinite series summation, infinite products, and power series objects.

> Important: This module requires the NumericSwift optional dependency. It is **off by default**. Enable it at build time:
> ```
> LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build
> ```
> Without this flag the module is not compiled and none of the symbols below are available.

## Overview

The Series module provides tools for working with Taylor polynomial approximations, computing
infinite sums and products over expression strings, iterating partial sums, and manipulating
power series objects algebraically. It also exposes symbolic series dispatchers when the Thales
CAS backend is present.

The module requires `MathExprModule` to be loaded first (it uses the expression evaluator
internally). Install order is handled automatically by `ModuleRegistry.installModules`.

## Installation

```swift
// Install all modules (recommended — handles ordering automatically)
ModuleRegistry.installModules(in: engine)

// Or install just the Series module (MathExprModule must already be installed)
ModuleRegistry.installSeriesModule(in: engine)
```

```lua
-- Access via the luaswift namespace
local series = luaswift.series

-- Or via the math namespace (available after extend_stdlib)
luaswift.extend_stdlib()
local series = math.series
```

## Taylor Series

### series.taylor(func\_name, options?)

Compute a Taylor polynomial for a **known function** using analytical coefficients supplied by
NumericSwift. Returns a callable polynomial object.

**Parameters:**
- `func_name` (string) — name of a supported function (see list below)
- `options` (optional table):
  - `at` (number) — expansion center, default `0`
  - `terms` (number) — number of terms, default `10`

**Returns:** polynomial object (callable, with `:eval`, `:tostring` methods and
`.coefficients`, `.center`, `.terms`, `.func_name` fields)

**Available functions:**

| Name | Function |
|------|----------|
| `"sin"` | sin(x) |
| `"cos"` | cos(x) |
| `"exp"` | e^x |
| `"log1p"` | ln(1+x) |
| `"sinh"` | sinh(x) |
| `"cosh"` | cosh(x) |
| `"tan"` | tan(x) |
| `"atan"` | arctan(x) |
| `"geometric"` | 1/(1-x) |
| `"geometric_alt"` | 1/(1+x) |
| `"sqrt1p"` | sqrt(1+x) |
| `"inv1p"` | 1/(1+x) via inverse series |

**Examples:**

```lua
-- Taylor polynomial for sin(x) around x=0, 10 terms
local poly = series.taylor("sin", {at=0, terms=10})

-- Evaluate the polynomial
print(poly(math.pi/6))   -- ≈ 0.5  (sin(π/6))
print(poly:eval(0))      -- 0

-- Inspect coefficients
for i, c in ipairs(poly.coefficients) do
    print(i, c)
end

-- String representation
print(tostring(poly))

-- Taylor for exp around x=1
local exp_poly = series.taylor("exp", {at=1, terms=8})
print(exp_poly(1))  -- ≈ e
```

### series.approximate\_taylor(f, options?)

Numerically approximate a Taylor polynomial for an **arbitrary Lua function** using
finite-difference derivative estimates over Chebyshev-distributed points.

**Parameters:**
- `f` (function) — Lua function `f(x) -> number`
- `options` (optional table):
  - `at` (number) — expansion center, default `0`
  - `degree` (number) — polynomial degree, default `10`
  - `scale` (number) — neighbourhood size around center, default `0.1`
  - `order` (number) — number of evaluation points, default `degree + 5`

**Returns:** polynomial object (same interface as `series.taylor`; `.approximate = true`)

**Example:**

```lua
-- Approximate Taylor polynomial for a custom function
local function my_func(x)
    return math.cos(x) * math.exp(-x/10)
end

local poly = series.approximate_taylor(my_func, {at=0, degree=6, scale=0.5})
print(poly(0.2))   -- ≈ my_func(0.2)
```

## Infinite Series

### series.sum(expr, options)

Sum a series defined by an expression string. Supports both finite sums (with `to`) and
convergent infinite sums (with `tol`).

**Parameters:**
- `expr` (string) — expression in the index variable (e.g. `"1/n^2"`)
- `options` (table):
  - `var` (string) — index variable name, default `"n"`
  - `from` (number) — starting index, default `1`
  - `to` (number, optional) — ending index; omit for infinite mode
  - `tol` (number) — convergence tolerance, default `1e-12` (infinite mode only)
  - `max_iter` (number) — iteration cap, default `10000`

**Returns (finite mode):** sum (number)

**Returns (infinite/convergence mode):** sum (number), info table `{converged, iterations, last_term}`

**Examples:**

```lua
-- Finite sum: 1 + 1/4 + 1/9 + ... + 1/100²
local s = series.sum("1/n^2", {var="n", from=1, to=100})
print(s)  -- ≈ 1.6350...

-- Infinite sum: Basel problem, converges to π²/6
local result, info = series.sum("1/n^2", {var="n", from=1, tol=1e-10})
print(result)           -- ≈ 1.6449... (π²/6)
print(info.converged)   -- true
print(info.iterations)  -- number of terms used

-- Geometric series: Σ(1/2)^n from n=0
local geo = series.sum("(1/2)^n", {var="n", from=0, tol=1e-14})
print(geo)  -- ≈ 2

-- Alternating series: Leibniz formula for π
local pi_over_4, info = series.sum("(-1)^n / (2*n+1)", {var="n", from=0, tol=1e-10})
print(pi_over_4 * 4)    -- ≈ π
```

### series.product(expr, options)

Compute a product series defined by an expression string.

**Parameters:**
- `expr` (string) — expression in the index variable (e.g. `"(1 - 1/n^2)"`)
- `options` (table):
  - `var` (string) — index variable name, default `"n"`
  - `from` (number) — starting index, default `1`
  - `to` (number, optional) — ending index; omit for convergence mode
  - `tol` (number) — relative convergence tolerance, default `1e-12`
  - `max_iter` (number) — iteration cap, default `10000`

**Returns (finite mode):** product (number)

**Returns (convergence mode):** product (number), info table `{converged, iterations}`

**Examples:**

```lua
-- Finite product: Π n/(n+1) from n=1 to 10
local p = series.product("n/(n+1)", {var="n", from=1, to=10})
print(p)    -- = 1/11

-- Wallis product: Π 4n²/(4n²-1) → π/2
local wallis, info = series.product("4*n^2/(4*n^2-1)", {var="n", from=1, tol=1e-8})
print(wallis * 2)   -- ≈ π
print(info.converged)
```

## Partial Sums

### series.partial\_sums(expr, options)

Iterate partial sums as a coroutine, yielding `(step, n, term, cumulative_sum)` at each step.
Memory-efficient for inspecting convergence behaviour.

**Parameters:**
- `expr` (string) — expression in the index variable
- `options` (table):
  - `var` (string) — index variable name, default `"n"`
  - `from` (number) — starting index, default `0`
  - `max_terms` (number) — maximum number of terms to emit, default `20`

**Returns:** coroutine iterator; each `coroutine.yield` produces `(step, n, term, sum)`

**Example:**

```lua
-- Inspect convergence of the harmonic series
for step, n, term, sum in series.partial_sums("1/n", {var="n", from=1, max_terms=10}) do
    print(string.format("step=%d  n=%d  term=%.6f  sum=%.6f", step, n, term, sum))
end

-- Convergence of 1/2^n
for step, n, term, sum in series.partial_sums("1/2^n", {var="n", from=0, max_terms=15}) do
    print(n, term, sum)
end
```

## Lazy Term Iterator

### series.terms(expr, options?)

Infinite lazy iterator over individual series terms; yields `(n, term)` pairs.

**Parameters:**
- `expr` (string) — expression in the index variable
- `options` (optional table):
  - `var` (string) — index variable name, default `"n"`
  - `from` (number) — starting index, default `0`

**Returns:** coroutine iterator (infinite — always use a break condition)

**Example:**

```lua
-- First 5 terms of the Taylor series for e: 1/n!
local count = 0
for n, term in series.terms("1/n!", {var="n", from=0}) do
    print(n, term)
    count = count + 1
    if count >= 5 then break end
end
```

## Power Series Objects

### series.power(opts)

Create a power series object supporting algebraic manipulation (addition, multiplication,
truncation, evaluation).

**Parameters:**
- `opts` (table):
  - `coefficients` (array) — coefficients `[a0, a1, a2, ...]` where the polynomial is
    `a0 + a1*(x-center) + a2*(x-center)^2 + ...`
  - `center` (number) — expansion center, default `0`
  - `variable` (string) — display variable name, default `"x"`

**Returns:** power series object with the following methods:

| Method | Description |
|--------|-------------|
| `:eval(x)` | Evaluate at `x` using Horner's method |
| `:add(other)` | Term-by-term addition (centers must match) |
| `:multiply(other)` | Cauchy product, truncated to shorter length |
| `:truncate(n)` | Keep first `n` coefficients |

The object is also callable (`ps(x)` ≡ `ps:eval(x)`) and supports `tostring`.

**Example:**

```lua
-- 1 + 2x + 3x²
local ps = series.power({coefficients = {1, 2, 3}, center = 0})
print(ps(2))        -- 1 + 4 + 12 = 17
print(tostring(ps)) -- "1 + 2*x + 3*x^2"

-- Algebra
local a = series.power({coefficients = {1, 1, 0.5}})   -- 1 + x + x²/2 (exp approx)
local b = series.power({coefficients = {1, -1, 0.5}})  -- 1 - x + x²/2 (exp(-x) approx)
local product = a:multiply(b)  -- truncated Cauchy product
print(product:eval(0.1))

-- Truncate to 3 terms
local short = a:truncate(3)
print(short:eval(0.5))
```

## Utility Functions

### series.available\_functions()

Returns the list of function names accepted by `series.taylor`.

```lua
local fns = series.available_functions()
-- {"sin", "cos", "exp", "log1p", "sinh", "cosh", "tan", "atan",
--  "geometric", "geometric_alt", "sqrt1p", "inv1p"}
for _, name in ipairs(fns) do print(name) end
```

### series.binomial(n, k)

Binomial coefficient C(n, k).

```lua
print(series.binomial(5, 2))  -- 10
print(series.binomial(10, 3)) -- 120
```

### series.\_factorial(n)

Cached factorial. Handles `n = 0..170`; returns `math.huge` for `n > 170`.

```lua
print(series._factorial(10))  -- 3628800
```

## Symbolic Series (Thales CAS)

The following functions delegate to the Thales CAS backend when compiled with
`LUASWIFT_INCLUDE_THALES=1`. Without Thales, `taylor_symbolic` falls back to
`series.taylor` for known functions; `laurent` and `puiseux` raise a clear error.

### series.taylor\_symbolic(expr, opts?)

Symbolic Taylor expansion. Falls back to numerical `series.taylor` for known functions when
Thales is unavailable.

**Parameters:**
- `expr` (string) — expression or known function name
- `opts` (optional table): `variable` (default `"x"`), `around` (default `0`), `terms` (default `5`)

```lua
-- With Thales: symbolic expansion of any expression
local poly = series.taylor_symbolic("sin(x)*exp(x)", {variable="x", around=0, terms=6})

-- Without Thales: falls back for known functions
local poly = series.taylor_symbolic("sin", {around=0, terms=8})
```

### series.laurent(expr, opts?)

Laurent series expansion. Requires `LUASWIFT_INCLUDE_THALES=1`.

**Parameters:** `variable` (default `"x"`), `center` (default `0`),
`neg_order` (default `3`), `pos_order` (default `3`)

```lua
local ls = series.laurent("1/sin(x)", {variable="x", center=0, neg_order=2, pos_order=4})
```

### series.puiseux(expr, opts?)

Puiseux series (fractional-power Laurent). Requires `LUASWIFT_INCLUDE_THALES=1`.

**Parameters:** `variable` (default `"x"`), `center` (default `0`), `order` (default `5`)

```lua
local ps = series.puiseux("sqrt(x - 1)", {variable="x", center=1, order=4})
```

## Applications

### Compute π via Leibniz Series

```lua
local s, info = series.sum("(-1)^n / (2*n+1)", {var="n", from=0, tol=1e-10})
print("π ≈", s * 4)
print("converged after", info.iterations, "terms")
```

### Approximate sin(x) and Compare

```lua
local poly = series.taylor("sin", {at=0, terms=11})

local test_points = {0, math.pi/6, math.pi/4, math.pi/3, math.pi/2}
for _, x in ipairs(test_points) do
    local approx = poly(x)
    local exact  = math.sin(x)
    print(string.format("x=%.4f  approx=%.10f  error=%.2e", x, approx, math.abs(approx-exact)))
end
```

### Wallis Product for π

```lua
local product, info = series.product(
    "4*n^2 / (4*n^2 - 1)", {var="n", from=1, tol=1e-9})
print("π ≈", product * 2)
print("converged:", info.converged)
```

### Inspect Convergence Rate

```lua
print("n   term           cumulative")
for step, n, term, sum in series.partial_sums("1/n^2", {var="n", from=1, max_terms=12}) do
    print(string.format("%3d  %14.10f  %.10f", n, term, sum))
end
-- Converges toward π²/6 ≈ 1.6449340668...
```

### Power Series Composition

```lua
-- Build cos(x) ≈ 1 - x²/2 + x⁴/24 as a power series
local cos_ps = series.power({coefficients = {1, 0, -0.5, 0, 1/24}})
print(cos_ps(0.3))          -- ≈ cos(0.3)
print(math.cos(0.3))

-- Double the polynomial by multiplying with constant series
local two = series.power({coefficients = {2}})
local doubled = cos_ps:multiply(two)
print(doubled:eval(0.3))    -- ≈ 2*cos(0.3)
```

## See Also

- ``SeriesModule``
- <doc:MathExprModule>
- <doc:IntegrateModule>
