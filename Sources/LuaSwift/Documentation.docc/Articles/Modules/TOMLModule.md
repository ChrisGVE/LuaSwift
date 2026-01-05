# TOML Module

Parse and generate TOML configuration files.

## Overview

The TOML module provides TOML (Tom's Obvious Minimal Language) encoding and decoding. TOML is designed to be a minimal configuration file format that's easy to read and maps unambiguously to a hash table.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the TOML module
ModuleRegistry.installTOMLModule(in: engine)
```

## Basic Usage

```lua
local toml = require("luaswift.toml")

-- Decode TOML string to Lua table
local config = toml.decode([[
title = "My App"
version = "1.0.0"

[server]
host = "localhost"
port = 8080
]])

print(config.title)        -- "My App"
print(config.server.host)  -- "localhost"
print(config.server.port)  -- 8080

-- Encode Lua table to TOML string
local str = toml.encode({
    title = "Config",
    database = {host = "db.local", port = 5432}
})
```

## API Reference

### encode(value)

Converts a Lua table to a TOML string.

**Parameters:**
- `value` - The Lua table to encode

**Returns:** TOML string

**Example:**

```lua
local config = {
    title = "Application",
    database = {
        server = "192.168.1.1",
        ports = {8001, 8002, 8003},
        enabled = true
    }
}

print(toml.encode(config))
-- title = "Application"
--
-- [database]
-- server = "192.168.1.1"
-- ports = [8001, 8002, 8003]
-- enabled = true
```

### decode(string)

Parses a TOML string into a Lua table.

**Parameters:**
- `string` - The TOML string to parse

**Returns:** Lua table

**Example:**

```lua
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

print(config.database.server)     -- "192.168.1.1"
print(config.database.ports[1])   -- 8001
print(config.servers.alpha.ip)    -- "10.0.0.1"
```

## Type Mapping

| TOML Type | Lua Type |
|-----------|----------|
| Table | table |
| Array | array (1-indexed) |
| String | string |
| Integer | number |
| Float | number |
| Boolean | boolean |
| Datetime | string (ISO 8601) |

## TOML Features

### Tables (Sections)

```lua
local config = toml.decode([[
[owner]
name = "Tom Preston-Werner"
organization = "GitHub"

[database]
server = "192.168.1.1"
ports = [8001, 8002]
]])

print(config.owner.name)         -- "Tom Preston-Werner"
print(config.database.ports[2])  -- 8002
```

### Nested Tables

```lua
local config = toml.decode([[
[servers]

[servers.alpha]
ip = "10.0.0.1"

[servers.beta]
ip = "10.0.0.2"
]])

-- Equivalent inline form
local config2 = toml.decode([[
servers = { alpha = { ip = "10.0.0.1" }, beta = { ip = "10.0.0.2" } }
]])
```

### Arrays of Tables

```lua
local config = toml.decode([[
[[products]]
name = "Hammer"
sku = 738594937

[[products]]
name = "Nail"
sku = 284758393
color = "gray"
]])

print(#config.products)           -- 2
print(config.products[1].name)    -- "Hammer"
print(config.products[2].color)   -- "gray"
```

### Arrays

```lua
local config = toml.decode([[
integers = [1, 2, 3]
colors = ["red", "yellow", "green"]
nested = [[1, 2], [3, 4, 5]]
mixed = ["string", 123, true]
]])

print(config.integers[1])     -- 1
print(config.colors[2])       -- "yellow"
print(config.nested[2][1])    -- 3
```

### Strings

```lua
local config = toml.decode([[
# Basic string
basic = "I'm a string"

# Literal string (no escapes)
literal = 'C:\Users\path'

# Multi-line basic string
multiline = """
Roses are red
Violets are blue"""

# Multi-line literal string
multiline_literal = '''
The first newline is trimmed.
   All other whitespace
   is preserved.
'''
]])
```

### Numbers

```lua
local config = toml.decode([[
# Integers
int1 = +99
int2 = 42
int3 = -17

# Hexadecimal, octal, binary
hex = 0xDEADBEEF
oct = 0o755
bin = 0b11010110

# Floats
flt1 = +1.0
flt2 = 3.1415
flt3 = -0.01

# Scientific notation
sci1 = 5e+22
sci2 = 1e06
sci3 = -2E-2

# Special floats
inf = inf
ninf = -inf
nan = nan
]])
```

### Booleans

```lua
local config = toml.decode([[
bool1 = true
bool2 = false
]])
```

### Dates and Times

```lua
local config = toml.decode([[
# Offset date-time
odt1 = 1979-05-27T07:32:00Z
odt2 = 1979-05-27T00:32:00-07:00

# Local date-time
ldt1 = 1979-05-27T07:32:00

# Local date
ld1 = 1979-05-27

# Local time
lt1 = 07:32:00
]])

-- Dates are returned as strings
print(config.odt1)  -- "1979-05-27T07:32:00Z"
```

## Common Patterns

### Application Configuration

```lua
local config = toml.decode([[
[app]
name = "MyService"
version = "2.1.0"
debug = false

[server]
host = "0.0.0.0"
port = 8080
workers = 4

[database]
url = "postgres://localhost/mydb"
pool_size = 10
timeout = 30

[logging]
level = "info"
file = "/var/log/myservice.log"
]])

-- Use configuration
local server_port = config.server.port
local db_url = config.database.url
```

### Cargo.toml Style

```lua
local cargo = toml.decode([[
[package]
name = "my-project"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1", features = ["full"] }

[dev-dependencies]
criterion = "0.5"
]])
```

### pyproject.toml Style

```lua
local pyproject = toml.decode([[
[project]
name = "my-package"
version = "1.0.0"
dependencies = [
    "requests>=2.25.0",
    "click>=8.0.0"
]

[project.scripts]
mycli = "mypackage.cli:main"

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"
]])
```

## Error Handling

Invalid TOML throws an error:

```lua
local success, result = pcall(function()
    return toml.decode([[
        invalid = "missing quote
    ]])
end)

if not success then
    print("TOML error: " .. result)
end
```

## TOML vs YAML vs JSON

| Feature | TOML | YAML | JSON |
|---------|------|------|------|
| Human readable | Excellent | Good | Moderate |
| Comments | Yes | Yes | No |
| Date/time types | Native | String | String |
| Strictness | Strict | Flexible | Strict |
| Best for | Config files | Data/Docs | APIs |

Use TOML for:
- Application configuration (Cargo.toml, pyproject.toml)
- Settings files
- Simple structured data
- When you want strict parsing with clear errors

## See Also

- ``TOMLModule``
- ``YAMLModule``
- ``JSONModule``
