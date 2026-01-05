# UTF8X Module

Unicode-aware string operations with proper character handling.

## Overview

The UTF8X module provides Unicode-aware string operations using Swift's native String handling. Unlike Lua's byte-based `string` library, UTF8X operates on characters (grapheme clusters), properly handling multi-byte characters, CJK text, emoji, and other Unicode content.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the UTF8X module
ModuleRegistry.installUTF8XModule(in: engine)
```

## Basic Usage

```lua
local utf8x = require("luaswift.utf8x")

-- Or use the global alias
local s = "Hello世界"
print(utf8x.len(s))        -- 7 (characters, not bytes)
print(#s)                   -- 11 (bytes)

-- Character operations work correctly
print(utf8x.sub(s, 6, 7))  -- "世界"
print(utf8x.reverse(s))     -- "界世olleH"

-- Extend Lua's utf8 library (Lua 5.3+)
utf8x.import()
print(utf8.width(s))        -- Now available on utf8 table
```

## Extending the Standard UTF8 Library

Call `utf8x.import()` to add UTF8X functions to Lua's standard `utf8` table (available in Lua 5.3+):

```lua
utf8x.import()

-- Now use directly on utf8
print(utf8.width("Hello世界"))      -- 11
print(utf8.reverse("Hello"))         -- "olleH"
print(utf8.upper("café"))            -- "CAFÉ"
```

## API Reference

### Character Length

#### len(s)
Returns the number of characters (grapheme clusters) in a string.

```lua
utf8x.len("Hello")         -- 5
utf8x.len("Hello世界")     -- 7
utf8x.len("café")          -- 4
utf8x.len("👨‍👩‍👧‍👦")          -- 1 (family emoji is one grapheme)
utf8x.len("")              -- 0

-- Compare with byte length
local s = "Hello世界"
print(utf8x.len(s))        -- 7 (characters)
print(#s)                   -- 11 (bytes)
```

### Display Width

#### width(s)
Calculates the display width of a string, accounting for wide characters. CJK characters, full-width symbols, and emoji are counted as width 2; other characters as width 1.

```lua
utf8x.width("Hello")           -- 5
utf8x.width("Hello世界")       -- 11 (5 + 2*3)
utf8x.width("日本語")           -- 6 (3 characters × 2 width)
utf8x.width("ＡＢＣ")          -- 6 (full-width letters)
utf8x.width("😀")              -- 2 (emoji)

-- Useful for column alignment
local function pad_to_width(s, width)
    local w = utf8x.width(s)
    if w >= width then return s end
    return s .. string.rep(" ", width - w)
end
```

**Wide character categories:**
- CJK Unified Ideographs (Chinese, Japanese, Korean characters)
- Hiragana and Katakana
- Hangul Syllables
- Full-width ASCII variants (Ａ-Ｚ, ０-９, etc.)
- Emoji and pictographs

### Substring

#### sub(s, i, j?)
Extracts a substring by character indices (not bytes). Supports negative indices.

**Parameters:**
- `s` - Source string
- `i` - Start index (1-based, or negative from end)
- `j` - End index (optional, defaults to end of string)

```lua
local s = "Hello世界"

utf8x.sub(s, 1, 5)         -- "Hello"
utf8x.sub(s, 6, 7)         -- "世界"
utf8x.sub(s, 6)            -- "世界" (to end)

-- Negative indices (from end)
utf8x.sub(s, -2, -1)       -- "世界"
utf8x.sub(s, -5, -3)       -- "llo"
utf8x.sub("Hello", -2)     -- "lo"

-- Empty results
utf8x.sub(s, 10, 20)       -- "" (out of range)
utf8x.sub(s, 5, 3)         -- "" (invalid range)
```

### Reverse

#### reverse(s)
Reverses a string by characters (not bytes), preserving grapheme clusters.

```lua
utf8x.reverse("Hello")         -- "olleH"
utf8x.reverse("Hello世界")     -- "界世olleH"
utf8x.reverse("café")          -- "éfac"
utf8x.reverse("12345")         -- "54321"
utf8x.reverse("")              -- ""
```

### Case Conversion

#### upper(s)
Converts string to uppercase using Unicode-aware rules.

```lua
utf8x.upper("hello")           -- "HELLO"
utf8x.upper("café")            -- "CAFÉ"
utf8x.upper("über")            -- "ÜBER"
utf8x.upper("ñ")               -- "Ñ"
utf8x.upper("Hello世界")       -- "HELLO世界" (CJK unchanged)
utf8x.upper("αβγ")             -- "ΑΒΓ" (Greek letters)
```

#### lower(s)
Converts string to lowercase using Unicode-aware rules.

```lua
utf8x.lower("HELLO")           -- "hello"
utf8x.lower("CAFÉ")            -- "café"
utf8x.lower("ÜBER")            -- "über"
utf8x.lower("Ñ")               -- "ñ"
utf8x.lower("HELLO世界")       -- "hello世界" (CJK unchanged)
utf8x.lower("ΑΒΓ")             -- "αβγ" (Greek letters)
```

### Character Iteration

#### chars(s)
Returns an array of individual characters for iteration.

```lua
local chars = utf8x.chars("Hello世界")
-- {"H", "e", "l", "l", "o", "世", "界"}

-- Iterate over characters
for _, char in ipairs(utf8x.chars("Hello")) do
    print(char)
end
-- Prints: H, e, l, l, o

-- Use with ipairs for index access
for i, char in ipairs(utf8x.chars("abc")) do
    print(i, char)
end
-- 1    a
-- 2    b
-- 3    c
```

## Common Patterns

### Text Truncation with Width

```lua
local function truncate_by_width(s, max_width, suffix)
    suffix = suffix or "..."
    local suffix_width = utf8x.width(suffix)

    if utf8x.width(s) <= max_width then
        return s
    end

    local result = ""
    local current_width = 0

    for _, char in ipairs(utf8x.chars(s)) do
        local char_width = utf8x.width(char)
        if current_width + char_width + suffix_width > max_width then
            break
        end
        result = result .. char
        current_width = current_width + char_width
    end

    return result .. suffix
end

print(truncate_by_width("Hello世界", 10, "..."))  -- "Hello世..."
```

### Column Alignment for CJK Text

```lua
local function align_columns(rows, widths)
    local result = {}
    for _, row in ipairs(rows) do
        local line = ""
        for i, cell in ipairs(row) do
            local w = utf8x.width(cell)
            local padding = widths[i] - w
            line = line .. cell .. string.rep(" ", padding) .. " "
        end
        result[#result + 1] = line
    end
    return result
end

local data = {
    {"Name", "City"},
    {"Alice", "Tokyo"},
    {"田中", "東京"},
}

local aligned = align_columns(data, {8, 6})
-- "Name     City   "
-- "Alice    Tokyo  "
-- "田中     東京   "
```

### Safe String Splitting

```lua
local function split_by_char(s)
    return utf8x.chars(s)
end

local function first_n_chars(s, n)
    return utf8x.sub(s, 1, n)
end

local function last_n_chars(s, n)
    return utf8x.sub(s, -n)
end

print(first_n_chars("Hello世界", 6))  -- "Hello世"
print(last_n_chars("Hello世界", 2))   -- "世界"
```

### Character Classification

```lua
local function is_cjk_char(char)
    -- CJK characters have display width of 2
    return utf8x.width(char) == 2
end

local function count_cjk_chars(s)
    local count = 0
    for _, char in ipairs(utf8x.chars(s)) do
        if is_cjk_char(char) then
            count = count + 1
        end
    end
    return count
end

print(count_cjk_chars("Hello世界"))  -- 2
```

### Palindrome Check

```lua
local function is_palindrome(s)
    -- Normalize: lowercase and remove spaces
    s = utf8x.lower(s)
    -- Compare with reverse
    return s == utf8x.reverse(s)
end

print(is_palindrome("Aba"))      -- true
print(is_palindrome("Hello"))    -- false
```

## Comparison with Lua's string Library

| Operation | `string` library | `utf8x` |
|-----------|-----------------|---------|
| Length | Bytes | Characters |
| Substring | Byte indices | Character indices |
| Reverse | Corrupts multi-byte | Correct |
| Case | ASCII only | Full Unicode |

```lua
local s = "café"

-- Length
print(#s)                 -- 5 (bytes, includes 2-byte é)
print(utf8x.len(s))       -- 4 (characters)

-- Substring
print(string.sub(s, 1, 4))   -- "caf" + garbage (byte-based)
print(utf8x.sub(s, 1, 4))    -- "café" (character-based)

-- Reverse
print(string.reverse(s))     -- corrupted (reverses bytes)
print(utf8x.reverse(s))      -- "éfac" (correct)

-- Case conversion
print(string.upper(s))       -- "CAFé" (ASCII only)
print(utf8x.upper(s))        -- "CAFÉ" (full Unicode)
```

## See Also

- ``UTF8XModule``
- ``StringXModule``
- ``RegexModule``
