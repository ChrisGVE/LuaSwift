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
}
