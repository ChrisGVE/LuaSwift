# Array Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.array` | **Global:** `array`

N-dimensional arrays with broadcasting and element-wise operations.

## Function Reference

| Function | Description |
|----------|-------------|
| [array(data, options?)](#array) | Create array from nested tables |
| [zeros(shape)](#zeros) | Create array filled with zeros |
| [ones(shape)](#ones) | Create array filled with ones |
| [full(shape, value)](#full) | Create array filled with value |
| [eye(n)](#eye) | Create n×n identity matrix |
| [arange(start, stop, step?)](#arange) | Create range of values |
| [linspace(start, stop, n)](#linspace) | Create n evenly spaced values |
| [random.rand(shape)](#randomrand) | Random uniform [0, 1) |
| [random.randn(shape)](#randomrandn) | Random normal distribution |
| [random.randint(low, high, shape)](#randomrandint) | Random integers |
| [complex(real, imag)](#complex) | Create complex array from real and imaginary parts |
| [shape()](#shape) | Get array dimensions |
| [ndim()](#ndim) | Get number of dimensions |
| [size()](#size) | Get total number of elements |
| [dtype()](#dtype) | Get data type |
| [get(...)](#get) | Get element at indices |
| [set(..., value)](#set) | Set element at indices |
| [reshape(new_shape)](#reshape) | Change shape without copying data |
| [flatten()](#flatten) | Flatten to 1D |
| [squeeze()](#squeeze) | Remove size-1 dimensions |
| [expand_dims(axis)](#expand_dims) | Add dimension at axis |
| [transpose()](#transpose) | Transpose array |
| [T()](#t) | Transpose array (shorthand) |
| [copy()](#copy) | Deep copy array |
| [abs(arr)](#abs) | Element-wise absolute value |
| [sqrt(arr)](#sqrt) | Element-wise square root |
| [exp(arr)](#exp) | Element-wise exponential |
| [log(arr)](#log) | Element-wise natural logarithm |
| [sin(arr)](#sin) | Element-wise sine |
| [cos(arr)](#cos) | Element-wise cosine |
| [tan(arr)](#tan) | Element-wise tangent |
| [negative(arr)](#negative) | Element-wise negation |
| [sum(axis?)](#sum) | Sum of elements |
| [mean(axis?)](#mean) | Mean of elements |
| [std(axis?)](#std) | Standard deviation |
| [var(axis?)](#var) | Variance |
| [min(axis?)](#min) | Minimum value |
| [max(axis?)](#max) | Maximum value |
| [argmin(axis?)](#argmin) | Index of minimum value |
| [argmax(axis?)](#argmax) | Index of maximum value |
| [prod(axis?)](#prod) | Product of elements |
| [equal(a, b)](#equal) | Element-wise equality |
| [greater(a, b)](#greater) | Element-wise greater than |
| [less(a, b)](#less) | Element-wise less than |
| [greater_equal(a, b)](#greater_equal) | Element-wise greater or equal |
| [less_equal(a, b)](#less_equal) | Element-wise less or equal |
| [where(condition, x, y)](#where) | Select elements based on condition |
| [dot(a, b)](#dot) | Dot product or matrix multiplication |
| [matmul(a, b)](#matmul) | Matrix multiplication |
| [outer(a, b)](#outer) | Outer product |
| [hstack(arrays)](#hstack) | Stack arrays horizontally |
| [vstack(arrays)](#vstack) | Stack arrays vertically |
| [stack(arrays, axis)](#stack) | Stack arrays along new axis |
| [concatenate(arrays, axis?)](#concatenate) | Concatenate arrays |
| [split(arr, n)](#split) | Split array into n parts |
| [real()](#real) | Extract real part of complex array |
| [imag()](#imag) | Extract imaginary part of complex array |
| [angle(arr)](#angle) | Element-wise phase angle of complex array |
| [tolist()](#tolist) | Convert array to nested Lua tables |

## Type System

| Data Type | Description |
|-----------|-------------|
| float64 | 64-bit floating point (default) |
| complex128 | Complex number (2×64-bit floats) |

---

## array

```
array.array(data, options?) -> array
```

Create array from nested tables.

**Parameters:**
- `data` - Nested Lua tables representing array data
- `options` (optional) - Table with creation options:
  - `dtype` (string): Data type ("float64" or "complex128")

```lua
-- 1D array
local a = array.array({1, 2, 3, 4, 5, 6})

-- 2D array (2x3)
local b = array.array({{1, 2, 3}, {4, 5, 6}})

-- Complex array
local c = array.array({1, 2, 3}, {dtype = "complex128"})
```

---

## zeros

```
array.zeros(shape) -> array
```

Create array filled with zeros.

**Parameters:**
- `shape` - Table of dimensions (e.g., `{2, 3}` for 2×3)

```lua
local z = array.zeros({3, 4})  -- 3x4 zeros
print(z:shape())  -- {3, 4}
```

---

## ones

```
array.ones(shape) -> array
```

Create array filled with ones.

**Parameters:**
- `shape` - Table of dimensions

```lua
local o = array.ones({2, 2})  -- 2x2 ones
```

---

## full

```
array.full(shape, value) -> array
```

Create array filled with specified value.

**Parameters:**
- `shape` - Table of dimensions
- `value` - Fill value (number)

```lua
local f = array.full({2, 3}, 7)  -- 2x3 filled with 7
```

---

## eye

```
array.eye(n) -> array
```

Create n×n identity matrix.

**Parameters:**
- `n` - Matrix size (integer)

```lua
local I = array.eye(3)
-- {{1, 0, 0},
--  {0, 1, 0},
--  {0, 0, 1}}
```

---

## arange

```
array.arange(start, stop, step?) -> array
```

Create range of values.

**Parameters:**
- `start` - Start value (inclusive)
- `stop` - Stop value (exclusive)
- `step` (optional) - Step size (default: 1)

```lua
local r = array.arange(0, 10, 2)  -- {0, 2, 4, 6, 8}
local s = array.arange(0, 5)       -- {0, 1, 2, 3, 4}
```

---

## linspace

```
array.linspace(start, stop, n) -> array
```

Create n evenly spaced values between start and stop (inclusive).

**Parameters:**
- `start` - Start value
- `stop` - Stop value
- `n` - Number of values (integer)

```lua
local l = array.linspace(0, 1, 5)  -- {0, 0.25, 0.5, 0.75, 1}
```

---

## random.rand

```
array.random.rand(shape) -> array
```

Create array with random values from uniform distribution [0, 1).

**Parameters:**
- `shape` - Table of dimensions

```lua
local r = array.random.rand({3, 3})  -- 3x3 random uniform
```

---

## random.randn

```
array.random.randn(shape) -> array
```

Create array with random values from standard normal distribution.

**Parameters:**
- `shape` - Table of dimensions

```lua
local r = array.random.randn({3, 3})  -- 3x3 random normal
```

---

## random.randint

```
array.random.randint(low, high, shape) -> array
```

Create array with random integers in range [low, high).

**Parameters:**
- `low` - Minimum value (inclusive)
- `high` - Maximum value (exclusive)
- `shape` - Table of dimensions

```lua
local r = array.random.randint(0, 10, {5, 5})  -- 5x5 random integers 0-9
```

---

## complex

```
array.complex(real, imag) -> array
```

Create complex array from real and imaginary parts.

**Parameters:**
- `real` - Array of real parts
- `imag` - Array of imaginary parts

```lua
local re = array.array({1, 2, 3})
local im = array.array({4, 5, 6})
local c = array.complex(re, im)
```

---

## shape

```
arr:shape() -> table
```

Get array dimensions as a table.

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
print(b:shape())  -- {2, 3}
```

---

## ndim

```
arr:ndim() -> number
```

Get number of dimensions.

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
print(b:ndim())  -- 2
```

---

## size

```
arr:size() -> number
```

Get total number of elements.

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
print(b:size())  -- 6
```

---

## dtype

```
arr:dtype() -> string
```

Get data type ("float64" or "complex128").

```lua
local a = array.array({1, 2, 3})
print(a:dtype())  -- "float64"
```

---

## get

```
arr:get(...) -> number
```

Get element at specified indices (1-based).

**Parameters:**
- `...` - Indices for each dimension

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
print(b:get(1, 2))  -- 2
print(b:get(2, 3))  -- 6
```

---

## set

```
arr:set(..., value) -> nil
```

Set element at specified indices (1-based).

**Parameters:**
- `...` - Indices for each dimension, followed by value

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
b:set(1, 2, 10)
print(b:get(1, 2))  -- 10
```

---

## reshape

```
arr:reshape(new_shape) -> array
```

Change shape without copying data. Total size must remain constant.

**Parameters:**
- `new_shape` - Table of new dimensions

```lua
local a = array.array({1, 2, 3, 4, 5, 6})
local reshaped = a:reshape({2, 3})  -- 2x3
```

**Errors:** Throws if new shape is incompatible with total size.

---

## flatten

```
arr:flatten() -> array
```

Flatten array to 1D.

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
local flat = b:flatten()  -- {1, 2, 3, 4, 5, 6}
```

---

## squeeze

```
arr:squeeze() -> array
```

Remove all dimensions of size 1.

```lua
local a = array.array({{{1}, {2}, {3}}})  -- shape {1, 3, 1}
local squeezed = a:squeeze()               -- shape {3}
```

---

## expand_dims

```
arr:expand_dims(axis) -> array
```

Add dimension of size 1 at specified axis.

**Parameters:**
- `axis` - Axis position (1-based)

```lua
local a = array.array({1, 2, 3})  -- shape {3}
local expanded = a:expand_dims(1)  -- shape {1, 3}
```

---

## transpose

```
arr:transpose() -> array
```

Transpose array (swap last two dimensions for n-D arrays).

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})  -- 2x3
local t = b:transpose()                          -- 3x2
```

---

## T

```
arr:T() -> array
```

Transpose array (shorthand for `transpose()`).

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
local t = b:T()
```

---

## copy

```
arr:copy() -> array
```

Create deep copy of array.

```lua
local a = array.array({1, 2, 3})
local b = a:copy()
b:set(1, 10)
print(a:get(1))  -- 1 (unchanged)
```

---

## abs

```
array.abs(arr) -> array
```

Element-wise absolute value.

**Parameters:**
- `arr` - Input array

```lua
local a = array.array({-1, -2, 3, -4})
local result = array.abs(a)  -- {1, 2, 3, 4}

-- For complex arrays, returns magnitude
local c = array.array({1, 2, 3}, {dtype = "complex128"})
local mag = array.abs(c)
```

---

## sqrt

```
array.sqrt(arr) -> array
```

Element-wise square root.

**Parameters:**
- `arr` - Input array

```lua
local a = array.array({1, 4, 9, 16})
local result = array.sqrt(a)  -- {1, 2, 3, 4}
```

---

## exp

```
array.exp(arr) -> array
```

Element-wise exponential (e^x).

**Parameters:**
- `arr` - Input array

```lua
local a = array.array({0, 1, 2})
local result = array.exp(a)  -- {1, 2.718..., 7.389...}
```

---

## log

```
array.log(arr) -> array
```

Element-wise natural logarithm.

**Parameters:**
- `arr` - Input array

```lua
local a = array.array({1, 2.718, 7.389})
local result = array.log(a)  -- {0, 1, 2}
```

---

## sin

```
array.sin(arr) -> array
```

Element-wise sine (radians).

**Parameters:**
- `arr` - Input array

```lua
local a = array.array({0, math.pi/2, math.pi})
local result = array.sin(a)  -- {0, 1, 0}
```

---

## cos

```
array.cos(arr) -> array
```

Element-wise cosine (radians).

**Parameters:**
- `arr` - Input array

```lua
local a = array.array({0, math.pi/2, math.pi})
local result = array.cos(a)  -- {1, 0, -1}
```

---

## tan

```
array.tan(arr) -> array
```

Element-wise tangent (radians).

**Parameters:**
- `arr` - Input array

```lua
local a = array.array({0, math.pi/4})
local result = array.tan(a)  -- {0, 1}
```

---

## negative

```
array.negative(arr) -> array
```

Element-wise negation.

**Parameters:**
- `arr` - Input array

```lua
local a = array.array({1, -2, 3})
local result = array.negative(a)  -- {-1, 2, -3}
```

---

## sum

```
arr:sum(axis?) -> number or array
```

Sum of elements.

**Parameters:**
- `axis` (optional) - Axis along which to sum (1-based). If not provided, returns global sum.

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})

-- Global sum
print(b:sum())  -- 21

-- Sum along axis
print(b:sum(1))  -- {5, 7, 9} (column sums)
print(b:sum(2))  -- {6, 15} (row sums)
```

---

## mean

```
arr:mean(axis?) -> number or array
```

Mean of elements.

**Parameters:**
- `axis` (optional) - Axis along which to compute mean

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
print(b:mean())  -- 3.5
```

---

## std

```
arr:std(axis?) -> number or array
```

Standard deviation of elements.

**Parameters:**
- `axis` (optional) - Axis along which to compute standard deviation

```lua
local a = array.array({1, 2, 3, 4, 5})
print(a:std())
```

---

## var

```
arr:var(axis?) -> number or array
```

Variance of elements.

**Parameters:**
- `axis` (optional) - Axis along which to compute variance

```lua
local a = array.array({1, 2, 3, 4, 5})
print(a:var())
```

---

## min

```
arr:min(axis?) -> number or array
```

Minimum value.

**Parameters:**
- `axis` (optional) - Axis along which to find minimum

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
print(b:min())  -- 1
```

---

## max

```
arr:max(axis?) -> number or array
```

Maximum value.

**Parameters:**
- `axis` (optional) - Axis along which to find maximum

```lua
local b = array.array({{1, 2, 3}, {4, 5, 6}})
print(b:max())  -- 6
```

---

## argmin

```
arr:argmin(axis?) -> number or array
```

Index of minimum value (1-based).

**Parameters:**
- `axis` (optional) - Axis along which to find index of minimum

```lua
local a = array.array({3, 1, 4, 1, 5})
print(a:argmin())  -- 2 (first occurrence)
```

---

## argmax

```
arr:argmax(axis?) -> number or array
```

Index of maximum value (1-based).

**Parameters:**
- `axis` (optional) - Axis along which to find index of maximum

```lua
local a = array.array({3, 1, 4, 1, 5})
print(a:argmax())  -- 5
```

---

## prod

```
arr:prod(axis?) -> number or array
```

Product of elements.

**Parameters:**
- `axis` (optional) - Axis along which to compute product

```lua
local a = array.array({1, 2, 3, 4})
print(a:prod())  -- 24
```

---

## equal

```
array.equal(a, b) -> array
```

Element-wise equality comparison. Returns boolean array.

**Parameters:**
- `a` - First array or scalar
- `b` - Second array or scalar

```lua
local a = array.array({1, 2, 3, 4, 5})
local mask = array.equal(a, 3)  -- {false, false, true, false, false}
```

---

## greater

```
array.greater(a, b) -> array
```

Element-wise greater than comparison. Returns boolean array.

**Parameters:**
- `a` - First array or scalar
- `b` - Second array or scalar

```lua
local a = array.array({1, 2, 3, 4, 5})
local mask = array.greater(a, 3)  -- {false, false, false, true, true}
```

---

## less

```
array.less(a, b) -> array
```

Element-wise less than comparison. Returns boolean array.

**Parameters:**
- `a` - First array or scalar
- `b` - Second array or scalar

```lua
local a = array.array({1, 2, 3, 4, 5})
local mask = array.less(a, 3)  -- {true, true, false, false, false}
```

---

## greater_equal

```
array.greater_equal(a, b) -> array
```

Element-wise greater or equal comparison. Returns boolean array.

**Parameters:**
- `a` - First array or scalar
- `b` - Second array or scalar

```lua
local a = array.array({1, 2, 3, 4, 5})
local mask = array.greater_equal(a, 3)  -- {false, false, true, true, true}
```

---

## less_equal

```
array.less_equal(a, b) -> array
```

Element-wise less or equal comparison. Returns boolean array.

**Parameters:**
- `a` - First array or scalar
- `b` - Second array or scalar

```lua
local a = array.array({1, 2, 3, 4, 5})
local mask = array.less_equal(a, 3)  -- {true, true, true, false, false}
```

---

## where

```
array.where(condition, x, y) -> array
```

Select elements from x or y based on condition.

**Parameters:**
- `condition` - Boolean array
- `x` - Array or scalar to select where condition is true
- `y` - Array or scalar to select where condition is false

```lua
local a = array.array({1, 2, 3, 4, 5})
local mask = array.greater(a, 3)
local result = array.where(mask, a, array.zeros({5}))
-- {0, 0, 0, 4, 5}
```

---

## dot

```
array.dot(a, b) -> number or array
```

Dot product or matrix multiplication.

**Parameters:**
- `a` - First array
- `b` - Second array

**Behavior:**
- 1D × 1D: Inner product (scalar)
- 2D × 1D: Matrix-vector product
- 2D × 2D: Matrix multiplication

```lua
-- Vector dot product
local v1 = array.array({1, 2, 3})
local v2 = array.array({4, 5, 6})
print(array.dot(v1, v2))  -- 32 (scalar)

-- Matrix multiplication
local m1 = array.array({{1, 2}, {3, 4}})
local m2 = array.array({{5, 6}, {7, 8}})
local result = array.dot(m1, m2)
```

---

## matmul

```
array.matmul(a, b) -> array
```

Matrix multiplication (alias for `dot`).

**Parameters:**
- `a` - First array
- `b` - Second array

```lua
local m1 = array.array({{1, 2}, {3, 4}})
local m2 = array.array({{5, 6}, {7, 8}})
local result = array.matmul(m1, m2)
```

---

## outer

```
array.outer(a, b) -> array
```

Outer product of two vectors.

**Parameters:**
- `a` - First 1D array
- `b` - Second 1D array

```lua
local v1 = array.array({1, 2, 3})
local v2 = array.array({4, 5, 6})
local result = array.outer(v1, v2)
-- {{4, 5, 6},
--  {8, 10, 12},
--  {12, 15, 18}}
```

---

## hstack

```
array.hstack(arrays) -> array
```

Stack arrays horizontally (column-wise).

**Parameters:**
- `arrays` - Table of arrays to stack

```lua
local a = array.array({1, 2, 3})
local b = array.array({4, 5, 6})
local result = array.hstack({a, b})  -- {1, 2, 3, 4, 5, 6}
```

---

## vstack

```
array.vstack(arrays) -> array
```

Stack arrays vertically (row-wise).

**Parameters:**
- `arrays` - Table of arrays to stack

```lua
local a = array.array({1, 2, 3})
local b = array.array({4, 5, 6})
local result = array.vstack({a, b})
-- {{1, 2, 3},
--  {4, 5, 6}}
```

---

## stack

```
array.stack(arrays, axis) -> array
```

Stack arrays along new axis.

**Parameters:**
- `arrays` - Table of arrays to stack
- `axis` - Axis along which to stack (1-based)

```lua
local a = array.array({1, 2, 3})
local b = array.array({4, 5, 6})
local result = array.stack({a, b}, 1)  -- shape {2, 3}
```

---

## concatenate

```
array.concatenate(arrays, axis?) -> array
```

Concatenate arrays along existing axis.

**Parameters:**
- `arrays` - Table of arrays to concatenate
- `axis` (optional) - Axis along which to concatenate (default: first axis)

```lua
local a = array.array({{1, 2}, {3, 4}})
local b = array.array({{5, 6}, {7, 8}})
local result = array.concatenate({a, b}, 1)  -- 4x2
```

---

## split

```
array.split(arr, n) -> table
```

Split array into n equal parts.

**Parameters:**
- `arr` - Array to split
- `n` - Number of parts (must divide evenly)

```lua
local a = array.array({1, 2, 3, 4, 5, 6})
local parts = array.split(a, 2)
-- parts[1]: {1, 2, 3}
-- parts[2]: {4, 5, 6}
```

**Errors:** Throws if array size is not evenly divisible by n.

---

## real

```
arr:real() -> array
```

Extract real part of complex array.

```lua
local c = array.complex(
  array.array({1, 2, 3}),
  array.array({4, 5, 6})
)
local re = c:real()  -- {1, 2, 3}
```

---

## imag

```
arr:imag() -> array
```

Extract imaginary part of complex array.

```lua
local c = array.complex(
  array.array({1, 2, 3}),
  array.array({4, 5, 6})
)
local im = c:imag()  -- {4, 5, 6}
```

---

## angle

```
array.angle(arr) -> array
```

Element-wise phase angle of complex array (in radians).

**Parameters:**
- `arr` - Complex array

```lua
local c = array.complex(
  array.array({1, 0}),
  array.array({0, 1})
)
local phase = array.angle(c)  -- {0, π/2}
```

---

## tolist

```
arr:tolist() -> table
```

Convert array to nested Lua tables.

```lua
local a = array.array({{1, 2}, {3, 4}})
local tbl = a:tolist()  -- {{1, 2}, {3, 4}}
```

---

## Examples

### Broadcasting

Arrays broadcast to compatible shapes automatically.

```lua
-- 3x1 + 1x3 broadcasts to 3x3
local x = array.array({{1}, {2}, {3}})  -- 3x1
local y = array.array({10, 20, 30})      -- 1x3
local z = x + y
-- {{11, 21, 31},
--  {12, 22, 32},
--  {13, 23, 33}}
```

**Broadcasting Rules:**
- Dimensions aligned from right to left
- Size-1 dimensions broadcast to match
- Missing dimensions treated as size 1

### Arithmetic Operations

```lua
local a = array.array({{1, 2}, {3, 4}})

-- Scalar operations
local doubled = a * 2
local shifted = a + 10
local squared = a ^ 2

-- Element-wise array operations
local b = array.array({{5, 6}, {7, 8}})
local sum = a + b
local diff = a - b
local prod = a * b  -- element-wise, not matrix multiplication
local quot = a / b
```

### Complex Array Operations

```lua
-- Create complex array
local re = array.array({1, 2, 3})
local im = array.array({4, 5, 6})
local c = array.complex(re, im)

-- Extract components
local real_part = c:real()       -- {1, 2, 3}
local imag_part = c:imag()       -- {4, 5, 6}
local magnitude = array.abs(c)   -- magnitude of each complex number
local phase = array.angle(c)     -- phase angle in radians

-- Complex arithmetic works with broadcasting
local scalar = {re = 2, im = 1}  -- complex scalar
local result = c + scalar         -- broadcasts scalar to array
```

### Filtering with Masks

```lua
local data = array.array({1, 5, 3, 8, 2, 9, 4})

-- Create mask
local mask = array.greater(data, 4)  -- {false, true, false, true, false, true, false}

-- Select values
local large = array.where(mask, data, 0)  -- {0, 5, 0, 8, 0, 9, 0}

-- Replace values
local clamped = array.where(
  array.greater(data, 5),
  5,           -- cap at 5
  data         -- keep original
)
```
