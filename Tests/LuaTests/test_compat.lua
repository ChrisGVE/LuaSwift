-- Tests for compat.lua module
-- These tests validate the Lua version compatibility layer

local T = require("run_tests")
local compat = require("compat")

T.suite("compat.version")

T.test("version string exists", function()
    T.assert_not_nil(compat.version)
    T.assert_type(compat.version, "string")
end)

T.test("version matches _VERSION format", function()
    -- Should be like "5.4" or "5.4.7"
    T.assert_true(compat.version:match("^%d+%.%d+"))
end)

T.test("exactly one version flag is true", function()
    local count = 0
    if compat.lua51 then count = count + 1 end
    if compat.lua52 then count = count + 1 end
    if compat.lua53 then count = count + 1 end
    if compat.lua54 then count = count + 1 end
    if compat.lua55 then count = count + 1 end
    T.assert_equal(count, 1, "Exactly one version flag should be true")
end)

T.suite("compat.bit32")

T.test("band basic", function()
    T.assert_equal(compat.bit32.band(0xFF, 0x0F), 0x0F)
    T.assert_equal(compat.bit32.band(0xF0, 0x0F), 0x00)
end)

T.test("band with multiple arguments", function()
    T.assert_equal(compat.bit32.band(0xFF, 0x0F, 0x03), 0x03)
    T.assert_equal(compat.bit32.band(0xFF, 0x7F, 0x3F, 0x1F), 0x1F)
end)

T.test("band edge cases", function()
    T.assert_equal(compat.bit32.band(0, 0xFFFFFFFF), 0)
    T.assert_equal(compat.bit32.band(0xFFFFFFFF, 0xFFFFFFFF), 0xFFFFFFFF)
    T.assert_equal(compat.bit32.band(), 0xFFFFFFFF) -- no args = all 1s
end)

T.test("bor basic", function()
    T.assert_equal(compat.bit32.bor(0xF0, 0x0F), 0xFF)
    T.assert_equal(compat.bit32.bor(0x00, 0x00), 0x00)
end)

T.test("bor with multiple arguments", function()
    T.assert_equal(compat.bit32.bor(0x01, 0x02, 0x04, 0x08), 0x0F)
end)

T.test("bor edge cases", function()
    T.assert_equal(compat.bit32.bor(), 0) -- no args = 0
    T.assert_equal(compat.bit32.bor(0, 0xABCD), 0xABCD)
end)

T.test("bxor basic", function()
    T.assert_equal(compat.bit32.bxor(0xFF, 0x0F), 0xF0)
    T.assert_equal(compat.bit32.bxor(0xAA, 0x55), 0xFF)
end)

T.test("bxor self is zero", function()
    T.assert_equal(compat.bit32.bxor(0xABCDEF12, 0xABCDEF12), 0)
end)

T.test("bnot basic", function()
    T.assert_equal(compat.bit32.bnot(0), 0xFFFFFFFF)
    T.assert_equal(compat.bit32.bnot(0xFFFFFFFF), 0)
end)

T.test("lshift basic", function()
    T.assert_equal(compat.bit32.lshift(1, 0), 1)
    T.assert_equal(compat.bit32.lshift(1, 4), 16)
    T.assert_equal(compat.bit32.lshift(1, 31), 0x80000000)
end)

T.test("lshift by 32 or more is zero", function()
    T.assert_equal(compat.bit32.lshift(0xFFFFFFFF, 32), 0)
    T.assert_equal(compat.bit32.lshift(1, 33), 0)
    T.assert_equal(compat.bit32.lshift(1, 100), 0)
end)

T.test("rshift basic", function()
    T.assert_equal(compat.bit32.rshift(16, 4), 1)
    T.assert_equal(compat.bit32.rshift(0x80000000, 31), 1)
end)

T.test("rshift by 32 or more is zero", function()
    T.assert_equal(compat.bit32.rshift(0xFFFFFFFF, 32), 0)
    T.assert_equal(compat.bit32.rshift(0x80000000, 33), 0)
end)

T.test("lrotate basic", function()
    T.assert_equal(compat.bit32.lrotate(0x80000000, 1), 1)
    T.assert_equal(compat.bit32.lrotate(1, 1), 2)
end)

T.test("lrotate by 32 is identity", function()
    T.assert_equal(compat.bit32.lrotate(0xABCD, 32), 0xABCD)
end)

T.test("rrotate basic", function()
    T.assert_equal(compat.bit32.rrotate(1, 1), 0x80000000)
    T.assert_equal(compat.bit32.rrotate(2, 1), 1)
end)

T.test("rrotate by 32 is identity", function()
    T.assert_equal(compat.bit32.rrotate(0xABCD, 32), 0xABCD)
end)

T.test("btest basic", function()
    T.assert_true(compat.bit32.btest(0xFF, 0x01))
    T.assert_false(compat.bit32.btest(0xF0, 0x01))
end)

T.test("btest with zero is always false", function()
    T.assert_false(compat.bit32.btest(0, 0))
    T.assert_false(compat.bit32.btest(0xFFFFFFFF, 0))
end)

T.test("extract basic", function()
    T.assert_equal(compat.bit32.extract(0xABCD, 0, 4), 0xD)
    T.assert_equal(compat.bit32.extract(0xABCD, 4, 4), 0xC)
    T.assert_equal(compat.bit32.extract(0xABCD, 8, 4), 0xB)
    T.assert_equal(compat.bit32.extract(0xABCD, 12, 4), 0xA)
end)

T.test("extract full word", function()
    T.assert_equal(compat.bit32.extract(0xABCDEF12, 0, 32), 0xABCDEF12)
end)

T.test("replace basic", function()
    T.assert_equal(compat.bit32.replace(0x0000, 0xA, 12, 4), 0xA000)
    T.assert_equal(compat.bit32.replace(0xFFFF, 0x0, 0, 4), 0xFFF0)
end)

T.test("arshift with positive high bit", function()
    T.assert_equal(compat.bit32.arshift(0x7FFFFFFF, 4), 0x07FFFFFF)
end)

T.test("arshift with negative high bit", function()
    T.assert_equal(compat.bit32.arshift(0x80000000, 4), 0xF8000000)
end)

T.suite("compat.version_compare")

T.test("less than", function()
    T.assert_true(compat.version_compare("5.3", "5.4") < 0)
    T.assert_true(compat.version_compare("4.0", "5.0") < 0)
end)

T.test("equal", function()
    T.assert_equal(compat.version_compare("5.4", "5.4"), 0)
end)

T.test("greater than", function()
    T.assert_true(compat.version_compare("5.4", "5.3") > 0)
    T.assert_true(compat.version_compare("5.0", "4.0") > 0)
end)

T.suite("compat.version_at_least")

T.test("current version", function()
    T.assert_true(compat.version_at_least(compat.version))
end)

T.test("always at least 5.1", function()
    T.assert_true(compat.version_at_least("5.1"))
end)

T.test("never at least 9.9", function()
    T.assert_false(compat.version_at_least("9.9"))
end)

T.suite("compat.install")

T.test("install makes bit32 global", function()
    compat.install()
    T.assert_not_nil(bit32)
    T.assert_equal(bit32.band(0xFF, 0x0F), 0x0F)
end)

T.test("install is idempotent", function()
    local before = bit32
    compat.install()
    compat.install()
    compat.install()
    T.assert_equal(bit32, before)
    T.assert_equal(bit32.band(0xFF, 0x0F), 0x0F)
end)

T.test("unpack is available after install", function()
    compat.install()
    T.assert_not_nil(unpack)
    local a, b, c = unpack({10, 20, 30})
    T.assert_equal(a, 10)
    T.assert_equal(b, 20)
    T.assert_equal(c, 30)
end)

T.suite("compat.features")

T.test("feature flags are booleans", function()
    T.assert_type(compat.features.table_unpack, "boolean")
    T.assert_type(compat.features.bitwise_ops, "boolean")
end)

T.test("feature flags consistent with version", function()
    -- In 5.2+, table.unpack exists
    if compat.lua52 or compat.lua53 or compat.lua54 or compat.lua55 then
        T.assert_true(compat.features.table_unpack)
    end

    -- In 5.3+, bitwise operators exist
    if compat.lua53 or compat.lua54 or compat.lua55 then
        T.assert_true(compat.features.bitwise_ops)
        T.assert_true(compat.features.utf8_library)
    end
end)
