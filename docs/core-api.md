# Core API Reference

## LuaEngine

The main interface for executing Lua code from Swift.

### Creating an Engine

```swift
// Create engine with default configuration (sandboxed)
let engine = try LuaEngine()

// Create with explicit configuration
let engine = try LuaEngine(configuration: .default)    // Sandboxed
let engine = try LuaEngine(configuration: .unrestricted) // Full access

// Custom configuration
let config = LuaEngineConfiguration(
    sandboxed: true,
    packagePath: "/path/to/lua/modules",
    memoryLimit: 10_000_000
)
let engine = try LuaEngine(configuration: config)
```

### Executing Lua Code

```swift
// Run code, discard result
try engine.run("print('Hello from Lua!')")

// Evaluate and return result
let value = try engine.evaluate("return 42")
print(value.numberValue!) // 42.0

// Seed random number generator
try engine.seed(12345) // Reproducible math.random()
```

### Registering Swift Resources

```swift
// Value servers (expose Swift data)
engine.register(server: myServer)
engine.unregister(namespace: "MyServer")

// Swift callbacks
engine.registerFunction(name: "myFunc") { args in
    return .nil
}
engine.unregisterFunction(name: "myFunc")
```

### Coroutine Management

```swift
let handle = try engine.createCoroutine(code: "...")
let result = try engine.resume(handle)
let result = try engine.resume(handle, with: [.number(42)])
let status = engine.coroutineStatus(handle)
engine.destroy(handle)
```

## LuaEngineConfiguration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `sandboxed` | `Bool` | `true` | Remove dangerous functions for security |
| `packagePath` | `String?` | `nil` | Custom path for `require()` to find Lua modules |
| `memoryLimit` | `Int` | `0` | Memory limit in bytes (`0` = unlimited) |

### Sandboxing

When sandboxed, these functions are removed:
- `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv`, `os.setlocale`
- `io.*` (entire library)
- `debug.*` (entire library)
- `loadfile`, `dofile`, `load`, `loadstring`

Safe libraries remain: `math`, `string`, `table`, `coroutine`, `utf8`

## LuaValue

Type-safe enum representing Lua values.

### Variants

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

### Accessors

```swift
let value: LuaValue = .number(42)

// Type-specific (return nil if wrong type)
value.numberValue   // Optional(42.0)
value.intValue      // Optional(42)
value.stringValue   // nil
value.boolValue     // nil
value.tableValue    // nil
value.arrayValue    // nil

// Always available
value.asString      // "42" - string representation
value.isTruthy      // true - Lua truthiness (only nil and false are falsy)
value.isNil         // false
```

### Literals

```swift
let str: LuaValue = "hello"
let num: LuaValue = 42
let float: LuaValue = 3.14
let bool: LuaValue = true
let arr: LuaValue = [1, 2, 3]
let dict: LuaValue = ["key": "value"]
```

## LuaValueServer Protocol

```swift
protocol LuaValueServer: AnyObject {
    var namespace: String { get }
    func resolve(path: [String]) -> LuaValue
    func canWrite(path: [String]) -> Bool      // Default: false
    func write(path: [String], value: LuaValue) throws  // Default: throws
}
```

See [Value Servers](value-servers.md) for detailed usage.

## CoroutineResult

```swift
public enum CoroutineResult {
    case yielded([LuaValue])    // Coroutine yielded values
    case completed(LuaValue)    // Coroutine finished
    case error(LuaError)        // Error occurred
}
```

## CoroutineStatus

```swift
public enum CoroutineStatus {
    case suspended  // Waiting to be resumed
    case running    // Currently executing
    case dead       // Finished or errored
    case normal     // Resumed another coroutine
}
```

## Error Handling

```swift
do {
    try engine.run("invalid lua code here")
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
