# LuaSwift

A lightweight Swift wrapper for Lua 5.4, designed for embedding Lua scripting in iOS and macOS applications.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FLuaSwift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ChrisGVE/LuaSwift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FLuaSwift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ChrisGVE/LuaSwift)
[![Lua](https://img.shields.io/badge/Lua-5.1--5.5-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Lua 5.4.7 Bundled** - Complete Lua source included, no external dependencies
- **Type-Safe** - Swift enums for Lua values with convenient accessors
- **Value Servers** - Expose Swift data to Lua with read/write support
- **Swift Callbacks** - Register Swift functions callable from Lua
- **Coroutines** - Create, resume, and manage Lua coroutines from Swift
- **Sandboxing** - Remove dangerous functions for security
- **Thread-Safe** - Safe for concurrent access

**Swift-Backed Modules** (high-performance, using Accelerate framework):
- JSON, YAML, TOML encoding/decoding
- Regular expressions (ICU)
- Extended math and statistics
- Linear algebra (BLAS/LAPACK)
- NumPy-like N-dimensional arrays

**Optional Security Modules** (require explicit opt-in):
- Sandboxed file I/O (configurable directory allowlist)
- HTTP client (URLSession-based)

**Pure Lua Modules**:
- Table and string extensions
- UTF-8 string operations
- Complex number arithmetic
- 2D/3D geometry with vectors and quaternions
- Lua version compatibility layer
- SVG generation and math expressions

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ChrisGVE/LuaSwift.git", from: "1.2.0")
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

## Bundled Modules

LuaSwift includes both Swift-backed modules (high performance via Accelerate framework) and pure Lua modules. All modules are auto-loaded and available immediately.

### Module Quick Reference

| Module | Require | Type | Description |
|--------|---------|------|-------------|
| [JSON](#json-module) | `luaswift.json` | Swift | JSON encoding/decoding |
| [YAML](#yaml-module) | `luaswift.yaml` | Swift | YAML with multi-document support |
| [TOML](#toml-module) | `luaswift.toml` | Swift | TOML configuration parsing |
| [Regex](#regex-module) | `luaswift.regex` | Swift | ICU regular expressions |
| [Math](#extended-math-module) | `luaswift.math` | Swift | Statistics and extended math |
| [Linear Algebra](#linear-algebra-module) | `luaswift.linalg` | Swift | BLAS/LAPACK matrix operations |
| [Array](#array-module-numpy-like) | `luaswift.array` | Swift | NumPy-like N-dimensional arrays |
| [Geometry](#geometry-geo) | `geo` | Swift | 2D/3D vectors, quaternions, SIMD |
| [Table Extensions](#table-extensions-tablex) | `tablex` | Swift | Functional table operations |
| [String Extensions](#string-extensions-stringx) | `stringx` | Swift | String manipulation utilities |
| [UTF-8 Extensions](#utf-8-extensions-utf8x) | `utf8x` | Swift | Unicode-aware string ops |
| [Complex Numbers](#complex-numbers-complex) | `complex` | Swift | Complex arithmetic |
| [Compatibility](#compatibility-compat) | `compat` | Lua | Lua version compatibility layer |
| [SVG](#svg-generation-svg) | `svg` | Lua | SVG graphics generation |
| [Math Expressions](#math-expressions-math_expr) | `math_expr` | Lua | Expression parsing/evaluation |
| [Types](#type-utilities-types) | `types` | Swift | Type detection and conversion |
| [IO](#io-module-sandboxed-file-system) | `luaswift.iox` | Swift | Sandboxed file I/O ⚠️ |
| [HTTP](#http-module-network-client) | `luaswift.http` | Swift | HTTP client ⚠️ |

> ⚠️ **Security modules** require explicit installation. See their documentation sections for setup instructions.

### Top-Level Globals

All modules are available as top-level globals for convenience:

```lua
-- No require() needed - these are available immediately:
json.encode({a = 1})
complex.new(1, 2)
geo.vec3(1, 2, 3)
linalg.matrix({{1,2},{3,4}})
array.zeros({3, 3})
stringx.capitalize("hello")
mathx.sign(-5)
tablex.keys({a=1, b=2})
types.typeof(complex.new(1, 2))
```

### Extending Standard Library

You can inject LuaSwift functions into Lua's standard library for seamless integration:

**Per-module import:**
```lua
-- Extend string library with stringx functions
stringx.import()

-- Now these work:
string.capitalize("hello")  -- "Hello"
("hello"):capitalize()      -- "Hello" (method syntax)
("  hi  "):strip()          -- "hi"

-- Same pattern for other modules:
mathx.import()   -- extends math
tablex.import()  -- extends table
utf8x.import()   -- extends utf8
```

**Global extension:**
```lua
-- Extend everything at once
luaswift.extend_stdlib()

-- Now all extensions are in the standard library:
math.sign(-5)                    -- -1
math.factorial(5)                -- 120
string.capitalize("hello")       -- "Hello"
table.keys({a=1, b=2})           -- {"a", "b"}

-- Plus specialized modules become math subnamespaces:
math.complex.new(3, 4)           -- complex number
math.linalg.vector({1, 2, 3})    -- linear algebra vector
math.geo.vec2(1, 2)              -- geometry vector
```

---

## Swift-Backed Modules

These modules are implemented in Swift for maximum performance, using Apple's Accelerate framework where applicable.

### JSON Module

**Namespace:** `luaswift.json`

JSON encoding and decoding with support for nested structures, Unicode, and pretty printing.

```lua
local json = require("luaswift.json")

-- Decode JSON string to Lua table
local data = json.decode('{"name": "John", "age": 30}')
print(data.name)  -- "John"

-- Encode Lua table to JSON string
local str = json.encode({items = {1, 2, 3}, active = true})
-- '{"active":true,"items":[1,2,3]}'

-- Pretty print with indentation
local pretty = json.encode({a = 1, b = 2}, {pretty = true, indent = 2})

-- Handle JSON null explicitly
local with_null = json.decode('{"value": null}')
if with_null.value == json.null then
    print("Value is null")
end
```

| Function | Description |
|----------|-------------|
| `decode(string)` | Parse JSON string to Lua value |
| `encode(value, options?)` | Convert Lua value to JSON string |
| `null` | Sentinel value for JSON null |

**Options for encode:** `{pretty = bool, indent = number}`

---

### YAML Module

**Namespace:** `luaswift.yaml`

YAML encoding and decoding with multi-document support.

```lua
local yaml = require("luaswift.yaml")

-- Decode YAML
local config = yaml.decode([[
server:
  host: localhost
  port: 8080
]])
print(config.server.port)  -- 8080

-- Encode to YAML
local str = yaml.encode({name = "test", values = {1, 2, 3}})

-- Multi-document support
local docs = yaml.decode_all([[
---
doc: 1
---
doc: 2
]])
print(#docs)  -- 2

local multi = yaml.encode_all({{a = 1}, {b = 2}})
-- "---\na: 1\n---\nb: 2\n"
```

| Function | Description |
|----------|-------------|
| `decode(string)` | Parse YAML string to Lua value |
| `encode(value)` | Convert Lua value to YAML string |
| `decode_all(string)` | Parse multi-document YAML to array |
| `encode_all(array)` | Convert array to multi-document YAML |

---

### TOML Module

**Namespace:** `luaswift.toml`

TOML encoding and decoding for configuration files.

```lua
local toml = require("luaswift.toml")

-- Decode TOML
local config = toml.decode([[
[database]
server = "192.168.1.1"
ports = [8001, 8002]
enabled = true
]])
print(config.database.server)  -- "192.168.1.1"

-- Encode to TOML
local str = toml.encode({
    title = "Config",
    owner = {name = "John", age = 30}
})
```

| Function | Description |
|----------|-------------|
| `decode(string)` | Parse TOML string to Lua table |
| `encode(table)` | Convert Lua table to TOML string |

**Note:** TOML requires the root value to be a table and does not support null values.

---

### Regex Module

**Namespace:** `luaswift.regex`

Regular expression support using ICU regex syntax via NSRegularExpression.

```lua
local regex = require("luaswift.regex")

-- Compile a pattern
local re = regex.compile("[a-z]+@[a-z]+\\.[a-z]+", "i")

-- Test if string matches
if re:test("user@example.com") then
    print("Valid email format")
end

-- Find first match
local match = re:match("Contact: user@example.com")
if match then
    print(match.text)   -- "user@example.com"
    print(match.start)  -- 10 (1-based position)
end

-- Find all matches
local emails = re:find_all("a@b.com and c@d.org")
for _, m in ipairs(emails) do
    print(m.text)
end

-- Replace
local result = re:replace("Hello World", "world", "Lua")  -- First match
local all = re:replace_all("a1b2c3", "\\d", "X")          -- "aXbXcX"

-- Split by pattern
local parts = regex.compile("\\s+"):split("a  b   c")     -- {"a", "b", "c"}

-- Quick one-shot match (no compilation)
local m = regex.match("test123", "\\d+")
print(m.text)  -- "123"
```

| Function | Description |
|----------|-------------|
| `compile(pattern, flags?)` | Compile regex pattern |
| `match(text, pattern)` | Quick one-shot match |

**Compiled regex methods:** `match`, `find_all`, `test`, `replace`, `replace_all`, `split`

**Flags:** `i` (case insensitive), `m` (multiline), `s` (dotall)

**Match object:** `{start, stop, text, groups}`

---

### Extended Math Module

**Namespace:** `luaswift.math`

Extended mathematical functions and statistics beyond the standard Lua math library.

```lua
local mathx = require("luaswift.math")

-- Hyperbolic functions
print(mathx.sinh(1))   -- 1.1752...
print(mathx.asinh(1))  -- 0.8813...

-- Rounding
print(mathx.round(3.14159, 2))  -- 3.14
print(mathx.trunc(3.9))         -- 3
print(mathx.sign(-5))           -- -1

-- Statistics
local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
print(mathx.sum(data))          -- 55
print(mathx.mean(data))         -- 5.5
print(mathx.median(data))       -- 5.5
print(mathx.stddev(data))       -- 2.872...
print(mathx.percentile(data, 75)) -- 7.75

-- Special functions
print(mathx.factorial(5))  -- 120
print(mathx.gamma(5))      -- 24 (= 4!)

-- Coordinate conversions
local x, y = table.unpack(mathx.polar_to_cart(1, math.pi/4))
local r, theta = table.unpack(mathx.cart_to_polar(1, 1))

-- Constants
print(mathx.phi)  -- 1.618... (golden ratio)
print(mathx.inf)  -- infinity
```

| Category | Functions |
|----------|-----------|
| Hyperbolic | `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh` |
| Rounding | `round(x, places?)`, `trunc`, `sign` |
| Logarithms | `log10`, `log2` |
| Statistics | `sum`, `mean`, `median`, `variance`, `stddev`, `percentile` |
| Special | `factorial`, `gamma`, `lgamma` |
| Coordinates | `polar_to_cart`, `cart_to_polar`, `spherical_to_cart`, `cart_to_spherical` |
| Constants | `phi`, `inf`, `nan` |

---

### Linear Algebra Module

**Namespace:** `luaswift.linalg`

Matrix and vector operations powered by Apple's Accelerate framework (BLAS/LAPACK).

```lua
local la = require("luaswift.linalg")

-- Create vectors and matrices
local v = la.vector({1, 2, 3})
local m = la.matrix({{1, 2}, {3, 4}, {5, 6}})

-- Special matrices
local I = la.eye(3)           -- 3x3 identity
local Z = la.zeros(2, 3)      -- 2x3 zeros
local O = la.ones(3, 2)       -- 3x2 ones
local D = la.diag({1, 2, 3})  -- diagonal matrix

-- Properties
print(m:rows(), m:cols())  -- 3, 2
print(m:shape())           -- {3, 2}
print(v:size())            -- 3

-- Element access
print(m:get(1, 2))         -- 2
m:set(1, 2, 10)

-- Arithmetic (operators: +, -, *, /)
local sum = m + m
local scaled = m * 2
local product = la.matrix({{1,2},{3,4}}) * la.matrix({{5,6},{7,8}})

-- Dot product
local dot = la.vector({1,2,3}):dot(la.vector({4,5,6}))  -- 32

-- Transpose
local mt = m:transpose()  -- or m:T

-- Linear algebra operations
local A = la.matrix({{4, 2}, {3, 1}})
print(A:det())      -- -2 (determinant)
print(A:trace())    -- 5
print(A:rank())     -- 2

local Ainv = A:inv()  -- inverse

-- Decompositions
local L, U, P = A:lu()     -- LU decomposition
local Q, R = A:qr()        -- QR decomposition
local U, S, V = A:svd()    -- Singular value decomposition
local vals, vecs = A:eig() -- Eigenvalues and eigenvectors

-- Solve linear system Ax = b
local A = la.matrix({{3, 1}, {1, 2}})
local b = la.vector({9, 8})
local x = la.solve(A, b)   -- x = {2, 3}

-- Least squares (overdetermined system)
local x = la.lstsq(A, b)
```

| Category | Functions |
|----------|-----------|
| Creation | `vector`, `matrix`, `zeros`, `ones`, `eye`, `diag`, `range`, `linspace` |
| Properties | `rows`, `cols`, `shape`, `size`, `get`, `set`, `row`, `col` |
| Arithmetic | `+`, `-`, `*`, `/`, `dot`, `hadamard` |
| Operations | `transpose`/`T`, `det`, `inv`, `trace`, `norm`, `rank` |
| Decompositions | `lu`, `qr`, `svd`, `eig`, `chol` |
| Solvers | `solve`, `lstsq` |

---

### Array Module (NumPy-like)

**Namespace:** `luaswift.array`

N-dimensional arrays with NumPy-style broadcasting and operations.

```lua
local np = require("luaswift.array")

-- Create arrays
local a = np.array({1, 2, 3, 4, 5, 6})        -- 1D
local b = np.array({{1, 2, 3}, {4, 5, 6}})    -- 2D (2x3)
local c = np.zeros({2, 3, 4})                  -- 3D zeros
local d = np.ones({3, 3})                      -- 3x3 ones
local e = np.full({2, 2}, 7)                   -- 2x2 filled with 7

-- Ranges
local r = np.arange(0, 10, 2)      -- {0, 2, 4, 6, 8}
local l = np.linspace(0, 1, 5)    -- {0, 0.25, 0.5, 0.75, 1}

-- Random arrays
local uniform = np.random.rand({3, 3})   -- uniform [0, 1)
local normal = np.random.randn({3, 3})   -- normal distribution

-- Properties
print(b:shape())  -- {2, 3}
print(b:ndim())   -- 2
print(b:size())   -- 6

-- Reshaping
local flat = b:flatten()           -- 1D: {1,2,3,4,5,6}
local reshaped = a:reshape({2, 3}) -- 2x3
local expanded = a:expand_dims(1)  -- add dimension
local squeezed = c:squeeze()       -- remove size-1 dimensions

-- Element access (1-based indexing)
print(b:get(1, 2))    -- 2
b:set(1, 2, 10)

-- Arithmetic with broadcasting
local x = np.array({{1}, {2}, {3}})  -- 3x1
local y = np.array({10, 20, 30})      -- 1x3
local z = x + y  -- broadcasts to 3x3

-- Scalar operations
local doubled = b * 2
local shifted = b + 10

-- Element-wise math
local sq = np.sqrt(b)
local ex = np.exp(a)
local logs = np.log(a)
local sines = np.sin(a)

-- Reductions
print(b:sum())         -- 21 (all elements)
print(b:sum(1))        -- sum along axis 0: {5, 7, 9}
print(b:mean())        -- 3.5
print(b:std())         -- standard deviation
print(b:min(), b:max())
print(b:argmax())      -- index of maximum (1-based)

-- Comparisons (return boolean arrays)
local mask = np.greater(a, 3)     -- {false, false, false, true, true, true}
local result = np.where(mask, a, np.zeros({6}))  -- conditional select

-- Matrix multiplication
local m1 = np.array({{1, 2}, {3, 4}})
local m2 = np.array({{5, 6}, {7, 8}})
local prod = np.dot(m1, m2)  -- matrix multiplication

-- Vector dot product
local v1 = np.array({1, 2, 3})
local v2 = np.array({4, 5, 6})
print(np.dot(v1, v2))  -- 32 (scalar)

-- Convert to Lua table
local tbl = b:tolist()  -- nested Lua arrays
```

| Category | Functions |
|----------|-----------|
| Creation | `array`, `zeros`, `ones`, `full`, `arange`, `linspace`, `random.rand`, `random.randn` |
| Properties | `shape`, `ndim`, `size`, `get`, `set` |
| Reshaping | `reshape`, `flatten`, `squeeze`, `expand_dims`, `transpose`/`T`, `copy` |
| Math | `abs`, `sqrt`, `exp`, `log`, `sin`, `cos`, `tan` |
| Arithmetic | `+`, `-`, `*`, `/`, `^` (with broadcasting) |
| Reductions | `sum`, `mean`, `std`, `var`, `min`, `max`, `argmin`, `argmax`, `prod` |
| Comparison | `equal`, `greater`, `less`, `where` |
| Linear Algebra | `dot` |

**Broadcasting Rules:**
- Dimensions aligned from right
- Size-1 dimensions broadcast to match
- Missing dimensions treated as size 1

---

### IO Module (Sandboxed File System)

**Require:** `luaswift.iox`

> ⚠️ **Security Module**: IOModule is NOT installed by default. It requires explicit configuration of allowed directories before use.

Sandboxed file system operations restricted to explicitly allowed directories.

**Swift Setup (Required):**

```swift
import LuaSwift

let engine = try LuaEngine()

// REQUIRED: Configure allowed directories BEFORE installing
let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
IOModule.setAllowedDirectories([documentsURL.path], for: engine)

// Then install the module
ModuleRegistry.installIOModule(in: engine)

// Now Lua can access files within the Documents directory
```

**Lua API:**

```lua
local iox = require("luaswift.iox")

-- File operations
local content = iox.read_file("/path/to/file.txt")
iox.write_file("/path/to/file.txt", "content")
iox.append_file("/path/to/log.txt", "new line\n")

-- Path checks
if iox.exists("/path/to/file") then ... end
if iox.is_file(path) then ... end
if iox.is_dir(path) then ... end

-- Directory operations
local files = iox.list_dir("/path/to/dir")  -- Returns array of names
iox.mkdir("/path/to/newdir")
iox.mkdir("/path/to/deep/nested/dir", {parents = true})
iox.remove("/path/to/file.txt")
iox.rename("/path/old.txt", "/path/new.txt")

-- File info
local info = iox.stat("/path/to/file.txt")
print(info.size)      -- File size in bytes
print(info.is_file)   -- true
print(info.is_dir)    -- false
print(info.modified)  -- Unix timestamp
print(info.created)   -- Unix timestamp

-- Path utilities (no security restrictions)
local full = iox.path.join("dir", "subdir", "file.txt")
local name = iox.path.basename("/path/to/file.txt")  -- "file.txt"
local dir = iox.path.dirname("/path/to/file.txt")    -- "/path/to"
local ext = iox.path.extension("/path/to/file.txt")  -- "txt" or nil
local abs = iox.path.absolute("relative/path")
local norm = iox.path.normalize("/path/../to/./file") -- "/to/file"
```

**Security Features:**

- All file operations validate paths against the allowed directories list
- Path traversal attacks (`../../../etc/passwd`) are detected and blocked
- Paths are normalized before validation to prevent bypass attempts
- `exists()`, `is_file()`, `is_dir()` return `false` for disallowed paths (no error)
- Other operations throw errors for disallowed paths

**Query Allowed Directories:**

```swift
// Check what directories are configured
let dirs = IOModule.getAllowedDirectories(for: engine)
print(dirs)  // ["/Users/.../Documents"]
```

---

### HTTP Module (Network Client)

**Require:** `luaswift.http`

> ⚠️ **Security Module**: HTTPModule is NOT installed by default. Apps must explicitly opt-in to enable network access from Lua scripts.

HTTP client using URLSession for making network requests.

**Swift Setup (Required):**

```swift
import LuaSwift

let engine = try LuaEngine()

// Explicitly install HTTP module to enable network access
ModuleRegistry.installHTTPModule(in: engine)

// Optionally also install JSON for parsing responses
ModuleRegistry.installJSONModule(in: engine)
```

**Lua API:**

```lua
local http = require("luaswift.http")
local json = require("luaswift.json")

-- Simple GET request
local resp = http.get("https://api.example.com/data")
print(resp.status)  -- 200
print(resp.ok)      -- true (status 200-299)
print(resp.body)    -- Response body as string

-- GET with custom headers
local resp = http.get("https://api.example.com/data", {
    headers = {
        ["Authorization"] = "Bearer token123",
        ["Accept"] = "application/json"
    }
})

-- POST with JSON body (auto-sets Content-Type)
local resp = http.post("https://api.example.com/users", {
    json = {name = "John", email = "john@example.com"}
})

-- POST with raw body
local resp = http.post("https://api.example.com/data", {
    headers = {["Content-Type"] = "text/plain"},
    body = "Raw content here"
})

-- Other HTTP methods
http.put(url, options)
http.patch(url, options)
http.delete(url, options)
http.head(url, options)    -- Returns headers only, empty body
http.options(url, options)

-- Generic request function
http.request("GET", url, options)

-- Request options
{
    headers = {},        -- Table of request headers
    body = "string",     -- Raw body content
    json = {},           -- Table auto-encoded as JSON
    timeout = 30,        -- Timeout in seconds (default: 30)
    follow_redirects = true  -- Follow HTTP redirects (default: true)
}

-- Response object
resp.status   -- HTTP status code (number)
resp.ok       -- true if status is 200-299 (boolean)
resp.headers  -- Response headers (table)
resp.body     -- Response body (string)
resp.url      -- Final URL after redirects (string)
```

**Example: Fetching and Parsing JSON:**

```lua
local http = require("luaswift.http")
local json = require("luaswift.json")

local resp = http.get("https://api.github.com/users/octocat")
if resp.ok then
    local user = json.decode(resp.body)
    print("Name:", user.name)
    print("Location:", user.location)
else
    print("Error:", resp.status)
end
```

**Error Handling:**

```lua
-- Invalid URLs throw errors
local ok, err = pcall(function()
    http.get("ht tp://invalid url")
end)
print(err)  -- "Invalid URL: ht tp://invalid url"

-- Timeouts throw errors
local ok, err = pcall(function()
    http.get("https://httpbin.org/delay/10", {timeout = 1})
end)
print(err)  -- "Request timed out" or similar
```

**Security Considerations:**

- HTTPModule is not included in `ModuleRegistry.installModules()` by default
- Host application must explicitly call `ModuleRegistry.installHTTPModule(in:)`
- This allows apps to control whether Lua scripts can make network requests
- Consider your app's security requirements before enabling

---

## Pure Lua Modules

These modules are implemented in pure Lua for portability.

### Table Extensions (tablex)

**Require:** `tablex`

Extended table operations including functional programming utilities.

```lua
local tablex = require("tablex")

-- Copying
local t = {a = 1, b = {c = 2}}
local shallow = tablex.copy(t)
local deep = tablex.deepcopy(t)

-- Merging
local merged = tablex.merge({a = 1}, {b = 2})        -- {a=1, b=2}
local deepm = tablex.deepmerge({a = {x = 1}}, {a = {y = 2}})

-- Functional operations
local doubled = tablex.map({1, 2, 3}, function(v) return v * 2 end)
local evens = tablex.filter({1, 2, 3, 4}, function(v) return v % 2 == 0 end)
local sum = tablex.reduce({1, 2, 3}, function(acc, v) return acc + v end, 0)

-- Query functions
local keys = tablex.keys({a = 1, b = 2})       -- {"a", "b"}
local values = tablex.values({a = 1, b = 2})   -- {1, 2}
local found = tablex.find({10, 20, 30}, 20)    -- 2 (key)
print(tablex.contains({1, 2, 3}, 2))           -- true
print(tablex.size({a = 1, b = 2}))             -- 2
print(tablex.isarray({1, 2, 3}))               -- true

-- Transformations
local inverted = tablex.invert({a = 1, b = 2})  -- {[1]="a", [2]="b"}
local flat = tablex.flatten({{1, 2}, {3, 4}})   -- {1, 2, 3, 4}
local slice = tablex.slice({1,2,3,4,5}, 2, 4)   -- {2, 3, 4}
local rev = tablex.reverse({1, 2, 3})           -- {3, 2, 1}

-- Set operations
local union = tablex.union({1, 2}, {2, 3})           -- {1, 2, 3}
local inter = tablex.intersection({1, 2}, {2, 3})    -- {2}
local diff = tablex.difference({1, 2, 3}, {2})       -- {1, 3}

-- Comparison
print(tablex.equals({1, 2}, {1, 2}))       -- true
print(tablex.deepequals({a={1}}, {a={1}})) -- true
```

| Category | Functions |
|----------|-----------|
| Copying | `copy`, `deepcopy` |
| Merging | `merge`, `deepmerge` |
| Functional | `map`, `filter`, `reduce`, `foreach` |
| Query | `find`, `contains`, `keys`, `values`, `size`, `isempty`, `isarray` |
| Transform | `invert`, `flatten`, `slice`, `reverse` |
| Sets | `union`, `intersection`, `difference` |
| Comparison | `equals`, `deepequals` |

---

### String Extensions (stringx)

**Require:** `stringx`

Extended string manipulation utilities.

```lua
local stringx = require("stringx")

-- Trimming
print(stringx.trim("  hello  "))     -- "hello"
print(stringx.ltrim("  hello"))      -- "hello"
print(stringx.rtrim("hello  "))      -- "hello"
print(stringx.strip("##hello##", "#")) -- "hello"

-- Case conversion
print(stringx.capitalize("hello world"))  -- "Hello world"
print(stringx.title("hello world"))       -- "Hello World"

-- Splitting and joining
local parts = stringx.split("a,b,c", ",")  -- {"a", "b", "c"}
local lines = stringx.splitlines("a\nb\nc") -- {"a", "b", "c"}
print(stringx.join({"a", "b"}, "-"))        -- "a-b"

-- Searching
print(stringx.startswith("hello", "he"))   -- true
print(stringx.endswith("hello", "lo"))     -- true
print(stringx.contains("hello", "ell"))    -- true
print(stringx.count("banana", "a"))        -- 3

-- Replacing
print(stringx.replace("hello", "l", "L"))     -- "heLLo"
print(stringx.replace("hello", "l", "L", 1))  -- "heLlo" (limit 1)

-- Padding
print(stringx.lpad("42", 5, "0"))    -- "00042"
print(stringx.rpad("hi", 5))         -- "hi   "
print(stringx.center("hi", 6))       -- "  hi  "

-- Testing
print(stringx.isalpha("hello"))   -- true
print(stringx.isdigit("123"))     -- true
print(stringx.isalnum("abc123"))  -- true
print(stringx.isspace("   "))     -- true
print(stringx.isempty(""))        -- true
print(stringx.isblank("  "))      -- true

-- Transformation
print(stringx.reverse("hello"))           -- "olleh"
print(stringx.wrap("long text here", 5))  -- word wrapped
print(stringx.truncate("hello world", 8)) -- "hello..."
print(stringx.slug("Hello World!"))       -- "hello-world"
```

| Category | Functions |
|----------|-----------|
| Trimming | `trim`, `ltrim`, `rtrim`, `strip` |
| Case | `capitalize`, `title` |
| Split/Join | `split`, `splitlines`, `join` |
| Search | `startswith`, `endswith`, `contains`, `count` |
| Replace | `replace` |
| Padding | `lpad`, `rpad`, `center` |
| Testing | `isalpha`, `isdigit`, `isalnum`, `isspace`, `isempty`, `isblank` |
| Transform | `reverse`, `wrap`, `truncate`, `slug` |

---

### UTF-8 Extensions (utf8x)

**Require:** `utf8x`

Extended UTF-8 string operations with Unicode awareness.

```lua
local utf8x = require("utf8x")

-- Character-based substring (not byte-based)
print(utf8x.sub("日本語", 1, 2))  -- "日本"

-- Reverse UTF-8 string
print(utf8x.reverse("hello"))  -- "olleh"
print(utf8x.reverse("日本"))   -- "本日"

-- Case conversion (Latin-1 support)
print(utf8x.upper("café"))  -- "CAFÉ"
print(utf8x.lower("NAÏVE")) -- "naïve"

-- Display width (CJK = 2, others = 1)
print(utf8x.width("hello"))  -- 5
print(utf8x.width("日本語")) -- 6 (3 chars × 2)
print(utf8x.width("Aあ"))    -- 3 (1 + 2)

-- Character properties (pass codepoint)
local cp = utf8.codepoint("A")
print(utf8x.isalpha(cp))  -- true
print(utf8x.isupper(cp))  -- true
print(utf8x.islower(cp))  -- false
print(utf8x.isdigit(utf8.codepoint("5")))  -- true
print(utf8x.isspace(utf8.codepoint(" ")))  -- true

-- Standard utf8 functions also available
print(utf8x.len("日本語"))  -- 3 (character count)
```

| Function | Description |
|----------|-------------|
| `sub(s, i, j?)` | Character-based substring |
| `reverse(s)` | Reverse UTF-8 string |
| `upper(s)` | Uppercase (Latin-1 aware) |
| `lower(s)` | Lowercase (Latin-1 aware) |
| `width(s)` | Display width (CJK-aware) |
| `isalpha(cp)` | Is alphabetic codepoint |
| `isupper(cp)` | Is uppercase codepoint |
| `islower(cp)` | Is lowercase codepoint |
| `isdigit(cp)` | Is digit codepoint |
| `isspace(cp)` | Is whitespace codepoint |

---

### Complex Numbers (complex)

**Require:** `complex`

Complex number arithmetic and mathematical functions.

```lua
local complex = require("complex")

-- Creation
local z1 = complex.new(3, 4)      -- 3 + 4i
local z2 = complex(1, -2)         -- callable syntax
local z3 = complex.polar(5, 0.9)  -- from polar form
local z4 = complex.parse("3+4i")  -- from string

-- Properties
print(z1.re, z1.im)  -- 3, 4
print(z1:abs())      -- 5 (magnitude)
print(z1:arg())      -- 0.927... (angle in radians)

-- Arithmetic (operators)
local sum = z1 + z2
local diff = z1 - z2
local prod = z1 * z2
local quot = z1 / z2
local neg = -z1
local pow = z1 ^ 2

-- Methods
local conj = z1:conj()           -- conjugate: 3 - 4i
local r, theta = z1:polar()      -- to polar form
print(z1:tostring())             -- "3+4i"

-- Mathematical functions
print(complex.sqrt(complex(-1, 0)))   -- 0+1i (i)
print(complex.exp(complex(0, math.pi))) -- -1+0i (Euler's)
print(complex.log(complex.new(1, 0))) -- 0+0i

-- Trigonometric (complex domain)
local sin_z = complex.sin(z1)
local cos_z = complex.cos(z1)
local tan_z = complex.tan(z1)

-- Hyperbolic
local sinh_z = complex.sinh(z1)
local cosh_z = complex.cosh(z1)

-- Inverse trigonometric
local asin_z = complex.asin(z1)
local acos_z = complex.acos(z1)
local atan_z = complex.atan(z1)
```

| Category | Functions |
|----------|-----------|
| Creation | `new`, `polar`, `parse` |
| Properties | `.re`, `.im`, `abs`, `arg`, `polar` |
| Operators | `+`, `-`, `*`, `/`, `^`, `-` (unary), `==` |
| Methods | `conj`, `clone`, `tostring` |
| Functions | `sqrt`, `exp`, `log` |
| Trigonometric | `sin`, `cos`, `tan`, `asin`, `acos`, `atan` |
| Hyperbolic | `sinh`, `cosh`, `tanh` |

---

### Geometry (geo)

**Require:** `geo`

2D and 3D geometry with vectors, quaternions, and transformations.

```lua
local geo = require("geo")

-- 2D Vectors
local v1 = geo.vec2(3, 4)
print(v1:length())      -- 5
print(v1:normalize())   -- unit vector
print(v1:angle())       -- angle in radians

local v2 = geo.vec2(1, 0)
print(v1:dot(v2))       -- dot product
print(v1:cross(v2))     -- 2D cross (scalar)
print(v1:rotate(math.pi/2))  -- rotate 90°
print(v1:lerp(v2, 0.5)) -- linear interpolation

-- Vector operators
local sum = v1 + v2
local scaled = v1 * 2
local neg = -v1

-- 3D Vectors
local v3 = geo.vec3(1, 2, 3)
local v4 = geo.vec3(4, 5, 6)
print(v3:cross(v4))     -- 3D cross product (vec3)
print(v3:rotate(geo.vec3(0,1,0), math.pi/4))  -- rotate around axis

-- 2D Geometry functions
local dist = geo.distance(v1, v2)
local angle = geo.angle(p1, p2, p3)  -- angle at p2
local area = geo.area_triangle(p1, p2, p3)
local center = geo.centroid({p1, p2, p3})
local inside = geo.point_in_polygon(point, polygon)
local hull = geo.convex_hull(points)
local intersect = geo.line_intersection({p1, p2}, {p3, p4})
local circle = geo.circle_from_3_points(p1, p2, p3)

-- 2D Transformations (chainable)
local t = geo.transform2d()
    :translate(10, 20)
    :rotate(math.pi/4)
    :scale(2)
local transformed = t:apply(v1)

-- Quaternions (3D rotations)
local q = geo.quaternion.from_euler(yaw, pitch, roll)
local q2 = geo.quaternion.from_axis_angle(geo.vec3(0,1,0), math.pi/2)
local rotated = q:rotate(v3)       -- rotate vector
local interpolated = q:slerp(q2, 0.5)  -- spherical lerp

-- Quaternion conversions
local yaw, pitch, roll = q:to_euler()
local axis, angle = q:to_axis_angle()
local matrix = q:to_matrix()

-- 3D Geometry functions
local plane = geo.plane_from_3_points(p1, p2, p3)
local dist = geo.point_plane_distance(point, plane)
local hit = geo.line_plane_intersection(line, plane)
local sphere = geo.sphere_from_4_points(p1, p2, p3, p4)

-- 3D Transformations
local t3d = geo.transform3d()
    :translate(1, 2, 3)
    :rotate_x(math.pi/4)
    :rotate_y(math.pi/4)
    :scale(2)
```

| Category | Functions |
|----------|-----------|
| 2D Vectors | `vec2`, methods: `length`, `normalize`, `dot`, `cross`, `angle`, `rotate`, `lerp`, `project`, `reflect`, `perpendicular` |
| 3D Vectors | `vec3`, same methods plus 3D cross product |
| 2D Geometry | `distance`, `angle`, `area_triangle`, `centroid`, `point_in_polygon`, `line_intersection`, `convex_hull`, `circle_from_3_points` |
| 3D Geometry | `plane_from_3_points`, `point_plane_distance`, `line_plane_intersection`, `sphere_from_4_points` |
| 2D Transform | `transform2d`, methods: `translate`, `rotate`, `scale`, `apply`, `multiply`, `inverse` |
| 3D Transform | `transform3d`, methods: `translate`, `rotate_x/y/z`, `rotate_axis`, `scale`, `apply`, `multiply` |
| Quaternions | `quaternion`, `from_euler`, `from_axis_angle`, methods: `normalize`, `conjugate`, `inverse`, `rotate`, `slerp`, `to_euler`, `to_axis_angle`, `to_matrix` |

---

### Type Utilities (types)

**Require:** `types` or `luaswift.types`

Type detection and conversion utilities for LuaSwift objects.

```lua
-- Type detection
types.typeof(complex.new(1, 2))         -- "complex"
types.typeof(geo.vec2(1, 2))            -- "vec2"
types.typeof(linalg.matrix({{1,2}}))    -- "linalg.matrix"
types.typeof({a = 1})                   -- "table"

-- Type checking
types.is(value, "complex")              -- true/false
types.is_luaswift(value)                -- true if any LuaSwift type

-- Category checks
types.is_numeric(value)                 -- number or complex
types.is_vector(value)                  -- vec2, vec3, or linalg.vector
types.is_matrix(value)                  -- linalg.matrix or array
types.is_geometry(value)                -- vec2, vec3, quaternion, transform3d

-- Conversion
types.to_complex(value)                 -- convert to complex
types.to_vec2(value)                    -- convert to vec2
types.to_vec3(value)                    -- convert to vec3
types.to_array(value)                   -- convert to array
types.to_vector(value)                  -- convert to linalg.vector
types.to_matrix(value)                  -- convert to linalg.matrix

-- Clone (deep copy preserving type)
local copy = types.clone(complex.new(1, 2))

-- List all LuaSwift types
for _, t in ipairs(types.all_types()) do
    print(t)  -- "complex", "vec2", "vec3", "array", etc.
end
```

| Function | Description |
|----------|-------------|
| `typeof(value)` | Get type name (returns `__luaswift_type` for objects) |
| `is(value, typename)` | Check if value is specific type |
| `is_luaswift(value)` | Check if value is any LuaSwift type |
| `is_numeric/vector/matrix/geometry(v)` | Category checks |
| `to_complex/vec2/vec3/array/vector/matrix(v)` | Type conversions |
| `clone(value)` | Deep clone preserving type |
| `all_types()` | List all LuaSwift types |

---

### Compatibility (compat)

**Require:** `compat`

Lua version compatibility layer for running legacy code on Lua 5.4.

```lua
local compat = require("compat")

-- Version detection
print(compat.version)    -- "5.4"
print(compat.lua54)      -- true
print(compat.lua53)      -- false
print(compat.luajit)     -- false

-- Feature detection
if compat.features.bitwise_ops then
    print("Native bitwise operators available")
end

-- bit32 library (removed in 5.4, provided here)
print(compat.bit32.band(0xFF, 0x0F))    -- 15
print(compat.bit32.bor(0x0F, 0xF0))     -- 255
print(compat.bit32.bxor(0xFF, 0x0F))    -- 240
print(compat.bit32.bnot(0))             -- 4294967295
print(compat.bit32.lshift(1, 4))        -- 16
print(compat.bit32.rshift(16, 2))       -- 4
print(compat.bit32.lrotate(0x80000000, 1)) -- 1
print(compat.bit32.extract(0xFF, 4, 4)) -- 15
print(compat.bit32.replace(0, 15, 4, 4)) -- 240

-- Legacy aliases
local unpack = compat.unpack  -- table.unpack
local loadstring = compat.loadstring  -- load

-- Install globally (modifies _G)
compat.install()  -- makes bit32, unpack, loadstring global

-- Check for deprecated features in code
local warnings = compat.check_deprecated([[
    local x = setfenv(func, {})
    module("mymodule")
]])
-- Returns {"setfenv is not supported...", "module() is deprecated..."}

-- Version comparison
if compat.version_at_least("5.3") then
    print("Lua 5.3+ features available")
end
print(compat.version_compare("5.4", "5.3"))  -- 1 (5.4 > 5.3)
```

| Category | Functions |
|----------|-----------|
| Detection | `version`, `lua51`/`lua52`/`lua53`/`lua54`, `luajit`, `features` |
| bit32 | `band`, `bor`, `bxor`, `bnot`, `lshift`, `rshift`, `arshift`, `lrotate`, `rrotate`, `btest`, `extract`, `replace` |
| Aliases | `unpack`, `loadstring`, `setfenv`*, `getfenv`* |
| Utilities | `install`, `check_deprecated`, `version_compare`, `version_at_least` |

*`setfenv`/`getfenv` throw errors as they cannot be emulated in Lua 5.2+

---

### SVG Generation (svg)

**Require:** `svg`

Create SVG graphics programmatically.

```lua
local svg = require("svg")

local drawing = svg.create(800, 600)

-- Basic shapes
drawing:rect(10, 10, 100, 50, {fill = "blue"})
drawing:circle(200, 200, 50, {stroke = "red", fill = "none"})
drawing:ellipse(400, 200, 60, 40, {fill = "green"})
drawing:line(0, 0, 100, 100, {stroke = "black"})

-- Polygons and paths
drawing:polygon({{x=100,y=10}, {x=150,y=90}, {x=50,y=90}}, {fill = "yellow"})
drawing:path("M 10 10 L 100 10 L 100 100 Z", {stroke = "purple"})

-- Text with Unicode support
drawing:text("Hello SVG!", 100, 100, {font_size = 20})
drawing:text(svg.greek.alpha .. " = 45°", 150, 150)

-- Groups and transforms
local g = drawing:group(svg.translate(50, 50))
g:circle(0, 0, 20, {fill = "red"})

-- Charts
drawing:linePlot({{x=0,y=0}, {x=50,y=30}, {x=100,y=10}}, {stroke = "blue"})
drawing:scatterPlot({{x=10,y=10}, {x=50,y=50}}, 5, {fill = "red"})

-- Render to string
local svgString = drawing:render()
```

| Category | Functions |
|----------|-----------|
| Creation | `svg.create(width, height, options?)` |
| Shapes | `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`, `path` |
| Text | `text` |
| Groups | `group` |
| Charts | `linePlot`, `scatterPlot`, `barChart` |
| Transforms | `svg.translate`, `svg.rotate`, `svg.scale` |
| Constants | `svg.greek` (Greek letters and subscripts) |
| Output | `render()` |

---

### Math Expressions (math_expr)

**Require:** `math_expr`

Parse and evaluate mathematical expressions.

```lua
local math_expr = require("math_expr")

-- Basic evaluation
print(math_expr.eval("2 + 3 * 4"))      -- 14
print(math_expr.eval("sqrt(16)"))        -- 4
print(math_expr.eval("sin(pi / 2)"))     -- 1

-- With variables
print(math_expr.eval("x^2 + 2*x + 1", {x = 3}))  -- 16
print(math_expr.eval("a * b", {a = 5, b = 7}))   -- 35

-- Step-by-step solving
local result = math_expr.solve("(2 + 3) * 4", {show_steps = true})
-- Returns table with intermediate steps
```

| Function | Description |
|----------|-------------|
| `eval(expr, vars?)` | Evaluate expression with optional variables |
| `solve(expr, options?)` | Solve with optional step-by-step output |

**Supported:** `+`, `-`, `*`, `/`, `^`, parentheses, `sin`, `cos`, `tan`, `sqrt`, `abs`, `log`, `ln`, `exp`, `pi`, `e`

---

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

`LuaEngine` is designed for safe concurrent access with comprehensive thread safety guarantees.

### Thread Safety Model

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

### Creating Engines on Background Threads

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

### Using Engines Across Threads

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

### High-Concurrency Patterns

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

### Async/Await Integration

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

### Coroutines and Threading

Lua coroutines are **not** Swift threads - they're cooperative lightweight threads within a single Lua state. Coroutine handles are tied to their parent engine and must be used from the same engine:

```swift
let engine = try LuaEngine()
let handle = try engine.createCoroutine(code: "coroutine.yield(1)")

// This works - same engine
let result = try engine.resume(handle)

// This does NOT work - different engine
let engine2 = try LuaEngine()
// engine2.resume(handle) // Would fail - handle belongs to engine1
```

### Limitations and Gotchas

1. **Lock contention**: Heavy concurrent access to a single engine will serialize. Use engine pools for parallelism.

2. **Long-running scripts**: A script running for extended time holds the lock, blocking other calls. Consider:
   - Breaking scripts into smaller chunks
   - Using coroutines with yield points
   - Setting memory limits to prevent runaway scripts

3. **Callback thread affinity**: Swift callbacks registered with `registerFunction()` execute on the calling thread (whichever thread called `run()` or `evaluate()`).

4. **Value servers**: `LuaValueServer` methods (`resolve`, `write`) are called while holding the engine lock. Keep them fast to avoid blocking.

5. **No Sendable conformance**: `LuaEngine` does not conform to `Sendable`. Use `@unchecked Sendable` wrapper or actor isolation if needed:

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

6. **Module registration timing**: Register all modules and callbacks before sharing an engine across threads to avoid registration races.

## Engine Reuse Patterns

`LuaEngine` is designed for reuse - create once, execute many scripts without reinitialization overhead.

### Reusing a Single Engine

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

### State Persistence Between Executions

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

### Resetting Engine State

`LuaEngine` does not have a built-in reset method. To clear state, choose from these approaches:

**Option 1: Create a new engine** (simplest, recommended)

```swift
// When you need a fresh state
let freshEngine = try LuaEngine()
```

**Option 2: Manually clear specific globals**

```swift
// Clear known variables
try engine.run("""
    x = nil
    config = nil
    myFunction = nil
""")
```

**Option 3: Track and clear all user-defined globals**

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

### Performance: Reuse vs Fresh Instantiation

| Operation | Cost | Notes |
|-----------|------|-------|
| `LuaEngine()` creation | ~1-5ms | Creates Lua state, opens libraries, applies sandbox, registers modules |
| `run()` / `evaluate()` | ~0.01-0.1ms | Just loads and executes code |
| `registerFunction()` | Negligible | One-time setup cost |
| `register(server:)` | Negligible | One-time setup cost |

**Guidelines:**
- Reuse engines when possible - 10-100x faster than creating new ones
- Create new engines when you need guaranteed clean state
- For request/response patterns, consider engine pools (see Thread Safety section)

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

### Long-Running Engine Instances

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

**Best practices for long-running engines:**

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

### Value Server Lifecycle

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

LuaSwift supports running multiple `LuaEngine` instances concurrently with complete isolation or shared resources.

### Independent Engines

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

**Key characteristics:**
- Each engine has a separate `lua_State`
- No cross-engine variable leakage
- Independent memory usage
- Independent sandboxing configuration

### Sharing Value Servers Between Engines

A single `LuaValueServer` can be registered with multiple engines, enabling shared data access:

```swift
// Create a shared data server
class SharedConfigServer: LuaValueServer {
    let namespace = "Config"
    private var settings: [String: LuaValue] = [
        "apiUrl": .string("https://api.example.com"),
        "timeout": .number(30),
        "debug": .bool(false)
    ]

    func resolve(path: [String]) -> LuaValue {
        guard let key = path.first else { return .table(settings) }
        return settings[key] ?? .nil
    }

    func canWrite(path: [String]) -> Bool { return true }

    func write(path: [String], value: LuaValue) throws {
        guard let key = path.first else { return }
        settings[key] = value
    }
}

let sharedConfig = SharedConfigServer()

// Register with multiple engines
let engine1 = try LuaEngine()
let engine2 = try LuaEngine()

engine1.register(server: sharedConfig)
engine2.register(server: sharedConfig)

// Both engines see the same data
try engine1.run("Config.timeout = 60")
let timeout = try engine2.evaluate("return Config.timeout")
print(timeout.numberValue!) // 60 - change from engine1 visible to engine2
```

**Thread safety for shared servers:**

When sharing servers across engines used from multiple threads, the server implementation must be thread-safe:

```swift
class ThreadSafeConfigServer: LuaValueServer {
    let namespace = "Config"
    private let lock = NSLock()
    private var settings: [String: LuaValue] = [:]

    func resolve(path: [String]) -> LuaValue {
        lock.lock()
        defer { lock.unlock() }
        guard let key = path.first else { return .table(settings) }
        return settings[key] ?? .nil
    }

    func canWrite(path: [String]) -> Bool { return true }

    func write(path: [String], value: LuaValue) throws {
        lock.lock()
        defer { lock.unlock() }
        guard let key = path.first else { return }
        settings[key] = value
    }
}
```

### Independent Value Server Configurations

Each engine can have different servers with the same or different namespaces:

```swift
// Development vs Production configurations
class DevConfigServer: LuaValueServer {
    let namespace = "Config"
    func resolve(path: [String]) -> LuaValue {
        switch path.first {
        case "apiUrl": return .string("http://localhost:8080")
        case "debug": return .bool(true)
        default: return .nil
        }
    }
}

class ProdConfigServer: LuaValueServer {
    let namespace = "Config"
    func resolve(path: [String]) -> LuaValue {
        switch path.first {
        case "apiUrl": return .string("https://api.production.com")
        case "debug": return .bool(false)
        default: return .nil
        }
    }
}

let devEngine = try LuaEngine()
let prodEngine = try LuaEngine()

devEngine.register(server: DevConfigServer())
prodEngine.register(server: ProdConfigServer())

// Same Lua code, different behavior
let script = "return Config.apiUrl"
try devEngine.evaluate(script).stringValue!  // "http://localhost:8080"
try prodEngine.evaluate(script).stringValue! // "https://api.production.com"
```

### Memory Management

**Engine lifecycle:**

```swift
// Engines are reference-counted - automatic cleanup
func processScript(_ code: String) throws -> LuaValue {
    let engine = try LuaEngine()  // Created
    let result = try engine.evaluate(code)
    return result
}  // Engine deallocated when function returns

// For long-lived engines, store in a property
class ScriptManager {
    private var engines: [String: LuaEngine] = [:]

    func getEngine(for context: String) throws -> LuaEngine {
        if let existing = engines[context] {
            return existing
        }
        let new = try LuaEngine()
        engines[context] = new
        return new
    }

    func releaseEngine(for context: String) {
        engines.removeValue(forKey: context)  // Deallocated if no other references
    }

    func releaseAll() {
        engines.removeAll()
    }
}
```

**Monitoring memory:**

```swift
// Set memory limits per engine
let limitedEngine = try LuaEngine(configuration: LuaEngineConfiguration(
    sandboxed: true,
    packagePath: nil,
    memoryLimit: 10 * 1024 * 1024  // 10 MB per engine
))

// For multiple engines, consider total memory budget
class MemoryAwareEngineFactory {
    private let maxTotalMemory: Int
    private var engines: [LuaEngine] = []

    init(maxTotalMemory: Int) {
        self.maxTotalMemory = maxTotalMemory
    }

    func createEngine() throws -> LuaEngine {
        let perEngineLimit = maxTotalMemory / max(engines.count + 1, 1)
        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: nil,
            memoryLimit: perEngineLimit
        )
        let engine = try LuaEngine(configuration: config)
        engines.append(engine)
        return engine
    }
}
```

### Use Cases for Multiple Engines

**1. Isolation for untrusted code:**

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

**2. Different configurations per context:**

```swift
// Different module sets for different use cases
let mathEngine = try LuaEngine()
ModuleRegistry.installMathModule(in: mathEngine)
ModuleRegistry.installLinAlgModule(in: mathEngine)
ModuleRegistry.installComplexModule(in: mathEngine)

let dataEngine = try LuaEngine()
ModuleRegistry.installJSONModule(in: dataEngine)
ModuleRegistry.installYAMLModule(in: dataEngine)
ModuleRegistry.installTOMLModule(in: dataEngine)

let fullEngine = try LuaEngine()
ModuleRegistry.installModules(in: fullEngine)  // All modules
```

**3. Parallel script execution:**

```swift
// Run independent scripts in parallel
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

### Engine Pooling Strategies

For high-concurrency scenarios, pools prevent both engine creation overhead and unbounded resource usage.

**Fixed-size pool:**

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

**Elastic pool (grows/shrinks):**

```swift
actor ElasticEnginePool {
    private var available: [LuaEngine] = []
    private let minSize: Int
    private let maxSize: Int
    private var totalCreated: Int = 0

    init(min: Int, max: Int) throws {
        self.minSize = min
        self.maxSize = max

        // Pre-create minimum engines
        for _ in 0..<min {
            let engine = try LuaEngine()
            ModuleRegistry.installModules(in: engine)
            available.append(engine)
            totalCreated += 1
        }
    }

    func acquire() async throws -> LuaEngine {
        if let engine = available.popLast() {
            return engine
        }

        if totalCreated < maxSize {
            let engine = try LuaEngine()
            ModuleRegistry.installModules(in: engine)
            totalCreated += 1
            return engine
        }

        // At max capacity - wait for an engine (simplified)
        try await Task.sleep(nanoseconds: 10_000_000)  // 10ms
        return try await acquire()
    }

    func release(_ engine: LuaEngine) {
        if available.count < minSize {
            available.append(engine)
        } else {
            // Let excess engines deallocate
            totalCreated -= 1
        }
    }
}
```

**Per-thread engine pattern:**

```swift
// One engine per thread - no locking needed within engine
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
- [Yams](https://github.com/jpsim/Yams) - YAML parsing for Swift
- [TOMLKit](https://github.com/LebJe/TOMLKit) - TOML parsing for Swift
- Inspired by various Lua-Swift bridges in the community
