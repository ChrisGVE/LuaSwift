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
            "startswith", "endswith", "contains", "count"
        ]

        for functionName in functions {
            let result = try engine.evaluate("""
                return type(luaswift.stringx.\(functionName))
                """)
            XCTAssertEqual(result.stringValue, "function",
                          "Function \(functionName) should be available")
        }
    }
}
