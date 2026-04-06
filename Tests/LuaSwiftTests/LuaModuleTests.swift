//
//  LuaModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//

import XCTest
@testable import LuaSwift

final class LuaModuleTests: XCTestCase {

    // MARK: - Helper Methods

    /// Get the path to the LuaModules directory
    private func getLuaModulesPath() -> String? {
        // Use the absolute path to LuaModules in the source tree
        // This works because Swift tests run from the package root
        let sourceRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()  // Remove LuaModuleTests.swift
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
        let engine = try LuaEngine(configuration: config)

        // Register Swift-backed modules (svg.lua was replaced by SVGModule.swift)
        SVGModule.register(in: engine)

        return engine
    }

    /// Configure package.path to find the LuaModules directory and register Swift-backed modules
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

        // Register Swift-backed modules (svg.lua was replaced by SVGModule.swift)
        SVGModule.register(in: engine)
    }

    // MARK: - SVG Module Tests

    func testSVGCreate() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(400, 300)
            return {
                width = drawing.width,
                height = drawing.height
            }
        """)

        XCTAssertNotNil(result.tableValue)
        XCTAssertEqual(result.tableValue?["width"]?.numberValue, 400)
        XCTAssertEqual(result.tableValue?["height"]?.numberValue, 300)
    }

    func testSVGRect() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(200, 200)
            drawing:rect(10, 20, 50, 30, {fill = 'red', stroke = 'black'})
            local svgStr = drawing:render()
            return svgStr:match('rect') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGCircle() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(200, 200)
            drawing:circle(100, 100, 50, {fill = 'blue'})
            local svgStr = drawing:render()
            return svgStr:match('circle') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGText() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(300, 100)
            drawing:text('Hello World', 150, 50, {font_size = 16})
            local svgStr = drawing:render()
            return svgStr:match('Hello World') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGGreekLetters() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(200, 100)
            local text = svg.greek.alpha .. svg.greek.beta .. svg.greek.pi
            drawing:text(text, 100, 50)
            local svgStr = drawing:render()
            -- Check for Greek letter alpha (α)
            return svgStr:match('α') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGLinePlot() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(400, 300)
            local points = {
                {x = 10, y = 100},
                {x = 50, y = 80},
                {x = 90, y = 120},
                {x = 130, y = 60}
            }
            drawing:linePlot(points, {stroke = 'blue', stroke_width = 2})
            local svgStr = drawing:render()
            return svgStr:match('polyline') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGRender() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(100, 100)
            drawing:rect(0, 0, 100, 100, {fill = 'white'})
            local svgStr = drawing:render()
            -- Check for SVG header and proper structure
            local hasXMLDecl = svgStr:match('<?xml') ~= nil
            local hasSVGTag = svgStr:match('<svg') ~= nil
            local hasClosing = svgStr:match('</svg>') ~= nil
            return hasXMLDecl and hasSVGTag and hasClosing
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - SVG Integration Tests

    func testSVGGreekLettersInText() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(400, 100)
            -- Create text with multiple Greek letters
            local text = svg.greek.pi .. ' ' .. svg.greek.alpha .. ' ' .. svg.greek.beta
            drawing:text(text, 200, 50, {font_size = 24})
            local svgStr = drawing:render()
            -- Check for Greek letters
            local hasPi = svgStr:match('π') ~= nil
            local hasAlpha = svgStr:match('α') ~= nil
            local hasBeta = svgStr:match('β') ~= nil
            return hasPi and hasAlpha and hasBeta
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGGroupTransform() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(300, 300)
            local group = drawing:group(svg.translate(50, 50))
            group:rect(0, 0, 100, 100, {fill = 'red'})
            local svgStr = drawing:render()
            -- Check for group with transform
            return svgStr:match('<g') ~= nil and svgStr:match('transform') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGPolylineAndPolygon() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local svg = require('luaswift.svg')
            local drawing = svg.create(400, 400)
            local points = {
                {x = 100, y = 100},
                {x = 200, y = 150},
                {x = 150, y = 200}
            }
            drawing:polyline(points, {stroke = 'blue', fill = 'none'})
            drawing:polygon(points, {stroke = 'red', fill = 'yellow'})
            local svgStr = drawing:render()
            local hasPolyline = svgStr:match('polyline') ~= nil
            local hasPolygon = svgStr:match('polygon') ~= nil
            return hasPolyline and hasPolygon
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Compat Module Tests

    func testCompatVersion() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.version
        """)

        // Version should match the Lua version we're built with
        let version = result.stringValue
        let validVersions = ["5.1", "5.2", "5.3", "5.4", "5.5"]
        XCTAssertTrue(validVersions.contains(version ?? ""), "Expected valid Lua version, got \(version ?? "nil")")
    }

    func testCompatVersionFlags() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                lua51 = compat.lua51,
                lua52 = compat.lua52,
                lua53 = compat.lua53,
                lua54 = compat.lua54,
                lua55 = compat.lua55
            }
        """)

        // Exactly one version flag should be true
        let lua51 = result.tableValue?["lua51"]?.boolValue ?? false
        let lua52 = result.tableValue?["lua52"]?.boolValue ?? false
        let lua53 = result.tableValue?["lua53"]?.boolValue ?? false
        let lua54 = result.tableValue?["lua54"]?.boolValue ?? false
        let lua55 = result.tableValue?["lua55"]?.boolValue ?? false

        let trueCount = [lua51, lua52, lua53, lua54, lua55].filter { $0 }.count
        XCTAssertEqual(trueCount, 1, "Exactly one version flag should be true")
    }

    func testCompatFeatures() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                version = compat.version,
                table_unpack = compat.features.table_unpack,
                utf8_library = compat.features.utf8_library,
                bitwise_ops = compat.features.bitwise_ops
            }
        """)

        // Features depend on Lua version
        let version = result.tableValue?["version"]?.stringValue ?? "5.4"
        let minor = Int(version.split(separator: ".").last ?? "4") ?? 4

        // table_unpack: 5.2+
        let expectedTableUnpack = minor >= 2
        XCTAssertEqual(result.tableValue?["table_unpack"]?.boolValue, expectedTableUnpack)

        // utf8_library: 5.3+
        let expectedUtf8 = minor >= 3
        XCTAssertEqual(result.tableValue?["utf8_library"]?.boolValue, expectedUtf8)

        // bitwise_ops: 5.3+
        let expectedBitwise = minor >= 3
        XCTAssertEqual(result.tableValue?["bitwise_ops"]?.boolValue, expectedBitwise)
    }

    func testCompatBit32Band() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.band(0xFF, 0x0F)
        """)

        XCTAssertEqual(result.numberValue, 0x0F)
    }

    func testCompatBit32Bor() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.bor(0xF0, 0x0F)
        """)

        XCTAssertEqual(result.numberValue, 0xFF)
    }

    func testCompatBit32Bxor() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.bxor(0xFF, 0x0F)
        """)

        XCTAssertEqual(result.numberValue, 0xF0)
    }

    func testCompatBit32Bnot() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.bnot(0)
        """)

        XCTAssertEqual(result.numberValue, 0xFFFFFFFF)
    }

    func testCompatBit32Lshift() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.lshift(1, 4)
        """)

        XCTAssertEqual(result.numberValue, 16)
    }

    func testCompatBit32Rshift() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.rshift(16, 4)
        """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testCompatBit32Lrotate() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.lrotate(0x80000000, 1)
        """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testCompatBit32Rrotate() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.rrotate(1, 1)
        """)

        XCTAssertEqual(result.numberValue, 0x80000000)
    }

    func testCompatBit32Btest() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                has_bit = compat.bit32.btest(0xFF, 0x01),
                no_bit = compat.bit32.btest(0xF0, 0x01)
            }
        """)

        XCTAssertEqual(result.tableValue?["has_bit"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["no_bit"]?.boolValue, false)
    }

    func testCompatBit32Extract() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.extract(0xABCD, 4, 8)
        """)

        XCTAssertEqual(result.numberValue, 0xBC)
    }

    func testCompatBit32Replace() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.replace(0xABCD, 0xFF, 4, 8)
        """)

        XCTAssertEqual(result.numberValue, 0xAFFD)
    }

    func testCompatVersionCompare() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                less = compat.version_compare("5.3", "5.4") < 0,
                equal = compat.version_compare("5.4", "5.4") == 0,
                greater = compat.version_compare("5.4", "5.3") > 0
            }
        """)

        XCTAssertEqual(result.tableValue?["less"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["equal"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["greater"]?.boolValue, true)
    }

    func testCompatVersionAtLeast() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                version = compat.version,
                at_least_51 = compat.version_at_least("5.1"),
                at_least_52 = compat.version_at_least("5.2"),
                at_least_53 = compat.version_at_least("5.3"),
                at_least_54 = compat.version_at_least("5.4"),
                at_least_55 = compat.version_at_least("5.5"),
                at_least_56 = compat.version_at_least("5.6")
            }
        """)

        // Get current version
        let version = result.tableValue?["version"]?.stringValue ?? "5.4"
        let minor = Int(version.split(separator: ".").last ?? "4") ?? 4

        // All versions should be at least 5.1
        XCTAssertEqual(result.tableValue?["at_least_51"]?.boolValue, true)

        // Version checks depend on current version
        XCTAssertEqual(result.tableValue?["at_least_52"]?.boolValue, minor >= 2)
        XCTAssertEqual(result.tableValue?["at_least_53"]?.boolValue, minor >= 3)
        XCTAssertEqual(result.tableValue?["at_least_54"]?.boolValue, minor >= 4)
        XCTAssertEqual(result.tableValue?["at_least_55"]?.boolValue, minor >= 5)

        // No version should be at least 5.6 (doesn't exist yet)
        XCTAssertEqual(result.tableValue?["at_least_56"]?.boolValue, false)
    }

    func testCompatInstall() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            compat.install()
            -- After install, bit32 should be available globally
            return bit32 ~= nil and bit32.band(0xFF, 0x0F) == 0x0F
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testCompatCheckDeprecated() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local warnings = compat.check_deprecated("setfenv(1, {}) bit32.band(1,2)")
            return {
                count = #warnings,
                version = compat.version
            }
        """)

        // Warnings depend on version:
        // - setfenv: warning in 5.2+ (removed in 5.2)
        // - bit32: warning in 5.4+ (removed in 5.4)
        let version = result.tableValue?["version"]?.stringValue ?? "5.4"
        let minor = Int(version.split(separator: ".").last ?? "4") ?? 4

        var expectedWarnings = 0
        if minor >= 2 { expectedWarnings += 1 }  // setfenv warning
        if minor >= 4 { expectedWarnings += 1 }  // bit32 warning

        XCTAssertEqual(result.tableValue?["count"]?.numberValue, Double(expectedWarnings))
    }

    // MARK: - Compat Module Edge Cases

    func testCompatBit32BandEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                -- Zero cases
                zero_and_anything = b.band(0, 0xFFFFFFFF),
                anything_and_zero = b.band(0xFFFFFFFF, 0),
                -- Max value cases
                max_and_max = b.band(0xFFFFFFFF, 0xFFFFFFFF),
                -- Multiple arguments
                multi_arg = b.band(0xFF, 0x0F, 0x03),
                -- Single argument
                single_arg = b.band(0xABCD),
                -- No arguments (should return all 1s)
                no_args = b.band()
            }
        """)

        XCTAssertEqual(result.tableValue?["zero_and_anything"]?.numberValue, 0)
        XCTAssertEqual(result.tableValue?["anything_and_zero"]?.numberValue, 0)
        XCTAssertEqual(result.tableValue?["max_and_max"]?.numberValue, 0xFFFFFFFF)
        XCTAssertEqual(result.tableValue?["multi_arg"]?.numberValue, 0x03)
        XCTAssertEqual(result.tableValue?["single_arg"]?.numberValue, 0xABCD)
        XCTAssertEqual(result.tableValue?["no_args"]?.numberValue, 0xFFFFFFFF)
    }

    func testCompatBit32BorEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                zero_or_anything = b.bor(0, 0xABCD),
                max_or_anything = b.bor(0xFFFFFFFF, 0),
                multi_arg = b.bor(0x01, 0x02, 0x04, 0x08),
                no_args = b.bor()
            }
        """)

        XCTAssertEqual(result.tableValue?["zero_or_anything"]?.numberValue, 0xABCD)
        XCTAssertEqual(result.tableValue?["max_or_anything"]?.numberValue, 0xFFFFFFFF)
        XCTAssertEqual(result.tableValue?["multi_arg"]?.numberValue, 0x0F)
        XCTAssertEqual(result.tableValue?["no_args"]?.numberValue, 0)
    }

    func testCompatBit32ShiftEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                -- Zero shift
                lshift_zero = b.lshift(0xABCD, 0),
                rshift_zero = b.rshift(0xABCD, 0),
                -- Shift by 31 (max useful shift)
                lshift_31 = b.lshift(1, 31),
                rshift_31 = b.rshift(0x80000000, 31),
                -- Shift by 32 (should be 0 for logical shift)
                lshift_32 = b.lshift(0xFFFFFFFF, 32),
                rshift_32 = b.rshift(0xFFFFFFFF, 32),
                -- Shift more than 32
                lshift_33 = b.lshift(1, 33),
                rshift_33 = b.rshift(0x80000000, 33),
                -- Large shift values (should be 0)
                lshift_100 = b.lshift(0xFFFFFFFF, 100)
            }
        """)

        XCTAssertEqual(result.tableValue?["lshift_zero"]?.numberValue, 0xABCD)
        XCTAssertEqual(result.tableValue?["rshift_zero"]?.numberValue, 0xABCD)
        XCTAssertEqual(result.tableValue?["lshift_31"]?.numberValue, 0x80000000)
        XCTAssertEqual(result.tableValue?["rshift_31"]?.numberValue, 1)
        XCTAssertEqual(result.tableValue?["lshift_32"]?.numberValue, 0)
        XCTAssertEqual(result.tableValue?["rshift_32"]?.numberValue, 0)
        XCTAssertEqual(result.tableValue?["lshift_33"]?.numberValue, 0)
        XCTAssertEqual(result.tableValue?["rshift_33"]?.numberValue, 0)
        XCTAssertEqual(result.tableValue?["lshift_100"]?.numberValue, 0)
    }

    func testCompatBit32RotateEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                -- Zero rotation
                lrotate_zero = b.lrotate(0xABCD, 0),
                rrotate_zero = b.rrotate(0xABCD, 0),
                -- Full rotation (32 bits = identity)
                lrotate_32 = b.lrotate(0xABCD, 32),
                rrotate_32 = b.rrotate(0xABCD, 32),
                -- Rotation > 32 (should wrap)
                lrotate_33 = b.lrotate(1, 33),
                -- Negative rotation (should work as opposite direction)
                lrotate_neg = b.lrotate(1, -1),
                rrotate_neg = b.rrotate(0x80000000, -1)
            }
        """)

        XCTAssertEqual(result.tableValue?["lrotate_zero"]?.numberValue, 0xABCD)
        XCTAssertEqual(result.tableValue?["rrotate_zero"]?.numberValue, 0xABCD)
        XCTAssertEqual(result.tableValue?["lrotate_32"]?.numberValue, 0xABCD)
        XCTAssertEqual(result.tableValue?["rrotate_32"]?.numberValue, 0xABCD)
        XCTAssertEqual(result.tableValue?["lrotate_33"]?.numberValue, 2) // Same as lrotate(1, 1)
        XCTAssertEqual(result.tableValue?["lrotate_neg"]?.numberValue, 0x80000000) // Same as rrotate(1, 1)
        XCTAssertEqual(result.tableValue?["rrotate_neg"]?.numberValue, 1) // Same as lrotate(0x80000000, 1)
    }

    func testCompatBit32ExtractEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                -- Extract from position 0
                extract_pos0 = b.extract(0xABCDEF12, 0, 8),
                -- Extract with width 1
                extract_width1 = b.extract(0xABCDEF12, 0, 1),
                extract_width1_at4 = b.extract(0xABCDEF12, 4, 1),
                -- Extract full 32 bits
                extract_full = b.extract(0xABCDEF12, 0, 32),
                -- Extract high bits
                extract_high = b.extract(0xABCDEF12, 24, 8),
                -- Default width (1 bit)
                extract_default_width = b.extract(0xABCDEF12, 0)
            }
        """)

        XCTAssertEqual(result.tableValue?["extract_pos0"]?.numberValue, 0x12)
        XCTAssertEqual(result.tableValue?["extract_width1"]?.numberValue, 0)  // LSB is 0
        XCTAssertEqual(result.tableValue?["extract_width1_at4"]?.numberValue, 1)  // Bit 4 is 1
        XCTAssertEqual(result.tableValue?["extract_full"]?.numberValue, 0xABCDEF12)
        XCTAssertEqual(result.tableValue?["extract_high"]?.numberValue, 0xAB)
        XCTAssertEqual(result.tableValue?["extract_default_width"]?.numberValue, 0)
    }

    func testCompatBit32ReplaceEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                -- Replace at position 0
                replace_pos0 = b.replace(0xABCDEF00, 0x12, 0, 8),
                -- Replace single bit
                replace_bit = b.replace(0x00000000, 1, 4, 1),
                -- Replace high byte
                replace_high = b.replace(0x00CDEF12, 0xAB, 24, 8),
                -- Default width (1 bit)
                replace_default = b.replace(0x00000000, 1, 0)
            }
        """)

        XCTAssertEqual(result.tableValue?["replace_pos0"]?.numberValue, 0xABCDEF12)
        XCTAssertEqual(result.tableValue?["replace_bit"]?.numberValue, 0x10)
        XCTAssertEqual(result.tableValue?["replace_high"]?.numberValue, 0xABCDEF12)
        XCTAssertEqual(result.tableValue?["replace_default"]?.numberValue, 0x01)
    }

    func testCompatBit32BtestEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                -- All zeros
                zero_zero = b.btest(0, 0),
                -- All ones
                ones_ones = b.btest(0xFFFFFFFF, 0xFFFFFFFF),
                -- Multiple arguments
                multi_true = b.btest(0xFF, 0x0F, 0x01),
                multi_false = b.btest(0xFF, 0xF0, 0x0F)
            }
        """)

        XCTAssertEqual(result.tableValue?["zero_zero"]?.boolValue, false)
        XCTAssertEqual(result.tableValue?["ones_ones"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["multi_true"]?.boolValue, true)  // 0xFF & 0x0F & 0x01 = 0x01 != 0
        XCTAssertEqual(result.tableValue?["multi_false"]?.boolValue, false)  // 0xFF & 0xF0 & 0x0F = 0
    }

    func testCompatBit32ArshiftEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                -- Positive number (should behave like rshift)
                arshift_pos = b.arshift(0x7FFFFFFF, 4),
                -- High bit set (should fill with 1s)
                arshift_neg = b.arshift(0x80000000, 4),
                -- Shift by 0
                arshift_zero = b.arshift(0x80000000, 0),
                -- Shift by 32+
                arshift_32 = b.arshift(0x80000000, 32)
            }
        """)

        XCTAssertEqual(result.tableValue?["arshift_pos"]?.numberValue, 0x07FFFFFF)
        XCTAssertEqual(result.tableValue?["arshift_neg"]?.numberValue, 0xF8000000)
        XCTAssertEqual(result.tableValue?["arshift_zero"]?.numberValue, 0x80000000)
        // arshift by 32 with high bit set should give 0xFFFFFFFF
        XCTAssertEqual(result.tableValue?["arshift_32"]?.numberValue, 0xFFFFFFFF)
    }

    func testCompatVersionCompareEdgeCases() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                -- Patch versions are treated as equal (only major.minor compared)
                -- This documents current limitation of version_compare
                patch_ignored = compat.version_compare("5.4.1", "5.4.2") == 0,
                patch_equal = compat.version_compare("5.4.1", "5.4.1") == 0,
                -- Major version difference
                major_diff = compat.version_compare("4.0", "5.0") < 0,
                major_greater = compat.version_compare("5.0", "4.0") > 0,
                -- Minor version difference
                minor_less = compat.version_compare("5.3", "5.4") < 0,
                minor_greater = compat.version_compare("5.4", "5.3") > 0,
                -- Same versions
                same = compat.version_compare("5.4", "5.4") == 0,
                -- Versions with different lengths (5.4 vs 5.4.0)
                short_vs_long = compat.version_compare("5.4", "5.4.0") == 0
            }
        """)

        // Patch versions are ignored - only major.minor compared
        XCTAssertEqual(result.tableValue?["patch_ignored"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["patch_equal"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["major_diff"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["major_greater"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["minor_less"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["minor_greater"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["same"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["short_vs_long"]?.boolValue, true)
    }

    func testCompatInstallIdempotent() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            -- Install multiple times
            compat.install()
            compat.install()
            compat.install()
            -- bit32 should still work correctly
            return bit32 ~= nil and bit32.band(0xFF, 0x0F) == 0x0F
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testCompatUnpackAlias() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            compat.install()
            -- unpack should work (either native or from compat)
            local t = {10, 20, 30, 40, 50}
            local a, b, c = unpack(t)
            local d, e = unpack(t, 4)  -- from index 4
            local f = unpack(t, 2, 2)  -- just index 2
            return {a = a, b = b, c = c, d = d, e = e, f = f}
        """)

        XCTAssertEqual(result.tableValue?["a"]?.numberValue, 10)
        XCTAssertEqual(result.tableValue?["b"]?.numberValue, 20)
        XCTAssertEqual(result.tableValue?["c"]?.numberValue, 30)
        XCTAssertEqual(result.tableValue?["d"]?.numberValue, 40)
        XCTAssertEqual(result.tableValue?["e"]?.numberValue, 50)
        XCTAssertEqual(result.tableValue?["f"]?.numberValue, 20)
    }

    func testCompatTablePackAvailability() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            compat.install()
            -- table.pack should exist (native in 5.2+ or from compat)
            if table.pack then
                local t = table.pack(10, 20, 30)
                return {
                    available = true,
                    n = t.n,
                    first = t[1],
                    last = t[3]
                }
            else
                return {available = false}
            end
        """)

        // table.pack exists in 5.2+, compat may or may not provide it for 5.1
        if result.tableValue?["available"]?.boolValue == true {
            XCTAssertEqual(result.tableValue?["n"]?.numberValue, 3)
            XCTAssertEqual(result.tableValue?["first"]?.numberValue, 10)
            XCTAssertEqual(result.tableValue?["last"]?.numberValue, 30)
        }
    }

    func testCompatBit32_32BitWrapping() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local compat = require('compat')
            local b = compat.bit32
            return {
                -- Input should be truncated to 32 bits
                large_input = b.band(0x1FFFFFFFF, 0xFFFFFFFF),
                -- bnot should produce 32-bit result
                bnot_max = b.bnot(0xFFFFFFFF),
                -- bxor identity
                xor_self = b.bxor(0xABCDEF12, 0xABCDEF12)
            }
        """)

        // Large input gets truncated to 32 bits: 0x1FFFFFFFF & 0xFFFFFFFF = 0xFFFFFFFF
        XCTAssertEqual(result.tableValue?["large_input"]?.numberValue, 0xFFFFFFFF)
        XCTAssertEqual(result.tableValue?["bnot_max"]?.numberValue, 0)
        XCTAssertEqual(result.tableValue?["xor_self"]?.numberValue, 0)
    }

    // MARK: - Stdlib Extension Tests

    func testExtendStdlibExists() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            return type(luaswift.extend_stdlib) == "function"
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testExtendStdlibImportsStringx() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            luaswift.extend_stdlib()
            return string.capitalize("hello")
            """)
        XCTAssertEqual(result.stringValue, "Hello")
    }

    func testExtendStdlibImportsMathx() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            luaswift.extend_stdlib()
            return math.sign(-5)
            """)
        XCTAssertEqual(result.numberValue, -1)
    }

    func testExtendStdlibImportsTablex() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            luaswift.extend_stdlib()
            return table.keys({a = 1, b = 2})[1] ~= nil
            """)
        XCTAssertEqual(result.boolValue, true)
    }

    #if LUASWIFT_NUMERICSWIFT
    func testExtendStdlibCreatesMathComplex() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            luaswift.extend_stdlib()
            local c = math.complex.new(3, 4)
            return c.re
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testExtendStdlibCreatesMathLinalg() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            luaswift.extend_stdlib()
            local v = math.linalg.vector({1, 2, 3})
            return v:size()
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testExtendStdlibCreatesMathGeo() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            luaswift.extend_stdlib()
            local v = math.geo.vec2(3, 4)
            return v.x
            """)
        XCTAssertEqual(result.numberValue, 3)
    }
    #endif  // LUASWIFT_NUMERICSWIFT

    // MARK: - Top-level Alias Tests

    func testTopLevelAliasJson() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            return json.encode({a = 1})
            """)
        XCTAssertNotNil(result.stringValue)
    }

    #if LUASWIFT_NUMERICSWIFT
    func testTopLevelAliasComplex() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            local c = complex.new(1, 2)
            return c.im
            """)
        XCTAssertEqual(result.numberValue, 2)
    }

    func testTopLevelAliasLinalg() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            local m = linalg.eye(3)
            return m:get(1, 1)
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testTopLevelAliasGeo() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            local v = geo.vec3(1, 2, 3)
            return v.z
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testTopLevelAliasTypes() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            return types.typeof(complex.new(1, 2))
            """)
        XCTAssertEqual(result.stringValue, "complex")
    }
    #endif  // LUASWIFT_NUMERICSWIFT

    #if LUASWIFT_ARRAYSWIFT
    func testTopLevelAliasArray() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            local a = array.array({1, 2, 3})
            return a:sum()
            """)
        XCTAssertEqual(result.numberValue, 6)
    }
    #endif  // LUASWIFT_ARRAYSWIFT

    // MARK: - Serialize Module Tests

    func testSerializeEncodeNumber() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode(42)
        """)

        XCTAssertEqual(result.stringValue, "42")
    }

    func testSerializeEncodeString() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode("hello")
        """)

        XCTAssertEqual(result.stringValue, "\"hello\"")
    }

    func testSerializeEncodeBoolean() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode(true) .. "," .. serialize.encode(false)
        """)

        XCTAssertEqual(result.stringValue, "true,false")
    }

    func testSerializeEncodeNil() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode(nil)
        """)

        XCTAssertEqual(result.stringValue, "nil")
    }

    func testSerializeEncodeArray() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode({1, 2, 3})
        """)

        XCTAssertEqual(result.stringValue, "{1, 2, 3}")
    }

    func testSerializeEncodeTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local str = serialize.encode({name = "test"})
            return str:match("name") ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeEncodeNestedTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local data = {
                user = {name = "Alice", age = 30},
                scores = {100, 95, 88}
            }
            local str = serialize.encode(data)
            return str:match("Alice") ~= nil and str:match("100") ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeDecodeNumber() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.decode("42")
        """)

        XCTAssertEqual(result.numberValue, 42)
    }

    func testSerializeDecodeString() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.decode('"hello"')
        """)

        XCTAssertEqual(result.stringValue, "hello")
    }

    func testSerializeDecodeTable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local t = serialize.decode('{a = 1, b = 2}')
            return t.a + t.b
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testSerializeRoundTrip() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = {
                name = "test",
                values = {1, 2, 3},
                nested = {x = 10, y = 20}
            }
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)
            return decoded.name == "test" and
                   decoded.values[2] == 2 and
                   decoded.nested.x == 10
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializePretty() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local str = serialize.pretty({a = 1})
            return str:match("\\n") ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeCompact() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local str = serialize.compact({a = 1, b = 2})
            return str:match("\\n") == nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeSafeDecode() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local val, err = serialize.safe_decode("invalid{{{")
            return val == nil and err ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeIsSerializable() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return {
                table_ok = serialize.is_serializable({a = 1}),
                string_ok = serialize.is_serializable("hello"),
                func_bad = not serialize.is_serializable(function() end)
            }
        """)

        XCTAssertEqual(result.tableValue?["table_ok"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["string_ok"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["func_bad"]?.boolValue, true)
    }

    func testSerializeSpecialNumbers() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local huge = serialize.encode(math.huge)
            local neg_huge = serialize.encode(-math.huge)
            return huge == "math.huge" and neg_huge == "-math.huge"
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeEscapedStrings() throws {
        let engine = try createEngineWithLuaModules()

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = 'hello\\nworld\\t"quoted"'
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)
            return decoded == original
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Bundle Resource Loading Tests

    /// Test that verifies loading Lua modules from a resource bundle works correctly.
    /// This test documents the recommended production pattern for loading bundled modules.
    ///
    /// Note: In production apps using LuaSwift as a dependency, you would use:
    /// ```swift
    /// import LuaSwift
    /// // Within the LuaSwift module:
    /// // let path = Bundle.module.resourcePath! + "/LuaModules"
    /// ```
    ///
    /// In test targets, Bundle.module refers to the test bundle, not LuaSwift's bundle,
    /// so we use the source path approach for testing. The production pattern is
    /// documented in Sandboxing.md.
    func testBundleModuleResourceLoading() throws {
        // In test context, we use source path since Bundle.module isn't available
        // for the LuaSwift module from the test target. The documentation in
        // Sandboxing.md shows the Bundle.module pattern for production use.
        guard let modulesPath = getLuaModulesPath() else {
            XCTFail("Could not find LuaModules directory")
            return
        }

        // Create engine with the discovered path - this is the same pattern
        // as using Bundle.module.resourcePath + "/LuaModules" in production
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: modulesPath,
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        // Verify compat module loads and works
        let compatVersion = try engine.evaluate("""
            local compat = require("compat")
            return compat.version
        """)
        XCTAssertNotNil(compatVersion.stringValue, "compat module should load and return version")

        // Verify serialize module loads and works
        let encoded = try engine.evaluate("""
            local serialize = require("serialize")
            return serialize.encode({test = true})
        """)
        XCTAssertTrue(
            encoded.stringValue?.contains("test") == true,
            "serialize module should load and encode tables"
        )
    }

    /// Test that verifies the documented pattern for loading multiple module paths works.
    func testMultipleModulePathsPattern() throws {
        guard let modulesPath = getLuaModulesPath() else {
            XCTFail("Could not find LuaModules directory")
            return
        }

        // Create engine and add custom path via package.path manipulation
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: modulesPath,
            memoryLimit: 0
        )
        let engine = try LuaEngine(configuration: config)

        // Verify that package.path includes our modules path
        let pathResult = try engine.evaluate("return package.path")
        XCTAssertTrue(
            pathResult.stringValue?.contains(modulesPath) == true,
            "package.path should include configured modulesPath"
        )

        // Add a secondary path (simulating multiple module directories)
        try engine.run("""
            package.path = package.path .. ";/additional/path/?.lua"
        """)

        let updatedPath = try engine.evaluate("return package.path")
        XCTAssertTrue(
            updatedPath.stringValue?.contains("/additional/path") == true,
            "Should be able to append additional paths to package.path"
        )
    }
}
