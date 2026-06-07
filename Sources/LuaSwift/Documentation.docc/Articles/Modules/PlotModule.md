# Plot Module

Matplotlib-compatible plotting with retained-mode vector graphics and multi-format export.

> Warning: **Experimental — opt-in, default OFF.** This module requires the PlotSwift package, which is an early 0.1.0 preview. The API may change between releases. Enable it by setting `LUASWIFT_INCLUDE_PLOTSWIFT=1` at build time (e.g. `LUASWIFT_INCLUDE_PLOTSWIFT=1 swift build`).

## Overview

The Plot module provides a matplotlib-compatible plotting interface for creating figures with lines, scatter plots, bar charts, histograms, pie charts, heatmaps, contour plots, box plots, error bars, and more. It also exposes a `plot.stat` namespace with seaborn-style statistical visualizations.

The architecture is retained-mode: drawing commands are stored as scale-free vectors in a `DrawingContext`. The host app can render the context at any resolution, or export directly to SVG, PNG, or PDF. The module registers as `luaswift.plot` and also installs a top-level global `plot`.

## Installation

```swift
// Install all modules (PlotModule included when built with LUASWIFT_INCLUDE_PLOTSWIFT=1)
try ModuleRegistry.install(in: engine)

// Or install just the Plot module
try PlotModule.install(in: engine)
```

Build flag:

```bash
LUASWIFT_INCLUDE_PLOTSWIFT=1 swift build
```

## Basic Usage

```lua
local plot = require("luaswift.plot")

-- Create a figure and single axes
local fig, ax = plot.subplots()

-- Plot data
ax:plot({1, 2, 3, 4}, {1, 4, 2, 3}, {color = "blue", label = "series"})
ax:set_title("My Plot")
ax:set_xlabel("X")
ax:set_ylabel("Y")
ax:legend()

-- Export
fig:savefig("output.png", {dpi = 150})
fig:savefig("output.svg")
fig:savefig("output.pdf")

-- Or get a DrawingContext for host-app rendering
local ctx = fig:get_context()
```

## API Reference

### Figure Creation

#### plot.figure(opts?)

Creates a figure. `opts` is an options table (all fields optional):

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `figsize` | `{w, h}` | `{6.4, 4.8}` | Figure dimensions in inches |
| `dpi` | number | `100` | Dots per inch; pixel size = `figsize[i] * dpi` |

```lua
local fig = plot.figure()                           -- 640 x 480 pixels
local fig = plot.figure({figsize = {10, 6}})        -- 1000 x 600 pixels
local fig = plot.figure({figsize = {8, 6}, dpi = 150})
```

> Note: There is no `plot.figure(w, h)` positional form. Width and height are set via the `figsize` field in the options table.

#### plot.subplots(nrows?, ncols?, opts?)

Creates a figure with a grid of axes and returns `fig, ax` (single axes) or `fig, axes_array` (multiple).

```lua
-- Single axes (default)
local fig, ax = plot.subplots()

-- 2x2 grid — returns fig and a flat array of four axes
local fig, axes = plot.subplots(2, 2)
local ax1, ax2, ax3, ax4 = axes[1], axes[2], axes[3], axes[4]

-- Pass figure options as opts
local fig, ax = plot.subplots(1, 1, {figsize = {10, 6}, dpi = 150})

-- Options table as first argument (shorthand for 1x1)
local fig, ax = plot.subplots({figsize = {8, 5}})
```

> Note: `plot.subplots()` is the main entry point. There is no `fig:subplot()` method.

#### plot.show() / plot.ion() / plot.ioff()

No-ops in the embedded context (no GUI is available). Provided for source compatibility with matplotlib scripts.

---

### Figure Methods

#### fig:get_context()

Returns the underlying `DrawingContext` for direct drawing or host-app rendering.

#### fig:savefig(path, opts?)

Save the figure to a file. Format is auto-detected from the file extension (`.png`, `.svg`, `.pdf`).

| `opts` field | Type | Description |
|---|---|---|
| `dpi` | number | PNG scale factor (relative to 72 dpi base) |
| `width` | number | Override pixel width |
| `height` | number | Override pixel height |
| `format` | string | Explicit format: `"png"`, `"svg"`, `"pdf"` |

```lua
fig:savefig("chart.png", {dpi = 150})
fig:savefig("chart.svg")
fig:savefig("chart.pdf")
```

#### fig:to_svg()

Returns an SVG string of the figure.

#### fig:to_png(opts?)

Returns PNG image data as a binary string. `opts.dpi` scales the output.

#### fig:to_pdf()

Returns PDF data as a binary string.

#### fig:colorbar(mappable, opts?)

Draw a colorbar. Reads colormap info from the most recently drawn `imshow` or `scatter` on the referenced axes.

```lua
ax:imshow(matrix, {cmap = "plasma"})
fig:colorbar(nil, {ax = ax, label = "Intensity"})
```

---

### Axes Methods — Plotting

All plot methods return `self` (the axes object) for chaining.

#### ax:plot(x, y, fmt?, opts?)

Line and/or marker plot. Supports multiple call signatures matching matplotlib:

```lua
ax:plot(y)                           -- y only; x = 1, 2, ...
ax:plot(x, y)                        -- x and y arrays
ax:plot(x, y, "r--")                 -- with format string
ax:plot(x, y, {color="red"})         -- with options table
ax:plot(x, y, "b-o", {linewidth=2})  -- format string + options
```

**Common options:**

| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `color` | `c` | string | Color name, hex, or single-char shorthand (`"r"`, `"b"`, …) |
| `linewidth` | `lw` | number | Line width in pixels |
| `linestyle` | `ls` | string | `"-"`, `"--"`, `"-."`, `":"`, `"none"` |
| `marker` | | string | See marker table below |
| `markersize` | `ms` | number | Marker size in pixels |
| `markerfacecolor` | `mfc` | string | Marker fill color |
| `markeredgecolor` | `mec` | string | Marker edge color |
| `markeredgewidth` | `mew` | number | Marker edge width |
| `alpha` | | number | Opacity 0–1 |
| `label` | | string | Legend label |

**Format string:** a matplotlib-style string such as `"r--o"` encodes color + linestyle + marker.

**Supported markers:** `o` (circle), `s` (square), `^` (triangle up), `v` (triangle down), `<` (triangle left), `>` (triangle right), `d`/`D` (diamond), `p` (pentagon), `h`/`H` (hexagon), `+`, `x`, `*`, `.`, `,`

#### ax:scatter(x, y, opts?)

Scatter plot of individual points.

| Option | Type | Description |
|--------|------|-------------|
| `s` | number or array | Marker size(s) |
| `c` / `color` | string or array | Color(s); a numeric array uses `cmap` |
| `cmap` | string | Colormap name (see colormaps below) |
| `vmin` / `vmax` | number | Data range for colormap normalization |
| `marker` | string | Marker shape (default `"o"`) |
| `alpha` | number | Opacity |
| `edgecolors` / `edgecolor` | string | Marker edge color |
| `linewidths` / `linewidth` | number | Marker edge width |

```lua
ax:scatter(x, y, {s = 30, c = values, cmap = "viridis"})
```

#### ax:bar(x, heights, opts?)

Vertical bar chart.

| Option | Type | Description |
|--------|------|-------------|
| `width` | number | Bar width as fraction of spacing (default `0.8`) |
| `color` | string | Fill color (default `"blue"`) |
| `edgecolor` | string | Edge color (default `"black"`) |
| `alpha` | number | Opacity |
| `bottom` | number or array | Bar base value(s) for stacking |
| `align` | string | `"center"` (default) or `"edge"` |

```lua
ax:bar({1, 2, 3}, {5, 7, 3}, {color = "steelblue", edgecolor = "none"})

-- Stacked bars
ax:bar(x, bottom_values, {color = "blue", label = "A"})
ax:bar(x, top_values, {bottom = bottom_values, color = "orange", label = "B"})
```

#### ax:hist(data, opts?)

Histogram. Returns `counts, bin_edges, {}`.

| Option | Type | Description |
|--------|------|-------------|
| `bins` | number | Number of bins (default `10`) |
| `range` | `{min, max}` | Data range to bin |
| `density` | boolean | Normalize to density |
| `cumulative` | boolean | Cumulative histogram |
| `color` | string | Fill color |
| `edgecolor` | string | Bin edge color |
| `alpha` | number | Opacity |
| `label` | string | Legend label |

```lua
local counts, edges = ax:hist(data, {bins = 20, density = true, color = "steelblue"})
```

#### ax:pie(sizes, opts?)

Pie chart.

| Option | Type | Description |
|--------|------|-------------|
| `labels` | array | Slice labels |
| `colors` | array | Slice colors (cycles) |
| `explode` | array | Per-slice offset fraction |
| `autopct` | string | Format string for percentages (e.g. `"%.1f%%"`) |
| `startangle` | number | Starting angle in degrees (default `0`) |
| `counterclock` | boolean | Direction (default `true`) |

```lua
ax:pie({30, 45, 25}, {
    labels = {"A", "B", "C"},
    autopct = "%.1f%%",
    explode = {0, 0.1, 0}
})
```

#### ax:imshow(data, opts?)

Display a 2-D data array as a heatmap. `data` is a table of rows, each row a table of numbers.

| Option | Type | Description |
|--------|------|-------------|
| `cmap` | string | Colormap name (default `"viridis"`) |
| `vmin` / `vmax` | number | Data range for color mapping |
| `aspect` | string | `"auto"` (default) |
| `interpolation` | string | `"nearest"` (default) |

```lua
local matrix = {{1,2,3},{4,5,6},{7,8,9}}
ax:imshow(matrix, {cmap = "plasma"})
```

#### ax:errorbar(x, y, opts?)

Plot data with error bars.

| Option | Type | Description |
|--------|------|-------------|
| `yerr` | number or array | Y error(s) |
| `xerr` | number or array | X error(s) |
| `fmt` | string | Marker format (default `"o"`) |
| `color` / `c` | string | Data point color |
| `ecolor` | string | Error bar color (defaults to `color`) |
| `elinewidth` | number | Error bar line width |
| `capsize` | number | Cap size in pixels |
| `capthick` | number | Cap line thickness |

```lua
ax:errorbar(x, y, {yerr = errors, capsize = 4, color = "navy"})
```

#### ax:boxplot(data, opts?)

Box-and-whisker plot. `data` can be a single array or an array of arrays.

| Option | Type | Description |
|--------|------|-------------|
| `positions` | array | X positions for each box |
| `widths` | number | Box width fraction |
| `vert` | boolean | Vertical orientation (default `true`) |
| `showmeans` | boolean | Show mean marker |
| `showfliers` | boolean | Show outliers (default `true`) |

```lua
ax:boxplot({dataset1, dataset2, dataset3})
ax:boxplot(single_dataset)
```

Whiskers extend to 1.5 × IQR. Outliers are drawn as individual points. The median is orange; the mean (if shown) is a dashed green line.

#### ax:contour(X, Y, Z, opts?)

Draw contour lines. `X`, `Y`, `Z` are 2-D grids (tables of rows).

| Option | Type | Description |
|--------|------|-------------|
| `levels` | number or array | Number of levels or explicit level values |
| `colors` | array | Per-level line colors (cycles) |
| `linewidths` | number or array | Line width(s) |

```lua
ax:contour(X, Y, Z, {levels = 8, colors = {"navy", "steelblue"}})
```

#### ax:contourf(X, Y, Z, opts?)

Filled contour plot. Delegates to `imshow` for the current implementation.

---

### Axes Methods — Annotation and Styling

#### ax:set_title(title, opts?)

Set the axes title. `opts.fontsize` controls font size (default `14`).

#### ax:set_xlabel(label, opts?) / ax:set_ylabel(label, opts?)

Set axis labels. `opts.fontsize` controls font size (default `12`).

#### ax:set_xlim(left, right) / ax:set_ylim(bottom, top)

Set axis limits.

```lua
ax:set_xlim(0, 10)
ax:set_ylim(-1, 1)
```

#### ax:get_xlim() / ax:get_ylim()

Return current limits as `{min, max}`.

#### ax:set_xscale(scale, opts?) / ax:set_yscale(scale, opts?)

Set axis scale. Supported values: `"linear"` (default), `"log"`, `"symlog"`.

For `"symlog"`, pass `opts.linthresh` (default `1`) to control the linear region around zero.

```lua
ax:set_xscale("log")
ax:set_yscale("symlog", {linthresh = 0.1})
```

#### ax:get_xscale() / ax:get_yscale()

Return the current scale string.

#### ax:set_aspect(aspect)

Set aspect ratio. Pass `"equal"` or a numeric ratio.

#### ax:axis(arg)

Control axis visibility and aspect. Accepted values: `"on"`, `"off"`, `"equal"`.

#### ax:legend(opts?)

Draw a legend from entries registered by `label` options in plot calls.

| Option | Type | Description |
|--------|------|-------------|
| `loc` | string | `"upper right"` (default/`"best"`), `"upper left"`, `"lower right"`, `"lower left"` |
| `fontsize` | number | Label font size (default `10`) |
| `frameon` | boolean | Draw legend box (default `true`) |

#### ax:grid(opts?)

Draw grid lines. Pass `false` or `{visible = false}` to disable.

| Option | Type | Description |
|--------|------|-------------|
| `visible` | boolean | Show grid (default `true`) |
| `which` | string | `"major"` (default) |
| `axis` | string | `"both"` (default), `"x"`, `"y"` |
| `color` | string | Grid color (default `"#cccccc"`) |
| `linestyle` | string | Line style (default `"-"`) |
| `linewidth` | number | Line width (default `0.5`) |
| `alpha` | number | Opacity (default `0.7`) |

---

### Colormaps

The following named colormaps are built in:

`viridis`, `plasma`, `inferno`, `magma`, `cividis`, `gray`, `hot`, `coolwarm`

---

### Statistical Namespace (plot.stat)

`plot.stat` contains seaborn-style statistical visualization functions. Each function takes an `ax` (axes object) as its first argument and returns `ax`.

```lua
local stat = require("luaswift.plot.stat")
-- or
local stat = plot.stat
```

#### stat.histplot(ax, data, opts?)

Enhanced histogram with optional KDE overlay.

| Option | Type | Description |
|--------|------|-------------|
| `bins` | number | Bin count (default `10`) |
| `binwidth` | number | Bin width (overrides `bins`) |
| `stat` | string | `"count"` (default), `"frequency"`, `"probability"`, `"percent"`, `"density"` |
| `kde` | boolean | Overlay KDE curve (default `false`) |
| `bw_adjust` | number | KDE bandwidth multiplier |
| `color` | string | Fill color (default `"steelblue"`) |
| `edgecolor` | string | Bin edge color (default `"white"`) |
| `alpha` | number | Opacity (default `0.7`) |
| `element` | string | `"bars"` (default) or `"step"` |
| `fill` | boolean | Fill bars (default `true`) |

```lua
stat.histplot(ax, data, {bins = 20, stat = "density", kde = true})
```

#### stat.kdeplot(ax, data, opts?)

Kernel density estimate curve with optional fill.

| Option | Type | Description |
|--------|------|-------------|
| `bw_method` | string or number | `"scott"` (default), `"silverman"`, or numeric bandwidth |
| `bw_adjust` | number | Bandwidth multiplier (default `1.0`) |
| `fill` | boolean | Fill under curve (default `false`) |
| `color` | string | Line/fill color (default `"blue"`) |
| `linewidth` | number | Line width (default `2`) |
| `alpha` | number | Fill opacity (default `0.3`) |
| `cumulative` | boolean | Cumulative KDE (default `false`) |
| `cut` | number | Extend range by `cut * bandwidth` (default `3`) |

#### stat.rugplot(ax, data, opts?)

Draw a rug plot (tick marks along an axis).

| Option | Type | Description |
|--------|------|-------------|
| `height` | number | Rug height as fraction of plot (default `0.05`) |
| `color` | string | Tick color (default `"black"`) |
| `linewidth` | number | Tick line width (default `1`) |
| `alpha` | number | Opacity (default `1.0`) |
| `axis` | string | `"x"` (default) or `"y"` |

#### stat.violinplot(ax, data, opts?)

Violin plot using KDE to show distribution shape. `data` can be a single array or an array of arrays.

| Option | Type | Description |
|--------|------|-------------|
| `positions` | array | X positions for each violin |
| `widths` | number or array | Violin width fraction (default `0.5`) |
| `showmeans` | boolean | Show mean dot (default `false`) |
| `showmedians` | boolean | Show median line (default `true`) |
| `showextrema` | boolean | Show extrema bar (default `true`) |
| `bw_method` | string | Bandwidth method (default `"scott"`) |
| `vert` | boolean | Vertical orientation (default `true`) |

#### stat.stripplot(ax, data, opts?)

Categorical strip plot (jittered scatter). `data` is a single array or array of arrays.

| Option | Type | Description |
|--------|------|-------------|
| `jitter` | number or boolean | Jitter amount (default `0.2`); `false` to disable |
| `color` | string | Point color (default `"steelblue"`) |
| `size` / `s` | number | Point diameter (default `5`) |
| `alpha` | number | Opacity (default `0.7`) |
| `orient` | string | `"v"` (default) or `"h"` |

#### stat.swarmplot(ax, data, opts?)

Beeswarm plot — like stripplot but positions points to avoid overlap.

| Option | Type | Description |
|--------|------|-------------|
| `color` | string | Point color (default `"steelblue"`) |
| `size` / `s` | number | Point diameter (default `5`) |
| `alpha` | number | Opacity (default `0.7`) |
| `orient` | string | `"v"` (default) or `"h"` |

#### stat.regplot(ax, x_data, y_data, opts?)

Scatter plot with optional linear regression line and confidence interval band.

| Option | Type | Description |
|--------|------|-------------|
| `ci` | number or boolean | Confidence interval percentage (default `95`); `false` to disable |
| `color` | string | Color for both scatter and line (default `"steelblue"`) |
| `scatter` | boolean | Draw scatter points (default `true`) |
| `fit_reg` | boolean | Draw regression line (default `true`) |
| `marker` | string | Point marker (default `"o"`) |
| `scatter_kws` | table | Extra options for scatter (e.g. `{s = 20, color = "gray"}`) |
| `line_kws` | table | Extra options for line (e.g. `{linewidth = 2}`) |

#### stat.heatmap(ax, data, opts?)

Annotated heatmap. `data` is a 2-D table of numbers.

| Option | Type | Description |
|--------|------|-------------|
| `annot` | boolean | Annotate cells with values (default `false`) |
| `fmt` | string | Annotation format string (default `"%.2g"`) |
| `cmap` | string | Colormap (default `"viridis"`) |
| `center` | number | Value to center the colormap |
| `vmin` / `vmax` | number | Data range |
| `linewidths` | number | Cell border width (default `0`) |
| `linecolor` | string | Cell border color (default `"white"`) |
| `square` | boolean | Force square cells |
| `cbar` | boolean | Draw colorbar (default `true`) |
| `xticklabels` | array | Column labels |
| `yticklabels` | array | Row labels |

```lua
stat.heatmap(ax, data, {annot = true, fmt = "%.1f", cmap = "coolwarm"})
```

#### stat.catplot(data, opts?)

Figure-level categorical plot. Returns `{fig = fig, ax = ax}`.

| Option | Type | Description |
|--------|------|-------------|
| `kind` | string | `"strip"` (default), `"swarm"`, `"box"`, `"violin"`, `"bar"`, `"count"`, `"point"` |
| `height` | number | Figure height in inches (default `4`) |
| `aspect` | number | Width-to-height ratio (default `1`) |
| `figsize` | `{w, h}` | Override figure size |

```lua
local result = stat.catplot(datasets, {kind = "violin"})
result.fig:savefig("catplot.svg")
```

#### stat.lmplot(data, opts?)

Figure-level regression plot. Returns `{fig = fig, ax = ax}`.

If `opts.x` and `opts.y` are set and `data` is a column-keyed table, they name the columns to use; otherwise `data[1]` and `data[2]` are used as x and y arrays.

| Option | Type | Description |
|--------|------|-------------|
| `x` | string | Column name for x values |
| `y` | string | Column name for y values |
| `ci` | number | Confidence interval (default `95`) |
| `scatter` | boolean | Draw scatter (default `true`) |
| `height` | number | Figure height (default `5`) |
| `aspect` | number | Width ratio (default `1`) |

#### stat.clustermap(data, opts?)

Hierarchical clustering heatmap. Reorders rows and columns by similarity. Returns `{fig, ax, row_order, col_order, clustered_data}`.

| Option | Type | Description |
|--------|------|-------------|
| `row_cluster` | boolean | Cluster rows (default `true`) |
| `col_cluster` | boolean | Cluster columns (default `true`) |
| `method` | string | Linkage method hint (default `"average"`) |
| `metric` | string | Distance metric hint (default `"euclidean"`) |
| `cmap` | string | Colormap (default `"viridis"`) |
| `annot` | boolean | Annotate cells |
| `fmt` | string | Annotation format |
| `figsize` | `{w, h}` | Figure size (default `{10, 10}`) |

---

### DrawingContext API

`DrawingContext` is the low-level vector drawing surface. Retrieve it with `fig:get_context()` or `ax:get_context()`. All methods return `self` for chaining.

**Path building:**

| Method | Description |
|--------|-------------|
| `ctx:move_to(x, y)` | Begin new path at (x, y) |
| `ctx:line_to(x, y)` | Add line to (x, y) |
| `ctx:curve_to(cp1x, cp1y, cp2x, cp2y, x, y)` | Cubic Bezier to (x, y) |
| `ctx:close_path()` | Close current path |

**Shapes:**

| Method | Description |
|--------|-------------|
| `ctx:rect(x, y, w, h)` | Add rectangle path |
| `ctx:ellipse(cx, cy, rx, ry)` | Add ellipse path |
| `ctx:circle(cx, cy, r)` | Add circle path |

**Style:**

| Method | Description |
|--------|-------------|
| `ctx:set_stroke(color, width?, style?)` | Set stroke color, width, and line style (`"-"`, `"--"`, `"-."`, `":"`) |
| `ctx:set_fill(color)` | Set fill color |
| `ctx:set_alpha(alpha)` | Set global opacity (0–1) |

**Drawing:**

| Method | Description |
|--------|-------------|
| `ctx:stroke()` | Stroke current path |
| `ctx:fill()` | Fill current path |

**Text:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `ctx:text(str, x, y, opts?)` | | Draw text at (x, y). `opts`: `font_size`/`fontSize`, `color`, `anchor` (`"start"`, `"middle"`, `"end"`), `font_weight`/`fontWeight` (`"normal"`, `"bold"`, `"light"`) |

**State:**

| Method | Description |
|--------|-------------|
| `ctx:save()` | Push graphics state |
| `ctx:restore()` | Pop graphics state |
| `ctx:clear()` | Remove all commands |
| `ctx:command_count()` | Return number of recorded commands |

**Convenience:**

| Method | Description |
|--------|-------------|
| `ctx:line(x1, y1, x2, y2)` | Draw a stroked line segment |
| `ctx:filled_rect(x, y, w, h, fill, stroke?)` | Draw a filled (and optionally stroked) rectangle |
| `ctx:filled_circle(cx, cy, r, fill, stroke?)` | Draw a filled (and optionally stroked) circle |

**Export:**

| Method | Description |
|--------|-------------|
| `ctx:to_svg(width?, height?)` | Render to SVG string |
| `ctx:to_png(width?, height?, scale?)` | Render to PNG binary string |
| `ctx:to_pdf(width?, height?)` | Render to PDF binary string |
| `ctx:savefig(path, opts?)` | Write to file; `opts.width`, `opts.height`, `opts.dpi`, `opts.format` |
| `ctx:destroy()` | Release the underlying context |

**Factory:**

```lua
local ctx = plot.create_context(width, height)
```

---

## Complete Example

```lua
local plot = require("luaswift.plot")

-- Figure with single axes
local fig, ax = plot.subplots({figsize = {8, 5}})

-- Generate data
local x, y1, y2 = {}, {}, {}
for i = 1, 100 do
    local t = i * 0.1
    x[i]  = t
    y1[i] = math.sin(t)
    y2[i] = math.cos(t)
end

ax:plot(x, y1, {color = "blue",  label = "sin(x)"})
ax:plot(x, y2, {color = "red",   label = "cos(x)", linestyle = "--"})
ax:set_title("Trigonometric Functions")
ax:set_xlabel("x")
ax:set_ylabel("y")
ax:legend()
ax:grid()

fig:savefig("trig.svg")
fig:savefig("trig.png", {dpi = 150})
```

## Multiple Subplots Example

```lua
local plot = require("luaswift.plot")

local fig, axes = plot.subplots(2, 2, {figsize = {12, 8}})
local ax1, ax2, ax3, ax4 = axes[1], axes[2], axes[3], axes[4]

-- Line plot
ax1:plot({1, 2, 3, 4}, {1, 4, 9, 16})
ax1:set_title("Line Plot")

-- Scatter
ax2:scatter({1, 2, 3, 4}, {2, 3, 1, 4}, {s = 40, c = {1, 2, 3, 4}, cmap = "viridis"})
ax2:set_title("Scatter Plot")

-- Bar chart
ax3:bar({1, 2, 3}, {5, 7, 3}, {color = "steelblue"})
ax3:set_title("Bar Chart")

-- Histogram
local data = {}
for i = 1, 500 do data[i] = math.random() + math.random() + math.random() end
ax4:hist(data, {bins = 20, color = "orange", alpha = 0.8})
ax4:set_title("Histogram")

fig:savefig("subplots.svg")
```

## Statistical Plots Example

```lua
local plot = require("luaswift.plot")
local stat = plot.stat

local fig, ax = plot.subplots()

-- KDE with rug
local samples = {}
for i = 1, 200 do samples[i] = math.random() * 4 - 2 end

stat.histplot(ax, samples, {bins = 15, stat = "density", kde = true, color = "steelblue"})
stat.rugplot(ax, samples, {color = "black", alpha = 0.5})
ax:set_title("Density with KDE and Rug")
fig:savefig("density.svg")

-- Heatmap
local fig2, ax2 = plot.subplots()
local matrix = {}
for i = 1, 5 do
    matrix[i] = {}
    for j = 1, 5 do matrix[i][j] = i * j end
end
stat.heatmap(ax2, matrix, {annot = true, fmt = "%d", cmap = "plasma"})
fig2:savefig("heatmap.svg")
```

## Low-Level Drawing Example

```lua
local plot = require("luaswift.plot")

local ctx = plot.create_context(400, 300)

-- White background
ctx:set_fill("white")
ctx:rect(0, 0, 400, 300)
ctx:fill()

-- Title text
ctx:text("Custom Drawing", 200, 20, {anchor = "middle", font_size = 14, font_weight = "bold"})

-- Filled circle
ctx:set_fill("#4878CF")
ctx:circle(200, 150, 60)
ctx:fill()

-- Dashed border
ctx:set_stroke("navy", 2, "--")
ctx:circle(200, 150, 60)
ctx:stroke()

-- Chain path operations
ctx:set_stroke("red", 1)
   :move_to(50, 50)
   :line_to(150, 250)
   :line_to(350, 50)
   :stroke()

local svg = ctx:to_svg()
ctx:destroy()
```

## Performance Notes

- The DrawingContext stores commands in memory; rendering happens lazily on export.
- SVG output is scale-free and suitable for web display or vector tools.
- PNG and PDF rendering use CoreGraphics (macOS/iOS); PNG/PDF export is not available on platforms without ImageIO.
- For large datasets (> 10,000 points), consider downsampling before passing to plot functions.

## See Also

- ``PlotModule``
- ``SVGModule``
- ``ArrayModule``
