//
//  MathSciModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class MathSciModuleTests: XCTestCase {
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

    // MARK: - Namespace Structure Tests

    func testMathStatsNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.stats)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathSpecialNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.special)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathConstantsNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.constants)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathOptimizeNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.optimize)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathIntegrateNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.integrate)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathInterpolateNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.interpolate)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathClusterNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.cluster)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathSpatialNamespaceExists() throws {
        let result = try engine.evaluate("return type(math.spatial)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathLinalgReExported() throws {
        let result = try engine.evaluate("return type(math.linalg)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathComplexReExported() throws {
        let result = try engine.evaluate("return type(math.complex)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testMathGeoReExported() throws {
        let result = try engine.evaluate("return type(math.geo)")
        XCTAssertEqual(result.stringValue, "table")
    }

    // MARK: - Built-in Math Functions Preserved

    func testMathSinPreserved() throws {
        let result = try engine.evaluate("return math.sin(math.pi / 2)")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testMathCosPreserved() throws {
        let result = try engine.evaluate("return math.cos(0)")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testMathSqrtPreserved() throws {
        let result = try engine.evaluate("return math.sqrt(4)")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testMathFloorPreserved() throws {
        let result = try engine.evaluate("return math.floor(3.7)")
        XCTAssertEqual(result.numberValue, 3)
    }

    func testMathCeilPreserved() throws {
        let result = try engine.evaluate("return math.ceil(3.2)")
        XCTAssertEqual(result.numberValue, 4)
    }

    func testMathAbsPreserved() throws {
        let result = try engine.evaluate("return math.abs(-5)")
        XCTAssertEqual(result.numberValue, 5)
    }

    func testMathExpPreserved() throws {
        let result = try engine.evaluate("return math.exp(1)")
        XCTAssertEqual(result.numberValue!, 2.718281828459045, accuracy: 1e-10)
    }

    func testMathLogPreserved() throws {
        let result = try engine.evaluate("return math.log(math.exp(1))")
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    // MARK: - math.stats Re-exports

    func testMathStatsSumReExported() throws {
        let result = try engine.evaluate("return math.stats.sum({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue, 15)
    }

    func testMathStatsMeanReExported() throws {
        let result = try engine.evaluate("return math.stats.mean({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testMathStatsMedianReExported() throws {
        let result = try engine.evaluate("return math.stats.median({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testMathStatsVarianceReExported() throws {
        let result = try engine.evaluate("return math.stats.variance({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, 2.0, accuracy: 1e-10)
    }

    func testMathStatsStddevReExported() throws {
        let result = try engine.evaluate("return math.stats.stddev({1, 2, 3, 4, 5})")
        XCTAssertEqual(result.numberValue!, 1.4142135623730951, accuracy: 1e-10)
    }

    func testMathStatsPercentileReExported() throws {
        let result = try engine.evaluate("return math.stats.percentile({1, 2, 3, 4, 5}, 50)")
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    // MARK: - math.special Re-exports

    func testMathSpecialFactorialReExported() throws {
        let result = try engine.evaluate("return math.special.factorial(5)")
        XCTAssertEqual(result.numberValue, 120)
    }

    func testMathSpecialGammaReExported() throws {
        let result = try engine.evaluate("return math.special.gamma(5)")
        XCTAssertEqual(result.numberValue!, 24.0, accuracy: 1e-10)
    }

    func testMathSpecialLgammaReExported() throws {
        let result = try engine.evaluate("return math.special.lgamma(5)")
        XCTAssertEqual(result.numberValue!, 3.178053830347946, accuracy: 1e-10)
    }

    func testMathSpecialGammalnAlias() throws {
        // gammaln should be an alias for lgamma
        let result = try engine.evaluate("return math.special.gammaln(5)")
        XCTAssertEqual(result.numberValue!, 3.178053830347946, accuracy: 1e-10)
    }

    // MARK: - math.constants Tests

    func testMathConstantsPi() throws {
        let result = try engine.evaluate("return math.constants.pi")
        XCTAssertEqual(result.numberValue!, Double.pi, accuracy: 1e-15)
    }

    func testMathConstantsE() throws {
        let result = try engine.evaluate("return math.constants.e")
        XCTAssertEqual(result.numberValue!, 2.718281828459045, accuracy: 1e-15)
    }

    func testMathConstantsTau() throws {
        let result = try engine.evaluate("return math.constants.tau")
        XCTAssertEqual(result.numberValue!, 2 * Double.pi, accuracy: 1e-15)
    }

    func testMathConstantsPhi() throws {
        let result = try engine.evaluate("return math.constants.phi")
        XCTAssertEqual(result.numberValue!, 1.618033988749895, accuracy: 1e-15)
    }

    func testMathConstantsEulerGamma() throws {
        let result = try engine.evaluate("return math.constants.euler_gamma")
        XCTAssertEqual(result.numberValue!, 0.5772156649015329, accuracy: 1e-15)
    }

    func testMathConstantsSqrt2() throws {
        let result = try engine.evaluate("return math.constants.sqrt2")
        XCTAssertEqual(result.numberValue!, 1.4142135623730951, accuracy: 1e-15)
    }

    func testMathConstantsSqrt3() throws {
        let result = try engine.evaluate("return math.constants.sqrt3")
        XCTAssertEqual(result.numberValue!, 1.7320508075688772, accuracy: 1e-15)
    }

    // MARK: - Physical Constants Tests

    func testMathConstantsSpeedOfLight() throws {
        let result = try engine.evaluate("return math.constants.c")
        XCTAssertEqual(result.numberValue!, 299792458.0, accuracy: 1)
    }

    func testMathConstantsPlanck() throws {
        let result = try engine.evaluate("return math.constants.h")
        XCTAssertEqual(result.numberValue!, 6.62607015e-34, accuracy: 1e-44)
    }

    func testMathConstantsReducedPlanck() throws {
        let result = try engine.evaluate("return math.constants.hbar")
        XCTAssertEqual(result.numberValue!, 1.054571817e-34, accuracy: 1e-44)
    }

    func testMathConstantsGravitational() throws {
        let result = try engine.evaluate("return math.constants.G")
        XCTAssertEqual(result.numberValue!, 6.67430e-11, accuracy: 1e-15)
    }

    func testMathConstantsElementaryCharge() throws {
        let result = try engine.evaluate("return math.constants.e_charge")
        XCTAssertEqual(result.numberValue!, 1.602176634e-19, accuracy: 1e-29)
    }

    func testMathConstantsElectronMass() throws {
        let result = try engine.evaluate("return math.constants.m_e")
        XCTAssertEqual(result.numberValue!, 9.1093837015e-31, accuracy: 1e-40)
    }

    func testMathConstantsProtonMass() throws {
        let result = try engine.evaluate("return math.constants.m_p")
        XCTAssertEqual(result.numberValue!, 1.67262192369e-27, accuracy: 1e-37)
    }

    func testMathConstantsBoltzmann() throws {
        let result = try engine.evaluate("return math.constants.k_B")
        XCTAssertEqual(result.numberValue!, 1.380649e-23, accuracy: 1e-33)
    }

    func testMathConstantsAvogadro() throws {
        let result = try engine.evaluate("return math.constants.N_A")
        XCTAssertEqual(result.numberValue!, 6.02214076e23, accuracy: 1e13)
    }

    func testMathConstantsGasConstant() throws {
        let result = try engine.evaluate("return math.constants.R")
        XCTAssertEqual(result.numberValue!, 8.314462618, accuracy: 1e-9)
    }

    func testMathConstantsVacuumPermittivity() throws {
        let result = try engine.evaluate("return math.constants.epsilon_0")
        XCTAssertEqual(result.numberValue!, 8.8541878128e-12, accuracy: 1e-22)
    }

    func testMathConstantsVacuumPermeability() throws {
        let result = try engine.evaluate("return math.constants.mu_0")
        XCTAssertEqual(result.numberValue!, 1.25663706212e-6, accuracy: 1e-16)
    }

    // MARK: - Conversion Factors Tests

    func testMathConstantsDegree() throws {
        let result = try engine.evaluate("return math.constants.degree")
        XCTAssertEqual(result.numberValue!, Double.pi / 180, accuracy: 1e-15)
    }

    func testMathConstantsInch() throws {
        let result = try engine.evaluate("return math.constants.inch")
        XCTAssertEqual(result.numberValue!, 0.0254, accuracy: 1e-10)
    }

    func testMathConstantsFoot() throws {
        let result = try engine.evaluate("return math.constants.foot")
        XCTAssertEqual(result.numberValue!, 0.3048, accuracy: 1e-10)
    }

    func testMathConstantsPound() throws {
        let result = try engine.evaluate("return math.constants.pound")
        XCTAssertEqual(result.numberValue!, 0.45359237, accuracy: 1e-10)
    }

    func testMathConstantsMinute() throws {
        let result = try engine.evaluate("return math.constants.minute")
        XCTAssertEqual(result.numberValue, 60)
    }

    func testMathConstantsHour() throws {
        let result = try engine.evaluate("return math.constants.hour")
        XCTAssertEqual(result.numberValue, 3600)
    }

    func testMathConstantsDay() throws {
        let result = try engine.evaluate("return math.constants.day")
        XCTAssertEqual(result.numberValue, 86400)
    }

    // MARK: - math.linalg Through math Namespace

    func testMathLinalgMatrixCreation() throws {
        let result = try engine.evaluate("""
            local m = math.linalg.matrix({{1,2},{3,4}})
            return m:rows() * 10 + m:cols()
            """)
        XCTAssertEqual(result.numberValue, 22)
    }

    func testMathLinalgSolve() throws {
        let result = try engine.evaluate("""
            local A = math.linalg.matrix({{2,1},{1,3}})
            local b = math.linalg.vector({4, 7})
            local x = math.linalg.solve(A, b)
            local arr = x:toarray()
            return arr[1] + arr[2]
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    // MARK: - Module Loaded Flag

    func testMathSciModuleLoaded() throws {
        let result = try engine.evaluate("return luaswift.mathsci.loaded")
        XCTAssertEqual(result.boolValue, true)
    }

    func testMathSciModuleVersion() throws {
        let result = try engine.evaluate("return luaswift.mathsci.version")
        XCTAssertEqual(result.stringValue, "1.0.0")
    }

    // MARK: - Integration Tests

    func testCombinedStatisticalComputation() throws {
        // Test using multiple math subnamespaces together
        let result = try engine.evaluate("""
            local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            local mean = math.stats.mean(data)
            local stddev = math.stats.stddev(data)
            local gamma_val = math.special.gamma(mean)
            return math.floor(gamma_val)
            """)
        // mean = 5.5, gamma(5.5) ≈ 52.34
        XCTAssertEqual(result.numberValue!, 52, accuracy: 1)
    }

    func testPhysicsCalculation() throws {
        // Test using physical constants
        let result = try engine.evaluate("""
            local c = math.constants.c
            local h = math.constants.h
            -- Energy of a photon with wavelength 500nm (green light)
            local wavelength = 500e-9  -- meters
            local energy = h * c / wavelength  -- E = hc/λ
            return energy
            """)
        // Expected: ~3.97e-19 J
        XCTAssertEqual(result.numberValue!, 3.97e-19, accuracy: 1e-21)
    }

    func testUnitConversion() throws {
        let result = try engine.evaluate("""
            local mile = math.constants.mile
            local foot = math.constants.foot
            -- Convert 1 mile to feet
            return mile / foot
            """)
        XCTAssertEqual(result.numberValue!, 5280, accuracy: 1e-10)
    }

    func testAngleConversion() throws {
        let result = try engine.evaluate("""
            local deg = math.constants.degree
            -- 90 degrees to radians
            return 90 * deg
            """)
        XCTAssertEqual(result.numberValue!, Double.pi / 2, accuracy: 1e-15)
    }
}
