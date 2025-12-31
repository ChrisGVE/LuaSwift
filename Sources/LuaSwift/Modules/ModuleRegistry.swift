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
    /// - `luaswift.regex`: Regular expression support
    ///
    /// - Parameter engine: The Lua engine to install modules in
    public static func installModules(in engine: LuaEngine) {
        installJSONModule(in: engine)
        installRegexModule(in: engine)
    }

    /// Install only the JSON module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installJSONModule(in engine: LuaEngine) {
        JSONModule.register(in: engine)
    }

    /// Install only the Regex module.
    ///
    /// - Parameter engine: The Lua engine to install the module in
    public static func installRegexModule(in engine: LuaEngine) {
        RegexModule.register(in: engine)
    }

    // MARK: - Future Module Registration

    // Additional module registration methods will be added here as modules are implemented:
    // - installYAMLModule(in:)
    // - installTOMLModule(in:)
    // - installMathModule(in:)
    // - installLinAlgModule(in:)
    // - installArrayModule(in:)
}
