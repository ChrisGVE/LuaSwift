# Thread Safety

[← Coroutines](coroutines.md) | [Documentation](index.md) | [Engine Reuse →](engine-reuse.md)

---

`LuaEngine` is designed for safe concurrent access with comprehensive thread safety guarantees.

## Thread Safety Model

Every public method on `LuaEngine` acquires an internal `NSLock` before accessing the Lua state:

```swift
// Internal implementation pattern:
public func run(_ code: String) throws {
    lock.lock()
    defer { lock.unlock() }
    // ... access Lua state ...
}
```

This ensures:
- **Individual method calls are atomic** - Two threads calling `evaluate()` simultaneously will execute sequentially
- **No data races** - The Lua state is protected from concurrent modification
- **Safe registration** - `registerFunction()`, `register(server:)`, and `unregister*()` calls are thread-safe

## Creating Engines on Background Threads

`LuaEngine` can be safely created on any thread:

```swift
// Create on main thread
let mainEngine = try LuaEngine()

// Create on background thread
DispatchQueue.global().async {
    do {
        let backgroundEngine = try LuaEngine()
        let result = try backgroundEngine.evaluate("return 1 + 1")
        print(result.numberValue!) // 2.0
    } catch {
        print("Error: \(error)")
    }
}

// Create with Swift concurrency
Task.detached {
    let asyncEngine = try LuaEngine()
    let result = try asyncEngine.evaluate("return 'hello'")
    print(result.stringValue!) // "hello"
}
```

## Using Engines Across Threads

An engine created on one thread can be used from another thread:

```swift
class ScriptRunner {
    private let engine: LuaEngine

    init() throws {
        self.engine = try LuaEngine()
    }

    // Safe to call from any thread
    func execute(_ code: String) throws -> LuaValue {
        return try engine.evaluate(code)
    }
}

let runner = try ScriptRunner()

// Call from multiple threads safely
DispatchQueue.global().async {
    let result = try? runner.execute("return 42")
}

DispatchQueue.main.async {
    let result = try? runner.execute("return 'main thread'")
}
```

## High-Concurrency Patterns

While `LuaEngine` is thread-safe, the internal lock means concurrent calls serialize. For high-throughput scenarios, use an engine pool:

```swift
actor LuaEnginePool {
    private var available: [LuaEngine] = []
    private let maxSize: Int

    init(size: Int) throws {
        self.maxSize = size
        for _ in 0..<size {
            available.append(try LuaEngine())
        }
    }

    func withEngine<T>(_ work: (LuaEngine) throws -> T) async throws -> T {
        guard let engine = available.popLast() else {
            // All engines busy - create temporary one
            let temp = try LuaEngine()
            return try work(temp)
        }

        defer { available.append(engine) }
        return try work(engine)
    }
}

// Usage
let pool = try await LuaEnginePool(size: 4)

await withTaskGroup(of: Double.self) { group in
    for i in 0..<100 {
        group.addTask {
            try await pool.withEngine { engine in
                let result = try engine.evaluate("return \(i) * 2")
                return result.numberValue ?? 0
            }
        }
    }
}
```

## Async/Await Integration

For Swift concurrency, wrap blocking calls appropriately:

```swift
extension LuaEngine {
    func evaluateAsync(_ code: String) async throws -> LuaValue {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    let result = try self.evaluate(code)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// Usage
Task {
    let engine = try LuaEngine()
    let result = try await engine.evaluateAsync("return math.sqrt(144)")
    print(result.numberValue!) // 12.0
}
```

## Limitations and Gotchas

### Lock Contention

Heavy concurrent access to a single engine will serialize. Use engine pools for parallelism.

### Long-Running Scripts

A script running for extended time holds the lock, blocking other calls. Consider:
- Breaking scripts into smaller chunks
- Using coroutines with yield points
- Setting memory limits to prevent runaway scripts

### Callback Thread Affinity

Swift callbacks registered with `registerFunction()` execute on the calling thread (whichever thread called `run()` or `evaluate()`).

### Value Server Performance

`LuaValueServer` methods (`resolve`, `write`) are called while holding the engine lock. Keep them fast to avoid blocking.

### No Sendable Conformance

`LuaEngine` does not conform to `Sendable`. Use `@unchecked Sendable` wrapper or actor isolation if needed:

```swift
final class SendableEngine: @unchecked Sendable {
    let engine: LuaEngine

    init() throws {
        self.engine = try LuaEngine()
    }

    func evaluate(_ code: String) throws -> LuaValue {
        try engine.evaluate(code)
    }
}
```

### Module Registration Timing

Register all modules and callbacks before sharing an engine across threads to avoid registration races.

## Fixed-Size Pool

```swift
actor FixedEnginePool {
    private var available: [LuaEngine]
    private var waiters: [CheckedContinuation<LuaEngine, Never>] = []

    init(size: Int) throws {
        available = try (0..<size).map { _ in try LuaEngine() }
        for engine in available {
            ModuleRegistry.installModules(in: engine)
        }
    }

    func acquire() async -> LuaEngine {
        if let engine = available.popLast() {
            return engine
        }

        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release(_ engine: LuaEngine) {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume(returning: engine)
        } else {
            available.append(engine)
        }
    }

    func withEngine<T>(_ work: (LuaEngine) async throws -> T) async throws -> T {
        let engine = await acquire()
        defer { release(engine) }
        return try await work(engine)
    }
}
```

## Per-Thread Engine Pattern

```swift
class ThreadLocalEngineProvider {
    private static let key = "com.luaswift.engine"

    static func current() throws -> LuaEngine {
        if let existing = Thread.current.threadDictionary[key] as? LuaEngine {
            return existing
        }

        let engine = try LuaEngine()
        ModuleRegistry.installModules(in: engine)
        Thread.current.threadDictionary[key] = engine
        return engine
    }
}

// Usage
DispatchQueue.global().async {
    let engine = try! ThreadLocalEngineProvider.current()
    // This engine is dedicated to this thread
    try! engine.run("x = 1")
}
```

---

[← Coroutines](coroutines.md) | [Documentation](index.md) | [Engine Reuse →](engine-reuse.md)
