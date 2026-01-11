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

**Optional Powerpack Modules:**
- Data formats: JSON, YAML, TOML parsing
- Scientific computing: N-dimensional arrays, linear algebra, statistics
- Math & geometry: Extended math, complex numbers, 2D/3D vectors, quaternions
- Probability & optimization: Distributions, integration, curve fitting
- Visualization: Plotting, SVG generation
- Utilities: Regex, string/table extensions, UTF-8
- Security (opt-in): Sandboxed file I/O, HTTP client

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

### Minimal Example (Wrapper Only)

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

// Use from Lua
try engine.run("""
    local data = json.decode('{"x": 1, "y": 2}')
    local v = geo.vec2(data.x, data.y)
    print(v:length())  -- 2.236...

    local m = linalg.matrix({{1, 2}, {3, 4}})
    print(m:det())  -- -2
""")
```

## Lua Version Selection

LuaSwift bundles Lua 5.1.5, 5.2.4, 5.3.6, 5.4.7, and 5.5.0. Default is 5.4.

**Build with specific version:**

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

All modules are auto-loaded. Use directly or via `require()`.

### Core Modules

| Module | Global | Require | Description |
|--------|--------|---------|-------------|
| JSON | `json` | `luaswift.json` | JSON encode/decode |
| YAML | `yaml` | `luaswift.yaml` | YAML with multi-document |
| TOML | `toml` | `luaswift.toml` | TOML configuration |
| Regex | `regex` | `luaswift.regex` | ICU regular expressions |

### Math & Scientific

| Module | Global | Require | Description |
|--------|--------|---------|-------------|
| Extended Math | `mathx` | `luaswift.math` | Statistics, hyperbolic, rounding |
| Linear Algebra | `linalg` | `luaswift.linalg` | Matrices, SVD, eigenvalues (BLAS/LAPACK) |
| Array | `array` | `luaswift.array` | NumPy-like N-dimensional arrays |
| Complex | `complex` | `complex` | Complex number arithmetic |
| Geometry | `geo` | `geo` | 2D/3D vectors, quaternions, transforms |
| Special Functions | `special` | `luaswift.special` | Bessel, gamma, erf, elliptic |

### SciPy-Inspired

| Module | Global | Require | Description |
|--------|--------|---------|-------------|
| Distributions | `distributions` | `luaswift.distributions` | Probability distributions, statistical tests |
| Integrate | `integrate` | `luaswift.integrate` | Numerical integration, ODE solvers |
| Optimize | `optimize` | `luaswift.optimize` | Minimization, root finding, curve fit |
| Interpolate | `interpolate` | `luaswift.interpolate` | Splines, PCHIP, Akima |
| Cluster | `cluster` | `luaswift.cluster` | K-means, hierarchical, DBSCAN |
| Spatial | `spatial` | `luaswift.spatial` | KDTree, Voronoi, Delaunay |
| Regression | `regress` | `luaswift.regress` | OLS, WLS, GLS, GLM, ARIMA |

### Visualization

| Module | Global | Require | Description |
|--------|--------|---------|-------------|
| Plot | `plot` | `luaswift.plot` | Matplotlib-style plotting |
| SVG | `svg` | `svg` | SVG document generation |

### Utilities

| Module | Global | Require | Description |
|--------|--------|---------|-------------|
| StringX | `stringx` | `stringx` | String manipulation |
| TableX | `tablex` | `tablex` | Functional table operations |
| UTF8X | `utf8x` | `utf8x` | Unicode-aware strings |
| Types | `types` | `types` | Type detection/conversion |
| Compat | `compat` | `compat` | Lua version compatibility |
| Math Expr | `math_expr` | `luaswift.mathexpr` | Expression parsing, LaTeX |
| Series | `series` | `luaswift.series` | Taylor, summation, products |

### Security Modules (Opt-In)

These modules require explicit installation:

| Module | Require | Description |
|--------|---------|-------------|
| IO | `luaswift.iox` | Sandboxed file I/O |
| HTTP | `luaswift.http` | URLSession-based HTTP client |

```swift
// IO: Configure allowed directories first
IOModule.setAllowedDirectories([documentsPath], for: engine)
ModuleRegistry.installIOModule(in: engine)

// HTTP: Explicit opt-in
ModuleRegistry.installHTTPModule(in: engine)
```

## Extending the Standard Library

Inject LuaSwift functions into Lua's built-in libraries:

```lua
-- Per-module
stringx.import()  -- string.capitalize(), ("hello"):strip()
mathx.import()    -- math.sign(), math.factorial()

-- All at once
luaswift.extend_stdlib()
-- Adds: math.complex, math.linalg, math.geo subnamespaces
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

For detailed API documentation, see the [docs/](docs/) folder:

- [Core API](docs/core-api.md) - LuaEngine, LuaValue, LuaValueServer
- [Value Servers](docs/value-servers.md) - Exposing Swift data to Lua
- [Callbacks](docs/callbacks.md) - Registering Swift functions
- [Coroutines](docs/coroutines.md) - Creating and managing coroutines
- [Threading](docs/threading.md) - Thread safety and engine pools
- [Engine Reuse](docs/engine-reuse.md) - Patterns for long-running engines
- [Modules](docs/modules/) - Detailed module documentation

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
