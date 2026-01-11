# Regression Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.regress` | **Global:** `math.regress` (after extend_stdlib)

Statistical regression modeling for LuaSwift, providing statsmodels-compatible API for ordinary least squares (OLS), weighted least squares (WLS), generalized least squares (GLS), generalized linear models (GLM), and autoregressive integrated moving average (ARIMA) models. All computations use hardware-accelerated LAPACK routines via the Accelerate framework.

## Function Reference

| Function | Description |
|----------|-------------|
| [add_constant(X)](#add_constant) | Add intercept column to design matrix |
| [OLS(endog, exog, opts?)](#ols) | Ordinary least squares regression |
| [WLS(endog, exog, weights, opts?)](#wls) | Weighted least squares regression |
| [GLS(endog, exog, sigma, opts?)](#gls) | Generalized least squares with error covariance |
| [GLM(endog, exog, opts)](#glm) | Generalized linear model (binomial, poisson, gamma, gaussian) |
| [ARIMA(endog, order, opts?)](#arima) | Autoregressive integrated moving average model |

## Results Object Methods

All regression models return a results object with these methods:

| Method | Description |
|--------|-------------|
| [summary(opts?)](#summary) | Print formatted regression summary |
| [predict(new_X?)](#predict) | Generate predictions (in-sample or out-of-sample) |
| [conf_int(alpha?)](#conf_int) | Confidence intervals for parameters |
| [get_bse(cov_type?)](#get_bse) | Standard errors (classical or robust) |
| [get_influence()](#get_influence) | Influence diagnostics (leverage, Cook's D, DFFITS) |
| [forecast(steps)](#forecast) | Multi-step forecasts (ARIMA only) |

---

## add_constant

```
math.regress.add_constant(X) -> table
```

Prepend column of ones to design matrix for intercept term.

**Parameters:**
- `X` (table) - 1D or 2D array

**Returns:** 2D array with constant column prepended

```lua
-- 1D array → 2D with constant
local x = {1, 2, 3, 4, 5}
local X = math.regress.add_constant(x)
-- X = {{1,1}, {1,2}, {1,3}, {1,4}, {1,5}}

-- 2D array → prepend constant column
local X = {{10, 20}, {30, 40}, {50, 60}}
local X_const = math.regress.add_constant(X)
-- X_const = {{1,10,20}, {1,30,40}, {1,50,60}}
```

---

## OLS

```
math.regress.OLS(endog, exog, opts?) -> model
```

Create ordinary least squares regression model minimizing squared residuals.

**Parameters:**
- `endog` (table) - Dependent variable (y values), 1D array
- `exog` (table) - Independent variables (X matrix), 2D array or 1D array for single predictor
- `opts` (table, optional) - Options:
  - `yname` (string): Name of dependent variable for display (default: "y")
  - `xnames` (table): Array of regressor names for display
  - `hasconst` (boolean): Whether X already includes constant column

**Returns:** Model object with `fit()` method

```lua
luaswift.extend_stdlib()

-- Simple linear regression
local y = {5, 8, 11, 14, 17}
local X = math.regress.add_constant({1, 2, 3, 4, 5})

local model = math.regress.OLS(y, X)
local results = model:fit()

print(results:summary())
print("Intercept:", results.params[1])  -- 2.0
print("Slope:", results.params[2])      -- 3.0
print("R²:", results.rsquared)          -- 1.0 (perfect fit)
```

### Multiple Regression Example

```lua
-- Predict house prices from size and bedrooms
local prices = {150, 200, 250, 300, 350}  -- thousands
local size = {1000, 1500, 2000, 2500, 3000}  -- sq ft
local bedrooms = {2, 3, 3, 4, 4}

-- Create design matrix with constant
local X = {}
for i = 1, #size do
  X[i] = {1, size[i], bedrooms[i]}  -- constant, size, bedrooms
end

local model = math.regress.OLS(prices, X, {
  yname = "price",
  xnames = {"const", "sqft", "beds"}
})

local results = model:fit()

print("Price = " .. results.params[1] .. " + " ..
      results.params[2] .. " * sqft + " ..
      results.params[3] .. " * beds")

-- Predict price for 2200 sq ft, 3 bedrooms
local new_X = {{1, 2200, 3}}
local predicted = results:predict(new_X)
print("Predicted price:", predicted[1])
```

---

## WLS

```
math.regress.WLS(endog, exog, weights, opts?) -> model
```

Create weighted least squares regression model for heteroskedastic errors.

**Parameters:**
- `endog` (table) - Dependent variable (y values), 1D array
- `exog` (table) - Independent variables (X matrix), 2D array or 1D array for single predictor
- `weights` (table) - 1D array of positive weights, same length as endog. Higher weights = more influence
- `opts` (table, optional) - Options:
  - `yname` (string): Name of dependent variable for display (default: "y")
  - `xnames` (table): Array of regressor names for display
  - `hasconst` (boolean): Whether X already includes constant column

**Returns:** Model object with `fit()` method

```lua
-- Data with heteroskedastic errors (variance increases with x)
local y = {2.1, 4.0, 5.9, 8.1, 10.0}
local x = {1, 2, 3, 4, 5}
local X = math.regress.add_constant(x)

-- Weight by 1/x (higher variance at higher x)
local weights = {}
for i = 1, #x do
  weights[i] = 1.0 / x[i]
end

local model = math.regress.WLS(y, X, weights)
local results = model:fit()

print(results:summary())
```

---

## GLS

```
math.regress.GLS(endog, exog, sigma, opts?) -> model
```

Create generalized least squares regression model with arbitrary error covariance structure.

**Parameters:**
- `endog` (table) - Dependent variable (y values), 1D array
- `exog` (table) - Independent variables (X matrix), 2D array or 1D array for single predictor
- `sigma` (table) - Error covariance matrix:
  - `nil` or scalar: Equivalent to OLS
  - 1D array: Diagonal variances (equivalent to WLS)
  - 2D array: Full n×n covariance matrix for correlated errors
- `opts` (table, optional) - Options:
  - `yname` (string): Name of dependent variable for display (default: "y")
  - `xnames` (table): Array of regressor names for display
  - `hasconst` (boolean): Whether X already includes constant column

**Returns:** Model object with `fit()` method

```lua
local y = {1.2, 2.1, 2.9, 4.2, 5.0}
local X = math.regress.add_constant({1, 2, 3, 4, 5})

-- Diagonal covariance (WLS-like)
local sigma = {0.5, 1.0, 1.0, 1.5, 2.0}

local model = math.regress.GLS(y, X, sigma)
local results = model:fit()

print("Intercept:", results.params[1])
print("Slope:", results.params[2])
```

---

## GLM

```
math.regress.GLM(endog, exog, opts) -> model
```

Create generalized linear model with non-normal response distributions and link functions.

**Parameters:**
- `endog` (table) - Dependent variable (y values), 1D array
- `exog` (table) - Independent variables (X matrix), 2D array or 1D array for single predictor
- `opts` (table) - Options:
  - `family` (string): Error distribution:
    - `"gaussian"` (default): Normal errors, identity link
    - `"binomial"`: Binary outcomes, logit link (logistic regression)
    - `"poisson"`: Count data, log link
    - `"gamma"`: Positive continuous, log link
  - `link` (string, optional): Link function (uses canonical if not specified):
    - `"identity"`, `"logit"`, `"log"`, `"inverse"`
  - `yname` (string): Name of dependent variable for display
  - `xnames` (table): Array of regressor names for display

**Returns:** Model object with `fit(opts)` method
- `opts.maxiter` (number): Maximum IRLS iterations (default: 100)
- `opts.tol` (number): Convergence tolerance (default: 1e-8)

### Logistic Regression Example

```lua
-- Binary classification: pass/fail based on hours studied
local passed = {0, 0, 0, 1, 1, 1}  -- 0 = fail, 1 = pass
local hours = {1, 2, 3, 4, 5, 6}
local X = math.regress.add_constant(hours)

local model = math.regress.GLM(passed, X, {
  family = "binomial",
  yname = "passed"
})

local results = model:fit()

print(results:summary())
print("Converged:", results.converged)
print("Iterations:", results.iterations)

-- Predict probability of passing with 3.5 hours
local new_X = {{1, 3.5}}
local prob = results:predict(new_X)
print("P(pass | 3.5 hours) =", prob[1])
```

### Poisson Regression Example

```lua
-- Number of complaints vs staff size
local complaints = {3, 5, 8, 12, 18}
local staff = {2, 3, 5, 8, 12}
local X = math.regress.add_constant(staff)

local model = math.regress.GLM(complaints, X, {
  family = "poisson"
})

local results = model:fit()
print(results:summary())
```

---

## ARIMA

```
math.regress.ARIMA(endog, order, opts?) -> model
```

Create AutoRegressive Integrated Moving Average model for time series.

**Parameters:**
- `endog` (table) - Time series values (1D array)
- `order` (table) - `{p, d, q}` where:
  - `p`: AR (autoregressive) order
  - `d`: Integration order (differencing)
  - `q`: MA (moving average) order
- `opts` (table, optional):
  - `yname` (string): Series name for display

**Returns:** Model object with `fit(opts)` method
- `opts.maxiter` (number): Maximum iterations (default: 100)
- `opts.tol` (number): Convergence tolerance (default: 1e-8)

### ARIMA(1,1,1) Example

```lua
-- Time series with trend
local data = {10, 12, 15, 14, 18, 20, 22, 24, 27, 30}

-- ARIMA(1,1,1): AR(1), first-order differencing, MA(1)
local model = math.regress.ARIMA(data, {1, 1, 1})
local results = model:fit()

print(results:summary())
print("AR coefficient:", results.arparams[1])
print("MA coefficient:", results.maparams[1])

-- Forecast next 3 periods
local forecast = results:forecast(3)
print("Next 3 values:", table.unpack(forecast))
```

### AR(2) Example

```lua
-- Stationary series
local data = {5, 6, 4, 7, 5, 8, 6, 9, 7, 10}

local model = math.regress.ARIMA(data, {2, 0, 0})  -- AR(2)
local results = model:fit()

print("AR(1):", results.arparams[1])
print("AR(2):", results.arparams[2])
```

---

## Results Object Attributes

All regression models return a results object with common attributes.

### Per-Parameter Metrics

- `params` (table): Coefficient estimates
- `bse` (table): Standard errors
- `tvalues` (table): t-statistics (z-statistics for GLM)
- `pvalues` (table): p-values for hypothesis tests

### Robust Standard Errors (OLS/WLS/GLS only)

- `bse_hc0`, `bse_hc1`, `bse_hc2`, `bse_hc3`: Heteroskedasticity-consistent SEs

### Per-Observation Metrics

- `resid` (table): Residuals (y - fitted)
- `fittedvalues` (table): Predicted values
- `hat_diag` (table): Hat matrix diagonal (leverage)
- `resid_studentized` (table): Studentized residuals
- `cooks_distance` (table): Cook's distance (influence)
- `dffits` (table): DFFITS statistic

### Model-Level Metrics

- `nobs` (number): Number of observations
- `df_model` (number): Model degrees of freedom
- `df_resid` (number): Residual degrees of freedom
- `rsquared` (number): R² coefficient of determination
- `rsquared_adj` (number): Adjusted R²
- `fvalue` (number): F-statistic
- `f_pvalue` (number): F-test p-value
- `llf` (number): Log-likelihood
- `aic` (number): Akaike Information Criterion
- `bic` (number): Bayesian Information Criterion
- `ssr` (number): Sum of squared residuals
- `ess` (number): Explained sum of squares
- `mse_resid` (number): Mean squared error of residuals
- `centered_tss` (number): Total sum of squares (centered)
- `condition_number` (number): Condition number (multicollinearity indicator)
- `eigenvalues` (table): X'X eigenvalues

### GLM-Specific Attributes

- `deviance` (number): Model deviance
- `null_deviance` (number): Null model deviance
- `pearson_chi2` (number): Pearson chi-squared statistic
- `converged` (boolean): Whether IRLS converged
- `iterations` (number): Number of iterations
- `mu` (table): Fitted mean values
- `eta` (table): Linear predictor values

### ARIMA-Specific Attributes

- `arparams` (table): AR coefficients
- `maparams` (table): MA coefficients
- `ar_bse` (table): AR standard errors
- `ma_bse` (table): MA standard errors
- `sigma2` (number): Residual variance
- `order` (table): Model order {p, d, q}

---

## summary

```
results:summary(opts?) -> string
```

Generate formatted regression summary string.

**Parameters:**
- `opts` (table, optional):
  - `alpha` (number): Significance level for confidence intervals (default: 0.05)

**Returns:** Formatted string with model specification, goodness-of-fit statistics, coefficient table with SEs, t-stats, p-values, CIs, and diagnostics

```lua
local summary_str = results:summary()
print(summary_str)

-- Customize significance level (99% CI)
local summary = results:summary({alpha = 0.01})
```

**Output includes:**
- Model specification and sample size
- Goodness-of-fit statistics (R², F-test, AIC, BIC)
- Coefficient table with SEs, t-stats, p-values, and CIs
- Diagnostics (condition number, leverage, Cook's D warnings)

---

## predict

```
results:predict(new_X?) -> table
```

Generate predictions from fitted model.

**Parameters:**
- `new_X` (table, optional) - New design matrix. If nil, returns fitted values.

**Returns:** Array of predictions

```lua
-- In-sample predictions (fitted values)
local fitted = results:predict()

-- Out-of-sample predictions
local new_data = {{1, 100}, {1, 200}}
local predictions = results:predict(new_data)
```

---

## conf_int

```
results:conf_int(alpha?) -> table
```

Compute confidence intervals for parameters.

**Parameters:**
- `alpha` (number, optional) - Significance level (default: 0.05)

**Returns:** Array of `{lower, upper}` pairs

```lua
local ci = results:conf_int(0.05)  -- 95% CI
for i, interval in ipairs(ci) do
  print(string.format("β%d: [%.4f, %.4f]", i-1, interval[1], interval[2]))
end

-- 99% CI
local ci_99 = results:conf_int(0.01)
```

---

## get_bse

```
results:get_bse(cov_type?) -> table
```

Get standard errors with optional robust covariance.

**Available for:** OLS, WLS, GLS only

**Parameters:**
- `cov_type` (string, optional) - Covariance type:
  - `"nonrobust"`: Classical standard errors
  - `"HC0"`: White's heteroskedasticity-robust
  - `"HC1"`: HC0 with small-sample correction
  - `"HC2"`: HC1 with leverage adjustment
  - `"HC3"`: Most conservative, recommended

**Returns:** Array of standard errors

```lua
-- Classical standard errors
local se_classical = results:get_bse("nonrobust")

-- Heteroskedasticity-robust (White's)
local se_hc0 = results:get_bse("HC0")
local se_hc1 = results:get_bse("HC1")
local se_hc2 = results:get_bse("HC2")
local se_hc3 = results:get_bse("HC3")  -- Most conservative
```

---

## get_influence

```
results:get_influence() -> table
```

Compute influence diagnostics for regression observations.

**Returns:** Table with:
- `hat_diag` (table): Hat matrix diagonal (leverage)
- `resid_studentized` (table): Studentized residuals
- `cooks_distance` (table): Cook's distance (influence)
- `dffits` (table): DFFITS values

```lua
local influence = results:get_influence()

-- Identify high-leverage points
local n, k = results.nobs, #results.params
for i, h in ipairs(influence.hat_diag) do
  if h > 2 * k / n then
    print("Observation " .. i .. " has high leverage")
  end
end

-- Identify influential observations
for i, d in ipairs(influence.cooks_distance) do
  if d > 1 then
    print("Observation " .. i .. " is highly influential")
  end
end
```

---

## forecast

```
results:forecast(steps) -> table
```

Generate multi-step ahead forecasts.

**Available for:** ARIMA models only

**Parameters:**
- `steps` (number) - Number of periods to forecast

**Returns:** Array of forecasted values

```lua
local model = math.regress.ARIMA(data, {1, 1, 1})
local results = model:fit()

-- Forecast next 5 periods
local forecast = results:forecast(5)
for i, value in ipairs(forecast) do
  print("t+" .. i .. ":", value)
end
```

---

## Examples

### Diagnostics and Assumption Checking

```lua
local results = model:fit()

-- 1. Linearity: plot residuals vs fitted
local resid = results.resid
local fitted = results.fittedvalues

-- 2. Homoskedasticity: residuals should have constant variance
-- Use robust standard errors if violated
local robust_se = results:get_bse("HC3")

-- 3. Normality: check large residuals
for i, r in ipairs(results.resid_studentized) do
  if math.abs(r) > 3 then
    print("Outlier at observation " .. i)
  end
end

-- 4. Independence: check for autocorrelation (ARIMA)

-- 5. Multicollinearity
if results.condition_number > 1000 then
  print("WARNING: High multicollinearity detected")
end
```

### Influence Analysis

```lua
local influence = results:get_influence()

-- High leverage (unusual X values)
local n, k = results.nobs, #results.params
local leverage_threshold = 2 * k / n

for i, h in ipairs(influence.hat_diag) do
  if h > leverage_threshold then
    print("High leverage point:", i)
  end
end

-- High influence (affects coefficients)
for i, d in ipairs(influence.cooks_distance) do
  if d > 4 / n then  -- common threshold
    print("Influential point:", i)
  end
end
```

### Model Comparison

```lua
-- Compare models using AIC/BIC (lower is better)
local model1 = math.regress.OLS(y, X1):fit()
local model2 = math.regress.OLS(y, X2):fit()

print("Model 1 AIC:", model1.aic)
print("Model 2 AIC:", model2.aic)

if model2.aic < model1.aic then
  print("Model 2 is preferred")
end

-- F-test for nested models (manual)
local ssr_reduced = model1.ssr
local ssr_full = model2.ssr
local df_diff = model1.df_resid - model2.df_resid
local f_stat = ((ssr_reduced - ssr_full) / df_diff) / model2.mse_resid
```

### Polynomial Regression

```lua
-- Fit quadratic: y = β₀ + β₁x + β₂x²
local x = {1, 2, 3, 4, 5, 6}
local y = {1.2, 3.8, 8.9, 16.1, 25.0, 36.2}

local X = {}
for i = 1, #x do
  X[i] = {1, x[i], x[i]^2}  -- constant, x, x²
end

local model = math.regress.OLS(y, X, {
  xnames = {"const", "x", "x²"}
})
local results = model:fit()

print(results:summary())
```

### Dummy Variables

```lua
-- Categorical predictor: region (North=0, South=1)
local sales = {100, 120, 110, 150, 160, 155}
local advertising = {10, 15, 12, 20, 25, 22}
local south = {0, 0, 0, 1, 1, 1}  -- dummy

local X = {}
for i = 1, #sales do
  X[i] = {1, advertising[i], south[i]}
end

local model = math.regress.OLS(sales, X, {
  xnames = {"const", "advertising", "south"}
})
local results = model:fit()

-- south coefficient = difference in intercept
print("South region effect:", results.params[3])
```

### Interaction Terms

```lua
-- y = β₀ + β₁x₁ + β₂x₂ + β₃(x₁×x₂)
local y = {5, 10, 8, 15, 20, 18}
local x1 = {1, 2, 1.5, 3, 4, 3.5}
local x2 = {2, 3, 2.5, 4, 5, 4.5}

local X = {}
for i = 1, #y do
  X[i] = {1, x1[i], x2[i], x1[i] * x2[i]}  -- interaction
end

local model = math.regress.OLS(y, X, {
  xnames = {"const", "x1", "x2", "x1:x2"}
})
local results = model:fit()

print("Interaction effect:", results.params[4])
```
