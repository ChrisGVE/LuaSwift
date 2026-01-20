# Sandboxing and Security

Control what Lua scripts can access to protect your application and system.

## Overview

LuaSwift includes built-in sandboxing to safely execute untrusted Lua code. By default, dangerous functions that could access the filesystem, execute system commands, or inspect the runtime are disabled.

Understanding sandboxing is essential for:
- Running user-provided scripts safely
- Embedding Lua in applications distributed to end users
- Protecting system resources from malicious or buggy scripts

## Default Sandboxed Mode

When you create a ``LuaEngine`` without specifying a configuration, sandboxing is enabled:

```swift
// Both of these create sandboxed engines
let engine1 = try LuaEngine()
let engine2 = try LuaEngine(configuration: .default)
```

### Disabled Functions

In sandboxed mode, the following functions are removed or restricted:

| Category | Disabled Functions |
|----------|-------------------|
| **OS Operations** | `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv`, `os.setlocale` |
| **File I/O** | Entire `io` library (`io.open`, `io.read`, `io.write`, etc.) |
| **Debug** | Entire `debug` library |
| **Code Loading** | `loadfile`, `dofile`, `load`, `loadstring` |
| **Package System** | `package.loadlib`, `package.cpath`, file-based `package.searchers` |

### Module Loading Restrictions

The sandbox also hardens the `require()` system to prevent bypass attempts:

- `package.loaded.io` and `package.loaded.debug` are cleared, so `require('io')` and `require('debug')` cannot restore disabled libraries
- `package.loadlib` is disabled to prevent dynamic library loading (App Store compliance)
- `package.cpath` is cleared to prevent C library loading
- `package.path` is cleared (unless `packagePath` is configured)
- **Without `packagePath`**: File-based searchers are removed from `package.searchers`, keeping only the preload searcher. This completely prevents loading `.lua` files from disk.
- **With `packagePath`**: File searchers are kept so modules can be loaded from the explicitly allowed directory. Only the configured path is searchable.

This ensures that even if a script attempts `require('io')`, it will fail rather than restoring the disabled library.

### Available Safe Libraries

These standard libraries remain fully functional in sandboxed mode:

- **math** - Mathematical functions (`sin`, `cos`, `sqrt`, `random`, etc.)
- **string** - String manipulation (`sub`, `find`, `gsub`, `format`, etc.)
- **table** - Table operations (`insert`, `remove`, `sort`, `concat`, etc.)
- **coroutine** - Coroutine support (`create`, `resume`, `yield`, etc.)
- **utf8** - UTF-8 string operations
- **os.time**, **os.date**, **os.difftime**, **os.clock** - Safe time functions

### What Scripts Cannot Do in Sandboxed Mode

```lua
-- All of these will fail with "attempt to call nil value"

-- Cannot execute system commands
os.execute("rm -rf /")        -- nil, no such function

-- Cannot read/write files
local f = io.open("secret.txt", "r")  -- nil, io is nil

-- Cannot inspect stack or internals
debug.getinfo(1)              -- nil, debug is nil

-- Cannot load external files
dofile("malicious.lua")       -- nil, no such function
loadfile("hack.lua")          -- nil, no such function

-- Cannot dynamically compile code
load("return os.execute('...')")  -- nil, no such function
```

### What Scripts CAN Do in Sandboxed Mode

```lua
-- Math operations work normally
local result = math.sin(math.pi / 2)  -- 1.0
local random = math.random(1, 100)    -- Random number

-- String operations work
local upper = string.upper("hello")   -- "HELLO"
local found = string.find("hello world", "world")  -- 7

-- Table operations work
local t = {3, 1, 4, 1, 5}
table.sort(t)                         -- {1, 1, 3, 4, 5}

-- Safe OS functions work
local now = os.time()                 -- Current timestamp
local date = os.date("%Y-%m-%d")      -- "2024-01-15"

-- Coroutines work
local co = coroutine.create(function()
    coroutine.yield(1)
    coroutine.yield(2)
    return 3
end)
```

## Unrestricted Mode

For trusted scripts that need full system access, use unrestricted mode:

```swift
let engine = try LuaEngine(configuration: .unrestricted)
```

> Warning: Only use unrestricted mode with code you fully trust. It allows arbitrary file access and system command execution.

### Full Access in Unrestricted Mode

```lua
-- File operations work
local f = io.open("data.txt", "w")
f:write("Hello, World!")
f:close()

-- System commands work
os.execute("ls -la")

-- Environment variables accessible
local home = os.getenv("HOME")

-- Dynamic code loading works
dofile("script.lua")
local chunk = loadfile("module.lua")
```

## Custom Configurations

Create custom configurations for specific needs:

```swift
// Sandboxed with custom module path
let config = LuaEngineConfiguration(
    sandboxed: true,
    packagePath: "/app/Resources/Lua",
    memoryLimit: 0
)
let engine = try LuaEngine(configuration: config)
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sandboxed` | `Bool` | `true` | Disable dangerous functions |
| `packagePath` | `String?` | `nil` | Custom path for `require()` |
| `memoryLimit` | `Int` | `0` | Memory limit for Swift modules in bytes (0 = unlimited) |

> Note: The `memoryLimit` option only limits memory allocated by Swift-backed modules (array, linalg, plot, etc.). Lua VM allocations (strings, tables, coroutines) are not tracked by this limit.

### Setting Package Path

The `packagePath` option allows Lua's `require()` to find modules in a custom directory:

```swift
let config = LuaEngineConfiguration(
    sandboxed: true,
    packagePath: Bundle.main.resourcePath! + "/Lua",
    memoryLimit: 0
)
let engine = try LuaEngine(configuration: config)
```

```lua
-- Now require() can find modules in your app bundle
local utils = require("utils")  -- Loads Lua/utils.lua
```

> Warning: **Security consideration**: Never set `packagePath` to a writable directory (such as Documents or Caches) when running untrusted Lua code. Doing so would allow malicious scripts to execute downloaded code via `require()`, which violates App Store guidelines 2.5.2. Only use `packagePath` with read-only directories like your app bundle resources.

## Loading Bundled Lua Modules

LuaSwift includes pure Lua modules (`compat.lua` and `serialize.lua`) that are bundled as SPM resources. This section explains how to access these modules in different contexts.

### How SPM Bundles Resources

LuaSwift's `Package.swift` includes the LuaModules directory as a copy resource:

```swift
resources: [
    .copy("LuaModules")
]
```

This means SPM copies the `LuaModules` folder into the resource bundle, making the Lua files available at runtime.

### Accessing Bundled Modules in Framework/Library Context

When using LuaSwift as a package dependency in your Swift code (including tests and library code), use `Bundle.module`:

```swift
import LuaSwift

// Access the LuaSwift package's bundled modules
if let luaModulesPath = Bundle.module.resourcePath.map({ $0 + "/LuaModules" }) {
    let config = LuaEngineConfiguration(
        sandboxed: true,
        packagePath: luaModulesPath,
        memoryLimit: 0
    )
    let engine = try LuaEngine(configuration: config)

    // Now require() finds the bundled modules
    try engine.run("""
        local compat = require("compat")
        local serialize = require("serialize")
    """)
}
```

> Note: `Bundle.module` is a synthesized accessor created by SPM for packages with resources. It refers to the bundle containing the package's resources, not the main application bundle.

### Accessing Bundled Modules in Application Context

When building an iOS/macOS application that embeds LuaSwift, the approach depends on how your app is structured:

**Option 1: Using Bundle.module (Recommended)**

If your app imports LuaSwift as a package, `Bundle.module` continues to work because SPM handles resource bundling automatically:

```swift
import LuaSwift

class LuaScriptRunner {
    let engine: LuaEngine

    init() throws {
        // Bundle.module finds LuaSwift's bundled resources
        let luaModulesPath = Bundle.module.resourcePath! + "/LuaModules"

        let config = LuaEngineConfiguration(
            sandboxed: true,
            packagePath: luaModulesPath,
            memoryLimit: 0
        )
        engine = try LuaEngine(configuration: config)
    }
}
```

**Option 2: Copying Modules to Your App Bundle**

If you want to include your own Lua modules alongside LuaSwift's, copy them to your app's resource bundle and use `Bundle.main`:

```swift
// In your app target
if let luaPath = Bundle.main.resourcePath?.appending("/Lua") {
    let config = LuaEngineConfiguration(
        sandboxed: true,
        packagePath: luaPath,
        memoryLimit: 0
    )
    let engine = try LuaEngine(configuration: config)
}
```

For this approach, add your Lua files to your Xcode project and ensure they're included in the "Copy Bundle Resources" build phase.

### Platform-Specific Considerations

#### iOS, watchOS, tvOS, visionOS

Bundle paths work the same across all Apple platforms. The main difference is that app bundles on iOS-family platforms are read-only, making them safe for `packagePath`.

#### macOS

On macOS, be aware that:
- App bundles are typically in `/Applications` (read-only for users)
- Development builds may be in writable locations
- Command-line tools don't have bundles; use explicit paths instead

```swift
// For macOS command-line tools, use explicit paths
let config = LuaEngineConfiguration(
    sandboxed: true,
    packagePath: "/usr/local/share/myapp/lua",
    memoryLimit: 0
)
```

### Loading Multiple Module Paths

Lua's `package.path` supports multiple search paths separated by semicolons. You can configure this manually after creating the engine:

```swift
let engine = try LuaEngine()

// Add multiple search paths
try engine.run("""
    package.path = package.path .. ";/path/to/modules1/?.lua"
    package.path = package.path .. ";/path/to/modules2/?.lua"
""")
```

> Warning: Only add paths to read-only directories when running untrusted code.

### Verifying Module Loading

Test that bundled modules load correctly:

```swift
func testBundledModulesLoad() throws {
    guard let luaModulesPath = Bundle.module.resourcePath.map({ $0 + "/LuaModules" }) else {
        XCTFail("Could not find LuaModules resource path")
        return
    }

    let config = LuaEngineConfiguration(
        sandboxed: true,
        packagePath: luaModulesPath,
        memoryLimit: 0
    )
    let engine = try LuaEngine(configuration: config)

    // Verify compat module loads
    let version = try engine.evaluate("""
        local compat = require("compat")
        return compat.version
    """)
    XCTAssertNotNil(version.stringValue)

    // Verify serialize module loads
    let encoded = try engine.evaluate("""
        local serialize = require("serialize")
        return serialize.encode({test = true})
    """)
    XCTAssertTrue(encoded.stringValue?.contains("test") == true)
}
```

## Security Best Practices

### 1. Always Use Sandboxed Mode for Untrusted Code

```swift
// Good: Sandboxed by default
let engine = try LuaEngine()

// Bad: Don't do this for user-provided scripts
let engine = try LuaEngine(configuration: .unrestricted)
```

### 2. Validate Callback Inputs

When registering Swift callbacks, validate all inputs from Lua:

```swift
engine.registerFunction(name: "processData") { args in
    guard let input = args.first?.stringValue else {
        throw LuaError.callbackError("Expected string")
    }

    // Validate input before processing
    guard input.count < 10000 else {
        throw LuaError.callbackError("Input too large")
    }

    // Safe to process...
    return .bool(true)
}
```

### 3. Limit Script Execution Time

Implement timeouts for potentially long-running scripts:

```swift
class TimeLimitedEngine {
    private let engine: LuaEngine
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 5.0) throws {
        self.engine = try LuaEngine()
        self.timeout = timeout
    }

    func evaluate(_ code: String) async throws -> LuaValue {
        return try await withThrowingTaskGroup(of: LuaValue.self) { group in
            group.addTask {
                return try self.engine.evaluate(code)
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(self.timeout * 1_000_000_000))
                throw LuaError.runtimeError("Script timeout")
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
```

### 4. Be Careful with Value Servers

When exposing data via ``LuaValueServer``, only expose what's necessary:

```swift
class SafeDataServer: LuaValueServer {
    let namespace = "Data"
    private let secrets = ["apiKey": "secret123"]  // Don't expose!
    private let publicData = ["appVersion": "1.0"]

    func resolve(path: [String]) -> LuaValue {
        // Only expose public data
        if let key = path.first, let value = publicData[key] {
            return .string(value)
        }
        return .nil  // Don't reveal that secrets exist
    }
}
```

### 5. Audit Registered Callbacks

Review all registered callbacks for potential security issues:

```swift
// BAD: Exposes file system
engine.registerFunction(name: "readFile") { args in
    guard let path = args.first?.stringValue else { return .nil }
    return .string(try! String(contentsOfFile: path))  // Dangerous!
}

// GOOD: Only read from allowed directory
engine.registerFunction(name: "readConfig") { args in
    guard let name = args.first?.stringValue else { return .nil }

    // Sanitize filename
    let safeName = name.replacingOccurrences(of: "/", with: "")
                       .replacingOccurrences(of: "..", with: "")

    // Only allow reading from config directory
    let path = "/app/config/\(safeName).json"
    guard FileManager.default.fileExists(atPath: path) else {
        return .nil
    }

    return .string(try! String(contentsOfFile: path))
}
```

## Built-in Module Security

LuaSwift's built-in modules (JSON, Regex, Math, etc.) are designed to be safe:

- They don't access the filesystem
- They don't execute system commands
- They process data in memory only
- They validate inputs to prevent crashes

```swift
// Install all modules safely
ModuleRegistry.installModules(in: engine)
```

```lua
-- All module operations are safe
local json = require("luaswift.json")
local data = json.decode('{"key": "value"}')  -- Safe

local regex = require("luaswift.regex")
local matches = regex.match("hello", "[a-z]+")  -- Safe
```

## Detecting Sandbox Violations

Sandbox violations appear as Lua runtime errors:

```swift
do {
    try engine.evaluate("os.execute('whoami')")
} catch let error as LuaError {
    switch error {
    case .runtimeError(let message):
        if message.contains("nil") {
            print("Attempted to call disabled function")
        }
    default:
        break
    }
}
```

## Multiple Engine Isolation

Each ``LuaEngine`` instance is completely isolated:

```swift
let trustedEngine = try LuaEngine(configuration: .unrestricted)
let untrustedEngine = try LuaEngine()  // Sandboxed

// Code in one engine cannot access the other
// Globals, functions, and state are not shared
```

## See Also

- ``LuaEngineConfiguration``
- ``LuaEngine/init(configuration:)``
- ``LuaError``
- <doc:ValueServers>
- <doc:SwiftCallbacks>
