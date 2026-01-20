//
//  LuaValueTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//

import XCTest
@testable import LuaSwift

final class LuaValueTests: XCTestCase {

    // MARK: - Type Tests

    func testStringValue() {
        let value: LuaValue = .string("hello")
        XCTAssertEqual(value.stringValue, "hello")
        XCTAssertNil(value.numberValue)
        XCTAssertNil(value.boolValue)
        XCTAssertTrue(value.isTruthy)
    }

    func testNumberValue() {
        let value: LuaValue = .number(42.5)
        XCTAssertEqual(value.numberValue, 42.5)
        XCTAssertNil(value.intValue)  // 42.5 has fractional part, so intValue is nil
        XCTAssertNil(value.stringValue)
        XCTAssertTrue(value.isTruthy)
    }

    func testIntValueWithWholeNumber() {
        // Whole numbers should return Int value
        XCTAssertEqual(LuaValue.number(42.0).intValue, 42)
        XCTAssertEqual(LuaValue.number(0.0).intValue, 0)
        XCTAssertEqual(LuaValue.number(-3.0).intValue, -3)
        XCTAssertEqual(LuaValue.number(1000000.0).intValue, 1000000)
    }

    func testIntValueWithFractionalNumber() {
        // Fractional numbers should return nil
        XCTAssertNil(LuaValue.number(1.5).intValue)
        XCTAssertNil(LuaValue.number(-2.7).intValue)
        XCTAssertNil(LuaValue.number(0.001).intValue)
        XCTAssertNil(LuaValue.number(42.5).intValue)
    }

    func testIntValueWithNonNumber() {
        // Non-numbers should return nil
        XCTAssertNil(LuaValue.string("42").intValue)
        XCTAssertNil(LuaValue.bool(true).intValue)
        XCTAssertNil(LuaValue.nil.intValue)
        XCTAssertNil(LuaValue.table([:]).intValue)
    }

    func testBoolValue() {
        let trueValue: LuaValue = .bool(true)
        let falseValue: LuaValue = .bool(false)

        XCTAssertEqual(trueValue.boolValue, true)
        XCTAssertEqual(falseValue.boolValue, false)
        XCTAssertTrue(trueValue.isTruthy)
        XCTAssertFalse(falseValue.isTruthy)
    }

    func testNilValue() {
        let value: LuaValue = .nil
        XCTAssertTrue(value.isNil)
        XCTAssertFalse(value.isTruthy)
        XCTAssertEqual(value.asString, "")
    }

    func testTableValue() {
        let value: LuaValue = .table(["key": .string("value")])
        XCTAssertNotNil(value.tableValue)
        XCTAssertEqual(value.tableValue?["key"]?.stringValue, "value")
        XCTAssertTrue(value.isTruthy)
    }

    func testArrayValue() {
        let value: LuaValue = .array([.number(1), .number(2), .number(3)])
        XCTAssertNotNil(value.arrayValue)
        XCTAssertEqual(value.arrayValue?.count, 3)
        XCTAssertEqual(value.arrayValue?[0].numberValue, 1)
    }

    func testComplexValue() {
        let value: LuaValue = .complex(re: 3, im: 4)
        XCTAssertNotNil(value.complexValue)
        XCTAssertEqual(value.complexValue?.re, 3)
        XCTAssertEqual(value.complexValue?.im, 4)
        XCTAssertTrue(value.isComplex)
        XCTAssertTrue(value.isScalar)
        XCTAssertTrue(value.isTruthy)
        XCTAssertNil(value.numberValue)
        XCTAssertNil(value.tableValue)
    }

    func testNumberIsScalar() {
        let value: LuaValue = .number(42)
        XCTAssertTrue(value.isScalar)
        XCTAssertFalse(value.isComplex)
    }

    func testComplexAsString() {
        let positive: LuaValue = .complex(re: 3, im: 4)
        let negative: LuaValue = .complex(re: 3, im: -4)
        XCTAssertEqual(positive.asString, "3.0+4.0i")
        XCTAssertEqual(negative.asString, "3.0-4.0i")
    }

    func testComplexDescription() {
        let positive: LuaValue = .complex(re: 3, im: 4)
        let negative: LuaValue = .complex(re: 3, im: -4)
        XCTAssertEqual(positive.description, "3.0+4.0i")
        XCTAssertEqual(negative.description, "3.0-4.0i")
    }

    func testComplexEquality() {
        let z1: LuaValue = .complex(re: 3, im: 4)
        let z2: LuaValue = .complex(re: 3, im: 4)
        let z3: LuaValue = .complex(re: 3, im: 5)
        XCTAssertEqual(z1, z2)
        XCTAssertNotEqual(z1, z3)
    }

    // MARK: - asString Tests

    func testAsStringConversion() {
        XCTAssertEqual(LuaValue.string("hello").asString, "hello")
        XCTAssertEqual(LuaValue.number(42).asString, "42")
        XCTAssertEqual(LuaValue.number(3.14).asString, "3.14")
        XCTAssertEqual(LuaValue.bool(true).asString, "true")
        XCTAssertEqual(LuaValue.bool(false).asString, "false")
        XCTAssertEqual(LuaValue.nil.asString, "")
    }

    // MARK: - Literal Tests

    func testStringLiteral() {
        let value: LuaValue = "hello"
        XCTAssertEqual(value.stringValue, "hello")
    }

    func testIntegerLiteral() {
        let value: LuaValue = 42
        XCTAssertEqual(value.numberValue, 42)
    }

    func testFloatLiteral() {
        let value: LuaValue = 3.14
        XCTAssertEqual(value.numberValue, 3.14)
    }

    func testBooleanLiteral() {
        let trueValue: LuaValue = true
        let falseValue: LuaValue = false
        XCTAssertEqual(trueValue.boolValue, true)
        XCTAssertEqual(falseValue.boolValue, false)
    }

    func testArrayLiteral() {
        let value: LuaValue = [1, 2, 3]
        XCTAssertEqual(value.arrayValue?.count, 3)
    }

    func testDictionaryLiteral() {
        let value: LuaValue = ["name": "John", "age": 30]
        XCTAssertEqual(value.tableValue?["name"]?.stringValue, "John")
        XCTAssertEqual(value.tableValue?["age"]?.numberValue, 30)
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        XCTAssertEqual(LuaValue.string("hello"), LuaValue.string("hello"))
        XCTAssertNotEqual(LuaValue.string("hello"), LuaValue.string("world"))
        XCTAssertEqual(LuaValue.number(42), LuaValue.number(42))
        XCTAssertEqual(LuaValue.bool(true), LuaValue.bool(true))
        XCTAssertEqual(LuaValue.nil, LuaValue.nil)
    }

    // MARK: - Description Tests

    func testDescription() {
        XCTAssertEqual(LuaValue.string("hello").description, "\"hello\"")
        XCTAssertEqual(LuaValue.number(42).description, "42.0")
        XCTAssertEqual(LuaValue.bool(true).description, "true")
        XCTAssertEqual(LuaValue.nil.description, "nil")
    }
}
