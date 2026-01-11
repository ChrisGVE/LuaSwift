# JSON Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.json` | **Global:** `json`

JSON encoding and decoding with support for nested structures, Unicode, and pretty printing.

## Function Reference

| Function | Description |
|----------|-------------|
| [decode(string)](#decode) | Parse JSON string to Lua value |
| [encode(value, options?)](#encode) | Convert Lua value to JSON string |
| [null](#null) | Sentinel value for JSON null |

## Type Mapping

| JSON | Lua |
|------|-----|
| object | table |
| array | table (array) |
| string | string |
| number | number |
| boolean | boolean |
| null | json.null |

---

## decode

```
json.decode(string) -> value
```

Parse JSON string to Lua value.

```lua
local data = json.decode('{"name": "John", "age": 30}')
print(data.name)  -- "John"
print(data.age)   -- 30

-- Arrays
local arr = json.decode('[1, 2, 3]')
print(arr[1])  -- 1

-- Nested structures
local complex = json.decode('{"users": [{"id": 1}, {"id": 2}]}')
print(complex.users[1].id)  -- 1
```

**Errors:** Throws on invalid JSON syntax.

---

## encode

```
json.encode(value, options?) -> string
```

Convert Lua value to JSON string.

**Parameters:**
- `value` - Lua value to encode (table, string, number, boolean, or json.null)
- `options` (optional) - Table with encoding options:
  - `pretty` (boolean): Enable pretty printing with newlines
  - `indent` (number): Spaces per indentation level (default: 2)

```lua
local str = json.encode({items = {1, 2, 3}, active = true})
-- '{"active":true,"items":[1,2,3]}'

-- Pretty print
local pretty = json.encode({a = 1, b = 2}, {pretty = true})
-- '{\n  "a": 1,\n  "b": 2\n}'

-- Custom indentation
local indented = json.encode({a = 1}, {pretty = true, indent = 4})
```

---

## null

Sentinel value representing JSON null.

```lua
-- Decoding null
local data = json.decode('{"value": null}')
if data.value == json.null then
    print("Value is null")
end

-- Encoding null
local str = json.encode({value = json.null})
-- '{"value":null}'
```

---

## Examples

### Round-Trip

```lua
local original = {
    name = "Test",
    values = {1, 2, 3},
    nested = {a = 1, b = 2}
}

local encoded = json.encode(original)
local decoded = json.decode(encoded)

print(decoded.name)  -- "Test"
print(decoded.values[2])  -- 2
```

### Error Handling

```lua
local ok, err = pcall(function()
    json.decode('not valid json')
end)
if not ok then
    print("Parse error:", err)
end
```

### Unicode Support

```lua
local data = json.encode({greeting = "Hello, 世界"})
local decoded = json.decode(data)
print(decoded.greeting)  -- "Hello, 世界"
```
