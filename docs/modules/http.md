# HTTP Module (Network Client)

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.http` | **Global:** `http`

HTTP client using URLSession for making network requests.

> **Note**: HTTPModule requires explicit installation. The host application controls whether Lua scripts can make network requests.

## Swift Setup (Required)

```swift
import LuaSwift

let engine = try LuaEngine()

// Explicitly install HTTP module to enable network access
ModuleRegistry.installHTTPModule(in: engine)

// Optionally also install JSON for parsing responses
ModuleRegistry.installJSONModule(in: engine)
```

## Function Reference

| Function | Description |
|----------|-------------|
| [get(url, options?)](#get) | HTTP GET request |
| [post(url, options?)](#post) | HTTP POST request |
| [put(url, options?)](#put) | HTTP PUT request |
| [patch(url, options?)](#patch) | HTTP PATCH request |
| [delete(url, options?)](#delete) | HTTP DELETE request |
| [head(url, options?)](#head) | HTTP HEAD request (headers only) |
| [options(url, options?)](#options) | HTTP OPTIONS request |
| [request(method, url, options?)](#request) | Generic request with any method |

## Response Object

All HTTP functions return a response object with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `status` | number | HTTP status code (200, 404, 500, etc.) |
| `ok` | boolean | true if status is 200-299 |
| `headers` | table | Response headers |
| `body` | string | Response body |
| `url` | string | Final URL after redirects |

## Request Options

All HTTP functions accept an optional options table:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `headers` | table | {} | Request headers |
| `body` | string | nil | Raw body content |
| `json` | table | nil | Table auto-encoded as JSON |
| `timeout` | number | 30 | Timeout in seconds |
| `follow_redirects` | boolean | true | Follow HTTP redirects |

---

## get

```
http.get(url, options?) -> response
```

Perform an HTTP GET request.

**Parameters:**
- `url` (string) - The URL to request
- `options` (table, optional) - Request options (see Request Options above)

**Returns:** Response object with `status`, `ok`, `headers`, `body`, and `url` fields.

```lua
local http = require("luaswift.http")

-- Simple GET
local resp = http.get("https://api.github.com/users/octocat")
print(resp.status)  -- 200
print(resp.ok)      -- true
print(resp.body)    -- JSON string

-- GET with headers
local resp = http.get("https://api.example.com/data", {
    headers = {
        ["Authorization"] = "Bearer token123",
        ["Accept"] = "application/json"
    }
})
```

**Errors:** Throws on invalid URL, network errors, or timeout.

---

## post

```
http.post(url, options?) -> response
```

Perform an HTTP POST request.

**Parameters:**
- `url` (string) - The URL to request
- `options` (table, optional) - Request options (see Request Options above)

**Returns:** Response object with `status`, `ok`, `headers`, `body`, and `url` fields.

```lua
-- POST with JSON (auto-sets Content-Type: application/json)
local resp = http.post("https://api.example.com/users", {
    json = {name = "John", email = "john@example.com"}
})

-- POST with raw body
local resp = http.post("https://api.example.com/data", {
    headers = {["Content-Type"] = "text/plain"},
    body = "Raw content here"
})
```

**Errors:** Throws on invalid URL, network errors, or timeout.

---

## put

```
http.put(url, options?) -> response
```

Perform an HTTP PUT request.

**Parameters:**
- `url` (string) - The URL to request
- `options` (table, optional) - Request options (see Request Options above)

**Returns:** Response object with `status`, `ok`, `headers`, `body`, and `url` fields.

```lua
local resp = http.put("https://api.example.com/users/123", {
    json = {name = "Jane", email = "jane@example.com"}
})
```

**Errors:** Throws on invalid URL, network errors, or timeout.

---

## patch

```
http.patch(url, options?) -> response
```

Perform an HTTP PATCH request.

**Parameters:**
- `url` (string) - The URL to request
- `options` (table, optional) - Request options (see Request Options above)

**Returns:** Response object with `status`, `ok`, `headers`, `body`, and `url` fields.

```lua
local resp = http.patch("https://api.example.com/users/123", {
    json = {email = "newemail@example.com"}
})
```

**Errors:** Throws on invalid URL, network errors, or timeout.

---

## delete

```
http.delete(url, options?) -> response
```

Perform an HTTP DELETE request.

**Parameters:**
- `url` (string) - The URL to request
- `options` (table, optional) - Request options (see Request Options above)

**Returns:** Response object with `status`, `ok`, `headers`, `body`, and `url` fields.

```lua
local resp = http.delete("https://api.example.com/users/123", {
    headers = {["Authorization"] = "Bearer token123"}
})
```

**Errors:** Throws on invalid URL, network errors, or timeout.

---

## head

```
http.head(url, options?) -> response
```

Perform an HTTP HEAD request. Returns only headers, with an empty body.

**Parameters:**
- `url` (string) - The URL to request
- `options` (table, optional) - Request options (see Request Options above)

**Returns:** Response object with `status`, `ok`, `headers`, empty `body`, and `url` fields.

```lua
local resp = http.head("https://api.example.com/large-file")
print(resp.headers["Content-Length"])
print(resp.body)  -- "" (empty)
```

**Errors:** Throws on invalid URL, network errors, or timeout.

---

## options

```
http.options(url, options?) -> response
```

Perform an HTTP OPTIONS request.

**Parameters:**
- `url` (string) - The URL to request
- `options` (table, optional) - Request options (see Request Options above)

**Returns:** Response object with `status`, `ok`, `headers`, `body`, and `url` fields.

```lua
local resp = http.options("https://api.example.com/endpoint")
print(resp.headers["Allow"])  -- "GET, POST, PUT, DELETE"
```

**Errors:** Throws on invalid URL, network errors, or timeout.

---

## request

```
http.request(method, url, options?) -> response
```

Generic request function supporting any HTTP method.

**Parameters:**
- `method` (string) - HTTP method (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, etc.)
- `url` (string) - The URL to request
- `options` (table, optional) - Request options (see Request Options above)

**Returns:** Response object with `status`, `ok`, `headers`, `body`, and `url` fields.

```lua
-- Custom method
local resp = http.request("PROPFIND", "https://webdav.example.com/files")

-- Equivalent to http.get()
local resp = http.request("GET", "https://api.example.com/data")
```

**Errors:** Throws on invalid URL, network errors, or timeout.

---

## Examples

### Fetching and Parsing JSON

```lua
local http = require("luaswift.http")
local json = require("luaswift.json")

local resp = http.get("https://api.github.com/users/octocat")
if resp.ok then
    local user = json.decode(resp.body)
    print("Name:", user.name)
    print("Location:", user.location)
else
    print("Error:", resp.status)
end
```

### Custom Timeout

```lua
local resp = http.get("https://slow-api.example.com/data", {
    timeout = 60  -- 60 seconds
})
```

### Disable Redirect Following

```lua
local resp = http.get("https://example.com/redirect", {
    follow_redirects = false
})
-- resp.status might be 301/302
-- resp.headers["Location"] contains redirect URL
```

### Error Handling

```lua
-- Invalid URLs throw errors
local ok, err = pcall(function()
    http.get("ht tp://invalid url")
end)
if not ok then
    print(err)  -- "Invalid URL: ht tp://invalid url"
end

-- Timeouts throw errors
local ok, err = pcall(function()
    http.get("https://httpbin.org/delay/10", {timeout = 1})
end)
if not ok then
    print(err)  -- "Request timed out" or similar
end

-- Network errors throw errors
local ok, err = pcall(function()
    http.get("https://nonexistent.invalid/")
end)
if not ok then
    print(err)  -- Network error message
end
```

---

## Security Considerations

- HTTPModule is **not** included in `ModuleRegistry.installModules()` by default
- Host application must explicitly call `ModuleRegistry.installHTTPModule(in:)`
- This allows apps to control whether Lua scripts can make network requests
- Consider your app's security requirements before enabling
- All requests go through URLSession with standard iOS/macOS security
