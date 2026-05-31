# Debug Module

Logging and console debugging utilities for Lua scripts (DEBUG builds only).

## Overview

The Debug module provides structured logging and console debugging tools for Lua scripts running inside a `LuaEngine`. It exposes two sub-tables — `log` for levelled, timestamped log output and `console` for interactive debugging tasks such as value inspection, stack traces, and performance timing.

> Important: This module is compiled only in `DEBUG` builds (`#if DEBUG`). It is completely absent from release binaries. Any Lua code that `require`s it must guard against the module being unavailable in release builds.

## Installation

```swift
// Install all modules (includes DebugModule in DEBUG builds)
ModuleRegistry.installModules(in: engine)

// Or install just the Debug module
ModuleRegistry.installDebugModule(in: engine)
```

## Accessing the Module

After installation the module is available three ways:

```lua
-- 1. Via require
local dbg = require("luaswift.debug")

-- 2. Via the luaswift namespace (always available after installation)
local dbg = luaswift.debug

-- 3. Via the top-level global alias (avoids collision with Lua's built-in debug table)
local dbg = debug_module
```

All three references point to the same table.

## API Reference

### log sub-table

The `log` sub-table writes timestamped, levelled messages to `stdout` and to the system log (`os_log`) using the subsystem `com.luaswift`, category `lua-script`.

#### log.debug(message)

Logs a message at DEBUG level.

**Parameters:**
- `message` (string) — The message to log

```lua
dbg.log.debug("Entering loop iteration 42")
```

#### log.info(message)

Logs a message at INFO level.

**Parameters:**
- `message` (string) — The message to log

```lua
dbg.log.info("Script initialised successfully")
```

#### log.warn(message)

Logs a message at WARN level.

**Parameters:**
- `message` (string) — The message to log

```lua
dbg.log.warn("Cache miss for key: user_profile")
```

#### log.error(message)

Logs a message at ERROR level.

**Parameters:**
- `message` (string) — The message to log

```lua
dbg.log.error("Failed to open file: config.json")
```

#### log.setLevel(level)

Sets the minimum log level. Messages below the threshold are silently discarded.

**Parameters:**
- `level` (string) — One of `"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`, or `"OFF"` (case-insensitive)

**Severity order:** `DEBUG` < `INFO` < `WARN` < `ERROR` < `OFF`

```lua
-- Suppress DEBUG messages; show INFO and above
dbg.log.setLevel("INFO")

dbg.log.debug("This is suppressed")   -- not printed
dbg.log.info("This is printed")       -- printed
```

### console sub-table

The `console` sub-table provides interactive debugging helpers modelled on the browser console API.

#### console.print(...)

Prints all arguments to `stdout`, separated by tabs.

**Parameters:**
- `...` — Any number of Lua values

```lua
dbg.console.print("x =", 42, "active =", true)
-- x =    42    active =    true
```

#### console.inspect(value)

Pretty-prints a Lua value with full recursive structure up to a depth of 10.

**Parameters:**
- `value` — Any Lua value

```lua
local data = {name = "Alice", scores = {95, 87, 92}}
dbg.console.inspect(data)
-- {
--   name = "Alice"
--   scores = [
--     [0] = 95
--     [1] = 87
--     [2] = 92
--   ]
-- }
```

#### console.trace()

Prints the current Swift call stack to `stdout`. Useful for understanding which Swift frames are active when a Lua callback fires.

```lua
dbg.console.trace()
```

#### console.time(label)

Starts a named performance timer. Timers are stored thread-safely; multiple timers with distinct labels may run concurrently.

**Parameters:**
- `label` (string) — A unique name for this timer

```lua
dbg.console.time("render")
```

#### console.timeEnd(label)

Stops the named timer and prints the elapsed time in milliseconds. The timer is removed after this call. Prints a warning if the label was never started.

**Parameters:**
- `label` (string) — The name passed to `console.time`

```lua
dbg.console.time("render")
-- ... work ...
dbg.console.timeEnd("render")
-- render: 12.345ms
```

#### console.assert(condition, message?)

Checks `condition`. If it is falsy, prints `"Assertion failed: <message>"` together with the current Swift call stack. Does nothing when the condition is truthy.

**Parameters:**
- `condition` (boolean) — The value to test
- `message` (string, optional) — Description shown on failure (default: `"Assertion failed"`)

```lua
local x = -1
dbg.console.assert(x > 0, "x must be positive")
-- Assertion failed: x must be positive
-- (Swift call stack follows)
```

## Complete Example

```lua
local dbg = require("luaswift.debug")

-- Configure log level
dbg.log.setLevel("INFO")

-- Log application flow
dbg.log.info("Starting computation")

-- Time a block of work
dbg.console.time("sum")
local total = 0
for i = 1, 100000 do
    total = total + i
end
dbg.console.timeEnd("sum")       -- e.g. "sum: 3.210ms"

-- Inspect a result
dbg.console.inspect({total = total, iterations = 100000})

-- Guard invariants
dbg.console.assert(total > 0, "total must be positive")

dbg.log.info("Computation complete")
```

## Log Output Format

Each log call produces a line of the form:

```
[2026-05-31T08:00:00Z] [INFO] Your message here
```

The same line is forwarded to the system log (`os_log`) with the matching `OSLogType`:

| Level | OSLogType |
|-------|-----------|
| DEBUG | `.debug` |
| INFO | `.info` |
| WARN | `.default` |
| ERROR | `.error` |

## Release Build Behaviour

In release builds (`#if DEBUG` is false) the `DebugModule` type does not exist. `ModuleRegistry.installModules` skips registration. Any Lua code that calls `require("luaswift.debug")` will receive an error. Guard usage accordingly:

```lua
local ok, dbg = pcall(require, "luaswift.debug")
if ok then
    dbg.log.debug("Debug module available")
end
```

## See Also

- ``DebugModule``
- <doc:TypesModule>
