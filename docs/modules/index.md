# Module Reference

[← Back to Documentation](../index.md)

## Overview

LuaSwift provides optional modules that extend Lua's capabilities. Install all modules with `ModuleRegistry.installModules(in: engine)`, or install individually.

After installation, call `luaswift.extend_stdlib()` to:
- Extend `string`, `table`, `utf8` with additional functions
- Create `math.*` subnamespaces for scientific modules

## Standard Library Extensions

These modules extend Lua's built-in libraries.

| Module | Extends | Description |
|--------|---------|-------------|
| stringx | `string` | String manipulation: trim, split, join, replace |
| tablex | `table` | Functional operations: map, filter, reduce, merge |
| utf8x | `utf8` | Unicode-aware: sub, reverse, width (CJK) |
| regex | `string` | ICU regular expressions |
| compat | - | Lua version compatibility layer |

```lua
luaswift.extend_stdlib()
string.trim("  hello  ")  -- "hello"
table.keys({a=1, b=2})    -- {"a", "b"}
```

## Data Formats

| Module | Global | Description |
|--------|--------|-------------|
| [json](json.md) | `json` | JSON encode/decode |
| yaml | `yaml` | YAML with multi-document |
| toml | `toml` | TOML configuration |

## Math Namespace

After `extend_stdlib()`, these are available under `math.*`:

| Module | Access | Description |
|--------|--------|-------------|
| Base | `math.*` | sign, round, factorial, gamma |
| [linalg](linalg.md) | `math.linalg` | Linear algebra (BLAS/LAPACK) |
| complex | `math.complex` | Complex numbers |
| geo | `math.geo` | 2D/3D geometry |
| special | `math.special` | Special functions |
| stats | `math.stats` | Statistics |
| distributions | `math.distributions` | Probability distributions |
| optimize | `math.optimize` | Optimization |
| integrate | `math.integrate` | Integration, ODEs |
| interpolate | `math.interpolate` | Interpolation |
| cluster | `math.cluster` | Clustering |
| spatial | `math.spatial` | Spatial algorithms |
| regress | `math.regress` | Regression models |
| series | `math.series` | Series evaluation |
| eval | `math.eval` | Expression parsing |
| constants | `math.constants` | Physical constants, units |
| numtheory | `math.numtheory` | Number theory |

```lua
luaswift.extend_stdlib()
local m = math.linalg.matrix({{1,2},{3,4}})
local c = math.constants.c  -- speed of light
```

## Array (Standalone)

| Module | Global | Description |
|--------|--------|-------------|
| [array](array.md) | `array` | N-dimensional arrays with broadcasting |

Array is a standalone module, not under `math`.

```lua
local a = array.zeros({3, 3})
local b = a + 1  -- broadcasting
```

## Visualization

| Module | Global | Description |
|--------|--------|-------------|
| plot | `plot` | Retained-mode plotting (includes SVG generation) |

```lua
local fig = plot.figure()
local ax = fig:subplot(1, 1, 1)
ax:plot({1, 2, 3}, {1, 4, 9})
local svg_string = fig:render()
```

## External Access (Opt-In)

These modules access resources outside the Lua sandbox and require explicit installation.

| Module | Require | Description |
|--------|---------|-------------|
| [iox](io.md) | `luaswift.iox` | Sandboxed file I/O |
| [http](http.md) | `luaswift.http` | HTTP client |

```swift
// File I/O requires allowed directories
IOModule.setAllowedDirectories([path], for: engine)
ModuleRegistry.installIOModule(in: engine)

// HTTP is opt-in
ModuleRegistry.installHTTPModule(in: engine)
```

## Installation Options

### All Modules

```swift
ModuleRegistry.installModules(in: engine)
try engine.run("luaswift.extend_stdlib()")
```

### Selective Installation

```swift
ModuleRegistry.installJSONModule(in: engine)
ModuleRegistry.installStringXModule(in: engine)
ModuleRegistry.installMathModule(in: engine)
ModuleRegistry.installLinAlgModule(in: engine)
```

### Module Dependencies

| Module | Requires |
|--------|----------|
| distributions | special |
| regress | linalg |
| series | MathExprModule |
| cluster | array (internally) |
| spatial | array (internally) |

---

[← Back to Documentation](../index.md)
