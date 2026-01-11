# Plot Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.plot` | **Global:** `plot`

A matplotlib/seaborn-compatible plotting library that generates high-quality visualizations using retained-mode vector graphics. Plots can be exported to SVG, PNG, or PDF formats.

The Plot module uses a retained vector graphics architecture where all drawing commands are stored in memory as scale-free vector operations. This enables high-quality rendering at any resolution, export to multiple formats, integration with Swift host applications, and a matplotlib-compatible API for familiar workflow.

## Function Reference

### Module Functions

| Function | Description |
|----------|-------------|
| [subplots(nrows?, ncols?, opts?)](#subplots) | Create figure with subplots grid |
| [figure(opts?)](#figure) | Create a new figure |
| [create_context(width?, height?)](#create_context) | Create raw drawing context |
| [show()](#show) | No-op in embedded context |
| [ion()](#ion) | No-op in embedded context |
| [ioff()](#ioff) | No-op in embedded context |

### Figure Methods

| Method | Description |
|--------|-------------|
| [savefig(path, opts?)](#savefig) | Save figure to file (PNG/SVG/PDF) |
| [to_svg()](#to_svg) | Return SVG string |
| [to_png(opts?)](#to_png) | Return PNG binary data |
| [to_pdf()](#to_pdf) | Return PDF binary data |
| [get_context()](#get_context) | Get underlying DrawingContext |

### Axes Methods - Plotting

| Method | Description |
|--------|-------------|
| [plot(x, y, fmt_or_opts?, opts?)](#plot) | Line plot |
| [scatter(x, y, opts?)](#scatter) | Scatter plot |
| [bar(x, height, opts?)](#bar) | Bar chart |
| [hist(data, opts?)](#hist) | Histogram |
| [pie(sizes, opts?)](#pie) | Pie chart |
| [imshow(data, opts?)](#imshow) | Display 2D array as image |
| [errorbar(x, y, opts?)](#errorbar) | Error bar plot |
| [boxplot(data, opts?)](#boxplot) | Box plot |
| [contour(X, Y, Z, opts?)](#contour) | Contour lines |
| [contourf(X, Y, Z, opts?)](#contourf) | Filled contours |

### Axes Methods - Customization

| Method | Description |
|--------|-------------|
| [set_title(title, opts?)](#set_title) | Set plot title |
| [set_xlabel(label, opts?)](#set_xlabel) | Set x-axis label |
| [set_ylabel(label, opts?)](#set_ylabel) | Set y-axis label |
| [set_xlim(left, right)](#set_xlim) | Set x-axis limits |
| [set_ylim(bottom, top)](#set_ylim) | Set y-axis limits |
| [get_xlim()](#get_xlim) | Get x-axis limits |
| [get_ylim()](#get_ylim) | Get y-axis limits |
| [set_xscale(scale, opts?)](#set_xscale) | Set x-axis scale (linear/log/symlog) |
| [set_yscale(scale, opts?)](#set_yscale) | Set y-axis scale |
| [get_xscale()](#get_xscale) | Get x-axis scale |
| [get_yscale()](#get_yscale) | Get y-axis scale |
| [set_aspect(aspect)](#set_aspect) | Set aspect ratio |
| [axis(arg)](#axis) | Control axis visibility ("on"/"off"/"equal") |
| [grid(opts?)](#grid) | Configure grid |
| [legend(opts?)](#legend) | Add legend |

### Statistical Plots (plot.stat)

| Function | Description |
|----------|-------------|
| [histplot(ax, data, opts?)](#histplot) | Enhanced histogram with KDE |
| [kdeplot(ax, data, opts?)](#kdeplot) | Kernel density estimate |
| [rugplot(ax, data, opts?)](#rugplot) | Rug plot (1D scatter) |
| [violinplot(ax, data, opts?)](#violinplot) | Violin plot |
| [stripplot(ax, data, opts?)](#stripplot) | Strip plot with jitter |
| [swarmplot(ax, data, opts?)](#swarmplot) | Categorical scatter (swarm) |
| [regplot(ax, x, y, opts?)](#regplot) | Regression plot with fit line |
| [heatmap(ax, data, opts?)](#heatmap) | Heatmap with annotations |
| [catplot(data, opts?)](#catplot) | Categorical plot |
| [lmplot(data, opts?)](#lmplot) | Linear model plot |
| [clustermap(data, opts?)](#clustermap) | Clustered heatmap |

### DrawingContext Methods

| Method | Description |
|--------|-------------|
| [move_to(x, y)](#move_to) | Move to point without drawing |
| [line_to(x, y)](#line_to) | Draw line to point |
| [curve_to(cp1x, cp1y, cp2x, cp2y, x, y)](#curve_to) | Cubic Bezier curve |
| [close_path()](#close_path) | Close current path |
| [rect(x, y, w, h)](#rect) | Add rectangle to path |
| [circle(cx, cy, r)](#circle) | Add circle to path |
| [ellipse(cx, cy, rx, ry)](#ellipse) | Add ellipse to path |
| [text(str, x, y, style?)](#text) | Draw text |
| [set_stroke(color, width?, style?)](#set_stroke) | Set stroke style |
| [set_fill(color)](#set_fill) | Set fill color |
| [set_alpha(alpha)](#set_alpha) | Set transparency (0-1) |
| [stroke()](#stroke) | Stroke current path |
| [fill()](#fill) | Fill current path |
| [save()](#save) | Save graphics state |
| [restore()](#restore) | Restore graphics state |
| [clear()](#clear) | Clear all commands |
| [command_count()](#command_count) | Get number of drawing commands |
| [line(x1, y1, x2, y2)](#line) | Draw line (convenience) |
| [filled_rect(x, y, w, h, fill, stroke?)](#filled_rect) | Draw filled rectangle |
| [filled_circle(cx, cy, r, fill, stroke?)](#filled_circle) | Draw filled circle |

---

## subplots

```
plot.subplots(nrows?, ncols?, opts?) -> figure, axes
```

Create a figure with a grid of subplots.

**Parameters:**
- `nrows` (optional) - Number of subplot rows (default: 1)
- `ncols` (optional) - Number of subplot columns (default: 1)
- `opts` (optional) - Table with options:
  - `figsize` (array): Figure size as `{width, height}` in inches
  - `dpi` (number): Dots per inch for rendering

```lua
-- Single subplot
local fig, ax = plot.subplots()

-- With specific size
local fig, ax = plot.subplots({figsize={8, 6}, dpi=100})

-- Multiple subplots
local fig, axes = plot.subplots(2, 2)  -- 2x2 grid
```

---

## figure

```
plot.figure(opts?) -> figure
```

Create a new figure without axes.

**Parameters:**
- `opts` (optional) - Table with options:
  - `figsize` (array): Figure size as `{width, height}` in inches
  - `dpi` (number): Dots per inch for rendering

```lua
local fig = plot.figure({figsize={10, 8}})
```

---

## create_context

```
plot.create_context(width?, height?) -> context
```

Create a raw drawing context for low-level drawing operations.

**Parameters:**
- `width` (optional) - Context width in pixels
- `height` (optional) - Context height in pixels

```lua
local ctx = plot.create_context(800, 600)
```

---

## show

```
plot.show()
```

No-op in embedded context (included for matplotlib compatibility).

---

## ion

```
plot.ion()
```

No-op in embedded context (included for matplotlib compatibility).

---

## ioff

```
plot.ioff()
```

No-op in embedded context (included for matplotlib compatibility).

---

## savefig

```
fig:savefig(path, opts?)
```

Save figure to file. Format is determined by file extension (`.png`, `.svg`, `.pdf`).

**Parameters:**
- `path` - Output file path
- `opts` (optional) - Table with options:
  - `dpi` (number): Dots per inch for PNG output (default: 72)

```lua
fig:savefig("plot.png", {dpi=150})
fig:savefig("plot.svg")
fig:savefig("plot.pdf")
```

---

## to_svg

```
fig:to_svg() -> string
```

Return the figure as an SVG string.

```lua
local svg_string = fig:to_svg()
```

---

## to_png

```
fig:to_png(opts?) -> binary_data
```

Return the figure as PNG binary data.

**Parameters:**
- `opts` (optional) - Table with options:
  - `dpi` (number): Dots per inch (default: 72)

```lua
local png_data = fig:to_png({dpi=300})
```

---

## to_pdf

```
fig:to_pdf() -> binary_data
```

Return the figure as PDF binary data.

```lua
local pdf_data = fig:to_pdf()
```

---

## get_context

```
fig:get_context() -> context
```

Get the underlying DrawingContext for low-level drawing operations.

```lua
local ctx = fig:get_context()
ctx:circle(100, 100, 50)
ctx:fill()
```

---

## plot

```
ax:plot(x, y, fmt_or_opts?, opts?)
```

Create a line plot.

**Parameters:**
- `x` - Array of x coordinates
- `y` - Array of y coordinates
- `fmt_or_opts` (optional) - Format string (matplotlib-style) or options table
- `opts` (optional) - Options table (if `fmt_or_opts` is a format string)

**Options:**
- `color` - Line color (named color, hex, or single character)
- `linestyle` - Line style: `"-"`, `"--"`, `"-."`, `":"`
- `linewidth` - Line width in points
- `marker` - Marker style: `"o"`, `"s"`, `"^"`, `"v"`, `"+"`, `"x"`, `"*"`, `"."`
- `markersize` - Marker size in points
- `label` - Label for legend

**Format string components:**
- **Color**: `r`, `g`, `b`, `c`, `m`, `y`, `k`, `w`
- **Line style**: `-`, `--`, `:`, `-.`
- **Marker**: `o`, `s`, `^`, `v`, `+`, `x`, `*`, `.`

```lua
-- Basic line plot
ax:plot({1, 2, 3}, {2, 4, 3})

-- With format string
ax:plot(x, y, "r--")  -- Red dashed line
ax:plot(x, y, "bo-")  -- Blue line with circle markers

-- With options
ax:plot(x, y, {
    color = "blue",
    linestyle = "--",
    linewidth = 2,
    marker = "o",
    markersize = 6,
    label = "Series 1"
})
```

---

## scatter

```
ax:scatter(x, y, opts?)
```

Create a scatter plot.

**Parameters:**
- `x` - Array of x coordinates
- `y` - Array of y coordinates
- `opts` (optional) - Options table:
  - `s` - Marker size
  - `c` - Color or array of colors
  - `marker` - Marker style
  - `alpha` - Transparency (0-1)
  - `edgecolors` - Edge color
  - `linewidths` - Edge line width

```lua
ax:scatter(x, y, {
    s = 50,
    c = "red",
    marker = "o",
    alpha = 0.7,
    edgecolors = "black",
    linewidths = 1
})
```

---

## bar

```
ax:bar(x, height, opts?)
```

Create a vertical bar chart.

**Parameters:**
- `x` - Array of x positions
- `height` - Array of bar heights
- `opts` (optional) - Options table:
  - `width` - Bar width (default: 0.8)
  - `color` - Bar fill color
  - `edgecolor` - Bar edge color
  - `alpha` - Transparency (0-1)

```lua
ax:bar(x, heights, {
    width = 0.8,
    color = "blue",
    edgecolor = "black",
    alpha = 0.7
})
```

---

## hist

```
ax:hist(data, opts?)
```

Create a histogram.

**Parameters:**
- `data` - Array of values
- `opts` (optional) - Options table:
  - `bins` - Number of bins or array of bin edges
  - `color` - Bar fill color
  - `edgecolor` - Bar edge color
  - `alpha` - Transparency (0-1)
  - `density` - If true, normalize to probability density

```lua
ax:hist(data, {
    bins = 20,
    color = "blue",
    edgecolor = "black",
    alpha = 0.7,
    density = false
})
```

---

## pie

```
ax:pie(sizes, opts?)
```

Create a pie chart.

**Parameters:**
- `sizes` - Array of slice sizes
- `opts` (optional) - Options table:
  - `labels` - Array of slice labels
  - `colors` - Array of slice colors
  - `explode` - Array of explosion distances
  - `autopct` - Format string for percentages
  - `startangle` - Starting angle in degrees

```lua
ax:pie(sizes, {
    labels = {"A", "B", "C"},
    colors = {"red", "green", "blue"},
    explode = {0, 0.1, 0},
    autopct = "%.1f%%",
    startangle = 90
})
```

---

## imshow

```
ax:imshow(data, opts?)
```

Display a 2D array as an image.

**Parameters:**
- `data` - 2D array of values
- `opts` (optional) - Options table:
  - `cmap` - Colormap name: `"viridis"`, `"plasma"`, `"gray"`, etc.
  - `aspect` - Aspect ratio: `"auto"`, `"equal"`
  - `interpolation` - Interpolation method: `"nearest"`
  - `vmin` - Minimum value for colormap
  - `vmax` - Maximum value for colormap

```lua
ax:imshow(data, {
    cmap = "viridis",
    aspect = "auto",
    interpolation = "nearest",
    vmin = 0,
    vmax = 100
})
```

---

## errorbar

```
ax:errorbar(x, y, opts?)
```

Create a plot with error bars.

**Parameters:**
- `x` - Array of x coordinates
- `y` - Array of y coordinates
- `opts` (optional) - Options table:
  - `yerr` - Y error values (symmetric or {lower, upper})
  - `xerr` - X error values (symmetric or {lower, upper})
  - `fmt` - Format string
  - `ecolor` - Error bar color
  - `elinewidth` - Error bar line width
  - `capsize` - Cap size at end of error bars

```lua
ax:errorbar(x, y, {
    yerr = y_errors,
    xerr = x_errors,
    fmt = "o-",
    ecolor = "red",
    elinewidth = 2,
    capsize = 5
})
```

---

## boxplot

```
ax:boxplot(data, opts?)
```

Create a box plot.

**Parameters:**
- `data` - Array or array of arrays
- `opts` (optional) - Options table:
  - `labels` - Array of group labels
  - `vert` - Vertical boxes (default: true)
  - `widths` - Box width
  - `showmeans` - Show mean markers
  - `showfliers` - Show outliers

```lua
ax:boxplot(data, {
    labels = {"Group 1", "Group 2"},
    vert = true,
    widths = 0.5,
    showmeans = true,
    showfliers = true
})
```

---

## contour

```
ax:contour(X, Y, Z, opts?)
```

Create contour lines.

**Parameters:**
- `X` - 2D array of x coordinates
- `Y` - 2D array of y coordinates
- `Z` - 2D array of z values
- `opts` (optional) - Options table:
  - `levels` - Number of contour levels
  - `colors` - Line colors
  - `linewidths` - Line widths

```lua
ax:contour(X, Y, Z, {
    levels = 10,
    colors = "black",
    linewidths = 1
})
```

---

## contourf

```
ax:contourf(X, Y, Z, opts?)
```

Create filled contours.

**Parameters:**
- `X` - 2D array of x coordinates
- `Y` - 2D array of y coordinates
- `Z` - 2D array of z values
- `opts` (optional) - Options table:
  - `levels` - Number of contour levels
  - `cmap` - Colormap name
  - `alpha` - Transparency (0-1)

```lua
ax:contourf(X, Y, Z, {
    levels = 20,
    cmap = "viridis",
    alpha = 0.8
})
```

---

## set_title

```
ax:set_title(title, opts?)
```

Set the plot title.

**Parameters:**
- `title` - Title text
- `opts` (optional) - Options table:
  - `fontsize` - Font size in points

```lua
ax:set_title("Plot Title", {fontsize=16})
```

---

## set_xlabel

```
ax:set_xlabel(label, opts?)
```

Set the x-axis label.

**Parameters:**
- `label` - Label text
- `opts` (optional) - Options table:
  - `fontsize` - Font size in points

```lua
ax:set_xlabel("X Label", {fontsize=12})
```

---

## set_ylabel

```
ax:set_ylabel(label, opts?)
```

Set the y-axis label.

**Parameters:**
- `label` - Label text
- `opts` (optional) - Options table:
  - `fontsize` - Font size in points

```lua
ax:set_ylabel("Y Label", {fontsize=12})
```

---

## set_xlim

```
ax:set_xlim(left, right)
```

Set x-axis limits.

**Parameters:**
- `left` - Minimum x value
- `right` - Maximum x value

```lua
ax:set_xlim(0, 10)
```

---

## set_ylim

```
ax:set_ylim(bottom, top)
```

Set y-axis limits.

**Parameters:**
- `bottom` - Minimum y value
- `top` - Maximum y value

```lua
ax:set_ylim(-5, 5)
```

---

## get_xlim

```
ax:get_xlim() -> {min, max}
```

Get current x-axis limits.

```lua
local xlim = ax:get_xlim()
print(xlim[1], xlim[2])  -- min, max
```

---

## get_ylim

```
ax:get_ylim() -> {min, max}
```

Get current y-axis limits.

```lua
local ylim = ax:get_ylim()
print(ylim[1], ylim[2])  -- min, max
```

---

## set_xscale

```
ax:set_xscale(scale, opts?)
```

Set x-axis scale type.

**Parameters:**
- `scale` - Scale type: `"linear"`, `"log"`, `"symlog"`
- `opts` (optional) - Options table:
  - `linthresh` - Linear threshold for symlog scale

```lua
ax:set_xscale("linear")
ax:set_xscale("log")
ax:set_xscale("symlog", {linthresh=1})
```

---

## set_yscale

```
ax:set_yscale(scale, opts?)
```

Set y-axis scale type.

**Parameters:**
- `scale` - Scale type: `"linear"`, `"log"`, `"symlog"`
- `opts` (optional) - Options table:
  - `linthresh` - Linear threshold for symlog scale

```lua
ax:set_yscale("log")
```

---

## get_xscale

```
ax:get_xscale() -> string
```

Get current x-axis scale type.

```lua
local xscale = ax:get_xscale()
```

---

## get_yscale

```
ax:get_yscale() -> string
```

Get current y-axis scale type.

```lua
local yscale = ax:get_yscale()
```

---

## set_aspect

```
ax:set_aspect(aspect)
```

Set aspect ratio.

**Parameters:**
- `aspect` - Aspect ratio: `"equal"`, `"auto"`, or numeric ratio

```lua
ax:set_aspect("equal")
ax:set_aspect(1.5)
```

---

## axis

```
ax:axis(arg)
```

Control axis visibility and aspect.

**Parameters:**
- `arg` - Axis mode: `"on"`, `"off"`, `"equal"`

```lua
ax:axis("off")    -- Hide axes
ax:axis("on")     -- Show axes
ax:axis("equal")  -- Equal aspect ratio
```

---

## grid

```
ax:grid(opts?)
```

Configure grid display.

**Parameters:**
- `opts` (optional) - Options table:
  - `visible` - Show grid (boolean)
  - `which` - Grid lines: `"major"`, `"minor"`, `"both"`
  - `axis` - Which axis: `"x"`, `"y"`, `"both"`
  - `color` - Grid color
  - `linestyle` - Line style
  - `linewidth` - Line width
  - `alpha` - Transparency (0-1)

```lua
-- Enable grid
ax:grid({visible=true})

-- Customize grid
ax:grid({
    visible = true,
    which = "major",
    axis = "both",
    color = "gray",
    linestyle = "--",
    linewidth = 0.5,
    alpha = 0.5
})
```

---

## legend

```
ax:legend(opts?)
```

Add a legend using labels from plot calls.

**Parameters:**
- `opts` (optional) - Options table:
  - `loc` - Location: `"upper left"`, `"upper right"`, `"lower left"`, `"lower right"`, `"center"`
  - `frameon` - Show frame (boolean)
  - `fancybox` - Rounded corners (boolean)
  - `shadow` - Drop shadow (boolean)
  - `ncol` - Number of columns
  - `fontsize` - Font size

```lua
ax:legend()

ax:legend({
    loc = "upper right",
    frameon = true,
    fancybox = true,
    shadow = false,
    ncol = 1,
    fontsize = 10
})
```

---

## histplot

```
plot.stat.histplot(ax, data, opts?)
```

Enhanced histogram with optional kernel density estimate.

**Parameters:**
- `ax` - Axes object
- `data` - Array of values
- `opts` (optional) - Options table:
  - `bins` - Number of bins
  - `kde` - Overlay KDE (boolean)
  - `color` - Bar color
  - `stat` - Statistic: `"count"`, `"frequency"`, `"density"`, `"probability"`

```lua
plot.stat.histplot(ax, data, {
    bins = 30,
    kde = true,
    color = "blue",
    stat = "density"
})
```

---

## kdeplot

```
plot.stat.kdeplot(ax, data, opts?)
```

Kernel density estimate plot.

**Parameters:**
- `ax` - Axes object
- `data` - Array of values
- `opts` (optional) - Options table:
  - `bandwidth` - KDE bandwidth (nil for auto)
  - `color` - Line color
  - `fill` - Fill area under curve (boolean)
  - `alpha` - Transparency (0-1)

```lua
plot.stat.kdeplot(ax, data, {
    bandwidth = nil,
    color = "blue",
    fill = true,
    alpha = 0.5
})
```

---

## rugplot

```
plot.stat.rugplot(ax, data, opts?)
```

Rug plot showing individual data points as vertical lines.

**Parameters:**
- `ax` - Axes object
- `data` - Array of values
- `opts` (optional) - Options table:
  - `height` - Line height as fraction of plot
  - `color` - Line color
  - `alpha` - Transparency (0-1)

```lua
plot.stat.rugplot(ax, data, {
    height = 0.05,
    color = "black",
    alpha = 0.5
})
```

---

## violinplot

```
plot.stat.violinplot(ax, data, opts?)
```

Violin plot combining box plot with kernel density.

**Parameters:**
- `ax` - Axes object
- `data` - Array or array of arrays
- `opts` (optional) - Options table:
  - `positions` - X positions for violins
  - `widths` - Violin widths
  - `showmeans` - Show mean markers (boolean)
  - `showextrema` - Show min/max markers (boolean)

```lua
plot.stat.violinplot(ax, data, {
    positions = {1, 2, 3},
    widths = 0.7,
    showmeans = true,
    showextrema = true
})
```

---

## stripplot

```
plot.stat.stripplot(ax, data, opts?)
```

Categorical scatter plot with optional jitter.

**Parameters:**
- `ax` - Axes object
- `data` - Array or array of arrays
- `opts` (optional) - Options table:
  - `jitter` - Horizontal jitter amount
  - `alpha` - Transparency (0-1)
  - `color` - Point color

```lua
plot.stat.stripplot(ax, data, {
    jitter = 0.2,
    alpha = 0.5,
    color = "blue"
})
```

---

## swarmplot

```
plot.stat.swarmplot(ax, data, opts?)
```

Categorical scatter plot with non-overlapping points.

**Parameters:**
- `ax` - Axes object
- `data` - Array or array of arrays
- `opts` (optional) - Options table:
  - `size` - Point size
  - `alpha` - Transparency (0-1)
  - `color` - Point color

```lua
plot.stat.swarmplot(ax, data, {
    size = 5,
    alpha = 0.7,
    color = "blue"
})
```

---

## regplot

```
plot.stat.regplot(ax, x_data, y_data, opts?)
```

Regression plot with fitted line and optional confidence interval.

**Parameters:**
- `ax` - Axes object
- `x_data` - Array of x values
- `y_data` - Array of y values
- `opts` (optional) - Options table:
  - `order` - Polynomial order (1 for linear)
  - `ci` - Confidence interval percentage
  - `scatter` - Show scatter points (boolean)
  - `color` - Plot color

```lua
plot.stat.regplot(ax, x_data, y_data, {
    order = 1,
    ci = 95,
    scatter = true,
    color = "blue"
})
```

---

## heatmap

```
plot.stat.heatmap(ax, data, opts?)
```

Heatmap with optional cell annotations.

**Parameters:**
- `ax` - Axes object
- `data` - 2D array of values
- `opts` (optional) - Options table:
  - `cmap` - Colormap name
  - `annot` - Annotate cells with values (boolean)
  - `fmt` - Value format string
  - `linewidths` - Cell border width
  - `cbar` - Show colorbar (boolean)

```lua
plot.stat.heatmap(ax, data, {
    cmap = "viridis",
    annot = true,
    fmt = "%.2f",
    linewidths = 0.5,
    cbar = true
})
```

---

## catplot

```
plot.stat.catplot(data, opts?)
```

Categorical plot (placeholder for future implementation).

---

## lmplot

```
plot.stat.lmplot(data, opts?)
```

Linear model plot (placeholder for future implementation).

---

## clustermap

```
plot.stat.clustermap(data, opts?)
```

Clustered heatmap (placeholder for future implementation).

---

## move_to

```
ctx:move_to(x, y)
```

Move to a point without drawing.

**Parameters:**
- `x` - X coordinate
- `y` - Y coordinate

```lua
ctx:move_to(100, 100)
```

---

## line_to

```
ctx:line_to(x, y)
```

Draw a line from current position to the specified point.

**Parameters:**
- `x` - X coordinate
- `y` - Y coordinate

```lua
ctx:move_to(0, 0)
ctx:line_to(100, 100)
ctx:stroke()
```

---

## curve_to

```
ctx:curve_to(cp1x, cp1y, cp2x, cp2y, x, y)
```

Draw a cubic Bezier curve.

**Parameters:**
- `cp1x`, `cp1y` - First control point
- `cp2x`, `cp2y` - Second control point
- `x`, `y` - End point

```lua
ctx:move_to(0, 0)
ctx:curve_to(50, 100, 100, 100, 150, 0)
ctx:stroke()
```

---

## close_path

```
ctx:close_path()
```

Close the current path by drawing a line to the starting point.

```lua
ctx:move_to(0, 0)
ctx:line_to(100, 0)
ctx:line_to(100, 100)
ctx:close_path()
ctx:stroke()
```

---

## rect

```
ctx:rect(x, y, w, h)
```

Add a rectangle to the current path.

**Parameters:**
- `x`, `y` - Top-left corner
- `w` - Width
- `h` - Height

```lua
ctx:rect(10, 10, 100, 50)
ctx:stroke()
```

---

## circle

```
ctx:circle(cx, cy, r)
```

Add a circle to the current path.

**Parameters:**
- `cx`, `cy` - Center point
- `r` - Radius

```lua
ctx:circle(100, 100, 50)
ctx:fill()
```

---

## ellipse

```
ctx:ellipse(cx, cy, rx, ry)
```

Add an ellipse to the current path.

**Parameters:**
- `cx`, `cy` - Center point
- `rx` - X radius
- `ry` - Y radius

```lua
ctx:ellipse(100, 100, 50, 30)
ctx:fill()
```

---

## text

```
ctx:text(str, x, y, style?)
```

Draw text at the specified position.

**Parameters:**
- `str` - Text string
- `x`, `y` - Text position
- `style` (optional) - Style table:
  - `fontSize` - Font size in points
  - `fontWeight` - Font weight: `"normal"`, `"bold"`, `"light"`
  - `color` - Text color
  - `anchor` - Text anchor: `"start"`, `"middle"`, `"end"`

```lua
ctx:text("Hello", 100, 100, {
    fontSize = 12,
    fontWeight = "bold",
    color = "black",
    anchor = "middle"
})
```

---

## set_stroke

```
ctx:set_stroke(color, width?, style?)
```

Set stroke style for subsequent drawing operations.

**Parameters:**
- `color` - Stroke color
- `width` (optional) - Line width
- `style` (optional) - Line style: `"-"`, `"--"`, `"-."`, `":"`

```lua
ctx:set_stroke("blue", 2, "--")
```

---

## set_fill

```
ctx:set_fill(color)
```

Set fill color for subsequent drawing operations.

**Parameters:**
- `color` - Fill color

```lua
ctx:set_fill("red")
```

---

## set_alpha

```
ctx:set_alpha(alpha)
```

Set transparency for subsequent drawing operations.

**Parameters:**
- `alpha` - Transparency value (0-1, where 0 is transparent and 1 is opaque)

```lua
ctx:set_alpha(0.5)
```

---

## stroke

```
ctx:stroke()
```

Stroke the current path using the current stroke style.

```lua
ctx:circle(100, 100, 50)
ctx:set_stroke("blue", 2)
ctx:stroke()
```

---

## fill

```
ctx:fill()
```

Fill the current path using the current fill color.

```lua
ctx:circle(100, 100, 50)
ctx:set_fill("red")
ctx:fill()
```

---

## save

```
ctx:save()
```

Save the current graphics state (styles, transformations) to a stack.

```lua
ctx:save()
ctx:set_fill("red")
-- ... drawing operations ...
ctx:restore()  -- Return to previous state
```

---

## restore

```
ctx:restore()
```

Restore the most recently saved graphics state.

```lua
ctx:save()
ctx:set_fill("red")
ctx:restore()  -- Restore previous fill color
```

---

## clear

```
ctx:clear()
```

Clear all drawing commands from the context.

```lua
ctx:clear()
```

---

## command_count

```
ctx:command_count() -> number
```

Get the number of drawing commands in the context.

```lua
local count = ctx:command_count()
print("Drawing commands:", count)
```

---

## line

```
ctx:line(x1, y1, x2, y2)
```

Draw a line from (x1, y1) to (x2, y2). Convenience method combining move_to, line_to, and stroke.

**Parameters:**
- `x1`, `y1` - Start point
- `x2`, `y2` - End point

```lua
ctx:line(0, 0, 100, 100)
```

---

## filled_rect

```
ctx:filled_rect(x, y, w, h, fill, stroke?)
```

Draw a filled rectangle with optional stroke.

**Parameters:**
- `x`, `y` - Top-left corner
- `w`, `h` - Width and height
- `fill` - Fill color
- `stroke` (optional) - Stroke color

```lua
ctx:filled_rect(10, 10, 100, 50, "red", "black")
```

---

## filled_circle

```
ctx:filled_circle(cx, cy, r, fill, stroke?)
```

Draw a filled circle with optional stroke.

**Parameters:**
- `cx`, `cy` - Center point
- `r` - Radius
- `fill` - Fill color
- `stroke` (optional) - Stroke color

```lua
ctx:filled_circle(100, 100, 50, "blue", "black")
```

---

## Colors

Colors can be specified as:
- **Named colors**: `"red"`, `"blue"`, `"green"`, `"black"`, `"white"`, `"gray"`, `"orange"`, `"purple"`, etc.
- **Hex colors**: `"#FF0000"`, `"#00FF00"`, `"#0000FF"`
- **Single characters** (matplotlib): `"r"`, `"g"`, `"b"`, `"c"`, `"m"`, `"y"`, `"k"`, `"w"`

Available named colors: `black`, `white`, `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`, `orange`, `purple`, `brown`, `pink`, `gray`, `lightgray`, `darkgray`

---

## Examples

### Basic Line Plot

```lua
local fig, ax = plot.subplots()

ax:plot({1, 2, 3, 4}, {1, 4, 2, 3}, {color='blue', linestyle='--', marker='o'})
ax:set_title("My First Plot")
ax:set_xlabel("X Axis")
ax:set_ylabel("Y Axis")
ax:grid({visible=true})

fig:savefig("output.png", {dpi=150})
```

### Trigonometric Functions

```lua
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

### Low-Level Drawing

```lua
local ctx = fig:get_context()

-- Path operations
ctx:move_to(100, 100)
ctx:line_to(200, 100)
ctx:line_to(150, 200)
ctx:close_path()
ctx:set_fill("red")
ctx:fill()

-- Convenience methods
ctx:filled_circle(300, 300, 50, "blue", "black")
ctx:text("Hello World", 300, 400, {
    fontSize = 16,
    fontWeight = "bold",
    anchor = "middle"
})
```

---

## Notes

- All coordinates use a bottom-left origin with y-axis pointing up (mathematical convention)
- Colors, line styles, and markers follow matplotlib conventions for compatibility
- Drawing operations are retained in memory as vector commands, enabling export at any resolution
- The module is designed for embedded use in Swift applications with no GUI dependency
