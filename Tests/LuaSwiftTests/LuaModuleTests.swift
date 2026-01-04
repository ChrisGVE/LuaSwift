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

    // MARK: - Tablex Module Tests

    func testTablexCopy() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local original = {a = 1, b = 2, c = 3}
            local copy = tablex.copy(original)
            -- Modify original, copy should be unaffected
            original.a = 100
            return copy.a
        """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testTablexDeepcopy() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local original = {nested = {value = 42}}
            local copy = tablex.deepcopy(original)
            -- Modify original nested table, copy should be unaffected
            original.nested.value = 100
            return copy.nested.value
        """)

        XCTAssertEqual(result.numberValue, 42)
    }

    func testTablexDeepcopyWithMetatable() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local mt = {__index = function(t, k) return "default" end}
            local original = setmetatable({a = 1}, mt)
            local copy = tablex.deepcopy(original)
            -- Check metatable was preserved
            return copy.nonexistent
        """)

        XCTAssertEqual(result.stringValue, "default")
    }

    func testTablexMerge() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t1 = {a = 1, b = 2}
            local t2 = {b = 3, c = 4}
            local merged = tablex.merge(t1, t2)
            return {a = merged.a, b = merged.b, c = merged.c}
        """)

        XCTAssertEqual(result.tableValue?["a"]?.numberValue, 1)
        XCTAssertEqual(result.tableValue?["b"]?.numberValue, 3)  // t2 overwrites
        XCTAssertEqual(result.tableValue?["c"]?.numberValue, 4)
    }

    func testTablexDeepmerge() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t1 = {nested = {a = 1, b = 2}}
            local t2 = {nested = {b = 3, c = 4}}
            local merged = tablex.deepmerge(t1, t2)
            return {
                a = merged.nested.a,
                b = merged.nested.b,
                c = merged.nested.c
            }
        """)

        XCTAssertEqual(result.tableValue?["a"]?.numberValue, 1)
        XCTAssertEqual(result.tableValue?["b"]?.numberValue, 3)  // t2 overwrites
        XCTAssertEqual(result.tableValue?["c"]?.numberValue, 4)
    }

    func testTablexMap() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, 2, 3, 4, 5}
            local doubled = tablex.map(t, function(v) return v * 2 end)
            return doubled[3]
        """)

        XCTAssertEqual(result.numberValue, 6)
    }

    func testTablexFilter() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, 2, 3, 4, 5, 6}
            local evens = tablex.filter(t, function(v) return v % 2 == 0 end)
            return #evens
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testTablexReduce() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, 2, 3, 4, 5}
            local sum = tablex.reduce(t, function(acc, v) return acc + v end, 0)
            return sum
        """)

        XCTAssertEqual(result.numberValue, 15)
    }

    func testTablexForeach() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {a = 1, b = 2, c = 3}
            local count = 0
            tablex.foreach(t, function(v, k) count = count + v end)
            return count
        """)

        XCTAssertEqual(result.numberValue, 6)
    }

    func testTablexFind() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {'apple', 'banana', 'cherry'}
            return tablex.find(t, 'banana')
        """)

        XCTAssertEqual(result.numberValue, 2)
    }

    func testTablexFindNotFound() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {'apple', 'banana', 'cherry'}
            return tablex.find(t, 'orange')
        """)

        XCTAssertTrue(result == .nil)
    }

    func testTablexContains() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, 2, 3, 4, 5}
            return tablex.contains(t, 3)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testTablexKeys() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {a = 1, b = 2, c = 3}
            local keys = tablex.keys(t)
            return #keys
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testTablexValues() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {a = 1, b = 2, c = 3}
            local values = tablex.values(t)
            local sum = 0
            for _, v in ipairs(values) do sum = sum + v end
            return sum
        """)

        XCTAssertEqual(result.numberValue, 6)
    }

    func testTablexSize() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {a = 1, b = 2, c = 3, d = 4}
            return tablex.size(t)
        """)

        XCTAssertEqual(result.numberValue, 4)
    }

    func testTablexIsempty() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local empty = {}
            local nonEmpty = {1, 2, 3}
            return tablex.isempty(empty) and not tablex.isempty(nonEmpty)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testTablexIsarray() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local array = {1, 2, 3, 4}
            local dict = {a = 1, b = 2}
            local mixed = {1, 2, a = 3}
            return tablex.isarray(array) and not tablex.isarray(dict) and not tablex.isarray(mixed)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testTablexInvert() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {a = 1, b = 2, c = 3}
            local inverted = tablex.invert(t)
            return inverted[1]
        """)

        XCTAssertEqual(result.stringValue, "a")
    }

    func testTablexFlatten() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, {2, 3}, {4, {5, 6}}}
            local flat = tablex.flatten(t)
            return #flat
        """)

        XCTAssertEqual(result.numberValue, 6)
    }

    func testTablexSlice() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, 2, 3, 4, 5, 6}
            local slice = tablex.slice(t, 2, 4)
            return {first = slice[1], last = slice[3], len = #slice}
        """)

        XCTAssertEqual(result.tableValue?["first"]?.numberValue, 2)
        XCTAssertEqual(result.tableValue?["last"]?.numberValue, 4)
        XCTAssertEqual(result.tableValue?["len"]?.numberValue, 3)
    }

    func testTablexReverse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, 2, 3, 4, 5}
            local reversed = tablex.reverse(t)
            return {first = reversed[1], last = reversed[5]}
        """)

        XCTAssertEqual(result.tableValue?["first"]?.numberValue, 5)
        XCTAssertEqual(result.tableValue?["last"]?.numberValue, 1)
    }

    func testTablexUnion() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t1 = {1, 2, 3}
            local t2 = {3, 4, 5}
            local u = tablex.union(t1, t2)
            return #u
        """)

        XCTAssertEqual(result.numberValue, 5)  // {1, 2, 3, 4, 5}
    }

    func testTablexIntersection() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t1 = {1, 2, 3, 4}
            local t2 = {3, 4, 5, 6}
            local inter = tablex.intersection(t1, t2)
            return #inter
        """)

        XCTAssertEqual(result.numberValue, 2)  // {3, 4}
    }

    func testTablexDifference() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t1 = {1, 2, 3, 4}
            local t2 = {3, 4, 5}
            local diff = tablex.difference(t1, t2)
            return #diff
        """)

        XCTAssertEqual(result.numberValue, 2)  // {1, 2}
    }

    func testTablexEquals() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t1 = {a = 1, b = 2}
            local t2 = {a = 1, b = 2}
            local t3 = {a = 1, b = 3}
            return tablex.equals(t1, t2) and not tablex.equals(t1, t3)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testTablexDeepequals() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t1 = {nested = {a = 1, b = {c = 2}}}
            local t2 = {nested = {a = 1, b = {c = 2}}}
            local t3 = {nested = {a = 1, b = {c = 3}}}
            return tablex.deepequals(t1, t2) and not tablex.deepequals(t1, t3)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testTablexCircularReference() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {value = 1}
            t.self = t  -- Circular reference
            local copy = tablex.deepcopy(t)
            -- Check that it didn't infinite loop and value was copied
            return copy.value
        """)

        XCTAssertEqual(result.numberValue, 1)
    }

    func testTablexSliceNegativeIndices() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, 2, 3, 4, 5}
            local slice = tablex.slice(t, -3, -1)
            return {first = slice[1], last = slice[3], len = #slice}
        """)

        XCTAssertEqual(result.tableValue?["first"]?.numberValue, 3)
        XCTAssertEqual(result.tableValue?["last"]?.numberValue, 5)
        XCTAssertEqual(result.tableValue?["len"]?.numberValue, 3)
    }

    func testTablexFlattenWithDepth() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local tablex = require('tablex')
            local t = {1, {2, {3, {4}}}}
            local flat1 = tablex.flatten(t, 1)
            local flat2 = tablex.flatten(t, 2)
            return {depth1 = #flat1, depth2 = #flat2}
        """)

        XCTAssertEqual(result.tableValue?["depth1"]?.numberValue, 3)  // {1, 2, {3, {4}}}
        XCTAssertEqual(result.tableValue?["depth2"]?.numberValue, 4)  // {1, 2, 3, {4}}
    }

    // MARK: - String Utilities (stringx) Module Tests

    func testStringxTrim() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return stringx.trim('  hello world  ')
        """)

        XCTAssertEqual(result.stringValue, "hello world")
    }

    func testStringxLtrimRtrim() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            local ltrimmed = stringx.ltrim('  hello  ')
            local rtrimmed = stringx.rtrim('  hello  ')
            return {ltrimmed = ltrimmed, rtrimmed = rtrimmed}
        """)

        XCTAssertEqual(result.tableValue?["ltrimmed"]?.stringValue, "hello  ")
        XCTAssertEqual(result.tableValue?["rtrimmed"]?.stringValue, "  hello")
    }

    func testStringxStrip() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return stringx.strip('--hello--', '-')
        """)

        XCTAssertEqual(result.stringValue, "hello")
    }

    func testStringxCapitalize() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return stringx.capitalize('hELLO WORLD')
        """)

        XCTAssertEqual(result.stringValue, "Hello world")
    }

    func testStringxTitle() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return stringx.title('hello world')
        """)

        XCTAssertEqual(result.stringValue, "Hello World")
    }

    func testStringxSplit() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            local parts = stringx.split('a,b,c', ',')
            return {first = parts[1], second = parts[2], third = parts[3], count = #parts}
        """)

        XCTAssertEqual(result.tableValue?["first"]?.stringValue, "a")
        XCTAssertEqual(result.tableValue?["second"]?.stringValue, "b")
        XCTAssertEqual(result.tableValue?["third"]?.stringValue, "c")
        XCTAssertEqual(result.tableValue?["count"]?.numberValue, 3)
    }

    func testStringxSplitlines() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            local lines = stringx.splitlines('line1\\nline2\\nline3')
            return {first = lines[1], count = #lines}
        """)

        XCTAssertEqual(result.tableValue?["first"]?.stringValue, "line1")
        XCTAssertEqual(result.tableValue?["count"]?.numberValue, 3)
    }

    func testStringxJoin() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return stringx.join({'a', 'b', 'c'}, '-')
        """)

        XCTAssertEqual(result.stringValue, "a-b-c")
    }

    func testStringxStartswith() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                yes = stringx.startswith('hello world', 'hello'),
                no = stringx.startswith('hello world', 'world')
            }
        """)

        XCTAssertEqual(result.tableValue?["yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["no"]?.boolValue, false)
    }

    func testStringxEndswith() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                yes = stringx.endswith('hello world', 'world'),
                no = stringx.endswith('hello world', 'hello')
            }
        """)

        XCTAssertEqual(result.tableValue?["yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["no"]?.boolValue, false)
    }

    func testStringxContains() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                yes = stringx.contains('hello world', 'lo wo'),
                no = stringx.contains('hello world', 'xyz')
            }
        """)

        XCTAssertEqual(result.tableValue?["yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["no"]?.boolValue, false)
    }

    func testStringxCount() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return stringx.count('hello hello world hello', 'hello')
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testStringxReplace() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                all = stringx.replace('aaa', 'a', 'b'),
                limited = stringx.replace('aaa', 'a', 'b', 2)
            }
        """)

        XCTAssertEqual(result.tableValue?["all"]?.stringValue, "bbb")
        XCTAssertEqual(result.tableValue?["limited"]?.stringValue, "bba")
    }

    func testStringxPadding() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                left = stringx.lpad('hi', 5, '*'),
                right = stringx.rpad('hi', 5, '*'),
                center = stringx.center('hi', 6, '*')
            }
        """)

        XCTAssertEqual(result.tableValue?["left"]?.stringValue, "***hi")
        XCTAssertEqual(result.tableValue?["right"]?.stringValue, "hi***")
        XCTAssertEqual(result.tableValue?["center"]?.stringValue, "**hi**")
    }

    func testStringxIsalpha() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                yes = stringx.isalpha('hello'),
                no = stringx.isalpha('hello123')
            }
        """)

        XCTAssertEqual(result.tableValue?["yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["no"]?.boolValue, false)
    }

    func testStringxIsdigit() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                yes = stringx.isdigit('12345'),
                no = stringx.isdigit('123abc')
            }
        """)

        XCTAssertEqual(result.tableValue?["yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["no"]?.boolValue, false)
    }

    func testStringxIsalnum() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                yes = stringx.isalnum('hello123'),
                no = stringx.isalnum('hello world')
            }
        """)

        XCTAssertEqual(result.tableValue?["yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["no"]?.boolValue, false)
    }

    func testStringxIsspace() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                yes = stringx.isspace('   \\t\\n'),
                no = stringx.isspace('  x  ')
            }
        """)

        XCTAssertEqual(result.tableValue?["yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["no"]?.boolValue, false)
    }

    func testStringxIsemptyIsblank() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                empty_yes = stringx.isempty(''),
                empty_no = stringx.isempty('   '),
                blank_yes = stringx.isblank('   '),
                blank_no = stringx.isblank('  x  ')
            }
        """)

        XCTAssertEqual(result.tableValue?["empty_yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["empty_no"]?.boolValue, false)
        XCTAssertEqual(result.tableValue?["blank_yes"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["blank_no"]?.boolValue, false)
    }

    func testStringxReverse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return stringx.reverse('hello')
        """)

        XCTAssertEqual(result.stringValue, "olleh")
    }

    func testStringxWrap() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            local wrapped = stringx.wrap('hello world this is a test', 10)
            local lines = stringx.splitlines(wrapped)
            return #lines
        """)

        XCTAssertTrue(result.numberValue! > 1)
    }

    func testStringxTruncate() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                default_suffix = stringx.truncate('hello world', 8),
                custom = stringx.truncate('hello world', 8, '~')
            }
        """)

        XCTAssertEqual(result.tableValue?["default_suffix"]?.stringValue, "hello...")
        XCTAssertEqual(result.tableValue?["custom"]?.stringValue, "hello w~")
    }

    func testStringxSlug() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return stringx.slug('Hello World! This is a Test.')
        """)

        XCTAssertEqual(result.stringValue, "hello-world-this-is-a-test")
    }

    func testStringxNilHandling() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local stringx = require('stringx')
            return {
                trim_nil = stringx.trim(nil) == nil,
                split_nil = #stringx.split(nil) == 0,
                startswith_nil = stringx.startswith(nil, 'x') == false
            }
        """)

        XCTAssertEqual(result.tableValue?["trim_nil"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["split_nil"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["startswith_nil"]?.boolValue, true)
    }

    // MARK: - UTF8x Module Tests

    func testUtf8xLen() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.len('Hello')
        """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testUtf8xLenUnicode() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- "Hello" in Japanese (Konnichiwa) - 5 characters
            return utf8x.len('こんにちは')
        """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testUtf8xSubBasic() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.sub('Hello World', 1, 5)
        """)

        XCTAssertEqual(result.stringValue, "Hello")
    }

    func testUtf8xSubUnicode() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- Extract first 2 characters from Japanese string
            return utf8x.sub('こんにちは', 1, 2)
        """)

        XCTAssertEqual(result.stringValue, "こん")
    }

    func testUtf8xSubNegativeIndex() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- Last 3 characters
            return utf8x.sub('Hello', -3, -1)
        """)

        XCTAssertEqual(result.stringValue, "llo")
    }

    func testUtf8xReverse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.reverse('Hello')
        """)

        XCTAssertEqual(result.stringValue, "olleH")
    }

    func testUtf8xReverseUnicode() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.reverse('こんにちは')
        """)

        XCTAssertEqual(result.stringValue, "はちにんこ")
    }

    func testUtf8xUpperAscii() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.upper('hello world')
        """)

        XCTAssertEqual(result.stringValue, "HELLO WORLD")
    }

    func testUtf8xLowerAscii() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.lower('HELLO WORLD')
        """)

        XCTAssertEqual(result.stringValue, "hello world")
    }

    func testUtf8xUpperAccented() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.upper('cafe')
        """)

        XCTAssertEqual(result.stringValue, "CAFE")
    }

    func testUtf8xLowerAccented() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.lower('NAIVE')
        """)

        XCTAssertEqual(result.stringValue, "naive")
    }

    func testUtf8xWidthAscii() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.width('Hello')
        """)

        XCTAssertEqual(result.numberValue, 5)
    }

    func testUtf8xWidthCJK() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- CJK characters are double-width
            return utf8x.width('日本語')
        """)

        XCTAssertEqual(result.numberValue, 6)  // 3 chars * 2 width each
    }

    func testUtf8xWidthMixed() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- Mix of ASCII (width 1) and CJK (width 2)
            return utf8x.width('Hi日本')
        """)

        XCTAssertEqual(result.numberValue, 6)  // 2 + 2 + 2
    }

    func testUtf8xIsalphaTrue() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local a = string.byte('A')
            local z = string.byte('z')
            return utf8x.isalpha(a) and utf8x.isalpha(z)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testUtf8xIsalphaFalse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local digit = string.byte('5')
            local space = string.byte(' ')
            return utf8x.isalpha(digit) or utf8x.isalpha(space)
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testUtf8xIsupperTrue() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local A = string.byte('A')
            local Z = string.byte('Z')
            return utf8x.isupper(A) and utf8x.isupper(Z)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testUtf8xIsupperFalse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local a = string.byte('a')
            return utf8x.isupper(a)
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testUtf8xIslowerTrue() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local a = string.byte('a')
            local z = string.byte('z')
            return utf8x.islower(a) and utf8x.islower(z)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testUtf8xIslowerFalse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local A = string.byte('A')
            return utf8x.islower(A)
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testUtf8xIsdigitTrue() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local zero = string.byte('0')
            local nine = string.byte('9')
            return utf8x.isdigit(zero) and utf8x.isdigit(nine)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testUtf8xIsdigitFalse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local a = string.byte('a')
            return utf8x.isdigit(a)
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testUtf8xIsspaceTrue() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local space = string.byte(' ')
            local tab = string.byte('\\t')
            local newline = string.byte('\\n')
            return utf8x.isspace(space) and utf8x.isspace(tab) and utf8x.isspace(newline)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testUtf8xIsspaceFalse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local a = string.byte('a')
            return utf8x.isspace(a)
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testUtf8xCodepoint() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.codepoint('A')
        """)

        XCTAssertEqual(result.numberValue, 65)  // ASCII 'A'
    }

    func testUtf8xChar() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.char(72, 101, 108, 108, 111)
        """)

        XCTAssertEqual(result.stringValue, "Hello")
    }

    func testUtf8xCodes() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local codepoints = {}
            for pos, cp in utf8x.codes('ABC') do
                table.insert(codepoints, cp)
            end
            return #codepoints
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    func testUtf8xOffset() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- Get byte offset of 2nd character in Japanese string
            local s = 'こんにちは'
            return utf8x.offset(s, 2)
        """)

        // Each Japanese hiragana is 3 bytes, so 2nd char starts at byte 4
        XCTAssertEqual(result.numberValue, 4)
    }

    func testUtf8xEmptyString() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return {
                len = utf8x.len(''),
                sub = utf8x.sub('', 1, 5),
                reverse = utf8x.reverse(''),
                upper = utf8x.upper(''),
                lower = utf8x.lower(''),
                width = utf8x.width('')
            }
        """)

        XCTAssertEqual(result.tableValue?["len"]?.numberValue, 0)
        XCTAssertEqual(result.tableValue?["sub"]?.stringValue, "")
        XCTAssertEqual(result.tableValue?["reverse"]?.stringValue, "")
        XCTAssertEqual(result.tableValue?["upper"]?.stringValue, "")
        XCTAssertEqual(result.tableValue?["lower"]?.stringValue, "")
        XCTAssertEqual(result.tableValue?["width"]?.numberValue, 0)
    }

    func testUtf8xSubOutOfRange() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            return utf8x.sub('Hello', 10, 20)
        """)

        XCTAssertEqual(result.stringValue, "")
    }

    func testUtf8xUpperLowerRoundTrip() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            local original = 'HeLLo WoRLd'
            local lower = utf8x.lower(original)
            local upper = utf8x.upper(lower)
            return upper
        """)

        XCTAssertEqual(result.stringValue, "HELLO WORLD")
    }

    func testUtf8xWidthKorean() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- Korean characters are also double-width
            return utf8x.width('한글')
        """)

        XCTAssertEqual(result.numberValue, 4)  // 2 chars * 2 width each
    }

    func testUtf8xIsalphaAccented() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- e with acute accent (e): U+00E9 = 233
            return utf8x.isalpha(233)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testUtf8xIsspaceNonBreaking() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local utf8x = require('utf8x')
            -- Non-breaking space: U+00A0 = 160
            return utf8x.isspace(160)
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Complex Number Module Tests

    func testComplexCreate() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(3, 4)
            return {re = z.re, im = z.im}
        """)

        XCTAssertEqual(result.tableValue?["re"]?.numberValue, 3)
        XCTAssertEqual(result.tableValue?["im"]?.numberValue, 4)
    }

    func testComplexPolar() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex.polar(5, math.pi/4)
            local re = z.re
            local im = z.im
            -- Should be approximately (3.535, 3.535)
            return math.abs(re - im) < 0.001
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testComplexParse() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z1 = complex.parse("3+4i")
            local z2 = complex.parse("3-4i")
            local z3 = complex.parse("5")
            local z4 = complex.parse("2i")
            return {
                z1_re = z1.re, z1_im = z1.im,
                z2_re = z2.re, z2_im = z2.im,
                z3_re = z3.re, z3_im = z3.im,
                z4_re = z4.re, z4_im = z4.im
            }
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["z1_re"]?.numberValue, 3)
        XCTAssertEqual(table["z1_im"]?.numberValue, 4)
        XCTAssertEqual(table["z2_re"]?.numberValue, 3)
        XCTAssertEqual(table["z2_im"]?.numberValue, -4)
        XCTAssertEqual(table["z3_re"]?.numberValue, 5)
        XCTAssertEqual(table["z3_im"]?.numberValue, 0)
        XCTAssertEqual(table["z4_re"]?.numberValue, 0)
        XCTAssertEqual(table["z4_im"]?.numberValue, 2)
    }

    func testComplexAbsArg() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(3, 4)
            return {abs = z:abs(), arg = z:arg()}
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["abs"]?.numberValue, 5)
        XCTAssertEqual(table["arg"]!.numberValue!, atan2(4, 3), accuracy: 0.0001)
    }

    func testComplexConjugate() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(3, 4)
            local conj = z:conj()
            return {re = conj.re, im = conj.im}
        """)

        XCTAssertEqual(result.tableValue?["re"]?.numberValue, 3)
        XCTAssertEqual(result.tableValue?["im"]?.numberValue, -4)
    }

    func testComplexAddition() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z1 = complex(1, 2)
            local z2 = complex(3, 4)
            local sum = z1 + z2
            return {re = sum.re, im = sum.im}
        """)

        XCTAssertEqual(result.tableValue?["re"]?.numberValue, 4)
        XCTAssertEqual(result.tableValue?["im"]?.numberValue, 6)
    }

    func testComplexSubtraction() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z1 = complex(5, 7)
            local z2 = complex(2, 3)
            local diff = z1 - z2
            return {re = diff.re, im = diff.im}
        """)

        XCTAssertEqual(result.tableValue?["re"]?.numberValue, 3)
        XCTAssertEqual(result.tableValue?["im"]?.numberValue, 4)
    }

    func testComplexMultiplication() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z1 = complex(1, 2)
            local z2 = complex(3, 4)
            -- (1+2i)(3+4i) = 3+4i+6i+8i^2 = 3+10i-8 = -5+10i
            local prod = z1 * z2
            return {re = prod.re, im = prod.im}
        """)

        XCTAssertEqual(result.tableValue?["re"]?.numberValue, -5)
        XCTAssertEqual(result.tableValue?["im"]?.numberValue, 10)
    }

    func testComplexDivision() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z1 = complex(1, 2)
            local z2 = complex(3, 4)
            local quot = z1 / z2
            -- (1+2i)/(3+4i) = (1+2i)(3-4i)/25 = (3-4i+6i-8i^2)/25 = (11+2i)/25
            return {re = quot.re, im = quot.im}
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, 11.0/25.0, accuracy: 0.0001)
        XCTAssertEqual(table["im"]!.numberValue!, 2.0/25.0, accuracy: 0.0001)
    }

    func testComplexNegation() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(3, 4)
            local neg = -z
            return {re = neg.re, im = neg.im}
        """)

        XCTAssertEqual(result.tableValue?["re"]?.numberValue, -3)
        XCTAssertEqual(result.tableValue?["im"]?.numberValue, -4)
    }

    func testComplexPower() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(0, 1)  -- i
            local z2 = z ^ 2  -- i^2 = -1
            local z4 = z ^ 4  -- i^4 = 1
            return {
                z2_re = z2.re, z2_im = z2.im,
                z4_re = z4.re, z4_im = z4.im
            }
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["z2_re"]!.numberValue!, -1, accuracy: 0.0001)
        XCTAssertEqual(table["z2_im"]!.numberValue!, 0, accuracy: 0.0001)
        XCTAssertEqual(table["z4_re"]!.numberValue!, 1, accuracy: 0.0001)
        XCTAssertEqual(table["z4_im"]!.numberValue!, 0, accuracy: 0.0001)
    }

    func testComplexSqrt() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(-1, 0)  -- -1
            local sqrt_z = complex.sqrt(z)  -- sqrt(-1) = i
            return {re = sqrt_z.re, im = sqrt_z.im}
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, 0, accuracy: 0.0001)
        XCTAssertEqual(table["im"]!.numberValue!, 1, accuracy: 0.0001)
    }

    func testComplexExp() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            -- e^(i*pi) = -1 (Euler's identity)
            local z = complex(0, math.pi)
            local exp_z = complex.exp(z)
            return {re = exp_z.re, im = exp_z.im}
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, -1, accuracy: 0.0001)
        XCTAssertEqual(table["im"]!.numberValue!, 0, accuracy: 0.0001)
    }

    func testComplexLog() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local e = math.exp(1)
            local z = complex(e, 0)
            local log_z = complex.log(z)
            return {re = log_z.re, im = log_z.im}
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, 1, accuracy: 0.0001)
        XCTAssertEqual(table["im"]!.numberValue!, 0, accuracy: 0.0001)
    }

    func testComplexTrigFunctions() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(1, 0)
            local sin_z = complex.sin(z)
            local cos_z = complex.cos(z)
            -- sin^2 + cos^2 = 1
            local sum = sin_z * sin_z + cos_z * cos_z
            return {re = sum.re, im = sum.im}
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["re"]!.numberValue!, 1, accuracy: 0.0001)
        XCTAssertEqual(table["im"]!.numberValue!, 0, accuracy: 0.0001)
    }

    func testComplexHyperbolicFunctions() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(1, 0)
            -- sinh(z) = (exp(z) - exp(-z)) / 2
            local sinh_z = complex.sinh(z)
            local expected = (math.exp(1) - math.exp(-1)) / 2
            return math.abs(sinh_z.re - expected) < 0.0001 and math.abs(sinh_z.im) < 0.0001
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testComplexTostring() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z1 = complex(3, 4)
            local z2 = complex(3, -4)
            local z3 = complex(0, 4)
            local z4 = complex(3, 0)
            return {
                s1 = tostring(z1),
                s2 = tostring(z2),
                s3 = tostring(z3),
                s4 = tostring(z4)
            }
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["s1"]?.stringValue, "3+4i")
        XCTAssertEqual(table["s2"]?.stringValue, "3-4i")
        XCTAssertEqual(table["s3"]?.stringValue, "4i")
        XCTAssertEqual(table["s4"]?.stringValue, "3")
    }

    func testComplexEquality() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z1 = complex(3, 4)
            local z2 = complex(3, 4)
            local z3 = complex(3, 5)
            return {eq = z1 == z2, neq = z1 == z3}
        """)

        XCTAssertEqual(result.tableValue?["eq"]?.boolValue, true)
        XCTAssertEqual(result.tableValue?["neq"]?.boolValue, false)
    }

    func testComplexWithRealNumber() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(3, 4)
            local sum = z + 5
            local prod = z * 2
            return {
                sum_re = sum.re, sum_im = sum.im,
                prod_re = prod.re, prod_im = prod.im
            }
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["sum_re"]?.numberValue, 8)
        XCTAssertEqual(table["sum_im"]?.numberValue, 4)
        XCTAssertEqual(table["prod_re"]?.numberValue, 6)
        XCTAssertEqual(table["prod_im"]?.numberValue, 8)
    }

    func testComplexInverseTrig() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(0.5, 0)
            local asin_z = complex.asin(z)
            local acos_z = complex.acos(z)
            -- asin(0.5) + acos(0.5) should equal pi/2
            local sum_re = asin_z.re + acos_z.re
            return math.abs(sum_re - math.pi/2) < 0.0001
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testComplexDivisionByZero() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        XCTAssertThrowsError(try engine.evaluate("""
            local complex = require('complex')
            local z1 = complex(1, 2)
            local z2 = complex(0, 0)
            return z1 / z2
        """)) { error in
            guard case LuaError.runtimeError = error else {
                XCTFail("Expected runtime error for division by zero")
                return
            }
        }
    }

    func testComplexPolarConversion() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(3, 4)
            local r, theta = z:polar()
            return {r = r, theta = theta}
        """)

        let table = result.tableValue!
        XCTAssertEqual(table["r"]?.numberValue, 5)
        XCTAssertEqual(table["theta"]!.numberValue!, atan2(4, 3), accuracy: 0.0001)
    }

    func testComplexTan() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(1, 0)
            local tan_z = complex.tan(z)
            local sin_z = complex.sin(z)
            local cos_z = complex.cos(z)
            local expected = sin_z / cos_z
            -- tan should equal sin/cos
            return math.abs(tan_z.re - expected.re) < 0.0001 and math.abs(tan_z.im - expected.im) < 0.0001
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testComplexTanh() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(1, 0)
            local tanh_z = complex.tanh(z)
            local sinh_z = complex.sinh(z)
            local cosh_z = complex.cosh(z)
            local expected = sinh_z / cosh_z
            -- tanh should equal sinh/cosh
            return math.abs(tanh_z.re - expected.re) < 0.0001 and math.abs(tanh_z.im - expected.im) < 0.0001
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testComplexAtan() throws {
        let engine = try LuaEngine()
        try configureLuaPath(engine: engine)

        let result = try engine.evaluate("""
            local complex = require('complex')
            local z = complex(0.5, 0)
            local atan_z = complex.atan(z)
            -- atan of a real number should give a real result close to math.atan
            return math.abs(atan_z.re - math.atan(0.5)) < 0.0001 and math.abs(atan_z.im) < 0.0001
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
