# Compatibility Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.compat`

The Compatibility Module provides Lua version detection and compatibility shims to run code seamlessly across different Lua versions (5.1, 5.2, 5.3, 5.4, 5.5). It restores removed APIs like `bit32`, provides legacy aliases for `unpack`/`loadstring`, and offers feature detection for version-specific capabilities.

## Overview

LuaSwift bundles multiple Lua versions selectable via environment variable. This module ensures code written for one Lua version can run on another without modification. It provides:

- **Version detection** - Boolean flags and version strings for runtime checks
- **Feature detection** - Detect availability of version-specific language features
- **bit32 library** - Full implementation for Lua 5.3+ (removed in 5.4)
- **Legacy aliases** - `unpack`, `loadstring`, `setfenv`, `getfenv`
- **Deprecation checking** - Scan code for deprecated API usage

## Version Detection

Check the current Lua version using boolean flags or version string:

```lua
local compat = require("compat")

if compat.lua54 then
    print("Running on Lua 5.4")
elseif compat.lua55 then
    print("Running on Lua 5.5")
end

print("Lua version: " .. compat.version)  -- "5.4", "5.5", etc.
```

Available version flags:
- `compat.lua51` - Lua 5.1.5
- `compat.lua52` - Lua 5.2.4
- `compat.lua53` - Lua 5.3.6
- `compat.lua54` - Lua 5.4.7 (LuaSwift default)
- `compat.lua55` - Lua 5.5.0
- `compat.luajit` - Running on LuaJIT

## Feature Detection

Check for language features introduced in specific versions:

```lua
local compat = require("compat")

if compat.features.bitwise_ops then
    -- Use &, |, ~, <<, >> operators (5.3+)
    local result = 0xFF & 0x0F
else
    -- Fallback to bit32 or arithmetic
    local result = compat.bit32.band(0xFF, 0x0F)
end

if compat.features.integer_division then
    local quotient = 10 // 3  -- 3 (5.3+)
end

if compat.features.utf8_library then
    local len = utf8.len("hello")
end
```

Available feature flags:
- `table_unpack` - `table.unpack` available (5.2+)
- `table_pack` - `table.pack` available (5.2+)
- `utf8_library` - `utf8` library available (5.3+)
- `math_type` - `math.type` function available (5.3+)
- `integer_division` - `//` operator (5.3+)
- `bitwise_ops` - `&`, `|`, `~`, `<<`, `>>` operators (5.3+)
- `const_close` - `<const>` and `<close>` attributes (5.4+)
- `warn_function` - `warn()` function (5.4+)

## bit32 Library

The `bit32` library was removed in Lua 5.4. This module provides a full implementation across all versions:

- **Lua 5.2** - Uses native `bit32` library
- **Lua 5.3+** - Uses native bitwise operators (`&`, `|`, `~`, `<<`, `>>`)
- **Lua 5.1** - Pure-Lua arithmetic fallback

```lua
local compat = require("compat")

-- All bit32 functions available regardless of version
local result = compat.bit32.band(0xFF, 0x0F)  -- 15
local shifted = compat.bit32.lshift(1, 8)     -- 256
local rotated = compat.bit32.lrotate(0x80000001, 1)  -- 3
local extracted = compat.bit32.extract(0xABCD, 4, 8)  -- 0xBC
```

### Bitwise Operations

```lua
-- Bitwise AND (multiple arguments)
compat.bit32.band(0xFF, 0x0F, 0xF0)  -- 0

-- Bitwise OR
compat.bit32.bor(0x01, 0x02, 0x04)  -- 7

-- Bitwise XOR
compat.bit32.bxor(0xFF, 0x0F)  -- 0xF0

-- Bitwise NOT
compat.bit32.bnot(0xFF)  -- 0xFFFFFF00

-- Test if any bits set
compat.bit32.btest(0xFF, 0x0F)  -- true
```

### Shift Operations

```lua
-- Logical left shift
compat.bit32.lshift(1, 8)  -- 256

-- Logical right shift
compat.bit32.rshift(256, 8)  -- 1

-- Arithmetic right shift (sign-extending)
compat.bit32.arshift(0x80000000, 1)  -- 0xC0000000
```

### Rotation Operations

```lua
-- Left rotate
compat.bit32.lrotate(0x80000001, 1)  -- 3

-- Right rotate
compat.bit32.rrotate(3, 1)  -- 0x80000001
```

### Bit Field Operations

```lua
-- Extract bits [field, field+width)
compat.bit32.extract(0xABCD, 4, 8)  -- 0xBC (bits 4-11)

-- Replace bits [field, field+width) with value
compat.bit32.replace(0xABCD, 0xFF, 4, 8)  -- 0xAFFD
```

## Legacy Aliases

Access functions that moved or were removed in later versions:

```lua
local compat = require("compat")

-- unpack (global in 5.1, table.unpack in 5.2+)
local a, b, c = compat.unpack({1, 2, 3})

-- loadstring (removed in 5.2+, replaced by load)
local fn = compat.loadstring("return 42")
print(fn())  -- 42

-- setfenv/getfenv (removed in 5.2+)
-- Errors on 5.2+ with helpful message
compat.setfenv(fn, {})  -- Error: "setfenv is not supported in Lua 5.2+"
```

## Global Polyfill Installation

Install compatibility shims into the global environment:

```lua
local compat = require("compat")
compat.install()

-- Now bit32, unpack, loadstring are globally available
print(bit32.band(0xFF, 0x0F))  -- 15
local a, b = unpack({1, 2})     -- 1, 2
local fn = loadstring("return 42")
```

**Warning:** `compat.install()` modifies global state. Use cautiously in shared environments.

## Deprecation Checking

Scan code for deprecated API usage:

```lua
local compat = require("compat")

local code = [[
    setfenv(1, {})
    module("mymodule")
    local x = bit32.band(0xFF, 0x0F)
]]

local warnings = compat.check_deprecated(code)
for _, warning in ipairs(warnings) do
    print("Warning: " .. warning)
end

-- Output (on Lua 5.4):
-- Warning: setfenv is not supported in Lua 5.2+
-- Warning: module() is deprecated since Lua 5.2
-- Warning: bit32 was removed in Lua 5.4, use native operators
```

## Version Comparison

Compare version strings and check minimum version requirements:

```lua
local compat = require("compat")

-- Compare two version strings
-- Returns: negative if v1 < v2, 0 if equal, positive if v1 > v2
local cmp = compat.version_compare("5.3", "5.4")  -- -1

-- Check if current version is at least the given version
if compat.version_at_least("5.3") then
    print("Bitwise operators available")
end
```

## Practical Examples

### Cross-Version Bitwise Operations

```lua
local compat = require("compat")

function safe_bitwise_and(a, b)
    if compat.features.bitwise_ops then
        return a & b  -- Native operator (5.3+)
    else
        return compat.bit32.band(a, b)  -- Fallback
    end
end

print(safe_bitwise_and(0xFF, 0x0F))  -- 15
```

### Conditional Feature Usage

```lua
local compat = require("compat")

function process_data(data)
    if compat.features.table_pack then
        -- Use table.pack (5.2+)
        local packed = table.pack(...)
        return packed.n, packed[1]
    else
        -- Fallback for Lua 5.1
        local args = {...}
        return #args, args[1]
    end
end
```

### Legacy Code Migration

```lua
local compat = require("compat")

-- Old code using global unpack
-- local a, b, c = unpack(tbl)

-- Portable version
local a, b, c = compat.unpack(tbl)

-- Or install globally
compat.install()
local a, b, c = unpack(tbl)  -- Works everywhere
```

## Implementation Details

The `bit32` implementation strategy depends on the Lua version:

1. **Lua 5.2**: Uses native `bit32` library directly (fastest)
2. **Lua 5.3+**: Uses `load()` to dynamically create implementation with native bitwise operators (avoids parse errors on older versions)
3. **Lua 5.1**: Pure-Lua arithmetic fallback using bit manipulation via division and modulo

All implementations normalize values to 32-bit unsigned integers (`x % 0x100000000`).

## Function Reference

| Function | Description |
|----------|-------------|
| **Version Detection** | |
| `compat.version` | Current Lua version string (e.g., "5.4") |
| `compat.lua51` | Boolean: running on Lua 5.1 |
| `compat.lua52` | Boolean: running on Lua 5.2 |
| `compat.lua53` | Boolean: running on Lua 5.3 |
| `compat.lua54` | Boolean: running on Lua 5.4 |
| `compat.lua55` | Boolean: running on Lua 5.5 |
| `compat.luajit` | Boolean: running on LuaJIT |
| `compat.features` | Table of feature availability flags |
| **Bitwise Operations** | |
| `compat.bit32.band(...)` | Bitwise AND of all arguments |
| `compat.bit32.bor(...)` | Bitwise OR of all arguments |
| `compat.bit32.bxor(...)` | Bitwise XOR of all arguments |
| `compat.bit32.bnot(x)` | Bitwise NOT (one's complement) |
| `compat.bit32.btest(...)` | True if bitwise AND is non-zero |
| **Shift Operations** | |
| `compat.bit32.lshift(x, disp)` | Logical left shift |
| `compat.bit32.rshift(x, disp)` | Logical right shift |
| `compat.bit32.arshift(x, disp)` | Arithmetic right shift (sign-extend) |
| **Rotation Operations** | |
| `compat.bit32.lrotate(x, disp)` | Left rotate |
| `compat.bit32.rrotate(x, disp)` | Right rotate |
| **Bit Field Operations** | |
| `compat.bit32.extract(n, field, width)` | Extract bit field |
| `compat.bit32.replace(n, v, field, width)` | Replace bit field with value |
| **Legacy Aliases** | |
| `compat.unpack(list)` | Unpack table (global in 5.1, table.unpack in 5.2+) |
| `compat.loadstring(str)` | Load string as function (removed in 5.2+) |
| `compat.setfenv(fn, env)` | Set function environment (errors on 5.2+) |
| `compat.getfenv(fn)` | Get function environment (errors on 5.2+) |
| **Utilities** | |
| `compat.install()` | Install polyfills globally (modifies _G) |
| `compat.check_deprecated(code)` | Return warnings for deprecated API usage |
| `compat.version_compare(v1, v2)` | Compare version strings (-1/0/+1) |
| `compat.version_at_least(v)` | Check if current version ≥ given version |
