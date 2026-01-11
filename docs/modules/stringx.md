# StringX Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.stringx` | **Global:** `stringx` | **Extends:** `string` (via `import()`)

String utilities inspired by Python and Penlight, providing trimming, splitting, padding, case conversion, and text processing.

## Function Reference

| Function | Description |
|----------|-------------|
| [strip(str, chars?)](#strip) | Remove leading and trailing characters |
| [lstrip(str, chars?)](#lstrip) | Remove leading characters |
| [rstrip(str, chars?)](#rstrip) | Remove trailing characters |
| [split(str, separator)](#split) | Split string by separator |
| [join(array, separator)](#join) | Join array with separator |
| [replace(str, old, new, count?)](#replace) | Replace occurrences |
| [startswith(str, prefix)](#startswith) | Check prefix |
| [endswith(str, suffix)](#endswith) | Check suffix |
| [contains(str, substring)](#contains) | Check substring |
| [count(str, pattern)](#count) | Count occurrences |
| [capitalize(str)](#capitalize) | Capitalize first letter |
| [title(str)](#title) | Title case all words |
| [lpad(str, width, char?)](#lpad) | Left pad to width |
| [rpad(str, width, char?)](#rpad) | Right pad to width |
| [center(str, width, char?)](#center) | Center pad to width |
| [is_alpha(str)](#is_alpha) | Check all letters |
| [is_digit(str)](#is_digit) | Check all digits |
| [is_alnum(str)](#is_alnum) | Check alphanumeric |
| [is_space(str)](#is_space) | Check all whitespace |
| [is_upper(str)](#is_upper) | Check uppercase letters |
| [is_lower(str)](#is_lower) | Check lowercase letters |
| [is_empty(str)](#is_empty) | Check empty string |
| [is_blank(str)](#is_blank) | Check empty or whitespace |
| [splitlines(str)](#splitlines) | Split on newlines |
| [wrap(str, width)](#wrap) | Word wrap to width |
| [truncate(str, width, suffix?)](#truncate) | Truncate with suffix |
| [import()](#import) | Extend string library |

## Usage Patterns

```lua
-- Namespace access
local stringx = require("luaswift.stringx")
local result = stringx.strip("  hello  ")

-- Global access
local result = stringx.strip("  hello  ")

-- Import into string library
stringx.import()
local result = "  hello  ":strip()
```

---

## strip

```
stringx.strip(str, chars?) -> string
```

Remove leading and trailing characters (whitespace by default).

**Parameters:**
- `str` - String to strip
- `chars` (optional) - Characters to remove (default: whitespace)

```lua
local s = stringx.strip("  hello  ")      -- "hello"
local s = stringx.strip("xxhelloxx", "x") -- "hello"
local s = stringx.strip("\n\ttext\t\n")   -- "text"
```

---

## lstrip

```
stringx.lstrip(str, chars?) -> string
```

Remove leading characters only.

**Parameters:**
- `str` - String to strip
- `chars` (optional) - Characters to remove (default: whitespace)

```lua
local s = stringx.lstrip("  hello  ")     -- "hello  "
local s = stringx.lstrip("xxhello", "x")  -- "hello"
```

---

## rstrip

```
stringx.rstrip(str, chars?) -> string
```

Remove trailing characters only.

**Parameters:**
- `str` - String to strip
- `chars` (optional) - Characters to remove (default: whitespace)

```lua
local s = stringx.rstrip("  hello  ")     -- "  hello"
local s = stringx.rstrip("helloxx", "x")  -- "hello"
```

---

## split

```
stringx.split(str, separator) -> table
```

Split string by separator into array.

**Parameters:**
- `str` - String to split
- `separator` - Separator string (empty string splits into characters)

```lua
local parts = stringx.split("a,b,c", ",")       -- {"a", "b", "c"}
local parts = stringx.split("a::b::c", "::")    -- {"a", "b", "c"}
local chars = stringx.split("hello", "")        -- {"h", "e", "l", "l", "o"}
```

---

## join

```
stringx.join(array, separator) -> string
```

Join array elements with separator.

**Parameters:**
- `array` - Array of strings to join
- `separator` - Separator string

```lua
local s = stringx.join({"a", "b", "c"}, ",")    -- "a,b,c"
local s = stringx.join({"one", "two"}, " ")     -- "one two"
local s = stringx.join({}, ",")                 -- ""
```

---

## replace

```
stringx.replace(str, old, new, count?) -> string
```

Replace occurrences of old string with new string.

**Parameters:**
- `str` - String to process
- `old` - String to find
- `new` - Replacement string
- `count` (optional) - Maximum replacements (default: all)

```lua
local s = stringx.replace("hello world", "world", "Lua")  -- "hello Lua"
local s = stringx.replace("aaa", "a", "b")                -- "bbb"
local s = stringx.replace("aaa", "a", "b", 2)             -- "bba" (limit to 2)
```

---

## startswith

```
stringx.startswith(str, prefix) -> boolean
```

Check if string starts with prefix.

**Parameters:**
- `str` - String to check
- `prefix` - Prefix to test

```lua
local ok = stringx.startswith("hello", "hel")   -- true
local ok = stringx.startswith("hello", "lo")    -- false
```

---

## endswith

```
stringx.endswith(str, suffix) -> boolean
```

Check if string ends with suffix.

**Parameters:**
- `str` - String to check
- `suffix` - Suffix to test

```lua
local ok = stringx.endswith("hello", "lo")      -- true
local ok = stringx.endswith("hello", "hel")     -- false
```

---

## contains

```
stringx.contains(str, substring) -> boolean
```

Check if string contains substring.

**Parameters:**
- `str` - String to search
- `substring` - Substring to find

```lua
local ok = stringx.contains("hello", "ell")     -- true
local ok = stringx.contains("hello", "world")   -- false
local ok = stringx.contains("hello", "")        -- true (empty always contained)
```

---

## count

```
stringx.count(str, pattern) -> number
```

Count occurrences of pattern in string.

**Parameters:**
- `str` - String to search
- `pattern` - Pattern to count (non-overlapping matches)

```lua
local n = stringx.count("hello", "l")           -- 2
local n = stringx.count("aaaa", "aa")           -- 2 (non-overlapping)
local n = stringx.count("hello", "x")           -- 0
```

---

## capitalize

```
stringx.capitalize(str) -> string
```

Capitalize first letter, lowercase rest.

**Parameters:**
- `str` - String to capitalize

```lua
local s = stringx.capitalize("hello world")     -- "Hello world"
local s = stringx.capitalize("HELLO")           -- "Hello"
```

---

## title

```
stringx.title(str) -> string
```

Capitalize first letter of each word.

**Parameters:**
- `str` - String to convert to title case

```lua
local s = stringx.title("hello world")          -- "Hello World"
local s = stringx.title("the quick brown fox")  -- "The Quick Brown Fox"
```

---

## lpad

```
stringx.lpad(str, width, char?) -> string
```

Left pad string to width with character (space by default).

**Parameters:**
- `str` - String to pad
- `width` - Target width
- `char` (optional) - Padding character (default: space)

```lua
local s = stringx.lpad("hi", 5)                 -- "   hi"
local s = stringx.lpad("hi", 5, "0")            -- "000hi"
local s = stringx.lpad("hello", 3)              -- "hello" (no padding)
```

---

## rpad

```
stringx.rpad(str, width, char?) -> string
```

Right pad string to width with character (space by default).

**Parameters:**
- `str` - String to pad
- `width` - Target width
- `char` (optional) - Padding character (default: space)

```lua
local s = stringx.rpad("hi", 5)                 -- "hi   "
local s = stringx.rpad("hi", 5, "0")            -- "hi000"
```

---

## center

```
stringx.center(str, width, char?) -> string
```

Center string within width with character (space by default).

**Parameters:**
- `str` - String to center
- `width` - Target width
- `char` (optional) - Padding character (default: space)

```lua
local s = stringx.center("hi", 6)               -- "  hi  "
local s = stringx.center("hi", 5)               -- " hi  " (odd padding: right gets extra)
local s = stringx.center("hi", 6, "-")          -- "--hi--"
```

---

## is_alpha

```
stringx.is_alpha(str) -> boolean
```

Check if all characters are letters.

**Parameters:**
- `str` - String to check

```lua
local ok = stringx.is_alpha("hello")            -- true
local ok = stringx.is_alpha("hello123")         -- false
local ok = stringx.is_alpha("")                 -- false
```

**Alias:** `isalpha` (deprecated, use `is_alpha`)

---

## is_digit

```
stringx.is_digit(str) -> boolean
```

Check if all characters are digits (0-9).

**Parameters:**
- `str` - String to check

```lua
local ok = stringx.is_digit("123")              -- true
local ok = stringx.is_digit("12.3")             -- false
local ok = stringx.is_digit("")                 -- false
```

**Alias:** `isdigit` (deprecated, use `is_digit`)

---

## is_alnum

```
stringx.is_alnum(str) -> boolean
```

Check if all characters are alphanumeric.

**Parameters:**
- `str` - String to check

```lua
local ok = stringx.is_alnum("abc123")           -- true
local ok = stringx.is_alnum("abc-123")          -- false
local ok = stringx.is_alnum("")                 -- false
```

**Alias:** `isalnum` (deprecated, use `is_alnum`)

---

## is_space

```
stringx.is_space(str) -> boolean
```

Check if all characters are whitespace.

**Parameters:**
- `str` - String to check

```lua
local ok = stringx.is_space("   ")              -- true
local ok = stringx.is_space("\n\t")             -- true
local ok = stringx.is_space("  a  ")            -- false
local ok = stringx.is_space("")                 -- false
```

**Alias:** `isspace` (deprecated, use `is_space`)

---

## is_upper

```
stringx.is_upper(str) -> boolean
```

Check if all letters are uppercase (non-letters ignored).

**Parameters:**
- `str` - String to check

```lua
local ok = stringx.is_upper("HELLO")            -- true
local ok = stringx.is_upper("HELLO123")         -- true (digits ignored)
local ok = stringx.is_upper("Hello")            -- false
local ok = stringx.is_upper("123")              -- false (no letters)
```

**Alias:** `isupper` (deprecated, use `is_upper`)

---

## is_lower

```
stringx.is_lower(str) -> boolean
```

Check if all letters are lowercase (non-letters ignored).

**Parameters:**
- `str` - String to check

```lua
local ok = stringx.is_lower("hello")            -- true
local ok = stringx.is_lower("hello123")         -- true (digits ignored)
local ok = stringx.is_lower("Hello")            -- false
local ok = stringx.is_lower("123")              -- false (no letters)
```

**Alias:** `islower` (deprecated, use `is_lower`)

---

## is_empty

```
stringx.is_empty(str) -> boolean
```

Check if string is empty.

**Parameters:**
- `str` - String to check

```lua
local ok = stringx.is_empty("")                 -- true
local ok = stringx.is_empty("   ")              -- false
```

**Alias:** `isempty` (deprecated, use `is_empty`)

---

## is_blank

```
stringx.is_blank(str) -> boolean
```

Check if string is empty or only whitespace.

**Parameters:**
- `str` - String to check

```lua
local ok = stringx.is_blank("")                 -- true
local ok = stringx.is_blank("   ")              -- true
local ok = stringx.is_blank("\n\t")             -- true
local ok = stringx.is_blank("  a  ")            -- false
```

**Alias:** `isblank` (deprecated, use `is_blank`)

---

## splitlines

```
stringx.splitlines(str) -> table
```

Split string on newlines (handles `\n`, `\r\n`, `\r`).

**Parameters:**
- `str` - String to split

```lua
local lines = stringx.splitlines("a\nb\nc")     -- {"a", "b", "c"}
local lines = stringx.splitlines("a\r\nb\r\nc") -- {"a", "b", "c"}
local lines = stringx.splitlines("a\rb\rc")     -- {"a", "b", "c"}
local lines = stringx.splitlines("")            -- {}
```

---

## wrap

```
stringx.wrap(str, width) -> string
```

Word wrap text to specified width.

**Parameters:**
- `str` - Text to wrap
- `width` - Maximum line width

```lua
local text = "The quick brown fox jumps over the lazy dog"
local wrapped = stringx.wrap(text, 15)
-- "The quick brown\nfox jumps over\nthe lazy dog"

-- Long words are broken
local wrapped = stringx.wrap("supercalifragilistic", 10)
-- "supercalif\nragilistic"
```

---

## truncate

```
stringx.truncate(str, width, suffix?) -> string
```

Truncate string to width with suffix (default `...`).

**Parameters:**
- `str` - String to truncate
- `width` - Maximum width (including suffix)
- `suffix` (optional) - Suffix to append (default: `...`)

```lua
local s = stringx.truncate("long text here", 7)         -- "long..."
local s = stringx.truncate("short", 10)                 -- "short"
local s = stringx.truncate("text", 7, ">>")             -- "text>>"
local s = stringx.truncate("long text", 3, "...")       -- "..." (suffix fits exactly)
```

---

## import

```
stringx.import()
```

Add all StringX functions to the `string` library and string metatable.

```lua
stringx.import()

-- Now available on string library
local s = string.strip("  hello  ")

-- Now available as string methods
local s = "  hello  ":strip()
local ok = "hello":startswith("hel")
local parts = "a,b,c":split(",")
```

---

## Examples

### Text Processing Pipeline

```lua
local text = "  Hello World  "
local result = stringx.strip(text):lower():replace(" ", "-")
-- Requires import() for method chaining

stringx.import()
local result = "  Hello World  ":strip():lower():replace(" ", "-")
-- "hello-world"
```

### CSV Parsing

```lua
local csv = "name,age,city\nJohn,30,NYC\nJane,25,LA"
local rows = stringx.splitlines(csv)
local data = {}

for i, row in ipairs(rows) do
    if i > 1 then  -- Skip header
        local fields = stringx.split(row, ",")
        table.insert(data, {
            name = fields[1],
            age = tonumber(fields[2]),
            city = fields[3]
        })
    end
end
```

### Input Validation

```lua
function validate_username(username)
    if stringx.is_blank(username) then
        return false, "Username cannot be blank"
    end

    if not stringx.is_alnum(username) then
        return false, "Username must be alphanumeric"
    end

    if #username < 3 or #username > 20 then
        return false, "Username must be 3-20 characters"
    end

    return true
end
```

### Text Formatting

```lua
-- Create aligned table
local headers = {"Name", "Age", "City"}
local rows = {
    {"John", "30", "NYC"},
    {"Jane", "25", "LA"}
}

stringx.import()

for _, header in ipairs(headers) do
    io.write(header:rpad(15))
end
print()

for _, row in ipairs(rows) do
    for _, cell in ipairs(row) do
        io.write(cell:rpad(15))
    end
    print()
end

-- Output:
-- Name           Age            City
-- John           30             NYC
-- Jane           25             LA
```
