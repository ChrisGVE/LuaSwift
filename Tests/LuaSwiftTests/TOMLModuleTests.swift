//
//  TOMLModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class TOMLModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installTOMLModule(in: engine)
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
            return luaswift.toml.decode('name = "John"')
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["name"]?.stringValue, "John")
    }

    func testDecodeNumber() throws {
        let result = try engine.evaluate("""
            return luaswift.toml.decode("age = 30")
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["age"]?.numberValue, 30.0)
    }

    func testDecodeBoolean() throws {
        let result = try engine.evaluate("""
            return luaswift.toml.decode("active = true\\ndisabled = false")
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
            return luaswift.toml.decode('items = ["apple", "banana", "cherry"]')
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
            local toml = [[
            [database]
            host = "localhost"
            port = 5432
            ]]
            return luaswift.toml.decode(toml)
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
            local str = luaswift.toml.encode({name = "John", age = 30})
            return str
            """)

        guard let tomlString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        // Check that the key-value pairs exist (format may vary)
        XCTAssertTrue(tomlString.contains("name") && tomlString.contains("John"))
        XCTAssertTrue(tomlString.contains("age") && tomlString.contains("30"))
    }

    func testEncodeArray() throws {
        let result = try engine.evaluate("""
            local str = luaswift.toml.encode({items = {"a", "b", "c"}})
            return str
            """)

        guard let tomlString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(tomlString.contains("items"))
    }

    func testEncodeNestedTable() throws {
        let result = try engine.evaluate("""
            local tbl = {
                server = {
                    host = "localhost",
                    port = 8080
                }
            }
            return luaswift.toml.encode(tbl)
            """)

        guard let tomlString = result.stringValue else {
            XCTFail("Expected string result")
            return
        }

        XCTAssertTrue(tomlString.contains("server"))
        XCTAssertTrue(tomlString.contains("host"))
    }

    // MARK: - Round Trip

    func testRoundTrip() throws {
        let result = try engine.evaluate("""
            local original = {
                name = "test",
                count = 42,
                enabled = true
            }
            local toml = luaswift.toml.encode(original)
            local decoded = luaswift.toml.decode(toml)
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

    func testDecodeInvalidTOML() throws {
        do {
            _ = try engine.evaluate("""
                return luaswift.toml.decode("invalid = [")
                """)
            XCTFail("Expected error for invalid TOML")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("toml.decode"))
        }
    }

    func testDecodeRequiresString() throws {
        do {
            _ = try engine.evaluate("""
                return luaswift.toml.decode(123)
                """)
            XCTFail("Expected error for non-string argument")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("string"))
        }
    }

    func testEncodeRequiresTable() throws {
        do {
            _ = try engine.evaluate("""
                return luaswift.toml.encode("not a table")
                """)
            XCTFail("Expected error for non-table argument")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("table"))
        }
    }

    // MARK: - Special Values

    func testDecodeFloat() throws {
        let result = try engine.evaluate("""
            return luaswift.toml.decode("pi = 3.14159")
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["pi"]!.numberValue!, 3.14159, accuracy: 0.00001)
    }

    func testDecodeNegativeNumber() throws {
        let result = try engine.evaluate("""
            return luaswift.toml.decode("temp = -40")
            """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["temp"]?.numberValue, -40)
    }

    func testDecodeInlineTable() throws {
        let result = try engine.evaluate("""
            return luaswift.toml.decode('point = { x = 1, y = 2 }')
            """)

        guard let table = result.tableValue,
              let point = table["point"]?.tableValue else {
            XCTFail("Expected nested table")
            return
        }

        XCTAssertEqual(point["x"]?.numberValue, 1)
        XCTAssertEqual(point["y"]?.numberValue, 2)
    }

    func testDecodeArrayOfTables() throws {
        let result = try engine.evaluate("""
            local toml = "[[products]]\\nname = \\"Hammer\\"\\n\\n[[products]]\\nname = \\"Nail\\""
            return luaswift.toml.decode(toml)
            """)

        guard let table = result.tableValue,
              let products = table["products"]?.arrayValue else {
            XCTFail("Expected array of tables")
            return
        }

        XCTAssertEqual(products.count, 2)
        XCTAssertEqual(products[0].tableValue?["name"]?.stringValue, "Hammer")
        XCTAssertEqual(products[1].tableValue?["name"]?.stringValue, "Nail")
    }
}
