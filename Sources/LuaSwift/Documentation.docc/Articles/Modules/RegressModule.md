# Regression Module

Statistical regression models including OLS, WLS, GLS, GLM, and time series (ARIMA).

## Overview

The Regression module provides comprehensive regression analysis tools inspired by statsmodels. Available under `math.regress` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local regress = math.regress
```

## Ordinary Least Squares (OLS)

### regress.ols(y, X)
Fit linear regression using ordinary least squares.

```lua
local array = require("luaswift.array")

-- Data: y = 2*x1 + 3*x2 + 1 + noise
local X = array.array({
    {1, 1, 2},  -- [intercept, x1, x2]
    {1, 2, 3},
    {1, 3, 4},
    {1, 4, 5}
})
local y = array.array({8, 14, 20, 26})

local model = regress.ols(y, X)

print("Coefficients:", model.params)  -- [intercept, β1, β2]
print("R-squared:", model.rsquared)
print("Std errors:", model.bse)
```

### Model Properties

```lua
print("Fitted values:", model.fittedvalues)
print("Residuals:", model.resid)
print("R-squared:", model.rsquared)
print("Adjusted R-squared:", model.rsquared_adj)
print("AIC:", model.aic)
print("BIC:", model.bic)
```

### Prediction

```lua
local X_new = array.array({{1, 5, 6}})
local predictions = model:predict(X_new)
```

## Weighted Least Squares (WLS)

### regress.wls(y, X, weights)
Fit regression with weighted observations.

```lua
local weights = array.array({1, 2, 1, 3})  -- Higher weight = more important

local model = regress.wls(y, X, weights)
print("Coefficients:", model.params)
```

## Generalized Least Squares (GLS)

### regress.gls(y, X, sigma?)
Fit regression with correlated errors.

```lua
-- Sigma: covariance matrix of errors
local model = regress.gls(y, X, sigma)
```

## Generalized Linear Models (GLM)

### regress.glm(y, X, family, link?)
Fit GLM with various distributions and link functions.

```lua
-- Logistic regression
local y_binary = array.array({0, 0, 1, 1})
local model = regress.glm(y_binary, X, "binomial", "logit")

-- Poisson regression
local y_count = array.array({1, 3, 5, 8})
local model = regress.glm(y_count, X, "poisson", "log")
```

### Families and Links

| Family | Common Links | Use Case |
|--------|--------------|----------|
| `"gaussian"` | `"identity"` | Continuous data |
| `"binomial"` | `"logit"`, `"probit"` | Binary outcomes |
| `"poisson"` | `"log"` | Count data |
| `"gamma"` | `"log"`, `"inverse"` | Positive continuous |

## Time Series: ARIMA

### regress.arima(y, order, options?)
Autoregressive Integrated Moving Average models.

```lua
-- ARIMA(p, d, q) where p=AR order, d=differences, q=MA order
local timeseries = array.array({/* time series data */})

-- ARIMA(1, 1, 1)
local model = regress.arima(timeseries, {1, 1, 1})

print("AR coefficients:", model.ar_params)
print("MA coefficients:", model.ma_params)
print("AIC:", model.aic)

-- Forecast
local forecast = model:forecast(10)  -- 10 steps ahead
```

## Diagnostic Tests

### Heteroskedasticity Tests

```lua
-- Breusch-Pagan test
local bp_stat, bp_pvalue = model:het_breuschpagan()

-- White's test
local white_stat, white_pvalue = model:het_white()
```

### Autocorrelation Tests

```lua
-- Durbin-Watson statistic
local dw = model:durbin_watson()

-- Ljung-Box test
local lb_stat, lb_pvalue = model:ljung_box(10)  -- 10 lags
```

### Normality Tests

```lua
-- Jarque-Bera test
local jb_stat, jb_pvalue = model:jarque_bera()
```

## Complete Example

```lua
local array = require("luaswift.array")
local regress = math.regress

-- Generate data: house prices based on size and age
local size = array.array({1200, 1500, 1800, 2100, 2400})
local age = array.array({5, 10, 8, 3, 15})
local price = array.array({200, 240, 260, 300, 250})  -- $1000s

-- Add intercept column
local n = size:shape()[1]
local intercept = array.ones({n})
local X = array.hstack({intercept:expand_dims(2),
                        size:expand_dims(2),
                        age:expand_dims(2)})

-- Fit model
local model = regress.ols(price, X)

print("Model Summary:")
print("Intercept:", model.params:get(1))
print("Size coefficient:", model.params:get(2), "±", model.bse:get(2))
print("Age coefficient:", model.params:get(3), "±", model.bse:get(3))
print("R²:", model.rsquared)

-- Predict for new house: 2000 sq ft, 7 years old
local X_new = array.array({{1, 2000, 7}})
local pred_price = model:predict(X_new)
print("Predicted price: $" .. (pred_price:get(1) * 1000))

-- Diagnostics
print("Durbin-Watson:", model:durbin_watson())
local jb_stat, jb_pval = model:jarque_bera()
print("Jarque-Bera p-value:", jb_pval)
```

## Logistic Regression Example

```lua
-- Binary outcome: pass/fail based on study hours
local hours = array.array({1, 2, 3, 4, 5, 6, 7, 8})
local pass = array.array({0, 0, 0, 1, 0, 1, 1, 1})

local intercept = array.ones({8})
local X = array.hstack({intercept:expand_dims(2), hours:expand_dims(2)})

local model = regress.glm(pass, X, "binomial", "logit")

print("Coefficients:", model.params)

-- Predict probability for 4.5 hours
local X_new = array.array({{1, 4.5}})
local prob = model:predict(X_new)
print("Probability of passing with 4.5 hours:", prob:get(1))
```

## Time Series Forecasting

```lua
local array = require("luaswift.array")
local regress = math.regress

-- Monthly sales data
local sales = array.array({
    120, 135, 158, 148, 160, 175, 185, 198, 210, 225, 240, 255
})

-- Fit ARIMA(1,1,1) - seasonal differencing, AR and MA terms
local model = regress.arima(sales, {1, 1, 1})

print("Model AIC:", model.aic)

-- Forecast next 3 months
local forecast = model:forecast(3)
print("Forecast:", forecast)

-- Get forecast intervals
local lower, upper = model:forecast_interval(3, 0.95)
print("95% CI:", lower, upper)
```

## See Also

- ``RegressModule``
- <doc:Modules/DistributionsModule>
- <doc:LinAlgModule>
