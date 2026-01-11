# IO Module (Sandboxed File System)

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.iox` | **Global:** `iox`

Sandboxed file system operations restricted to explicitly allowed directories.

> **Note**: IOModule requires explicit installation with configured allowed directories. Lua scripts can only access files within these directories.

## Swift Setup (Required)

```swift
import LuaSwift

let engine = try LuaEngine()

// REQUIRED: Configure allowed directories BEFORE installing
let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
IOModule.setAllowedDirectories([documentsURL.path], for: engine)

// Then install the module
ModuleRegistry.installIOModule(in: engine)

// Now Lua can access files within the Documents directory
```

## File Operations

```lua
local iox = require("luaswift.iox")

-- Read entire file
local content = iox.read_file("/path/to/file.txt")

-- Write file (overwrites)
iox.write_file("/path/to/file.txt", "content")

-- Append to file
iox.append_file("/path/to/log.txt", "new line\n")
```

## Path Checks

```lua
-- Check existence (returns false for disallowed paths, no error)
if iox.exists("/path/to/file") then
    print("File exists")
end

-- Check type
if iox.is_file(path) then
    print("It's a file")
end

if iox.is_dir(path) then
    print("It's a directory")
end
```

## Directory Operations

```lua
-- List directory contents
local files = iox.list_dir("/path/to/dir")
for _, name in ipairs(files) do
    print(name)
end

-- Create directory
iox.mkdir("/path/to/newdir")

-- Create nested directories
iox.mkdir("/path/to/deep/nested/dir", {parents = true})

-- Remove file or empty directory
iox.remove("/path/to/file.txt")

-- Rename/move
iox.rename("/path/old.txt", "/path/new.txt")
```

## File Information

```lua
local info = iox.stat("/path/to/file.txt")

print(info.size)      -- File size in bytes
print(info.is_file)   -- true
print(info.is_dir)    -- false
print(info.modified)  -- Unix timestamp (last modification)
print(info.created)   -- Unix timestamp (creation)
```

## Path Utilities

Path utilities have no security restrictions - they just manipulate strings:

```lua
-- Join path components
local full = iox.path.join("dir", "subdir", "file.txt")
-- "dir/subdir/file.txt"

-- Extract components
local name = iox.path.basename("/path/to/file.txt")  -- "file.txt"
local dir = iox.path.dirname("/path/to/file.txt")    -- "/path/to"
local ext = iox.path.extension("/path/to/file.txt")  -- "txt" or nil

-- Path manipulation
local abs = iox.path.absolute("relative/path")
local norm = iox.path.normalize("/path/../to/./file")  -- "/to/file"
```

## Security Features

### Allowed Directory Restriction

All file operations validate paths against the allowed directories list:

```swift
// Only allow access to Documents and tmp
IOModule.setAllowedDirectories([
    documentsPath,
    NSTemporaryDirectory()
], for: engine)
```

### Path Traversal Protection

Path traversal attacks are detected and blocked:

```lua
-- These will fail with security error
iox.read_file("/allowed/dir/../../../etc/passwd")
iox.read_file("/allowed/dir/./../../secret")
```

### Silent Denial for Existence Checks

`exists()`, `is_file()`, and `is_dir()` return `false` for disallowed paths (no error):

```lua
-- Returns false for paths outside allowed directories
print(iox.exists("/etc/passwd"))  -- false (no error thrown)
```

### Errors for Write Operations

Other operations throw errors for disallowed paths:

```lua
local ok, err = pcall(function()
    iox.read_file("/etc/passwd")
end)
if not ok then
    print(err)  -- "Access denied: path not in allowed directories"
end
```

## Query Configuration

From Swift, check what directories are allowed:

```swift
let dirs = IOModule.getAllowedDirectories(for: engine)
print(dirs)  // ["/Users/.../Documents", "/tmp"]
```

## Example: Safe File Manager

```lua
local iox = require("luaswift.iox")

local function safe_read(filename)
    local path = iox.path.join(BASE_DIR, filename)
    if iox.exists(path) and iox.is_file(path) then
        return iox.read_file(path)
    end
    return nil, "File not found"
end

local function safe_write(filename, content)
    local path = iox.path.join(BASE_DIR, filename)
    -- Ensure parent directory exists
    local dir = iox.path.dirname(path)
    if not iox.exists(dir) then
        iox.mkdir(dir, {parents = true})
    end
    iox.write_file(path, content)
end
```
