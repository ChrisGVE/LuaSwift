# ``LuaSwift``

A type-safe Swift wrapper around Lua 5.x for iOS and macOS.

## Overview

LuaSwift provides a modern Swift interface to the Lua scripting language, enabling you to embed Lua scripts in your iOS and macOS applications. The library bundles Lua C source directly for App Store compliance - no external dependencies or downloaded code.

### Key Features

- **Type-Safe API**: All Lua values are represented as Swift enums with convenient accessors
- **Full Lua 5.x Support**: Works with Lua 5.1, 5.2, 5.3, 5.4, and 5.5
- **Thread-Safe**: Built-in synchronization for safe concurrent access
- **Sandboxed by Default**: Dangerous functions (IO, OS, debug) are disabled
- **Swift Callbacks**: Register Swift functions callable from Lua
- **Value Servers**: Expose Swift data structures to Lua scripts
- **Rich Module Library**: JSON, YAML, TOML, Regex, Linear Algebra, Geometry, and more

### Quick Example

```swift
import LuaSwift

// Create an engine and run Lua code
let engine = try LuaEngine()
let result = try engine.evaluate("return 2 + 2")
print(result.numberValue!) // 4

// Register a Swift callback
engine.registerFunction(name: "greet") { args in
    guard let name = args.first?.stringValue else {
        return .nil
    }
    return .string("Hello, \(name)!")
}

try engine.run("""
    print(greet("World"))  -- Hello, World!
""")
```

## Topics

### Essentials

- <doc:GettingStarted>
- ``LuaEngine``
- ``LuaValue``

### Data Exchange

- <doc:ValueServers>
- <doc:SwiftCallbacks>
- ``LuaValueServer``
- ``LuaError``

### Security

- <doc:Sandboxing>
- ``LuaEngineConfiguration``

### Built-in Modules

- ``ModuleRegistry``

### Data Formats

- <doc:JSONModule>
- <doc:YAMLModule>
- <doc:TOMLModule>

### Text Processing

- <doc:RegexModule>
- <doc:StringXModule>
- <doc:UTF8XModule>
- <doc:TableXModule>

### Mathematics

- <doc:MathXModule>
- <doc:LinAlgModule>
- <doc:ArrayModule>
- <doc:ComplexModule>

### Graphics and Geometry

- <doc:GeometryModule>
- ``SVGModule``

### Utilities

- ``TypesModule``
- ``MathExprModule``
