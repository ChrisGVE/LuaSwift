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

/// SVG generation module for LuaSwift.
///
/// Provides SVG document creation and manipulation with support for basic shapes,
/// paths, text, groups, and styling. Implemented primarily in Lua for proper
/// group nesting support, with Swift providing XML escape optimization.
///
/// ## Usage
///
/// ```lua
/// local svg = require("luaswift.svg")
///
/// local drawing = svg.create(800, 600, {background = "#ffffff"})
/// drawing:rect(10, 10, 100, 50, {fill = "blue", stroke = "black"})
/// drawing:circle(200, 200, 50, {fill = "red"})
/// drawing:text("Hello, SVG!", 100, 300, {["font-size"] = 24})
///
/// -- Groups return group objects for nesting
/// local g = drawing:group(svg.translate(50, 50))
/// g:rect(0, 0, 20, 20, {fill = "green"})
///
/// local output = drawing:render()
/// ```
public struct SVGModule {

    // MARK: - Registration

    /// Register the SVG module with a LuaEngine.
    ///
    /// The SVG module is implemented primarily in Lua for proper group nesting support.
    /// Swift provides an optional XML escape helper for performance.
    public static func register(in engine: LuaEngine) {
        // Register XML escape helper for performance (optional - Lua has fallback)
        let xmlEscapeCallback: ([LuaValue]) throws -> LuaValue = { args in
            guard let text = args.first?.stringValue else {
                return .string("")
            }
            return .string(escapeXML(text))
        }
        engine.registerFunction(name: "_luaswift_svg_xml_escape", callback: xmlEscapeCallback)

        // Set up the luaswift.svg namespace (pure Lua implementation)
        do {
            try engine.run(svgLuaWrapper)
        } catch {
            // Module setup failed
        }
    }

    // MARK: - Helper Functions

    /// Escape XML special characters (used by Lua wrapper for performance)
    private static func escapeXML(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }

    // MARK: - Lua Wrapper Code

    private static let svgLuaWrapper = """
    -- Create luaswift.svg namespace
    if not luaswift then luaswift = {} end
    luaswift.svg = {}
    local svg = luaswift.svg

    -- XML escape helper (use Swift version for performance)
    local _xmlEscape = _luaswift_svg_xml_escape

    -- Escape XML special characters (fallback if Swift not available)
    local function xmlEscape(str)
        if not str then return "" end
        if _xmlEscape then return _xmlEscape(tostring(str)) end
        str = tostring(str)
        str = str:gsub("&", "&amp;")
        str = str:gsub("<", "&lt;")
        str = str:gsub(">", "&gt;")
        str = str:gsub('"', "&quot;")
        str = str:gsub("'", "&apos;")
        return str
    end

    -- Convert style table to SVG attribute string
    local function styleToAttrs(style)
        if not style then return "" end
        local attrs = {}
        for k, v in pairs(style) do
            local attrName = k:gsub("_", "-")
            table.insert(attrs, string.format('%s="%s"', attrName, xmlEscape(v)))
        end
        table.sort(attrs)  -- Sort for deterministic output
        return table.concat(attrs, " ")
    end

    -- Drawing object (stores elements in Lua for proper group support)
    local Drawing = {}
    Drawing.__index = Drawing

    function Drawing:rect(x, y, width, height, style)
        local attrs = styleToAttrs(style)
        local elem = string.format('<rect x="%s" y="%s" width="%s" height="%s" %s/>',
            x, y, width, height, attrs)
        table.insert(self.elements, elem)
        return self
    end

    function Drawing:circle(cx, cy, r, style)
        local attrs = styleToAttrs(style)
        local elem = string.format('<circle cx="%s" cy="%s" r="%s" %s/>',
            cx, cy, r, attrs)
        table.insert(self.elements, elem)
        return self
    end

    function Drawing:ellipse(cx, cy, rx, ry, style)
        local attrs = styleToAttrs(style)
        local elem = string.format('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" %s/>',
            cx, cy, rx, ry, attrs)
        table.insert(self.elements, elem)
        return self
    end

    function Drawing:line(x1, y1, x2, y2, style)
        style = style or {}
        if not style.stroke then style.stroke = "black" end
        local attrs = styleToAttrs(style)
        local elem = string.format('<line x1="%s" y1="%s" x2="%s" y2="%s" %s/>',
            x1, y1, x2, y2, attrs)
        table.insert(self.elements, elem)
        return self
    end

    function Drawing:polyline(points, style)
        local coords = {}
        for _, pt in ipairs(points) do
            table.insert(coords, string.format("%s,%s", pt.x or pt[1], pt.y or pt[2]))
        end
        local pointsStr = table.concat(coords, " ")
        style = style or {}
        if not style.fill then style.fill = "none" end
        if not style.stroke then style.stroke = "black" end
        local attrs = styleToAttrs(style)
        local elem = string.format('<polyline points="%s" %s/>', pointsStr, attrs)
        table.insert(self.elements, elem)
        return self
    end

    function Drawing:polygon(points, style)
        local coords = {}
        for _, pt in ipairs(points) do
            table.insert(coords, string.format("%s,%s", pt.x or pt[1], pt.y or pt[2]))
        end
        local pointsStr = table.concat(coords, " ")
        local attrs = styleToAttrs(style)
        local elem = string.format('<polygon points="%s" %s/>', pointsStr, attrs)
        table.insert(self.elements, elem)
        return self
    end

    function Drawing:path(d, style)
        local attrs = styleToAttrs(style)
        local elem = string.format('<path d="%s" %s/>', xmlEscape(d), attrs)
        table.insert(self.elements, elem)
        return self
    end

    function Drawing:text(text, x, y, style)
        local attrs = styleToAttrs(style)
        local elem = string.format('<text x="%s" y="%s" %s>%s</text>',
            x, y, attrs, xmlEscape(text))
        table.insert(self.elements, elem)
        return self
    end

    function Drawing:group(transform, style)
        local group = {elements = {}, transform = transform, style = style, height = self.height}

        -- Add all Drawing methods to group (except render and group to prevent deep nesting issues)
        for name, method in pairs(Drawing) do
            if type(method) == "function" and name ~= "render" and name ~= "clear" and name ~= "count" then
                group[name] = function(grp, ...)
                    -- Create a temporary wrapper to add elements to group's array
                    local wrapper = {elements = grp.elements, height = grp.height}
                    setmetatable(wrapper, {__index = Drawing})
                    method(wrapper, ...)
                    return grp
                end
            end
        end

        table.insert(self.elements, group)
        return group
    end

    function Drawing:linePlot(points, style)
        style = style or {}
        if not style.fill then style.fill = "none" end
        if not style.stroke then style.stroke = "black" end
        return self:polyline(points, style)
    end

    function Drawing:scatterPlot(points, radius, style)
        radius = radius or 3
        for _, pt in ipairs(points) do
            self:circle(pt.x or pt[1], pt.y or pt[2], radius, style)
        end
        return self
    end

    function Drawing:barChart(data, style)
        for _, bar in ipairs(data) do
            local x = bar.x or bar[1]
            local height = bar.y or bar[2]
            local width = bar.width or bar[3] or 20
            local y = self.height - height
            self:rect(x, y, width, height, style)
        end
        return self
    end

    function Drawing:clear()
        self.elements = {}
        return self
    end

    function Drawing:count()
        return #self.elements
    end

    -- Render group element to SVG string
    local function renderGroup(group, indent)
        indent = indent or "  "
        local attrs = {}

        if group.transform then
            table.insert(attrs, string.format('transform="%s"', group.transform))
        end

        if group.style then
            local styleStr = styleToAttrs(group.style)
            if styleStr ~= "" then
                table.insert(attrs, styleStr)
            end
        end

        local attrStr = table.concat(attrs, " ")
        if attrStr ~= "" then attrStr = " " .. attrStr end

        local lines = {string.format("%s<g%s>", indent, attrStr)}

        for _, elem in ipairs(group.elements) do
            if type(elem) == "table" and elem.elements then
                table.insert(lines, renderGroup(elem, indent .. "  "))
            else
                table.insert(lines, indent .. "  " .. elem)
            end
        end

        table.insert(lines, indent .. "</g>")
        return table.concat(lines, "\\n")
    end

    function Drawing:render()
        local lines = {'<?xml version="1.0" encoding="UTF-8"?>'}

        -- Build SVG opening tag
        local svgAttrs = {
            string.format('width="%s"', self.width),
            string.format('height="%s"', self.height),
            'xmlns="http://www.w3.org/2000/svg"'
        }

        if self.viewBox then
            table.insert(svgAttrs, string.format('viewBox="%s"', self.viewBox))
        end

        table.insert(lines, string.format("<svg %s>", table.concat(svgAttrs, " ")))

        -- Add background if specified
        if self.background then
            table.insert(lines, string.format('  <rect width="100%%" height="100%%" fill="%s"/>',
                xmlEscape(self.background)))
        end

        -- Add all elements
        for _, elem in ipairs(self.elements) do
            if type(elem) == "table" and elem.elements then
                table.insert(lines, renderGroup(elem, "  "))
            else
                table.insert(lines, "  " .. elem)
            end
        end

        table.insert(lines, "</svg>")
        return table.concat(lines, "\\n")
    end

    -- Factory function
    function svg.create(width, height, options)
        options = options or {}
        local drawing = setmetatable({
            width = width,
            height = height,
            viewBox = options.viewBox,
            background = options.background,
            elements = {},
            __luaswift_type = "svg.drawing"
        }, {
            __index = Drawing,
            __tostring = function(self)
                return string.format("svg.drawing(%dx%d, %d elements)", self.width, self.height, #self.elements)
            end
        })
        return drawing
    end

    -- Transform helper functions
    function svg.translate(tx, ty)
        ty = ty or 0
        return string.format("translate(%s,%s)", tx, ty)
    end

    function svg.rotate(angle, cx, cy)
        if cx and cy then
            return string.format("rotate(%s,%s,%s)", angle, cx, cy)
        else
            return string.format("rotate(%s)", angle)
        end
    end

    function svg.scale(sx, sy)
        sy = sy or sx
        return string.format("scale(%s,%s)", sx, sy)
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
        -- Subscripts
        sub0 = "₀", sub1 = "₁", sub2 = "₂", sub3 = "₃", sub4 = "₄",
        sub5 = "₅", sub6 = "₆", sub7 = "₇", sub8 = "₈", sub9 = "₉",
        -- Superscripts
        sup0 = "⁰", sup1 = "¹", sup2 = "²", sup3 = "³", sup4 = "⁴",
        sup5 = "⁵", sup6 = "⁶", sup7 = "⁷", sup8 = "⁸", sup9 = "⁹",
        -- Math symbols
        infinity = "∞", plusminus = "±", sqrt = "√", sum = "∑", integral = "∫",
        degree = "°", times = "×", divide = "÷", neq = "≠", leq = "≤", geq = "≥"
    }

    -- Create top-level alias
    svg_module = svg

    -- Make available via require
    package.loaded["luaswift.svg"] = svg

    -- Clean up temporary globals
    _luaswift_svg_xml_escape = nil
    """
}
