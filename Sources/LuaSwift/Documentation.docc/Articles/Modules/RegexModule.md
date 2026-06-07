# Regex Module

Regular expression support backed by NSRegularExpression (ICU regex engine).

## Overview

The Regex module provides full regular expression support including matching, replacing, and splitting. It wraps `NSRegularExpression`, which uses the ICU regex engine — the same engine used throughout Apple's platforms. This gives you Unicode-aware matching, named and numbered capture groups, and a well-specified replacement-template syntax.

## Installation

```swift
// Install all modules
try ModuleRegistry.install(in: engine)

// Or install just the Regex module
try RegexModule.install(in: engine)
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
- `pattern` - The ICU regex pattern string
- `flags` (optional) - String of flag characters:
  - `i` - Case-insensitive matching
  - `m` - Multiline mode (`^` and `$` match line boundaries)
  - `s` - Single-line / dotall mode (`.` matches newlines)

**Returns:** Compiled regex object

**Example:**

```lua
local regex = require("luaswift.regex")

-- Basic pattern
local word_re = regex.compile("\\w+")

-- Case-insensitive
local email_re = regex.compile("[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", "i")

-- Multiline: ^ and $ anchor to each line
local line_re = regex.compile("^\\d+", "m")
```

### regex.match(text, pattern)

Quick one-shot match without compilation. Use this for simple, one-time matches.

**Parameters:**
- `text` - The string to search in
- `pattern` - The ICU regex pattern string

**Returns:** Match object or `nil` if no match

**Example:**

```lua
local regex = require("luaswift.regex")

-- \$ in the pattern matches a literal dollar sign (ICU syntax)
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
- `stop` - End position (1-indexed, inclusive)
- `groups` - Array of capture group texts (1-indexed; `nil` for unmatched optional groups)

**Example:**

```lua
local regex = require("luaswift.regex")

local re = regex.compile("(\\w+)=(\\w+)")
local m = re:match("key=value")

print(m.text)       -- "key=value"
print(m.start)      -- 1
print(m.stop)       -- 9
print(m.groups[1])  -- "key"
print(m.groups[2])  -- "value"
```

### re:find_all(text)

Finds all non-overlapping matches in the text.

**Returns:** Array of match objects (same structure as `re:match`)

**Example:**

```lua
local regex = require("luaswift.regex")

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
local regex = require("luaswift.regex")

local email_re = regex.compile("[a-z]+@[a-z]+\\.[a-z]+", "i")

if email_re:test("Contact: user@example.com") then
    print("Contains email")
end
```

### re:replace(text, replacement)

Replaces the **first** match with the replacement string.

**Parameters:**
- `text` - The input string
- `replacement` - The replacement template (see Replacement Template Syntax below)

**Returns:** String with first match replaced

**Example:**

```lua
local regex = require("luaswift.regex")

local re = regex.compile("\\d+")
local result = re:replace("abc123def456", "XXX")
print(result)  -- "abcXXXdef456"
```

### re:replace_all(text, replacement)

Replaces **all** matches with the replacement string.

**Parameters:**
- `text` - The input string
- `replacement` - The replacement template (see Replacement Template Syntax below)

**Returns:** String with all matches replaced

**Example:**

```lua
local regex = require("luaswift.regex")

local re = regex.compile("(\\w+)@(\\w+\\.\\w+)")
local result = re:replace_all(
    "alice@example.com and bob@test.org",
    "[$1 at $2]"
)
print(result)  -- "[alice at example.com] and [bob at test.org]"
```

### re:split(text)

Splits the text at every position where the pattern matches.

**Parameters:**
- `text` - The string to split

**Returns:** Array of strings. If the pattern does not match, the array contains the original string as its only element.

**Example:**

```lua
local regex = require("luaswift.regex")

local re = regex.compile("[,;\\s]+")
local parts = re:split("apple, banana; cherry  date")

for _, part in ipairs(parts) do
    print(part)  -- "apple", "banana", "cherry", "date"
end
```

## Replacement Template Syntax

`replace` and `replace_all` accept an ICU replacement template string
(processed by `NSRegularExpression.replacementString(for:in:offset:template:)`).

| Template token | Expands to |
|----------------|-----------|
| `$0` | The entire matched substring |
| `$1`, `$2`, … | Capture group 1, 2, … |
| `\$` | A literal dollar sign (`"\\$"` in a Lua string literal) |

> **Important — escaping a literal `$`:** Because `$` introduces a back-reference in the template, a literal dollar sign must be written as `\$`. In a Lua string literal that is two characters: a backslash followed by a dollar sign — written `"\\$"`.
>
> `$$` is **not** valid escape syntax in this template language and does not produce a literal dollar sign.

**Example — preserve a currency symbol:**

```lua
local regex = require("luaswift.regex")

-- Pattern: match a dollar amount like $19.99
-- Replacement: wrap it in angle brackets, keeping the $ sign
-- Use \$ in the template to emit a literal dollar sign
local re = regex.compile("\\$[\\d.]+")
local result = re:replace_all("Pay $19.99 or $5.00", "<\\$&>")
-- Note: $& is not supported; use $0 for the full match
local result2 = re:replace_all("Pay $19.99 or $5.00", "USD\\$0")
-- Wrong — $0 is the back-reference, not the literal text "$0"
-- Correct approach: capture the digits and reconstruct
local re2 = regex.compile("\\$([\\d.]+)")
local result3 = re2:replace_all("Pay $19.99 or $5.00", "USD\\$$1")
print(result3)  -- "Pay USD$19.99 or USD$5.00"
```

**Example — phone number reformatting:**

```lua
local regex = require("luaswift.regex")

local phone_re = regex.compile("(\\d{3})(\\d{3})(\\d{4})")
local formatted = phone_re:replace("5551234567", "($1) $2-$3")
print(formatted)  -- "(555) 123-4567"
```

## Pattern Syntax

The module accepts standard ICU regular expression syntax. The tables below cover the most commonly used features.

### Character Classes

| Pattern | Description |
|---------|-------------|
| `.` | Any character except newline (use `s` flag to include newline) |
| `\d` | Digit `[0-9]` |
| `\D` | Non-digit |
| `\w` | Word character `[a-zA-Z0-9_]` |
| `\W` | Non-word character |
| `\s` | Whitespace |
| `\S` | Non-whitespace |
| `[abc]` | Any of a, b, c |
| `[^abc]` | Not a, b, or c |
| `[a-z]` | Range a to z |

> In Lua string literals, every regex backslash must be doubled: `\d` is written `"\\d"`.

### Quantifiers

| Pattern | Description |
|---------|-------------|
| `*` | 0 or more (greedy) |
| `+` | 1 or more (greedy) |
| `?` | 0 or 1 (greedy) |
| `{n}` | Exactly n |
| `{n,}` | n or more |
| `{n,m}` | Between n and m |
| `*?`, `+?`, `??` | Non-greedy (lazy) versions |

### Anchors

| Pattern | Description |
|---------|-------------|
| `^` | Start of string (or line in `m` mode) |
| `$` | End of string (or line in `m` mode) |
| `\b` | Word boundary |
| `\B` | Non-word boundary |

### Groups

| Pattern | Description |
|---------|-------------|
| `(...)` | Capture group |
| `(?:...)` | Non-capturing group |
| `(?=...)` | Positive lookahead |
| `(?!...)` | Negative lookahead |
| `(?<=...)` | Positive lookbehind |
| `(?<!...)` | Negative lookbehind |

## Common Patterns

### Email Validation

```lua
local regex = require("luaswift.regex")

local email_re = regex.compile(
    "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
)

if email_re:test("user@example.com") then
    print("Valid email")
end
```

### URL Extraction

```lua
local regex = require("luaswift.regex")

local url_re = regex.compile("https?://[^\\s]+")
local urls = url_re:find_all("Visit https://example.com or http://test.org")

for _, m in ipairs(urls) do
    print(m.text)
end
```

### Phone Number Formatting

```lua
local regex = require("luaswift.regex")

local phone_re = regex.compile("(\\d{3})(\\d{3})(\\d{4})")
local formatted = phone_re:replace("5551234567", "($1) $2-$3")
print(formatted)  -- "(555) 123-4567"
```

### Parsing Key-Value Pairs

```lua
local regex = require("luaswift.regex")

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
local regex = require("luaswift.regex")

-- Collapse runs of whitespace to a single space
local spaces_re = regex.compile("\\s+")
local cleaned = spaces_re:replace_all("too   many    spaces", " ")
print(cleaned)  -- "too many spaces"

-- Trim leading and trailing whitespace
local trim_re = regex.compile("^\\s+|\\s+$")
local trimmed = trim_re:replace_all("  hello world  ", "")
print(trimmed)  -- "hello world"
```

## Error Handling

Invalid patterns or unsupported flags throw an error that can be caught with `pcall`:

```lua
local regex = require("luaswift.regex")

local ok, err = pcall(function()
    return regex.compile("[invalid(")
end)

if not ok then
    print("Regex error: " .. err)
end
```

Valid flags are `i`, `m`, and `s`. Any other flag character also throws an error.

## Performance Tips

1. **Compile once, reuse many times** — `regex.compile` returns an object backed by a compiled `NSRegularExpression`; store it in a local or upvalue and call its methods repeatedly rather than calling `regex.match` in a loop.
2. **Use `test()` for existence checks** — It short-circuits after finding the first match and returns a boolean, with no allocation for a match object.
3. **Be specific** — Anchored and specific patterns are faster than broad ones.
4. **Avoid catastrophic backtracking** — Patterns like `(a+)+b` on long non-matching strings can be very slow; prefer possessive quantifiers or atomic groups when available in ICU.

## See Also

- ``RegexModule``
- ``StringXModule``
- ``UTF8XModule``
