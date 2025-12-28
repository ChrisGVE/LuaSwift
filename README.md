# LuaSwift

A lightweight Swift wrapper for Lua 5.4, designed for embedding Lua scripting in iOS and macOS applications.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015%2B%20%7C%20macOS%2012%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Lua 5.4.7 Bundled** - Complete Lua source included, no external dependencies
- **Type-Safe** - Swift enums for Lua values with convenient accessors
- **Value Servers** - Expose Swift data to Lua with read/write support
- **Sandboxing** - Remove dangerous functions for security
- **Thread-Safe** - Safe for concurrent access
- **Minimal API** - Two methods: `run()` and `evaluate()`

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/chrisgve/LuaSwift.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → Enter the repository URL.

## Quick Start

### Basic Execution

```swift
import LuaSwift

// Create engine (sandboxed by default)
let engine = try LuaEngine()

// Evaluate Lua code and get result
let result = try engine.evaluate("return 1 + 2")
print(result.numberValue!) // 3.0

// Run Lua code without needing a result
try engine.run("print('Hello from Lua!')")

// Evaluate returning a table
let user = try engine.evaluate("""
    return {
        name = "John",
        age = 30
    }
""")
print(user.tableValue?["name"]?.stringValue) // Optional("John")
```

### Value Servers (Read-Only)

Expose your application data to Lua:

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

// Register server
let server = AppServer()
engine.register(server: server)

// Access from Lua
let name = try engine.evaluate("return App.user.name")
print(name.stringValue!) // "John"
```

### Value Servers (Read/Write)

Enable Lua scripts to write back to your application:

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

### Problem Generation Example

```swift
// Seed for reproducible results
try engine.seed(42)

let problem = try engine.evaluate("""
    local a = math.random(1, 10)
    local b = math.random(1, 10)

    return {
        question = string.format("What is %d + %d?", a, b),
        answer = a + b,
        hints = {
            "Think about counting",
            "Use your fingers"
        }
    }
""")

print(problem.tableValue?["question"]?.stringValue)  // "What is 7 + 3?"
print(problem.tableValue?["answer"]?.numberValue)    // 10.0
```

## API Reference

### LuaEngine

```swift
// Create engine
let engine = try LuaEngine()                           // Sandboxed
let engine = try LuaEngine(configuration: .default)    // Sandboxed
let engine = try LuaEngine(configuration: .unrestricted)

// Execute Lua code
try engine.run("print('no return value')")             // Discard result
let value = try engine.evaluate("return 42")           // Return LuaValue

// Random seeding
try engine.seed(12345)                                 // Reproducible math.random()

// Value servers
engine.register(server: myServer)
engine.unregister(namespace: "MyServer")
```

### LuaValue

The `LuaValue` enum represents all Lua types:

```swift
public enum LuaValue {
    case string(String)
    case number(Double)
    case bool(Bool)
    case table([String: LuaValue])
    case array([LuaValue])
    case `nil`
}
```

#### Convenience Accessors

```swift
let value: LuaValue = .number(42)

value.numberValue   // Optional(42.0)
value.intValue      // Optional(42)
value.stringValue   // nil
value.boolValue     // nil
value.tableValue    // nil
value.arrayValue    // nil
value.asString      // "42" (always succeeds)
value.isTruthy      // true
value.isNil         // false
```

#### Literals

```swift
let str: LuaValue = "hello"
let num: LuaValue = 42
let float: LuaValue = 3.14
let bool: LuaValue = true
let arr: LuaValue = [1, 2, 3]
let dict: LuaValue = ["key": "value"]
```

### LuaValueServer Protocol

```swift
protocol LuaValueServer: AnyObject {
    var namespace: String { get }
    func resolve(path: [String]) -> LuaValue
    func canWrite(path: [String]) -> Bool      // Default: false
    func write(path: [String], value: LuaValue) throws  // Default: throws
}
```

**Important**: For write support to work, `resolve()` must return `.nil` for intermediate paths. This creates proxy tables with metamethods that intercept writes.

## Configuration

### Default (Sandboxed)

```swift
let engine = try LuaEngine() // Sandboxed by default
```

Removes: `os.execute`, `os.exit`, `io.*`, `debug.*`, `loadfile`, `dofile`, `load`

### Custom Configuration

```swift
let config = LuaEngineConfiguration(
    sandboxed: true,
    packagePath: "/path/to/lua/modules",
    memoryLimit: 10_000_000  // 10MB (0 = unlimited)
)
let engine = try LuaEngine(configuration: config)
```

### Unrestricted (Use with Caution)

```swift
let engine = try LuaEngine(configuration: .unrestricted)
```

## Error Handling

```swift
do {
    try engine.run("Cache.readOnly = 'value'")
} catch let error as LuaError {
    switch error {
    case .syntaxError(let message):
        print("Syntax error: \(message)")
    case .runtimeError(let message):
        print("Runtime error: \(message)")
    case .readOnlyAccess(let path):
        print("Cannot write to: \(path)")
    case .typeError(let expected, let actual):
        print("Expected \(expected), got \(actual)")
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

## Thread Safety

`LuaEngine` is thread-safe for all public methods. However, for best performance with concurrent access, consider using a pool of engines or serializing access.

## App Store Compliance

LuaSwift is designed to be App Store compliant:

- **Bundled interpreter**: Lua source is compiled into your app (no downloading code)
- **Sandboxing**: Dangerous functions (`os.execute`, `io.*`, `debug.*`) are disabled by default
- **No JIT**: Uses standard Lua interpreter, not LuaJIT
- Scripts cannot escape sandbox or modify other apps

Per Apple's [App Store Review Guidelines 2.5.2](https://developer.apple.com/app-store/review/guidelines/#software-requirements), apps may include interpreters as long as they don't download code, don't let users distribute apps, and have no escape mechanisms.

## License

MIT License. See [LICENSE](LICENSE) for details.

Lua is also MIT licensed. See https://www.lua.org/license.html

## Acknowledgments

- [Lua](https://www.lua.org/) - The Lua programming language
- Inspired by various Lua-Swift bridges in the community
