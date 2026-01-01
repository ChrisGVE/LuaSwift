//
//  YAMLModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class YAMLModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installYAMLModule(in: engine)
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Basic Decoding

    func testDecodeSimpleString() throws {
        let result = try engine.evaluate("""
            return luaswift.yaml.decode("name: John")
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "John")
    }

    func testDecodeNumber() throws {
        let result = try engine.evaluate("""
            return luaswift.yaml.decode("age: 30")
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["age"]?.numberValue, 30.0)
    }

    func testDecodeBoolean() throws {
        let result = try engine.evaluate("""
            return luaswift.yaml.decode("active: true\\ndisabled: false")
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["active"]?.boolValue, true)
        XCTAssertEqual(table["disabled"]?.boolValue, false)
    }

    func testDecodeArray() throws {
        let result = try engine.evaluate("""
            local yaml = [[
            items:
              - apple
              - banana
              - cherry
            ]]
            return luaswift.yaml.decode(yaml)
            """)

        guard let table = result.tableValue,
              let items = table["items"]?.arrayValue else {
            XCTFail("Expected table with array")
            return
        }

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].stringValue, "apple")
        XCTAssertEqual(items[1].stringValue, "banana")
        XCTAssertEqual(items[2].stringValue, "cherry")
    }

    func testDecodeNestedTable() throws {
        let result = try engine.evaluate("""
            local yaml = [[
            database:
              host: localhost
              port: 5432
            ]]
            return luaswift.yaml.decode(yaml)
            """)

        guard let table = result.tableValue,
              let database = table["database"]?.tableValue else {
            XCTFail("Expected nested table")
            return
        }

        XCTAssertEqual(database["host"]?.stringValue, "localhost")
        XCTAssertEqual(database["port"]?.numberValue, 5432)
    }

    // MARK: - Basic Encoding

    func testEncodeSimpleTable() throws {
        let result = try engine.evaluate("""
            local str = luaswift.yaml.encode({name = "John", age = 30})
            return str
            """)

        guard let yamlString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(yamlString.contains("name: John") || yamlString.contains("name: \"John\""))
        XCTAssertTrue(yamlString.contains("age: 30"))
    }

    func testEncodeArray() throws {
        let result = try engine.evaluate("""
            local str = luaswift.yaml.encode({items = {"a", "b", "c"}})
            return str
            """)

        guard let yamlString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(yamlString.contains("items:"))
    }

    // MARK: - Multi-Document

    func testDecodeAll() throws {
        let result = try engine.evaluate("""
            local yaml = [[---
            foo: 1
            ---
            bar: 2
            ]]
            return luaswift.yaml.decode_all(yaml)
            """)

        guard let docs = result.arrayValue else {
            XCTFail("Expected array result")
            return
        }

        XCTAssertEqual(docs.count, 2)
        XCTAssertEqual(docs[0].tableValue?["foo"]?.numberValue, 1)
        XCTAssertEqual(docs[1].tableValue?["bar"]?.numberValue, 2)
    }

    func testEncodeAll() throws {
        let result = try engine.evaluate("""
            local docs = {{foo = 1}, {bar = 2}}
            return luaswift.yaml.encode_all(docs)
            """)

        guard let yamlString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(yamlString.contains("---"))
        XCTAssertTrue(yamlString.contains("foo: 1"))
        XCTAssertTrue(yamlString.contains("bar: 2"))
    }

    // MARK: - Round Trip

    func testRoundTrip() throws {
        let result = try engine.evaluate("""
            local original = {
                name = "test",
                count = 42,
                enabled = true,
                items = {"a", "b", "c"}
            }
            local yaml = luaswift.yaml.encode(original)
            local decoded = luaswift.yaml.decode(yaml)
            return decoded
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "test")
        XCTAssertEqual(table["count"]?.numberValue, 42)
        XCTAssertEqual(table["enabled"]?.boolValue, true)
    }

    // MARK: - Error Handling

    func testDecodeInvalidYAML() throws {
        do {
            _ = try engine.evaluate("""
                return luaswift.yaml.decode(":\\n  invalid: [")
                """)
            XCTFail("Expected error for invalid YAML")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("yaml.decode"))
        }
    }

    func testDecodeRequiresString() throws {
        do {
            _ = try engine.evaluate("""
                return luaswift.yaml.decode(123)
                """)
            XCTFail("Expected error for non-string argument")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("string"))
        }
    }

    // MARK: - Special Values

    func testDecodeNull() throws {
        let result = try engine.evaluate("""
            local t = luaswift.yaml.decode("value: null")
            return t.value == nil
            """)

        // YAML null becomes Lua nil, so accessing t.value returns nil
        // The Lua comparison t.value == nil returns true
        XCTAssertEqual(result.boolValue, true)
    }

    func testDecodeFloat() throws {
        let result = try engine.evaluate("""
            return luaswift.yaml.decode("pi: 3.14159")
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["pi"]!.numberValue!, 3.14159, accuracy: 0.00001)
    }
}
