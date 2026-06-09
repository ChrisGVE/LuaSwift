# Core API Reference

[← Documentation](index.md) | [Value Servers →](value-servers.md)

---

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

`run`, `evaluate`, `precompile`, `createCoroutine`, and `runDebug` all accept an
optional `chunkName:` label:

```swift
try engine.run("error('boom')", chunkName: "user-config")
// → traceback references [string "user-config"] instead of [string "error('boom')"]
```

The name appears in error messages and tracebacks, making failures in many small
scripts distinguishable. A `@`-prefixed name (e.g. `chunkName: "@/path/file.lua"`)
is treated as a filename: Lua tail-truncates it in messages. When omitted, the
chunk is named after a truncation of its own source, matching prior behavior.

### Precompiled Chunks

Cache parsed Lua as a `CompiledChunk` to skip re-parsing on repeated execution:

```swift
// Compile once (optionally naming the chunk for tracebacks)...
let chunk = try engine.precompile("return x * 2", chunkName: "doubler")
print(chunk.chunkName) // Optional("doubler")

// ...execute many times
try engine.run(chunk)                      // discard result
let value = try engine.evaluate(chunk)     // return result
```

`CompiledChunk` carries the `chunkName` it was compiled with as a public
property. It is `Codable`, so it can be persisted (e.g. with `JSONEncoder`)
and reloaded in a later launch. Each chunk is stamped with the provenance of the
build that compiled it (Lua version, integer/number sizes, byte order); `run`/
`evaluate` validate that metadata against the running engine and throw a
descriptive `LuaError.runtimeError` on mismatch, so a stale cache fails cleanly
instead of corrupting the VM. There is **no cryptographic integrity** protection
of persisted caches — store them where untrusted code cannot write.

The encoded format carries a `formatVersion`. Adding `chunkName` bumped it from
`1` to `2`; a v1 cache (no chunk name) still decodes, so caches written by older
LuaSwift releases load unchanged.

> The former raw-`Data` API (`compile(_:)`, `runBytecode(_:)`,
> `evaluateBytecode(_:)`) is deprecated. Migration: recompile sources with
> `precompile(_:)` and persist the resulting `CompiledChunk` — raw bytecode
> caches cannot be wrapped, only recompiled.

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

### Engine Introspection

Read-only, raw inspection of live engine state — for tooling (debuggers, mock
environment navigators) that needs to see what is registered or defined without
executing user code:

```swift
engine.registeredValueServerNames      // [String] — servers from register(server:)
engine.registeredFunctionNames         // [String] — callbacks from registerFunction(name:)
engine.installedModuleNames            // [String] — modules from ModuleRegistry.install

// Raw globals (no metamethods)
engine.globalNames()                   // all globals
engine.globalNames(includingStandardLibrary: false) // user-defined only
engine.globalValue("myGlobal")         // LuaValue? — nil if absent/nil
```

Guarantees:

- **Raw access at every depth.** `globalNames` uses `lua_next` (not `pairs`, so
  no `__pairs`); `globalValue` uses `lua_rawget` (no `__index`). Nested tables in
  a returned value are materialized raw too — a table's metamethods are never run.
- **Globals-table identity.** Enumeration targets the registry globals table, not
  the `_ENV` upvalue; code that rebinds `_ENV` does not change what is enumerated.
- **`includingStandardLibrary: false`** subtracts a baseline snapshot taken at the
  end of `init`, leaving only globals created by executed code. The filter is
  version-agnostic (no hardcoded stdlib name list).
- **Between-runs only.** Safe only when no run is executing or paused; the engine
  lock is acquired before every access.
- **Reference-typed globals.** A global whose value is a function, userdata, or
  thread is returned as a typed, non-re-injectable `LuaValue.opaqueReference(kind)`
  (`kind` is a `LuaRefKind`: `.function` / `.userdata` / `.thread`) — present and
  typed, but carrying no registry handle. This keeps `globalValue` leak-free when
  called after every run. To *call* a function you need a `.luaFunction` handle,
  obtained by passing it to a Swift callback — not from introspection.
- **No re-injection.** An `.opaqueReference` cannot be pushed back into any engine
  (it has no referent — it materializes as `nil` if used as an argument).

Works on Lua 5.1 through 5.5.

## LuaEngineConfiguration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `sandboxed` | `Bool` | `true` | Remove dangerous functions for security |
| `packagePath` | `String?` | `nil` | Custom path for `require()` to find Lua modules |
| `memoryLimit` | `Int` | `0` | Memory limit in bytes (`0` = unlimited) |
| `vmMemoryLimit` | `Int` | `0` | Ceiling in bytes on total Lua VM allocation enforced by a custom allocator; `0` = disabled. Complements `memoryLimit`, which bounds only Swift-backed module buffers. |

> **Note:** `setInstructionLimit` is a CPU-bound control only. It does **not** interrupt a single VM instruction that calls a C function (e.g. `string.rep('A', 1e9)`), which can allocate unbounded memory before returning. Pair it with `vmMemoryLimit` to also bound Lua VM memory. See the [Resource limits](../README.md#configuration) summary in the README.

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
    case completed([LuaValue])  // Coroutine finished — all return values
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
    case .runtimeFailure(let failure):
        // Structured: includes line number, traceback, and call frames.
        print("Runtime error at line \(failure.line.map(String.init) ?? "?"): \(failure.message)")
        print(failure.traceback)
    case .cancelled:
        print("Run was cancelled")
    case .instructionLimitExceeded:
        print("Instruction limit exceeded")
    case .readOnlyAccess(let path):
        print("Cannot write to: \(path)")
    case .typeError(let expected, let actual):
        print("Expected \(expected), got \(actual)")
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

## Structured Runtime Errors

When a Lua runtime error occurs during `run()`, `evaluate()`, or
`callLuaFunction()`, LuaSwift throws `LuaError.runtimeFailure(_:)` containing
a `LuaRuntimeFailure` with:

- `message`: The error message with the `"chunk:line: "` prefix stripped.
- `rawMessage`: The unmodified error string Lua produced.
- `line`: The Lua source line where the error originated, or `nil` for
  Swift-callback errors (no Lua source line maps to Swift code).
- `traceback`: A full stack-traceback string (works on all Lua versions,
  including 5.1 which lacks `luaL_traceback`).
- `frames`: A structured `[LuaStackFrame]` array with name, source, and line
  for each frame.

Coroutine errors from `resume(_:)` surface as `LuaError.runtimeError(String)`
(unstructured), not `.runtimeFailure`, because `lua_resume` has no errfunc slot.

## Cancellation

```swift
// Request cancellation from any thread (lock-free).
engine.requestCancellation()

// After a cancelled run, reset before the next run.
engine.resetCancellation()
```

`run()` / `evaluate()` throw `LuaError.cancelled`. Call `resetCancellation()`
after both `.cancelled` and `.instructionLimitExceeded` before running again.

Instruction limits fire within `[limit, limit + hookInterval)` instructions due
to hook granularity — not exactly at `limit`.

## Debug Hook API

```swift
// Install a handler that fires on every Lua line.
engine.setDebugHandler { event, inspector in
    if case .line(let n) = event {
        print("About to execute line \(n)")
        let locals = inspector.locals(frameLevel: 0)
        return .continueRun    // or .stop, .stepInto, .stepOver, .stepOut
    }
    return .continueRun
}

// Run with the debug hook active.
try engine.runDebug("local x = 1\nlocal y = 2")

// Remove the handler.
engine.setDebugHandler(nil)
```

`LuaDebugInspector` gives read-only access to the paused VM:

| Property / Method | Description |
|---|---|
| `callStack` | All Lua frames at pause time |
| `locals(frameLevel:)` | Local variables at a given call-stack frame |
| `upvalues(frameLevel:)` | Upvalues (closures) at a given frame |
| `globals()` | All global names and their inspected values |
| `isValid` | `false` after the debug callback returns |

CALL and RET events are suppressed while a step command (`.stepInto`,
`.stepOver`, `.stepOut`) is active; only LINE events are delivered.

### Inspecting untrusted code — breadth bound

> **Security:** the inspector is **unbounded by default**, and that default is
> unsafe for debugging untrusted Lua.

`locals()`/`upvalues()`/`globals()` eagerly materialize one `LuaInspectedValue`
per table entry, under the engine lock, while the VM is paused. Against trusted
code this is the correct, faithful behavior — the host, not the library, owns the
trust decision. But a **hostile** script can build a table (or `_G`) with millions
of keys; inspecting it then allocates a `Child` per entry and can exhaust host
memory — a debugger-only DoS (CWE-400, SEC-201).

`LuaInspectedValue.maxInspectionBreadth` reports the active cap: `nil` (unbounded)
in a default build. To bound it, compile LuaSwift with the opt-in flag:

```
LUASWIFT_BOUNDED_INSPECTION=1 swift build
```

(Package.swift reads the env var and defines the flag, like the other
`LUASWIFT_*` build switches.)

Each table (and `_G` itself) then materializes at most
`LuaInspectedValue.boundedInspectionBreadth` (10,000) real children followed by a
single breadth-limit sentinel child — detect it via `value.isBreadthLimited`
rather than matching the preview string. The cap is generous enough never to
truncate realistic debug data while stopping adversarial million-entry breadth
bombs. **If you debug untrusted code, set this flag.** Trusted-code debugging
needs no bound and keeps the faithful default.

## swift-atomics Dependency

LuaSwift uses [`swift-atomics`](https://github.com/apple/swift-atomics) for
the lock-free `isPaused` and `abortReason` flags that coordinate between the
Lua VM thread and threads calling `requestCancellation()`. This is the sole
external Swift dependency; all Lua C source is bundled in-tree.

---

[← Documentation](index.md) | [Value Servers →](value-servers.md)
