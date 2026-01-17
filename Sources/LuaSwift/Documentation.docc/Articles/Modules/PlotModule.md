# Plot Module

Matplotlib-inspired plotting with retained-mode API and SVG output.

## Overview

The Plot module provides a matplotlib-compatible plotting interface for creating publication-quality figures. It uses a retained-mode API where you build a figure structure and then render it to SVG.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the Plot module
ModuleRegistry.installPlotModule(in: engine)
```

## Basic Usage

```lua
-- Create a figure
local fig = plot.figure()

-- Add a subplot (1 row, 1 column, index 1)
local ax = fig:subplot(1, 1, 1)

-- Plot data
ax:plot({1, 2, 3, 4}, {1, 4, 9, 16})

-- Render to SVG
local svg = fig:render()
```

## API Reference

### Figure Creation

#### plot.figure(width?, height?)
Creates a new figure with optional dimensions in pixels.

```lua
local fig = plot.figure()           -- Default size
local fig = plot.figure(800, 600)   -- 800x600 pixels
```

### Subplots

#### fig:subplot(rows, cols, index)
Adds a subplot to the figure. Returns an axes object.

```lua
-- Single plot
local ax = fig:subplot(1, 1, 1)

-- 2x2 grid of subplots
local ax1 = fig:subplot(2, 2, 1)  -- Top-left
local ax2 = fig:subplot(2, 2, 2)  -- Top-right
local ax3 = fig:subplot(2, 2, 3)  -- Bottom-left
local ax4 = fig:subplot(2, 2, 4)  -- Bottom-right
```

### Plotting Functions

#### ax:plot(x, y, options?)
Plot y versus x as lines and/or markers.

```lua
-- Simple line plot
ax:plot({1, 2, 3}, {1, 4, 9})

-- With options
ax:plot({1, 2, 3}, {1, 4, 9}, {
    color = "red",
    linewidth = 2,
    marker = "o",
    label = "Data"
})
```

#### ax:scatter(x, y, options?)
Scatter plot of y versus x.

```lua
ax:scatter({1, 2, 3, 4}, {1, 4, 2, 3}, {
    color = "blue",
    size = 50,
    marker = "o",
    label = "Points"
})
```

#### ax:bar(x, heights, options?)
Create a bar chart.

```lua
ax:bar({1, 2, 3}, {5, 7, 3}, {
    color = "green",
    width = 0.8
})
```

#### ax:hist(data, bins?, options?)
Compute and plot a histogram.

```lua
local data = {/* random samples */}
ax:hist(data, 20, {
    color = "orange",
    alpha = 0.7
})
```

### Styling Options

Common options for plot functions:

| Option | Type | Description |
|--------|------|-------------|
| `color` | string | Color name or hex code |
| `linewidth` | number | Line width in pixels |
| `linestyle` | string | "-", "--", "-.", ":" |
| `marker` | string | "o", "s", "^", "v", "x", "+" |
| `markersize` | number | Marker size |
| `label` | string | Legend label |
| `alpha` | number | Transparency (0-1) |

### Labels and Titles

#### ax:set_title(title)
Set the axes title.

```lua
ax:set_title("My Plot")
```

#### ax:set_xlabel(label)
Set the x-axis label.

```lua
ax:set_xlabel("Time (s)")
```

#### ax:set_ylabel(label)
Set the y-axis label.

```lua
ax:set_ylabel("Amplitude")
```

### Limits and Scaling

#### ax:set_xlim(min, max)
Set x-axis limits.

```lua
ax:set_xlim(0, 10)
```

#### ax:set_ylim(min, max)
Set y-axis limits.

```lua
ax:set_ylim(-1, 1)
```

### Legend

#### ax:legend(options?)
Add a legend to the plot.

```lua
ax:legend()

-- With options
ax:legend({
    loc = "upper right",
    frameon = true
})
```

### Grid

#### ax:grid(visible?, options?)
Configure grid visibility.

```lua
ax:grid(true)
ax:grid(true, {alpha = 0.3, linestyle = "--"})
```

### Rendering

#### fig:render()
Render the figure to SVG string.

```lua
local svg_string = fig:render()
```

## Complete Example

```lua
local plot = require("luaswift.plot")

-- Create figure
local fig = plot.figure(800, 600)
local ax = fig:subplot(1, 1, 1)

-- Generate data
local x = {}
local y1 = {}
local y2 = {}
for i = 0, 100 do
    local t = i * 0.1
    x[i+1] = t
    y1[i+1] = math.sin(t)
    y2[i+1] = math.cos(t)
end

-- Plot multiple series
ax:plot(x, y1, {color = "blue", label = "sin(x)"})
ax:plot(x, y2, {color = "red", label = "cos(x)", linestyle = "--"})

-- Styling
ax:set_title("Trigonometric Functions")
ax:set_xlabel("x")
ax:set_ylabel("y")
ax:legend()
ax:grid(true)

-- Render
local svg = fig:render()

-- Save to file (if iox module is installed)
local io = require("luaswift.iox")
io.write_file("plot.svg", svg)
```

## Multiple Subplots Example

```lua
local fig = plot.figure(1200, 800)

-- Top-left: Line plot
local ax1 = fig:subplot(2, 2, 1)
ax1:plot({1, 2, 3, 4}, {1, 4, 9, 16})
ax1:set_title("Line Plot")

-- Top-right: Scatter
local ax2 = fig:subplot(2, 2, 2)
ax2:scatter({1, 2, 3, 4}, {2, 3, 1, 4})
ax2:set_title("Scatter Plot")

-- Bottom-left: Bar chart
local ax3 = fig:subplot(2, 2, 3)
ax3:bar({1, 2, 3}, {5, 7, 3})
ax3:set_title("Bar Chart")

-- Bottom-right: Histogram
local ax4 = fig:subplot(2, 2, 4)
local data = {}
for i = 1, 1000 do
    data[i] = math.random() + math.random() + math.random()
end
ax4:hist(data, 30)
ax4:set_title("Histogram")

local svg = fig:render()
```

## Performance Notes

- The plotting API builds an in-memory representation before rendering
- SVG output is suitable for web display or further processing
- For large datasets (>10,000 points), consider downsampling

## See Also

- ``PlotModule``
- ``SVGModule``
- ``ArrayModule``
