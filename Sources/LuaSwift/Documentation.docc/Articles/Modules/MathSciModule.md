# Math Sci Module

Unified scientific computing namespace coordinator for the `math` table.

## Overview

The MathSci module is the umbrella coordinator that organises all scientific computing
sub-namespaces under Lua's built-in `math` table. It runs at module-registration time
(not at `extend_stdlib()` time) and performs two jobs:

1. Creates the sub-namespace tables (`math.stats`, `math.special`, `math.optimize`,
   `math.integrate`, `math.interpolate`, `math.cluster`, `math.spatial`, `math.eval`,
   `math.x`, `math.constants`) directly in the global `math` table.
2. Re-exports functions from already-registered modules into those namespaces
   (`luaswift.mathx` → `math.stats` / `math.special` / `math.x`;
    `luaswift.linalg` → `math.linalg`;
    `luaswift.complex` → `math.complex`;
    `luaswift.geometry` → `math.geometry`).

> Important: MathSci module and all scientific sub-namespaces are **opt-in** and
> **default-off**. They require the `LUASWIFT_NUMERICSWIFT` build flag
> (`LUASWIFT_INCLUDE_NUMERICSWIFT=1`). Without it, none of the `math.*`
> sub-namespaces described here are created.

## Installation

```swift
// Install all modules (NumericSwift sub-namespaces only when LUASWIFT_NUMERICSWIFT is set)
ModuleRegistry.installModules(in: engine)

// Or install MathSci explicitly (after individual modules are registered)
ModuleRegistry.installMathSciModule(in: engine)
```

The sub-namespaces are ready immediately after `installModules(in:)` returns.
Calling `luaswift.extend_stdlib()` is **not** required to access them; however,
`extend_stdlib()` also sets `math.complex`, `math.linalg`, `math.geo`, and
`math.regress` as convenient aliases and imports MathX functions directly onto the
`math` table (via `mathx.import()`).

## Namespace Overview

With `LUASWIFT_NUMERICSWIFT` active, the following sub-namespaces are available on the
global `math` table after `installModules(in:)`:

| Namespace | Source | Populated by |
|---|---|---|
| `math.linalg` | `luaswift.linalg` | MathSciModule (re-export) |
| `math.complex` | `luaswift.complex` | MathSciModule (re-export) |
| `math.geometry` | `luaswift.geometry` | MathSciModule (re-export) |
| `math.stats` | `luaswift.mathx` stats functions | MathSciModule + DistributionsModule |
| `math.special` | `luaswift.mathx` special functions | MathSciModule + SpecialModule |
| `math.optimize` | — | OptimizeModule |
| `math.integrate` | — | IntegrateModule |
| `math.interpolate` | — | InterpolateModule |
| `math.cluster` | — | ClusterModule |
| `math.spatial` | — | SpatialModule |
| `math.eval` | — | MathExprModule |
| `math.x` | `luaswift.mathx` utilities | MathSciModule (re-export) |
| `math.constants` | literal values | MathSciModule |

Without `LUASWIFT_NUMERICSWIFT`, none of these sub-namespaces are created. The base
`math` table and `luaswift.mathx` functions remain available regardless.

## `math.x` — Extended Utilities

`math.x` collects extended math utilities re-exported from `luaswift.mathx`:

```lua
-- Rounding
math.x.round(3.7)       -- 4
math.x.round(3.2)       -- 3
math.x.trunc(3.7)       -- 3
math.x.trunc(-3.7)      -- -3

-- Sign
math.x.sign(5)          -- 1
math.x.sign(-3)         -- -1
math.x.sign(0)          -- 0

-- Hyperbolic functions
math.x.sinh(1)          -- 1.1752011936438
math.x.cosh(1)          -- 1.5430806348152
math.x.tanh(1)          -- 0.76159415595576
math.x.asinh(1)         -- 0.88137358701954
math.x.acosh(2)         -- 1.3169578969248
math.x.atanh(0.5)       -- 0.54930614433405

-- Extended logarithms
math.x.log10(1000)      -- 3
math.x.log2(8)          -- 3
```

The same functions are also accessible as `luaswift.mathx.*`, and after calling
`luaswift.extend_stdlib()` they are imported directly onto the `math` table
(e.g. `math.sinh`, `math.round`). `math.x` is a stable namespace alias for
code that prefers explicit qualification.

## `math.constants` — Physical and Mathematical Constants

`math.constants` is always populated by MathSciModule (no further modules required),
regardless of which other NumericSwift modules are active.

### Mathematical constants

| Key | Value | Description |
|---|---|---|
| `pi` | 3.14159265358979… | Ratio of circumference to diameter |
| `e` | 2.71828182845905… | Euler's number |
| `tau` | 6.28318530717959… | 2π |
| `phi` | 1.61803398874990… | Golden ratio |
| `euler_gamma` | 0.57721566490153… | Euler–Mascheroni constant |
| `sqrt2` | 1.41421356237310… | √2 |
| `sqrt3` | 1.73205080756888… | √3 |
| `ln2` | 0.69314718055995… | ln 2 |
| `ln10` | 2.30258509299405… | ln 10 |

### Physical constants (CODATA 2018, SI units)

| Key | Value | Unit | Description |
|---|---|---|---|
| `c` | 299 792 458 | m/s | Speed of light in vacuum |
| `h` | 6.62607015 × 10⁻³⁴ | J⋅s | Planck constant |
| `hbar` | 1.054571817 × 10⁻³⁴ | J⋅s | Reduced Planck constant |
| `G` | 6.67430 × 10⁻¹¹ | m³/(kg⋅s²) | Gravitational constant |
| `e_charge` | 1.602176634 × 10⁻¹⁹ | C | Elementary charge |
| `m_e` | 9.1093837015 × 10⁻³¹ | kg | Electron mass |
| `m_p` | 1.67262192369 × 10⁻²⁷ | kg | Proton mass |
| `m_n` | 1.67492749804 × 10⁻²⁷ | kg | Neutron mass |
| `k_B` | 1.380649 × 10⁻²³ | J/K | Boltzmann constant |
| `N_A` | 6.02214076 × 10²³ | 1/mol | Avogadro constant |
| `R` | 8.314462618 | J/(mol⋅K) | Molar gas constant |
| `epsilon_0` | 8.8541878128 × 10⁻¹² | F/m | Vacuum permittivity |
| `mu_0` | 1.25663706212 × 10⁻⁶ | H/m | Vacuum permeability |
| `sigma` | 5.670374419 × 10⁻⁸ | W/(m²⋅K⁴) | Stefan–Boltzmann constant |
| `alpha` | 7.2973525693 × 10⁻³ | — | Fine-structure constant |
| `Ry` | 10 973 731.568160 | 1/m | Rydberg constant |
| `a_0` | 5.29177210903 × 10⁻¹¹ | m | Bohr radius |

### Conversion factors

| Key | Value | Converts to |
|---|---|---|
| `degree` | π / 180 | Radians per degree |
| `arcmin` | π / 10 800 | Radians per arcminute |
| `arcsec` | π / 648 000 | Radians per arcsecond |
| `inch` | 0.0254 | Metres |
| `foot` | 0.3048 | Metres |
| `yard` | 0.9144 | Metres |
| `mile` | 1 609.344 | Metres |
| `nautical_mile` | 1 852 | Metres |
| `pound` | 0.45359237 | Kilograms |
| `ounce` | 0.028349523125 | Kilograms |
| `gram` | 0.001 | Kilograms |
| `tonne` | 1 000 | Kilograms |
| `zero_Celsius` | 273.15 | Kelvin |
| `minute` | 60 | Seconds |
| `hour` | 3 600 | Seconds |
| `day` | 86 400 | Seconds |
| `week` | 604 800 | Seconds |
| `year` | 31 557 600 | Seconds (Julian year, 365.25 days) |

```lua
-- Example: convert 45 degrees to radians
local rad = 45 * math.constants.degree   -- 0.7853...

-- Energy of a photon at 500 nm
local lambda = 500e-9
local energy = math.constants.h * math.constants.c / lambda  -- ~3.98e-19 J
```

## `extend_stdlib()` and MathSci

`luaswift.extend_stdlib()` is a separate, independent function. It does **not** create
the MathSci sub-namespaces — those are created at module-registration time by
`MathSciModule.register()`. What `extend_stdlib()` does do is:

- Import `luaswift.stringx` functions into the `string` table.
- Import `luaswift.mathx` functions directly onto the `math` table (e.g. `math.sinh`,
  `math.round`, `math.mean`).
- Import `luaswift.tablex` functions into the `table` table.
- Import `luaswift.utf8x` functions into the `utf8` table.
- Set convenience aliases: `math.complex`, `math.linalg`, `math.geo` (alias for
  `math.geometry`), and `math.regress` — when the corresponding modules are available.

Calling `extend_stdlib()` is optional. Use it when you want shorter unqualified access
like `math.sinh(x)` instead of `luaswift.mathx.sinh(x)`.

## Basic Usage

```lua
-- Sub-namespaces are available after installModules(in:) with LUASWIFT_NUMERICSWIFT
-- No extend_stdlib() call is required

-- Linear algebra
local m = math.linalg.matrix({{1, 2}, {3, 4}})

-- Complex numbers
local z = math.complex.new(3, 4)

-- Special functions (from math.special, populated by SpecialModule)
local g = math.special.gamma(5)   -- 24

-- Statistics (from math.stats, populated by MathSciModule + DistributionsModule)
local avg = math.stats.mean({1, 2, 3, 4, 5})   -- 3

-- Physical constant
local c = math.constants.c         -- 299792458

-- Extended utilities
local s = math.x.sign(-7)          -- -1
```

## Conditional Availability

```swift
// Only install NumericSwift modules when the flag is set
// In your Package.swift or build environment:
//   LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build
```

```lua
-- Guard against missing NumericSwift at runtime
if math.linalg then
    local m = math.linalg.matrix({{1, 0}, {0, 1}})
    print("LinAlg available")
else
    print("Build without LUASWIFT_NUMERICSWIFT — math.linalg not available")
end

-- math.constants and math.x are always nil when NumericSwift is off
if math.constants then
    print("Speed of light:", math.constants.c)
end
```

## Module Registration Order

When installing modules individually (not via `installModules(in:)`), MathSciModule
must be registered **after** the modules it re-exports
(`MathXModule`, `LinAlgModule`, `ComplexModule`, `GeometryModule`) and **before**
`MathExprModule` (which relies on the `math.eval` namespace that MathSciModule creates).

```swift
// Correct order for manual installation
ModuleRegistry.installMathModule(in: engine)        // MathXModule
ModuleRegistry.installLinAlgModule(in: engine)      // LinAlgModule
ModuleRegistry.installComplexModule(in: engine)     // ComplexModule
ModuleRegistry.installGeometryModule(in: engine)    // GeometryModule
ModuleRegistry.installMathSciModule(in: engine)     // Creates namespaces + re-exports
ModuleRegistry.installMathExprModule(in: engine)    // Populates math.eval
```

## See Also

- ``MathSciModule``
- <doc:MathXModule>
- <doc:LinAlgModule>
- <doc:ComplexModule>
- <doc:GeometryModule>
- <doc:SpecialModule>
- <doc:DistributionsModule>
- <doc:OptimizeModule>
- <doc:IntegrateModule>
- <doc:InterpolateModule>
- <doc:ClusterModule>
- <doc:SpatialModule>
- <doc:SeriesModule>
- <doc:NumberTheoryModule>
