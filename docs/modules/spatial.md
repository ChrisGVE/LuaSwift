# Spatial Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.spatial` | **Global:** `math.spatial` (after extend_stdlib)

Swift-backed spatial data structures and algorithms for nearest neighbor queries, distance computations, Voronoi diagrams, and Delaunay triangulation. All implementations use BLAS/vDSP optimization for maximum performance.

## Distance Functions

Compute distances between points using various metrics. All functions use hardware-accelerated vector operations.

```lua
local p1 = {0, 0}
local p2 = {3, 4}

-- Euclidean distance (L2 norm)
local d = math.spatial.distance.euclidean(p1, p2)  -- 5.0

-- Squared Euclidean (faster, no sqrt)
local d2 = math.spatial.distance.sqeuclidean(p1, p2)  -- 25.0

-- Manhattan distance (L1 norm)
local d3 = math.spatial.distance.cityblock(p1, p2)  -- 7.0

-- Chebyshev distance (L-infinity norm)
local d4 = math.spatial.distance.chebyshev(p1, p2)  -- 4.0

-- Minkowski distance (generalized Lp norm)
local d5 = math.spatial.distance.minkowski(p1, p2, 3)  -- p=3

-- Cosine distance (1 - cosine similarity)
local d6 = math.spatial.distance.cosine({1, 2, 3}, {4, 5, 6})

-- Correlation distance (1 - Pearson correlation)
local d7 = math.spatial.distance.correlation({1, 2, 3}, {4, 5, 6})
```

## Pairwise Distances

Compute all pairwise distances between sets of points.

### cdist: Distance Matrix Between Two Sets

```lua
local XA = {{0, 0}, {1, 1}, {2, 2}}
local XB = {{0, 1}, {1, 0}}

-- Compute all pairwise distances (3x2 matrix)
local distances = math.spatial.cdist(XA, XB)
-- distances[i][j] = distance from XA[i] to XB[j]

-- With different metric
local distances = math.spatial.cdist(XA, XB, "cityblock")
```

Supported metrics: `"euclidean"` (default), `"sqeuclidean"`, `"cityblock"`, `"manhattan"`, `"chebyshev"`, `"cosine"`, `"correlation"`

### pdist: Condensed Distance Matrix

```lua
local points = {{0, 0}, {1, 1}, {2, 2}, {3, 3}}

-- Condensed distance matrix (upper triangle)
local condensed = math.spatial.pdist(points)
-- Returns 1D array: [d(0,1), d(0,2), d(0,3), d(1,2), d(1,3), d(2,3)]

-- Convert to square matrix
local square = math.spatial.squareform(condensed)
-- square[i][j] = distance from points[i] to points[j]

-- Convert back to condensed
local condensed2 = math.spatial.squareform(square)
```

## KDTree: Nearest Neighbor Queries

Efficient spatial data structure for k-nearest neighbor and radius queries.

### Building a KDTree

```lua
local points = {
    {0, 0},
    {1, 1},
    {2, 2},
    {5, 5},
    {0.5, 0.5}
}

local tree = math.spatial.KDTree(points)
print(tree.n, tree.dim)  -- 5 points, 2 dimensions
```

### k-Nearest Neighbors

```lua
-- Find 2 nearest neighbors to query point
local indices, distances = tree:query({0.5, 0.5}, 2)
-- indices = {5, 2}  (1-indexed)
-- distances = {0.0, 0.707...}

-- Find single nearest neighbor
local idx, dist = tree:query({0, 0}, 1)
```

### Radius Queries

```lua
-- Find all points within radius 3
local indices, distances = tree:query_radius({0, 0}, 3)
-- Returns all points sorted by distance

-- Find all pairs of points within distance r
local pairs = tree:query_pairs(2.0)
-- pairs[i] = {idx1, idx2, distance}
```

## Delaunay Triangulation

Compute Delaunay triangulation using the Bowyer-Watson algorithm.

```lua
local points = {
    {0, 0},
    {1, 0},
    {0, 1},
    {1, 1}
}

local tri = math.spatial.Delaunay(points)

-- Access triangulation data
print(tri.points)      -- Original points
print(tri.simplices)   -- Triangles as vertex indices (1-indexed)
-- simplices[i] = {v1, v2, v3} where v1, v2, v3 are indices into points

print(tri.neighbors)   -- Neighbor information
-- neighbors[i] = {n1, n2, ...} indices of adjacent triangles
```

### Handling Edge Cases

```lua
-- Collinear points: returns line segments instead of triangles
local points = {{0, 0}, {1, 1}, {2, 2}}
local tri = math.spatial.Delaunay(points)
-- simplices = {{1, 2}, {2, 3}}  (line segments)

-- Fewer than 3 points
local tri = math.spatial.Delaunay({{0, 0}, {1, 1}})
-- Returns empty simplices
```

## Voronoi Diagrams

Compute Voronoi diagram as dual of Delaunay triangulation.

```lua
local points = {
    {0, 0},
    {1, 0},
    {0, 1},
    {1, 1}
}

local vor = math.spatial.Voronoi(points)

-- Voronoi vertices (circumcenters of Delaunay triangles)
print(vor.vertices)    -- Array of {x, y} points

-- Region for each input point
print(vor.regions)     -- regions[i] = indices of Voronoi vertices
-- regions[i] = {v1, v2, v3, ...} vertices forming polygon around points[i]

-- Ridge information (edges of Voronoi cells)
print(vor.ridge_vertices)  -- {{v1, v2}, ...} vertex pairs
print(vor.ridge_points)    -- {{p1, p2}, ...} point pairs sharing ridge

print(vor.points)      -- Original input points
```

### Practical Example: Nearest Site

```lua
-- Find which input point owns each region
local vor = math.spatial.Voronoi(points)

for i, region in ipairs(vor.regions) do
    print("Point", i, "has region with vertices:", region)
    -- Plot polygon using vor.vertices[region[j]]
end
```

## Convex Hull

Compute 2D convex hull using Graham scan algorithm.

```lua
local points = {
    {0, 0}, {1, 1}, {2, 0}, {0.5, 0.5}, {1, 0}
}

local hull = math.spatial.ConvexHull(points)

print(hull.vertices)   -- Indices of hull vertices (1-indexed)
-- vertices = {1, 5, 3, 2} (ordered counter-clockwise)

print(hull.simplices)  -- Hull edges
-- simplices[i] = {v1, v2} edge from hull.vertices[i] to next vertex

print(hull.points)     -- Original input points
```

### Traversing the Hull

```lua
local hull = math.spatial.ConvexHull(points)

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

## Performance Notes

- All distance functions use BLAS (cblas_*) or vDSP for hardware acceleration
- `cdist` uses concurrent processing for matrices with >1000 elements
- KDTree construction is O(n log n), queries are O(log n) average case
- Delaunay/Voronoi use Bowyer-Watson algorithm: O(n log n) expected time
- Convex hull uses Graham scan: O(n log n)

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

## Function Reference

### Distance Metrics

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `distance.euclidean(p1, p2)` | Two points | number | L2 norm: √(Σ(p1-p2)²) |
| `distance.sqeuclidean(p1, p2)` | Two points | number | Squared L2: Σ(p1-p2)² |
| `distance.cityblock(p1, p2)` | Two points | number | L1 norm: Σ\|p1-p2\| |
| `distance.chebyshev(p1, p2)` | Two points | number | L∞ norm: max(\|p1-p2\|) |
| `distance.minkowski(p1, p2, p)` | Two points, p value | number | Lp norm: (Σ\|p1-p2\|^p)^(1/p) |
| `distance.cosine(p1, p2)` | Two points | number | 1 - dot(p1,p2)/(‖p1‖‖p2‖) |
| `distance.correlation(p1, p2)` | Two points | number | 1 - Pearson correlation |

### Pairwise Distance Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `cdist(XA, XB [, metric])` | Two point sets, metric name | 2D array | Distance matrix XA×XB |
| `pdist(X [, metric])` | Point set, metric name | 1D array | Condensed distance matrix |
| `squareform(X)` | Condensed or square matrix | Converted form | Convert between formats |

### KDTree Methods

| Method | Arguments | Returns | Description |
|--------|-----------|---------|-------------|
| `KDTree(points)` | Array of points | KDTree object | Build k-d tree |
| `tree:query(point, k)` | Query point, k | indices, distances | k nearest neighbors |
| `tree:query_radius(point, r)` | Query point, radius | indices, distances | Points within radius |
| `tree:query_pairs(r)` | Radius | Array of {i,j,d} | All pairs within radius |

### Geometric Algorithms

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `Delaunay(points)` | Array of points | Table with simplices | Delaunay triangulation |
| `Voronoi(points)` | Array of points | Table with vertices, regions | Voronoi diagram |
| `ConvexHull(points)` | Array of points | Table with vertices, simplices | 2D convex hull |

### Return Structures

**Delaunay result:**
- `points`: Original input points
- `simplices`: Array of triangles `{v1, v2, v3}` (1-indexed)
- `neighbors`: Array of neighbor lists for each simplex

**Voronoi result:**
- `points`: Original input points
- `vertices`: Voronoi vertices (circumcenters)
- `regions`: Vertex indices for each input point's region
- `ridge_vertices`: Edges of Voronoi cells
- `ridge_points`: Point pairs sharing each ridge

**ConvexHull result:**
- `points`: Original input points
- `vertices`: Indices of hull vertices (counter-clockwise)
- `simplices`: Hull edges `{v1, v2}`
