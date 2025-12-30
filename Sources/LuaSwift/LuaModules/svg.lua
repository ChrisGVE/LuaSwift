-- svg.lua - Minimal SVG Builder for Lua 5.4.7
-- Copyright (c) 2025 LuaSwift Project
-- Licensed under the MIT License
--
-- A pure Lua module for building SVG graphics programmatically.
-- Designed for educational apps on iOS/macOS via LuaSwift wrapper.

local svg = {}

-- Greek letters and special characters lookup table
svg.greek = {
  alpha = "α", beta = "β", gamma = "γ", delta = "δ", epsilon = "ε",
  theta = "θ", pi = "π", omega = "Ω", sigma = "σ", mu = "μ",
  -- Subscripts
  sub0 = "₀", sub1 = "₁", sub2 = "₂", sub3 = "₃", sub4 = "₄",
  sub5 = "₅", sub6 = "₆", sub7 = "₇", sub8 = "₈", sub9 = "₉",
  -- Superscripts
  sup0 = "⁰", sup1 = "¹", sup2 = "²", sup3 = "³", sup4 = "⁴",
  sup5 = "⁵", sup6 = "⁶", sup7 = "⁷", sup8 = "⁸", sup9 = "⁹"
}

-- Escape XML special characters
local function xmlEscape(str)
  if not str then return "" end
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
  return table.concat(attrs, " ")
end

-- SVG Drawing object
local Drawing = {}
Drawing.__index = Drawing

-- Create a new SVG drawing
-- @param width: canvas width in pixels
-- @param height: canvas height in pixels
-- @param options: optional table with viewBox, background, etc.
-- @return: Drawing object
function svg.create(width, height, options)
  options = options or {}
  local self = setmetatable({
    width = width,
    height = height,
    viewBox = options.viewBox,
    background = options.background,
    elements = {}
  }, Drawing)
  return self
end

-- Add rectangle to drawing
-- @param x, y: top-left corner coordinates
-- @param width, height: rectangle dimensions
-- @param style: optional table {fill, stroke, stroke_width, etc.}
function Drawing:rect(x, y, width, height, style)
  local attrs = styleToAttrs(style)
  local elem = string.format('<rect x="%s" y="%s" width="%s" height="%s" %s/>',
    x, y, width, height, attrs)
  table.insert(self.elements, elem)
  return self
end

-- Add circle to drawing
-- @param cx, cy: center coordinates
-- @param r: radius
-- @param style: optional styling
function Drawing:circle(cx, cy, r, style)
  local attrs = styleToAttrs(style)
  local elem = string.format('<circle cx="%s" cy="%s" r="%s" %s/>',
    cx, cy, r, attrs)
  table.insert(self.elements, elem)
  return self
end

-- Add ellipse to drawing
-- @param cx, cy: center coordinates
-- @param rx, ry: x-radius and y-radius
-- @param style: optional styling
function Drawing:ellipse(cx, cy, rx, ry, style)
  local attrs = styleToAttrs(style)
  local elem = string.format('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" %s/>',
    cx, cy, rx, ry, attrs)
  table.insert(self.elements, elem)
  return self
end

-- Add line to drawing
-- @param x1, y1: start point
-- @param x2, y2: end point
-- @param style: optional styling
function Drawing:line(x1, y1, x2, y2, style)
  local attrs = styleToAttrs(style)
  local elem = string.format('<line x1="%s" y1="%s" x2="%s" y2="%s" %s/>',
    x1, y1, x2, y2, attrs)
  table.insert(self.elements, elem)
  return self
end

-- Add polyline (connected line segments)
-- @param points: array of {x, y} tables
-- @param style: optional styling
function Drawing:polyline(points, style)
  local coords = {}
  for _, pt in ipairs(points) do
    table.insert(coords, string.format("%s,%s", pt.x or pt[1], pt.y or pt[2]))
  end
  local pointsStr = table.concat(coords, " ")
  local attrs = styleToAttrs(style)
  local elem = string.format('<polyline points="%s" %s/>', pointsStr, attrs)
  table.insert(self.elements, elem)
  return self
end

-- Add polygon (closed shape)
-- @param points: array of {x, y} tables
-- @param style: optional styling
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

-- Add path using SVG path data
-- @param d: path data string (e.g., "M 10 10 L 90 90")
-- @param style: optional styling
function Drawing:path(d, style)
  local attrs = styleToAttrs(style)
  local elem = string.format('<path d="%s" %s/>', xmlEscape(d), attrs)
  table.insert(self.elements, elem)
  return self
end

-- Add text to drawing (supports UTF-8, Greek letters)
-- @param text: text content (supports UTF-8)
-- @param x, y: text position
-- @param style: optional {font_size, font_family, fill, text_anchor, etc.}
function Drawing:text(text, x, y, style)
  local attrs = styleToAttrs(style)
  local elem = string.format('<text x="%s" y="%s" %s>%s</text>',
    x, y, attrs, xmlEscape(text))
  table.insert(self.elements, elem)
  return self
end

-- Create a group with optional transform
-- @param transform: optional transform string (e.g., "translate(10,20)")
-- @param style: optional styling
-- @return: group object with methods to add shapes
function Drawing:group(transform, style)
  local group = {elements = {}, transform = transform, style = style}

  -- Add methods to group
  for name, method in pairs(Drawing) do
    if type(method) == "function" and name ~= "render" and name ~= "group" then
      group[name] = function(self, ...)
        method(self, ...)
        return self
      end
    end
  end

  table.insert(self.elements, group)
  return group
end

-- Apply translate transform
-- @param tx, ty: translation offsets
-- @return: transform string
function svg.translate(tx, ty)
  return string.format("translate(%s,%s)", tx, ty or 0)
end

-- Apply rotate transform
-- @param angle: rotation angle in degrees
-- @param cx, cy: optional rotation center
-- @return: transform string
function svg.rotate(angle, cx, cy)
  if cx and cy then
    return string.format("rotate(%s,%s,%s)", angle, cx, cy)
  else
    return string.format("rotate(%s)", angle)
  end
end

-- Apply scale transform
-- @param sx, sy: scale factors (sy defaults to sx)
-- @return: transform string
function svg.scale(sx, sy)
  return string.format("scale(%s,%s)", sx, sy or sx)
end

-- Create line plot from data points
-- @param points: array of {x, y} tables
-- @param style: optional styling for the line
function Drawing:linePlot(points, style)
  style = style or {}
  if not style.fill then style.fill = "none" end
  if not style.stroke then style.stroke = "black" end
  return self:polyline(points, style)
end

-- Create scatter plot from data points
-- @param points: array of {x, y} tables
-- @param radius: point radius (default 3)
-- @param style: optional styling for points
function Drawing:scatterPlot(points, radius, style)
  radius = radius or 3
  for _, pt in ipairs(points) do
    self:circle(pt.x or pt[1], pt.y or pt[2], radius, style)
  end
  return self
end

-- Create bar chart
-- @param data: array of {x, y, width} tables (y is bar height)
-- @param style: optional styling for bars
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
  return table.concat(lines, "\n")
end

-- Render the SVG drawing to string
-- @return: complete SVG document as string
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
  return table.concat(lines, "\n")
end

return svg
