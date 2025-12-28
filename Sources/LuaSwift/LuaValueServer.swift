//
//  LuaValueServer.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Protocol for value servers that expose data to Lua scripts.
///
/// A value server provides access to application data through a hierarchical
/// namespace. Lua scripts access values using dot notation:
///
/// ```lua
/// local name = MyServer.User.name      -- Read access
/// MyServer.Cache.result = 42           -- Write access (if mutable)
/// ```
///
/// By default, all paths are read-only. Override `canWrite(path:)` and
/// `write(path:value:)` to enable write access for specific paths.
///
/// ## Mutability Model
///
/// - **Immutable paths**: Cannot be modified or have children added
/// - **Mutable paths**: Can have values modified and children added
/// - Values created by Lua under mutable paths remain mutable
///
/// ## Example Implementation
///
/// ```swift
/// class AppServer: LuaValueServer {
///     let namespace = "App"
///     private var cache: [String: LuaValue] = [:]
///
///     func resolve(path: [String]) -> LuaValue {
///         guard !path.isEmpty else { return .nil }
///         switch path[0] {
///         case "version":
///             return .string("1.0.0")  // Read-only
///         case "cache":
///             return resolveCache(Array(path.dropFirst()))
///         default:
///             return .nil
///         }
///     }
///
///     func canWrite(path: [String]) -> Bool {
///         // Allow writes under "cache" path
///         return path.first == "cache"
///     }
///
///     func write(path: [String], value: LuaValue) throws {
///         guard path.first == "cache", path.count >= 2 else {
///             throw LuaError.readOnlyAccess(path: path.joined(separator: "."))
///         }
///         let key = path.dropFirst().joined(separator: ".")
///         cache[key] = value
///     }
/// }
/// ```
public protocol LuaValueServer: AnyObject {
    /// The namespace under which this server's values are accessible in Lua.
    ///
    /// For example, if `namespace` is `"MyApp"`, Lua accesses values as:
    /// `MyApp.path.to.value`
    var namespace: String { get }

    /// Resolve a path to a value.
    ///
    /// - Parameter path: The path components after the namespace.
    ///   For `MyApp.User.name`, path would be `["User", "name"]`.
    /// - Returns: The resolved value, or `.nil` if the path is invalid.
    func resolve(path: [String]) -> LuaValue

    /// Check if a path can be written to.
    ///
    /// Override this method to enable write access for specific paths.
    /// The default implementation returns `false` for all paths.
    ///
    /// - Parameter path: The path components to check.
    /// - Returns: `true` if the path accepts writes, `false` otherwise.
    func canWrite(path: [String]) -> Bool

    /// Write a value to a path.
    ///
    /// Override this method to handle writes for mutable paths.
    /// The default implementation throws `LuaError.readOnlyAccess`.
    ///
    /// - Parameters:
    ///   - path: The path components to write to.
    ///   - value: The value to write.
    /// - Throws: `LuaError.readOnlyAccess` if the path is not writable.
    func write(path: [String], value: LuaValue) throws
}

/// Extension providing default implementations.
public extension LuaValueServer {
    /// Default implementation: all paths are read-only.
    func canWrite(path: [String]) -> Bool {
        return false
    }

    /// Default implementation: throws read-only error.
    func write(path: [String], value: LuaValue) throws {
        throw LuaError.readOnlyAccess(path: "\(namespace).\(path.joined(separator: "."))")
    }

    /// Resolve a dot-separated path string.
    ///
    /// - Parameter pathString: A dot-separated path like "User.name"
    /// - Returns: The resolved value
    func resolve(pathString: String) -> LuaValue {
        let components = pathString.split(separator: ".").map(String.init)
        return resolve(path: components)
    }
}
