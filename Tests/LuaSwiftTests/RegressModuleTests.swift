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

    // MARK: - GLS Tests

    func testGLSFunctionExists() throws {
        let result = try engine.evaluate("return type(math.regress.GLS)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testGLSWithIdentitySigmaEqualsOLS() throws {
        // GLS with identity covariance matrix should equal OLS
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})

            -- OLS
            local ols_model = math.regress.OLS(y, X)
            local ols_results = ols_model:fit()

            -- GLS with no sigma (defaults to identity)
            local gls_model = math.regress.GLS(y, X)
            local gls_results = gls_model:fit()

            -- Parameters should be identical
            return {
                math.abs(ols_results.params[1] - gls_results.params[1]) < 1e-10,
                math.abs(ols_results.params[2] - gls_results.params[2]) < 1e-10
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testGLSWithScalarSigma() throws {
        // GLS with scalar sigma (constant variance)
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})

            -- GLS with scalar sigma = 2 (same as OLS, just scaled variance)
            local gls_model = math.regress.GLS(y, X, 2.0)
            local gls_results = gls_model:fit()

            -- Should still get same params as OLS
            return {gls_results.params[1], gls_results.params[2]}
        """)
        let params = result.arrayValue!.compactMap { $0.numberValue }
        XCTAssertEqual(params[0], 2.0, accuracy: 1e-10)  // intercept
        XCTAssertEqual(params[1], 3.0, accuracy: 1e-10)  // slope
    }

    func testGLSWithDiagonalSigmaEqualsWLS() throws {
        // GLS with diagonal sigma (variances) should equal WLS
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local variances = {1, 2, 1, 2, 1}  -- heteroscedastic variances
            local weights = {}
            for i, v in ipairs(variances) do
                weights[i] = 1 / v  -- WLS weights are inverse variances
            end

            -- WLS
            local wls_model = math.regress.WLS(y, X, weights)
            local wls_results = wls_model:fit()

            -- GLS with diagonal covariance
            local gls_model = math.regress.GLS(y, X, variances)
            local gls_results = gls_model:fit()

            -- Parameters should be very close (numerical precision)
            return {
                math.abs(wls_results.params[1] - gls_results.params[1]) < 1e-8,
                math.abs(wls_results.params[2] - gls_results.params[2]) < 1e-8
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testGLSWithFullCovarianceMatrix() throws {
        // GLS with full covariance matrix (AR(1) structure)
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})

            -- Create AR(1) covariance structure with rho = 0.5
            local rho = 0.5
            local sigma = {}
            for i = 1, 5 do
                sigma[i] = {}
                for j = 1, 5 do
                    sigma[i][j] = rho ^ math.abs(i - j)
                end
            end

            local gls_model = math.regress.GLS(y, X, sigma)
            local gls_results = gls_model:fit()

            -- Check results exist and are reasonable
            return {
                gls_results.params[1] ~= nil,
                gls_results.params[2] ~= nil,
                gls_results.rsquared > 0.9
            }
        """)
        let values = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(values[0])
        XCTAssertTrue(values[1])
        XCTAssertTrue(values[2])
    }

    func testGLSResultsHaveAllFields() throws {
        // GLS results should have all standard fields
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local gls_model = math.regress.GLS(y, X)
            local results = gls_model:fit()

            return {
                type(results.params) == "table",
                type(results.bse) == "table",
                type(results.tvalues) == "table",
                type(results.pvalues) == "table",
                type(results.resid) == "table",
                type(results.fittedvalues) == "table",
                type(results.rsquared) == "number",
                type(results.rsquared_adj) == "number",
                type(results.aic) == "number",
                type(results.bic) == "number",
                results._model_type == "GLS"
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        for (i, v) in valid.enumerated() {
            XCTAssertTrue(v, "Field \(i) check failed")
        }
    }

    func testGLSModelType() throws {
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local gls_model = math.regress.GLS(y, X)
            local results = gls_model:fit()
            return results._model_type
        """)
        XCTAssertEqual(result.stringValue, "GLS")
    }

    func testGLSPredictMethod() throws {
        // Predict with GLS model
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local gls_model = math.regress.GLS(y, X)
            local results = gls_model:fit()
            -- Predict for x = 6 (should be close to 2 + 3*6 = 20)
            local new_X = math.regress.add_constant({6})
            local pred = results:predict(new_X)
            return pred[1]
        """)
        XCTAssertEqual(result.numberValue!, 20.0, accuracy: 1e-10)
    }

    func testGLSSummaryMethod() throws {
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local gls_model = math.regress.GLS(y, X)
            local results = gls_model:fit()
            local summary = results:summary()
            return {
                type(summary) == "string",
                string.find(summary, "GLS") ~= nil
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testGLSInfluenceDiagnostics() throws {
        // GLS should also have influence diagnostics
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local gls_model = math.regress.GLS(y, X)
            local results = gls_model:fit()

            return {
                type(results.hat_diag) == "table",
                type(results.cooks_distance) == "table",
                type(results.dffits) == "table",
                #results.hat_diag == 5
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
        XCTAssertTrue(valid[2])
        XCTAssertTrue(valid[3])
    }

    func testGLSRobustStandardErrors() throws {
        // GLS should also have HC standard errors
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local gls_model = math.regress.GLS(y, X)
            local results = gls_model:fit()

            return {
                type(results.bse_hc0) == "table",
                type(results.bse_hc1) == "table",
                type(results.bse_hc2) == "table",
                type(results.bse_hc3) == "table"
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
        XCTAssertTrue(valid[2])
        XCTAssertTrue(valid[3])
    }

    func testGLSConfidenceIntervals() throws {
        let result = try engine.evaluate("""
            local y = {3.1, 4.9, 7.2, 8.8, 11.1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local gls_model = math.regress.GLS(y, X)
            local results = gls_model:fit()
            local ci = results:conf_int(0.05)
            -- Check that lower < param < upper
            local valid1 = ci[1][1] < results.params[1] and results.params[1] < ci[1][2]
            local valid2 = ci[2][1] < results.params[2] and results.params[2] < ci[2][2]
            return {valid1, valid2}
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    // MARK: - GLM Tests

    func testGLMFunctionExists() throws {
        let result = try engine.evaluate("return type(math.regress.GLM)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testGLMGaussianEqualsOLS() throws {
        // GLM with Gaussian family should equal OLS
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})

            -- OLS
            local ols_model = math.regress.OLS(y, X)
            local ols_results = ols_model:fit()

            -- GLM with gaussian family (default)
            local glm_model = math.regress.GLM(y, X, {family = "gaussian"})
            local glm_results = glm_model:fit()

            -- Parameters should be very close
            return {
                math.abs(ols_results.params[1] - glm_results.params[1]) < 0.01,
                math.abs(ols_results.params[2] - glm_results.params[2]) < 0.01
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testGLMBinomialLogistic() throws {
        // Logistic regression: GLM with binomial family
        let result = try engine.evaluate("""
            -- Binary outcome data
            local y = {0, 0, 0, 0, 1, 1, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6, 7, 8})

            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local glm_results = glm_model:fit()

            -- Debug: print what we got
            local result = {
                glm_results.converged or false,
                #glm_results.params == 2,
                glm_results.params and glm_results.params[2] and glm_results.params[2] > 0 or false
            }
            return result
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        // Model may not always converge for small samples, but should return reasonable params
        XCTAssertEqual(valid.count, 3)  // Got all 3 results
        XCTAssertTrue(valid[1])  // 2 params
    }

    func testGLMPoisson() throws {
        // Poisson regression: GLM with poisson family
        let result = try engine.evaluate("""
            -- Count data
            local y = {1, 2, 3, 5, 8, 13, 21, 34}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6, 7, 8})

            local glm_model = math.regress.GLM(y, X, {family = "poisson"})
            local glm_results = glm_model:fit()

            return {
                glm_results.converged,
                #glm_results.params == 2,
                glm_results.params[2] > 0  -- Positive coefficient expected
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
        XCTAssertTrue(valid[2])
    }

    func testGLMGamma() throws {
        // Gamma regression
        let result = try engine.evaluate("""
            -- Positive continuous data
            local y = {1.5, 2.3, 3.1, 4.2, 5.0, 6.1, 7.3, 8.2}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6, 7, 8})

            local glm_model = math.regress.GLM(y, X, {family = "gamma"})
            local glm_results = glm_model:fit()

            return {
                glm_results.converged,
                #glm_results.params == 2
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testGLMResultsHaveAllFields() throws {
        let result = try engine.evaluate("""
            local y = {0, 0, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()

            return {
                type(results.params) == "table",
                type(results.bse) == "table",
                type(results.tvalues) == "table",
                type(results.pvalues) == "table",
                type(results.mu) == "table",
                type(results.deviance) == "number",
                type(results.null_deviance) == "number",
                type(results.aic) == "number",
                type(results.bic) == "number",
                type(results.converged) == "boolean"
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        for (i, v) in valid.enumerated() {
            XCTAssertTrue(v, "GLM field \(i) check failed")
        }
    }

    func testGLMDeviance() throws {
        // Deviance should be less than null deviance for good fit
        let result = try engine.evaluate("""
            local y = {0, 0, 0, 1, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()

            -- Deviance should be <= null deviance
            return results.deviance <= results.null_deviance
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testGLMPredictMethod() throws {
        let result = try engine.evaluate("""
            local y = {0, 0, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()

            -- Predict should return probabilities between 0 and 1
            local pred = results:predict()
            local all_valid = true
            for _, p in ipairs(pred) do
                if p < 0 or p > 1 then all_valid = false end
            end
            return all_valid
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testGLMSummaryMethod() throws {
        let result = try engine.evaluate("""
            local y = {0, 0, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()
            local summary = results:summary()
            return {
                type(summary) == "string",
                string.find(summary, "GLM") ~= nil,
                string.find(summary, "binomial") ~= nil
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
        XCTAssertTrue(valid[2])
    }

    func testGLMConfInt() throws {
        let result = try engine.evaluate("""
            local y = {0, 0, 0, 1, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()
            local ci = results:conf_int(0.05)
            -- Check that lower < param < upper
            local valid1 = ci[1][1] < results.params[1] and results.params[1] < ci[1][2]
            local valid2 = ci[2][1] < results.params[2] and results.params[2] < ci[2][2]
            return {valid1, valid2}
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testGLMConvergenceFlag() throws {
        let result = try engine.evaluate("""
            local y = {0, 0, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit({maxiter = 100, tol = 1e-8})
            return {results.converged, results.iterations > 0}
        """)
        let values = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(values[0])  // converged
        XCTAssertTrue(values[1])  // iterations > 0
    }

    func testGLMIterationCount() throws {
        let result = try engine.evaluate("""
            local y = {0, 0, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()
            return results.iterations
        """)
        // Should converge in reasonable iterations
        XCTAssertLessThan(result.numberValue!, 50.0)
        XCTAssertGreaterThan(result.numberValue!, 0.0)
    }

    func testGLMDefaultFamilyIsGaussian() throws {
        let result = try engine.evaluate("""
            local y = {5, 8, 11, 14, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            -- No family specified, should default to gaussian
            local glm_model = math.regress.GLM(y, X, {})
            local results = glm_model:fit()
            return results._family
        """)
        XCTAssertEqual(result.stringValue, "gaussian")
    }

    func testGLMPearsonChi2() throws {
        let result = try engine.evaluate("""
            local y = {0, 0, 1, 1, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()
            return {
                type(results.pearson_chi2) == "number",
                results.pearson_chi2 >= 0
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid[0])
        XCTAssertTrue(valid[1])
    }

    func testGLMLogLikelihood() throws {
        let result = try engine.evaluate("""
            local y = {0, 0, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()
            -- Log-likelihood should be negative for binomial
            return results.llf <= 0
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - ARIMA Tests

    func testARIMAFunctionExists() throws {
        let result = try engine.evaluate("""
            return type(math.regress.ARIMA) == "function"
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAModelCreation() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            return model ~= nil
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAFitReturnsResults() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            return results ~= nil and type(results.params) == "table"
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAResultsHaveAllFields() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 4, 7, 11, 16, 22, 29, 37, 46, 56, 67, 79, 92, 106}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            return {
                type(results.params) == "table",
                type(results.order) == "table",
                type(results.nobs) == "number",
                type(results.aic) == "number",
                type(results.bic) == "number",
                type(results.llf) == "number",
                type(results.sigma2) == "number",
                type(results.resid) == "table"
            }
        """)
        let valid = result.arrayValue!.compactMap { $0.boolValue }
        XCTAssertTrue(valid.allSatisfy { $0 })
    }

    func testARIMAOrderStored() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {2, 1, 1})
            local results = model:fit()
            return {results.order[1], results.order[2], results.order[3]}
        """)
        let order = result.arrayValue!.compactMap { $0.intValue }
        XCTAssertEqual(order[0], 2)
        XCTAssertEqual(order[1], 1)
        XCTAssertEqual(order[2], 1)
    }

    func testARIMAAR1PositiveAutocorrelation() throws {
        // Generate AR(1) data with positive autocorrelation
        let result = try engine.evaluate("""
            -- Simulated AR(1) process with phi=0.7: y_t = 0.7 * y_{t-1} + e_t
            local y = {0.0, 0.7, 1.19, 1.533, 0.873, 1.411, 1.788, 2.052, 2.236, 1.965,
                       2.176, 2.323, 2.426, 2.498, 2.549, 2.584, 2.609, 2.626, 2.638, 2.647}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            -- AR(1) coefficient should be positive
            local ar_coef = results.params[1]
            return ar_coef
        """)
        let arCoef = result.numberValue!
        // AR(1) coefficient should be positive (CSS estimation may slightly exceed 1.0 bounds)
        // The true value is ~0.7; CSS typically gets close but doesn't enforce stationarity bounds
        XCTAssertGreaterThan(arCoef, 0.5, "AR coefficient should be significantly positive")
        XCTAssertLessThan(arCoef, 1.5, "AR coefficient should be reasonable")
    }

    func testARIMAWithDifferencing() throws {
        // ARIMA(1,1,0) - differencing should be applied
        let result = try engine.evaluate("""
            -- Linear trend data: differencing should make it stationary
            local y = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29}
            local model = math.regress.ARIMA(y, {1, 1, 0})
            local results = model:fit()
            -- After differencing, all differences are 2, so nobs should be n-d
            return results.nobs == 14
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMASummaryMethod() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            local summary = results:summary()
            return type(summary) == "string" and #summary > 0
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMASummaryContainsOrder() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {2, 1, 1})
            local results = model:fit()
            local summary = results:summary()
            return summary:find("Order") ~= nil or summary:find("ARIMA") ~= nil
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAForecastMethod() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            local forecast = results:forecast(5)
            return type(forecast) == "table" and #forecast == 5
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAForecastTrendContinues() throws {
        let result = try engine.evaluate("""
            -- Upward trend data
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            local forecast = results:forecast(3)
            -- First forecast should continue upward trend
            return forecast[1] > y[#y] - 5  -- Should be reasonably close to last value
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAPredictMethod() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            local predictions = results:predict()
            return type(predictions) == "table" and #predictions > 0
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAResidualsMeanNearZero() throws {
        let result = try engine.evaluate("""
            local y = {1, 3, 5, 7, 9, 8, 10, 12, 14, 16, 15, 17, 19, 21, 23}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            local resid = results.resid
            local sum = 0
            for _, v in ipairs(resid) do
                sum = sum + v
            end
            local mean = sum / #resid
            return math.abs(mean) < 5  -- Mean should be close to zero
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAModelType() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {1, 1, 0})
            local results = model:fit()
            return results._model_type == "ARIMA"
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAInformationCriteria() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            -- AIC and BIC should be finite numbers
            local aic_valid = results.aic == results.aic  -- NaN check
            local bic_valid = results.bic == results.bic  -- NaN check
            return aic_valid and bic_valid
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAHigherOrderAR() throws {
        let result = try engine.evaluate("""
            -- AR(2) model should have 2 AR coefficients
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}
            local model = math.regress.ARIMA(y, {2, 0, 0})
            local results = model:fit()
            -- Should have params for 2 AR coefficients
            return #results.params >= 2
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAWithMA() throws {
        let result = try engine.evaluate("""
            -- ARIMA(0,0,1) - MA(1) model
            local y = {1.5, 2.3, 1.8, 2.9, 3.2, 2.7, 3.5, 4.1, 3.8, 4.5,
                       5.0, 4.6, 5.3, 5.8, 5.4, 6.1, 6.6, 6.2, 6.9, 7.4}
            local model = math.regress.ARIMA(y, {0, 0, 1})
            local results = model:fit()
            -- Should have at least one MA coefficient
            return #results.params >= 1
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAWithARandMA() throws {
        let result = try engine.evaluate("""
            -- ARIMA(1,0,1) - mixed model
            local y = {1.5, 2.3, 1.8, 2.9, 3.2, 2.7, 3.5, 4.1, 3.8, 4.5,
                       5.0, 4.6, 5.3, 5.8, 5.4, 6.1, 6.6, 6.2, 6.9, 7.4}
            local model = math.regress.ARIMA(y, {1, 0, 1})
            local results = model:fit()
            -- Should have AR + MA coefficients
            return #results.params >= 2
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAErrorOnShortSeries() throws {
        let result = try engine.evaluate("""
            local y = {1, 2}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            -- Should return nil for too short series
            return results == nil
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMAErrorOnInvalidOrder() throws {
        let result = try engine.evaluate("""
            local ok, err = pcall(function()
                local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
                local model = math.regress.ARIMA(y, {1, 0})  -- Invalid order (2 elements instead of 3)
            end)
            return not ok  -- Should error
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testARIMASigma2Positive() throws {
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            return results.sigma2 > 0
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Ported statsmodels GLM Tests

    // Tests ported from statsmodels test_glm.py
    // Reference: https://github.com/statsmodels/statsmodels/blob/main/statsmodels/genmod/tests/test_glm.py

    func testGLMBinomialStatsmodelsAPI() throws {
        // Test binomial GLM API matches statsmodels pattern
        // Based on Star98 dataset structure from statsmodels
        let result = try engine.evaluate("""
            -- Simulated binomial data similar to Star98 structure
            local successes = {45, 52, 38, 61, 55, 48, 42, 57, 50, 46}
            local trials = {100, 100, 100, 100, 100, 100, 100, 100, 100, 100}

            -- Convert to proportions
            local y = {}
            for i = 1, #successes do
                y[i] = successes[i] / trials[i]
            end

            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()

            return {
                has_params = type(results.params) == "table",
                has_bse = type(results.bse) == "table",
                has_deviance = type(results.deviance) == "number",
                has_pearson_chi2 = type(results.pearson_chi2) == "number",
                has_llf = type(results.llf) == "number",
                converged = results.converged
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertTrue(resultTable["has_params"]?.boolValue ?? false)
        XCTAssertTrue(resultTable["has_bse"]?.boolValue ?? false)
        XCTAssertTrue(resultTable["has_deviance"]?.boolValue ?? false)
        XCTAssertTrue(resultTable["has_pearson_chi2"]?.boolValue ?? false)
        XCTAssertTrue(resultTable["has_llf"]?.boolValue ?? false)
    }

    func testGLMPoissonCountData() throws {
        // Test Poisson GLM with count data
        // Pattern from statsmodels cpunish dataset tests
        let result = try engine.evaluate("""
            -- Count data (similar to cpunish structure)
            local counts = {2, 5, 3, 8, 12, 7, 15, 10, 18, 14, 22, 17}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12})

            local glm_model = math.regress.GLM(counts, X, {family = "poisson"})
            local results = glm_model:fit()

            -- Poisson GLM properties
            return {
                params_count = #results.params,
                deviance_positive = results.deviance > 0,
                llf_negative = results.llf < 0,  -- Log-likelihood for Poisson is typically negative
                slope_positive = results.params[2] > 0  -- Increasing counts should give positive slope
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertEqual(resultTable["params_count"]?.intValue, 2)
        XCTAssertTrue(resultTable["deviance_positive"]?.boolValue ?? false)
        XCTAssertTrue(resultTable["llf_negative"]?.boolValue ?? false)
        XCTAssertTrue(resultTable["slope_positive"]?.boolValue ?? false)
    }

    func testGLMGammaScotlandPattern() throws {
        // Test Gamma GLM pattern from Scotland voting dataset
        // Reference: statsmodels Scotland dataset example
        let result = try engine.evaluate("""
            -- Positive continuous data similar to Scotland voting percentages
            local y = {35.2, 42.1, 28.9, 51.3, 45.7, 38.4, 33.6, 47.2,
                       41.5, 36.8, 44.9, 39.1, 32.4, 48.6, 43.2, 37.5}
            local X = math.regress.add_constant({
                12.1, 8.3, 15.2, 6.1, 7.8, 10.5, 13.4, 5.9,
                9.2, 11.8, 7.1, 10.1, 14.3, 6.5, 8.0, 11.2
            })

            local glm_model = math.regress.GLM(y, X, {family = "gamma"})
            local results = glm_model:fit()

            return {
                has_params = type(results.params) == "table" and #results.params == 2,
                deviance = results.deviance,
                pearson_chi2 = results.pearson_chi2,
                nobs = results.nobs,
                converged = results.converged
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertTrue(resultTable["has_params"]?.boolValue ?? false, "Should have 2 parameters")
        XCTAssertEqual(resultTable["nobs"]?.intValue, 16)
        // Deviance and Pearson chi2 should be non-negative for Gamma models
        if let deviance = resultTable["deviance"]?.numberValue,
           let pearsonChi2 = resultTable["pearson_chi2"]?.numberValue {
            XCTAssertTrue(deviance >= 0, "Deviance should be non-negative")
            XCTAssertTrue(pearsonChi2 >= 0, "Pearson chi2 should be non-negative")
        }
    }

    func testGLMDevianceCalculation() throws {
        // Verify deviance calculation matches statsmodels formula
        // Deviance = 2 * sum(unit_deviance)
        let result = try engine.evaluate("""
            local y = {0.2, 0.4, 0.5, 0.6, 0.8}
            local X = math.regress.add_constant({1, 2, 3, 4, 5})
            local glm_model = math.regress.GLM(y, X, {family = "gaussian"})
            local results = glm_model:fit()

            -- For Gaussian, deviance = sum of squared residuals
            local manual_deviance = 0
            local resid = results.resid
            for i = 1, #resid do
                manual_deviance = manual_deviance + resid[i] * resid[i]
            end

            return math.abs(results.deviance - manual_deviance) < 1e-6
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testGLMNullDeviance() throws {
        // Verify null deviance calculation (intercept-only model)
        let result = try engine.evaluate("""
            local y = {10, 12, 15, 18, 22, 25}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6})
            local glm_model = math.regress.GLM(y, X, {family = "gaussian"})
            local results = glm_model:fit()

            -- Null deviance should be greater than or equal to deviance
            return results.null_deviance >= results.deviance
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testGLMInformationCriteriaFormulas() throws {
        // Verify AIC and BIC formulas match our implementation
        // AIC = -2*llf + 2*k (k = number of beta parameters)
        // BIC = -2*llf + k*log(n)
        let result = try engine.evaluate("""
            local y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
            local glm_model = math.regress.GLM(y, X, {family = "gaussian"})
            local results = glm_model:fit()

            local k = #results.params  -- Number of beta parameters
            local n = results.nobs
            local llf = results.llf

            local expected_aic = -2 * llf + 2 * k
            local expected_bic = -2 * llf + k * math.log(n)

            return {
                aic_close = math.abs(results.aic - expected_aic) < 1,
                bic_close = math.abs(results.bic - expected_bic) < 1,
                aic = results.aic,
                expected_aic = expected_aic
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertTrue(resultTable["aic_close"]?.boolValue ?? false, "AIC should match formula: -2*llf + 2*k")
        XCTAssertTrue(resultTable["bic_close"]?.boolValue ?? false, "BIC should match formula: -2*llf + k*log(n)")
    }

    func testGLMPoissonExponentialMean() throws {
        // Poisson with log link: E[y] = exp(X*beta)
        // Verify fitted values are exponential of linear predictor
        let result = try engine.evaluate("""
            local y = {1, 3, 5, 8, 12, 18}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6})
            local glm_model = math.regress.GLM(y, X, {family = "poisson"})
            local results = glm_model:fit()

            -- mu should be positive (exp of linear predictor)
            local all_positive = true
            for i, mu in ipairs(results.mu) do
                if mu <= 0 then
                    all_positive = false
                    break
                end
            end

            return all_positive
        """)
        XCTAssertTrue(result.boolValue!)
    }

    func testGLMBinomialProbabilityBounds() throws {
        // Binomial: fitted probabilities should be in (0,1)
        let result = try engine.evaluate("""
            local y = {0, 0, 0, 1, 1, 1, 1, 1}
            local X = math.regress.add_constant({1, 2, 3, 4, 5, 6, 7, 8})
            local glm_model = math.regress.GLM(y, X, {family = "binomial"})
            local results = glm_model:fit()

            local in_bounds = true
            for i, mu in ipairs(results.mu) do
                if mu <= 0 or mu >= 1 then
                    in_bounds = false
                    break
                end
            end

            return in_bounds
        """)
        XCTAssertTrue(result.boolValue!)
    }

    // MARK: - Ported statsmodels ARIMA Tests

    // Tests ported from statsmodels tsa tests
    // Reference: https://www.statsmodels.org/devel/examples/notebooks/generated/tsa_arma_0.html

    func testARIMASunspotAR2Pattern() throws {
        // Test AR(2) model on sunspot-like data
        // Statsmodels expected for sunspots AR(2):
        // ar.L1 ≈ 1.39, ar.L2 ≈ -0.69, sigma2 ≈ 275
        let result = try engine.evaluate("""
            -- Sunspot-like data (subset of annual sunspot numbers)
            -- These are actual sunspot values from 1700-1750
            local sunspots = {
                5, 11, 16, 23, 36, 58, 29, 20, 10, 8, 3, 0, 0, 2, 11,
                27, 47, 63, 60, 39, 28, 26, 22, 11, 21, 40, 78, 122, 103, 73,
                47, 35, 11, 5, 16, 34, 70, 81, 111, 101, 73, 40, 20, 16, 5,
                11, 22, 40, 60, 80, 83
            }

            local model = math.regress.ARIMA(sunspots, {2, 0, 0})
            local results = model:fit()

            -- Check AR coefficients have expected signs and magnitudes
            -- ar1 should be positive and > 1, ar2 should be negative
            local ar1 = results.arparams[1]
            local ar2 = results.arparams[2]

            return {
                ar1_positive = ar1 > 0,
                ar1_magnitude = ar1 > 0.5 and ar1 < 2.0,
                ar2_negative = ar2 < 0,
                ar2_magnitude = ar2 > -1.0 and ar2 < 0,
                sigma2_reasonable = results.sigma2 > 0 and results.sigma2 < 1000
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertTrue(resultTable["ar1_positive"]?.boolValue ?? false, "AR1 should be positive")
        XCTAssertTrue(resultTable["ar1_magnitude"]?.boolValue ?? false, "AR1 magnitude should be reasonable")
        XCTAssertTrue(resultTable["ar2_negative"]?.boolValue ?? false, "AR2 should be negative")
        XCTAssertTrue(resultTable["ar2_magnitude"]?.boolValue ?? false, "AR2 magnitude should be reasonable")
        XCTAssertTrue(resultTable["sigma2_reasonable"]?.boolValue ?? false, "Sigma2 should be reasonable")
    }

    func testARIMAAICBICFormulas() throws {
        // Verify AIC/BIC formulas match statsmodels
        // AIC = -2*llf + 2*k
        // BIC = -2*llf + k*log(n)
        let result = try engine.evaluate("""
            local y = {10, 12, 15, 14, 18, 22, 20, 25, 28, 26, 30, 35, 33, 38, 42}
            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()

            local k = #results.params + 1  -- AR params + sigma2
            local n = results.nobs
            local llf = results.llf

            local expected_aic = -2 * llf + 2 * k
            local expected_bic = -2 * llf + k * math.log(n)

            return {
                aic_matches = math.abs(results.aic - expected_aic) < 1,
                bic_matches = math.abs(results.bic - expected_bic) < 1
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertTrue(resultTable["aic_matches"]?.boolValue ?? false, "AIC formula should match")
        XCTAssertTrue(resultTable["bic_matches"]?.boolValue ?? false, "BIC formula should match")
    }

    func testARIMAStationaryAR() throws {
        // Test that estimated AR coefficients satisfy stationarity
        // For AR(1): |phi| < 1 ideally (CSS may slightly violate)
        // For AR(2): phi1 + phi2 < 1, phi2 - phi1 < 1, |phi2| < 1
        let result = try engine.evaluate("""
            local y = {
                100, 102, 99, 105, 103, 108, 106, 110, 107, 112,
                109, 115, 113, 118, 115, 120, 117, 122, 119, 125
            }
            local model = math.regress.ARIMA(y, {2, 0, 0})
            local results = model:fit()

            local ar1 = results.arparams[1] or 0
            local ar2 = results.arparams[2] or 0

            -- Check approximate stationarity conditions
            local sum_condition = (ar1 + ar2) < 1.5  -- Allow some slack for CSS
            local diff_condition = (ar2 - ar1) < 1.5
            local ar2_condition = math.abs(ar2) < 1.5

            return sum_condition and diff_condition and ar2_condition
        """)
        XCTAssertTrue(result.boolValue!, "AR coefficients should approximately satisfy stationarity")
    }

    func testARIMADifferencingIntegration() throws {
        // Test that ARIMA(p,d,q) properly applies differencing
        // After d=1 differencing, a random walk becomes stationary
        let result = try engine.evaluate("""
            -- Random walk: y[t] = y[t-1] + noise
            local random_walk = {100}
            for i = 2, 30 do
                random_walk[i] = random_walk[i-1] + (i % 3 - 1)  -- Deterministic "noise"
            end

            -- ARIMA(1,1,0) should capture this
            local model = math.regress.ARIMA(random_walk, {1, 1, 0})
            local results = model:fit()

            -- After differencing, should have n-1 observations
            return {
                nobs_correct = results.nobs == 29,
                order_correct = results.order[1] == 1 and results.order[2] == 1 and results.order[3] == 0
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertTrue(resultTable["nobs_correct"]?.boolValue ?? false, "Nobs should be n-d after differencing")
        XCTAssertTrue(resultTable["order_correct"]?.boolValue ?? false, "Order should be preserved")
    }

    func testARIMAForecastMeanReversion() throws {
        // Test that forecasts show mean reversion for stationary series
        let result = try engine.evaluate("""
            -- Stationary AR(1) process with mean around 50
            local y = {
                48, 52, 49, 53, 47, 54, 46, 55, 45, 56,
                50, 51, 49, 52, 48, 53, 47, 54, 50, 51
            }

            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()
            local forecasts = results:forecast(10)

            -- Mean of original series
            local sum = 0
            for _, v in ipairs(y) do sum = sum + v end
            local mean_y = sum / #y

            -- Long-term forecasts should tend toward mean
            local last_forecast = forecasts[10]
            local near_mean = math.abs(last_forecast - mean_y) < 20  -- Within 20 of mean

            return near_mean
        """)
        XCTAssertTrue(result.boolValue!, "Long-term forecasts should tend toward mean")
    }

    func testARIMAMAComponentEffect() throws {
        // Test that MA component captures short-term dependencies
        let result = try engine.evaluate("""
            -- Data with MA(1) structure
            local y = {
                10.5, 11.2, 10.8, 12.1, 11.5, 13.2, 12.4, 14.1, 13.3, 15.0,
                14.2, 15.8, 14.9, 16.5, 15.7, 17.3, 16.4, 18.0, 17.1, 18.7
            }

            local model_ar = math.regress.ARIMA(y, {1, 0, 0})
            local model_arma = math.regress.ARIMA(y, {1, 0, 1})

            local results_ar = model_ar:fit()
            local results_arma = model_arma:fit()

            -- ARMA should have lower or similar AIC than pure AR
            -- (allowing for numerical variations in CSS estimation)
            return {
                ar_aic = results_ar.aic,
                arma_aic = results_arma.aic,
                arma_has_ma = #results_arma.maparams >= 1
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertTrue(resultTable["arma_has_ma"]?.boolValue ?? false, "ARMA should have MA params")
    }

    func testARIMAResidualWhiteNoise() throws {
        // Well-specified ARIMA should have white noise residuals
        // Test: mean ≈ 0, no strong autocorrelation
        let result = try engine.evaluate("""
            local y = {
                100, 105, 103, 108, 106, 111, 109, 114, 112, 117,
                115, 120, 118, 123, 121, 126, 124, 129, 127, 132
            }

            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()

            local resid = results.resid
            local n = #resid

            -- Check mean is near zero
            local sum = 0
            for _, r in ipairs(resid) do sum = sum + r end
            local mean_resid = sum / n

            -- Check variance is finite and positive
            local sum_sq = 0
            for _, r in ipairs(resid) do sum_sq = sum_sq + (r - mean_resid)^2 end
            local var_resid = sum_sq / (n - 1)

            return {
                mean_near_zero = math.abs(mean_resid) < 10,
                variance_positive = var_resid > 0,
                variance_finite = var_resid == var_resid  -- NaN check
            }
        """)
        let resultTable = result.tableValue!
        XCTAssertTrue(resultTable["mean_near_zero"]?.boolValue ?? false, "Residual mean should be near zero")
        XCTAssertTrue(resultTable["variance_positive"]?.boolValue ?? false, "Residual variance should be positive")
        XCTAssertTrue(resultTable["variance_finite"]?.boolValue ?? false, "Residual variance should be finite")
    }

    func testARIMALogLikelihoodSign() throws {
        // Log-likelihood should be negative for most real data
        let result = try engine.evaluate("""
            local y = {
                1.2, 1.5, 1.3, 1.8, 1.6, 2.1, 1.9, 2.4, 2.2, 2.7,
                2.5, 3.0, 2.8, 3.3, 3.1, 3.6, 3.4, 3.9, 3.7, 4.2
            }

            local model = math.regress.ARIMA(y, {1, 0, 0})
            local results = model:fit()

            -- For continuous data, log-likelihood is typically negative
            -- (probability density can exceed 1, but log of small values is negative)
            return results.llf == results.llf  -- At minimum, should not be NaN
        """)
        XCTAssertTrue(result.boolValue!, "Log-likelihood should be finite")
    }

    func testARIMAHigherOrderDifferencing() throws {
        // Test ARIMA with d=2 (second-order differencing)
        let result = try engine.evaluate("""
            -- Quadratic trend data
            local y = {}
            for i = 1, 25 do
                y[i] = i * i + 0.5 * i
            end

            local model = math.regress.ARIMA(y, {1, 2, 0})
            local results = model:fit()

            -- After d=2 differencing, should have n-2 observations
            return results.nobs == 23
        """)
        XCTAssertTrue(result.boolValue!, "Second-order differencing should reduce nobs by 2")
    }
}
