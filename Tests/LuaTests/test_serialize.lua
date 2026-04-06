-- Tests for serialize.lua module
-- These tests validate the table serialization functionality

local T = require("run_tests")
local serialize = require("serialize")

T.suite("serialize.encode primitives")

T.test("encode nil", function()
    T.assert_equal(serialize.encode(nil), "nil")
end)

T.test("encode boolean true", function()
    T.assert_equal(serialize.encode(true), "true")
end)

T.test("encode boolean false", function()
    T.assert_equal(serialize.encode(false), "false")
end)

T.test("encode integer", function()
    T.assert_equal(serialize.encode(42), "42")
end)

T.test("encode negative integer", function()
    T.assert_equal(serialize.encode(-123), "-123")
end)

T.test("encode float", function()
    local result = serialize.encode(3.14)
    T.assert_true(result:match("^3%.14"))
end)

T.test("encode string", function()
    T.assert_equal(serialize.encode("hello"), '"hello"')
end)

T.test("encode string with quotes", function()
    local result = serialize.encode('say "hi"')
    -- Should escape the inner quotes
    T.assert_true(result:match('say'))
    T.assert_true(result:match('hi'))
end)

T.test("encode string with newline", function()
    local result = serialize.encode("line1\nline2")
    -- Should handle newline somehow (escape or long string)
    T.assert_not_nil(result)
end)

T.suite("serialize.encode tables")

T.test("encode empty table", function()
    T.assert_equal(serialize.encode({}), "{}")
end)

T.test("encode array", function()
    local result = serialize.encode({1, 2, 3})
    -- Should produce array-like output
    T.assert_true(result:match("1"))
    T.assert_true(result:match("2"))
    T.assert_true(result:match("3"))
end)

T.test("encode dictionary", function()
    local result = serialize.encode({a = 1, b = 2})
    T.assert_true(result:match("a"))
    T.assert_true(result:match("1"))
    T.assert_true(result:match("b"))
    T.assert_true(result:match("2"))
end)

T.test("encode nested table", function()
    local result = serialize.encode({
        outer = {
            inner = 42
        }
    })
    T.assert_true(result:match("outer"))
    T.assert_true(result:match("inner"))
    T.assert_true(result:match("42"))
end)

T.suite("serialize.decode")

T.test("decode nil", function()
    T.assert_nil(serialize.decode("nil"))
end)

T.test("decode boolean", function()
    T.assert_true(serialize.decode("true"))
    T.assert_false(serialize.decode("false"))
end)

T.test("decode number", function()
    T.assert_equal(serialize.decode("42"), 42)
    T.assert_equal(serialize.decode("-123"), -123)
    T.assert_approx(serialize.decode("3.14"), 3.14, 0.001)
end)

T.test("decode string", function()
    T.assert_equal(serialize.decode('"hello"'), "hello")
end)

T.test("decode empty table", function()
    local result = serialize.decode("{}")
    T.assert_type(result, "table")
end)

T.test("decode array", function()
    local result = serialize.decode("{1, 2, 3}")
    T.assert_type(result, "table")
    T.assert_equal(result[1], 1)
    T.assert_equal(result[2], 2)
    T.assert_equal(result[3], 3)
end)

T.test("decode dictionary", function()
    local result = serialize.decode("{a = 1, b = 2}")
    T.assert_type(result, "table")
    T.assert_equal(result.a, 1)
    T.assert_equal(result.b, 2)
end)

T.suite("serialize round-trip")

T.test("round-trip nil", function()
    T.assert_nil(serialize.decode(serialize.encode(nil)))
end)

T.test("round-trip boolean", function()
    T.assert_true(serialize.decode(serialize.encode(true)))
    T.assert_false(serialize.decode(serialize.encode(false)))
end)

T.test("round-trip number", function()
    T.assert_equal(serialize.decode(serialize.encode(42)), 42)
    T.assert_equal(serialize.decode(serialize.encode(-999)), -999)
end)

T.test("round-trip string", function()
    T.assert_equal(serialize.decode(serialize.encode("hello world")), "hello world")
end)

T.test("round-trip simple table", function()
    local original = {a = 1, b = "two", c = true}
    local decoded = serialize.decode(serialize.encode(original))
    T.assert_equal(decoded.a, original.a)
    T.assert_equal(decoded.b, original.b)
    T.assert_equal(decoded.c, original.c)
end)

T.test("round-trip array", function()
    local original = {10, 20, 30, 40, 50}
    local decoded = serialize.decode(serialize.encode(original))
    for i = 1, 5 do
        T.assert_equal(decoded[i], original[i])
    end
end)

T.test("round-trip nested table", function()
    local original = {
        name = "test",
        data = {
            values = {1, 2, 3},
            flag = true
        }
    }
    local decoded = serialize.decode(serialize.encode(original))
    T.assert_equal(decoded.name, original.name)
    T.assert_equal(decoded.data.flag, original.data.flag)
    T.assert_equal(decoded.data.values[1], original.data.values[1])
    T.assert_equal(decoded.data.values[2], original.data.values[2])
    T.assert_equal(decoded.data.values[3], original.data.values[3])
end)

T.suite("serialize.pretty")

T.test("pretty output has newlines", function()
    local result = serialize.pretty({a = 1, b = 2})
    T.assert_true(result:match("\n"))
end)

T.test("pretty output has indentation", function()
    local result = serialize.pretty({nested = {value = 1}})
    -- Should have some indentation
    T.assert_true(result:match("  ") or result:match("\t"))
end)

T.suite("serialize.compact")

T.test("compact has no extra whitespace", function()
    local result = serialize.compact({a = 1, b = 2})
    -- Should not have newlines
    T.assert_false(result:match("\n"))
end)

T.suite("serialize.safe_decode")

T.test("safe_decode returns value on success", function()
    local val, err = serialize.safe_decode("{a = 1}")
    T.assert_nil(err)
    T.assert_equal(val.a, 1)
end)

T.test("safe_decode returns error on invalid input", function()
    local val, err = serialize.safe_decode("this is not valid lua")
    -- Should return nil and an error message
    T.assert_nil(val)
    T.assert_not_nil(err)
end)

T.suite("serialize.is_serializable")

T.test("primitives are serializable", function()
    T.assert_true(serialize.is_serializable(nil))
    T.assert_true(serialize.is_serializable(true))
    T.assert_true(serialize.is_serializable(42))
    T.assert_true(serialize.is_serializable("hello"))
end)

T.test("tables are serializable", function()
    T.assert_true(serialize.is_serializable({}))
    T.assert_true(serialize.is_serializable({1, 2, 3}))
    T.assert_true(serialize.is_serializable({a = 1}))
end)

T.test("functions are not serializable", function()
    T.assert_false(serialize.is_serializable(function() end))
end)

T.test("tables with functions are not serializable", function()
    T.assert_false(serialize.is_serializable({
        value = 1,
        callback = function() end
    }))
end)

T.test("userdata is not serializable", function()
    -- io.stdout is a userdata in standard Lua
    if io and io.stdout then
        T.assert_false(serialize.is_serializable(io.stdout))
    end
end)

T.suite("serialize edge cases")

T.test("empty string", function()
    local encoded = serialize.encode("")
    local decoded = serialize.decode(encoded)
    T.assert_equal(decoded, "")
end)

T.test("string with special characters", function()
    local special = "tab\there\nnewline\\backslash"
    local encoded = serialize.encode(special)
    local decoded = serialize.decode(encoded)
    T.assert_equal(decoded, special)
end)

T.test("very large number", function()
    local big = 1e308
    local encoded = serialize.encode(big)
    local decoded = serialize.decode(encoded)
    T.assert_approx(decoded, big, big * 1e-10)
end)

T.test("very small number", function()
    local small = 1e-308
    local encoded = serialize.encode(small)
    local decoded = serialize.decode(encoded)
    T.assert_approx(decoded, small, small * 1e-10)
end)

T.test("mixed array and dictionary keys", function()
    local mixed = {1, 2, 3, name = "test", [10] = "ten"}
    local decoded = serialize.decode(serialize.encode(mixed))
    T.assert_equal(decoded[1], 1)
    T.assert_equal(decoded[2], 2)
    T.assert_equal(decoded[3], 3)
    T.assert_equal(decoded.name, "test")
    T.assert_equal(decoded[10], "ten")
end)

T.test("deeply nested table", function()
    local deep = {a = {b = {c = {d = {e = {f = 42}}}}}}
    local decoded = serialize.decode(serialize.encode(deep))
    T.assert_equal(decoded.a.b.c.d.e.f, 42)
end)
