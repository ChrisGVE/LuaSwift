# SVG Module

SVG document creation and rendering for vector graphics.

## Overview

The SVG module provides tools for creating SVG (Scalable Vector Graphics) documents programmatically. It supports basic shapes, paths, text, grouping with transforms, and simple chart helpers. The generated SVG can be saved to files or embedded in web pages.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the SVG module
ModuleRegistry.installSVGModule(in: engine)
```

## Basic Usage

```lua
local svg = require("luaswift.svg")

-- Create a drawing canvas
local drawing = svg.create(400, 300, {background = "#f0f0f0"})

-- Add shapes
drawing:rect(10, 10, 100, 50, {fill = "blue", stroke = "black"})
drawing:circle(200, 100, 40, {fill = "red"})
drawing:text("Hello, SVG!", 50, 200, {["font-size"] = "24"})

-- Render to SVG string
local output = drawing:render()
print(output)
```

## API Reference

### Creating a Drawing

#### svg.create(width, height, options?)
Creates a new SVG drawing canvas.

**Parameters:**
- `width` - Canvas width in pixels
- `height` - Canvas height in pixels
- `options` - Optional settings table:
  - `background` - Background fill color
  - `viewBox` - SVG viewBox attribute string

```lua
-- Simple canvas
local d = svg.create(800, 600)

-- With background
local d = svg.create(400, 300, {background = "#ffffff"})

-- With viewBox for scaling
local d = svg.create(100, 100, {viewBox = "0 0 100 100"})
```

### Basic Shapes

All shape methods return `self` for chaining and accept an optional `style` table.

#### rect(x, y, width, height, style?)
Draws a rectangle.

```lua
-- Simple rectangle
drawing:rect(10, 10, 100, 50)

-- Styled rectangle
drawing:rect(10, 10, 100, 50, {
    fill = "blue",
    stroke = "black",
    ["stroke-width"] = "2"
})

-- Rounded corners
drawing:rect(10, 10, 100, 50, {
    fill = "#3498db",
    rx = "10",
    ry = "10"
})
```

#### circle(cx, cy, r, style?)
Draws a circle.

```lua
drawing:circle(100, 100, 50, {fill = "red"})

-- Outlined circle
drawing:circle(200, 100, 30, {
    fill = "none",
    stroke = "green",
    ["stroke-width"] = "3"
})
```

#### ellipse(cx, cy, rx, ry, style?)
Draws an ellipse.

```lua
drawing:ellipse(100, 100, 80, 40, {fill = "purple"})
```

#### line(x1, y1, x2, y2, style?)
Draws a line. Default stroke is black if not specified.

```lua
drawing:line(0, 0, 100, 100)

-- Styled line
drawing:line(0, 0, 100, 100, {
    stroke = "red",
    ["stroke-width"] = "2",
    ["stroke-dasharray"] = "5,5"
})
```

#### polyline(points, style?)
Draws connected line segments. Default fill is none, stroke is black.

**Points format:** Array of `{x, y}` or `{x = x, y = y}` tables.

```lua
local points = {{0, 0}, {50, 100}, {100, 50}, {150, 100}}
drawing:polyline(points, {stroke = "blue", ["stroke-width"] = "2"})

-- With named coordinates
local points = {
    {x = 0, y = 0},
    {x = 100, y = 50},
    {x = 200, y = 0}
}
drawing:polyline(points)
```

#### polygon(points, style?)
Draws a closed polygon (automatically connects last point to first).

```lua
-- Triangle
local triangle = {{100, 10}, {150, 100}, {50, 100}}
drawing:polygon(triangle, {fill = "yellow", stroke = "black"})

-- Hexagon
local hexagon = {}
for i = 0, 5 do
    local angle = math.pi/3 * i - math.pi/2
    table.insert(hexagon, {
        100 + 50 * math.cos(angle),
        100 + 50 * math.sin(angle)
    })
end
drawing:polygon(hexagon, {fill = "#9b59b6"})
```

#### path(d, style?)
Draws an SVG path using path data string.

```lua
-- Simple path
drawing:path("M 10 10 L 100 10 L 100 100 Z", {fill = "orange"})

-- Bezier curve
drawing:path("M 10 80 Q 95 10 180 80", {
    fill = "none",
    stroke = "black",
    ["stroke-width"] = "2"
})

-- Arc
drawing:path("M 10 80 A 45 45 0 0 0 125 125", {
    fill = "none",
    stroke = "blue"
})
```

#### text(text, x, y, style?)
Draws text at the specified position.

```lua
drawing:text("Hello!", 100, 50)

-- Styled text
drawing:text("Styled", 100, 100, {
    ["font-family"] = "Arial",
    ["font-size"] = "24",
    ["font-weight"] = "bold",
    fill = "#2c3e50"
})

-- Centered text
drawing:text("Centered", 200, 150, {
    ["text-anchor"] = "middle",
    ["dominant-baseline"] = "middle"
})
```

### Grouping

#### group(transform?, style?)
Creates a group element for organizing shapes and applying transforms. Returns a group object with the same drawing methods.

```lua
-- Basic group with transform
local g = drawing:group(svg.translate(100, 50))
g:rect(0, 0, 50, 30, {fill = "blue"})
g:circle(25, 15, 10, {fill = "white"})

-- Nested groups
local outer = drawing:group(svg.translate(200, 200))
outer:rect(-50, -50, 100, 100, {fill = "#ecf0f1"})

local inner = outer:group(svg.rotate(45))
inner:rect(-20, -20, 40, 40, {fill = "#e74c3c"})
```

### Transform Helpers

Helper functions to generate SVG transform strings.

#### svg.translate(tx, ty?)
Creates a translation transform.

```lua
svg.translate(100, 50)    -- "translate(100,50)"
svg.translate(50)          -- "translate(50,0)"
```

#### svg.rotate(angle, cx?, cy?)
Creates a rotation transform. Angle is in degrees.

```lua
svg.rotate(45)             -- "rotate(45)"
svg.rotate(45, 100, 100)   -- "rotate(45,100,100)" (around point)
```

#### svg.scale(sx, sy?)
Creates a scale transform.

```lua
svg.scale(2)               -- "scale(2,2)"
svg.scale(2, 0.5)          -- "scale(2,0.5)"
```

### Chart Helpers

Simple chart creation utilities.

#### linePlot(points, style?)
Creates a line chart from data points.

```lua
local data = {{0, 100}, {50, 80}, {100, 120}, {150, 60}, {200, 90}}
drawing:linePlot(data, {
    stroke = "#3498db",
    ["stroke-width"] = "2"
})
```

#### scatterPlot(points, radius?, style?)
Creates a scatter plot with circles at each point.

```lua
local data = {{50, 80}, {100, 120}, {150, 60}, {200, 90}}
drawing:scatterPlot(data, 5, {fill = "#e74c3c"})
```

#### barChart(data, style?)
Creates a bar chart. Each data item should have x, height, and optional width.

```lua
local data = {
    {x = 10, y = 100, width = 30},
    {x = 50, y = 150, width = 30},
    {x = 90, y = 80, width = 30},
    {x = 130, y = 120, width = 30}
}
drawing:barChart(data, {fill = "#2ecc71"})
```

### Utility Methods

#### clear()
Removes all elements from the drawing.

```lua
drawing:clear()
```

#### count()
Returns the number of top-level elements.

```lua
print(drawing:count())  -- Number of shapes/groups
```

#### render()
Generates the complete SVG document as a string.

```lua
local svgString = drawing:render()
-- Returns complete SVG with XML declaration
```

### Style Properties

Common SVG style properties for the `style` table:

| Property | Description | Example |
|----------|-------------|---------|
| `fill` | Fill color | `"#ff0000"`, `"red"`, `"none"` |
| `stroke` | Stroke color | `"black"`, `"#333"` |
| `stroke-width` | Line thickness | `"2"`, `"0.5"` |
| `stroke-dasharray` | Dash pattern | `"5,5"`, `"10,5,2,5"` |
| `stroke-linecap` | Line endings | `"round"`, `"square"`, `"butt"` |
| `stroke-linejoin` | Corner style | `"round"`, `"bevel"`, `"miter"` |
| `opacity` | Overall opacity | `"0.5"` |
| `fill-opacity` | Fill opacity | `"0.8"` |
| `stroke-opacity` | Stroke opacity | `"0.5"` |
| `font-family` | Font name | `"Arial"`, `"serif"` |
| `font-size` | Font size | `"12"`, `"24px"` |
| `font-weight` | Font weight | `"bold"`, `"normal"` |
| `text-anchor` | Text alignment | `"start"`, `"middle"`, `"end"` |

### Greek Letters and Symbols

The module provides a table of Greek letters and mathematical symbols for text content.

```lua
print(svg.greek.alpha)      -- "α"
print(svg.greek.Delta)      -- "Δ"
print(svg.greek.pi)         -- "π"
print(svg.greek.infinity)   -- "∞"
print(svg.greek.sqrt)       -- "√"

-- Use in text
drawing:text(svg.greek.pi .. " = 3.14159", 100, 50)

-- Subscripts and superscripts
drawing:text("x" .. svg.greek.sub2, 50, 100)  -- x₂
drawing:text("x" .. svg.greek.sup2, 50, 150)  -- x²
```

**Available symbols:**
- Lowercase Greek: `alpha` through `omega`
- Uppercase Greek: `Alpha` through `Omega`
- Subscripts: `sub0` through `sub9`
- Superscripts: `sup0` through `sup9`
- Math: `infinity`, `plusminus`, `sqrt`, `sum`, `integral`, `degree`, `times`, `divide`, `neq`, `leq`, `geq`

## Common Patterns

### Creating a Simple Chart

```lua
local svg = require("luaswift.svg")
local d = svg.create(400, 300, {background = "#ffffff"})

-- Data
local values = {40, 80, 60, 120, 90, 150, 70}
local barWidth = 40
local spacing = 10

-- Draw bars
for i, value in ipairs(values) do
    local x = (i - 1) * (barWidth + spacing) + 20
    local y = 280 - value
    d:rect(x, y, barWidth, value, {fill = "#3498db"})

    -- Label
    d:text(tostring(value), x + barWidth/2, y - 10, {
        ["text-anchor"] = "middle",
        ["font-size"] = "12"
    })
end

-- Axis
d:line(15, 280, 380, 280, {stroke = "black"})
d:line(15, 280, 15, 20, {stroke = "black"})

print(d:render())
```

### Animated Elements

```lua
local d = svg.create(200, 200)

-- Circle with animation attributes
d:circle(100, 100, 20, {
    fill = "red",
    id = "animated-circle"
})

-- Add animation via path
d:path("", {
    -- SVG animations are added as style attributes
})

-- Note: For complex animations, render() output can be
-- post-processed or templates can be used
```

### Method Chaining

```lua
local d = svg.create(400, 400, {background = "#f5f5f5"})
    :rect(10, 10, 100, 100, {fill = "blue"})
    :rect(120, 10, 100, 100, {fill = "green"})
    :circle(280, 60, 50, {fill = "red"})
    :text("Shapes", 200, 150, {["text-anchor"] = "middle"})

print(d:render())
```

### Exporting to File

```lua
local svg = require("luaswift.svg")
local d = svg.create(800, 600)

-- ... add shapes ...

local svgString = d:render()
-- Use io.open to write to file (requires IO permissions)
```

## See Also

- ``SVGModule``
- ``GeometryModule``
