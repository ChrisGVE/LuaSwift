# Swift Callbacks

[← Value Servers](value-servers.md) | [Documentation](index.md) | [Coroutines →](coroutines.md)

---

Register Swift functions that Lua scripts can call directly.

## Basic Callbacks

```swift
// Simple callback
engine.registerFunction(name: "greet") { args in
    let name = args.first?.stringValue ?? "World"
    return .string("Hello, \(name)!")
}

// Use from Lua
let result = try engine.evaluate("return greet('Swift')")
print(result.stringValue!) // "Hello, Swift!"
```

## Multiple Arguments

```swift
engine.registerFunction(name: "add") { args in
    let a = args[0].numberValue ?? 0
    let b = args[1].numberValue ?? 0
    return .number(a + b)
}

try engine.run("print(add(10, 32))")  // Prints: 42.0
```

## Returning Tables

```swift
engine.registerFunction(name: "getUser") { args in
    return .table([
        "name": .string("John"),
        "age": .number(30),
        "active": .bool(true)
    ])
}

try engine.run("""
    local user = getUser()
    print(user.name)   -- John
    print(user.age)    -- 30
""")
```

## Returning Arrays

```swift
engine.registerFunction(name: "getNumbers") { args in
    return .array([.number(1), .number(2), .number(3)])
}

try engine.run("""
    local nums = getNumbers()
    for i, n in ipairs(nums) do
        print(i, n)  -- 1 1, 2 2, 3 3
    end
""")
```

## Error Handling

Callbacks can throw errors that propagate to Lua:

```swift
enum CustomError: Error {
    case invalidInput(String)
}

engine.registerFunction(name: "validate") { args in
    guard let value = args.first?.stringValue, !value.isEmpty else {
        throw CustomError.invalidInput("Value cannot be empty")
    }
    return .bool(true)
}

// In Lua, wrap in pcall to handle errors
try engine.run("""
    local ok, err = pcall(function()
        validate("")
    end)
    if not ok then
        print("Error:", err)
    end
""")
```

## Unregistering Callbacks

```swift
engine.registerFunction(name: "temporary") { _ in .nil }
// ... use function ...
engine.unregisterFunction(name: "temporary")
// Function is now unavailable in Lua
```

## Thread Safety

Callbacks execute on the thread that called `run()` or `evaluate()`. The engine lock is held during callback execution:

```swift
engine.registerFunction(name: "threadInfo") { _ in
    let threadName = Thread.current.name ?? "unknown"
    return .string(threadName)
}

// On main thread
try engine.evaluate("return threadInfo()")  // Returns main thread name

// On background thread
DispatchQueue.global().async {
    try? engine.evaluate("return threadInfo()")  // Returns worker thread name
}
```

## Accessing Engine from Callbacks

Callbacks receive arguments but not the engine directly. If you need engine access, capture it:

```swift
let engine = try LuaEngine()

engine.registerFunction(name: "runScript") { [weak engine] args in
    guard let engine = engine,
          let code = args.first?.stringValue else {
        return .nil
    }
    // Note: Be careful with recursion and deadlocks
    return (try? engine.evaluate(code)) ?? .nil
}
```

## Patterns

### Factory Pattern

```swift
var counter = 0
engine.registerFunction(name: "createId") { _ in
    counter += 1
    return .string("id-\(counter)")
}
```

### Delegation Pattern

```swift
protocol ScriptDelegate: AnyObject {
    func onEvent(name: String, data: [String: LuaValue])
}

class ScriptRunner {
    weak var delegate: ScriptDelegate?
    let engine: LuaEngine

    init() throws {
        engine = try LuaEngine()
        engine.registerFunction(name: "emit") { [weak self] args in
            guard let name = args.first?.stringValue else { return .nil }
            let data = args.dropFirst().first?.tableValue ?? [:]
            self?.delegate?.onEvent(name: name, data: data)
            return .nil
        }
    }
}
```

### Async Operations

For long-running operations, consider using coroutines instead:

```swift
// Don't block the callback
engine.registerFunction(name: "fetchData") { args in
    // This blocks the Lua state - avoid for long operations
    let data = someSyncOperation()
    return .string(data)
}

// Better: use coroutines for async patterns
// See coroutines.md for details
```


---

[← Value Servers](value-servers.md) | [Documentation](index.md) | [Coroutines →](coroutines.md)
