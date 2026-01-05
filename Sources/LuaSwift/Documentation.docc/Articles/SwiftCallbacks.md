# Registering Swift Callbacks

Make Swift functions callable from Lua scripts to extend functionality and integrate with your application.

## Overview

Swift callbacks allow you to expose native functionality to Lua scripts. When you register a callback, it becomes available as a global Lua function that can be called just like any built-in Lua function.

Callbacks receive Lua values as ``LuaValue`` arrays and return a ``LuaValue`` result. They can also throw errors that propagate back to the Lua runtime.

## Basic Registration

Register a callback using ``LuaEngine/registerFunction(name:callback:)``:

```swift
let engine = try LuaEngine()

engine.registerFunction(name: "add") { args in
    guard args.count == 2,
          let a = args[0].numberValue,
          let b = args[1].numberValue else {
        return .nil
    }
    return .number(a + b)
}

let result = try engine.evaluate("return add(5, 3)")
print(result.numberValue!) // 8.0
```

The callback receives an array of `LuaValue` containing all arguments passed from Lua. Return a `LuaValue` to send a result back to Lua.

## Handling Arguments

### Accessing Arguments by Index

Arguments are passed as an array. Use safe indexing and optional binding:

```swift
engine.registerFunction(name: "greet") { args in
    // Use safe indexing
    guard let name = args.first?.stringValue else {
        return .string("Hello, stranger!")
    }
    return .string("Hello, \(name)!")
}
```

### Multiple Arguments

Access multiple arguments by index:

```swift
engine.registerFunction(name: "createPoint") { args in
    guard args.count >= 2,
          let x = args[0].numberValue,
          let y = args[1].numberValue else {
        return .nil
    }
    return .table(["x": .number(x), "y": .number(y)])
}
```

### Variable Arguments

Handle any number of arguments:

```swift
engine.registerFunction(name: "concat") { args in
    let strings = args.compactMap { $0.stringValue }
    return .string(strings.joined(separator: " "))
}

// Lua: concat("Hello", "from", "Swift") -> "Hello from Swift"
```

### No Arguments

Some callbacks don't need arguments:

```swift
var counter = 0
engine.registerFunction(name: "getNext") { _ in
    counter += 1
    return .number(Double(counter))
}
```

## Return Values

### Basic Types

Return any ``LuaValue`` type:

```swift
// Number
engine.registerFunction(name: "pi") { _ in
    return .number(Double.pi)
}

// String
engine.registerFunction(name: "version") { _ in
    return .string("1.0.0")
}

// Boolean
engine.registerFunction(name: "isDebug") { _ in
    return .bool(false)
}

// Nil
engine.registerFunction(name: "nothing") { _ in
    return .nil
}
```

### Tables and Arrays

Return complex data structures:

```swift
// Return a table (dictionary)
engine.registerFunction(name: "getConfig") { _ in
    return .table([
        "name": .string("MyApp"),
        "version": .string("1.0.0"),
        "debugEnabled": .bool(false)
    ])
}

// Return an array
engine.registerFunction(name: "getNumbers") { _ in
    return .array([.number(1), .number(2), .number(3)])
}
```

Lua receives these as native tables:

```lua
local config = getConfig()
print(config.name)        -- "MyApp"
print(config.version)     -- "1.0.0"

local nums = getNumbers()
print(nums[1])            -- 1
print(#nums)              -- 3
```

### Using Swift Literals

`LuaValue` conforms to several literal protocols for convenience:

```swift
engine.registerFunction(name: "example") { _ in
    // ExpressibleByStringLiteral
    return "Hello"  // Automatically becomes .string("Hello")
}

engine.registerFunction(name: "answer") { _ in
    // ExpressibleByIntegerLiteral
    return 42  // Automatically becomes .number(42)
}

engine.registerFunction(name: "check") { _ in
    // ExpressibleByBooleanLiteral
    return true  // Automatically becomes .bool(true)
}
```

## Error Handling

### Throwing LuaError

Use ``LuaError/callbackError(_:)`` for callback-specific errors:

```swift
engine.registerFunction(name: "divide") { args in
    guard args.count == 2,
          let a = args[0].numberValue,
          let b = args[1].numberValue else {
        throw LuaError.callbackError("divide requires two numbers")
    }

    guard b != 0 else {
        throw LuaError.callbackError("Division by zero")
    }

    return .number(a / b)
}
```

Errors propagate to Lua as runtime errors:

```lua
-- This works
local result = divide(10, 2)  -- 5

-- This throws an error
local bad = divide(10, 0)  -- Error: Division by zero
```

### Custom Error Types

Any Swift `Error` can be thrown and will be wrapped:

```swift
enum ValidationError: Error {
    case invalidInput(String)
}

engine.registerFunction(name: "validate") { args in
    guard let input = args.first?.stringValue else {
        throw ValidationError.invalidInput("Expected string")
    }
    // ... validation logic
    return true
}
```

### Error Recovery in Lua

Lua can catch errors using `pcall`:

```lua
local success, result = pcall(function()
    return divide(10, 0)
end)

if not success then
    print("Error: " .. result)
else
    print("Result: " .. result)
end
```

## Receiving Complex Data from Lua

### Tables (Dictionaries)

Access table values passed from Lua:

```swift
engine.registerFunction(name: "processConfig") { args in
    guard let config = args.first?.tableValue else {
        throw LuaError.callbackError("Expected table argument")
    }

    let name = config["name"]?.stringValue ?? "unknown"
    let timeout = config["timeout"]?.numberValue ?? 30.0

    // Process configuration...
    return .bool(true)
}
```

```lua
processConfig({
    name = "MyService",
    timeout = 60
})
```

### Arrays

Process arrays from Lua:

```swift
engine.registerFunction(name: "sum") { args in
    guard let array = args.first?.arrayValue else {
        return 0
    }

    let total = array.compactMap { $0.numberValue }.reduce(0, +)
    return .number(total)
}
```

```lua
local total = sum({1, 2, 3, 4, 5})  -- 15
```

### Nested Structures

Handle deeply nested data:

```swift
engine.registerFunction(name: "processOrder") { args in
    guard let order = args.first?.tableValue,
          let items = order["items"]?.arrayValue else {
        throw LuaError.callbackError("Invalid order format")
    }

    var total = 0.0
    for item in items {
        if let itemTable = item.tableValue,
           let price = itemTable["price"]?.numberValue,
           let quantity = itemTable["qty"]?.numberValue {
            total += price * quantity
        }
    }

    return .number(total)
}
```

```lua
local total = processOrder({
    customer = "Alice",
    items = {
        {name = "Widget", price = 9.99, qty = 2},
        {name = "Gadget", price = 24.99, qty = 1}
    }
})
-- total = 44.97
```

## Unregistering Callbacks

Remove a callback when it's no longer needed:

```swift
engine.registerFunction(name: "temporary") { _ in
    return "available"
}

// Use the function...
try engine.evaluate("print(temporary())")

// Remove it
engine.unregisterFunction(name: "temporary")

// Now calling it throws an error
try engine.evaluate("print(temporary())")  // Error: attempt to call nil
```

## Stateful Callbacks

Callbacks capture their environment, enabling stateful behavior:

```swift
class Counter {
    private var count = 0

    func register(in engine: LuaEngine) {
        engine.registerFunction(name: "increment") { [weak self] _ in
            guard let self = self else { return .nil }
            self.count += 1
            return .number(Double(self.count))
        }

        engine.registerFunction(name: "getCount") { [weak self] _ in
            return .number(Double(self?.count ?? 0))
        }

        engine.registerFunction(name: "reset") { [weak self] _ in
            self?.count = 0
            return .nil
        }
    }
}

let counter = Counter()
counter.register(in: engine)

try engine.run("""
    increment()
    increment()
    print(getCount())  -- 2
    reset()
    print(getCount())  -- 0
""")
```

> Warning: Use `[weak self]` to avoid retain cycles when capturing `self` in callbacks.

## Integration with Lua Functions

Callbacks integrate seamlessly with Lua code:

```swift
engine.registerFunction(name: "double") { args in
    guard let n = args.first?.numberValue else { return .nil }
    return .number(n * 2)
}
```

```lua
-- Use in Lua functions
function quadruple(n)
    return double(double(n))
end

-- Use with table operations
local numbers = {1, 2, 3, 4, 5}
for i, n in ipairs(numbers) do
    numbers[i] = double(n)
end
```

## Best Practices

1. **Validate arguments** - Always check argument count and types before using them.

2. **Return meaningful errors** - Use descriptive error messages to help debug Lua scripts.

3. **Use weak references** - When capturing `self`, use `[weak self]` to avoid retain cycles.

4. **Keep callbacks focused** - Each callback should do one thing well.

5. **Document expected types** - Make it clear what arguments and return types are expected.

6. **Consider nil handling** - Decide whether to return `.nil` or throw an error for invalid input.

7. **Avoid blocking** - Don't perform long-running operations in callbacks as they block the Lua execution.

## See Also

- ``LuaEngine/registerFunction(name:callback:)``
- ``LuaEngine/unregisterFunction(name:)``
- ``LuaValue``
- ``LuaError``
