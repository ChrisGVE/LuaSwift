# Plot Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.plot` | **Global:** `plot`

A matplotlib/seaborn-compatible plotting library that generates high-quality visualizations using retained-mode vector graphics. Plots can be exported to SVG, PNG, or PDF formats.

## Overview

The Plot module uses a retained vector graphics architecture where all drawing commands are stored in memory as scale-free vector operations. This enables:

- High-quality rendering at any resolution
- Export to multiple formats (SVG, PNG, PDF)
- Integration with Swift host applications
- matplotlib-compatible API for familiar workflow

## Quick Start

```lua
-- plot is available as a global after ModuleRegistry.installModules()

-- Create figure and axes
local fig, ax = plot.subplots()

-- Plot data
ax:plot({1, 2, 3, 4}, {1, 4, 2, 3}, {color='blue', linestyle='--', marker='o'})
ax:set_title("My First Plot")
ax:set_xlabel("X Axis")
ax:set_ylabel("Y Axis")
ax:grid({visible=true})

-- Export to file
fig:savefig("output.png", {dpi=150})
fig:savefig("output.svg")
```

## Figure and Axes

### Creating Figures

```lua
-- Create a single figure with one axes
local fig, ax = plot.subplots()

-- Create with specific size and DPI
local fig, ax = plot.subplots({figsize={8, 6}, dpi=100})

-- Create multiple subplots
local fig, axes = plot.subplots(2, 2)  -- 2x2 grid
```

### Figure Methods

```lua
-- Export to various formats
fig:savefig("plot.png", {dpi=150})
fig:savefig("plot.svg")
fig:savefig("plot.pdf")

-- Get raw output
local svg_string = fig:to_svg()
local png_data = fig:to_png({dpi=150})
local pdf_data = fig:to_pdf()

-- Access drawing context
local ctx = fig:get_context()
```

## Plot Types

### Line Plot

```lua
-- Basic line plot
ax:plot({1, 2, 3}, {2, 4, 3})

-- With formatting string (matplotlib-style)
ax:plot(x, y, "r--")  -- Red dashed line
ax:plot(x, y, "bo-")  -- Blue line with circle markers

-- With options table
ax:plot(x, y, {
    color = "blue",
    linestyle = "--",     -- "-", "--", "-.", ":"
    linewidth = 2,
    marker = "o",         -- "o", "s", "^", "v", "+", "x", "*", "."
    markersize = 6,
    label = "Series 1"
})
```

Format string components:
- **Color**: `r` (red), `g` (green), `b` (blue), `c` (cyan), `m` (magenta), `y` (yellow), `k` (black), `w` (white)
- **Line style**: `-` (solid), `--` (dashed), `:` (dotted), `-.` (dash-dot)
- **Marker**: `o` (circle), `s` (square), `^` (triangle up), `v` (triangle down), `+` (plus), `x` (cross), `*` (star), `.` (dot)

### Scatter Plot

```lua
ax:scatter(x, y, {
    s = 50,              -- Marker size
    c = "red",           -- Color or array of colors
    marker = "o",
    alpha = 0.7,
    edgecolors = "black",
    linewidths = 1
})
```

### Bar Chart

```lua
-- Vertical bars
ax:bar(x, heights, {
    width = 0.8,
    color = "blue",
    edgecolor = "black",
    alpha = 0.7
})

-- Horizontal bars (use barh if available, or transpose data)
```

### Histogram

```lua
ax:hist(data, {
    bins = 20,           -- Number of bins or array of bin edges
    color = "blue",
    edgecolor = "black",
    alpha = 0.7,
    density = false      -- If true, normalize to probability density
})
```

### Pie Chart

```lua
ax:pie(sizes, {
    labels = {"A", "B", "C"},
    colors = {"red", "green", "blue"},
    explode = {0, 0.1, 0},  -- Explode second slice
    autopct = "%.1f%%",     -- Percentage format
    startangle = 90
})
```

### Image Display

```lua
-- Display 2D array as image
ax:imshow(data, {
    cmap = "viridis",    -- "viridis", "plasma", "gray", etc.
    aspect = "auto",     -- "auto", "equal"
    interpolation = "nearest",
    vmin = 0,            -- Min value for colormap
    vmax = 100           -- Max value for colormap
})
```

### Error Bars

```lua
ax:errorbar(x, y, {
    yerr = y_errors,     -- Error bars in y direction
    xerr = x_errors,     -- Error bars in x direction
    fmt = "o-",          -- Format string
    ecolor = "red",      -- Error bar color
    elinewidth = 2,
    capsize = 5          -- Cap size at end of error bars
})
```

### Box Plot

```lua
ax:boxplot(data, {
    labels = {"Group 1", "Group 2"},
    vert = true,         -- Vertical boxes
    widths = 0.5,
    showmeans = true,
    showfliers = true
})
```

### Contour Plot

```lua
-- Contour lines
ax:contour(X, Y, Z, {
    levels = 10,         -- Number of contour levels
    colors = "black",
    linewidths = 1
})

-- Filled contours
ax:contourf(X, Y, Z, {
    levels = 20,
    cmap = "viridis",
    alpha = 0.8
})
```

## Statistical Plots (Seaborn-style)

The `plot.stat` namespace provides seaborn-compatible statistical visualizations.

### Histogram with KDE

```lua
plot.stat.histplot(ax, data, {
    bins = 30,
    kde = true,          -- Overlay kernel density estimate
    color = "blue",
    stat = "density"     -- "count", "frequency", "density", "probability"
})
```

### Kernel Density Plot

```lua
plot.stat.kdeplot(ax, data, {
    bandwidth = nil,     -- Auto-detect using Scott's rule
    color = "blue",
    fill = true,         -- Fill area under curve
    alpha = 0.5
})
```

### Rug Plot

```lua
plot.stat.rugplot(ax, data, {
    height = 0.05,
    color = "black",
    alpha = 0.5
})
```

### Violin Plot

```lua
plot.stat.violinplot(ax, data, {
    positions = {1, 2, 3},
    widths = 0.7,
    showmeans = true,
    showextrema = true
})
```

### Strip Plot

```lua
plot.stat.stripplot(ax, data, {
    jitter = 0.2,        -- Add horizontal jitter
    alpha = 0.5,
    color = "blue"
})
```

### Swarm Plot

```lua
plot.stat.swarmplot(ax, data, {
    size = 5,
    alpha = 0.7,
    color = "blue"
})
```

### Regression Plot

```lua
plot.stat.regplot(ax, x_data, y_data, {
    order = 1,           -- Polynomial order (1=linear)
    ci = 95,             -- Confidence interval
    scatter = true,      -- Show scatter points
    color = "blue"
})
```

### Heatmap

```lua
plot.stat.heatmap(ax, data, {
    cmap = "viridis",
    annot = true,        -- Annotate cells with values
    fmt = "%.2f",
    linewidths = 0.5,
    cbar = true          -- Show colorbar
})
```

## Customization

### Axis Configuration

```lua
-- Set axis limits
ax:set_xlim(0, 10)
ax:set_ylim(-5, 5)

-- Get current limits
local xlim = ax:get_xlim()  -- Returns {min, max}
local ylim = ax:get_ylim()

-- Set axis scale
ax:set_xscale("linear")      -- "linear", "log", "symlog"
ax:set_yscale("log")

-- Get current scale
local xscale = ax:get_xscale()

-- Symmetric log scale with linear threshold
ax:set_yscale("symlog", {linthresh=1})
```

### Labels and Titles

```lua
ax:set_title("Plot Title", {fontsize=16})
ax:set_xlabel("X Label", {fontsize=12})
ax:set_ylabel("Y Label", {fontsize=12})
```

### Grid

```lua
-- Enable grid
ax:grid({visible=true})

-- Customize grid
ax:grid({
    visible = true,
    which = "major",     -- "major", "minor", "both"
    axis = "both",       -- "x", "y", "both"
    color = "gray",
    linestyle = "--",
    linewidth = 0.5,
    alpha = 0.5
})
```

### Legend

```lua
-- Add legend (uses labels from plot calls)
ax:legend()

-- Customize legend
ax:legend({
    loc = "upper right",  -- "upper/lower left/right/center", "center"
    frameon = true,
    fancybox = true,
    shadow = false,
    ncol = 1,
    fontsize = 10
})
```

### Aspect Ratio

```lua
ax:set_aspect("equal")   -- Equal scaling
ax:set_aspect(1.5)       -- Custom aspect ratio
```

### Axis Visibility

```lua
ax:axis("off")           -- Hide axes
ax:axis("on")            -- Show axes
ax:axis("equal")         -- Equal aspect ratio
```

## Drawing Context API

For low-level drawing, you can access the DrawingContext directly:

```lua
local ctx = fig:get_context()

-- Path operations
ctx:move_to(x, y)
ctx:line_to(x, y)
ctx:curve_to(cp1x, cp1y, cp2x, cp2y, x, y)
ctx:close_path()

-- Shapes
ctx:rect(x, y, width, height)
ctx:circle(cx, cy, radius)
ctx:ellipse(cx, cy, rx, ry)

-- Text
ctx:text("Hello", x, y, {
    fontSize = 12,
    fontWeight = "bold",   -- "normal", "bold", "light"
    color = "black",
    anchor = "middle"      -- "start", "middle", "end"
})

-- Styling
ctx:set_stroke("blue", linewidth, linestyle)
ctx:set_fill("red")
ctx:set_alpha(0.5)

-- Drawing
ctx:stroke()
ctx:fill()

-- State management
ctx:save()
ctx:restore()

-- Convenience methods
ctx:line(x1, y1, x2, y2)
ctx:filled_rect(x, y, w, h, fill_color, stroke_color)
ctx:filled_circle(cx, cy, r, fill_color, stroke_color)
```

## Colors

Colors can be specified as:
- **Named colors**: `"red"`, `"blue"`, `"green"`, `"black"`, `"white"`, `"gray"`, `"orange"`, `"purple"`, etc.
- **Hex colors**: `"#FF0000"`, `"#00FF00"`, `"#0000FF"`
- **Single characters** (matplotlib): `"r"`, `"g"`, `"b"`, `"c"`, `"m"`, `"y"`, `"k"`, `"w"`

Available named colors:
`black`, `white`, `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`, `orange`, `purple`, `brown`, `pink`, `gray`, `lightgray`, `darkgray`

## Export Formats

### SVG (Vector)

```lua
fig:savefig("plot.svg")
local svg_string = fig:to_svg()
```

SVG files are vector graphics that scale infinitely without quality loss.

### PNG (Raster)

```lua
-- Export with custom DPI
fig:savefig("plot.png", {dpi=150})

-- Default is 72 DPI
fig:savefig("plot.png")

-- Get PNG data
local png_data = fig:to_png({dpi=300})
```

### PDF (Vector)

```lua
fig:savefig("plot.pdf")
local pdf_data = fig:to_pdf()
```

PDF files preserve vector quality and are suitable for publication.

## Complete Example

```lua
-- plot is available as a global after ModuleRegistry.installModules()

-- Create figure
local fig, ax = plot.subplots({figsize={10, 6}, dpi=100})

-- Generate sample data
local x = {}
local y1, y2 = {}, {}
for i = 1, 50 do
    x[i] = i / 10
    y1[i] = math.sin(x[i])
    y2[i] = math.cos(x[i])
end

-- Plot multiple series
ax:plot(x, y1, {
    color = "blue",
    linestyle = "-",
    linewidth = 2,
    marker = "o",
    markersize = 4,
    label = "sin(x)"
})

ax:plot(x, y2, {
    color = "red",
    linestyle = "--",
    linewidth = 2,
    marker = "s",
    markersize = 4,
    label = "cos(x)"
})

-- Customize plot
ax:set_title("Trigonometric Functions", {fontsize=16})
ax:set_xlabel("x", {fontsize=12})
ax:set_ylabel("y", {fontsize=12})
ax:set_xlim(0, 5)
ax:set_ylim(-1.5, 1.5)
ax:grid({visible=true, alpha=0.3})
ax:legend({loc="upper right"})

-- Export
fig:savefig("trig_plot.png", {dpi=150})
fig:savefig("trig_plot.svg")
```

## Function Reference

### Module Functions

| Function | Description |
|----------|-------------|
| `plot.subplots([nrows, ncols], [opts])` | Create figure with subplots grid |
| `plot.figure([opts])` | Create a new figure |
| `plot.create_context([width, height])` | Create raw drawing context |
| `plot.show()` | No-op in embedded context |
| `plot.ion()` | No-op in embedded context |
| `plot.ioff()` | No-op in embedded context |

### Figure Methods

| Method | Description |
|--------|-------------|
| `fig:savefig(path, [opts])` | Save figure to file (PNG/SVG/PDF) |
| `fig:to_svg()` | Return SVG string |
| `fig:to_png([opts])` | Return PNG binary data |
| `fig:to_pdf()` | Return PDF binary data |
| `fig:get_context()` | Get underlying DrawingContext |

### Axes Methods - Plotting

| Method | Description |
|--------|-------------|
| `ax:plot(x, y, [fmt_or_opts], [opts])` | Line plot |
| `ax:scatter(x, y, [opts])` | Scatter plot |
| `ax:bar(x, height, [opts])` | Bar chart |
| `ax:hist(data, [opts])` | Histogram |
| `ax:pie(sizes, [opts])` | Pie chart |
| `ax:imshow(data, [opts])` | Display 2D array as image |
| `ax:errorbar(x, y, [opts])` | Error bar plot |
| `ax:boxplot(data, [opts])` | Box plot |
| `ax:contour(X, Y, Z, [opts])` | Contour lines |
| `ax:contourf(X, Y, Z, [opts])` | Filled contours |

### Axes Methods - Customization

| Method | Description |
|--------|-------------|
| `ax:set_title(title, [opts])` | Set plot title |
| `ax:set_xlabel(label, [opts])` | Set x-axis label |
| `ax:set_ylabel(label, [opts])` | Set y-axis label |
| `ax:set_xlim(left, right)` | Set x-axis limits |
| `ax:set_ylim(bottom, top)` | Set y-axis limits |
| `ax:get_xlim()` | Get x-axis limits |
| `ax:get_ylim()` | Get y-axis limits |
| `ax:set_xscale(scale, [opts])` | Set x-axis scale (linear/log/symlog) |
| `ax:set_yscale(scale, [opts])` | Set y-axis scale |
| `ax:get_xscale()` | Get x-axis scale |
| `ax:get_yscale()` | Get y-axis scale |
| `ax:set_aspect(aspect)` | Set aspect ratio |
| `ax:axis(arg)` | Control axis visibility ("on"/"off"/"equal") |
| `ax:grid([opts])` | Configure grid |
| `ax:legend([opts])` | Add legend |
| `ax:get_context()` | Get underlying DrawingContext |

### Statistical Plots (plot.stat)

| Function | Description |
|----------|-------------|
| `stat.histplot(ax, data, [opts])` | Enhanced histogram with KDE |
| `stat.kdeplot(ax, data, [opts])` | Kernel density estimate |
| `stat.rugplot(ax, data, [opts])` | Rug plot (1D scatter) |
| `stat.violinplot(ax, data, [opts])` | Violin plot |
| `stat.stripplot(ax, data, [opts])` | Strip plot with jitter |
| `stat.swarmplot(ax, data, [opts])` | Categorical scatter (swarm) |
| `stat.regplot(ax, x, y, [opts])` | Regression plot with fit line |
| `stat.heatmap(ax, data, [opts])` | Heatmap with annotations |
| `stat.catplot(data, [opts])` | Categorical plot |
| `stat.lmplot(data, [opts])` | Linear model plot |
| `stat.clustermap(data, [opts])` | Clustered heatmap |

### DrawingContext Methods

| Method | Description |
|--------|-------------|
| `ctx:move_to(x, y)` | Move to point without drawing |
| `ctx:line_to(x, y)` | Draw line to point |
| `ctx:curve_to(cp1x, cp1y, cp2x, cp2y, x, y)` | Cubic Bezier curve |
| `ctx:close_path()` | Close current path |
| `ctx:rect(x, y, w, h)` | Add rectangle to path |
| `ctx:circle(cx, cy, r)` | Add circle to path |
| `ctx:ellipse(cx, cy, rx, ry)` | Add ellipse to path |
| `ctx:text(str, x, y, [style])` | Draw text |
| `ctx:set_stroke(color, [width], [style])` | Set stroke style |
| `ctx:set_fill(color)` | Set fill color |
| `ctx:set_alpha(alpha)` | Set transparency (0-1) |
| `ctx:stroke()` | Stroke current path |
| `ctx:fill()` | Fill current path |
| `ctx:save()` | Save graphics state |
| `ctx:restore()` | Restore graphics state |
| `ctx:clear()` | Clear all commands |
| `ctx:command_count()` | Get number of drawing commands |
| `ctx:line(x1, y1, x2, y2)` | Draw line (convenience) |
| `ctx:filled_rect(x, y, w, h, fill, [stroke])` | Draw filled rectangle |
| `ctx:filled_circle(cx, cy, r, fill, [stroke])` | Draw filled circle |

## Notes

- All coordinates use a bottom-left origin with y-axis pointing up (mathematical convention)
- Colors, line styles, and markers follow matplotlib conventions for compatibility
- Drawing operations are retained in memory as vector commands, enabling export at any resolution
- The module is designed for embedded use in Swift applications with no GUI dependency
