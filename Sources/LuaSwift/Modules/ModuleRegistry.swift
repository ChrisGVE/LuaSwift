//
//  ModuleRegistry.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Registry for built-in LuaSwift modules.
///
/// Provides a centralized way to register all Swift-backed modules with a LuaEngine.
///
/// ## Usage
///
/// ```swift
/// let engine = try LuaEngine()
/// ModuleRegistry.installModules(in: engine)
///
/// // Now Lua code can use:
/// // local json = require("luaswift.json")
/// // local value = json.decode('{"key":"value"}')
/// ```
public struct ModuleRegistry {
    /// Install all built-in modules in the specified engine.
    ///
    /// This registers all available Swift-backed modules. Currently includes:
    /// - `luaswift.json`: JSON encoding/decoding
    /// - `luaswift.yaml`: YAML encoding/decoding
    /// - `luaswift.toml`: TOML encoding/decoding
    /// - `luaswift.regex`: Regular expression support
    /// - `luaswift.mathx`: Extended math functions and statistics
    /// - `luaswift.linalg`: Linear algebra operations
    /// - `luaswift.array`: NumPy-like N-dimensional arrays
    /// - `luaswift.geo`: Optimized 2D/3D geometry with SIMD
    /// - `luaswift.utf8x`: UTF-8 string utilities with Unicode support
    /// - `luaswift.stringx`: Swift-backed string utilities
    /// - `luaswift.tablex`: Swift-backed table utilities
    /// - `luaswift.complex`: Complex number arithmetic and functions
    /// - `luaswift.types`: Type detection and conversion utilities
    /// - `luaswift.svg`: SVG document generation
    /// - `luaswift.mathexpr`: Mathematical expression parsing and evaluation
    /// - `luaswift.plot`: Matplotlib-compatible plotting with retained vector graphics
    /// - `luaswift.mathsci`: Unified scientific computing namespace
    /// - `luaswift.distributions`: Probability distributions (norm, t, chi2, f, gamma, beta)
    /// - `luaswift.interpolate`: Interpolation functions (interp1d, CubicSpline, PCHIP, Akima)
    /// - `luaswift.cluster`: Clustering algorithms (kmeans, hierarchical, DBSCAN)
    /// - `luaswift.spatial`: Spatial algorithms (KDTree, distance functions, Voronoi, Delaunay)
    /// - `luaswift.special`: Special functions (erf, erfc, beta, betainc, bessel)
    /// - `luaswift.regress`: Regression models (OLS, WLS, GLS, GLM, ARIMA)
    /// - `luaswift.series`: Series evaluation (Taylor, summation, products, convergence)
    /// - `luaswift.numtheory`: Number theory functions (euler_phi, mobius, prime_pi, etc.)
    /// - `luaswift.debug`: Debugging utilities (DEBUG builds only)
    ///
    /// Top-level aliases are also created: `stringx`, `mathx`, `tablex`, `utf8x`,
    /// `complex`, `linalg`, `geo`, `array`, `json`, `yaml`, `toml`, `regex`, `types`,
    /// `svg_module`, `mathexpr_module`, `plt`, `debug_module`.
    ///
    /// Use `luaswift.extend_stdlib()` to inject all extensions into the standard library.
    /// After calling extend_stdlib(), math subnamespaces are available:
    /// `math.linalg`, `math.stats`, `math.special`, `math.regress`, `math.constants`, etc.
    ///
    /// - Parameter engine: The Lua engine to install modules in
    public static func installModules(in engine: LuaEngine) {
        // Core modules (always available)
        installJSONModule(in: engine)
        installYAMLModule(in: engine)
        installTOMLModule(in: engine)
        installRegexModule(in: engine)
        installMathModule(in: engine)
        installUTF8XModule(in: engine)
        installStringXModule(in: engine)
        installTableXModule(in: engine)
        installTypesModule(in: engine)
        installSVGModule(in: engine)

        // ArraySwift-dependent module
        #if LUASWIFT_ARRAYSWIFT
        installArrayModule(in: engine)
        #endif

        // PlotSwift-dependent module
        #if LUASWIFT_PLOTSWIFT
        installPlotModule(in: engine)
        #endif

        // NumericSwift-dependent modules
        #if LUASWIFT_NUMERICSWIFT
        installLinAlgModule(in: engine)
        installGeometryModule(in: engine)
        installComplexModule(in: engine)
        installMathSciModule(in: engine)  // Must be before MathExprModule to create math.eval namespace
        installMathExprModule(in: engine)
        installOptimizeModule(in: engine)
        installIntegrateModule(in: engine)
        installDistributionsModule(in: engine)
        installInterpolateModule(in: engine)
        installClusterModule(in: engine)
        installSpatialModule(in: engine)
        installSpecialModule(in: engine)
        installRegressModule(in: engine)
        installSeriesModule(in: engine)  // Must be after MathExprModule (uses eval)
        installNumberTheoryModule(in: engine)
        #endif

        #if DEBUG
        installDebugModule(in: engine)
        #endif
        installExtendStdlib(in: engine)
    }

    /// Install the extend_stdlib() helper function and top-level aliases.
    ///
    /// This creates:
    /// - Top-level aliases for all modules (json, yaml, toml, regex, linalg, array, geo, complex, types)
    /// - `luaswift.extend_stdlib()` which imports all extensions into standard library
    ///
    /// - Parameter engine: The Lua engine to install in
    private static func installExtendStdlib(in engine: LuaEngine) {
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Create top-level global aliases for all modules
                json = luaswift.json
                yaml = luaswift.yaml
                toml = luaswift.toml
                regex = luaswift.regex
                linalg = luaswift.linalg
                array = luaswift.array
                geo = luaswift.geometry
                complex = luaswift.complex
                types = luaswift.types

                -- Also create luaswift.geo as alias
                luaswift.geo = luaswift.geometry

                -- extend_stdlib() imports all extensions into the standard library
                function luaswift.extend_stdlib()
                    -- Import stringx into string
                    if luaswift.stringx and luaswift.stringx.import then
                        luaswift.stringx.import()
                    end

                    -- Import mathx into math
                    if luaswift.mathx and luaswift.mathx.import then
                        luaswift.mathx.import()
                    end

                    -- Import tablex into table
                    if luaswift.tablex and luaswift.tablex.import then
                        luaswift.tablex.import()
                    end

                    -- Import utf8x into utf8
                    if luaswift.utf8x and luaswift.utf8x.import then
                        luaswift.utf8x.import()
                    end

                    -- Create math subnamespaces for specialized modules
                    if luaswift.complex then
                        math.complex = luaswift.complex
                    end

                    if luaswift.linalg then
                        math.linalg = luaswift.linalg
                    end

                    if luaswift.geometry then
                        math.geo = luaswift.geometry
                    end

                    if luaswift.regress then
                        math.regress = luaswift.regress
                    end
                end
                """)
        } catch {
            #if DEBUG
            print("[LuaSwift] Warning: extend_stdlib setup failed: \(error)")
            #endif
        }
    }

    /// Install only the JSON module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installJSONModule(in engine: LuaEngine) {
        JSONModule.register(in: engine)
    }

    /// Install only the YAML module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installYAMLModule(in engine: LuaEngine) {
        YAMLModule.register(in: engine)
    }

    /// Install only the TOML module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installTOMLModule(in engine: LuaEngine) {
        TOMLModule.register(in: engine)
    }

    /// Install only the Regex module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installRegexModule(in engine: LuaEngine) {
        RegexModule.register(in: engine)
    }

    #if LUASWIFT_NUMERICSWIFT
    /// Install only the Linear Algebra module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installLinAlgModule(in engine: LuaEngine) {
        LinAlgModule.register(in: engine)
    }
    #endif

    /// Install only the Math extension module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installMathModule(in engine: LuaEngine) {
        MathXModule.register(in: engine)
    }

    #if LUASWIFT_ARRAYSWIFT
    /// Install only the Array module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installArrayModule(in engine: LuaEngine) {
        ArrayModule.register(in: engine)
    }
    #endif

    #if LUASWIFT_NUMERICSWIFT
    /// Install only the Geometry module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installGeometryModule(in engine: LuaEngine) {
        GeometryModule.register(in: engine)
    }
    #endif

    /// Install only the UTF8X module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installUTF8XModule(in engine: LuaEngine) {
        UTF8XModule.register(in: engine)
    }

    /// Install only the StringX module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installStringXModule(in engine: LuaEngine) {
        StringXModule.register(in: engine)
    }

    /// Install only the TableX module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installTableXModule(in engine: LuaEngine) {
        TableXModule.register(in: engine)
    }

    #if LUASWIFT_NUMERICSWIFT
    /// Install only the Complex module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installComplexModule(in engine: LuaEngine) {
        ComplexModule.register(in: engine)
    }
    #endif

    /// Install only the Types module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installTypesModule(in engine: LuaEngine) {
        TypesModule.register(in: engine)
    }

    /// Install only the SVG module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installSVGModule(in engine: LuaEngine) {
        SVGModule.register(in: engine)
    }

    #if LUASWIFT_NUMERICSWIFT
    /// Install only the MathExpr module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installMathExprModule(in engine: LuaEngine) {
        MathExprModule.register(in: engine)
    }
    #endif

    #if DEBUG
    /// Install only the Debug module.
    ///
    /// This module is only available in DEBUG builds.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installDebugModule(in engine: LuaEngine) {
        DebugModule.register(in: engine)
    }
    #endif

    #if LUASWIFT_PLOTSWIFT
    /// Install only the Plot module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installPlotModule(in engine: LuaEngine) {
        PlotModule.register(in: engine)
    }
    #endif

    #if LUASWIFT_NUMERICSWIFT
    /// Install only the MathSci module.
    ///
    /// This module sets up math subnamespaces by re-exporting existing modules.
    /// Should be called after individual modules (MathXModule, LinAlgModule, etc.)
    /// are already registered.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installMathSciModule(in engine: LuaEngine) {
        MathSciModule.register(in: engine)
    }

    /// Install only the Optimize module.
    ///
    /// This module provides numerical optimization functions.
    /// Should be called after MathSciModule to add to math.optimize namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installOptimizeModule(in engine: LuaEngine) {
        OptimizeModule.register(in: engine)
    }

    /// Install only the Integrate module.
    ///
    /// This module provides numerical integration functions.
    /// Should be called after MathSciModule to add to math.integrate namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installIntegrateModule(in engine: LuaEngine) {
        IntegrateModule.register(in: engine)
    }

    /// Install only the Distributions module.
    ///
    /// This module provides probability distributions (norm, uniform, t, chi2, etc.).
    /// Should be called after MathSciModule to add to math.stats namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installDistributionsModule(in engine: LuaEngine) {
        DistributionsModule.register(in: engine)
    }

    /// Install only the Interpolate module.
    ///
    /// This module provides interpolation functions (interp1d, CubicSpline, etc.).
    /// Should be called after MathSciModule to add to math.interpolate namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installInterpolateModule(in engine: LuaEngine) {
        InterpolateModule.register(in: engine)
    }

    /// Install only the Cluster module.
    ///
    /// This module provides clustering algorithms (kmeans, hierarchical, DBSCAN).
    /// Should be called after MathSciModule to add to math.cluster namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installClusterModule(in engine: LuaEngine) {
        ClusterModule.register(in: engine)
    }

    /// Install only the Spatial module.
    ///
    /// This module provides spatial algorithms (KDTree, distance functions, Voronoi, Delaunay).
    /// Should be called after MathSciModule to add to math.spatial namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installSpatialModule(in engine: LuaEngine) {
        SpatialModule.register(in: engine)
    }

    /// Install only the Special functions module.
    ///
    /// This module provides advanced special mathematical functions (erf, beta, bessel).
    /// Should be called after MathSciModule to add to math.special namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installSpecialModule(in engine: LuaEngine) {
        SpecialModule.register(in: engine)
    }

    /// Install only the Regress module.
    ///
    /// This module provides regression models (OLS, WLS, GLS, GLM, ARIMA).
    /// Should be called after MathSciModule to add to math.regress namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installRegressModule(in engine: LuaEngine) {
        RegressModule.register(in: engine)
    }

    /// Install only the Series module.
    ///
    /// This module provides series evaluation (Taylor polynomials, summation, products).
    /// Should be called after MathExprModule to use eval for expression evaluation.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installSeriesModule(in engine: LuaEngine) {
        SeriesModule.register(in: engine)
    }

    /// Install only the Number Theory module.
    ///
    /// This module provides number-theoretic arithmetic functions:
    /// - Euler's totient function (euler_phi)
    /// - Divisor/sigma function (divisor_sigma)
    /// - Möbius function (mobius)
    /// - Liouville function (liouville)
    /// - Carmichael function (carmichael)
    /// - Chebyshev functions (chebyshev_theta, chebyshev_psi)
    /// - Von Mangoldt function (mangoldt)
    /// - Prime counting function (prime_pi)
    /// - Primality testing and factorization (is_prime, factor, primes_up_to)
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installNumberTheoryModule(in engine: LuaEngine) {
        NumberTheoryModule.register(in: engine)
    }
    #endif

    /// Install only the HTTP module.
    ///
    /// This module provides HTTP client functionality using URLSession.
    /// Unlike other modules, HTTPModule is NOT included in `installModules()`
    /// because network access may not be desired in all environments.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let engine = try LuaEngine()
    /// ModuleRegistry.installHTTPModule(in: engine)
    ///
    /// let result = try engine.evaluate("""
    ///     local http = require("luaswift.http")
    ///     local resp = http.get("https://api.example.com/data")
    ///     return resp.status
    /// """)
    /// ```
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installHTTPModule(in engine: LuaEngine) {
        HTTPModule.register(in: engine)
    }

    /// Install only the IO module.
    ///
    /// This module provides sandboxed file system operations. Unlike other modules,
    /// IOModule is NOT included in `installModules()` because it requires explicit
    /// configuration of allowed directories before use.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let engine = try LuaEngine()
    ///
    /// // Configure allowed directories FIRST
    /// IOModule.setAllowedDirectories(["/path/to/allowed/dir"], for: engine)
    ///
    /// // Then install the module
    /// ModuleRegistry.installIOModule(in: engine)
    ///
    /// // Now Lua can use sandboxed file operations
    /// try engine.run("""
    ///     local iox = require("luaswift.iox")
    ///     local content = iox.read_file("/path/to/allowed/dir/file.txt")
    /// """)
    /// ```
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installIOModule(in engine: LuaEngine) {
        IOModule.register(in: engine)
    }
}
