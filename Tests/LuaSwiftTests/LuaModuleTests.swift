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
}
