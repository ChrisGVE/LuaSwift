# HTTP Module

Opt-in HTTP client for making network requests from Lua.

## Overview

The HTTP module provides a synchronous HTTP client backed by `URLSession`. It supports all common HTTP methods, custom headers, raw string bodies, automatic JSON encoding, redirect control, and a per-engine session cache.

**This module is opt-in.** It is not included in `ModuleRegistry.installModules()` because network access may not be appropriate in every environment. Install it explicitly before use.

## Installation

```swift
let engine = try LuaEngine()
ModuleRegistry.installHTTPModule(in: engine)
```

```lua
local http = require("luaswift.http")
```

The module is also accessible as `luaswift.http` once installed.

## Quick Start

```lua
local http = require("luaswift.http")

-- Simple GET
local resp = http.get("https://api.example.com/data")
print(resp.status)   -- 200
print(resp.ok)       -- true
print(resp.body)     -- response body as string

-- POST with JSON (auto-encoded)
local resp = http.post("https://api.example.com/users", {
    json = {name = "Alice", email = "alice@example.com"}
})
print(resp.status)   -- 201

-- POST with raw string body
local resp = http.post("https://api.example.com/data", {
    headers = {["Content-Type"] = "application/json"},
    body = '{"key": "value"}'
})
```

## API Reference

### http.get(url, options?)

Perform an HTTP GET request.

**Parameters:**
- `url` (string) — The request URL
- `options` (table, optional) — Request options (see [Options](#options))

**Returns:** Response object (see [Response Object](#response-object))

```lua
local resp = http.get("https://api.example.com/items")
local resp = http.get("https://api.example.com/items", {
    headers = {["Authorization"] = "Bearer token123"},
    timeout = 10
})
```

### http.post(url, options?)

Perform an HTTP POST request. Supply the request body via the `body` or `json` option.

**Parameters:**
- `url` (string) — The request URL
- `options` (table, optional) — Request options (see [Options](#options))

**Returns:** Response object

```lua
-- Raw body
local resp = http.post("https://api.example.com/login", {
    headers = {["Content-Type"] = "application/x-www-form-urlencoded"},
    body = "username=alice&password=secret"
})

-- Auto-encoded JSON (sets Content-Type automatically)
local resp = http.post("https://api.example.com/users", {
    json = {name = "Alice", role = "admin"}
})
```

### http.put(url, options?)

Perform an HTTP PUT request.

```lua
local resp = http.put("https://api.example.com/users/42", {
    json = {name = "Alice", email = "new@example.com"}
})
```

### http.patch(url, options?)

Perform an HTTP PATCH request.

```lua
local resp = http.patch("https://api.example.com/users/42", {
    json = {email = "updated@example.com"}
})
```

### http.delete(url, options?)

Perform an HTTP DELETE request.

```lua
local resp = http.delete("https://api.example.com/users/42")
```

### http.head(url, options?)

Perform an HTTP HEAD request. The response body will be empty; use the status code and headers.

```lua
local resp = http.head("https://api.example.com/resource")
print(resp.status)
print(resp.headers["Content-Length"])
```

### http.options(url, options?)

Perform an HTTP OPTIONS request.

```lua
local resp = http.options("https://api.example.com/resource")
print(resp.headers["Allow"])
```

### http.request(method, url, options?)

Generic request function. `method` is an uppercase HTTP method string.

```lua
local resp = http.request("GET", "https://api.example.com/data")
local resp = http.request("POST", "https://api.example.com/data", {
    json = {key = "value"}
})
```

## Options

All HTTP methods accept an optional options table with these keys:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `headers` | table | `{}` | Request headers as key-value pairs |
| `body` | string | nil | Raw request body (UTF-8 string) |
| `json` | table/value | nil | Lua value to auto-encode as JSON body; sets `Content-Type: application/json` if not already set |
| `timeout` | number | `30` | Request timeout in seconds |
| `follow_redirects` | boolean | `true` | Follow HTTP redirects; set to `false` to receive the 3xx response directly |

When both `body` and `json` are provided, `json` takes precedence.

```lua
local resp = http.get("https://api.example.com/data", {
    headers = {
        ["Authorization"] = "Bearer token123",
        ["User-Agent"] = "LuaSwift/1.0"
    },
    timeout = 60,
    follow_redirects = false
})
```

## Response Object

Every request returns a Lua table with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `status` | number | HTTP status code (e.g. `200`, `404`) |
| `ok` | boolean | `true` when status is 2xx (200–299) |
| `body` | string | Response body as a UTF-8 string; if the response body is not valid UTF-8, it is base64-encoded instead |
| `body_is_base64` | boolean | Present and `true` when `body` contains a base64-encoded binary payload |
| `headers` | table | Response headers as key-value string pairs |
| `url` | string | Final URL after any redirects |

```lua
local resp = http.get("https://api.example.com/data")

print(resp.status)              -- 200
print(resp.ok)                  -- true
print(resp.body)                -- response body string
print(resp.headers["Content-Type"])
print(resp.url)                 -- final URL (may differ from request URL after redirects)

if resp.body_is_base64 then
    -- body contains binary data encoded as base64
end
```

## Working with JSON APIs

Use the `json` request option to send JSON without a separate encode step. Parse the response body with `luaswift.json`.

```lua
local http = require("luaswift.http")
local json = require("luaswift.json")

-- Fetch a resource
local resp = http.get("https://api.github.com/users/octocat", {
    headers = {["Accept"] = "application/vnd.github+json"}
})

if resp.ok then
    local user = json.decode(resp.body)
    print("Name:", user.name)
    print("Followers:", user.followers)
else
    print("HTTP error:", resp.status)
end

-- Create a resource
local resp = http.post("https://api.example.com/items", {
    json = {title = "New Item", priority = 1}
})

if resp.ok then
    local created = json.decode(resp.body)
    print("Created ID:", created.id)
end
```

## Authentication

### Bearer Token

```lua
local resp = http.get("https://api.example.com/protected", {
    headers = {["Authorization"] = "Bearer " .. token}
})
```

### Basic Authentication

Basic Auth credentials must be base64-encoded by the caller. Build the encoded string from Swift before passing it to Lua, or construct it in Lua using a base64 library of your choice.

```lua
-- Build from Swift (recommended: pass the pre-encoded header value via a value server)
local resp = http.get("https://api.example.com/protected", {
    headers = {["Authorization"] = "Basic " .. encoded_credentials}
})
```

## Redirect Control

By default the module follows redirects. Set `follow_redirects = false` to receive the 3xx response instead.

```lua
local resp = http.get("https://example.com/redirect", {
    follow_redirects = false
})
-- resp.status == 301 or 302
-- resp.headers["Location"] contains the redirect target
print(resp.headers["Location"])
```

## Error Handling

Network failures and invalid URLs throw a Lua error. Use `pcall` to handle them gracefully. HTTP error status codes (4xx, 5xx) do **not** throw; check `resp.ok` or `resp.status` instead.

```lua
local http = require("luaswift.http")

-- Network / URL errors throw
local ok, result = pcall(function()
    return http.get("https://unreachable.invalid")
end)

if not ok then
    print("Network error:", result)
    return
end

-- HTTP errors are in the response, not exceptions
if result.ok then
    print("Success:", result.body)
elseif result.status == 404 then
    print("Not found")
elseif result.status >= 500 then
    print("Server error:", result.status)
end
```

## Query Parameters

Build query strings manually or programmatically:

```lua
-- Manual
local resp = http.get("https://api.example.com/items?page=1&limit=10")

-- Programmatic
local function build_query(params)
    local parts = {}
    for key, value in pairs(params) do
        table.insert(parts, key .. "=" .. tostring(value))
    end
    return "?" .. table.concat(parts, "&")
end

local resp = http.get(
    "https://api.example.com/items" .. build_query({page = 1, limit = 10, sort = "name"})
)
```

## REST API Client Pattern

```lua
local http = require("luaswift.http")
local json = require("luaswift.json")

local API = {base_url = "https://api.example.com", token = nil}

function API:auth(token) self.token = token end

function API:call(method, endpoint, payload)
    local opts = {headers = {["Accept"] = "application/json"}}
    if self.token then
        opts.headers["Authorization"] = "Bearer " .. self.token
    end
    if payload then
        opts.json = payload
    end
    local resp = http.request(method, self.base_url .. endpoint, opts)
    if resp.ok then
        return json.decode(resp.body)
    else
        error("API error " .. resp.status .. ": " .. resp.body)
    end
end

-- Usage
API:auth("your_token_here")
local users = API:call("GET", "/users")
local item  = API:call("POST", "/items", {name = "Widget", qty = 5})
```

## Performance Notes

- Requests are **synchronous and blocking**. Do not call from the main thread in UI applications.
- Each `LuaEngine` shares a pair of `URLSession` instances (one that follows redirects, one that does not). Sessions are created on first use and invalidated when the engine is deallocated.
- Set appropriate `timeout` values; the default is 30 seconds.

## Security Notes

- Always use HTTPS for sensitive data.
- Never hardcode API keys in Lua scripts. Pass credentials from Swift via a value server or registered function.
- Validate response data before using it.
- The module does not perform certificate pinning; rely on the system trust store.

## See Also

- ``HTTPModule``
- <doc:IOModule>
- <doc:JSONModule>
