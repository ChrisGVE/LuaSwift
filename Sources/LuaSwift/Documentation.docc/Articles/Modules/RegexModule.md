# Regex Module

Powerful regular expression support using Swift's native regex engine.

## Overview

The Regex module provides full regular expression support including matching, replacing, and splitting. It uses Swift's native regex engine for optimal performance and Unicode support.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the Regex module
ModuleRegistry.installRegexModule(in: engine)
```

## Basic Usage

```lua
local regex = require("luaswift.regex")

-- Quick match (no compilation needed)
local match = regex.match("Hello World", "\\w+")
print(match.text)  -- "Hello"

-- Compile pattern for reuse
local re = regex.compile("[a-z]+@[a-z]+\\.[a-z]+", "i")

-- Test if pattern matches
if re:test("user@example.com") then
    print("Valid email format")
end

-- Find first match
local m = re:match("Contact: admin@site.com")
print(m.text)  -- "admin@site.com"

-- Replace matches
local result = re:replace_all("email: a@b.com and c@d.com", "[REDACTED]")
print(result)  -- "email: [REDACTED] and [REDACTED]"
```

## API Reference

### regex.compile(pattern, flags?)

Compiles a regular expression pattern for reuse.

**Parameters:**
- `pattern` - The regex pattern string
- `flags` (optional) - String of flag characters:
  - `i` - Case-insensitive matching
  - `m` - Multiline mode (^ and $ match line boundaries)
  - `s` - Single-line mode (. matches newlines)

**Returns:** Compiled regex object

**Example:**

```lua
-- Basic pattern
local word_re = regex.compile("\\w+")

-- Case-insensitive
local email_re = regex.compile("[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", "i")

-- Multiline
local line_re = regex.compile("^\\d+", "m")
```

### regex.match(text, pattern)

Quick one-shot match without compilation. Use this for simple, one-time matches.

**Parameters:**
- `text` - The string to search in
- `pattern` - The regex pattern string

**Returns:** Match object or `nil` if no match

**Example:**

```lua
local m = regex.match("Price: $19.99", "\\$([\\d.]+)")
if m then
    print(m.text)       -- "$19.99"
    print(m.groups[1])  -- "19.99"
end
```

## Compiled Regex Methods

### re:match(text)

Finds the first match in the text.

**Returns:** Match object or `nil`

Match object fields:
- `text` - The matched text
- `start` - Start position (1-indexed)
- `stop` - End position (1-indexed)
- `groups` - Array of capture group texts

**Example:**

```lua
local re = regex.compile("(\\w+)=(\\w+)")
local m = re:match("key=value")

print(m.text)       -- "key=value"
print(m.start)      -- 1
print(m.stop)       -- 9
print(m.groups[1])  -- "key"
print(m.groups[2])  -- "value"
```

### re:find_all(text)

Finds all matches in the text.

**Returns:** Array of match objects

**Example:**

```lua
local re = regex.compile("\\d+")
local matches = re:find_all("a1b22c333")

for _, m in ipairs(matches) do
    print(m.text)  -- "1", "22", "333"
end
```

### re:test(text)

Tests if the pattern matches anywhere in the text.

**Returns:** `true` if pattern matches, `false` otherwise

**Example:**

```lua
local email_re = regex.compile("[a-z]+@[a-z]+\\.[a-z]+", "i")

if email_re:test("Contact: user@example.com") then
    print("Contains email")
end
```

### re:replace(text, replacement)

Replaces the first match with the replacement string.

**Parameters:**
- `text` - The input string
- `replacement` - The replacement string (supports `$0`, `$1`, etc.)

**Returns:** String with first match replaced

**Example:**

```lua
local re = regex.compile("\\d+")
local result = re:replace("abc123def456", "XXX")
print(result)  -- "abcXXXdef456"
```

### re:replace_all(text, replacement)

Replaces all matches with the replacement string.

**Parameters:**
- `text` - The input string
- `replacement` - The replacement string (supports `$0`, `$1`, etc.)

**Returns:** String with all matches replaced

**Replacement patterns:**
- `$0` - The entire match
- `$1`, `$2`, ... - Capture groups
- `$$` - Literal dollar sign

**Example:**

```lua
local re = regex.compile("(\\w+)@(\\w+\\.\\w+)")
local result = re:replace_all(
    "alice@example.com and bob@test.org",
    "[$1 at $2]"
)
print(result)  -- "[alice at example.com] and [bob at test.org]"
```

### re:split(text)

Splits the text by the pattern.

**Parameters:**
- `text` - The string to split

**Returns:** Array of strings

**Example:**

```lua
local re = regex.compile("[,;\\s]+")
local parts = re:split("apple, banana; cherry  date")

for _, part in ipairs(parts) do
    print(part)  -- "apple", "banana", "cherry", "date"
end
```

## Pattern Syntax

### Character Classes

| Pattern | Description |
|---------|-------------|
| `.` | Any character (except newline) |
| `\d` | Digit [0-9] |
| `\D` | Non-digit |
| `\w` | Word character [a-zA-Z0-9_] |
| `\W` | Non-word character |
| `\s` | Whitespace |
| `\S` | Non-whitespace |
| `[abc]` | Any of a, b, c |
| `[^abc]` | Not a, b, or c |
| `[a-z]` | Range a to z |

### Quantifiers

| Pattern | Description |
|---------|-------------|
| `*` | 0 or more |
| `+` | 1 or more |
| `?` | 0 or 1 |
| `{n}` | Exactly n |
| `{n,}` | n or more |
| `{n,m}` | Between n and m |
| `*?`, `+?` | Non-greedy versions |

### Anchors

| Pattern | Description |
|---------|-------------|
| `^` | Start of string/line |
| `$` | End of string/line |
| `\b` | Word boundary |
| `\B` | Non-word boundary |

### Groups

| Pattern | Description |
|---------|-------------|
| `(...)` | Capture group |
| `(?:...)` | Non-capturing group |
| `(?=...)` | Positive lookahead |
| `(?!...)` | Negative lookahead |

## Common Patterns

### Email Validation

```lua
local email_re = regex.compile(
    "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
)

if email_re:test("user@example.com") then
    print("Valid email")
end
```

### URL Extraction

```lua
local url_re = regex.compile("https?://[^\\s]+")
local urls = url_re:find_all("Visit https://example.com or http://test.org")

for _, m in ipairs(urls) do
    print(m.text)
end
```

### Phone Number Formatting

```lua
local phone_re = regex.compile("(\\d{3})(\\d{3})(\\d{4})")
local formatted = phone_re:replace("5551234567", "($1) $2-$3")
print(formatted)  -- "(555) 123-4567"
```

### Parsing Key-Value Pairs

```lua
local kv_re = regex.compile("(\\w+)\\s*=\\s*([^,]+)")
local text = "name=John, age=30, city=NYC"

for _, m in ipairs(kv_re:find_all(text)) do
    print(m.groups[1] .. " -> " .. m.groups[2])
end
-- name -> John
-- age -> 30
-- city -> NYC
```

### Cleaning Whitespace

```lua
-- Remove extra spaces
local spaces_re = regex.compile("\\s+")
local cleaned = spaces_re:replace_all("too   many    spaces", " ")
print(cleaned)  -- "too many spaces"

-- Trim leading/trailing whitespace
local trim_re = regex.compile("^\\s+|\\s+$")
local trimmed = trim_re:replace_all("  hello world  ", "")
print(trimmed)  -- "hello world"
```

## Error Handling

Invalid patterns throw an error:

```lua
local success, result = pcall(function()
    return regex.compile("[invalid(")
end)

if not success then
    print("Regex error: " .. result)
end
```

## Performance Tips

1. **Compile once, use many times** - For patterns used repeatedly, compile once and reuse
2. **Use `test()` for existence checks** - It's faster than `match()` when you only need boolean
3. **Be specific** - More specific patterns are often faster than broad ones
4. **Avoid catastrophic backtracking** - Patterns like `(a+)+` can be very slow

## See Also

- ``RegexModule``
- ``StringXModule``
- ``UTF8XModule``
