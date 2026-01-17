# Cluster Module

Machine learning clustering algorithms.

## Overview

The Cluster module provides unsupervised learning algorithms for grouping data points. Available under `math.cluster` after calling `luaswift.extend_stdlib()`.

## Installation

```swift
ModuleRegistry.installMathModule(in: engine)
```

```lua
luaswift.extend_stdlib()
local cluster = math.cluster
```

## K-Means Clustering

### cluster.kmeans(data, k, options?)
Partition data into k clusters.

```lua
local array = require("luaswift.array")

-- 2D data points
local data = array.array({
    {1, 2}, {1.5, 1.8}, {5, 8}, {8, 8},
    {1, 0.6}, {9, 11}, {8, 2}, {10, 2}
})

local result = cluster.kmeans(data, 3)  -- 3 clusters

print("Labels:", result.labels)         -- Cluster assignment for each point
print("Centers:", result.centers)       -- Cluster centroids
print("Inertia:", result.inertia)       -- Sum of squared distances
```

### Options

```lua
local result = cluster.kmeans(data, k, {
    max_iter = 300,    -- Maximum iterations
    n_init = 10,       -- Number of initializations
    tol = 1e-4,        -- Convergence tolerance
    random_state = 42  -- Random seed
})
```

## Hierarchical Clustering

### cluster.hierarchical(data, method?, metric?)
Hierarchical/agglomerative clustering.

```lua
local result = cluster.hierarchical(data, "ward", "euclidean")

-- Get linkage matrix
print(result.linkage)

-- Cut tree to get k clusters
local labels = result:cut(3)  -- 3 clusters
```

### Linkage Methods

- `"ward"` - Minimize variance (default)
- `"single"` - Minimum distance
- `"complete"` - Maximum distance
- `"average"` - Average distance

## DBSCAN

### cluster.dbscan(data, eps, min_samples)
Density-based spatial clustering.

```lua
local result = cluster.dbscan(data, 0.5, 2)

print("Labels:", result.labels)  -- -1 for outliers
print("Core samples:", result.core_sample_indices)
print("Components:", result.n_clusters)
```

## Gaussian Mixture Models

### cluster.gmm(data, n_components, options?)
Fit Gaussian mixture model.

```lua
local result = cluster.gmm(data, 3)

print("Means:", result.means)
print("Covariances:", result.covariances)
print("Weights:", result.weights)

-- Predict cluster probabilities
local probs = result:predict_proba(new_point)
```

## Evaluation Metrics

### cluster.silhouette_score(data, labels)
Compute mean silhouette coefficient (higher is better).

```lua
local score = cluster.silhouette_score(data, result.labels)
print("Silhouette score:", score)  -- Range: [-1, 1]
```

## Example: Customer Segmentation

```lua
local array = require("luaswift.array")
local cluster = math.cluster

-- Customer data: [age, income, spending_score]
local customers = array.array({
    {25, 35, 39}, {28, 42, 81}, {35, 68, 6}, {45, 59, 3},
    {26, 35, 77}, {30, 42, 76}, {40, 87, 6}, {50, 75, 5},
    -- ... more customers
})

-- Find 4 segments
local result = cluster.kmeans(customers, 4)

-- Analyze segments
for i = 1, 4 do
    local center = result.centers:get(i)
    print("Segment " .. i .. ": Age=" .. center:get(1) ..
          ", Income=" .. center:get(2) ..
          ", Spending=" .. center:get(3))
end
```

## See Also

- ``ClusterModule``
- <doc:ArrayModule>
- <doc:Modules/SpatialModule>
