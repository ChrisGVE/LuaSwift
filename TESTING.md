# Testing Guide

This document explains how to run LuaSwift tests with different configurations.

## Quick Start

```bash
# Run all tests with the default dependency set (Lua 5.4; Yams ON, everything
# else OFF). Only Yams is enabled by default — the other optional dependencies
# are opt-in:
#   LUASWIFT_INCLUDE_YAMS         default 1  (opt-out: set to 0)
#   LUASWIFT_INCLUDE_TOMLKIT      default 0  (opt-in:  set to 1)
#   LUASWIFT_INCLUDE_NUMERICSWIFT default 0  (opt-in:  set to 1)
#   LUASWIFT_INCLUDE_ARRAYSWIFT   default 0  (opt-in:  set to 1)
#   LUASWIFT_INCLUDE_PLOTSWIFT    default 0  (opt-in:  set to 1)
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

LuaSwift has five optional dependencies: Yams, TOMLKit, NumericSwift, ArraySwift, and PlotSwift. Use environment variables to include or exclude them:

```bash
# Test without any optional dependencies (core only, JSON as sole data format)
LUASWIFT_INCLUDE_YAMS=0 \
LUASWIFT_INCLUDE_TOMLKIT=0 \
LUASWIFT_INCLUDE_NUMERICSWIFT=0 \
LUASWIFT_INCLUDE_ARRAYSWIFT=0 \
LUASWIFT_INCLUDE_PLOTSWIFT=0 \
swift test

# Test with only ArraySwift
LUASWIFT_INCLUDE_YAMS=0 \
LUASWIFT_INCLUDE_TOMLKIT=0 \
LUASWIFT_INCLUDE_NUMERICSWIFT=0 \
LUASWIFT_INCLUDE_ARRAYSWIFT=1 \
LUASWIFT_INCLUDE_PLOTSWIFT=0 \
swift test

# Test with every optional dependency enabled (NOT the default — the bare
# `swift test` enables only Yams)
LUASWIFT_INCLUDE_TOMLKIT=1 \
LUASWIFT_INCLUDE_NUMERICSWIFT=1 \
LUASWIFT_INCLUDE_ARRAYSWIFT=1 \
LUASWIFT_INCLUDE_PLOTSWIFT=1 \
swift test
```

### Writing Dependency-Conditional Tests

Use `#if LUASWIFT_*` guards for tests that require optional dependencies:

```swift
#if LUASWIFT_ARRAYSWIFT
func testArrayModuleAvailable() throws {
    let engine = try LuaEngine()
    try ModuleRegistry.install(in: engine)
    let result = try engine.evaluate("return luaswift.array ~= nil")
    XCTAssertTrue(result.boolValue ?? false)
}
#else
func testArrayModuleNotAvailable() throws {
    let engine = try LuaEngine()
    try ModuleRegistry.install(in: engine)
    let result = try engine.evaluate("return luaswift.array == nil")
    XCTAssertTrue(result.boolValue ?? false)
}
#endif
```

See `OptionalDependencyTests.swift` for comprehensive examples.

## CI Test Matrix

The CI workflow (`.github/workflows/ci.yml`) runs the test suite across several
jobs. A `setup-matrix` job first generates the dependency and Lua-version
matrices from `scripts/test-matrix.json`; the test jobs then fan out from it.
Every matrix cell runs `swift test --skip Benchmark` — the perf benchmarks run
only in the dedicated report-only `benchmarks` job (below).

### Dependency Combinations — `test-combinations` (8 jobs)

Tests all permutations of the three sibling-checkout optional dependencies with
the default Lua 5.4 (and the default Yams=ON / TOMLKit=OFF). `8 = 2³` (three
optional deps):

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

### Lua Versions — `test-lua-versions` (5 jobs)

Tests all Lua versions with full sibling dependencies (N+A+P):

- Lua 5.1
- Lua 5.2
- Lua 5.3
- Lua 5.4
- Lua 5.5

### Toggle dependencies — `test-toggles` (2 jobs)

A single data-driven job that exercises the pure-SwiftPM toggle dependencies
defined under `toggle_dependencies` in `scripts/test-matrix.json`. Each entry
flips one dependency away from its default value and runs once:

- `LUASWIFT_INCLUDE_YAMS=0` — Yams is the only opt-out dependency (ON by
  default), so this covers the no-YAML build path the `test-combinations`
  matrix never reaches.
- `LUASWIFT_INCLUDE_TOMLKIT=1` — TOMLKit is OFF by default, so this covers the
  opt-in TOML build path.

Both are pure SPM dependencies (no sibling checkout). The
`LUASWIFT_INCLUDE_THALES` opt-in build is currently disabled (issue #18) and is
intentionally excluded until the upstream API stabilises.

### Documentation — `docs` (required)

Runs `swift package generate-documentation` for the `LuaSwift` target so broken
article links or unresolved symbol references fail CI instead of slipping into
the published docs. A single default-config build suffices — the public API
surface is identical across Lua versions (the version is a build-time C-source
swap), and optional dependencies only add symbols. This is a required gate,
wired into `all-tests`.

### Summary gate — `all-tests`

Aggregates `test-combinations`, `test-lua-versions`, `test-toggles`, and
`docs`; it fails the run if any of them failed. This is the job that gates a
push/PR.

### Benchmarks — `benchmarks` (report-only)

Runs `swift test --filter Benchmark` once on the default Lua version with all
optional dependencies enabled. It is **report-only**: it uses
`continue-on-error` and is deliberately NOT in the `all-tests` `needs` list, so
it surfaces hook/cancellation/debug overhead timings without ever gating the
build (macOS-runner timing variance makes a hard gate unreliable for now).

Total: 13 matrix jobs (`8 + 5`) plus the `test-toggles` (×2), `docs`,
`setup-matrix`, `all-tests`, and report-only `benchmarks` jobs per push/PR.

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

## Test Scripts

LuaSwift provides comprehensive test scripts for running the full test matrix locally.

### Prerequisites

The scripts require `jq` for JSON parsing:

```bash
brew install jq
```

### Quick Test

Run a quick test on the default Lua version (5.4) with all three
sibling-clone optional dependencies enabled (NumericSwift, ArraySwift,
PlotSwift). The pure-SwiftPM toggle dependencies stay at their `Package.swift`
defaults (Yams ON, TOMLKit OFF):

```bash
./scripts/run-all-tests.sh --quick
```

### Full Test Matrix

Run the complete test matrix (all Lua versions × all dependency combinations):

```bash
# Sequential execution (slower but easier to debug)
./scripts/run-all-tests.sh

# Parallel execution (faster)
./scripts/run-all-tests.sh --parallel
```

### Partial Test Runs

```bash
# Test all dependency combinations with default Lua 5.4
./scripts/run-all-tests.sh --deps-only

# Test all Lua versions with all dependencies
./scripts/run-all-tests.sh --lua-only

# Test a specific Lua version
./scripts/run-all-tests.sh --lua 51

# Test a specific dependency combination (N=1, A=0, P=1 means NumericSwift+PlotSwift)
./scripts/run-all-tests.sh --combo "1 0 1"
```

### Legacy Script

The original dependency combinations script is still available:

```bash
# Test all 8 dependency combinations
./scripts/test-combinations.sh

# Run in parallel
./scripts/test-combinations.sh --parallel
```

## Centralized Configuration

Test configuration is centralized in `scripts/test-matrix.json`. Both the local test scripts and GitHub CI workflow read from this file.

```json
{
  "lua_versions": [
    {"code": "51", "name": "Lua 5.1"},
    {"code": "52", "name": "Lua 5.2"},
    ...
  ],
  "default_lua_version": "54",
  "optional_dependencies": [
    {
      "short": "N",
      "name": "NumericSwift",
      "env_var": "LUASWIFT_INCLUDE_NUMERICSWIFT",
      "repo": "https://github.com/ChrisGVE/NumericSwift.git"
    },
    ...
  ]
}
```

## Adding a New Optional Dependency

To add a new optional dependency (e.g., `StatSwift`):

1. **Update `scripts/test-matrix.json`**:
   ```json
   {
     "optional_dependencies": [
       ... existing deps ...,
       {
         "short": "S",
         "name": "StatSwift",
         "env_var": "LUASWIFT_INCLUDE_STATSWIFT",
         "repo": "https://github.com/ChrisGVE/StatSwift.git"
       }
     ]
   }
   ```

2. **Update `Package.swift`**:
   ```swift
   let includeStatSwift = ProcessInfo.processInfo.environment["LUASWIFT_INCLUDE_STATSWIFT"] != "0"

   // In dependencies:
   if includeStatSwift {
       deps.append(.package(url: "https://github.com/ChrisGVE/StatSwift.git", from: "0.1.0"))
   }

   // In target dependencies:
   if includeStatSwift {
       deps.append("StatSwift")
   }

   // In swiftSettings:
   if includeStatSwift {
       settings.append(.define("LUASWIFT_STATSWIFT"))
   }
   ```

3. **Write conditional code and tests**:
   ```swift
   #if LUASWIFT_STATSWIFT
   import StatSwift
   // ... module implementation
   #endif
   ```

The CI workflow and test scripts will automatically pick up the new dependency and generate the expanded test matrix (2^n combinations where n = number of optional dependencies).

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

## Maintainer Runbook

Operational notes for keeping the test suite and CI healthy.

### Triaging flaky tests

The suite is designed to be hermetic — there are no tests that depend on the
network or on real filesystem state.

- **HTTP tests are in-process.** `HTTPModuleTests.swift` runs against
  `MockHTTPServer.swift`, an in-process HTTP server bound to `127.0.0.1` on an
  ephemeral port — no external network and no live endpoint. A failure here is
  a real regression, not flakiness. To debug one:
  - Run the single test in isolation, e.g.
    `swift test --filter HTTPModuleTests/<testName> 2>&1`.
  - The mock server logs the requests it received and the canned responses it
    returned; inspect that exchange to see whether the failure is on the
    request side (module built the wrong request) or the response side (module
    mis-parsed a well-formed response).
  - If a test intermittently fails to bind, suspect a port/teardown race in the
    mock server lifecycle (server not fully stopped between tests) rather than
    the HTTP module itself.
- **General flakiness.** Filesystem scenarios must always be mocked, never run
  against the real filesystem; if a test touches the filesystem, fix the test
  to mock it rather than retrying. Reproduce locally with the exact
  `LUASWIFT_LUA_VERSION` and `LUASWIFT_INCLUDE_*` flags from the failing CI cell
  (the job name encodes them) so the build configuration matches.

### Benchmark regressions

The `benchmarks` CI job is **intentionally report-only** (`continue-on-error`,
and not part of the `all-tests` gate) because macOS-runner timing variance makes
a hard pass/fail threshold unreliable. So a benchmark "regression" never fails
CI on its own.

- Treat the benchmark numbers as a trend, not a gate. A single slow run on a
  shared CI runner is usually noise.
- To investigate a suspected real regression, run the benchmarks locally on a
  quiescent machine for a stable baseline:
  `swift test --filter Benchmark` (enable the relevant `LUASWIFT_INCLUDE_*`
  flags so the dependency-gated benchmarks run too).
- If and when a stable baseline is established, the job can be tightened into a
  hard gate (see the comment on the `benchmarks` job in `ci.yml`).

### When the automated Lua-source-update PR fails

The `lua-version-check` workflow (`.github/workflows/lua-version-check.yml`)
runs weekly: it checks `lua.org/ftp` for new releases in each 5.x series, and if
any are found it downloads the new sources into the matching `CLua*` directory,
updates the version comments/tables, runs the suite with Lua 5.4 and 5.5, and
opens a PR (branch `lua-version-update`, labels `lua-update`/`automated-pr`).

If that workflow fails or the PR is red:

- **Tests fail on the new sources.** The new Lua release likely changed an API
  or behaviour. Check the upstream Lua release notes for the affected series,
  reconcile the wrapper/module code, and update or add the affected tests —
  fix the root cause, do not skip the test. Re-run the failing version locally
  with `LUASWIFT_LUA_VERSION=<code> swift test`.
- **The download/copy step fails.** Confirm the tarball exists at
  `https://www.lua.org/ftp/lua-<version>.tar.gz` and that the `BUNDLED` map and
  the `SERIES → TARGET_DIR` case in the workflow still cover the series.
- **The root `LICENSE` was touched.** The workflow guards this explicitly (only
  `CLua*/LICENSE` files are managed, never the repo-root `LICENSE`, which
  GitHub uses for license detection). If the verify step reports a change, it
  restores the file; ensure the restore actually ran before merging.
- **Recovery.** The update is mechanical and reproducible — you can reproduce it
  by hand by following the workflow steps for the affected `CLua*` directory, or
  re-trigger the workflow via `workflow_dispatch` once the underlying issue is
  fixed.
