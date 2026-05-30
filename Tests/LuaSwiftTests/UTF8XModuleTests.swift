//
//  UTF8XModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import LuaSwift

final class UTF8XModuleTests: XCTestCase {

  var engine: LuaEngine!

  override func setUp() {
    super.setUp()
    engine = try! LuaEngine()
    UTF8XModule.register(in: engine)
  }

  override func tearDown() {
    engine = nil
    super.tearDown()
  }

  // MARK: - Width Tests

  func testWidthASCII() throws {
    let result = try engine.evaluate("return luaswift.utf8x.width('Hello')")
    XCTAssertEqual(result.numberValue, 5)
  }

  func testWidthCJK() throws {
    let result = try engine.evaluate("return luaswift.utf8x.width('世界')")
    XCTAssertEqual(result.numberValue, 4)  // 2 chars * 2 width
  }

  func testWidthMixed() throws {
    let result = try engine.evaluate("return luaswift.utf8x.width('Hello世界')")
    XCTAssertEqual(result.numberValue, 9)  // 5 + 4
  }

  func testWidthEmoji() throws {
    let result = try engine.evaluate("return luaswift.utf8x.width('😀😁')")
    XCTAssertEqual(result.numberValue, 4)  // 2 emoji * 2 width
  }

  func testWidthHiragana() throws {
    let result = try engine.evaluate("return luaswift.utf8x.width('こんにちは')")
    XCTAssertEqual(result.numberValue, 10)  // 5 chars * 2 width
  }

  func testWidthFullWidth() throws {
    let result = try engine.evaluate("return luaswift.utf8x.width('Ａ')")
    XCTAssertEqual(result.numberValue, 2)  // Full-width A
  }

  func testWidthEmpty() throws {
    let result = try engine.evaluate("return luaswift.utf8x.width('')")
    XCTAssertEqual(result.numberValue, 0)
  }

  // MARK: - Substring Tests

  func testSubBasic() throws {
    let result = try engine.evaluate("return luaswift.utf8x.sub('Hello', 1, 3)")
    XCTAssertEqual(result.stringValue, "Hel")
  }

  func testSubCJK() throws {
    let result = try engine.evaluate("return luaswift.utf8x.sub('Hello世界', 6, 7)")
    XCTAssertEqual(result.stringValue, "世界")
  }

  func testSubNegativeStart() throws {
    let result = try engine.evaluate("return luaswift.utf8x.sub('Hello', -2, 5)")
    XCTAssertEqual(result.stringValue, "lo")
  }

  func testSubNegativeEnd() throws {
    let result = try engine.evaluate("return luaswift.utf8x.sub('Hello', 1, -1)")
    XCTAssertEqual(result.stringValue, "Hello")
  }

  func testSubNegativeBoth() throws {
    let result = try engine.evaluate("return luaswift.utf8x.sub('Hello', -4, -2)")
    XCTAssertEqual(result.stringValue, "ell")
  }

  func testSubDefaultEnd() throws {
    let result = try engine.evaluate("return luaswift.utf8x.sub('Hello', 3)")
    XCTAssertEqual(result.stringValue, "llo")
  }

  func testSubOutOfBounds() throws {
    let result = try engine.evaluate("return luaswift.utf8x.sub('Hello', 10, 20)")
    XCTAssertEqual(result.stringValue, "")
  }

  func testSubEmoji() throws {
    let result = try engine.evaluate("return luaswift.utf8x.sub('😀😁😂', 2, 2)")
    XCTAssertEqual(result.stringValue, "😁")
  }

  // MARK: - Reverse Tests

  func testReverseASCII() throws {
    let result = try engine.evaluate("return luaswift.utf8x.reverse('Hello')")
    XCTAssertEqual(result.stringValue, "olleH")
  }

  func testReverseCJK() throws {
    let result = try engine.evaluate("return luaswift.utf8x.reverse('世界')")
    XCTAssertEqual(result.stringValue, "界世")
  }

  func testReverseMixed() throws {
    let result = try engine.evaluate("return luaswift.utf8x.reverse('Hello世界')")
    XCTAssertEqual(result.stringValue, "界世olleH")
  }

  func testReverseEmoji() throws {
    let result = try engine.evaluate("return luaswift.utf8x.reverse('😀😁😂')")
    XCTAssertEqual(result.stringValue, "😂😁😀")
  }

  func testReverseEmpty() throws {
    let result = try engine.evaluate("return luaswift.utf8x.reverse('')")
    XCTAssertEqual(result.stringValue, "")
  }

  // MARK: - Case Conversion Tests

  func testUpperASCII() throws {
    let result = try engine.evaluate("return luaswift.utf8x.upper('hello')")
    XCTAssertEqual(result.stringValue, "HELLO")
  }

  func testUpperAccented() throws {
    let result = try engine.evaluate("return luaswift.utf8x.upper('café')")
    XCTAssertEqual(result.stringValue, "CAFÉ")
  }

  func testUpperMixed() throws {
    let result = try engine.evaluate("return luaswift.utf8x.upper('Hello World')")
    XCTAssertEqual(result.stringValue, "HELLO WORLD")
  }

  func testUpperCJK() throws {
    // CJK characters don't have case
    let result = try engine.evaluate("return luaswift.utf8x.upper('世界')")
    XCTAssertEqual(result.stringValue, "世界")
  }

  func testLowerASCII() throws {
    let result = try engine.evaluate("return luaswift.utf8x.lower('HELLO')")
    XCTAssertEqual(result.stringValue, "hello")
  }

  func testLowerAccented() throws {
    let result = try engine.evaluate("return luaswift.utf8x.lower('CAFÉ')")
    XCTAssertEqual(result.stringValue, "café")
  }

  func testLowerMixed() throws {
    let result = try engine.evaluate("return luaswift.utf8x.lower('Hello World')")
    XCTAssertEqual(result.stringValue, "hello world")
  }

  func testLowerCJK() throws {
    // CJK characters don't have case
    let result = try engine.evaluate("return luaswift.utf8x.lower('世界')")
    XCTAssertEqual(result.stringValue, "世界")
  }

  // MARK: - Length Tests

  func testLenASCII() throws {
    let result = try engine.evaluate("return luaswift.utf8x.len('Hello')")
    XCTAssertEqual(result.numberValue, 5)
  }

  func testLenCJK() throws {
    let result = try engine.evaluate("return luaswift.utf8x.len('世界')")
    XCTAssertEqual(result.numberValue, 2)
  }

  func testLenMixed() throws {
    let result = try engine.evaluate("return luaswift.utf8x.len('Hello世界')")
    XCTAssertEqual(result.numberValue, 7)
  }

  func testLenEmoji() throws {
    let result = try engine.evaluate("return luaswift.utf8x.len('😀😁😂')")
    XCTAssertEqual(result.numberValue, 3)
  }

  func testLenEmpty() throws {
    let result = try engine.evaluate("return luaswift.utf8x.len('')")
    XCTAssertEqual(result.numberValue, 0)
  }

  // MARK: - Character Iterator Tests

  func testCharsASCII() throws {
    let result = try engine.evaluate(
      """
          local chars = {}
          for _, char in ipairs(luaswift.utf8x.chars('Hello')) do
              table.insert(chars, char)
          end
          return chars
      """)

    guard let array = result.arrayValue else {
      XCTFail("Expected array")
      return
    }

    XCTAssertEqual(array.count, 5)
    XCTAssertEqual(array[0].stringValue, "H")
    XCTAssertEqual(array[1].stringValue, "e")
    XCTAssertEqual(array[2].stringValue, "l")
    XCTAssertEqual(array[3].stringValue, "l")
    XCTAssertEqual(array[4].stringValue, "o")
  }

  func testCharsCJK() throws {
    let result = try engine.evaluate(
      """
          local chars = {}
          for _, char in ipairs(luaswift.utf8x.chars('世界')) do
              table.insert(chars, char)
          end
          return chars
      """)

    guard let array = result.arrayValue else {
      XCTFail("Expected array")
      return
    }

    XCTAssertEqual(array.count, 2)
    XCTAssertEqual(array[0].stringValue, "世")
    XCTAssertEqual(array[1].stringValue, "界")
  }

  func testCharsEmoji() throws {
    let result = try engine.evaluate(
      """
          local chars = {}
          for _, char in ipairs(luaswift.utf8x.chars('😀😁')) do
              table.insert(chars, char)
          end
          return chars
      """)

    guard let array = result.arrayValue else {
      XCTFail("Expected array")
      return
    }

    XCTAssertEqual(array.count, 2)
    XCTAssertEqual(array[0].stringValue, "😀")
    XCTAssertEqual(array[1].stringValue, "😁")
  }

  func testCharsEmpty() throws {
    let result = try engine.evaluate(
      """
          local chars = luaswift.utf8x.chars('')
          return #chars
      """)

    XCTAssertEqual(result.numberValue, 0)
  }

  // MARK: - Error Handling Tests

  func testWidthNoArgs() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.width()"))
  }

  func testSubNoArgs() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.sub()"))
  }

  func testSubOneArg() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.sub('Hello')"))
  }

  func testReverseNoArgs() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.reverse()"))
  }

  func testUpperNoArgs() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.upper()"))
  }

  func testLowerNoArgs() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.lower()"))
  }

  func testLenNoArgs() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.len()"))
  }

  func testCharsNoArgs() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.chars()"))
  }

  // MARK: - slice() tests

  func testSliceBasicASCII() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('hello', 2, 4)")
    XCTAssertEqual(result.stringValue, "ell")
  }

  func testSliceToEnd() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('hello', 3)")
    XCTAssertEqual(result.stringValue, "llo")
  }

  func testSliceUnicode() throws {
    // "Hello世界" — characters at indices 6 and 7 are '世' and '界'
    let result = try engine.evaluate("return luaswift.utf8x.slice('Hello世界', 6, 7)")
    XCTAssertEqual(result.stringValue, "世界")
  }

  func testSliceNegativeStart() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('hello', -3)")
    XCTAssertEqual(result.stringValue, "llo")
  }

  func testSliceNegativeStop() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('hello', 1, -2)")
    XCTAssertEqual(result.stringValue, "hell")
  }

  func testSliceWithStep() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('abcdef', 1, 6, 2)")
    XCTAssertEqual(result.stringValue, "ace")
  }

  func testSliceReverseStep() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('hello', 5, 1, -1)")
    XCTAssertEqual(result.stringValue, "olleh")
  }

  func testSliceUnicodeReverse() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('Hello世界', 7, 6, -1)")
    XCTAssertEqual(result.stringValue, "界世")
  }

  func testSliceEmptyResult() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('hello', 4, 2)")
    XCTAssertEqual(result.stringValue, "")
  }

  func testSliceEmptyString() throws {
    let result = try engine.evaluate("return luaswift.utf8x.slice('', 1, 3)")
    XCTAssertEqual(result.stringValue, "")
  }

  func testSliceStepZeroError() throws {
    XCTAssertThrowsError(try engine.evaluate("return luaswift.utf8x.slice('hello', 1, 5, 0)"))
  }
}
