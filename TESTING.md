# Testing Guide

This document explains how to run LuaSwift tests with different configurations.

## Quick Start

```bash
# Run all tests with defaults (Lua 5.4, all optional dependencies)
swift test

# Run a specific test class
swift test --filter LuaEngineTests

# Run a specific test
swift test --filter LuaEngineTests/testEvaluateReturnsValue
```

## Lua Version Testing

LuaSwift supports Lua versions 5.1 through 5.5. Use the `LUASWIFT_LUA_VERSION` environment variable to select which version to test against:

```bash
# Test with Lua 5.1
LUASWIFT_LUA_VERSION=51 swift test

# Test with Lua 5.2
LUASWIFT_LUA_VERSION=52 swift test

# Test with Lua 5.3
LUASWIFT_LUA_VERSION=53 swift test

# Test with Lua 5.4 (default)
LUASWIFT_LUA_VERSION=54 swift test

# Test with Lua 5.5
LUASWIFT_LUA_VERSION=55 swift test
```

### Version-Specific Features

Different Lua versions have different features. The `compat.lua` module provides compatibility shims:

| Feature | 5.1 | 5.2 | 5.3 | 5.4 | 5.5 |
|---------|-----|-----|-----|-----|-----|
| `bit32` library | - | Native | Compat | Compat | Compat |
| `utf8` library | - | - | Native | Native | Native |
| Bitwise operators | - | - | Native | Native | Native |
| `table.unpack` | - | Native | Native | Native | Native |
| `goto` statement | - | Native | Native | Native | Native |
| `loadstring` | Native | Native | - | - | - |
| `setfenv`/`getfenv` | Native | - | - | - | - |
| Integer division `//` | - | - | Native | Native | Native |
| `warn` function | - | - | - | Native | Native |
| `<close>` variables | - | - | - | Native | Native |

The `LuaVersionTests.swift` file contains tests that validate these version-specific behaviors using conditional compilation (`#if LUA_VERSION_*`).

## Optional Dependency Testing

LuaSwift has three optional dependencies: NumericSwift, ArraySwift, and PlotSwift. Use environment variables to include or exclude them:

```bash
# Test without any optional dependencies (core only)
LUASWIFT_INCLUDE_NUMERICSWIFT=0 \
LUASWIFT_INCLUDE_ARRAYSWIFT=0 \
LUASWIFT_INCLUDE_PLOTSWIFT=0 \
swift test

# Test with only ArraySwift
LUASWIFT_INCLUDE_NUMERICSWIFT=0 \
LUASWIFT_INCLUDE_ARRAYSWIFT=1 \
LUASWIFT_INCLUDE_PLOTSWIFT=0 \
swift test

# Test with all dependencies (default)
swift test
```

### Writing Dependency-Conditional Tests

Use `#if LUASWIFT_*` guards for tests that require optional dependencies:

```swift
#if LUASWIFT_ARRAYSWIFT
func testArrayModuleAvailable() throws {
    let engine = try LuaEngine()
    ModuleRegistry.installModules(in: engine)
    let result = try engine.evaluate("return luaswift.array ~= nil")
    XCTAssertTrue(result.boolValue ?? false)
}
#else
func testArrayModuleNotAvailable() throws {
    let engine = try LuaEngine()
    ModuleRegistry.installModules(in: engine)
    let result = try engine.evaluate("return luaswift.array == nil")
    XCTAssertTrue(result.boolValue ?? false)
}
#endif
```

See `OptionalDependencyTests.swift` for comprehensive examples.

## CI Test Matrix

The CI runs two test matrices:

### Dependency Combinations (8 jobs)

Tests all permutations of optional dependencies with default Lua 5.4:

| Job | NumericSwift | ArraySwift | PlotSwift |
|-----|--------------|------------|-----------|
| Standalone | - | - | - |
| NumericSwift | Yes | - | - |
| ArraySwift | - | Yes | - |
| PlotSwift | - | - | Yes |
| N+A | Yes | Yes | - |
| N+P | Yes | - | Yes |
| A+P | - | Yes | Yes |
| N+A+P | Yes | Yes | Yes |

### Lua Versions (5 jobs)

Tests all Lua versions with full dependencies (N+A+P):

- Lua 5.1
- Lua 5.2
- Lua 5.3
- Lua 5.4
- Lua 5.5

Total: 13 CI jobs per push/PR.

## Writing Version-Conditional Tests

Use `#if LUA_VERSION_*` guards for tests that depend on Lua version:

```swift
func testBitwiseOperators() throws {
    let engine = try LuaEngine()

    #if LUA_VERSION_51 || LUA_VERSION_52
    // Bitwise operators don't exist - use bit32 library
    let result = try engine.evaluate("""
        local compat = require('compat')
        return compat.bit32.band(5, 3)
    """)
    XCTAssertEqual(result.intValue, 1)
    #else
    // Bitwise operators exist in 5.3+
    let result = try engine.evaluate("return 5 & 3")
    XCTAssertEqual(result.intValue, 1)
    #endif
}
```

## Pure Lua Tests

LuaSwift includes a pure Lua test suite in `Tests/LuaTests/`:

- `run_tests.lua` - Test runner framework
- `test_compat.lua` - Tests for compat.lua module
- `test_serialize.lua` - Tests for serialize.lua module

### Running via Swift

```bash
swift test --filter LuaTestRunnerTests
```

### Running Standalone

The Lua tests can run with any standard Lua interpreter:

```bash
cd Tests/LuaTests

# Run with system Lua (adjust path as needed)
lua5.4 -e "
    package.path = '?.lua;../../Sources/LuaSwift/LuaModules/?.lua'
    local T = require('run_tests')
    T.verbose = true
    T.reset()
    dofile('test_compat.lua')
    dofile('test_serialize.lua')
    T.print_summary()
"
```

### Writing Lua Tests

Use the test runner framework:

```lua
local T = require("run_tests")

T.suite("my_module")

T.test("basic functionality", function()
    T.assert_equal(1 + 1, 2)
    T.assert_true(true)
    T.assert_not_nil("hello")
end)

T.test("approximate equality", function()
    T.assert_approx(math.pi, 3.14159, 0.001)
end)
```

## Test Organization

```
Tests/
├── LuaSwiftTests/           # Swift XCTest tests
│   ├── LuaEngineTests.swift      # Core engine tests
│   ├── LuaValueTests.swift       # Value type tests
│   ├── LuaVersionTests.swift     # Version-specific tests
│   ├── LuaTestRunnerTests.swift  # Runs Lua tests via Swift
│   ├── OptionalDependencyTests.swift
│   ├── [Module]Tests.swift       # One per Swift module
│   └── ...
└── LuaTests/                # Pure Lua tests
    ├── run_tests.lua             # Test runner framework
    ├── test_compat.lua           # compat.lua tests
    └── test_serialize.lua        # serialize.lua tests
```

## Debugging Test Failures

### View Detailed Output

```bash
swift test --verbose
```

### Run Single Test with Debug Output

```bash
swift test --filter "LuaEngineTests/testEvaluateReturnsValue" 2>&1
```

### Check Lua Version Being Used

```swift
func testLuaVersion() throws {
    let engine = try LuaEngine()
    let result = try engine.evaluate("return _VERSION")
    print("Lua version: \(result.stringValue ?? "unknown")")
}
```

## Performance Testing

Benchmarks are in `BenchmarkTests.swift`:

```bash
swift test --filter BenchmarkTests
```

Note: Benchmark tests may take longer. They measure operations like:
- Rapid engine creation/destruction
- Many evaluations
- Large table handling
- Callback performance
