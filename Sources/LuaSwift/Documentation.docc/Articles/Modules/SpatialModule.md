# Spatial Module

Spatial data structures and computational geometry.

## Overview

The Spatial module provides efficient spatial data structures (KDTree) and computational geometry algorithms (Voronoi, Delaunay). Available under `math.spatial` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local spatial = math.spatial
```

## KDTree

### spatial.kdtree(points)
Construct a k-d tree for efficient nearest neighbor queries.

```lua
local array = require("luaswift.array")

-- 2D points
local points = array.array({
    {0, 0}, {1, 1}, {2, 2}, {3, 3},
    {0, 1}, {1, 0}, {2, 1}, {1, 2}
})

local tree = spatial.kdtree(points)
```

### tree:query(point, k?)
Find k nearest neighbors.

```lua
-- Find nearest neighbor to (1.5, 1.5)
local distances, indices = tree:query({1.5, 1.5}, 1)
print("Nearest point index:", indices[1])
print("Distance:", distances[1])

-- Find 3 nearest neighbors
local dists, idxs = tree:query({1.5, 1.5}, 3)
```

### tree:query_radius(point, radius)
Find all points within radius.

```lua
local indices = tree:query_radius({1, 1}, 1.5)
print("Points within radius:", #indices)
```

## Voronoi Diagrams

### spatial.voronoi(points)
Compute Voronoi diagram.

```lua
local points = array.array({
    {0, 0}, {1, 0}, {0, 1}, {1, 1}
})

local vor = spatial.voronoi(points)

print("Vertices:", vor.vertices)     -- Voronoi vertices
print("Regions:", vor.regions)       -- Point regions
print("Ridge points:", vor.ridge_points)
```

## Delaunay Triangulation

### spatial.delaunay(points)
Compute Delaunay triangulation.

```lua
local points = array.array({
    {0, 0}, {1, 0}, {0.5, 0.866},
    {1, 1}, {0, 1}
})

local tri = spatial.delaunay(points)

print("Simplices:", tri.simplices)   -- Triangle indices
print("Neighbors:", tri.neighbors)   -- Adjacent triangles
```

### tri:find_simplex(point)
Find triangle containing point.

```lua
local simplex_idx = tri:find_simplex({0.5, 0.5})
print("Point is in triangle:", simplex_idx)
```

## Convex Hull

### spatial.convex_hull(points)
Compute convex hull of points.

```lua
local points = array.array({
    {0, 0}, {1, 0}, {1, 1}, {0, 1},
    {0.5, 0.5}  -- Interior point
})

local hull = spatial.convex_hull(points)
print("Hull vertices:", hull.vertices)  -- Indices of hull points
print("Area:", hull.area)
```

## Distance Matrices

### spatial.distance_matrix(points1, points2?)
Compute pairwise distances.

```lua
local points1 = array.array({{0, 0}, {1, 1}})
local points2 = array.array({{0, 1}, {1, 0}})

local dists = spatial.distance_matrix(points1, points2)
-- dists[i][j] = distance from points1[i] to points2[j]
```

## Applications

### Nearest Neighbor Search

```lua
-- Find k nearest stores to each customer
local stores = array.array({{0, 0}, {5, 5}, {10, 0}})
local customers = array.array({{1, 1}, {6, 4}, {8, 1}})

local tree = spatial.kdtree(stores)

for i = 1, customers:shape()[1] do
    local customer = {customers:get(i, 1), customers:get(i, 2)}
    local dists, indices = tree:query(customer, 2)
    print("Customer " .. i .. " nearest stores:", indices[1], indices[2])
end
```

### Density Estimation

```lua
-- Count neighbors within radius for density map
local data = array.random.rand({100, 2}) * 10

local tree = spatial.kdtree(data)

local densities = {}
for i = 1, 100 do
    local point = {data:get(i, 1), data:get(i, 2)}
    local neighbors = tree:query_radius(point, 1.0)
    densities[i] = #neighbors
end
```

### Spatial Interpolation

```lua
-- Interpolate values using nearest neighbors
local points = array.array({{0, 0}, {1, 0}, {0, 1}, {1, 1}})
local values = {0, 1, 1, 2}

local tree = spatial.kdtree(points)

local function interpolate(x, y, k)
    local dists, indices = tree:query({x, y}, k)

    -- Inverse distance weighting
    local sum_val, sum_weight = 0, 0
    for i = 1, k do
        local weight = 1 / (dists[i] + 1e-10)
        sum_val = sum_val + weight * values[indices[i]]
        sum_weight = sum_weight + weight
    end

    return sum_val / sum_weight
end

print("Value at (0.5, 0.5):", interpolate(0.5, 0.5, 4))
```

### Mesh Generation

```lua
-- Generate mesh for finite element analysis
local boundary_points = array.array({
    {0, 0}, {1, 0}, {1, 1}, {0, 1}
})

local tri = spatial.delaunay(boundary_points)

-- Use triangulation for FEM
for i = 1, tri.simplices:shape()[1] do
    local v1 = tri.simplices:get(i, 1)
    local v2 = tri.simplices:get(i, 2)
    local v3 = tri.simplices:get(i, 3)
    -- Process triangle v1, v2, v3
end
```

## Performance Notes

- KDTree construction: O(n log n)
- KDTree query: O(log n) average case
- Suitable for 2D and 3D data
- For higher dimensions (>10), use ball tree or brute force

## See Also

- ``SpatialModule``
- <doc:Modules/ClusterModule>
- <doc:GeometryModule>
