# Integration Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.integrate` | **Global:** `math.integrate` (after extend_stdlib)

Numerical integration and ODE (Ordinary Differential Equation) solvers inspired by SciPy's `integrate` module. Provides adaptive quadrature, multi-dimensional integration, classical integration methods, and state-of-the-art ODE solvers.

## Function Reference

| Function | Description |
|----------|-------------|
| [quad(f, a, b, options?)](#quad) | Adaptive Gauss-Kronrod quadrature integration |
| [dblquad(f, xa, xb, ya, yb, options?)](#dblquad) | Double integration over rectangular or curvilinear regions |
| [tplquad(f, xa, xb, ya, yb, za, zb, options?)](#tplquad) | Triple integration over 3D regions |
| [fixed_quad(f, a, b, n?)](#fixed_quad) | Fixed-order Gauss-Legendre quadrature |
| [romberg(f, a, b, options?)](#romberg) | Romberg integration using Richardson extrapolation |
| [simps(y, x?, dx?)](#simps) | Simpson's rule integration |
| [trapz(y, x?, dx?)](#trapz) | Trapezoidal rule integration |
| [solve_ivp(fun, t_span, y0, options?)](#solve_ivp) | Solve initial value problems for ODE systems |
| [odeint(func, y0, t, options?)](#odeint) | Legacy ODE interface compatible with SciPy |

---

## quad

```
quad(f, a, b, options?) -> result, error, neval
```

Adaptive integration using Gauss-Kronrod 15-point rule. The gold standard for single integrals.

**Parameters:**
- `f` - Function to integrate (can return real or complex values)
- `a`, `b` - Integration limits (can be `-math.huge` or `math.huge` for infinite bounds)
- `options` (optional) - Table with:
  - `epsabs` (number): Absolute error tolerance (default: 1.49e-8)
  - `epsrel` (number): Relative error tolerance (default: 1.49e-8)
  - `limit` (number): Maximum number of subdivisions (default: 50)

**Returns:**
- `result` - Integral value (number or complex table `{re=..., im=...}`)
- `error` - Estimated absolute error
- `neval` - Number of function evaluations

```lua
-- Basic integration
local val = math.integrate.quad(math.sin, 0, math.pi)
print(val)  -- 2.0

-- Infinite bounds: ∫exp(-x^2)dx from -∞ to ∞ = √π
local result = math.integrate.quad(
    function(x) return math.exp(-x*x) end,
    -math.huge, math.huge
)
print(result)  -- 1.7724... (√π)

-- Complex-valued integrand
local z = math.integrate.quad(
    function(t) return {re=math.cos(t), im=math.sin(t)} end,
    0, math.pi/2
)
print(z.re, z.im)  -- 1.0, 1.0
```

**Infinite bounds transformations:**
- `[-∞, ∞]`: Uses `x = t/(1-t²)` transformation
- `[-∞, b]`: Uses `x = b - (1-t)/t` transformation
- `[a, ∞]`: Uses `x = a + t/(1-t)` transformation

---

## dblquad

```
dblquad(f, xa, xb, ya, yb, options?) -> result, error
```

Double integration over rectangular or curvilinear regions.

**Parameters:**
- `f` - Function `f(y, x)` to integrate (note order: y first, then x)
- `xa`, `xb` - x-axis limits
- `ya`, `yb` - y-axis limits (numbers or functions of x)
- `options` (optional) - Passed to inner quad calls

```lua
-- Rectangular region: ∫∫ xy dxdy over [0,1]×[0,1]
local result = math.integrate.dblquad(
    function(y, x) return x * y end,
    0, 1,  -- x limits
    0, 1   -- y limits
)
print(result)  -- 0.25

-- Triangular region: y from 0 to x
local result = math.integrate.dblquad(
    function(y, x) return 1 end,
    0, 1,  -- x: 0 to 1
    0,     -- y: 0
    function(x) return x end  -- y: to x
)
print(result)  -- 0.5 (area of triangle)
```

---

## tplquad

```
tplquad(f, xa, xb, ya, yb, za, zb, options?) -> result, error
```

Triple integration over 3D regions.

**Parameters:**
- `f` - Function `f(z, y, x)` to integrate
- `xa`, `xb` - x-axis limits
- `ya`, `yb` - y-axis limits (numbers or functions of x)
- `za`, `zb` - z-axis limits (numbers or functions of x, y)
- `options` (optional) - Passed to inner quad calls

```lua
-- Volume of unit cube
local result = math.integrate.tplquad(
    function(z, y, x) return 1 end,
    0, 1, 0, 1, 0, 1
)
print(result)  -- 1.0

-- Integration over sphere (r ≤ 1)
local result = math.integrate.tplquad(
    function(z, y, x) return 1 end,
    -1, 1,  -- x
    function(x) return -math.sqrt(1-x^2) end,
    function(x) return  math.sqrt(1-x^2) end,  -- y
    function(x, y) return -math.sqrt(1-x^2-y^2) end,
    function(x, y) return  math.sqrt(1-x^2-y^2) end   -- z
)
print(result)  -- 4.189... (4π/3)
```

---

## fixed_quad

```
fixed_quad(f, a, b, n?) -> result
```

Fixed-order Gauss-Legendre quadrature. Fast for smooth integrands when you know the required order.

**Parameters:**
- `f` - Function to integrate
- `a`, `b` - Integration limits
- `n` (optional) - Number of points (1-5, default: 5)

```lua
-- 5-point Gauss quadrature
local result = math.integrate.fixed_quad(
    function(x) return x^4 end,
    0, 1,
    5
)
print(result)  -- 0.2 (exact for polynomials up to degree 9)
```

---

## romberg

```
romberg(f, a, b, options?) -> result, error
```

Romberg integration using Richardson extrapolation on trapezoidal rule.

**Parameters:**
- `f` - Function to integrate
- `a`, `b` - Integration limits
- `options` (optional) - Table with:
  - `tol` (number): Tolerance (default: 1e-8)
  - `divmax` (number): Maximum divisions (default: 10)

```lua
local result, error = math.integrate.romberg(
    math.sin, 0, math.pi,
    {tol = 1e-10}
)
print(result)  -- 2.0
```

---

## simps

```
simps(y, x?, dx?) -> result
```

Simpson's rule integration. Can integrate sampled data or functions.

**Parameters:**
- `y` - Array of function values OR function
- `x` (optional) - Array of x values OR lower limit (if y is function)
- `dx` (optional) - Step size OR upper limit (if y is function)

```lua
-- Integrate sampled data
local y = {0, 1, 4, 9, 16}
local result = math.integrate.simps(y, nil, 1)  -- dx=1
print(result)  -- ~43.333

-- Integrate function
local result = math.integrate.simps(
    function(x) return x^2 end,
    0,   -- a
    4    -- b
)
print(result)  -- ~21.333
```

---

## trapz

```
trapz(y, x?, dx?) -> result
```

Trapezoidal rule integration. Handles non-uniform spacing.

**Parameters:**
- `y` - Array of function values
- `x` (optional) - Array of x values
- `dx` (optional) - Uniform step size (default: 1)

```lua
-- Uniform spacing
local y = {1, 2, 3, 4, 5}
local result = math.integrate.trapz(y, nil, 0.5)  -- dx=0.5
print(result)  -- 6.0

-- Non-uniform spacing
local x = {0, 1, 3, 7}
local y = {0, 1, 3, 7}
local result = math.integrate.trapz(y, x)
print(result)  -- 21.0
```

---

## solve_ivp

```
solve_ivp(fun, t_span, y0, options?) -> solution
```

Solve initial value problems for ODE systems using adaptive Runge-Kutta methods. The modern interface similar to SciPy.

**Parameters:**
- `fun` - Function `f(t, y)` returning `dy/dt` (array)
- `t_span` - `{t0, tf}` - initial and final time
- `y0` - Initial state (array)
- `options` (optional) - Table with:
  - `method` (string): `'RK45'` (default), `'RK23'`, or `'RK4'`
  - `t_eval` (array): Times at which to store solution
  - `max_step` (number): Maximum step size (default: inf)
  - `rtol` (number): Relative tolerance (default: 1e-3)
  - `atol` (number): Absolute tolerance (default: 1e-6)
  - `first_step` (number): Initial step size (default: auto)

**Returns:** Table with:
- `t` - Array of times
- `y` - Array of states (each element is an array of state variables)
- `success` - Boolean indicating completion
- `message` - Status message
- `nfev` - Number of function evaluations

```lua
-- Exponential decay: dy/dt = -y, y(0) = 1
local sol = math.integrate.solve_ivp(
    function(t, y) return {-y[1]} end,
    {0, 5},  -- t_span
    {1}      -- y0
)

print("Final value:", sol.y[#sol.y][1])  -- e^-5 ≈ 0.00674
print("Evaluations:", sol.nfev)

-- Harmonic oscillator: d²x/dt² = -x
-- Convert to system: y1=x, y2=dx/dt
local sol = math.integrate.solve_ivp(
    function(t, y)
        return {
            y[2],      -- dy1/dt = y2
            -y[1]      -- dy2/dt = -y1
        }
    end,
    {0, 2*math.pi},
    {1, 0},  -- x(0)=1, v(0)=0
    {t_eval = {0, math.pi/2, math.pi, 3*math.pi/2, 2*math.pi}}
)

for i, t in ipairs(sol.t) do
    print(string.format("t=%.2f: x=%.4f", t, sol.y[i][1]))
end
```

**Method selection:**
- `RK45`: Dormand-Prince 5(4) - best for most problems
- `RK23`: Bogacki-Shampine 3(2) - faster for loose tolerances
- `RK4`: Classical Runge-Kutta - fixed step, no error control

---

## odeint

```
odeint(func, y0, t, options?) -> y [, info]
```

Legacy interface compatible with SciPy's `odeint`. Integrates at specified time points.

**Parameters:**
- `func` - Function `f(y, t, ...)` returning `dy/dt` (note: y first, then t)
- `y0` - Initial state (array)
- `t` - Array of times at which to compute solution
- `options` (optional) - Table with:
  - `args` (table): Additional arguments to pass to func
  - `rtol` (number): Relative tolerance (default: 1.49e-8)
  - `atol` (number): Absolute tolerance (default: 1.49e-8)
  - `h0` (number): Initial step size (default: auto)
  - `hmax` (number): Maximum step size (default: auto)
  - `full_output` (boolean): Return extra info (default: false)

**Returns:**
- `y` - 2D array: `y[time_index][component_index]`
- `info` (if `full_output=true`) - Table containing `nfe` and `message`

```lua
-- Exponential decay at specific times
local function dydt(y, t)
    return {-y[1]}
end

local times = {0, 1, 2, 3, 4, 5}
local y = math.integrate.odeint(dydt, {1}, times)

for i, t in ipairs(times) do
    print(string.format("t=%d: y=%.4f", t, y[i][1]))
end

-- With additional parameters
local function growth(y, t, k)
    return {k * y[1]}
end

local y = math.integrate.odeint(
    growth,
    {1},
    {0, 1, 2},
    {args = {0.5}}  -- growth rate k=0.5
)
```

---

## Examples

### Complex Integration

```lua
-- Contour integral: ∫z dz around unit circle
-- Parameterize: z = e^(it), dz = ie^(it)dt, t: 0 to 2π
local result = math.integrate.quad(
    function(t)
        local z = {re=math.cos(t), im=math.sin(t)}
        local dz = {re=-math.sin(t), im=math.cos(t)}
        -- z * dz (complex multiplication)
        return {
            re = z.re*dz.re - z.im*dz.im,
            im = z.re*dz.im + z.im*dz.re
        }
    end,
    0, 2*math.pi
)
print(result.re, result.im)  -- 0, 0 (closed contour)
```

### Coupled ODEs: Predator-Prey (Lotka-Volterra)

```lua
-- dx/dt = ax - bxy  (prey)
-- dy/dt = -cy + dxy (predator)
local function lotka_volterra(t, y)
    local x, y_pred = y[1], y[2]
    local a, b, c, d = 1.5, 1.0, 3.0, 1.0
    return {
        a*x - b*x*y_pred,        -- dx/dt
        -c*y_pred + d*x*y_pred   -- dy/dt
    }
end

local sol = math.integrate.solve_ivp(
    lotka_volterra,
    {0, 15},
    {10, 5},  -- Initial: 10 prey, 5 predators
    {rtol=1e-6, atol=1e-8}
)

-- Find population at t=15
local final = sol.y[#sol.y]
print(string.format("Final: %.2f prey, %.2f predators", final[1], final[2]))
```

### Stiff ODE: Van der Pol Oscillator

```lua
-- d²x/dt² - μ(1-x²)dx/dt + x = 0
-- System: y1=x, y2=dx/dt
local function van_der_pol(t, y)
    local mu = 1000  -- Stiffness parameter
    return {
        y[2],
        mu * (1 - y[1]^2) * y[2] - y[1]
    }
end

local sol = math.integrate.solve_ivp(
    van_der_pol,
    {0, 3000},
    {2, 0},
    {
        method = 'RK45',
        max_step = 1,  -- Small steps for stiff problem
        rtol = 1e-4,
        atol = 1e-6
    }
)

print("Solved in", sol.nfev, "evaluations")
```

### Numerical Probability Integrals

```lua
-- CDF of standard normal: Φ(x) = ∫_{-∞}^x (1/√2π)e^(-t²/2) dt
local function normal_cdf(x)
    local result = math.integrate.quad(
        function(t)
            return (1/math.sqrt(2*math.pi)) * math.exp(-0.5*t*t)
        end,
        -math.huge,
        x,
        {epsrel=1e-10}
    )
    return result
end

print(normal_cdf(0))     -- 0.5
print(normal_cdf(1.96))  -- 0.975
print(normal_cdf(-1.96)) -- 0.025
```

### Area and Volume Calculations

```lua
-- Area between curves: y=x² and y=√x from x=0 to x=1
local area = math.integrate.quad(
    function(x) return math.sqrt(x) - x*x end,
    0, 1
)
print("Area:", area)  -- 1/3

-- Volume of revolution: rotate y=sin(x) around x-axis, x:0 to π
-- V = π∫y²dx
local volume = math.pi * math.integrate.quad(
    function(x) return math.sin(x)^2 end,
    0, math.pi
)
print("Volume:", volume)  -- π²/2
```

### Performance Tips

1. **Choose the right method:**
   - Use `quad` for general purpose adaptive integration
   - Use `fixed_quad` when you know the smoothness (faster)
   - Use `romberg` for very smooth functions
   - Use `simps`/`trapz` for pre-sampled data

2. **Adjust tolerances:**
   - Default `quad` tolerances (1.49e-8) balance speed and accuracy
   - Tighten for critical calculations: `{epsabs=1e-12, epsrel=1e-12}`
   - Loosen for rough estimates: `{epsabs=1e-4, epsrel=1e-4}`

3. **ODE solver tuning:**
   - `RK45` (default) works well for most problems
   - Use `max_step` to prevent large jumps in stiff problems
   - Provide good `first_step` estimate if you know the scale
   - Use `t_eval` to get output at specific times (more efficient than dense output)

4. **Infinite integrals:**
   - Transform to finite domain when possible
   - Check that integrand decays sufficiently fast
   - Increase `limit` if convergence is slow
