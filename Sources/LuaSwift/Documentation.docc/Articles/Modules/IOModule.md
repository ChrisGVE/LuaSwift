# IO Module

Sandboxed file I/O operations.

## Overview

The IO module provides file system access within explicitly configured directories. It replaces Lua's standard `io` library with a secure, sandboxed alternative. Available as `iox` global after installation.

## Installation

```swift
// Configure allowed directories first
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].path

IOModule.setAllowedDirectories([documentsPath, cachePath], for: engine)

// Then install the module
ModuleRegistry.installIOModule(in: engine)
```

```lua
local io = require("luaswift.iox")
```

## Security Model

- Lua scripts can only access files in explicitly allowed directories
- Path traversal attempts (e.g., `../../../`) are blocked
- Absolute paths outside allowed directories are rejected
- Symbolic links are resolved and checked against allowed paths

## File Reading

### io.read_file(path)
Read entire file as string.

```lua
local content = io.read_file("data.txt")
print(content)
```

### io.read_lines(path)
Read file as array of lines.

```lua
local lines = io.read_lines("data.txt")
for i, line in ipairs(lines) do
    print(i, line)
end
```

## File Writing

### io.write_file(path, content)
Write string to file (overwrites existing).

```lua
io.write_file("output.txt", "Hello, world!")
```

### io.append_file(path, content)
Append string to file.

```lua
io.append_file("log.txt", "New entry\n")
```

## File Operations

### io.exists(path)
Check if file or directory exists.

```lua
if io.exists("config.json") then
    print("Config found")
end
```

### io.remove(path)
Delete file or empty directory.

```lua
io.remove("temp.txt")
```

### io.copy(source, dest)
Copy file.

```lua
io.copy("data.txt", "backup.txt")
```

### io.move(source, dest)
Move or rename file.

```lua
io.move("old_name.txt", "new_name.txt")
```

## Directory Operations

### io.mkdir(path)
Create directory (creates parent directories if needed).

```lua
io.mkdir("data/exports")
```

### io.list_dir(path)
List directory contents.

```lua
local files = io.list_dir(".")
for _, name in ipairs(files) do
    print(name)
end
```

### io.is_dir(path)
Check if path is a directory.

```lua
if io.is_dir("data") then
    print("data is a directory")
end
```

## File Info

### io.file_size(path)
Get file size in bytes.

```lua
local size = io.file_size("data.txt")
print("Size: " .. size .. " bytes")
```

### io.modified_time(path)
Get last modification timestamp.

```lua
local timestamp = io.modified_time("data.txt")
print("Last modified:", os.date("%c", timestamp))
```

## Working with JSON

```lua
local io = require("luaswift.iox")
local json = require("luaswift.json")

-- Save data
local data = {name = "Alice", age = 30, scores = {95, 87, 92}}
local json_str = json.encode(data)
io.write_file("data.json", json_str)

-- Load data
local loaded_str = io.read_file("data.json")
local loaded_data = json.decode(loaded_str)
print(loaded_data.name)  -- "Alice"
```

## Working with CSV

```lua
local io = require("luaswift.iox")

-- Write CSV
local csv_lines = {
    "Name,Age,Score",
    "Alice,25,95",
    "Bob,30,87",
    "Charlie,28,92"
}
io.write_file("data.csv", table.concat(csv_lines, "\n"))

-- Read CSV
local lines = io.read_lines("data.csv")
local header = lines[1]
for i = 2, #lines do
    print(lines[i])
end
```

## Logging Example

```lua
local io = require("luaswift.iox")

local function log(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local entry = timestamp .. " - " .. message .. "\n"
    io.append_file("app.log", entry)
end

log("Application started")
log("User logged in")
log("Processing complete")
```

## Configuration Files

```lua
local io = require("luaswift.iox")
local toml = require("luaswift.toml")

-- Load configuration
local function load_config()
    if io.exists("config.toml") then
        local content = io.read_file("config.toml")
        return toml.decode(content)
    else
        return {
            theme = "light",
            font_size = 14,
            auto_save = true
        }
    end
end

-- Save configuration
local function save_config(config)
    local content = toml.encode(config)
    io.write_file("config.toml", content)
end

local config = load_config()
config.font_size = 16
save_config(config)
```

## Data Export

```lua
local io = require("luaswift.iox")
local plot = require("luaswift.plot")

-- Generate plot
local fig = plot.figure()
local ax = fig:subplot(1, 1, 1)
ax:plot({1, 2, 3, 4}, {1, 4, 9, 16})
ax:set_title("Data Visualization")

-- Export to SVG
local svg = fig:render()
io.write_file("plot.svg", svg)
print("Plot saved to plot.svg")
```

## Batch Processing

```lua
local io = require("luaswift.iox")

-- Process all text files in directory
local files = io.list_dir("input")

for _, filename in ipairs(files) do
    if filename:match("%.txt$") then
        local input_path = "input/" .. filename
        local output_path = "output/" .. filename

        -- Read, process, write
        local content = io.read_file(input_path)
        local processed = string.upper(content)  -- Example processing
        io.write_file(output_path, processed)

        print("Processed: " .. filename)
    end
end
```

## Error Handling

```lua
local io = require("luaswift.iox")

local success, result = pcall(function()
    return io.read_file("nonexistent.txt")
end)

if success then
    print("File content:", result)
else
    print("Error reading file:", result)
end
```

## Security Notes

- All paths are validated against allowed directories
- Attempting to access forbidden paths raises an error
- Use `pcall()` to catch and handle access violations
- Allowed directories are set per-engine by Swift code

## See Also

- ``IOModule``
- <doc:Modules/HTTPModule>
- <doc:JSONModule>
