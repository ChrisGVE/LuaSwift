# LinAlg Module

Hardware-accelerated linear algebra operations for vectors and matrices.

## Overview

The LinAlg module provides comprehensive linear algebra functionality using Apple's Accelerate framework for optimal performance. It supports vector and matrix creation, arithmetic operations, matrix decompositions, and linear system solvers.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the LinAlg module
ModuleRegistry.installLinAlgModule(in: engine)
```

## Basic Usage

```lua
local linalg = require("luaswift.linalg")

-- Create vectors
local v = linalg.vector({1, 2, 3, 4})
local u = linalg.ones(4)

-- Vector operations
local sum = v + u
local dot = v:dot(u)        -- 10 (scalar)
print(v:norm())             -- Euclidean norm

-- Create matrices
local A = linalg.matrix({{1, 2}, {3, 4}})
local I = linalg.eye(2)

-- Matrix operations
local B = A + I
local C = A:dot(A)          -- Matrix multiplication
print(A:det())              -- Determinant
local Ainv = A:inv()        -- Inverse
```

## API Reference

### Vector Creation

#### vector(array)
Creates a vector from a 1D array of numbers.

```lua
local v = linalg.vector({1, 2, 3, 4, 5})
print(v:size())    -- 5
print(v:get(1))    -- 1
```

#### zeros(n)
Creates a vector of zeros with n elements.

```lua
local v = linalg.zeros(5)
print(v:toarray())    -- {0, 0, 0, 0, 0}
```

#### ones(n)
Creates a vector of ones with n elements.

```lua
local v = linalg.ones(3)
print(v:toarray())    -- {1, 1, 1}
```

#### range(start, stop, step?)
Creates a vector with values from start to stop (exclusive) with optional step.

```lua
local v = linalg.range(0, 10, 2)
print(v:toarray())    -- {0, 2, 4, 6, 8}

local w = linalg.range(5, 0, -1)
print(w:toarray())    -- {5, 4, 3, 2, 1}
```

#### linspace(start, stop, n)
Creates a vector with n evenly spaced values from start to stop (inclusive).

```lua
local v = linalg.linspace(0, 1, 5)
print(v:toarray())    -- {0, 0.25, 0.5, 0.75, 1}
```

### Matrix Creation

#### matrix(array)
Creates a matrix from a 2D array (array of rows).

```lua
local A = linalg.matrix({
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9}
})
print(A:rows(), A:cols())    -- 3  3
```

#### zeros(rows, cols)
Creates a matrix of zeros with specified dimensions.

```lua
local A = linalg.zeros(3, 4)
print(A:shape())    -- {3, 4}
```

#### ones(rows, cols)
Creates a matrix of ones with specified dimensions.

```lua
local A = linalg.ones(2, 3)
```

#### eye(n)
Creates an n×n identity matrix.

```lua
local I = linalg.eye(3)
-- [[1, 0, 0],
--  [0, 1, 0],
--  [0, 0, 1]]
```

#### diag(array)
Creates a diagonal matrix from an array of values.

```lua
local D = linalg.diag({1, 2, 3})
-- [[1, 0, 0],
--  [0, 2, 0],
--  [0, 0, 3]]
```

### Properties and Access

#### m:rows()
Returns the number of rows.

```lua
local A = linalg.matrix({{1,2},{3,4},{5,6}})
print(A:rows())    -- 3
```

#### m:cols()
Returns the number of columns.

```lua
print(A:cols())    -- 2
```

#### m:shape()
Returns the dimensions as an array.

```lua
print(A:shape())       -- {3, 2} for matrix
local v = linalg.vector({1,2,3})
print(v:shape())       -- {3} for vector
```

#### m:size()
Returns the total number of elements.

```lua
print(A:size())    -- 6
```

#### m:get(i, j) / v:get(i)
Gets the element at position (i, j) for matrices or position i for vectors. Indices are 1-based.

```lua
local A = linalg.matrix({{1,2},{3,4}})
print(A:get(1, 2))    -- 2

local v = linalg.vector({10, 20, 30})
print(v:get(2))       -- 20
```

#### m:set(i, j, value) / v:set(i, value)
Sets the element at the specified position. Returns the modified matrix/vector.

```lua
local A = linalg.matrix({{1,2},{3,4}})
A:set(1, 2, 99)
print(A:get(1, 2))    -- 99
```

#### m:row(i)
Returns the i-th row as a row vector.

```lua
local A = linalg.matrix({{1,2,3},{4,5,6}})
local r = A:row(1)
print(r:toarray())    -- {{1, 2, 3}}
```

#### m:col(j)
Returns the j-th column as a column vector.

```lua
local c = A:col(2)
print(c:toarray())    -- {2, 5}
```

#### m:transpose() / m:T()
Returns the transpose of the matrix.

```lua
local A = linalg.matrix({{1,2},{3,4}})
local At = A:transpose()
-- or equivalently
local At = A:T()
```

#### m:toarray()
Converts to a Lua array.

```lua
local A = linalg.matrix({{1,2},{3,4}})
local arr = A:toarray()    -- {{1, 2}, {3, 4}}

local v = linalg.vector({1, 2, 3})
local varr = v:toarray()   -- {1, 2, 3}
```

### Arithmetic Operations

Matrices and vectors support standard arithmetic operators.

#### Addition (+)
```lua
local A = linalg.matrix({{1,2},{3,4}})
local B = linalg.matrix({{5,6},{7,8}})
local C = A + B    -- {{6,8},{10,12}}
```

#### Subtraction (-)
```lua
local C = A - B    -- {{-4,-4},{-4,-4}}
```

#### Scalar Multiplication (*)
```lua
local C = A * 2    -- {{2,4},{6,8}}
local D = 3 * A    -- {{3,6},{9,12}}
```

#### Scalar Division (/)
```lua
local C = A / 2    -- {{0.5,1},{1.5,2}}
```

#### Negation (-)
```lua
local C = -A       -- {{-1,-2},{-3,-4}}
```

#### m:dot(other)
Matrix multiplication or vector dot product.

```lua
-- Matrix multiplication
local A = linalg.matrix({{1,2},{3,4}})
local B = linalg.matrix({{5,6},{7,8}})
local C = A:dot(B)    -- {{19,22},{43,50}}

-- Matrix-vector multiplication
local v = linalg.vector({1, 2})
local w = A:dot(v)    -- {5, 11}

-- Vector dot product (returns scalar)
local u = linalg.vector({1, 2, 3})
local v = linalg.vector({4, 5, 6})
local d = u:dot(v)    -- 32
```

#### m:hadamard(other)
Element-wise (Hadamard) product.

```lua
local A = linalg.matrix({{1,2},{3,4}})
local B = linalg.matrix({{5,6},{7,8}})
local C = A:hadamard(B)    -- {{5,12},{21,32}}
```

### Linear Algebra Operations

#### m:det()
Computes the determinant of a square matrix.

```lua
local A = linalg.matrix({{1,2},{3,4}})
print(A:det())    -- -2
```

#### m:inv()
Computes the inverse of a square matrix.

```lua
local A = linalg.matrix({{1,2},{3,4}})
local Ainv = A:inv()
local I = A:dot(Ainv)    -- Identity matrix (within numerical precision)
```

#### m:trace()
Computes the trace (sum of diagonal elements) of a square matrix.

```lua
local A = linalg.matrix({{1,2},{3,4}})
print(A:trace())    -- 5 (1 + 4)
```

#### m:norm(p?)
Computes the matrix or vector norm.

**For vectors:**
- `p = 1`: L1 norm (sum of absolute values)
- `p = 2` (default): L2 norm (Euclidean)
- `p = math.huge`: Infinity norm (maximum absolute value)
- Other p: General p-norm

**For matrices:**
- `p = 1`: Column sum norm
- `p = math.huge`: Row sum norm
- `"fro"`: Frobenius norm

```lua
local v = linalg.vector({3, 4})
print(v:norm())       -- 5 (L2 norm)
print(v:norm(1))      -- 7 (L1 norm)
print(v:norm(math.huge))  -- 4 (infinity norm)

local A = linalg.matrix({{1,2},{3,4}})
print(A:norm("fro"))  -- Frobenius norm
```

#### m:rank()
Computes the numerical rank of a matrix.

```lua
local A = linalg.matrix({{1,2,3},{4,5,6},{7,8,9}})
print(A:rank())    -- 2 (rows are linearly dependent)
```

### Matrix Decompositions

#### m:lu()
LU decomposition with partial pivoting. Returns L, U, P matrices such that P·A = L·U.

```lua
local A = linalg.matrix({{2,1},{1,3}})
local L, U, P = A:lu()

-- L is lower triangular with 1s on diagonal
-- U is upper triangular
-- P is permutation matrix
```

#### m:qr()
QR decomposition. Returns Q (orthogonal) and R (upper triangular) such that A = Q·R.

```lua
local A = linalg.matrix({{1,2},{3,4},{5,6}})
local Q, R = A:qr()

-- Q is orthogonal: Q^T · Q = I
-- R is upper triangular
```

#### m:svd()
Singular Value Decomposition. Returns U, S, V such that A = U·S·V^T.

```lua
local A = linalg.matrix({{1,2},{3,4},{5,6}})
local U, S, V = A:svd()

-- U: left singular vectors (orthogonal)
-- S: diagonal matrix of singular values
-- V: right singular vectors (orthogonal)
```

#### m:eig()
Eigenvalue decomposition for square matrices. Returns eigenvalues and eigenvectors.

```lua
local A = linalg.matrix({{4,2},{1,3}})
local vals, vecs = A:eig()

-- vals: vector of eigenvalues
-- vecs: matrix with eigenvectors as columns
```

#### m:chol()
Cholesky decomposition for symmetric positive-definite matrices. Returns L such that A = L·L^T.

```lua
local A = linalg.matrix({{4,2},{2,5}})
local L = A:chol()

-- L is lower triangular
-- L:dot(L:T()) equals A
```

### Linear System Solvers

#### linalg.solve(A, b)
Solves the linear system A·x = b for square matrix A.

```lua
local A = linalg.matrix({{3,1},{1,2}})
local b = linalg.vector({9, 8})

local x = linalg.solve(A, b)
-- x satisfies A:dot(x) ≈ b
```

#### linalg.lstsq(A, b)
Least squares solution to A·x = b (for overdetermined or underdetermined systems).

```lua
-- Overdetermined system (more equations than unknowns)
local A = linalg.matrix({{1,1},{1,2},{1,3}})
local b = linalg.vector({1, 2, 2})

local x = linalg.lstsq(A, b)
-- x minimizes ||A·x - b||
```

## Common Patterns

### Solving Linear Systems

```lua
local linalg = require("luaswift.linalg")

-- System: 3x + y = 9, x + 2y = 8
local A = linalg.matrix({{3, 1}, {1, 2}})
local b = linalg.vector({9, 8})

local x = linalg.solve(A, b)
print(x:toarray())    -- {2, 3}

-- Verify: A·x should equal b
local check = A:dot(x)
print(check:toarray())    -- {9, 8}
```

### Computing Matrix Properties

```lua
local A = linalg.matrix({{1, 2, 3}, {4, 5, 6}, {7, 8, 10}})

print("Determinant:", A:det())
print("Trace:", A:trace())
print("Rank:", A:rank())
print("Frobenius norm:", A:norm("fro"))
```

### Linear Regression

```lua
-- Data points: (1,2), (2,3), (3,5), (4,4)
local X = linalg.matrix({
    {1, 1},
    {1, 2},
    {1, 3},
    {1, 4}
})
local y = linalg.vector({2, 3, 5, 4})

-- Least squares fit: y = a + b*x
local coeffs = linalg.lstsq(X, y)
local a, b = coeffs:get(1), coeffs:get(2)
print(string.format("y = %.2f + %.2fx", a, b))
```

### Principal Component Analysis (PCA)

```lua
local linalg = require("luaswift.linalg")

-- Data matrix (rows are samples, columns are features)
local data = linalg.matrix({
    {2.5, 2.4},
    {0.5, 0.7},
    {2.2, 2.9},
    {1.9, 2.2},
    {3.1, 3.0}
})

-- Center the data
local n = data:rows()
local mean_x = 0
local mean_y = 0
for i = 1, n do
    mean_x = mean_x + data:get(i, 1)
    mean_y = mean_y + data:get(i, 2)
end
mean_x, mean_y = mean_x / n, mean_y / n

-- Compute covariance matrix
-- ... (simplified example)

-- Get principal components via SVD
local U, S, V = data:svd()
-- V contains principal component directions
```

### Matrix Inversion Check

```lua
local A = linalg.matrix({{1, 2}, {3, 4}})

-- Check if matrix is invertible
local det = A:det()
if math.abs(det) < 1e-10 then
    print("Matrix is singular!")
else
    local Ainv = A:inv()

    -- Verify: A · A^-1 should be identity
    local I = A:dot(Ainv)
    print("Product is identity:", I:toarray())
end
```

## Performance Notes

- The LinAlg module uses Apple's Accelerate framework for hardware-accelerated computation
- All operations use double-precision floating-point numbers
- For best performance, avoid creating many small temporary matrices in tight loops
- Prefer batch operations over element-by-element access when possible

## See Also

- ``LinAlgModule``
- ``MathXModule``
- ``ArrayModule``
- ``ComplexModule``
