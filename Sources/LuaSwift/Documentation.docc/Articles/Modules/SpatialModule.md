# Spatial Module

Spatial data structures, nearest-neighbor search, computational geometry, and distance functions.

## Overview

The Spatial module provides efficient spatial data structures and computational geometry algorithms
backed by Swift and BLAS/vDSP via **NumericSwift**.

> Important: This module requires the **NumericSwift** optional dependency, which is **disabled by
> default**. Build with `LUASWIFT_INCLUDE_NUMERICSWIFT=1` to enable it. Without that flag the
> module is not compiled and `math.spatial` will be `nil` at runtime.

After installation the module is available under `math.spatial` (and `luaswift.spatial`) once you
call `luaswift.extend_stdlib()`.

## Installation

```swift
// Install all modules (NumericSwift must be present)
try ModuleRegistry.install(in: engine)

// Or install just the Spatial module
try SpatialModule.install(in: engine)
```

```lua
luaswift.extend_stdlib()
local spatial = math.spatial
```

## Distance Functions

Point-to-point distance functions live under the `math.spatial.distance` namespace. All functions
accept two arrays of numbers and return a single number.

### distance.euclidean(p1, p2)

Straight-line (L2) distance.

```lua
local d = math.spatial.distance.euclidean({0, 0}, {3, 4})  -- 5.0
```

### distance.sqeuclidean(p1, p2)

Squared Euclidean distance (avoids the square-root, useful for comparisons).

```lua
local d = math.spatial.distance.sqeuclidean({0, 0}, {3, 4})  -- 25.0
```

### distance.cityblock(p1, p2)

Manhattan / L1 distance.

```lua
local d = math.spatial.distance.cityblock({0, 0}, {3, 4})  -- 7.0
```

### distance.chebyshev(p1, p2)

Chebyshev / L∞ distance (maximum absolute coordinate difference).

```lua
local d = math.spatial.distance.chebyshev({0, 0}, {3, 4})  -- 4.0
```

### distance.minkowski(p1, p2, p?)

Minkowski distance of order `p`. Defaults to `p = 2` (Euclidean) when omitted.

```lua
local d = math.spatial.distance.minkowski({0, 0}, {3, 4}, 1)  -- 7.0  (L1)
local d2 = math.spatial.distance.minkowski({0, 0}, {3, 4})    -- 5.0  (L2)
```

### distance.cosine(p1, p2)

Cosine distance (1 − cosine similarity).

```lua
local d = math.spatial.distance.cosine({1, 0}, {0, 1})  -- 1.0 (orthogonal)
```

### distance.correlation(p1, p2)

Correlation distance (1 − Pearson correlation).

```lua
local d = math.spatial.distance.correlation({1, 2, 3}, {4, 5, 6})  -- 0.0 (perfect correlation)
```

## Batch Distance Functions

### spatial.cdist(XA, XB, metric?)

Compute all pairwise distances between every row of `XA` and every row of `XB`. Returns an
`m × n` matrix (array of arrays) where `m = #XA` and `n = #XB`.

`metric` is a string: `"euclidean"` (default), `"sqeuclidean"`, `"cityblock"`,
`"chebyshev"`, `"cosine"`, or `"correlation"`. `"manhattan"` is accepted as an alias for
`"cityblock"`.

```lua
local XA = {{0, 0}, {1, 0}}
local XB = {{0, 1}, {1, 1}}

local D = math.spatial.cdist(XA, XB)
-- D[1][1] = distance({0,0}, {0,1}) = 1.0
-- D[1][2] = distance({0,0}, {1,1}) = 1.414...
-- D[2][1] = distance({1,0}, {0,1}) = 1.414...
-- D[2][2] = distance({1,0}, {1,1}) = 1.0
```

### spatial.pdist(X, metric?)

Compute pairwise distances among all rows of `X`. Returns a condensed 1-D array of length
`n*(n-1)/2` in row-major upper-triangle order. `metric` accepts the same values as `cdist`.

```lua
local X = {{0, 0}, {1, 0}, {0, 1}}
local d = math.spatial.pdist(X)
-- d[1] = dist(X[1], X[2]) = 1.0
-- d[2] = dist(X[1], X[3]) = 1.0
-- d[3] = dist(X[2], X[3]) = 1.414...
```

### spatial.squareform(X)

Convert between condensed and square distance-matrix forms.

- **Condensed → square**: pass a 1-D array (output of `pdist`); returns a symmetric `n × n` matrix.
- **Square → condensed**: pass a 2-D array; returns the upper-triangle as a 1-D array.

```lua
local X    = {{0, 0}, {1, 0}, {0, 1}}
local cond = math.spatial.pdist(X)          -- condensed [1.0, 1.0, 1.414...]
local sq   = math.spatial.squareform(cond)  -- 3×3 symmetric matrix
local back = math.spatial.squareform(sq)    -- condensed again
```

## KDTree

### spatial.KDTree(points)

Build a k-d tree from an array of points. Each point is itself an array of numbers.

```lua
local points = {{0, 0}, {1, 1}, {2, 2}, {5, 5}}
local tree = math.spatial.KDTree(points)
-- tree.points  — the original points array
-- tree.n       — number of points
-- tree.dim     — dimensionality
```

### tree:query(point, k?)

Find the `k` nearest neighbors of `point`. `k` defaults to `1`.

Returns two values: **`indices`, `distances`** — both arrays of length `k`.
Indices are 1-based.

```lua
local tree = math.spatial.KDTree({{0,0},{1,1},{2,2},{5,5}})

-- Single nearest neighbor
local indices, distances = tree:query({0.5, 0.5}, 1)
print(indices[1], distances[1])   -- 1   0.707...

-- Three nearest neighbors
local idxs, dists = tree:query({0.5, 0.5}, 3)
for i = 1, #idxs do
    print("index:", idxs[i], "distance:", dists[i])
end
```

> Note: The return order is **`indices` first, `distances` second**. This is the opposite of what
> some older documentation showed.

### tree:query_radius(point, r)

Find all points within Euclidean radius `r` of `point`.

Returns two values: **`indices`, `distances`** — both arrays. Indices are 1-based.

```lua
local tree = math.spatial.KDTree({{0,0},{1,0},{0,1},{3,3}})
local indices, distances = tree:query_radius({0, 0}, 1.5)
-- indices contains the 1-based indices of all points within radius 1.5
```

### tree:query_pairs(r)

Find all pairs of points within distance `r` of each other. Returns an array of triplets
`{i, j, distance}` where `i` and `j` are 1-based indices and `i < j`.

```lua
local tree = math.spatial.KDTree({{0,0},{1,0},{0,1},{5,5}})
local pairs = tree:query_pairs(1.5)
for _, p in ipairs(pairs) do
    print("pair:", p[1], p[2], "dist:", p[3])
end
```

## Voronoi Diagrams

### spatial.Voronoi(points)

Compute the Voronoi diagram of a set of 2-D input points using NumericSwift.

Returns a table with the following fields (all indices are 1-based):

| Field | Type | Description |
|---|---|---|
| `points` | array of arrays | The original input points |
| `vertices` | array of arrays | Coordinates of Voronoi vertices |
| `regions` | array of arrays | For each input point, the indices of its Voronoi vertices |
| `ridge_vertices` | array of arrays | Each ridge as a pair of Voronoi vertex indices |
| `ridge_points` | array of arrays | Each ridge as a pair of input-point indices |

```lua
local points = {{0,0},{1,0},{0,1},{1,1}}
local vor = math.spatial.Voronoi(points)

print(#vor.vertices)               -- number of Voronoi vertices
print(#vor.regions)                -- one region per input point
print(#vor.ridge_vertices)         -- number of ridges
print(#vor.ridge_points)           -- same count, input-point pairs

-- Iterate ridges
for _, ridge in ipairs(vor.ridge_vertices) do
    local v1, v2 = ridge[1], ridge[2]
    -- v1, v2 are 1-based indices into vor.vertices
end
```

## Delaunay Triangulation

### spatial.Delaunay(points)

Compute the Delaunay triangulation of a set of 2-D input points using NumericSwift. Collinear
points are handled gracefully (returned as line segments).

Returns a table with the following fields (all indices are 1-based):

| Field | Type | Description |
|---|---|---|
| `points` | array of arrays | The original input points |
| `simplices` | array of arrays | Each triangle as three point indices |
| `neighbors` | array of arrays | For each triangle, its adjacent triangle indices |

```lua
local points = {{0,0},{1,0},{0.5,0.866},{1,1},{0,1}}
local tri = math.spatial.Delaunay(points)

print(#tri.simplices)              -- number of triangles

for _, simplex in ipairs(tri.simplices) do
    local v1, v2, v3 = simplex[1], simplex[2], simplex[3]
    -- v1, v2, v3 are 1-based indices into tri.points
end
```

## Convex Hull

### spatial.ConvexHull(points)

Compute the convex hull of a set of 2-D points using NumericSwift.

Returns a table with the following fields (all indices are 1-based):

| Field | Type | Description |
|---|---|---|
| `points` | array of arrays | The original input points |
| `vertices` | array | 1-based indices of hull vertices in order |
| `simplices` | array of arrays | Hull edges, each as a pair of point indices |

```lua
local points = {{0,0},{1,0},{1,1},{0,1},{0.5,0.5}}
local hull = math.spatial.ConvexHull(points)

print(hull.vertices)               -- e.g. {1, 2, 3, 4}  (interior point excluded)

for _, edge in ipairs(hull.simplices) do
    local a, b = edge[1], edge[2]
    -- a, b are 1-based indices into hull.points
end
```

## Applications

### Nearest Neighbor Search

```lua
local stores    = {{0,0},{5,5},{10,0}}
local customers = {{1,1},{6,4},{8,1}}

local tree = math.spatial.KDTree(stores)

for i, customer in ipairs(customers) do
    local indices, distances = tree:query(customer, 2)
    print("Customer " .. i .. " nearest stores:", indices[1], indices[2])
    print("  distances:", distances[1], distances[2])
end
```

### Density Estimation with Radius Queries

```lua
-- Count points within radius for a density map
local data = {}
for i = 1, 100 do
    data[i] = {math.random() * 10, math.random() * 10}
end

local tree = math.spatial.KDTree(data)

local densities = {}
for i, point in ipairs(data) do
    local indices, _ = tree:query_radius(point, 1.0)
    densities[i] = #indices
end
```

### Nearby-Pair Detection

```lua
-- Find all points that are closer than a threshold
local points = {{0,0},{0.5,0},{1,0},{2,0},{3,0}}
local tree   = math.spatial.KDTree(points)

for _, pair in ipairs(tree:query_pairs(0.8)) do
    print("Close pair:", pair[1], pair[2], "dist:", pair[3])
end
```

### Inverse-Distance Weighted Interpolation

```lua
local points = {{0,0},{1,0},{0,1},{1,1}}
local values = {0, 1, 1, 2}
local tree   = math.spatial.KDTree(points)

local function interpolate(x, y, k)
    local indices, distances = tree:query({x, y}, k)
    local sum_val, sum_weight = 0, 0
    for i = 1, k do
        local weight = 1 / (distances[i] + 1e-10)
        sum_val    = sum_val    + weight * values[indices[i]]
        sum_weight = sum_weight + weight
    end
    return sum_val / sum_weight
end

print("Value at (0.5, 0.5):", interpolate(0.5, 0.5, 4))
```

### Distance-Matrix Workflow

```lua
local set1 = {{0,0},{1,0},{2,0}}
local set2 = {{0,1},{1,1}}

-- All pairwise distances between two sets
local D = math.spatial.cdist(set1, set2)

-- Condensed self-distances then expand to square form
local condensed = math.spatial.pdist(set1)
local square    = math.spatial.squareform(condensed)
```

### Triangulation for Mesh Generation

```lua
local boundary = {{0,0},{1,0},{1,1},{0,1}}
local tri      = math.spatial.Delaunay(boundary)

for _, simplex in ipairs(tri.simplices) do
    local v1, v2, v3 = simplex[1], simplex[2], simplex[3]
    -- process triangle
end
```

## Performance Notes

- KDTree construction: O(n log n); single query: O(log n) average
- `cdist` uses concurrent dispatch for matrices larger than 1 000 elements
- All distance functions use BLAS/vDSP via NumericSwift
- Suitable for 2-D and 3-D data; for dimensions > 10 consider brute-force

## See Also

- ``SpatialModule``
- <doc:ClusterModule>
- <doc:GeometryModule>
