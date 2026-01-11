# Module Documentation

Detailed documentation for all LuaSwift modules.

## Data Formats

- [JSON](json.md) - JSON encoding/decoding
- [YAML](yaml.md) - YAML with multi-document support
- [TOML](toml.md) - TOML configuration parsing

## Math & Scientific

- [Extended Math (mathx)](mathx.md) - Statistics, hyperbolic functions, rounding
- [Linear Algebra (linalg)](linalg.md) - Matrices, SVD, eigenvalues, BLAS/LAPACK
- [Array](array.md) - NumPy-like N-dimensional arrays
- [Complex Numbers](complex.md) - Complex arithmetic
- [Geometry (geo)](geo.md) - 2D/3D vectors, quaternions, transforms
- [Special Functions](special.md) - Bessel, gamma, erf, elliptic integrals

## SciPy-Inspired

- [Distributions](distributions.md) - Probability distributions, statistical tests
- [Integrate](integrate.md) - Numerical integration, ODE solvers
- [Optimize](optimize.md) - Minimization, root finding, curve fitting
- [Interpolate](interpolate.md) - Splines, PCHIP, Akima
- [Cluster](cluster.md) - K-means, hierarchical, DBSCAN
- [Spatial](spatial.md) - KDTree, Voronoi, Delaunay
- [Regression](regression.md) - OLS, WLS, GLS, GLM, ARIMA

## Visualization

- [Plot](plot.md) - Matplotlib-style plotting
- [SVG](svg.md) - SVG document generation

## Utilities

- [StringX](stringx.md) - String manipulation
- [TableX](tablex.md) - Functional table operations
- [UTF8X](utf8x.md) - Unicode-aware strings
- [Types](types.md) - Type detection/conversion
- [Compat](compat.md) - Lua version compatibility
- [Regex](regex.md) - ICU regular expressions

## Security Modules (Opt-In)

- [IO (iox)](io.md) - Sandboxed file I/O
- [HTTP](http.md) - URLSession-based HTTP client

---

## Installing Modules

### Install All Modules

```swift
let engine = try LuaEngine()
ModuleRegistry.installModules(in: engine)
```

### Install Specific Modules

```swift
let engine = try LuaEngine()
ModuleRegistry.installJSONModule(in: engine)
ModuleRegistry.installMathModule(in: engine)
ModuleRegistry.installLinAlgModule(in: engine)
```

### Security Modules (Explicit Opt-In)

```swift
// IO Module - requires allowed directories
IOModule.setAllowedDirectories([documentsPath], for: engine)
ModuleRegistry.installIOModule(in: engine)

// HTTP Module
ModuleRegistry.installHTTPModule(in: engine)
```

## Module Access Patterns

### Global Access

All modules are available as globals:

```lua
json.encode({a = 1})
linalg.matrix({{1,2},{3,4}})
geo.vec3(1, 2, 3)
```

### Require Access

```lua
local json = require("luaswift.json")
local la = require("luaswift.linalg")
local geo = require("geo")
```

### Standard Library Extension

```lua
-- Extend individual libraries
stringx.import()  -- adds to string.*
mathx.import()    -- adds to math.*
tablex.import()   -- adds to table.*

-- Extend all at once
luaswift.extend_stdlib()
-- Creates: math.complex, math.linalg, math.geo
```
