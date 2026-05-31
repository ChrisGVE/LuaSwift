# StringX Module

Extended string utilities beyond Lua's standard string library.

## Overview

The StringX module provides comprehensive string manipulation functions using Swift's native String handling for proper Unicode support. It offers trimming, splitting, joining, pattern matching, case conversion, padding, character classification, slicing, and text processing utilities.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the StringX module
ModuleRegistry.installStringXModule(in: engine)
```

## Basic Usage

```lua
local stringx = require("luaswift.stringx")

-- Or use the global alias
print(stringx.strip("  hello  "))       -- "hello"
print(stringx.capitalize("hello"))       -- "Hello"
print(stringx.contains("hello", "ell"))  -- true

-- Extend standard string library
stringx.import()
print(string.capitalize("hello"))        -- Now available on string table
print(("hello"):capitalize())            -- Method syntax also works
```

## Extending the Standard String Library

Call `stringx.import()` to add all StringX functions to Lua's standard `string` table and string metatable:

```lua
stringx.import()

-- Function syntax
print(string.strip("  hello  "))         -- "hello"
print(string.split("a,b,c", ","))        -- {"a", "b", "c"}

-- Method syntax (s:method())
print(("  hello  "):strip())             -- "hello"
print(("hello world"):capitalize())      -- "Hello world"
print(("hello"):startswith("hel"))       -- true
```

## API Reference

### Trimming Functions

#### strip(s, chars?)
Removes leading and trailing characters. Defaults to whitespace and newlines.

```lua
stringx.strip("  hello  ")           -- "hello"
stringx.strip("\n\thello\n\t")       -- "hello"
stringx.strip("xxhelloxx", "x")      -- "hello"
stringx.strip("##hello##", "#")      -- "hello"
```

#### lstrip(s, chars?)
Removes leading characters only.

```lua
stringx.lstrip("  hello  ")          -- "hello  "
stringx.lstrip("xxhello", "x")       -- "hello"
stringx.lstrip("00123", "0")         -- "123"
```

#### rstrip(s, chars?)
Removes trailing characters only.

```lua
stringx.rstrip("  hello  ")          -- "  hello"
stringx.rstrip("helloxx", "x")       -- "hello"
stringx.rstrip("hello...", ".")      -- "hello"
```

### Splitting and Joining

#### split(s, sep)
Splits a string by separator. Returns an array of substrings.

```lua
local parts = stringx.split("a,b,c", ",")
-- {"a", "b", "c"}

local words = stringx.split("hello world", " ")
-- {"hello", "world"}

-- Split into characters with empty separator
local chars = stringx.split("abc", "")
-- {"a", "b", "c"}

-- Consecutive separators create empty strings
local parts = stringx.split("a,,b", ",")
-- {"a", "", "b"}
```

#### join(array, sep)
Joins array elements with a separator.

```lua
local s = stringx.join({"a", "b", "c"}, ",")
-- "a,b,c"

local path = stringx.join({"usr", "local", "bin"}, "/")
-- "usr/local/bin"

local s = stringx.join({"hello", "world"}, " ")
-- "hello world"

-- Empty separator concatenates
local s = stringx.join({"a", "b", "c"}, "")
-- "abc"
```

#### splitlines(s)
Splits a string on newlines. Handles `\n`, `\r\n`, and `\r`.

```lua
local lines = stringx.splitlines("line1\nline2\nline3")
-- {"line1", "line2", "line3"}

-- Handles Windows line endings
local lines = stringx.splitlines("line1\r\nline2\r\nline3")
-- {"line1", "line2", "line3"}

-- Handles old Mac line endings
local lines = stringx.splitlines("line1\rline2\rline3")
-- {"line1", "line2", "line3"}
```

### Replacement

#### replace(s, old, new, count?)
Replaces occurrences of a substring. Optional `count` limits replacements.

```lua
local s = stringx.replace("hello world", "world", "Swift")
-- "hello Swift"

local s = stringx.replace("banana", "a", "o")
-- "bonono"

-- Limit number of replacements
local s = stringx.replace("aaa", "a", "b", 2)
-- "bba"

local s = stringx.replace("one two one three one", "one", "1", 2)
-- "1 two 1 three one"
```

### Pattern Matching

#### startswith(s, prefix)
Checks if string starts with the given prefix.

```lua
stringx.startswith("hello", "hel")       -- true
stringx.startswith("hello", "world")     -- false
stringx.startswith("hello", "")          -- true (empty prefix)
stringx.startswith("", "hello")          -- false
```

#### endswith(s, suffix)
Checks if string ends with the given suffix.

```lua
stringx.endswith("hello", "lo")          -- true
stringx.endswith("hello", "llo")         -- true
stringx.endswith("hello", "world")       -- false
stringx.endswith("hello", "")            -- true (empty suffix)
```

#### contains(s, substring)
Checks if string contains the given substring.

```lua
stringx.contains("hello world", "lo wo")  -- true
stringx.contains("hello", "ell")          -- true
stringx.contains("hello", "xyz")          -- false
stringx.contains("hello", "")             -- true (empty always contained)
```

#### count(s, pattern)
Counts non-overlapping occurrences of a pattern.

```lua
stringx.count("hello", "l")              -- 2
stringx.count("banana", "a")             -- 3
stringx.count("banana", "na")            -- 2
stringx.count("hello", "xyz")            -- 0
stringx.count("hello", "")               -- 0 (empty pattern)
```

### Case Conversion

#### capitalize(s)
Capitalizes the first letter, lowercases the rest.

```lua
stringx.capitalize("hello")              -- "Hello"
stringx.capitalize("hello world")        -- "Hello world"
stringx.capitalize("HELLO")              -- "Hello"
stringx.capitalize("")                   -- ""
```

#### title(s)
Title case — capitalizes the first letter of each word.

```lua
stringx.title("hello world")             -- "Hello World"
stringx.title("the quick brown fox")     -- "The Quick Brown Fox"
stringx.title("HELLO WORLD")             -- "Hello World"
stringx.title("")                        -- ""
```

### Padding Functions

#### lpad(s, width, char?)
Left-pads string to the specified width. Default pad character is space.

```lua
stringx.lpad("hi", 5)                    -- "   hi"
stringx.lpad("hi", 5, "0")               -- "000hi"
stringx.lpad("hello", 3)                 -- "hello" (no padding if >= width)
stringx.lpad("42", 6, "0")               -- "000042"
```

#### rpad(s, width, char?)
Right-pads string to the specified width. Default pad character is space.

```lua
stringx.rpad("hi", 5)                    -- "hi   "
stringx.rpad("hi", 5, ".")               -- "hi..."
stringx.rpad("hello", 3)                 -- "hello" (no padding if >= width)
stringx.rpad("name", 10, "-")            -- "name------"
```

#### center(s, width, char?)
Centers string within the specified width. Default pad character is space.

```lua
stringx.center("hi", 6)                  -- "  hi  "
stringx.center("hi", 7)                  -- "  hi   " (extra padding on right)
stringx.center("hi", 6, "*")             -- "**hi**"
stringx.center("title", 11, "=")         -- "===title==="
```

### Character Classification

The canonical naming convention uses the `is_<name>` snake_case form. All eight predicates accept a single string argument and return `false` for an empty string unless noted otherwise.

#### is_alpha(s)
Returns `true` if every character is a Unicode letter.

```lua
stringx.is_alpha("hello")                -- true
stringx.is_alpha("Hello")                -- true
stringx.is_alpha("hello123")             -- false
stringx.is_alpha("")                     -- false
stringx.is_alpha("héllo")                -- true (Unicode letters)
```

#### is_digit(s)
Returns `true` if every character is a decimal digit (0–9).

```lua
stringx.is_digit("123")                  -- true
stringx.is_digit("123.45")               -- false (contains '.')
stringx.is_digit("12 34")                -- false (contains space)
stringx.is_digit("")                     -- false
```

#### is_alnum(s)
Returns `true` if every character is a letter or a decimal digit.

```lua
stringx.is_alnum("hello123")             -- true
stringx.is_alnum("abc")                  -- true
stringx.is_alnum("123")                  -- true
stringx.is_alnum("hello world")          -- false (contains space)
stringx.is_alnum("")                     -- false
```

#### is_space(s)
Returns `true` if every character is Unicode whitespace and the string is non-empty.

```lua
stringx.is_space("   ")                  -- true
stringx.is_space("\t\n")                 -- true
stringx.is_space(" \t \n ")              -- true
stringx.is_space("hello")                -- false
stringx.is_space("")                     -- false
```

#### is_upper(s)
Returns `true` if the string contains at least one letter and every letter is uppercase. Non-letter characters are ignored.

```lua
stringx.is_upper("HELLO")               -- true
stringx.is_upper("HELLO 123")           -- true (digits ignored)
stringx.is_upper("Hello")               -- false
stringx.is_upper("")                    -- false
stringx.is_upper("123")                 -- false (no letters present)
```

#### is_lower(s)
Returns `true` if the string contains at least one letter and every letter is lowercase. Non-letter characters are ignored.

```lua
stringx.is_lower("hello")               -- true
stringx.is_lower("hello 123")           -- true (digits ignored)
stringx.is_lower("Hello")               -- false
stringx.is_lower("")                    -- false
stringx.is_lower("123")                 -- false (no letters present)
```

#### is_empty(s)
Returns `true` if the string has zero characters.

```lua
stringx.is_empty("")                     -- true
stringx.is_empty("hello")               -- false
stringx.is_empty(" ")                    -- false (whitespace is not empty)
```

#### is_blank(s)
Returns `true` if the string is empty or contains only whitespace.

```lua
stringx.is_blank("")                     -- true
stringx.is_blank("   ")                  -- true
stringx.is_blank("\t\n")                 -- true
stringx.is_blank("hello")               -- false
stringx.is_blank("  hello  ")           -- false
```

#### Deprecated aliases

The following names without underscores are backward-compatible aliases and map to the canonical functions above. They will be removed in a future version.

| Deprecated | Canonical |
|---|---|
| `isalpha` | `is_alpha` |
| `isdigit` | `is_digit` |
| `isalnum` | `is_alnum` |
| `isspace` | `is_space` |
| `isupper` | `is_upper` |
| `islower` | `is_lower` |
| `isempty` | `is_empty` |
| `isblank` | `is_blank` |

### Slicing

#### slice(s, start?, stop?, step?)
Extracts a substring using Lua 1-based indices and an optional step. Negative indices count from the end of the string (`-1` is the last character). `stop` is inclusive. `step` defaults to `1`; a negative step traverses the string in reverse. A step of `0` raises an error.

```lua
local s = "hello"

-- Basic forward slices (1-based)
stringx.slice(s, 2, 4)          -- "ell"  (characters 2, 3, 4)
stringx.slice(s, 1, 3)          -- "hel"
stringx.slice(s, 3)             -- "llo"  (from position 3 to end)

-- Negative indices count from end
stringx.slice(s, -3)            -- "llo"  (last 3 characters)
stringx.slice(s, 1, -2)         -- "hell" (up to second-to-last, inclusive)

-- Step > 1 skips characters
stringx.slice(s, 1, 5, 2)       -- "hlo"  (positions 1, 3, 5)

-- Reverse with step = -1
stringx.slice(s, nil, nil, -1)  -- "olleh"

-- Reverse a slice
stringx.slice("abcde", 4, 2, -1) -- "dcb"  (positions 4, 3, 2)

-- Out-of-range indices are clamped
stringx.slice(s, 1, 100)        -- "hello"
```

### Text Processing

#### wrap(s, width)
Word-wraps text to the specified width. Words longer than `width` are broken at the column boundary.

```lua
local text = "The quick brown fox jumps over the lazy dog"
local wrapped = stringx.wrap(text, 20)
-- "The quick brown fox\njumps over the lazy\ndog"

-- Long words are broken if they exceed width
local wrapped = stringx.wrap("supercalifragilistic", 10)
-- "supercalif\nragilistic"
```

#### truncate(s, width, suffix?)
Truncates string to `width` total characters including the suffix. Default suffix is `"..."`.

```lua
stringx.truncate("hello world", 8)           -- "hello..."
stringx.truncate("hello world", 8, ">>")     -- "hello >>"
stringx.truncate("hi", 10)                   -- "hi" (no truncation needed)
stringx.truncate("hello world", 5, "...")    -- "he..."
```

## Common Patterns

### Input Cleaning

```lua
local stringx = require("luaswift.stringx")

local function clean_input(s)
    s = stringx.strip(s)
    local parts = stringx.split(s, " ")
    local cleaned = {}
    for _, p in ipairs(parts) do
        if not stringx.is_blank(p) then
            table.insert(cleaned, p)
        end
    end
    return stringx.join(cleaned, " ")
end

print(clean_input("  hello    world  "))  -- "hello world"
```

### Path Manipulation

```lua
local stringx = require("luaswift.stringx")

local function split_path(path)
    return stringx.split(path, "/")
end

local function join_path(parts)
    return stringx.join(parts, "/")
end

local function get_extension(filename)
    local parts = stringx.split(filename, ".")
    if #parts > 1 then
        return parts[#parts]
    end
    return ""
end

print(get_extension("document.pdf"))  -- "pdf"
```

### CSV Parsing (Simple)

```lua
local stringx = require("luaswift.stringx")

local function parse_csv_line(line)
    return stringx.split(line, ",")
end

local function format_csv_line(values)
    return stringx.join(values, ",")
end

local csv = "name,age,city"
local fields = parse_csv_line(csv)  -- {"name", "age", "city"}
```

### Text Formatting

```lua
local stringx = require("luaswift.stringx")

local function format_column(text, width)
    if stringx.is_empty(text) then
        return stringx.rpad("", width)
    end
    if #text > width then
        return stringx.truncate(text, width)
    end
    return stringx.rpad(text, width)
end

local function format_header(title, width)
    return stringx.center(stringx.title(title), width, "=")
end

print(format_header("users", 20))  -- "=======Users========"
```

### Validation

```lua
local stringx = require("luaswift.stringx")

local function is_valid_identifier(s)
    if stringx.is_empty(s) then
        return false
    end
    -- First character must be a letter or underscore
    local first = s:sub(1, 1)
    if not (stringx.is_alpha(first) or first == "_") then
        return false
    end
    -- Remaining characters must be alphanumeric or underscore
    for i = 2, #s do
        local c = s:sub(i, i)
        if not (stringx.is_alnum(c) or c == "_") then
            return false
        end
    end
    return true
end

print(is_valid_identifier("myVar"))      -- true
print(is_valid_identifier("_private"))   -- true
print(is_valid_identifier("123abc"))     -- false
```

## Unicode Support

All StringX functions handle Unicode strings correctly using Swift's native String type:

```lua
local stringx = require("luaswift.stringx")

-- Unicode letters
stringx.is_alpha("héllo")                -- true
stringx.capitalize("ñoño")              -- "Ñoño"
stringx.title("über cool")              -- "Über Cool"

-- Unicode-aware operations
stringx.strip("  日本語  ")             -- "日本語"
stringx.count("emoji 😀 emoji 😀", "😀") -- 2

-- Proper character counting for padding
stringx.center("中文", 8)               -- "   中文   "
```

## See Also

- ``StringXModule``
- ``UTF8XModule``
- ``RegexModule``
