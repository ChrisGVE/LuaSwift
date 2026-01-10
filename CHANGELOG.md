# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
