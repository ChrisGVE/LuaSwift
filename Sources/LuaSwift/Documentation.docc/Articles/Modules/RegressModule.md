# Regression Module

Statistical regression models including OLS, WLS, GLS, GLM, and time series (ARIMA).

## Overview

The Regression module provides statsmodels-style regression analysis with a two-phase API: construct a model object, then call `:fit()` to obtain a results object carrying all statistics and methods.

> Important: This module requires **NumericSwift** and is compiled only when `LUASWIFT_INCLUDE_NUMERICSWIFT=1` is set at build time. It is **off by default**. All content on this page applies only when that flag is enabled.

Models are available under `math.regress` after calling `luaswift.extend_stdlib()`, or directly as `luaswift.regress`.

## Installation

```swift
// NumericSwift must be available and the flag set at build time:
// LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build

// Register all modules (includes regress when NumericSwift is present)
ModuleRegistry.installModules(in: engine)
```

```lua
luaswift.extend_stdlib()
local regress = math.regress
```

## Two-Phase API

Every model follows the same pattern: construct with data, then call `:fit()`.

```lua
local model   = math.regress.OLS(y, X)   -- phase 1: model specification
local results = model:fit()               -- phase 2: numerical fitting
print(results:summary())
```

The constructor validates inputs and stores them. No computation happens until `:fit()` is called. `:fit()` accepts an optional options table for fit-time parameters (`maxiter`, `tol`).

## Ordinary Least Squares (OLS)

### regress.OLS(y, X, opts?)

Constructs an OLS model.

**Parameters:**
- `y` - Response array (1-D table of numbers)
- `X` - Design matrix (2-D table, or 1-D for a single predictor)
- `opts` (optional) - Table with:
  - `yname` (string) - Name for the dependent variable (default: `"y"`)
  - `xnames` (table) - Array of predictor names for the summary table
  - `hasconst` (boolean) - Hint that X already contains a constant column

**Returns:** OLS model object with `:fit(opts?)` method.

Use `regress.add_constant(X)` to prepend a column of ones to your design matrix before passing it to `OLS`.

```lua
local regress = math.regress

-- y = 1 + 2*x1 + 3*x2 + noise
local X_raw = {
    {1, 2}, {2, 3}, {3, 4}, {4, 5}, {5, 6}
}
local y = {9, 14, 19, 24, 29}

-- Prepend intercept column
local X = regress.add_constant(X_raw)

local model   = regress.OLS(y, X, {yname = "sales", xnames = {"const", "x1", "x2"}})
local results = model:fit()

print(results:summary())
print("R²:", results.rsquared)
print("Adj R²:", results.rsquared_adj)
```

### OLS Result Fields

**Per-parameter:**

| Field | Description |
|-------|-------------|
| `params` | Array of fitted coefficients |
| `bse` | Standard errors |
| `tvalues` | t-statistics |
| `pvalues` | Two-sided p-values |

**Robust standard errors (HC sandwich estimators):**

| Field | Description |
|-------|-------------|
| `bse_hc0` | HC0 heteroskedasticity-robust SE |
| `bse_hc1` | HC1 (degrees-of-freedom corrected) SE |
| `bse_hc2` | HC2 SE |
| `bse_hc3` | HC3 SE (recommended for small samples) |

**Per-observation:**

| Field | Description |
|-------|-------------|
| `resid` | Residuals |
| `fittedvalues` | Fitted (predicted) values for the training set |
| `hat_diag` | Diagonal of the hat (leverage) matrix |
| `resid_studentized` | Studentized residuals |
| `cooks_distance` | Cook's distance per observation |
| `dffits` | DFFITS influence measure per observation |

**Model-level:**

| Field | Description |
|-------|-------------|
| `rsquared` | R² |
| `rsquared_adj` | Adjusted R² |
| `fvalue` | F-statistic |
| `f_pvalue` | p-value for the F-test |
| `llf` | Log-likelihood |
| `aic` | Akaike Information Criterion |
| `bic` | Bayesian Information Criterion |
| `ssr` | Sum of squared residuals |
| `ess` | Explained sum of squares |
| `mse_resid` | Mean squared error of residuals |
| `centered_tss` | Centered total sum of squares |
| `nobs` | Number of observations |
| `df_model` | Model degrees of freedom |
| `df_resid` | Residual degrees of freedom |
| `condition_number` | Condition number (multicollinearity indicator) |
| `eigenvalues` | Eigenvalues of X'X |

### OLS Result Methods

#### :summary(opts?)

Returns a formatted text table (string) modelled on the statsmodels summary output.

```lua
-- Default alpha = 0.05 for confidence interval columns
print(results:summary())
print(results:summary({alpha = 0.01}))
```

#### :predict(exog?)

Returns fitted values for the training data when called with no argument, or predictions for a new design matrix.

```lua
-- Fitted values (in-sample)
local fitted = results:predict()

-- Out-of-sample predictions
local X_new = {{1, 6, 7}, {1, 7, 8}}
local preds  = results:predict(X_new)
```

#### :conf_int(alpha?)

Returns confidence intervals for the estimated parameters. Default `alpha = 0.05` (95% intervals).

```lua
local ci = results:conf_int()       -- 95% CI
local ci = results:conf_int(0.01)   -- 99% CI
-- ci[i] = {lower, upper} for parameter i
print(ci[1][1], ci[1][2])           -- intercept interval
```

#### :get_bse(cov_type?)

Returns standard errors for a named covariance type.

```lua
results:get_bse()          -- "nonrobust" (classical SE)
results:get_bse("HC3")     -- HC3 robust SE
-- Valid: "nonrobust", "classical", "HC0", "HC1", "HC2", "HC3"
```

#### :get_influence()

Returns a table of per-observation influence diagnostics.

```lua
local infl = results:get_influence()
-- infl.hat_diag          -- leverage values
-- infl.resid_studentized -- studentized residuals
-- infl.cooks_distance    -- Cook's D
-- infl.dffits            -- DFFITS
```

## Weighted Least Squares (WLS)

### regress.WLS(y, X, weights, opts?)

Constructs a WLS model. Observations with higher weights have more influence on the fit.

**Parameters:**
- `y` - Response array
- `X` - Design matrix
- `weights` - Array of per-observation weights (same length as `y`)
- `opts` (optional) - Same options as `OLS`

**Returns:** Model object with `:fit(opts?)`. Result fields are identical to OLS.

```lua
local regress = math.regress

local y       = {10, 20, 30, 40}
local X       = regress.add_constant({{1}, {2}, {3}, {4}})
local weights = {1, 2, 1, 4}   -- observation 4 is four times more important

local results = regress.WLS(y, X, weights):fit()
print("WLS params:", results.params[1], results.params[2])
```

## Generalized Least Squares (GLS)

### regress.GLS(y, X, sigma?, opts?)

Constructs a GLS model for data with heteroskedastic or correlated errors.

**Parameters:**
- `y` - Response array
- `X` - Design matrix
- `sigma` (optional) - Error covariance specification:
  - `nil` — falls back to OLS
  - 1-D table — diagonal variances; internally converted to weights `1/sigma_i`
  - 2-D matrices are **not** supported in the current implementation
- `opts` (optional) - Same options as `OLS`

**Returns:** Model object with `:fit(opts?)`. Result fields are identical to OLS.

```lua
local regress = math.regress

local y     = {5, 9, 14, 20}
local X     = regress.add_constant({{1}, {2}, {3}, {4}})
local sigma = {0.5, 1.0, 0.5, 2.0}   -- diagonal variances

local results = regress.GLS(y, X, sigma):fit()
print("GLS params:", results.params[1], results.params[2])
```

## Generalized Linear Models (GLM)

### regress.GLM(y, X, opts?)

Constructs a GLM. The family and link function are passed in the `opts` table.

**Parameters:**
- `y` - Response array
- `X` - Design matrix
- `opts` (optional) - Table with:
  - `family` (string) - Distribution family (default: `"gaussian"`)
  - `link` (string) - Link function (default: canonical link for the chosen family)
  - `yname` (string) - Name for the dependent variable
  - `xnames` (table) - Predictor names

**Returns:** GLM model object with `:fit(opts?)`.

### Families and links

| `family` | Canonical link | Other supported links | Typical use |
|----------|---------------|----------------------|-------------|
| `"gaussian"` | `"identity"` | | Continuous response |
| `"binomial"` | `"logit"` | `"probit"` | Binary / proportions |
| `"poisson"` | `"log"` | `"identity"` | Count data |
| `"gamma"` | `"inverse"` | `"log"`, `"identity"` | Positive continuous |

Link names accepted: `"identity"`, `"logit"`, `"log"`, `"inverse"`, `"probit"`.

```lua
local regress = math.regress

-- Logistic regression
local y_bin = {0, 0, 1, 1, 0, 1, 1, 1}
local X     = regress.add_constant({{1},{2},{3},{4},{5},{6},{7},{8}})

local model   = regress.GLM(y_bin, X, {family = "binomial"})
local results = model:fit()
print(results:summary())

-- Poisson regression
local y_cnt = {1, 2, 3, 5, 8}
local X2    = regress.add_constant({{1},{2},{3},{4},{5}})
local pois  = regress.GLM(y_cnt, X2, {family = "poisson", link = "log"}):fit()
print("AIC:", pois.aic)
```

### GLM fit options

`:fit()` accepts an optional table:

| Key | Default | Description |
|-----|---------|-------------|
| `maxiter` | `100` | Maximum IRLS iterations |
| `tol` | `1e-8` | Convergence tolerance |

### GLM Result Fields

| Field | Description |
|-------|-------------|
| `params` | Fitted coefficients (on link scale) |
| `bse` | Standard errors |
| `tvalues` | z-statistics (Wald test) |
| `pvalues` | Two-sided p-values |
| `resid` | Response residuals |
| `fittedvalues` | Fitted values on the response scale (equal to `mu`) |
| `mu` | Fitted means on the response scale |
| `eta` | Linear predictor values |
| `deviance` | Residual deviance |
| `null_deviance` | Null (intercept-only) deviance |
| `pearson_chi2` | Pearson chi-squared statistic |
| `llf` | Log-likelihood |
| `aic` | AIC |
| `bic` | BIC |
| `nobs` | Number of observations |
| `df_model` | Model degrees of freedom |
| `df_resid` | Residual degrees of freedom |
| `converged` | Boolean: did IRLS converge? |
| `iterations` | Number of IRLS iterations used |

### GLM Result Methods

#### :summary(opts?)

Returns a formatted text summary including deviance statistics and a z-value parameter table.

#### :predict(new_X?)

Returns in-sample fitted values (`mu`) when called without arguments, or applies the inverse link function to produce predictions for a new design matrix.

```lua
local fitted = results:predict()

local X_new = {{1, 3.5}, {1, 7.0}}
local probs = results:predict(X_new)   -- probabilities for binomial family
```

#### :conf_int(alpha?)

Returns normal-approximation confidence intervals (large-sample). Default `alpha = 0.05`.

```lua
local ci = results:conf_int(0.05)
-- ci[i] = {lower, upper} for coefficient i
```

## ARIMA (Time Series)

### regress.ARIMA(y, order, opts?)

Constructs an ARIMA(p, d, q) model.

**Parameters:**
- `y` - Time series as a 1-D table of numbers (must have more than 2 observations)
- `order` - `{p, d, q}` table where `p` = AR order, `d` = differencing order, `q` = MA order
- `opts` (optional) - Table with:
  - `yname` (string) - Name for the variable

**Returns:** ARIMA model object with `:fit(opts?)`. Returns `nil` if the series is too short or inputs are invalid.

```lua
local regress = math.regress

local sales = {120, 135, 158, 148, 160, 175, 185, 198, 210, 225, 240, 255}

-- ARIMA(1, 1, 1): AR order 1, one difference, MA order 1
local model   = regress.ARIMA(sales, {1, 1, 1})
local results = model:fit()

if results then
    print(results:summary())
    print("AIC:", results.aic)
end
```

### ARIMA fit options

`:fit()` accepts an optional table:

| Key | Default | Description |
|-----|---------|-------------|
| `maxiter` | `100` | Maximum optimisation iterations |
| `tol` | `1e-8` | Convergence tolerance |

### ARIMA Result Fields

| Field | Description |
|-------|-------------|
| `arparams` | Array of AR coefficients (length = p) |
| `maparams` | Array of MA coefficients (length = q) |
| `ar_bse` | Standard errors for AR coefficients |
| `ma_bse` | Standard errors for MA coefficients |
| `params` | Combined array: AR params followed by MA params |
| `bse` | Combined standard errors (AR then MA) |
| `resid` | Model residuals |
| `fittedvalues` | In-sample fitted values |
| `sigma2` | Estimated noise variance |
| `llf` | Log-likelihood |
| `aic` | AIC |
| `bic` | BIC |
| `nobs` | Number of (effective) observations |
| `converged` | Boolean: did the optimiser converge? |
| `iterations` | Number of optimiser iterations used |
| `order` | The `{p, d, q}` order table (public copy) |

### ARIMA Result Methods

#### :summary(opts?)

Returns a formatted text summary showing AR and MA coefficients with standard errors.

#### :forecast(steps?)

Generates out-of-sample point forecasts. Integration (un-differencing) is applied automatically when `d > 0`.

```lua
local forecasts = results:forecast(6)   -- 6 steps ahead
for i, v in ipairs(forecasts) do
    print(string.format("t+%d: %.2f", i, v))
end
```

#### :predict(start_idx?, end_idx?)

Returns in-sample fitted values. Index arguments are accepted for API compatibility but the current implementation always returns the full `fittedvalues` array.

## Helpers

### regress.add_constant(X)

Prepends a column of ones to a design matrix for use as an intercept term.

- 1-D input `{x1, x2, ...}` → `{{1, x1}, {1, x2}, ...}`
- 2-D input `{{x1, x2}, ...}` → `{{1, x1, x2}, ...}`

```lua
local X = math.regress.add_constant({{1.2}, {3.4}, {5.6}})
-- X = {{1, 1.2}, {1, 3.4}, {1, 5.6}}
```

## Complete Example

```lua
luaswift.extend_stdlib()
local regress = math.regress

-- House price data: intercept, size (sq ft), age (years)
local X_raw = {
    {1200, 5}, {1500, 10}, {1800, 8}, {2100, 3}, {2400, 15}
}
local price = {200, 240, 260, 300, 250}   -- $1000s

local X       = regress.add_constant(X_raw)
local model   = regress.OLS(price, X, {
    yname  = "price",
    xnames = {"const", "size", "age"}
})
local results = model:fit()

print(results:summary())

-- Confidence intervals for each coefficient
local ci = results:conf_int(0.05)
for i, interval in ipairs(ci) do
    print(string.format("param[%d]: [%.3f, %.3f]", i, interval[1], interval[2]))
end

-- Predict for a new house: 2000 sq ft, 7 years old
local X_new = {{1, 2000, 7}}
local pred  = results:predict(X_new)
print(string.format("Predicted price: $%.0fk", pred[1]))

-- Influence diagnostics
local infl = results:get_influence()
for i, h in ipairs(infl.hat_diag) do
    print(string.format("obs %d: leverage=%.3f, Cook's D=%.4f", i, h, infl.cooks_distance[i]))
end
```

## Logistic Regression Example

```lua
luaswift.extend_stdlib()
local regress = math.regress

local hours = {1, 2, 3, 4, 5, 6, 7, 8}
local pass  = {0, 0, 0, 1, 0, 1, 1, 1}

local X = regress.add_constant(hours)   -- add_constant handles 1-D input
local results = regress.GLM(pass, X, {
    family = "binomial",
    xnames = {"const", "hours"}
}):fit()

print(results:summary())

-- Probability of passing with 4.5 study hours
local X_new = {{1, 4.5}}
local prob  = results:predict(X_new)
print(string.format("P(pass | 4.5 h) = %.3f", prob[1]))
```

## Time Series Forecasting Example

```lua
luaswift.extend_stdlib()
local regress = math.regress

local sales = {120, 135, 158, 148, 160, 175, 185, 198, 210, 225, 240, 255}

local results = regress.ARIMA(sales, {1, 1, 1}):fit()

if results then
    print(results:summary())
    print(string.format("sigma²: %.4f", results.sigma2))

    -- AR and MA coefficients
    print("AR params:", results.arparams[1])
    if #results.maparams > 0 then
        print("MA params:", results.maparams[1])
    end

    -- Forecast next 3 periods
    local fc = results:forecast(3)
    for i, v in ipairs(fc) do
        print(string.format("t+%d forecast: %.1f", i, v))
    end
else
    print("ARIMA fit returned nil (series too short or invalid order)")
end
```

## See Also

- ``RegressModule``
- <doc:DistributionsModule>
- <doc:LinAlgModule>
