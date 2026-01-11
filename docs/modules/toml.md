# TOML Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.toml` | **Global:** `toml`

The TOML module provides encoding and decoding functionality for TOML (Tom's Obvious, Minimal Language) format. It uses the TOMLKit library to parse and generate TOML documents, supporting all standard TOML data types including tables, arrays, dates, and times.

## Functions

### toml.decode(toml_string)

Decode a TOML string into a Lua table.

**Parameters:**
- `toml_string` (string): TOML document as a string

**Returns:** (table) Decoded Lua table

**Example:**
```lua
local toml = require("luaswift.toml")

local config = toml.decode([[
[database]
server = "192.168.1.1"
ports = [8001, 8002, 8003]
connection_max = 5000
enabled = true

[servers.alpha]
ip = "10.0.0.1"
dc = "eqdc10"

[servers.beta]
ip = "10.0.0.2"
dc = "eqdc10"
]])

print(config.database.server)           -- 192.168.1.1
print(config.database.ports[1])         -- 8001
print(config.database.enabled)          -- true
print(config.servers.alpha.ip)          -- 10.0.0.1
```

**Date/Time Support:**
```lua
local doc = toml.decode([[
date = 1979-05-27
time = 07:32:00
datetime = 1979-05-27T07:32:00Z
]])

-- Dates and times are converted to strings
print(doc.date)      -- "1979-05-27"
print(doc.time)      -- "07:32:00"
print(doc.datetime)  -- "1979-05-27T07:32:00Z"
```

**Error Handling:**
```lua
local success, result = pcall(toml.decode, "invalid = [[[")
if not success then
    print("Parse error:", result)
end
```

### toml.encode(table)

Encode a Lua table into a TOML string.

**Parameters:**
- `table` (table): Lua table to encode (must be a table, not a primitive value)

**Returns:** (string) TOML-formatted string

**Example:**
```lua
local toml = require("luaswift.toml")

local config = {
    title = "TOML Example",

    owner = {
        name = "Tom Preston-Werner",
        dob = "1979-05-27T07:32:00-08:00"
    },

    database = {
        server = "192.168.1.1",
        ports = {8001, 8002, 8003},
        connection_max = 5000,
        enabled = true
    },

    servers = {
        alpha = {
            ip = "10.0.0.1",
            dc = "eqdc10"
        },
        beta = {
            ip = "10.0.0.2",
            dc = "eqdc10"
        }
    }
}

local toml_str = toml.encode(config)
print(toml_str)
```

**Output:**
```toml
title = "TOML Example"

[owner]
name = "Tom Preston-Werner"
dob = "1979-05-27T07:32:00-08:00"

[database]
server = "192.168.1.1"
ports = [8001, 8002, 8003]
connection_max = 5000
enabled = true

[servers.alpha]
ip = "10.0.0.1"
dc = "eqdc10"

[servers.beta]
ip = "10.0.0.2"
dc = "eqdc10"
```

**Number Handling:**
```lua
local data = {
    integer = 42,
    float = 3.14159,
    scientific = 5e+22
}

local toml_str = toml.encode(data)
-- Integers are encoded as integers, floats as floats
-- integer = 42
-- float = 3.14159
-- scientific = 5.0e+22
```

**Complex Numbers:**
```lua
-- Complex numbers are encoded as special tables
local data = {
    signal = {1, 2, 3}  -- Assuming complex array
}

-- Complex values become:
-- [signal]
-- __type = "complex"
-- re = 1.0
-- im = 2.0
```

## Data Type Mapping

### Lua to TOML

| Lua Type | TOML Type | Notes |
|----------|-----------|-------|
| `boolean` | Boolean | Direct mapping |
| `number` (integer) | Integer | When `n % 1 == 0` |
| `number` (float) | Float | Decimal numbers |
| `string` | String | Direct mapping |
| `table` (array) | Array | Sequential numeric indices |
| `table` (dict) | Table | String keys |
| `nil` | - | **Not supported** (throws error) |

### TOML to Lua

| TOML Type | Lua Type | Notes |
|-----------|----------|-------|
| Boolean | `boolean` | Direct mapping |
| Integer | `number` | Converted to double |
| Float | `number` | Direct mapping |
| String | `string` | Direct mapping |
| Array | `table` (array) | Sequential indices |
| Table | `table` (dict) | String keys |
| Date | `string` | ISO 8601 format |
| Time | `string` | HH:MM:SS format |
| DateTime | `string` | ISO 8601 format |

## Limitations

1. **No nil values**: TOML does not support null/nil. Attempting to encode a table containing `nil` values will throw an error.

2. **Root must be a table**: Unlike JSON, TOML documents must have a table as the root element. Primitive values cannot be encoded directly.

3. **Date/Time as strings**: TOML date and time types are converted to strings when decoded, not native Lua date objects.

4. **Complex number encoding**: Complex numbers are encoded as tables with `__type`, `re`, and `im` fields, not as TOML primitives.

## Practical Examples

### Configuration File

```lua
local toml = require("luaswift.toml")

-- Read configuration
local config_text = [[
[app]
name = "MyApp"
version = "1.0.0"

[logging]
level = "info"
file = "/var/log/myapp.log"

[database]
host = "localhost"
port = 5432
name = "myapp_db"
]]

local config = toml.decode(config_text)

print("App:", config.app.name, config.app.version)
print("DB:", config.database.host .. ":" .. config.database.port)
```

### Round-trip Conversion

```lua
local toml = require("luaswift.toml")

-- Original data
local original = {
    package = {
        name = "example",
        version = "1.0.0",
        dependencies = {"lua >= 5.1", "luasocket"}
    }
}

-- Encode to TOML
local toml_string = toml.encode(original)

-- Decode back to Lua
local restored = toml.decode(toml_string)

-- Verify
print(restored.package.name)  -- "example"
print(restored.package.dependencies[1])  -- "lua >= 5.1"
```

### Error Handling Pattern

```lua
local toml = require("luaswift.toml")

local function safe_decode(toml_string)
    local success, result = pcall(toml.decode, toml_string)
    if success then
        return result
    else
        print("TOML parse error:", result)
        return nil
    end
end

local config = safe_decode([[
[section]
key = value  # Missing quotes - syntax error
]])

if config then
    print("Config loaded")
else
    print("Using defaults")
end
```

## Function Reference

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `decode` | `toml_string: string` | `table` | Parse TOML string into Lua table |
| `encode` | `table: table` | `string` | Convert Lua table to TOML string |
