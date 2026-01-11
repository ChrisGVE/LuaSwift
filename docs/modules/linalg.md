# Linear Algebra Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.linalg` | **Global:** `math.linalg` (after extend_stdlib)

Matrix and vector operations powered by Apple's Accelerate framework (BLAS/LAPACK).

## Creating Vectors and Matrices

```lua
local la = require("luaswift.linalg")

-- Vectors
local v = la.vector({1, 2, 3})

-- Matrices
local m = la.matrix({{1, 2}, {3, 4}, {5, 6}})  -- 3x2 matrix

-- Special matrices
local I = la.eye(3)           -- 3x3 identity
local Z = la.zeros(2, 3)      -- 2x3 zeros
local O = la.ones(3, 2)       -- 3x2 ones
local D = la.diag({1, 2, 3})  -- diagonal matrix

-- Ranges
local r = la.range(1, 10)         -- {1, 2, ..., 10}
local l = la.linspace(0, 1, 5)    -- {0, 0.25, 0.5, 0.75, 1}
```

## Matrix Properties

```lua
local m = la.matrix({{1, 2, 3}, {4, 5, 6}})

print(m:rows())   -- 2
print(m:cols())   -- 3
print(m:shape())  -- {2, 3}

-- Element access (1-indexed)
print(m:get(1, 2))  -- 2
m:set(1, 2, 10)

-- Row/column extraction
local row1 = m:row(1)   -- vector
local col2 = m:col(2)   -- vector
```

## Arithmetic

```lua
local A = la.matrix({{1, 2}, {3, 4}})
local B = la.matrix({{5, 6}, {7, 8}})

-- Element-wise operations
local sum = A + B
local diff = A - B
local scaled = A * 2
local divided = A / 2

-- Matrix multiplication
local product = A * B  -- 2x2 * 2x2 = 2x2

-- Hadamard (element-wise) product
local hadamard = A:hadamard(B)

-- Dot product (vectors)
local v1 = la.vector({1, 2, 3})
local v2 = la.vector({4, 5, 6})
local dot = v1:dot(v2)  -- 32
```

## Matrix Operations

```lua
local A = la.matrix({{4, 2}, {3, 1}})

-- Transpose
local At = A:transpose()  -- or A:T()

-- Determinant
print(A:det())  -- -2

-- Trace
print(A:trace())  -- 5

-- Rank
print(A:rank())  -- 2

-- Inverse
local Ainv = A:inv()

-- Norm
print(A:norm())      -- Frobenius norm
print(A:norm(1))     -- 1-norm
print(A:norm("inf")) -- infinity norm
```

## Decompositions

```lua
local A = la.matrix({{4, 2}, {3, 1}})

-- LU decomposition
local L, U, P = A:lu()
-- P * A = L * U

-- QR decomposition
local Q, R = A:qr()
-- A = Q * R

-- Singular Value Decomposition
local U, S, V = A:svd()
-- A = U * diag(S) * V^T

-- Eigenvalue decomposition (square matrices)
local eigenvalues, eigenvectors = A:eig()

-- Cholesky decomposition (positive definite)
local L = A:chol()
```

## Solving Linear Systems

```lua
-- Solve Ax = b
local A = la.matrix({{3, 1}, {1, 2}})
local b = la.vector({9, 8})
local x = la.solve(A, b)  -- x = {2, 3}

-- Verify
print((A * x - b):norm())  -- ~0

-- Least squares (overdetermined systems)
local A = la.matrix({{1, 1}, {1, 2}, {1, 3}})
local b = la.vector({1, 2, 2})
local x = la.lstsq(A, b)

-- Pseudo-inverse
local Apinv = la.pinv(A)

-- Condition number
local cond = la.cond(A)
```

## Complex Matrices

```lua
-- Create complex matrix
local A = la.cmatrix({{1, 2}, {3, 4}}, {{0, 1}, {1, 0}})
-- First table: real parts, second table: imaginary parts

-- Complex determinant
local det = la.cdet(A)  -- returns {re=..., im=...}

-- Complex inverse
local Ainv = la.cinv(A)
```

## Function Reference

| Category | Functions |
|----------|-----------|
| Creation | `vector`, `matrix`, `zeros`, `ones`, `eye`, `diag`, `range`, `linspace` |
| Properties | `rows`, `cols`, `shape`, `size`, `get`, `set`, `row`, `col` |
| Arithmetic | `+`, `-`, `*`, `/`, `dot`, `hadamard` |
| Operations | `transpose`/`T`, `det`, `inv`, `trace`, `norm`, `rank` |
| Decompositions | `lu`, `qr`, `svd`, `eig`, `chol` |
| Solvers | `solve`, `lstsq`, `pinv`, `cond` |
| Complex | `cmatrix`, `cdet`, `cinv` |
