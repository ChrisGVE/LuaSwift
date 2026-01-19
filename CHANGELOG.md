# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
