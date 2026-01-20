//
//  RegressModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//
//  REFACTORED: Now uses NumericSwift for all numerical computations.
//  This module provides thin Lua bindings to NumericSwift regression functions.
//

#if LUASWIFT_NUMERICSWIFT
import Foundation
import NumericSwift

/// Swift-backed regression modeling module for LuaSwift.
///
/// Provides statsmodels-compatible regression analysis including OLS, WLS, GLS,
/// GLM, and ARIMA models. Delegates to NumericSwift for all numerical computation.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- Ordinary Least Squares
/// local model = math.regress.OLS(y, X)
/// local results = model:fit()
/// print(results:summary())
/// print(results.params, results.rsquared, results.pvalues)
///
/// -- Weighted Least Squares
/// local wls = math.regress.WLS(y, X, weights)
/// local results = wls:fit()
///
/// -- Generalized Linear Models
/// local glm = math.regress.GLM(y, X, {family = 'binomial'})
/// local results = glm:fit()
///
/// -- Make predictions
/// local predictions = results:predict(new_X)
///
/// -- Confidence intervals
/// local ci = results:conf_int(0.05)
/// ```
public struct RegressModule {

    // MARK: - Registration

    /// Register the regression module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks for core computations
        registerOLSCallbacks(in: engine)
        registerGLMCallbacks(in: engine)
        registerARIMACallbacks(in: engine)

        // Set up the luaswift.regress namespace with Lua wrapper code
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.regress then luaswift.regress = {} end

                local regress = luaswift.regress

                -- Store references to Swift callbacks
                local _ols_fit = _luaswift_regress_ols_fit
                local _glm_fit = _luaswift_regress_glm_fit
                local _arima_fit = _luaswift_regress_arima_fit

                ----------------------------------------------------------------
                -- Results object metatable
                -- Holds fitted model results with statistics and methods
                ----------------------------------------------------------------
                local Results_mt = {}
                Results_mt.__index = Results_mt

                function Results_mt:summary(opts)
                    opts = opts or {}
                    local alpha = opts.alpha or 0.05

                    local lines = {}
                    table.insert(lines, string.rep("=", 78))
                    table.insert(lines, string.format("%-40s %s", "Dep. Variable:", self._yname or "y"))
                    table.insert(lines, string.format("%-40s %s", "Model:", self._model_type or "OLS"))
                    table.insert(lines, string.format("%-40s %d", "No. Observations:", self.nobs))
                    table.insert(lines, string.format("%-40s %d", "Df Residuals:", self.df_resid))
                    table.insert(lines, string.format("%-40s %d", "Df Model:", self.df_model))
                    table.insert(lines, string.rep("-", 78))
                    table.insert(lines, string.format("%-40s %.6f", "R-squared:", self.rsquared))
                    table.insert(lines, string.format("%-40s %.6f", "Adj. R-squared:", self.rsquared_adj))
                    table.insert(lines, string.format("%-40s %.4f", "F-statistic:", self.fvalue or 0))
                    table.insert(lines, string.format("%-40s %.4g", "Prob (F-statistic):", self.f_pvalue or 1))
                    table.insert(lines, string.format("%-40s %.4f", "Log-Likelihood:", self.llf or 0))
                    table.insert(lines, string.format("%-40s %.4f", "AIC:", self.aic or 0))
                    table.insert(lines, string.format("%-40s %.4f", "BIC:", self.bic or 0))
                    table.insert(lines, string.rep("=", 78))

                    -- Parameter table header
                    table.insert(lines, string.format("%-12s %12s %12s %12s %12s %12s %12s",
                        "", "coef", "std err", "t", "P>|t|", "[0.025", "0.975]"))
                    table.insert(lines, string.rep("-", 78))

                    -- Parameter rows
                    local xnames = self._xnames or {}
                    for i = 1, #self.params do
                        local name = xnames[i] or string.format("x%d", i)
                        local coef = self.params[i]
                        local se = self.bse and self.bse[i] or 0
                        local tval = self.tvalues and self.tvalues[i] or 0
                        local pval = self.pvalues and self.pvalues[i] or 1
                        local ci_low = self._conf_int and self._conf_int[i] and self._conf_int[i][1] or (coef - 1.96 * se)
                        local ci_high = self._conf_int and self._conf_int[i] and self._conf_int[i][2] or (coef + 1.96 * se)

                        table.insert(lines, string.format("%-12s %12.4f %12.4f %12.4f %12.4f %12.4f %12.4f",
                            name:sub(1, 12), coef, se, tval, pval, ci_low, ci_high))
                    end

                    table.insert(lines, string.rep("=", 78))

                    -- Diagnostics section
                    table.insert(lines, string.format("%-38s %-38s",
                        string.format("Cond. No.: %.4g", self.condition_number or 0),
                        string.format("MSE Resid: %.4g", self.mse_resid or 0)))
                    table.insert(lines, string.rep("=", 78))

                    -- Warnings
                    local warnings = {}
                    if self.condition_number and self.condition_number > 1000 then
                        table.insert(warnings, "[1] The condition number is large (" ..
                            string.format("%.0f", self.condition_number) ..
                            "). This might indicate strong multicollinearity.")
                    end

                    -- Check for high leverage points
                    if self.hat_diag then
                        local n = #self.hat_diag
                        local k = #self.params
                        local threshold = 2 * (k + 1) / n
                        local high_leverage = 0
                        for i = 1, n do
                            if self.hat_diag[i] > threshold then
                                high_leverage = high_leverage + 1
                            end
                        end
                        if high_leverage > 0 then
                            table.insert(warnings, "[" .. (#warnings + 1) .. "] " ..
                                high_leverage .. " observations have high leverage (h > 2(k+1)/n).")
                        end
                    end

                    -- Check for influential points
                    if self.cooks_distance then
                        local influential = 0
                        for i = 1, #self.cooks_distance do
                            if self.cooks_distance[i] > 1 then
                                influential = influential + 1
                            end
                        end
                        if influential > 0 then
                            table.insert(warnings, "[" .. (#warnings + 1) .. "] " ..
                                influential .. " observations have Cook's D > 1 (highly influential).")
                        end
                    end

                    if #warnings > 0 then
                        table.insert(lines, "")
                        table.insert(lines, "Warnings:")
                        for _, w in ipairs(warnings) do
                            table.insert(lines, w)
                        end
                    end

                    return table.concat(lines, "\\n")
                end

                -- Get influence diagnostics as a table
                function Results_mt:get_influence()
                    return {
                        hat_diag = self.hat_diag,
                        resid_studentized = self.resid_studentized,
                        cooks_distance = self.cooks_distance,
                        dffits = self.dffits
                    }
                end

                -- Get standard errors with optional robust covariance type
                function Results_mt:get_bse(cov_type)
                    cov_type = cov_type or "nonrobust"
                    if cov_type == "nonrobust" or cov_type == "classical" then
                        return self.bse
                    elseif cov_type == "HC0" then
                        return self.bse_hc0
                    elseif cov_type == "HC1" then
                        return self.bse_hc1
                    elseif cov_type == "HC2" then
                        return self.bse_hc2
                    elseif cov_type == "HC3" then
                        return self.bse_hc3
                    else
                        error("Unknown cov_type: " .. tostring(cov_type) ..
                            ". Use 'nonrobust', 'HC0', 'HC1', 'HC2', or 'HC3'.")
                    end
                end

                function Results_mt:predict(exog)
                    if not exog then
                        return self.fittedvalues
                    end

                    -- Matrix-vector multiplication: predictions = exog * params
                    local predictions = {}
                    local nobs = #exog
                    local k = #self.params

                    for i = 1, nobs do
                        local pred = 0
                        local row = exog[i]
                        for j = 1, k do
                            pred = pred + (row[j] or 0) * self.params[j]
                        end
                        predictions[i] = pred
                    end

                    return predictions
                end

                function Results_mt:conf_int(alpha)
                    alpha = alpha or 0.05
                    -- Use stored conf_int if available, otherwise compute approximate
                    if self._conf_int then
                        return self._conf_int
                    end

                    -- Approximate using normal distribution (z = 1.96 for 95%)
                    local z = 1.96  -- For 95% CI
                    if alpha == 0.01 then z = 2.576
                    elseif alpha == 0.10 then z = 1.645
                    end

                    local ci = {}
                    for i = 1, #self.params do
                        local se = self.bse and self.bse[i] or 0
                        ci[i] = {self.params[i] - z * se, self.params[i] + z * se}
                    end
                    return ci
                end

                ----------------------------------------------------------------
                -- OLS Model metatable
                -- Holds model specification before fitting
                ----------------------------------------------------------------
                local OLS_mt = {}
                OLS_mt.__index = OLS_mt

                function OLS_mt:fit(opts)
                    opts = opts or {}

                    -- Call Swift backend to fit the model
                    local result = _ols_fit(self._endog, self._exog, self._weights)

                    if not result then
                        error("OLS fit failed")
                    end

                    -- Create Results object
                    local results = setmetatable({}, Results_mt)

                    -- Per-parameter metrics
                    results.params = result.params
                    results.bse = result.bse
                    results.tvalues = result.tvalues
                    results.pvalues = result.pvalues
                    results._conf_int = result.conf_int

                    -- Robust standard errors (HC0-HC3)
                    results.bse_hc0 = result.bse_hc0
                    results.bse_hc1 = result.bse_hc1
                    results.bse_hc2 = result.bse_hc2
                    results.bse_hc3 = result.bse_hc3

                    -- Per-observation metrics
                    results.resid = result.resid
                    results.fittedvalues = result.fittedvalues
                    results.hat_diag = result.hat_diag
                    results.resid_studentized = result.resid_studentized
                    results.cooks_distance = result.cooks_distance
                    results.dffits = result.dffits

                    -- Model-level metrics
                    results.rsquared = result.rsquared
                    results.rsquared_adj = result.rsquared_adj
                    results.fvalue = result.fvalue
                    results.f_pvalue = result.f_pvalue
                    results.llf = result.llf
                    results.aic = result.aic
                    results.bic = result.bic
                    results.ssr = result.ssr
                    results.ess = result.ess
                    results.mse_resid = result.mse_resid
                    results.centered_tss = result.centered_tss
                    results.nobs = result.nobs
                    results.df_model = result.df_model
                    results.df_resid = result.df_resid

                    -- Multicollinearity diagnostics
                    results.condition_number = result.condition_number
                    results.eigenvalues = result.eigenvalues

                    -- Store metadata
                    results._model_type = self._model_type or "OLS"
                    results._yname = self._yname
                    results._xnames = self._xnames
                    results._model = self  -- Reference to original model

                    return results
                end

                ----------------------------------------------------------------
                -- OLS constructor
                -- OLS(endog, exog, opts)
                ----------------------------------------------------------------
                function regress.OLS(endog, exog, opts)
                    opts = opts or {}

                    -- Validate inputs
                    if type(endog) ~= "table" then
                        error("endog must be a table (array of values)")
                    end

                    -- Create model object
                    local model = setmetatable({}, OLS_mt)
                    model._endog = endog
                    model._exog = exog
                    model._model_type = "OLS"
                    model._yname = opts.yname or "y"
                    model._xnames = opts.xnames
                    model._hasconst = opts.hasconst

                    return model
                end

                ----------------------------------------------------------------
                -- WLS constructor (Weighted Least Squares)
                -- WLS(endog, exog, weights, opts)
                ----------------------------------------------------------------
                function regress.WLS(endog, exog, weights, opts)
                    opts = opts or {}

                    if type(endog) ~= "table" then
                        error("endog must be a table (array of values)")
                    end

                    local model = setmetatable({}, OLS_mt)
                    model._endog = endog
                    model._exog = exog
                    model._weights = weights
                    model._model_type = "WLS"
                    model._yname = opts.yname or "y"
                    model._xnames = opts.xnames

                    return model
                end

                ----------------------------------------------------------------
                -- GLS constructor (Generalized Least Squares)
                -- GLS delegates to WLS with transformed weights
                ----------------------------------------------------------------
                function regress.GLS(endog, exog, sigma, opts)
                    opts = opts or {}

                    if type(endog) ~= "table" then
                        error("endog must be a table (array of values)")
                    end

                    -- Convert sigma to weights
                    -- For diagonal sigma (1D array), weights = 1/sigma
                    -- For scalar or nil, use equal weights (OLS)
                    local weights = nil
                    if type(sigma) == "table" then
                        if type(sigma[1]) == "number" then
                            -- 1D array - diagonal variances
                            weights = {}
                            for i, v in ipairs(sigma) do
                                weights[i] = 1.0 / math.max(v, 1e-10)
                            end
                        end
                        -- 2D sigma matrix not supported - would need Cholesky decomposition
                    end

                    local model = setmetatable({}, OLS_mt)
                    model._endog = endog
                    model._exog = exog
                    model._weights = weights
                    model._model_type = "GLS"
                    model._yname = opts.yname or "y"
                    model._xnames = opts.xnames

                    return model
                end

                ----------------------------------------------------------------
                -- GLM (Generalized Linear Model)
                -- Supports binomial (logistic), poisson, gamma, gaussian families
                ----------------------------------------------------------------
                local GLM_Results_mt = {}
                GLM_Results_mt.__index = GLM_Results_mt

                function GLM_Results_mt:summary(opts)
                    opts = opts or {}

                    local lines = {}
                    table.insert(lines, string.rep("=", 78))
                    table.insert(lines, string.format("%-40s %s", "Dep. Variable:", self._yname or "y"))
                    table.insert(lines, string.format("%-40s %s", "Model:", "GLM"))
                    table.insert(lines, string.format("%-40s %s", "Family:", self._family or "gaussian"))
                    table.insert(lines, string.format("%-40s %s", "Link:", self._link or "identity"))
                    table.insert(lines, string.format("%-40s %d", "No. Observations:", self.nobs))
                    table.insert(lines, string.format("%-40s %d", "Df Residuals:", self.df_resid))
                    table.insert(lines, string.format("%-40s %d", "Df Model:", self.df_model))
                    table.insert(lines, string.rep("-", 78))
                    table.insert(lines, string.format("%-40s %.6f", "Deviance:", self.deviance or 0))
                    table.insert(lines, string.format("%-40s %.6f", "Null Deviance:", self.null_deviance or 0))
                    table.insert(lines, string.format("%-40s %.6f", "Pearson Chi2:", self.pearson_chi2 or 0))
                    table.insert(lines, string.format("%-40s %.4f", "Log-Likelihood:", self.llf or 0))
                    table.insert(lines, string.format("%-40s %.4f", "AIC:", self.aic or 0))
                    table.insert(lines, string.format("%-40s %.4f", "BIC:", self.bic or 0))
                    if self.converged ~= nil then
                        table.insert(lines, string.format("%-40s %s (iterations: %d)",
                            "Converged:", self.converged and "Yes" or "No", self.iterations or 0))
                    end
                    table.insert(lines, string.rep("=", 78))

                    -- Parameter table header
                    table.insert(lines, string.format("%-12s %12s %12s %12s %12s %12s %12s",
                        "", "coef", "std err", "z", "P>|z|", "[0.025", "0.975]"))
                    table.insert(lines, string.rep("-", 78))

                    -- Parameter rows
                    local xnames = self._xnames or {}
                    for i = 1, #self.params do
                        local name = xnames[i] or string.format("x%d", i)
                        local coef = self.params[i]
                        local se = self.bse and self.bse[i] or 0
                        local zval = self.tvalues and self.tvalues[i] or 0
                        local pval = self.pvalues and self.pvalues[i] or 1
                        local ci_low = coef - 1.96 * se
                        local ci_high = coef + 1.96 * se

                        table.insert(lines, string.format("%-12s %12.4f %12.4f %12.4f %12.4f %12.4f %12.4f",
                            name:sub(1, 12), coef, se, zval, pval, ci_low, ci_high))
                    end

                    table.insert(lines, string.rep("=", 78))

                    return table.concat(lines, "\\n")
                end

                function GLM_Results_mt:predict(new_X)
                    -- If no new X, return fitted values
                    if not new_X then
                        return self.fittedvalues or self.mu
                    end

                    -- Compute linear predictor eta = X * beta
                    local predictions = {}
                    for i = 1, #new_X do
                        local eta = 0
                        local row = new_X[i]
                        if type(row) == "number" then
                            -- Single predictor case
                            eta = self.params[1] * row
                        else
                            for j = 1, #row do
                                eta = eta + (self.params[j] or 0) * (row[j] or 0)
                            end
                        end
                        -- Apply inverse link function
                        local link = self._link or "identity"
                        if link == "identity" then
                            predictions[i] = eta
                        elseif link == "logit" or link == "log" then
                            predictions[i] = 1.0 / (1.0 + math.exp(-eta))
                        elseif link == "log_link" then
                            predictions[i] = math.exp(eta)
                        elseif link == "inverse" then
                            predictions[i] = 1.0 / eta
                        else
                            predictions[i] = eta
                        end
                    end
                    return predictions
                end

                function GLM_Results_mt:conf_int(alpha)
                    alpha = alpha or 0.05
                    -- For GLM, use normal distribution for CI (large sample)
                    local z = 1.96  -- 95% CI for normal
                    if alpha == 0.01 then z = 2.576
                    elseif alpha == 0.10 then z = 1.645 end

                    local intervals = {}
                    for i = 1, #self.params do
                        local se = self.bse and self.bse[i] or 0
                        intervals[i] = {
                            self.params[i] - z * se,
                            self.params[i] + z * se
                        }
                    end
                    return intervals
                end

                local GLM_mt = {}
                GLM_mt.__index = GLM_mt

                function GLM_mt:fit(opts)
                    opts = opts or {}
                    local maxiter = opts.maxiter or 100
                    local tol = opts.tol or 1e-8

                    local result = _glm_fit(self._endog, self._exog, self._family, self._link, maxiter, tol)
                    if not result then
                        error("GLM fit failed")
                    end

                    -- Create GLM results object
                    local results = setmetatable({}, GLM_Results_mt)
                    results.params = result.params
                    results.bse = result.bse
                    results.tvalues = result.zvalues  -- z-values for GLM
                    results.pvalues = result.pvalues
                    results.resid = result.resid_response
                    results.fittedvalues = result.mu
                    results.mu = result.mu
                    results.eta = result.eta

                    results.deviance = result.deviance
                    results.null_deviance = result.null_deviance
                    results.pearson_chi2 = result.pearson_chi2
                    results.llf = result.llf
                    results.aic = result.aic
                    results.bic = result.bic

                    results.nobs = result.nobs
                    results.df_model = result.df_model
                    results.df_resid = result.df_resid

                    results.converged = result.converged
                    results.iterations = result.iterations

                    results._model_type = "GLM"
                    results._family = self._family
                    results._link = self._link
                    results._yname = self._yname
                    results._xnames = self._xnames
                    results._exog = self._exog

                    return results
                end

                function regress.GLM(endog, exog, opts)
                    opts = opts or {}
                    if type(endog) ~= "table" then
                        error("endog must be a table (array of values)")
                    end

                    local model = setmetatable({}, GLM_mt)
                    model._endog = endog
                    model._exog = exog
                    model._family = opts.family or "gaussian"
                    model._link = opts.link  -- nil means use canonical link
                    model._yname = opts.yname or "y"
                    model._xnames = opts.xnames

                    return model
                end

                ----------------------------------------------------------------
                -- ARIMA (AutoRegressive Integrated Moving Average)
                -- Time series model: ARIMA(p, d, q)
                ----------------------------------------------------------------
                local ARIMA_Results_mt = {}
                ARIMA_Results_mt.__index = ARIMA_Results_mt

                function ARIMA_Results_mt:summary(opts)
                    opts = opts or {}

                    local lines = {}
                    table.insert(lines, string.rep("=", 78))
                    table.insert(lines, string.format("%-40s %s", "Dep. Variable:", self._yname or "y"))
                    table.insert(lines, string.format("%-40s ARIMA(%d,%d,%d)",
                        "Model:", self._order[1], self._order[2], self._order[3]))
                    table.insert(lines, string.format("%-40s %d", "No. Observations:", self.nobs))
                    table.insert(lines, string.rep("-", 78))
                    table.insert(lines, string.format("%-40s %.4f", "Log-Likelihood:", self.llf or 0))
                    table.insert(lines, string.format("%-40s %.4f", "AIC:", self.aic or 0))
                    table.insert(lines, string.format("%-40s %.4f", "BIC:", self.bic or 0))
                    table.insert(lines, string.format("%-40s %.6f", "Sigma^2:", self.sigma2 or 0))
                    if self.converged ~= nil then
                        table.insert(lines, string.format("%-40s %s (iterations: %d)",
                            "Converged:", self.converged and "Yes" or "No", self.iterations or 0))
                    end
                    table.insert(lines, string.rep("=", 78))

                    -- AR coefficients
                    if self.arparams and #self.arparams > 0 then
                        table.insert(lines, "AR Coefficients:")
                        for i, coef in ipairs(self.arparams) do
                            local se = self.ar_bse and self.ar_bse[i] or 0
                            table.insert(lines, string.format("  ar.L%d: %12.4f (se: %.4f)", i, coef, se))
                        end
                    end

                    -- MA coefficients
                    if self.maparams and #self.maparams > 0 then
                        table.insert(lines, "MA Coefficients:")
                        for i, coef in ipairs(self.maparams) do
                            local se = self.ma_bse and self.ma_bse[i] or 0
                            table.insert(lines, string.format("  ma.L%d: %12.4f (se: %.4f)", i, coef, se))
                        end
                    end

                    table.insert(lines, string.rep("=", 78))

                    return table.concat(lines, "\\n")
                end

                function ARIMA_Results_mt:forecast(steps)
                    steps = steps or 1
                    if steps < 1 then return {} end

                    local p, d, q = self._order[1], self._order[2], self._order[3]
                    local ar = self.arparams or {}
                    local ma = self.maparams or {}
                    local resid = self.resid or {}
                    local y = self._y_diff or {}  -- differenced series

                    local forecasts = {}
                    local n = #y

                    for h = 1, steps do
                        local pred = 0

                        -- AR component
                        for i = 1, p do
                            local idx = n + h - i
                            if idx > n then
                                -- Use previous forecast
                                pred = pred + ar[i] * (forecasts[idx - n] or 0)
                            elseif idx > 0 then
                                pred = pred + ar[i] * y[idx]
                            end
                        end

                        -- MA component (use 0 for future errors)
                        for j = 1, q do
                            local idx = n + h - j
                            if idx <= n and idx > 0 then
                                pred = pred + ma[j] * (resid[idx] or 0)
                            end
                        end

                        forecasts[h] = pred
                    end

                    -- If differenced, need to integrate back
                    if d > 0 and self._original_y then
                        local orig = self._original_y
                        local last_val = orig[#orig]
                        for h = 1, steps do
                            forecasts[h] = last_val + forecasts[h]
                            last_val = forecasts[h]
                        end
                    end

                    return forecasts
                end

                function ARIMA_Results_mt:predict(start_idx, end_idx)
                    start_idx = start_idx or 1
                    end_idx = end_idx or self.nobs

                    return self.fittedvalues or {}
                end

                local ARIMA_mt = {}
                ARIMA_mt.__index = ARIMA_mt

                function ARIMA_mt:fit(opts)
                    opts = opts or {}
                    local maxiter = opts.maxiter or 100
                    local tol = opts.tol or 1e-8

                    local result = _arima_fit(self._endog, self._order[1], self._order[2], self._order[3], maxiter, tol)
                    if not result then
                        return nil  -- Return nil for invalid inputs (too short series, etc.)
                    end

                    -- Create ARIMA results object
                    local results = setmetatable({}, ARIMA_Results_mt)
                    results.arparams = result.arparams or {}
                    results.maparams = result.maparams or {}
                    results.ar_bse = result.ar_bse or {}
                    results.ma_bse = result.ma_bse or {}
                    results.resid = result.resid
                    results.fittedvalues = result.fittedvalues

                    -- Combined params array (AR params followed by MA params)
                    results.params = {}
                    for _, v in ipairs(results.arparams) do
                        table.insert(results.params, v)
                    end
                    for _, v in ipairs(results.maparams) do
                        table.insert(results.params, v)
                    end

                    -- Combined bse array
                    results.bse = {}
                    for _, v in ipairs(results.ar_bse) do
                        table.insert(results.bse, v)
                    end
                    for _, v in ipairs(results.ma_bse) do
                        table.insert(results.bse, v)
                    end

                    results.sigma2 = result.sigma2
                    results.llf = result.llf
                    results.aic = result.aic
                    results.bic = result.bic

                    results.nobs = result.nobs
                    results.converged = result.converged
                    results.iterations = result.iterations

                    results._model_type = "ARIMA"
                    results.order = self._order  -- Public order field
                    results._order = self._order
                    results._yname = self._yname
                    results._y_diff = result.y_diff
                    results._original_y = self._endog

                    return results
                end

                function regress.ARIMA(endog, order, opts)
                    opts = opts or {}
                    if type(endog) ~= "table" then
                        error("endog must be a table (array of values)")
                    end
                    if type(order) ~= "table" or #order ~= 3 then
                        error("order must be a table {p, d, q}")
                    end

                    local model = setmetatable({}, ARIMA_mt)
                    model._endog = endog
                    model._order = order  -- {p, d, q}
                    model._yname = opts.yname or "y"

                    return model
                end

                ----------------------------------------------------------------
                -- Helper: add_constant
                -- Adds a column of ones to the design matrix
                ----------------------------------------------------------------
                function regress.add_constant(X)
                    if type(X) ~= "table" then
                        error("X must be a table")
                    end

                    local result = {}
                    local n = #X

                    -- Handle 1D array (single regressor)
                    if type(X[1]) == "number" then
                        for i = 1, n do
                            result[i] = {1, X[i]}
                        end
                    else
                        -- 2D array
                        for i = 1, n do
                            local row = {1}
                            local orig_row = X[i]
                            for j = 1, #orig_row do
                                row[j + 1] = orig_row[j]
                            end
                            result[i] = row
                        end
                    end

                    return result
                end

                -- Create alias
                luaswift.regress = regress

                -- Clean up temporary globals
                _luaswift_regress_ols_fit = nil
                _luaswift_regress_glm_fit = nil
                _luaswift_regress_arima_fit = nil
                """)
        } catch {
            #if DEBUG
            print("[LuaSwift] RegressModule setup failed: \(error)")
            #endif
        }
    }

    // MARK: - OLS Callback (Thin Wrapper around NumericSwift.ols)

    private static func registerOLSCallbacks(in engine: LuaEngine) {
        engine.registerFunction(name: "_luaswift_regress_ols_fit") { args in
            guard let endogArray = args.first?.arrayValue else {
                return .nil
            }

            // Extract endog (y) values
            let endog = endogArray.compactMap { $0.numberValue }
            let n = endog.count

            guard n > 0 else {
                return .nil
            }

            // Extract exog (X) matrix
            var exog: [[Double]] = []

            if args.count > 1, let exogTable = args[1].arrayValue {
                // Check if it's a 2D array or 1D array
                if exogTable.first?.arrayValue != nil {
                    // 2D array
                    for row in exogTable {
                        if let rowArray = row.arrayValue {
                            let rowValues = rowArray.compactMap { $0.numberValue }
                            exog.append(rowValues)
                        }
                    }
                } else {
                    // 1D array - treat as single column
                    let values = exogTable.compactMap { $0.numberValue }
                    for val in values {
                        exog.append([val])
                    }
                }
            }

            // If no exog provided, use intercept only
            if exog.isEmpty {
                exog = Array(repeating: [1.0], count: n)
            }

            guard exog.count == n else {
                return .nil  // Mismatched dimensions
            }

            // Extract weights (for WLS)
            var weights: [Double]?
            if args.count > 2, let weightsArray = args[2].arrayValue {
                weights = weightsArray.compactMap { $0.numberValue }
            }

            // Call NumericSwift.ols
            guard let result = NumericSwift.ols(endog, exog, weights: weights) else {
                return .nil
            }

            // Convert OLSResult to LuaValue table
            return .table([
                // Per-parameter metrics
                "params": .array(result.params.map { .number($0) }),
                "bse": .array(result.bse.map { .number($0) }),
                "tvalues": .array(result.tvalues.map { .number($0) }),
                "pvalues": .array(result.pvalues.map { .number($0) }),
                "conf_int": .array(result.confInt.map { row in
                    .array(row.map { .number($0) })
                }),

                // Robust standard errors (HC0-HC3)
                "bse_hc0": .array(result.bseHC0.map { .number($0) }),
                "bse_hc1": .array(result.bseHC1.map { .number($0) }),
                "bse_hc2": .array(result.bseHC2.map { .number($0) }),
                "bse_hc3": .array(result.bseHC3.map { .number($0) }),

                // Per-observation metrics
                "resid": .array(result.residuals.map { .number($0) }),
                "fittedvalues": .array(result.fittedValues.map { .number($0) }),
                "hat_diag": .array(result.hatDiag.map { .number($0) }),
                "resid_studentized": .array(result.studentizedResiduals.map { .number($0) }),
                "cooks_distance": .array(result.cooksDistance.map { .number($0) }),
                "dffits": .array(result.dffits.map { .number($0) }),

                // Model-level metrics
                "rsquared": .number(result.rsquared),
                "rsquared_adj": .number(result.rsquaredAdj),
                "fvalue": .number(result.fvalue),
                "f_pvalue": .number(result.fPvalue),
                "llf": .number(result.llf),
                "aic": .number(result.aic),
                "bic": .number(result.bic),
                "ssr": .number(result.ssr),
                "ess": .number(result.ess),
                "mse_resid": .number(result.mse),
                "centered_tss": .number(result.tss),
                "nobs": .number(Double(result.nobs)),
                "df_model": .number(Double(result.dfModel)),
                "df_resid": .number(Double(result.dfResid)),

                // Multicollinearity diagnostics
                "condition_number": .number(result.conditionNumber),
                "eigenvalues": .array(result.eigenvalues.map { .number($0) })
            ])
        }
    }

    // MARK: - GLM Callback (Thin Wrapper around NumericSwift.glm)

    private static func registerGLMCallbacks(in engine: LuaEngine) {
        engine.registerFunction(name: "_luaswift_regress_glm_fit") { args in
            guard let endogArray = args.first?.arrayValue else {
                return .nil
            }

            // Extract endog (y) values
            let endog = endogArray.compactMap { $0.numberValue }
            let n = endog.count

            guard n > 0 else {
                return .nil
            }

            // Extract exog (X) matrix
            var exog: [[Double]] = []

            if args.count > 1, let exogTable = args[1].arrayValue {
                if exogTable.first?.arrayValue != nil {
                    for row in exogTable {
                        if let rowArray = row.arrayValue {
                            let rowValues = rowArray.compactMap { $0.numberValue }
                            exog.append(rowValues)
                        }
                    }
                } else {
                    let values = exogTable.compactMap { $0.numberValue }
                    for val in values {
                        exog.append([val])
                    }
                }
            }

            if exog.isEmpty {
                exog = Array(repeating: [1.0], count: n)
            }

            guard exog.count == n else {
                return .nil
            }

            // Extract family
            let familyStr = args.count > 2 ? (args[2].stringValue ?? "gaussian") : "gaussian"
            let family: GLMFamily
            switch familyStr.lowercased() {
            case "binomial": family = .binomial
            case "poisson": family = .poisson
            case "gamma": family = .gamma
            default: family = .gaussian
            }

            // Extract link (optional)
            var link: GLMLink?
            if args.count > 3, let linkStr = args[3].stringValue {
                switch linkStr.lowercased() {
                case "identity": link = .identity
                case "logit": link = .logit
                case "log": link = .log
                case "inverse": link = .inverse
                case "probit": link = .probit
                default: break
                }
            }

            // Extract maxiter and tol
            let maxiter = args.count > 4 ? Int(args[4].numberValue ?? 100) : 100
            let tol = args.count > 5 ? (args[5].numberValue ?? 1e-8) : 1e-8

            // Call NumericSwift.glm
            guard let result = NumericSwift.glm(endog, exog, family: family, link: link, maxiter: maxiter, tol: tol) else {
                return .nil
            }

            // Convert GLMResult to LuaValue table
            return .table([
                "params": .array(result.params.map { .number($0) }),
                "bse": .array(result.bse.map { .number($0) }),
                "zvalues": .array(result.zvalues.map { .number($0) }),
                "pvalues": .array(result.pvalues.map { .number($0) }),
                "mu": .array(result.mu.map { .number($0) }),
                "eta": .array(result.eta.map { .number($0) }),
                "resid_response": .array(result.residResponse.map { .number($0) }),
                "deviance": .number(result.deviance),
                "null_deviance": .number(result.nullDeviance),
                "pearson_chi2": .number(result.pearsonChi2),
                "llf": .number(result.llf),
                "aic": .number(result.aic),
                "bic": .number(result.bic),
                "nobs": .number(Double(result.nobs)),
                "df_model": .number(Double(result.dfModel)),
                "df_resid": .number(Double(result.dfResid)),
                "converged": .bool(result.converged),
                "iterations": .number(Double(result.iterations))
            ])
        }
    }

    // MARK: - ARIMA Callback (Thin Wrapper around NumericSwift.arima)

    private static func registerARIMACallbacks(in engine: LuaEngine) {
        engine.registerFunction(name: "_luaswift_regress_arima_fit") { args in
            guard let endogArray = args.first?.arrayValue else {
                return .nil
            }

            // Extract y values
            let y = endogArray.compactMap { $0.numberValue }

            guard y.count > 2 else {
                return .nil
            }

            // Extract p, d, q
            let p = args.count > 1 ? Int(args[1].numberValue ?? 0) : 0
            let d = args.count > 2 ? Int(args[2].numberValue ?? 0) : 0
            let q = args.count > 3 ? Int(args[3].numberValue ?? 0) : 0

            // Extract maxiter and tol
            let maxiter = args.count > 4 ? Int(args[4].numberValue ?? 100) : 100
            let tol = args.count > 5 ? (args[5].numberValue ?? 1e-8) : 1e-8

            // Call NumericSwift.arima
            guard let result = NumericSwift.arima(y, p: p, d: d, q: q, maxiter: maxiter, tol: tol) else {
                return .nil
            }

            // Convert ARIMAResult to LuaValue table
            return .table([
                "arparams": .array(result.arParams.map { .number($0) }),
                "maparams": .array(result.maParams.map { .number($0) }),
                "ar_bse": .array(result.arBse.map { .number($0) }),
                "ma_bse": .array(result.maBse.map { .number($0) }),
                "resid": .array(result.residuals.map { .number($0) }),
                "fittedvalues": .array(result.fittedValues.map { .number($0) }),
                "y_diff": .array(result.yDiff.map { .number($0) }),
                "sigma2": .number(result.sigma2),
                "llf": .number(result.llf),
                "aic": .number(result.aic),
                "bic": .number(result.bic),
                "nobs": .number(Double(result.nobs)),
                "converged": .bool(result.converged),
                "iterations": .number(Double(result.iterations))
            ])
        }
    }
}
#endif
