# LuaSwift Documentation

[← Back to README](../README.md)

## Overview

LuaSwift is a lightweight Swift wrapper for embedding Lua in iOS and macOS applications. This documentation covers the core API, optional powerpack modules, and advanced usage patterns.

## Quick Navigation

### Core Wrapper

| Topic | Description |
|-------|-------------|
| [Core API](core-api.md) | LuaEngine, LuaValue, LuaValueServer, error handling |
| [Value Servers](value-servers.md) | Exposing Swift data to Lua (read/write) |
| [Callbacks](callbacks.md) | Registering Swift functions callable from Lua |
| [Coroutines](coroutines.md) | Creating and managing Lua coroutines |

### Advanced Usage

| Topic | Description |
|-------|-------------|
| [Threading](threading.md) | Thread safety, engine pools, async/await |
| [Engine Reuse](engine-reuse.md) | Patterns for long-running engines, state management |

### Modules

| Category | Description |
|----------|-------------|
| [Module Index](modules/index.md) | Complete module reference |
| [Standard Library Extensions](modules/stdlib.md) | stringx, tablex, utf8x, compat |
| [Data Formats](modules/data-formats.md) | JSON, YAML, TOML |
| [Math Namespace](modules/math.md) | linalg, complex, geo, special, stats, etc. |
| [Array](modules/array.md) | NumPy-like N-dimensional arrays |
| [Visualization](modules/visualization.md) | plot, svg |
| [External Access](modules/external.md) | iox (file I/O), http (network) |

## Getting Started

### 1. Wrapper Only

```swift
import LuaSwift

let engine = try LuaEngine()
let result = try engine.evaluate("return 1 + 2")
print(result.numberValue!)  // 3.0
```

### 2. With Powerpack

```swift
let engine = try LuaEngine()
ModuleRegistry.installModules(in: engine)
try engine.run("luaswift.extend_stdlib()")

// Now all modules are available
try engine.run("""
    local m = math.linalg.matrix({{1,2},{3,4}})
    print(m:det())  -- -2
""")
```

### 3. Selective Installation

```swift
let engine = try LuaEngine()

// Install only what you need
ModuleRegistry.installJSONModule(in: engine)
ModuleRegistry.installStringXModule(in: engine)
```

## Architecture

```
LuaSwift
├── Core Wrapper (always available)
│   ├── LuaEngine        - Execute Lua code
│   ├── LuaValue         - Type-safe values
│   └── LuaValueServer   - Expose Swift data
│
└── Powerpack Modules (optional)
    ├── Standard Library Extensions
    │   ├── stringx      → extends string.*
    │   ├── tablex       → extends table.*
    │   ├── utf8x        → extends utf8.*
    │   └── compat       - version compatibility
    │
    ├── Data Formats
    │   ├── json
    │   ├── yaml
    │   └── toml
    │
    ├── Math (unified namespace after extend_stdlib)
    │   ├── math.linalg
    │   ├── math.complex
    │   ├── math.geo
    │   ├── math.special
    │   ├── math.stats
    │   ├── math.distributions
    │   ├── math.optimize
    │   ├── math.integrate
    │   ├── math.interpolate
    │   ├── math.cluster
    │   ├── math.spatial
    │   ├── math.regress
    │   ├── math.series
    │   ├── math.eval
    │   ├── math.constants
    │   └── math.numtheory
    │
    ├── Array (standalone)
    │   └── array        - NumPy-like arrays
    │
    ├── Visualization
    │   ├── plot         - matplotlib-style
    │   └── svg          - SVG generation
    │
    ├── Pattern Matching
    │   └── regex        - ICU regex
    │
    └── External Access (opt-in)
        ├── iox          - sandboxed file I/O
        └── http         - HTTP client
```

## Module Dependencies

Most modules are independent, but some have dependencies:

| Module | Requires |
|--------|----------|
| math.distributions | math.special |
| math.regress | math.linalg |
| math.series | math.eval (MathExprModule) |
| math.cluster | (uses array internally) |
| math.spatial | (uses array internally) |
| plot | svg |

## Configuration Reference

```swift
LuaEngineConfiguration(
    sandboxed: Bool = true,        // Remove dangerous functions
    packagePath: String? = nil,    // Custom require() path
    memoryLimit: Int = 0           // Bytes, 0 = unlimited
)
```

**Preset configurations:**
- `.default` - sandboxed, no memory limit
- `.unrestricted` - full Lua access (use with caution)

## Lua Version Support

| Version | Env Variable | Notes |
|---------|--------------|-------|
| 5.4.7 | `LUASWIFT_LUA_VERSION=54` | Default, recommended |
| 5.5.0 | `55` | Latest features |
| 5.3.6 | `53` | Integer subtype |
| 5.2.4 | `52` | Goto statement |
| 5.1.5 | `51` | Maximum compatibility |

---

[← Back to README](../README.md) | [Core API →](core-api.md)
