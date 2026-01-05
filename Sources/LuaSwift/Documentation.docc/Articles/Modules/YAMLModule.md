# YAML Module

Parse and generate YAML data with support for multi-document files.

## Overview

The YAML module provides YAML encoding and decoding using the Yams library. It supports single and multi-document YAML files, making it ideal for configuration files, data serialization, and document processing.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the YAML module
ModuleRegistry.installYAMLModule(in: engine)
```

## Basic Usage

```lua
local yaml = require("luaswift.yaml")

-- Decode YAML string to Lua table
local config = yaml.decode([[
name: MyApp
version: 1.0.0
debug: true
]])

print(config.name)     -- "MyApp"
print(config.version)  -- "1.0.0"
print(config.debug)    -- true

-- Encode Lua table to YAML string
local str = yaml.encode({
    name = "Bob",
    scores = {95, 87, 92}
})
print(str)
-- name: Bob
-- scores:
-- - 95
-- - 87
-- - 92
```

## API Reference

### encode(value)

Converts a Lua value to a YAML string.

**Parameters:**
- `value` - The Lua value to encode (table, array, string, number, boolean, or nil)

**Returns:** YAML string

**Example:**

```lua
local data = {
    server = {
        host = "localhost",
        port = 8080
    },
    features = {"auth", "logging"}
}

print(yaml.encode(data))
-- server:
--   host: localhost
--   port: 8080
-- features:
-- - auth
-- - logging
```

### decode(string)

Parses a YAML string into a Lua value. For multi-document YAML, only the first document is returned.

**Parameters:**
- `string` - The YAML string to parse

**Returns:** Lua value (table, array, string, number, boolean, or nil)

**Example:**

```lua
local config = yaml.decode([[
database:
  host: db.example.com
  port: 5432
  credentials:
    username: admin
    password: secret
]])

print(config.database.host)                    -- "db.example.com"
print(config.database.credentials.username)    -- "admin"
```

### encode_all(documents)

Encodes an array of Lua values into a multi-document YAML string.

**Parameters:**
- `documents` - Array of Lua values, each becoming a YAML document

**Returns:** Multi-document YAML string with `---` separators

**Example:**

```lua
local docs = {
    {name = "Document 1", data = {1, 2, 3}},
    {name = "Document 2", data = {4, 5, 6}}
}

print(yaml.encode_all(docs))
-- ---
-- name: Document 1
-- data:
-- - 1
-- - 2
-- - 3
-- ---
-- name: Document 2
-- data:
-- - 4
-- - 5
-- - 6
```

### decode_all(string)

Parses a multi-document YAML string into an array of Lua values.

**Parameters:**
- `string` - Multi-document YAML string (documents separated by `---`)

**Returns:** Array of Lua values

**Example:**

```lua
local yaml_str = [[
---
type: config
values:
  timeout: 30
---
type: data
items:
  - apple
  - banana
]]

local docs = yaml.decode_all(yaml_str)
print(#docs)                  -- 2
print(docs[1].type)           -- "config"
print(docs[2].items[1])       -- "apple"
```

## Type Mapping

| YAML Type | Lua Type |
|-----------|----------|
| mapping | table |
| sequence | array (1-indexed) |
| string | string |
| integer | number |
| float | number |
| boolean (true/false, yes/no, on/off) | boolean |
| null (~, null) | nil |

## YAML Features

### Mappings (Objects)

```lua
local data = yaml.decode([[
person:
  name: Alice
  age: 30
  address:
    city: New York
    zip: "10001"
]])

print(data.person.name)          -- "Alice"
print(data.person.address.city)  -- "New York"
```

### Sequences (Arrays)

```lua
local data = yaml.decode([[
fruits:
  - apple
  - banana
  - orange
numbers: [1, 2, 3, 4, 5]
]])

print(data.fruits[1])    -- "apple"
print(data.numbers[3])   -- 3
```

### Multiline Strings

```lua
local data = yaml.decode([[
description: |
  This is a multiline
  string that preserves
  newlines.

compact: >
  This is a folded
  string where newlines
  become spaces.
]])

print(data.description)
-- "This is a multiline\nstring that preserves\nnewlines.\n"

print(data.compact)
-- "This is a folded string where newlines become spaces.\n"
```

### Anchors and Aliases

```lua
local data = yaml.decode([[
defaults: &defaults
  adapter: postgres
  host: localhost

development:
  <<: *defaults
  database: dev_db

production:
  <<: *defaults
  database: prod_db
]])

print(data.development.adapter)  -- "postgres"
print(data.production.host)      -- "localhost"
```

## Common Patterns

### Configuration Files

```lua
local config = yaml.decode([[
app:
  name: MyService
  version: 2.1.0

server:
  host: 0.0.0.0
  port: 8080
  ssl: true

logging:
  level: info
  format: json
]])

-- Access configuration
local port = config.server.port
local log_level = config.logging.level
```

### Data Serialization

```lua
-- Save application state
local state = {
    user = {name = "Alice", level = 42},
    inventory = {"sword", "shield"},
    settings = {sound = true, music = false}
}
local saved = yaml.encode(state)

-- Load state later
local loaded = yaml.decode(saved)
```

### Processing Multi-Document Files

```lua
-- Kubernetes-style manifests
local manifests = yaml.decode_all([[
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  setting: value
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  password: base64encoded
]])

for i, manifest in ipairs(manifests) do
    print(string.format("Resource %d: %s/%s",
        i, manifest.kind, manifest.metadata.name))
end
```

## Error Handling

Invalid YAML throws an error:

```lua
local success, result = pcall(function()
    return yaml.decode("invalid: yaml: content:")
end)

if not success then
    print("YAML error: " .. result)
end
```

## YAML vs JSON

| Feature | YAML | JSON |
|---------|------|------|
| Readability | More human-readable | Compact |
| Comments | Supported | Not supported |
| Multi-document | Supported | Not supported |
| Anchors/Aliases | Supported | Not supported |
| File extension | .yaml, .yml | .json |

Use YAML for:
- Configuration files
- Human-editable data
- Multi-document files
- Files with comments

Use JSON for:
- API responses
- Data interchange
- Strict parsing requirements

## See Also

- ``YAMLModule``
- ``JSONModule``
- ``TOMLModule``
