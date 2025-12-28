# LuaSwift

A lightweight Swift wrapper for Lua 5.4, designed for embedding Lua scripting in iOS and macOS applications.

## Features

- **Lua 5.4** - Latest stable Lua release
- **Type-Safe** - Swift enums for Lua values
- **Value Servers** - Expose Swift data to Lua via protocol
- **Sandboxing** - Remove dangerous functions for security
- **Thread-Safe** - Safe for concurrent access
- **Minimal API** - Simple interface for common use cases

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

// Execute Lua code
let result = try engine.execute("return 1 + 2")
print(result.numberValue!) // 3.0

// Execute returning a table
let table = try engine.executeForTable("""
    return {
        name = "John",
        age = 30
    }
""")
print(table["name"]?.stringValue) // Optional("John")
```

### Value Servers

Expose your application data to Lua:

```swift
class AppServer: LuaValueServer {
    let namespace = "App"

    func resolve(path: [String]) -> LuaValue {
        guard !path.isEmpty else { return .nil }

        switch path[0] {
        case "version":
            return .string("1.0.0")
        case "settings":
            return resolveSettings(path: Array(path.dropFirst()))
        default:
            return .nil
        }
    }

    private func resolveSettings(path: [String]) -> LuaValue {
        guard let key = path.first else {
            return .table(["theme": "dark", "language": "en"])
        }
        switch key {
        case "theme": return .string("dark")
        case "language": return .string("en")
        default: return .nil
        }
    }
}

// Register server
let server = AppServer()
engine.register(server: server)

// Access from Lua
let theme = try engine.execute("return App.settings.theme")
print(theme.stringValue!) // "dark"
```

### Problem Generation Example

```swift
let problem = try engine.executeForTable("""
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

print(problem["question"]?.stringValue)  // "What is 7 + 3?"
print(problem["answer"]?.numberValue)    // 10.0
```

### Reproducible Testing

```swift
// Set fixed seed for reproducible results
try engine.seed(12345)

// All math.random() calls will produce the same sequence
let result1 = try engine.execute("return math.random(1, 100)")
let result2 = try engine.execute("return math.random(1, 100)")
// Always the same values for seed 12345
```

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

## LuaValue Type

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

### Convenience Accessors

```swift
let value: LuaValue = .number(42)

value.numberValue   // Optional(42.0)
value.intValue      // Optional(42)
value.stringValue   // nil
value.asString      // "42" (always succeeds)
value.isTruthy      // true
```

### Literals

```swift
let str: LuaValue = "hello"
let num: LuaValue = 42
let bool: LuaValue = true
let arr: LuaValue = [1, 2, 3]
let dict: LuaValue = ["key": "value"]
```

## Error Handling

```swift
do {
    let result = try engine.execute("invalid lua code here")
} catch let error as LuaError {
    switch error {
    case .syntaxError(let message):
        print("Syntax error: \(message)")
    case .runtimeError(let message):
        print("Runtime error: \(message)")
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

## Thread Safety

`LuaEngine` is thread-safe for all public methods. However, for best performance with concurrent access, consider using a pool of engines or serializing access.

## License

MIT License. See [LICENSE](LICENSE) for details.

Lua is also MIT licensed. See https://www.lua.org/license.html

## Acknowledgments

- [Lua](https://www.lua.org/) - The Lua programming language
- Inspired by various Lua-Swift bridges in the community
