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
}
