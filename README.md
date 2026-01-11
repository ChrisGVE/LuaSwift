# LuaSwift

A lightweight Swift wrapper for Lua with an optional powerpack of advanced modules.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FLuaSwift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ChrisGVE/LuaSwift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FLuaSwift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ChrisGVE/LuaSwift)
[![Lua](https://img.shields.io/badge/Lua-5.1--5.5-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

LuaSwift embeds the Lua scripting language in iOS and macOS applications. The core wrapper is lightweight and dependency-free, bundling the complete Lua source for App Store compliance.

**Core Wrapper Features:**
- Multi-version Lua support (5.1, 5.2, 5.3, 5.4, 5.5 - default 5.4)
- Type-safe Swift-Lua value bridging
- Value servers for exposing Swift data to Lua
- Swift callbacks callable from Lua
- Coroutine management
- Configurable sandboxing
- Thread-safe design

**Optional Powerpack:** Install additional modules for:
- Standard library extensions (string, table, utf8)
- Data format parsing (JSON, YAML, TOML)
- Mathematics (extended math, linear algebra, complex numbers, geometry)
- Scientific computing (statistics, optimization, integration, interpolation)
- N-dimensional arrays (NumPy-like)
- Visualization (plotting, SVG)
- Pattern matching (regex)
- External access (sandboxed file I/O, HTTP client)

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ChrisGVE/LuaSwift.git", from: "1.4.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL.

## Quick Start

### Wrapper Only (No Modules)

```swift
import LuaSwift

// Create sandboxed engine (default: Lua 5.4)
let engine = try LuaEngine()

// Evaluate Lua code
let result = try engine.evaluate("return 1 + 2")
print(result.numberValue!) // 3.0

// Expose Swift data to Lua
class AppData: LuaValueServer {
    let namespace = "App"
    func resolve(path: [String]) -> LuaValue {
        path.first == "version" ? .string("1.0") : .nil
    }
}
engine.register(server: AppData())
let version = try engine.evaluate("return App.version")
```

### With Powerpack Modules

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Extend standard library with LuaSwift enhancements
try engine.run("luaswift.extend_stdlib()")

// Use from Lua
try engine.run("""
    -- Standard library extensions work seamlessly
    local s = string.capitalize("hello world")  -- "Hello world"
    local keys = table.keys({a=1, b=2})         -- {"a", "b"}

    -- Math submodules are available
    local m = math.linalg.matrix({{1, 2}, {3, 4}})
    local z = math.complex.new(3, 4)
    local v = math.geo.vec3(1, 2, 3)

    -- Data parsing
    local data = json.decode('{"x": 1, "y": 2}')

    -- Arrays (standalone module)
    local a = array.zeros({3, 3})
""")
```

## Lua Version Selection

LuaSwift bundles Lua 5.1.5, 5.2.4, 5.3.6, 5.4.7, and 5.5.0. Default is 5.4.

```bash
LUASWIFT_LUA_VERSION=55 swift build  # Lua 5.5
LUASWIFT_LUA_VERSION=51 swift build  # Lua 5.1
```

| Version | Env Value | Notes |
|---------|-----------|-------|
| 5.4.7   | `54` (default) | Recommended for new projects |
| 5.5.0   | `55` | Latest, experimental features |
| 5.3.6   | `53` | Integer subtype support |
| 5.2.4   | `52` | Goto, bit32 library |
| 5.1.5   | `51` | Maximum compatibility |

## Module Reference

### Standard Library Extensions

These modules extend Lua's built-in libraries. After calling `luaswift.extend_stdlib()`, their functions are available directly on `string`, `table`, and `utf8`.

| Module | Extends | Key Functions |
|--------|---------|---------------|
| stringx | `string` | `capitalize`, `trim`, `split`, `join`, `startswith`, `endswith`, `replace` |
| tablex | `table` | `keys`, `values`, `map`, `filter`, `reduce`, `merge`, `deepcopy` |
| utf8x | `utf8` | `sub`, `reverse`, `upper`, `lower`, `width` (CJK-aware) |
| compat | - | Lua version compatibility (bit32, unpack, loadstring) |

```lua
luaswift.extend_stdlib()

-- Now available on standard libraries
string.trim("  hello  ")           -- "hello"
table.keys({a=1, b=2})             -- {"a", "b"}
utf8.sub("日本語", 1, 2)            -- "日本"
```

### Data Formats

| Module | Global | Description |
|--------|--------|-------------|
| json | `json` | JSON encode/decode with null handling |
| yaml | `yaml` | YAML with multi-document support |
| toml | `toml` | TOML configuration parsing |

### Math (Unified Namespace)

After `luaswift.extend_stdlib()`, all math modules are available under the `math` namespace:

| Submodule | Access | Description |
|-----------|--------|-------------|
| Base extensions | `math.*` | Extended functions: `sign`, `round`, `factorial`, `gamma` |
| Linear Algebra | `math.linalg` | Matrices, SVD, eigenvalues (BLAS/LAPACK) |
| Complex Numbers | `math.complex` | Complex arithmetic and functions |
| Geometry | `math.geo` | 2D/3D vectors, quaternions, transforms |
| Special Functions | `math.special` | Bessel, gamma, erf, elliptic integrals |
| Statistics | `math.stats` | Mean, median, variance, percentile |
| Distributions | `math.distributions` | Normal, t, chi2, F, gamma, beta distributions |
| Optimization | `math.optimize` | Minimization, root finding, curve fitting |
| Integration | `math.integrate` | Numerical integration, ODE solvers |
| Interpolation | `math.interpolate` | Splines, PCHIP, Akima |
| Clustering | `math.cluster` | K-means, hierarchical, DBSCAN |
| Spatial | `math.spatial` | KDTree, Voronoi, Delaunay |
| Regression | `math.regress` | OLS, WLS, GLS, GLM, ARIMA |
| Series | `math.series` | Taylor polynomials, summation, products |
| Expressions | `math.eval` | Expression parsing, LaTeX support |
| Constants | `math.constants` | Physical constants, unit conversions |
| Number Theory | `math.numtheory` | Primes, factorization, totient |

```lua
luaswift.extend_stdlib()

-- All under math namespace
local m = math.linalg.matrix({{1, 2}, {3, 4}})
local z = math.complex.new(3, 4)
local v = math.geo.vec3(1, 2, 3)
local g = math.special.gamma(5)    -- 24
local c = math.constants.c         -- speed of light
local avg = math.stats.mean({1, 2, 3, 4, 5})
```

### Array (Standalone)

N-dimensional arrays with NumPy-style broadcasting. Standalone module, not under `math`.

| Module | Global | Description |
|--------|--------|-------------|
| array | `array` | NumPy-like N-dimensional arrays |

```lua
local a = array.zeros({3, 3})
local b = array.linspace(0, 1, 100)
local c = a + 1  -- broadcasting
```

### Visualization

| Module | Global | Description |
|--------|--------|-------------|
| plot | `plot` | Matplotlib-style plotting with retained graphics |
| svg | `svg` | SVG document generation (used by plot) |

```lua
local fig = plot.figure()
local ax = fig:subplot(1, 1, 1)
ax:plot({1, 2, 3}, {1, 4, 9})
local svg_string = fig:render()
```

### Pattern Matching

| Module | Global | Description |
|--------|--------|-------------|
| regex | `regex` | ICU regular expressions |

### External Access (Opt-In)

These modules are **not** included in `installModules()` and require explicit installation because they access resources outside the Lua sandbox.

| Module | Require | Why Separate |
|--------|---------|--------------|
| iox | `luaswift.iox` | File system access requires allowed directory configuration |
| http | `luaswift.http` | Network access may not be desired in all environments |

```swift
// File I/O: Configure allowed directories first
IOModule.setAllowedDirectories([documentsPath], for: engine)
ModuleRegistry.installIOModule(in: engine)

// HTTP: Explicit opt-in for network access
ModuleRegistry.installHTTPModule(in: engine)
```

The `iox` module provides sandboxed file operations restricted to configured directories. It does not replace Lua's standard `io` library (which is removed in sandboxed mode).

## Selective Module Installation

You can install individual modules instead of the full powerpack:

```swift
let engine = try LuaEngine()

// Install only what you need
ModuleRegistry.installJSONModule(in: engine)
ModuleRegistry.installStringXModule(in: engine)
ModuleRegistry.installMathModule(in: engine)

// Note: Some modules have dependencies
// - math.linalg requires MathModule
// - math.distributions requires MathModule + SpecialModule
// - series requires MathExprModule
```

## Configuration

```swift
// Default: sandboxed, Lua 5.4, no memory limit
let engine = try LuaEngine()

// Custom configuration
let config = LuaEngineConfiguration(
    sandboxed: true,              // Remove dangerous functions
    packagePath: "/path/to/lua",  // Custom require() path
    memoryLimit: 50_000_000       // 50 MB limit
)
let engine = try LuaEngine(configuration: config)

// Unrestricted (use with caution)
let engine = try LuaEngine(configuration: .unrestricted)
```

**Sandboxing removes:** `os.execute`, `os.exit`, `io.*`, `debug.*`, `loadfile`, `dofile`, `load`

## Documentation

For detailed API documentation, see [docs/index.md](docs/index.md):

- [Core API](docs/core-api.md) - LuaEngine, LuaValue, LuaValueServer
- [Value Servers](docs/value-servers.md) - Exposing Swift data to Lua
- [Callbacks](docs/callbacks.md) - Registering Swift functions
- [Coroutines](docs/coroutines.md) - Creating and managing coroutines
- [Threading](docs/threading.md) - Thread safety and engine pools
- [Engine Reuse](docs/engine-reuse.md) - Patterns for long-running engines
- [Modules](docs/modules/index.md) - Detailed module documentation

## App Store Compliance

LuaSwift is designed to be App Store compliant:

- **Bundled interpreter**: Lua source compiled into app (no code download)
- **Sandboxing**: Dangerous functions disabled by default
- **No JIT**: Standard interpreter, not LuaJIT

Per Apple's [App Store Review Guidelines 2.5.2](https://developer.apple.com/app-store/review/guidelines/#software-requirements).

## License

MIT License. See [LICENSE](LICENSE) for details.

Lua is also MIT licensed. See https://www.lua.org/license.html

## Acknowledgments

- [Lua](https://www.lua.org/) - The Lua programming language
- [Yams](https://github.com/jpsim/Yams) - YAML parsing for Swift
- [TOMLKit](https://github.com/LebJe/TOMLKit) - TOML parsing for Swift
