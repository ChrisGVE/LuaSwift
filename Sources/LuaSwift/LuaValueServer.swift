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
/// A value server provides read-only access to application data through
/// a hierarchical namespace. Lua scripts access values using dot notation:
///
/// ```lua
/// local name = MyServer.User.name
/// local count = MyServer.Items.count
/// ```
///
/// Implement this protocol to expose your application's data to Lua.
///
/// ## Example Implementation
///
/// ```swift
/// class AppServer: LuaValueServer {
///     let namespace = "App"
///
///     func resolve(path: [String]) -> LuaValue {
///         guard !path.isEmpty else { return .nil }
///         switch path[0] {
///         case "version":
///             return .string("1.0.0")
///         case "user":
///             return resolveUser(path: Array(path.dropFirst()))
///         default:
///             return .nil
///         }
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
}

/// Extension providing default implementations and utilities.
public extension LuaValueServer {
    /// Resolve a dot-separated path string.
    ///
    /// - Parameter pathString: A dot-separated path like "User.name"
    /// - Returns: The resolved value
    func resolve(pathString: String) -> LuaValue {
        let components = pathString.split(separator: ".").map(String.init)
        return resolve(path: components)
    }
}
