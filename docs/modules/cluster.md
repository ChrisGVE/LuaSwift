# Clustering Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.cluster` | **Global:** `math.cluster` (after extend_stdlib)

High-performance clustering algorithms including k-means, hierarchical clustering, and DBSCAN. All implementations use BLAS/vDSP acceleration for optimal performance.

## K-Means Clustering

Partition data into k clusters by minimizing within-cluster variance. Uses k-means++ initialization by default for better convergence.

```lua
local data = {{1,1}, {1.5,2}, {3,4}, {5,7}, {3.5,5}, {4.5,5}, {3.5,4.5}}
local result = math.cluster.kmeans(data, 2)

print(result.labels)     -- {1, 1, 2, 2, 2, 2, 2}
print(result.centroids)  -- {{1.25, 1.5}, {4.125, 5.125}}
print(result.inertia)    -- sum of squared distances
print(result.n_iter)     -- number of iterations
```

**Options:**
- `init`: initialization method (`"k-means++"` default, `"random"`)
- `max_iter`: maximum iterations (default: 300)
- `tol`: convergence tolerance (default: 1e-4)
- `n_init`: number of runs with different seeds (default: 10, returns best)

```lua
-- Custom options
local result = math.cluster.kmeans(data, 3, {
    init = "random",
    max_iter = 500,
    tol = 1e-5,
    n_init = 20
})
```

## Hierarchical Clustering

Agglomerative hierarchical clustering with multiple linkage methods. Returns linkage matrix compatible with dendrogram visualization.

```lua
local data = {{1,1}, {1.5,2}, {3,4}, {5,7}}
local result = math.cluster.hierarchical(data, {linkage = "ward"})

-- Linkage matrix format: {cluster1_id, cluster2_id, distance, size}
print(result.linkage_matrix)  -- Merge history
print(result.n_leaves)        -- Number of original points
```

**Linkage methods:**
- `ward`: minimize variance increase (default)
- `single`: minimum distance between clusters
- `complete`: maximum distance between clusters
- `average`: average distance between clusters

**Cutting the dendrogram:**

```lua
-- Cut to 2 clusters
local result = math.cluster.hierarchical(data, {
    linkage = "ward",
    n_clusters = 2
})
print(result.labels)  -- {1, 1, 2, 2}

-- Cut at distance threshold
local result = math.cluster.hierarchical(data, {
    linkage = "average",
    distance_threshold = 1.5
})
print(result.labels)  -- Cluster assignments
```

## DBSCAN

Density-based clustering that identifies clusters of arbitrary shape and marks outliers as noise.

```lua
local data = {
    {1,1}, {1.5,1.5}, {2,2},      -- cluster 1
    {5,5}, {5.5,5.5}, {6,6},      -- cluster 2
    {10,10}                        -- noise
}

local result = math.cluster.dbscan(data, {
    eps = 1.5,          -- neighborhood radius
    min_samples = 2     -- minimum points to form cluster
})

print(result.labels)        -- {1, 1, 1, 2, 2, 2, -1}
print(result.core_samples)  -- Indices of core points
print(result.n_clusters)    -- 2
```

**Parameters:**
- `eps`: maximum distance between neighbors (default: 0.5)
- `min_samples`: minimum points to form dense region (default: 5)

**Label interpretation:**
- Positive integers: cluster assignment (1, 2, 3, ...)
- `-1`: noise/outlier points

## Cluster Quality Metrics

### Silhouette Score

Measure cluster cohesion and separation. Values range from -1 (poor) to 1 (excellent).

```lua
local data = {{1,1}, {2,2}, {10,10}, {11,11}}
local labels = {1, 1, 2, 2}

local score = math.cluster.silhouette_score(data, labels)
print(score)  -- ~0.8 (good clustering)
```

**Interpretation:**
- `0.7 - 1.0`: strong structure
- `0.5 - 0.7`: reasonable structure
- `0.25 - 0.5`: weak structure
- `< 0.25`: no substantial structure

### Elbow Method

Find optimal number of clusters by analyzing inertia curve.

```lua
local data = {{1,1}, {2,2}, {3,3}, {10,10}, {11,11}, {12,12}}

local result = math.cluster.elbow_method(data, 6)
print(result.inertias)     -- {82.5, 24.0, 2.0, 0.67, 0.33, 0.0}
print(result.suggested_k)  -- 2
```

**Usage pattern:**
```lua
-- Find optimal k
local elbow = math.cluster.elbow_method(data)
local k = elbow.suggested_k

-- Cluster with optimal k
local result = math.cluster.kmeans(data, k)
```

## Practical Examples

### Customer Segmentation

```lua
-- Customer data: {age, income, spending_score}
local customers = {
    {25, 40000, 39}, {34, 50000, 81}, {26, 43000, 6},
    {35, 51000, 77}, {23, 38000, 40}, {48, 74000, 6},
    {49, 75000, 94}, {24, 39000, 3}, {50, 76000, 72}
}

-- Find optimal clusters
local elbow = math.cluster.elbow_method(customers, 5)
local k = elbow.suggested_k

-- Segment customers
local result = math.cluster.kmeans(customers, k)

for i, label in ipairs(result.labels) do
    print(string.format("Customer %d → Segment %d", i, label))
end

-- Validate quality
local score = math.cluster.silhouette_score(customers, result.labels)
print("Silhouette score:", score)
```

### Anomaly Detection with DBSCAN

```lua
-- Detect outliers in network traffic patterns
local traffic = {
    {100, 50}, {105, 52}, {98, 49},    -- normal
    {102, 51}, {99, 50}, {103, 48},    -- normal
    {500, 200}                         -- anomaly
}

local result = math.cluster.dbscan(traffic, {
    eps = 10,
    min_samples = 3
})

-- Find anomalies
for i, label in ipairs(result.labels) do
    if label == -1 then
        print("Anomaly detected:", traffic[i])
    end
end
```

### Hierarchical Taxonomy

```lua
-- Build document taxonomy
local documents = {
    {0.8, 0.1, 0.1},  -- tech-focused
    {0.7, 0.2, 0.1},  -- tech-focused
    {0.1, 0.8, 0.1},  -- business-focused
    {0.1, 0.7, 0.2},  -- business-focused
    {0.1, 0.1, 0.8},  -- science-focused
    {0.2, 0.1, 0.7}   -- science-focused
}

local result = math.cluster.hierarchical(documents, {
    linkage = "ward",
    n_clusters = 3
})

-- Print taxonomy
print("Linkage matrix (merge history):")
for _, merge in ipairs(result.linkage_matrix) do
    print(string.format("  Merged %d + %d at distance %.3f (size %d)",
        merge[1], merge[2], merge[3], merge[4]))
end

print("\nDocument categories:")
for i, label in ipairs(result.labels) do
    print(string.format("  Doc %d → Category %d", i, label))
end
```

### Comparing Clustering Methods

```lua
local data = generate_test_data()  -- Your data

-- K-means: fast, spherical clusters
local km = math.cluster.kmeans(data, 3)
local km_score = math.cluster.silhouette_score(data, km.labels)

-- Hierarchical: deterministic, hierarchical structure
local hc = math.cluster.hierarchical(data, {
    linkage = "ward",
    n_clusters = 3
})
local hc_score = math.cluster.silhouette_score(data, hc.labels)

-- DBSCAN: arbitrary shapes, handles noise
local db = math.cluster.dbscan(data, {eps = 0.5, min_samples = 5})
local db_score = math.cluster.silhouette_score(data, db.labels)

print("K-means silhouette:", km_score)
print("Hierarchical silhouette:", hc_score)
print("DBSCAN silhouette:", db_score)
```

## Implementation Notes

**BLAS/vDSP Acceleration:**
- Distance computations use `vDSP_vsubD` for vector subtraction
- Euclidean norms use `cblas_dnrm2` for optimal performance
- Centroid calculations use `vDSP_vaddD` and `vDSP_vsdivD`

**K-Means++ Initialization:**
- Chooses first centroid randomly
- Subsequent centroids selected with probability proportional to D(x)²
- Provides faster convergence than random initialization

**Memory Efficiency:**
- DBSCAN caches neighborhoods to avoid repeated distance calculations
- Hierarchical clustering deactivates merged clusters instead of copying arrays
- All algorithms process data in-place where possible

**Label Indexing:**
- All cluster labels are 1-indexed for Lua consistency
- DBSCAN uses -1 for noise (not 0)
- Empty clusters maintain their indices (no gaps)

## Function Reference

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `kmeans(data, k, options)` | `data`: array of points<br>`k`: number of clusters<br>`options`: configuration table | `{labels, centroids, inertia, n_iter}` | K-means clustering with k-means++ initialization |
| `hierarchical(data, options)` | `data`: array of points<br>`options`: linkage method and cut parameters | `{linkage_matrix, labels, n_leaves}` | Agglomerative hierarchical clustering |
| `dbscan(data, options)` | `data`: array of points<br>`options`: eps and min_samples | `{labels, core_samples, n_clusters}` | Density-based clustering |
| `silhouette_score(data, labels)` | `data`: array of points<br>`labels`: cluster assignments | `number` | Cluster quality metric (-1 to 1) |
| `elbow_method(data, max_k)` | `data`: array of points<br>`max_k`: maximum k to test (default: 10) | `{inertias, suggested_k}` | Find optimal number of clusters |
