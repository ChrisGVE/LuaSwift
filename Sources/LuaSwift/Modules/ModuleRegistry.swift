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
    /// - `luaswift.sliderule`: Slide rule simulation for analog computation
    /// - `luaswift.plot`: Matplotlib-compatible plotting with retained vector graphics
    /// - `luaswift.debug`: Debugging utilities (DEBUG builds only)
    ///
    /// Top-level aliases are also created: `stringx`, `mathx`, `tablex`, `utf8x`,
    /// `complex`, `linalg`, `geo`, `array`, `json`, `yaml`, `toml`, `regex`, `types`,
    /// `svg_module`, `mathexpr_module`, `sliderule_module`, `plt`, `debug_module`.
    ///
    /// Use `luaswift.extend_stdlib()` to inject all extensions into the standard library.
    ///
    /// - Parameter engine: The Lua engine to install modules in
    public static func installModules(in engine: LuaEngine) {
        installJSONModule(in: engine)
        installYAMLModule(in: engine)
        installTOMLModule(in: engine)
        installRegexModule(in: engine)
        installMathModule(in: engine)
        installLinAlgModule(in: engine)
        installArrayModule(in: engine)
        installGeometryModule(in: engine)
        installUTF8XModule(in: engine)
        installStringXModule(in: engine)
        installTableXModule(in: engine)
        installComplexModule(in: engine)
        installTypesModule(in: engine)
        installSVGModule(in: engine)
        installMathExprModule(in: engine)
        installSlideRuleModule(in: engine)
        installPlotModule(in: engine)
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

                -- Create sliderule alias
                sliderule = luaswift.sliderule

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
                end
                """)
        } catch {
            // Silently fail if setup fails
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

    /// Install only the Linear Algebra module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installLinAlgModule(in engine: LuaEngine) {
        LinAlgModule.register(in: engine)
    }

    /// Install only the Math extension module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installMathModule(in engine: LuaEngine) {
        MathXModule.register(in: engine)
    }

    /// Install only the Array module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installArrayModule(in engine: LuaEngine) {
        ArrayModule.register(in: engine)
    }

    /// Install only the Geometry module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installGeometryModule(in engine: LuaEngine) {
        GeometryModule.register(in: engine)
    }

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

    /// Install only the Complex module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installComplexModule(in engine: LuaEngine) {
        ComplexModule.register(in: engine)
    }

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

    /// Install only the MathExpr module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installMathExprModule(in engine: LuaEngine) {
        MathExprModule.register(in: engine)
    }

    /// Install only the SlideRule module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installSlideRuleModule(in engine: LuaEngine) {
        SlideRuleModule.register(in: engine)
    }

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

    /// Install only the Plot module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installPlotModule(in engine: LuaEngine) {
        PlotModule.register(in: engine)
    }
}
