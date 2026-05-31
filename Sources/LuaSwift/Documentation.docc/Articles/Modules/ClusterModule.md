# Cluster Module

Machine learning clustering algorithms backed by NumericSwift.

> **Opt-in dependency — disabled by default.** ClusterModule requires the
> `NumericSwift` package. It is compiled only when you set the environment
> variable `LUASWIFT_NUMERICSWIFT=1` at build time:
> ```
> LUASWIFT_NUMERICSWIFT=1 swift build
> ```
> Without that flag the module is not available and none of the functions
> described here exist at runtime.

## Overview

The Cluster module provides unsupervised learning algorithms for grouping data
points. It is available under `math.cluster` (and `luaswift.cluster`) after
calling `luaswift.extend_stdlib()`. Underlying computations use
NumericSwift's Accelerate-optimised implementations.

All cluster label arrays are **1-indexed** (matching Lua convention). DBSCAN
uses `-1` to mark noise points.

## Installation

```swift
// Install all modules (NumericSwift build flag required)
ModuleRegistry.installModules(in: engine)

// Or install just the cluster module
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local cluster = math.cluster
```

## API Reference

### cluster.kmeans(data, k, options?)

Partition `data` into `k` clusters using the k-means algorithm.

**Parameters:**
- `data` — Array of points, where each point is an array of numbers
  (e.g. `{{1,2}, {3,4}, ...}`)
- `k` — Number of clusters (integer)
- `options` (optional) — Table with algorithm parameters:
  - `max_iter` (number) — Maximum iterations (default: `300`)
  - `n_init` (number) — Number of independent initialisations; best result is
    kept (default: `10`)
  - `tol` (number) — Convergence tolerance on centroid movement (default: `1e-4`)
  - `init` (string) — Initialisation strategy: `"k-means++"` (default) or
    `"random"`

**Returns:** Table with fields:
- `labels` — Array of integers (1-indexed cluster assignment for each point)
- `centroids` — Array of centroid coordinate arrays
- `inertia` — Sum of squared distances from each point to its centroid
- `n_iter` — Number of iterations performed

**Example:**

```lua
luaswift.extend_stdlib()
local cluster = math.cluster

local data = {{1,1}, {1.5,2}, {3,4}, {5,7}, {3.5,5}, {4.5,5}, {3.5,4.5}}
local result = cluster.kmeans(data, 2)

print(result.labels)     -- e.g. {1, 1, 2, 2, 2, 2, 2}
print(result.inertia)    -- total within-cluster variance
print(result.n_iter)     -- iterations until convergence

-- Inspect centroids
for i, c in ipairs(result.centroids) do
    print("Centroid " .. i .. ": x=" .. c[1] .. " y=" .. c[2])
end
```

**With options:**

```lua
local result = cluster.kmeans(data, 3, {
    max_iter = 500,
    n_init   = 20,
    tol      = 1e-6,
    init     = "random"
})
```

---

### cluster.hierarchical(data, options?)

Agglomerative (bottom-up) hierarchical clustering.

**Parameters:**
- `data` — Array of points
- `options` (optional) — Table with algorithm parameters:
  - `linkage` (string) — Linkage criterion: `"ward"` (default), `"single"`,
    `"complete"`, or `"average"`
  - `n_clusters` (number) — If provided, the tree is cut to produce this many
    flat clusters and `labels` is populated
  - `distance_threshold` (number) — Alternative cut point; clusters whose
    merge distance exceeds this value are split

**Returns:** Table with fields:
- `linkage_matrix` — Array of merge steps. Each step is a 4-element array
  `{cluster1, cluster2, distance, size}` (cluster IDs are 1-indexed)
- `labels` — Array of cluster assignments (1-indexed), or `nil` when neither
  `n_clusters` nor `distance_threshold` was supplied
- `n_leaves` — Number of original data points (leaves in the tree)

**Example:**

```lua
local data = {{1,1}, {1.2,1.1}, {5,5}, {5.1,4.9}, {9,1}}
local result = cluster.hierarchical(data, {linkage = "ward"})

-- Inspect the merge tree
for i, step in ipairs(result.linkage_matrix) do
    print(string.format("Step %d: merge %d+%d dist=%.3f size=%d",
        i, step[1], step[2], step[3], step[4]))
end

print("Leaves:", result.n_leaves)  -- 5
```

**Flat clusters via n_clusters:**

```lua
local result = cluster.hierarchical(data, {
    linkage    = "ward",
    n_clusters = 3
})
-- result.labels is now populated (1-indexed)
for i, lbl in ipairs(result.labels) do
    print("Point " .. i .. " → cluster " .. lbl)
end
```

**Linkage methods:**

| Value | Criterion |
|-------|-----------|
| `"ward"` | Minimise within-cluster variance (default) |
| `"single"` | Distance of closest pair |
| `"complete"` | Distance of furthest pair |
| `"average"` | Average pairwise distance |

---

### cluster.dbscan(data, options?)

Density-Based Spatial Clustering of Applications with Noise (DBSCAN).

**Parameters:**
- `data` — Array of points
- `options` (optional) — Table with algorithm parameters:
  - `eps` (number) — Neighbourhood radius (default: `0.5`)
  - `min_samples` (number) — Minimum points to form a core region
    (default: `5`)

**Returns:** Table with fields:
- `labels` — Array of cluster assignments. Noise points are labelled `-1`;
  cluster members are labelled `1`, `2`, … (1-indexed)
- `core_samples` — Array of 1-indexed positions of core points in `data`
- `n_clusters` — Number of clusters found (excluding noise)

**Example:**

```lua
local data = {
    {1,2}, {1.1,1.9}, {0.9,2.1},   -- cluster 1
    {5,8}, {5.1,7.9},               -- cluster 2
    {99,99}                          -- noise
}
local result = cluster.dbscan(data, {eps = 0.5, min_samples = 2})

for i, lbl in ipairs(result.labels) do
    if lbl == -1 then
        print("Point " .. i .. " is noise")
    else
        print("Point " .. i .. " → cluster " .. lbl)
    end
end

print("Clusters found:", result.n_clusters)
print("Core point count:", #result.core_samples)
```

---

### cluster.silhouette_score(data, labels)

Compute the mean silhouette coefficient — a measure of how well each point
fits its assigned cluster versus neighbouring clusters.

**Parameters:**
- `data` — Array of points
- `labels` — Array of cluster assignments (matching the 1-indexed convention
  used by `kmeans`, `hierarchical`, and `dbscan`)

**Returns:** Number in `[-1, 1]`. Values near `1` indicate well-separated
clusters; values near `-1` indicate poor assignments.

**Example:**

```lua
local result = cluster.kmeans(data, 3)
local score  = cluster.silhouette_score(data, result.labels)
print("Silhouette score:", score)
```

---

### cluster.elbow_method(data, max_k?)

Run k-means for each `k` from 1 to `max_k` and return the inertia curve.
Use the "elbow" in the curve to choose the optimal number of clusters.

**Parameters:**
- `data` — Array of points
- `max_k` (optional) — Largest `k` to evaluate (default: `10`)

**Returns:** Table with fields:
- `inertias` — Array of inertia values indexed by `k` (position 1 = k=1, etc.)
- `suggested_k` — Heuristically determined optimal `k`

**Example:**

```lua
local result = cluster.elbow_method(data, 8)

for k, inertia in ipairs(result.inertias) do
    print("k=" .. k .. "  inertia=" .. string.format("%.2f", inertia))
end
print("Suggested k:", result.suggested_k)
```

## Complete Example: Customer Segmentation

```lua
luaswift.extend_stdlib()
local cluster = math.cluster

-- Customer data: {age, annual_income, spending_score}
local customers = {
    {25, 35, 39}, {28, 42, 81}, {35, 68, 6}, {45, 59, 3},
    {26, 35, 77}, {30, 42, 76}, {40, 87, 6}, {50, 75, 5},
}

-- Use elbow method to choose k
local elbow = cluster.elbow_method(customers, 6)
print("Suggested segments:", elbow.suggested_k)

-- Cluster with the suggested k
local result = cluster.kmeans(customers, elbow.suggested_k)

-- Evaluate quality
local score = cluster.silhouette_score(customers, result.labels)
print("Silhouette score:", score)

-- Report centroids
for i, c in ipairs(result.centroids) do
    print(string.format("Segment %d — age=%.1f income=%.1f spending=%.1f",
        i, c[1], c[2], c[3]))
end
```

## See Also

- ``ClusterModule``
- <doc:SpatialModule>
