# YAML Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.yaml` | **Global:** `yaml`

YAML encoding and decoding for Lua tables. Powered by the Yams library, this module enables seamless conversion between Lua data structures and YAML format, including support for multi-document YAML files.

## Function Reference

| Function | Description |
|----------|-------------|
| [decode(yaml_string)](#decode) | Parse YAML string to Lua value |
| [encode(value)](#encode) | Convert Lua value to YAML string |
| [decode_all(yaml_string)](#decode_all) | Parse multi-document YAML to array of values |
| [encode_all(documents)](#encode_all) | Convert array of values to multi-document YAML |

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

---

## decode

```
yaml.decode(yaml_string) -> value
```

Parse YAML string to Lua value.

**Parameters:**
- `yaml_string` - String containing YAML data

**Returns:**
- Lua value (table, array, string, number, boolean, or nil)

```lua
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

---

## encode

```
yaml.encode(value) -> string
```

Convert Lua value to YAML string.

**Parameters:**
- `value` - Any Lua value (table, array, string, number, boolean, nil)

**Returns:**
- String containing YAML representation

```lua
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

---

## decode_all

```
yaml.decode_all(yaml_string) -> array
```

Parse multi-document YAML string to array of Lua values.

**Parameters:**
- `yaml_string` - String containing multi-document YAML (with `---` separators)

**Returns:**
- Array of Lua values

```lua
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

---

## encode_all

```
yaml.encode_all(documents) -> string
```

Encode multiple Lua values as multi-document YAML string.

**Parameters:**
- `documents` - Array of Lua values

**Returns:**
- String containing multi-document YAML (documents separated by `---`)

```lua
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

---

## Examples

### Configuration Files

```lua
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

### Error Handling

```lua
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
