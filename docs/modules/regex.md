# Regex Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.regex` | **Global:** `regex` (also extends `string` after extend_stdlib)

Full regular expression support using ICU regex syntax via NSRegularExpression. Provides pattern compilation, matching, replacement, splitting, and capture group extraction.

## Quick Start

```lua
local regex = require("luaswift.regex")

-- Quick one-shot match
local match = regex.match("Email: user@example.com", "\\b\\w+@\\w+\\.\\w+\\b")
-- Returns: {start=8, stop=24, text="user@example.com", groups={}}

-- Compile for reuse (more efficient)
local email_re = regex.compile("\\b(\\w+)@(\\w+)\\.(\\w+)\\b", "i")
local match = email_re:match("Contact: Support@Example.COM")
-- Returns: {start=10, stop=28, text="Support@Example.COM", groups={"Support", "Example", "COM"}}
```

## Pattern Compilation

### regex.compile(pattern, flags)

Compiles a regex pattern for efficient reuse. Returns a regex object with methods for matching, replacing, and splitting.

**Parameters:**
- `pattern` (string): ICU regular expression pattern
- `flags` (string, optional): Modifier flags:
  - `"i"` - case insensitive matching
  - `"m"` - multiline mode (^ and $ match line boundaries)
  - `"s"` - dotall mode (. matches newlines)
  - Flags can be combined: `"im"`, `"ims"`, etc.

**Returns:** Compiled regex object

```lua
local re = regex.compile("\\d+", "i")
local re = regex.compile("^line\\s*$", "m")  -- Match "line" on any line
local re = regex.compile("start.*end", "s")  -- . matches newlines
```

## Matching

### regex.match(text, pattern)

Quick one-shot match without compilation. Useful for single-use patterns.

**Parameters:**
- `text` (string): Text to search
- `pattern` (string): Regex pattern

**Returns:** Match table or `nil` if no match

```lua
local match = regex.match("Price: $42.99", "\\$([0-9.]+)")
-- Returns: {start=8, stop=14, text="$42.99", groups={"42.99"}}
```

### re:match(text)

Find the first match in text using a compiled pattern.

**Parameters:**
- `text` (string): Text to search

**Returns:** Match table or `nil`

**Match table structure:**
- `start` (number): 1-based start position
- `stop` (number): 1-based end position (inclusive)
- `text` (string): Full matched text
- `groups` (array): Captured groups (empty array if no groups)

```lua
local re = regex.compile("(\\d{3})-(\\d{3})-(\\d{4})")
local match = re:match("Call 555-123-4567 today")

if match then
    print("Found:", match.text)           -- "555-123-4567"
    print("Position:", match.start)       -- 6
    print("Area code:", match.groups[1])  -- "555"
    print("Exchange:", match.groups[2])   -- "123"
    print("Number:", match.groups[3])     -- "4567"
end
```

### re:find_all(text)

Find all non-overlapping matches in text.

**Parameters:**
- `text` (string): Text to search

**Returns:** Array of match tables (empty array if no matches)

```lua
local re = regex.compile("\\b\\w+\\b")
local matches = re:find_all("one two three")

for i, match in ipairs(matches) do
    print(i, match.text)  -- 1 "one", 2 "two", 3 "three"
end
```

### re:test(text)

Test if pattern matches anywhere in text.

**Parameters:**
- `text` (string): Text to test

**Returns:** `true` if match found, `false` otherwise

```lua
local email_re = regex.compile("@\\w+\\.\\w+")

if email_re:test("user@example.com") then
    print("Valid email format")
end
```

## Replacement

### re:replace(text, replacement)

Replace the first match with replacement string. Supports capture group references.

**Parameters:**
- `text` (string): Text to modify
- `replacement` (string): Replacement string with optional references:
  - `$0` - Full match
  - `$1`, `$2`, etc. - Capture groups
  - `$$` - Literal dollar sign

**Returns:** Modified string

```lua
local re = regex.compile("(\\w+)\\s+(\\w+)")
local result = re:replace("hello world", "$2 $1")
-- Returns: "world hello"

-- Redact first email
local email_re = regex.compile("\\b\\w+@\\w+\\.\\w+\\b")
local result = email_re:replace("Send to user@example.com or admin@example.com", "[REDACTED]")
-- Returns: "Send to [REDACTED] or admin@example.com"
```

### re:replace_all(text, replacement)

Replace all matches with replacement string.

**Parameters:**
- `text` (string): Text to modify
- `replacement` (string): Replacement string (same syntax as `replace`)

**Returns:** Modified string

```lua
-- Wrap all numbers in brackets
local re = regex.compile("\\d+")
local result = re:replace_all("Room 123 costs $45", "[$0]")
-- Returns: "Room [123] costs $[45]"

-- Redact all emails
local email_re = regex.compile("\\b\\w+@\\w+\\.\\w+\\b")
local result = email_re:replace_all("Contact user@example.com or admin@example.com", "[REDACTED]")
-- Returns: "Contact [REDACTED] or [REDACTED]"
```

## Splitting

### re:split(text)

Split text by pattern matches. Returns array of strings between matches.

**Parameters:**
- `text` (string): Text to split

**Returns:** Array of strings

```lua
-- Split by comma with optional whitespace
local re = regex.compile("\\s*,\\s*")
local parts = re:split("one, two,three,  four")
-- Returns: {"one", "two", "three", "four"}

-- Split by whitespace
local ws_re = regex.compile("\\s+")
local words = ws_re:split("  hello   world  ")
-- Returns: {"", "hello", "world", ""}

-- Split CSV line (simple case)
local csv_re = regex.compile(",")
local fields = csv_re:split("name,email,age")
-- Returns: {"name", "email", "age"}
```

## Pattern Syntax

LuaSwift uses ICU regular expression syntax (NSRegularExpression). Key differences from Lua patterns:

| Feature | ICU Regex | Lua Pattern |
|---------|-----------|-------------|
| Character class | `[a-z]` | `[a-z]` |
| Negated class | `[^a-z]` | `[^a-z]` |
| Any character | `.` | `.` |
| Digit | `\d` | `%d` |
| Word character | `\w` | Not available |
| Whitespace | `\s` | `%s` |
| Word boundary | `\b` | Not available |
| Zero or more | `*` | `*` |
| One or more | `+` | `+` |
| Optional | `?` | `-` or `?` |
| Exact count | `{3}` | Not available |
| Range | `{2,5}` | Not available |
| Capturing group | `(...)` | `(...)` |
| Non-capturing | `(?:...)` | Not available |
| Alternation | `a|b` | Not available |
| Escape | `\` | `%` |

**Common ICU patterns:**

```lua
-- Email (basic)
"\\b[\\w._%+-]+@[\\w.-]+\\.[A-Za-z]{2,}\\b"

-- URL
"https?://[\\w.-]+(?:\\.[\\w\\.-]+)+[\\w\\-\\._~:/?#\\[\\]@!\\$&'\\(\\)\\*\\+,;=.]+"

-- Phone (US)
"\\(?\\d{3}\\)?[-.\\s]?\\d{3}[-.\\s]?\\d{4}"

-- IPv4 address
"\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b"

-- Hex color
"#[0-9A-Fa-f]{6}\\b"

-- Date (YYYY-MM-DD)
"\\b\\d{4}-\\d{2}-\\d{2}\\b"
```

## Examples

### Extract all URLs from text

```lua
local url_re = regex.compile("https?://[\\w.-]+(?:\\.[\\w\\.-]+)+[\\w\\-\\._~:/?#\\[\\]@!\\$&'\\(\\)\\*\\+,;=.]*")
local text = "Visit https://example.com or http://test.org/path?query=1"
local matches = url_re:find_all(text)

for _, match in ipairs(matches) do
    print(match.text)
end
-- Output:
-- https://example.com
-- http://test.org/path?query=1
```

### Validate and parse structured data

```lua
-- Parse log entries
local log_re = regex.compile("^\\[(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})\\] (\\w+): (.*)$")
local entry = "[2025-01-11 14:30:45] ERROR: Connection timeout"
local match = log_re:match(entry)

if match then
    local timestamp = match.groups[1]  -- "2025-01-11 14:30:45"
    local level = match.groups[2]      -- "ERROR"
    local message = match.groups[3]    -- "Connection timeout"
end
```

### Clean and normalize text

```lua
-- Remove extra whitespace
local ws_re = regex.compile("\\s+")
local clean = ws_re:replace_all("  hello    world  ", " ")
-- Returns: " hello world "

-- Normalize phone numbers
local phone_re = regex.compile("\\(?\\d{3}\\)?[-.\\s]?\\d{3}[-.\\s]?\\d{4}")
local normalize = function(text)
    local matches = phone_re:find_all(text)
    for _, match in ipairs(matches) do
        -- Extract digits only
        local digits = string.gsub(match.text, "%D", "")
        text = string.gsub(text, match.text, string.format("%s-%s-%s",
            string.sub(digits, 1, 3),
            string.sub(digits, 4, 6),
            string.sub(digits, 7, 10)))
    end
    return text
end

print(normalize("Call (555) 123-4567 or 555.987.6543"))
-- Returns: "Call 555-123-4567 or 555-987-6543"
```

### Data extraction with groups

```lua
-- Parse CSV with quoted fields
local csv_re = regex.compile('"([^"]*)"|([^,]+)')
local parse_csv = function(line)
    local fields = {}
    local matches = csv_re:find_all(line)
    for _, match in ipairs(matches) do
        -- Use first non-nil group
        local value = match.groups[1] or match.groups[2]
        table.insert(fields, value)
    end
    return fields
end

local fields = parse_csv('"Name","Email",Age')
-- Returns: {"Name", "Email", "Age"}
```

## Function Reference

| Function | Description |
|----------|-------------|
| `regex.compile(pattern, flags?)` | Compile a regex pattern with optional flags (`"i"`, `"m"`, `"s"`) |
| `regex.match(text, pattern)` | Quick one-shot match without compilation |
| `re:match(text)` | Find first match, returns match table or `nil` |
| `re:find_all(text)` | Find all matches, returns array of match tables |
| `re:test(text)` | Test if pattern matches, returns boolean |
| `re:replace(text, replacement)` | Replace first match with template string |
| `re:replace_all(text, replacement)` | Replace all matches with template string |
| `re:split(text)` | Split text by pattern, returns array of strings |

**Match table fields:** `start`, `stop`, `text`, `groups`

**Replacement template syntax:** `$0` (full match), `$1...$n` (groups), `$$` (literal `$`)
