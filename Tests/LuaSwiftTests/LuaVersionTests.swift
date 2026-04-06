import XCTest
@testable import LuaSwift

/// Tests that validate Lua version-specific behavior.
/// These tests use conditional compilation (#if LUA_VERSION_*) to verify
/// that the correct Lua version is being used and that version-specific
/// features behave as expected.
final class LuaVersionTests: XCTestCase {

    // MARK: - Version Detection

    func testLuaVersionMacroIsDefined() throws {
        // Exactly one version macro should be defined
        var count = 0
        #if LUA_VERSION_51
        count += 1
        #endif
        #if LUA_VERSION_52
        count += 1
        #endif
        #if LUA_VERSION_53
        count += 1
        #endif
        #if LUA_VERSION_54
        count += 1
        #endif
        #if LUA_VERSION_55
        count += 1
        #endif
        XCTAssertEqual(count, 1, "Exactly one LUA_VERSION_* macro should be defined")
    }

    func testLuaVersionString() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return _VERSION")
        let version = result.stringValue ?? ""

        #if LUA_VERSION_51
        XCTAssertTrue(version.contains("5.1"), "Expected Lua 5.1, got \(version)")
        #elseif LUA_VERSION_52
        XCTAssertTrue(version.contains("5.2"), "Expected Lua 5.2, got \(version)")
        #elseif LUA_VERSION_53
        XCTAssertTrue(version.contains("5.3"), "Expected Lua 5.3, got \(version)")
        #elseif LUA_VERSION_54
        XCTAssertTrue(version.contains("5.4"), "Expected Lua 5.4, got \(version)")
        #elseif LUA_VERSION_55
        XCTAssertTrue(version.contains("5.5"), "Expected Lua 5.5, got \(version)")
        #endif
    }

    // MARK: - loadstring Availability

    func testLoadstringAvailability() throws {
        let engine = try LuaEngine(configuration: LuaEngineConfiguration(sandboxed: false, packagePath: nil, memoryLimit: 0))
        let result = try engine.evaluate("return loadstring ~= nil")

        #if LUA_VERSION_51 || LUA_VERSION_52 || LUA_VERSION_53
        // loadstring exists in 5.1 natively, and in 5.2/5.3 via compatibility mode
        // (LUA_COMPAT_ALL for 5.2, LUA_COMPAT_5_1 for 5.3)
        XCTAssertTrue(result.boolValue ?? false, "loadstring should exist in Lua 5.1/5.2/5.3 (with compat)")
        #else
        // loadstring was fully removed in 5.4+ (use load instead)
        // No compatibility option exists to bring it back
        XCTAssertFalse(result.boolValue ?? true, "loadstring should not exist in Lua 5.4+")
        #endif
    }

    func testLoadFunctionExists() throws {
        let engine = try LuaEngine(configuration: LuaEngineConfiguration(sandboxed: false, packagePath: nil, memoryLimit: 0))
        let result = try engine.evaluate("return load ~= nil")

        // load exists in all versions (though behavior differs)
        XCTAssertTrue(result.boolValue ?? false, "load should exist in all Lua versions")
    }

    // MARK: - unpack vs table.unpack

    func testUnpackGlobalAvailability() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return unpack ~= nil")

        #if LUA_VERSION_51
        // unpack is a global in 5.1
        XCTAssertTrue(result.boolValue ?? false, "unpack should be global in Lua 5.1")
        #else
        // In 5.2+, unpack was moved to table.unpack (global may or may not exist)
        // The global unpack doesn't exist by default in 5.2+
        // (compat.lua may provide it, but we're testing vanilla Lua here)
        // Note: Some builds may still have it, so we just document behavior
        _ = result // Behavior varies; this test documents it
        #endif
    }

    func testTableUnpackAvailability() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return table.unpack ~= nil")

        #if LUA_VERSION_51
        // table.unpack doesn't exist in 5.1
        XCTAssertFalse(result.boolValue ?? true, "table.unpack should not exist in Lua 5.1")
        #else
        // table.unpack exists in 5.2+
        XCTAssertTrue(result.boolValue ?? false, "table.unpack should exist in Lua 5.2+")
        #endif
    }

    // MARK: - bit32 Library

    func testBit32NativeAvailability() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return bit32 ~= nil")

        #if LUA_VERSION_51
        // bit32 doesn't exist in 5.1 (unless provided by external library)
        XCTAssertFalse(result.boolValue ?? true, "bit32 should not exist natively in Lua 5.1")
        #elseif LUA_VERSION_52
        // bit32 is native in 5.2
        XCTAssertTrue(result.boolValue ?? false, "bit32 should exist natively in Lua 5.2")
        #else
        // In 5.3+, bit32 was deprecated/removed (bitwise operators added instead)
        // Some builds may include it for compatibility
        // We test that bitwise operators work instead
        _ = result
        #endif
    }

    func testBitwiseOperatorsAvailability() throws {
        let engine = try LuaEngine()

        #if LUA_VERSION_51 || LUA_VERSION_52
        // Bitwise operators (& | ~ >> <<) don't exist in 5.1/5.2
        // They use bit32 library instead
        let result = try engine.evaluate("""
            return pcall(function()
                return load("return 5 & 3")()
            end)
        """)
        XCTAssertFalse(result.boolValue ?? true, "Bitwise operators should not exist in Lua 5.1/5.2")
        #else
        // Bitwise operators exist in 5.3+
        let result = try engine.evaluate("return 5 & 3")
        XCTAssertEqual(result.intValue, 1, "5 & 3 should equal 1 in Lua 5.3+")
        #endif
    }

    // MARK: - utf8 Library

    func testUtf8LibraryAvailability() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return utf8 ~= nil")

        #if LUA_VERSION_51 || LUA_VERSION_52
        // utf8 library doesn't exist in 5.1/5.2
        XCTAssertFalse(result.boolValue ?? true, "utf8 library should not exist in Lua 5.1/5.2")
        #else
        // utf8 library exists in 5.3+
        XCTAssertTrue(result.boolValue ?? false, "utf8 library should exist in Lua 5.3+")
        #endif
    }

    func testUtf8Len() throws {
        let engine = try LuaEngine()

        #if LUA_VERSION_51 || LUA_VERSION_52
        // Skip - utf8 library doesn't exist
        #else
        let result = try engine.evaluate("return utf8.len('hello')")
        XCTAssertEqual(result.intValue, 5)

        let unicodeResult = try engine.evaluate("return utf8.len('héllo')")
        XCTAssertEqual(unicodeResult.intValue, 5, "utf8.len should count characters, not bytes")
        #endif
    }

    // MARK: - Integer Division Operator

    func testIntegerDivisionOperator() throws {
        let engine = try LuaEngine()

        #if LUA_VERSION_51 || LUA_VERSION_52
        // Integer division operator // doesn't exist
        let result = try engine.evaluate("""
            return pcall(function()
                return load("return 7 // 2")()
            end)
        """)
        XCTAssertFalse(result.boolValue ?? true, "// operator should not exist in Lua 5.1/5.2")
        #else
        // Integer division exists in 5.3+
        let result = try engine.evaluate("return 7 // 2")
        XCTAssertEqual(result.intValue, 3, "7 // 2 should equal 3")
        #endif
    }

    // MARK: - goto Statement

    func testGotoStatement() throws {
        let engine = try LuaEngine()

        #if LUA_VERSION_51
        // goto doesn't exist in 5.1
        let result = try engine.evaluate("""
            return pcall(function()
                return load([[
                    local x = 0
                    ::start::
                    x = x + 1
                    if x < 3 then goto start end
                    return x
                ]])()
            end)
        """)
        XCTAssertFalse(result.boolValue ?? true, "goto should not exist in Lua 5.1")
        #else
        // goto exists in 5.2+
        let result = try engine.evaluate("""
            local x = 0
            ::start::
            x = x + 1
            if x < 3 then goto start end
            return x
        """)
        XCTAssertEqual(result.intValue, 3, "goto loop should work in Lua 5.2+")
        #endif
    }

    // MARK: - _ENV

    func testEnvAvailability() throws {
        let engine = try LuaEngine()

        #if LUA_VERSION_51
        // _ENV doesn't exist in 5.1 (uses setfenv/getfenv instead)
        let result = try engine.evaluate("return _ENV == nil")
        XCTAssertTrue(result.boolValue ?? false, "_ENV should not exist in Lua 5.1")
        #else
        // _ENV exists in 5.2+
        let result = try engine.evaluate("return _ENV ~= nil")
        XCTAssertTrue(result.boolValue ?? false, "_ENV should exist in Lua 5.2+")
        #endif
    }

    // MARK: - setfenv/getfenv (5.1 only)

    func testSetfenvGetfenv() throws {
        let engine = try LuaEngine(configuration: LuaEngineConfiguration(sandboxed: false, packagePath: nil, memoryLimit: 0))
        let setfenvResult = try engine.evaluate("return setfenv ~= nil")
        let getfenvResult = try engine.evaluate("return getfenv ~= nil")

        #if LUA_VERSION_51
        // setfenv/getfenv exist in 5.1
        XCTAssertTrue(setfenvResult.boolValue ?? false, "setfenv should exist in Lua 5.1")
        XCTAssertTrue(getfenvResult.boolValue ?? false, "getfenv should exist in Lua 5.1")
        #else
        // setfenv/getfenv were removed in 5.2+
        XCTAssertFalse(setfenvResult.boolValue ?? true, "setfenv should not exist in Lua 5.2+")
        XCTAssertFalse(getfenvResult.boolValue ?? true, "getfenv should not exist in Lua 5.2+")
        #endif
    }

    // MARK: - String Escape Sequences

    func testHexEscapeSequence() throws {
        let engine = try LuaEngine()

        // \xNN hex escapes were added in Lua 5.2
        #if LUA_VERSION_51
        // In 5.1, \x is not recognized - this may cause syntax error or be literal
        // Behavior varies, so we just document it
        #else
        let result = try engine.evaluate("return '\\x41'")
        XCTAssertEqual(result.stringValue, "A", "\\x41 should equal 'A' in Lua 5.2+")
        #endif
    }

    // MARK: - Integers vs Floats (5.3+)

    func testIntegerType() throws {
        let engine = try LuaEngine()

        #if LUA_VERSION_51 || LUA_VERSION_52
        // In 5.1/5.2, all numbers are floats
        let result = try engine.evaluate("return math.type ~= nil")
        XCTAssertFalse(result.boolValue ?? true, "math.type should not exist in Lua 5.1/5.2")
        #else
        // In 5.3+, integers and floats are distinct subtypes
        let intResult = try engine.evaluate("return math.type(1)")
        XCTAssertEqual(intResult.stringValue, "integer")

        let floatResult = try engine.evaluate("return math.type(1.0)")
        XCTAssertEqual(floatResult.stringValue, "float")
        #endif
    }

    // MARK: - Coroutine Improvements

    func testCoroutineIsyieldable() throws {
        let engine = try LuaEngine()

        #if LUA_VERSION_51 || LUA_VERSION_52
        // coroutine.isyieldable doesn't exist
        let result = try engine.evaluate("return coroutine.isyieldable == nil")
        XCTAssertTrue(result.boolValue ?? false, "coroutine.isyieldable should not exist in Lua 5.1/5.2")
        #else
        // coroutine.isyieldable exists in 5.3+
        let result = try engine.evaluate("return coroutine.isyieldable ~= nil")
        XCTAssertTrue(result.boolValue ?? false, "coroutine.isyieldable should exist in Lua 5.3+")
        #endif
    }

    // MARK: - warn Function (5.4+)

    func testWarnFunction() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("return warn ~= nil")

        #if LUA_VERSION_51 || LUA_VERSION_52 || LUA_VERSION_53
        XCTAssertFalse(result.boolValue ?? true, "warn should not exist in Lua 5.1/5.2/5.3")
        #else
        XCTAssertTrue(result.boolValue ?? false, "warn should exist in Lua 5.4+")
        #endif
    }

    // MARK: - const and close (5.4+)

    func testToBeClosedVariables() throws {
        let engine = try LuaEngine()

        #if LUA_VERSION_51 || LUA_VERSION_52 || LUA_VERSION_53
        // <close> attribute doesn't exist
        #else
        // In 5.4+, <close> creates to-be-closed variables
        let result = try engine.evaluate("""
            local closed = false
            do
                local x <close> = setmetatable({}, {
                    __close = function() closed = true end
                })
            end
            return closed
        """)
        XCTAssertTrue(result.boolValue ?? false, "<close> variable should trigger __close in Lua 5.4+")
        #endif
    }
}
