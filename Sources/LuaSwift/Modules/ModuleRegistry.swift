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
    /// - `luaswift.linalg`: Linear algebra operations
    /// - `luaswift.array`: NumPy-like N-dimensional arrays
    ///
    /// - Parameter engine: The Lua engine to install modules in
    public static func installModules(in engine: LuaEngine) {
        installJSONModule(in: engine)
        installYAMLModule(in: engine)
        installTOMLModule(in: engine)
        installRegexModule(in: engine)
        installLinAlgModule(in: engine)
        installArrayModule(in: engine)
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
}
