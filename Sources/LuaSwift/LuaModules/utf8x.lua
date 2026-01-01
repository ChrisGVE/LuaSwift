-- utf8x.lua - UTF-8 Extensions Module for Lua 5.4
-- Copyright (c) 2025 LuaSwift Project
-- Licensed under the MIT License
--
-- A pure Lua module extending the standard utf8 library with:
-- - Character-based string operations (substring, reverse)
-- - Case conversion (ASCII + common Latin-1 accented characters)
-- - Display width calculation (CJK awareness)
-- - Character property functions (isalpha, isupper, etc.)
--
-- Designed for iOS/macOS via LuaSwift wrapper.

local utf8x = {}

-- Re-export standard utf8 library functions for convenience
utf8x.len = utf8.len
utf8x.offset = utf8.offset
utf8x.codepoint = utf8.codepoint
utf8x.char = utf8.char
utf8x.codes = utf8.codes
utf8x.charpattern = utf8.charpattern

--------------------------------------------------------------------------------
-- Case Conversion Tables (ASCII + Latin-1 Supplement + Latin Extended-A)
--------------------------------------------------------------------------------

-- Uppercase to lowercase mapping
local upperToLower = {
    -- ASCII uppercase (A-Z: 65-90 -> a-z: 97-122)
    [0x0041] = 0x0061, [0x0042] = 0x0062, [0x0043] = 0x0063, [0x0044] = 0x0064,
    [0x0045] = 0x0065, [0x0046] = 0x0066, [0x0047] = 0x0067, [0x0048] = 0x0068,
    [0x0049] = 0x0069, [0x004A] = 0x006A, [0x004B] = 0x006B, [0x004C] = 0x006C,
    [0x004D] = 0x006D, [0x004E] = 0x006E, [0x004F] = 0x006F, [0x0050] = 0x0070,
    [0x0051] = 0x0071, [0x0052] = 0x0072, [0x0053] = 0x0073, [0x0054] = 0x0074,
    [0x0055] = 0x0075, [0x0056] = 0x0076, [0x0057] = 0x0077, [0x0058] = 0x0078,
    [0x0059] = 0x0079, [0x005A] = 0x007A,
    -- Latin-1 Supplement accented uppercase
    [0x00C0] = 0x00E0, -- A grave -> a grave
    [0x00C1] = 0x00E1, -- A acute -> a acute
    [0x00C2] = 0x00E2, -- A circumflex -> a circumflex
    [0x00C3] = 0x00E3, -- A tilde -> a tilde
    [0x00C4] = 0x00E4, -- A diaeresis -> a diaeresis
    [0x00C5] = 0x00E5, -- A ring -> a ring
    [0x00C6] = 0x00E6, -- AE -> ae
    [0x00C7] = 0x00E7, -- C cedilla -> c cedilla
    [0x00C8] = 0x00E8, -- E grave -> e grave
    [0x00C9] = 0x00E9, -- E acute -> e acute
    [0x00CA] = 0x00EA, -- E circumflex -> e circumflex
    [0x00CB] = 0x00EB, -- E diaeresis -> e diaeresis
    [0x00CC] = 0x00EC, -- I grave -> i grave
    [0x00CD] = 0x00ED, -- I acute -> i acute
    [0x00CE] = 0x00EE, -- I circumflex -> i circumflex
    [0x00CF] = 0x00EF, -- I diaeresis -> i diaeresis
    [0x00D0] = 0x00F0, -- Eth -> eth
    [0x00D1] = 0x00F1, -- N tilde -> n tilde
    [0x00D2] = 0x00F2, -- O grave -> o grave
    [0x00D3] = 0x00F3, -- O acute -> o acute
    [0x00D4] = 0x00F4, -- O circumflex -> o circumflex
    [0x00D5] = 0x00F5, -- O tilde -> o tilde
    [0x00D6] = 0x00F6, -- O diaeresis -> o diaeresis
    [0x00D8] = 0x00F8, -- O stroke -> o stroke
    [0x00D9] = 0x00F9, -- U grave -> u grave
    [0x00DA] = 0x00FA, -- U acute -> u acute
    [0x00DB] = 0x00FB, -- U circumflex -> u circumflex
    [0x00DC] = 0x00FC, -- U diaeresis -> u diaeresis
    [0x00DD] = 0x00FD, -- Y acute -> y acute
    [0x00DE] = 0x00FE, -- Thorn -> thorn
    -- Latin Extended-A (selected common characters)
    [0x0100] = 0x0101, -- A macron
    [0x0102] = 0x0103, -- A breve
    [0x0104] = 0x0105, -- A ogonek
    [0x0106] = 0x0107, -- C acute
    [0x0108] = 0x0109, -- C circumflex
    [0x010A] = 0x010B, -- C dot above
    [0x010C] = 0x010D, -- C caron
    [0x010E] = 0x010F, -- D caron
    [0x0110] = 0x0111, -- D stroke
    [0x0112] = 0x0113, -- E macron
    [0x0114] = 0x0115, -- E breve
    [0x0116] = 0x0117, -- E dot above
    [0x0118] = 0x0119, -- E ogonek
    [0x011A] = 0x011B, -- E caron
    [0x011C] = 0x011D, -- G circumflex
    [0x011E] = 0x011F, -- G breve
    [0x0120] = 0x0121, -- G dot above
    [0x0122] = 0x0123, -- G cedilla
    [0x0124] = 0x0125, -- H circumflex
    [0x0126] = 0x0127, -- H stroke
    [0x0128] = 0x0129, -- I tilde
    [0x012A] = 0x012B, -- I macron
    [0x012C] = 0x012D, -- I breve
    [0x012E] = 0x012F, -- I ogonek
    [0x0130] = 0x0069, -- I dot above -> i (Turkish)
    [0x0132] = 0x0133, -- IJ -> ij
    [0x0134] = 0x0135, -- J circumflex
    [0x0136] = 0x0137, -- K cedilla
    [0x0139] = 0x013A, -- L acute
    [0x013B] = 0x013C, -- L cedilla
    [0x013D] = 0x013E, -- L caron
    [0x013F] = 0x0140, -- L middle dot
    [0x0141] = 0x0142, -- L stroke
    [0x0143] = 0x0144, -- N acute
    [0x0145] = 0x0146, -- N cedilla
    [0x0147] = 0x0148, -- N caron
    [0x014A] = 0x014B, -- Eng
    [0x014C] = 0x014D, -- O macron
    [0x014E] = 0x014F, -- O breve
    [0x0150] = 0x0151, -- O double acute
    [0x0152] = 0x0153, -- OE -> oe
    [0x0154] = 0x0155, -- R acute
    [0x0156] = 0x0157, -- R cedilla
    [0x0158] = 0x0159, -- R caron
    [0x015A] = 0x015B, -- S acute
    [0x015C] = 0x015D, -- S circumflex
    [0x015E] = 0x015F, -- S cedilla
    [0x0160] = 0x0161, -- S caron
    [0x0162] = 0x0163, -- T cedilla
    [0x0164] = 0x0165, -- T caron
    [0x0166] = 0x0167, -- T stroke
    [0x0168] = 0x0169, -- U tilde
    [0x016A] = 0x016B, -- U macron
    [0x016C] = 0x016D, -- U breve
    [0x016E] = 0x016F, -- U ring
    [0x0170] = 0x0171, -- U double acute
    [0x0172] = 0x0173, -- U ogonek
    [0x0174] = 0x0175, -- W circumflex
    [0x0176] = 0x0177, -- Y circumflex
    [0x0178] = 0x00FF, -- Y diaeresis
    [0x0179] = 0x017A, -- Z acute
    [0x017B] = 0x017C, -- Z dot above
    [0x017D] = 0x017E, -- Z caron
}

-- Lowercase to uppercase mapping (reverse of above)
local lowerToUpper = {}
for upper, lower in pairs(upperToLower) do
    lowerToUpper[lower] = upper
end
-- Special case: German sharp s (eszett) has no single uppercase equivalent
-- Special case: Turkish dotless i
lowerToUpper[0x0131] = 0x0049 -- dotless i -> I (Turkish)

--------------------------------------------------------------------------------
-- Character Property Sets
--------------------------------------------------------------------------------

-- Check if codepoint is in ASCII uppercase range
local function isAsciiUpper(cp)
    return cp >= 0x0041 and cp <= 0x005A
end

-- Check if codepoint is in ASCII lowercase range
local function isAsciiLower(cp)
    return cp >= 0x0061 and cp <= 0x007A
end

-- Check if codepoint is ASCII digit
local function isAsciiDigit(cp)
    return cp >= 0x0030 and cp <= 0x0039
end

-- Check if codepoint is ASCII whitespace
local function isAsciiWhitespace(cp)
    return cp == 0x0020 or  -- space
           cp == 0x0009 or  -- tab
           cp == 0x000A or  -- newline
           cp == 0x000D or  -- carriage return
           cp == 0x000C or  -- form feed
           cp == 0x000B     -- vertical tab
end

-- Check if codepoint is Unicode whitespace (common characters)
local function isUnicodeWhitespace(cp)
    return isAsciiWhitespace(cp) or
           cp == 0x00A0 or  -- no-break space
           cp == 0x1680 or  -- ogham space mark
           cp == 0x2000 or  -- en quad
           cp == 0x2001 or  -- em quad
           cp == 0x2002 or  -- en space
           cp == 0x2003 or  -- em space
           cp == 0x2004 or  -- three-per-em space
           cp == 0x2005 or  -- four-per-em space
           cp == 0x2006 or  -- six-per-em space
           cp == 0x2007 or  -- figure space
           cp == 0x2008 or  -- punctuation space
           cp == 0x2009 or  -- thin space
           cp == 0x200A or  -- hair space
           cp == 0x2028 or  -- line separator
           cp == 0x2029 or  -- paragraph separator
           cp == 0x202F or  -- narrow no-break space
           cp == 0x205F or  -- medium mathematical space
           cp == 0x3000     -- ideographic space
end

--------------------------------------------------------------------------------
-- CJK and Wide Character Ranges
--------------------------------------------------------------------------------

-- Check if a codepoint is a wide character (CJK, fullwidth, etc.)
-- Returns true for characters that typically display as double-width
local function isWideChar(cp)
    -- CJK Unified Ideographs and extensions
    if cp >= 0x4E00 and cp <= 0x9FFF then return true end   -- CJK Unified Ideographs
    if cp >= 0x3400 and cp <= 0x4DBF then return true end   -- CJK Extension A
    if cp >= 0x20000 and cp <= 0x2A6DF then return true end -- CJK Extension B
    if cp >= 0x2A700 and cp <= 0x2B73F then return true end -- CJK Extension C
    if cp >= 0x2B740 and cp <= 0x2B81F then return true end -- CJK Extension D
    if cp >= 0x2B820 and cp <= 0x2CEAF then return true end -- CJK Extension E
    if cp >= 0x2CEB0 and cp <= 0x2EBEF then return true end -- CJK Extension F
    if cp >= 0x30000 and cp <= 0x3134F then return true end -- CJK Extension G

    -- CJK Compatibility Ideographs
    if cp >= 0xF900 and cp <= 0xFAFF then return true end
    if cp >= 0x2F800 and cp <= 0x2FA1F then return true end

    -- Hiragana and Katakana
    if cp >= 0x3040 and cp <= 0x309F then return true end   -- Hiragana
    if cp >= 0x30A0 and cp <= 0x30FF then return true end   -- Katakana
    if cp >= 0x31F0 and cp <= 0x31FF then return true end   -- Katakana Extensions

    -- Hangul (Korean)
    if cp >= 0xAC00 and cp <= 0xD7AF then return true end   -- Hangul Syllables
    if cp >= 0x1100 and cp <= 0x11FF then return true end   -- Hangul Jamo
    if cp >= 0x3130 and cp <= 0x318F then return true end   -- Hangul Compatibility Jamo

    -- Fullwidth forms
    if cp >= 0xFF00 and cp <= 0xFF60 then return true end   -- Fullwidth ASCII
    if cp >= 0xFFE0 and cp <= 0xFFE6 then return true end   -- Fullwidth symbols

    -- CJK Symbols and Punctuation
    if cp >= 0x3000 and cp <= 0x303F then return true end

    -- Bopomofo
    if cp >= 0x3100 and cp <= 0x312F then return true end

    -- Yi
    if cp >= 0xA000 and cp <= 0xA48F then return true end

    return false
end

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

-- Collect all codepoints from a string into a table
local function collectCodepoints(s)
    local codepoints = {}
    for _, cp in utf8.codes(s) do
        table.insert(codepoints, cp)
    end
    return codepoints
end

-- Normalize index (handle negative indices like Lua strings)
-- @param i: index (1-based, negative for from end)
-- @param len: total length
-- @return: normalized 1-based index
local function normalizeIndex(i, len)
    if i < 0 then
        i = len + i + 1
    end
    if i < 1 then i = 1 end
    if i > len then i = len + 1 end
    return i
end

--------------------------------------------------------------------------------
-- Extended Functions
--------------------------------------------------------------------------------

--- Get a substring by character indices (not byte indices)
-- @param s: input string
-- @param i: start index (1-based, inclusive, negative for from end)
-- @param j: end index (1-based, inclusive, default: -1 for end of string)
-- @return: substring
function utf8x.sub(s, i, j)
    if not s or s == "" then return "" end

    local codepoints = collectCodepoints(s)
    local len = #codepoints

    i = normalizeIndex(i or 1, len)
    j = normalizeIndex(j or -1, len)

    if i > len or i > j then return "" end

    -- Extract the codepoints in range
    local result = {}
    for idx = i, j do
        if idx <= len then
            table.insert(result, codepoints[idx])
        end
    end

    return utf8.char(table.unpack(result))
end

--- Reverse a UTF-8 string
-- @param s: input string
-- @return: reversed string
function utf8x.reverse(s)
    if not s or s == "" then return "" end

    local codepoints = collectCodepoints(s)

    -- Reverse the codepoints array
    local reversed = {}
    for i = #codepoints, 1, -1 do
        table.insert(reversed, codepoints[i])
    end

    return utf8.char(table.unpack(reversed))
end

--- Convert string to uppercase (ASCII + common accented characters)
-- @param s: input string
-- @return: uppercase string
function utf8x.upper(s)
    if not s or s == "" then return "" end

    local result = {}
    for _, cp in utf8.codes(s) do
        local upper = lowerToUpper[cp]
        if upper then
            table.insert(result, upper)
        else
            table.insert(result, cp)
        end
    end

    return utf8.char(table.unpack(result))
end

--- Convert string to lowercase (ASCII + common accented characters)
-- @param s: input string
-- @return: lowercase string
function utf8x.lower(s)
    if not s or s == "" then return "" end

    local result = {}
    for _, cp in utf8.codes(s) do
        local lower = upperToLower[cp]
        if lower then
            table.insert(result, lower)
        else
            table.insert(result, cp)
        end
    end

    return utf8.char(table.unpack(result))
end

--- Calculate display width of a string
-- CJK characters count as 2, most others as 1
-- @param s: input string
-- @return: display width in terminal columns
function utf8x.width(s)
    if not s or s == "" then return 0 end

    local width = 0
    for _, cp in utf8.codes(s) do
        if isWideChar(cp) then
            width = width + 2
        else
            width = width + 1
        end
    end

    return width
end

--------------------------------------------------------------------------------
-- Character Property Functions
--------------------------------------------------------------------------------

--- Check if a codepoint is alphabetic
-- @param codepoint: Unicode codepoint (integer)
-- @return: true if alphabetic
function utf8x.isalpha(codepoint)
    if type(codepoint) ~= "number" then return false end

    -- ASCII letters
    if isAsciiUpper(codepoint) or isAsciiLower(codepoint) then
        return true
    end

    -- Latin-1 Supplement letters (excluding non-letter symbols)
    if codepoint >= 0x00C0 and codepoint <= 0x00D6 then return true end
    if codepoint >= 0x00D8 and codepoint <= 0x00F6 then return true end
    if codepoint >= 0x00F8 and codepoint <= 0x00FF then return true end

    -- Latin Extended-A
    if codepoint >= 0x0100 and codepoint <= 0x017F then return true end

    -- Latin Extended-B (selected)
    if codepoint >= 0x0180 and codepoint <= 0x024F then return true end

    -- Greek (basic)
    if codepoint >= 0x0391 and codepoint <= 0x03A9 then return true end  -- uppercase
    if codepoint >= 0x03B1 and codepoint <= 0x03C9 then return true end  -- lowercase

    -- Cyrillic (basic)
    if codepoint >= 0x0410 and codepoint <= 0x044F then return true end

    return false
end

--- Check if a codepoint is uppercase
-- @param codepoint: Unicode codepoint (integer)
-- @return: true if uppercase letter
function utf8x.isupper(codepoint)
    if type(codepoint) ~= "number" then return false end

    -- Check if in uppercase->lowercase mapping (means it's uppercase)
    if upperToLower[codepoint] then return true end

    -- ASCII uppercase (redundant but explicit)
    if isAsciiUpper(codepoint) then return true end

    return false
end

--- Check if a codepoint is lowercase
-- @param codepoint: Unicode codepoint (integer)
-- @return: true if lowercase letter
function utf8x.islower(codepoint)
    if type(codepoint) ~= "number" then return false end

    -- Check if in lowercase->uppercase mapping (means it's lowercase)
    if lowerToUpper[codepoint] then return true end

    -- ASCII lowercase (redundant but explicit)
    if isAsciiLower(codepoint) then return true end

    -- Special cases not in conversion tables
    if codepoint == 0x00DF then return true end  -- German sharp s (eszett)

    return false
end

--- Check if a codepoint is a digit
-- @param codepoint: Unicode codepoint (integer)
-- @return: true if digit (0-9)
function utf8x.isdigit(codepoint)
    if type(codepoint) ~= "number" then return false end
    return isAsciiDigit(codepoint)
end

--- Check if a codepoint is whitespace
-- @param codepoint: Unicode codepoint (integer)
-- @return: true if whitespace
function utf8x.isspace(codepoint)
    if type(codepoint) ~= "number" then return false end
    return isUnicodeWhitespace(codepoint)
end

return utf8x
