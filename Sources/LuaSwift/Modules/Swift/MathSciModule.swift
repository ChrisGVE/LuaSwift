//
//  MathSciModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed unified math module for scientific computing in LuaSwift.
///
/// This umbrella module extends Lua's built-in `math` table with scientific computing
/// subnamespaces, providing a unified API similar to Python's scientific ecosystem
/// but implemented from mathematical principles (NOT a scipy port).
///
/// ## Architecture
///
/// MathSciModule orchestrates existing LuaSwift modules by re-exporting them under
/// the `math` namespace:
/// - `luaswift.linalg` → `math.linalg`
/// - `luaswift.mathx` stats functions → `math.stats`
/// - `luaswift.mathx` special functions → `math.special`
/// - `luaswift.complex` → `math.complex` (via extend_stdlib)
/// - `luaswift.geometry` → `math.geometry` (via extend_stdlib)
///
/// ## Namespace Structure
///
/// ```
/// math (extends Lua's built-in math)
/// ├── linalg         # Matrix operations (re-export LinAlgModule)
/// ├── stats          # Statistics + distributions + tests
/// ├── special        # Special functions (gamma, erf, bessel, etc.)
/// ├── constants      # Physical/mathematical constants
/// ├── optimize       # Optimization (minimize, root finding, curve_fit)
/// ├── integrate      # Numerical integration (quad, odeint)
/// ├── interpolate    # Interpolation (interp1d, CubicSpline)
/// ├── cluster        # Clustering algorithms (k-means, hierarchical, DBSCAN)
/// ├── spatial        # Spatial algorithms (KDTree, distance, Voronoi)
/// ├── complex        # Complex number arithmetic (re-export ComplexModule)
/// ├── geometry       # Geometry operations (re-export GeometryModule)
/// └── x              # Extended math utilities (round, trunc, sign, clip)
/// ```
///
/// ## Usage
///
/// ```lua
/// -- Ensure extend_stdlib() is called first
/// luaswift.extend_stdlib()
///
/// -- Now use math subnamespaces
/// local m = math.linalg.matrix({{1,2},{3,4}})
/// local avg = math.stats.mean({1, 2, 3, 4, 5})
/// local g = math.special.gamma(5)  -- 24 (same as 4!)
/// local c = math.constants.pi      -- 3.14159...
/// ```
public struct MathSciModule {

    /// Register the unified math/scientific module with a LuaEngine.
    ///
    /// This creates the `math` subnamespaces by re-exporting and extending
    /// existing LuaSwift modules. Should be called after all individual modules
    /// are registered.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Set up the math subnamespaces
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.mathsci then luaswift.mathsci = {} end

                -- Helper to create empty namespace tables if not existing
                local function ensure_namespace(parent, name)
                    if not parent[name] then
                        parent[name] = {}
                    end
                    return parent[name]
                end

                -- Create all math subnamespaces
                -- These are initially empty or will be populated by re-exports

                -- math.stats - Statistics, distributions, and statistical tests
                -- Re-exports mathx statistics functions + adds distributions
                ensure_namespace(math, "stats")

                -- math.special - Special mathematical functions
                -- Re-exports mathx special functions + adds more (erf, bessel, etc.)
                ensure_namespace(math, "special")

                -- math.constants - Physical and mathematical constants
                ensure_namespace(math, "constants")

                -- math.optimize - Optimization algorithms
                -- (Will be populated by future implementation)
                ensure_namespace(math, "optimize")

                -- math.integrate - Numerical integration
                -- (Will be populated by future implementation)
                ensure_namespace(math, "integrate")

                -- math.interpolate - Interpolation functions
                -- (Will be populated by future implementation)
                ensure_namespace(math, "interpolate")

                -- math.cluster - Clustering algorithms
                -- (Will be populated by future implementation)
                ensure_namespace(math, "cluster")

                -- math.spatial - Spatial algorithms
                -- (Will be populated by future implementation)
                ensure_namespace(math, "spatial")

                -- math.eval - Expression evaluation, compilation, and symbolic manipulation
                -- (Will be populated by MathExprModule)
                ensure_namespace(math, "eval")

                -- Re-export luaswift.linalg → math.linalg
                -- (extend_stdlib already does this, but ensure it's available)
                if luaswift.linalg then
                    math.linalg = luaswift.linalg
                end

                -- Re-export luaswift.complex → math.complex
                if luaswift.complex then
                    math.complex = luaswift.complex
                end

                -- Re-export luaswift.geometry → math.geometry
                if luaswift.geometry then
                    math.geometry = luaswift.geometry
                end

                -- Create math.x for extended utilities
                ensure_namespace(math, "x")

                -- Re-export mathx statistics functions → math.stats
                if luaswift.mathx then
                    local mathx = luaswift.mathx
                    local stats = math.stats

                    -- Core statistics (from MathXModule)
                    stats.sum = mathx.sum
                    stats.mean = mathx.mean
                    stats.median = mathx.median
                    stats.variance = mathx.variance
                    stats.stddev = mathx.stddev
                    stats.percentile = mathx.percentile
                end

                -- Re-export mathx special functions → math.special
                if luaswift.mathx then
                    local mathx = luaswift.mathx
                    local special = math.special

                    -- Special functions (from MathXModule)
                    special.factorial = mathx.factorial
                    special.gamma = mathx.gamma
                    special.lgamma = mathx.lgamma

                    -- Also alias gammaln for compatibility with common conventions
                    special.gammaln = mathx.lgamma
                end

                -- Re-export mathx extended utilities → math.x
                if luaswift.mathx then
                    local mathx = luaswift.mathx
                    local x = math.x

                    -- Extended utilities (trivial Darwin-based extensions)
                    x.round = mathx.round
                    x.trunc = mathx.trunc
                    x.sign = mathx.sign

                    -- Hyperbolic functions
                    x.sinh = mathx.sinh
                    x.cosh = mathx.cosh
                    x.tanh = mathx.tanh
                    x.asinh = mathx.asinh
                    x.acosh = mathx.acosh
                    x.atanh = mathx.atanh

                    -- Extended logarithms
                    x.log10 = mathx.log10
                    x.log2 = mathx.log2
                end

                -- Populate math.constants with physical and mathematical constants
                local constants = math.constants

                -- Mathematical constants
                -- Note: math.pi and math.huge are already in Lua's math
                constants.pi = math.pi
                constants.e = 2.718281828459045
                constants.tau = 2 * math.pi  -- 2π
                constants.phi = 1.618033988749895  -- Golden ratio
                constants.euler_gamma = 0.5772156649015329  -- Euler-Mascheroni constant
                constants.sqrt2 = 1.4142135623730951
                constants.sqrt3 = 1.7320508075688772
                constants.ln2 = 0.6931471805599453
                constants.ln10 = 2.302585092994046

                -- Physical constants (SI units, CODATA 2018 values)
                constants.c = 299792458  -- Speed of light in vacuum (m/s)
                constants.h = 6.62607015e-34  -- Planck constant (J⋅s)
                constants.hbar = 1.054571817e-34  -- Reduced Planck constant (J⋅s)
                constants.G = 6.67430e-11  -- Gravitational constant (m³/(kg⋅s²))
                constants.e_charge = 1.602176634e-19  -- Elementary charge (C)
                constants.m_e = 9.1093837015e-31  -- Electron mass (kg)
                constants.m_p = 1.67262192369e-27  -- Proton mass (kg)
                constants.m_n = 1.67492749804e-27  -- Neutron mass (kg)
                constants.k_B = 1.380649e-23  -- Boltzmann constant (J/K)
                constants.N_A = 6.02214076e23  -- Avogadro constant (1/mol)
                constants.R = 8.314462618  -- Gas constant (J/(mol⋅K))
                constants.epsilon_0 = 8.8541878128e-12  -- Vacuum permittivity (F/m)
                constants.mu_0 = 1.25663706212e-6  -- Vacuum permeability (H/m)
                constants.sigma = 5.670374419e-8  -- Stefan-Boltzmann constant (W/(m²⋅K⁴))
                constants.alpha = 7.2973525693e-3  -- Fine-structure constant (dimensionless)
                constants.Ry = 10973731.568160  -- Rydberg constant (1/m)
                constants.a_0 = 5.29177210903e-11  -- Bohr radius (m)

                -- Conversion factors
                constants.degree = math.pi / 180  -- Radians per degree
                constants.arcmin = math.pi / 10800  -- Radians per arcminute
                constants.arcsec = math.pi / 648000  -- Radians per arcsecond

                -- Length conversions to meters
                constants.inch = 0.0254
                constants.foot = 0.3048
                constants.yard = 0.9144
                constants.mile = 1609.344
                constants.nautical_mile = 1852

                -- Mass conversions to kilograms
                constants.pound = 0.45359237
                constants.ounce = 0.028349523125
                constants.gram = 0.001
                constants.tonne = 1000

                -- Temperature conversions
                constants.zero_Celsius = 273.15  -- Kelvin

                -- Time conversions to seconds
                constants.minute = 60
                constants.hour = 3600
                constants.day = 86400
                constants.week = 604800
                constants.year = 31557600  -- Julian year (365.25 days)

                -- Store reference to indicate module is loaded
                luaswift.mathsci.version = "1.0.0"
                luaswift.mathsci.loaded = true
                """)
        } catch {
            // Silently fail if setup fails
        }
    }
}
