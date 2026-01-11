# Statistics Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Global:** `math.stats` (after `extend_stdlib`)

Descriptive statistics functions for analyzing numeric data. All statistics functions operate on Lua arrays containing numeric values.

## Basic Statistics

### sum

Calculate the sum of all values in an array.

```lua
luaswift.extend_stdlib()

local data = {1, 2, 3, 4, 5}
local total = math.stats.sum(data)  -- 15
```

### mean

Calculate the arithmetic mean (average) of values.

```lua
local data = {10, 20, 30, 40}
local avg = math.stats.mean(data)  -- 25
```

### median

Calculate the median (middle value) of a dataset.

```lua
-- Odd number of values
local data1 = {1, 3, 5, 7, 9}
local med1 = math.stats.median(data1)  -- 5

-- Even number of values (average of middle two)
local data2 = {1, 2, 3, 4}
local med2 = math.stats.median(data2)  -- 2.5
```

## Variability Measures

### variance

Calculate the variance of a dataset. Accepts optional `ddof` (delta degrees of freedom) parameter.

```lua
local data = {2, 4, 6, 8, 10}

-- Population variance (ddof=0, default)
local pop_var = math.stats.variance(data)

-- Sample variance (ddof=1)
local sample_var = math.stats.variance(data, 1)
```

**Parameters:**
- `data` (array): Numeric array
- `ddof` (number, optional): Delta degrees of freedom. Default is 0 (population variance). Use 1 for sample variance.

### stddev

Calculate the standard deviation (square root of variance). Accepts optional `ddof` parameter.

```lua
local data = {2, 4, 6, 8, 10}

-- Population standard deviation
local pop_std = math.stats.stddev(data)

-- Sample standard deviation
local sample_std = math.stats.stddev(data, 1)
```

**Parameters:**
- `data` (array): Numeric array
- `ddof` (number, optional): Delta degrees of freedom. Default is 0. Use 1 for sample standard deviation.

## Percentiles and Quantiles

### percentile

Calculate the value at a given percentile using linear interpolation.

```lua
local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

local p25 = math.stats.percentile(data, 25)   -- First quartile
local p50 = math.stats.percentile(data, 50)   -- Median (5.5)
local p75 = math.stats.percentile(data, 75)   -- Third quartile
local p90 = math.stats.percentile(data, 90)   -- 90th percentile
```

**Parameters:**
- `data` (array): Numeric array
- `percentile` (number): Value between 0 and 100

## Advanced Means

### gmean

Calculate the geometric mean (nth root of the product of n values). Requires all positive values.

```lua
-- Geometric mean for growth rates
local growth = {1.05, 1.08, 1.03, 1.07}  -- 5%, 8%, 3%, 7% growth
local avg_growth = math.stats.gmean(growth)  -- ~1.057 (5.7% average)

-- Geometric mean of positive numbers
local data = {2, 8, 32}
local gm = math.stats.gmean(data)  -- 8 (cube root of 512)
```

Uses log-sum-exp formula for numerical stability: `exp(mean(log(x)))`.

### hmean

Calculate the harmonic mean (reciprocal of the arithmetic mean of reciprocals). Requires all positive values.

```lua
-- Harmonic mean for rates and ratios
local speeds = {60, 40, 30}  -- km/h
local avg_speed = math.stats.hmean(speeds)  -- ~40 km/h

-- Harmonic mean useful for averaging ratios
local data = {1, 2, 4}
local hm = math.stats.hmean(data)  -- ~1.71
```

Formula: `n / sum(1/x_i)`.

### mode

Find the most frequently occurring value. Returns the smallest value if there are ties.

```lua
local data = {1, 2, 2, 3, 3, 3, 4}
local most_common = math.stats.mode(data)  -- 3

-- Multiple modes (returns smallest)
local data2 = {1, 1, 2, 2, 3}
local mode2 = math.stats.mode(data2)  -- 1
```

## Usage Examples

### Complete Statistical Summary

```lua
luaswift.extend_stdlib()

local measurements = {23, 25, 28, 29, 30, 32, 35, 37, 38, 42}

-- Central tendency
local avg = math.stats.mean(measurements)      -- 31.9
local med = math.stats.median(measurements)    -- 31

-- Spread
local std = math.stats.stddev(measurements, 1) -- Sample std
local variance = math.stats.variance(measurements, 1)

-- Range
local q25 = math.stats.percentile(measurements, 25)
local q75 = math.stats.percentile(measurements, 75)
local iqr = q75 - q25  -- Interquartile range
```

### Analyzing Test Scores

```lua
local scores = {85, 92, 78, 90, 88, 95, 82, 87, 91, 89}

-- Calculate statistics
local mean_score = math.stats.mean(scores)         -- 87.7
local median_score = math.stats.median(scores)     -- 88.5
local std_dev = math.stats.stddev(scores, 1)       -- ~5.16

-- Find percentile rankings
local passing_threshold = math.stats.percentile(scores, 10)  -- 10th percentile
local excellence_threshold = math.stats.percentile(scores, 90)  -- 90th percentile
```

### Comparing Datasets

```lua
local group_a = {75, 82, 88, 91, 95}
local group_b = {70, 73, 76, 78, 81}

-- Compare means
local mean_a = math.stats.mean(group_a)  -- 86.2
local mean_b = math.stats.mean(group_b)  -- 75.6

-- Compare variability
local std_a = math.stats.stddev(group_a, 1)  -- ~7.79
local std_b = math.stats.stddev(group_b, 1)  -- ~4.34
-- Group A has higher mean and higher variability
```

## Error Handling

All statistics functions validate their inputs:

```lua
-- Empty arrays
math.stats.mean({})  -- Error: mean requires non-empty array

-- Non-numeric values
math.stats.mean({1, "two", 3})  -- Error: all elements must be numbers

-- Invalid percentile range
math.stats.percentile({1, 2, 3}, 150)  -- Error: percentile must be in range [0, 100]

-- Geometric/harmonic mean requirements
math.stats.gmean({-1, 2, 3})  -- Error: requires all positive values
math.stats.hmean({0, 1, 2})   -- Error: requires all positive values

-- Variance with invalid ddof
math.stats.variance({1, 2, 3}, 5)  -- Error: ddof must be less than array length
```

## Function Reference

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `sum(data)` | Sum of all values | `data`: array | number |
| `mean(data)` | Arithmetic mean | `data`: array | number |
| `median(data)` | Median (50th percentile) | `data`: array | number |
| `variance(data, [ddof])` | Variance | `data`: array, `ddof`: number (default 0) | number |
| `stddev(data, [ddof])` | Standard deviation | `data`: array, `ddof`: number (default 0) | number |
| `percentile(data, p)` | Value at percentile p | `data`: array, `p`: number (0-100) | number |
| `gmean(data)` | Geometric mean | `data`: array (all positive) | number |
| `hmean(data)` | Harmonic mean | `data`: array (all positive) | number |
| `mode(data)` | Most frequent value | `data`: array | number |

All functions require non-empty arrays and will throw errors for invalid inputs.
