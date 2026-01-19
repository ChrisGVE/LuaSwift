# LuaSwift

A lightweight Swift wrapper for Lua with optional extensions for scientific computing, data formats, and visualization.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat)](https://opensource.org/licenses/MIT)
[![GitHub Release](https://img.shields.io/github/v/release/ChrisGVE/LuaSwift?style=flat&logo=github)](https://github.com/ChrisGVE/LuaSwift/releases)
[![CI](https://github.com/ChrisGVE/LuaSwift/actions/workflows/test-combinations.yml/badge.svg)](https://github.com/ChrisGVE/LuaSwift/actions/workflows/test-combinations.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FLuaSwift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ChrisGVE/LuaSwift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FLuaSwift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ChrisGVE/LuaSwift)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue.svg?style=flat&logo=readthedocs&logoColor=white)](https://swiftpackageindex.com/ChrisGVE/LuaSwift/documentation)
[![Lua](https://img.shields.io/badge/Lua-5.1--5.5-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)

## Overview

LuaSwift embeds the Lua scripting language in iOS and macOS applications. The core wrapper is lightweight and dependency-free, bundling the complete Lua source for App Store compliance. Optional extensions add scientific computing, data formats, and visualization capabilities.

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

## Documentation

Full API reference and module documentation: **[docs/index.md](docs/index.md)**

Quick links: [Core API](docs/core-api.md) · [Value Servers](docs/value-servers.md) · [Callbacks](docs/callbacks.md) · [Modules](docs/modules/index.md)

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

N-dimensional arrays with broadcasting and element-wise operations. Standalone module, not under `math`.

| Module | Global | Description |
|--------|--------|-------------|
| array | `array` | N-dimensional arrays with broadcasting |

```lua
local a = array.zeros({3, 3})
local b = array.linspace(0, 1, 100)
local c = a + 1  -- broadcasting
```

### Visualization

| Module | Global | Description |
|--------|--------|-------------|
| plot | `plot` | Retained-mode plotting (includes SVG generation) |

```lua
local fig = plot.figure()
local ax = fig:subplot(1, 1, 1)
ax:plot({1, 2, 3}, {1, 4, 9})
local svg_string = fig:render()
```

### Pattern Matching

| Module | Global | Description |
|--------|--------|-------------|
| regex | `regex` | ICU regular expressions (also extends `string` after extend_stdlib) |

### File and Network Access

These modules require explicit installation and configuration.

| Module | Global | Description |
|--------|--------|-------------|
| iox | `iox` | Sandboxed file I/O within configured directories |
| http | `http` | HTTP client for network requests |

```swift
// File I/O: Configure which directories Lua can access
IOModule.setAllowedDirectories([documentsPath, cachePath], for: engine)
ModuleRegistry.installIOModule(in: engine)

// HTTP: Enable network requests
ModuleRegistry.installHTTPModule(in: engine)
```

The `iox` module restricts file operations to explicitly allowed directories—Lua scripts cannot access files outside these paths. This replaces Lua's standard `io` library (which is removed in sandboxed mode) with a secure alternative.

## Optional Swift Package Dependencies

LuaSwift can optionally include three companion Swift packages that provide enhanced implementations for specific module groups. These packages are developed as independent Swift libraries that can also be used directly without Lua.

### Available Optional Packages

| Package | Environment Variable | Description |
|---------|---------------------|-------------|
| [NumericSwift](https://github.com/ChrisGVE/NumericSwift) | `LUASWIFT_INCLUDE_NUMERICSWIFT` | Complex numbers, statistics, geometry, special functions |
| [ArraySwift](https://github.com/ChrisGVE/ArraySwift) | `LUASWIFT_INCLUDE_ARRAYSWIFT` | N-dimensional arrays with broadcasting |
| [PlotSwift](https://github.com/ChrisGVE/PlotSwift) | `LUASWIFT_INCLUDE_PLOTSWIFT` | Matplotlib-inspired plotting with SVG output |

### Compile-Time Selection

By default, all optional packages are included. To exclude packages and reduce binary size or dependencies:

```bash
# Exclude specific packages
LUASWIFT_INCLUDE_PLOTSWIFT=0 swift build           # No PlotSwift
LUASWIFT_INCLUDE_ARRAYSWIFT=0 swift build          # No ArraySwift
LUASWIFT_INCLUDE_NUMERICSWIFT=0 swift build        # No NumericSwift

# Exclude multiple packages
LUASWIFT_INCLUDE_PLOTSWIFT=0 LUASWIFT_INCLUDE_ARRAYSWIFT=0 swift build

# Minimal build (core wrapper only)
LUASWIFT_INCLUDE_PLOTSWIFT=0 LUASWIFT_INCLUDE_ARRAYSWIFT=0 LUASWIFT_INCLUDE_NUMERICSWIFT=0 swift build
```

### What Each Package Provides

**NumericSwift** powers these Lua modules:
- `math.complex` - Complex number arithmetic
- `math.geometry` - 2D/3D vectors and transforms
- `math.stats` - Statistical functions
- `math.special` - Special mathematical functions
- `math.numtheory` - Number theory (primes, factorization)
- Extended math utilities (vDSP-accelerated array operations)

**ArraySwift** powers:
- `array` - N-dimensional arrays with NumPy-like semantics

**PlotSwift** powers:
- `plot` - Figure/axes plotting system
- `svg` - SVG document generation

When a package is excluded, its corresponding Lua modules are unavailable at runtime. Attempting to use them will result in a clear error message.

### Xcode Integration

For Xcode projects, set environment variables in your scheme:

1. Product → Scheme → Edit Scheme
2. Select "Run" in the left sidebar
3. Click "Arguments" tab
4. Add environment variables under "Environment Variables"

### Why Optional Dependencies?

- **Binary size**: Each package adds to the final binary; exclude what you don't need
- **Build time**: Fewer dependencies means faster builds
- **Platform support**: Some packages may have platform-specific requirements
- **App Store size**: iOS apps benefit from smaller binaries

### Technical Note: SPM Optional Dependencies

Swift Package Manager does not have a native "optional dependency" feature like some package managers. LuaSwift uses **environment variables at build time** combined with **conditional compilation** (`#if` directives) to achieve optional dependencies.

For consumers who want fine-grained control, there are two approaches:

1. **Environment variables** (current, Swift 5.9+): Set `LUASWIFT_INCLUDE_*=0` before building
2. **SPM Traits** (Swift 6.1+): A newer feature that provides trait-based conditional dependencies

The environment variable approach is used for maximum compatibility. Future versions may adopt [SPM Traits](https://theswiftdev.com/2025/all-about-swift-package-manager-traits/) when Swift 6.1+ becomes the minimum supported version.

## Module Selection

LuaSwift also supports compile-time module selection via environment variables for built-in modules:

```bash
# Build with specific module groups
LUASWIFT_MODULES=core swift build                    # Core wrapper only
LUASWIFT_MODULES=core,data swift build               # + JSON, YAML, TOML
LUASWIFT_MODULES=core,data,math swift build          # + Math namespace
LUASWIFT_MODULES=all swift build                     # Everything (default)
```

| Module Group | Contents |
|--------------|----------|
| `core` | Wrapper + stdlib extensions (stringx, tablex, utf8x, compat, regex) |
| `data` | Data formats (json, yaml, toml) |
| `math` | Math namespace (linalg, complex, geo, stats, optimize, etc.) |
| `array` | N-dimensional arrays |
| `plot` | Visualization (plot with SVG) |
| `iox` | Sandboxed file I/O |
| `http` | HTTP client |
| `all` | All modules (default) |

At runtime, install only what you need:

```swift
let engine = try LuaEngine()

// Install specific modules
ModuleRegistry.installJSONModule(in: engine)
ModuleRegistry.installStringXModule(in: engine)
ModuleRegistry.installMathModule(in: engine)

// Or install all compiled modules
ModuleRegistry.installModules(in: engine)
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

LuaSwift's scientific computing modules are inspired by excellent open-source libraries:

- [NumPy](https://numpy.org/) - N-dimensional array design and broadcasting semantics
- [SciPy](https://scipy.org/) - Optimization, integration, interpolation, and special functions
- [statsmodels](https://www.statsmodels.org/) - Statistical modeling and regression analysis
- [matplotlib](https://matplotlib.org/) - Plotting API design
- [Penlight](https://github.com/lunarmodules/Penlight) - String and table utility patterns

**Required Dependencies:**
- [Lua](https://www.lua.org/) - The Lua programming language (bundled)
- [Yams](https://github.com/jpsim/Yams) - YAML parsing for Swift
- [TOMLKit](https://github.com/LebJe/TOMLKit) - TOML parsing for Swift

**Optional Dependencies:**
- [NumericSwift](https://github.com/ChrisGVE/NumericSwift) - Complex numbers, statistics, geometry
- [ArraySwift](https://github.com/ChrisGVE/ArraySwift) - N-dimensional arrays
- [PlotSwift](https://github.com/ChrisGVE/PlotSwift) - Plotting and SVG generation
