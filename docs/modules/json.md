# JSON Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.json` | **Global:** `json`

JSON encoding and decoding with support for nested structures, Unicode, and pretty printing.

## Function Reference

| Function | Description |
|----------|-------------|
| [decode(string, options?)](#decode) | Parse JSON string to Lua value |
| [decode_jsonc(string)](#decode_jsonc) | Parse JSONC (JSON with comments) string |
| [decode_json5(string)](#decode_json5) | Parse JSON5 (relaxed JSON) string |
| [encode(value, options?)](#encode) | Convert Lua value to JSON string |
| [is_null(v)](#is_null) | Test whether a value is the JSON null sentinel |
| [null](#null) | Sentinel value representing JSON null |

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
json.decode(string, options?) -> value
```

Parse JSON string to Lua value.

**Parameters:**
- `string` - JSON string to parse
- `options` (optional) - Table with decoding options:
  - `format` (string): `"json"` (default), `"jsonc"`, or `"json5"`
  - `comments` (boolean): shorthand for `format = "jsonc"` when `true`

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

-- JSONC via options
local data2 = json.decode('{"x": 1 /* comment */}', {format = "jsonc"})
local data3 = json.decode('{"x": 1 // line comment\n}', {comments = true})
```

**Errors:** Throws on invalid syntax for the chosen format.

---

## decode_jsonc

```
json.decode_jsonc(string) -> value
```

Parse a JSONC string (JSON with `//` line comments and `/* */` block comments).
Equivalent to `json.decode(string, {format = "jsonc"})`.

```lua
local data = json.decode_jsonc([[
{
    // user record
    "name": "John",
    "age": 30  /* current age */
}
]])
print(data.name)  -- "John"
```

**Errors:** Throws on invalid JSONC syntax.

---

## decode_json5

```
json.decode_json5(string) -> value
```

Parse a JSON5 string (relaxed JSON: unquoted keys, trailing commas, single-quoted
strings, hex literals, `Infinity`, `NaN`, comments).

```lua
local data = json.decode_json5([[
{
    name: 'John',   // unquoted key, single-quoted string
    age: 0x1E,      // hex literal (30)
}
]])
print(data.name)  -- "John"
print(data.age)   -- 30
```

**Errors:** Throws on invalid JSON5 syntax.

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

Sentinel value representing JSON null. `json.null` is the canonical, internal
representation of a JSON null on the Lua side: decoding a JSON `null` yields it,
and encoding it produces a JSON `null`, so null survives a round-trip (a plain
Lua `nil` could not — it would drop its key from the containing table).

Prefer `json.is_null(v)` over `v == json.null` to test for it; the predicate
also guards against a user table that happens to carry the internal marker key.

```lua
-- Decoding null
local data = json.decode('{"value": null}')
if json.is_null(data.value) then
    print("Value is null")
end

-- Encoding null
local str = json.encode({value = json.null})
-- '{"value":null}'
```

The HTTP module honors the same sentinel: a `json.null` value inside a request's
`json` body encodes as JSON `null` (see [http](http.md)).

> **Swift note.** The Swift-side `JSONNull` struct and `JSONModule.null` static
> are **deprecated** (slated for removal in 2.0) — they were never bridged into
> the Lua conversion paths. `json.null` (tested with `json.is_null`) is the one
> canonical JSON-null representation.

---

## is_null

```
json.is_null(v) -> boolean
```

Return `true` if `v` is the JSON null sentinel or a value produced by decoding a
JSON `null`.

Prefer this over `v == json.null`: `json.decode` produces a fresh table instance
for each decoded null, so identity comparison (`==`) would return `false` for
decoded nulls. `is_null` checks the internal marker field and verifies it is the
sole key, so ordinary objects that happen to contain the marker key are not treated
as null.

```lua
local data = json.decode('{"a": null, "b": 1}')

-- identity check FAILS for decoded nulls:
print(data.a == json.null)   -- false (distinct table instances)

-- is_null works correctly:
print(json.is_null(data.a))  -- true
print(json.is_null(data.b))  -- false
print(json.is_null(json.null))  -- true
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
