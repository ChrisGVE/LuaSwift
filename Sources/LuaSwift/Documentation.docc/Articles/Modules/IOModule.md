# IO Module

Sandboxed file I/O with path utilities, restricted to explicitly allowed directories.

## Overview

The IO module (`luaswift.iox`) provides file system access within explicitly configured directories. It replaces Lua's standard `io` library with a secure, sandboxed alternative.

> Important: This module is **opt-in** and is not included in the default ``ModuleRegistry/installModules(in:)`` call. You must configure allowed directories and install the module explicitly before Lua scripts can use it.

## Installation

```swift
let engine = try LuaEngine()

// Configure allowed directories FIRST
let documentsPath = FileManager.default.urls(
    for: .documentDirectory, in: .userDomainMask)[0].path

IOModule.setAllowedDirectories([documentsPath], for: engine)

// Then install the module
ModuleRegistry.installIOModule(in: engine)
```

```lua
local iox = require("luaswift.iox")
```

The module is also accessible as the global `luaswift.iox` table without `require`.

## Security Model

- Lua scripts can only access paths inside explicitly allowed directories.
- Path traversal attempts (`../../../`) are detected and blocked.
- Absolute paths outside allowed directories are rejected.
- Symbolic links are resolved to their real targets and checked against allowed paths before any operation.
- `iox.exists` and the `is_*` predicates return `false` instead of throwing when a path is outside the sandbox.

## File Reading

### iox.read_file(path)

Reads an entire file and returns its contents as a string.

```lua
local iox = require("luaswift.iox")
local content = iox.read_file("/documents/notes.txt")
print(content)
```

**Returns:** string — the file contents encoded as UTF-8.

## File Writing

### iox.write_file(path, content)

Writes a string to a file, replacing any existing content. The write is atomic.

```lua
iox.write_file("/documents/output.txt", "Hello, world!")
```

**Returns:** `true` on success; throws on error.

### iox.append_file(path, content)

Appends a string to an existing file. Creates the file if it does not exist.

```lua
iox.append_file("/documents/app.log", "New entry\n")
```

**Returns:** `true` on success; throws on error.

## Existence and Type Checks

### iox.exists(path)

Returns `true` if the path exists (file or directory). Returns `false` for paths outside the sandbox instead of throwing.

```lua
if iox.exists("/documents/config.json") then
    print("Config found")
end
```

### iox.is_file(path)

Returns `true` if the path exists and is a regular file (not a directory or symlink).

```lua
if iox.is_file("/documents/report.pdf") then
    print("report.pdf is a regular file")
end
```

### iox.is_dir(path)

Returns `true` if the path exists and is a directory.

```lua
if iox.is_dir("/documents/exports") then
    print("exports directory exists")
end
```

## Directory Operations

### iox.list_dir(path)

Returns an array of entry names (not full paths) in the given directory.

```lua
local files = iox.list_dir("/documents")
for _, name in ipairs(files) do
    print(name)
end
```

### iox.mkdir(path [, options])

Creates a directory. Pass `{parents = true}` to create all intermediate directories (equivalent to `mkdir -p`).

```lua
-- Create a single directory (parent must already exist)
iox.mkdir("/documents/exports")

-- Create nested directories in one call
iox.mkdir("/documents/data/2026/reports", {parents = true})
```

**Returns:** `true` on success; throws on error.

### iox.remove(path)

Deletes a file or empty directory.

```lua
iox.remove("/documents/temp.txt")
```

**Returns:** `true` on success; throws on error.

### iox.rename(old_path, new_path)

Moves or renames a file or directory. Both paths must be within allowed directories.

```lua
iox.rename("/documents/draft.txt", "/documents/final.txt")
```

**Returns:** `true` on success; throws on error.

## File Info

### iox.stat(path)

Returns a table of file metadata. The path must exist within an allowed directory.

```lua
local info = iox.stat("/documents/report.pdf")
print(info.size)        -- number: size in bytes
print(info.is_file)     -- boolean
print(info.is_dir)      -- boolean
print(info.is_symlink)  -- boolean
print(info.modified)    -- number: Unix timestamp (seconds since epoch)
print(info.created)     -- number: Unix timestamp
print(info.permissions) -- number: POSIX permission bits (e.g. 0644)
```

**Returns:** table with keys `size`, `is_file`, `is_dir`, `is_symlink`, `modified`, `created`, `permissions`.

## Path Utilities

The `iox.path` namespace provides path manipulation functions. These functions operate on strings only and do not access the file system.

### iox.path.join(component, ...)

Joins one or more path components. Accepts any number of string arguments.

```lua
local full = iox.path.join("/documents", "exports", "report.pdf")
-- "/documents/exports/report.pdf"
```

### iox.path.basename(path)

Returns the last component of a path.

```lua
iox.path.basename("/documents/exports/report.pdf")  -- "report.pdf"
iox.path.basename("/documents/exports/")             -- "exports"
```

### iox.path.dirname(path)

Returns the directory portion of a path (everything except the last component).

```lua
iox.path.dirname("/documents/exports/report.pdf")  -- "/documents/exports"
```

### iox.path.extension(path)

Returns the file extension without the leading dot, or `nil` if there is none.

```lua
iox.path.extension("/documents/report.pdf")  -- "pdf"
iox.path.extension("/documents/Makefile")    -- nil
```

### iox.path.absolute(path)

Expands `~` and resolves `.` and `..` components to produce an absolute path. Does not resolve symlinks.

```lua
iox.path.absolute("~/Documents/notes.txt")
-- "/Users/alice/Documents/notes.txt"
```

### iox.path.normalize(path)

Resolves `.` and `..` components in a path without expanding `~`. Does not resolve symlinks.

```lua
iox.path.normalize("/documents/../documents/./report.pdf")
-- "/documents/report.pdf"
```

## Working with JSON

```lua
local iox  = require("luaswift.iox")
local json = require("luaswift.json")

-- Save data
local data = {name = "Alice", age = 30, scores = {95, 87, 92}}
iox.write_file("/documents/data.json", json.encode(data, {pretty = true}))

-- Load data
local loaded = json.decode(iox.read_file("/documents/data.json"))
print(loaded.name)  -- "Alice"
```

## Working with TOML Configuration Files

```lua
local iox  = require("luaswift.iox")
local toml = require("luaswift.toml")

local function load_config()
    if iox.exists("/documents/config.toml") then
        return toml.decode(iox.read_file("/documents/config.toml"))
    end
    return {theme = "light", font_size = 14, auto_save = true}
end

local function save_config(config)
    iox.write_file("/documents/config.toml", toml.encode(config))
end

local config = load_config()
config.font_size = 16
save_config(config)
```

## Logging

```lua
local iox = require("luaswift.iox")

local function log(message)
    local entry = os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n"
    iox.append_file("/documents/app.log", entry)
end

log("Application started")
log("Processing complete")
```

## Batch Processing

```lua
local iox = require("luaswift.iox")

iox.mkdir("/documents/output", {parents = true})

for _, name in ipairs(iox.list_dir("/documents/input")) do
    if name:match("%.txt$") then
        local src = iox.path.join("/documents/input",  name)
        local dst = iox.path.join("/documents/output", name)
        iox.write_file(dst, string.upper(iox.read_file(src)))
        print("Processed: " .. name)
    end
end
```

## Error Handling

All functions throw on failure (access denied, path not found, I/O error). Use `pcall` to catch errors.

```lua
local iox = require("luaswift.iox")

local ok, result = pcall(function()
    return iox.read_file("/documents/nonexistent.txt")
end)

if ok then
    print("Content:", result)
else
    print("Error:", result)
end
```

`iox.exists`, `iox.is_file`, and `iox.is_dir` never throw — they return `false` for paths outside the sandbox or paths that do not exist.

## Security Notes

- All paths are validated against allowed directories before any operation.
- Allowed directories are set per-engine by the host Swift application; Lua scripts cannot change them.
- Use `pcall()` to catch and handle access-denied errors gracefully.
- This module is not installed by `installModules()` to prevent accidental file-system exposure. Install it explicitly only in engines that require file access.

## See Also

- ``IOModule``
- <doc:HTTPModule>
- <doc:JSONModule>
