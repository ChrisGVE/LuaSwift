//
//  SVGModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-04.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed SVG generation module for LuaSwift.
///
/// Provides SVG document creation and manipulation with support for basic shapes,
/// paths, text, and styling.
///
/// ## Usage
///
/// ```lua
/// local svg = require("luaswift.svg")
///
/// local drawing = svg.create(800, 600, {background = "#ffffff"})
/// drawing:rect(10, 10, 100, 50, {fill = "blue", stroke = "black"})
/// drawing:circle(200, 200, 50, {fill = "red"})
/// drawing:text(100, 300, "Hello, SVG!", {["font-size"] = 24})
///
/// local output = drawing:render()
/// ```
public struct SVGModule {

    // MARK: - Drawing Storage

    /// Thread-safe storage for SVGDrawing instances by engine
    private static var drawingsStorage: [ObjectIdentifier: [Int: SVGDrawing]] = [:]
    private static let storageLock = NSLock()
    private static var nextDrawingId: [ObjectIdentifier: Int] = [:]

    /// Get the next drawing ID for an engine
    private static func getNextDrawingId(for engineKey: ObjectIdentifier) -> Int {
        storageLock.lock()
        defer { storageLock.unlock() }
        let id = (nextDrawingId[engineKey] ?? 0) + 1
        nextDrawingId[engineKey] = id
        return id
    }

    /// Store a drawing for an engine
    private static func storeDrawing(_ drawing: SVGDrawing, id: Int, engineKey: ObjectIdentifier) {
        storageLock.lock()
        defer { storageLock.unlock() }
        if drawingsStorage[engineKey] == nil {
            drawingsStorage[engineKey] = [:]
        }
        drawingsStorage[engineKey]?[id] = drawing
    }

    /// Get a drawing by ID
    private static func getDrawing(id: Int, engineKey: ObjectIdentifier) -> SVGDrawing? {
        storageLock.lock()
        defer { storageLock.unlock() }
        return drawingsStorage[engineKey]?[id]
    }

    /// Clean up drawings for an engine
    internal static func cleanup(for engine: LuaEngine) {
        let key = ObjectIdentifier(engine)
        storageLock.lock()
        defer { storageLock.unlock() }
        drawingsStorage.removeValue(forKey: key)
        nextDrawingId.removeValue(forKey: key)
    }

    // MARK: - Registration

    /// Register the SVG module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        let engineKey = ObjectIdentifier(engine)

        // Create callback
        let createCallback: ([LuaValue]) throws -> LuaValue = { args in
            try createDrawing(args, engineKey: engineKey)
        }

        // Shape callbacks
        let rectCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addRect(args, engineKey: engineKey)
        }

        let circleCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addCircle(args, engineKey: engineKey)
        }

        let ellipseCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addEllipse(args, engineKey: engineKey)
        }

        let lineCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addLine(args, engineKey: engineKey)
        }

        let polylineCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addPolyline(args, engineKey: engineKey)
        }

        let polygonCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addPolygon(args, engineKey: engineKey)
        }

        let pathCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addPath(args, engineKey: engineKey)
        }

        let textCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addText(args, engineKey: engineKey)
        }

        let groupCallback: ([LuaValue]) throws -> LuaValue = { args in
            try addGroup(args, engineKey: engineKey)
        }

        // Utility callbacks
        let renderCallback: ([LuaValue]) throws -> LuaValue = { args in
            try renderDrawing(args, engineKey: engineKey)
        }

        let clearCallback: ([LuaValue]) throws -> LuaValue = { args in
            try clearDrawing(args, engineKey: engineKey)
        }

        let countCallback: ([LuaValue]) throws -> LuaValue = { args in
            try countElements(args, engineKey: engineKey)
        }

        // Register all functions
        engine.registerFunction(name: "_luaswift_svg_create", callback: createCallback)
        engine.registerFunction(name: "_luaswift_svg_rect", callback: rectCallback)
        engine.registerFunction(name: "_luaswift_svg_circle", callback: circleCallback)
        engine.registerFunction(name: "_luaswift_svg_ellipse", callback: ellipseCallback)
        engine.registerFunction(name: "_luaswift_svg_line", callback: lineCallback)
        engine.registerFunction(name: "_luaswift_svg_polyline", callback: polylineCallback)
        engine.registerFunction(name: "_luaswift_svg_polygon", callback: polygonCallback)
        engine.registerFunction(name: "_luaswift_svg_path", callback: pathCallback)
        engine.registerFunction(name: "_luaswift_svg_text", callback: textCallback)
        engine.registerFunction(name: "_luaswift_svg_group", callback: groupCallback)
        engine.registerFunction(name: "_luaswift_svg_render", callback: renderCallback)
        engine.registerFunction(name: "_luaswift_svg_clear", callback: clearCallback)
        engine.registerFunction(name: "_luaswift_svg_count", callback: countCallback)

        // Set up the luaswift.svg namespace
        do {
            try engine.run(svgLuaWrapper)
        } catch {
            // Module setup failed - functions still available as globals
        }
    }

    // MARK: - Helper Functions

    /// Escape XML special characters
    private static func escapeXML(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }

    /// Convert Lua table to SVG attribute string
    private static func attrsToString(_ attrs: [String: LuaValue]?) -> String {
        guard let attrs = attrs, !attrs.isEmpty else { return "" }

        // Sort keys for deterministic output
        let sortedKeys = attrs.keys.sorted()
        var parts: [String] = []

        for key in sortedKeys {
            guard let value = attrs[key] else { continue }
            let stringValue: String
            switch value {
            case .string(let s):
                stringValue = escapeXML(s)
            case .number(let n):
                if n == n.rounded() && abs(n) < Double(Int.max) {
                    stringValue = String(Int(n))
                } else {
                    stringValue = String(format: "%.4g", n)
                }
            case .bool(let b):
                stringValue = b ? "true" : "false"
            default:
                continue
            }
            parts.append("\(key)=\"\(stringValue)\"")
        }

        return parts.isEmpty ? "" : " " + parts.joined(separator: " ")
    }

    /// Extract drawing ID from table
    private static func extractDrawingId(_ value: LuaValue) -> Int? {
        guard let table = value.tableValue,
              let id = table["_id"]?.intValue else { return nil }
        return id
    }

    // MARK: - Callbacks

    private static func createDrawing(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let width = args.first?.intValue else {
            throw LuaError.callbackError("svg.create requires width as first argument")
        }

        guard args.count >= 2, let height = args[1].intValue else {
            throw LuaError.callbackError("svg.create requires height as second argument")
        }

        // Parse options
        var viewBox: String? = nil
        var background: String? = nil

        if args.count >= 3, let options = args[2].tableValue {
            if let vb = options["viewBox"]?.stringValue {
                viewBox = vb
            }
            if let bg = options["background"]?.stringValue {
                background = bg
            }
        }

        // Create drawing
        let drawing = SVGDrawing(width: width, height: height, viewBox: viewBox, background: background)
        let id = getNextDrawingId(for: engineKey)
        storeDrawing(drawing, id: id, engineKey: engineKey)

        // Return table with ID for Lua to wrap with metatable
        return .table([
            "_id": .number(Double(id)),
            "width": .number(Double(width)),
            "height": .number(Double(height))
        ])
    }

    private static func addRect(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        guard args.count >= 5,
              let x = args[1].numberValue,
              let y = args[2].numberValue,
              let width = args[3].numberValue,
              let height = args[4].numberValue else {
            throw LuaError.callbackError("rect requires x, y, width, height arguments")
        }

        let attrs = args.count >= 6 ? args[5].tableValue : nil
        let element = "<rect x=\"\(Int(x))\" y=\"\(Int(y))\" width=\"\(Int(width))\" height=\"\(Int(height))\"\(attrsToString(attrs))/>"
        drawing.addElement(element)

        return args[0] // Return drawing for chaining
    }

    private static func addCircle(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        guard args.count >= 4,
              let cx = args[1].numberValue,
              let cy = args[2].numberValue,
              let r = args[3].numberValue else {
            throw LuaError.callbackError("circle requires cx, cy, r arguments")
        }

        let attrs = args.count >= 5 ? args[4].tableValue : nil
        let element = "<circle cx=\"\(Int(cx))\" cy=\"\(Int(cy))\" r=\"\(Int(r))\"\(attrsToString(attrs))/>"
        drawing.addElement(element)

        return args[0]
    }

    private static func addEllipse(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        guard args.count >= 5,
              let cx = args[1].numberValue,
              let cy = args[2].numberValue,
              let rx = args[3].numberValue,
              let ry = args[4].numberValue else {
            throw LuaError.callbackError("ellipse requires cx, cy, rx, ry arguments")
        }

        let attrs = args.count >= 6 ? args[5].tableValue : nil
        let element = "<ellipse cx=\"\(Int(cx))\" cy=\"\(Int(cy))\" rx=\"\(Int(rx))\" ry=\"\(Int(ry))\"\(attrsToString(attrs))/>"
        drawing.addElement(element)

        return args[0]
    }

    private static func addLine(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        guard args.count >= 5,
              let x1 = args[1].numberValue,
              let y1 = args[2].numberValue,
              let x2 = args[3].numberValue,
              let y2 = args[4].numberValue else {
            throw LuaError.callbackError("line requires x1, y1, x2, y2 arguments")
        }

        var attrs = args.count >= 6 ? args[5].tableValue : nil
        // Default stroke for visibility
        if attrs == nil {
            attrs = ["stroke": .string("black")]
        } else if attrs?["stroke"] == nil {
            attrs?["stroke"] = .string("black")
        }

        let element = "<line x1=\"\(Int(x1))\" y1=\"\(Int(y1))\" x2=\"\(Int(x2))\" y2=\"\(Int(y2))\"\(attrsToString(attrs))/>"
        drawing.addElement(element)

        return args[0]
    }

    private static func addPolyline(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        guard args.count >= 2, let pointsTable = args[1].arrayValue else {
            throw LuaError.callbackError("polyline requires points array")
        }

        // Convert points to string
        var pointStrings: [String] = []
        for point in pointsTable {
            if let arr = point.arrayValue, arr.count >= 2,
               let x = arr[0].numberValue,
               let y = arr[1].numberValue {
                pointStrings.append("\(Int(x)),\(Int(y))")
            } else if let table = point.tableValue,
                      let x = table["x"]?.numberValue ?? table["1"]?.numberValue,
                      let y = table["y"]?.numberValue ?? table["2"]?.numberValue {
                pointStrings.append("\(Int(x)),\(Int(y))")
            }
        }

        var attrs = args.count >= 3 ? args[2].tableValue : nil
        // Default fill none and stroke for visibility
        if attrs == nil {
            attrs = ["fill": .string("none"), "stroke": .string("black")]
        } else {
            if attrs?["fill"] == nil { attrs?["fill"] = .string("none") }
            if attrs?["stroke"] == nil { attrs?["stroke"] = .string("black") }
        }

        let pointsStr = pointStrings.joined(separator: " ")
        let element = "<polyline points=\"\(pointsStr)\"\(attrsToString(attrs))/>"
        drawing.addElement(element)

        return args[0]
    }

    private static func addPolygon(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        guard args.count >= 2, let pointsTable = args[1].arrayValue else {
            throw LuaError.callbackError("polygon requires points array")
        }

        // Convert points to string
        var pointStrings: [String] = []
        for point in pointsTable {
            if let arr = point.arrayValue, arr.count >= 2,
               let x = arr[0].numberValue,
               let y = arr[1].numberValue {
                pointStrings.append("\(Int(x)),\(Int(y))")
            } else if let table = point.tableValue,
                      let x = table["x"]?.numberValue ?? table["1"]?.numberValue,
                      let y = table["y"]?.numberValue ?? table["2"]?.numberValue {
                pointStrings.append("\(Int(x)),\(Int(y))")
            }
        }

        let attrs = args.count >= 3 ? args[2].tableValue : nil
        let pointsStr = pointStrings.joined(separator: " ")
        let element = "<polygon points=\"\(pointsStr)\"\(attrsToString(attrs))/>"
        drawing.addElement(element)

        return args[0]
    }

    private static func addPath(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        guard args.count >= 2, let d = args[1].stringValue else {
            throw LuaError.callbackError("path requires d (path data) argument")
        }

        let attrs = args.count >= 3 ? args[2].tableValue : nil
        let element = "<path d=\"\(escapeXML(d))\"\(attrsToString(attrs))/>"
        drawing.addElement(element)

        return args[0]
    }

    private static func addText(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        guard args.count >= 4,
              let x = args[1].numberValue,
              let y = args[2].numberValue,
              let content = args[3].stringValue else {
            throw LuaError.callbackError("text requires x, y, content arguments")
        }

        let attrs = args.count >= 5 ? args[4].tableValue : nil
        let element = "<text x=\"\(Int(x))\" y=\"\(Int(y))\"\(attrsToString(attrs))>\(escapeXML(content))</text>"
        drawing.addElement(element)

        return args[0]
    }

    private static func addGroup(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        let attrs = args.count >= 2 ? args[1].tableValue : nil
        drawing.beginGroup(attrsToString(attrs))

        return args[0]
    }

    private static func renderDrawing(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        return .string(drawing.render())
    }

    private static func clearDrawing(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        drawing.clear()
        return args[0]
    }

    private static func countElements(_ args: [LuaValue], engineKey: ObjectIdentifier) throws -> LuaValue {
        guard let drawingId = extractDrawingId(args[0]),
              let drawing = getDrawing(id: drawingId, engineKey: engineKey) else {
            throw LuaError.callbackError("Invalid drawing object")
        }

        return .number(Double(drawing.elementCount))
    }

    // MARK: - Lua Wrapper Code

    private static let svgLuaWrapper = """
    -- Create luaswift.svg namespace
    if not luaswift then luaswift = {} end
    luaswift.svg = {}
    local svg = luaswift.svg

    -- Store references to Swift functions
    local _create = _luaswift_svg_create
    local _rect = _luaswift_svg_rect
    local _circle = _luaswift_svg_circle
    local _ellipse = _luaswift_svg_ellipse
    local _line = _luaswift_svg_line
    local _polyline = _luaswift_svg_polyline
    local _polygon = _luaswift_svg_polygon
    local _path = _luaswift_svg_path
    local _text = _luaswift_svg_text
    local _group = _luaswift_svg_group
    local _render = _luaswift_svg_render
    local _clear = _luaswift_svg_clear
    local _count = _luaswift_svg_count

    -- Drawing metatable
    local drawing_mt = {
        __tostring = function(self)
            return string.format("svg.drawing(%dx%d, %d elements)", self.width, self.height, _count(self))
        end,
        __index = {
            rect = function(self, x, y, w, h, attrs)
                _rect(self, x, y, w, h, attrs)
                return self
            end,
            circle = function(self, cx, cy, r, attrs)
                _circle(self, cx, cy, r, attrs)
                return self
            end,
            ellipse = function(self, cx, cy, rx, ry, attrs)
                _ellipse(self, cx, cy, rx, ry, attrs)
                return self
            end,
            line = function(self, x1, y1, x2, y2, attrs)
                _line(self, x1, y1, x2, y2, attrs)
                return self
            end,
            polyline = function(self, points, attrs)
                _polyline(self, points, attrs)
                return self
            end,
            polygon = function(self, points, attrs)
                _polygon(self, points, attrs)
                return self
            end,
            path = function(self, d, attrs)
                _path(self, d, attrs)
                return self
            end,
            text = function(self, x, y, content, attrs)
                _text(self, x, y, content, attrs)
                return self
            end,
            group = function(self, attrs)
                _group(self, attrs)
                return self
            end,
            render = function(self)
                return _render(self)
            end,
            clear = function(self)
                _clear(self)
                return self
            end,
            count = function(self)
                return _count(self)
            end
        }
    }

    -- Factory function
    function svg.create(width, height, options)
        local drawing = _create(width, height, options)
        drawing.__luaswift_type = "svg.drawing"
        setmetatable(drawing, drawing_mt)
        return drawing
    end

    -- Greek letter table for text content
    svg.greek = {
        -- Lowercase
        alpha = "α", beta = "β", gamma = "γ", delta = "δ", epsilon = "ε",
        zeta = "ζ", eta = "η", theta = "θ", iota = "ι", kappa = "κ",
        lambda = "λ", mu = "μ", nu = "ν", xi = "ξ", omicron = "ο",
        pi = "π", rho = "ρ", sigma = "σ", tau = "τ", upsilon = "υ",
        phi = "φ", chi = "χ", psi = "ψ", omega = "ω",
        -- Uppercase
        Alpha = "Α", Beta = "Β", Gamma = "Γ", Delta = "Δ", Epsilon = "Ε",
        Zeta = "Ζ", Eta = "Η", Theta = "Θ", Iota = "Ι", Kappa = "Κ",
        Lambda = "Λ", Mu = "Μ", Nu = "Ν", Xi = "Ξ", Omicron = "Ο",
        Pi = "Π", Rho = "Ρ", Sigma = "Σ", Tau = "Τ", Upsilon = "Υ",
        Phi = "Φ", Chi = "Χ", Psi = "Ψ", Omega = "Ω",
        -- Math symbols
        infinity = "∞", plusminus = "±", sqrt = "√", sum = "∑", integral = "∫",
        degree = "°", times = "×", divide = "÷", neq = "≠", leq = "≤", geq = "≥"
    }

    -- Create top-level alias
    svg_module = svg

    -- Make available via require
    package.loaded["luaswift.svg"] = svg

    -- Clean up temporary globals
    _luaswift_svg_create = nil
    _luaswift_svg_rect = nil
    _luaswift_svg_circle = nil
    _luaswift_svg_ellipse = nil
    _luaswift_svg_line = nil
    _luaswift_svg_polyline = nil
    _luaswift_svg_polygon = nil
    _luaswift_svg_path = nil
    _luaswift_svg_text = nil
    _luaswift_svg_group = nil
    _luaswift_svg_render = nil
    _luaswift_svg_clear = nil
    _luaswift_svg_count = nil
    """
}

// MARK: - SVGDrawing Class

/// Internal class to hold SVG drawing state.
internal class SVGDrawing {
    var width: Int
    var height: Int
    var viewBox: String?
    var background: String?
    var elements: [String] = []
    private var groupStack: [(attrs: String, startIndex: Int)] = []

    init(width: Int, height: Int, viewBox: String? = nil, background: String? = nil) {
        self.width = width
        self.height = height
        self.viewBox = viewBox
        self.background = background
    }

    var elementCount: Int {
        return elements.count
    }

    func addElement(_ element: String) {
        elements.append(element)
    }

    func beginGroup(_ attrs: String) {
        groupStack.append((attrs: attrs, startIndex: elements.count))
    }

    func endGroup() {
        guard let group = groupStack.popLast() else { return }
        let groupElements = Array(elements[group.startIndex...])
        elements.removeLast(groupElements.count)
        let groupContent = groupElements.joined(separator: "\n  ")
        elements.append("<g\(group.attrs)>\n  \(groupContent)\n</g>")
    }

    func clear() {
        elements.removeAll()
        groupStack.removeAll()
    }

    func render() -> String {
        // Close any open groups
        while !groupStack.isEmpty {
            endGroup()
        }

        let viewBoxAttr = viewBox ?? "0 0 \(width) \(height)"
        var svgContent = ""

        // Add background rect if specified
        if let bg = background {
            svgContent += "  <rect width=\"100%\" height=\"100%\" fill=\"\(bg)\"/>\n"
        }

        // Add all elements
        svgContent += elements.map { "  \($0)" }.joined(separator: "\n")

        return """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(width)" height="\(height)" viewBox="\(viewBoxAttr)">
        \(svgContent)
        </svg>
        """
    }
}
