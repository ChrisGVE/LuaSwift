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
        └── Swift/           # Swift-backed modules (31 files)
            # Scientific computing (math.* namespace)
            ├── ArrayModule.swift        # NumPy-like N-dimensional arrays
            ├── LinAlgModule.swift       # Linear algebra with Accelerate
            ├── ComplexModule.swift      # Complex number arithmetic
            ├── ComplexHelper.swift      # Complex number utilities
            ├── DistributionsModule.swift # Probability distributions
            ├── IntegrateModule.swift    # Numerical integration
            ├── InterpolateModule.swift  # Spline/polynomial interpolation
            ├── OptimizeModule.swift     # Numerical optimization
            ├── RegressModule.swift      # Regression analysis
            ├── ClusterModule.swift      # Clustering algorithms
            ├── SpatialModule.swift      # KDTree, Voronoi, Delaunay
            ├── SeriesModule.swift       # Taylor series, summation
            ├── SpecialModule.swift      # Gamma, Bessel, error functions
            ├── NumberTheoryModule.swift # Primes, factorization
            ├── GeometryModule.swift     # 2D/3D geometry with SIMD
            ├── MathXModule.swift        # Extended math functions
            ├── MathSciModule.swift      # Scientific computing namespace
            ├── MathExprModule.swift     # Math expression parsing
            # Data formats
            ├── JSONModule.swift         # JSON encode/decode
            ├── YAMLModule.swift         # YAML encode/decode
            ├── TOMLModule.swift         # TOML encode/decode
            # Visualization
            ├── PlotModule.swift         # matplotlib-compatible plotting
            ├── SVGModule.swift          # SVG document generation
            # String/Table utilities (Penlight-inspired)
            ├── StringXModule.swift      # String utilities
            ├── TableXModule.swift       # Table utilities
            ├── UTF8XModule.swift        # UTF-8 string utilities
            ├── RegexModule.swift        # Regular expressions
            # System/Utilities
            ├── TypesModule.swift        # Type detection/conversion
            ├── IOModule.swift           # File I/O (opt-in)
            ├── HTTPModule.swift         # HTTP client (opt-in)
            └── DebugModule.swift        # Debugging utilities

Tests/LuaSwiftTests/
├── LuaEngineTests.swift     # Core engine tests
├── LuaValueTests.swift      # Value type tests
├── LuaCallbackTests.swift   # Swift callback tests
├── LuaCoroutineTests.swift  # Coroutine tests
├── LuaModuleTests.swift     # Pure Lua module tests
├── BenchmarkTests.swift     # Performance benchmarks
├── ProblemControllerTests.swift
├── SerializeModuleTests.swift
└── [Module]Tests.swift      # One test file per Swift module (23 total)
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

**Performance & Precision:**
- No compromise on precision or optimization compared to the inspiration source (licensing permitting)
- Use hardware-accelerated libraries (BLAS, LAPACK via Accelerate) wherever the original does
- If Fortran sources are missing from the platform, bring them in as needed

**Implementation Language:**
- All module logic must be implemented in Swift (or C/Fortran when required for performance)
- Only the Lua API entry points should be in Lua - no algorithmic code in Lua
- This ensures modules are available to Swift applications directly, not just via Lua

### Second Principle: Cross-Library Module Interactions

When Swift modules within LuaSwift interact with each other (or with future extracted Swift libraries), the following principles apply:

**Invisible to Lua API:**
- Cross Swift library/module interactions are implementation details invisible to Lua scripts
- Lua code sees only the public API of each module; internal Swift-to-Swift communication is transparent
- Example: PlotModule may use ArrayModule internally for data handling, but Lua scripts interact with each independently

**Optional Dependencies:**
- Cross-module functionality creates optional dependencies
- If a dependent module is not compiled/available, related functionality is gracefully unavailable
- Modules must handle missing dependencies without crashing (check availability, provide meaningful errors)
- Example: If PlotModule is compiled without ArrayModule, array-based plotting features are unavailable

**Deferring Complex API Elements:**
- API elements that are unnecessarily complex for a Lua library context can be deferred
- Create tasks in task-master under the `Swift-API` tag for:
  - Features that make sense only for Swift consumers
  - Advanced features requiring complex type systems not expressible in Lua
  - Performance optimizations that add API complexity
- The Lua API remains clean and approachable; Swift API can be richer

**Practical Implications:**
1. Design modules with clear boundaries for optional features
2. Use Swift's `#if` or runtime checks for optional module availability
3. Document which features require which module combinations
4. Keep the Lua API surface minimal and idiomatic

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

### Strategic Direction: Swift Module Independence

**Vision:** All Swift-backed modules in LuaSwift are on a trajectory to become **independent Swift libraries**. Once extracted, LuaSwift will consume these libraries as optional dependencies, providing thin Lua binding shims.

**Current State (Tactical):**
- Swift modules are developed within LuaSwift for convenience
- Modules are implemented in Swift with Lua API entry points
- Tests cover both Swift functionality and Lua bindings

**Future State (Strategic):**
- Each major Swift module becomes its own Swift Package (e.g., `SwiftArray`, `SwiftLinAlg`, `SwiftDistributions`)
- These packages have no Lua dependency - pure Swift APIs
- LuaSwift becomes a thin integration layer:
  - Imports the Swift packages as dependencies
  - Provides Lua bindings via the existing shim pattern
  - Handles type conversion between Lua values and Swift types

**Implications for Development:**
1. **API Design**: Design Swift APIs first, then wrap for Lua. Never let Lua idioms drive Swift API design.
2. **Type System**: Swift modules should use proper Swift types (generics, protocols, enums). Lua bindings handle conversion.
3. **Dependencies**: Swift modules may depend on each other (e.g., Distributions depends on Array). Plan the dependency graph.
4. **Testing**: Write Swift-native tests in addition to Lua integration tests. Swift tests travel with the extracted package.
5. **Documentation**: Document the Swift API independently. Lua binding docs reference the Swift docs.

**Module Extraction Priority** (based on standalone utility and downstream dependencies):
1. **ArrayModule** → `SwiftNDArray` - Foundation for scientific computing; statsmodels, scipy equivalents depend on it
2. **LinAlgModule** → `SwiftLinAlg` - Matrix operations; may merge with or depend on NDArray
3. **ComplexModule** → `SwiftComplex` - Complex number support; integrates with NDArray for complex arrays
4. **DistributionsModule** → `SwiftDistributions` - Probability distributions; depends on Array
5. **IntegrateModule** → `SwiftIntegrate` - Numerical integration; depends on Array
6. **OptimizeModule** → `SwiftOptimize` - Optimization; depends on Array, LinAlg
7. **GeometryModule** → `SwiftGeometry` - 2D/3D geometry with SIMD
8. **MathXModule** → `SwiftMathX` - Extended math functions
9. Utility modules (JSON, TOML, YAML, Regex, StringX, etc.) - Lower priority, many Swift alternatives exist

**Critical Path**: ArrayModule is foundational. Its architecture (especially dtype support) affects all dependent modules. Prioritize getting Array right before extracting others.
