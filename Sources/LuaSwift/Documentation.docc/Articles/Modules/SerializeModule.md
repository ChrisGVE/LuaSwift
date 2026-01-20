# Serialize Module

Serialize Lua values to string representation and back.

## Overview

The Serialize module provides serialization of Lua values to human-readable string representation and deserialization back to Lua values. Unlike JSON, the output is valid Lua syntax that can represent all serializable Lua types including tables with mixed keys.

## Installation

The serialize module is a pure Lua module bundled with LuaSwift. Load it directly:

```lua
local serialize = require("serialize")
```

## Basic Usage

```lua
local serialize = require("serialize")

-- Serialize a table to string
local str = serialize.encode({name = "test", values = {1, 2, 3}})
print(str)  -- {name = "test", values = {1, 2, 3}}

-- Deserialize string back to table
local data = serialize.decode(str)
print(data.name)  -- "test"

-- Pretty print with indentation
local pretty = serialize.pretty(data)
print(pretty)
```

## API Reference

### encode(value, options?)

Encode a Lua value to a string representation.

**Parameters:**
- `value` - The value to serialize (table, string, number, boolean, or nil)
- `options` (optional) - Table with encoding options:
  - `indent` (number) - Spaces for indentation (nil for compact output)
  - `sort_keys` (boolean) - Sort table keys alphabetically (default: false)
  - `max_depth` (number) - Maximum nesting depth (default: 100)

**Returns:** String representation of the value

**Throws:** Error if value contains unsupported types or circular references

**Examples:**

```lua
-- Compact encoding (default)
serialize.encode({x = 1, y = 2})
-- {x = 1, y = 2}

-- Pretty printing
serialize.encode({x = 1, y = 2}, {indent = 2})
-- {
--   x = 1,
--   y = 2
-- }

-- With sorted keys
serialize.encode({b = 2, a = 1}, {indent = 2, sort_keys = true})
-- {
--   a = 1,
--   b = 2
-- }
```

### decode(str)

Decode a serialized string back to a Lua value.

**Parameters:**
- `str` - String produced by `serialize.encode()`

**Returns:** The deserialized Lua value

**Throws:** Error if string is malformed or contains invalid syntax

**Examples:**

```lua
local data = serialize.decode('{name = "Alice", age = 30}')
print(data.name)  -- "Alice"
print(data.age)   -- 30

-- Arrays
local arr = serialize.decode('{1, 2, 3}')
print(arr[1])  -- 1

-- Mixed keys
local mixed = serialize.decode('{[1] = "one", key = "value"}')
```

### pretty(value, indent?)

Convenience function for pretty-printed serialization with sorted keys.

**Parameters:**
- `value` - The value to serialize
- `indent` (optional) - Number of spaces for indentation (default: 2)

**Returns:** Pretty-printed string representation

**Example:**

```lua
local data = {
    users = {"Alice", "Bob"},
    settings = {theme = "dark"}
}

print(serialize.pretty(data))
-- {
--   settings = {
--     theme = "dark"
--   },
--   users = {
--     "Alice",
--     "Bob"
--   }
-- }
```

### compact(value)

Convenience function for compact serialization (no whitespace, unsorted keys).

**Parameters:**
- `value` - The value to serialize

**Returns:** Compact string representation

**Example:**

```lua
local data = {a = 1, b = 2, c = {3, 4}}
print(serialize.compact(data))
-- {a = 1, b = 2, c = {3, 4}}
```

### safe_decode(str)

Safely decode a string, returning nil and error message on failure instead of throwing.

**Parameters:**
- `str` - String to decode

**Returns:**
- On success: `value, nil`
- On failure: `nil, error_message`

**Example:**

```lua
local data, err = serialize.safe_decode('{valid = true}')
if data then
    print(data.valid)  -- true
end

local data2, err2 = serialize.safe_decode('{invalid syntax')
if not data2 then
    print("Error: " .. err2)
end
```

### is_serializable(value)

Check if a value can be serialized without errors.

**Parameters:**
- `value` - The value to check

**Returns:** `true` if value can be serialized, `false` otherwise

**Example:**

```lua
print(serialize.is_serializable({a = 1}))       -- true
print(serialize.is_serializable("hello"))        -- true
print(serialize.is_serializable(print))          -- false (function)
print(serialize.is_serializable(coroutine.create(function() end)))  -- false

-- Circular reference detection
local t = {}
t.self = t
print(serialize.is_serializable(t))  -- false
```

## Type Support

### Supported Types

| Lua Type | Serialized Format | Example |
|----------|-------------------|---------|
| nil | `nil` | `nil` |
| boolean | `true` / `false` | `true` |
| number | numeric literal | `42`, `3.14`, `-1e10` |
| string | quoted string | `"hello"` |
| table (array) | `{values}` | `{1, 2, 3}` |
| table (dict) | `{key = value}` | `{name = "test"}` |

### Special Number Values

```lua
serialize.encode(math.huge)   -- "math.huge"
serialize.encode(-math.huge)  -- "-math.huge"
serialize.encode(0/0)         -- "0/0" (NaN)
```

### Unsupported Types

The following types throw an error when serialized:
- `function`
- `userdata`
- `thread` (coroutine)

Use `is_serializable()` to check before serializing if unsure.

## Key Handling

### Identifier Keys

Simple string keys that are valid Lua identifiers serialize without brackets:

```lua
serialize.encode({name = "Alice"})
-- {name = "Alice"}
```

### Bracket Keys

String keys with special characters and all numeric/boolean keys use bracket notation:

```lua
serialize.encode({["my-key"] = 1})   -- {["my-key"] = 1}
serialize.encode({[1] = "one"})      -- {[1] = "one"}
serialize.encode({[true] = "yes"})   -- {[true] = "yes"}
```

## Error Handling

### Circular References

```lua
local t = {}
t.self = t

-- This throws an error
local ok, err = pcall(serialize.encode, t)
print(err)  -- "Circular reference detected in table"

-- Use is_serializable to check first
if serialize.is_serializable(t) then
    print(serialize.encode(t))
else
    print("Cannot serialize")
end
```

### Depth Limiting

```lua
-- Default max depth is 100
local deep = {{{{{{{...}}}}}}}

-- Custom depth limit
local ok, err = pcall(serialize.encode, deep, {max_depth = 5})
print(err)  -- "Maximum serialization depth exceeded"
```

## Common Patterns

### Configuration Files

```lua
local serialize = require("serialize")

-- Save configuration
local config = {
    window = {width = 800, height = 600},
    theme = "dark",
    recent_files = {"/path/to/file1", "/path/to/file2"}
}
local str = serialize.pretty(config)
-- Write str to file

-- Load configuration
local loaded = serialize.decode(str)
```

### Game State Persistence

```lua
local serialize = require("serialize")

local game_state = {
    level = 5,
    score = 12500,
    inventory = {"sword", "shield", "potion"},
    position = {x = 100, y = 200}
}

-- Save
local saved = serialize.compact(game_state)

-- Load
local loaded = serialize.decode(saved)
```

### Data Validation

```lua
local serialize = require("serialize")

local function save_data(data)
    if not serialize.is_serializable(data) then
        error("Data contains non-serializable values")
    end
    return serialize.encode(data)
end

-- Safe loading with error handling
local function load_data(str)
    local data, err = serialize.safe_decode(str)
    if not data then
        print("Failed to load: " .. err)
        return nil
    end
    return data
end
```

## Comparison with JSON

| Feature | serialize | JSON |
|---------|-----------|------|
| Output format | Lua syntax | JSON syntax |
| Table keys | string, number, boolean | string only |
| Array indices | 1-based (Lua) | 0-based |
| Special numbers | `math.huge`, `0/0` | Not supported |
| Comments | Not supported | JSONC/JSON5 only |
| Interoperability | Lua only | Universal |

Use **serialize** for:
- Lua-to-Lua data persistence
- Configuration files read only by Lua
- Debugging and inspection

Use **JSON** for:
- Data exchange with other languages
- Web APIs
- Standard configuration formats

## See Also

- <doc:CompatModule>
- ``JSONModule``
