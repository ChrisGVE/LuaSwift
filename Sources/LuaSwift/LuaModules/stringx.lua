-- stringx.lua - Extended String Utilities for Lua 5.4.7
-- Copyright (c) 2025 LuaSwift Project
-- Licensed under the MIT License
--
-- A pure Lua module providing extended string manipulation functions.
-- Designed for use with LuaSwift on iOS/macOS.

local stringx = {}

--------------------------------------------------------------------------------
-- Trimming Functions
--------------------------------------------------------------------------------

-- Remove leading and trailing whitespace
-- @param s: input string
-- @return: trimmed string
function stringx.trim(s)
    if s == nil then return nil end
    return (tostring(s):match("^%s*(.-)%s*$"))
end

-- Remove leading whitespace only
-- @param s: input string
-- @return: left-trimmed string
function stringx.ltrim(s)
    if s == nil then return nil end
    return (tostring(s):match("^%s*(.*)"))
end

-- Remove trailing whitespace only
-- @param s: input string
-- @return: right-trimmed string
function stringx.rtrim(s)
    if s == nil then return nil end
    return (tostring(s):match("(.-)%s*$"))
end

-- Remove specific characters from both ends
-- @param s: input string
-- @param chars: string of characters to remove (default: whitespace)
-- @return: stripped string
function stringx.strip(s, chars)
    if s == nil then return nil end
    s = tostring(s)
    if chars == nil or chars == "" then
        return stringx.trim(s)
    end
    local pattern = "[" .. chars:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "]"
    -- Strip from left
    while #s > 0 and s:sub(1, 1):match(pattern) do
        s = s:sub(2)
    end
    -- Strip from right
    while #s > 0 and s:sub(-1):match(pattern) do
        s = s:sub(1, -2)
    end
    return s
end

--------------------------------------------------------------------------------
-- Case Conversion Functions
--------------------------------------------------------------------------------

-- Capitalize first letter, lowercase rest
-- @param s: input string
-- @return: capitalized string
function stringx.capitalize(s)
    if s == nil then return nil end
    s = tostring(s)
    if #s == 0 then return s end
    return s:sub(1, 1):upper() .. s:sub(2):lower()
end

-- Title Case Each Word
-- @param s: input string
-- @return: title-cased string
function stringx.title(s)
    if s == nil then return nil end
    s = tostring(s)
    return (s:gsub("(%S)(%S*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

--------------------------------------------------------------------------------
-- Splitting and Joining Functions
--------------------------------------------------------------------------------

-- Split string by separator
-- @param s: input string
-- @param sep: separator string (default: whitespace)
-- @return: array of substrings
function stringx.split(s, sep)
    if s == nil then return {} end
    s = tostring(s)
    local result = {}

    if sep == nil or sep == "" then
        -- Split by whitespace
        for part in s:gmatch("%S+") do
            table.insert(result, part)
        end
    else
        -- Split by literal separator
        local pattern = "([^" .. sep:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "]*)"
        local pos = 1
        local first = true
        for part in s:gmatch(pattern) do
            if first then
                table.insert(result, part)
                first = false
            elseif pos <= #s then
                table.insert(result, part)
            end
            pos = pos + #part + #sep
        end
    end

    return result
end

-- Split string by newlines
-- @param s: input string
-- @return: array of lines
function stringx.splitlines(s)
    if s == nil then return {} end
    s = tostring(s)
    local result = {}
    local pos = 1

    while pos <= #s do
        local line_end = s:find("[\r\n]", pos)
        if line_end then
            table.insert(result, s:sub(pos, line_end - 1))
            -- Handle \r\n as single newline
            if s:sub(line_end, line_end) == "\r" and s:sub(line_end + 1, line_end + 1) == "\n" then
                pos = line_end + 2
            else
                pos = line_end + 1
            end
        else
            table.insert(result, s:sub(pos))
            break
        end
    end

    return result
end

-- Join array elements with separator
-- @param array: array of values to join
-- @param sep: separator string (default: empty string)
-- @return: joined string
function stringx.join(array, sep)
    if array == nil then return "" end
    sep = sep or ""
    local parts = {}
    for _, v in ipairs(array) do
        table.insert(parts, tostring(v))
    end
    return table.concat(parts, sep)
end

--------------------------------------------------------------------------------
-- Searching Functions
--------------------------------------------------------------------------------

-- Check if string starts with prefix
-- @param s: input string
-- @param prefix: prefix to check
-- @return: boolean
function stringx.startswith(s, prefix)
    if s == nil or prefix == nil then return false end
    s = tostring(s)
    prefix = tostring(prefix)
    return s:sub(1, #prefix) == prefix
end

-- Check if string ends with suffix
-- @param s: input string
-- @param suffix: suffix to check
-- @return: boolean
function stringx.endswith(s, suffix)
    if s == nil or suffix == nil then return false end
    s = tostring(s)
    suffix = tostring(suffix)
    if #suffix == 0 then return true end
    return s:sub(-#suffix) == suffix
end

-- Check if string contains substring
-- @param s: input string
-- @param substr: substring to find
-- @return: boolean
function stringx.contains(s, substr)
    if s == nil or substr == nil then return false end
    s = tostring(s)
    substr = tostring(substr)
    return s:find(substr, 1, true) ~= nil
end

-- Count occurrences of substring
-- @param s: input string
-- @param substr: substring to count
-- @return: count of occurrences
function stringx.count(s, substr)
    if s == nil or substr == nil or substr == "" then return 0 end
    s = tostring(s)
    substr = tostring(substr)
    local count = 0
    local pos = 1
    while true do
        local found = s:find(substr, pos, true)
        if not found then break end
        count = count + 1
        pos = found + 1
    end
    return count
end

--------------------------------------------------------------------------------
-- Replacing Functions
--------------------------------------------------------------------------------

-- Replace occurrences of old with new
-- @param s: input string
-- @param old: substring to replace
-- @param new: replacement string
-- @param count: maximum replacements (nil = all)
-- @return: result string
function stringx.replace(s, old, new, count)
    if s == nil then return nil end
    s = tostring(s)
    old = tostring(old or "")
    new = tostring(new or "")

    if old == "" then return s end

    local result = {}
    local pos = 1
    local replacements = 0

    while pos <= #s do
        local found = s:find(old, pos, true)
        if not found or (count and replacements >= count) then
            table.insert(result, s:sub(pos))
            break
        end
        table.insert(result, s:sub(pos, found - 1))
        table.insert(result, new)
        pos = found + #old
        replacements = replacements + 1
    end

    return table.concat(result)
end

--------------------------------------------------------------------------------
-- Padding Functions
--------------------------------------------------------------------------------

-- Left pad string to specified width
-- @param s: input string
-- @param width: target width
-- @param char: padding character (default: space)
-- @return: padded string
function stringx.lpad(s, width, char)
    if s == nil then return nil end
    s = tostring(s)
    width = width or 0
    char = char or " "
    if #char == 0 then char = " " end
    char = char:sub(1, 1)

    local padding = width - #s
    if padding <= 0 then return s end
    return string.rep(char, padding) .. s
end

-- Right pad string to specified width
-- @param s: input string
-- @param width: target width
-- @param char: padding character (default: space)
-- @return: padded string
function stringx.rpad(s, width, char)
    if s == nil then return nil end
    s = tostring(s)
    width = width or 0
    char = char or " "
    if #char == 0 then char = " " end
    char = char:sub(1, 1)

    local padding = width - #s
    if padding <= 0 then return s end
    return s .. string.rep(char, padding)
end

-- Center string within specified width
-- @param s: input string
-- @param width: target width
-- @param char: padding character (default: space)
-- @return: centered string
function stringx.center(s, width, char)
    if s == nil then return nil end
    s = tostring(s)
    width = width or 0
    char = char or " "
    if #char == 0 then char = " " end
    char = char:sub(1, 1)

    local padding = width - #s
    if padding <= 0 then return s end
    local left = math.floor(padding / 2)
    local right = padding - left
    return string.rep(char, left) .. s .. string.rep(char, right)
end

--------------------------------------------------------------------------------
-- Testing Functions
--------------------------------------------------------------------------------

-- Check if string contains only alphabetic characters
-- @param s: input string
-- @return: boolean
function stringx.isalpha(s)
    if s == nil or s == "" then return false end
    return tostring(s):match("^%a+$") ~= nil
end

-- Check if string contains only digits
-- @param s: input string
-- @return: boolean
function stringx.isdigit(s)
    if s == nil or s == "" then return false end
    return tostring(s):match("^%d+$") ~= nil
end

-- Check if string contains only alphanumeric characters
-- @param s: input string
-- @return: boolean
function stringx.isalnum(s)
    if s == nil or s == "" then return false end
    return tostring(s):match("^%w+$") ~= nil
end

-- Check if string contains only whitespace
-- @param s: input string
-- @return: boolean
function stringx.isspace(s)
    if s == nil or s == "" then return false end
    return tostring(s):match("^%s+$") ~= nil
end

-- Check if string is empty
-- @param s: input string
-- @return: boolean
function stringx.isempty(s)
    return s == nil or tostring(s) == ""
end

-- Check if string is empty or contains only whitespace
-- @param s: input string
-- @return: boolean
function stringx.isblank(s)
    if s == nil then return true end
    return tostring(s):match("^%s*$") ~= nil
end

--------------------------------------------------------------------------------
-- Transformation Functions
--------------------------------------------------------------------------------

-- Reverse a string
-- @param s: input string
-- @return: reversed string
function stringx.reverse(s)
    if s == nil then return nil end
    return tostring(s):reverse()
end

-- Word wrap text to specified width
-- @param s: input string
-- @param width: maximum line width (default: 80)
-- @return: wrapped string with newlines
function stringx.wrap(s, width)
    if s == nil then return nil end
    s = tostring(s)
    width = width or 80
    if width <= 0 then return s end

    local result = {}
    local line = ""

    for word in s:gmatch("%S+") do
        if #line == 0 then
            line = word
        elseif #line + 1 + #word <= width then
            line = line .. " " .. word
        else
            table.insert(result, line)
            line = word
        end
    end

    if #line > 0 then
        table.insert(result, line)
    end

    return table.concat(result, "\n")
end

-- Truncate string to specified length with suffix
-- @param s: input string
-- @param len: maximum length
-- @param suffix: suffix to append when truncated (default: "...")
-- @return: truncated string
function stringx.truncate(s, len, suffix)
    if s == nil then return nil end
    s = tostring(s)
    len = len or 80
    suffix = suffix or "..."

    if #s <= len then return s end

    local cutoff = len - #suffix
    if cutoff <= 0 then
        return suffix:sub(1, len)
    end

    return s:sub(1, cutoff) .. suffix
end

-- Convert string to URL-friendly slug
-- @param s: input string
-- @return: slug string (lowercase, hyphens for spaces, alphanumeric only)
function stringx.slug(s)
    if s == nil then return nil end
    s = tostring(s)

    -- Convert to lowercase
    s = s:lower()

    -- Replace whitespace and underscores with hyphens
    s = s:gsub("[%s_]+", "-")

    -- Remove non-alphanumeric characters except hyphens
    s = s:gsub("[^%w%-]", "")

    -- Collapse multiple hyphens
    s = s:gsub("%-+", "-")

    -- Trim hyphens from ends
    s = s:gsub("^%-+", ""):gsub("%-+$", "")

    return s
end

return stringx
