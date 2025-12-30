# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run a specific test
swift test --filter LuaEngineTests/testValueServerWrite

# Run tests for a specific test class
swift test --filter LuaEngineTests

# Build for release
swift build -c release
```

## Project Architecture

LuaSwift is a Swift wrapper around Lua 5.4.7 for iOS/macOS. It bundles the complete Lua C source for App Store compliance (no external dependencies or downloaded code).

### Module Structure

```
Sources/
├── CLua/           # Lua 5.4.7 C source (MIT licensed)
│   ├── *.c         # 31 C implementation files
│   └── include/    # 27 header files + module.modulemap
└── LuaSwift/       # Swift wrapper layer
    ├── LuaEngine.swift      # Main API: run(), evaluate(), register()
    ├── LuaValue.swift       # Type-safe enum for Lua values
    ├── LuaValueServer.swift # Protocol for exposing Swift data to Lua
    ├── LuaError.swift       # Error types
    └── LuaHelpers.swift     # Swift wrappers for Lua C macros
```

### Core Concepts

**LuaEngine**: Thread-safe wrapper managing the Lua state. Key methods:
- `run(_:)` - Execute Lua code, discard return value
- `evaluate(_:)` - Execute Lua code, return `LuaValue`
- `register(server:)` - Register a value server for Lua access
- `registerFunction(name:callback:)` - Register Swift function callable from Lua
- `unregisterFunction(name:)` - Remove registered function

**LuaValue**: Enum representing all Lua types (`string`, `number`, `bool`, `table`, `array`, `nil`). Supports Swift literals and provides convenience accessors (`.numberValue`, `.stringValue`, etc.).

**LuaValueServer**: Protocol for exposing Swift data to Lua scripts. Supports both read and write access:
- `resolve(path:)` - Return value for a path (required)
- `canWrite(path:)` - Check if path is writable (default: false)
- `write(path:value:)` - Handle writes (default: throws)

**Important**: For write support, `resolve()` must return `.nil` for intermediate paths so proxy tables with metamethods are created.

**Swift Callbacks**: Register Swift functions that Lua can call directly:
- Callbacks receive `[LuaValue]` arguments and return `LuaValue`
- Can throw errors that propagate to Lua
- Stored in thread-safe dictionary
- Use `lua_pushcclosure` with upvalues for engine pointer and function name

### C Interop Pattern

LuaHelpers.swift provides Swift wrappers for Lua C macros that Swift cannot import directly (e.g., `lua_pop`, `lua_newtable`, `lua_pcall`). These are marked `@inline(__always)` for performance.

The engine uses Lua metamethods (`__index`/`__newindex`) via C callbacks (`serverIndexCallback`/`serverNewIndexCallback`) to intercept value server access. Swift callbacks use `callbackTrampoline` C function. Engine pointer is stored in metatables/upvalues via `lua_pushlightuserdata`.

### Sandboxing

Default configuration removes dangerous functions:
- `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv`, `os.setlocale`
- `io.*`, `debug.*`
- `loadfile`, `dofile`, `load`, `loadstring`

Safe libraries remain: `math`, `string`, `table`, `coroutine`, `utf8`

### Thread Safety

`LuaEngine` uses `NSLock` for all public methods. For high concurrency, use engine pools rather than sharing a single instance.
