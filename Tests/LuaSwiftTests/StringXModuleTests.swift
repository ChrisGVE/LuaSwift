//
//  StringXModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class StringXModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        ModuleRegistry.installStringXModule(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - strip() tests

    func testStripWhitespace() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.strip("  hello world  ")
            """)
        XCTAssertEqual(result.stringValue, "hello world")
    }

    func testStripCustomChars() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.strip("xxhelloxx", "x")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testStripMultipleCustomChars() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.strip("xyxhelloyxy", "xy")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testStripNoMatch() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.strip("hello", "x")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testStripNewlines() throws {
        let result = try engine.evaluate(#"""
            local s = "\n\nhello\n\n"
            return luaswift.stringx.strip(s)
            """#)
        XCTAssertEqual(result.stringValue, "hello")
    }

    // MARK: - lstrip() tests

    func testLstripWhitespace() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lstrip("  hello world  ")
            """)
        XCTAssertEqual(result.stringValue, "hello world  ")
    }

    func testLstripCustomChars() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lstrip("xxhelloxx", "x")
            """)
        XCTAssertEqual(result.stringValue, "helloxx")
    }

    func testLstripNoMatch() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lstrip("hello", "x")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    // MARK: - rstrip() tests

    func testRstripWhitespace() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.rstrip("  hello world  ")
            """)
        XCTAssertEqual(result.stringValue, "  hello world")
    }

    func testRstripCustomChars() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.rstrip("xxhelloxx", "x")
            """)
        XCTAssertEqual(result.stringValue, "xxhello")
    }

    func testRstripNoMatch() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.rstrip("hello", "x")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    // MARK: - split() tests

    func testSplitBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.split("a,b,c", ",")
            """)
        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].stringValue, "a")
        XCTAssertEqual(array[1].stringValue, "b")
        XCTAssertEqual(array[2].stringValue, "c")
    }

    func testSplitMultiCharSeparator() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.split("hello::world::test", "::")
            """)
        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].stringValue, "hello")
        XCTAssertEqual(array[1].stringValue, "world")
        XCTAssertEqual(array[2].stringValue, "test")
    }

    func testSplitEmptyString() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.split("", ",")
            """)
        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }
        XCTAssertEqual(array.count, 1)
        XCTAssertEqual(array[0].stringValue, "")
    }

    func testSplitNoSeparator() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.split("hello", ",")
            """)
        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }
        XCTAssertEqual(array.count, 1)
        XCTAssertEqual(array[0].stringValue, "hello")
    }

    func testSplitConsecutiveSeparators() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.split("a,,b", ",")
            """)
        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].stringValue, "a")
        XCTAssertEqual(array[1].stringValue, "")
        XCTAssertEqual(array[2].stringValue, "b")
    }

    // MARK: - replace() tests

    func testReplaceBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.replace("hello world", "world", "Swift")
            """)
        XCTAssertEqual(result.stringValue, "hello Swift")
    }

    func testReplaceWithCount() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.replace("aaa", "a", "b", 2)
            """)
        XCTAssertEqual(result.stringValue, "bba")
    }

    func testReplaceAll() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.replace("aaa", "a", "b")
            """)
        XCTAssertEqual(result.stringValue, "bbb")
    }

    func testReplaceNoMatch() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.replace("hello", "x", "y")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testReplaceEmptyString() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.replace("hello", "", "x")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testReplaceMultipleOccurrences() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.replace("hello hello hello", "hello", "hi", 2)
            """)
        XCTAssertEqual(result.stringValue, "hi hi hello")
    }

    // MARK: - join() tests

    func testJoinBasic() throws {
        let result = try engine.evaluate("""
            local arr = {"a", "b", "c"}
            return luaswift.stringx.join(arr, ",")
            """)
        XCTAssertEqual(result.stringValue, "a,b,c")
    }

    func testJoinEmptyArray() throws {
        let result = try engine.evaluate("""
            local arr = {}
            return luaswift.stringx.join(arr, ",")
            """)
        XCTAssertEqual(result.stringValue, "")
    }

    func testJoinSingleElement() throws {
        let result = try engine.evaluate("""
            local arr = {"hello"}
            return luaswift.stringx.join(arr, ",")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testJoinMultiCharSeparator() throws {
        let result = try engine.evaluate("""
            local arr = {"hello", "world", "test"}
            return luaswift.stringx.join(arr, "::")
            """)
        XCTAssertEqual(result.stringValue, "hello::world::test")
    }

    // MARK: - startswith() tests

    func testStartswithTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.startswith("hello world", "hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testStartswithFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.startswith("hello world", "world")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testStartswithEmptyPrefix() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.startswith("hello", "")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testStartswithExactMatch() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.startswith("hello", "hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - endswith() tests

    func testEndswithTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.endswith("hello world", "world")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testEndswithFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.endswith("hello world", "hello")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testEndswithEmptySuffix() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.endswith("hello", "")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testEndswithExactMatch() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.endswith("hello", "hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - contains() tests

    func testContainsTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.contains("hello world", "lo wo")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testContainsFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.contains("hello world", "xyz")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testContainsEmptySubstring() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.contains("hello", "")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testContainsExactMatch() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.contains("hello", "hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - count() tests

    func testCountBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.count("hello world", "l")
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testCountNoMatch() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.count("hello", "x")
            """)
        XCTAssertEqual(result.numberValue, 0)
    }

    func testCountMultiChar() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.count("hello hello hello", "hello")
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testCountOverlapping() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.count("aaa", "aa")
            """)
        // Non-overlapping count: should find "aa" at positions 0-2, then position 2 is start of next search
        XCTAssertEqual(result.numberValue, 1)
    }

    func testCountEmptyPattern() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.count("hello", "")
            """)
        XCTAssertEqual(result.numberValue, 0)
    }

    // MARK: - Integration tests

    func testChainedOperations() throws {
        let result = try engine.evaluate("""
            local s = "  hello world  "
            s = luaswift.stringx.strip(s)
            s = luaswift.stringx.replace(s, "world", "Swift")
            return s
            """)
        XCTAssertEqual(result.stringValue, "hello Swift")
    }

    func testSplitAndJoin() throws {
        let result = try engine.evaluate("""
            local parts = luaswift.stringx.split("a,b,c", ",")
            return luaswift.stringx.join(parts, ";")
            """)
        XCTAssertEqual(result.stringValue, "a;b;c")
    }

    func testModuleAvailable() throws {
        let result = try engine.evaluate("""
            return type(luaswift.stringx)
            """)
        XCTAssertEqual(result.stringValue, "table")
    }

    func testAllFunctionsAvailable() throws {
        let functions = [
            "strip", "lstrip", "rstrip", "split", "replace", "join",
            "startswith", "endswith", "contains", "count",
            "capitalize", "title", "lpad", "rpad", "center",
            // New is_<name> convention
            "is_alpha", "is_digit", "is_alnum", "is_space", "is_upper", "is_lower", "is_empty", "is_blank",
            // Backward compatible aliases
            "isalpha", "isdigit", "isalnum", "isspace", "isupper", "islower", "isempty", "isblank",
            "splitlines", "wrap", "truncate"
        ]

        for functionName in functions {
            let result = try engine.evaluate("""
                return type(luaswift.stringx.\(functionName))
                """)
            XCTAssertEqual(result.stringValue, "function",
                          "Function \(functionName) should be available")
        }
    }

    // MARK: - capitalize() tests

    func testCapitalizeBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.capitalize("hello world")
            """)
        XCTAssertEqual(result.stringValue, "Hello world")
    }

    func testCapitalizeAllUpper() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.capitalize("HELLO WORLD")
            """)
        XCTAssertEqual(result.stringValue, "Hello world")
    }

    func testCapitalizeEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.capitalize("")
            """)
        XCTAssertEqual(result.stringValue, "")
    }

    func testCapitalizeSingleChar() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.capitalize("a")
            """)
        XCTAssertEqual(result.stringValue, "A")
    }

    func testCapitalizeUnicode() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.capitalize("ÜBER")
            """)
        XCTAssertEqual(result.stringValue, "Über")
    }

    // MARK: - title() tests

    func testTitleBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.title("hello world")
            """)
        XCTAssertEqual(result.stringValue, "Hello World")
    }

    func testTitleAllUpper() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.title("HELLO WORLD")
            """)
        XCTAssertEqual(result.stringValue, "Hello World")
    }

    func testTitleEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.title("")
            """)
        XCTAssertEqual(result.stringValue, "")
    }

    func testTitleMixedCase() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.title("hELLO wORLD")
            """)
        XCTAssertEqual(result.stringValue, "Hello World")
    }

    func testTitleUnicode() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.title("über münchen")
            """)
        XCTAssertEqual(result.stringValue, "Über München")
    }

    // MARK: - lpad() tests

    func testLpadBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lpad("hi", 5)
            """)
        XCTAssertEqual(result.stringValue, "   hi")
    }

    func testLpadCustomChar() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lpad("42", 5, "0")
            """)
        XCTAssertEqual(result.stringValue, "00042")
    }

    func testLpadNoChange() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lpad("hello", 3)
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testLpadExactWidth() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lpad("hi", 2)
            """)
        XCTAssertEqual(result.stringValue, "hi")
    }

    func testLpadEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lpad("", 3)
            """)
        XCTAssertEqual(result.stringValue, "   ")
    }

    func testLpadUnicode() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.lpad("日本", 5, "-")
            """)
        XCTAssertEqual(result.stringValue, "---日本")
    }

    // MARK: - rpad() tests

    func testRpadBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.rpad("hi", 5)
            """)
        XCTAssertEqual(result.stringValue, "hi   ")
    }

    func testRpadCustomChar() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.rpad("hi", 5, ".")
            """)
        XCTAssertEqual(result.stringValue, "hi...")
    }

    func testRpadNoChange() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.rpad("hello", 3)
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testRpadEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.rpad("", 3, "x")
            """)
        XCTAssertEqual(result.stringValue, "xxx")
    }

    // MARK: - center() tests

    func testCenterBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.center("hi", 6)
            """)
        XCTAssertEqual(result.stringValue, "  hi  ")
    }

    func testCenterOddPadding() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.center("hi", 7)
            """)
        XCTAssertEqual(result.stringValue, "  hi   ")
    }

    func testCenterCustomChar() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.center("hi", 6, "-")
            """)
        XCTAssertEqual(result.stringValue, "--hi--")
    }

    func testCenterNoChange() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.center("hello", 3)
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testCenterEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.center("", 4, "*")
            """)
        XCTAssertEqual(result.stringValue, "****")
    }

    // MARK: - isalpha() tests

    func testIsalphaTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalpha("hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsalphaFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalpha("hello123")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsalphaWithSpace() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalpha("hello world")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsalphaEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalpha("")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsalphaUnicode() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalpha("über")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - isdigit() tests

    func testIsdigitTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isdigit("12345")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsdigitFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isdigit("123abc")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsdigitWithDecimal() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isdigit("3.14")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsdigitEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isdigit("")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - isalnum() tests

    func testIsalnumTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalnum("hello123")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsalnumLettersOnly() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalnum("hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsalnumDigitsOnly() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalnum("12345")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsalnumFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalnum("hello!")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsalnumEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isalnum("")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - isspace() tests

    func testIsspaceTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isspace("   ")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsspaceTabs() throws {
        let result = try engine.evaluate(#"""
            return luaswift.stringx.isspace("\t\n ")
            """#)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsspaceFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isspace("  x  ")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsspaceEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isspace("")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - isempty() tests

    func testIsemptyTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isempty("")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsemptyFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isempty("hello")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsemptyWhitespace() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isempty("   ")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - isblank() tests

    func testIsblankTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isblank("")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsblankWhitespace() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isblank("   ")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsblankMixed() throws {
        let result = try engine.evaluate(#"""
            return luaswift.stringx.isblank(" \t\n ")
            """#)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsblankFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.isblank("  x  ")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - is_upper() tests

    func testIsUpperTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_upper("HELLO")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsUpperFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_upper("Hello")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsUpperWithNumbers() throws {
        // Numbers are ignored, only letters count
        let result = try engine.evaluate("""
            return luaswift.stringx.is_upper("HELLO123")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsUpperEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_upper("")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsUpperNoLetters() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_upper("123")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsUpperUnicode() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_upper("ÜBER")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsUpperBackwardCompat() throws {
        // Test backward compatible alias
        let result = try engine.evaluate("""
            return luaswift.stringx.isupper("HELLO")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - is_lower() tests

    func testIsLowerTrue() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_lower("hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsLowerFalse() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_lower("Hello")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsLowerWithNumbers() throws {
        // Numbers are ignored, only letters count
        let result = try engine.evaluate("""
            return luaswift.stringx.is_lower("hello123")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsLowerEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_lower("")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsLowerNoLetters() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_lower("123")
            """)
        XCTAssertEqual(result.boolValue, false)
    }

    func testIsLowerUnicode() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_lower("über")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsLowerBackwardCompat() throws {
        // Test backward compatible alias
        let result = try engine.evaluate("""
            return luaswift.stringx.islower("hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - New is_<name> convention tests

    func testIsAlphaNewConvention() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_alpha("hello")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsDigitNewConvention() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_digit("12345")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsAlnumNewConvention() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_alnum("hello123")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsSpaceNewConvention() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_space("   ")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsEmptyNewConvention() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_empty("")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testIsBlankNewConvention() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.is_blank("   ")
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - splitlines() tests

    func testSplitlinesUnix() throws {
        let result = try engine.evaluate(#"""
            local lines = luaswift.stringx.splitlines("a\nb\nc")
            return lines[1] .. "," .. lines[2] .. "," .. lines[3]
            """#)
        XCTAssertEqual(result.stringValue, "a,b,c")
    }

    func testSplitlinesWindows() throws {
        // Test Windows-style line endings (CR-LF)
        // Note: Due to how escape sequences pass through Swift raw strings and Lua,
        // testing \r\n as a two-byte sequence requires special handling.
        // We verify CR-LF handling by checking the line count and content.

        // Test 1: Verify that the string with \r\n has the expected length
        let lengthResult = try engine.evaluate(#"""
            return #("a\r\nb")
            """#)
        // 'a' + CR(1) + LF(1) + 'b' = 4 bytes
        XCTAssertEqual(lengthResult.numberValue, 4)

        // Test 2: Verify splitlines returns correct count
        let result = try engine.evaluate(#"""
            local lines = luaswift.stringx.splitlines("a\r\nb\r\nc")
            return #lines
            """#)
        // CR-LF should be treated as a single line break, yielding 3 lines
        XCTAssertEqual(result.numberValue, 3)
    }

    func testSplitlinesMacClassic() throws {
        // Test old Mac-style line endings (CR only)
        // First verify the string length - if \r is interpreted as CR, length should be 5
        let lengthResult = try engine.evaluate(#"""
            return #("a\rb\rc")
            """#)
        // 'a' + CR + 'b' + CR + 'c' = 5 (if \r is carriage return)
        // 'a' + '\' + 'r' + 'b' + '\' + 'r' + 'c' = 7 (if \r is literal)
        XCTAssertEqual(lengthResult.numberValue, 5)

        // Now test splitlines
        let result = try engine.evaluate(#"""
            local lines = luaswift.stringx.splitlines("a\rb\rc")
            return #lines
            """#)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testSplitlinesMixed() throws {
        // Mix of Unix (\n) and Mac (\r) line endings
        // Simplified test without \r\n combination
        let result = try engine.evaluate(#"""
            local lines = luaswift.stringx.splitlines("a\nb\rc\nd")
            return #lines
            """#)
        XCTAssertEqual(result.numberValue, 4)
    }

    func testSplitlinesEmpty() throws {
        let result = try engine.evaluate("""
            local lines = luaswift.stringx.splitlines("")
            return #lines
            """)
        XCTAssertEqual(result.numberValue, 0)
    }

    func testSplitlinesTrailingNewline() throws {
        let result = try engine.evaluate(#"""
            local lines = luaswift.stringx.splitlines("a\nb\n")
            return #lines .. ":" .. lines[3]
            """#)
        XCTAssertEqual(result.stringValue, "3:")
    }

    func testSplitlinesNoNewlines() throws {
        let result = try engine.evaluate("""
            local lines = luaswift.stringx.splitlines("hello")
            return #lines .. ":" .. lines[1]
            """)
        XCTAssertEqual(result.stringValue, "1:hello")
    }

    // MARK: - wrap() tests

    func testWrapBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.wrap("hello world test", 10)
            """)
        XCTAssertEqual(result.stringValue, "hello\nworld test")
    }

    func testWrapLongWord() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.wrap("superlongword", 5)
            """)
        XCTAssertEqual(result.stringValue, "super\nlongw\nord")
    }

    func testWrapNoWrapNeeded() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.wrap("hi", 10)
            """)
        XCTAssertEqual(result.stringValue, "hi")
    }

    func testWrapEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.wrap("", 10)
            """)
        XCTAssertEqual(result.stringValue, "")
    }

    func testWrapMultipleSpaces() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.wrap("a b c d e", 3)
            """)
        // With width 3, "a b" fits, then "c d" fits on next, etc.
        let lines = result.stringValue?.components(separatedBy: "\n") ?? []
        XCTAssertEqual(lines.count, 3)
    }

    // MARK: - truncate() tests

    func testTruncateBasic() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.truncate("hello world", 8)
            """)
        XCTAssertEqual(result.stringValue, "hello...")
    }

    func testTruncateCustomSuffix() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.truncate("hello world", 9, ">>")
            """)
        XCTAssertEqual(result.stringValue, "hello w>>")
    }

    func testTruncateNoChange() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.truncate("hello", 10)
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testTruncateExactWidth() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.truncate("hello", 5)
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testTruncateEmpty() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.truncate("", 5)
            """)
        XCTAssertEqual(result.stringValue, "")
    }

    func testTruncateShortWidth() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.truncate("hello world", 2)
            """)
        // Width is 2, suffix "..." is 3, so truncateLength = -1
        // Should return truncated suffix: ".."
        XCTAssertEqual(result.stringValue, "..")
    }

    func testTruncateUnicode() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.truncate("日本語のテキスト", 6)
            """)
        XCTAssertEqual(result.stringValue, "日本語...")
    }

    func testTruncateEmptySuffix() throws {
        let result = try engine.evaluate("""
            return luaswift.stringx.truncate("hello world", 5, "")
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    // MARK: - Top-level Global Tests

    func testTopLevelGlobalStringx() throws {
        // stringx should be available as a top-level global
        let result = try engine.evaluate("""
            return stringx.capitalize("hello")
            """)
        XCTAssertEqual(result.stringValue, "Hello")
    }

    func testTopLevelGlobalEqualsLuaswiftStringx() throws {
        // stringx and luaswift.stringx should be the same table
        let result = try engine.evaluate("""
            return stringx == luaswift.stringx
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Import Function Tests

    func testImportExtendsStringTable() throws {
        // After import(), string.capitalize should work
        let result = try engine.evaluate("""
            stringx.import()
            return string.capitalize("hello")
            """)
        XCTAssertEqual(result.stringValue, "Hello")
    }

    func testImportExtendsStringMetatable() throws {
        // After import(), s:capitalize() method syntax should work
        let result = try engine.evaluate("""
            stringx.import()
            return ("hello"):capitalize()
            """)
        XCTAssertEqual(result.stringValue, "Hello")
    }

    func testImportMethodSyntaxTitle() throws {
        // Test method syntax with title()
        let result = try engine.evaluate("""
            stringx.import()
            return ("hello world"):title()
            """)
        XCTAssertEqual(result.stringValue, "Hello World")
    }

    func testImportMethodSyntaxStrip() throws {
        // Test method syntax with strip()
        let result = try engine.evaluate("""
            stringx.import()
            return ("  hello  "):strip()
            """)
        XCTAssertEqual(result.stringValue, "hello")
    }

    func testImportMethodSyntaxSplit() throws {
        // Test method syntax with split()
        let result = try engine.evaluate("""
            stringx.import()
            local parts = ("a,b,c"):split(",")
            return parts[2]
            """)
        XCTAssertEqual(result.stringValue, "b")
    }
}
