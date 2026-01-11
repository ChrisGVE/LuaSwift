# YAML Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.yaml` | **Global:** `yaml`

YAML encoding and decoding for Lua tables. Powered by the Yams library, this module enables seamless conversion between Lua data structures and YAML format, including support for multi-document YAML files.

## Basic Usage

```lua
local yaml = require("luaswift.yaml")

-- Decode YAML to Lua table
local config = yaml.decode([[
name: LuaSwift
version: 1.0
features:
  - YAML support
  - JSON support
  - Multi-document parsing
]])

print(config.name)  -- "LuaSwift"
print(config.version)  -- 1.0
print(config.features[1])  -- "YAML support"

-- Encode Lua table to YAML
local data = {
    name = "John Doe",
    age = 30,
    languages = {"Lua", "Swift", "Python"}
}

local yaml_str = yaml.encode(data)
print(yaml_str)
-- Output:
-- age: 30
-- languages:
-- - Lua
-- - Swift
-- - Python
-- name: John Doe
```

## Functions

### encode(value)

Converts a Lua value to a YAML string.

**Parameters:**
- `value` - Any Lua value (table, array, string, number, boolean, nil)

**Returns:**
- String containing YAML representation

**Example:**

```lua
local yaml = require("luaswift.yaml")

-- Simple types
print(yaml.encode(42))  -- "42\n"
print(yaml.encode("hello"))  -- "hello\n"
print(yaml.encode(true))  -- "true\n"

-- Tables
local person = {
    name = "Alice",
    age = 28,
    active = true
}
print(yaml.encode(person))
-- age: 28
-- active: true
-- name: Alice

-- Arrays
local colors = {"red", "green", "blue"}
print(yaml.encode(colors))
-- - red
-- - green
-- - blue

-- Nested structures
local project = {
    name = "MyApp",
    dependencies = {
        {name = "LuaSwift", version = "1.0"},
        {name = "OtherLib", version = "2.1"}
    }
}
print(yaml.encode(project))
-- dependencies:
-- - name: LuaSwift
--   version: '1.0'
-- - name: OtherLib
--   version: '2.1'
-- name: MyApp
```

### decode(yaml_string)

Parses a YAML string and returns a Lua value.

**Parameters:**
- `yaml_string` - String containing YAML data

**Returns:**
- Lua value (table, array, string, number, boolean, or nil)

**Example:**

```lua
local yaml = require("luaswift.yaml")

-- Decode simple YAML
local num = yaml.decode("42")
print(num)  -- 42

-- Decode object
local person = yaml.decode([[
name: Bob
age: 35
employed: true
]])
print(person.name)  -- "Bob"
print(person.age)  -- 35
print(person.employed)  -- true

-- Decode array
local items = yaml.decode([[
- item1
- item2
- item3
]])
print(items[1])  -- "item1"

-- Decode nested structures
local config = yaml.decode([[
database:
  host: localhost
  port: 5432
  credentials:
    username: admin
    password: secret
]])
print(config.database.host)  -- "localhost"
print(config.database.credentials.username)  -- "admin"

-- Null/nil values
local data = yaml.decode([[
value1: ~
value2: null
value3:
]])
print(data.value1)  -- nil
print(data.value2)  -- nil
print(data.value3)  -- nil
```

### encode_all(documents)

Encodes multiple Lua values as a multi-document YAML string. Documents are separated by `---` markers.

**Parameters:**
- `documents` - Array of Lua values

**Returns:**
- String containing multi-document YAML

**Example:**

```lua
local yaml = require("luaswift.yaml")

local docs = {
    {name = "Document 1", type = "config"},
    {name = "Document 2", type = "data"},
    {name = "Document 3", type = "metadata"}
}

local multi_yaml = yaml.encode_all(docs)
print(multi_yaml)
-- ---
-- name: Document 1
-- type: config
-- ---
-- name: Document 2
-- type: data
-- ---
-- name: Document 3
-- type: metadata

-- Mixed types
local mixed = {
    {language = "Lua"},
    {"item1", "item2", "item3"},
    "Simple string",
    42
}
print(yaml.encode_all(mixed))
-- ---
-- language: Lua
-- ---
-- - item1
-- - item2
-- - item3
-- ---
-- Simple string
-- ---
-- 42
```

### decode_all(yaml_string)

Parses a multi-document YAML string and returns an array of Lua values.

**Parameters:**
- `yaml_string` - String containing multi-document YAML (with `---` separators)

**Returns:**
- Array of Lua values

**Example:**

```lua
local yaml = require("luaswift.yaml")

local yaml_str = [[
---
name: Config 1
enabled: true
---
name: Config 2
enabled: false
---
name: Config 3
enabled: true
]]

local docs = yaml.decode_all(yaml_str)
print(#docs)  -- 3
print(docs[1].name)  -- "Config 1"
print(docs[1].enabled)  -- true
print(docs[2].enabled)  -- false

-- Process all documents
for i, doc in ipairs(docs) do
    print(string.format("Document %d: %s (enabled=%s)",
        i, doc.name, tostring(doc.enabled)))
end
-- Document 1: Config 1 (enabled=true)
-- Document 2: Config 2 (enabled=false)
-- Document 3: Config 3 (enabled=true)
```

## Type Mapping

### Lua to YAML

| Lua Type | YAML Type | Notes |
|----------|-----------|-------|
| `nil` | `null` | Empty or tilde notation |
| `boolean` | `true`/`false` | Boolean literals |
| `number` (integer) | Integer | When no fractional part |
| `number` (float) | Float | When fractional part present |
| `string` | String | Quoted or unquoted as needed |
| `table` (dict) | Mapping | Key-value pairs |
| `array` | Sequence | Array elements with `-` markers |
| `complex` | Mapping | Special structure: `{__type: "complex", re: x, im: y}` |

### YAML to Lua

| YAML Type | Lua Type | Notes |
|-----------|----------|-------|
| `null`, `~`, empty | `nil` | All null variants |
| `true`/`false` | `boolean` | Boolean values |
| Integer literal | `number` | Converted to double |
| Float literal | `number` | Native double |
| String | `string` | Unescaped |
| Mapping | `table` | Dictionary with string keys |
| Sequence | `array` | Numeric-indexed table |
| Alias | Resolved | Anchors resolved during parsing |

## Practical Examples

### Configuration Files

```lua
local yaml = require("luaswift.yaml")

-- Write configuration
local config = {
    app = {
        name = "MyApp",
        version = "1.0.0",
        debug = false
    },
    server = {
        host = "0.0.0.0",
        port = 8080,
        timeout = 30
    },
    logging = {
        level = "info",
        output = "stdout"
    }
}

local config_yaml = yaml.encode(config)
-- Save to file or use directly

-- Read configuration
local loaded_config = yaml.decode(config_yaml)
print(loaded_config.server.port)  -- 8080
```

### Data Serialization

```lua
local yaml = require("luaswift.yaml")

-- Serialize game state
local save_data = {
    player = {
        name = "Hero",
        level = 42,
        position = {x = 100, y = 250},
        inventory = {"sword", "shield", "potion"}
    },
    timestamp = os.time(),
    checksum = "abc123"
}

local yaml_save = yaml.encode(save_data)
-- Store to file

-- Restore game state
local restored = yaml.decode(yaml_save)
print(restored.player.level)  -- 42
print(restored.player.inventory[1])  -- "sword"
```

### Multi-Document Processing

```lua
local yaml = require("luaswift.yaml")

-- Process multiple API responses
local api_responses = yaml.decode_all([[
---
status: 200
data:
  user_id: 123
  username: alice
---
status: 200
data:
  user_id: 456
  username: bob
---
status: 404
error: User not found
]])

local successful = {}
for _, response in ipairs(api_responses) do
    if response.status == 200 then
        table.insert(successful, response.data)
    end
end

print(#successful)  -- 2
print(successful[1].username)  -- "alice"
```

### Complex Numbers

```lua
local yaml = require("luaswift.yaml")

-- YAML doesn't natively support complex numbers,
-- so they're encoded as special dictionaries
local data = {
    result = {re = 3.0, im = 4.0}  -- Complex number
}

local encoded = yaml.encode(data)
print(encoded)
-- result:
--   __type: complex
--   im: 4.0
--   re: 3.0

local decoded = yaml.decode(encoded)
print(decoded.result.__type)  -- "complex"
print(decoded.result.re)  -- 3.0
print(decoded.result.im)  -- 4.0
```

## Error Handling

```lua
local yaml = require("luaswift.yaml")

-- Wrap operations in pcall for error handling
local success, result = pcall(yaml.decode, "invalid: yaml: content:")
if not success then
    print("YAML decode error:", result)
end

-- Handle encoding errors
local success, yaml_str = pcall(yaml.encode, some_value)
if success then
    print("Encoded successfully")
else
    print("Encoding failed:", yaml_str)
end
```

## Function Reference

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `encode` | `value` | `string` | Encode Lua value to YAML string |
| `decode` | `yaml_string` | `any` | Decode YAML string to Lua value |
| `encode_all` | `documents` (array) | `string` | Encode multiple documents to multi-document YAML |
| `decode_all` | `yaml_string` | `array` | Decode multi-document YAML to array of values |
