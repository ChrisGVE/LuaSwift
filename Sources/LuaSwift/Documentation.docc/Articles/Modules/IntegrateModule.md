# Integrate Module

Numerical integration (quadrature) and ODE solvers.

## Overview

> Important: This module requires the **NumericSwift** optional dependency. It is **disabled by default**. To enable it, set `LUASWIFT_INCLUDE_NUMERICSWIFT=1` in your build environment.

The Integrate module provides adaptive quadrature, multi-dimensional integration, fixed-order quadrature, array-based rules, and ODE solvers. It follows scipy's API conventions. All functions are available under `math.integrate` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
// Requires LUASWIFT_INCLUDE_NUMERICSWIFT=1 at build time
try MathXModule.install(in: engine)
```

```lua
luaswift.extend_stdlib()
local integrate = math.integrate
```

## Adaptive Quadrature

### integrate.quad(f, a, b, options?)

Computes the definite integral of `f` from `a` to `b` using adaptive Gauss-Kronrod quadrature. Supports both real-valued and complex-valued integrands.

**Parameters:**
- `f` — function `f(x)` returning a number or a complex table `{re=..., im=...}`
- `a`, `b` — integration limits (use `math.huge` / `-math.huge` for infinite limits)
- `options` (optional) — table:
  - `epsabs` — absolute error tolerance (default: `1.49e-8`)
  - `epsrel` — relative error tolerance (default: `1.49e-8`)
  - `limit` — maximum number of adaptive subdivisions (default: `50`)

**Returns:** `value, error` — integral value and error estimate

```lua
-- Integrate sin(x) from 0 to π  → 2.0
local function f(x)
    return math.sin(x)
end
local result, err = integrate.quad(f, 0, math.pi)
print(result)  -- ~2.0

-- With options
local result, err = integrate.quad(f, 0, math.pi, {
    epsabs = 1e-12,
    epsrel = 1e-12,
    limit  = 100
})
```

#### Infinite Limits

```lua
-- ∫₀^∞ e^−x dx = 1
local result, err = integrate.quad(function(x) return math.exp(-x) end, 0, math.huge)
print(result)  -- ~1.0
```

#### Complex-Valued Integrand

When the integrand returns a table `{re=..., im=...}`, `quad` integrates the real and imaginary parts separately and returns a complex result table as the first return value.

```lua
local complex = require("math.complex")
local function f(x)
    -- e^(ix) = cos(x) + i·sin(x)
    return {re = math.cos(x), im = math.sin(x)}
end
local result, err = integrate.quad(f, 0, math.pi)
-- result is {re=..., im=...}
```

## Double and Triple Integration

### integrate.dblquad(f, xa, xb, ya, yb, options?)

Computes the double integral ∬ f(y, x) dy dx, with x from `xa` to `xb` and y from `ya(x)` to `yb(x)`.

> Note: The integrand receives arguments in the order **`f(y, x)`** — inner variable first, matching scipy's convention.

**Parameters:**
- `f` — function `f(y, x)` returning a number
- `xa`, `xb` — outer (x) integration limits
- `ya`, `yb` — inner (y) limits: numbers or functions of `x`
- `options` (optional) — table with `epsabs`, `epsrel`

**Returns:** `value, error`

```lua
-- ∫₀¹ ∫₀¹ x·y dy dx = 0.25
local result, err = integrate.dblquad(
    function(y, x) return x * y end,
    0, 1,   -- x limits
    0, 1    -- y limits
)
print(result)  -- ~0.25

-- Variable y limits: 0 ≤ y ≤ x
local result, err = integrate.dblquad(
    function(y, x) return x + y end,
    0, 1,                          -- x limits
    function(x) return 0 end,     -- ya(x) = 0
    function(x) return x end      -- yb(x) = x
)
```

### integrate.tplquad(f, xa, xb, ya, yb, za, zb, options?)

Computes the triple integral ∭ f(z, y, x) dz dy dx.

> Note: The integrand receives arguments in the order **`f(z, y, x)`** — innermost variable first.

**Parameters:**
- `f` — function `f(z, y, x)` returning a number
- `xa`, `xb` — outermost (x) limits
- `ya`, `yb` — middle (y) limits: numbers or functions of `x`
- `za`, `zb` — innermost (z) limits: numbers or functions of `x, y`
- `options` (optional) — table with `epsabs`, `epsrel`

**Returns:** `value, error`

```lua
-- ∫₀¹ ∫₀¹ ∫₀¹ x·y·z dz dy dx = 0.125
local result, err = integrate.tplquad(
    function(z, y, x) return x * y * z end,
    0, 1,   -- x limits
    0, 1,   -- y limits
    0, 1    -- z limits
)
print(result)  -- ~0.125
```

## Fixed-Order and Romberg

### integrate.fixed_quad(f, a, b, n?)

Computes the integral using a fixed-order Gaussian quadrature rule. Faster than `quad` for smooth integrands when precision requirements are modest.

**Parameters:**
- `f` — function `f(x)`
- `a`, `b` — limits
- `n` — number of quadrature points (default: `5`)

**Returns:** single number (no error estimate)

```lua
-- ∫₀¹ x² dx = 0.333...
local result = integrate.fixed_quad(function(x) return x^2 end, 0, 1, 5)
print(result)  -- ~0.333

-- Higher order for better accuracy
local result = integrate.fixed_quad(function(x) return math.sin(x) end, 0, math.pi, 10)
```

### integrate.romberg(f, a, b, options?)

Computes the integral using Romberg's method (Richardson extrapolation on the trapezoidal rule).

**Parameters:**
- `f` — function `f(x)`
- `a`, `b` — limits
- `options` (optional):
  - `tol` — convergence tolerance (default: `1e-8`)
  - `divmax` — maximum number of refinement levels (default: `10`)

**Returns:** `value, error`

```lua
local result, err = integrate.romberg(
    function(x) return math.exp(x) end,
    0, 1,
    {tol = 1e-10}
)
print(result)  -- ~1.718 (e - 1)
```

## Array-Based Rules

These functions operate on pre-sampled data arrays rather than on a function.

### integrate.trapz(y, x?, dx?)

Integrates sampled data using the composite trapezoidal rule.

**Parameters:**
- `y` — array of function values (at least 2 elements)
- `x` — array of sample points (optional; if omitted, uniform spacing assumed)
- `dx` — uniform spacing (default: `1`; ignored when `x` is provided)

**Returns:** single number

```lua
-- Uniform spacing
local y  = {1, 2, 3, 4, 5}
local result = integrate.trapz(y)          -- dx=1 → 8.0
local result = integrate.trapz(y, nil, 0.5) -- dx=0.5 → 4.0

-- Non-uniform spacing
local x = {0, 0.5, 1.0, 2.0, 4.0}
local y = {0, 0.25, 1, 4, 16}   -- x² sampled
local result = integrate.trapz(y, x)        -- ≈ 21.0
```

### integrate.simps(y, x?, dx?)

Integrates sampled data using Simpson's rule. Requires an odd number of evenly spaced points for exact results; falls back gracefully for even-count arrays.

**Parameters:**
- `y` — array of function values (at least 3 elements)
- `x` — array of sample points (optional)
- `dx` — uniform spacing (default: `1`)

**Returns:** single number

```lua
-- Five evenly spaced points for x² over [0, 1]
local y = {0, 0.0625, 0.25, 0.5625, 1}  -- (0, 0.25, 0.5, 0.75, 1)²
local result = integrate.simps(y, nil, 0.25)
print(result)  -- ~0.333
```

## ODE Solvers

### integrate.odeint(func, y0, t, options?)

Integrates a system of ODEs using an adaptive Runge-Kutta method, following scipy's `odeint` interface.

> Important: The state function is called as **`func(y, t, ...)`** — state vector first, time second. This is the scipy `odeint` convention, which is the **reverse** of `solve_ivp`'s convention.

**Parameters:**
- `func` — function `func(y, t)` or `func(y, t, ...)` returning an array of derivatives
- `y0` — initial state as an **array** (e.g. `{1.0}` for a scalar ODE)
- `t` — array of time points to evaluate (at least 2 elements; first element is the initial time)
- `options` (optional):
  - `rtol` — relative tolerance (default: `1.49e-8`)
  - `atol` — absolute tolerance (default: `1.49e-8`)
  - `args` — extra arguments passed to `func` after `t`
  - `full_output` — if `true`, return `y, info` instead of just `y` (default: `false`)

**Returns:** array of state vectors, one per time point — `result[i]` is an array containing the state at `t[i]`

```lua
-- Exponential decay: dy/dt = -0.5·y, y(0) = 1
-- Note: y first, t second in the function signature
local function dydt(y, t)
    return {-0.5 * y[1]}
end

local y0 = {1.0}              -- initial state as array
local t  = {0, 1, 2, 3, 4, 5}

local sol = integrate.odeint(dydt, y0, t)
-- sol[i] is the state array at t[i]
for i, state in ipairs(sol) do
    print(string.format("t=%.1f  y=%.4f", t[i], state[1]))
end
-- t=0.0  y=1.0000
-- t=1.0  y=0.6065
-- ...
```

#### System of ODEs

```lua
-- Harmonic oscillator: dx/dt = v, dv/dt = -x
-- State vector: {x, v}
local function derivatives(y, t)
    local x, v = y[1], y[2]
    return {v, -x}
end

local y0 = {1.0, 0.0}   -- x=1, v=0
local t  = {}
for i = 0, 100 do
    t[i + 1] = i * 0.1
end

local sol = integrate.odeint(derivatives, y0, t)
-- sol[i][1] = x(t[i]),  sol[i][2] = v(t[i])
print(sol[1][1], sol[1][2])  -- 1.0, 0.0  (initial condition)
```

#### Extra Arguments

```lua
-- Parameterised decay: dy/dt = -k·y
local function dydt(y, t, k)
    return {-k * y[1]}
end

local sol = integrate.odeint(dydt, {1.0}, t, {args = {0.5}})
```

#### Full Output

```lua
local sol, info = integrate.odeint(dydt, {1.0}, t, {full_output = true})
print("Function evaluations:", info.nfe)
```

### integrate.solve_ivp(fun, t_span, y0, options?)

Solves an IVP using an adaptive Runge-Kutta method, following scipy's `solve_ivp` interface.

> Important: The derivative function is called as **`fun(t, y)`** — time first, state vector second. This is the scipy `solve_ivp` convention, which is the **reverse** of `odeint`'s convention.

**Parameters:**
- `fun` — function `fun(t, y)` returning an array of derivatives
- `t_span` — two-element array `{t0, tf}`
- `y0` — initial state array
- `options` (optional):
  - `method` — `"RK45"` (default), `"RK23"`, or `"RK4"`
  - `t_eval` — array of times at which to store the solution (optional)
  - `max_step` — maximum step size (default: `math.huge`)
  - `rtol` — relative tolerance (default: `1e-3`)
  - `atol` — absolute tolerance (default: `1e-6`)
  - `first_step` — initial step size (optional)

**Returns:** result table with fields:
- `t` — array of time points where solution was evaluated
- `y` — array of state vectors, `y[i]` is the state array at `t[i]`
- `success` — boolean
- `message` — status string
- `nfev` — number of function evaluations

```lua
-- Note: fun(t, y) — time is the FIRST argument
local function fun(t, y)
    return {-0.5 * y[1]}   -- dy/dt = -0.5·y
end

local result = integrate.solve_ivp(fun, {0, 10}, {1.0})
if result.success then
    for i, ti in ipairs(result.t) do
        print(string.format("t=%.2f  y=%.4f", ti, result.y[i][1]))
    end
end
```

#### Dense Output with t_eval

```lua
local t_eval = {}
for i = 0, 100 do t_eval[i + 1] = i * 0.1 end

local result = integrate.solve_ivp(fun, {0, 10}, {1.0}, {
    t_eval = t_eval,
    rtol   = 1e-6,
    atol   = 1e-9
})
```

#### ODE Methods

| Method | Description |
|--------|-------------|
| `"RK45"` | Explicit Runge-Kutta 4(5) — default, general purpose |
| `"RK23"` | Explicit Runge-Kutta 2(3) — lower order, faster for loose tolerances |
| `"RK4"`  | Classic fixed-step Runge-Kutta 4 |

## Argument Order Summary

| Function | Signature | Convention |
|----------|-----------|------------|
| `quad` | `f(x)` | Standard |
| `dblquad` | `f(y, x)` | Inner variable first |
| `tplquad` | `f(z, y, x)` | Innermost variable first |
| `odeint` | `func(y, t)` | State first, time second |
| `solve_ivp` | `fun(t, y)` | Time first, state second |

## Physical Applications

### Projectile with Air Resistance

```lua
-- dv/dt = -g - k·v²,  dy/dt = v
-- State: {y_pos, v}   — solve_ivp convention: fun(t, state)
local function derivatives(t, state)
    local y_pos, v = state[1], state[2]
    local g, k = 9.81, 0.01
    return {v, -g - k * v^2}
end

local result = integrate.solve_ivp(derivatives, {0, 10}, {0, 50})
```

### RC Circuit

```lua
-- dV/dt = (V0 - V) / RC   — odeint convention: func(y, t)
local function dVdt(y, t)
    local V  = y[1]
    local V0 = 10.0
    local RC = 1.0
    return {(V0 - V) / RC}
end

local t = {0, 0.5, 1, 1.5, 2, 2.5, 3}
local sol = integrate.odeint(dVdt, {0.0}, t)
-- sol[i][1] = voltage at t[i]
```

### Lotka-Volterra (Predator-Prey)

```lua
-- dx/dt = α·x - β·x·y   (prey)
-- dy/dt = δ·x·y - γ·y   (predator)
-- odeint convention: func(state, t)
local function derivatives(state, t)
    local prey, pred = state[1], state[2]
    local alpha, beta  = 1.0, 0.1
    local delta, gamma = 0.1, 1.0
    return {
        alpha * prey - beta * prey * pred,
        delta * prey * pred - gamma * pred
    }
end

local t = {}
for i = 0, 200 do t[i + 1] = i * 0.1 end

local sol = integrate.odeint(derivatives, {10, 5}, t)
-- sol[i] = {prey_count, predator_count} at t[i]
```

## Error Handling

All functions throw on invalid input:

```lua
local ok, err = pcall(function()
    integrate.quad(nil, 0, 1)   -- error: function expected
end)
print(err)  -- "quad: expected function, lower, upper"

local ok, err = pcall(function()
    integrate.simps({1, 2})     -- error: need at least 3 points
end)
```

## Performance Notes

- `quad` uses adaptive Gauss-Kronrod from NumericSwift; suitable for smooth to moderately oscillatory integrands.
- `fixed_quad` is faster for smooth, well-behaved integrands where the order `n` is known to suffice.
- `romberg` excels when the integrand is smooth and the interval finite.
- `simps` and `trapz` are best for pre-sampled data; `simps` achieves higher accuracy for the same number of points.
- For stiff ODEs neither `odeint` nor `solve_ivp` provides an implicit solver; reduce step size via `atol`/`rtol` in that case.

## See Also

- ``IntegrateModule``
- <doc:OptimizeModule>
- <doc:InterpolateModule>
