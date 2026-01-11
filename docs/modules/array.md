# Array Module (NumPy-like)

**Namespace:** `luaswift.array` | **Global:** `array`

N-dimensional arrays with NumPy-style broadcasting and operations.

## Creating Arrays

```lua
local np = require("luaswift.array")

-- From nested tables
local a = np.array({1, 2, 3, 4, 5, 6})        -- 1D
local b = np.array({{1, 2, 3}, {4, 5, 6}})    -- 2D (2x3)

-- Special constructors
local c = np.zeros({2, 3, 4})     -- 3D zeros
local d = np.ones({3, 3})         -- 3x3 ones
local e = np.full({2, 2}, 7)      -- 2x2 filled with 7
local I = np.eye(3)               -- 3x3 identity

-- Ranges
local r = np.arange(0, 10, 2)     -- {0, 2, 4, 6, 8}
local l = np.linspace(0, 1, 5)    -- {0, 0.25, 0.5, 0.75, 1}

-- Random arrays
local uniform = np.random.rand({3, 3})   -- uniform [0, 1)
local normal = np.random.randn({3, 3})   -- normal distribution
local integers = np.random.randint(0, 10, {5, 5})  -- random integers
```

## Array Properties

```lua
local b = np.array({{1, 2, 3}, {4, 5, 6}})

print(b:shape())  -- {2, 3}
print(b:ndim())   -- 2
print(b:size())   -- 6
print(b:dtype())  -- "float64"

-- Element access (1-based indexing)
print(b:get(1, 2))    -- 2
b:set(1, 2, 10)
```

## Reshaping

```lua
local a = np.array({1, 2, 3, 4, 5, 6})

local reshaped = a:reshape({2, 3})     -- 2x3
local flat = reshaped:flatten()         -- back to 1D
local expanded = a:expand_dims(1)       -- add dimension
local squeezed = expanded:squeeze()     -- remove size-1 dimensions
local transposed = reshaped:transpose() -- or :T()
local copied = a:copy()                 -- deep copy
```

## Arithmetic with Broadcasting

```lua
-- Arrays broadcast to compatible shapes
local x = np.array({{1}, {2}, {3}})  -- 3x1
local y = np.array({10, 20, 30})      -- 1x3
local z = x + y  -- broadcasts to 3x3:
-- {{11, 21, 31},
--  {12, 22, 32},
--  {13, 23, 33}}

-- Scalar operations
local doubled = b * 2
local shifted = b + 10

-- Element-wise operations
local sum = x + y
local diff = x - y
local prod = x * y
local quot = x / y
local power = x ^ 2
```

**Broadcasting Rules:**
- Dimensions aligned from right
- Size-1 dimensions broadcast to match
- Missing dimensions treated as size 1

## Element-wise Math

```lua
local a = np.array({1, 4, 9, 16})

local sq = np.sqrt(a)      -- {1, 2, 3, 4}
local ex = np.exp(a)
local logs = np.log(a)
local sines = np.sin(a)
local cosines = np.cos(a)
local absolute = np.abs(a)
local negated = np.negative(a)
```

## Reductions

```lua
local b = np.array({{1, 2, 3}, {4, 5, 6}})

-- Global reductions
print(b:sum())   -- 21
print(b:mean())  -- 3.5
print(b:std())   -- standard deviation
print(b:var())   -- variance
print(b:min())   -- 1
print(b:max())   -- 6
print(b:prod())  -- product of all elements

-- Axis reductions
print(b:sum(1))  -- sum along axis 0: {5, 7, 9}
print(b:sum(2))  -- sum along axis 1: {6, 15}

-- Index of min/max
print(b:argmax())  -- index of maximum (1-based)
print(b:argmin())  -- index of minimum (1-based)
```

## Comparisons

```lua
local a = np.array({1, 2, 3, 4, 5})

-- Returns boolean arrays
local mask = np.greater(a, 3)     -- {false, false, false, true, true}
local eq = np.equal(a, 3)         -- {false, false, true, false, false}
local lt = np.less(a, 3)          -- {true, true, false, false, false}

-- Conditional selection
local result = np.where(mask, a, np.zeros({5}))
-- {0, 0, 0, 4, 5}
```

## Matrix Operations

```lua
local m1 = np.array({{1, 2}, {3, 4}})
local m2 = np.array({{5, 6}, {7, 8}})

-- Matrix multiplication
local prod = np.dot(m1, m2)
-- or: np.matmul(m1, m2)

-- Vector dot product
local v1 = np.array({1, 2, 3})
local v2 = np.array({4, 5, 6})
print(np.dot(v1, v2))  -- 32 (scalar)

-- Outer product
local outer = np.outer(v1, v2)
```

## Stacking and Splitting

```lua
local a = np.array({1, 2, 3})
local b = np.array({4, 5, 6})

-- Concatenate
local h = np.hstack({a, b})  -- {1, 2, 3, 4, 5, 6}
local v = np.vstack({a, b})  -- {{1, 2, 3}, {4, 5, 6}}

-- Stack along new axis
local stacked = np.stack({a, b}, 1)  -- 2x3

-- Split
local parts = np.split(h, 2)  -- split into 2 equal parts
```

## Conversion

```lua
local a = np.array({{1, 2}, {3, 4}})

-- To nested Lua tables
local tbl = a:tolist()  -- {{1, 2}, {3, 4}}
```

## Complex Arrays

```lua
-- Create complex array
local c = np.array({1, 2, 3}, {dtype = "complex128"})

-- Or from real + imaginary
local re = np.array({1, 2, 3})
local im = np.array({4, 5, 6})
local complex = np.complex(re, im)

-- Extract components
local real_part = complex:real()
local imag_part = complex:imag()
local magnitude = np.abs(complex)
local phase = np.angle(complex)
```

## Function Reference

| Category | Functions |
|----------|-----------|
| Creation | `array`, `zeros`, `ones`, `full`, `eye`, `arange`, `linspace`, `random.*` |
| Properties | `shape`, `ndim`, `size`, `dtype`, `get`, `set` |
| Reshaping | `reshape`, `flatten`, `squeeze`, `expand_dims`, `transpose`/`T`, `copy` |
| Math | `abs`, `sqrt`, `exp`, `log`, `sin`, `cos`, `tan`, `negative` |
| Arithmetic | `+`, `-`, `*`, `/`, `^` (with broadcasting) |
| Reductions | `sum`, `mean`, `std`, `var`, `min`, `max`, `argmin`, `argmax`, `prod` |
| Comparison | `equal`, `greater`, `less`, `greater_equal`, `less_equal`, `where` |
| Linear Algebra | `dot`, `matmul`, `outer` |
| Stacking | `hstack`, `vstack`, `stack`, `concatenate`, `split` |
