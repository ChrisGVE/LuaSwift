# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the package (default Lua 5.4)
swift build

# Build with specific Lua version
LUASWIFT_LUA_VERSION=55 swift build  # Lua 5.5
LUASWIFT_LUA_VERSION=54 swift build  # Lua 5.4 (default)

# Run all tests
swift test

# Run tests with specific Lua version
LUASWIFT_LUA_VERSION=55 swift test

# Run a specific test
swift test --filter LuaEngineTests/testValueServerWrite

# Run tests for a specific test class
swift test --filter LuaEngineTests

# Build for release
swift build -c release
```

## Multi-Version Lua Support

LuaSwift bundles multiple Lua versions selectable via environment variable:

| Env Value | Lua Version | Directory     | Status |
|-----------|-------------|---------------|--------|
| 51        | 5.1.5       | Sources/CLua51| Needs compat wrappers |
| 52        | 5.2.4       | Sources/CLua52| Needs compat wrappers |
| 53        | 5.3.6       | Sources/CLua53| Needs compat wrappers |
| 54        | 5.4.7       | Sources/CLua | **Default** |
| 55        | 5.5.0       | Sources/CLua55| Working |

## Release Process

### Automated Lua Updates (Weekly)
1. `.github/workflows/lua-version-check.yml` checks lua.org for new versions
2. If found: downloads sources, updates files, runs tests, creates PR
3. PR includes `lua-update` label and updates CHANGELOG.md

### Creating a Release
**Automatic (on Lua update PR merge to main):**
- `.github/workflows/release.yml` triggers automatically
- Bumps patch version (e.g., 1.2.0 → 1.2.1)
- Extracts notes from CHANGELOG.md `[Unreleased]` section
- Creates GitHub Release (picked up by Swift Package Index)

**Manual release:**
1. Go to Actions → "Create Release" → Run workflow
2. Select version bump type: patch / minor / major
3. Workflow creates tag and GitHub Release from CHANGELOG

### CHANGELOG Maintenance
- Keep `[Unreleased]` section updated with changes
- Lua version table is auto-updated by CI
- On release, `[Unreleased]` becomes the new version header
- **Never modify root LICENSE file** (GitHub license detection)

## Project Architecture

LuaSwift is a Swift wrapper around Lua for iOS/macOS. It bundles the complete Lua C source for App Store compliance (no external dependencies or downloaded code).

### Project Structure

```
Sources/
├── CLua/                    # Lua 5.4.7 C source (default)
├── CLua51/                  # Lua 5.1.5 C source
├── CLua52/                  # Lua 5.2.4 C source
├── CLua53/                  # Lua 5.3.6 C source
├── CLua55/                  # Lua 5.5.0 C source
│   ├── *.c                  # C implementation files
│   └── include/             # Header files + module.modulemap
└── LuaSwift/
    ├── LuaEngine.swift      # Main API: run(), evaluate(), register()
    ├── LuaValue.swift       # Type-safe enum for Lua values
    ├── LuaValueServer.swift # Protocol for exposing Swift data to Lua
    ├── LuaError.swift       # Error types
    ├── LuaHelpers.swift     # Swift wrappers for Lua C macros
    ├── CoroutineHandle.swift # Coroutine management
    ├── ProblemController.swift # Problem flow controller
    ├── LuaModules/          # Pure Lua modules
    │   ├── compat.lua       # Lua version compatibility
    │   ├── serialize.lua    # Table serialization
    │   └── math_expr.lua    # Math expression parsing (Lua parts)
    └── Modules/
        ├── ModuleRegistry.swift # Central module registration
        └── Swift/           # Swift-backed modules
            ├── ArrayModule.swift      # NumPy-like N-dimensional arrays
            ├── ComplexModule.swift    # Complex number arithmetic
            ├── DebugModule.swift      # Debugging utilities (DEBUG only)
            ├── GeometryModule.swift   # 2D/3D geometry with SIMD
            ├── IntegrateModule.swift  # Numerical integration (scipy-inspired)
            ├── JSONModule.swift       # JSON encode/decode
            ├── LinAlgModule.swift     # Linear algebra with Accelerate
            ├── MathExprModule.swift   # Math expression parsing
            ├── MathSciModule.swift    # Scientific computing namespace
            ├── MathXModule.swift      # Extended math functions
            ├── OptimizeModule.swift   # Numerical optimization (scipy-inspired)
            ├── PlotModule.swift       # matplotlib/seaborn-compatible plotting
            ├── RegexModule.swift      # Regular expressions
            ├── SlideRuleModule.swift  # Slide rule simulation
            ├── StringXModule.swift    # String utilities (Penlight-inspired)
            ├── SVGModule.swift        # SVG document generation
            ├── TableXModule.swift     # Table utilities (Penlight-inspired)
            ├── TOMLModule.swift       # TOML encode/decode
            ├── TypesModule.swift      # Type detection/conversion
            ├── UTF8XModule.swift      # UTF-8 string utilities
            └── YAMLModule.swift       # YAML encode/decode

Tests/LuaSwiftTests/
├── LuaEngineTests.swift     # Core engine tests
├── LuaValueTests.swift      # Value type tests
├── LuaCallbackTests.swift   # Swift callback tests
├── LuaCoroutineTests.swift  # Coroutine tests
├── LuaModuleTests.swift     # Pure Lua module tests
├── BenchmarkTests.swift     # Performance benchmarks
├── ProblemControllerTests.swift
├── SerializeModuleTests.swift
└── [Module]Tests.swift      # One test file per Swift module (22 total)
```

### Core Concepts

**LuaEngine**: Thread-safe wrapper managing the Lua state. Key methods:
- `run(_:)` - Execute Lua code, discard return value
- `evaluate(_:)` - Execute Lua code, return `LuaValue`
- `register(server:)` - Register a value server for Lua access
- `registerFunction(name:callback:)` - Register Swift function callable from Lua
- `unregisterFunction(name:)` - Remove registered function

**LuaValue**: Enum representing all Lua types (`string`, `number`, `bool`, `table`, `array`, `nil`). Supports Swift literals and provides convenience accessors (`.numberValue`, `.stringValue`, etc.).

**LuaValueServer**: Protocol for exposing Swift data to Lua scripts. Supports both read and write access:
- `resolve(path:)` - Return value for a path (required)
- `canWrite(path:)` - Check if path is writable (default: false)
- `write(path:value:)` - Handle writes (default: throws)

**Important**: For write support, `resolve()` must return `.nil` for intermediate paths so proxy tables with metamethods are created.

**Swift Callbacks**: Register Swift functions that Lua can call directly:
- Callbacks receive `[LuaValue]` arguments and return `LuaValue`
- Can throw errors that propagate to Lua
- Stored in thread-safe dictionary
- Use `lua_pushcclosure` with upvalues for engine pointer and function name

### C Interop Pattern

LuaHelpers.swift provides Swift wrappers for Lua C macros that Swift cannot import directly (e.g., `lua_pop`, `lua_newtable`, `lua_pcall`). These are marked `@inline(__always)` for performance.

The engine uses Lua metamethods (`__index`/`__newindex`) via C callbacks (`serverIndexCallback`/`serverNewIndexCallback`) to intercept value server access. Swift callbacks use `callbackTrampoline` C function. Engine pointer is stored in metatables/upvalues via `lua_pushlightuserdata`.

### Sandboxing

Default configuration removes dangerous functions:
- `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv`, `os.setlocale`
- `io.*`, `debug.*`
- `loadfile`, `dofile`, `load`, `loadstring`

Safe libraries remain: `math`, `string`, `table`, `coroutine`, `utf8`

### Thread Safety

`LuaEngine` uses `NSLock` for all public methods. For high concurrency, use engine pools rather than sharing a single instance.

### First Principle: "Inspired By" Library Portage

When porting functionality from established libraries (matplotlib, seaborn, scipy, numpy, pandas, statsmodels, manim, Penlight, or any other source), the following principles apply to ALL "inspired by" work:

**Algorithm/Implementation Fidelity:**
1. **Study the original implementation thoroughly** - Algorithms and design patterns are not copyrightable. Understanding how the original handles edge cases, error conditions, and complex scenarios is essential engineering.
2. **Implement equivalent robustness** - Naive or simplified implementations defeat the purpose. Port the same considerations for edge cases, error handling, and behavioral nuances.
3. **Use underlying algorithms when available** - Many core routines are **public domain** (e.g., QUADPACK, MINPACK, ODEPACK, FFTPACK for numerics). These can be studied and ported freely.

**Test Suite Portage:**
1. **Test cases are facts** - The expected behavior "function X with input Y produces output Z" is not owned by anyone. Port test scenarios and expected outcomes.
2. **Use standard test cases** - Mathematical facts (∫sin(x)dx from 0 to π = 2), well-known test problems (Rosenbrock for optimization), edge cases (empty inputs, boundary values).
3. **Cover the same edge cases** - If the original tests for specific error conditions, malformed inputs, or corner cases, our tests should too.

**Licensing Approach:**
| Source License | Approach |
|----------------|----------|
| Public Domain | Study and port freely |
| BSD-3-Clause (scipy, numpy, matplotlib) | Study implementation, implement in Swift/Lua, attribute if directly inspired |
| MIT (Penlight, many JS libs) | Study and port with attribution |
| GPL | Study patterns only, clean-room implementation |

**Quality Standard:**
- Lesser work defeats the purpose of providing robust Lua capabilities
- If we can't match the robustness of the original, document limitations clearly
- Every "inspired by" module must have its algorithms/implementation AND test suite reviewed against the original

### Swift-Backed Module Replacements

When replacing a pure Lua module with a Swift-backed module, it **must be a complete drop-in replacement**:

1. **API Surface**: All functions, methods, and properties must have identical signatures
2. **Behavior**: The module must behave identically to the original Lua implementation
3. **Functionality**: All features of the original must be replicated entirely

Swift optimizations are encouraged but must not affect observable behavior. The replacement module should pass all tests written for the original Lua module without modification.

**Process:**
1. Study the original Lua module thoroughly before implementing
2. Match all function signatures exactly (parameter order, optional parameters, return values)
3. Replicate all internal behaviors (e.g., nested groups returning group objects, not self)
4. Delete the original Lua file only after the Swift version is verified complete
5. Never mark the Lua module as "deprecated" - either fully replace it or don't
