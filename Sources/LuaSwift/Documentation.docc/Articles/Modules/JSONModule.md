# JSON Module

Encode and decode JSON data with support for JSONC and JSON5 formats.

## Overview

The JSON module provides fast, type-safe JSON encoding and decoding using Swift's native `JSONSerialization`. It supports standard JSON, JSONC (JSON with Comments), and JSON5 (relaxed JSON syntax).

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the JSON module
ModuleRegistry.installJSONModule(in: engine)
```

## Basic Usage

```lua
local json = require("luaswift.json")

-- Decode JSON string to Lua table
local data = json.decode('{"name": "Alice", "age": 30}')
print(data.name)  -- "Alice"
print(data.age)   -- 30

-- Encode Lua table to JSON string
local str = json.encode({name = "Bob", scores = {95, 87, 92}})
print(str)  -- {"name":"Bob","scores":[95,87,92]}
```

## API Reference

### encode(value, options?)

Converts a Lua value to a JSON string.

**Parameters:**
- `value` - The Lua value to encode (table, array, string, number, boolean, or nil)
- `options` (optional) - Table with encoding options:
  - `pretty` (boolean) - Enable pretty printing with indentation
  - `indent` (number) - Indentation spaces (default: 2)

**Returns:** JSON string

**Examples:**

```lua
-- Simple encoding
json.encode({x = 1, y = 2})  -- '{"x":1,"y":2}'

-- Pretty printing
json.encode({x = 1, y = 2}, {pretty = true})
-- {
--   "x": 1,
--   "y": 2
-- }

-- Custom indentation
json.encode({a = 1}, {pretty = true, indent = 4})
```

### decode(string, options?)

Parses a JSON string into a Lua value.

**Parameters:**
- `string` - The JSON string to parse
- `options` (optional) - Table with decoding options:
  - `format` (string) - Format: "json" (default), "jsonc", or "json5"
  - `comments` (boolean) - If true, use JSONC format

**Returns:** Lua value (table, array, string, number, boolean, or nil)

**Examples:**

```lua
-- Standard JSON
local data = json.decode('{"items": [1, 2, 3]}')

-- JSONC (JSON with Comments)
local config = json.decode([[
{
    // This is a comment
    "debug": true,
    /* Block comment */
    "port": 8080
}
]], {comments = true})

-- JSON5 format
local data = json.decode([[
{
    unquoted: 'single quotes',
    trailing: true,
}
]], {format = "json5"})
```

### decode_jsonc(string)

Parses a JSONC (JSON with Comments) string. JSONC is used by VS Code configurations, tsconfig.json, and other tools.

**Supported comment styles:**
- Single-line: `// comment`
- Block: `/* comment */`

**Example:**

```lua
local config = json.decode_jsonc([[
{
    // Database settings
    "host": "localhost",
    "port": 5432,

    /*
     * Connection pool settings
     */
    "pool": {
        "min": 5,
        "max": 20
    }
}
]])
```

### decode_json5(string)

Parses a JSON5 string. JSON5 extends JSON with more relaxed syntax.

**JSON5 features supported:**
- Single and block comments (`//` and `/* */`)
- Trailing commas in arrays and objects
- Unquoted object keys (valid identifiers)
- Single-quoted strings
- Hexadecimal numbers (`0xFF`)
- Leading decimal points (`.5` becomes `0.5`)
- Infinity and NaN (converted to `nil`)

**Example:**

```lua
local data = json.decode_json5([[
{
    // Unquoted keys and single quotes
    name: 'Alice',
    age: 30,

    // Hex numbers
    flags: 0xFF,

    // Trailing commas allowed
    tags: ['user', 'admin',],
}
]])
```

### null

A sentinel value representing JSON null. Use this to distinguish between absent values and explicit nulls.

**Example:**

```lua
local data = json.decode('{"value": null}')
if data.value == nil then
    print("Value is null or missing")
end

-- Encode with explicit null
local str = json.encode({
    name = "Test",
    optional = json.null
})
```

## Type Mapping

| JSON Type | Lua Type |
|-----------|----------|
| object | table |
| array | array (1-indexed) |
| string | string |
| number | number |
| boolean | boolean |
| null | nil |

## Working with Arrays

JSON arrays become 1-indexed Lua arrays:

```lua
local data = json.decode('[10, 20, 30]')
print(data[1])  -- 10 (Lua is 1-indexed)
print(#data)    -- 3

-- Encode Lua array
local json_str = json.encode({10, 20, 30})
-- Result: [10,20,30]
```

## Nested Structures

```lua
local complex = json.decode([[
{
    "users": [
        {"name": "Alice", "roles": ["admin", "user"]},
        {"name": "Bob", "roles": ["user"]}
    ],
    "settings": {
        "theme": "dark",
        "notifications": true
    }
}
]])

print(complex.users[1].name)           -- "Alice"
print(complex.users[1].roles[1])       -- "admin"
print(complex.settings.theme)          -- "dark"
```

## Error Handling

Invalid JSON throws an error:

```lua
local success, result = pcall(function()
    return json.decode('{"invalid": }')
end)

if not success then
    print("JSON error: " .. result)
end
```

## Performance Tips

1. **Reuse decoded data** - Decoding is faster than re-parsing the same string multiple times
2. **Use compact JSON** - Skip `pretty = true` for data exchange
3. **Prefer arrays for sequences** - Arrays encode more compactly than tables with numeric keys

## Common Patterns

### Configuration Files

```lua
-- Read and parse config
local config = json.decode_jsonc([[
{
    // App configuration
    "app": {
        "name": "MyApp",
        "version": "1.0.0"
    },
    "features": {
        "darkMode": true,
        "analytics": false
    }
}
]])

-- Access configuration
if config.features.darkMode then
    enableDarkMode()
end
```

### API Response Handling

```lua
local response = json.decode(api_response_body)

if response.error then
    print("API error: " .. response.error.message)
else
    for _, item in ipairs(response.data.items) do
        process(item)
    end
end
```

### Data Serialization

```lua
-- Save game state
local state = {
    level = 5,
    score = 12500,
    inventory = {"sword", "shield", "potion"}
}
local saved = json.encode(state, {pretty = true})

-- Load game state
local loaded = json.decode(saved)
```

## See Also

- ``JSONModule``
- ``YAMLModule``
- ``TOMLModule``
