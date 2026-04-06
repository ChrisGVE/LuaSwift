-- LuaSwift Pure Lua Test Runner
-- This module provides a simple test framework for testing Lua modules
-- It can be run standalone or integrated with Swift tests

local M = {}

-- Test statistics
M.stats = {
    passed = 0,
    failed = 0,
    errors = {},
    current_suite = nil
}

-- Reset statistics
function M.reset()
    M.stats.passed = 0
    M.stats.failed = 0
    M.stats.errors = {}
    M.stats.current_suite = nil
end

-- Start a test suite
function M.suite(name)
    M.stats.current_suite = name
    if M.verbose then
        print(string.format("\n=== %s ===", name))
    end
end

-- Run a single test
function M.test(name, fn)
    local full_name = M.stats.current_suite
        and (M.stats.current_suite .. "/" .. name)
        or name

    local ok, err = pcall(fn)
    if ok then
        M.stats.passed = M.stats.passed + 1
        if M.verbose then
            print(string.format("[PASS] %s", full_name))
        end
        return true
    else
        M.stats.failed = M.stats.failed + 1
        table.insert(M.stats.errors, {
            name = full_name,
            error = tostring(err)
        })
        if M.verbose then
            print(string.format("[FAIL] %s: %s", full_name, tostring(err)))
        end
        return false
    end
end

-- Assertion helpers

function M.assert_true(value, msg)
    if not value then
        error(msg or "Expected true, got " .. tostring(value), 2)
    end
end

function M.assert_false(value, msg)
    if value then
        error(msg or "Expected false, got " .. tostring(value), 2)
    end
end

function M.assert_equal(actual, expected, msg)
    if actual ~= expected then
        error(msg or string.format("Expected %s, got %s",
            tostring(expected), tostring(actual)), 2)
    end
end

function M.assert_not_equal(actual, expected, msg)
    if actual == expected then
        error(msg or string.format("Expected values to differ, both are %s",
            tostring(actual)), 2)
    end
end

function M.assert_nil(value, msg)
    if value ~= nil then
        error(msg or "Expected nil, got " .. tostring(value), 2)
    end
end

function M.assert_not_nil(value, msg)
    if value == nil then
        error(msg or "Expected non-nil value", 2)
    end
end

function M.assert_type(value, expected_type, msg)
    local actual_type = type(value)
    if actual_type ~= expected_type then
        error(msg or string.format("Expected type %s, got %s",
            expected_type, actual_type), 2)
    end
end

function M.assert_error(fn, msg)
    local ok = pcall(fn)
    if ok then
        error(msg or "Expected function to raise an error", 2)
    end
end

function M.assert_no_error(fn, msg)
    local ok, err = pcall(fn)
    if not ok then
        error(msg or "Unexpected error: " .. tostring(err), 2)
    end
end

-- Approximate equality for floating point
function M.assert_approx(actual, expected, tolerance, msg)
    tolerance = tolerance or 1e-10
    if math.abs(actual - expected) > tolerance then
        error(msg or string.format("Expected %s (tolerance %s), got %s",
            tostring(expected), tostring(tolerance), tostring(actual)), 2)
    end
end

-- Table equality (shallow)
function M.assert_table_equal(actual, expected, msg)
    if type(actual) ~= "table" or type(expected) ~= "table" then
        error(msg or "Both arguments must be tables", 2)
    end

    -- Check all keys in expected are in actual with same values
    for k, v in pairs(expected) do
        if actual[k] ~= v then
            error(msg or string.format("Table mismatch at key %s: expected %s, got %s",
                tostring(k), tostring(v), tostring(actual[k])), 2)
        end
    end

    -- Check no extra keys in actual
    for k, v in pairs(actual) do
        if expected[k] == nil then
            error(msg or string.format("Unexpected key %s in table", tostring(k)), 2)
        end
    end
end

-- Get summary
function M.summary()
    local total = M.stats.passed + M.stats.failed
    return {
        total = total,
        passed = M.stats.passed,
        failed = M.stats.failed,
        errors = M.stats.errors
    }
end

-- Print summary
function M.print_summary()
    local s = M.summary()
    print(string.format("\n=== Test Summary ==="))
    print(string.format("Total:  %d", s.total))
    print(string.format("Passed: %d", s.passed))
    print(string.format("Failed: %d", s.failed))

    if #s.errors > 0 then
        print("\nFailures:")
        for i, e in ipairs(s.errors) do
            print(string.format("  %d. %s: %s", i, e.name, e.error))
        end
    end

    return s.failed == 0
end

-- Run all test files in a directory (standalone mode)
function M.run_all(test_files, modules_path)
    M.reset()
    M.verbose = true

    -- Set up package path to find modules
    if modules_path then
        package.path = modules_path .. "/?.lua;" .. package.path
    end

    -- Run each test file
    for _, file in ipairs(test_files) do
        local ok, err = pcall(dofile, file)
        if not ok then
            print(string.format("[ERROR] Failed to load %s: %s", file, tostring(err)))
            M.stats.failed = M.stats.failed + 1
            table.insert(M.stats.errors, {
                name = file,
                error = "Failed to load: " .. tostring(err)
            })
        end
    end

    return M.print_summary()
end

return M
