# Distributions Module

Probability distributions and statistical tests for scientific computing.

## Overview

The Distributions module provides scipy.stats-compatible probability distributions with functional-style API: PDF, CDF, percent-point function (PPF/quantile), random sampling, and distribution statistics. Statistical tests and descriptive statistics are also included.

> Important: This module requires the **NumericSwift** optional dependency. It is compiled only when `LUASWIFT_INCLUDE_NUMERICSWIFT=1` is set at build time. The flag is **off by default**. When NumericSwift is absent the `math.stats` namespace and all symbols documented here are unavailable.

## Installation

```swift
// Install all modules (NumericSwift must be available)
ModuleRegistry.installModules(in: engine)

// Or install just the distributions module
DistributionsModule.register(in: engine)
```

```lua
luaswift.extend_stdlib()
-- Distributions are available under math.stats.<name>
```

## Namespace

All distributions and tests live under `math.stats`. The same symbols are also aliased under `luaswift.distributions` for convenience.

```lua
math.stats.norm.pdf(0)          -- primary namespace
luaswift.distributions.norm.pdf(0)  -- alias, identical
```

## Continuous Distributions

Each distribution is a table of functions. All share the same method set: `pdf`, `cdf`, `ppf`, `rvs`, `mean`, `var`, `std`.

### Normal Distribution — `math.stats.norm`

Signature group: `(x_or_p_or_size, loc=0, scale=1)`

```lua
-- PDF: probability density at x
local y = math.stats.norm.pdf(0)           -- ~0.3989
local y = math.stats.norm.pdf(5, 5, 2)    -- peak of N(5, 2) at x=5

-- CDF: cumulative probability P(X <= x)
local p = math.stats.norm.cdf(1.96)       -- ~0.975
local p = math.stats.norm.cdf(7, 5, 2)   -- N(5,2), x=7

-- PPF: percent-point function (inverse CDF)
local x = math.stats.norm.ppf(0.975)      -- ~1.96
local x = math.stats.norm.ppf(0.975, 5, 2)

-- RVS: random variates
local single  = math.stats.norm.rvs()          -- 1 sample from N(0,1)
local samples = math.stats.norm.rvs(100)       -- array of 100 samples
local samples = math.stats.norm.rvs(100, 5, 2) -- from N(5,2)

-- Distribution statistics
local m = math.stats.norm.mean(0, 1)   -- 0.0
local v = math.stats.norm.var(0, 1)    -- 1.0
local s = math.stats.norm.std(0, 1)    -- 1.0
```

### Uniform Distribution — `math.stats.uniform`

Signature group: `(x_or_p_or_size, loc=0, scale=1)` — support is `[loc, loc+scale]`

```lua
local y = math.stats.uniform.pdf(0.5)          -- 1.0 on [0,1]
local p = math.stats.uniform.cdf(0.5)          -- 0.5
local x = math.stats.uniform.ppf(0.75)         -- 0.75
local s = math.stats.uniform.rvs(50, 2, 8)     -- 50 samples from [2,10]
local m = math.stats.uniform.mean(0, 1)        -- 0.5
```

### Exponential Distribution — `math.stats.expon`

Signature group: `(x_or_p_or_size, loc=0, scale=1)` — `scale` = 1/lambda

```lua
local y = math.stats.expon.pdf(1)              -- pdf at x=1 (scale=1)
local p = math.stats.expon.cdf(1)              -- ~0.632
local x = math.stats.expon.ppf(0.5)            -- median ~0.693
local s = math.stats.expon.rvs(200, 0, 2)      -- 200 samples, mean=2
local m = math.stats.expon.mean(0, 2)          -- 2.0
```

### Student's t Distribution — `math.stats.t`

Signature group: `(x_or_p_or_size, df, loc=0, scale=1)` — `df` is required

```lua
local y = math.stats.t.pdf(0, 10)             -- peak, 10 df
local p = math.stats.t.cdf(1.812, 10)         -- ~0.95
local x = math.stats.t.ppf(0.975, 29)         -- critical value, 29 df
local s = math.stats.t.rvs(100, 10)           -- 100 samples, 10 df
local m = math.stats.t.mean(10)               -- 0.0
local v = math.stats.t.var(10)                -- 10/8 = 1.25
```

### Chi-Squared Distribution — `math.stats.chi2`

Signature group: `(x_or_p_or_size, df, loc=0, scale=1)` — `df` is required

```lua
local y = math.stats.chi2.pdf(5, 5)
local p = math.stats.chi2.cdf(11.07, 5)       -- ~0.95
local x = math.stats.chi2.ppf(0.95, 5)        -- ~11.07
local s = math.stats.chi2.rvs(50, 5)
local m = math.stats.chi2.mean(5)             -- 5.0
```

### F Distribution — `math.stats.f`

Signature group: `(x_or_p_or_size, dfn, dfd, loc=0, scale=1)` — both `dfn` and `dfd` are required

```lua
local y = math.stats.f.pdf(1, 5, 10)
local p = math.stats.f.cdf(3.33, 5, 10)       -- ~0.95
local x = math.stats.f.ppf(0.95, 5, 10)       -- ~3.33
local s = math.stats.f.rvs(50, 5, 10)
local m = math.stats.f.mean(5, 10)            -- 10/8 = 1.25
```

### Gamma Distribution — `math.stats.gamma_dist`

Signature group: `(x_or_p_or_size, a, loc=0, scale=1)` — `a` is the shape parameter

> Note: The Lua name is `gamma_dist` (not `gamma`) to avoid collision with the gamma special function in `math.stats`.

```lua
local y = math.stats.gamma_dist.pdf(2, 2)     -- shape=2
local p = math.stats.gamma_dist.cdf(4, 2)
local x = math.stats.gamma_dist.ppf(0.5, 2)
local s = math.stats.gamma_dist.rvs(100, 2, 0, 2)  -- scale=2
local m = math.stats.gamma_dist.mean(2, 0, 1) -- a * scale = 2.0
```

### Beta Distribution — `math.stats.beta_dist`

Signature group: `(x_or_p_or_size, a, b, loc=0, scale=1)` — both `a` and `b` are required

> Note: The Lua name is `beta_dist` (not `beta`) to avoid collision with the beta special function in `math.stats`.

```lua
local y = math.stats.beta_dist.pdf(0.3, 2, 5)
local p = math.stats.beta_dist.cdf(0.5, 2, 5)
local x = math.stats.beta_dist.ppf(0.5, 2, 5)
local s = math.stats.beta_dist.rvs(100, 2, 5)
local m = math.stats.beta_dist.mean(2, 5)     -- a/(a+b) = 2/7 ~0.286
```

## Method Reference

The table below summarises every method available on each distribution object.

| Method | Arguments | Returns |
|--------|-----------|---------|
| `pdf` | `x [, shape_params...] [, loc, scale]` | density at x |
| `cdf` | `x [, shape_params...] [, loc, scale]` | cumulative probability P(X ≤ x) |
| `ppf` | `p [, shape_params...] [, loc, scale]` | quantile: x such that P(X ≤ x) = p |
| `rvs` | `size [, shape_params...] [, loc, scale]` | single number (size=1) or array |
| `mean` | `[shape_params...] [, loc, scale]` | distribution mean |
| `var` | `[shape_params...] [, loc, scale]` | distribution variance |
| `std` | `[shape_params...] [, loc, scale]` | distribution standard deviation |

Shape parameters by distribution:

| Distribution | Shape params | Default loc | Default scale |
|---|---|---|---|
| `norm` | — | 0 | 1 |
| `uniform` | — | 0 | 1 |
| `expon` | — | 0 | 1 |
| `t` | `df` (required) | 0 | 1 |
| `chi2` | `df` (required) | 0 | 1 |
| `f` | `dfn`, `dfd` (both required) | 0 | 1 |
| `gamma_dist` | `a` (shape, required) | 0 | 1 |
| `beta_dist` | `a`, `b` (both required) | 0 | 1 |

## Statistical Tests

### `math.stats.ttest_1samp(sample, popmean)`

One-sample t-test. Tests whether the sample mean differs from `popmean`.

**Returns:** `statistic, pvalue`

```lua
local data = {23, 25, 27, 24, 26, 28, 22, 29, 25, 24}
local t, p = math.stats.ttest_1samp(data, 20)
print(string.format("t=%.4f  p=%.4f", t, p))
```

### `math.stats.ttest_ind(sample1, sample2, equal_var?)`

Independent two-sample t-test. `equal_var` defaults to `true` (pooled variance).

**Returns:** `statistic, pvalue`

```lua
local a = {10, 12, 11, 13, 12}
local b = {14, 15, 13, 16, 14}
local t, p = math.stats.ttest_ind(a, b)
local t2, p2 = math.stats.ttest_ind(a, b, false)  -- Welch's t-test
```

### `math.stats.pearsonr(x, y)`

Pearson correlation coefficient.

**Returns:** `correlation, pvalue`

```lua
local x = {1, 2, 3, 4, 5}
local y = {2, 4, 5, 4, 5}
local r, p = math.stats.pearsonr(x, y)
```

### `math.stats.spearmanr(x, y)`

Spearman rank correlation coefficient.

**Returns:** `correlation, pvalue`

```lua
local r, p = math.stats.spearmanr(x, y)
```

### `math.stats.describe(data)`

Descriptive statistics for a data array.

**Returns:** table with fields `nobs`, `min`, `max`, `mean`, `variance`, `skewness`, `kurtosis`

```lua
local stats = math.stats.describe({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
print(stats.mean)      -- 5.5
print(stats.variance)  -- 9.1667
print(stats.skewness)  -- ~0.0
```

### `math.stats.zscore(data, ddof?)`

Standardise each observation. `ddof` controls degrees of freedom (default `0`).

**Returns:** array of z-scores

```lua
local z = math.stats.zscore({10, 20, 30, 40, 50})
-- z[3] == 0.0  (median of symmetric data)
```

### `math.stats.skew(data)`

Sample skewness.

**Returns:** number

```lua
local s = math.stats.skew({1, 1, 1, 2, 3, 10})  -- right-skewed > 0
```

### `math.stats.kurtosis(data, fisher?)`

Sample kurtosis. `fisher=true` (default) returns excess kurtosis (normal = 0); `fisher=false` returns Pearson kurtosis (normal = 3).

**Returns:** number

```lua
local k = math.stats.kurtosis({1, 2, 2, 3, 3, 3, 4, 4, 5})
```

### `math.stats.mode(data)`

Most frequent value in a data array.

**Returns:** table with fields `mode` (value) and `count` (frequency)

```lua
local result = math.stats.mode({1, 2, 2, 3, 2, 4})
print(result.mode)   -- 2
print(result.count)  -- 3
```

## Practical Examples

### Hypothesis Test

```lua
luaswift.extend_stdlib()

local data = {23, 25, 27, 24, 26, 28, 22, 29, 25, 24}

-- One-sample t-test against population mean of 20
local t, p = math.stats.ttest_1samp(data, 20)
print(string.format("t=%.4f  p=%.6f", t, p))

if p < 0.05 then
    print("Reject null hypothesis (p < 0.05)")
end
```

### Confidence Interval

```lua
luaswift.extend_stdlib()

local data   = {23, 25, 27, 24, 26, 28, 22, 29, 25, 24}
local n      = #data
local stats  = math.stats.describe(data)
local se     = math.sqrt(stats.variance / n)

-- 95% CI using t critical value
local t_crit = math.stats.t.ppf(0.975, n - 1)
local margin = t_crit * se
print(string.format("95%% CI: [%.2f, %.2f]", stats.mean - margin, stats.mean + margin))
```

### Monte Carlo Simulation

```lua
luaswift.extend_stdlib()

-- Simulate portfolio returns: 60% stock A (N(8%,20%)), 40% stock B (N(6%,15%))
local results = {}
for i = 1, 10000 do
    local r1 = math.stats.norm.rvs(1, 0.08, 0.20)
    local r2 = math.stats.norm.rvs(1, 0.06, 0.15)
    results[i] = 0.6 * r1 + 0.4 * r2
end

local s = math.stats.describe(results)
print(string.format("Expected return: %.4f", s.mean))
print(string.format("Volatility:      %.4f", math.sqrt(s.variance)))
```

### Distribution Fitting Check

```lua
luaswift.extend_stdlib()

-- Generate data and check normality via skew/kurtosis
local samples = math.stats.norm.rvs(1000, 0, 1)
local sk = math.stats.skew(samples)
local ku = math.stats.kurtosis(samples)  -- excess kurtosis, ~0 for normal
print(string.format("skew=%.3f  excess_kurtosis=%.3f", sk, ku))
```

## See Also

- ``DistributionsModule``
- ``SpecialModule``
- <doc:SpecialModule>
