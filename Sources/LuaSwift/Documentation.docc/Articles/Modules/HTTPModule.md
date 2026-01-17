# HTTP Module

HTTP client for network requests.

## Overview

The HTTP module provides a simple HTTP client for making network requests from Lua. Available as `http` global after installation.

## Installation

```swift
ModuleRegistry.installHTTPModule(in: engine)
```

```lua
local http = require("luaswift.http")
```

## GET Requests

### http.get(url, options?)
Perform HTTP GET request.

```lua
local response = http.get("https://api.example.com/data")

print("Status:", response.status)
print("Body:", response.body)
print("Headers:", response.headers["content-type"])
```

## POST Requests

### http.post(url, body?, options?)
Perform HTTP POST request.

```lua
local json = require("luaswift.json")

local data = {name = "Alice", email = "alice@example.com"}
local body = json.encode(data)

local response = http.post("https://api.example.com/users", body, {
    headers = {
        ["Content-Type"] = "application/json"
    }
})

print("Status:", response.status)
```

## Other HTTP Methods

### http.put(url, body?, options?)
```lua
local response = http.put("https://api.example.com/users/123", body)
```

### http.delete(url, options?)
```lua
local response = http.delete("https://api.example.com/users/123")
```

### http.patch(url, body?, options?)
```lua
local response = http.patch("https://api.example.com/users/123", body)
```

## Request Options

```lua
local response = http.get(url, {
    headers = {
        ["Authorization"] = "Bearer token123",
        ["User-Agent"] = "LuaSwift/1.0"
    },
    timeout = 30,  -- seconds
    follow_redirects = true
})
```

## Response Object

```lua
local response = http.get(url)

-- Properties
print(response.status)        -- HTTP status code (200, 404, etc.)
print(response.body)          -- Response body as string
print(response.headers)       -- Table of headers
print(response.url)           -- Final URL (after redirects)
```

## Working with JSON APIs

```lua
local http = require("luaswift.http")
local json = require("luaswift.json")

-- Fetch data
local response = http.get("https://api.github.com/users/octocat")
if response.status == 200 then
    local user = json.decode(response.body)
    print("Name:", user.name)
    print("Followers:", user.followers)
end

-- Post data
local new_user = {username = "newuser", email = "new@example.com"}
local response = http.post(
    "https://api.example.com/users",
    json.encode(new_user),
    {headers = {["Content-Type"] = "application/json"}}
)

if response.status == 201 then
    print("User created successfully")
end
```

## Error Handling

```lua
local success, response = pcall(function()
    return http.get("https://invalid-url.example.com")
end)

if success then
    if response.status == 200 then
        print("Success:", response.body)
    else
        print("HTTP error:", response.status)
    end
else
    print("Network error:", response)
end
```

## Authentication

### Bearer Token

```lua
local token = "your_api_token"
local response = http.get("https://api.example.com/protected", {
    headers = {
        ["Authorization"] = "Bearer " .. token
    }
})
```

### Basic Authentication

```lua
local credentials = "username:password"
local encoded = base64.encode(credentials)  -- You'd need base64 encoding

local response = http.get("https://api.example.com/protected", {
    headers = {
        ["Authorization"] = "Basic " .. encoded
    }
})
```

## Query Parameters

```lua
-- Manual construction
local params = "?page=1&limit=10&sort=name"
local response = http.get("https://api.example.com/items" .. params)

-- Or build programmatically
local function build_query(params)
    local parts = {}
    for key, value in pairs(params) do
        table.insert(parts, key .. "=" .. tostring(value))
    end
    return "?" .. table.concat(parts, "&")
end

local query = build_query({page = 1, limit = 10, sort = "name"})
local response = http.get("https://api.example.com/items" .. query)
```

## Form Data

```lua
local form_data = "username=alice&password=secret123"

local response = http.post("https://example.com/login", form_data, {
    headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }
})
```

## Downloading Files

```lua
local http = require("luaswift.http")
local io = require("luaswift.iox")

local response = http.get("https://example.com/file.pdf")

if response.status == 200 then
    io.write_file("downloaded.pdf", response.body)
    print("File downloaded")
end
```

## Uploading Data

```lua
local http = require("luaswift.http")
local io = require("luaswift.iox")

-- Read file
local content = io.read_file("data.txt")

-- Upload
local response = http.put("https://api.example.com/upload", content, {
    headers = {
        ["Content-Type"] = "text/plain"
    }
})
```

## REST API Client Example

```lua
local http = require("luaswift.http")
local json = require("luaswift.json")

local API = {
    base_url = "https://api.example.com",
    token = nil
}

function API:set_token(token)
    self.token = token
end

function API:request(method, endpoint, body)
    local url = self.base_url .. endpoint
    local options = {
        headers = {
            ["Content-Type"] = "application/json"
        }
    }

    if self.token then
        options.headers["Authorization"] = "Bearer " .. self.token
    end

    local response
    if method == "GET" then
        response = http.get(url, options)
    elseif method == "POST" then
        response = http.post(url, json.encode(body), options)
    elseif method == "PUT" then
        response = http.put(url, json.encode(body), options)
    elseif method == "DELETE" then
        response = http.delete(url, options)
    end

    if response.status >= 200 and response.status < 300 then
        return json.decode(response.body)
    else
        error("API error: " .. response.status)
    end
end

-- Usage
API:set_token("your_token_here")
local users = API:request("GET", "/users")
local new_user = API:request("POST", "/users", {name = "Alice"})
```

## Webhook Handler Example

```lua
-- Receive webhook data (this would be called by your app)
local function handle_webhook(request_body)
    local json = require("luaswift.json")
    local http = require("luaswift.http")

    local data = json.decode(request_body)

    -- Process the webhook
    print("Received event:", data.event)

    -- Send acknowledgment
    local response = http.post("https://api.example.com/ack", json.encode({
        received = true,
        event_id = data.id
    }))

    return response.status == 200
end
```

## Performance Notes

- Requests are synchronous and blocking
- For multiple requests, consider making them sequentially
- Set appropriate timeout values for slow APIs
- Cache responses when possible to reduce network traffic

## Security Notes

- Always use HTTPS for sensitive data
- Never hardcode API keys in Lua scripts
- Pass credentials from Swift code securely
- Validate response data before using it

## See Also

- ``HTTPModule``
- <doc:Modules/IOModule>
- <doc:JSONModule>
