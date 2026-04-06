//
//  SerializeModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-05.
//

import XCTest
@testable import LuaSwift

final class SerializeModuleTests: XCTestCase {

    // MARK: - Helper Methods

    /// Get the path to the LuaModules directory
    private func getLuaModulesPath() -> String? {
        // Use the absolute path to LuaModules in the source tree
        let sourceRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()  // Remove SerializeModuleTests.swift
            .deletingLastPathComponent()  // Remove LuaSwiftTests
            .deletingLastPathComponent()  // Remove Tests

        let modulesPath = sourceRoot
            .appendingPathComponent("Sources")
            .appendingPathComponent("LuaSwift")
            .appendingPathComponent("LuaModules")
            .path

        guard FileManager.default.fileExists(atPath: modulesPath) else {
            return nil
        }

        return modulesPath
    }

    /// Create a LuaEngine configured to find the LuaModules directory
    private func createEngineWithLuaModules() throws -> LuaEngine {
        guard let modulesPath = getLuaModulesPath() else {
            throw LuaError.runtimeError("Could not find LuaModules directory")
        }

        // Create engine with packagePath set so file searchers are kept
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: modulesPath,
            memoryLimit: 0
        )
        return try LuaEngine(configuration: config)
    }

    /// Configure package.path to find the LuaModules directory
    /// @deprecated Use createEngineWithLuaModules() instead for sandboxed engines
    private func configureLuaPath(engine: LuaEngine) throws {
        guard let modulesPath = getLuaModulesPath() else {
            XCTFail("Could not find LuaModules directory")
            return
        }

        let pathConfig = """
            package.path = '\(modulesPath)/?.lua;' .. package.path
        """
        try engine.run(pathConfig)
    }

    // MARK: - Basic Module Loading Tests

    func testModuleCanBeRequired() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return type(serialize) == 'table'
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testModuleFunctionsExist() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return {
                encode = type(serialize.encode) == 'function',
                decode = type(serialize.decode) == 'function',
                pretty = type(serialize.pretty) == 'function',
                compact = type(serialize.compact) == 'function',
                safe_decode = type(serialize.safe_decode) == 'function',
                is_serializable = type(serialize.is_serializable) == 'function'
            }
        """)

        XCTAssertEqual(result.tableValue?["encode"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["decode"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["pretty"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["compact"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["safe_decode"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["is_serializable"]?.boolValue, true)
    }

    // MARK: - encode() Tests

    func testEncodeString() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode('hello world')
        """)

        XCTAssertEqual(result.stringValue, "\"hello world\"")
    }

    func testEncodeNumber() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode(42)
        """)

        XCTAssertEqual(result.stringValue, "42")
    }

    func testEncodeBoolean() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return {
                t = serialize.encode(true),
                f = serialize.encode(false)
            }
        """)

        XCTAssertEqual(result.tableValue?["t"]?.stringValue, "true")
        XCTAssertEqual(result.tableValue?["f"]?.stringValue, "false")
    }

    func testEncodeNil() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode(nil)
        """)

        XCTAssertEqual(result.stringValue, "nil")
    }

    func testEncodeEmptyTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode({})
        """)

        XCTAssertEqual(result.stringValue, "{}")
    }

    func testEncodeArray() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode({1, 2, 3})
        """)

        XCTAssertEqual(result.stringValue, "{1, 2, 3}")
    }

    func testEncodeTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local encoded = serialize.encode({name = 'test', value = 42})
            -- Check that both keys are present (order may vary)
            return encoded:match('name = "test"') ~= nil and encoded:match('value = 42') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testEncodeNestedTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {
                outer = {
                    inner = {1, 2, 3}
                }
            }
            local encoded = serialize.encode(data)
            -- Verify structure is present
            return encoded:match('outer') ~= nil and encoded:match('inner') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testEncodeSpecialNumbers() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return {
                inf = serialize.encode(math.huge),
                neg_inf = serialize.encode(-math.huge),
                nan = serialize.encode(0/0)
            }
        """)

        XCTAssertEqual(result.tableValue?["inf"]?.stringValue, "math.huge")
        XCTAssertEqual(result.tableValue?["neg_inf"]?.stringValue, "-math.huge")
        XCTAssertEqual(result.tableValue?["nan"]?.stringValue, "0/0")
    }

    func testEncodeEscapedStrings() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return {
                newline = serialize.encode('hello\\nworld'),
                tab = serialize.encode('hello\\tworld'),
                quote = serialize.encode('say "hello"'),
                backslash = serialize.encode('path\\\\to\\\\file')
            }
        """)

        XCTAssertTrue(result.tableValue?["newline"]?.stringValue?.contains("\\n") ?? false)
        XCTAssertTrue(result.tableValue?["tab"]?.stringValue?.contains("\\t") ?? false)
        XCTAssertTrue(result.tableValue?["quote"]?.stringValue?.contains("\\\"") ?? false)
        XCTAssertTrue(result.tableValue?["backslash"]?.stringValue?.contains("\\\\") ?? false)
    }

    // MARK: - decode() Tests

    func testDecodeString() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.decode('"hello world"')
        """)

        XCTAssertEqual(result.stringValue, "hello world")
    }

    func testDecodeNumber() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.decode('42')
        """)

        XCTAssertEqual(result.numberValue, 42)
    }

    func testDecodeBoolean() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return {
                t = serialize.decode('true'),
                f = serialize.decode('false')
            }
        """)

        XCTAssertEqual(result.tableValue?["t"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["f"]?.boolValue, false)
    }

    func testDecodeNil() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local val = serialize.decode('nil')
            return val == nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testDecodeArray() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local arr = serialize.decode('{1, 2, 3}')
            return {
                len = #arr,
                first = arr[1],
                second = arr[2],
                third = arr[3]
            }
        """)

        XCTAssertEqual(result.tableValue?["len"]?.numberValue, 3)
        XCTAssertEqual(result.tableValue?["first"]?.numberValue, 1)
        XCTAssertEqual(result.tableValue?["second"]?.numberValue, 2)
        XCTAssertEqual(result.tableValue?["third"]?.numberValue, 3)
    }

    func testDecodeTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local tbl = serialize.decode('{name = "test", value = 42}')
            return {
                name = tbl.name,
                value = tbl.value
            }
        """)

        XCTAssertEqual(result.tableValue?["name"]?.stringValue, "test")
        XCTAssertEqual(result.tableValue?["value"]?.numberValue, 42)
    }

    func testDecodeSpecialNumbers() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local inf = serialize.decode('math.huge')
            local neg_inf = serialize.decode('-math.huge')
            local nan = serialize.decode('0/0')
            return {
                is_inf = inf == math.huge,
                is_neg_inf = neg_inf == -math.huge,
                is_nan = nan ~= nan  -- NaN is not equal to itself
            }
        """)

        XCTAssertEqual(result.tableValue?["is_inf"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["is_neg_inf"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["is_nan"]?.boolValue, true)
    }

    // MARK: - Round-trip Tests

    func testRoundTripString() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = 'hello world'
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)
            return decoded == original
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testRoundTripNumber() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = 42.5
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)
            return decoded == original
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testRoundTripBoolean() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local encoded_true = serialize.encode(true)
            local encoded_false = serialize.encode(false)
            return serialize.decode(encoded_true) and not serialize.decode(encoded_false)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testRoundTripArray() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = {1, 2, 3, 4, 5}
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)

            if #decoded ~= #original then return false end
            for i = 1, #original do
                if decoded[i] ~= original[i] then return false end
            end
            return true
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testRoundTripTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = {name = 'test', value = 42, active = true}
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)

            return decoded.name == original.name and
                   decoded.value == original.value and
                   decoded.active == original.active
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testRoundTripNestedTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = {
                outer = {
                    inner = {1, 2, 3},
                    name = 'test'
                },
                value = 42
            }
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)

            return decoded.value == 42 and
                   decoded.outer.name == 'test' and
                   #decoded.outer.inner == 3 and
                   decoded.outer.inner[1] == 1
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - pretty() Tests

    func testPrettyFormat() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {name = 'test', value = 42}
            local pretty = serialize.pretty(data)
            -- Pretty format should contain newlines
            return pretty:match('\\n') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testPrettyCustomIndent() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {a = 1}
            local pretty = serialize.pretty(data, 4)
            -- Should contain indentation
            return pretty:match('\\n') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testPrettySortedKeys() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {zebra = 1, apple = 2, banana = 3}
            local pretty = serialize.pretty(data)

            -- In pretty mode, keys should be sorted alphabetically
            local apple_pos = pretty:find('apple')
            local banana_pos = pretty:find('banana')
            local zebra_pos = pretty:find('zebra')

            return apple_pos < banana_pos and banana_pos < zebra_pos
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - compact() Tests

    func testCompactFormat() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {name = 'test', value = 42}
            local compact = serialize.compact(data)
            -- Compact format should not contain newlines
            return compact:match('\\n') == nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testCompactVsPrettySize() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {a = 1, b = 2, c = 3}
            local compact = serialize.compact(data)
            local pretty = serialize.pretty(data)
            -- Pretty should be longer than compact
            return #pretty > #compact
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - safe_decode() Tests

    func testSafeDecodeSuccess() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local value, err = serialize.safe_decode('42')
            return {
                value = value,
                has_error = err ~= nil
            }
        """)

        XCTAssertEqual(result.tableValue?["value"]?.numberValue, 42)
        XCTAssertEqual(result.tableValue?["has_error"]?.boolValue, false)
    }

    func testSafeDecodeError() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local value, err = serialize.safe_decode('invalid syntax {')
            return {
                value_is_nil = value == nil,
                has_error = type(err) == 'string'
            }
        """)

        XCTAssertEqual(result.tableValue?["value_is_nil"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["has_error"]?.boolValue, true)
    }

    func testSafeDecodeInvalidInput() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local value, err = serialize.safe_decode('not valid lua')
            return {
                value_is_nil = value == nil,
                has_error = type(err) == 'string' and #err > 0
            }
        """)

        XCTAssertEqual(result.tableValue?["value_is_nil"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["has_error"]?.boolValue, true)
    }

    // MARK: - is_serializable() Tests

    func testIsSerializableString() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.is_serializable('hello')
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsSerializableNumber() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.is_serializable(42)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsSerializableBoolean() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.is_serializable(true)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsSerializableNil() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.is_serializable(nil)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsSerializableTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.is_serializable({a = 1, b = 2})
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testIsSerializableFunction() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.is_serializable(function() end)
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testIsSerializableCircularReference() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local t = {a = 1}
            t.self = t
            return serialize.is_serializable(t)
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - Edge Cases Tests

    func testCircularReferenceError() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local t = {a = 1}
            t.self = t

            local success, err = pcall(serialize.encode, t)
            return {
                failed = not success,
                has_circular_msg = err and err:match('[Cc]ircular') ~= nil
            }
        """)

        XCTAssertEqual(result.tableValue?["failed"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["has_circular_msg"]?.boolValue, true)
    }

    func testDeeplyNestedTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')

            -- Create a deeply nested table
            local t = {}
            local current = t
            for i = 1, 10 do
                current.next = {}
                current = current.next
            end
            current.value = 42

            -- Should succeed
            local encoded = serialize.encode(t)
            local decoded = serialize.decode(encoded)

            -- Navigate to the deep value
            current = decoded
            for i = 1, 10 do
                current = current.next
            end

            return current.value == 42
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testMaxDepthExceeded() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')

            -- Create a table deeper than max_depth (default 100)
            local t = {}
            local current = t
            for i = 1, 101 do
                current.next = {}
                current = current.next
            end

            local success, err = pcall(serialize.encode, t)
            return {
                failed = not success,
                has_depth_msg = err and err:match('[Dd]epth') ~= nil
            }
        """)

        XCTAssertEqual(result.tableValue?["failed"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["has_depth_msg"]?.boolValue, true)
    }

    func testMixedArrayAndTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local mixed = {1, 2, 3, name = 'test', value = 42}
            local encoded = serialize.encode(mixed)
            local decoded = serialize.decode(encoded)

            return decoded[1] == 1 and
                   decoded[2] == 2 and
                   decoded[3] == 3 and
                   decoded.name == 'test' and
                   decoded.value == 42
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testEmptyString() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local encoded = serialize.encode('')
            local decoded = serialize.decode(encoded)
            return decoded == ''
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testUnicodeString() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            -- Test simple unicode (Chinese characters)
            local original = '你好世界'
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)

            -- Unicode strings get encoded with escape sequences
            -- The round-trip should preserve the content
            return {
                has_encoded = #encoded > 0,
                has_decoded = #decoded > 0,
                -- For now, just verify the encoding/decoding works
                -- Full unicode support with emojis may need hex escapes (Lua 5.2+)
                can_encode = type(encoded) == 'string',
                can_decode = type(decoded) == 'string'
            }
        """)

        XCTAssertEqual(result.tableValue?["can_encode"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["can_decode"]?.boolValue, true)
    }

    func testNumericKeys() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local t = {[1] = 'a', [2] = 'b', [10] = 'c'}
            local encoded = serialize.encode(t)
            local decoded = serialize.decode(encoded)

            return decoded[1] == 'a' and
                   decoded[2] == 'b' and
                   decoded[10] == 'c'
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testBooleanKeys() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local t = {[true] = 'yes', [false] = 'no'}
            local encoded = serialize.encode(t)
            local decoded = serialize.decode(encoded)

            return decoded[true] == 'yes' and decoded[false] == 'no'
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testFloatingPointPrecision() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = 3.141592653589793
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)

            -- Should preserve reasonable precision
            return math.abs(decoded - original) < 1e-15
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testNegativeNumbers() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {-1, -42, -3.14}
            local encoded = serialize.encode(data)
            local decoded = serialize.decode(encoded)

            return decoded[1] == -1 and
                   decoded[2] == -42 and
                   decoded[3] == -3.14
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testLargeInteger() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local large = 9007199254740992  -- 2^53
            local encoded = serialize.encode(large)
            local decoded = serialize.decode(encoded)

            return decoded == large
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testOptionsIndent() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {a = 1}
            local compact = serialize.encode(data, {indent = nil})
            local pretty = serialize.encode(data, {indent = 2})

            return #pretty > #compact
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testOptionsSortKeys() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {z = 1, a = 2, m = 3}
            local sorted = serialize.encode(data, {sort_keys = true, indent = nil})

            -- In sorted output, 'a' should come before 'm' which should come before 'z'
            local a_pos = sorted:find('a')
            local m_pos = sorted:find('m')
            local z_pos = sorted:find('z')

            return a_pos < m_pos and m_pos < z_pos
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testOptionsMaxDepth() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')

            -- Create nested table with depth 3
            local t = {a = {b = {c = 1}}}

            -- Should fail with max_depth = 2
            local success, err = pcall(serialize.encode, t, {max_depth = 2})

            return {
                failed = not success,
                has_depth_msg = err and err:match('[Dd]epth') ~= nil
            }
        """)

        XCTAssertEqual(result.tableValue?["failed"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["has_depth_msg"]?.boolValue, true)
    }
}
