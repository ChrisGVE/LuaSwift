//
//  ComplexHelperTests.swift
//  LuaSwiftTests
//
//  Created by Claude on 2026-01-10.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
import XCTest
@testable import LuaSwift

final class ComplexHelperTests: XCTestCase {

    // MARK: - isComplex Tests

    func testIsComplexWithComplexTable() {
        let value = LuaValue.table(["re": .number(3.0), "im": .number(4.0)])
        XCTAssertTrue(ComplexHelper.isComplex(value))
    }

    func testIsComplexWithRealNumber() {
        let value = LuaValue.number(5.0)
        XCTAssertFalse(ComplexHelper.isComplex(value))
    }

    func testIsComplexWithString() {
        let value = LuaValue.string("not a number")
        XCTAssertFalse(ComplexHelper.isComplex(value))
    }

    func testIsComplexWithNil() {
        let value = LuaValue.nil
        XCTAssertFalse(ComplexHelper.isComplex(value))
    }

    func testIsComplexWithIncompleteTable() {
        // Table with only re key
        let value1 = LuaValue.table(["re": .number(3.0)])
        XCTAssertFalse(ComplexHelper.isComplex(value1))

        // Table with only im key
        let value2 = LuaValue.table(["im": .number(4.0)])
        XCTAssertFalse(ComplexHelper.isComplex(value2))

        // Table with wrong key types
        let value3 = LuaValue.table(["re": .string("3"), "im": .number(4.0)])
        XCTAssertFalse(ComplexHelper.isComplex(value3))
    }

    func testIsComplexWithZeroImaginary() {
        let value = LuaValue.table(["re": .number(5.0), "im": .number(0.0)])
        XCTAssertTrue(ComplexHelper.isComplex(value))
    }

    // MARK: - toComplex Tests

    func testToComplexFromComplexTable() {
        let value = LuaValue.table(["re": .number(3.0), "im": .number(4.0)])
        let result = ComplexHelper.toComplex(value)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, 3.0, accuracy: 1e-15)
        XCTAssertEqual(result!.im, 4.0, accuracy: 1e-15)
    }

    func testToComplexFromRealNumber() {
        let value = LuaValue.number(5.0)
        let result = ComplexHelper.toComplex(value)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, 5.0, accuracy: 1e-15)
        XCTAssertEqual(result!.im, 0.0, accuracy: 1e-15)
    }

    func testToComplexFromInvalidValue() {
        let value = LuaValue.string("invalid")
        let result = ComplexHelper.toComplex(value)
        XCTAssertNil(result)
    }

    func testToComplexFromNil() {
        let result = ComplexHelper.toComplex(.nil)
        XCTAssertNil(result)
    }

    func testToComplexFromNegativeValues() {
        let value = LuaValue.table(["re": .number(-2.5), "im": .number(-3.5)])
        let result = ComplexHelper.toComplex(value)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, -2.5, accuracy: 1e-15)
        XCTAssertEqual(result!.im, -3.5, accuracy: 1e-15)
    }

    // MARK: - toLua Tests

    func testToLuaCreatesProperTable() {
        let result = ComplexHelper.toLua(3.0, 4.0)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table value with re and im")
            return
        }
        XCTAssertEqual(re, 3.0, accuracy: 1e-15)
        XCTAssertEqual(im, 4.0, accuracy: 1e-15)
    }

    func testToLuaWithZeros() {
        let result = ComplexHelper.toLua(0.0, 0.0)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table value with re and im")
            return
        }
        XCTAssertEqual(re, 0.0, accuracy: 1e-15)
        XCTAssertEqual(im, 0.0, accuracy: 1e-15)
    }

    func testToLuaWithNegatives() {
        let result = ComplexHelper.toLua(-1.5, -2.5)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table value with re and im")
            return
        }
        XCTAssertEqual(re, -1.5, accuracy: 1e-15)
        XCTAssertEqual(im, -2.5, accuracy: 1e-15)
    }

    // MARK: - toResult Tests

    func testToResultReturnsRealForSmallImaginary() {
        // Imaginary part is negligible (1e-16 < 1e-15 default tolerance)
        let result = ComplexHelper.toResult(5.0, 1e-16)
        XCTAssertNil(result.tableValue)  // Should not be a table
        guard let num = result.numberValue else {
            XCTFail("Expected number value")
            return
        }
        XCTAssertEqual(num, 5.0, accuracy: 1e-15)
    }

    func testToResultReturnsComplexForSignificantImaginary() {
        // Imaginary part is significant (0.001 > 1e-15)
        let result = ComplexHelper.toResult(5.0, 0.001)
        XCTAssertNotNil(result.tableValue)
        guard let table = result.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else {
            XCTFail("Expected table value with re and im")
            return
        }
        XCTAssertEqual(re, 5.0, accuracy: 1e-15)
        XCTAssertEqual(im, 0.001, accuracy: 1e-15)
    }

    func testToResultWithCustomTolerance() {
        // With tolerance of 0.01, im=0.005 should be considered negligible
        let result1 = ComplexHelper.toResult(5.0, 0.005, tolerance: 0.01)
        XCTAssertNil(result1.tableValue)
        guard let num = result1.numberValue else {
            XCTFail("Expected number value")
            return
        }
        XCTAssertEqual(num, 5.0, accuracy: 1e-15)

        // With tolerance of 0.001, im=0.005 should be significant
        let result2 = ComplexHelper.toResult(5.0, 0.005, tolerance: 0.001)
        XCTAssertNotNil(result2.tableValue)
    }

    func testToResultHandlesNegativeImaginary() {
        // Negative imaginary part with small absolute value
        let result = ComplexHelper.toResult(3.0, -1e-16)
        XCTAssertNil(result.tableValue)
        guard let num = result.numberValue else {
            XCTFail("Expected number value")
            return
        }
        XCTAssertEqual(num, 3.0, accuracy: 1e-15)
    }

    // MARK: - Complex Arithmetic Helper Tests

    func testMultiply() {
        // (3 + 4i) * (1 + 2i) = (3*1 - 4*2) + (3*2 + 4*1)i = -5 + 10i
        let result = ComplexHelper.multiply(3, 4, 1, 2)
        XCTAssertEqual(result.re, -5.0, accuracy: 1e-15)
        XCTAssertEqual(result.im, 10.0, accuracy: 1e-15)
    }

    func testMultiplyWithZero() {
        let result = ComplexHelper.multiply(3, 4, 0, 0)
        XCTAssertEqual(result.re, 0.0, accuracy: 1e-15)
        XCTAssertEqual(result.im, 0.0, accuracy: 1e-15)
    }

    func testMultiplyPureImaginary() {
        // i * i = -1
        let result = ComplexHelper.multiply(0, 1, 0, 1)
        XCTAssertEqual(result.re, -1.0, accuracy: 1e-15)
        XCTAssertEqual(result.im, 0.0, accuracy: 1e-15)
    }

    func testDivide() {
        // (3 + 4i) / (1 + 2i)
        // = [(3*1 + 4*2) + (4*1 - 3*2)i] / (1 + 4)
        // = (11 - 2i) / 5 = 2.2 - 0.4i
        let result = ComplexHelper.divide(3, 4, 1, 2)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, 2.2, accuracy: 1e-15)
        XCTAssertEqual(result!.im, -0.4, accuracy: 1e-15)
    }

    func testDivideByZero() {
        let result = ComplexHelper.divide(3, 4, 0, 0)
        XCTAssertNil(result)
    }

    func testDivideByPureImaginary() {
        // (1 + 0i) / (0 + 1i) = 1/i = -i
        let result = ComplexHelper.divide(1, 0, 0, 1)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, 0.0, accuracy: 1e-15)
        XCTAssertEqual(result!.im, -1.0, accuracy: 1e-15)
    }

    func testSqrt() {
        // sqrt(3 + 4i) = 2 + i (can verify: (2+i)^2 = 4 + 4i - 1 = 3 + 4i)
        let result = ComplexHelper.sqrt(3, 4)
        XCTAssertEqual(result.re, 2.0, accuracy: 1e-10)
        XCTAssertEqual(result.im, 1.0, accuracy: 1e-10)
    }

    func testSqrtOfNegativeReal() {
        // sqrt(-1) = i
        let result = ComplexHelper.sqrt(-1, 0)
        XCTAssertEqual(result.re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(result.im, 1.0, accuracy: 1e-10)
    }

    func testSqrtOfPositiveReal() {
        // sqrt(4) = 2
        let result = ComplexHelper.sqrt(4, 0)
        XCTAssertEqual(result.re, 2.0, accuracy: 1e-10)
        XCTAssertEqual(result.im, 0.0, accuracy: 1e-10)
    }

    func testSqrtOfZero() {
        let result = ComplexHelper.sqrt(0, 0)
        XCTAssertEqual(result.re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(result.im, 0.0, accuracy: 1e-10)
    }

    func testLog() {
        // log(e) = 1 + 0i
        let result = ComplexHelper.log(M_E, 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, 1.0, accuracy: 1e-10)
        XCTAssertEqual(result!.im, 0.0, accuracy: 1e-10)
    }

    func testLogOfNegativeOne() {
        // log(-1) = 0 + pi*i
        let result = ComplexHelper.log(-1, 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(result!.im, Double.pi, accuracy: 1e-10)
    }

    func testLogOfI() {
        // log(i) = log(e^(i*pi/2)) = i*pi/2
        let result = ComplexHelper.log(0, 1)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(result!.im, Double.pi / 2, accuracy: 1e-10)
    }

    func testLogOfZero() {
        let result = ComplexHelper.log(0, 0)
        XCTAssertNil(result)
    }

    func testExp() {
        // exp(0) = 1
        let result1 = ComplexHelper.exp(0, 0)
        XCTAssertEqual(result1.re, 1.0, accuracy: 1e-10)
        XCTAssertEqual(result1.im, 0.0, accuracy: 1e-10)

        // exp(i*pi) = -1 (Euler's identity)
        let result2 = ComplexHelper.exp(0, Double.pi)
        XCTAssertEqual(result2.re, -1.0, accuracy: 1e-10)
        XCTAssertEqual(result2.im, 0.0, accuracy: 1e-10)
    }

    func testExpOfOne() {
        // exp(1 + 0i) = e
        let result = ComplexHelper.exp(1, 0)
        XCTAssertEqual(result.re, M_E, accuracy: 1e-10)
        XCTAssertEqual(result.im, 0.0, accuracy: 1e-10)
    }

    func testPow() {
        // (1 + i)^2 = 1 + 2i - 1 = 2i
        let result = ComplexHelper.pow(1, 1, 2)
        XCTAssertEqual(result.re, 0.0, accuracy: 1e-10)
        XCTAssertEqual(result.im, 2.0, accuracy: 1e-10)
    }

    func testPowWithZeroExponent() {
        // z^0 = 1 for any z
        let result = ComplexHelper.pow(3, 4, 0)
        XCTAssertEqual(result.re, 1.0, accuracy: 1e-10)
        XCTAssertEqual(result.im, 0.0, accuracy: 1e-10)
    }

    func testPowWithNegativeExponent() {
        // 2^(-1) = 0.5
        let result = ComplexHelper.pow(2, 0, -1)
        XCTAssertEqual(result.re, 0.5, accuracy: 1e-10)
        XCTAssertEqual(result.im, 0.0, accuracy: 1e-10)
    }

    // MARK: - Roundtrip Tests

    func testToLuaAndToComplexRoundtrip() {
        let original = (re: 3.14159, im: 2.71828)
        let luaValue = ComplexHelper.toLua(original.re, original.im)
        let extracted = ComplexHelper.toComplex(luaValue)

        XCTAssertNotNil(extracted)
        XCTAssertEqual(extracted!.re, original.re, accuracy: 1e-15)
        XCTAssertEqual(extracted!.im, original.im, accuracy: 1e-15)
    }

    func testSqrtAndPowRoundtrip() {
        // sqrt(z)^2 should equal z
        let z = (re: 3.0, im: 4.0)
        let sqrtZ = ComplexHelper.sqrt(z.re, z.im)
        let result = ComplexHelper.pow(sqrtZ.re, sqrtZ.im, 2)

        XCTAssertEqual(result.re, z.re, accuracy: 1e-10)
        XCTAssertEqual(result.im, z.im, accuracy: 1e-10)
    }

    func testExpAndLogRoundtrip() {
        // log(exp(z)) should equal z (for principal branch)
        let z = (re: 1.5, im: 0.5)
        let expZ = ComplexHelper.exp(z.re, z.im)
        let result = ComplexHelper.log(expZ.re, expZ.im)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.re, z.re, accuracy: 1e-10)
        XCTAssertEqual(result!.im, z.im, accuracy: 1e-10)
    }
}
#endif  // LUASWIFT_NUMERICSWIFT
