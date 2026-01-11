# Linear Algebra Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.linalg` | **Global:** `math.linalg` (after extend_stdlib)

Matrix and vector operations powered by Apple's Accelerate framework (BLAS/LAPACK).

## Function Reference

| Function | Description |
|----------|-------------|
| [vector(values)](#vector) | Create a vector from array |
| [matrix(rows)](#matrix) | Create a matrix from 2D array |
| [zeros(rows, cols)](#zeros) | Create matrix of zeros |
| [ones(rows, cols)](#ones) | Create matrix of ones |
| [eye(n)](#eye) | Create identity matrix |
| [diag(values)](#diag) | Create diagonal matrix |
| [range(start, stop)](#range) | Create range vector |
| [linspace(start, stop, count)](#linspace) | Create linearly spaced vector |
| [rows()](#rows) | Get number of rows |
| [cols()](#cols) | Get number of columns |
| [shape()](#shape) | Get matrix dimensions |
| [size()](#size) | Get total element count |
| [get(row, col)](#get) | Get element value |
| [set(row, col, value)](#set) | Set element value |
| [row(index)](#row) | Extract row as vector |
| [col(index)](#col) | Extract column as vector |
| [dot(other)](#dot) | Vector dot product |
| [hadamard(other)](#hadamard) | Element-wise product |
| [transpose()](#transpose) | Matrix transpose |
| [T()](#t) | Matrix transpose (alias) |
| [det()](#det) | Matrix determinant |
| [inv()](#inv) | Matrix inverse |
| [trace()](#trace) | Matrix trace |
| [norm(type?)](#norm) | Matrix norm |
| [rank()](#rank) | Matrix rank |
| [lu()](#lu) | LU decomposition |
| [qr()](#qr) | QR decomposition |
| [svd()](#svd) | Singular value decomposition |
| [eig()](#eig) | Eigenvalue decomposition |
| [chol()](#chol) | Cholesky decomposition |
| [solve(A, b)](#solve) | Solve linear system |
| [lstsq(A, b)](#lstsq) | Least squares solution |
| [pinv(A)](#pinv) | Pseudo-inverse |
| [cond(A)](#cond) | Condition number |
| [cmatrix(real, imag)](#cmatrix) | Create complex matrix |
| [cdet(A)](#cdet) | Complex determinant |
| [cinv(A)](#cinv) | Complex inverse |

## Type Mapping

| Type | Description |
|------|-------------|
| vector | 1D array represented as Nx1 matrix |
| matrix | 2D array with rows and columns |
| complex matrix | Matrix with real and imaginary parts |

---

## vector

```
la.vector(values) -> vector
```

Create a vector from array.

**Parameters:**
- `values` - Array of numbers

```lua
local v = la.vector({1, 2, 3})
print(v:size())  -- 3
```

---

## matrix

```
la.matrix(rows) -> matrix
```

Create a matrix from 2D array.

**Parameters:**
- `rows` - Array of arrays representing matrix rows

```lua
local m = la.matrix({{1, 2}, {3, 4}, {5, 6}})  -- 3x2 matrix
print(m:rows())  -- 3
print(m:cols())  -- 2
```

---

## zeros

```
la.zeros(rows, cols) -> matrix
```

Create matrix filled with zeros.

**Parameters:**
- `rows` - Number of rows
- `cols` - Number of columns

```lua
local Z = la.zeros(2, 3)  -- 2x3 zeros matrix
```

---

## ones

```
la.ones(rows, cols) -> matrix
```

Create matrix filled with ones.

**Parameters:**
- `rows` - Number of rows
- `cols` - Number of columns

```lua
local O = la.ones(3, 2)  -- 3x2 ones matrix
```

---

## eye

```
la.eye(n) -> matrix
```

Create identity matrix.

**Parameters:**
- `n` - Matrix dimension (creates nxn matrix)

```lua
local I = la.eye(3)  -- 3x3 identity matrix
-- [[1, 0, 0],
--  [0, 1, 0],
--  [0, 0, 1]]
```

---

## diag

```
la.diag(values) -> matrix
```

Create diagonal matrix from values.

**Parameters:**
- `values` - Array of diagonal elements

```lua
local D = la.diag({1, 2, 3})
-- [[1, 0, 0],
--  [0, 2, 0],
--  [0, 0, 3]]
```

---

## range

```
la.range(start, stop) -> vector
```

Create vector with integer range.

**Parameters:**
- `start` - First value (inclusive)
- `stop` - Last value (inclusive)

```lua
local r = la.range(1, 10)  -- {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
```

---

## linspace

```
la.linspace(start, stop, count) -> vector
```

Create vector with linearly spaced values.

**Parameters:**
- `start` - First value
- `stop` - Last value
- `count` - Number of values

```lua
local l = la.linspace(0, 1, 5)  -- {0, 0.25, 0.5, 0.75, 1}
```

---

## rows

```
matrix:rows() -> number
```

Get number of rows in matrix.

```lua
local m = la.matrix({{1, 2, 3}, {4, 5, 6}})
print(m:rows())  -- 2
```

---

## cols

```
matrix:cols() -> number
```

Get number of columns in matrix.

```lua
local m = la.matrix({{1, 2, 3}, {4, 5, 6}})
print(m:cols())  -- 3
```

---

## shape

```
matrix:shape() -> {rows, cols}
```

Get matrix dimensions as array.

```lua
local m = la.matrix({{1, 2, 3}, {4, 5, 6}})
local s = m:shape()  -- {2, 3}
print(s[1], s[2])    -- 2, 3
```

---

## size

```
matrix:size() -> number
```

Get total number of elements.

```lua
local m = la.matrix({{1, 2, 3}, {4, 5, 6}})
print(m:size())  -- 6
```

---

## get

```
matrix:get(row, col) -> number
```

Get element value (1-indexed).

**Parameters:**
- `row` - Row index (1-based)
- `col` - Column index (1-based)

```lua
local m = la.matrix({{1, 2}, {3, 4}})
print(m:get(1, 2))  -- 2
print(m:get(2, 1))  -- 3
```

---

## set

```
matrix:set(row, col, value)
```

Set element value (1-indexed).

**Parameters:**
- `row` - Row index (1-based)
- `col` - Column index (1-based)
- `value` - New value

```lua
local m = la.matrix({{1, 2}, {3, 4}})
m:set(1, 2, 10)
print(m:get(1, 2))  -- 10
```

---

## row

```
matrix:row(index) -> vector
```

Extract row as vector.

**Parameters:**
- `index` - Row index (1-based)

```lua
local m = la.matrix({{1, 2, 3}, {4, 5, 6}})
local row1 = m:row(1)  -- vector {1, 2, 3}
```

---

## col

```
matrix:col(index) -> vector
```

Extract column as vector.

**Parameters:**
- `index` - Column index (1-based)

```lua
local m = la.matrix({{1, 2, 3}, {4, 5, 6}})
local col2 = m:col(2)  -- vector {2, 5}
```

---

## dot

```
vector:dot(other) -> number
```

Compute vector dot product.

**Parameters:**
- `other` - Another vector of same size

```lua
local v1 = la.vector({1, 2, 3})
local v2 = la.vector({4, 5, 6})
local result = v1:dot(v2)  -- 1*4 + 2*5 + 3*6 = 32
```

---

## hadamard

```
matrix:hadamard(other) -> matrix
```

Element-wise (Hadamard) product.

**Parameters:**
- `other` - Matrix of same dimensions

```lua
local A = la.matrix({{1, 2}, {3, 4}})
local B = la.matrix({{5, 6}, {7, 8}})
local H = A:hadamard(B)  -- {{5, 12}, {21, 32}}
```

---

## transpose

```
matrix:transpose() -> matrix
```

Return transposed matrix.

```lua
local A = la.matrix({{1, 2, 3}, {4, 5, 6}})  -- 2x3
local At = A:transpose()  -- 3x2
-- [[1, 4],
--  [2, 5],
--  [3, 6]]
```

---

## T

```
matrix:T() -> matrix
```

Return transposed matrix (alias for transpose).

```lua
local A = la.matrix({{1, 2}, {3, 4}})
local At = A:T()  -- same as A:transpose()
```

---

## det

```
matrix:det() -> number
```

Compute matrix determinant (square matrices only).

```lua
local A = la.matrix({{4, 2}, {3, 1}})
print(A:det())  -- -2
```

---

## inv

```
matrix:inv() -> matrix
```

Compute matrix inverse (non-singular matrices only).

```lua
local A = la.matrix({{4, 2}, {3, 1}})
local Ainv = A:inv()

-- Verify A * A^-1 = I
local I = A * Ainv
print(I:get(1, 1))  -- ~1
print(I:get(1, 2))  -- ~0
```

**Errors:** Throws if matrix is singular.

---

## trace

```
matrix:trace() -> number
```

Compute matrix trace (sum of diagonal elements).

```lua
local A = la.matrix({{4, 2}, {3, 1}})
print(A:trace())  -- 4 + 1 = 5
```

---

## norm

```
matrix:norm(type?) -> number
```

Compute matrix norm.

**Parameters:**
- `type` (optional) - Norm type: 1, 2 (default), "inf", or "fro"

```lua
local A = la.matrix({{3, 4}, {0, 0}})
print(A:norm())      -- Frobenius norm (default)
print(A:norm("fro")) -- Frobenius norm: sqrt(3^2 + 4^2) = 5
print(A:norm(1))     -- 1-norm (max column sum)
print(A:norm("inf")) -- infinity norm (max row sum)
```

---

## rank

```
matrix:rank() -> number
```

Compute matrix rank.

```lua
local A = la.matrix({{1, 2}, {2, 4}})  -- linearly dependent rows
print(A:rank())  -- 1

local B = la.matrix({{1, 2}, {3, 4}})
print(B:rank())  -- 2
```

---

## lu

```
matrix:lu() -> L, U, P
```

LU decomposition with partial pivoting.

**Returns:**
- `L` - Lower triangular matrix
- `U` - Upper triangular matrix
- `P` - Permutation matrix (P * A = L * U)

```lua
local A = la.matrix({{4, 2}, {3, 1}})
local L, U, P = A:lu()

-- Verify P * A = L * U
local result = L * U
local PA = P * A
```

---

## qr

```
matrix:qr() -> Q, R
```

QR decomposition.

**Returns:**
- `Q` - Orthogonal matrix
- `R` - Upper triangular matrix (A = Q * R)

```lua
local A = la.matrix({{4, 2}, {3, 1}})
local Q, R = A:qr()

-- Verify A = Q * R
local reconstructed = Q * R
```

---

## svd

```
matrix:svd() -> U, S, V
```

Singular Value Decomposition.

**Returns:**
- `U` - Left singular vectors
- `S` - Singular values (vector)
- `V` - Right singular vectors (A = U * diag(S) * V^T)

```lua
local A = la.matrix({{4, 2}, {3, 1}})
local U, S, V = A:svd()

-- Reconstruct A
local Sdiag = la.diag(S)
local reconstructed = U * Sdiag * V:T()
```

---

## eig

```
matrix:eig() -> eigenvalues, eigenvectors
```

Eigenvalue decomposition (square matrices only).

**Returns:**
- `eigenvalues` - Vector of eigenvalues
- `eigenvectors` - Matrix of eigenvectors (columns)

```lua
local A = la.matrix({{4, 2}, {3, 1}})
local vals, vecs = A:eig()

-- First eigenvalue and eigenvector
print(vals:get(1, 1))
local v1 = vecs:col(1)
```

---

## chol

```
matrix:chol() -> L
```

Cholesky decomposition (positive definite matrices only).

**Returns:**
- `L` - Lower triangular matrix (A = L * L^T)

```lua
-- Create positive definite matrix
local A = la.matrix({{4, 2}, {2, 3}})
local L = A:chol()

-- Verify A = L * L^T
local reconstructed = L * L:T()
```

**Errors:** Throws if matrix is not positive definite.

---

## solve

```
la.solve(A, b) -> x
```

Solve linear system Ax = b.

**Parameters:**
- `A` - Coefficient matrix (square)
- `b` - Right-hand side vector

**Returns:**
- `x` - Solution vector

```lua
local A = la.matrix({{3, 1}, {1, 2}})
local b = la.vector({9, 8})
local x = la.solve(A, b)  -- x = {2, 3}

-- Verify solution
local residual = (A * x - b):norm()
print(residual)  -- ~0
```

---

## lstsq

```
la.lstsq(A, b) -> x
```

Least squares solution for overdetermined systems.

**Parameters:**
- `A` - Coefficient matrix (may have more rows than columns)
- `b` - Right-hand side vector

**Returns:**
- `x` - Least squares solution minimizing ||Ax - b||

```lua
-- Overdetermined system (3 equations, 2 unknowns)
local A = la.matrix({{1, 1}, {1, 2}, {1, 3}})
local b = la.vector({1, 2, 2})
local x = la.lstsq(A, b)

-- Best fit solution
print("Residual:", (A * x - b):norm())
```

---

## pinv

```
la.pinv(A) -> Apinv
```

Compute Moore-Penrose pseudo-inverse.

**Parameters:**
- `A` - Matrix (may be non-square or singular)

**Returns:**
- `Apinv` - Pseudo-inverse

```lua
local A = la.matrix({{1, 2}, {3, 4}, {5, 6}})
local Apinv = la.pinv(A)

-- For overdetermined systems: x = pinv(A) * b
-- minimizes ||Ax - b||
```

---

## cond

```
la.cond(A) -> number
```

Compute condition number of matrix.

**Parameters:**
- `A` - Matrix

**Returns:**
- Condition number (ratio of largest to smallest singular value)

```lua
local A = la.matrix({{1, 2}, {3, 4}})
local c = la.cond(A)

-- Well-conditioned: cond ~ 1
-- Ill-conditioned: cond >> 1
-- Singular: cond = infinity
```

---

## cmatrix

```
la.cmatrix(real, imag) -> complex_matrix
```

Create complex matrix from real and imaginary parts.

**Parameters:**
- `real` - 2D array of real parts
- `imag` - 2D array of imaginary parts (same dimensions as real)

```lua
local A = la.cmatrix(
    {{1, 2}, {3, 4}},  -- real parts
    {{0, 1}, {1, 0}}   -- imaginary parts
)
```

---

## cdet

```
la.cdet(A) -> {re=number, im=number}
```

Compute determinant of complex matrix.

**Parameters:**
- `A` - Complex matrix

**Returns:**
- Complex number as table with `re` and `im` fields

```lua
local A = la.cmatrix({{1, 0}, {0, 1}}, {{1, 0}, {0, 1}})
local det = la.cdet(A)
print(det.re, det.im)  -- real and imaginary parts
```

---

## cinv

```
la.cinv(A) -> complex_matrix
```

Compute inverse of complex matrix.

**Parameters:**
- `A` - Complex matrix (non-singular)

**Returns:**
- Complex matrix inverse

```lua
local A = la.cmatrix({{1, 0}, {0, 1}}, {{1, 0}, {0, 1}})
local Ainv = la.cinv(A)

-- Verify A * A^-1 = I (complex identity)
```

**Errors:** Throws if matrix is singular.

---

## Examples

### Basic Arithmetic

```lua
local la = require("luaswift.linalg")

local A = la.matrix({{1, 2}, {3, 4}})
local B = la.matrix({{5, 6}, {7, 8}})

-- Element-wise operations
local sum = A + B      -- {{6, 8}, {10, 12}}
local diff = A - B     -- {{-4, -4}, {-4, -4}}
local scaled = A * 2   -- {{2, 4}, {6, 8}}
local divided = A / 2  -- {{0.5, 1}, {1.5, 2}}

-- Matrix multiplication
local product = A * B  -- 2x2 * 2x2 = 2x2
```

### Solving Linear Systems

```lua
-- Simple system
local A = la.matrix({{3, 1}, {1, 2}})
local b = la.vector({9, 8})
local x = la.solve(A, b)  -- {2, 3}

-- Verify
print((A * x - b):norm())  -- ~0
```

### Matrix Decompositions

```lua
local A = la.matrix({{4, 2}, {3, 1}})

-- LU decomposition
local L, U, P = A:lu()
print((P * A - L * U):norm())  -- ~0

-- QR decomposition
local Q, R = A:qr()
print((A - Q * R):norm())  -- ~0

-- SVD
local U, S, V = A:svd()
local reconstructed = U * la.diag(S) * V:T()
print((A - reconstructed):norm())  -- ~0
```

### Complex Matrices

```lua
-- Create complex matrix
local A = la.cmatrix({{1, 2}, {3, 4}}, {{0, 1}, {1, 0}})

-- Complex determinant
local det = la.cdet(A)
print("Determinant:", det.re, "+", det.im, "i")

-- Complex inverse
local Ainv = la.cinv(A)
```
