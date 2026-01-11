# Coroutines

[← Callbacks](callbacks.md) | [Documentation](index.md) | [Threading →](threading.md)

---

Create and manage Lua coroutines from Swift for cooperative multitasking.

## Basic Usage

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
```

## Coroutine Status

Check the status before resuming:

```swift
let status = engine.coroutineStatus(handle)

switch status {
case .suspended:
    print("Ready to resume")
case .running:
    print("Currently executing")
case .dead:
    print("Finished or errored")
case .normal:
    print("Resumed another coroutine")
}
```

## CoroutineResult

```swift
public enum CoroutineResult {
    case yielded([LuaValue])    // Coroutine yielded values
    case completed(LuaValue)    // Coroutine finished
    case error(LuaError)        // Error occurred
}
```

Handle each case appropriately:

```swift
let result = try engine.resume(handle)

switch result {
case .yielded(let values):
    // Coroutine paused, can resume later
    print("Yielded: \(values)")

case .completed(let value):
    // Coroutine finished normally
    print("Result: \(value)")
    engine.destroy(handle)

case .error(let error):
    // Coroutine threw an error
    print("Error: \(error)")
    engine.destroy(handle)
}
```

## Passing Values

Resume with values that become yield return values:

```swift
let handle = try engine.createCoroutine(code: """
    local a, b = coroutine.yield()  -- Receive two values
    return a + b
""")

// First resume starts execution
try engine.resume(handle)

// Second resume passes values
let result = try engine.resume(handle, with: [.number(3), .number(4)])
// result is .completed(.number(7))
```

## Multiple Yields

```swift
let handle = try engine.createCoroutine(code: """
    for i = 1, 5 do
        coroutine.yield(i * i)
    end
    return "done"
""")

// Resume until complete
while true {
    let result = try engine.resume(handle)
    switch result {
    case .yielded(let values):
        print(values[0].numberValue!) // 1, 4, 9, 16, 25
    case .completed(let value):
        print(value.stringValue!) // "done"
        engine.destroy(handle)
        break
    case .error(let error):
        print("Error: \(error)")
        engine.destroy(handle)
        break
    }
}
```

## Generators Pattern

Use coroutines as iterators:

```swift
let handle = try engine.createCoroutine(code: """
    local function fibonacci(n)
        local a, b = 0, 1
        for i = 1, n do
            coroutine.yield(a)
            a, b = b, a + b
        end
    end
    fibonacci(10)
""")

var fibs: [Int] = []
while case .yielded(let values) = try engine.resume(handle) {
    if let n = values.first?.intValue {
        fibs.append(n)
    }
}
// fibs = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

engine.destroy(handle)
```

## Error Handling

```swift
let handle = try engine.createCoroutine(code: """
    coroutine.yield(1)
    error("Something went wrong")
""")

// First resume succeeds
let r1 = try engine.resume(handle)
// .yielded([.number(1)])

// Second resume triggers error
let r2 = try engine.resume(handle)
if case .error(let err) = r2 {
    print("Coroutine error: \(err)")
}

engine.destroy(handle)
```

## Important Notes

### Coroutines are Engine-Bound

Coroutine handles belong to their parent engine:

```swift
let engine1 = try LuaEngine()
let engine2 = try LuaEngine()

let handle = try engine1.createCoroutine(code: "coroutine.yield(1)")

// This works
try engine1.resume(handle)

// This would fail - handle belongs to engine1
// try engine2.resume(handle)  // Error!
```

### Always Destroy Handles

Clean up coroutines when done:

```swift
let handle = try engine.createCoroutine(code: "...")
defer { engine.destroy(handle) }

// Use coroutine...
```

### Coroutines vs Swift Threads

Lua coroutines are cooperative, not preemptive:
- They run within a single Lua state
- They yield explicitly, not at arbitrary points
- They don't provide parallelism

For parallel execution, use multiple `LuaEngine` instances.

### Long-Running Coroutines

Add yield points for responsive execution:

```swift
let handle = try engine.createCoroutine(code: """
    for i = 1, 1000000 do
        -- Do work...
        if i % 1000 == 0 then
            coroutine.yield(i)  -- Yield periodically
        end
    end
""")

// Resume in chunks, allowing UI updates or cancellation
while true {
    let result = try engine.resume(handle)
    if case .completed = result { break }
    // Check for cancellation, update UI, etc.
}
```


---

[← Callbacks](callbacks.md) | [Documentation](index.md) | [Threading →](threading.md)
