# Compatibility Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.compat`

The Compatibility Module provides Lua version detection and compatibility shims to run code seamlessly across different Lua versions (5.1, 5.2, 5.3, 5.4, 5.5). It restores removed APIs like `bit32`, provides legacy aliases for `unpack`/`loadstring`, and offers feature detection for version-specific capabilities.

## Function Reference

| Function | Description |
|----------|-------------|
| [version](#version) | Current Lua version string |
| [lua51](#lua51) | Boolean: running on Lua 5.1 |
| [lua52](#lua52) | Boolean: running on Lua 5.2 |
| [lua53](#lua53) | Boolean: running on Lua 5.3 |
| [lua54](#lua54) | Boolean: running on Lua 5.4 |
| [lua55](#lua55) | Boolean: running on Lua 5.5 |
| [luajit](#luajit) | Boolean: running on LuaJIT |
| [features](#features) | Table of feature availability flags |
| [bit32.band(...)](#bit32band) | Bitwise AND of all arguments |
| [bit32.bor(...)](#bit32bor) | Bitwise OR of all arguments |
| [bit32.bxor(...)](#bit32bxor) | Bitwise XOR of all arguments |
| [bit32.bnot(x)](#bit32bnot) | Bitwise NOT (one's complement) |
| [bit32.btest(...)](#bit32btest) | True if bitwise AND is non-zero |
| [bit32.lshift(x, disp)](#bit32lshift) | Logical left shift |
| [bit32.rshift(x, disp)](#bit32rshift) | Logical right shift |
| [bit32.arshift(x, disp)](#bit32arshift) | Arithmetic right shift (sign-extend) |
| [bit32.lrotate(x, disp)](#bit32lrotate) | Left rotate |
| [bit32.rrotate(x, disp)](#bit32rrotate) | Right rotate |
| [bit32.extract(n, field, width)](#bit32extract) | Extract bit field |
| [bit32.replace(n, v, field, width)](#bit32replace) | Replace bit field with value |
| [unpack(list)](#unpack) | Unpack table (global in 5.1, table.unpack in 5.2+) |
| [loadstring(str)](#loadstring) | Load string as function (removed in 5.2+) |
| [setfenv(fn, env)](#setfenv) | Set function environment (errors on 5.2+) |
| [getfenv(fn)](#getfenv) | Get function environment (errors on 5.2+) |
| [install()](#install) | Install polyfills globally (modifies _G) |
| [check_deprecated(code)](#check_deprecated) | Return warnings for deprecated API usage |
| [version_compare(v1, v2)](#version_compare) | Compare version strings (-1/0/+1) |
| [version_at_least(v)](#version_at_least) | Check if current version ≥ given version |

---

## version

Current Lua version string (e.g., "5.4", "5.5").

```lua
local compat = require("compat")
print("Lua version: " .. compat.version)  -- "5.4", "5.5", etc.
```

---

## lua51

Boolean flag indicating if running on Lua 5.1.5.

```lua
local compat = require("compat")
if compat.lua51 then
    print("Running on Lua 5.1")
end
```

---

## lua52

Boolean flag indicating if running on Lua 5.2.4.

```lua
local compat = require("compat")
if compat.lua52 then
    print("Running on Lua 5.2")
end
```

---

## lua53

Boolean flag indicating if running on Lua 5.3.6.

```lua
local compat = require("compat")
if compat.lua53 then
    print("Running on Lua 5.3")
end
```

---

## lua54

Boolean flag indicating if running on Lua 5.4.7 (LuaSwift default).

```lua
local compat = require("compat")
if compat.lua54 then
    print("Running on Lua 5.4")
end
```

---

## lua55

Boolean flag indicating if running on Lua 5.5.0.

```lua
local compat = require("compat")
if compat.lua55 then
    print("Running on Lua 5.5")
end
```

---

## luajit

Boolean flag indicating if running on LuaJIT.

```lua
local compat = require("compat")
if compat.luajit then
    print("Running on LuaJIT")
end
```

---

## features

Table of feature availability flags for version-specific language features.

**Available flags:**
- `table_unpack` - `table.unpack` available (5.2+)
- `table_pack` - `table.pack` available (5.2+)
- `utf8_library` - `utf8` library available (5.3+)
- `math_type` - `math.type` function available (5.3+)
- `integer_division` - `//` operator (5.3+)
- `bitwise_ops` - `&`, `|`, `~`, `<<`, `>>` operators (5.3+)
- `const_close` - `<const>` and `<close>` attributes (5.4+)
- `warn_function` - `warn()` function (5.4+)

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

---

## bit32.band

```
compat.bit32.band(...) -> number
```

Bitwise AND of all arguments. Returns the bitwise AND of all provided numbers, normalized to 32-bit unsigned integers.

**Parameters:**
- `...` - One or more numbers to AND together

```lua
local compat = require("compat")

-- Single argument
local result = compat.bit32.band(0xFF)  -- 255

-- Multiple arguments
local result = compat.bit32.band(0xFF, 0x0F, 0xF0)  -- 0
local result = compat.bit32.band(0xFF, 0x0F)  -- 15
```

---

## bit32.bor

```
compat.bit32.bor(...) -> number
```

Bitwise OR of all arguments. Returns the bitwise OR of all provided numbers, normalized to 32-bit unsigned integers.

**Parameters:**
- `...` - One or more numbers to OR together

```lua
local compat = require("compat")

local result = compat.bit32.bor(0x01, 0x02, 0x04)  -- 7
local result = compat.bit32.bor(0x0F, 0xF0)  -- 255
```

---

## bit32.bxor

```
compat.bit32.bxor(...) -> number
```

Bitwise XOR of all arguments. Returns the bitwise XOR of all provided numbers, normalized to 32-bit unsigned integers.

**Parameters:**
- `...` - One or more numbers to XOR together

```lua
local compat = require("compat")

local result = compat.bit32.bxor(0xFF, 0x0F)  -- 0xF0 (240)
local result = compat.bit32.bxor(0xFF, 0xFF)  -- 0
```

---

## bit32.bnot

```
compat.bit32.bnot(x) -> number
```

Bitwise NOT (one's complement). Returns the bitwise NOT of the provided number, normalized to 32-bit unsigned integers.

**Parameters:**
- `x` - Number to invert

```lua
local compat = require("compat")

local result = compat.bit32.bnot(0xFF)  -- 0xFFFFFF00
local result = compat.bit32.bnot(0)  -- 0xFFFFFFFF
```

---

## bit32.btest

```
compat.bit32.btest(...) -> boolean
```

Returns true if the bitwise AND of all arguments is non-zero.

**Parameters:**
- `...` - One or more numbers to test

```lua
local compat = require("compat")

local result = compat.bit32.btest(0xFF, 0x0F)  -- true
local result = compat.bit32.btest(0xFF, 0x00)  -- false
local result = compat.bit32.btest(0x01, 0x02)  -- false
```

---

## bit32.lshift

```
compat.bit32.lshift(x, disp) -> number
```

Logical left shift. Shifts `x` left by `disp` bits, filling with zeros.

**Parameters:**
- `x` - Number to shift
- `disp` - Number of bits to shift (negative shifts right)

```lua
local compat = require("compat")

local result = compat.bit32.lshift(1, 8)  -- 256
local result = compat.bit32.lshift(0xFF, 4)  -- 4080
```

---

## bit32.rshift

```
compat.bit32.rshift(x, disp) -> number
```

Logical right shift. Shifts `x` right by `disp` bits, filling with zeros.

**Parameters:**
- `x` - Number to shift
- `disp` - Number of bits to shift (negative shifts left)

```lua
local compat = require("compat")

local result = compat.bit32.rshift(256, 8)  -- 1
local result = compat.bit32.rshift(0xFF00, 8)  -- 255
```

---

## bit32.arshift

```
compat.bit32.arshift(x, disp) -> number
```

Arithmetic right shift (sign-extending). Shifts `x` right by `disp` bits, preserving the sign bit.

**Parameters:**
- `x` - Number to shift
- `disp` - Number of bits to shift (negative shifts left)

```lua
local compat = require("compat")

local result = compat.bit32.arshift(0x80000000, 1)  -- 0xC0000000
local result = compat.bit32.arshift(256, 2)  -- 64
```

---

## bit32.lrotate

```
compat.bit32.lrotate(x, disp) -> number
```

Left rotate. Rotates `x` left by `disp` bits, wrapping bits around.

**Parameters:**
- `x` - Number to rotate
- `disp` - Number of bits to rotate (negative rotates right)

```lua
local compat = require("compat")

local result = compat.bit32.lrotate(0x80000001, 1)  -- 3
local result = compat.bit32.lrotate(0x01, 8)  -- 0x100
```

---

## bit32.rrotate

```
compat.bit32.rrotate(x, disp) -> number
```

Right rotate. Rotates `x` right by `disp` bits, wrapping bits around.

**Parameters:**
- `x` - Number to rotate
- `disp` - Number of bits to rotate (negative rotates left)

```lua
local compat = require("compat")

local result = compat.bit32.rrotate(3, 1)  -- 0x80000001
local result = compat.bit32.rrotate(0x100, 8)  -- 0x01
```

---

## bit32.extract

```
compat.bit32.extract(n, field, width?) -> number
```

Extract bit field. Extracts `width` bits from `n` starting at bit position `field`.

**Parameters:**
- `n` - Number to extract from
- `field` - Starting bit position (0-based)
- `width` (optional) - Number of bits to extract (default: 1)

```lua
local compat = require("compat")

-- Extract bits 4-11 (8 bits)
local result = compat.bit32.extract(0xABCD, 4, 8)  -- 0xBC (188)

-- Extract single bit at position 7
local result = compat.bit32.extract(0xFF, 7)  -- 1
```

---

## bit32.replace

```
compat.bit32.replace(n, v, field, width?) -> number
```

Replace bit field with value. Replaces `width` bits in `n` starting at bit position `field` with the low `width` bits of `v`.

**Parameters:**
- `n` - Original number
- `v` - Value to insert
- `field` - Starting bit position (0-based)
- `width` (optional) - Number of bits to replace (default: 1)

```lua
local compat = require("compat")

-- Replace bits 4-11 with 0xFF
local result = compat.bit32.replace(0xABCD, 0xFF, 4, 8)  -- 0xAFFD

-- Set bit 7 to 1
local result = compat.bit32.replace(0x00, 1, 7)  -- 0x80
```

---

## unpack

```
compat.unpack(list) -> ...
```

Unpack table. Returns all elements from the given table as separate values. Provides compatibility across Lua versions (global `unpack` in 5.1, `table.unpack` in 5.2+).

**Parameters:**
- `list` - Table to unpack

```lua
local compat = require("compat")

local a, b, c = compat.unpack({1, 2, 3})
print(a, b, c)  -- 1  2  3
```

---

## loadstring

```
compat.loadstring(str) -> function
```

Load string as function. Compiles the given string as Lua code and returns a function. Provides compatibility for the `loadstring` function removed in Lua 5.2+ (replaced by `load`).

**Parameters:**
- `str` - Lua code string

```lua
local compat = require("compat")

local fn = compat.loadstring("return 42")
print(fn())  -- 42

local fn = compat.loadstring("return 2 + 3")
print(fn())  -- 5
```

---

## setfenv

```
compat.setfenv(fn, env)
```

Set function environment. **Note:** This function was removed in Lua 5.2+ and will throw an error on those versions with a helpful message.

**Parameters:**
- `fn` - Function to modify
- `env` - New environment table

```lua
local compat = require("compat")

-- Works on Lua 5.1
compat.setfenv(fn, {})

-- Errors on Lua 5.2+:
-- "setfenv is not supported in Lua 5.2+"
```

---

## getfenv

```
compat.getfenv(fn) -> table
```

Get function environment. **Note:** This function was removed in Lua 5.2+ and will throw an error on those versions with a helpful message.

**Parameters:**
- `fn` - Function to query

```lua
local compat = require("compat")

-- Works on Lua 5.1
local env = compat.getfenv(fn)

-- Errors on Lua 5.2+:
-- "getfenv is not supported in Lua 5.2+"
```

---

## install

```
compat.install()
```

Install polyfills globally. Installs compatibility shims (`bit32`, `unpack`, `loadstring`) into the global environment (`_G`).

**Warning:** This function modifies global state. Use cautiously in shared environments.

```lua
local compat = require("compat")
compat.install()

-- Now bit32, unpack, loadstring are globally available
print(bit32.band(0xFF, 0x0F))  -- 15
local a, b = unpack({1, 2})     -- 1, 2
local fn = loadstring("return 42")
```

---

## check_deprecated

```
compat.check_deprecated(code) -> table
```

Scan code for deprecated API usage. Returns a table of warning strings for any deprecated API usage found in the provided code string.

**Parameters:**
- `code` - Lua code string to scan

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

---

## version_compare

```
compat.version_compare(v1, v2) -> number
```

Compare version strings. Returns negative if `v1 < v2`, 0 if equal, positive if `v1 > v2`.

**Parameters:**
- `v1` - First version string (e.g., "5.3")
- `v2` - Second version string (e.g., "5.4")

```lua
local compat = require("compat")

local cmp = compat.version_compare("5.3", "5.4")  -- -1
local cmp = compat.version_compare("5.4", "5.4")  -- 0
local cmp = compat.version_compare("5.5", "5.4")  -- 1
```

---

## version_at_least

```
compat.version_at_least(v) -> boolean
```

Check if current version is at least the given version. Returns true if the current Lua version is greater than or equal to the specified version.

**Parameters:**
- `v` - Minimum version string (e.g., "5.3")

```lua
local compat = require("compat")

if compat.version_at_least("5.3") then
    print("Bitwise operators available")
end

if compat.version_at_least("5.4") then
    print("Const/close attributes available")
end
```

---

## Examples

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

function process_data(...)
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

### Version-Specific Logic

```lua
local compat = require("compat")

if compat.lua54 then
    print("Running on Lua 5.4")
elseif compat.lua55 then
    print("Running on Lua 5.5")
end

-- Or using version comparison
if compat.version_at_least("5.3") then
    -- Use features available in 5.3+
end
```

## Implementation Details

The `bit32` implementation strategy depends on the Lua version:

1. **Lua 5.2**: Uses native `bit32` library directly (fastest)
2. **Lua 5.3+**: Uses `load()` to dynamically create implementation with native bitwise operators (avoids parse errors on older versions)
3. **Lua 5.1**: Pure-Lua arithmetic fallback using bit manipulation via division and modulo

All implementations normalize values to 32-bit unsigned integers (`x % 0x100000000`).
