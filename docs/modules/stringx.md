# StringX Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.stringx` | **Global:** `stringx` | **Extends:** `string` (via `import()`)

String utilities inspired by Python and Penlight, providing trimming, splitting, padding, case conversion, and text processing.

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

## Functions

### strip(str, chars?)

Remove leading and trailing characters (whitespace by default).

```lua
local s = stringx.strip("  hello  ")      -- "hello"
local s = stringx.strip("xxhelloxx", "x") -- "hello"
local s = stringx.strip("\n\ttext\t\n")   -- "text"
```

### lstrip(str, chars?)

Remove leading characters only.

```lua
local s = stringx.lstrip("  hello  ")     -- "hello  "
local s = stringx.lstrip("xxhello", "x")  -- "hello"
```

### rstrip(str, chars?)

Remove trailing characters only.

```lua
local s = stringx.rstrip("  hello  ")     -- "  hello"
local s = stringx.rstrip("helloxx", "x")  -- "hello"
```

### split(str, separator)

Split string by separator into array.

```lua
local parts = stringx.split("a,b,c", ",")       -- {"a", "b", "c"}
local parts = stringx.split("a::b::c", "::")    -- {"a", "b", "c"}
local chars = stringx.split("hello", "")        -- {"h", "e", "l", "l", "o"}
```

### join(array, separator)

Join array elements with separator.

```lua
local s = stringx.join({"a", "b", "c"}, ",")    -- "a,b,c"
local s = stringx.join({"one", "two"}, " ")     -- "one two"
local s = stringx.join({}, ",")                 -- ""
```

### replace(str, old, new, count?)

Replace occurrences of old string with new string.

```lua
local s = stringx.replace("hello world", "world", "Lua")  -- "hello Lua"
local s = stringx.replace("aaa", "a", "b")                -- "bbb"
local s = stringx.replace("aaa", "a", "b", 2)             -- "bba" (limit to 2)
```

### startswith(str, prefix)

Check if string starts with prefix.

```lua
local ok = stringx.startswith("hello", "hel")   -- true
local ok = stringx.startswith("hello", "lo")    -- false
```

### endswith(str, suffix)

Check if string ends with suffix.

```lua
local ok = stringx.endswith("hello", "lo")      -- true
local ok = stringx.endswith("hello", "hel")     -- false
```

### contains(str, substring)

Check if string contains substring.

```lua
local ok = stringx.contains("hello", "ell")     -- true
local ok = stringx.contains("hello", "world")   -- false
local ok = stringx.contains("hello", "")        -- true (empty always contained)
```

### count(str, pattern)

Count occurrences of pattern in string.

```lua
local n = stringx.count("hello", "l")           -- 2
local n = stringx.count("aaaa", "aa")           -- 2 (non-overlapping)
local n = stringx.count("hello", "x")           -- 0
```

### capitalize(str)

Capitalize first letter, lowercase rest.

```lua
local s = stringx.capitalize("hello world")     -- "Hello world"
local s = stringx.capitalize("HELLO")           -- "Hello"
```

### title(str)

Capitalize first letter of each word.

```lua
local s = stringx.title("hello world")          -- "Hello World"
local s = stringx.title("the quick brown fox")  -- "The Quick Brown Fox"
```

### lpad(str, width, char?)

Left pad string to width with character (space by default).

```lua
local s = stringx.lpad("hi", 5)                 -- "   hi"
local s = stringx.lpad("hi", 5, "0")            -- "000hi"
local s = stringx.lpad("hello", 3)              -- "hello" (no padding)
```

### rpad(str, width, char?)

Right pad string to width with character (space by default).

```lua
local s = stringx.rpad("hi", 5)                 -- "hi   "
local s = stringx.rpad("hi", 5, "0")            -- "hi000"
```

### center(str, width, char?)

Center string within width with character (space by default).

```lua
local s = stringx.center("hi", 6)               -- "  hi  "
local s = stringx.center("hi", 5)               -- " hi  " (odd padding: right gets extra)
local s = stringx.center("hi", 6, "-")          -- "--hi--"
```

### is_alpha(str)

Check if all characters are letters.

```lua
local ok = stringx.is_alpha("hello")            -- true
local ok = stringx.is_alpha("hello123")         -- false
local ok = stringx.is_alpha("")                 -- false
```

**Alias:** `isalpha` (deprecated, use `is_alpha`)

### is_digit(str)

Check if all characters are digits (0-9).

```lua
local ok = stringx.is_digit("123")              -- true
local ok = stringx.is_digit("12.3")             -- false
local ok = stringx.is_digit("")                 -- false
```

**Alias:** `isdigit` (deprecated, use `is_digit`)

### is_alnum(str)

Check if all characters are alphanumeric.

```lua
local ok = stringx.is_alnum("abc123")           -- true
local ok = stringx.is_alnum("abc-123")          -- false
local ok = stringx.is_alnum("")                 -- false
```

**Alias:** `isalnum` (deprecated, use `is_alnum`)

### is_space(str)

Check if all characters are whitespace.

```lua
local ok = stringx.is_space("   ")              -- true
local ok = stringx.is_space("\n\t")             -- true
local ok = stringx.is_space("  a  ")            -- false
local ok = stringx.is_space("")                 -- false
```

**Alias:** `isspace` (deprecated, use `is_space`)

### is_upper(str)

Check if all letters are uppercase (non-letters ignored).

```lua
local ok = stringx.is_upper("HELLO")            -- true
local ok = stringx.is_upper("HELLO123")         -- true (digits ignored)
local ok = stringx.is_upper("Hello")            -- false
local ok = stringx.is_upper("123")              -- false (no letters)
```

**Alias:** `isupper` (deprecated, use `is_upper`)

### is_lower(str)

Check if all letters are lowercase (non-letters ignored).

```lua
local ok = stringx.is_lower("hello")            -- true
local ok = stringx.is_lower("hello123")         -- true (digits ignored)
local ok = stringx.is_lower("Hello")            -- false
local ok = stringx.is_lower("123")              -- false (no letters)
```

**Alias:** `islower` (deprecated, use `is_lower`)

### is_empty(str)

Check if string is empty.

```lua
local ok = stringx.is_empty("")                 -- true
local ok = stringx.is_empty("   ")              -- false
```

**Alias:** `isempty` (deprecated, use `is_empty`)

### is_blank(str)

Check if string is empty or only whitespace.

```lua
local ok = stringx.is_blank("")                 -- true
local ok = stringx.is_blank("   ")              -- true
local ok = stringx.is_blank("\n\t")             -- true
local ok = stringx.is_blank("  a  ")            -- false
```

**Alias:** `isblank` (deprecated, use `is_blank`)

### splitlines(str)

Split string on newlines (handles `\n`, `\r\n`, `\r`).

```lua
local lines = stringx.splitlines("a\nb\nc")     -- {"a", "b", "c"}
local lines = stringx.splitlines("a\r\nb\r\nc") -- {"a", "b", "c"}
local lines = stringx.splitlines("a\rb\rc")     -- {"a", "b", "c"}
local lines = stringx.splitlines("")            -- {}
```

### wrap(str, width)

Word wrap text to specified width.

```lua
local text = "The quick brown fox jumps over the lazy dog"
local wrapped = stringx.wrap(text, 15)
-- "The quick brown\nfox jumps over\nthe lazy dog"

-- Long words are broken
local wrapped = stringx.wrap("supercalifragilistic", 10)
-- "supercalif\nragilistic"
```

### truncate(str, width, suffix?)

Truncate string to width with suffix (default `...`).

```lua
local s = stringx.truncate("long text here", 7)         -- "long..."
local s = stringx.truncate("short", 10)                 -- "short"
local s = stringx.truncate("text", 7, ">>")             -- "text>>"
local s = stringx.truncate("long text", 3, "...")       -- "..." (suffix fits exactly)
```

### import()

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

## Function Reference

| Function | Description |
|----------|-------------|
| `strip(str, chars?)` | Remove leading and trailing characters |
| `lstrip(str, chars?)` | Remove leading characters |
| `rstrip(str, chars?)` | Remove trailing characters |
| `split(str, sep)` | Split string by separator |
| `join(array, sep)` | Join array with separator |
| `replace(str, old, new, count?)` | Replace occurrences |
| `startswith(str, prefix)` | Check prefix |
| `endswith(str, suffix)` | Check suffix |
| `contains(str, substring)` | Check substring |
| `count(str, pattern)` | Count occurrences |
| `capitalize(str)` | Capitalize first letter |
| `title(str)` | Title case all words |
| `lpad(str, width, char?)` | Left pad to width |
| `rpad(str, width, char?)` | Right pad to width |
| `center(str, width, char?)` | Center pad to width |
| `is_alpha(str)` | Check all letters |
| `is_digit(str)` | Check all digits |
| `is_alnum(str)` | Check alphanumeric |
| `is_space(str)` | Check all whitespace |
| `is_upper(str)` | Check uppercase letters |
| `is_lower(str)` | Check lowercase letters |
| `is_empty(str)` | Check empty string |
| `is_blank(str)` | Check empty or whitespace |
| `splitlines(str)` | Split on newlines |
| `wrap(str, width)` | Word wrap to width |
| `truncate(str, width, suffix?)` | Truncate with suffix |
| `import()` | Extend string library |
