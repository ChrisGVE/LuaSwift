//
//  SVGModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-04.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class SVGModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        SVGModule.register(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Basic Creation Tests

    func testSVGCreate() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(800, 600)
            return {width = drawing.width, height = drawing.height}
        """)

        guard let table = result.tableValue,
              let width = table["width"]?.numberValue,
              let height = table["height"]?.numberValue else {
            XCTFail("Expected table with width and height")
            return
        }

        XCTAssertEqual(width, 800)
        XCTAssertEqual(height, 600)
    }

    func testSVGCreateWithOptions() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(400, 300, {background = "#ffffff", viewBox = "0 0 800 600"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("viewBox=\"0 0 800 600\""))
        XCTAssertTrue(svgString.contains("fill=\"#ffffff\""))
    }

    func testSVGTypeMetadata() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(100, 100)
            return drawing.__luaswift_type
        """)

        XCTAssertEqual(result.stringValue, "svg.drawing")
    }

    func testSVGToString() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(800, 600)
            drawing:rect(0, 0, 100, 100)
            return tostring(drawing)
        """)

        guard let str = result.stringValue else {
            XCTFail("Expected string")
            return
        }

        XCTAssertTrue(str.contains("svg.drawing"))
        XCTAssertTrue(str.contains("800x600"))
        XCTAssertTrue(str.contains("1 element"))
    }

    // MARK: - Shape Tests

    func testSVGRect() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:rect(10, 20, 100, 50, {fill = "blue", stroke = "black"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<rect"))
        XCTAssertTrue(svgString.contains("x=\"10\""))
        XCTAssertTrue(svgString.contains("y=\"20\""))
        XCTAssertTrue(svgString.contains("width=\"100\""))
        XCTAssertTrue(svgString.contains("height=\"50\""))
        XCTAssertTrue(svgString.contains("fill=\"blue\""))
        XCTAssertTrue(svgString.contains("stroke=\"black\""))
    }

    func testSVGCircle() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:circle(100, 100, 50, {fill = "red"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<circle"))
        XCTAssertTrue(svgString.contains("cx=\"100\""))
        XCTAssertTrue(svgString.contains("cy=\"100\""))
        XCTAssertTrue(svgString.contains("r=\"50\""))
        XCTAssertTrue(svgString.contains("fill=\"red\""))
    }

    func testSVGEllipse() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:ellipse(100, 100, 80, 40, {fill = "green"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<ellipse"))
        XCTAssertTrue(svgString.contains("cx=\"100\""))
        XCTAssertTrue(svgString.contains("cy=\"100\""))
        XCTAssertTrue(svgString.contains("rx=\"80\""))
        XCTAssertTrue(svgString.contains("ry=\"40\""))
    }

    func testSVGLine() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:line(0, 0, 100, 100, {stroke = "black", ["stroke-width"] = 2})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<line"))
        XCTAssertTrue(svgString.contains("x1=\"0\""))
        XCTAssertTrue(svgString.contains("y1=\"0\""))
        XCTAssertTrue(svgString.contains("x2=\"100\""))
        XCTAssertTrue(svgString.contains("y2=\"100\""))
    }

    func testSVGLineDefaultStroke() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:line(0, 0, 100, 100)
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("stroke=\"black\""))
    }

    func testSVGPolyline() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:polyline({{0, 0}, {50, 50}, {100, 0}}, {stroke = "blue"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<polyline"))
        XCTAssertTrue(svgString.contains("points=\"0,0 50,50 100,0\""))
    }

    func testSVGPolygon() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:polygon({{50, 0}, {100, 100}, {0, 100}}, {fill = "yellow"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<polygon"))
        XCTAssertTrue(svgString.contains("points=\"50,0 100,100 0,100\""))
        XCTAssertTrue(svgString.contains("fill=\"yellow\""))
    }

    func testSVGPath() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:path("M 0 0 L 100 100 Z", {stroke = "black", fill = "none"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<path"))
        XCTAssertTrue(svgString.contains("d=\"M 0 0 L 100 100 Z\""))
    }

    func testSVGText() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:text("Hello, SVG!", 50, 100, {["font-size"] = 16})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<text"))
        XCTAssertTrue(svgString.contains("x=\"50\""))
        XCTAssertTrue(svgString.contains("y=\"100\""))
        XCTAssertTrue(svgString.contains(">Hello, SVG!</text>"))
    }

    func testSVGTextWithGreekLetters() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:text(svg.greek.theta .. " = 30" .. svg.greek.degree, 50, 100, {["font-size"] = 16})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("θ"))
        XCTAssertTrue(svgString.contains("°"))
    }

    // MARK: - Greek Letter Tests

    func testGreekLetterTable() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            return {
                alpha = svg.greek.alpha,
                theta = svg.greek.theta,
                pi = svg.greek.pi,
                Omega = svg.greek.Omega,
                infinity = svg.greek.infinity
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["alpha"]?.stringValue, "α")
        XCTAssertEqual(table["theta"]?.stringValue, "θ")
        XCTAssertEqual(table["pi"]?.stringValue, "π")
        XCTAssertEqual(table["Omega"]?.stringValue, "Ω")
        XCTAssertEqual(table["infinity"]?.stringValue, "∞")
    }

    // MARK: - Chaining Tests

    func testMethodChaining() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:rect(0, 0, 50, 50)
                   :circle(100, 100, 25)
                   :line(0, 0, 200, 200)
            return drawing:count()
        """)

        XCTAssertEqual(result.numberValue, 3)
    }

    // MARK: - Element Count Tests

    func testElementCount() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            local count1 = drawing:count()
            drawing:rect(0, 0, 50, 50)
            local count2 = drawing:count()
            drawing:circle(100, 100, 25)
            local count3 = drawing:count()
            return {count1, count2, count3}
        """)

        guard let arr = result.arrayValue,
              arr.count == 3 else {
            XCTFail("Expected array of 3 counts")
            return
        }

        XCTAssertEqual(arr[0].numberValue, 0)
        XCTAssertEqual(arr[1].numberValue, 1)
        XCTAssertEqual(arr[2].numberValue, 2)
    }

    // MARK: - Clear Tests

    func testClear() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:rect(0, 0, 50, 50)
            drawing:circle(100, 100, 25)
            local countBefore = drawing:count()
            drawing:clear()
            local countAfter = drawing:count()
            return {before = countBefore, after = countAfter}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["before"]?.numberValue, 2)
        XCTAssertEqual(table["after"]?.numberValue, 0)
    }

    // MARK: - Render Tests

    func testRenderProducesValidSVG() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(400, 300)
            drawing:rect(10, 10, 100, 50, {fill = "blue"})
            drawing:circle(200, 150, 40, {fill = "red"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        // Check SVG structure (includes XML declaration like svg.lua)
        XCTAssertTrue(svgString.hasPrefix("<?xml"))
        XCTAssertTrue(svgString.hasSuffix("</svg>"))
        XCTAssertTrue(svgString.contains("<svg"))
        XCTAssertTrue(svgString.contains("xmlns=\"http://www.w3.org/2000/svg\""))
        XCTAssertTrue(svgString.contains("width=\"400\""))
        XCTAssertTrue(svgString.contains("height=\"300\""))
    }

    // MARK: - XML Escape Tests

    func testXMLEscaping() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:text("A < B & C > D", 50, 100, {})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("&lt;"))
        XCTAssertTrue(svgString.contains("&amp;"))
        XCTAssertTrue(svgString.contains("&gt;"))
    }

    // MARK: - Module Availability Tests

    func testRequireSVG() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            return svg ~= nil and type(svg.create) == "function"
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testTopLevelAlias() throws {
        let result = try engine.evaluate("""
            return svg_module ~= nil and type(svg_module.create) == "function"
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Multiple Drawing Tests

    func testMultipleDrawings() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local d1 = svg.create(100, 100)
            local d2 = svg.create(200, 200)
            d1:rect(0, 0, 50, 50)
            d2:circle(100, 100, 50)
            d2:circle(50, 50, 25)
            return {count1 = d1:count(), count2 = d2:count()}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["count1"]?.numberValue, 1)
        XCTAssertEqual(table["count2"]?.numberValue, 2)
    }

    // MARK: - Points Format Tests

    func testPolylineWithXYPoints() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:polyline({{x = 0, y = 0}, {x = 50, y = 50}, {x = 100, y = 0}})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("points=\"0,0 50,50 100,0\""))
    }

    // MARK: - Transform Helper Tests

    func testTranslateHelper() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            return {
                full = svg.translate(50, 100),
                xOnly = svg.translate(25)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["full"]?.stringValue, "translate(50,100)")
        XCTAssertEqual(table["xOnly"]?.stringValue, "translate(25,0)")
    }

    func testRotateHelper() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            return {
                simple = svg.rotate(45),
                withCenter = svg.rotate(90, 100, 100)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["simple"]?.stringValue, "rotate(45)")
        XCTAssertEqual(table["withCenter"]?.stringValue, "rotate(90,100,100)")
    }

    func testScaleHelper() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            return {
                uniform = svg.scale(2),
                nonUniform = svg.scale(2, 3)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["uniform"]?.stringValue, "scale(2,2)")
        XCTAssertEqual(table["nonUniform"]?.stringValue, "scale(2,3)")
    }

    func testGroupWithTransform() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            local g = drawing:group(svg.translate(50, 50))
            g:rect(0, 0, 50, 50, {fill = "red"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<g"))
        XCTAssertTrue(svgString.contains("transform=\"translate(50,50)\""))
    }

    func testCombinedTransforms() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local t1 = svg.translate(100, 100)
            local t2 = svg.rotate(45)
            local t3 = svg.scale(0.5)
            return t1 .. " " .. t2 .. " " .. t3
        """)

        XCTAssertEqual(result.stringValue, "translate(100,100) rotate(45) scale(0.5,0.5)")
    }

    func testGroupReturnsGroupObject() throws {
        // Groups should return a group object (not self) that has its own elements
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            local g = drawing:group(svg.translate(50, 50))
            -- Group should be different from drawing
            local isDifferent = g ~= drawing
            -- Group should have its own elements array
            g:rect(0, 0, 20, 20)
            -- Drawing should have 1 element (the group), group should have 1 element (the rect)
            return {isDifferent = isDifferent, drawingCount = drawing:count(), groupHasRect = #g.elements == 1}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["isDifferent"]?.boolValue, true, "Group should be different object from drawing")
        XCTAssertEqual(table["drawingCount"]?.numberValue, 1, "Drawing should have 1 element (the group)")
        XCTAssertEqual(table["groupHasRect"]?.boolValue, true, "Group should have rect in its elements")
    }

    func testNestedGroups() throws {
        // Test nested group rendering
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            local g1 = drawing:group(svg.translate(10, 10))
            g1:rect(0, 0, 50, 50, {fill = "red"})
            local g2 = drawing:group(svg.translate(100, 100))
            g2:circle(0, 0, 25, {fill = "blue"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        // Both groups should be in the output
        XCTAssertTrue(svgString.contains("<g transform=\"translate(10,10)\">"))
        XCTAssertTrue(svgString.contains("<g transform=\"translate(100,100)\">"))
        XCTAssertTrue(svgString.contains("<rect"))
        XCTAssertTrue(svgString.contains("<circle"))
    }

    func testGroupWithStyle() throws {
        // Test group with both transform and style
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            local g = drawing:group(svg.rotate(45), {fill = "green", opacity = "0.5"})
            g:rect(0, 0, 50, 50)
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("transform=\"rotate(45)\""))
        XCTAssertTrue(svgString.contains("fill=\"green\""))
        XCTAssertTrue(svgString.contains("opacity=\"0.5\""))
    }

    // MARK: - Plot Function Tests

    func testLinePlot() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:linePlot({{0, 100}, {50, 50}, {100, 75}, {150, 25}})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("<polyline"))
        XCTAssertTrue(svgString.contains("fill=\"none\""))
        XCTAssertTrue(svgString.contains("stroke=\"black\""))
    }

    func testLinePlotWithStyle() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:linePlot({{0, 0}, {100, 100}}, {stroke = "red", ["stroke-width"] = 2})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("stroke=\"red\""))
    }

    func testScatterPlot() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:scatterPlot({{50, 50}, {100, 100}, {150, 75}})
            return {count = drawing:count(), svg = drawing:render()}
        """)

        guard let table = result.tableValue,
              let count = table["count"]?.numberValue,
              let svgString = table["svg"]?.stringValue else {
            XCTFail("Expected table with count and svg")
            return
        }

        XCTAssertEqual(count, 3) // 3 circles
        XCTAssertTrue(svgString.contains("<circle"))
        XCTAssertTrue(svgString.contains("r=\"3\"")) // default radius
    }

    func testScatterPlotWithRadius() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:scatterPlot({{50, 50}, {100, 100}}, 10, {fill = "blue"})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("r=\"10\""))
        XCTAssertTrue(svgString.contains("fill=\"blue\""))
    }

    func testBarChart() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:barChart({{10, 50}, {40, 80}, {70, 30}}, {fill = "steelblue"})
            return {count = drawing:count(), svg = drawing:render()}
        """)

        guard let table = result.tableValue,
              let count = table["count"]?.numberValue,
              let svgString = table["svg"]?.stringValue else {
            XCTFail("Expected table with count and svg")
            return
        }

        XCTAssertEqual(count, 3) // 3 rectangles
        XCTAssertTrue(svgString.contains("<rect"))
        XCTAssertTrue(svgString.contains("fill=\"steelblue\""))
    }

    func testBarChartWithCustomWidth() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(200, 200)
            drawing:barChart({{x = 10, y = 100, width = 30}})
            return drawing:render()
        """)

        guard let svgString = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svgString.contains("width=\"30\""))
        XCTAssertTrue(svgString.contains("height=\"100\""))
    }

    func testPlotChaining() throws {
        let result = try engine.evaluate("""
            local svg = require("luaswift.svg")
            local drawing = svg.create(300, 200)
            drawing:linePlot({{0, 100}, {100, 50}})
                   :scatterPlot({{50, 75}}, 5)
                   :barChart({{150, 80}})
            return drawing:count()
        """)

        XCTAssertEqual(result.numberValue, 3) // 1 polyline + 1 circle + 1 rect
    }
}
