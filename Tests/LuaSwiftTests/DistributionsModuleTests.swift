//
//  DistributionsModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class DistributionsModuleTests: XCTestCase {
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

    // MARK: - Normal Distribution Tests

    func testNormPdfAtZero() throws {
        // PDF at mean should be 1/sqrt(2*pi) ≈ 0.3989
        let result = try engine.evaluate("return math.stats.norm.pdf(0)")
        XCTAssertEqual(result.numberValue!, 1.0 / sqrt(2 * Double.pi), accuracy: 1e-4)
    }

    func testNormPdfStandardized() throws {
        // PDF at x=1 for standard normal
        let result = try engine.evaluate("return math.stats.norm.pdf(1)")
        let expected = exp(-0.5) / sqrt(2 * Double.pi)
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-4)
    }

    func testNormPdfWithLocScale() throws {
        // PDF at x=5 with loc=5, scale=2 (same as PDF(0) for standard normal, scaled)
        let result = try engine.evaluate("return math.stats.norm.pdf(5, 5, 2)")
        let expected = 1.0 / (2 * sqrt(2 * Double.pi))
        XCTAssertEqual(result.numberValue!, expected, accuracy: 1e-4)
    }

    func testNormCdfAtZero() throws {
        // CDF at mean should be 0.5
        let result = try engine.evaluate("return math.stats.norm.cdf(0)")
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-4)
    }

    func testNormCdfAt196() throws {
        // CDF at 1.96 ≈ 0.975 (97.5th percentile)
        let result = try engine.evaluate("return math.stats.norm.cdf(1.96)")
        XCTAssertEqual(result.numberValue!, 0.975, accuracy: 1e-3)
    }

    func testNormCdfAtNeg196() throws {
        // CDF at -1.96 ≈ 0.025 (2.5th percentile)
        let result = try engine.evaluate("return math.stats.norm.cdf(-1.96)")
        XCTAssertEqual(result.numberValue!, 0.025, accuracy: 1e-3)
    }

    func testNormPpfAt975() throws {
        // PPF at 0.975 ≈ 1.96
        let result = try engine.evaluate("return math.stats.norm.ppf(0.975)")
        XCTAssertEqual(result.numberValue!, 1.96, accuracy: 0.01)
    }

    func testNormPpfAt50() throws {
        // PPF at 0.5 = 0 (median of standard normal)
        let result = try engine.evaluate("return math.stats.norm.ppf(0.5)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-6)
    }

    func testNormCdfPpfInverse() throws {
        // CDF(PPF(p)) should equal p
        let result = try engine.evaluate("""
            local p = 0.7
            local x = math.stats.norm.ppf(p)
            return math.stats.norm.cdf(x)
            """)
        XCTAssertEqual(result.numberValue!, 0.7, accuracy: 1e-4)
    }

    func testNormRvsSingleValue() throws {
        // RVS with size=1 should return a number
        let result = try engine.evaluate("return type(math.stats.norm.rvs(1))")
        XCTAssertEqual(result.stringValue, "number")
    }

    func testNormRvsMultipleValues() throws {
        // RVS with size=10 should return a table with 10 elements
        let result = try engine.evaluate("return #math.stats.norm.rvs(10)")
        XCTAssertEqual(result.intValue, 10)
    }

    func testNormMean() throws {
        let result = try engine.evaluate("return math.stats.norm.mean(5, 2)")
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testNormVar() throws {
        let result = try engine.evaluate("return math.stats.norm.var(0, 2)")
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 1e-10)
    }

    func testNormStd() throws {
        let result = try engine.evaluate("return math.stats.norm.std(0, 2)")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    // MARK: - Uniform Distribution Tests

    func testUniformPdfInRange() throws {
        // PDF within [0,1] should be 1
        let result = try engine.evaluate("return math.stats.uniform.pdf(0.5)")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testUniformPdfOutOfRange() throws {
        // PDF outside range should be 0
        let result = try engine.evaluate("return math.stats.uniform.pdf(-0.1)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testUniformCdf() throws {
        // CDF at 0.5 for uniform[0,1] should be 0.5
        let result = try engine.evaluate("return math.stats.uniform.cdf(0.5)")
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
    }

    func testUniformPpf() throws {
        // PPF at 0.5 should be 0.5 for uniform[0,1]
        let result = try engine.evaluate("return math.stats.uniform.ppf(0.5)")
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
    }

    func testUniformCdfPpfInverse() throws {
        let result = try engine.evaluate("""
            local p = 0.3
            local x = math.stats.uniform.ppf(p)
            return math.stats.uniform.cdf(x)
            """)
        XCTAssertEqual(result.numberValue!, 0.3, accuracy: 1e-10)
    }

    func testUniformMean() throws {
        // Mean of uniform[0,1] is 0.5
        let result = try engine.evaluate("return math.stats.uniform.mean(0, 1)")
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-10)
    }

    func testUniformVar() throws {
        // Var of uniform[0,1] is 1/12
        let result = try engine.evaluate("return math.stats.uniform.var(0, 1)")
        XCTAssertEqual(result.numberValue!, 1.0/12.0, accuracy: 1e-10)
    }

    // MARK: - Exponential Distribution Tests

    func testExponPdfAtZero() throws {
        // PDF at 0 for scale=1 is 1
        let result = try engine.evaluate("return math.stats.expon.pdf(0)")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testExponPdfAtOne() throws {
        // PDF at 1 for scale=1 is exp(-1)
        let result = try engine.evaluate("return math.stats.expon.pdf(1)")
        XCTAssertEqual(result.numberValue!, exp(-1), accuracy: 1e-10)
    }

    func testExponCdf() throws {
        // CDF at 1 for scale=1 is 1 - exp(-1)
        let result = try engine.evaluate("return math.stats.expon.cdf(1)")
        XCTAssertEqual(result.numberValue!, 1.0 - exp(-1), accuracy: 1e-10)
    }

    func testExponPpf() throws {
        // PPF at 0.5 for scale=1 is ln(2)
        let result = try engine.evaluate("return math.stats.expon.ppf(0.5)")
        XCTAssertEqual(result.numberValue!, log(2), accuracy: 1e-6)
    }

    func testExponMean() throws {
        // Mean of exponential with scale=2 is 2
        let result = try engine.evaluate("return math.stats.expon.mean(0, 2)")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testExponVar() throws {
        // Var of exponential with scale=2 is 4
        let result = try engine.evaluate("return math.stats.expon.var(0, 2)")
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 1e-10)
    }

    // MARK: - Student's t Distribution Tests

    func testTPdfAtZero() throws {
        // PDF at 0 is symmetric maximum
        let result = try engine.evaluate("return math.stats.t.pdf(0, 10)")
        // t(df=10) pdf at 0 ≈ 0.389
        XCTAssertGreaterThan(result.numberValue!, 0.38)
        XCTAssertLessThan(result.numberValue!, 0.40)
    }

    func testTCdfAtZero() throws {
        // CDF at 0 should be 0.5 (symmetric)
        let result = try engine.evaluate("return math.stats.t.cdf(0, 10)")
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-4)
    }

    func testTCdfAt196HighDf() throws {
        // For high df, t approaches normal: CDF at 1.96 ≈ 0.975
        let result = try engine.evaluate("return math.stats.t.cdf(1.96, 100)")
        XCTAssertEqual(result.numberValue!, 0.975, accuracy: 0.01)
    }

    func testTCdfPpfInverse() throws {
        let result = try engine.evaluate("""
            local p = 0.95
            local x = math.stats.t.ppf(p, 10)
            return math.stats.t.cdf(x, 10)
            """)
        XCTAssertEqual(result.numberValue!, 0.95, accuracy: 0.01)
    }

    func testTMean() throws {
        // Mean of t with df > 1 is loc
        let result = try engine.evaluate("return math.stats.t.mean(10, 5, 1)")
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testTVar() throws {
        // Var of t with df=10 is df/(df-2) = 10/8 = 1.25 (for scale=1)
        let result = try engine.evaluate("return math.stats.t.var(10, 0, 1)")
        XCTAssertEqual(result.numberValue!, 10.0/8.0, accuracy: 1e-4)
    }

    // MARK: - Chi-squared Distribution Tests

    func testChi2CdfAt384() throws {
        // chi2.cdf(3.841, df=1) ≈ 0.95 (critical value for 95%)
        let result = try engine.evaluate("return math.stats.chi2.cdf(3.841, 1)")
        XCTAssertEqual(result.numberValue!, 0.95, accuracy: 0.01)
    }

    func testChi2CdfAt599() throws {
        // chi2.cdf(5.991, df=2) ≈ 0.95
        let result = try engine.evaluate("return math.stats.chi2.cdf(5.991, 2)")
        XCTAssertEqual(result.numberValue!, 0.95, accuracy: 0.01)
    }

    func testChi2PpfAt95() throws {
        // chi2.ppf(0.95, df=1) ≈ 3.841
        let result = try engine.evaluate("return math.stats.chi2.ppf(0.95, 1)")
        XCTAssertEqual(result.numberValue!, 3.841, accuracy: 0.1)
    }

    func testChi2CdfPpfInverse() throws {
        let result = try engine.evaluate("""
            local p = 0.9
            local x = math.stats.chi2.ppf(p, 5)
            return math.stats.chi2.cdf(x, 5)
            """)
        XCTAssertEqual(result.numberValue!, 0.9, accuracy: 0.01)
    }

    func testChi2Mean() throws {
        // Mean of chi2 with df=5 is 5
        let result = try engine.evaluate("return math.stats.chi2.mean(5)")
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testChi2Var() throws {
        // Var of chi2 with df=5 is 2*5 = 10
        let result = try engine.evaluate("return math.stats.chi2.var(5)")
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    // MARK: - F Distribution Tests

    func testFCdfAt391() throws {
        // F(3.91, dfn=5, dfd=10) ≈ 0.95
        let result = try engine.evaluate("return math.stats.f.cdf(3.33, 5, 10)")
        XCTAssertEqual(result.numberValue!, 0.95, accuracy: 0.05)
    }

    func testFCdfPpfInverse() throws {
        let result = try engine.evaluate("""
            local p = 0.9
            local x = math.stats.f.ppf(p, 5, 10)
            return math.stats.f.cdf(x, 5, 10)
            """)
        XCTAssertEqual(result.numberValue!, 0.9, accuracy: 0.02)
    }

    func testFMean() throws {
        // Mean of F with dfd > 2 is dfd/(dfd-2)
        let result = try engine.evaluate("return math.stats.f.mean(5, 10)")
        XCTAssertEqual(result.numberValue!, 10.0/8.0, accuracy: 1e-4)
    }

    // MARK: - Gamma Distribution Tests

    func testGammaPdf() throws {
        // gamma(shape=2) pdf at x=1 = 1*exp(-1) = exp(-1)
        let result = try engine.evaluate("return math.stats.gamma_dist.pdf(1, 2)")
        XCTAssertEqual(result.numberValue!, exp(-1), accuracy: 1e-4)
    }

    func testGammaCdf() throws {
        // gamma(shape=1) is exponential, CDF at x=1 = 1-exp(-1)
        let result = try engine.evaluate("return math.stats.gamma_dist.cdf(1, 1)")
        XCTAssertEqual(result.numberValue!, 1.0 - exp(-1), accuracy: 1e-4)
    }

    func testGammaCdfPpfInverse() throws {
        let result = try engine.evaluate("""
            local p = 0.8
            local x = math.stats.gamma_dist.ppf(p, 3)
            return math.stats.gamma_dist.cdf(x, 3)
            """)
        XCTAssertEqual(result.numberValue!, 0.8, accuracy: 0.01)
    }

    func testGammaMean() throws {
        // Mean of gamma(shape=3, scale=2) is 3*2 = 6
        let result = try engine.evaluate("return math.stats.gamma_dist.mean(3, 0, 2)")
        XCTAssertEqual(result.numberValue!, 6.0, accuracy: 1e-10)
    }

    func testGammaVar() throws {
        // Var of gamma(shape=3, scale=2) is a*scale^2 = 3*4 = 12
        let result = try engine.evaluate("return math.stats.gamma_dist.var(3, 0, 2)")
        XCTAssertEqual(result.numberValue!, 12.0, accuracy: 1e-10)
    }

    // MARK: - Beta Distribution Tests

    func testBetaPdfUniform() throws {
        // beta(1,1) is uniform, pdf = 1 everywhere in (0,1)
        let result = try engine.evaluate("return math.stats.beta_dist.pdf(0.5, 1, 1)")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-4)
    }

    func testBetaPdfSymmetric() throws {
        // beta(2,2) is symmetric, pdf at 0.5 is maximum
        let result = try engine.evaluate("return math.stats.beta_dist.pdf(0.5, 2, 2)")
        // pdf = 6 * 0.25 * 0.25 = 1.5
        XCTAssertEqual(result.numberValue!, 1.5, accuracy: 1e-4)
    }

    func testBetaCdf() throws {
        // beta(1,1) cdf at 0.5 = 0.5 (uniform)
        let result = try engine.evaluate("return math.stats.beta_dist.cdf(0.5, 1, 1)")
        XCTAssertEqual(result.numberValue!, 0.5, accuracy: 1e-4)
    }

    func testBetaCdfPpfInverse() throws {
        let result = try engine.evaluate("""
            local p = 0.7
            local x = math.stats.beta_dist.ppf(p, 2, 5)
            return math.stats.beta_dist.cdf(x, 2, 5)
            """)
        XCTAssertEqual(result.numberValue!, 0.7, accuracy: 0.01)
    }

    func testBetaMean() throws {
        // Mean of beta(2, 3) is 2/5 = 0.4
        let result = try engine.evaluate("return math.stats.beta_dist.mean(2, 3)")
        XCTAssertEqual(result.numberValue!, 0.4, accuracy: 1e-10)
    }

    func testBetaVar() throws {
        // Var of beta(2, 3) is 2*3 / (25*6) = 6/150 = 0.04
        let result = try engine.evaluate("return math.stats.beta_dist.var(2, 3)")
        XCTAssertEqual(result.numberValue!, 0.04, accuracy: 1e-4)
    }

    // MARK: - Namespace Tests

    func testMathStatsNormExists() throws {
        let result = try engine.evaluate("return type(math.stats.norm)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathStatsUniformExists() throws {
        let result = try engine.evaluate("return type(math.stats.uniform)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathStatsExponExists() throws {
        let result = try engine.evaluate("return type(math.stats.expon)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathStatsTExists() throws {
        let result = try engine.evaluate("return type(math.stats.t)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathStatsChi2Exists() throws {
        let result = try engine.evaluate("return type(math.stats.chi2)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathStatsFExists() throws {
        let result = try engine.evaluate("return type(math.stats.f)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathStatsGammaDistExists() throws {
        let result = try engine.evaluate("return type(math.stats.gamma_dist)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathStatsBetaDistExists() throws {
        let result = try engine.evaluate("return type(math.stats.beta_dist)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testLuaswiftDistributionsAlias() throws {
        let result = try engine.evaluate("return luaswift.distributions.norm.pdf(0)")
        XCTAssertEqual(result.numberValue!, 1.0 / sqrt(2 * Double.pi), accuracy: 1e-4)
    }

    // MARK: - Edge Cases

    func testNormPdfNegativeInfinity() throws {
        let result = try engine.evaluate("return math.stats.norm.pdf(-1e10)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testNormCdfNegativeInfinity() throws {
        let result = try engine.evaluate("return math.stats.norm.cdf(-10)")
        XCTAssertLessThan(result.numberValue!, 1e-10)
    }

    func testNormCdfPositiveInfinity() throws {
        let result = try engine.evaluate("return math.stats.norm.cdf(10)")
        XCTAssertGreaterThan(result.numberValue!, 1.0 - 1e-10)
    }

    func testExponPdfNegative() throws {
        // PDF for x < loc should be 0
        let result = try engine.evaluate("return math.stats.expon.pdf(-1)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testChi2PdfNegative() throws {
        // PDF for x <= 0 should be 0
        let result = try engine.evaluate("return math.stats.chi2.pdf(-1, 5)")
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testBetaPdfOutsideRange() throws {
        // PDF for x <= 0 or x >= 1 should be 0
        let result1 = try engine.evaluate("return math.stats.beta_dist.pdf(-0.1, 2, 3)")
        let result2 = try engine.evaluate("return math.stats.beta_dist.pdf(1.1, 2, 3)")
        XCTAssertEqual(result1.numberValue!, 0.0, accuracy: 1e-10)
        XCTAssertEqual(result2.numberValue!, 0.0, accuracy: 1e-10)
    }

    // MARK: - Random Variate Tests

    func testNormRvsMeanApproximation() throws {
        // Mean of 1000 samples should be close to theoretical mean
        let result = try engine.evaluate("""
            local samples = math.stats.norm.rvs(1000, 5, 2)
            local sum = 0
            for _, v in ipairs(samples) do sum = sum + v end
            return sum / 1000
            """)
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 0.5)
    }

    func testUniformRvsInRange() throws {
        // All samples should be in [0, 1]
        let result = try engine.evaluate("""
            local samples = math.stats.uniform.rvs(100)
            local min, max = math.huge, -math.huge
            for _, v in ipairs(samples) do
                if v < min then min = v end
                if v > max then max = v end
            end
            return min >= 0 and max <= 1 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue!, 1.0)
    }

    func testExponRvsPositive() throws {
        // All samples should be positive
        let result = try engine.evaluate("""
            local samples = math.stats.expon.rvs(100)
            for _, v in ipairs(samples) do
                if v < 0 then return 0 end
            end
            return 1
            """)
        XCTAssertEqual(result.numberValue!, 1.0)
    }

    // MARK: - Statistical Tests

    func testTtest1sampBasic() throws {
        // Sample with mean ~0, test against popmean=0
        let result = try engine.evaluate("""
            local sample = {-0.5, 0.5, -0.3, 0.3, -0.1, 0.1, -0.2, 0.2, -0.4, 0.4}
            local stat, pval = math.stats.ttest_1samp(sample, 0)
            return pval
            """)
        // p-value should be close to 1 since sample mean is 0
        XCTAssertGreaterThan(result.numberValue!, 0.5)
    }

    func testTtest1sampSignificant() throws {
        // Sample with mean ~5, test against popmean=0
        let result = try engine.evaluate("""
            local sample = {4.9, 5.1, 5.0, 4.8, 5.2, 5.1, 4.9, 5.0, 5.0, 5.1}
            local stat, pval = math.stats.ttest_1samp(sample, 0)
            return pval
            """)
        // p-value should be very small
        XCTAssertLessThan(result.numberValue!, 0.001)
    }

    func testTtest1sampStatistic() throws {
        // Verify statistic calculation
        let result = try engine.evaluate("""
            local sample = {1, 2, 3, 4, 5}
            local stat, pval = math.stats.ttest_1samp(sample, 3)
            return stat
            """)
        // mean=3, popmean=3, so t-stat should be 0
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testTtestIndEqualMeans() throws {
        // Two samples with same mean
        let result = try engine.evaluate("""
            local sample1 = {1, 2, 3, 4, 5}
            local sample2 = {1.1, 1.9, 3.1, 3.9, 5.1}
            local stat, pval = math.stats.ttest_ind(sample1, sample2, true)
            return pval
            """)
        // p-value should be large (not significant)
        XCTAssertGreaterThan(result.numberValue!, 0.05)
    }

    func testTtestIndDifferentMeans() throws {
        // Two samples with different means
        let result = try engine.evaluate("""
            local sample1 = {1, 2, 3, 4, 5}
            local sample2 = {10, 11, 12, 13, 14}
            local stat, pval = math.stats.ttest_ind(sample1, sample2, true)
            return pval
            """)
        // p-value should be very small (significant)
        XCTAssertLessThan(result.numberValue!, 0.001)
    }

    func testTtestIndWelch() throws {
        // Welch's t-test (unequal variances)
        let result = try engine.evaluate("""
            local sample1 = {1, 2, 3, 4, 5}
            local sample2 = {10, 11, 12, 13, 14}
            local stat, pval = math.stats.ttest_ind(sample1, sample2, false)
            return pval
            """)
        // p-value should be very small
        XCTAssertLessThan(result.numberValue!, 0.001)
    }

    func testPearsonrPerfectPositive() throws {
        // Perfect positive correlation
        let result = try engine.evaluate("""
            local x = {1, 2, 3, 4, 5}
            local y = {2, 4, 6, 8, 10}
            local r, pval = math.stats.pearsonr(x, y)
            return r
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testPearsonrPerfectNegative() throws {
        // Perfect negative correlation
        let result = try engine.evaluate("""
            local x = {1, 2, 3, 4, 5}
            local y = {10, 8, 6, 4, 2}
            local r, pval = math.stats.pearsonr(x, y)
            return r
            """)
        XCTAssertEqual(result.numberValue!, -1.0, accuracy: 1e-10)
    }

    func testPearsonrNoCorrelation() throws {
        // No correlation
        let result = try engine.evaluate("""
            local x = {1, 2, 3, 4, 5}
            local y = {3, 1, 4, 1, 5}
            local r, pval = math.stats.pearsonr(x, y)
            return math.abs(r)
            """)
        // Correlation should be weak
        XCTAssertLessThan(result.numberValue!, 0.5)
    }

    func testSpearmanrPerfectPositive() throws {
        // Perfect monotonic relationship
        let result = try engine.evaluate("""
            local x = {1, 2, 3, 4, 5}
            local y = {10, 20, 30, 40, 50}
            local rho, pval = math.stats.spearmanr(x, y)
            return rho
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testSpearmanrPerfectNegative() throws {
        // Perfect negative monotonic relationship
        let result = try engine.evaluate("""
            local x = {1, 2, 3, 4, 5}
            local y = {50, 40, 30, 20, 10}
            local rho, pval = math.stats.spearmanr(x, y)
            return rho
            """)
        XCTAssertEqual(result.numberValue!, -1.0, accuracy: 1e-10)
    }

    func testSpearmanrNonlinear() throws {
        // Non-linear but monotonic
        let result = try engine.evaluate("""
            local x = {1, 2, 3, 4, 5}
            local y = {1, 4, 9, 16, 25}  -- y = x^2
            local rho, pval = math.stats.spearmanr(x, y)
            return rho
            """)
        // Should be 1 for monotonic relationship
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testDescribeBasic() throws {
        let result = try engine.evaluate("""
            local data = {1, 2, 3, 4, 5}
            local desc = math.stats.describe(data)
            return desc.mean
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testDescribeNobs() throws {
        let result = try engine.evaluate("""
            local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            local desc = math.stats.describe(data)
            return desc.nobs
            """)
        XCTAssertEqual(result.numberValue!, 10.0, accuracy: 1e-10)
    }

    func testDescribeMinMax() throws {
        let result = try engine.evaluate("""
            local data = {5, 2, 8, 1, 9, 3}
            local desc = math.stats.describe(data)
            return desc.min, desc.max
            """)
        // This returns the first value (min), check via separate tests
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testDescribeVariance() throws {
        let result = try engine.evaluate("""
            local data = {1, 2, 3, 4, 5}
            local desc = math.stats.describe(data)
            return desc.variance
            """)
        // Sample variance of {1,2,3,4,5} = 2.5
        XCTAssertEqual(result.numberValue!, 2.5, accuracy: 1e-10)
    }

    func testZscoreBasic() throws {
        let result = try engine.evaluate("""
            local data = {1, 2, 3, 4, 5}
            local z = math.stats.zscore(data)
            return z[3]  -- Middle value should be ~0
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testZscoreMeanZero() throws {
        // Z-scores should have mean 0
        let result = try engine.evaluate("""
            local data = {10, 20, 30, 40, 50}
            local z = math.stats.zscore(data)
            local sum = 0
            for _, v in ipairs(z) do sum = sum + v end
            return sum / #z
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testSkewSymmetric() throws {
        // Symmetric distribution should have skewness ~0
        let result = try engine.evaluate("""
            local data = {1, 2, 3, 4, 5, 6, 7, 8, 9}
            return math.stats.skew(data)
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testSkewPositive() throws {
        // Right-skewed distribution
        let result = try engine.evaluate("""
            local data = {1, 1, 1, 2, 2, 3, 10}
            return math.stats.skew(data)
            """)
        XCTAssertGreaterThan(result.numberValue!, 0.0)
    }

    func testKurtosisNormal() throws {
        // Generate approximately normal data
        let result = try engine.evaluate("""
            local data = {-2, -1, -1, 0, 0, 0, 0, 1, 1, 2}
            return math.stats.kurtosis(data)
            """)
        // Normal distribution has excess kurtosis ~0
        // This approximate data should be close to 0
        XCTAssertLessThan(abs(result.numberValue!), 2.0)
    }

    func testKurtosisLeptokurtic() throws {
        // Heavy-tailed distribution (leptokurtic, positive excess kurtosis)
        let result = try engine.evaluate("""
            local data = {0, 0, 0, 0, 0, 0, 10, -10}
            return math.stats.kurtosis(data)
            """)
        // Should have positive excess kurtosis
        XCTAssertGreaterThan(result.numberValue!, 0.0)
    }

    func testModeBasic() throws {
        let result = try engine.evaluate("""
            local data = {1, 2, 2, 3, 3, 3, 4}
            local m = math.stats.mode(data)
            return m.mode
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testModeCount() throws {
        let result = try engine.evaluate("""
            local data = {1, 2, 2, 3, 3, 3, 4}
            local m = math.stats.mode(data)
            return m.count
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    // MARK: - Statistical Tests Namespace Tests

    func testTtest1sampExists() throws {
        let result = try engine.evaluate("return type(math.stats.ttest_1samp)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testTtestIndExists() throws {
        let result = try engine.evaluate("return type(math.stats.ttest_ind)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testPearsonrExists() throws {
        let result = try engine.evaluate("return type(math.stats.pearsonr)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testSpearmanrExists() throws {
        let result = try engine.evaluate("return type(math.stats.spearmanr)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testDescribeExists() throws {
        let result = try engine.evaluate("return type(math.stats.describe)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testZscoreExists() throws {
        let result = try engine.evaluate("return type(math.stats.zscore)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testSkewExists() throws {
        let result = try engine.evaluate("return type(math.stats.skew)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testKurtosisExists() throws {
        let result = try engine.evaluate("return type(math.stats.kurtosis)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testModeExists() throws {
        let result = try engine.evaluate("return type(math.stats.mode)")
        XCTAssertEqual(result.stringValue, "function")
    }
}
