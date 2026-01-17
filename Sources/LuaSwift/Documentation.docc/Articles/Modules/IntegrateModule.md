# Integrate Module

Numerical integration and ODE solvers.

## Overview

The Integrate module provides numerical integration (quadrature) and ordinary differential equation (ODE) solvers. Available under `math.integrate` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local integrate = math.integrate
```

## Definite Integrals

### integrate.quad(f, a, b, options?)
Compute definite integral of f from a to b.

```lua
-- Integrate sin(x) from 0 to π
local function f(x)
    return math.sin(x)
end

local result, error = integrate.quad(f, 0, math.pi)
print("Result:", result)     -- ~2.0
print("Error estimate:", error)
```

### Options

```lua
local result, error = integrate.quad(f, a, b, {
    epsabs = 1e-8,   -- Absolute error tolerance
    epsrel = 1e-6,   -- Relative error tolerance
    limit = 50       -- Max subdivisions
})
```

## Examples

### Area Under Curve

```lua
-- Area under Gaussian curve
local function gaussian(x)
    return math.exp(-x^2 / 2) / math.sqrt(2 * math.pi)
end

-- Integrate from -3 to 3 (approximately 99.7% of distribution)
local area = integrate.quad(gaussian, -3, 3)
print("Area:", area)  -- ~0.997
```

### Work Done by Variable Force

```lua
-- Force F(x) = 3x^2 from x=0 to x=5
local function force(x)
    return 3 * x^2
end

local work = integrate.quad(force, 0, 5)
print("Work:", work)  -- 125 Joules
```

### Volume of Revolution

```lua
-- Volume when y = x^2 is rotated around x-axis from 0 to 1
local function f(x)
    return math.pi * (x^2)^2
end

local volume = integrate.quad(f, 0, 1)
print("Volume:", volume)  -- π/5
```

## Infinite Integrals

```lua
-- Integrate from 0 to infinity
local function f(x)
    return math.exp(-x)
end

local result = integrate.quad(f, 0, math.huge)
print("Result:", result)  -- ~1.0
```

## ODE Solvers

### integrate.odeint(f, y0, t, options?)
Solve ordinary differential equations.

```lua
-- Solve dy/dt = -k*y with y(0) = 1
local function dydt(t, y)
    local k = 0.5
    return -k * y
end

local y0 = 1.0
local t = {0, 1, 2, 3, 4, 5}  -- Time points

local solution = integrate.odeint(dydt, y0, t)
for i, val in ipairs(solution) do
    print("t=" .. t[i] .. ", y=" .. val)
end
```

### System of ODEs

```lua
-- Solve coupled equations
-- dx/dt = y
-- dy/dt = -x (harmonic oscillator)
local function derivatives(t, state)
    local x, y = state[1], state[2]
    return {y, -x}
end

local y0 = {1.0, 0.0}  -- Initial: x=1, y=0
local t = {}
for i = 0, 100 do
    t[i+1] = i * 0.1
end

local solution = integrate.odeint(derivatives, y0, t)
-- solution[i] = {x(t[i]), y(t[i])}
```

## Advanced Integration

### Improper Integrals

```lua
-- Integral with singularity at endpoint
local function f(x)
    return 1 / math.sqrt(x)
end

-- From 0 to 1 (singularity at 0)
local result = integrate.quad(f, 0, 1)
print("Result:", result)  -- 2.0
```

### Oscillatory Integrands

```lua
-- Highly oscillatory function
local function f(x)
    return math.sin(100 * x)
end

local result = integrate.quad(f, 0, 2*math.pi, {
    limit = 100  -- More subdivisions for oscillatory functions
})
```

## Physical Applications

### Projectile Motion

```lua
-- Solve projectile with air resistance
-- dv/dt = -g - k*v^2
local function derivatives(t, state)
    local y, v = state[1], state[2]  -- position, velocity
    local g = 9.81
    local k = 0.01
    local dy_dt = v
    local dv_dt = -g - k * v^2
    return {dy_dt, dv_dt}
end

local y0 = {0, 50}  -- Start at ground with 50 m/s upward
local t = {}
for i = 0, 100 do
    t[i+1] = i * 0.1
end

local solution = integrate.odeint(derivatives, y0, t)
```

### RC Circuit

```lua
-- Charging capacitor: dV/dt = (V0 - V) / (R*C)
local function dVdt(t, V)
    local V0 = 10  -- Source voltage
    local RC = 1.0 -- Time constant
    return (V0 - V) / RC
end

local V0 = 0  -- Initially uncharged
local t = {0, 0.5, 1, 1.5, 2, 2.5, 3}

local voltages = integrate.odeint(dVdt, V0, t)
```

### Population Dynamics (Lotka-Volterra)

```lua
-- Predator-prey model
local function derivatives(t, state)
    local prey, predator = state[1], state[2]
    local alpha, beta = 1.0, 0.1   -- Prey growth, predation rate
    local delta, gamma = 0.1, 1.0  -- Predator efficiency, death rate

    local dprey_dt = alpha * prey - beta * prey * predator
    local dpred_dt = delta * prey * predator - gamma * predator

    return {dprey_dt, dpred_dt}
end

local y0 = {10, 5}  -- Initial populations
local t = {}
for i = 0, 200 do
    t[i+1] = i * 0.1
end

local solution = integrate.odeint(derivatives, y0, t)
```

## Performance Notes

- Uses adaptive quadrature based on QUADPACK
- ODE solver uses Runge-Kutta method (RK4)
- For stiff equations, use smaller time steps
- Vectorized operations improve performance for system of ODEs

## See Also

- ``IntegrateModule``
- <doc:Modules/OptimizeModule>
- <doc:Modules/InterpolateModule>
