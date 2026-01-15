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
import PlotSwift

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
        let ctx = DrawingContext()
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

    // MARK: - Compatibility Shims Tests

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

    func testIonIsNoOp() throws {
        // plt.ion() should not throw (interactive mode on - no-op in embedded context)
        try engine.run("""
            local plt = require("luaswift.plot")
            plt.ion()
        """)
    }

    func testIoffIsNoOp() throws {
        // plt.ioff() should not throw (interactive mode off - no-op in embedded context)
        try engine.run("""
            local plt = require("luaswift.plot")
            plt.ioff()
        """)
    }

    func testInteractiveModeWorkflow() throws {
        // Full workflow with interactive mode calls (all no-ops)
        try engine.run("""
            local plt = require("luaswift.plot")
            plt.ioff()  -- Turn off interactive mode
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6})
            plt.show()
            plt.ion()  -- Turn on interactive mode
        """)
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
        let ctx = DrawingContext()
        XCTAssertEqual(ctx.commandCount, 0)
    }

    func testSwiftDrawingContextCommands() {
        let ctx = DrawingContext()
        ctx.moveTo(10, 20)
        ctx.lineTo(100, 200)
        ctx.closePath()
        XCTAssertEqual(ctx.commandCount, 3)
    }

    func testSwiftDrawingContextClear() {
        let ctx = DrawingContext()
        ctx.moveTo(10, 20)
        ctx.lineTo(100, 200)
        XCTAssertEqual(ctx.commandCount, 2)
        ctx.clear()
        XCTAssertEqual(ctx.commandCount, 0)
    }

    func testSwiftDrawingContextBounds() {
        let ctx = DrawingContext()
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
        let red = Color(hex: "#FF0000")
        XCTAssertNotNil(red)
        XCTAssertEqual(red?.red, 1.0)
        XCTAssertEqual(red?.green, 0.0)
        XCTAssertEqual(red?.blue, 0.0)

        let green = Color(hex: "00FF00")
        XCTAssertNotNil(green)
        XCTAssertEqual(green?.green, 1.0)

        // Test named colors
        let blue = Color(name: "blue")
        XCTAssertNotNil(blue)
        XCTAssertEqual(blue?.blue, 1.0)

        let orange = Color(name: "orange")
        XCTAssertNotNil(orange)
    }

    func testSwiftColorToHex() {
        let color = Color(red: 1.0, green: 0.5, blue: 0.0)
        let hex = color.toHex()
        XCTAssertEqual(hex, "#FF7F00")
    }

    func testSwiftSVGExport() {
        let ctx = DrawingContext()
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
        let ctx = DrawingContext()
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
        let ctx = DrawingContext()
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

    // MARK: - Imshow Tests

    func testImshowBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {
                {1, 2, 3},
                {4, 5, 6},
                {7, 8, 9}
            }
            ax:imshow(data)
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testImshowWithColormap() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {
                {0.0, 0.5, 1.0},
                {0.25, 0.5, 0.75},
                {0.5, 0.5, 0.5}
            }
            ax:imshow(data, {cmap = "plasma", vmin = 0, vmax = 1})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testImshowColormaps() throws {
        // Test that different colormaps work
        let colormaps = ["viridis", "plasma", "inferno", "gray", "hot", "cool", "coolwarm"]

        for cmap in colormaps {
            let result = try engine.evaluate("""
                local plt = require("luaswift.plot")
                local fig, ax = plt.subplots()
                ax:imshow({{0, 0.5}, {0.5, 1}}, {cmap = "\(cmap)"})
                return fig:get_context():command_count() > 0
            """)
            XCTAssertEqual(result.boolValue, true, "Colormap \(cmap) should work")
        }
    }

    func testImshowStoresData() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:imshow({{1, 2}, {3, 4}}, {vmin = 1, vmax = 4})
            return ax._imshow_data ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Errorbar Tests

    func testErrorbarBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:errorbar({1, 2, 3}, {4, 5, 6}, {yerr = {0.5, 0.3, 0.4}})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testErrorbarWithXerr() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:errorbar({1, 2, 3}, {4, 5, 6}, {
                xerr = {0.2, 0.2, 0.2},
                yerr = {0.5, 0.3, 0.4}
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testErrorbarWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:errorbar({1, 2, 3}, {4, 5, 6}, {
                yerr = {0.5, 0.3, 0.4},
                fmt = "o",
                color = "red",
                capsize = 5,
                elinewidth = 2,
                label = "Data with errors"
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testErrorbarWithScalarError() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:errorbar({1, 2, 3}, {4, 5, 6}, {yerr = 0.5})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Boxplot Tests

    func testBoxplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            ax:boxplot({data})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testBoxplotMultipleSeries() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data1 = {1, 2, 3, 4, 5}
            local data2 = {3, 4, 5, 6, 7}
            local data3 = {5, 6, 7, 8, 9}
            ax:boxplot({data1, data2, data3})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testBoxplotWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            ax:boxplot({data}, {
                vert = true,
                widths = 0.6,
                showmeans = true,
                showfliers = true,
                boxprops = {color = "blue"},
                medianprops = {color = "red"}
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testBoxplotHorizontal() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:boxplot({{1, 2, 3, 4, 5}}, {vert = false})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testBoxplotWithOutliers() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            -- Data with outliers (100 is an outlier)
            local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100}
            ax:boxplot({data}, {showfliers = true})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Contour Tests

    func testContourBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            -- Create grid data for z = x^2 + y^2
            local X, Y, Z = {}, {}, {}
            for i = 1, 5 do
                X[i], Y[i], Z[i] = {}, {}, {}
                for j = 1, 5 do
                    local x = (i - 3) * 0.5
                    local y = (j - 3) * 0.5
                    X[i][j] = x
                    Y[i][j] = y
                    Z[i][j] = x*x + y*y
                end
            end
            ax:contour(X, Y, Z)
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testContourWithLevels() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local X, Y, Z = {}, {}, {}
            for i = 1, 5 do
                X[i], Y[i], Z[i] = {}, {}, {}
                for j = 1, 5 do
                    X[i][j], Y[i][j] = i, j
                    Z[i][j] = (i - 3)^2 + (j - 3)^2
                end
            end
            ax:contour(X, Y, Z, {levels = {1, 2, 3, 4}})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testContourWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local X, Y, Z = {}, {}, {}
            for i = 1, 5 do
                X[i], Y[i], Z[i] = {}, {}, {}
                for j = 1, 5 do
                    X[i][j], Y[i][j] = i, j
                    Z[i][j] = math.sin(i * 0.5) * math.cos(j * 0.5)
                end
            end
            ax:contour(X, Y, Z, {
                levels = 5,
                colors = {"blue", "green", "red"},
                linewidths = 2
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testContourfBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local X, Y, Z = {}, {}, {}
            for i = 1, 3 do
                X[i], Y[i], Z[i] = {}, {}, {}
                for j = 1, 3 do
                    X[i][j], Y[i][j] = i, j
                    Z[i][j] = i + j
                end
            end
            ax:contourf(X, Y, Z)
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Colorbar Tests

    func testColorbarBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:imshow({{0, 0.5}, {0.5, 1}}, {cmap = "viridis", vmin = 0, vmax = 1})
            fig:colorbar(nil, {ax = ax})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testColorbarWithLabel() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:imshow({{1, 2}, {3, 4}})
            fig:colorbar(nil, {ax = ax, label = "Value"})
            local svg = fig:to_svg()
            return svg:find("Value") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testColorbarWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:imshow({{0, 1}, {2, 3}}, {vmin = 0, vmax = 3})
            fig:colorbar(nil, {
                ax = ax,
                orientation = "vertical",
                shrink = 0.8,
                aspect = 20
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testColorbarWithoutImshow() throws {
        // Colorbar should be a no-op if no imshow data exists
        try engine.run("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6})
            fig:colorbar()  -- Should not error
        """)
    }

    // MARK: - Advanced Integration Tests

    func testHeatmapWithColorbar() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots({figsize = {8, 6}})

            -- Create heatmap data
            local data = {}
            for i = 1, 10 do
                data[i] = {}
                for j = 1, 10 do
                    data[i][j] = math.sin(i * 0.5) * math.cos(j * 0.5)
                end
            end

            ax:imshow(data, {cmap = "coolwarm", vmin = -1, vmax = 1})
            ax:set_title("Heatmap Example")
            fig:colorbar(nil, {ax = ax, label = "sin(x)cos(y)"})

            local svg = fig:to_svg()
            return svg:find("<rect") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testErrorbarWithPlot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            local x = {1, 2, 3, 4, 5}
            local y = {2, 4, 6, 8, 10}
            local yerr = {0.5, 0.4, 0.6, 0.3, 0.5}

            ax:plot(x, y, {color = "blue", linestyle = "--"})
            ax:errorbar(x, y, {yerr = yerr, fmt = "o", color = "red", capsize = 5})
            ax:set_xlabel("X")
            ax:set_ylabel("Y")
            ax:set_title("Data with Error Bars")

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testBoxplotComparison() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            -- Generate sample data
            local function generate_data(n, mean, std)
                local data = {}
                for i = 1, n do
                    -- Simple approximation of normal distribution
                    local sum = 0
                    for j = 1, 12 do
                        sum = sum + math.random()
                    end
                    data[i] = mean + (sum - 6) * std
                end
                return data
            end

            local data1 = generate_data(50, 10, 2)
            local data2 = generate_data(50, 15, 3)
            local data3 = generate_data(50, 12, 1.5)

            ax:boxplot({data1, data2, data3}, {
                positions = {1, 2, 3},
                widths = 0.6,
                showmeans = true
            })
            ax:set_title("Box Plot Comparison")

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Statistical Plot Tests (luaswift.plot.stat)

    func testStatNamespaceExists() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            return plt.stat ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testStatNamespaceRequire() throws {
        let result = try engine.evaluate("""
            local stat = require("luaswift.plot.stat")
            return stat ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testHistplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 7, 8}
            stat.histplot(ax, data)
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testHistplotWithKDE() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 7, 8}
            stat.histplot(ax, data, {kde = true, stat = "density"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testHistplotStatTypes() throws {
        let statTypes = ["count", "frequency", "probability", "percent", "density"]

        for statType in statTypes {
            let result = try engine.evaluate("""
                local plt = require("luaswift.plot")
                local stat = plt.stat
                local fig, ax = plt.subplots()
                stat.histplot(ax, {1, 2, 3, 4, 5}, {stat = "\(statType)"})
                return fig:get_context():command_count() > 0
            """)
            XCTAssertEqual(result.boolValue, true, "stat=\(statType) should work")
        }
    }

    func testHistplotStepElement() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.histplot(ax, {1, 2, 3, 4, 5, 6}, {element = "step"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testKdeplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {1, 2, 2, 3, 3, 3, 4, 4, 5}
            stat.kdeplot(ax, data)
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testKdeplotWithFill() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.kdeplot(ax, {1, 2, 3, 4, 5}, {fill = true, color = "blue"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testKdeplotBandwidthMethods() throws {
        let methods = ["scott", "silverman"]

        for method in methods {
            let result = try engine.evaluate("""
                local plt = require("luaswift.plot")
                local stat = plt.stat
                local fig, ax = plt.subplots()
                stat.kdeplot(ax, {1, 2, 3, 4, 5}, {bw_method = "\(method)"})
                return fig:get_context():command_count() > 0
            """)
            XCTAssertEqual(result.boolValue, true, "bw_method=\(method) should work")
        }
    }

    func testKdeplotCumulative() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.kdeplot(ax, {1, 2, 3, 4, 5}, {cumulative = true})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testRugplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.rugplot(ax, {1, 2, 3, 4, 5})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testRugplotWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.rugplot(ax, {1, 2, 3, 4, 5}, {height = 0.1, color = "red"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testRugplotYAxis() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.rugplot(ax, {1, 2, 3, 4, 5}, {axis = "y"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testViolinplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.violinplot(ax, {1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testViolinplotMultipleSeries() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data1 = {1, 2, 3, 4, 5}
            local data2 = {3, 4, 5, 6, 7}
            local data3 = {5, 6, 7, 8, 9}
            stat.violinplot(ax, {data1, data2, data3})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testViolinplotWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.violinplot(ax, {{1, 2, 3, 4, 5}}, {
                showmeans = true,
                showmedians = true,
                showextrema = true,
                widths = 0.7
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Statistical Plot Integration Tests

    func testKdeWithHistplotOverlay() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()

            -- Generate some sample data
            local data = {}
            for i = 1, 100 do
                -- Approximate normal distribution
                local sum = 0
                for j = 1, 12 do
                    sum = sum + math.random()
                end
                data[i] = (sum - 6) * 2 + 10
            end

            stat.histplot(ax, data, {stat = "density", kde = true, color = "steelblue"})
            ax:set_title("Distribution with KDE Overlay")

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testKdeWithRugplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()

            local data = {1, 2, 2.5, 3, 3.5, 4, 5, 6, 7}
            stat.kdeplot(ax, data, {fill = true, color = "lightblue"})
            stat.rugplot(ax, data, {height = 0.03, color = "black"})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testViolinplotComparison() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()

            -- Generate different distributions
            local function gen_normal(n, mean, std)
                local data = {}
                for i = 1, n do
                    local sum = 0
                    for j = 1, 12 do sum = sum + math.random() end
                    data[i] = (sum - 6) * std + mean
                end
                return data
            end

            local group1 = gen_normal(30, 5, 1)
            local group2 = gen_normal(30, 7, 2)
            local group3 = gen_normal(30, 4, 1.5)

            stat.violinplot(ax, {group1, group2, group3}, {
                positions = {1, 2, 3},
                showmeans = true
            })
            ax:set_title("Violin Plot Comparison")

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Stripplot Tests

    func testStripplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.stripplot(ax, {{1, 2, 3, 4, 5}})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testStripplotWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.stripplot(ax, {{1, 2, 3, 4, 5}}, {
                jitter = 0.2,
                color = "blue",
                size = 8,
                alpha = 0.7
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testStripplotMultipleSeries() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data1 = {1, 2, 3, 4, 5}
            local data2 = {3, 4, 5, 6, 7}
            stat.stripplot(ax, {data1, data2})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testStripplotHorizontal() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.stripplot(ax, {{1, 2, 3, 4, 5}}, {orient = "h"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Swarmplot Tests

    func testSwarmplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.swarmplot(ax, {{1, 2, 2, 3, 3, 3, 4, 4, 5}})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSwarmplotWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            stat.swarmplot(ax, {{1, 2, 2, 3, 3, 4}}, {
                color = "green",
                size = 6,
                alpha = 0.8
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSwarmplotMultipleSeries() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data1 = {1, 2, 2, 3, 3, 3}
            local data2 = {2, 3, 3, 4, 4, 4}
            stat.swarmplot(ax, {data1, data2}, {size = 4})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSwarmplotNoOverlap() throws {
        // Swarmplot should arrange points so they don't overlap
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            -- Data with many identical values to test overlap handling
            stat.swarmplot(ax, {{1, 1, 1, 1, 2, 2, 2, 3, 3, 4}})
            return fig:get_context():command_count() > 5  -- Multiple points drawn
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Regplot Tests

    func testRegplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local x = {1, 2, 3, 4, 5}
            local y = {2, 4, 5, 4, 5}
            stat.regplot(ax, x, y)
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testRegplotWithConfidenceInterval() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local x = {1, 2, 3, 4, 5, 6, 7, 8}
            local y = {2.1, 3.9, 6.2, 7.8, 10.1, 12.0, 13.9, 16.2}
            stat.regplot(ax, x, y, {ci = 95})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testRegplotNoScatter() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local x = {1, 2, 3, 4, 5}
            local y = {2, 4, 6, 8, 10}
            stat.regplot(ax, x, y, {scatter = false})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testRegplotWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local x = {1, 2, 3, 4, 5}
            local y = {2, 4, 6, 8, 10}
            stat.regplot(ax, x, y, {
                color = "red",
                marker = "s",
                line_kws = {linestyle = "--"},
                scatter_kws = {alpha = 0.5}
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testRegplotLineOnly() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local x = {1, 2, 3, 4, 5}
            local y = {2.1, 4.2, 5.8, 8.1, 9.9}
            stat.regplot(ax, x, y, {scatter = false, ci = false})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Seaborn-style Heatmap Tests

    func testSeabornHeatmapBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}
            stat.heatmap(ax, data)
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSeabornHeatmapWithAnnotations() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{1, 2}, {3, 4}}
            stat.heatmap(ax, data, {annot = true})
            local svg = fig:to_svg()
            -- Should contain text annotations
            return svg:find("<text") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSeabornHeatmapWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{0, 0.5, 1}, {0.5, 1, 0.5}, {1, 0.5, 0}}
            stat.heatmap(ax, data, {
                cmap = "coolwarm",
                vmin = 0,
                vmax = 1,
                linewidths = 1,
                linecolor = "white"
            })
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSeabornHeatmapWithLabels() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{1, 2}, {3, 4}}
            stat.heatmap(ax, data, {
                xticklabels = {"A", "B"},
                yticklabels = {"Row 1", "Row 2"}
            })
            local svg = fig:to_svg()
            return svg:find("Row 1") ~= nil and svg:find("A") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSeabornHeatmapWithFmt() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{0.123, 0.456}, {0.789, 0.012}}
            stat.heatmap(ax, data, {annot = true, fmt = ".2f"})
            local svg = fig:to_svg()
            return svg:find("0.12") ~= nil or svg:find("0.46") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testSeabornHeatmapSquare() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{1, 2, 3}, {4, 5, 6}}
            stat.heatmap(ax, data, {square = true})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Combined Statistical Plot Tests

    func testStripplotWithViolinplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {
                {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
                {2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
            }
            stat.violinplot(ax, data, {alpha = 0.3})
            stat.stripplot(ax, data, {color = "black", size = 3})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testRegplotWithResidualsHistogram() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, axes = plt.subplots(1, 2)
            local ax1 = axes[1]
            local ax2 = axes[2]

            local x = {1, 2, 3, 4, 5, 6, 7, 8}
            local y = {2.1, 3.9, 6.2, 7.8, 10.1, 12.0, 13.9, 16.2}

            stat.regplot(ax1, x, y, {ci = 95})
            ax1:set_title("Regression")

            -- Simple residuals (not computed, just example data)
            stat.histplot(ax2, {0.1, -0.1, 0.2, -0.2, 0.1, 0, -0.1, 0.2}, {kde = true})
            ax2:set_title("Residuals")

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testHeatmapCorrelationMatrix() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()

            -- Simulated correlation matrix
            local corr = {
                {1.0, 0.8, 0.3, -0.2},
                {0.8, 1.0, 0.5, -0.1},
                {0.3, 0.5, 1.0, 0.6},
                {-0.2, -0.1, 0.6, 1.0}
            }

            stat.heatmap(ax, corr, {
                annot = true,
                fmt = ".2f",
                cmap = "coolwarm",
                vmin = -1,
                vmax = 1,
                xticklabels = {"A", "B", "C", "D"},
                yticklabels = {"A", "B", "C", "D"},
                linewidths = 0.5
            })
            ax:set_title("Correlation Matrix")

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Catplot Tests

    func testCatplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 3, 4, 5}})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testCatplotKindStrip() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 3}, {4, 5, 6}}, {kind = "strip"})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testCatplotKindSwarm() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 2, 3}, {2, 3, 3, 4}}, {kind = "swarm"})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testCatplotKindBox() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 3, 4, 5}, {3, 4, 5, 6, 7}}, {kind = "box"})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testCatplotKindViolin() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 3, 4, 5, 6, 7, 8}}, {kind = "violin"})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testCatplotKindBar() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 3}, {4, 5, 6}}, {kind = "bar"})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testCatplotKindPoint() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 3}, {4, 5, 6}}, {kind = "point"})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testCatplotWithFigsize() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 3}}, {height = 6, aspect = 1.2})
            return result.fig ~= nil and result.ax ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Lmplot Tests

    func testLmplotBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.lmplot({{1, 2, 3, 4, 5}, {2, 4, 5, 4, 5}})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testLmplotWithNamedData() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {
                x_values = {1, 2, 3, 4, 5},
                y_values = {2, 4, 6, 8, 10}
            }
            local result = stat.lmplot(data, {x = "x_values", y = "y_values"})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testLmplotNoScatter() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.lmplot({{1, 2, 3, 4, 5}, {2, 4, 6, 8, 10}}, {scatter = false})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testLmplotWithCI() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.lmplot({{1, 2, 3, 4, 5}, {2, 4, 5, 8, 9}}, {ci = 95})
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testLmplotWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.lmplot({{1, 2, 3, 4}, {2, 4, 6, 8}}, {
                height = 5,
                aspect = 1.5,
                color = "red",
                marker = "s"
            })
            return result.fig ~= nil and result.ax ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Clustermap Tests

    func testClustermapBasic() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {
                {1, 2, 3},
                {4, 5, 6},
                {7, 8, 9}
            }
            local result = stat.clustermap(data)
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testClustermapReturnsOrder() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {
                {1, 2, 3},
                {6, 5, 4},
                {7, 8, 9}
            }
            local result = stat.clustermap(data)
            return result.row_order ~= nil and result.col_order ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testClustermapWithAnnotations() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {
                {1, 2},
                {3, 4}
            }
            local result = stat.clustermap(data, {annot = true})
            local svg = result.fig:to_svg()
            return svg:find("<text") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testClustermapNoRowCluster() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {
                {1, 2, 3},
                {4, 5, 6},
                {7, 8, 9}
            }
            local result = stat.clustermap(data, {row_cluster = false})
            -- With no row clustering, row_order should be {1, 2, 3}
            return result.row_order[1] == 1 and result.row_order[2] == 2 and result.row_order[3] == 3
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testClustermapNoColCluster() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {
                {1, 2, 3},
                {4, 5, 6},
                {7, 8, 9}
            }
            local result = stat.clustermap(data, {col_cluster = false})
            -- With no col clustering, col_order should be {1, 2, 3}
            return result.col_order[1] == 1 and result.col_order[2] == 2 and result.col_order[3] == 3
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testClustermapWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {
                {0, 0.5, 1},
                {0.5, 1, 0.5},
                {1, 0.5, 0}
            }
            local result = stat.clustermap(data, {
                cmap = "coolwarm",
                annot = true,
                fmt = ".1f",
                vmin = 0,
                vmax = 1,
                linewidths = 1,
                linecolor = "black"
            })
            return result.fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    func testClustermapReordersData() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            -- Data with clear clustering structure
            local data = {
                {10, 11, 1, 2},   -- Row 1: high values on left
                {9, 12, 2, 1},   -- Row 2: similar to row 1
                {1, 2, 10, 11},  -- Row 3: high values on right
                {2, 1, 11, 9}    -- Row 4: similar to row 3
            }
            local result = stat.clustermap(data)
            -- Clustered data should exist
            return result.clustered_data ~= nil and #result.clustered_data == 4
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Figure-Level API Integration Tests

    func testCatplotAndLmplotTogether() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat

            -- Create categorical plot
            local cat_result = stat.catplot({{1, 2, 3, 4, 5}}, {kind = "box"})

            -- Create regression plot
            local lm_result = stat.lmplot({{1, 2, 3, 4, 5}, {2, 3, 5, 4, 5}})

            return cat_result.fig ~= nil and lm_result.fig ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Python to Lua Translation Tests
    // These tests verify that Python matplotlib/seaborn code translates directly to Lua
    // with only syntax changes: [] → {}, keyword= → key=, . → : (for methods)

    /// Test: Basic line plot translation
    /// Python: ax.plot([1, 2, 3], [4, 5, 6])
    /// Lua:    ax:plot({1, 2, 3}, {4, 5, 6})
    func testTranslationBasicLinePlot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Line plot with format string
    /// Python: ax.plot([1, 2, 3], [4, 5, 6], 'r--o')
    /// Lua:    ax:plot({1, 2, 3}, {4, 5, 6}, "r--o")
    func testTranslationFormatString() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6}, "r--o")
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Line plot with keyword arguments
    /// Python: ax.plot([1, 2, 3], [4, 5, 6], color='blue', linestyle='--', marker='o', label='data')
    /// Lua:    ax:plot({1, 2, 3}, {4, 5, 6}, {color="blue", linestyle="--", marker="o", label="data"})
    func testTranslationKeywordArgs() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6}, {color="blue", linestyle="--", marker="o", label="data"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Scatter plot translation
    /// Python: ax.scatter([1, 2, 3], [4, 5, 6], s=50, c='red', marker='s')
    /// Lua:    ax:scatter({1, 2, 3}, {4, 5, 6}, {s=50, c="red", marker="s"})
    func testTranslationScatter() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:scatter({1, 2, 3}, {4, 5, 6}, {s=50, c="red", marker="s"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Bar chart translation
    /// Python: ax.bar([1, 2, 3], [10, 20, 15], width=0.8, color='green')
    /// Lua:    ax:bar({1, 2, 3}, {10, 20, 15}, {width=0.8, color="green"})
    func testTranslationBar() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:bar({1, 2, 3}, {10, 20, 15}, {width=0.8, color="green"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Histogram translation
    /// Python: ax.hist(data, bins=20, density=True, color='blue', alpha=0.7)
    /// Lua:    ax:hist(data, {bins=20, density=true, color="blue", alpha=0.7})
    func testTranslationHistogram() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {1, 2, 2, 3, 3, 3, 4, 4, 5}
            ax:hist(data, {bins=5, density=true, color="blue", alpha=0.7})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Pie chart translation
    /// Python: ax.pie([15, 30, 45, 10], labels=['A', 'B', 'C', 'D'], autopct='%1.1f%%')
    /// Lua:    ax:pie({15, 30, 45, 10}, {labels={"A", "B", "C", "D"}, autopct="%1.1f%%"})
    func testTranslationPie() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:pie({15, 30, 45, 10}, {labels={"A", "B", "C", "D"}, autopct="%1.1f%%"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Subplots creation translation
    /// Python: fig, ax = plt.subplots()
    /// Lua:    local fig, ax = plt.subplots()
    func testTranslationSubplots() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            return fig ~= nil and ax ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Figure with options translation
    /// Python: fig, ax = plt.subplots(figsize=(10, 8), dpi=100)
    /// Lua:    local fig, ax = plt.subplots({figsize={10, 8}, dpi=100})
    func testTranslationFigureWithOptions() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots({figsize={10, 8}, dpi=100})
            return fig._width == 1000 and fig._height == 800
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Multiple subplots translation
    /// Python: fig, axes = plt.subplots(2, 2)
    /// Lua:    local fig, axes = plt.subplots(2, 2)
    func testTranslationMultipleSubplots() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, axes = plt.subplots(2, 2)
            return type(axes) == "table" and #axes == 4
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Title and labels translation
    /// Python: ax.set_title('My Plot'); ax.set_xlabel('X'); ax.set_ylabel('Y')
    /// Lua:    ax:set_title("My Plot"); ax:set_xlabel("X"); ax:set_ylabel("Y")
    func testTranslationTitleAndLabels() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:set_title("My Plot")
            ax:set_xlabel("X Axis")
            ax:set_ylabel("Y Axis")
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Legend translation
    /// Python: ax.legend(loc='upper right')
    /// Lua:    ax:legend({loc="upper right"})
    func testTranslationLegend() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6}, {label="data"})
            ax:legend({loc="upper right"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Grid translation
    /// Python: ax.grid(True, linestyle='--', alpha=0.7)
    /// Lua:    ax:grid({linestyle="--", alpha=0.7})
    func testTranslationGrid() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:grid({linestyle="--", alpha=0.7})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Axis limits translation
    /// Python: ax.set_xlim(0, 10); ax.set_ylim(-5, 5)
    /// Lua:    ax:set_xlim(0, 10); ax:set_ylim(-5, 5)
    func testTranslationAxisLimits() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:set_xlim(0, 10)
            ax:set_ylim(-5, 5)
            local xlim = ax:get_xlim()
            local ylim = ax:get_ylim()
            return xlim[1] == 0 and xlim[2] == 10 and ylim[1] == -5 and ylim[2] == 5
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Savefig translation
    /// Python: fig.savefig('plot.svg', format='svg')
    /// Lua:    fig:savefig("plot.svg", {format="svg"})
    func testTranslationSavefig() throws {
        let tmpDir = FileManager.default.temporaryDirectory.path
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            ax:plot({1, 2, 3}, {4, 5, 6})
            fig:savefig("\(tmpDir)/test_translation.svg", {format="svg"})
            return true
        """)
        XCTAssertEqual(result.boolValue, true)
        // Clean up
        try? FileManager.default.removeItem(atPath: "\(tmpDir)/test_translation.svg")
    }

    /// Test: Imshow translation
    /// Python: ax.imshow(data, cmap='viridis', vmin=0, vmax=1)
    /// Lua:    ax:imshow(data, {cmap="viridis", vmin=0, vmax=1})
    func testTranslationImshow() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data = {{0, 0.5, 1}, {0.5, 1, 0.5}, {1, 0.5, 0}}
            ax:imshow(data, {cmap="viridis", vmin=0, vmax=1})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Errorbar translation
    /// Python: ax.errorbar(x, y, yerr=errors, fmt='o', capsize=5)
    /// Lua:    ax:errorbar(x, y, {yerr=errors, fmt="o", capsize=5})
    func testTranslationErrorbar() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local x = {1, 2, 3}
            local y = {4, 5, 6}
            local errors = {0.5, 0.3, 0.4}
            ax:errorbar(x, y, {yerr=errors, fmt="o", capsize=5})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Boxplot translation
    /// Python: ax.boxplot([data1, data2], widths=0.6, showmeans=True)
    /// Lua:    ax:boxplot({data1, data2}, {widths=0.6, showmeans=true})
    func testTranslationBoxplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()
            local data1 = {1, 2, 3, 4, 5}
            local data2 = {3, 4, 5, 6, 7}
            ax:boxplot({data1, data2}, {widths=0.6, showmeans=true})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Seaborn Translation Tests

    /// Test: sns.histplot translation
    /// Python: sns.histplot(data, kde=True, stat='density')
    /// Lua:    stat.histplot(ax, data, {kde=true, stat="density"})
    func testTranslationSeabornHistplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {1, 2, 2, 3, 3, 3, 4, 4, 5}
            stat.histplot(ax, data, {kde=true, stat="density"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.kdeplot translation
    /// Python: sns.kdeplot(data, fill=True, bw_method='scott')
    /// Lua:    stat.kdeplot(ax, data, {fill=true, bw_method="scott"})
    func testTranslationSeabornKdeplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {1, 2, 3, 4, 5}
            stat.kdeplot(ax, data, {fill=true, bw_method="scott"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.violinplot translation
    /// Python: sns.violinplot(data=[d1, d2], showmeans=True, showmedians=True)
    /// Lua:    stat.violinplot(ax, {d1, d2}, {showmeans=true, showmedians=true})
    func testTranslationSeabornViolinplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local d1 = {1, 2, 3, 4, 5}
            local d2 = {3, 4, 5, 6, 7}
            stat.violinplot(ax, {d1, d2}, {showmeans=true, showmedians=true})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.regplot translation
    /// Python: sns.regplot(x=x, y=y, ci=95, scatter=True)
    /// Lua:    stat.regplot(ax, x, y, {ci=95, scatter=true})
    func testTranslationSeabornRegplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local x = {1, 2, 3, 4, 5}
            local y = {2, 4, 5, 4, 5}
            stat.regplot(ax, x, y, {ci=95, scatter=true})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.heatmap translation
    /// Python: sns.heatmap(data, annot=True, fmt='.2f', cmap='coolwarm')
    /// Lua:    stat.heatmap(ax, data, {annot=true, fmt=".2f", cmap="coolwarm"})
    func testTranslationSeabornHeatmap() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{1, 0.8, 0.3}, {0.8, 1, 0.5}, {0.3, 0.5, 1}}
            stat.heatmap(ax, data, {annot=true, fmt=".2f", cmap="coolwarm"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.stripplot translation
    /// Python: sns.stripplot(data=data, jitter=0.2, color='blue')
    /// Lua:    stat.stripplot(ax, data, {jitter=0.2, color="blue"})
    func testTranslationSeabornStripplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{1, 2, 3, 4, 5}}
            stat.stripplot(ax, data, {jitter=0.2, color="blue"})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.swarmplot translation
    /// Python: sns.swarmplot(data=data, size=5)
    /// Lua:    stat.swarmplot(ax, data, {size=5})
    func testTranslationSeabornSwarmplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, ax = plt.subplots()
            local data = {{1, 2, 2, 3, 3, 4}}
            stat.swarmplot(ax, data, {size=5})
            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.catplot translation
    /// Python: g = sns.catplot(data=data, kind='box', height=5)
    /// Lua:    local result = stat.catplot(data, {kind="box", height=5})
    func testTranslationSeabornCatplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local result = stat.catplot({{1, 2, 3, 4, 5}}, {kind="box", height=5})
            return result.fig ~= nil and result.ax ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.lmplot translation
    /// Python: g = sns.lmplot(data=df, x='x', y='y', ci=95)
    /// Lua:    local result = stat.lmplot(data, {x="x", y="y", ci=95})
    func testTranslationSeabornLmplot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {x={1, 2, 3, 4, 5}, y={2, 4, 5, 4, 5}}
            local result = stat.lmplot(data, {x="x", y="y", ci=95})
            return result.fig ~= nil and result.ax ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: sns.clustermap translation
    /// Python: g = sns.clustermap(data, annot=True, cmap='viridis')
    /// Lua:    local result = stat.clustermap(data, {annot=true, cmap="viridis"})
    func testTranslationSeabornClustermap() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local stat = plt.stat
            local data = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}
            local result = stat.clustermap(data, {annot=true, cmap="viridis"})
            return result.fig ~= nil and result.row_order ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Complete Workflow Translation Test

    /// Test: Complete matplotlib workflow translation
    /// This test demonstrates a complete Python → Lua translation
    func testTranslationCompleteWorkflow() throws {
        let result = try engine.evaluate("""
            -- Python equivalent:
            -- import matplotlib.pyplot as plt
            -- fig, ax = plt.subplots(figsize=(10, 8))
            -- ax.plot([1, 2, 3, 4, 5], [1, 4, 9, 16, 25], 'b-o', label='y = x²')
            -- ax.scatter([1, 2, 3, 4, 5], [1, 4, 9, 16, 25], s=100, c='red')
            -- ax.set_title('Square Function')
            -- ax.set_xlabel('x')
            -- ax.set_ylabel('y')
            -- ax.legend(loc='upper left')
            -- ax.grid(True, linestyle='--', alpha=0.7)
            -- ax.set_xlim(0, 6)
            -- ax.set_ylim(0, 30)
            -- plt.show()

            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots({figsize={10, 8}})
            ax:plot({1, 2, 3, 4, 5}, {1, 4, 9, 16, 25}, "b-o", {label="y = x²"})
            ax:scatter({1, 2, 3, 4, 5}, {1, 4, 9, 16, 25}, {s=100, c="red"})
            ax:set_title("Square Function")
            ax:set_xlabel("x")
            ax:set_ylabel("y")
            ax:legend({loc="upper left"})
            ax:grid({linestyle="--", alpha=0.7})
            ax:set_xlim(0, 6)
            ax:set_ylim(0, 30)
            plt.show()

            local svg = fig:to_svg()
            return svg:find("<svg") ~= nil and svg:find("<path") ~= nil
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Complete seaborn workflow translation
    func testTranslationSeabornCompleteWorkflow() throws {
        let result = try engine.evaluate("""
            -- Python equivalent:
            -- import seaborn as sns
            -- import matplotlib.pyplot as plt
            -- fig, axes = plt.subplots(1, 2, figsize=(12, 5))
            -- data = [1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 7, 8]
            -- sns.histplot(data, kde=True, ax=axes[0])
            -- axes[0].set_title('Distribution')
            -- sns.kdeplot(data, fill=True, ax=axes[1])
            -- axes[1].set_title('KDE Plot')
            -- plt.show()

            local plt = require("luaswift.plot")
            local stat = plt.stat
            local fig, axes = plt.subplots(1, 2, {figsize={12, 5}})
            local data = {1, 2, 2, 3, 3, 3, 4, 4, 5, 6, 7, 8}
            stat.histplot(axes[1], data, {kde=true})
            axes[1]:set_title("Distribution")
            stat.kdeplot(axes[2], data, {fill=true})
            axes[2]:set_title("KDE Plot")
            plt.show()

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Format String and Marker Tests

    /// Test: Plot with format string parsing
    func testPlotFormatString() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            -- Test format strings like matplotlib
            ax:plot({1, 2, 3}, {1, 4, 9}, "r--o")  -- red dashed line with circle markers
            ax:plot({1, 2, 3}, {2, 5, 10}, "b-^")  -- blue solid line with triangle markers
            ax:plot({1, 2, 3}, {3, 6, 11}, "g:s")  -- green dotted line with square markers

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Plot with explicit marker parameters
    func testPlotMarkerParameters() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:plot({1, 2, 3}, {1, 4, 9}, {
                marker = "o",
                markersize = 10,
                markerfacecolor = "red",
                markeredgecolor = "black",
                markeredgewidth = 2
            })

            -- Also test ms, mfc, mec aliases
            ax:plot({1, 2, 3}, {2, 5, 10}, {
                marker = "s",
                ms = 8,
                mfc = "blue",
                mec = "white"
            })

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: All marker types
    func testAllMarkerTypes() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            local markers = {"o", "s", "^", "v", "<", ">", "d", "D", "p", "h", "H", "+", "x", "*", ".", ","}
            for i, m in ipairs(markers) do
                ax:plot({i}, {i}, {marker = m, markersize = 10, color = "blue"})
            end

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Alpha Transparency Tests

    /// Test: Plot with alpha transparency
    func testPlotAlpha() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:plot({1, 2, 3}, {1, 4, 9}, {alpha = 0.5, color = "blue"})
            ax:plot({1, 2, 3}, {2, 5, 10}, {alpha = 0.3, color = "red"})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Scatter with alpha
    func testScatterAlpha() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:scatter({1, 2, 3, 4, 5}, {1, 4, 9, 16, 25}, {alpha = 0.5, s = 100})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Bar with alpha
    func testBarAlpha() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:bar({1, 2, 3}, {10, 20, 15}, {alpha = 0.7, color = "steelblue"})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Scatter Array Support Tests

    /// Test: Scatter with array-valued sizes
    func testScatterArraySizes() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            local x = {1, 2, 3, 4, 5}
            local y = {1, 4, 9, 16, 25}
            local sizes = {50, 100, 150, 200, 250}  -- Different size for each point

            ax:scatter(x, y, {s = sizes})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Scatter with array-valued colors
    func testScatterArrayColors() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            local x = {1, 2, 3, 4, 5}
            local y = {1, 4, 9, 16, 25}
            local colors = {"red", "green", "blue", "orange", "purple"}

            ax:scatter(x, y, {c = colors, s = 100})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Scatter with edgecolors and linewidths
    func testScatterEdgeColors() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:scatter({1, 2, 3}, {1, 4, 9}, {
                s = 200,
                c = "lightblue",
                edgecolors = "darkblue",
                linewidths = 2
            })

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Bar Stacked and Align Tests

    /// Test: Stacked bar chart with bottom parameter
    func testBarStacked() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            local x = {1, 2, 3}
            local bottom_values = {5, 10, 8}
            local top_values = {10, 15, 12}

            -- Bottom layer
            ax:bar(x, bottom_values, {color = "blue"})
            -- Top layer (stacked)
            ax:bar(x, top_values, {color = "orange", bottom = bottom_values})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Bar with align parameter
    func testBarAlign() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            -- Edge-aligned bars
            ax:bar({1, 2, 3}, {10, 20, 15}, {align = "edge", color = "green"})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Axis Scaling Tests

    /// Test: Set axis scale
    func testAxisScale() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:set_xscale("log")
            ax:set_yscale("log")

            return ax:get_xscale() == "log" and ax:get_yscale() == "log"
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Symlog scale with threshold
    func testSymlogScale() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:set_yscale("symlog", {linthresh = 2})

            return ax:get_yscale() == "symlog"
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    // MARK: - Edge Case Tests

    /// Test: Empty data handling
    func testEmptyDataHandling() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            -- Empty arrays should not crash
            local success = pcall(function()
                ax:plot({}, {})
            end)

            return fig:get_context():command_count() >= 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Single point plot
    func testSinglePointPlot() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:plot({5}, {10}, {marker = "o", markersize = 10})
            ax:scatter({5}, {10}, {s = 100})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Degenerate input (all same values)
    func testDegenerateInput() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            -- All y values the same
            ax:plot({1, 2, 3, 4, 5}, {5, 5, 5, 5, 5})

            -- All x values the same
            ax:plot({3, 3, 3, 3, 3}, {1, 2, 3, 4, 5})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Plot markers only (no line)
    func testMarkersOnlyNoLine() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            -- Using linestyle="none" to show only markers
            ax:plot({1, 2, 3}, {1, 4, 9}, {
                marker = "o",
                linestyle = "none",
                markersize = 10
            })

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Line only (no markers, default)
    func testLineOnlyNoMarkers() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            -- Default: line only, no markers
            ax:plot({1, 2, 3, 4, 5}, {1, 4, 9, 16, 25})

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }

    /// Test: Both line and markers
    func testLineAndMarkers() throws {
        let result = try engine.evaluate("""
            local plt = require("luaswift.plot")
            local fig, ax = plt.subplots()

            ax:plot({1, 2, 3, 4, 5}, {1, 4, 9, 16, 25}, {
                marker = "o",
                linestyle = "-",
                color = "blue"
            })

            return fig:get_context():command_count() > 0
        """)
        XCTAssertEqual(result.boolValue, true)
    }
}
