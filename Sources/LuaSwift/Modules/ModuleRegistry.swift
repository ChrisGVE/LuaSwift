//
//  ModuleRegistry.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
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
/// try ModuleRegistry.install(in: engine)
///
/// // Now Lua code can use:
/// // local json = require("luaswift.json")
/// // local value = json.decode('{"key":"value"}')
/// ```
public struct ModuleRegistry {
  /// Install all built-in modules in the specified engine, collecting
  /// per-module failures.
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
  /// Even when a module fails, installation of the remaining modules
  /// continues; every failure is then reported through a single
  /// ``ModuleInstallError`` so that one broken module cannot hide the
  /// state of the others.
  ///
  /// - Parameter engine: The Lua engine to install modules in
  /// - Throws: ``ModuleInstallError`` listing every module whose setup failed
  public static func install(in engine: LuaEngine) throws {
    var failures: [(module: String, error: Error)] = []

    /// Run one module installation, recording (not propagating) its failure
    /// so the remaining modules still get installed.
    func collectFailure(_ moduleName: String, _ installModule: () throws -> Void) {
      do {
        try installModule()
      } catch {
        failures.append((module: moduleName, error: error))
      }
    }

    // Core modules (always available)
    collectFailure("JSONModule") { try JSONModule.install(in: engine) }
    #if LUASWIFT_YAMS
      collectFailure("YAMLModule") { try YAMLModule.install(in: engine) }
    #endif
    #if LUASWIFT_TOMLKIT
      collectFailure("TOMLModule") { try TOMLModule.install(in: engine) }
    #endif
    collectFailure("RegexModule") { try RegexModule.install(in: engine) }
    collectFailure("MathXModule") { try MathXModule.install(in: engine) }
    collectFailure("UTF8XModule") { try UTF8XModule.install(in: engine) }
    collectFailure("StringXModule") { try StringXModule.install(in: engine) }
    collectFailure("TableXModule") { try TableXModule.install(in: engine) }
    collectFailure("TypesModule") { try TypesModule.install(in: engine) }
    collectFailure("SVGModule") { try SVGModule.install(in: engine) }

    // ArraySwift-dependent module
    #if LUASWIFT_ARRAYSWIFT
      collectFailure("ArrayModule") { try ArrayModule.install(in: engine) }
    #endif

    // PlotSwift-dependent module
    #if LUASWIFT_PLOTSWIFT
      collectFailure("PlotModule") { try PlotModule.install(in: engine) }
    #endif

    // NumericSwift-dependent modules
    #if LUASWIFT_NUMERICSWIFT
      collectFailure("LinAlgModule") { try LinAlgModule.install(in: engine) }
      collectFailure("GeometryModule") { try GeometryModule.install(in: engine) }
      collectFailure("ComplexModule") { try ComplexModule.install(in: engine) }
      // MathSciModule must come before MathExprModule to create the math.eval namespace
      collectFailure("MathSciModule") { try MathSciModule.install(in: engine) }
      collectFailure("MathExprModule") { try MathExprModule.install(in: engine) }
      collectFailure("OptimizeModule") { try OptimizeModule.install(in: engine) }
      collectFailure("IntegrateModule") { try IntegrateModule.install(in: engine) }
      collectFailure("DistributionsModule") { try DistributionsModule.install(in: engine) }
      collectFailure("InterpolateModule") { try InterpolateModule.install(in: engine) }
      collectFailure("ClusterModule") { try ClusterModule.install(in: engine) }
      collectFailure("SpatialModule") { try SpatialModule.install(in: engine) }
      collectFailure("SpecialModule") { try SpecialModule.install(in: engine) }
      collectFailure("RegressModule") { try RegressModule.install(in: engine) }
      // SeriesModule must come after MathExprModule (uses eval)
      collectFailure("SeriesModule") { try SeriesModule.install(in: engine) }
      collectFailure("NumberTheoryModule") { try NumberTheoryModule.install(in: engine) }
    #endif

    // Thales CAS module
    #if LUASWIFT_THALES
      collectFailure("ThalesModule") { try ThalesModule.install(in: engine) }
    #endif

    #if DEBUG
      collectFailure("DebugModule") { try DebugModule.install(in: engine) }
    #endif
    collectFailure("extend_stdlib") { try installExtendStdlib(in: engine) }

    if !failures.isEmpty {
      throw ModuleInstallError(failures: failures)
    }
  }

  /// Deprecated alias for ``install(in:)`` that swallows setup failures.
  ///
  /// - Parameter engine: The Lua engine to install modules in
  @available(*, deprecated, message: "Use install(in:) which surfaces setup failures; installModules(in:) swallows them.")
  public static func installModules(in engine: LuaEngine) {
    installSwallowingFailure("ModuleRegistry.install") { try install(in: engine) }
  }

  /// Run one module installation for a deprecated non-throwing entry point,
  /// swallowing any failure (DEBUG builds print it).
  private static func installSwallowingFailure(
    _ moduleName: String, _ installModule: () throws -> Void
  ) {
    do {
      try installModule()
    } catch {
      #if DEBUG
        print("[LuaSwift] \(moduleName) setup failed: \(error)")
      #endif
    }
  }

  /// Install the extend_stdlib() helper function and top-level aliases.
  ///
  /// This creates:
  /// - Top-level aliases for all modules (json, yaml, toml, regex, linalg, array, geo, complex, types)
  /// - `luaswift.extend_stdlib()` which imports all extensions into standard library
  ///
  /// - Parameter engine: The Lua engine to install in
  /// - Throws: An error if the Lua setup code fails to run
  private static func installExtendStdlib(in engine: LuaEngine) throws {
    try engine.run(
      """
        if not luaswift then luaswift = {} end

        -- Create top-level global aliases for all modules
        json = luaswift.json
        if luaswift.yaml then yaml = luaswift.yaml end
        if luaswift.toml then toml = luaswift.toml end
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
  }

  /// Install only the JSON module.
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use JSONModule.install(in:) which surfaces setup failures.")
  public static func installJSONModule(in engine: LuaEngine) {
    installSwallowingFailure("JSONModule") { try JSONModule.install(in: engine) }
  }

  #if LUASWIFT_YAMS
    /// Install only the YAML module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use YAMLModule.install(in:) which surfaces setup failures.")
    public static func installYAMLModule(in engine: LuaEngine) {
      installSwallowingFailure("YAMLModule") { try YAMLModule.install(in: engine) }
    }
  #endif

  #if LUASWIFT_TOMLKIT
    /// Install only the TOML module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use TOMLModule.install(in:) which surfaces setup failures.")
    public static func installTOMLModule(in engine: LuaEngine) {
      installSwallowingFailure("TOMLModule") { try TOMLModule.install(in: engine) }
    }
  #endif

  /// Install only the Regex module.
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use RegexModule.install(in:) which surfaces setup failures.")
  public static func installRegexModule(in engine: LuaEngine) {
    installSwallowingFailure("RegexModule") { try RegexModule.install(in: engine) }
  }

  #if LUASWIFT_NUMERICSWIFT
    /// Install only the Linear Algebra module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use LinAlgModule.install(in:) which surfaces setup failures.")
    public static func installLinAlgModule(in engine: LuaEngine) {
      installSwallowingFailure("LinAlgModule") { try LinAlgModule.install(in: engine) }
    }
  #endif

  /// Install only the Math extension module.
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use MathXModule.install(in:) which surfaces setup failures.")
  public static func installMathModule(in engine: LuaEngine) {
    installSwallowingFailure("MathXModule") { try MathXModule.install(in: engine) }
  }

  #if LUASWIFT_ARRAYSWIFT
    /// Install only the Array module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use ArrayModule.install(in:) which surfaces setup failures.")
    public static func installArrayModule(in engine: LuaEngine) {
      installSwallowingFailure("ArrayModule") { try ArrayModule.install(in: engine) }
    }
  #endif

  #if LUASWIFT_NUMERICSWIFT
    /// Install only the Geometry module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use GeometryModule.install(in:) which surfaces setup failures.")
    public static func installGeometryModule(in engine: LuaEngine) {
      installSwallowingFailure("GeometryModule") { try GeometryModule.install(in: engine) }
    }
  #endif

  /// Install only the UTF8X module.
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use UTF8XModule.install(in:) which surfaces setup failures.")
  public static func installUTF8XModule(in engine: LuaEngine) {
    installSwallowingFailure("UTF8XModule") { try UTF8XModule.install(in: engine) }
  }

  /// Install only the StringX module.
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use StringXModule.install(in:) which surfaces setup failures.")
  public static func installStringXModule(in engine: LuaEngine) {
    installSwallowingFailure("StringXModule") { try StringXModule.install(in: engine) }
  }

  /// Install only the TableX module.
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use TableXModule.install(in:) which surfaces setup failures.")
  public static func installTableXModule(in engine: LuaEngine) {
    installSwallowingFailure("TableXModule") { try TableXModule.install(in: engine) }
  }

  #if LUASWIFT_NUMERICSWIFT
    /// Install only the Complex module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use ComplexModule.install(in:) which surfaces setup failures.")
    public static func installComplexModule(in engine: LuaEngine) {
      installSwallowingFailure("ComplexModule") { try ComplexModule.install(in: engine) }
    }
  #endif

  /// Install only the Types module.
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use TypesModule.install(in:) which surfaces setup failures.")
  public static func installTypesModule(in engine: LuaEngine) {
    installSwallowingFailure("TypesModule") { try TypesModule.install(in: engine) }
  }

  /// Install only the SVG module.
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use SVGModule.install(in:) which surfaces setup failures.")
  public static func installSVGModule(in engine: LuaEngine) {
    installSwallowingFailure("SVGModule") { try SVGModule.install(in: engine) }
  }

  #if LUASWIFT_NUMERICSWIFT
    /// Install only the MathExpr module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use MathExprModule.install(in:) which surfaces setup failures.")
    public static func installMathExprModule(in engine: LuaEngine) {
      installSwallowingFailure("MathExprModule") { try MathExprModule.install(in: engine) }
    }
  #endif

  #if DEBUG
    /// Install only the Debug module.
    ///
    /// This module is only available in DEBUG builds.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use DebugModule.install(in:) which surfaces setup failures.")
    public static func installDebugModule(in engine: LuaEngine) {
      installSwallowingFailure("DebugModule") { try DebugModule.install(in: engine) }
    }
  #endif

  #if LUASWIFT_PLOTSWIFT
    /// Install only the Plot module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use PlotModule.install(in:) which surfaces setup failures.")
    public static func installPlotModule(in engine: LuaEngine) {
      installSwallowingFailure("PlotModule") { try PlotModule.install(in: engine) }
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
    @available(*, deprecated, message: "Use MathSciModule.install(in:) which surfaces setup failures.")
    public static func installMathSciModule(in engine: LuaEngine) {
      installSwallowingFailure("MathSciModule") { try MathSciModule.install(in: engine) }
    }

    /// Install only the Optimize module.
    ///
    /// This module provides numerical optimization functions.
    /// Should be called after MathSciModule to add to math.optimize namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use OptimizeModule.install(in:) which surfaces setup failures.")
    public static func installOptimizeModule(in engine: LuaEngine) {
      installSwallowingFailure("OptimizeModule") { try OptimizeModule.install(in: engine) }
    }

    /// Install only the Integrate module.
    ///
    /// This module provides numerical integration functions.
    /// Should be called after MathSciModule to add to math.integrate namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use IntegrateModule.install(in:) which surfaces setup failures.")
    public static func installIntegrateModule(in engine: LuaEngine) {
      installSwallowingFailure("IntegrateModule") { try IntegrateModule.install(in: engine) }
    }

    /// Install only the Distributions module.
    ///
    /// This module provides probability distributions (norm, uniform, t, chi2, etc.).
    /// Should be called after MathSciModule to add to math.stats namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use DistributionsModule.install(in:) which surfaces setup failures.")
    public static func installDistributionsModule(in engine: LuaEngine) {
      installSwallowingFailure("DistributionsModule") { try DistributionsModule.install(in: engine) }
    }

    /// Install only the Interpolate module.
    ///
    /// This module provides interpolation functions (interp1d, CubicSpline, etc.).
    /// Should be called after MathSciModule to add to math.interpolate namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use InterpolateModule.install(in:) which surfaces setup failures.")
    public static func installInterpolateModule(in engine: LuaEngine) {
      installSwallowingFailure("InterpolateModule") { try InterpolateModule.install(in: engine) }
    }

    /// Install only the Cluster module.
    ///
    /// This module provides clustering algorithms (kmeans, hierarchical, DBSCAN).
    /// Should be called after MathSciModule to add to math.cluster namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use ClusterModule.install(in:) which surfaces setup failures.")
    public static func installClusterModule(in engine: LuaEngine) {
      installSwallowingFailure("ClusterModule") { try ClusterModule.install(in: engine) }
    }

    /// Install only the Spatial module.
    ///
    /// This module provides spatial algorithms (KDTree, distance functions, Voronoi, Delaunay).
    /// Should be called after MathSciModule to add to math.spatial namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use SpatialModule.install(in:) which surfaces setup failures.")
    public static func installSpatialModule(in engine: LuaEngine) {
      installSwallowingFailure("SpatialModule") { try SpatialModule.install(in: engine) }
    }

    /// Install only the Special functions module.
    ///
    /// This module provides advanced special mathematical functions (erf, beta, bessel).
    /// Should be called after MathSciModule to add to math.special namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use SpecialModule.install(in:) which surfaces setup failures.")
    public static func installSpecialModule(in engine: LuaEngine) {
      installSwallowingFailure("SpecialModule") { try SpecialModule.install(in: engine) }
    }

    /// Install only the Regress module.
    ///
    /// This module provides regression models (OLS, WLS, GLS, GLM, ARIMA).
    /// Should be called after MathSciModule to add to math.regress namespace.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use RegressModule.install(in:) which surfaces setup failures.")
    public static func installRegressModule(in engine: LuaEngine) {
      installSwallowingFailure("RegressModule") { try RegressModule.install(in: engine) }
    }

    /// Install only the Series module.
    ///
    /// This module provides series evaluation (Taylor polynomials, summation, products).
    /// Should be called after MathExprModule to use eval for expression evaluation.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use SeriesModule.install(in:) which surfaces setup failures.")
    public static func installSeriesModule(in engine: LuaEngine) {
      installSwallowingFailure("SeriesModule") { try SeriesModule.install(in: engine) }
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
    @available(*, deprecated, message: "Use NumberTheoryModule.install(in:) which surfaces setup failures.")
    public static func installNumberTheoryModule(in engine: LuaEngine) {
      installSwallowingFailure("NumberTheoryModule") { try NumberTheoryModule.install(in: engine) }
    }
  #endif

  #if LUASWIFT_THALES
    /// Install only the Thales CAS module.
    ///
    /// This module provides symbolic mathematics via the Thales Computer Algebra System:
    /// simplification, equation solving, calculus, series, ODEs, and LaTeX formatting.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    @available(*, deprecated, message: "Use ThalesModule.install(in:) which surfaces setup failures.")
    public static func installThalesModule(in engine: LuaEngine) {
      installSwallowingFailure("ThalesModule") { try ThalesModule.install(in: engine) }
    }
  #endif

  /// Install only the HTTP module.
  ///
  /// This module provides HTTP client functionality using URLSession.
  /// Unlike other modules, HTTPModule is NOT included in `ModuleRegistry.install(in:)`
  /// because network access may not be desired in all environments.
  ///
  /// ## Usage
  ///
  /// ```swift
  /// let engine = try LuaEngine()
  /// try HTTPModule.install(in: engine)
  ///
  /// let result = try engine.evaluate("""
  ///     local http = require("luaswift.http")
  ///     local resp = http.get("https://api.example.com/data")
  ///     return resp.status
  /// """)
  /// ```
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use HTTPModule.install(in:) which surfaces setup failures.")
  public static func installHTTPModule(in engine: LuaEngine) {
    installSwallowingFailure("HTTPModule") { try HTTPModule.install(in: engine) }
  }

  /// Install only the IO module.
  ///
  /// This module provides sandboxed file system operations. Unlike other modules,
  /// IOModule is NOT included in `ModuleRegistry.install(in:)` because it requires explicit
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
  /// try IOModule.install(in: engine)
  ///
  /// // Now Lua can use sandboxed file operations
  /// try engine.run("""
  ///     local iox = require("luaswift.iox")
  ///     local content = iox.read_file("/path/to/allowed/dir/file.txt")
  /// """)
  /// ```
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use IOModule.install(in:) which surfaces setup failures.")
  public static func installIOModule(in engine: LuaEngine) {
    installSwallowingFailure("IOModule") { try IOModule.install(in: engine) }
  }

  /// Install only the UI module.
  ///
  /// This module provides alert and confirmation dialog support using native platform
  /// APIs (NSAlert on macOS, UIAlertController on iOS). Unlike other modules,
  /// UIModule is NOT included in `ModuleRegistry.install(in:)` because it requires a running
  /// main run loop and UI framework access.
  ///
  /// Lua calls to `ui.alert()` and `ui.confirm()` block until the user dismisses
  /// the dialog and return a 1-indexed button number.
  ///
  /// ## Usage
  ///
  /// ```swift
  /// let engine = try LuaEngine()
  /// try UIModule.install(in: engine)
  ///
  /// let result = try engine.evaluate("""
  ///     local ui = require("luaswift.ui")
  ///     return ui.alert("Title", "Message", {"OK", "Cancel"})
  /// """)
  /// // result == .number(1) when OK is pressed
  /// ```
  ///
  /// - Parameter engine: The Lua engine to install the module in
  @available(*, deprecated, message: "Use UIModule.install(in:) which surfaces setup failures.")
  public static func installUIModule(in engine: LuaEngine) {
    installSwallowingFailure("UIModule") { try UIModule.install(in: engine) }
  }
}
