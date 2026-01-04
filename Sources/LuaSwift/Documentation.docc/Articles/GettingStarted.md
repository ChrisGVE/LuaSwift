# Getting Started with LuaSwift

Learn how to integrate LuaSwift into your iOS or macOS project and run your first Lua scripts.

## Overview

LuaSwift lets you embed the Lua scripting language in your Swift applications. This guide walks you through installation, basic usage, and common patterns.

## Installation

### Swift Package Manager

Add LuaSwift to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/ChrisGVE/LuaSwift.git", from: "1.3.0")
]
```

Then add `LuaSwift` to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["LuaSwift"]
)
```

### Xcode Integration

1. Go to File > Add Packages...
2. Enter the repository URL: `https://github.com/ChrisGVE/LuaSwift.git`
3. Select your version requirements
4. Click Add Package

## Creating Your First Engine

The ``LuaEngine`` class is your main interface to Lua:

```swift
import LuaSwift

// Create an engine with default (sandboxed) configuration
let engine = try LuaEngine()

// Run Lua code (ignores return value)
try engine.run("x = 10 + 20")

// Evaluate Lua code and get the result
let result = try engine.evaluate("return x * 2")
print(result.numberValue!) // 60
```

## Working with Values

Lua values are represented by the ``LuaValue`` enum:

```swift
// Numbers
let num: LuaValue = .number(42)
print(num.numberValue!) // 42

// Strings
let str: LuaValue = .string("hello")
print(str.stringValue!) // "hello"

// Booleans
let flag: LuaValue = .bool(true)
print(flag.boolValue!) // true

// Tables (dictionaries)
let table: LuaValue = .table(["name": .string("Alice"), "age": .number(30)])
if let name = table.tableValue?["name"]?.stringValue {
    print(name) // "Alice"
}

// Arrays
let arr: LuaValue = .array([.number(1), .number(2), .number(3)])
if let nums = arr.arrayValue {
    print(nums.count) // 3
}
```

## Registering Swift Functions

Make Swift functions callable from Lua:

```swift
// Register a function
engine.registerFunction(name: "multiply") { args in
    guard let a = args[safe: 0]?.numberValue,
          let b = args[safe: 1]?.numberValue else {
        throw LuaError.callbackError("multiply requires two numbers")
    }
    return .number(a * b)
}

// Call it from Lua
let result = try engine.evaluate("return multiply(6, 7)")
print(result.numberValue!) // 42
```

## Using Value Servers

Expose Swift data to Lua with ``LuaValueServer``:

```swift
class GameState: LuaValueServer {
    var name = "Player"
    var playerHealth = 100
    var playerScore = 0

    func resolve(path: [String]) -> LuaValue {
        switch path.first {
        case "health": return .number(Double(playerHealth))
        case "score": return .number(Double(playerScore))
        default: return .nil
        }
    }

    func canWrite(path: [String]) -> Bool {
        return ["health", "score"].contains(path.first ?? "")
    }

    func write(path: [String], value: LuaValue) throws {
        switch path.first {
        case "health":
            playerHealth = Int(value.numberValue ?? 0)
        case "score":
            playerScore = Int(value.numberValue ?? 0)
        default:
            throw LuaError.valueServerWriteError("Unknown path")
        }
    }
}

let state = GameState()
engine.register(server: state, name: "game")

try engine.run("""
    game.score = game.score + 100
    print("Score: " .. game.score)  -- Score: 100
""")
```

## Using Built-in Modules

LuaSwift includes many Swift-backed modules:

```swift
// Install all modules at once
ModuleRegistry.installModules(in: engine)

// Or install specific modules
ModuleRegistry.installJSONModule(in: engine)
ModuleRegistry.installGeometryModule(in: engine)
```

### JSON Example

```lua
local json = require("luaswift.json")

local data = {name = "Alice", scores = {100, 95, 88}}
local encoded = json.encode(data)
print(encoded)  -- {"name":"Alice","scores":[100,95,88]}

local decoded = json.decode('{"x": 1, "y": 2}')
print(decoded.x)  -- 1
```

### Geometry Example

```lua
local geo = luaswift.geometry

local v1 = geo.vec2(3, 4)
print(v1:length())  -- 5

local v2 = geo.vec3(1, 0, 0)
local v3 = geo.vec3(0, 1, 0)
print(v2:cross(v3))  -- vec3(0, 0, 1)

local q = geo.quaternion.from_axis_angle(geo.vec3(0, 1, 0), math.pi / 2)
local rotated = q:rotate(geo.vec3(1, 0, 0))
```

### Math Expression Example

```lua
local mathexpr = require("luaswift.mathexpr")

-- Evaluate expressions
local result = mathexpr.eval("sin(x)^2 + cos(x)^2", {x = 1.5})
print(result)  -- 1.0

-- Compile for reuse
local f = mathexpr.compile("x^2 - 2*x + 1")
print(f(0))  -- 1
print(f(1))  -- 0
print(f(2))  -- 1
```

## Selecting Lua Version

LuaSwift supports multiple Lua versions. Set the `LUASWIFT_LUA_VERSION` environment variable:

```bash
# Build with Lua 5.1
LUASWIFT_LUA_VERSION=51 swift build

# Build with Lua 5.3
LUASWIFT_LUA_VERSION=53 swift build

# Default is Lua 5.4
swift build
```

## Thread Safety

``LuaEngine`` is thread-safe for individual method calls. For high-concurrency scenarios, use a pool of engines rather than sharing a single instance:

```swift
actor LuaEnginePool {
    private var engines: [LuaEngine] = []

    func withEngine<T>(_ work: (LuaEngine) throws -> T) async throws -> T {
        let engine = engines.isEmpty ? try LuaEngine() : engines.removeLast()
        defer { engines.append(engine) }
        return try work(engine)
    }
}
```

## Next Steps

- Explore the ``LuaEngine`` API reference
- Learn about ``LuaValue`` type conversions
- Check out the built-in modules via ``ModuleRegistry``
