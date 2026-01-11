# Module Reference

[← Back to Documentation](../index.md)

## Overview

LuaSwift provides optional modules that extend Lua's capabilities. Install all modules with `ModuleRegistry.installModules(in: engine)`, or install individually.

After installation, call `luaswift.extend_stdlib()` to:
- Extend `string`, `table`, `utf8` with additional functions
- Create `math.*` subnamespaces for scientific modules

## Standard Library Extensions

These modules extend Lua's built-in libraries.

| Module | Extends | Documentation |
|--------|---------|---------------|
| [stringx](stringx.md) | `string` | String manipulation: trim, split, join, replace |
| [tablex](tablex.md) | `table` | Functional operations: map, filter, reduce, merge |
| [utf8x](utf8x.md) | `utf8` | Unicode-aware: sub, reverse, width (CJK) |
| [compat](compat.md) | - | Lua version compatibility layer |

```lua
luaswift.extend_stdlib()
string.trim("  hello  ")  -- "hello"
table.keys({a=1, b=2})    -- {"a", "b"}
```

## Data Formats

| Module | Global | Documentation |
|--------|--------|---------------|
| [json](json.md) | `json` | JSON encode/decode |
| [yaml](yaml.md) | `yaml` | YAML with multi-document |
| [toml](toml.md) | `toml` | TOML configuration |

## Math Namespace

After `extend_stdlib()`, these are available under `math.*`:

| Module | Access | Documentation |
|--------|--------|---------------|
| Base | `math.*` | sign, round, factorial, gamma |
| [linalg](linalg.md) | `math.linalg` | Linear algebra (BLAS/LAPACK) |
| [complex](complex.md) | `math.complex` | Complex numbers |
| [geo](geo.md) | `math.geo` | 2D/3D geometry |
| [special](special.md) | `math.special` | Special functions |
| [stats](stats.md) | `math.stats` | Statistics |
| [distributions](distributions.md) | `math.distributions` | Probability distributions |
| [optimize](optimize.md) | `math.optimize` | Optimization |
| [integrate](integrate.md) | `math.integrate` | Integration, ODEs |
| [interpolate](interpolate.md) | `math.interpolate` | Interpolation |
| [cluster](cluster.md) | `math.cluster` | Clustering |
| [spatial](spatial.md) | `math.spatial` | Spatial algorithms |
| [regress](regress.md) | `math.regress` | Regression models |
| [series](series.md) | `math.series` | Series evaluation |
| [eval](eval.md) | `math.eval` | Expression parsing |
| [constants](constants.md) | `math.constants` | Physical constants |
| [numtheory](numtheory.md) | `math.numtheory` | Number theory |

```lua
luaswift.extend_stdlib()
local m = math.linalg.matrix({{1,2},{3,4}})
local c = math.constants.c  -- speed of light
```

## Array (Standalone)

| Module | Global | Documentation |
|--------|--------|---------------|
| [array](array.md) | `array` | NumPy-like N-dimensional arrays |

Array is a standalone module, not under `math`.

```lua
local a = array.zeros({3, 3})
local b = a + 1  -- broadcasting
```

## Visualization

| Module | Global | Documentation |
|--------|--------|---------------|
| [plot](plot.md) | `plot` | Matplotlib-style plotting |
| [svg](svg.md) | `svg` | SVG document generation |

## Pattern Matching

| Module | Global | Documentation |
|--------|--------|---------------|
| [regex](regex.md) | `regex` | ICU regular expressions |

## External Access (Opt-In)

These modules access resources outside the Lua sandbox and require explicit installation.

| Module | Require | Documentation |
|--------|---------|---------------|
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
| cluster | (array internally) |
| spatial | (array internally) |

---

[← Back to Documentation](../index.md)
