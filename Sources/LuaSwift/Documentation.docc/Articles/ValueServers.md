# Working with Value Servers

Expose your Swift application state to Lua scripts using the LuaValueServer protocol.

## Overview

Value servers provide a powerful way to bridge Swift data with Lua scripts. Instead of manually marshaling data back and forth, you define a server that automatically exposes your Swift properties as Lua variables.

When Lua code accesses `MyServer.path.to.value`, the engine calls your server's `resolve(path:)` method with `["path", "to", "value"]`. You return the appropriate ``LuaValue``, and the Lua script receives it seamlessly.

## Creating a Read-Only Server

The simplest value server exposes read-only data. Implement the ``LuaValueServer`` protocol with just two requirements:

```swift
class AppInfoServer: LuaValueServer {
    let namespace = "AppInfo"

    func resolve(path: [String]) -> LuaValue {
        guard let key = path.first, path.count == 1 else {
            return .nil
        }

        switch key {
        case "name":
            return .string(Bundle.main.appName ?? "Unknown")
        case "version":
            return .string(Bundle.main.version ?? "0.0.0")
        case "build":
            return .string(Bundle.main.buildNumber ?? "0")
        case "platform":
            #if os(iOS)
            return .string("iOS")
            #elseif os(macOS)
            return .string("macOS")
            #else
            return .string("unknown")
            #endif
        default:
            return .nil
        }
    }
}

// Register with the engine
let server = AppInfoServer()
engine.register(server: server)

// Now Lua can access:
// AppInfo.name     -> "MyApp"
// AppInfo.version  -> "1.2.0"
// AppInfo.platform -> "iOS"
```

## The Importance of Returning .nil

A critical implementation detail: you must return `.nil` for paths that represent **intermediate nodes** (non-leaf paths). This allows the engine to create proxy tables with metamethods.

### Why This Matters

When Lua accesses `Server.user.name`, it actually performs two operations:
1. Get `Server.user` (intermediate path)
2. Get `name` from the result

If `resolve(path: ["user"])` returns an actual value instead of `.nil`, Lua receives that value directly and cannot access `.name` on it. The engine needs to return a proxy table that intercepts the second access.

### Correct Pattern

```swift
func resolve(path: [String]) -> LuaValue {
    switch path.count {
    case 0:
        return .nil  // Root - needs proxy
    case 1:
        switch path[0] {
        case "user":
            return .nil  // Intermediate - needs proxy
        case "version":
            return .string("1.0")  // Leaf - return value
        default:
            return .nil
        }
    case 2 where path[0] == "user":
        switch path[1] {
        case "name": return .string("Alice")
        case "email": return .string("alice@example.com")
        default: return .nil
        }
    default:
        return .nil
    }
}
```

### Returning Tables for Iteration

If you need Lua to iterate over a node's children, you can return a table:

```swift
func resolve(path: [String]) -> LuaValue {
    guard path.count == 1, path[0] == "settings" else { return .nil }

    // Return a table when Lua needs to iterate
    return .table([
        "theme": .string("dark"),
        "fontSize": .number(14),
        "notifications": .bool(true)
    ])
}
```

This allows Lua code like:
```lua
for key, value in pairs(Server.settings) do
    print(key, value)
end
```

## Adding Write Support

To allow Lua to modify values, implement `canWrite(path:)` and `write(path:value:)`:

```swift
class SettingsServer: LuaValueServer {
    let namespace = "Settings"

    // Stored settings
    private var theme = "light"
    private var volume = 0.8
    private var notifications = true

    func resolve(path: [String]) -> LuaValue {
        guard let key = path.first, path.count == 1 else {
            return .nil
        }

        switch key {
        case "theme": return .string(theme)
        case "volume": return .number(volume)
        case "notifications": return .bool(notifications)
        default: return .nil
        }
    }

    func canWrite(path: [String]) -> Bool {
        guard path.count == 1 else { return false }
        return ["theme", "volume", "notifications"].contains(path[0])
    }

    func write(path: [String], value: LuaValue) throws {
        guard let key = path.first, path.count == 1 else {
            throw LuaError.valueServerWriteError("Invalid path")
        }

        switch key {
        case "theme":
            guard let str = value.stringValue else {
                throw LuaError.valueServerWriteError("theme must be a string")
            }
            theme = str

        case "volume":
            guard let num = value.numberValue else {
                throw LuaError.valueServerWriteError("volume must be a number")
            }
            volume = max(0, min(1, num))  // Clamp to 0-1

        case "notifications":
            guard let bool = value.boolValue else {
                throw LuaError.valueServerWriteError("notifications must be a boolean")
            }
            notifications = bool

        default:
            throw LuaError.readOnlyAccess(path: path.joined(separator: "."))
        }
    }
}
```

Now Lua can both read and write:
```lua
print(Settings.volume)      -- 0.8
Settings.volume = 0.5       -- Updates Swift property
Settings.theme = "dark"     -- Updates Swift property
```

## Dynamic Storage Servers

For caching or dynamic data, implement a server with dictionary-backed storage:

```swift
class CacheServer: LuaValueServer {
    let namespace = "Cache"
    private var data: [String: LuaValue] = [:]

    func resolve(path: [String]) -> LuaValue {
        guard !path.isEmpty else { return .nil }
        let key = path.joined(separator: ".")
        return data[key] ?? .nil
    }

    func canWrite(path: [String]) -> Bool {
        return !path.isEmpty
    }

    func write(path: [String], value: LuaValue) throws {
        guard !path.isEmpty else {
            throw LuaError.valueServerWriteError("Cannot write to root")
        }
        let key = path.joined(separator: ".")

        if case .nil = value {
            data.removeValue(forKey: key)
        } else {
            data[key] = value
        }
    }

    // Optional: clear all cached data
    func clear() {
        data.removeAll()
    }
}
```

Usage:
```lua
-- Store computed results
Cache.fibonacci_50 = expensive_calculation(50)

-- Retrieve later
local result = Cache.fibonacci_50

-- Clear a value
Cache.fibonacci_50 = nil
```

## Nested Data Structures

For complex hierarchical data, organize your resolve method to handle depth:

```swift
class GameServer: LuaValueServer {
    let namespace = "Game"

    var player = Player(name: "Hero", health: 100, level: 1)
    var world = World(name: "Forest", difficulty: 2)
    var inventory: [String: Int] = ["gold": 100, "potions": 5]

    func resolve(path: [String]) -> LuaValue {
        guard let root = path.first else { return .nil }
        let subpath = Array(path.dropFirst())

        switch root {
        case "player":
            return resolvePlayer(subpath)
        case "world":
            return resolveWorld(subpath)
        case "inventory":
            return resolveInventory(subpath)
        default:
            return .nil
        }
    }

    private func resolvePlayer(_ path: [String]) -> LuaValue {
        guard let key = path.first, path.count == 1 else {
            return .nil  // Intermediate or invalid
        }
        switch key {
        case "name": return .string(player.name)
        case "health": return .number(Double(player.health))
        case "level": return .number(Double(player.level))
        case "isAlive": return .bool(player.health > 0)
        default: return .nil
        }
    }

    private func resolveWorld(_ path: [String]) -> LuaValue {
        guard let key = path.first, path.count == 1 else {
            return .nil
        }
        switch key {
        case "name": return .string(world.name)
        case "difficulty": return .number(Double(world.difficulty))
        default: return .nil
        }
    }

    private func resolveInventory(_ path: [String]) -> LuaValue {
        if path.isEmpty {
            // Return full inventory for iteration
            return .table(inventory.mapValues { .number(Double($0)) })
        }
        guard let item = path.first, path.count == 1 else {
            return .nil
        }
        return .number(Double(inventory[item] ?? 0))
    }

    func canWrite(path: [String]) -> Bool {
        guard path.count == 2 else { return false }
        switch path[0] {
        case "player":
            return ["health"].contains(path[1])
        case "inventory":
            return true
        default:
            return false
        }
    }

    func write(path: [String], value: LuaValue) throws {
        guard path.count == 2 else {
            throw LuaError.valueServerWriteError("Invalid write path")
        }

        switch (path[0], path[1]) {
        case ("player", "health"):
            guard let num = value.numberValue else {
                throw LuaError.valueServerWriteError("health must be a number")
            }
            player.health = max(0, Int(num))

        case ("inventory", let item):
            guard let num = value.numberValue else {
                throw LuaError.valueServerWriteError("inventory values must be numbers")
            }
            inventory[item] = max(0, Int(num))

        default:
            throw LuaError.readOnlyAccess(path: path.joined(separator: "."))
        }
    }
}
```

Lua usage:
```lua
-- Read nested values
print(Game.player.name)           -- "Hero"
print(Game.player.health)         -- 100
print(Game.world.difficulty)      -- 2

-- Modify allowed values
Game.player.health = Game.player.health - 20

-- Modify inventory
Game.inventory.potions = Game.inventory.potions - 1
Game.inventory.gold = Game.inventory.gold + 50

-- Iterate inventory
for item, count in pairs(Game.inventory) do
    print(item .. ": " .. count)
end
```

## Sharing Servers Between Engines

Value servers can be shared across multiple ``LuaEngine`` instances. Since servers are registered by reference, updates to the server's data are visible to all engines:

```swift
class SharedConfig: LuaValueServer {
    let namespace = "Config"
    var apiEndpoint = "https://api.example.com"

    func resolve(path: [String]) -> LuaValue {
        guard path == ["apiEndpoint"] else { return .nil }
        return .string(apiEndpoint)
    }
}

let config = SharedConfig()

let engine1 = try LuaEngine()
let engine2 = try LuaEngine()

engine1.register(server: config)
engine2.register(server: config)

// Both engines see the same value
try engine1.run("print(Config.apiEndpoint)")  -- https://api.example.com
try engine2.run("print(Config.apiEndpoint)")  -- https://api.example.com

// Update once, visible everywhere
config.apiEndpoint = "https://api-v2.example.com"
try engine1.run("print(Config.apiEndpoint)")  -- https://api-v2.example.com
```

> Warning: When sharing writable servers between engines running on different threads, ensure your server implementation is thread-safe using locks or actors.

## Thread-Safe Server Implementation

For multi-threaded scenarios with writable servers:

```swift
class ThreadSafeCache: LuaValueServer {
    let namespace = "Cache"
    private let lock = NSLock()
    private var data: [String: LuaValue] = [:]

    func resolve(path: [String]) -> LuaValue {
        guard !path.isEmpty else { return .nil }
        let key = path.joined(separator: ".")

        lock.lock()
        defer { lock.unlock() }
        return data[key] ?? .nil
    }

    func canWrite(path: [String]) -> Bool {
        return !path.isEmpty
    }

    func write(path: [String], value: LuaValue) throws {
        guard !path.isEmpty else {
            throw LuaError.valueServerWriteError("Cannot write to root")
        }
        let key = path.joined(separator: ".")

        lock.lock()
        defer { lock.unlock() }
        data[key] = value
    }
}
```

## Best Practices

1. **Return .nil for intermediate paths** - Critical for nested access to work correctly.

2. **Validate write values** - Check types and ranges in `write(path:value:)` before storing.

3. **Use meaningful namespaces** - Choose descriptive names that reflect the server's purpose.

4. **Keep servers focused** - Create multiple small servers rather than one large monolithic server.

5. **Document writable paths** - Make it clear which paths accept writes and what types they expect.

6. **Handle errors gracefully** - Throw descriptive ``LuaError`` values for invalid operations.

7. **Consider thread safety** - Use synchronization if servers are shared across threads.

## See Also

- ``LuaValueServer``
- ``LuaEngine/register(server:)``
- ``LuaValue``
- ``LuaError``
