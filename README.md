# LuaSwift

A lightweight Swift wrapper for Lua 5.4, designed for embedding Lua scripting in iOS and macOS applications.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FLuaSwift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ChrisGVE/LuaSwift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FLuaSwift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ChrisGVE/LuaSwift)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Lua 5.4.7 Bundled** - Complete Lua source included, no external dependencies
- **Type-Safe** - Swift enums for Lua values with convenient accessors
- **Value Servers** - Expose Swift data to Lua with read/write support
- **Swift Callbacks** - Register Swift functions callable from Lua
- **Coroutines** - Create, resume, and manage Lua coroutines from Swift
- **Sandboxing** - Remove dangerous functions for security
- **Thread-Safe** - Safe for concurrent access
- **Bundled Lua Modules** - SVG generation, math expressions

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ChrisGVE/LuaSwift.git", from: "1.0.0")
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

### Swift Callbacks

Register Swift functions that Lua can call:

```swift
// Register a simple callback
engine.registerFunction(name: "greet") { args in
    let name = args.first?.stringValue ?? "World"
    return .string("Hello, \(name)!")
}

// Use from Lua
let result = try engine.evaluate("return greet('Swift')")
print(result.stringValue!) // "Hello, Swift!"

// Callback with multiple arguments
engine.registerFunction(name: "add") { args in
    let a = args[0].numberValue ?? 0
    let b = args[1].numberValue ?? 0
    return .number(a + b)
}

try engine.run("print(add(10, 32))")  // Prints: 42.0

// Unregister when done
engine.unregisterFunction(name: "greet")
```

### Coroutines

Create and manage Lua coroutines from Swift:

```swift
// Create a coroutine
let handle = try engine.createCoroutine(code: """
    local x = coroutine.yield(1)
    local y = coroutine.yield(x + 1)
    return y * 2
""")

// First resume - yields 1
let r1 = try engine.resume(handle)
if case .yielded(let values) = r1 {
    print(values[0].numberValue!) // 1.0
}

// Second resume - pass 10, yields 11
let r2 = try engine.resume(handle, with: [.number(10)])
if case .yielded(let values) = r2 {
    print(values[0].numberValue!) // 11.0
}

// Third resume - pass 5, returns 10
let r3 = try engine.resume(handle, with: [.number(5)])
if case .completed(let value) = r3 {
    print(value.numberValue!) // 10.0
}

// Clean up
engine.destroy(handle)

// Check status before resume
let status = engine.coroutineStatus(handle) // .dead after completion
```

### Bundled Lua Modules

LuaSwift includes pure Lua modules for common tasks. To use them, you need to configure the package path to point to where the modules are located.

#### Setting Up the Package Path

```swift
// Option 1: Configure via LuaEngineConfiguration
let modulesPath = "/path/to/LuaModules"
let config = LuaEngineConfiguration(
    sandboxed: true,
    packagePath: modulesPath,
    memoryLimit: 0
)
let engine = try LuaEngine(configuration: config)

// Option 2: Set package.path directly in Lua
try engine.run("""
    package.path = '/path/to/LuaModules/?.lua;' .. package.path
""")

// Option 3: Access bundled resources (in an app using LuaSwift)
if let modulesURL = Bundle.module.url(forResource: "LuaModules", withExtension: nil) {
    let config = LuaEngineConfiguration(
        sandboxed: true,
        packagePath: modulesURL.path,
        memoryLimit: 0
    )
    let engine = try LuaEngine(configuration: config)
}
```

#### SVG Generation

```swift
let result = try engine.evaluate("""
    local svg = require("svg")
    local drawing = svg.create(800, 600)

    -- Basic shapes
    drawing:rect(10, 10, 100, 50, {fill = "blue"})
    drawing:circle(200, 200, 50, {stroke = "red", fill = "none"})
    drawing:text("Hello SVG!", 100, 100, {font_size = 20})

    -- Greek letters supported
    drawing:text(svg.greek.theta .. " = 45°", 150, 150)

    -- Chart helpers
    local points = {{x=0,y=0}, {x=100,y=50}, {x=200,y=25}}
    drawing:linePlot(points, {stroke = "green"})

    return drawing:render()
""")
```

#### Math Expressions

```swift
let result = try engine.evaluate("""
    local math_expr = require("math_expr")

    -- Basic evaluation
    local r1 = math_expr.eval("2 + 3 * 4")  -- 14

    -- With variables
    local r2 = math_expr.eval("x^2 + 2*x", {x = 3})  -- 15

    -- Functions
    local r3 = math_expr.eval("sin(pi/2)")  -- 1.0

    -- Step-by-step solving
    local steps = math_expr.solve("(2 + 3) * 4", {show_steps = true})
    -- Returns table of intermediate steps

    return r1
""")
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

// Swift callbacks
engine.registerFunction(name: "myFunc") { args in return .nil }
engine.unregisterFunction(name: "myFunc")

// Coroutines
let handle = try engine.createCoroutine(code: "...")
let result = try engine.resume(handle)                 // with: defaults to []
let result = try engine.resume(handle, with: [.number(42)])
let status = engine.coroutineStatus(handle)            // CoroutineStatus
engine.destroy(handle)
```

### CoroutineResult

```swift
public enum CoroutineResult {
    case yielded([LuaValue])    // Coroutine yielded values
    case completed(LuaValue)    // Coroutine finished
    case error(LuaError)        // Error occurred
}
```

### CoroutineStatus

```swift
public enum CoroutineStatus {
    case suspended  // Waiting to be resumed
    case running    // Currently executing
    case dead       // Finished or errored
    case normal     // Resumed another coroutine
}
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

value.numberValue   // Optional(42.0) - nil if not a number
value.intValue      // Optional(42) - nil if not a number
value.stringValue   // nil - nil if not a string
value.boolValue     // nil - nil if not a bool
value.tableValue    // nil - nil if not a table
value.arrayValue    // nil - nil if not an array
value.asString      // "42" - always returns a String (never nil)
value.isTruthy      // true - Lua truthiness: only nil and false are falsy
value.isNil         // false - true only for .nil case
```

**Note on `isTruthy`**: Follows Lua semantics where only `nil` and `false` are falsy. Numbers (including `0`), strings (including `""`), tables, and arrays are all truthy.

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
    func canWrite(path: [String]) -> Bool      // Default: returns false (read-only)
    func write(path: [String], value: LuaValue) throws  // Default: throws readOnlyAccess
}
```

**Default Behavior**:
- `canWrite(path:)` returns `false` - all paths are read-only unless overridden
- `write(path:value:)` throws `LuaError.readOnlyAccess` - must override for write support

**Important**: For write support to work, `resolve()` must return `.nil` for intermediate paths. This creates proxy tables with metamethods that intercept writes.

## Configuration

### LuaEngineConfiguration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `sandboxed` | `Bool` | `true` | Remove dangerous functions for security |
| `packagePath` | `String?` | `nil` | Custom path for `require()` to find Lua modules |
| `memoryLimit` | `Int` | `0` | Memory limit in bytes (`0` = unlimited) |

### Default (Sandboxed)

```swift
let engine = try LuaEngine() // Uses .default configuration
// Equivalent to:
let engine = try LuaEngine(configuration: .default)
// Which is:
// LuaEngineConfiguration(sandboxed: true, packagePath: nil, memoryLimit: 0)
```

**Sandboxing removes**: `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv`, `os.setlocale`, `io.*`, `debug.*`, `loadfile`, `dofile`, `load`, `loadstring`

**Safe libraries remain**: `math`, `string`, `table`, `coroutine`, `utf8`

### Custom Configuration

```swift
let config = LuaEngineConfiguration(
    sandboxed: true,                          // Default: true
    packagePath: "/path/to/lua/modules",      // Default: nil
    memoryLimit: 10_000_000                   // Default: 0 (unlimited)
)
let engine = try LuaEngine(configuration: config)
```

### Unrestricted (Use with Caution)

```swift
let engine = try LuaEngine(configuration: .unrestricted)
// Which is:
// LuaEngineConfiguration(sandboxed: false, packagePath: nil, memoryLimit: 0)
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
