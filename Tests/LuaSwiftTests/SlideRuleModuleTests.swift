//
//  SlideRuleModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-05.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class SlideRuleModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        SlideRuleModule.register(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Basic Creation Tests

    func testSlideRuleCreation() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return tostring(rule)
        """)

        guard let str = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(str.contains("sliderule"))
    }

    func testSlideRuleWithModel() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new({model = "basic"})
            return #rule:available_scales()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(count, 4)  // basic model has C, D, A, B
    }

    func testSlideRuleWithPrecision() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new({precision = 4})
            return rule.precision
        """)

        guard let precision = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(precision, 4)
    }

    func testPredefinedModels() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            return {
                basic = sr.models.basic ~= nil,
                scientific = sr.models.scientific ~= nil,
                engineering = sr.models.engineering ~= nil,
                log_log = sr.models.log_log ~= nil,
                trig = sr.models.trig ~= nil
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["basic"]?.boolValue, true)
        XCTAssertEqual(table["scientific"]?.boolValue, true)
        XCTAssertEqual(table["engineering"]?.boolValue, true)
        XCTAssertEqual(table["log_log"]?.boolValue, true)
        XCTAssertEqual(table["trig"]?.boolValue, true)
    }

    // MARK: - Scale Definition Tests

    func testScaleDefinitions() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            return {
                hasC = sr.scales.C ~= nil,
                hasD = sr.scales.D ~= nil,
                hasCI = sr.scales.CI ~= nil,
                hasA = sr.scales.A ~= nil,
                hasS = sr.scales.S ~= nil,
                hasLL3 = sr.scales.LL3 ~= nil
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["hasC"]?.boolValue, true)
        XCTAssertEqual(table["hasD"]?.boolValue, true)
        XCTAssertEqual(table["hasCI"]?.boolValue, true)
        XCTAssertEqual(table["hasA"]?.boolValue, true)
        XCTAssertEqual(table["hasS"]?.boolValue, true)
        XCTAssertEqual(table["hasLL3"]?.boolValue, true)
    }

    func testHasScale() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new({model = "scientific"})
            return {
                hasC = rule:has_scale('C'),
                hasD = rule:has_scale('D'),
                hasCI = rule:has_scale('CI'),
                hasXYZ = rule:has_scale('XYZ')
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["hasC"]?.boolValue, true)
        XCTAssertEqual(table["hasD"]?.boolValue, true)
        XCTAssertEqual(table["hasCI"]?.boolValue, true)
        XCTAssertEqual(table["hasXYZ"]?.boolValue, false)
    }

    // MARK: - Cursor State Tests

    func testSetAndReadCursor() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            rule:set('D', 5)
            return rule:read('D')
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 5, accuracy: 0.01)
    }

    func testClearState() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            rule:set('D', 5)
            rule:clear()
            return rule.cursor_position == nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Multiplication Tests (C/D Scales)

    func testMultiply2x3() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:multiply(2, 3)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 6, accuracy: 0.01)
    }

    func testMultiply7x8() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:multiply(7, 8)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 56, accuracy: 0.5)  // Slide rule precision
    }

    func testMultiplyDecimals() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:multiply(1.5, 2.5)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 3.75, accuracy: 0.05)
    }

    func testMultiplyWithDecimalShift() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:multiply(25, 40)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 1000, accuracy: 10)
    }

    // MARK: - Division Tests (C/D Scales)

    func testDivide15by3() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:divide(15, 3)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 5, accuracy: 0.05)
    }

    func testDivide8by4() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:divide(8, 4)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 2, accuracy: 0.02)
    }

    func testDivideDecimals() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:divide(7.5, 2.5)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 3, accuracy: 0.03)
    }

    // MARK: - Reciprocal Tests (CI Scale)

    func testReciprocal2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:reciprocal(2)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 0.5, accuracy: 0.01)
    }

    func testReciprocal4() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:reciprocal(4)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 0.25, accuracy: 0.01)
    }

    func testReciprocal5() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:reciprocal(5)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 0.2, accuracy: 0.01)
    }

    // MARK: - Square Tests (A/D Scales)

    func testSquare2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:square(2)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 4, accuracy: 0.1)
    }

    func testSquare3() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:square(3)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 9, accuracy: 0.1)
    }

    func testSquare5() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:square(5)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 25, accuracy: 0.3)
    }

    func testSquare7() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:square(7)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 49, accuracy: 0.5)
    }

    // MARK: - Square Root Tests (A/D Scales)

    func testSqrt4() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sqrt(4)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 2, accuracy: 0.02)
    }

    func testSqrt9() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sqrt(9)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 3, accuracy: 0.03)
    }

    func testSqrt16() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sqrt(16)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 4, accuracy: 0.04)
    }

    func testSqrt25() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sqrt(25)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 5, accuracy: 0.05)
    }

    func testSqrt50() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sqrt(50)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, sqrt(50), accuracy: 0.1)
    }

    // MARK: - Cube Tests (K/D Scales)

    func testCube2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cube(2)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 8, accuracy: 0.2)
    }

    func testCube3() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cube(3)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 27, accuracy: 0.5)
    }

    func testCube4() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cube(4)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 64, accuracy: 1.5)  // Slide rule precision
    }

    func testCube5() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cube(5)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 125, accuracy: 2.5)  // Slide rule precision
    }

    // MARK: - Cube Root Tests (K/D Scales)

    func testCbrt8() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cbrt(8)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 2, accuracy: 0.05)
    }

    func testCbrt27() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cbrt(27)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 3, accuracy: 0.05)
    }

    func testCbrt64() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cbrt(64)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 4, accuracy: 0.1)
    }

    func testCbrt125() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cbrt(125)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 5, accuracy: 0.15)  // Slide rule precision
    }

    func testCbrt500() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cbrt(500)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, pow(500, 1.0/3.0), accuracy: 0.2)
    }

    // MARK: - Power Tests (LL Scales)

    func testPower2to3() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:power(2, 3)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 8, accuracy: 0.2)
    }

    func testPower1_5to2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:power(1.5, 2)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 2.25, accuracy: 0.05)
    }

    func testPowerEto1() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:power(math.exp(1), 1)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, exp(1), accuracy: 0.05)
    }

    func testPower10to0_5() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:power(10, 0.5)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, sqrt(10), accuracy: 0.1)
    }

    // MARK: - Natural Log Tests (LL Scales)

    func testLnE() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:ln(math.exp(1))
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 1, accuracy: 0.01)
    }

    func testLnE2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:ln(math.exp(2))
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 2, accuracy: 0.02)
    }

    func testLn2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:ln(2)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, log(2), accuracy: 0.01)
    }

    // MARK: - Exponential Tests (LL Scales)

    func testExp0_5() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:exp(0.5)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, exp(0.5), accuracy: 0.02)
    }

    func testExp1() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:exp(1)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, exp(1), accuracy: 0.03)
    }

    func testExp2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:exp(2)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, exp(2), accuracy: 0.1)
    }

    // MARK: - Sine Tests (S Scale)

    func testSin30() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sin_deg(30)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 0.5, accuracy: 0.01)
    }

    func testSin45() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sin_deg(45)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, sin(Double.pi / 4), accuracy: 0.01)
    }

    func testSin60() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sin_deg(60)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, sin(Double.pi / 3), accuracy: 0.01)
    }

    func testSin90() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sin_deg(90)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 1, accuracy: 0.01)
    }

    // MARK: - Tangent Tests (T Scale)

    func testTan10() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:tan_deg(10)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, tan(10 * Double.pi / 180), accuracy: 0.01)
    }

    func testTan20() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:tan_deg(20)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, tan(20 * Double.pi / 180), accuracy: 0.01)
    }

    func testTan30() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:tan_deg(30)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, tan(30 * Double.pi / 180), accuracy: 0.01)
    }

    func testTan45() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:tan_deg(45)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 1, accuracy: 0.01)
    }

    // MARK: - Small Angle Approximation Tests (ST Scale)

    func testSmallAngle1() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:small_angle_trig(1)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        // For small angles, sin ≈ tan ≈ radians
        let expected = 1 * Double.pi / 180
        XCTAssertEqual(value, expected, accuracy: 0.001)
    }

    func testSmallAngle2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:small_angle_trig(2)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        let expected = 2 * Double.pi / 180
        XCTAssertEqual(value, expected, accuracy: 0.001)
    }

    func testSmallAngle3() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:small_angle_trig(3)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        let expected = 3 * Double.pi / 180
        XCTAssertEqual(value, expected, accuracy: 0.001)
    }

    func testSmallAngle5() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:small_angle_trig(5)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        let expected = 5 * Double.pi / 180
        XCTAssertEqual(value, expected, accuracy: 0.001)
    }

    // MARK: - Pi Multiplication Tests (CF/DF Scales)

    func testPiMultiply1() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:pi_multiply(1)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, Double.pi, accuracy: 0.01)
    }

    func testPiMultiply2() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:pi_multiply(2)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 2 * Double.pi, accuracy: 0.02)
    }

    func testPiMultiply3() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:pi_multiply(3)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 3 * Double.pi, accuracy: 0.03)
    }

    // MARK: - Method Chaining Tests

    func testMethodChainingSetRead() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:set('D', 3):read('D')
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 3, accuracy: 0.03)
    }

    func testMethodChainingClear() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            rule:set('D', 5):clear()
            return rule.cursor_position == nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Type and Metadata Tests

    func testSlideRuleType() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule.__luaswift_type
        """)

        guard let typeStr = result.stringValue else {
            XCTFail("Expected string")
            return
        }

        XCTAssertEqual(typeStr, "sliderule")
    }

    func testAvailableScales() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new({model = "trig"})
            local scales = rule:available_scales()
            return #scales
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(count, 5)  // trig model has C, D, S, T, ST
    }

    // MARK: - Global Alias Tests

    func testGlobalAlias() throws {
        // This test requires ModuleRegistry to be installed
        let engine2 = try LuaEngine()
        ModuleRegistry.installModules(in: engine2)

        let result = try engine2.evaluate("""
            return sliderule ~= nil and luaswift.sliderule ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Edge Cases and Error Handling

    func testMultiplySmallNumbers() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:multiply(0.5, 0.3)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 0.15, accuracy: 0.01)
    }

    func testDivideSmallByLarge() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:divide(3, 100)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 0.03, accuracy: 0.003)
    }

    func testSqrtLargeNumber() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:sqrt(100)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 10, accuracy: 0.1)
    }

    func testCbrtLargeNumber() throws {
        let result = try engine.evaluate("""
            local sr = require("luaswift.sliderule")
            local rule = sr.new()
            return rule:cbrt(1000)
        """)

        guard let value = result.numberValue else {
            XCTFail("Expected number")
            return
        }

        XCTAssertEqual(value, 10, accuracy: 0.2)
    }
}
