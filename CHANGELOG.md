# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Top-level JSON scalars decode** - `json.decode` now accepts bare top-level JSON values (`null`, numbers, strings, booleans) via `.fragmentsAllowed` instead of throwing, completing the JSON-`null` round-trip symmetry (`decode(encode(json.null))` now reproduces the sentinel).
- **Build without Yams** - Fixed compilation and test failures under `LUASWIFT_INCLUDE_YAMS=0` (the optional-dependency-free "nimble" build): the YAML `require()` test now compiles only with Yams, and the optional-dependency tests no longer assert `luaswift.yaml` as unconditionally available.
- **iOS alert dismissal delegate** - The alert dismissal delegate is now assigned after presentation begins, so interactive dismissals (notably iPad popover-backed action sheets) are detected promptly instead of relying on the watchdog fallback.

## [1.9.0] - 2026-05-31

### Added
- **Symmetric JSON `null`** - Decoding a JSON `null` now yields a truthy `luaswift.json.null` marker table instead of Lua `nil`, so object keys with `null` values are preserved across a decode/encode round-trip. Encoding the marker (or `luaswift.json.null`) emits `null`. Test membership with `luaswift.json.is_null(v)`. Only a single-key marker table is treated as `null` (collision guard), so ordinary tables are unaffected.

### Changed
- **`bit32` deprecation gate** - The `bit32` compatibility shim now emits its deprecation warning from Lua 5.3 onward (previously 5.4+), matching when upstream Lua deprecated the library.
- **Hermetic HTTP tests** - The HTTP module test suite now runs against an in-process httpbin-compatible server instead of live third-party hosts, making it deterministic and network-independent. No change to the shipped `luaswift.http` API.

### Fixed
- **iOS alert deadlock** - Fixed a main-thread deadlock when presenting the UI `alert`/confirm dialog on iOS. The presentation wait now terminates on every path: button tap (idempotent completion), interactive dismissal, programmatic dismissal, and a watchdog for the never-presented case.
- **`require()` access for Swift-backed modules** - Registered `package.loaded` entries so `require("luaswift.<module>")` resolves the same instances as the `luaswift.*` globals for every module exposed under that namespace (`array`, `complex`, `debug`, `geometry`, `http`, `iox`, `json`, `linalg`, `math`/`mathx`, `mathexpr`, `plot`, `regex`, `stringx`, `svg`, `tablex`, `toml`, `types`, `ui`, `utf8x`, `yaml`, plus `cas` when Thales is enabled). The SciPy-style scientific modules are reached through the `math.*` namespace (e.g. `math.stats`, `math.integrate`) rather than a `luaswift.<name>` require path.
- **`linalg.norm` string orders** - `norm` now accepts string orders (`"fro"`, `"inf"`) and rejects unsupported orders with a clear error instead of misbehaving.

### Documentation
- **Module docs rewrite** - All module articles in the DocC catalog were rewritten to match the current implementation.

## [1.8.5] - 2026-05-30

### Changed
- **License header consistency** - Corrected source-file license headers to match the project's Apache License 2.0 (LICENSE). Stale `Licensed under the MIT License` headers in 74 Swift/Lua source and test files were replaced with `SPDX-License-Identifier: Apache-2.0`. Bundled Lua C sources retain their own (correct) MIT license.

## [1.8.4] - 2026-05-30

### Changed
- **Repository hygiene** - Stopped tracking developer-local files (`CLAUDE.md`, `code_audit.md`) in version control; these are now ignored locally. No public-facing or packaged code is affected.

## [1.8.3] - 2026-05-30

### Changed
- **Optional dependency defaults flipped to OFF** - NumericSwift, ArraySwift, PlotSwift, and TOMLKit are now excluded by default; only Yams (YAML) remains on by default. Set the corresponding `LUASWIFT_INCLUDE_*=1` env var to opt in. This makes the default build lighter; opt into the scientific-computing and TOML stacks explicitly.

## [1.8.2] - 2026-05-30

### Changed
- **Optional Data-Format Dependencies** - Yams (YAML) and TOMLKit (TOML) are now optional dependencies, following the same env-var pattern as NumericSwift/ArraySwift/PlotSwift. Set `LUASWIFT_INCLUDE_YAMS=0` or `LUASWIFT_INCLUDE_TOMLKIT=0` to exclude. Both included by default for backward compatibility. A minimal build with all optional deps excluded has zero external dependencies (JSON via Foundation only).

## [1.8.1] - 2026-05-29

### Fixed
- **Cross-Version Bytecode C-API** - Gated `lua_dump`/`luaL_loadbuffer` bytecode calls by Lua version so the bytecode-compilation path builds correctly on Lua 5.1 and 5.2 (the 1.8.0 release failed to compile on those versions). Lua 5.3–5.5 are unaffected.

## [1.8.0] - 2026-05-29

### Added
- **Instruction-Count Limit** - `LuaEngine.setInstructionLimit(_:)` installs a `lua_sethook` count hook that deterministically aborts runaway Lua code (e.g. infinite loops) with the new `LuaError.instructionLimitExceeded`. The limit re-arms before every `run`/`evaluate` call; pass `0` to disable (default).
- **Bytecode Compilation** - `LuaEngine.compile(_:)`, `runBytecode(_:)`, `evaluateBytecode(_:)` for precompiling Lua source to bytecode and executing it; instruction-count limit applies on the bytecode path.
- **Complex-Dispatch Math** - `mathx` `sin`/`cos`/`tan`/`exp`/`log`/`sqrt` now dispatch on complex arguments, returning complex results while remaining real-valued for real inputs.
- **ArraySwift 0.2.0 Bindings** - Exposed ArraySwift's dtype infrastructure (float64/int64/bool/complex128/date with NumPy-style promotion), FFT family (`fft`/`ifft`/`rfft`/`fft2`/`fftn`/`fftfreq`), set operations (`intersect1d`/`union1d`/`setdiff1d`/`setxor1d`/`in1d`), and boolean/fancy/negative indexing to the Lua `array` module.
- **Power-Series Object** - `series.power` power-series type with `add`/`multiply`/`truncate`/`eval` operations.
- **Thales CAS Module** *(optional, opt-in)* - When built with `LUASWIFT_INCLUDE_THALES=1`, exposes computer-algebra operations to Lua: `asymptotic`, `compose_series`, `revert_series`, `puiseux`, `residue`, `convergence_radius`. Built on the optional Thales v0.4.2 dependency; off by default.
- **Table Comprehensions** - Python-style list/dict/set comprehensions in the `tablex` module.
- **Dialog Module** - UI `alert` and confirmation dialog module.
- **Slice Notation** - Python-style slice notation for `string`, `table`, and `array` modules.

### Changed
- **Dependency Bumps** - ArraySwift → 0.2.0, NumericSwift → 0.2.1.
- **MathExprModule** - Updated to the NumericSwift 0.2.1 parser API (`MathLexExpression`) after NumericSwift removed its public `tokenize` entry point.

### Fixed
- **CI Permissions** - Added write permissions to the Lua version-check workflow.

## [1.7.0] - 2026-04-06

### Added
- **Plot Colormaps** - Colormap support for scatter plots with numeric color arrays
- **Plot Axis Scaling** - Integrated axis scaling (log, symlog, logit) into all plot functions
- **HTTP Follow Redirects** - `follow_redirects` option for HTTP module
- **LuaFunction Auto-Release** - Automatic Lua function reference release mechanism for safer memory management
- **Lua Version Matrix CI** - CI now tests all 5 Lua versions (5.1-5.5)
- **Pure Lua Test Suite** - Standalone Lua test framework with test runner for cross-interpreter validation
- **Version-Specific Tests** - Swift tests with conditional compilation for Lua version differences
- **Test Infrastructure** - Centralized test configuration with data-driven dependency combinations
- **TESTING.md** - Comprehensive documentation for all test configurations and patterns
- **DocC Articles** - Documentation for compat and serialize Lua modules

### Fixed
- **Lua 5.1/5.2 Compatibility** - Enable LUA_COMPAT mode for backwards-compatible features across all supported versions
- **Array Module** - Use Lua 5.1-compatible `unpack` function instead of `table.unpack`
- **Optimize Module** - Use unpack compatibility shim for Lua 5.1
- **String Bridging** - Support embedded NUL bytes in string conversion
- **LuaValue.intValue** - Now returns nil for fractional numbers instead of truncating
- **Sandbox Security** - Harden sandbox to prevent `require()` bypass attempts
- **IO Sandbox** - Resolve symlinks to prevent sandbox directory escape

### Performance
- **HTTP Module** - Reuse URLSession instances per engine instead of creating new sessions per request

## [1.6.0] - 2026-01-19

### Changed
- **Deeper NumericSwift Integration** - Modules now use NumericSwift as thin wrappers:
  - SpatialModule: Delaunay, Voronoi, ConvexHull now delegate to NumericSwift (~290 lines removed)
  - SeriesModule: Taylor coefficient generation delegates to NumericSwift (~90 lines removed)
  - MathExprModule: parse, substitute, to_string, find_variables delegate to NumericSwift (~187 lines removed)
  - All algorithmic code now lives in NumericSwift; LuaSwift modules handle only Lua↔Swift type conversion

### Fixed
- **test-combinations.sh** - Fixed SIGPIPE issue with bash pipefail option causing false test failures

## [1.5.0] - 2026-01-17

### Added
- **Optional Dependencies** - NumericSwift, ArraySwift, and PlotSwift are now optional dependencies:
  - `LUASWIFT_INCLUDE_NUMERICSWIFT=0` to exclude NumericSwift
  - `LUASWIFT_INCLUDE_ARRAYSWIFT=0` to exclude ArraySwift
  - `LUASWIFT_INCLUDE_PLOTSWIFT=0` to exclude PlotSwift
  - All three included by default for backward compatibility
  - Reduces binary size when optional features are not needed
- **Platform Support** - Added support for additional Apple platforms:
  - visionOS 1.0+
  - watchOS 8.0+
  - tvOS 15.0+
- **DocC Documentation Catalog** - Full documentation for Swift Package Index:
  - 37 documentation articles covering all modules
  - Getting started guide and core API documentation
  - Comprehensive examples and usage patterns
  - Automatic documentation hosting via SPI
- **CI Workflow** - GitHub Actions workflow for testing all 8 dependency combinations:
  - Matrix strategy runs combinations in parallel
  - Triggers on push to dev/main and PRs
- **Test Script** - Local script (`scripts/test-combinations.sh`) for testing dependency combinations:
  - Sequential and parallel modes
  - Tests all 8 combinations (standalone through all three)
- **Unit Tests** - `OptionalDependencyTests.swift` verifying optional dependency behavior:
  - Module availability based on compilation flags
  - Graceful handling when dependencies excluded

### Changed
- **Refactored Scientific Modules** - Integrated with NumericSwift for shared algorithms:
  - ComplexModule now uses NumericSwift.Complex type
  - SpecialModule delegates to NumericSwift (beta, bessel, gamma, zeta, elliptic)
  - SeriesModule uses NumericSwift (factorial, Chebyshev, polynomial evaluation)
  - NumberTheoryModule uses NumericSwift (primes, factorization, arithmetic functions)
  - LinAlgModule reduced from 3231 to 1645 lines using NumericSwift.LinAlg
  - DistributionsModule uses NumericSwift for statistical functions
  - OptimizeModule uses NumericSwift (golden section, Brent, Nelder-Mead, Levenberg-Marquardt)
  - InterpolateModule uses NumericSwift (splines, PCHIP, Akima)
  - IntegrateModule uses NumericSwift (Gauss-Kronrod, ODE solvers)
  - GeometryModule integrated with NumericSwift
  - SpatialModule integrated with NumericSwift
  - ClusterModule integrated with NumericSwift
  - RegressModule integrated with NumericSwift
  - MathExprModule integrated with NumericSwift
- **ArrayModule** - Now uses ArraySwift package for NDArray implementation
- **PlotModule** - Now uses PlotSwift package for DrawingContext and styling types
- **Lua Namespaces** - Updated namespace organization:
  - `math.geo` renamed to `math.geometry`
  - Added `math.x` namespace for extended math utilities
  - `plt` global renamed to `plot` (users can alias: `local plt = plot`)

### Performance
- **Table-to-Array Conversion** - Optimized from O(n log n) to O(n) using min/max check instead of sorting

## [1.4.1] - 2026-01-11

### Added
- **Comprehensive API Documentation** for all 28 modules:
  - Standard Library Extensions: stringx, tablex, utf8x, regex, compat
  - Data Formats: json, yaml, toml
  - Math Namespace: linalg, complex, geo, special, stats, distributions, optimize, integrate, interpolate, cluster, spatial, regress, series, eval, constants, numtheory
  - Visualization: plot
  - File and Network: iox, http
- **docs/ folder** with full API reference and usage guides
- **Documentation badge** in README

### Changed
- README restructured with documentation link before examples
- All module docs now use "Function Reference at top" pattern with anchor links
- "External Access" renamed to "File and Network Access" for clarity
- Clarified iox operates within sandbox (not outside)
- Replaced Python-style variable names (np, plt) with descriptive names

## [1.4.0] - 2026-01-11

### Added
- **SciPy-inspired Scientific Computing Modules** (all Swift-backed with Accelerate):
  - `luaswift.distributions` - Probability distributions (norm, t, chi2, f, gamma, beta, uniform) with pdf, cdf, ppf, sf, isf, rvs methods
  - `luaswift.integrate` - Numerical integration (quad, dblquad, tplquad, nquad, odeint, simps, trapz, cumtrapz)
  - `luaswift.optimize` - Optimization (minimize, minimize_scalar, root, root_scalar, curve_fit, least_squares)
  - `luaswift.interpolate` - Interpolation (interp1d, CubicSpline, PCHIP, Akima, make_interp_spline)
  - `luaswift.cluster` - Clustering algorithms (kmeans, hierarchical, DBSCAN, silhouette_score)
  - `luaswift.spatial` - Spatial algorithms (KDTree, Voronoi, Delaunay, ConvexHull, distance functions)
  - `luaswift.special` - Special functions (erf, erfc, gamma, lgamma, digamma, beta, betainc, bessel j0/j1/jn/y0/y1/yn, ellipk, ellipe, zeta, lambertw)
  - `luaswift.regress` - Regression models (OLS, WLS, GLS, GLM with multiple families, ARIMA)
  - `luaswift.series` - Series evaluation (Taylor polynomials, series summation/product, convergence detection, lazy iterators)

- **Visualization Modules**:
  - `luaswift.plot` - Matplotlib/seaborn-compatible plotting with retained vector graphics (figure, subplot, plot, scatter, bar, hist, heatmap, pie, boxplot, violin, contour, imshow)
  - `luaswift.svg` - Swift-backed SVG document generation (complete rewrite from Lua)

- **Math/Expression Modules**:
  - `luaswift.mathexpr` - Mathematical expression parsing with LaTeX support, step-by-step evaluation, equation solving
  - `luaswift.mathsci` - Unified scientific computing namespace (math.stats, math.linalg, math.special, etc.)
  - `luaswift.sliderule` - Slide rule simulation for analog computation

- **Debug Module** (`luaswift.debug`, DEBUG builds only):
  - Structured logging with levels (debug, info, warn, error)
  - Console utilities (print, inspect, trace, assert)
  - Performance timing (time, timeEnd)

- **MathX Extensions**:
  - Additional constants: tau, phi (golden ratio), euler_gamma
  - Probability functions: ncr, npr, factorial

- **LinAlg Extensions**:
  - Singular Value Decomposition (SVD)
  - QR decomposition
  - Eigenvalue decomposition
  - Least squares solver (lstsq)
  - Moore-Penrose pseudo-inverse (pinv)
  - Matrix condition number (cond)

- **Memory Limit Enforcement**:
  - LuaEngine tracks memory allocations from Swift modules
  - `trackAllocation(bytes:)` throws when limit exceeded
  - ArrayModule and LinAlgModule respect configured limits
  - Configurable via `LuaEngineConfiguration.memoryLimit`

- **Geometry Extensions**:
  - Additional 2D/3D utilities
  - Quaternion improvements

### Changed
- All modules now use Swift-backed implementations for performance (previously some were pure Lua)
- Test suite expanded to 2171+ XCTest tests + 202 Swift Testing tests
- MathExpr module rewritten in Swift with LaTeX preprocessing

## [1.3.0] - 2026-01-04

### Added
- **Multi-version Lua support** (5.1.5, 5.2.4, 5.3.6, 5.4.7, 5.5.0)
  - All 715 tests pass on every Lua version
  - Environment variable `LUASWIFT_LUA_VERSION` for version selection
  - Comprehensive compatibility shims in LuaHelpers.swift
- GitHub CI workflows for automated Lua version updates and releases
- Types module for type detection and conversion (`luaswift.types`)
- Stdlib extension capability (`luaswift.extend_stdlib()`)
- Top-level global aliases for all modules (json, yaml, complex, geo, etc.)
- Serialize module for Lua value serialization/deserialization

### Changed
- Default Lua version remains 5.4.7 for backwards compatibility
- Compat module now works across all Lua versions with graceful fallbacks
- Serialize module uses Lua 5.1-compatible string escaping

### Lua Versions
| Series | Bundled Version |
|--------|-----------------|
| 5.1    | 5.1.5           |
| 5.2    | 5.2.4           |
| 5.3    | 5.3.6           |
| 5.4    | 5.4.7           |
| 5.5    | 5.5.0           |

## [1.2.0] - 2026-01-02

### Added
- Types module for type detection and conversion
- Stdlib extension pattern with `import()` functions
- Top-level global aliases for modules

## [1.0.0] - 2025-12-28

### Added
- Initial release
- LuaEngine with sandboxed execution
- LuaValue type-safe value representation
- LuaValueServer protocol for Swift-Lua data bridging
- Coroutine support with CoroutineHandle
- Swift callback registration
- Bundled modules: JSON, YAML, TOML, Regex, StringX, TableX, UTF8X, MathX
- Linear algebra module (vectors, matrices)
- Geometry module (vec2, vec3, quaternion, transform3d)
- Complex number module
- Array module (NumPy-like operations)
- Compat module for Lua version compatibility
