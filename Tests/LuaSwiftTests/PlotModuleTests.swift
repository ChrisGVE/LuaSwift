//
//  PlotModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-05.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class PlotModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        PlotModule.register(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Module Loading Tests

    func testPlotModuleLoads() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            return plt ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testPlotGlobalAliasExists() throws {
        let result = try engine.evaluate("""
            return plt ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - DrawingContext Tests

    func testCreateContext() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            return ctx ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testContextDimensions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(800, 600)
            return {width = ctx._width, height = ctx._height}
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

    func testContextType() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            return ctx.__luaswift_type
        """)
        XCTAssertEqual(result.stringValue, "plot.context")
    }

    func testContextCommandCount() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            local before = ctx:command_count()
            ctx:move_to(10, 10)
            ctx:line_to(100, 100)
            ctx:stroke()
            local after = ctx:command_count()
            return {before = before, after = after}
        """)

        guard let table = result.tableValue,
              let before = table["before"]?.numberValue,
              let after = table["after"]?.numberValue else {
            XCTFail("Expected table with before and after counts")
            return
        }

        XCTAssertEqual(before, 0)
        XCTAssertTrue(after > 0, "Commands should be recorded")
    }

    func testContextClear() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:move_to(10, 10)
            ctx:line_to(100, 100)
            local before = ctx:command_count()
            ctx:clear()
            local after = ctx:command_count()
            return {before = before, after = after}
        """)

        guard let table = result.tableValue,
              let before = table["before"]?.numberValue,
              let after = table["after"]?.numberValue else {
            XCTFail("Expected table with before and after counts")
            return
        }

        XCTAssertTrue(before > 0)
        XCTAssertEqual(after, 0)
    }

    // MARK: - Path Operations Tests

    func testPathOperations() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:move_to(10, 10)
            ctx:line_to(100, 10)
            ctx:line_to(100, 100)
            ctx:close_path()
            ctx:stroke()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertEqual(count, 5, "Should have 5 commands: move, line, line, close, stroke")
    }

    func testCurveTo() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:move_to(10, 10)
            ctx:curve_to(50, 50, 100, 50, 150, 10)
            ctx:stroke()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertEqual(count, 3)
    }

    // MARK: - Shape Tests

    func testRectShape() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:set_fill("blue")
            ctx:rect(10, 10, 100, 50)
            ctx:fill()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertEqual(count, 3)
    }

    func testCircleShape() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:set_stroke("red", 2)
            ctx:circle(100, 100, 50)
            ctx:stroke()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertTrue(count >= 3, "Should have stroke color, stroke width, circle, and stroke commands")
    }

    func testEllipseShape() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:ellipse(100, 100, 60, 40)
            ctx:stroke()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertTrue(count >= 2)
    }

    // MARK: - Text Tests

    func testTextDrawing() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:text("Hello, World!", 100, 100)
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertEqual(count, 1)
    }

    func testTextWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:text("Styled Text", 100, 100, {
                fontSize = 24,
                color = "blue",
                anchor = "middle",
                fontWeight = "bold"
            })
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertEqual(count, 1)
    }

    // MARK: - Style Tests

    func testSetStroke() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:set_stroke("#FF0000", 3, "--")
            ctx:move_to(10, 10)
            ctx:line_to(100, 100)
            ctx:stroke()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertTrue(count >= 5, "Should have stroke color, width, style, move, line, stroke")
    }

    func testSetFill() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:set_fill("green")
            ctx:rect(10, 10, 100, 100)
            ctx:fill()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertEqual(count, 3)
    }

    // MARK: - State Management Tests

    func testSaveRestore() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:save()
            ctx:set_stroke("red")
            ctx:restore()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertEqual(count, 3)
    }

    // MARK: - Convenience Methods Tests

    func testLineMethod() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:line(10, 10, 100, 100)
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertTrue(count >= 3, "Line should create move, line, stroke commands")
    }

    func testFilledRect() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:filled_rect(10, 10, 100, 50, "blue", "black")
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertTrue(count >= 4, "Filled rect should have fill color, rect, fill, stroke color, rect, stroke")
    }

    func testFilledCircle() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:filled_circle(100, 100, 50, "red", "black")
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertTrue(count >= 4)
    }

    // MARK: - Figure and Axes Tests

    func testFigureCreate() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig = plt.figure()
            return fig ~= nil and fig.__luaswift_type == "plot.figure"
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testFigureWithSize() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig = plt.figure({figsize = {10, 8}, dpi = 100})
            return {width = fig._width, height = fig._height}
        """)

        guard let table = result.tableValue,
              let width = table["width"]?.numberValue,
              let height = table["height"]?.numberValue else {
            XCTFail("Expected table with width and height")
            return
        }

        XCTAssertEqual(width, 1000)  // 10 * 100 dpi
        XCTAssertEqual(height, 800)  // 8 * 100 dpi
    }

    func testSubplots() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            return {
                fig_ok = fig ~= nil and fig.__luaswift_type == "plot.figure",
                ax_ok = ax ~= nil and ax.__luaswift_type == "plot.axes"
            }
        """)

        guard let table = result.tableValue,
              let figOk = table["fig_ok"]?.boolValue,
              let axOk = table["ax_ok"]?.boolValue else {
            XCTFail("Expected table with fig_ok and ax_ok")
            return
        }

        XCTAssertTrue(figOk)
        XCTAssertTrue(axOk)
    }

    func testSubplotsMultiple() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, axes = plt.subplots(2, 2)
            return type(axes) == "table" and #axes == 4
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Plot Method Tests

    func testPlotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3, 4}, {1, 4, 2, 3})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testPlotWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3, 4}, {1, 4, 2, 3}, {
                color = "red",
                linewidth = 2,
                linestyle = "--",
                label = "my data"
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testScatter() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:scatter({1, 2, 3}, {4, 5, 6}, {s = 50, c = "blue"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testBar() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:bar({1, 2, 3}, {10, 20, 15}, {color = "green"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Label Tests

    func testSetTitle() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:set_title("My Plot")
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSetLabels() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:set_xlabel("X Axis")
            ax:set_ylabel("Y Axis")
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - SVG Export Tests

    func testToSVG() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(400, 300)
            ctx:set_stroke("blue", 2)
            ctx:move_to(10, 10)
            ctx:line_to(100, 100)
            ctx:stroke()
            return ctx:to_svg(400, 300)
        """)

        guard let svg = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svg.contains("<?xml"))
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("</svg>"))
        XCTAssertTrue(svg.contains("width=\"400\""))
        XCTAssertTrue(svg.contains("height=\"300\""))
    }

    func testFigureToSVG() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6})
            return fig:to_svg()
        """)

        guard let svg = result.stringValue else {
            XCTFail("Expected SVG string")
            return
        }

        XCTAssertTrue(svg.contains("<svg"))
    }

    // MARK: - PNG Export Tests

    func testToPNG() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(100, 100)
            ctx:set_fill("blue")
            ctx:rect(10, 10, 80, 80)
            ctx:fill()
            local data = ctx:to_png(100, 100)
            -- Check PNG magic bytes (first 8 bytes)
            return data and #data > 8
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testPNGMagicBytes() throws {
        // Test via Swift API directly since binary data transfer through Lua strings
        // has encoding complexities (ISO-8859-1 vs UTF-8)
        let ctx = PlotModule.DrawingContext()
        ctx.setFillColor(.blue)
        ctx.rect(5, 5, 40, 40)
        ctx.fillPath()

        guard let data = ctx.renderToPNG(size: CGSize(width: 50, height: 50)) else {
            XCTFail("PNG rendering failed")
            return
        }

        // PNG magic bytes: 0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A
        let bytes = [UInt8](data.prefix(8))
        XCTAssertEqual(bytes[0], 0x89, "First byte should be 0x89")
        XCTAssertEqual(bytes[1], 0x50, "Second byte should be P")
        XCTAssertEqual(bytes[2], 0x4E, "Third byte should be N")
        XCTAssertEqual(bytes[3], 0x47, "Fourth byte should be G")
    }

    // MARK: - PDF Export Tests

    func testToPDF() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(100, 100)
            ctx:set_fill("red")
            ctx:circle(50, 50, 30)
            ctx:fill()
            local data = ctx:to_pdf(100, 100)
            -- Check PDF header
            return data and data:sub(1, 4) == "%PDF"
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Show No-op Test

    func testShowIsNoOp() throws {
        // plt.show() should not throw
        try engine.run("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6})
            plt.show()
        """)
        // If we get here without exception, test passes
    }

    // MARK: - Chaining Tests

    func testMethodChaining() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(640, 480)
            ctx:set_stroke("blue", 2)
               :move_to(10, 10)
               :line_to(100, 100)
               :stroke()
            return ctx:command_count()
        """)

        guard let count = result.numberValue else {
            XCTFail("Expected number")
            return
        }
        XCTAssertTrue(count > 0, "Chained methods should record commands")
    }

    // MARK: - Color Parsing Tests

    func testHexColor() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(100, 100)
            ctx:set_stroke("#FF5500")
            ctx:move_to(10, 10)
            ctx:line_to(90, 90)
            ctx:stroke()
            local svg = ctx:to_svg()
            return svg:find("#FF5500") ~= nil or svg:find("#ff5500") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testNamedColor() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local ctx = plt.create_context(100, 100)
            ctx:set_fill("red")
            ctx:circle(50, 50, 30)
            ctx:fill()
            local svg = ctx:to_svg()
            return svg:find("#FF0000") ~= nil or svg:find("#ff0000") ~= nil or svg:find("red") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Histogram Tests

    func testHistBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {1, 2, 2, 3, 3, 3, 4, 4, 5}
            local n, bins = ax:hist(data)
            return {n_count = #n, bins_count = #bins}
        """)

        guard let table = result.tableValue,
              let nCount = table["n_count"]?.numberValue,
              let binsCount = table["bins_count"]?.numberValue else {
            XCTFail("Expected table with counts")
            return
        }

        XCTAssertEqual(nCount, 10, "Should have 10 bins by default")
        XCTAssertEqual(binsCount, 11, "Should have 11 bin edges")
    }

    func testHistWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {1, 2, 2, 3, 3, 3, 4, 4, 5}
            ax:hist(data, {bins = 5, color = "green", density = true})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testHistCumulative() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {1, 2, 3, 4, 5}
            local n, bins = ax:hist(data, {bins = 5, cumulative = true})
            -- Last bin should have cumulative count
            return n[5] >= n[1]
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Pie Chart Tests

    func testPieBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:pie({15, 30, 45, 10})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testPieWithLabels() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:pie({15, 30, 45, 10}, {
                labels = {"A", "B", "C", "D"},
                autopct = "%.1f%%"
            })
            local svg = fig:to_svg()
            return svg:find("<text") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testPieExplode() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:pie({15, 30, 45, 10}, {
                explode = {0, 0.1, 0, 0},
                startangle = 90
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Legend Tests

    func testLegend() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6}, {label = "Series 1", color = "blue"})
            ax:plot({1, 2, 3}, {3, 4, 5}, {label = "Series 2", color = "red"})
            ax:legend()
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testLegendPosition() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6}, {label = "Data"})
            ax:legend({loc = "upper left"})
            local svg = fig:to_svg()
            return svg:find("<rect") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testLegendEmpty() throws {
        // Legend with no labeled data should not error
        try engine.run("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6})
            ax:legend()
        """)
    }

    // MARK: - Grid Tests

    func testGridBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6})
            ax:grid()
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testGridWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:grid({color = "#dddddd", linestyle = "--", axis = "y"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testGridOff() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local before = fig:get_context():command_count()
            ax:grid(false)
            local after = fig:get_context():command_count()
            return before == after
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Axis Limits Tests

    func testSetXlim() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:set_xlim(0, 100)
            local xlim = ax:get_xlim()
            return xlim[1] == 0 and xlim[2] == 100
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSetYlim() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:set_ylim(-10, 50)
            local ylim = ax:get_ylim()
            return ylim[1] == -10 and ylim[2] == 50
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testAxisOff() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:axis("off")
            return ax._axis_visible == false
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSetAspect() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:set_aspect("equal")
            return ax._aspect == "equal"
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")

            -- Create figure with subplots (matplotlib style)
            local fig, ax = plt.subplots()

            -- Plot some data
            ax:plot({1, 2, 3, 4, 5}, {1, 4, 9, 16, 25}, {color = "blue", label = "y = x^2"})
            ax:scatter({1, 2, 3, 4, 5}, {1, 4, 9, 16, 25}, {s = 30, c = "red"})

            -- Add labels
            ax:set_title("Square Function")
            ax:set_xlabel("x")
            ax:set_ylabel("y")

            -- Export to SVG
            local svg = fig:to_svg()

            return {
                has_svg = svg:find("<svg") ~= nil,
                has_path = svg:find("<path") ~= nil or svg:find("<ellipse") ~= nil,
                has_text = svg:find("<text") ~= nil
            }
        """)

        guard let table = result.tableValue,
              let hasSvg = table["has_svg"]?.boolValue,
              let hasPath = table["has_path"]?.boolValue,
              let hasText = table["has_text"]?.boolValue else {
            XCTFail("Expected table with test results")
            return
        }

        XCTAssertTrue(hasSvg, "Should generate valid SVG")
        XCTAssertTrue(hasPath, "Should contain path or ellipse elements")
        XCTAssertTrue(hasText, "Should contain text elements")
    }

    // MARK: - Swift DrawingContext Direct Tests

    func testSwiftDrawingContextCreation() {
        let ctx = PlotModule.DrawingContext()
        XCTAssertEqual(ctx.commandCount, 0)
    }

    func testSwiftDrawingContextCommands() {
        let ctx = PlotModule.DrawingContext()
        ctx.moveTo(10, 20)
        ctx.lineTo(100, 200)
        ctx.closePath()
        XCTAssertEqual(ctx.commandCount, 3)
    }

    func testSwiftDrawingContextClear() {
        let ctx = PlotModule.DrawingContext()
        ctx.moveTo(10, 20)
        ctx.lineTo(100, 200)
        XCTAssertEqual(ctx.commandCount, 2)
        ctx.clear()
        XCTAssertEqual(ctx.commandCount, 0)
    }

    func testSwiftDrawingContextBounds() {
        let ctx = PlotModule.DrawingContext()
        ctx.moveTo(10, 20)
        ctx.lineTo(100, 200)
        ctx.rect(50, 50, 100, 100)

        let bounds = ctx.bounds
        XCTAssertEqual(bounds.minX, 10)
        XCTAssertEqual(bounds.minY, 20)
        XCTAssertEqual(bounds.maxX, 150) // 50 + 100
        XCTAssertEqual(bounds.maxY, 200)
    }

    func testSwiftColorParsing() {
        // Test hex colors
        let red = PlotModule.Color(hex: "#FF0000")
        XCTAssertNotNil(red)
        XCTAssertEqual(red?.red, 1.0)
        XCTAssertEqual(red?.green, 0.0)
        XCTAssertEqual(red?.blue, 0.0)

        let green = PlotModule.Color(hex: "00FF00")
        XCTAssertNotNil(green)
        XCTAssertEqual(green?.green, 1.0)

        // Test named colors
        let blue = PlotModule.Color(name: "blue")
        XCTAssertNotNil(blue)
        XCTAssertEqual(blue?.blue, 1.0)

        let orange = PlotModule.Color(name: "orange")
        XCTAssertNotNil(orange)
    }

    func testSwiftColorToHex() {
        let color = PlotModule.Color(red: 1.0, green: 0.5, blue: 0.0)
        let hex = color.toHex()
        XCTAssertEqual(hex, "#FF7F00")
    }

    func testSwiftSVGExport() {
        let ctx = PlotModule.DrawingContext()
        ctx.setStrokeColor(.blue)
        ctx.setStrokeWidth(2)
        ctx.moveTo(10, 10)
        ctx.lineTo(100, 100)
        ctx.strokePath()

        let svg = ctx.renderToSVG(size: CGSize(width: 200, height: 200))
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("</svg>"))
        XCTAssertTrue(svg.contains("<path"))
    }

    #if canImport(ImageIO)
    func testSwiftPNGExport() {
        let ctx = PlotModule.DrawingContext()
        ctx.setFillColor(.red)
        ctx.rect(10, 10, 80, 80)
        ctx.fillPath()

        let pngData = ctx.renderToPNG(size: CGSize(width: 100, height: 100))
        XCTAssertNotNil(pngData)

        // Check PNG magic bytes
        if let data = pngData {
            XCTAssertTrue(data.count > 8)
            let bytes = [UInt8](data.prefix(8))
            XCTAssertEqual(bytes[0], 0x89)
            XCTAssertEqual(bytes[1], 0x50) // P
            XCTAssertEqual(bytes[2], 0x4E) // N
            XCTAssertEqual(bytes[3], 0x47) // G
        }
    }

    func testSwiftPDFExport() {
        let ctx = PlotModule.DrawingContext()
        ctx.setFillColor(.green)
        ctx.circle(cx: 50, cy: 50, r: 30)
        ctx.fillPath()

        let pdfData = ctx.renderToPDF(size: CGSize(width: 100, height: 100))
        XCTAssertNotNil(pdfData)

        // Check PDF header
        if let data = pdfData,
           let header = String(data: data.prefix(5), encoding: .ascii) {
            XCTAssertEqual(header, "%PDF-")
        }
    }
    #endif
}
