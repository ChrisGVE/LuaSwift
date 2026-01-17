# Debug Module

Debugging utilities for Lua scripts.

## Overview

The Debug module provides tools for inspecting Lua execution, including stack traces, value inspection, and performance profiling. Available as `debug` global after installation (replaces sandboxed debug library).

## Installation

```swift
ModuleRegistry.installDebugModule(in: engine)
```

```lua
local dbg = require("luaswift.debug")
```

## Stack Inspection

### dbg.traceback(message?, level?)
Get formatted stack traceback.

```lua
local function deep_function()
    error("Something went wrong")
end

local function middle_function()
    deep_function()
end

local function top_function()
    local success, err = pcall(middle_function)
    if not success then
        print(dbg.traceback(err))
    end
end

top_function()
```

### dbg.getinfo(level)
Get information about a stack frame.

```lua
local function example()
    local info = dbg.getinfo(1)
    print("Function:", info.name)
    print("Line:", info.currentline)
    print("Source:", info.source)
end
```

## Value Inspection

### dbg.inspect(value, depth?)
Pretty-print any Lua value.

```lua
local data = {
    name = "Alice",
    scores = {95, 87, 92},
    metadata = {
        created = "2024-01-01",
        tags = {"student", "active"}
    }
}

print(dbg.inspect(data))
-- Outputs formatted, indented structure
```

### dbg.type(value)
Get detailed type information.

```lua
print(dbg.type(42))         -- "number"
print(dbg.type("hello"))    -- "string"
print(dbg.type({}))         -- "table"
print(dbg.type(function() end))  -- "function"
```

## Performance Profiling

### dbg.profile_start()
Start profiling code execution.

```lua
dbg.profile_start()

-- Code to profile
for i = 1, 1000000 do
    local x = math.sin(i)
end

local stats = dbg.profile_stop()
print("Time:", stats.elapsed, "seconds")
print("Memory used:", stats.memory_delta, "bytes")
```

### dbg.profile_stop()
Stop profiling and get statistics.

```lua
local stats = dbg.profile_stop()
print("Elapsed time:", stats.elapsed)
print("CPU time:", stats.cpu_time)
print("Memory allocated:", stats.memory_allocated)
print("Memory deallocated:", stats.memory_deallocated)
```

## Benchmarking

### dbg.benchmark(func, iterations?)
Benchmark a function.

```lua
local function test_function()
    local sum = 0
    for i = 1, 1000 do
        sum = sum + math.sqrt(i)
    end
    return sum
end

local stats = dbg.benchmark(test_function, 100)
print("Average time:", stats.avg_time, "seconds")
print("Min time:", stats.min_time)
print("Max time:", stats.max_time)
print("Total time:", stats.total_time)
```

## Memory Tracking

### dbg.memory_usage()
Get current memory usage.

```lua
local before = dbg.memory_usage()

-- Allocate some memory
local big_table = {}
for i = 1, 100000 do
    big_table[i] = {value = i}
end

local after = dbg.memory_usage()
print("Memory used:", after - before, "bytes")
```

## Assertions

### dbg.assert(condition, message?)
Enhanced assertion with better error messages.

```lua
local function divide(a, b)
    dbg.assert(b ~= 0, "Division by zero")
    return a / b
end

divide(10, 0)  -- Error with stack trace
```

## Function Timing

```lua
-- Time a specific operation
local function time_operation(name, func)
    local start = os.clock()
    local result = func()
    local elapsed = os.clock() - start
    print(name .. " took " .. elapsed .. " seconds")
    return result
end

local result = time_operation("Matrix multiplication", function()
    local linalg = math.linalg
    local A = linalg.random(100, 100)
    local B = linalg.random(100, 100)
    return linalg.matmul(A, B)
end)
```

## Performance Comparison

```lua
local dbg = require("luaswift.debug")

-- Compare two implementations
local function compare(name1, func1, name2, func2, iterations)
    iterations = iterations or 1000

    local stats1 = dbg.benchmark(func1, iterations)
    local stats2 = dbg.benchmark(func2, iterations)

    print("\nPerformance Comparison:")
    print(name1 .. ": " .. stats1.avg_time .. "s")
    print(name2 .. ": " .. stats2.avg_time .. "s")

    local speedup = stats1.avg_time / stats2.avg_time
    if speedup > 1 then
        print(name2 .. " is " .. speedup .. "x faster")
    else
        print(name1 .. " is " .. (1/speedup) .. "x faster")
    end
end

-- Example: Compare table iteration methods
local data = {}
for i = 1, 10000 do data[i] = i end

compare(
    "ipairs",
    function()
        local sum = 0
        for i, v in ipairs(data) do sum = sum + v end
    end,
    "numeric for",
    function()
        local sum = 0
        for i = 1, #data do sum = sum + data[i] end
    end
)
```

## Debug Logging

```lua
local DEBUG_LEVEL = 2  -- 0=off, 1=error, 2=warn, 3=info, 4=debug

local function log(level, message)
    if level <= DEBUG_LEVEL then
        local levels = {"ERROR", "WARN", "INFO", "DEBUG"}
        local info = dbg.getinfo(2)
        print(string.format("[%s] %s:%d - %s",
            levels[level],
            info.source or "?",
            info.currentline or 0,
            message))
    end
end

function error_log(msg) log(1, msg) end
function warn_log(msg) log(2, msg) end
function info_log(msg) log(3, msg) end
function debug_log(msg) log(4, msg) end

-- Usage
info_log("Application started")
debug_log("Processing item 123")
warn_log("Cache miss")
error_log("Failed to connect")
```

## Memory Leak Detection

```lua
local dbg = require("luaswift.debug")

-- Track memory over iterations
local function detect_leak(func, iterations)
    iterations = iterations or 100

    local memories = {}
    for i = 1, iterations do
        func()
        collectgarbage("collect")
        memories[i] = dbg.memory_usage()
    end

    -- Check if memory is growing
    local growth = memories[iterations] - memories[1]
    if growth > 0 then
        print("Potential leak detected!")
        print("Memory growth:", growth, "bytes")
        print("Per iteration:", growth / iterations, "bytes")
    else
        print("No leak detected")
    end
end

-- Test function
detect_leak(function()
    local temp = {}
    for i = 1, 100 do
        temp[i] = {data = "test"}
    end
end)
```

## See Also

- ``DebugModule``
- <doc:Modules/TypesModule>
