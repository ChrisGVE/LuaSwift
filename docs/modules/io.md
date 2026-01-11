# IO Module (Sandboxed File System)

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.iox` | **Global:** `iox`

Sandboxed file system operations restricted to explicitly allowed directories.

> **Note**: IOModule requires explicit installation with configured allowed directories. Lua scripts can only access files within these directories.

## Function Reference

| Function | Description |
|----------|-------------|
| [read_file(path)](#read_file) | Read entire file content |
| [write_file(path, content)](#write_file) | Write content to file (overwrites) |
| [append_file(path, content)](#append_file) | Append content to file |
| [exists(path)](#exists) | Check if path exists |
| [is_file(path)](#is_file) | Check if path is a file |
| [is_dir(path)](#is_dir) | Check if path is a directory |
| [list_dir(path)](#list_dir) | List directory contents |
| [mkdir(path, options?)](#mkdir) | Create directory |
| [remove(path)](#remove) | Remove file or empty directory |
| [rename(old_path, new_path)](#rename) | Rename or move file/directory |
| [stat(path)](#stat) | Get file/directory information |
| [path.join(...)](#pathjoin) | Join path components |
| [path.basename(path)](#pathbasename) | Extract filename from path |
| [path.dirname(path)](#pathdirname) | Extract directory from path |
| [path.extension(path)](#pathextension) | Extract file extension |
| [path.absolute(path)](#pathabsolute) | Convert to absolute path |
| [path.normalize(path)](#pathnormalize) | Normalize path |

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

---

## read_file

```
iox.read_file(path) -> string
```

Read entire file content as a string.

**Parameters:**
- `path` - Absolute path to file (must be within allowed directories)

```lua
local content = iox.read_file("/path/to/file.txt")
print(content)
```

**Errors:** Throws if path is outside allowed directories or file cannot be read.

---

## write_file

```
iox.write_file(path, content)
```

Write content to file, overwriting if it exists.

**Parameters:**
- `path` - Absolute path to file (must be within allowed directories)
- `content` - String content to write

```lua
iox.write_file("/path/to/file.txt", "Hello, World!")
```

**Errors:** Throws if path is outside allowed directories or write fails.

---

## append_file

```
iox.append_file(path, content)
```

Append content to end of file.

**Parameters:**
- `path` - Absolute path to file (must be within allowed directories)
- `content` - String content to append

```lua
iox.append_file("/path/to/log.txt", "New log entry\n")
```

**Errors:** Throws if path is outside allowed directories or write fails.

---

## exists

```
iox.exists(path) -> boolean
```

Check if path exists. Returns `false` for paths outside allowed directories (no error).

**Parameters:**
- `path` - Path to check

```lua
if iox.exists("/path/to/file") then
    print("File exists")
end
```

---

## is_file

```
iox.is_file(path) -> boolean
```

Check if path exists and is a file. Returns `false` for paths outside allowed directories (no error).

**Parameters:**
- `path` - Path to check

```lua
if iox.is_file(path) then
    print("It's a file")
end
```

---

## is_dir

```
iox.is_dir(path) -> boolean
```

Check if path exists and is a directory. Returns `false` for paths outside allowed directories (no error).

**Parameters:**
- `path` - Path to check

```lua
if iox.is_dir(path) then
    print("It's a directory")
end
```

---

## list_dir

```
iox.list_dir(path) -> table
```

List directory contents as an array of filenames.

**Parameters:**
- `path` - Directory path (must be within allowed directories)

```lua
local files = iox.list_dir("/path/to/dir")
for _, name in ipairs(files) do
    print(name)
end
```

**Errors:** Throws if path is outside allowed directories or not a directory.

---

## mkdir

```
iox.mkdir(path, options?)
```

Create directory.

**Parameters:**
- `path` - Directory path to create (must be within allowed directories)
- `options` (optional) - Table with options:
  - `parents` (boolean): Create parent directories if needed (default: false)

```lua
-- Create single directory
iox.mkdir("/path/to/newdir")

-- Create nested directories
iox.mkdir("/path/to/deep/nested/dir", {parents = true})
```

**Errors:** Throws if path is outside allowed directories, parent doesn't exist (without `parents = true`), or creation fails.

---

## remove

```
iox.remove(path)
```

Remove file or empty directory.

**Parameters:**
- `path` - Path to remove (must be within allowed directories)

```lua
iox.remove("/path/to/file.txt")
```

**Errors:** Throws if path is outside allowed directories, directory is not empty, or removal fails.

---

## rename

```
iox.rename(old_path, new_path)
```

Rename or move file/directory.

**Parameters:**
- `old_path` - Current path (must be within allowed directories)
- `new_path` - New path (must be within allowed directories)

```lua
iox.rename("/path/old.txt", "/path/new.txt")
```

**Errors:** Throws if either path is outside allowed directories or operation fails.

---

## stat

```
iox.stat(path) -> table
```

Get file or directory information.

**Parameters:**
- `path` - Path to inspect (must be within allowed directories)

**Returns:** Table with fields:
- `size` (number): File size in bytes
- `is_file` (boolean): True if path is a file
- `is_dir` (boolean): True if path is a directory
- `modified` (number): Unix timestamp of last modification
- `created` (number): Unix timestamp of creation

```lua
local info = iox.stat("/path/to/file.txt")
print("Size:", info.size)
print("Modified:", info.modified)
print("Is file:", info.is_file)
```

**Errors:** Throws if path is outside allowed directories or doesn't exist.

---

## path.join

```
iox.path.join(...) -> string
```

Join path components with platform-appropriate separator.

**Parameters:**
- `...` - Variable number of path components (strings)

```lua
local full = iox.path.join("dir", "subdir", "file.txt")
-- "dir/subdir/file.txt" on Unix
```

**Note:** Path utilities have no security restrictions - they only manipulate strings.

---

## path.basename

```
iox.path.basename(path) -> string
```

Extract filename from path.

**Parameters:**
- `path` - File path

```lua
local name = iox.path.basename("/path/to/file.txt")
-- "file.txt"
```

---

## path.dirname

```
iox.path.dirname(path) -> string
```

Extract directory path (parent directory).

**Parameters:**
- `path` - File path

```lua
local dir = iox.path.dirname("/path/to/file.txt")
-- "/path/to"
```

---

## path.extension

```
iox.path.extension(path) -> string | nil
```

Extract file extension without the dot.

**Parameters:**
- `path` - File path

**Returns:** Extension string or `nil` if no extension.

```lua
local ext = iox.path.extension("/path/to/file.txt")
-- "txt"

local none = iox.path.extension("/path/to/noext")
-- nil
```

---

## path.absolute

```
iox.path.absolute(path) -> string
```

Convert relative path to absolute path.

**Parameters:**
- `path` - Relative or absolute path

```lua
local abs = iox.path.absolute("relative/path")
-- "/current/working/dir/relative/path"
```

---

## path.normalize

```
iox.path.normalize(path) -> string
```

Normalize path by resolving `.` and `..` components.

**Parameters:**
- `path` - Path to normalize

```lua
local norm = iox.path.normalize("/path/../to/./file")
-- "/to/file"
```

---

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

### Query Configuration

From Swift, check what directories are allowed:

```swift
let dirs = IOModule.getAllowedDirectories(for: engine)
print(dirs)  // ["/Users/.../Documents", "/tmp"]
```

---

## Examples

### Safe File Manager

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
