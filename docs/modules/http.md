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

## HTTP Methods

```lua
local http = require("luaswift.http")

-- GET request
local resp = http.get("https://api.example.com/data")

-- POST request
local resp = http.post("https://api.example.com/users", options)

-- Other methods
http.put(url, options)
http.patch(url, options)
http.delete(url, options)
http.head(url, options)    -- Returns headers only, empty body
http.options(url, options)

-- Generic request function
http.request("GET", url, options)
```

## Response Object

```lua
local resp = http.get("https://api.example.com/data")

resp.status   -- HTTP status code (number): 200, 404, 500, etc.
resp.ok       -- true if status is 200-299 (boolean)
resp.headers  -- Response headers (table)
resp.body     -- Response body (string)
resp.url      -- Final URL after redirects (string)
```

## Request Options

```lua
{
    headers = {},            -- Table of request headers
    body = "string",         -- Raw body content
    json = {},               -- Table auto-encoded as JSON
    timeout = 30,            -- Timeout in seconds (default: 30)
    follow_redirects = true  -- Follow HTTP redirects (default: true)
}
```

## Examples

### Simple GET

```lua
local resp = http.get("https://api.github.com/users/octocat")
print(resp.status)  -- 200
print(resp.ok)      -- true
print(resp.body)    -- JSON string
```

### GET with Headers

```lua
local resp = http.get("https://api.example.com/data", {
    headers = {
        ["Authorization"] = "Bearer token123",
        ["Accept"] = "application/json"
    }
})
```

### POST with JSON

```lua
-- Auto-sets Content-Type: application/json
local resp = http.post("https://api.example.com/users", {
    json = {name = "John", email = "john@example.com"}
})
```

### POST with Raw Body

```lua
local resp = http.post("https://api.example.com/data", {
    headers = {["Content-Type"] = "text/plain"},
    body = "Raw content here"
})
```

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

## Error Handling

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

## Security Considerations

- HTTPModule is **not** included in `ModuleRegistry.installModules()` by default
- Host application must explicitly call `ModuleRegistry.installHTTPModule(in:)`
- This allows apps to control whether Lua scripts can make network requests
- Consider your app's security requirements before enabling
- All requests go through URLSession with standard iOS/macOS security

## Function Reference

| Function | Description |
|----------|-------------|
| `get(url, options?)` | HTTP GET request |
| `post(url, options?)` | HTTP POST request |
| `put(url, options?)` | HTTP PUT request |
| `patch(url, options?)` | HTTP PATCH request |
| `delete(url, options?)` | HTTP DELETE request |
| `head(url, options?)` | HTTP HEAD request (headers only) |
| `options(url, options?)` | HTTP OPTIONS request |
| `request(method, url, options?)` | Generic request with any method |
