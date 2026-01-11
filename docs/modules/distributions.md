# Distributions Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.distributions` | **Global:** `math.stats` (after extend_stdlib)

The Distributions module provides scipy.stats-compatible probability distributions and statistical functions. Each distribution implements pdf, cdf, ppf (quantile), rvs (random samples), and moment methods.

## Available Distributions

### Continuous Distributions

- **`norm`** - Normal (Gaussian) distribution
- **`uniform`** - Uniform distribution
- **`expon`** - Exponential distribution
- **`t`** - Student's t distribution
- **`chi2`** - Chi-squared distribution
- **`f`** - F distribution
- **`gamma_dist`** - Gamma distribution
- **`beta_dist`** - Beta distribution

## Distribution Methods

All distributions support the following methods:

- **`pdf(x, ...params)`** - Probability density function
- **`cdf(x, ...params)`** - Cumulative distribution function
- **`ppf(p, ...params)`** - Percent point function (inverse CDF, quantile)
- **`rvs(size, ...params)`** - Random variates (samples)
- **`mean(...params)`** - Distribution mean
- **`var(...params)`** - Distribution variance
- **`std(...params)`** - Distribution standard deviation

### Parameter Convention

Most distributions follow the scipy convention:
- **`loc`** - Location parameter (shift)
- **`scale`** - Scale parameter (stretch)

Default values: `loc=0`, `scale=1`

## Basic Usage

```lua
luaswift.extend_stdlib()

-- Normal distribution N(0, 1)
local p = math.stats.norm.pdf(0)        -- 0.3989
local q = math.stats.norm.cdf(1.96)     -- 0.975
local x = math.stats.norm.ppf(0.975)    -- 1.96
local samples = math.stats.norm.rvs(100) -- 100 samples

-- Normal distribution N(5, 2)
local mu, sigma = 5, 2
local p2 = math.stats.norm.pdf(5, mu, sigma)
local samples2 = math.stats.norm.rvs(100, mu, sigma)
```

## Distributions Reference

### Normal Distribution

```lua
math.stats.norm
```

Standard normal distribution (Gaussian).

**Parameters:**
- `loc` - Mean (default: 0)
- `scale` - Standard deviation (default: 1)

**Examples:**

```lua
-- Standard normal N(0, 1)
print(math.stats.norm.pdf(0))         -- 0.3989
print(math.stats.norm.cdf(1.96))      -- 0.975
print(math.stats.norm.ppf(0.025))     -- -1.96

-- Custom normal N(100, 15)
local mu, sigma = 100, 15
print(math.stats.norm.mean(mu, sigma))  -- 100
print(math.stats.norm.std(mu, sigma))   -- 15

-- Generate random samples
local samples = math.stats.norm.rvs(1000, mu, sigma)
```

### Uniform Distribution

```lua
math.stats.uniform
```

Uniform distribution on interval [loc, loc + scale].

**Parameters:**
- `loc` - Lower bound (default: 0)
- `scale` - Width of interval (default: 1)

**Examples:**

```lua
-- Uniform on [0, 1]
print(math.stats.uniform.pdf(0.5))    -- 1.0
print(math.stats.uniform.cdf(0.75))   -- 0.75

-- Uniform on [10, 20]
local a, width = 10, 10
print(math.stats.uniform.pdf(15, a, width))  -- 0.1
print(math.stats.uniform.mean(a, width))     -- 15

-- Generate random values in [0, 100]
local samples = math.stats.uniform.rvs(100, 0, 100)
```

### Exponential Distribution

```lua
math.stats.expon
```

Exponential distribution (continuous analog of geometric).

**Parameters:**
- `loc` - Location shift (default: 0)
- `scale` - 1/lambda, where lambda is rate parameter (default: 1)

**Examples:**

```lua
-- Standard exponential (rate=1)
print(math.stats.expon.pdf(0))        -- 1.0
print(math.stats.expon.cdf(1))        -- 0.632
print(math.stats.expon.mean())        -- 1.0

-- Exponential with rate=0.5 (scale=2)
local scale = 2
print(math.stats.expon.mean(0, scale))  -- 2.0
print(math.stats.expon.std(0, scale))   -- 2.0

-- Simulate waiting times (mean=5 minutes)
local wait_times = math.stats.expon.rvs(100, 0, 5)
```

### Student's t Distribution

```lua
math.stats.t
```

Student's t distribution (heavy-tailed, used in t-tests).

**Parameters:**
- `df` - Degrees of freedom (required)
- `loc` - Location (default: 0)
- `scale` - Scale (default: 1)

**Examples:**

```lua
-- t distribution with 10 degrees of freedom
local df = 10
print(math.stats.t.pdf(0, df))        -- 0.3891
print(math.stats.t.cdf(1.812, df))    -- 0.95
print(math.stats.t.ppf(0.975, df))    -- 2.228

-- Compare with normal (df→∞)
print(math.stats.t.ppf(0.975, 30))    -- 2.042
print(math.stats.norm.ppf(0.975))     -- 1.96

-- Variance undefined for df ≤ 2
print(math.stats.t.var(2))            -- inf
print(math.stats.t.var(3))            -- 3.0
```

### Chi-squared Distribution

```lua
math.stats.chi2
```

Chi-squared distribution (sum of squared normals).

**Parameters:**
- `df` - Degrees of freedom (required)
- `loc` - Location shift (default: 0)
- `scale` - Scale factor (default: 1)

**Examples:**

```lua
-- Chi-squared with 5 degrees of freedom
local df = 5
print(math.stats.chi2.pdf(5, df))     -- 0.1606
print(math.stats.chi2.cdf(11.07, df)) -- 0.95
print(math.stats.chi2.ppf(0.05, df))  -- 1.145

-- Mean and variance
print(math.stats.chi2.mean(df))       -- 5
print(math.stats.chi2.var(df))        -- 10

-- Goodness-of-fit test simulation
local samples = math.stats.chi2.rvs(1000, df)
```

### F Distribution

```lua
math.stats.f
```

F distribution (ratio of chi-squared distributions).

**Parameters:**
- `dfn` - Numerator degrees of freedom (required)
- `dfd` - Denominator degrees of freedom (required)
- `loc` - Location shift (default: 0)
- `scale` - Scale factor (default: 1)

**Examples:**

```lua
-- F distribution with (5, 10) degrees of freedom
local dfn, dfd = 5, 10
print(math.stats.f.pdf(1, dfn, dfd))      -- 0.6596
print(math.stats.f.cdf(3.33, dfn, dfd))   -- 0.95
print(math.stats.f.ppf(0.95, dfn, dfd))   -- 3.33

-- Mean defined for dfd > 2
print(math.stats.f.mean(dfn, dfd))        -- 1.25
-- Variance defined for dfd > 4
print(math.stats.f.var(dfn, dfd))         -- 1.354

-- ANOVA F-test simulation
local f_stats = math.stats.f.rvs(100, dfn, dfd)
```

### Gamma Distribution

```lua
math.stats.gamma_dist
```

Gamma distribution (generalization of chi-squared and exponential).

**Parameters:**
- `a` - Shape parameter (required)
- `loc` - Location shift (default: 0)
- `scale` - Scale factor (default: 1)

**Examples:**

```lua
-- Gamma(2, 1) distribution
local shape = 2
print(math.stats.gamma_dist.pdf(2, shape))    -- 0.2707
print(math.stats.gamma_dist.cdf(3, shape))    -- 0.8009
print(math.stats.gamma_dist.mean(shape))      -- 2.0
print(math.stats.gamma_dist.var(shape))       -- 2.0

-- Erlang distribution (integer shape)
local k = 5
local samples = math.stats.gamma_dist.rvs(100, k, 0, 2)

-- Note: exponential is gamma with shape=1
print(math.stats.gamma_dist.pdf(1, 1))        -- 0.3679
print(math.stats.expon.pdf(1))                -- 0.3679
```

### Beta Distribution

```lua
math.stats.beta_dist
```

Beta distribution on [0, 1] (useful for probabilities).

**Parameters:**
- `a` - First shape parameter (required)
- `b` - Second shape parameter (required)
- `loc` - Location shift (default: 0)
- `scale` - Scale factor (default: 1)

**Examples:**

```lua
-- Symmetric Beta(2, 2)
local a, b = 2, 2
print(math.stats.beta_dist.pdf(0.5, a, b))    -- 1.5
print(math.stats.beta_dist.mean(a, b))        -- 0.5
print(math.stats.beta_dist.var(a, b))         -- 0.05

-- Skewed Beta(2, 5)
a, b = 2, 5
print(math.stats.beta_dist.mean(a, b))        -- 0.2857
local samples = math.stats.beta_dist.rvs(100, a, b)

-- Uniform is Beta(1, 1)
print(math.stats.beta_dist.pdf(0.7, 1, 1))    -- 1.0
print(math.stats.uniform.pdf(0.7))            -- 1.0
```

## Statistical Functions

### Hypothesis Tests

#### One-Sample t-test

```lua
math.stats.ttest_1samp(sample, popmean)
```

Test if sample mean differs from population mean.

**Returns:** `statistic, pvalue`

**Example:**

```lua
local data = {5.1, 4.9, 5.0, 5.2, 4.8}
local t, p = math.stats.ttest_1samp(data, 5.0)
print(string.format("t=%.3f, p=%.3f", t, p))  -- t=0.000, p=1.000
```

#### Two-Sample t-test

```lua
math.stats.ttest_ind(sample1, sample2, equal_var)
```

Compare means of two independent samples.

**Parameters:**
- `sample1` - First sample
- `sample2` - Second sample
- `equal_var` - Assume equal variance (default: true)

**Returns:** `statistic, pvalue`

**Example:**

```lua
local group1 = {5.1, 4.9, 5.0, 5.2}
local group2 = {4.5, 4.7, 4.6, 4.8}

-- Pooled variance (equal_var=true)
local t, p = math.stats.ttest_ind(group1, group2, true)
print(string.format("t=%.3f, p=%.3f", t, p))

-- Welch's t-test (equal_var=false)
local t2, p2 = math.stats.ttest_ind(group1, group2, false)
print(string.format("t=%.3f, p=%.3f", t2, p2))
```

#### Pearson Correlation

```lua
math.stats.pearsonr(x, y)
```

Compute Pearson correlation coefficient and p-value.

**Returns:** `correlation, pvalue`

**Example:**

```lua
local x = {1, 2, 3, 4, 5}
local y = {2, 4, 5, 4, 5}
local r, p = math.stats.pearsonr(x, y)
print(string.format("r=%.3f, p=%.3f", r, p))  -- r=0.832, p=0.080
```

#### Spearman Correlation

```lua
math.stats.spearmanr(x, y)
```

Compute Spearman rank correlation coefficient (non-parametric).

**Returns:** `correlation, pvalue`

**Example:**

```lua
local x = {1, 2, 3, 4, 5}
local y = {5, 6, 7, 8, 7}
local rho, p = math.stats.spearmanr(x, y)
print(string.format("rho=%.3f, p=%.3f", rho, p))  -- rho=0.821, p=0.089
```

### Descriptive Statistics

#### Comprehensive Description

```lua
math.stats.describe(data)
```

Compute comprehensive descriptive statistics.

**Returns:** Table with keys: `nobs`, `min`, `max`, `mean`, `variance`, `skewness`, `kurtosis`

**Example:**

```lua
local data = {1, 2, 3, 4, 5, 6, 7, 8, 9}
local desc = math.stats.describe(data)

print("Observations:", desc.nobs)      -- 9
print("Range:", desc.min, desc.max)    -- 1, 9
print("Mean:", desc.mean)              -- 5.0
print("Variance:", desc.variance)      -- 7.5
print("Skewness:", desc.skewness)      -- 0.0
print("Kurtosis:", desc.kurtosis)      -- -1.2
```

#### Z-scores

```lua
math.stats.zscore(data, ddof)
```

Compute standardized z-scores.

**Parameters:**
- `data` - Array of values
- `ddof` - Delta degrees of freedom (default: 0)

**Returns:** Array of z-scores

**Example:**

```lua
local data = {1, 2, 3, 4, 5}
local z = math.stats.zscore(data)

for i, val in ipairs(z) do
    print(string.format("z[%d] = %.3f", i, val))
end
-- z[1] = -1.265, z[2] = -0.632, z[3] = 0.000,
-- z[4] = 0.632, z[5] = 1.265
```

#### Skewness

```lua
math.stats.skew(data)
```

Compute Fisher's skewness (asymmetry measure).

**Returns:** Skewness value

**Example:**

```lua
local symmetric = {1, 2, 3, 4, 5}
local right_skewed = {1, 2, 3, 4, 10}

print(math.stats.skew(symmetric))      -- ~0.0
print(math.stats.skew(right_skewed))   -- ~1.3 (positive)
```

#### Kurtosis

```lua
math.stats.kurtosis(data, fisher)
```

Compute kurtosis (tail weight measure).

**Parameters:**
- `data` - Array of values
- `fisher` - Use Fisher's definition (excess kurtosis, default: true)

**Returns:** Kurtosis value

**Example:**

```lua
local data = {1, 2, 3, 4, 5}

-- Excess kurtosis (normal = 0)
print(math.stats.kurtosis(data, true))   -- -1.3

-- Pearson kurtosis (normal = 3)
print(math.stats.kurtosis(data, false))  -- 1.7
```

#### Mode

```lua
math.stats.mode(data)
```

Find the most frequent value.

**Returns:** Table with keys: `mode`, `count`

**Example:**

```lua
local data = {1, 2, 2, 3, 3, 3, 4}
local result = math.stats.mode(data)

print("Mode:", result.mode)      -- 3
print("Count:", result.count)    -- 3
```

## Advanced Examples

### Monte Carlo Simulation

```lua
-- Estimate pi using uniform random points
local function estimate_pi(n)
    local inside = 0
    for i = 1, n do
        local x = math.stats.uniform.rvs(1, -1, 2)
        local y = math.stats.uniform.rvs(1, -1, 2)
        if x*x + y*y <= 1 then
            inside = inside + 1
        end
    end
    return 4 * inside / n
end

print("Pi estimate:", estimate_pi(10000))  -- ~3.14
```

### Central Limit Theorem

```lua
-- Demonstrate CLT with exponential distribution
local function sample_means(dist, size, n_samples)
    local means = {}
    for i = 1, n_samples do
        local samples = dist.rvs(size)
        local sum = 0
        for _, v in ipairs(samples) do sum = sum + v end
        means[i] = sum / size
    end
    return means
end

-- Sample means approach normal even from exponential
local means = sample_means(math.stats.expon, 30, 1000)
local desc = math.stats.describe(means)
print("Skewness of means:", desc.skewness)  -- ~0 (normal-like)
```

### Hypothesis Testing Workflow

```lua
-- Complete A/B test example
local control = {23, 25, 21, 24, 22, 26, 23, 24}
local treatment = {28, 27, 29, 26, 30, 28, 27, 29}

-- Check normality assumption via skewness/kurtosis
print("Control skew:", math.stats.skew(control))
print("Treatment skew:", math.stats.skew(treatment))

-- Perform two-sample t-test
local t, p = math.stats.ttest_ind(control, treatment, true)
print(string.format("t-statistic: %.3f", t))
print(string.format("p-value: %.4f", p))

if p < 0.05 then
    print("Significant difference (reject H0)")
else
    print("No significant difference (fail to reject H0)")
end

-- Effect size (Cohen's d)
local desc_c = math.stats.describe(control)
local desc_t = math.stats.describe(treatment)
local pooled_std = math.sqrt((desc_c.variance + desc_t.variance) / 2)
local cohen_d = (desc_t.mean - desc_c.mean) / pooled_std
print(string.format("Cohen's d: %.3f", cohen_d))
```

### Distribution Fitting

```lua
-- Fit normal distribution to data
local data = {23, 25, 21, 24, 22, 26, 23, 24}
local desc = math.stats.describe(data)

local mu = desc.mean
local sigma = math.sqrt(desc.variance)

print(string.format("Fitted N(%.2f, %.2f)", mu, sigma))

-- Kolmogorov-Smirnov test (simplified)
local max_diff = 0
for _, x in ipairs(data) do
    local empirical = 0
    for _, y in ipairs(data) do
        if y <= x then empirical = empirical + 1 end
    end
    empirical = empirical / #data
    local theoretical = math.stats.norm.cdf(x, mu, sigma)
    max_diff = math.max(max_diff, math.abs(empirical - theoretical))
end
print(string.format("KS statistic: %.4f", max_diff))
```

## Function Reference

| Function | Description |
|----------|-------------|
| **Distributions** | |
| `norm.pdf/cdf/ppf/rvs/mean/var/std` | Normal distribution |
| `uniform.pdf/cdf/ppf/rvs/mean/var/std` | Uniform distribution |
| `expon.pdf/cdf/ppf/rvs/mean/var/std` | Exponential distribution |
| `t.pdf/cdf/ppf/rvs/mean/var/std` | Student's t distribution |
| `chi2.pdf/cdf/ppf/rvs/mean/var/std` | Chi-squared distribution |
| `f.pdf/cdf/ppf/rvs/mean/var/std` | F distribution |
| `gamma_dist.pdf/cdf/ppf/rvs/mean/var/std` | Gamma distribution |
| `beta_dist.pdf/cdf/ppf/rvs/mean/var/std` | Beta distribution |
| **Hypothesis Tests** | |
| `ttest_1samp(sample, popmean)` | One-sample t-test |
| `ttest_ind(s1, s2, equal_var)` | Independent two-sample t-test |
| `pearsonr(x, y)` | Pearson correlation coefficient |
| `spearmanr(x, y)` | Spearman rank correlation |
| **Descriptive Statistics** | |
| `describe(data)` | Comprehensive statistics |
| `zscore(data, ddof)` | Standardized z-scores |
| `skew(data)` | Distribution skewness |
| `kurtosis(data, fisher)` | Distribution kurtosis |
| `mode(data)` | Most frequent value |

## Implementation Notes

- Uses Lanczos approximation for gamma function
- Incomplete beta/gamma via continued fractions and series expansion
- Newton-Raphson iteration for inverse CDFs (ppf)
- Box-Muller transform for normal random variates
- Marsaglia-Tsang method for gamma random variates
- Statistical tests use exact t/F/chi-squared distributions
