# Engine Reuse Patterns

`LuaEngine` is designed for reuse - create once, execute many scripts without reinitialization overhead.

## Reusing a Single Engine

Once created, an engine can execute unlimited scripts:

```swift
let engine = try LuaEngine()

// Execute many scripts - no reinitialization needed
try engine.run("x = 10")
try engine.run("y = 20")
let sum = try engine.evaluate("return x + y")
print(sum.numberValue!) // 30.0

// Register functions and servers once, use many times
engine.registerFunction(name: "double") { args in
    guard let n = args.first?.numberValue else { return .nil }
    return .number(n * 2)
}

for i in 1...1000 {
    let result = try engine.evaluate("return double(\(i))")
    // Each call is fast - no engine setup cost
}
```

## State Persistence

Global variables, functions, and tables persist between `run()` and `evaluate()` calls:

```swift
let engine = try LuaEngine()

// First execution: define data
try engine.run("""
    config = {
        maxRetries = 3,
        timeout = 30
    }

    function processItem(item)
        return item * config.maxRetries
    end
""")

// Later executions: use the defined data
let result1 = try engine.evaluate("return config.timeout") // 30
let result2 = try engine.evaluate("return processItem(10)") // 30

// Modify state
try engine.run("config.timeout = 60")
let result3 = try engine.evaluate("return config.timeout") // 60
```

This enables powerful patterns like:
- Loading configuration once, using throughout app lifetime
- Building up state incrementally across multiple script calls
- Caching computed values in Lua for reuse

## Resetting Engine State

`LuaEngine` does not have a built-in reset method. Choose from these approaches:

### Option 1: Create a New Engine (Recommended)

```swift
// When you need a fresh state
let freshEngine = try LuaEngine()
```

### Option 2: Manually Clear Specific Globals

```swift
// Clear known variables
try engine.run("""
    x = nil
    config = nil
    myFunction = nil
""")
```

### Option 3: Track and Clear All User-Defined Globals

```swift
// At start, capture built-in globals
try engine.run("""
    _G._originalGlobals = {}
    for k, v in pairs(_G) do
        _G._originalGlobals[k] = true
    end
""")

// Later, reset to original state
try engine.run("""
    for k, v in pairs(_G) do
        if not _G._originalGlobals[k] then
            _G[k] = nil
        end
    end
""")
```

## Performance Comparison

| Operation | Cost | Notes |
|-----------|------|-------|
| `LuaEngine()` creation | ~1-5ms | Creates Lua state, opens libraries, applies sandbox, registers modules |
| `run()` / `evaluate()` | ~0.01-0.1ms | Just loads and executes code |
| `registerFunction()` | Negligible | One-time setup cost |
| `register(server:)` | Negligible | One-time setup cost |

### Guidelines

- Reuse engines when possible - 10-100x faster than creating new ones
- Create new engines when you need guaranteed clean state
- For request/response patterns, consider engine pools

```swift
// Good: Reuse for repeated operations
let engine = try LuaEngine()
for item in items {
    let result = try engine.evaluate("return process(\(item))")
    // Fast - no engine overhead
}

// Avoid: Creating new engines in loops
for item in items {
    let engine = try LuaEngine() // Slow - full initialization each time
    let result = try engine.evaluate("return process(\(item))")
}
```

## Long-Running Engine Instances

Engines can safely run for the entire app lifetime:

```swift
class ScriptService {
    private let engine: LuaEngine

    init() throws {
        self.engine = try LuaEngine()

        // One-time setup
        ModuleRegistry.installModules(in: engine)
        try engine.run("""
            -- Initialize shared state
            cache = {}
            stats = { calls = 0, errors = 0 }
        """)
    }

    func execute(_ script: String) throws -> LuaValue {
        return try engine.evaluate("""
            stats.calls = stats.calls + 1
            \(script)
        """)
    }

    func getStats() throws -> LuaValue {
        return try engine.evaluate("return stats")
    }
}
```

### Best Practices for Long-Running Engines

1. **Register all modules/functions at initialization** - Not during normal operation
2. **Monitor memory** - Use `configuration.memoryLimit` if running untrusted scripts
3. **Clean up coroutines** - Call `destroy()` on completed coroutines to free resources
4. **Avoid unbounded growth** - Periodically clear caches or large tables if needed

```swift
// Memory-limited long-running engine
let config = LuaEngineConfiguration(
    sandboxed: true,
    packagePath: nil,
    memoryLimit: 50 * 1024 * 1024  // 50 MB limit
)
let engine = try LuaEngine(configuration: config)
```

## Value Server Lifecycle

Registered value servers persist until explicitly unregistered:

```swift
let engine = try LuaEngine()

// Register a server
engine.register(server: myDataServer)

// Server remains accessible across all script executions
try engine.run("local x = MyData.value1")
try engine.run("local y = MyData.value2")

// Unregister when no longer needed
engine.unregister(namespace: "MyData")

// Server is now inaccessible
// try engine.run("return MyData.value1") // Would error
```

## Multiple Engine Instances

Each engine maintains its own isolated Lua state:

```swift
// Create multiple independent engines
let engine1 = try LuaEngine()
let engine2 = try LuaEngine()
let engine3 = try LuaEngine()

// Each engine has its own global state
try engine1.run("x = 100")
try engine2.run("x = 200")
try engine3.run("x = 300")

// Values are independent
try engine1.evaluate("return x").numberValue! // 100
try engine2.evaluate("return x").numberValue! // 200
try engine3.evaluate("return x").numberValue! // 300
```

## Use Cases

### Isolation for Untrusted Code

```swift
// Each user gets their own isolated engine
class UserScriptRunner {
    private var userEngines: [String: LuaEngine] = [:]

    func runUserScript(userId: String, script: String) throws -> LuaValue {
        let engine = try userEngines[userId] ?? {
            let new = try LuaEngine()  // Sandboxed by default
            userEngines[userId] = new
            return new
        }()

        return try engine.evaluate(script)
    }
}
```

### Different Configurations per Context

```swift
// Different module sets for different use cases
let mathEngine = try LuaEngine()
ModuleRegistry.installMathModule(in: mathEngine)
ModuleRegistry.installLinAlgModule(in: mathEngine)

let dataEngine = try LuaEngine()
ModuleRegistry.installJSONModule(in: dataEngine)
ModuleRegistry.installYAMLModule(in: dataEngine)

let fullEngine = try LuaEngine()
ModuleRegistry.installModules(in: fullEngine)  // All modules
```

### Parallel Script Execution

```swift
func processScriptsInParallel(_ scripts: [String]) async throws -> [LuaValue] {
    return try await withThrowingTaskGroup(of: (Int, LuaValue).self) { group in
        for (index, script) in scripts.enumerated() {
            group.addTask {
                let engine = try LuaEngine()  // Each task gets its own engine
                ModuleRegistry.installModules(in: engine)
                let result = try engine.evaluate(script)
                return (index, result)
            }
        }

        var results = Array(repeating: LuaValue.nil, count: scripts.count)
        for try await (index, result) in group {
            results[index] = result
        }
        return results
    }
}
```
