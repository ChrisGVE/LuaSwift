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

    /// Configure package.path to find the LuaModules directory
    private func configureLuaPath(engine: LuaEngine) throws {
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
            XCTFail("Could not find LuaModules directory at \(modulesPath)")
            return
        }

        let pathConfig = """
            package.path = '\(modulesPath)/?.lua;' .. package.path
        """
        try engine.run(pathConfig)
    }

    // MARK: - SVG Module Tests

    func testSVGCreate() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
            local drawing = svg.create(200, 200)
            drawing:rect(10, 20, 50, 30, {fill = 'red', stroke = 'black'})
            local svgStr = drawing:render()
            return svgStr:match('rect') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGCircle() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
            local drawing = svg.create(200, 200)
            drawing:circle(100, 100, 50, {fill = 'blue'})
            local svgStr = drawing:render()
            return svgStr:match('circle') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGText() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
            local drawing = svg.create(300, 100)
            drawing:text('Hello World', 150, 50, {font_size = 16})
            local svgStr = drawing:render()
            return svgStr:match('Hello World') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGGreekLetters() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
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

    // MARK: - Math Expression Module Tests

    func testMathEvalSimple() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            return math_expr.eval('2 + 3 * 4')
        """)

        XCTAssertEqual(result.numberValue, 14)
    }

    func testMathEvalWithVariables() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            return math_expr.eval('x^2', {x = 5})
        """)

        XCTAssertEqual(result.numberValue, 25)
    }

    func testMathEvalFunctions() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            return math_expr.eval('sin(pi/2)')
        """)

        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 0.0001)
    }

    func testMathStepByStep() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            local steps = math_expr.solve('2 + 3', {show_steps = true})
            return #steps > 1
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testMathEvalComplexExpression() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            return math_expr.eval('sqrt(16) + abs(-5) * 2')
        """)

        XCTAssertEqual(result.numberValue, 14)
    }

    func testMathEvalUnaryMinus() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            return math_expr.eval('-5 + 3')
        """)

        XCTAssertEqual(result.numberValue, -2)
    }

    func testMathEvalParentheses() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            return math_expr.eval('(2 + 3) * 4')
        """)

        XCTAssertEqual(result.numberValue, 20)
    }

    func testMathEvalConstants() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            local piValue = math_expr.eval('pi')
            return piValue
        """)

        XCTAssertEqual(result.numberValue!, 3.14159265, accuracy: 0.00001)
    }

    // MARK: - Integration Tests

    func testSVGWithMathExpression() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
            local math_expr = require('math_expr')
            local drawing = svg.create(300, 100)
            -- Evaluate an expression
            local result = math_expr.eval('3 + 4')
            -- Use result in SVG text
            local text = '3 + 4 = ' .. tostring(result)
            drawing:text(text, 150, 50)
            local svgStr = drawing:render()
            return svgStr:match('3 %+ 4 = 7') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGGreekLettersInText() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
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

    func testMathExpressionWithSolveSteps() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local math_expr = require('math_expr')
            local steps = math_expr.solve('2 * 3 + 4', {show_steps = true})
            -- Should have multiple steps
            local hasSteps = #steps > 1
            -- First step should be original expression
            local firstStep = steps[1].desc == 'Original expression'
            return hasSteps and firstStep
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSVGGroupTransform() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
            local drawing = svg.create(300, 300)
            local group = drawing:group(svg.translate(50, 50))
            group:rect(0, 0, 100, 100, {fill = 'red'})
            local svgStr = drawing:render()
            -- Check for group with transform
            return svgStr:match('<g') ~= nil and svgStr:match('transform') ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testMathExprDivisionByZeroError() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        XCTAssertThrowsError(try engine.evaluate("""
            local math_expr = require('math_expr')
            return math_expr.eval('1 / 0')
        """)) { error in
            guard case LuaError.runtimeError = error else {
                XCTFail("Expected runtime error for division by zero")
                return
            }
        }
    }

    func testSVGPolylineAndPolygon() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local svg = require('svg')
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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.version
        """)

        XCTAssertEqual(result.stringValue, "5.4")
    }

    func testCompatVersionFlags() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                lua51 = compat.lua51,
                lua52 = compat.lua52,
                lua53 = compat.lua53,
                lua54 = compat.lua54
            }
        """)

        XCTAssertEqual(result.tableValue?["lua51"]?.boolValue, false)
        XCTAssertEqual(result.tableValue?["lua52"]?.boolValue, false)
        XCTAssertEqual(result.tableValue?["lua53"]?.boolValue, false)
        XCTAssertEqual(result.tableValue?["lua54"]?.boolValue, true)
    }

    func testCompatFeatures() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                table_unpack = compat.features.table_unpack,
                utf8_library = compat.features.utf8_library,
                bitwise_ops = compat.features.bitwise_ops
            }
        """)

        XCTAssertEqual(result.tableValue?["table_unpack"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["utf8_library"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["bitwise_ops"]?.boolValue, true)
    }

    func testCompatBit32Band() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.band(0xFF, 0x0F)
        """)

        XCTAssertEqual(result.numberValue, 0x0F)
    }

    func testCompatBit32Bor() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.bor(0xF0, 0x0F)
        """)

        XCTAssertEqual(result.numberValue, 0xFF)
    }

    func testCompatBit32Bxor() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.bxor(0xFF, 0x0F)
        """)

        XCTAssertEqual(result.numberValue, 0xF0)
    }

    func testCompatBit32Bnot() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.bnot(0)
        """)

        XCTAssertEqual(result.numberValue, 0xFFFFFFFF)
    }

    func testCompatBit32Lshift() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.lshift(1, 4)
        """)

        XCTAssertEqual(result.numberValue, 16)
    }

    func testCompatBit32Rshift() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.rshift(16, 4)
        """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testCompatBit32Lrotate() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.lrotate(0x80000000, 1)
        """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testCompatBit32Rrotate() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.rrotate(1, 1)
        """)

        XCTAssertEqual(result.numberValue, 0x80000000)
    }

    func testCompatBit32Btest() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.extract(0xABCD, 4, 8)
        """)

        XCTAssertEqual(result.numberValue, 0xBC)
    }

    func testCompatBit32Replace() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return compat.bit32.replace(0xABCD, 0xFF, 4, 8)
        """)

        XCTAssertEqual(result.numberValue, 0xAFFD)
    }

    func testCompatVersionCompare() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            return {
                at_least_53 = compat.version_at_least("5.3"),
                at_least_54 = compat.version_at_least("5.4"),
                at_least_55 = compat.version_at_least("5.5")
            }
        """)

        XCTAssertEqual(result.tableValue?["at_least_53"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["at_least_54"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["at_least_55"]?.boolValue, false)
    }

    func testCompatInstall() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            compat.install()
            -- After install, bit32 should be available globally
            return bit32 ~= nil and bit32.band(0xFF, 0x0F) == 0x0F
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testCompatCheckDeprecated() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local compat = require('compat')
            local warnings = compat.check_deprecated("setfenv(1, {}) bit32.band(1,2)")
            return #warnings
        """)

        XCTAssertEqual(result.numberValue, 2)
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

    // MARK: - Top-level Alias Tests

    func testTopLevelAliasJson() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            return json.encode({a = 1})
            """)
        XCTAssertNotNil(result.stringValue)
    }

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

    func testTopLevelAliasArray() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            local a = array.array({1, 2, 3})
            return a:sum()
            """)
        XCTAssertEqual(result.numberValue, 6)
    }

    func testTopLevelAliasTypes() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)

        let result = try engine.evaluate("""
            return types.typeof(complex.new(1, 2))
            """)
        XCTAssertEqual(result.stringValue, "complex")
    }

    // MARK: - Serialize Module Tests

    func testSerializeEncodeNumber() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode(42)
        """)

        XCTAssertEqual(result.stringValue, "42")
    }

    func testSerializeEncodeString() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode("hello")
        """)

        XCTAssertEqual(result.stringValue, "\"hello\"")
    }

    func testSerializeEncodeBoolean() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode(true) .. "," .. serialize.encode(false)
        """)

        XCTAssertEqual(result.stringValue, "true,false")
    }

    func testSerializeEncodeNil() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode(nil)
        """)

        XCTAssertEqual(result.stringValue, "nil")
    }

    func testSerializeEncodeArray() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.encode({1, 2, 3})
        """)

        XCTAssertEqual(result.stringValue, "{1, 2, 3}")
    }

    func testSerializeEncodeTable() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local str = serialize.encode({name = "test"})
            return str:match("name") ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeEncodeNestedTable() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.decode("42")
        """)

        XCTAssertEqual(result.numberValue, 42)
    }

    func testSerializeDecodeString() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            return serialize.decode('"hello"')
        """)

        XCTAssertEqual(result.stringValue, "hello")
    }

    func testSerializeDecodeTable() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local t = serialize.decode('{a = 1, b = 2}')
            return t.a + t.b
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testSerializeRoundTrip() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local str = serialize.pretty({a = 1})
            return str:match("\\n") ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeCompact() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local str = serialize.compact({a = 1, b = 2})
            return str:match("\\n") == nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeSafeDecode() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local val, err = serialize.safe_decode("invalid{{{")
            return val == nil and err ~= nil
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeIsSerializable() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

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
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local huge = serialize.encode(math.huge)
            local neg_huge = serialize.encode(-math.huge)
            return huge == "math.huge" and neg_huge == "-math.huge"
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testSerializeEscapedStrings() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local serialize = require('serialize')
            local original = 'hello\\nworld\\t"quoted"'
            local encoded = serialize.encode(original)
            local decoded = serialize.decode(encoded)
            return decoded == original
        """)

        XCTAssertEqual(result.boolValue, true)
    }
}
