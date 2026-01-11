# Spatial Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.spatial` | **Global:** `math.spatial` (after extend_stdlib)

Swift-backed spatial data structures and algorithms for nearest neighbor queries, distance computations, Voronoi diagrams, and Delaunay triangulation. All implementations use BLAS/vDSP optimization for maximum performance.

## Function Reference

| Function | Description |
|----------|-------------|
| [distance.euclidean(p1, p2)](#distanceeuclidean) | L2 norm: √(Σ(p1-p2)²) |
| [distance.sqeuclidean(p1, p2)](#distancesqeuclidean) | Squared L2: Σ(p1-p2)² |
| [distance.cityblock(p1, p2)](#distancecityblock) | L1 norm: Σ\|p1-p2\| |
| [distance.chebyshev(p1, p2)](#distancechebyshev) | L∞ norm: max(\|p1-p2\|) |
| [distance.minkowski(p1, p2, p)](#distanceminkowski) | Lp norm: (Σ\|p1-p2\|^p)^(1/p) |
| [distance.cosine(p1, p2)](#distancecosine) | 1 - dot(p1,p2)/(‖p1‖‖p2‖) |
| [distance.correlation(p1, p2)](#distancecorrelation) | 1 - Pearson correlation |
| [cdist(XA, XB, metric?)](#cdist) | Distance matrix between two point sets |
| [pdist(X, metric?)](#pdist) | Condensed distance matrix |
| [squareform(X)](#squareform) | Convert between condensed/square formats |
| [KDTree(points)](#kdtree) | Build k-d tree for nearest neighbor queries |
| [Delaunay(points)](#delaunay) | Compute Delaunay triangulation |
| [Voronoi(points)](#voronoi) | Compute Voronoi diagram |
| [ConvexHull(points)](#convexhull) | Compute 2D convex hull |

## Type Mapping

| Input/Output | Lua Type |
|--------------|----------|
| Point | table (array of numbers) |
| Point set | table (array of points) |
| Distance | number |
| Index | number (1-indexed) |

---

## distance.euclidean

```
math.spatial.distance.euclidean(p1, p2) -> number
```

Compute Euclidean distance (L2 norm) between two points. Uses BLAS acceleration.

**Parameters:**
- `p1` - First point (array of numbers)
- `p2` - Second point (array of numbers, same dimension as p1)

```lua
local p1 = {0, 0}
local p2 = {3, 4}
local d = math.spatial.distance.euclidean(p1, p2)
print(d)  -- 5.0
```

---

## distance.sqeuclidean

```
math.spatial.distance.sqeuclidean(p1, p2) -> number
```

Compute squared Euclidean distance. Faster than euclidean (no square root).

**Parameters:**
- `p1` - First point
- `p2` - Second point

```lua
local d = math.spatial.distance.sqeuclidean({0, 0}, {3, 4})
print(d)  -- 25.0
```

---

## distance.cityblock

```
math.spatial.distance.cityblock(p1, p2) -> number
```

Compute Manhattan/cityblock distance (L1 norm). Uses vDSP acceleration.

**Parameters:**
- `p1` - First point
- `p2` - Second point

```lua
local d = math.spatial.distance.cityblock({0, 0}, {3, 4})
print(d)  -- 7.0 (|3-0| + |4-0|)
```

---

## distance.chebyshev

```
math.spatial.distance.chebyshev(p1, p2) -> number
```

Compute Chebyshev distance (L∞ norm). Uses vDSP acceleration.

**Parameters:**
- `p1` - First point
- `p2` - Second point

```lua
local d = math.spatial.distance.chebyshev({0, 0}, {3, 4})
print(d)  -- 4.0 (max of |3-0|, |4-0|)
```

---

## distance.minkowski

```
math.spatial.distance.minkowski(p1, p2, p) -> number
```

Compute Minkowski distance (generalized Lp norm).

**Parameters:**
- `p1` - First point
- `p2` - Second point
- `p` - Order of the norm (p ≥ 1)

```lua
local d = math.spatial.distance.minkowski({0, 0}, {3, 4}, 3)
print(d)  -- (3^3 + 4^3)^(1/3) ≈ 4.497
```

---

## distance.cosine

```
math.spatial.distance.cosine(p1, p2) -> number
```

Compute cosine distance (1 - cosine similarity). Uses BLAS acceleration.

**Parameters:**
- `p1` - First point
- `p2` - Second point

```lua
local d = math.spatial.distance.cosine({1, 2, 3}, {4, 5, 6})
print(d)  -- 1 - dot(p1,p2)/(||p1|| * ||p2||)
```

---

## distance.correlation

```
math.spatial.distance.correlation(p1, p2) -> number
```

Compute correlation distance (1 - Pearson correlation). Uses BLAS acceleration.

**Parameters:**
- `p1` - First point
- `p2` - Second point

```lua
local d = math.spatial.distance.correlation({1, 2, 3}, {4, 5, 6})
print(d)
```

---

## cdist

```
math.spatial.cdist(XA, XB, metric?) -> table
```

Compute distance matrix between two sets of points.

**Parameters:**
- `XA` - First point set (array of points)
- `XB` - Second point set (array of points)
- `metric` (optional) - Distance metric name (default: "euclidean")

**Returns:** 2D array where `result[i][j]` = distance from `XA[i]` to `XB[j]`

**Supported metrics:** `"euclidean"`, `"sqeuclidean"`, `"cityblock"`, `"manhattan"`, `"chebyshev"`, `"cosine"`, `"correlation"`

```lua
local XA = {{0, 0}, {1, 1}, {2, 2}}
local XB = {{0, 1}, {1, 0}}

-- Compute all pairwise distances (3x2 matrix)
local distances = math.spatial.cdist(XA, XB)
print(distances[1][1])  -- distance from XA[1] to XB[1]

-- With different metric
local manhattan = math.spatial.cdist(XA, XB, "cityblock")
```

**Performance:** Uses concurrent processing for matrices with >1000 elements.

---

## pdist

```
math.spatial.pdist(X, metric?) -> table
```

Compute condensed distance matrix (upper triangle only).

**Parameters:**
- `X` - Point set (array of points)
- `metric` (optional) - Distance metric name (default: "euclidean")

**Returns:** 1D array in condensed format: `[d(0,1), d(0,2), d(0,3), d(1,2), d(1,3), d(2,3)]`

```lua
local points = {{0, 0}, {1, 1}, {2, 2}, {3, 3}}

-- Condensed distance matrix
local condensed = math.spatial.pdist(points)
-- Returns 1D array: [d(0,1), d(0,2), d(0,3), d(1,2), d(1,3), d(2,3)]

print(#condensed)  -- 6 (for 4 points: n*(n-1)/2)
```

---

## squareform

```
math.spatial.squareform(X) -> table
```

Convert between condensed and square distance matrix formats.

**Parameters:**
- `X` - Condensed (1D) or square (2D) distance matrix

**Returns:** Square matrix if input is condensed, condensed array if input is square

```lua
local points = {{0, 0}, {1, 1}, {2, 2}, {3, 3}}
local condensed = math.spatial.pdist(points)

-- Convert to square matrix
local square = math.spatial.squareform(condensed)
print(square[1][2])  -- distance from points[1] to points[2]
print(square[2][1])  -- same (symmetric)

-- Convert back to condensed
local condensed2 = math.spatial.squareform(square)
```

---

## KDTree

```
math.spatial.KDTree(points) -> KDTree
```

Build k-d tree for efficient nearest neighbor queries.

**Parameters:**
- `points` - Array of points (all same dimension)

**Returns:** KDTree object with properties and methods

**Properties:**
- `n` - Number of points
- `dim` - Point dimension

**Methods:**
- `query(point, k)` - Find k nearest neighbors
- `query_radius(point, r)` - Find all points within radius
- `query_pairs(r)` - Find all pairs within distance

```lua
local points = {
    {0, 0},
    {1, 1},
    {2, 2},
    {5, 5},
    {0.5, 0.5}
}

local tree = math.spatial.KDTree(points)
print(tree.n, tree.dim)  -- 5, 2
```

**Performance:** Construction is O(n log n), queries are O(log n) average case.

### tree:query

```
tree:query(point, k) -> indices, distances
```

Find k nearest neighbors to query point.

**Parameters:**
- `point` - Query point
- `k` - Number of neighbors to find

**Returns:** Two arrays: indices (1-indexed) and distances

```lua
local tree = math.spatial.KDTree({{0, 0}, {1, 1}, {2, 2}})

-- Find 2 nearest neighbors
local indices, distances = tree:query({0.5, 0.5}, 2)
print(indices[1], distances[1])  -- closest point

-- Find single nearest neighbor
local idx, dist = tree:query({0, 0}, 1)
```

### tree:query_radius

```
tree:query_radius(point, r) -> indices, distances
```

Find all points within radius r of query point.

**Parameters:**
- `point` - Query point
- `r` - Search radius

**Returns:** Arrays of indices and distances (sorted by distance)

```lua
local tree = math.spatial.KDTree({{0, 0}, {1, 1}, {2, 2}, {5, 5}})

-- Find all points within radius 3
local indices, distances = tree:query_radius({0, 0}, 3)
-- Returns points at distance ≤ 3
```

### tree:query_pairs

```
tree:query_pairs(r) -> pairs
```

Find all pairs of points within distance r.

**Parameters:**
- `r` - Maximum distance

**Returns:** Array of `{idx1, idx2, distance}` tables

```lua
local tree = math.spatial.KDTree({{0, 0}, {1, 1}, {2, 2}})

local pairs = tree:query_pairs(2.0)
for _, pair in ipairs(pairs) do
    print(pair[1], pair[2], pair[3])  -- i, j, distance
end
```

---

## Delaunay

```
math.spatial.Delaunay(points) -> table
```

Compute Delaunay triangulation using Bowyer-Watson algorithm.

**Parameters:**
- `points` - Array of 2D points

**Returns:** Table with fields:
- `points` - Original input points
- `simplices` - Array of triangles as `{v1, v2, v3}` vertex indices (1-indexed)
- `neighbors` - Array of neighbor lists for each simplex

```lua
local points = {
    {0, 0},
    {1, 0},
    {0, 1},
    {1, 1}
}

local tri = math.spatial.Delaunay(points)

-- Access triangulation data
print(#tri.simplices)  -- Number of triangles
for i, simplex in ipairs(tri.simplices) do
    local v1, v2, v3 = simplex[1], simplex[2], simplex[3]
    print(string.format("Triangle %d: vertices %d, %d, %d", i, v1, v2, v3))
end
```

**Edge cases:**
- Collinear points: Returns line segments `{v1, v2}` instead of triangles
- Fewer than 3 points: Returns empty simplices array

```lua
-- Collinear points
local points = {{0, 0}, {1, 1}, {2, 2}}
local tri = math.spatial.Delaunay(points)
-- simplices = {{1, 2}, {2, 3}}  (line segments)
```

**Performance:** O(n log n) expected time.

---

## Voronoi

```
math.spatial.Voronoi(points) -> table
```

Compute Voronoi diagram as dual of Delaunay triangulation.

**Parameters:**
- `points` - Array of 2D points

**Returns:** Table with fields:
- `points` - Original input points
- `vertices` - Voronoi vertices (circumcenters of Delaunay triangles)
- `regions` - For each input point, indices of Voronoi vertices forming its region
- `ridge_vertices` - Edges of Voronoi cells as `{v1, v2}` vertex pairs
- `ridge_points` - Point pairs sharing each ridge

```lua
local points = {
    {0, 0},
    {1, 0},
    {0, 1},
    {1, 1}
}

local vor = math.spatial.Voronoi(points)

-- Voronoi vertices (circumcenters)
print(#vor.vertices)

-- Region for each input point
for i, region in ipairs(vor.regions) do
    print(string.format("Point %d has region with %d vertices", i, #region))
    for _, v_idx in ipairs(region) do
        local vertex = vor.vertices[v_idx]
        print(string.format("  Vertex: (%.2f, %.2f)", vertex[1], vertex[2]))
    end
end

-- Ridge information
for i, ridge in ipairs(vor.ridge_vertices) do
    local p1, p2 = vor.ridge_points[i][1], vor.ridge_points[i][2]
    print(string.format("Ridge %d separates points %d and %d", i, p1, p2))
end
```

**Performance:** O(n log n) expected time.

---

## ConvexHull

```
math.spatial.ConvexHull(points) -> table
```

Compute 2D convex hull using Graham scan algorithm.

**Parameters:**
- `points` - Array of 2D points

**Returns:** Table with fields:
- `points` - Original input points
- `vertices` - Indices of hull vertices (1-indexed, counter-clockwise order)
- `simplices` - Hull edges as `{v1, v2}` pairs

```lua
local points = {
    {0, 0}, {1, 1}, {2, 0}, {0.5, 0.5}, {1, 0}
}

local hull = math.spatial.ConvexHull(points)

print(#hull.vertices)  -- Number of hull vertices

-- Walk the convex hull perimeter
for i, v_idx in ipairs(hull.vertices) do
    local point = points[v_idx]
    print(string.format("Vertex %d: (%.2f, %.2f)", i, point[1], point[2]))
end

-- Or use simplices for edges
for i, edge in ipairs(hull.simplices) do
    local p1 = points[edge[1]]
    local p2 = points[edge[2]]
    print(string.format("Edge %d: (%.2f,%.2f) -> (%.2f,%.2f)",
        i, p1[1], p1[2], p2[1], p2[2]))
end
```

**Performance:** O(n log n).

---

## Examples

### Complete Spatial Analysis Workflow

```lua
-- Sample data
local points = {
    {0, 0}, {1, 0}, {0, 1}, {1, 1}, {0.5, 0.5}
}

-- 1. Distance computations
local d = math.spatial.distance.euclidean(points[1], points[2])
print("Distance:", d)

-- 2. Pairwise distances
local distances = math.spatial.pdist(points)
local square = math.spatial.squareform(distances)

-- 3. Nearest neighbor queries
local tree = math.spatial.KDTree(points)
local indices, dists = tree:query({0.3, 0.3}, 3)
print("3 nearest neighbors:", table.concat(indices, ", "))

-- 4. Triangulation
local tri = math.spatial.Delaunay(points)
print("Triangles:", #tri.simplices)

-- 5. Voronoi diagram
local vor = math.spatial.Voronoi(points)
print("Voronoi regions:", #vor.regions)

-- 6. Convex hull
local hull = math.spatial.ConvexHull(points)
print("Hull vertices:", table.concat(hull.vertices, ", "))
```

### Clustering with KDTree

```lua
-- Find dense regions using radius queries
local points = generate_random_points(1000)  -- your data
local tree = math.spatial.KDTree(points)

local clusters = {}
local visited = {}

for i = 1, #points do
    if not visited[i] then
        local indices = tree:query_radius(points[i], 0.5)
        if #indices > 10 then  -- density threshold
            table.insert(clusters, indices)
            for _, idx in ipairs(indices) do
                visited[idx] = true
            end
        end
    end
end

print("Found", #clusters, "dense clusters")
```

---

## scipy.spatial Compatibility

This module is inspired by `scipy.spatial` with the following equivalents:

| scipy.spatial | luaswift.spatial | Notes |
|---------------|------------------|-------|
| `distance.euclidean` | `distance.euclidean` | BLAS-accelerated |
| `distance.cityblock` | `distance.cityblock` | vDSP-accelerated |
| `distance.chebyshev` | `distance.chebyshev` | vDSP-accelerated |
| `distance.cosine` | `distance.cosine` | BLAS-accelerated |
| `distance.correlation` | `distance.correlation` | BLAS-accelerated |
| `distance.cdist` | `cdist` | Parallel processing |
| `distance.pdist` | `pdist` | Condensed format |
| `distance.squareform` | `squareform` | Bidirectional conversion |
| `KDTree` | `KDTree` | Same API |
| `Delaunay` | `Delaunay` | Bowyer-Watson algorithm |
| `Voronoi` | `Voronoi` | Dual of Delaunay |
| `ConvexHull` | `ConvexHull` | Graham scan |
