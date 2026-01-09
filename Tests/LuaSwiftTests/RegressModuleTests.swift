//
//  RegressModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class RegressModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installModules(in: engine)
            try engine.run("luaswift.extend_stdlib()")
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Namespace Tests

    func testRegressNamespaceExists() throws {
        let result = try engine.evaluate("return type(luaswift.regress)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathRegressNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.regress)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testOLSFunctionExists() throws {
        let result = try engine.evaluate("return type(math.regress.OLS)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testWLSFunctionExists() throws {
        let result = try engine.evaluate("return type(math.regress.WLS)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testAddConstantFunctionExists() throws {
        let result = try engine.evaluate("return type(math.regress.add_constant)")
        XCTAssertEqual(result.stringValue, "function")
    }

    // MARK: - add_constant Tests

    func testAddConstantTo1DArray() throws {
        // Add constant to 1D array should prepend 1s
        // Result should be {{1, 1}, {1, 2}, {1, 3}}
        let result = try engine.evaluate("""
            local X = {1, 2, 3}
            local X_with_const = math.regress.add_constant(X)
            -- Return as a flat table for easier testing
            return {
                X_with_const[1][1], X_with_const[1][2],
                X_with_const[2][1], X_with_const[2][2]
            }
        """)
        let values = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(values, [1.0, 1.0, 1.0, 2.0])
    }

    func testAddConstantTo2DArray() throws {
        // Add constant to 2D array should prepend 1s column
        let result = try engine.evaluate("""
            local X = {{1, 2}, {3, 4}, {5, 6}}
            local X_with_const = math.regress.add_constant(X)
            return {X_with_const[1][1], X_with_const[2][1], #X_with_const[1]}
        """)
        let values = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(values[0], 1.0)  // constant column
        XCTAssertEqual(values[1], 1.0)  // constant column
        XCTAssertEqual(values[2], 3.0)  // now 3 columns
    }

    // MARK: - OLS Basic Tests

    func testOLSSimpleLinearRegression() throws {
        // Perfect linear fit: y = 2 + 3*x
        // x = {1, 2, 3, 4, 5}, y = {5, 8, 11, 14, 17}
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {results.params[1], results.params[2]}
        """)
        let params = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(params[0], 2.0, accuracy: 1e-10)  // intercept
        XCTAssertEqual(params[1], 3.0, accuracy: 1e-10)  // slope
    }

    func testOLSRSquaredPerfectFit() throws {
        // Perfect linear fit should have R² = 1
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return results.rsquared
        """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testOLSWithNoise() throws {
        // Linear relationship with some noise
        // y ≈ 1 + 2*x with noise
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}  -- approx 1 + 2*x
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {results.params[1], results.params[2], results.rsquared}
        """)
        let values = result.arrayValue!.compactMap { $0.numberValue }
        // Intercept should be close to 1
        XCTAssertEqual(values[0], 1.0, accuracy: 0.5)
        // Slope should be close to 2
        XCTAssertEqual(values[1], 2.0, accuracy: 0.1)
        // R² should be high but not perfect
        XCTAssertGreaterThan(values[2], 0.99)
    }

    // MARK: - Results Object Properties

    func testResultsNobs() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return results.nobs
        """)
        XCTAssertEqual(result.numberValue!, 5.0)
    }

    func testResultsDfResid() throws {
        // df_resid = n - k where k is number of regressors (including constant)
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return results.df_resid
        """)
        XCTAssertEqual(result.numberValue!, 3.0)  // 5 - 2 = 3
    }

    func testResultsDfModel() throws {
        // df_model = k - 1 (excluding constant)
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return results.df_model
        """)
        XCTAssertEqual(result.numberValue!, 1.0)
    }

    func testResultsBse() throws {
        // Standard errors should exist
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return #results.bse
        """)
        XCTAssertEqual(result.numberValue!, 2.0)  // 2 standard errors (intercept + slope)
    }

    func testResultsTvalues() throws {
        // t-values = params / bse
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return #results.tvalues
        """)
        XCTAssertEqual(result.numberValue!, 2.0)
    }

    func testResultsPvalues() throws {
        // p-values should exist and be between 0 and 1
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local p1, p2 = results.pvalues[1], results.pvalues[2]
            return {(p1 >= 0 and p1 <= 1), (p2 >= 0 and p2 <= 1)}
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testResultsResid() throws {
        // Residuals for perfect fit should be near zero
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local max_resid = 0
            for _, r in ipairs(results.resid) do
                if math.abs(r) > max_resid then max_resid = math.abs(r) end
            end
            return max_resid
        """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testResultsFittedValues() throws {
        // Fitted values for perfect fit should equal y
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {results.fittedvalues[1], results.fittedvalues[3], results.fittedvalues[5]}
        """)
        let fitted = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(fitted[0], 5.0, accuracy: 1e-10)
        XCTAssertEqual(fitted[1], 11.0, accuracy: 1e-10)
        XCTAssertEqual(fitted[2], 17.0, accuracy: 1e-10)
    }

    // MARK: - Results Methods

    func testResultsSummary() throws {
        // Summary should return a string
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return type(results:summary())
        """)
        XCTAssertEqual(result.stringValue, "string")
    }

    func testResultsSummaryContainsRSquared() throws {
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local summary = results:summary()
            return string.find(summary, "R%-squared") ~= nil
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testResultsPredict() throws {
        // Predict with new data
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- Predict for x = 6 (should be 2 + 3*6 = 20)
            local new_X = math.regress.add_constant({6})
            local pred = results:predict(new_X)
            return pred[1]
        """)
        XCTAssertEqual(result.numberValue!, 20.0, accuracy: 1e-10)
    }

    func testResultsPredictWithoutNewX() throws {
        // Predict without new X returns fitted values
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local pred = results:predict()
            return {pred[1], pred[5]}
        """)
        let pred = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(pred[0], 5.0, accuracy: 1e-10)
        XCTAssertEqual(pred[1], 17.0, accuracy: 1e-10)
    }

    func testResultsConfInt() throws {
        // Confidence intervals should be 2D array [lower, upper] for each param
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local ci = results:conf_int(0.05)
            -- Check that lower < param < upper for each parameter
            local valid1 = ci[1][1] < results.params[1] and results.params[1] < ci[1][2]
            local valid2 = ci[2][1] < results.params[2] and results.params[2] < ci[2][2]
            return {valid1, valid2}
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    // MARK: - WLS Tests

    func testWLSBasic() throws {
        // WLS with equal weights should equal OLS
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local weights = {1, 1, 1, 1, 1}
            local wls_model = math.regress.WLS(y, X, weights)
            local wls_results = wls_model:fit()
            return {wls_results.params[1], wls_results.params[2]}
        """)
        let params = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(params[0], 2.0, accuracy: 1e-10)
        XCTAssertEqual(params[1], 3.0, accuracy: 1e-10)
    }

    func testWLSWithVariableWeights() throws {
        // WLS with higher weights on certain observations
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            -- Higher weight on last observations
            local weights = {0.1, 0.1, 0.1, 1.0, 1.0}
            local wls_model = math.regress.WLS(y, X, weights)
            local wls_results = wls_model:fit()
            -- Should still be close to 2 and 3 for this perfect-fit data
            return {wls_results.params[1], wls_results.params[2]}
        """)
        let params = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(params[0], 2.0, accuracy: 1e-8)
        XCTAssertEqual(params[1], 3.0, accuracy: 1e-8)
    }

    // MARK: - Multiple Regression Tests

    func testOLSMultipleRegressors() throws {
        // y = 1 + 2*x1 + 3*x2
        let result = try engine.evaluate("""
            local y = {6, 11, 16, 12, 17}  -- 1 + 2*x1 + 3*x2
            local X = {
                {1, 1, 1},   -- const, x1=1, x2=1 -> y = 1 + 2 + 3 = 6
                {1, 2, 2},   -- const, x1=2, x2=2 -> y = 1 + 4 + 6 = 11
                {1, 3, 3},   -- const, x1=3, x2=3 -> y = 1 + 6 + 9 = 16
                {1, 1, 3},   -- const, x1=1, x2=3 -> y = 1 + 2 + 9 = 12
                {1, 2, 4}    -- const, x1=2, x2=4 -> y = 1 + 4 + 12 = 17
            }
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {results.params[1], results.params[2], results.params[3]}
        """)
        let params = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(params[0], 1.0, accuracy: 1e-10)  // intercept
        XCTAssertEqual(params[1], 2.0, accuracy: 1e-10)  // x1 coefficient
        XCTAssertEqual(params[2], 3.0, accuracy: 1e-10)  // x2 coefficient
    }

    // MARK: - Information Criteria Tests

    func testResultsAIC() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return type(results.aic)
        """)
        XCTAssertEqual(result.stringValue, "number")
    }

    func testResultsBIC() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return type(results.bic)
        """)
        XCTAssertEqual(result.stringValue, "number")
    }

    func testResultsLogLikelihood() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return type(results.llf)
        """)
        XCTAssertEqual(result.stringValue, "number")
    }

    // MARK: - F-statistic Tests

    func testResultsFValue() throws {
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- For perfect fit, F should be very large (or inf)
            return results.fvalue > 1000 or results.fvalue == math.huge
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testResultsFPValue() throws {
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- F p-value should be very small for significant relationship
            return results.f_pvalue
        """)
        XCTAssertLessThan(result.numberValue!, 0.01)
    }

    // MARK: - Edge Cases

    func testOLSMinimalObservations() throws {
        // Minimum observations for 2 parameters: need at least 3
        let result = try engine.evaluate("""
            local y = {5, 8, 11}
            local X = math.regress.add_constant({1, 2, 3})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return results.df_resid
        """)
        XCTAssertEqual(result.numberValue!, 1.0)  // 3 - 2 = 1
    }

    func testOLSRSquaredAdjusted() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- Adjusted R² should be <= R²
            return results.rsquared_adj <= results.rsquared
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Statsmodels Compatibility

    func testStatsmodelsAPIPattern() throws {
        // Verify the statsmodels-like API: OLS(y, X).fit() pattern
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            -- This should work like statsmodels
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- Model should be callable
            return {type(model.fit), type(results.summary)}
        """)
        let types = result.arrayValue!.compactMap { $0.stringValue }
        XCTAssertEqual(types[0], "function")
        XCTAssertEqual(types[1], "function")
    }

    // MARK: - Influence Diagnostics Tests

    func testHatDiagExists() throws {
        // Hat matrix diagonal (leverage) should be computed
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.hat_diag), #results.hat_diag}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 5.0)  // n observations
    }

    func testHatDiagSumEqualsK() throws {
        // Sum of hat diagonal should equal k (number of parameters)
        // This is a fundamental property: tr(H) = k
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local sum_h = 0
            for _, h in ipairs(results.hat_diag) do
                sum_h = sum_h + h
            end
            return sum_h
        """)
        // k = 2 (intercept + slope)
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testHatDiagBetween0And1() throws {
        // Hat diagonal values should be between 0 and 1
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local all_valid = true
            for _, h in ipairs(results.hat_diag) do
                if h < 0 or h > 1 then all_valid = false end
            end
            return all_valid
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testStudentizedResidualsExists() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.resid_studentized), #results.resid_studentized}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 5.0)
    }

    func testCooksDistanceExists() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.cooks_distance), #results.cooks_distance}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 5.0)
    }

    func testCooksDistanceNonNegative() throws {
        // Cook's distance should always be non-negative
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local all_valid = true
            for _, d in ipairs(results.cooks_distance) do
                if d < 0 then all_valid = false end
            end
            return all_valid
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testDFFITSExists() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.dffits), #results.dffits}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 5.0)
    }

    func testGetInfluenceMethod() throws {
        // get_influence() should return a table with all influence diagnostics
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local infl = results:get_influence()
            return {
                type(infl.hat_diag),
                type(infl.resid_studentized),
                type(infl.cooks_distance),
                type(infl.dffits)
            }
        """)
        let types = result.arrayValue!.compactMap { $0.stringValue }
        XCTAssertEqual(types, ["table", "table", "table", "table"])
    }

    // MARK: - Robust Standard Errors Tests (HC0-HC3)

    func testHC0StandardErrorsExist() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.bse_hc0), #results.bse_hc0}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 2.0)  // 2 parameters
    }

    func testHC1StandardErrorsExist() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.bse_hc1), #results.bse_hc1}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 2.0)
    }

    func testHC2StandardErrorsExist() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.bse_hc2), #results.bse_hc2}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 2.0)
    }

    func testHC3StandardErrorsExist() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.bse_hc3), #results.bse_hc3}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 2.0)
    }

    func testHC1GreaterThanHC0() throws {
        // HC1 applies n/(n-k) correction, should be >= HC0
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- HC1 should be larger than HC0 (it's HC0 * sqrt(n/(n-k)))
            return results.bse_hc1[1] >= results.bse_hc0[1]
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testHC3GreaterThanHC2() throws {
        // HC3 uses (1-h_ii)^2 in denominator vs (1-h_ii) for HC2
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- HC3 should generally be larger than HC2
            return results.bse_hc3[1] >= results.bse_hc2[1]
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testGetBseMethod() throws {
        // get_bse(cov_type) method should work
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local bse_default = results:get_bse()
            local bse_hc3 = results:get_bse("HC3")
            return {
                bse_default[1] == results.bse[1],
                bse_hc3[1] == results.bse_hc3[1]
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testGetBseAllCovTypes() throws {
        // Test all cov_type options
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local types = {"nonrobust", "HC0", "HC1", "HC2", "HC3"}
            local all_work = true
            for _, t in ipairs(types) do
                local se = results:get_bse(t)
                if type(se) ~= "table" or #se ~= 2 then
                    all_work = false
                end
            end
            return all_work
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Multicollinearity Diagnostics Tests

    func testConditionNumberExists() throws {
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.condition_number), results.condition_number > 0}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "number")
        XCTAssertTrue(values[1].boolValue!)
    }

    func testConditionNumberLowForWellConditioned() throws {
        // A simple design matrix should have low condition number
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- For this simple case, condition number should be reasonable
            return results.condition_number
        """)
        XCTAssertLessThan(result.numberValue!, 100.0)
    }

    func testEigenvaluesExist() throws {
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {type(results.eigenvalues), #results.eigenvalues}
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 2.0)  // k eigenvalues
    }

    func testEigenvaluesPositive() throws {
        // X'X eigenvalues should be positive (positive semi-definite)
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local all_positive = true
            for _, e in ipairs(results.eigenvalues) do
                if e <= 0 then all_positive = false end
            end
            return all_positive
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testEigenvaluesDescendingOrder() throws {
        // Eigenvalues should be sorted in descending order
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local descending = true
            for i = 2, #results.eigenvalues do
                if results.eigenvalues[i] > results.eigenvalues[i-1] then
                    descending = false
                end
            end
            return descending
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testConditionNumberConsistentWithEigenvalues() throws {
        // cond = sqrt(max_eig / min_eig)
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local max_eig = results.eigenvalues[1]
            local min_eig = results.eigenvalues[#results.eigenvalues]
            local expected_cond = math.sqrt(max_eig / min_eig)
            return math.abs(results.condition_number - expected_cond) < 0.001
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Summary Diagnostics Tests

    func testSummaryContainsConditionNumber() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local summary = results:summary()
            return string.find(summary, "Cond. No.") ~= nil
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testSummaryContainsMSEResid() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local summary = results:summary()
            return string.find(summary, "MSE Resid") ~= nil
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testSummaryWarningHighConditionNumber() throws {
        // Create a dataset with high multicollinearity
        let result = try engine.evaluate("""
            -- Create nearly collinear data
            local y = {}
            local X = {}
            for i = 1, 20 do
                y[i] = i + math.random() * 0.01
                -- x1 and x2 are nearly perfectly correlated
                X[i] = {1, i, i + math.random() * 0.0001}
            end
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            local summary = results:summary()
            -- Should warn about high condition number
            return string.find(summary, "multicollinearity") ~= nil
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Influence Detection Tests

    func testHighLeveragePointDetection() throws {
        // Add an outlier in X-space to create high leverage
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 50}  -- Last point is unusual in both y and x
            local X = math.regress.add_constant({1, 2, 3, 4, 100})  -- Extreme x value
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- Last observation should have highest leverage
            local max_h = 0
            local max_i = 0
            for i, h in ipairs(results.hat_diag) do
                if h > max_h then
                    max_h = h
                    max_i = i
                end
            end
            return max_i
        """)
        XCTAssertEqual(result.numberValue!, 5.0)  // 5th observation
    }

    func testCooksDistanceInfluentialPoint() throws {
        // Add an influential point and verify Cook's D is high
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 1000}  -- Very unusual y
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- Last observation should have high Cook's D
            return results.cooks_distance[5] > 0.5
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Perfect Fit Diagnostics

    func testPerfectFitInfluenceDiagnostics() throws {
        // For a model with very small residuals, verify Cook's D values exist
        // Note: Perfect fit creates numerical instability in Cook's D (0/0 case)
        // so we test a model with actual residuals for stability
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}  -- Model with noise
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- Cook's D should be relatively small for well-behaved data
            local max_cooks = 0
            for _, d in ipairs(results.cooks_distance) do
                if d > max_cooks then max_cooks = d end
            end
            -- For this simple case, no point should be highly influential
            return max_cooks
        """)
        // Cook's D < 1 generally indicates non-influential points
        XCTAssertLessThan(result.numberValue!, 1.0)
    }

    func testPerfectFitHatDiag() throws {
        // For perfect fit, hat diagonal should still be well-defined
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- Sum of leverage should equal k
            local sum_h = 0
            for _, h in ipairs(results.hat_diag) do
                sum_h = sum_h + h
            end
            return sum_h
        """)
        // k = 2 parameters
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    // MARK: - Longley Dataset Tests (Port from Statsmodels)

    func testLongleyDatasetBasic() throws {
        // Longley dataset is a classic test case for multicollinearity
        // Values from NIST and statsmodels
        let result = try engine.evaluate("""
            -- Longley dataset (1967) - known for multicollinearity
            local TOTEMP = {60323, 61122, 60171, 61187, 63221, 63639, 64989, 63761, 66019, 67857, 68169, 66513, 68655, 69564, 69331, 70551}
            local GNPDEFL = {83.0, 88.5, 88.2, 89.5, 96.2, 98.1, 99.0, 100.0, 101.2, 104.6, 108.4, 110.8, 112.6, 114.2, 115.7, 116.9}
            local GNP = {234289, 259426, 258054, 284599, 328975, 346999, 365385, 363112, 397469, 419180, 442769, 444546, 482704, 502601, 518173, 554894}
            local UNEMP = {2356, 2325, 3682, 3351, 2099, 1932, 1870, 3578, 2904, 2822, 2936, 4681, 3813, 3931, 4806, 4007}
            local ARMED = {1590, 1456, 1616, 1650, 3099, 3594, 3547, 3350, 3048, 2857, 2798, 2637, 2552, 2514, 2572, 2827}
            local POP = {107608, 108632, 109773, 110929, 112075, 113270, 115094, 116219, 117388, 118734, 120445, 121950, 123366, 125368, 127852, 130081}
            local YEAR = {1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962}

            -- Build design matrix with constant
            local X = {}
            for i = 1, 16 do
                X[i] = {1, GNPDEFL[i], GNP[i], UNEMP[i], ARMED[i], POP[i], YEAR[i]}
            end

            local model = math.regress.OLS(TOTEMP, X)
            local results = model:fit()

            return {
                results.nobs,
                #results.params,
                results.df_resid,
                results.rsquared > 0.99  -- R² should be very high
            }
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].numberValue, 16.0)  // 16 observations
        XCTAssertEqual(values[1].numberValue, 7.0)   // 7 parameters
        XCTAssertEqual(values[2].numberValue, 9.0)   // 16 - 7 = 9
        XCTAssertTrue(values[3].boolValue!)          // R² > 0.99
    }

    func testLongleyHighConditionNumber() throws {
        // Longley dataset is known for severe multicollinearity
        let result = try engine.evaluate("""
            local TOTEMP = {60323, 61122, 60171, 61187, 63221, 63639, 64989, 63761, 66019, 67857, 68169, 66513, 68655, 69564, 69331, 70551}
            local GNPDEFL = {83.0, 88.5, 88.2, 89.5, 96.2, 98.1, 99.0, 100.0, 101.2, 104.6, 108.4, 110.8, 112.6, 114.2, 115.7, 116.9}
            local GNP = {234289, 259426, 258054, 284599, 328975, 346999, 365385, 363112, 397469, 419180, 442769, 444546, 482704, 502601, 518173, 554894}
            local UNEMP = {2356, 2325, 3682, 3351, 2099, 1932, 1870, 3578, 2904, 2822, 2936, 4681, 3813, 3931, 4806, 4007}
            local ARMED = {1590, 1456, 1616, 1650, 3099, 3594, 3547, 3350, 3048, 2857, 2798, 2637, 2552, 2514, 2572, 2827}
            local POP = {107608, 108632, 109773, 110929, 112075, 113270, 115094, 116219, 117388, 118734, 120445, 121950, 123366, 125368, 127852, 130081}
            local YEAR = {1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962}

            local X = {}
            for i = 1, 16 do
                X[i] = {1, GNPDEFL[i], GNP[i], UNEMP[i], ARMED[i], POP[i], YEAR[i]}
            end

            local model = math.regress.OLS(TOTEMP, X)
            local results = model:fit()

            -- Condition number for Longley is known to be very high (> 1000)
            return results.condition_number > 1000
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Edge Case Tests

    func testMinimalObservationsInfluence() throws {
        // With minimal observations, leverage should be high
        let result = try engine.evaluate("""
            local y = {5, 8, 11}
            local X = math.regress.add_constant({1, 2, 3})
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- With n=3, k=2, average leverage = k/n = 2/3
            local avg_leverage = 0
            for _, h in ipairs(results.hat_diag) do
                avg_leverage = avg_leverage + h
            end
            avg_leverage = avg_leverage / 3
            return math.abs(avg_leverage - 2/3) < 0.001
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testInterceptOnlyModel() throws {
        // Model with only intercept (no regressors)
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5}
            local X = {{1}, {1}, {1}, {1}, {1}}  -- Only constant
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            -- Intercept should be mean of y
            return {results.params[1], 3.0}  -- mean of {1,2,3,4,5}
        """)
        let values = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(values[0], values[1], accuracy: 1e-10)
    }

    func testInterceptOnlyRobustSE() throws {
        // Even intercept-only model should have robust SEs
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5}
            local X = {{1}, {1}, {1}, {1}, {1}}
            local model = math.regress.OLS(y, X)
            local results = model:fit()
            return {
                type(results.bse_hc0),
                #results.bse_hc0,
                results.bse_hc0[1] >= 0
            }
        """)
        let values = result.arrayValue!
        XCTAssertEqual(values[0].stringValue, "table")
        XCTAssertEqual(values[1].numberValue, 1.0)
        XCTAssertTrue(values[2].boolValue!)
    }
}
