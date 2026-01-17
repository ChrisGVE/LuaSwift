# Distributions Module

Probability distributions for statistical computing.

## Overview

The Distributions module provides a comprehensive set of probability distributions including PDF, CDF, quantile functions, and random sampling. Available under `math.distributions` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local dist = math.distributions
```

## Continuous Distributions

### Normal Distribution

#### dist.normal(mean?, std?)
Creates a normal (Gaussian) distribution.

```lua
-- Standard normal N(0, 1)
local std_normal = dist.normal()

-- Custom parameters N(10, 2)
local custom = dist.normal(10, 2)

-- PDF
print(std_normal:pdf(0))      -- 0.3989... (peak at 0)
print(custom:pdf(10))         -- Peak at mean=10

-- CDF
print(std_normal:cdf(0))      -- 0.5
print(std_normal:cdf(1.96))   -- ~0.975

-- Quantile (inverse CDF)
print(std_normal:quantile(0.5))    -- 0
print(std_normal:quantile(0.975))  -- ~1.96

-- Random sampling
local sample = std_normal:sample()
local samples = std_normal:sample(1000)
```

### Student's t Distribution

#### dist.t(df)
Creates a t-distribution with degrees of freedom.

```lua
local t_dist = dist.t(10)  -- 10 degrees of freedom

print(t_dist:pdf(0))        -- Peak at 0
print(t_dist:cdf(1.812))    -- ~0.95
print(t_dist:quantile(0.95))
```

### Chi-Squared Distribution

#### dist.chi2(df)
Creates a chi-squared distribution.

```lua
local chi2 = dist.chi2(5)   -- 5 degrees of freedom

print(chi2:pdf(5))
print(chi2:cdf(11.07))      -- ~0.95
```

### F Distribution

#### dist.f(df1, df2)
Creates an F-distribution.

```lua
local f_dist = dist.f(5, 10)  -- df1=5, df2=10

print(f_dist:pdf(1))
print(f_dist:cdf(3.33))       -- ~0.95
```

### Gamma Distribution

#### dist.gamma(shape, scale?)
Creates a gamma distribution.

```lua
local gamma_dist = dist.gamma(2, 2)  -- shape=2, scale=2

print(gamma_dist:pdf(2))
print(gamma_dist:cdf(4))
```

### Beta Distribution

#### dist.beta(alpha, beta)
Creates a beta distribution.

```lua
local beta_dist = dist.beta(2, 5)

print(beta_dist:pdf(0.3))
print(beta_dist:cdf(0.5))
```

### Exponential Distribution

#### dist.exponential(rate)
Creates an exponential distribution.

```lua
local exp_dist = dist.exponential(0.5)  -- rate = 0.5

print(exp_dist:pdf(2))
print(exp_dist:cdf(5))
```

## Discrete Distributions

### Binomial Distribution

#### dist.binomial(n, p)
Creates a binomial distribution.

```lua
local binom = dist.binomial(10, 0.5)  -- 10 trials, p=0.5

print(binom:pmf(5))         -- P(X = 5)
print(binom:cdf(7))         -- P(X <= 7)
print(binom:sample())       -- Random sample
```

### Poisson Distribution

#### dist.poisson(lambda)
Creates a Poisson distribution.

```lua
local poisson = dist.poisson(3)  -- lambda = 3

print(poisson:pmf(3))       -- P(X = 3)
print(poisson:cdf(5))       -- P(X <= 5)
```

## Distribution Methods

All distributions support these methods:

### PDF/PMF
- Continuous: `dist:pdf(x)` - Probability density at x
- Discrete: `dist:pmf(x)` - Probability mass at x

### CDF
- `dist:cdf(x)` - Cumulative probability P(X ≤ x)

### Quantile
- `dist:quantile(p)` - Inverse CDF, returns x where P(X ≤ x) = p

### Sampling
- `dist:sample()` - Single random sample
- `dist:sample(n)` - Array of n samples

## Statistical Testing Example

```lua
luaswift.extend_stdlib()
local dist = math.distributions
local stats = math.stats

-- Sample data
local data = {23, 25, 27, 24, 26, 28, 22, 29, 25, 24}

-- Test if mean is significantly different from 20
local n = #data
local mean = stats.mean(data)
local std = stats.std(data)
local se = std / math.sqrt(n)

-- Calculate t-statistic
local t_stat = (mean - 20) / se

-- Get p-value (two-tailed)
local t_dist = dist.t(n - 1)
local p_value = 2 * (1 - t_dist:cdf(math.abs(t_stat)))

print("t-statistic:", t_stat)
print("p-value:", p_value)
```

## Confidence Intervals

```lua
local dist = math.distributions
local stats = math.stats

local data = {/* your data */}
local n = #data
local mean = stats.mean(data)
local std = stats.std(data)
local se = std / math.sqrt(n)

-- 95% confidence interval
local t_dist = dist.t(n - 1)
local t_crit = t_dist:quantile(0.975)
local margin = t_crit * se

print("95% CI: [" .. (mean - margin) .. ", " .. (mean + margin) .. "]")
```

## Monte Carlo Simulation

```lua
local dist = math.distributions

-- Simulate portfolio returns
local stock1 = dist.normal(0.08, 0.2)  -- 8% mean, 20% volatility
local stock2 = dist.normal(0.06, 0.15)

local simulations = 10000
local results = {}

for i = 1, simulations do
    local r1 = stock1:sample()
    local r2 = stock2:sample()
    local portfolio_return = 0.6 * r1 + 0.4 * r2
    results[i] = portfolio_return
end

-- Analyze results
local stats = math.stats
print("Expected return:", stats.mean(results))
print("Volatility:", stats.std(results))
print("5th percentile (VaR):", stats.percentile(results, 5))
```

## See Also

- ``DistributionsModule``
- ``SpecialModule``
- <doc:Modules/SpecialModule>
