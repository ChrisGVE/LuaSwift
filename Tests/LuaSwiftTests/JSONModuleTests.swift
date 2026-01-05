//
//  JSONModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class JSONModuleTests: XCTestCase {

    // MARK: - Setup

    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installJSONModule(in: engine)
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Basic Decoding Tests

    func testDecodeSimpleObject() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{"name":"John","age":30}')
            return tbl
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "John")
        XCTAssertEqual(table["age"]?.numberValue, 30.0)
    }

    func testDecodeArray() throws {
        let result = try engine.evaluate("""
            local arr = luaswift.json.decode('[1, 2, 3, 4, 5]')
            return arr
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array[0].numberValue, 1.0)
        XCTAssertEqual(array[2].numberValue, 3.0)
        XCTAssertEqual(array.count, 5)
    }

    func testDecodeBoolean() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{"active":true,"disabled":false}')
            return tbl
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["active"]?.boolValue, true)
        XCTAssertEqual(table["disabled"]?.boolValue, false)
    }

    func testDecodeNull() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{"value":null}')
            return tbl.value
            """)

        XCTAssertTrue(result.isNil)
    }

    func testDecodeString() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{"message":"Hello, World!"}')
            return tbl.message
            """)

        XCTAssertEqual(result.stringValue, "Hello, World!")
    }

    func testDecodeNumber() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{"integer":42,"float":3.14,"negative":-10}')
            return tbl
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["integer"]?.numberValue, 42.0)
        XCTAssertEqual(table["float"]?.numberValue, 3.14)
        XCTAssertEqual(table["negative"]?.numberValue, -10.0)
    }

    // MARK: - Nested Structures

    func testDecodeNestedObject() throws {
        let result = try engine.evaluate("""
            local json_str = '{"person":{"name":"Alice","address":{"city":"NYC","zip":"10001"}}}'
            local tbl = luaswift.json.decode(json_str)
            return tbl
            """)

        guard let table = result.tableValue,
              let person = table["person"]?.tableValue,
              let address = person["address"]?.tableValue else {
            XCTFail("Expected nested table structure")
            return
        }

        XCTAssertEqual(person["name"]?.stringValue, "Alice")
        XCTAssertEqual(address["city"]?.stringValue, "NYC")
    }

    func testDecodeNestedArray() throws {
        let result = try engine.evaluate("""
            local arr = luaswift.json.decode('[[1,2],[3,4],[5,6]]')
            return arr
            """)

        guard let outerArray = result.arrayValue,
              let innerArray = outerArray[1].arrayValue else {
            XCTFail("Expected nested array structure")
            return
        }

        XCTAssertEqual(innerArray[0].numberValue, 3.0)
        XCTAssertEqual(innerArray[1].numberValue, 4.0)
    }

    func testDecodeMixedNesting() throws {
        let result = try engine.evaluate("""
            local json_str = '{"users":[{"name":"Bob","age":25},{"name":"Carol","age":30}]}'
            local tbl = luaswift.json.decode(json_str)
            return tbl
            """)

        guard let table = result.tableValue,
              let users = table["users"]?.arrayValue,
              let user1 = users[0].tableValue,
              let user2 = users[1].tableValue else {
            XCTFail("Expected nested structure")
            return
        }

        XCTAssertEqual(user1["name"]?.stringValue, "Bob")
        XCTAssertEqual(user2["age"]?.numberValue, 30.0)
    }

    // MARK: - Basic Encoding Tests

    func testEncodeSimpleObject() throws {
        let result = try engine.evaluate("""
            local json_str = luaswift.json.encode({name="John", age=30})
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        // Parse back to verify
        let decoded = try engine.evaluate("""
            local tbl = luaswift.json.decode('\(jsonString)')
            return tbl
            """)

        guard let table = decoded.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "John")
        XCTAssertEqual(table["age"]?.numberValue, 30.0)
    }

    func testEncodeArray() throws {
        let result = try engine.evaluate("""
            local json_str = luaswift.json.encode({1, 2, 3, 4, 5})
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(jsonString.contains("1"))
        XCTAssertTrue(jsonString.contains("5"))

        // Verify round-trip
        let decoded = try engine.evaluate("""
            local arr = luaswift.json.decode('\(jsonString)')
            return arr
            """)

        guard let array = decoded.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 5)
        XCTAssertEqual(array[2].numberValue, 3.0)
    }

    func testEncodeBoolean() throws {
        let result = try engine.evaluate("""
            local json_str = luaswift.json.encode({active=true, disabled=false})
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(jsonString.contains("true"))
        XCTAssertTrue(jsonString.contains("false"))
    }

    func testEncodeString() throws {
        let result = try engine.evaluate("""
            local json_str = luaswift.json.encode({message="Hello, World!"})
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(jsonString.contains("Hello, World!"))
    }

    // MARK: - Nested Encoding

    func testEncodeNestedObject() throws {
        let result = try engine.evaluate("""
            local obj = {
                person = {
                    name = "Alice",
                    address = {
                        city = "NYC",
                        zip = "10001"
                    }
                }
            }
            local json_str = luaswift.json.encode(obj)
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        // Verify round-trip
        let decoded = try engine.evaluate("""
            local tbl = luaswift.json.decode('\(jsonString)')
            return tbl
            """)

        guard let table = decoded.tableValue,
              let person = table["person"]?.tableValue,
              let address = person["address"]?.tableValue else {
            XCTFail("Expected nested structure")
            return
        }

        XCTAssertEqual(person["name"]?.stringValue, "Alice")
        XCTAssertEqual(address["city"]?.stringValue, "NYC")
    }

    func testEncodeNestedArray() throws {
        let result = try engine.evaluate("""
            local arr = {{1,2},{3,4},{5,6}}
            local json_str = luaswift.json.encode(arr)
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        // Verify round-trip
        let decoded = try engine.evaluate("""
            local arr = luaswift.json.decode('\(jsonString)')
            return arr
            """)

        guard let outerArray = decoded.arrayValue,
              let innerArray = outerArray[1].arrayValue else {
            XCTFail("Expected nested array")
            return
        }

        XCTAssertEqual(innerArray[0].numberValue, 3.0)
        XCTAssertEqual(innerArray[1].numberValue, 4.0)
    }

    // MARK: - Pretty Printing

    func testEncodePrettyPrint() throws {
        let result = try engine.evaluate("""
            local obj = {name="John", age=30, active=true}
            local json_str = luaswift.json.encode(obj, {pretty=true})
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        // Pretty-printed JSON should have newlines
        XCTAssertTrue(jsonString.contains("\n"))

        // Verify it's still valid
        let decoded = try engine.evaluate("""
            local tbl = luaswift.json.decode([[\(jsonString)]])
            return tbl.name
            """)

        XCTAssertEqual(decoded.stringValue, "John")
    }

    func testEncodePrettyPrintWithIndent() throws {
        let result = try engine.evaluate("""
            local obj = {nested={value=42}}
            local json_str = luaswift.json.encode(obj, {pretty=true, indent=4})
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        // Should contain newlines for pretty printing
        XCTAssertTrue(jsonString.contains("\n"))
    }

    // MARK: - Round-Trip Tests

    func testRoundTripSimpleObject() throws {
        try engine.run("""
            local original = {name="Test", value=123, flag=true}
            local json_str = luaswift.json.encode(original)
            local decoded = luaswift.json.decode(json_str)
            assert(decoded.name == original.name)
            assert(decoded.value == original.value)
            assert(decoded.flag == original.flag)
            """)
    }

    func testRoundTripArray() throws {
        try engine.run("""
            local original = {10, 20, 30, 40, 50}
            local json_str = luaswift.json.encode(original)
            local decoded = luaswift.json.decode(json_str)
            assert(#decoded == #original)
            for i = 1, #original do
                assert(decoded[i] == original[i])
            end
            """)
    }

    func testRoundTripNestedStructure() throws {
        try engine.run("""
            local original = {
                users = {
                    {name="Alice", age=25},
                    {name="Bob", age=30}
                },
                count = 2
            }
            local json_str = luaswift.json.encode(original)
            local decoded = luaswift.json.decode(json_str)
            assert(decoded.count == original.count)
            assert(decoded.users[1].name == original.users[1].name)
            assert(decoded.users[2].age == original.users[2].age)
            """)
    }

    // MARK: - Error Handling

    func testDecodeInvalidJSON() throws {
        XCTAssertThrowsError(try engine.evaluate("""
            return luaswift.json.decode('not valid json')
            """)) { error in
            if let luaError = error as? LuaError {
                switch luaError {
                case .runtimeError(let message):
                    XCTAssertTrue(message.contains("json.decode error"))
                default:
                    XCTFail("Expected runtime error, got \(luaError)")
                }
            } else {
                XCTFail("Expected LuaError, got \(error)")
            }
        }
    }

    func testDecodeMissingArgument() throws {
        XCTAssertThrowsError(try engine.evaluate("""
            return luaswift.json.decode()
            """)) { error in
            if let luaError = error as? LuaError {
                switch luaError {
                case .runtimeError(let message):
                    XCTAssertTrue(message.contains("requires a string argument"))
                default:
                    XCTFail("Expected runtime error, got \(luaError)")
                }
            } else {
                XCTFail("Expected LuaError, got \(error)")
            }
        }
    }

    func testEncodeWithNonTableArgument() throws {
        // Encoding a string should work
        let result = try engine.evaluate("""
            return luaswift.json.encode("test")
            """)

        XCTAssertEqual(result.stringValue, "\"test\"")
    }

    // MARK: - Edge Cases

    func testDecodeEmptyObject() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{}')
            return tbl
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertTrue(table.isEmpty)
    }

    func testDecodeEmptyArray() throws {
        let result = try engine.evaluate("""
            local arr = luaswift.json.decode('[]')
            return #arr
            """)

        XCTAssertEqual(result.numberValue, 0.0)
    }

    func testEncodeEmptyTable() throws {
        let result = try engine.evaluate("""
            local json_str = luaswift.json.encode({})
            return json_str
            """)

        guard let jsonString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        // Empty table can encode as either {} or []
        XCTAssertTrue(jsonString == "{}" || jsonString == "[]")
    }

    func testDecodeUnicodeString() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{"text":"Hello 世界 🌍"}')
            return tbl.text
            """)

        XCTAssertEqual(result.stringValue, "Hello 世界 🌍")
    }

    func testEncodeUnicodeString() throws {
        try engine.run("""
            local original = {text="Hello 世界 🌍"}
            local json_str = luaswift.json.encode(original)
            local decoded = luaswift.json.decode(json_str)
            assert(decoded.text == original.text)
            """)
    }

    func testDecodeLargeNumber() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{"big":9007199254740991}')
            return tbl.big
            """)

        XCTAssertEqual(result.numberValue, 9007199254740991.0)
    }

    func testDecodeNegativeNumber() throws {
        let result = try engine.evaluate("""
            local tbl = luaswift.json.decode('{"neg":-999.99}')
            return tbl.neg
            """)

        XCTAssertEqual(result.numberValue, -999.99)
    }

    // MARK: - Null Sentinel

    func testNullSentinel() throws {
        let result = try engine.evaluate("""
            return luaswift.json.null
            """)

        // The null sentinel is a special table with a metatable
        XCTAssertNotNil(result.tableValue)
    }

    func testNullToString() throws {
        let result = try engine.evaluate("""
            return tostring(luaswift.json.null)
            """)

        XCTAssertEqual(result.stringValue, "null")
    }

    // MARK: - Module Availability

    func testModuleNamespace() throws {
        try engine.run("""
            assert(luaswift ~= nil)
            assert(luaswift.json ~= nil)
            assert(type(luaswift.json.encode) == "function")
            assert(type(luaswift.json.decode) == "function")
            """)
    }

    // MARK: - Performance Tests

    func testDecodeLargeArray() throws {
        // Create a JSON array with 1000 elements
        let jsonArray = "[" + (1...1000).map { String($0) }.joined(separator: ",") + "]"

        let result = try engine.evaluate("""
            local arr = luaswift.json.decode('\(jsonArray)')
            return arr
            """)

        guard let array = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(array.count, 1000)
        XCTAssertEqual(array[499].numberValue, 500.0)  // Lua is 1-indexed, Swift is 0-indexed
    }

    func testEncodeLargeTable() throws {
        let result = try engine.evaluate("""
            local tbl = {}
            for i = 1, 100 do
                tbl[i] = {id=i, name="Item"..i, value=i*10}
            end
            local json_str = luaswift.json.encode(tbl)
            local decoded = luaswift.json.decode(json_str)
            return decoded
            """)

        guard let array = result.arrayValue,
              let item50 = array[49].tableValue else {  // Lua is 1-indexed, Swift is 0-indexed
            XCTFail("Expected array with table elements")
            return
        }

        XCTAssertEqual(array.count, 100)
        XCTAssertEqual(item50["name"]?.stringValue, "Item50")
    }

    // MARK: - JSONC Tests (JSON with Comments)

    func testDecodeJSONCWithLineComment() throws {
        let result = try engine.evaluate("""
            local jsonc = [[{
                // This is a comment
                "name": "John",
                "age": 30 // inline comment
            }]]
            return luaswift.json.decode_jsonc(jsonc)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "John")
        XCTAssertEqual(table["age"]?.numberValue, 30.0)
    }

    func testDecodeJSONCWithBlockComment() throws {
        let result = try engine.evaluate("""
            local jsonc = [[{
                /* This is a
                   multi-line comment */
                "name": "Alice",
                "values": [1, /* inline */ 2, 3]
            }]]
            return luaswift.json.decode_jsonc(jsonc)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "Alice")
        guard let values = table["values"]?.arrayValue else {
            XCTFail("Expected array")
            return
        }
        XCTAssertEqual(values.count, 3)
    }

    func testDecodeJSONCMixedComments() throws {
        let result = try engine.evaluate("""
            local jsonc = [[{
                // Line comment
                "key1": "value1",
                /* Block comment */
                "key2": "value2",
                "key3": "value3" // trailing
            }]]
            return luaswift.json.decode_jsonc(jsonc)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["key1"]?.stringValue, "value1")
        XCTAssertEqual(table["key2"]?.stringValue, "value2")
        XCTAssertEqual(table["key3"]?.stringValue, "value3")
    }

    func testDecodeJSONCCommentsInStringsPreserved() throws {
        let result = try engine.evaluate("""
            local jsonc = [[{
                "url": "http://example.com",
                "comment": "This has // slashes and /* stars */"
            }]]
            return luaswift.json.decode_jsonc(jsonc)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["url"]?.stringValue, "http://example.com")
        XCTAssertEqual(table["comment"]?.stringValue, "This has // slashes and /* stars */")
    }

    func testDecodeWithCommentsOption() throws {
        let result = try engine.evaluate("""
            local jsonc = [[{
                // Comment
                "name": "Test"
            }]]
            return luaswift.json.decode(jsonc, {comments = true})
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "Test")
    }

    func testDecodeWithFormatOption() throws {
        let result = try engine.evaluate("""
            local jsonc = [[{
                // Comment
                "name": "Test"
            }]]
            return luaswift.json.decode(jsonc, {format = "jsonc"})
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "Test")
    }

    // MARK: - JSON5 Tests

    func testDecodeJSON5TrailingCommas() throws {
        let result = try engine.evaluate("""
            local json5 = [[{
                "array": [1, 2, 3,],
                "nested": {"a": 1, "b": 2,},
            }]]
            return luaswift.json.decode_json5(json5)
            """)

        guard let table = result.tableValue,
              let array = table["array"]?.arrayValue else {
            XCTFail("Expected table with array")
            return
        }

        XCTAssertEqual(array.count, 3)
    }

    func testDecodeJSON5UnquotedKeys() throws {
        let result = try engine.evaluate("""
            local json5 = [[{
                name: "John",
                age: 30,
                _private: true,
                $special: "value"
            }]]
            return luaswift.json.decode_json5(json5)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "John")
        XCTAssertEqual(table["age"]?.numberValue, 30.0)
        XCTAssertEqual(table["_private"]?.boolValue, true)
        XCTAssertEqual(table["$special"]?.stringValue, "value")
    }

    func testDecodeJSON5SingleQuotedStrings() throws {
        let result = try engine.evaluate("""
            local json5 = [[{
                "name": 'John',
                'key': 'value'
            }]]
            return luaswift.json.decode_json5(json5)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "John")
        XCTAssertEqual(table["key"]?.stringValue, "value")
    }

    func testDecodeJSON5HexNumbers() throws {
        let result = try engine.evaluate("""
            local json5 = [[{
                "hex": 0xFF,
                "big": 0x1A2B
            }]]
            return luaswift.json.decode_json5(json5)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["hex"]?.numberValue, 255.0)
        XCTAssertEqual(table["big"]?.numberValue, 6699.0)
    }

    func testDecodeJSON5LeadingDecimal() throws {
        let result = try engine.evaluate("""
            local json5 = [[{
                "value": .5,
                "array": [.25, .75]
            }]]
            return luaswift.json.decode_json5(json5)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["value"]?.numberValue, 0.5)
    }

    func testDecodeJSON5Comments() throws {
        let result = try engine.evaluate("""
            local json5 = [[{
                // Line comment
                name: "Test",
                /* Block comment */
                value: 42,
            }]]
            return luaswift.json.decode_json5(json5)
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "Test")
        XCTAssertEqual(table["value"]?.numberValue, 42.0)
    }

    func testDecodeJSON5Infinity() throws {
        // JSON doesn't support Infinity, so it gets converted to null (nil in Lua)
        let result = try engine.evaluate("""
            local json5 = [[{
                "positive": Infinity,
                "negative": -Infinity
            }]]
            local tbl = luaswift.json.decode_json5(json5)
            return tbl.positive, tbl.negative
            """)

        // Infinity values should be converted to nil (since JSON doesn't support them)
        XCTAssertTrue(result.isNil)
    }

    func testDecodeJSON5NaN() throws {
        let result = try engine.evaluate("""
            local json5 = [[{
                "value": NaN
            }]]
            local tbl = luaswift.json.decode_json5(json5)
            return tbl.value
            """)

        // NaN is converted to null, which becomes nil in Lua
        XCTAssertTrue(result.isNil)
    }

    func testDecodeJSON5Complex() throws {
        // Test a complex JSON5 document with multiple features
        let result = try engine.evaluate("""
            local json5 = [[{
                // Configuration file
                name: 'MyApp',
                version: "1.0.0",
                features: [
                    'feature1',
                    "feature2",
                ],
                settings: {
                    maxRetries: 3,
                    timeout: 0xFF, // 255 in hex
                    ratio: .75,
                },
            }]]
            return luaswift.json.decode_json5(json5)
            """)

        guard let table = result.tableValue,
              let features = table["features"]?.arrayValue,
              let settings = table["settings"]?.tableValue else {
            XCTFail("Expected complex structure")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "MyApp")
        XCTAssertEqual(features.count, 2)
        XCTAssertEqual(settings["timeout"]?.numberValue, 255.0)
        XCTAssertEqual(settings["ratio"]?.numberValue, 0.75)
    }

    func testDecodeWithFormatJSON5() throws {
        let result = try engine.evaluate("""
            local json5 = [[{name: 'Test',}]]
            return luaswift.json.decode(json5, {format = "json5"})
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "Test")
    }

    // MARK: - Module Function Availability

    func testJSONCFunctionAvailable() throws {
        try engine.run("""
            assert(type(luaswift.json.decode_jsonc) == "function")
            """)
    }

    func testJSON5FunctionAvailable() throws {
        try engine.run("""
            assert(type(luaswift.json.decode_json5) == "function")
            """)
    }
}
