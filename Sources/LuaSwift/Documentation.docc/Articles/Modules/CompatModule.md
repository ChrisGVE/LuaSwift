# Compat Module

Lua version compatibility utilities and polyfills.

## Overview

The Compat module provides version detection and compatibility shims for running code across different Lua versions (5.1, 5.2, 5.3, 5.4, 5.5). It includes a portable `bit32` library implementation, legacy function aliases, and version comparison utilities.

## Installation

The compat module is a pure Lua module bundled with LuaSwift. Load it directly:

```lua
local compat = require("compat")
```

## Basic Usage

```lua
local compat = require("compat")

-- Check current Lua version
print(compat.version)  -- "5.4"

-- Version flags
if compat.lua54 then
    print("Running on Lua 5.4")
end

-- Use bit32 operations (available on all versions)
local result = compat.bit32.band(0xFF, 0x0F)  -- 15

-- Install polyfills globally
compat.install()
```

## API Reference

### Version Detection

#### version

The current Lua version as a string (e.g., "5.4").

#### lua51, lua52, lua53, lua54, lua55

Boolean flags indicating the current Lua version.

```lua
if compat.lua51 then
    print("Running Lua 5.1")
elseif compat.lua54 then
    print("Running Lua 5.4")
end
```

#### luajit

Boolean indicating if running on LuaJIT.

```lua
if compat.luajit then
    print("Running on LuaJIT")
end
```

### Feature Detection

#### features

Table containing feature availability flags:

| Feature | Description | Available |
|---------|-------------|-----------|
| `table_unpack` | `table.unpack` function | 5.2+ |
| `table_pack` | `table.pack` function | 5.2+ |
| `utf8_library` | `utf8` standard library | 5.3+ |
| `math_type` | `math.type` function | 5.3+ |
| `integer_division` | `//` operator | 5.3+ |
| `bitwise_ops` | `&`, `\|`, `~`, `<<`, `>>` operators | 5.3+ |
| `const_close` | `<const>` and `<close>` attributes | 5.4+ |
| `warn_function` | `warn()` function | 5.4+ |

**Example:**

```lua
if compat.features.utf8_library then
    -- Use utf8.len() directly
    local len = utf8.len("héllo")
else
    -- Use alternative approach
end
```

### bit32 Library

#### bit32

A portable bit32 library implementation that works on all Lua versions:
- Lua 5.2: Uses native `bit32` library
- Lua 5.3+: Uses native bitwise operators
- Lua 5.1: Uses pure-Lua arithmetic fallback

**Functions:**

| Function | Description |
|----------|-------------|
| `band(...)` | Bitwise AND |
| `bor(...)` | Bitwise OR |
| `bxor(...)` | Bitwise XOR |
| `bnot(x)` | Bitwise NOT |
| `lshift(x, disp)` | Logical left shift |
| `rshift(x, disp)` | Logical right shift |
| `arshift(x, disp)` | Arithmetic right shift |
| `lrotate(x, disp)` | Left rotate |
| `rrotate(x, disp)` | Right rotate |
| `btest(...)` | Test if AND is non-zero |
| `extract(n, field, width)` | Extract bits |
| `replace(n, v, field, width)` | Replace bits |

**Example:**

```lua
local bit32 = compat.bit32

local mask = bit32.band(0xFF, 0x0F)        -- 15
local flags = bit32.bor(0x01, 0x02, 0x04)  -- 7
local inverted = bit32.bnot(0)             -- 4294967295
local shifted = bit32.lshift(1, 8)         -- 256
local rotated = bit32.lrotate(0x80000001, 1) -- 3

-- Extract 4 bits starting at position 4
local nibble = bit32.extract(0xABCD, 4, 4)  -- 12 (0xC)

-- Replace 4 bits starting at position 4
local replaced = bit32.replace(0xABCD, 0xF, 4, 4)  -- 0xABFD
```

### Legacy Aliases

#### unpack

Alias for `table.unpack` (moved from global in 5.2+).

```lua
local a, b, c = compat.unpack({1, 2, 3})
```

#### loadstring

Alias for `load` (renamed in 5.2+).

```lua
local fn = compat.loadstring("return 42")
print(fn())  -- 42
```

#### setfenv / getfenv

Throws an error in Lua 5.2+ (these functions were removed).

### Version Utilities

#### version_compare(v1, v2)

Compare two version strings.

**Parameters:**
- `v1` - First version string (e.g., "5.3")
- `v2` - Second version string (e.g., "5.4")

**Returns:** Negative if v1 < v2, zero if equal, positive if v1 > v2

**Example:**

```lua
local cmp = compat.version_compare("5.3", "5.4")  -- negative
local cmp2 = compat.version_compare("5.4", "5.4") -- 0
```

#### version_at_least(v)

Check if the current Lua version is at least the given version.

**Parameters:**
- `v` - Version string to compare against

**Returns:** `true` if current version >= v

**Example:**

```lua
if compat.version_at_least("5.3") then
    -- Use Lua 5.3+ features
end
```

### Global Installation

#### install()

Install compatibility polyfills into the global environment.

**Effects:**
- Adds `bit32` globally if not present
- Adds global `unpack` if not present (5.1 compatibility)
- Adds global `loadstring` if not present

**Returns:** The compat module itself (for chaining)

**Example:**

```lua
require("compat").install()

-- Now these work on all versions
local result = bit32.band(0xFF, 0x0F)
local a, b = unpack({1, 2})
local fn = loadstring("return 42")
```

### Deprecation Checking

#### check_deprecated(code)

Check Lua code for deprecated features.

**Parameters:**
- `code` - String containing Lua source code

**Returns:** Array of warning messages

**Example:**

```lua
local code = [[
    setfenv(1, {})
    module("mymod", package.seeall)
]]

local warnings = compat.check_deprecated(code)
for _, warning in ipairs(warnings) do
    print("Warning: " .. warning)
end
-- Warning: setfenv is not supported in Lua 5.2+
-- Warning: module() is deprecated since Lua 5.2
```

## Common Patterns

### Writing Version-Portable Code

```lua
local compat = require("compat")

-- Use compat.unpack for portability
local function apply(fn, args)
    return fn(compat.unpack(args))
end

-- Check features before using
local function get_string_length(s)
    if compat.features.utf8_library then
        return utf8.len(s)
    else
        -- Fallback for 5.1/5.2
        return #s
    end
end
```

### Bitwise Operations Across Versions

```lua
local compat = require("compat")
local bit32 = compat.bit32

-- These work on Lua 5.1 through 5.5
local function set_flag(value, bit)
    return bit32.bor(value, bit32.lshift(1, bit))
end

local function clear_flag(value, bit)
    return bit32.band(value, bit32.bnot(bit32.lshift(1, bit)))
end

local function test_flag(value, bit)
    return bit32.btest(value, bit32.lshift(1, bit))
end
```

### Conditional Feature Usage

```lua
local compat = require("compat")

if compat.features.const_close then
    -- Lua 5.4+ with to-be-closed variables
    print("Can use <close> attribute")
else
    -- Manual resource management
    print("Using manual cleanup")
end
```

## See Also

- <doc:SerializeModule>
