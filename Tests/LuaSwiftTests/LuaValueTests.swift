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
        XCTAssertEqual(value.intValue, 42)
        XCTAssertNil(value.stringValue)
        XCTAssertTrue(value.isTruthy)
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
