//
//  RegressModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Accelerate

/// Swift-backed regression modeling module for LuaSwift.
///
/// Provides statsmodels-compatible regression analysis including OLS, WLS, GLS,
/// GLM, and ARIMA models. Uses the Accelerate framework for hardware-accelerated
/// computation.
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
        registerGLSCallbacks(in: engine)
        registerGLMCallbacks(in: engine)

        // Set up the luaswift.regress namespace with Lua wrapper code
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.regress then luaswift.regress = {} end

                local regress = luaswift.regress

                -- Store references to Swift callbacks
                local _ols_fit = _luaswift_regress_ols_fit
                local _gls_fit = _luaswift_regress_gls_fit
                local _glm_fit = _luaswift_regress_glm_fit

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
                -- GLS Model metatable
                -- Generalized Least Squares with correlated errors
                ----------------------------------------------------------------
                local GLS_mt = {}
                GLS_mt.__index = GLS_mt

                function GLS_mt:fit(opts)
                    opts = opts or {}

                    -- Call Swift backend to fit the GLS model
                    local result = _gls_fit(self._endog, self._exog, self._sigma)

                    if not result then
                        error("GLS fit failed")
                    end

                    -- Create Results object (same structure as OLS)
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
                    results._model_type = "GLS"
                    results._yname = self._yname
                    results._xnames = self._xnames
                    results._model = self

                    return results
                end

                ----------------------------------------------------------------
                -- GLS constructor (Generalized Least Squares)
                -- GLS(endog, exog, sigma, opts)
                -- sigma: covariance matrix of errors
                --   - nil or scalar: equivalent to OLS
                --   - 1D array: diagonal variances (equivalent to WLS)
                --   - 2D array: full covariance matrix
                ----------------------------------------------------------------
                function regress.GLS(endog, exog, sigma, opts)
                    opts = opts or {}

                    if type(endog) ~= "table" then
                        error("endog must be a table (array of values)")
                    end

                    local model = setmetatable({}, GLS_mt)
                    model._endog = endog
                    model._exog = exog
                    model._sigma = sigma
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
                _luaswift_regress_gls_fit = nil
                _luaswift_regress_glm_fit = nil
                """)
        } catch {
            // Silently fail if setup fails
        }
    }

    // MARK: - OLS Callbacks

    private static func registerOLSCallbacks(in engine: LuaEngine) {
        // OLS fit callback - performs the actual regression using Accelerate
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
            var k = 0  // number of regressors

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
                    k = exog.first?.count ?? 0
                } else {
                    // 1D array - treat as single column
                    let values = exogTable.compactMap { $0.numberValue }
                    for val in values {
                        exog.append([val])
                    }
                    k = 1
                }
            }

            // If no exog provided, use intercept only
            if exog.isEmpty {
                exog = Array(repeating: [1.0], count: n)
                k = 1
            }

            guard exog.count == n else {
                return .nil  // Mismatched dimensions
            }

            // Extract weights (for WLS)
            var weights: [Double]?
            if args.count > 2, let weightsArray = args[2].arrayValue {
                weights = weightsArray.compactMap { $0.numberValue }
            }

            // Apply weights if provided (WLS)
            var y = endog
            var X = exog
            if let w = weights, w.count == n {
                // Transform: y* = y * sqrt(w), X* = X * sqrt(w)
                for i in 0..<n {
                    let sqrtW = sqrt(w[i])
                    y[i] *= sqrtW
                    for j in 0..<k {
                        X[i][j] *= sqrtW
                    }
                }
            }

            // Solve least squares using LAPACK (via Accelerate)
            // We need to solve X * beta = y for beta

            // Flatten X to column-major order for LAPACK
            var XFlat = [Double](repeating: 0.0, count: n * k)
            for j in 0..<k {
                for i in 0..<n {
                    XFlat[j * n + i] = X[i][j]
                }
            }

            // Copy y to work array
            var yCopy = y

            // Call LAPACK dgels (least squares solver)
            var m = __CLPK_integer(n)
            var nCols = __CLPK_integer(k)
            var nrhs = __CLPK_integer(1)
            var lda = __CLPK_integer(n)
            var ldb = __CLPK_integer(max(n, k))
            var info: __CLPK_integer = 0

            // Resize yCopy to max(n, k) for LAPACK
            if k > n {
                yCopy.append(contentsOf: [Double](repeating: 0.0, count: k - n))
            }

            // Query optimal workspace size
            var workQuery = [Double](repeating: 0.0, count: 1)
            var lwork: __CLPK_integer = -1
            dgels_(UnsafeMutablePointer(mutating: ("N" as NSString).utf8String),
                   &m, &nCols, &nrhs, &XFlat, &lda, &yCopy, &ldb, &workQuery, &lwork, &info)

            lwork = __CLPK_integer(workQuery[0])
            var work = [Double](repeating: 0.0, count: Int(lwork))

            // Solve the least squares problem
            dgels_(UnsafeMutablePointer(mutating: ("N" as NSString).utf8String),
                   &m, &nCols, &nrhs, &XFlat, &lda, &yCopy, &ldb, &work, &lwork, &info)

            guard info == 0 else {
                return .nil  // LAPACK failed
            }

            // Extract parameters (first k elements of yCopy)
            let params = Array(yCopy.prefix(k))

            // Compute fitted values and residuals (using original endog/exog)
            var fittedValues = [Double](repeating: 0.0, count: n)
            var residuals = [Double](repeating: 0.0, count: n)

            for i in 0..<n {
                var fitted = 0.0
                for j in 0..<k {
                    fitted += exog[i][j] * params[j]
                }
                fittedValues[i] = fitted
                residuals[i] = endog[i] - fitted
            }

            // Compute statistics
            let yMean = endog.reduce(0, +) / Double(n)

            // Sum of squares
            var ssr = 0.0  // Sum of squared residuals
            var ess = 0.0  // Explained sum of squares
            var tss = 0.0  // Total sum of squares

            for i in 0..<n {
                ssr += residuals[i] * residuals[i]
                ess += (fittedValues[i] - yMean) * (fittedValues[i] - yMean)
                tss += (endog[i] - yMean) * (endog[i] - yMean)
            }

            // Degrees of freedom
            let dfModel = k - 1  // Assuming intercept is included
            let dfResid = n - k

            // R-squared
            let rsquared = tss > 0 ? 1.0 - ssr / tss : 0.0
            let rsquaredAdj = dfResid > 0 ? 1.0 - (1.0 - rsquared) * Double(n - 1) / Double(dfResid) : 0.0

            // Mean squared error (for standard errors)
            let mse = dfResid > 0 ? ssr / Double(dfResid) : 0.0

            // Compute (X'X)^-1 for standard errors
            // First compute X'X
            var XtX = [Double](repeating: 0.0, count: k * k)
            for i in 0..<k {
                for j in 0..<k {
                    var sum = 0.0
                    for obs in 0..<n {
                        sum += exog[obs][i] * exog[obs][j]
                    }
                    XtX[j * k + i] = sum  // Column-major
                }
            }

            // Invert X'X using LAPACK (dpotrf + dpotri for symmetric positive definite)
            var kInt = __CLPK_integer(k)
            var ldaXtX = __CLPK_integer(k)
            var infoInv: __CLPK_integer = 0

            // Cholesky factorization
            dpotrf_(UnsafeMutablePointer(mutating: ("U" as NSString).utf8String),
                    &kInt, &XtX, &ldaXtX, &infoInv)

            var XtXInv = XtX
            if infoInv == 0 {
                // Invert using Cholesky factor
                dpotri_(UnsafeMutablePointer(mutating: ("U" as NSString).utf8String),
                        &kInt, &XtXInv, &ldaXtX, &infoInv)

                // Fill in lower triangle (symmetric matrix)
                for i in 0..<k {
                    for j in i+1..<k {
                        XtXInv[i * k + j] = XtXInv[j * k + i]
                    }
                }
            }

            // Standard errors of parameters: sqrt(diag((X'X)^-1) * MSE)
            var bse = [Double](repeating: 0.0, count: k)
            if infoInv == 0 {
                for i in 0..<k {
                    bse[i] = sqrt(XtXInv[i * k + i] * mse)
                }
            }

            // t-values and p-values
            var tvalues = [Double](repeating: 0.0, count: k)
            var pvalues = [Double](repeating: 1.0, count: k)

            for i in 0..<k {
                if bse[i] > 0 {
                    tvalues[i] = params[i] / bse[i]
                    // Two-tailed p-value using t-distribution
                    pvalues[i] = 2.0 * (1.0 - tCDF(abs(tvalues[i]), Double(dfResid)))
                }
            }

            // F-statistic: (ESS/df_model) / (SSR/df_resid)
            var fvalue = 0.0
            var f_pvalue = 1.0
            if dfModel > 0 && dfResid > 0 && ssr > 0 {
                fvalue = (ess / Double(dfModel)) / (ssr / Double(dfResid))
                f_pvalue = 1.0 - fCDF(fvalue, Double(dfModel), Double(dfResid))
            }

            // Log-likelihood (assuming normal errors)
            let llf = -Double(n) / 2.0 * (log(2.0 * Double.pi) + log(ssr / Double(n)) + 1.0)

            // Information criteria
            let aic = -2.0 * llf + 2.0 * Double(k)
            let bic = -2.0 * llf + log(Double(n)) * Double(k)

            // Confidence intervals (95%)
            let tCrit = tPPF(0.975, Double(dfResid))
            var confInt: [[Double]] = []
            for i in 0..<k {
                confInt.append([params[i] - tCrit * bse[i], params[i] + tCrit * bse[i]])
            }

            // ============================================================
            // Per-Observation Influence Diagnostics
            // ============================================================

            // Hat matrix diagonal: h_ii = [X(X'X)^-1 X']_ii
            // More efficient computation: h_ii = sum_j (X_ij * [XtXInv * X']_ji)
            var hatDiag = [Double](repeating: 0.0, count: n)
            if infoInv == 0 {
                for i in 0..<n {
                    var h_ii = 0.0
                    for j in 0..<k {
                        var sum = 0.0
                        for l in 0..<k {
                            sum += XtXInv[l * k + j] * exog[i][l]
                        }
                        h_ii += exog[i][j] * sum
                    }
                    hatDiag[i] = h_ii
                }
            }

            // Studentized residuals (internal): e_i / (s * sqrt(1 - h_ii))
            var residStudentized = [Double](repeating: 0.0, count: n)
            let rmse = sqrt(mse)
            for i in 0..<n {
                let denom = rmse * sqrt(max(1e-15, 1.0 - hatDiag[i]))
                residStudentized[i] = denom > 1e-15 ? residuals[i] / denom : 0.0
            }

            // Cook's distance: D_i = (e_i^2 / (p * MSE)) * (h_ii / (1 - h_ii)^2)
            var cooksDistance = [Double](repeating: 0.0, count: n)
            if k > 0 && mse > 0 {
                for i in 0..<n {
                    let h_ii = hatDiag[i]
                    if h_ii < 1.0 - 1e-10 {
                        let e2 = residuals[i] * residuals[i]
                        cooksDistance[i] = (e2 / (Double(k) * mse)) * (h_ii / ((1.0 - h_ii) * (1.0 - h_ii)))
                    }
                }
            }

            // DFFITS: studentized_resid * sqrt(h_ii / (1 - h_ii))
            var dffits = [Double](repeating: 0.0, count: n)
            for i in 0..<n {
                let h_ii = hatDiag[i]
                if h_ii < 1.0 - 1e-10 {
                    dffits[i] = residStudentized[i] * sqrt(h_ii / (1.0 - h_ii))
                }
            }

            // ============================================================
            // Multicollinearity Diagnostics
            // ============================================================

            // Condition number: sqrt(max_eigenvalue / min_eigenvalue) of X'X
            var conditionNumber = Double.infinity
            var eigenvalues = [Double](repeating: 0.0, count: k)

            if k > 0 {
                // Compute eigenvalues of X'X using LAPACK dsyev
                var XtXCopy = [Double](repeating: 0.0, count: k * k)
                // Recompute X'X since we may have modified it
                for i in 0..<k {
                    for j in 0..<k {
                        var sum = 0.0
                        for obs in 0..<n {
                            sum += exog[obs][i] * exog[obs][j]
                        }
                        XtXCopy[j * k + i] = sum
                    }
                }

                var kEig = __CLPK_integer(k)
                var ldaEig = __CLPK_integer(k)
                var eigenW = [Double](repeating: 0.0, count: k)
                var workEig = [Double](repeating: 0.0, count: 1)
                var lworkEig: __CLPK_integer = -1
                var infoEig: __CLPK_integer = 0

                // Query workspace size
                dsyev_(UnsafeMutablePointer(mutating: ("V" as NSString).utf8String),
                       UnsafeMutablePointer(mutating: ("U" as NSString).utf8String),
                       &kEig, &XtXCopy, &ldaEig, &eigenW, &workEig, &lworkEig, &infoEig)

                lworkEig = __CLPK_integer(workEig[0])
                workEig = [Double](repeating: 0.0, count: Int(lworkEig))

                // Compute eigenvalues
                dsyev_(UnsafeMutablePointer(mutating: ("V" as NSString).utf8String),
                       UnsafeMutablePointer(mutating: ("U" as NSString).utf8String),
                       &kEig, &XtXCopy, &ldaEig, &eigenW, &workEig, &lworkEig, &infoEig)

                if infoEig == 0 {
                    eigenvalues = eigenW.sorted(by: >)  // Descending order
                    let maxEig = eigenvalues.first ?? 1.0
                    let minEig = eigenvalues.last ?? 1.0
                    if minEig > 1e-15 {
                        conditionNumber = sqrt(maxEig / minEig)
                    }
                }
            }

            // ============================================================
            // Heteroscedasticity-Robust Covariance (HC0-HC3)
            // ============================================================

            // Compute X' * diag(u^2) * X for HC estimators where u = residuals
            // HC0: Omega = diag(e_i^2)
            // HC1: n/(n-k) * HC0
            // HC2: Omega = diag(e_i^2 / (1 - h_ii))
            // HC3: Omega = diag(e_i^2 / (1 - h_ii)^2)

            var bseHC0 = [Double](repeating: 0.0, count: k)
            var bseHC1 = [Double](repeating: 0.0, count: k)
            var bseHC2 = [Double](repeating: 0.0, count: k)
            var bseHC3 = [Double](repeating: 0.0, count: k)

            if infoInv == 0 && n > k {
                // Compute X' * Omega * X for each HC type
                // Then cov = (X'X)^-1 * X'OmegaX * (X'X)^-1

                func computeHCStdErrors(omega: [Double]) -> [Double] {
                    // Compute X' * Omega * X
                    var XtOmegaX = [Double](repeating: 0.0, count: k * k)
                    for i in 0..<k {
                        for j in 0..<k {
                            var sum = 0.0
                            for obs in 0..<n {
                                sum += exog[obs][i] * omega[obs] * exog[obs][j]
                            }
                            XtOmegaX[j * k + i] = sum
                        }
                    }

                    // Compute (X'X)^-1 * X'OmegaX * (X'X)^-1
                    // First: temp = X'OmegaX * (X'X)^-1
                    var temp = [Double](repeating: 0.0, count: k * k)
                    for i in 0..<k {
                        for j in 0..<k {
                            var sum = 0.0
                            for l in 0..<k {
                                sum += XtOmegaX[l * k + i] * XtXInv[j * k + l]
                            }
                            temp[j * k + i] = sum
                        }
                    }

                    // Then: cov = (X'X)^-1 * temp
                    var cov = [Double](repeating: 0.0, count: k * k)
                    for i in 0..<k {
                        for j in 0..<k {
                            var sum = 0.0
                            for l in 0..<k {
                                sum += XtXInv[l * k + i] * temp[j * k + l]
                            }
                            cov[j * k + i] = sum
                        }
                    }

                    // Extract diagonal and sqrt
                    var se = [Double](repeating: 0.0, count: k)
                    for i in 0..<k {
                        se[i] = sqrt(max(0.0, cov[i * k + i]))
                    }
                    return se
                }

                // HC0: Omega = diag(e_i^2)
                let omegaHC0 = residuals.map { $0 * $0 }
                bseHC0 = computeHCStdErrors(omega: omegaHC0)

                // HC1: n/(n-k) * HC0
                let hc1Factor = Double(n) / Double(n - k)
                bseHC1 = bseHC0.map { $0 * sqrt(hc1Factor) }

                // HC2: Omega = diag(e_i^2 / (1 - h_ii))
                var omegaHC2 = [Double](repeating: 0.0, count: n)
                for i in 0..<n {
                    let denom = max(1e-15, 1.0 - hatDiag[i])
                    omegaHC2[i] = residuals[i] * residuals[i] / denom
                }
                bseHC2 = computeHCStdErrors(omega: omegaHC2)

                // HC3: Omega = diag(e_i^2 / (1 - h_ii)^2)
                var omegaHC3 = [Double](repeating: 0.0, count: n)
                for i in 0..<n {
                    let denom = max(1e-15, 1.0 - hatDiag[i])
                    omegaHC3[i] = residuals[i] * residuals[i] / (denom * denom)
                }
                bseHC3 = computeHCStdErrors(omega: omegaHC3)
            }

            // ============================================================
            // Build Result Table
            // ============================================================

            return .table([
                // Per-parameter metrics
                "params": .array(params.map { .number($0) }),
                "bse": .array(bse.map { .number($0) }),
                "tvalues": .array(tvalues.map { .number($0) }),
                "pvalues": .array(pvalues.map { .number($0) }),
                "conf_int": .array(confInt.map { row in
                    .array(row.map { .number($0) })
                }),

                // Robust standard errors (HC0-HC3)
                "bse_hc0": .array(bseHC0.map { .number($0) }),
                "bse_hc1": .array(bseHC1.map { .number($0) }),
                "bse_hc2": .array(bseHC2.map { .number($0) }),
                "bse_hc3": .array(bseHC3.map { .number($0) }),

                // Per-observation metrics
                "resid": .array(residuals.map { .number($0) }),
                "fittedvalues": .array(fittedValues.map { .number($0) }),
                "hat_diag": .array(hatDiag.map { .number($0) }),
                "resid_studentized": .array(residStudentized.map { .number($0) }),
                "cooks_distance": .array(cooksDistance.map { .number($0) }),
                "dffits": .array(dffits.map { .number($0) }),

                // Model-level metrics
                "rsquared": .number(rsquared),
                "rsquared_adj": .number(rsquaredAdj),
                "fvalue": .number(fvalue),
                "f_pvalue": .number(f_pvalue),
                "llf": .number(llf),
                "aic": .number(aic),
                "bic": .number(bic),
                "ssr": .number(ssr),
                "ess": .number(ess),
                "mse_resid": .number(mse),
                "centered_tss": .number(tss),
                "nobs": .number(Double(n)),
                "df_model": .number(Double(dfModel)),
                "df_resid": .number(Double(dfResid)),

                // Multicollinearity diagnostics
                "condition_number": .number(conditionNumber),
                "eigenvalues": .array(eigenvalues.map { .number($0) })
            ])
        }
    }

    // MARK: - Statistical Distribution Functions

    /// Student's t-distribution CDF using incomplete beta function
    private static func tCDF(_ t: Double, _ df: Double) -> Double {
        if t == 0 { return 0.5 }

        let x = df / (df + t * t)
        let p = 0.5 * betainc(df / 2.0, 0.5, x)

        return t > 0 ? 1.0 - p : p
    }

    /// Student's t-distribution PPF (inverse CDF) using Newton-Raphson
    private static func tPPF(_ p: Double, _ df: Double) -> Double {
        guard p > 0 && p < 1 else {
            if p <= 0 { return -.infinity }
            if p >= 1 { return .infinity }
            return .nan
        }

        // Initial guess from normal approximation
        var x = sqrt(2.0) * erfinv(2.0 * p - 1.0)

        // Newton-Raphson iteration
        for _ in 0..<50 {
            let cdfVal = tCDF(x, df)
            let pdfVal = tPDF(x, df)

            guard pdfVal > 1e-30 else { break }
            let dx = (cdfVal - p) / pdfVal
            x -= dx
            if abs(dx) < 1e-10 { break }
        }

        return x
    }

    /// Student's t-distribution PDF
    private static func tPDF(_ x: Double, _ df: Double) -> Double {
        let coef = exp(lgamma((df + 1) / 2.0) - lgamma(df / 2.0)) / sqrt(df * .pi)
        return coef * pow(1.0 + x * x / df, -(df + 1) / 2.0)
    }

    /// F-distribution CDF using incomplete beta function
    private static func fCDF(_ x: Double, _ dfn: Double, _ dfd: Double) -> Double {
        guard x > 0 else { return 0.0 }
        let u = dfn * x / (dfn * x + dfd)
        return betainc(dfn / 2.0, dfd / 2.0, u)
    }

    /// Regularized incomplete beta function I_x(a, b)
    private static func betainc(_ a: Double, _ b: Double, _ x: Double) -> Double {
        if x < 0 || x > 1 { return .nan }
        if x == 0 { return 0.0 }
        if x == 1 { return 1.0 }

        // Use symmetry relation if x > (a+1)/(a+b+2)
        if x > (a + 1.0) / (a + b + 2.0) {
            return 1.0 - betainc(b, a, 1.0 - x)
        }

        let bt = exp(lgamma(a + b) - lgamma(a) - lgamma(b) + a * log(x) + b * log(1.0 - x))
        return bt * betaincCF(a, b, x) / a
    }

    /// Continued fraction for incomplete beta
    private static func betaincCF(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let maxIterations = 200
        let epsilon = 1e-15

        let qab = a + b
        let qap = a + 1.0
        let qam = a - 1.0

        var c = 1.0
        var d = 1.0 - qab * x / qap
        if abs(d) < 1e-30 { d = 1e-30 }
        d = 1.0 / d
        var h = d

        for m in 1..<maxIterations {
            let m2 = 2 * m
            var aa = Double(m) * (b - Double(m)) * x / ((qam + Double(m2)) * (a + Double(m2)))
            d = 1.0 + aa * d
            if abs(d) < 1e-30 { d = 1e-30 }
            c = 1.0 + aa / c
            if abs(c) < 1e-30 { c = 1e-30 }
            d = 1.0 / d
            h *= d * c

            aa = -(a + Double(m)) * (qab + Double(m)) * x / ((a + Double(m2)) * (qap + Double(m2)))
            d = 1.0 + aa * d
            if abs(d) < 1e-30 { d = 1e-30 }
            c = 1.0 + aa / c
            if abs(c) < 1e-30 { c = 1e-30 }
            d = 1.0 / d
            let del = d * c
            h *= del
            if abs(del - 1.0) < epsilon {
                break
            }
        }

        return h
    }

    /// Inverse error function using Winitzki approximation
    private static func erfinv(_ x: Double) -> Double {
        guard x > -1 && x < 1 else {
            if x == -1 { return -.infinity }
            if x == 1 { return .infinity }
            return .nan
        }

        let a = 0.147
        let ln1mx2 = log(1.0 - x * x)
        let term1 = 2.0 / (Double.pi * a) + ln1mx2 / 2.0
        let term2 = ln1mx2 / a

        let sign = x < 0 ? -1.0 : 1.0
        return sign * sqrt(sqrt(term1 * term1 - term2) - term1)
    }

    // MARK: - GLS Callbacks

    private static func registerGLSCallbacks(in engine: LuaEngine) {
        // GLS fit callback - Generalized Least Squares using Accelerate
        // GLS transforms the model using the error covariance matrix:
        // β_GLS = (X'Σ⁻¹X)⁻¹ X'Σ⁻¹y
        // Implemented via Cholesky decomposition: Σ = LL', y* = L⁻¹y, X* = L⁻¹X
        engine.registerFunction(name: "_luaswift_regress_gls_fit") { args in
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
            var k = 0

            if args.count > 1, let exogTable = args[1].arrayValue {
                if exogTable.first?.arrayValue != nil {
                    for row in exogTable {
                        if let rowArray = row.arrayValue {
                            let rowValues = rowArray.compactMap { $0.numberValue }
                            exog.append(rowValues)
                        }
                    }
                    k = exog.first?.count ?? 0
                } else {
                    let values = exogTable.compactMap { $0.numberValue }
                    for val in values {
                        exog.append([val])
                    }
                    k = 1
                }
            }

            if exog.isEmpty {
                exog = Array(repeating: [1.0], count: n)
                k = 1
            }

            guard exog.count == n else {
                return .nil
            }

            // Parse sigma (covariance matrix of errors)
            // sigma can be: nil, scalar, 1D array (diagonal), or 2D array (full)
            var sigmaMatrix = [Double](repeating: 0.0, count: n * n)

            // Default: identity matrix (equivalent to OLS)
            for i in 0..<n {
                sigmaMatrix[i * n + i] = 1.0
            }

            if args.count > 2 {
                if let sigmaScalar = args[2].numberValue {
                    // Scalar: constant variance (still OLS-like)
                    for i in 0..<n {
                        sigmaMatrix[i * n + i] = sigmaScalar
                    }
                } else if let sigmaArray = args[2].arrayValue {
                    // Check if 1D or 2D
                    if sigmaArray.first?.arrayValue != nil {
                        // 2D array: full covariance matrix
                        for i in 0..<min(n, sigmaArray.count) {
                            if let row = sigmaArray[i].arrayValue {
                                for j in 0..<min(n, row.count) {
                                    if let val = row[j].numberValue {
                                        sigmaMatrix[i * n + j] = val
                                    }
                                }
                            }
                        }
                    } else {
                        // 1D array: diagonal covariance (variances only)
                        let variances = sigmaArray.compactMap { $0.numberValue }
                        for i in 0..<min(n, variances.count) {
                            sigmaMatrix[i * n + i] = variances[i]
                        }
                    }
                }
            }

            // Compute Cholesky decomposition of sigma: Σ = LL'
            // We need L⁻¹, so we'll use dpotrf to get L, then cblas_dtrsm to solve
            var nChol = __CLPK_integer(n)
            var ldaChol = __CLPK_integer(n)
            var infoChol: __CLPK_integer = 0

            // Cholesky factorization (lower triangular)
            dpotrf_(UnsafeMutablePointer(mutating: ("L" as NSString).utf8String),
                    &nChol, &sigmaMatrix, &ldaChol, &infoChol)

            guard infoChol == 0 else {
                // Cholesky failed - sigma is not positive definite
                return .nil
            }

            // Transform y: y* = L⁻¹y (solve L * y* = y)
            var yTransformed = endog
            let alpha = 1.0
            cblas_dtrsm(CblasColMajor, CblasLeft, CblasLower, CblasNoTrans, CblasNonUnit,
                        __CLPK_integer(n), 1, alpha, sigmaMatrix, __CLPK_integer(n),
                        &yTransformed, __CLPK_integer(n))

            // Transform X: X* = L⁻¹X (solve L * X* = X for each column)
            // Flatten X to column-major for LAPACK
            var XFlat = [Double](repeating: 0.0, count: n * k)
            for j in 0..<k {
                for i in 0..<n {
                    XFlat[j * n + i] = exog[i][j]
                }
            }

            cblas_dtrsm(CblasColMajor, CblasLeft, CblasLower, CblasNoTrans, CblasNonUnit,
                        __CLPK_integer(n), __CLPK_integer(k), alpha, sigmaMatrix, __CLPK_integer(n),
                        &XFlat, __CLPK_integer(n))

            // Convert transformed X back to 2D array
            var XTransformed: [[Double]] = []
            for i in 0..<n {
                var row = [Double](repeating: 0.0, count: k)
                for j in 0..<k {
                    row[j] = XFlat[j * n + i]
                }
                XTransformed.append(row)
            }

            // Now perform OLS on transformed data
            // Solve X* * β = y* using LAPACK dgels
            var m = __CLPK_integer(n)
            var nCols = __CLPK_integer(k)
            var nrhsOLS = __CLPK_integer(1)
            var lda = __CLPK_integer(n)
            var ldb = __CLPK_integer(max(n, k))
            var info: __CLPK_integer = 0

            var yCopy = yTransformed
            if k > n {
                yCopy.append(contentsOf: [Double](repeating: 0.0, count: k - n))
            }

            // Query optimal workspace
            var workQuery = [Double](repeating: 0.0, count: 1)
            var lwork: __CLPK_integer = -1
            dgels_(UnsafeMutablePointer(mutating: ("N" as NSString).utf8String),
                   &m, &nCols, &nrhsOLS, &XFlat, &lda, &yCopy, &ldb, &workQuery, &lwork, &info)

            lwork = __CLPK_integer(workQuery[0])
            var work = [Double](repeating: 0.0, count: Int(lwork))

            dgels_(UnsafeMutablePointer(mutating: ("N" as NSString).utf8String),
                   &m, &nCols, &nrhsOLS, &XFlat, &lda, &yCopy, &ldb, &work, &lwork, &info)

            guard info == 0 else {
                return .nil
            }

            // Extract parameters
            let params = Array(yCopy.prefix(k))

            // Compute fitted values and residuals using ORIGINAL data
            var fittedValues = [Double](repeating: 0.0, count: n)
            var residuals = [Double](repeating: 0.0, count: n)

            for i in 0..<n {
                var fitted = 0.0
                for j in 0..<k {
                    fitted += exog[i][j] * params[j]
                }
                fittedValues[i] = fitted
                residuals[i] = endog[i] - fitted
            }

            // Compute statistics using original data
            let yMean = endog.reduce(0, +) / Double(n)

            var ssr = 0.0
            var ess = 0.0
            var tss = 0.0

            for i in 0..<n {
                ssr += residuals[i] * residuals[i]
                ess += (fittedValues[i] - yMean) * (fittedValues[i] - yMean)
                tss += (endog[i] - yMean) * (endog[i] - yMean)
            }

            let dfModel = k - 1
            let dfResid = n - k

            let rsquared = tss > 0 ? 1.0 - ssr / tss : 0.0
            let rsquaredAdj = dfResid > 0 ? 1.0 - (1.0 - rsquared) * Double(n - 1) / Double(dfResid) : 0.0

            let mse = dfResid > 0 ? ssr / Double(dfResid) : 0.0

            // Standard errors: For GLS, we need (X'Σ⁻¹X)⁻¹
            // Since we transformed X* = L⁻¹X, we have X*'X* = X'(L⁻¹)'L⁻¹X = X'Σ⁻¹X
            // So we compute (X*'X*)⁻¹ using the transformed X
            var XtX = [Double](repeating: 0.0, count: k * k)
            for i in 0..<k {
                for j in 0..<k {
                    var sum = 0.0
                    for obs in 0..<n {
                        sum += XTransformed[obs][i] * XTransformed[obs][j]
                    }
                    XtX[j * k + i] = sum
                }
            }

            var kInv = __CLPK_integer(k)
            var ldaXtX = __CLPK_integer(k)
            var infoInv: __CLPK_integer = 0

            dpotrf_(UnsafeMutablePointer(mutating: ("U" as NSString).utf8String),
                    &kInv, &XtX, &ldaXtX, &infoInv)

            var XtXInv = XtX
            if infoInv == 0 {
                dpotri_(UnsafeMutablePointer(mutating: ("U" as NSString).utf8String),
                        &kInv, &XtXInv, &ldaXtX, &infoInv)

                for i in 0..<k {
                    for j in i+1..<k {
                        XtXInv[i * k + j] = XtXInv[j * k + i]
                    }
                }
            }

            // Standard errors: sqrt(diag((X*'X*)⁻¹) * MSE)
            var bse = [Double](repeating: 0.0, count: k)
            if infoInv == 0 {
                for i in 0..<k {
                    bse[i] = sqrt(XtXInv[i * k + i] * mse)
                }
            }

            // t-values and p-values
            var tvalues = [Double](repeating: 0.0, count: k)
            var pvalues = [Double](repeating: 1.0, count: k)

            for i in 0..<k {
                if bse[i] > 0 {
                    tvalues[i] = params[i] / bse[i]
                    pvalues[i] = 2.0 * (1.0 - tCDF(abs(tvalues[i]), Double(dfResid)))
                }
            }

            // F-statistic
            var fvalue = 0.0
            var f_pvalue = 1.0
            if dfModel > 0 && dfResid > 0 && ssr > 0 {
                fvalue = (ess / Double(dfModel)) / (ssr / Double(dfResid))
                f_pvalue = 1.0 - fCDF(fvalue, Double(dfModel), Double(dfResid))
            }

            // Log-likelihood (assuming normal errors)
            let llf = -Double(n) / 2.0 * (log(2.0 * Double.pi) + log(ssr / Double(n)) + 1.0)

            // Information criteria
            let aic = -2.0 * llf + 2.0 * Double(k)
            let bic = -2.0 * llf + log(Double(n)) * Double(k)

            // Confidence intervals
            let tCrit = tPPF(0.975, Double(dfResid))
            var confInt: [[Double]] = []
            for i in 0..<k {
                confInt.append([params[i] - tCrit * bse[i], params[i] + tCrit * bse[i]])
            }

            // Hat matrix diagonal using transformed X
            var hatDiag = [Double](repeating: 0.0, count: n)
            if infoInv == 0 {
                for i in 0..<n {
                    var h_ii = 0.0
                    for j in 0..<k {
                        var sum = 0.0
                        for l in 0..<k {
                            sum += XtXInv[l * k + j] * XTransformed[i][l]
                        }
                        h_ii += XTransformed[i][j] * sum
                    }
                    hatDiag[i] = h_ii
                }
            }

            // Studentized residuals
            var residStudentized = [Double](repeating: 0.0, count: n)
            let rmse = sqrt(mse)
            for i in 0..<n {
                let denom = rmse * sqrt(max(1e-15, 1.0 - hatDiag[i]))
                residStudentized[i] = denom > 1e-15 ? residuals[i] / denom : 0.0
            }

            // Cook's distance
            var cooksDistance = [Double](repeating: 0.0, count: n)
            if k > 0 && mse > 0 {
                for i in 0..<n {
                    let h_ii = hatDiag[i]
                    if h_ii < 1.0 - 1e-10 {
                        let e2 = residuals[i] * residuals[i]
                        cooksDistance[i] = (e2 / (Double(k) * mse)) * (h_ii / ((1.0 - h_ii) * (1.0 - h_ii)))
                    }
                }
            }

            // DFFITS
            var dffits = [Double](repeating: 0.0, count: n)
            for i in 0..<n {
                let h_ii = hatDiag[i]
                if h_ii < 1.0 - 1e-10 {
                    dffits[i] = residStudentized[i] * sqrt(h_ii / (1.0 - h_ii))
                }
            }

            // Condition number using transformed X'X
            var conditionNumber = Double.infinity
            var eigenvalues = [Double](repeating: 0.0, count: k)

            if k > 0 {
                var XtXCopy = [Double](repeating: 0.0, count: k * k)
                for i in 0..<k {
                    for j in 0..<k {
                        var sum = 0.0
                        for obs in 0..<n {
                            sum += XTransformed[obs][i] * XTransformed[obs][j]
                        }
                        XtXCopy[j * k + i] = sum
                    }
                }

                var kEig = __CLPK_integer(k)
                var ldaEig = __CLPK_integer(k)
                var eigenW = [Double](repeating: 0.0, count: k)
                var workEig = [Double](repeating: 0.0, count: 1)
                var lworkEig: __CLPK_integer = -1
                var infoEig: __CLPK_integer = 0

                dsyev_(UnsafeMutablePointer(mutating: ("V" as NSString).utf8String),
                       UnsafeMutablePointer(mutating: ("U" as NSString).utf8String),
                       &kEig, &XtXCopy, &ldaEig, &eigenW, &workEig, &lworkEig, &infoEig)

                lworkEig = __CLPK_integer(workEig[0])
                workEig = [Double](repeating: 0.0, count: Int(lworkEig))

                dsyev_(UnsafeMutablePointer(mutating: ("V" as NSString).utf8String),
                       UnsafeMutablePointer(mutating: ("U" as NSString).utf8String),
                       &kEig, &XtXCopy, &ldaEig, &eigenW, &workEig, &lworkEig, &infoEig)

                if infoEig == 0 {
                    eigenvalues = eigenW.sorted(by: >)
                    let maxEig = eigenvalues.first ?? 1.0
                    let minEig = eigenvalues.last ?? 1.0
                    if minEig > 1e-15 {
                        conditionNumber = sqrt(maxEig / minEig)
                    }
                }
            }

            // HC standard errors (using original X)
            var bseHC0 = [Double](repeating: 0.0, count: k)
            var bseHC1 = [Double](repeating: 0.0, count: k)
            var bseHC2 = [Double](repeating: 0.0, count: k)
            var bseHC3 = [Double](repeating: 0.0, count: k)

            if infoInv == 0 && n > k {
                func computeHCStdErrors(omega: [Double]) -> [Double] {
                    var XtOmegaX = [Double](repeating: 0.0, count: k * k)
                    for i in 0..<k {
                        for j in 0..<k {
                            var sum = 0.0
                            for obs in 0..<n {
                                sum += XTransformed[obs][i] * omega[obs] * XTransformed[obs][j]
                            }
                            XtOmegaX[j * k + i] = sum
                        }
                    }

                    var temp = [Double](repeating: 0.0, count: k * k)
                    for i in 0..<k {
                        for j in 0..<k {
                            var sum = 0.0
                            for l in 0..<k {
                                sum += XtOmegaX[l * k + i] * XtXInv[j * k + l]
                            }
                            temp[j * k + i] = sum
                        }
                    }

                    var cov = [Double](repeating: 0.0, count: k * k)
                    for i in 0..<k {
                        for j in 0..<k {
                            var sum = 0.0
                            for l in 0..<k {
                                sum += XtXInv[l * k + i] * temp[j * k + l]
                            }
                            cov[j * k + i] = sum
                        }
                    }

                    var se = [Double](repeating: 0.0, count: k)
                    for i in 0..<k {
                        se[i] = sqrt(max(0.0, cov[i * k + i]))
                    }
                    return se
                }

                let omegaHC0 = residuals.map { $0 * $0 }
                bseHC0 = computeHCStdErrors(omega: omegaHC0)

                let hc1Factor = Double(n) / Double(n - k)
                bseHC1 = bseHC0.map { $0 * sqrt(hc1Factor) }

                var omegaHC2 = [Double](repeating: 0.0, count: n)
                for i in 0..<n {
                    let denom = max(1e-15, 1.0 - hatDiag[i])
                    omegaHC2[i] = residuals[i] * residuals[i] / denom
                }
                bseHC2 = computeHCStdErrors(omega: omegaHC2)

                var omegaHC3 = [Double](repeating: 0.0, count: n)
                for i in 0..<n {
                    let denom = max(1e-15, 1.0 - hatDiag[i])
                    omegaHC3[i] = residuals[i] * residuals[i] / (denom * denom)
                }
                bseHC3 = computeHCStdErrors(omega: omegaHC3)
            }

            return .table([
                "params": .array(params.map { .number($0) }),
                "bse": .array(bse.map { .number($0) }),
                "tvalues": .array(tvalues.map { .number($0) }),
                "pvalues": .array(pvalues.map { .number($0) }),
                "conf_int": .array(confInt.map { row in
                    .array(row.map { .number($0) })
                }),

                "bse_hc0": .array(bseHC0.map { .number($0) }),
                "bse_hc1": .array(bseHC1.map { .number($0) }),
                "bse_hc2": .array(bseHC2.map { .number($0) }),
                "bse_hc3": .array(bseHC3.map { .number($0) }),

                "resid": .array(residuals.map { .number($0) }),
                "fittedvalues": .array(fittedValues.map { .number($0) }),
                "hat_diag": .array(hatDiag.map { .number($0) }),
                "resid_studentized": .array(residStudentized.map { .number($0) }),
                "cooks_distance": .array(cooksDistance.map { .number($0) }),
                "dffits": .array(dffits.map { .number($0) }),

                "rsquared": .number(rsquared),
                "rsquared_adj": .number(rsquaredAdj),
                "fvalue": .number(fvalue),
                "f_pvalue": .number(f_pvalue),
                "llf": .number(llf),
                "aic": .number(aic),
                "bic": .number(bic),
                "ssr": .number(ssr),
                "ess": .number(ess),
                "mse_resid": .number(mse),
                "centered_tss": .number(tss),
                "nobs": .number(Double(n)),
                "df_model": .number(Double(dfModel)),
                "df_resid": .number(Double(dfResid)),

                "condition_number": .number(conditionNumber),
                "eigenvalues": .array(eigenvalues.map { .number($0) })
            ])
        }
    }

    // MARK: - GLM Callbacks

    private static func registerGLMCallbacks(in engine: LuaEngine) {
        // GLM fit callback - Generalized Linear Models using IRLS
        // Supports: gaussian, binomial, poisson, gamma families
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
            var k = 0

            if args.count > 1, let exogTable = args[1].arrayValue {
                if exogTable.first?.arrayValue != nil {
                    for row in exogTable {
                        if let rowArray = row.arrayValue {
                            let rowValues = rowArray.compactMap { $0.numberValue }
                            exog.append(rowValues)
                        }
                    }
                    k = exog.first?.count ?? 0
                } else {
                    let values = exogTable.compactMap { $0.numberValue }
                    for val in values {
                        exog.append([val])
                    }
                    k = 1
                }
            }

            if exog.isEmpty {
                exog = Array(repeating: [1.0], count: n)
                k = 1
            }

            guard exog.count == n else {
                return .nil
            }

            // Extract family
            var family = "gaussian"
            if args.count > 2, let familyStr = args[2].stringValue {
                family = familyStr.lowercased()
            }

            // Extract link (or use canonical)
            var link: String
            if args.count > 3, let linkStr = args[3].stringValue {
                link = linkStr.lowercased()
            } else {
                // Canonical links
                switch family {
                case "gaussian": link = "identity"
                case "binomial": link = "logit"
                case "poisson": link = "log"
                case "gamma": link = "inverse"
                default: link = "identity"
                }
            }

            // Extract maxiter and tolerance
            var maxiter = 100
            if args.count > 4, let maxiterVal = args[4].numberValue {
                maxiter = Int(maxiterVal)
            }

            var tol = 1e-8
            if args.count > 5, let tolVal = args[5].numberValue {
                tol = tolVal
            }

            // IRLS Algorithm for GLM
            // Initialize mu (mean response)
            var mu = [Double](repeating: 0.0, count: n)
            var eta = [Double](repeating: 0.0, count: n)

            // Initialize mu based on family
            for i in 0..<n {
                switch family {
                case "binomial":
                    // Bound between 0.001 and 0.999
                    mu[i] = (endog[i] + 0.5) / 2.0
                    mu[i] = max(0.001, min(0.999, mu[i]))
                case "poisson":
                    mu[i] = max(endog[i], 0.1)
                case "gamma":
                    mu[i] = max(endog[i], 0.1)
                default:  // gaussian
                    mu[i] = endog[i]
                }
            }

            // Convert mu to eta using link function
            for i in 0..<n {
                eta[i] = applyLink(mu[i], link: link)
            }

            // Initialize beta
            var beta = [Double](repeating: 0.0, count: k)

            var converged = false
            var iterations = 0

            // IRLS main loop
            for iter in 0..<maxiter {
                iterations = iter + 1

                // Compute working weights and working response
                var weights = [Double](repeating: 0.0, count: n)
                var z = [Double](repeating: 0.0, count: n)  // working response

                for i in 0..<n {
                    // Derivative of inverse link (dmu/deta)
                    let dmuDeta = inverseLinkDerivative(eta[i], link: link)

                    // Variance function V(mu)
                    let variance = varianceFunction(mu[i], family: family)

                    // Weight = (dmu/deta)^2 / V(mu)
                    if variance > 1e-10 && dmuDeta.isFinite {
                        weights[i] = (dmuDeta * dmuDeta) / variance
                    } else {
                        weights[i] = 1e-10
                    }

                    // Working response: z = eta + (y - mu) / (dmu/deta)
                    if abs(dmuDeta) > 1e-10 {
                        z[i] = eta[i] + (endog[i] - mu[i]) / dmuDeta
                    } else {
                        z[i] = eta[i]
                    }
                }

                // Solve weighted least squares: (X'WX)^-1 X'Wz
                let betaNew = solveWLS(exog: exog, y: z, weights: weights, n: n, k: k)

                guard let newBeta = betaNew else {
                    return .nil  // WLS failed
                }

                // Check convergence
                var maxChange = 0.0
                for j in 0..<k {
                    let change = abs(newBeta[j] - beta[j])
                    if change > maxChange {
                        maxChange = change
                    }
                }

                beta = newBeta

                // Update eta and mu
                for i in 0..<n {
                    var etaNew = 0.0
                    for j in 0..<k {
                        etaNew += exog[i][j] * beta[j]
                    }
                    eta[i] = etaNew
                    mu[i] = applyInverseLink(eta[i], link: link, family: family)
                }

                if maxChange < tol {
                    converged = true
                    break
                }
            }

            // Compute residuals
            var residResponse = [Double](repeating: 0.0, count: n)
            for i in 0..<n {
                residResponse[i] = endog[i] - mu[i]
            }

            // Compute deviance
            var deviance = 0.0
            var nullDeviance = 0.0
            let yMean = endog.reduce(0, +) / Double(n)

            for i in 0..<n {
                deviance += unitDeviance(y: endog[i], mu: mu[i], family: family)
                nullDeviance += unitDeviance(y: endog[i], mu: yMean, family: family)
            }

            // Compute Pearson chi-squared
            var pearsonChi2 = 0.0
            for i in 0..<n {
                let variance = varianceFunction(mu[i], family: family)
                if variance > 1e-10 {
                    pearsonChi2 += (endog[i] - mu[i]) * (endog[i] - mu[i]) / variance
                }
            }

            // Compute standard errors using Fisher information
            let bse = computeGLMStandardErrors(exog: exog, mu: mu, family: family, link: link, n: n, k: k)

            // Compute z-values and p-values
            var zvalues = [Double](repeating: 0.0, count: k)
            var pvalues = [Double](repeating: 1.0, count: k)

            for j in 0..<k {
                if bse[j] > 1e-10 {
                    zvalues[j] = beta[j] / bse[j]
                    // Two-tailed p-value from standard normal
                    pvalues[j] = 2.0 * (1.0 - standardNormalCDF(abs(zvalues[j])))
                }
            }

            // Compute log-likelihood
            let llf = logLikelihood(y: endog, mu: mu, family: family, n: n)

            // Degrees of freedom
            let dfModel = k - 1
            let dfResid = n - k

            // Information criteria
            let aic = -2.0 * llf + 2.0 * Double(k)
            let bic = -2.0 * llf + Double(k) * log(Double(n))

            return .table([
                "params": .array(beta.map { .number($0) }),
                "bse": .array(bse.map { .number($0) }),
                "zvalues": .array(zvalues.map { .number($0) }),
                "pvalues": .array(pvalues.map { .number($0) }),

                "mu": .array(mu.map { .number($0) }),
                "eta": .array(eta.map { .number($0) }),
                "resid_response": .array(residResponse.map { .number($0) }),

                "deviance": .number(deviance),
                "null_deviance": .number(nullDeviance),
                "pearson_chi2": .number(pearsonChi2),
                "llf": .number(llf),
                "aic": .number(aic),
                "bic": .number(bic),

                "nobs": .number(Double(n)),
                "df_model": .number(Double(dfModel)),
                "df_resid": .number(Double(dfResid)),

                "converged": .bool(converged),
                "iterations": .number(Double(iterations))
            ])
        }
    }

    // MARK: - GLM Helper Functions

    /// Apply link function: eta = g(mu)
    private static func applyLink(_ mu: Double, link: String) -> Double {
        switch link {
        case "identity":
            return mu
        case "logit":
            let p = max(1e-10, min(1.0 - 1e-10, mu))
            return log(p / (1.0 - p))
        case "log":
            return log(max(1e-10, mu))
        case "inverse":
            return 1.0 / max(1e-10, mu)
        case "probit":
            let p = max(1e-10, min(1.0 - 1e-10, mu))
            return erfinv(2.0 * p - 1.0) * sqrt(2.0)
        default:
            return mu
        }
    }

    /// Apply inverse link function: mu = g^-1(eta)
    private static func applyInverseLink(_ eta: Double, link: String, family: String) -> Double {
        var mu: Double
        switch link {
        case "identity":
            mu = eta
        case "logit":
            let expEta = exp(min(700, max(-700, eta)))  // Prevent overflow
            mu = expEta / (1.0 + expEta)
        case "log":
            mu = exp(min(700, eta))
        case "inverse":
            mu = 1.0 / eta
        case "probit":
            mu = 0.5 * (1.0 + erf(eta / sqrt(2.0)))
        default:
            mu = eta
        }

        // Apply family-specific bounds
        switch family {
        case "binomial":
            mu = max(1e-10, min(1.0 - 1e-10, mu))
        case "poisson", "gamma":
            mu = max(1e-10, mu)
        default:
            break
        }

        return mu
    }

    /// Derivative of inverse link: dmu/deta
    private static func inverseLinkDerivative(_ eta: Double, link: String) -> Double {
        switch link {
        case "identity":
            return 1.0
        case "logit":
            let expEta = exp(min(700, max(-700, eta)))
            let p = expEta / (1.0 + expEta)
            return p * (1.0 - p)
        case "log":
            return exp(min(700, eta))
        case "inverse":
            return -1.0 / (eta * eta)
        case "probit":
            return exp(-eta * eta / 2.0) / sqrt(2.0 * .pi)
        default:
            return 1.0
        }
    }

    /// Variance function V(mu) for different families
    private static func varianceFunction(_ mu: Double, family: String) -> Double {
        switch family {
        case "gaussian":
            return 1.0
        case "binomial":
            let p = max(1e-10, min(1.0 - 1e-10, mu))
            return p * (1.0 - p)
        case "poisson":
            return max(1e-10, mu)
        case "gamma":
            return mu * mu
        default:
            return 1.0
        }
    }

    /// Unit deviance for different families
    private static func unitDeviance(y: Double, mu: Double, family: String) -> Double {
        let muBound = max(1e-10, mu)

        switch family {
        case "gaussian":
            return (y - mu) * (y - mu)
        case "binomial":
            let yBound = max(1e-10, min(1.0 - 1e-10, y))
            let muBoundBinom = max(1e-10, min(1.0 - 1e-10, mu))
            var dev = 0.0
            if y > 0 {
                dev += 2.0 * y * log(yBound / muBoundBinom)
            }
            if y < 1 {
                dev += 2.0 * (1.0 - y) * log((1.0 - yBound) / (1.0 - muBoundBinom))
            }
            return dev
        case "poisson":
            var dev = 0.0
            if y > 0 {
                dev = 2.0 * (y * log(y / muBound) - (y - muBound))
            } else {
                dev = 2.0 * muBound
            }
            return dev
        case "gamma":
            return 2.0 * ((y - muBound) / muBound - log(max(1e-10, y) / muBound))
        default:
            return (y - mu) * (y - mu)
        }
    }

    /// Log-likelihood for different families
    private static func logLikelihood(y: [Double], mu: [Double], family: String, n: Int) -> Double {
        var llf = 0.0

        switch family {
        case "gaussian":
            // Assume unit variance
            var ssr = 0.0
            for i in 0..<n {
                ssr += (y[i] - mu[i]) * (y[i] - mu[i])
            }
            llf = -Double(n) / 2.0 * log(2.0 * .pi) - Double(n) / 2.0 * log(ssr / Double(n)) - Double(n) / 2.0
        case "binomial":
            for i in 0..<n {
                let p = max(1e-10, min(1.0 - 1e-10, mu[i]))
                if y[i] > 0 {
                    llf += y[i] * log(p)
                }
                if y[i] < 1 {
                    llf += (1.0 - y[i]) * log(1.0 - p)
                }
            }
        case "poisson":
            for i in 0..<n {
                let muBound = max(1e-10, mu[i])
                llf += y[i] * log(muBound) - muBound - lgamma(y[i] + 1.0)
            }
        case "gamma":
            // Assume shape = 1 (exponential)
            for i in 0..<n {
                let muBound = max(1e-10, mu[i])
                llf += -y[i] / muBound - log(muBound)
            }
        default:
            var ssr = 0.0
            for i in 0..<n {
                ssr += (y[i] - mu[i]) * (y[i] - mu[i])
            }
            llf = -Double(n) / 2.0 * log(2.0 * .pi * ssr / Double(n)) - Double(n) / 2.0
        }

        return llf
    }

    /// Solve weighted least squares using LAPACK
    private static func solveWLS(exog: [[Double]], y: [Double], weights: [Double], n: Int, k: Int) -> [Double]? {
        // Transform: X* = sqrt(W) * X, y* = sqrt(W) * y
        var yTransformed = [Double](repeating: 0.0, count: n)
        var XTransformed = [[Double]](repeating: [Double](repeating: 0.0, count: k), count: n)

        for i in 0..<n {
            let sqrtW = sqrt(max(1e-10, weights[i]))
            yTransformed[i] = y[i] * sqrtW
            for j in 0..<k {
                XTransformed[i][j] = exog[i][j] * sqrtW
            }
        }

        // Flatten X to column-major order
        var XFlat = [Double](repeating: 0.0, count: n * k)
        for j in 0..<k {
            for i in 0..<n {
                XFlat[j * n + i] = XTransformed[i][j]
            }
        }

        var yCopy = yTransformed
        if k > n {
            yCopy.append(contentsOf: [Double](repeating: 0.0, count: k - n))
        }

        var m = __CLPK_integer(n)
        var nCols = __CLPK_integer(k)
        var nrhs = __CLPK_integer(1)
        var lda = __CLPK_integer(n)
        var ldb = __CLPK_integer(max(n, k))
        var info: __CLPK_integer = 0

        // Query workspace
        var workQuery = [Double](repeating: 0.0, count: 1)
        var lwork: __CLPK_integer = -1
        dgels_(UnsafeMutablePointer(mutating: ("N" as NSString).utf8String),
               &m, &nCols, &nrhs, &XFlat, &lda, &yCopy, &ldb, &workQuery, &lwork, &info)

        lwork = __CLPK_integer(workQuery[0])
        var work = [Double](repeating: 0.0, count: Int(lwork))

        // Solve
        dgels_(UnsafeMutablePointer(mutating: ("N" as NSString).utf8String),
               &m, &nCols, &nrhs, &XFlat, &lda, &yCopy, &ldb, &work, &lwork, &info)

        if info != 0 {
            return nil
        }

        return Array(yCopy.prefix(k))
    }

    /// Compute GLM standard errors from Fisher information matrix
    private static func computeGLMStandardErrors(exog: [[Double]], mu: [Double], family: String, link: String, n: Int, k: Int) -> [Double] {
        // Fisher information: I = X' W X where W = diag((dmu/deta)^2 / V(mu))
        // Standard errors = sqrt(diag((X' W X)^-1))

        // Compute weights
        var weights = [Double](repeating: 0.0, count: n)
        for i in 0..<n {
            let eta = applyLink(mu[i], link: link)
            let dmuDeta = inverseLinkDerivative(eta, link: link)
            let variance = varianceFunction(mu[i], family: family)
            if variance > 1e-10 {
                weights[i] = (dmuDeta * dmuDeta) / variance
            } else {
                weights[i] = 1e-10
            }
        }

        // Compute X' W X
        var XtWX = [Double](repeating: 0.0, count: k * k)
        for j1 in 0..<k {
            for j2 in 0..<k {
                var sum = 0.0
                for i in 0..<n {
                    sum += exog[i][j1] * weights[i] * exog[i][j2]
                }
                XtWX[j1 * k + j2] = sum
            }
        }

        // Invert X' W X using LAPACK
        var invXtWX = XtWX
        var ipiv = [__CLPK_integer](repeating: 0, count: k)
        var info: __CLPK_integer = 0

        // LU factorization
        var m1 = __CLPK_integer(k)
        var n1 = __CLPK_integer(k)
        var lda1 = __CLPK_integer(k)
        dgetrf_(&m1, &n1, &invXtWX, &lda1, &ipiv, &info)
        if info != 0 {
            return [Double](repeating: 0.0, count: k)
        }

        // Query workspace for inversion
        var workQuery = [Double](repeating: 0.0, count: 1)
        var lwork: __CLPK_integer = -1
        var n2 = __CLPK_integer(k)
        var lda2 = __CLPK_integer(k)
        dgetri_(&n2, &invXtWX, &lda2, &ipiv, &workQuery, &lwork, &info)

        lwork = __CLPK_integer(workQuery[0])
        var work = [Double](repeating: 0.0, count: Int(lwork))

        // Invert
        var n3 = __CLPK_integer(k)
        var lda3 = __CLPK_integer(k)
        dgetri_(&n3, &invXtWX, &lda3, &ipiv, &work, &lwork, &info)
        if info != 0 {
            return [Double](repeating: 0.0, count: k)
        }

        // Extract diagonal elements (standard errors)
        var bse = [Double](repeating: 0.0, count: k)
        for j in 0..<k {
            let variance = invXtWX[j * k + j]
            bse[j] = variance > 0 ? sqrt(variance) : 0.0
        }

        return bse
    }

    /// Standard normal CDF
    private static func standardNormalCDF(_ x: Double) -> Double {
        return 0.5 * (1.0 + erf(x / sqrt(2.0)))
    }
}
