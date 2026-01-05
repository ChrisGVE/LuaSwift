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

/// Protocol for value servers that expose application data to Lua scripts.
///
/// A value server provides access to Swift data through a hierarchical namespace.
/// Lua scripts access values using dot notation, enabling seamless integration
/// between your Swift application state and Lua scripting logic.
///
/// ## Overview
///
/// Value servers bridge the gap between Swift and Lua by exposing Swift data
/// structures as Lua tables. When registered with a ``LuaEngine``, the server's
/// namespace becomes a global Lua variable:
///
/// ```lua
/// -- Access data from Swift
/// local name = MyServer.User.name      -- Read access
/// local config = MyServer.Settings     -- Returns a table
///
/// -- Modify data in Swift (if mutable)
/// MyServer.Cache.result = 42           -- Write access
/// MyServer.User.score = MyServer.User.score + 100
/// ```
///
/// By default, all paths are read-only. Override ``canWrite(path:)`` and
/// ``write(path:value:)`` to enable write access for specific paths.
///
/// ## Mutability Model
///
/// Value servers support three mutability patterns:
///
/// - **Read-only**: Default behavior. All writes throw ``LuaError/readOnlyAccess(path:)``.
/// - **Selective write**: Override `canWrite` to allow writes to specific paths.
/// - **Full read-write**: Return `true` from `canWrite` for all paths.
///
/// Values created by Lua under mutable paths remain mutable until the engine
/// is deallocated or the path is explicitly cleared.
///
/// ## Important: Returning .nil for Intermediate Paths
///
/// When implementing ``resolve(path:)``, you must return `.nil` for paths that
/// represent intermediate (non-leaf) nodes. This allows the engine to create
/// proxy tables with metamethods that properly intercept nested access.
///
/// ```swift
/// func resolve(path: [String]) -> LuaValue {
///     switch path.count {
///     case 0:
///         return .nil  // Root level - return nil for proxy
///     case 1:
///         switch path[0] {
///         case "user":
///             return .nil  // Intermediate node - return nil for proxy
///         case "version":
///             return .string("1.0.0")  // Leaf value
///         default:
///             return .nil
///         }
///     case 2 where path[0] == "user":
///         switch path[1] {
///         case "name": return .string(userName)
///         case "score": return .number(Double(userScore))
///         default: return .nil
///         }
///     default:
///         return .nil
///     }
/// }
/// ```
///
/// If you return an actual value for an intermediate path, Lua will not be able
/// to access nested properties through that path.
///
/// ## Example: Read-Only Server
///
/// A simple server that exposes application configuration:
///
/// ```swift
/// class ConfigServer: LuaValueServer {
///     let namespace = "Config"
///
///     func resolve(path: [String]) -> LuaValue {
///         guard let first = path.first else { return .nil }
///         switch first {
///         case "appName":
///             return .string("MyApp")
///         case "version":
///             return .string("1.2.0")
///         case "debug":
///             return .bool(false)
///         default:
///             return .nil
///         }
///     }
/// }
/// ```
///
/// ## Example: Read-Write Cache Server
///
/// A server with mutable storage for caching computed values:
///
/// ```swift
/// class CacheServer: LuaValueServer {
///     let namespace = "Cache"
///     private var storage: [String: LuaValue] = [:]
///
///     func resolve(path: [String]) -> LuaValue {
///         guard !path.isEmpty else { return .nil }
///         let key = path.joined(separator: ".")
///         return storage[key] ?? .nil
///     }
///
///     func canWrite(path: [String]) -> Bool {
///         return !path.isEmpty  // Allow writes to any non-root path
///     }
///
///     func write(path: [String], value: LuaValue) throws {
///         guard !path.isEmpty else {
///             throw LuaError.valueServerWriteError("Cannot write to root")
///         }
///         let key = path.joined(separator: ".")
///         storage[key] = value
///     }
/// }
/// ```
///
/// ## Example: Nested Data Server
///
/// A server exposing hierarchical application state:
///
/// ```swift
/// class GameServer: LuaValueServer {
///     let namespace = "Game"
///     var playerName = "Hero"
///     var playerHealth = 100
///     var inventory: [String: Int] = ["gold": 50, "potions": 3]
///
///     func resolve(path: [String]) -> LuaValue {
///         switch path.first {
///         case nil:
///             return .nil  // Root - proxy needed
///         case "player":
///             return resolvePlayer(Array(path.dropFirst()))
///         case "inventory":
///             return resolveInventory(Array(path.dropFirst()))
///         default:
///             return .nil
///         }
///     }
///
///     private func resolvePlayer(_ path: [String]) -> LuaValue {
///         guard let key = path.first else { return .nil }  // Intermediate
///         switch key {
///         case "name": return .string(playerName)
///         case "health": return .number(Double(playerHealth))
///         default: return .nil
///         }
///     }
///
///     private func resolveInventory(_ path: [String]) -> LuaValue {
///         guard let item = path.first else {
///             // Return full inventory as table
///             return .table(inventory.mapValues { .number(Double($0)) })
///         }
///         return .number(Double(inventory[item] ?? 0))
///     }
///
///     func canWrite(path: [String]) -> Bool {
///         guard path.count >= 2 else { return false }
///         return path[0] == "player" || path[0] == "inventory"
///     }
///
///     func write(path: [String], value: LuaValue) throws {
///         guard path.count >= 2 else {
///             throw LuaError.valueServerWriteError("Cannot write to \(path)")
///         }
///         switch (path[0], path[1]) {
///         case ("player", "health"):
///             playerHealth = Int(value.numberValue ?? 0)
///         case ("inventory", let item):
///             inventory[item] = Int(value.numberValue ?? 0)
///         default:
///             throw LuaError.readOnlyAccess(path: path.joined(separator: "."))
///         }
///     }
/// }
/// ```
///
/// Usage from Lua:
///
/// ```lua
/// print(Game.player.name)       -- "Hero"
/// print(Game.player.health)     -- 100
/// Game.player.health = 80       -- Update health
/// Game.inventory.potions = Game.inventory.potions - 1
/// ```
///
/// ## Topics
///
/// ### Implementing a Value Server
///
/// - ``namespace``
/// - ``resolve(path:)``
/// - ``canWrite(path:)``
/// - ``write(path:value:)``
///
/// ### Related
///
/// - ``LuaEngine/register(server:)``
/// - ``LuaError``
/// - <doc:ValueServers>
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
