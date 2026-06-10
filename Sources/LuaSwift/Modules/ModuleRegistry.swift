//
//  ModuleRegistry.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-31.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/Modules/ModuleRegistry.swift
//
//  Context: Central installer/registry for the Swift-backed Lua modules.
//  ModuleRegistry.install(in:) drives the whole module set: orderedModuleTypes()
//  builds the install list from `[any LuaSwiftModule.Type]` under the same
//  `#if LUASWIFT_*` gates that select the package's optional dependencies
//  (Package.swift), so a module is present only when its backing dependency was
//  compiled in. Each module's `install(in:)` registers its Swift callbacks and
//  runs its Lua setup, which seeds `package.loaded["luaswift.<name>"]` so Lua
//  `require("luaswift.<name>")` resolves; a trailing extend_stdlib step then
//  wires the top-level aliases and the `luaswift.extend_stdlib()` helper. Install
//  order is load-bearing (MathSci → MathExpr → Series) and a small prerequisite
//  cascade skips a dependent whose prerequisite failed. Failures never abort the
//  loop: every per-module failure (and synthetic prerequisite skip) is collected
//  and surfaced once through ModuleInstallError, so one broken module cannot hide
//  the state of the others; each success is also recorded in
//  LuaEngine.installedModules for introspection (#21).
//
//  Neighbors:
//    LuaSwiftModule.swift             — the protocol each module adopts (install(in:))
//    ModuleInstallError.swift         — aggregated failure type install(in:) throws
//    ModuleRegistry+Deprecated.swift  — older register(in:) entry points
//    Modules/Swift/*.swift            — the concrete LuaSwiftModule conformers
//    LuaEngine+Introspection.swift    — installedModules set populated on success
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
  /// The ordered module set is built from `[any LuaSwiftModule.Type]` under the
  /// same `#if LUASWIFT_*` gates that select the package's optional
  /// dependencies, and each module's failure label is derived from its
  /// ``LuaSwiftModule/moduleName`` rather than a hardcoded string. The install
  /// order is significant and preserved: `MathSciModule` creates the
  /// `math.eval` namespace consumed by `MathExprModule`, and `SeriesModule`
  /// runs after `MathExprModule` because it uses `eval`.
  ///
  /// A small prerequisite cascade protects those dependencies: if a documented
  /// prerequisite failed (or was itself skipped), the dependent module is
  /// skipped and recorded as a synthetic failure rather than being installed
  /// against a half-built engine state. Concretely, `MathExprModule` is skipped
  /// when `MathSciModule` failed, and `SeriesModule` is skipped when
  /// `MathExprModule` failed or was skipped.
  ///
  /// `extend_stdlib` is run last. It is not a module — it wires the top-level
  /// aliases and the `luaswift.extend_stdlib()` helper after every module is
  /// installed — so it is collected as a trailing special step.
  ///
  /// - Parameter engine: The Lua engine to install modules in
  /// - Throws: ``ModuleInstallError`` listing every module whose setup failed
  public static func install(in engine: LuaEngine) throws {
    var outcomes = InstallOutcomes(engine: engine)

    // Documented prerequisite edges (dependent → prerequisite). A dependent is
    // skipped when its prerequisite is unavailable.
    let prerequisites: [String: String] = [
      "MathExprModule": "MathSciModule",
      "SeriesModule": "MathExprModule",
    ]

    for moduleType in orderedModuleTypes() {
      let name = moduleType.moduleName
      if let prerequisite = prerequisites[name], outcomes.unavailable.contains(prerequisite) {
        // Prerequisite failed/skipped: record a synthetic skip rather than
        // installing against a broken engine state.
        outcomes.skip(name, missingPrerequisite: prerequisite)
        continue
      }
      outcomes.collect(name) { try moduleType.install(in: engine) }
    }

    // extend_stdlib is a finalization step, not a module — do not record it in
    // installedModules (it must not appear in installedModuleNames).
    outcomes.collect("extend_stdlib", record: false) { try installExtendStdlib(in: engine) }

    if !outcomes.failures.isEmpty {
      throw ModuleInstallError(failures: outcomes.failures)
    }
  }

  /// Accumulates per-module install outcomes for ``install(in:)`` so one broken
  /// module cannot hide the state of the others. Successes are recorded in the
  /// engine's introspection set; failures and skips are tracked so the
  /// prerequisite cascade can short-circuit their dependents.
  private struct InstallOutcomes {
    let engine: LuaEngine
    var failures: [ModuleInstallError.Failure] = []
    /// Names of modules that failed or were skipped.
    var unavailable: Set<String> = []

    /// Run one module installation, recording (not propagating) any failure so
    /// the remaining modules still install. On success the module name is
    /// recorded in ``LuaEngine/installedModules`` for introspection (F4 / #21)
    /// unless `record` is `false` — finalization steps like `extend_stdlib` are
    /// not `LuaSwiftModule`s and must not appear in `installedModuleNames`.
    mutating func collect(
      _ moduleName: String, record: Bool = true, _ installModule: () throws -> Void
    ) {
      do {
        try installModule()
        if record { engine.installedModules.insert(moduleName) }
      } catch {
        failures.append(.init(module: moduleName, underlyingError: error))
        unavailable.insert(moduleName)
      }
    }

    /// Record a synthetic skip for a module whose prerequisite is unavailable,
    /// standing in for it in the aggregated ``ModuleInstallError``.
    mutating func skip(_ moduleName: String, missingPrerequisite prerequisite: String) {
      failures.append(.init(
        module: moduleName,
        underlyingError: ModulePrerequisiteError(module: moduleName, prerequisite: prerequisite)))
      unavailable.insert(moduleName)
    }
  }

  /// The ordered set of modules ``install(in:)`` registers, in install order.
  ///
  /// Gates mirror the optional dependencies declared in Package.swift; order
  /// within the NumericSwift block is load-bearing (see ``install(in:)``'s doc
  /// comment): `MathSciModule` precedes `MathExprModule` (creates `math.eval`),
  /// and `SeriesModule` follows `MathExprModule` (uses `eval`).
  static func orderedModuleTypes() -> [any LuaSwiftModule.Type] {
    var modules: [any LuaSwiftModule.Type] = [JSONModule.self]
    #if LUASWIFT_YAMS
      modules.append(YAMLModule.self)
    #endif
    #if LUASWIFT_TOMLKIT
      modules.append(TOMLModule.self)
    #endif
    modules.append(contentsOf: [
      RegexModule.self,
      MathXModule.self,
      UTF8XModule.self,
      StringXModule.self,
      TableXModule.self,
      TypesModule.self,
      SVGModule.self,
    ])
    #if LUASWIFT_ARRAYSWIFT
      modules.append(ArrayModule.self)
    #endif
    #if LUASWIFT_PLOTSWIFT
      modules.append(PlotModule.self)
    #endif
    #if LUASWIFT_NUMERICSWIFT
      modules.append(contentsOf: [
        LinAlgModule.self,
        GeometryModule.self,
        ComplexModule.self,
        MathSciModule.self,
        MathExprModule.self,
        OptimizeModule.self,
        IntegrateModule.self,
        DistributionsModule.self,
        InterpolateModule.self,
        ClusterModule.self,
        SpatialModule.self,
        SpecialModule.self,
        RegressModule.self,
        SeriesModule.self,
        NumberTheoryModule.self,
      ])
    #endif
    #if LUASWIFT_THALES
      modules.append(ThalesModule.self)
    #endif
    #if DEBUG
      modules.append(DebugModule.self)
    #endif
    return modules
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
    try engine.run(extendStdlibScript)
  }

  /// Lua run once by ``installExtendStdlib(in:)``: it creates the top-level
  /// module aliases (json/yaml/toml/regex/types and the optional
  /// linalg/array/geo/complex) and defines `luaswift.extend_stdlib()`, which
  /// imports the `*x` extensions into the standard library and adds the `math.*`
  /// subnamespaces. Optional modules are each guarded so a missing one does not
  /// create an explicit `nil` global.
  private static let extendStdlibScript = """
    if not luaswift then luaswift = {} end

    -- Create top-level global aliases for all modules
    json = luaswift.json
    if luaswift.yaml then yaml = luaswift.yaml end
    if luaswift.toml then toml = luaswift.toml end
    regex = luaswift.regex
    types = luaswift.types

    -- Optional (NumericSwift/ArraySwift) modules may be absent; guard each
    -- alias so it does not create an explicit nil global when missing.
    if luaswift.linalg then linalg = luaswift.linalg end
    if luaswift.array then array = luaswift.array end
    if luaswift.geometry then geo = luaswift.geometry end
    if luaswift.complex then complex = luaswift.complex end

    -- Also create luaswift.geo as alias
    if luaswift.geometry then luaswift.geo = luaswift.geometry end

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
    """
}

/// Synthetic error recorded by ``ModuleRegistry/install(in:)`` for a module
/// that was *skipped* because one of its documented prerequisites failed (or
/// was itself skipped). The dependent is not installed against a half-built
/// engine state; instead this stands in for it in the aggregated
/// ``ModuleInstallError``.
///
/// This type is module-internal, so a consumer inspecting
/// ``ModuleInstallError/Failure/underlyingError`` cannot pattern-match it;
/// a skip is identified by its ``errorDescription`` ("skipped: …
/// prerequisite failed").
struct ModulePrerequisiteError: Error, LocalizedError {
  /// The dependent module that was skipped.
  let module: String

  /// The prerequisite module whose unavailability caused the skip.
  let prerequisite: String

  var errorDescription: String? {
    "skipped: \(prerequisite) prerequisite failed"
  }
}
