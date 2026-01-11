# UTF8X Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.utf8x` | **Global:** `utf8x` | **Extends:** `utf8`

Unicode-aware string operations including display width calculation, character-based substring extraction, reversing, case conversion, and iteration. All operations use Swift's native Unicode handling for correct behavior with multi-byte characters.

## Function Reference

| Function | Description |
|----------|-------------|
| [width(str)](#width) | Display width accounting for wide characters |
| [sub(str, i, j?)](#sub) | Extract substring by character position |
| [reverse(str)](#reverse) | Reverse string by character |
| [upper(str)](#upper) | Convert to uppercase (locale-aware) |
| [lower(str)](#lower) | Convert to lowercase (locale-aware) |
| [len(str)](#len) | Count characters (not bytes) |
| [chars(str)](#chars) | Return array of individual characters |
| [import()](#import) | Extend built-in `utf8` library |

## Import to utf8

Extend the built-in `utf8` library with utf8x functions:

```lua
luaswift.extend_stdlib()
-- or manually:
utf8x.import()

-- Now available under utf8
local w = utf8.width("Hello世界")
local s = utf8.sub("Hello世界", 6, 7)
```

---

## width

```
utf8x.width(str) -> number
```

Calculate display width of a string, accounting for wide characters (CJK ideographs, emoji).

Wide characters (CJK, full-width, emoji) count as 2, others count as 1.

```lua
local w1 = utf8x.width("Hello")     -- 5
local w2 = utf8x.width("世界")      -- 4 (2 characters × 2)
local w3 = utf8x.width("Hello世界") -- 11 (5 + 2×3)
local w4 = utf8x.width("café")      -- 4

-- Emoji
local w5 = utf8x.width("👍")        -- 2
local w6 = utf8x.width("Hello 👍")  -- 8 (5 + 1 space + 2 emoji)
```

**Wide character ranges:**
- CJK Unified Ideographs (U+4E00 to U+9FFF)
- Hangul Syllables (U+AC00 to U+D7AF)
- Hiragana and Katakana (U+3040 to U+30FF)
- Full-width ASCII (U+FF01 to U+FF60)
- Emoji (U+1F300 to U+1F9FF)

---

## sub

```
utf8x.sub(str, i, j?) -> string
```

Extract substring by character position (not byte position).

**Parameters:**
- `str` - Input string
- `i` - Start character position (1-based)
- `j` (optional) - End character position (defaults to end of string)

Supports negative indices (counting from end).

```lua
-- Basic substring
local s1 = utf8x.sub("Hello", 1, 3)         -- "Hel"
local s2 = utf8x.sub("Hello", 2)            -- "ello" (j defaults to end)

-- With Unicode
local s3 = utf8x.sub("Hello世界", 6, 7)     -- "世界"
local s4 = utf8x.sub("café", 1, 3)          -- "caf"

-- Negative indices (from end)
local s5 = utf8x.sub("Hello", -2, -1)       -- "lo"
local s6 = utf8x.sub("世界", -1, -1)        -- "界"
local s7 = utf8x.sub("Hello", 1, -2)        -- "Hell"

-- Out of bounds returns empty string
local s8 = utf8x.sub("Hello", 10, 20)       -- ""
local s9 = utf8x.sub("Hello", 5, 3)         -- "" (start > end)
```

---

## reverse

```
utf8x.reverse(str) -> string
```

Reverse string by character (not byte).

```lua
local r1 = utf8x.reverse("Hello")      -- "olleH"
local r2 = utf8x.reverse("世界")       -- "界世"
local r3 = utf8x.reverse("Hello世界")  -- "界世olleH"
local r4 = utf8x.reverse("café")       -- "éfac"

-- Emoji
local r5 = utf8x.reverse("Hello 👍")   -- "👍 olleH"
```

---

## upper

```
utf8x.upper(str) -> string
```

Convert to uppercase using locale-aware rules.

```lua
local u1 = utf8x.upper("hello")        -- "HELLO"
local u2 = utf8x.upper("café")         -- "CAFÉ"
local u3 = utf8x.upper("naïve")        -- "NAÏVE"
local u4 = utf8x.upper("straße")       -- "STRASSE" (German ß → SS)
```

---

## lower

```
utf8x.lower(str) -> string
```

Convert to lowercase using locale-aware rules.

```lua
local l1 = utf8x.lower("HELLO")        -- "hello"
local l2 = utf8x.lower("CAFÉ")         -- "café"
local l3 = utf8x.lower("NAÏVE")        -- "naïve"
```

---

## len

```
utf8x.len(str) -> number
```

Count characters (not bytes).

Compatible with `utf8.len` from Lua 5.3+ but counts characters directly.

```lua
local len1 = utf8x.len("Hello")        -- 5
local len2 = utf8x.len("世界")         -- 2
local len3 = utf8x.len("Hello世界")    -- 7
local len4 = utf8x.len("café")         -- 4

-- Compare to byte length
print(#"café")                         -- 5 (bytes)
print(utf8x.len("café"))               -- 4 (characters)
```

---

## chars

```
utf8x.chars(str) -> table
```

Return array of individual characters.

```lua
-- Basic iteration
local chars1 = utf8x.chars("Hello")
-- {"H", "e", "l", "l", "o"}

-- Unicode characters
local chars2 = utf8x.chars("世界")
-- {"世", "界"}

local chars3 = utf8x.chars("café")
-- {"c", "a", "f", "é"}

-- Use in loop
local chars = utf8x.chars("Hello世界")
for i, char in ipairs(chars) do
    print(i, char, utf8x.width(char))
end
-- 1  H  1
-- 2  e  1
-- 3  l  1
-- 4  l  1
-- 5  o  1
-- 6  世 2
-- 7  界 2
```

---

## import

```
utf8x.import()
```

Extend the built-in `utf8` library with utf8x functions.

After calling this function, all utf8x functions are available under the `utf8` namespace.

```lua
utf8x.import()

-- Now available under utf8
local w = utf8.width("Hello世界")
local s = utf8.sub("Hello世界", 6, 7)
local r = utf8.reverse("世界")
```

---

## Examples

### Text Alignment

```lua
function pad_center(text, width)
    local text_width = utf8x.width(text)
    local padding = math.floor((width - text_width) / 2)
    local left_pad = string.rep(" ", padding)
    local right_pad = string.rep(" ", width - text_width - padding)
    return left_pad .. text .. right_pad
end

print(pad_center("Hello", 10))      -- "  Hello   "
print(pad_center("世界", 10))       -- "   世界   "
```

### Character Processing

```lua
-- Reverse each word
function reverse_words(text)
    local result = {}
    for word in text:gmatch("%S+") do
        table.insert(result, utf8x.reverse(word))
    end
    return table.concat(result, " ")
end

print(reverse_words("Hello 世界"))  -- "olleH 界世"
```

### Title Case

```lua
function title_case(text)
    local words = {}
    for word in text:gmatch("%S+") do
        local chars = utf8x.chars(word)
        if #chars > 0 then
            chars[1] = utf8x.upper(chars[1])
            for i = 2, #chars do
                chars[i] = utf8x.lower(chars[i])
            end
            table.insert(words, table.concat(chars))
        end
    end
    return table.concat(words, " ")
end

print(title_case("hello WORLD"))    -- "Hello World"
print(title_case("café résumé"))    -- "Café Résumé"
```

### Substring with Display Width

```lua
-- Truncate to display width
function truncate_width(text, max_width)
    local chars = utf8x.chars(text)
    local result = {}
    local current_width = 0

    for _, char in ipairs(chars) do
        local char_width = utf8x.width(char)
        if current_width + char_width > max_width then
            break
        end
        table.insert(result, char)
        current_width = current_width + char_width
    end

    return table.concat(result)
end

print(truncate_width("Hello世界", 7))   -- "Hello世" (width: 7)
print(truncate_width("Hello世界", 6))   -- "Hello" (width: 5, can't fit 世)
```
