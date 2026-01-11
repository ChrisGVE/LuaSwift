# Value Servers

[← Core API](core-api.md) | [Documentation](index.md) | [Callbacks →](callbacks.md)

---

Value servers expose Swift data to Lua scripts. They act as bridges that allow Lua code to read (and optionally write) values stored in your Swift application.

## Basic Read-Only Server

```swift
class AppServer: LuaValueServer {
    let namespace = "App"

    func resolve(path: [String]) -> LuaValue {
        guard !path.isEmpty else { return .nil }

        switch path[0] {
        case "version":
            return .string("1.0.0")
        case "user":
            guard path.count > 1 else { return .nil }
            return resolveUser(key: path[1])
        default:
            return .nil
        }
    }

    private func resolveUser(key: String) -> LuaValue {
        switch key {
        case "name": return .string("John")
        case "level": return .number(42)
        default: return .nil
        }
    }
}

// Register and use
let server = AppServer()
engine.register(server: server)

let name = try engine.evaluate("return App.user.name")
print(name.stringValue!) // "John"
```

## Writable Server

Enable Lua scripts to write values back to your application:

```swift
class CacheServer: LuaValueServer {
    let namespace = "Cache"
    var storage: [String: LuaValue] = [:]

    func resolve(path: [String]) -> LuaValue {
        guard path.count > 0 else { return .nil }
        let key = path.joined(separator: ".")
        return storage[key] ?? .nil
    }

    func canWrite(path: [String]) -> Bool {
        return true  // All paths are writable
    }

    func write(path: [String], value: LuaValue) throws {
        let key = path.joined(separator: ".")
        storage[key] = value
    }
}

let cache = CacheServer()
engine.register(server: cache)

// Lua can now write values
try engine.run("""
    Cache.result = 42
    Cache.message = "Calculation complete"
    Cache.data = { x = 10, y = 20 }
""")

// Read back in Swift
print(cache.storage["result"]?.numberValue)  // Optional(42.0)
print(cache.storage["message"]?.stringValue) // Optional("Calculation complete")
```

## Selective Write Access

Control which paths are writable:

```swift
class ConfigServer: LuaValueServer {
    let namespace = "Config"
    var settings: [String: LuaValue] = [
        "theme": .string("dark"),
        "fontSize": .number(14)
    ]
    let readOnlyKeys: Set<String> = ["apiKey", "secretToken"]

    func resolve(path: [String]) -> LuaValue {
        guard let key = path.first else { return .table(settings) }
        return settings[key] ?? .nil
    }

    func canWrite(path: [String]) -> Bool {
        guard let key = path.first else { return false }
        return !readOnlyKeys.contains(key)
    }

    func write(path: [String], value: LuaValue) throws {
        guard let key = path.first, canWrite(path: path) else {
            throw LuaError.readOnlyAccess(path.joined(separator: "."))
        }
        settings[key] = value
    }
}
```

## Important Notes

### Returning `.nil` for Intermediate Paths

For write support to work correctly, `resolve()` must return `.nil` for intermediate paths that don't exist yet. This triggers the creation of proxy tables with metamethods:

```swift
func resolve(path: [String]) -> LuaValue {
    // Return .nil for paths that don't exist
    // This allows Lua to write to new paths
    guard path.count > 0 else { return .nil }
    let key = path.joined(separator: ".")
    return storage[key] ?? .nil  // Returns .nil if key doesn't exist
}
```

### Thread Safety

Value server methods are called while holding the engine lock. Keep them fast to avoid blocking:

```swift
class ThreadSafeServer: LuaValueServer {
    let namespace = "Data"
    private let lock = NSLock()
    private var data: [String: LuaValue] = [:]

    func resolve(path: [String]) -> LuaValue {
        lock.lock()
        defer { lock.unlock() }
        return data[path.first ?? ""] ?? .nil
    }
}
```

### Sharing Servers Between Engines

A single server instance can be registered with multiple engines:

```swift
let sharedConfig = ConfigServer()

let engine1 = try LuaEngine()
let engine2 = try LuaEngine()

engine1.register(server: sharedConfig)
engine2.register(server: sharedConfig)

// Changes from one engine visible to the other
try engine1.run("Config.theme = 'light'")
let theme = try engine2.evaluate("return Config.theme")
print(theme.stringValue!) // "light"
```

### Unregistering Servers

```swift
engine.register(server: myServer)
// ... use server ...
engine.unregister(namespace: "MyServer")
// Server is now inaccessible from Lua
```


---

[← Core API](core-api.md) | [Documentation](index.md) | [Callbacks →](callbacks.md)
