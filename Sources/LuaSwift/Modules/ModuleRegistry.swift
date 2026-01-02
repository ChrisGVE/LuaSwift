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
    /// - `luaswift.math`: Extended math functions and statistics
    /// - `luaswift.linalg`: Linear algebra operations
    /// - `luaswift.array`: NumPy-like N-dimensional arrays
    /// - `luaswift.geometry`: Optimized 2D/3D geometry with SIMD
    /// - `luaswift.utf8x`: UTF-8 string utilities with Unicode support
    /// - `luaswift.stringx`: Swift-backed string utilities
    /// - `luaswift.tablex`: Swift-backed table utilities
    /// - `luaswift.complex`: Complex number arithmetic and functions
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
}
