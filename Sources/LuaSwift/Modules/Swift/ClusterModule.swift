//
//  ClusterModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed clustering module for LuaSwift.
///
/// Provides clustering algorithms including k-means, hierarchical clustering,
/// and DBSCAN. Since these algorithms need access to user data, they are
/// implemented in Lua for natural integration.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- K-means clustering
/// local data = {{1,1}, {1.5,2}, {3,4}, {5,7}, {3.5,5}, {4.5,5}, {3.5,4.5}}
/// local result = math.cluster.kmeans(data, 2)
/// print(result.labels)     -- cluster assignment for each point
/// print(result.centroids)  -- final cluster centers
/// print(result.inertia)    -- sum of squared distances to centroids
///
/// -- Hierarchical clustering
/// local result = math.cluster.hierarchical(data, {linkage = "ward"})
/// print(result.linkage_matrix)  -- linkage matrix for dendrogram
/// print(result.labels)          -- cluster labels (if n_clusters specified)
///
/// -- DBSCAN
/// local result = math.cluster.dbscan(data, {eps = 0.5, min_samples = 2})
/// print(result.labels)         -- cluster labels (-1 for noise)
/// print(result.core_samples)   -- indices of core samples
/// ```
public struct ClusterModule {

    // MARK: - Registration

    /// Register the cluster module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // All clustering algorithms implemented in Lua for natural data access
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.cluster then luaswift.cluster = {} end

                local cluster = {}

                -- Default parameters
                local DEFAULT_MAX_ITER = 300
                local DEFAULT_TOL = 1e-4
                local DEFAULT_N_INIT = 10

                ----------------------------------------------------------------
                -- Helper functions
                ----------------------------------------------------------------

                -- Euclidean distance between two points (arrays)
                local function euclidean_distance(p1, p2)
                    local sum = 0
                    for i = 1, #p1 do
                        local diff = p1[i] - (p2[i] or 0)
                        sum = sum + diff * diff
                    end
                    return math.sqrt(sum)
                end

                -- Squared Euclidean distance (faster, avoids sqrt)
                local function squared_distance(p1, p2)
                    local sum = 0
                    for i = 1, #p1 do
                        local diff = p1[i] - (p2[i] or 0)
                        sum = sum + diff * diff
                    end
                    return sum
                end

                -- Compute centroid of a set of points
                local function compute_centroid(points)
                    if #points == 0 then return nil end
                    local dim = #points[1]
                    local centroid = {}
                    for d = 1, dim do
                        centroid[d] = 0
                        for i = 1, #points do
                            centroid[d] = centroid[d] + points[i][d]
                        end
                        centroid[d] = centroid[d] / #points
                    end
                    return centroid
                end

                -- Copy a point (array)
                local function copy_point(p)
                    local result = {}
                    for i = 1, #p do result[i] = p[i] end
                    return result
                end

                ----------------------------------------------------------------
                -- kmeans: K-means clustering
                --
                -- Arguments:
                --   data: array of data points (each point is an array of coordinates)
                --   k: number of clusters
                --   options: {
                --     max_iter: maximum iterations (default: 300)
                --     tol: convergence tolerance (default: 1e-4)
                --     n_init: number of random initializations (default: 10)
                --     init: initialization method ("k-means++" or "random", default: "k-means++")
                --     random_state: random seed (optional)
                --   }
                --
                -- Returns:
                --   labels: cluster assignment for each point (1-indexed)
                --   centroids: final cluster centers
                --   inertia: sum of squared distances to nearest centroid
                --   n_iter: number of iterations run
                ----------------------------------------------------------------
                function cluster.kmeans(data, k, options)
                    options = options or {}
                    local max_iter = options.max_iter or DEFAULT_MAX_ITER
                    local tol = options.tol or DEFAULT_TOL
                    local n_init = options.n_init or DEFAULT_N_INIT
                    local init_method = options.init or "k-means++"

                    local n = #data
                    if n == 0 then
                        return {
                            labels = {},
                            centroids = {},
                            inertia = 0,
                            n_iter = 0
                        }
                    end

                    local dim = #data[1]

                    -- K-means++ initialization
                    local function kmeans_plus_plus_init()
                        local centroids = {}
                        -- Choose first centroid randomly
                        local first_idx = math.random(1, n)
                        centroids[1] = copy_point(data[first_idx])

                        for c = 2, k do
                            -- Compute D(x)^2 for each point
                            local distances = {}
                            local total_dist = 0
                            for i = 1, n do
                                local min_dist = math.huge
                                for j = 1, #centroids do
                                    local d = squared_distance(data[i], centroids[j])
                                    if d < min_dist then min_dist = d end
                                end
                                distances[i] = min_dist
                                total_dist = total_dist + min_dist
                            end

                            -- Choose next centroid with probability proportional to D(x)^2
                            local r = math.random() * total_dist
                            local cumsum = 0
                            for i = 1, n do
                                cumsum = cumsum + distances[i]
                                if cumsum >= r then
                                    centroids[c] = copy_point(data[i])
                                    break
                                end
                            end
                            if not centroids[c] then
                                centroids[c] = copy_point(data[n])
                            end
                        end

                        return centroids
                    end

                    -- Random initialization
                    local function random_init()
                        local centroids = {}
                        local used = {}
                        for c = 1, k do
                            local idx
                            repeat
                                idx = math.random(1, n)
                            until not used[idx]
                            used[idx] = true
                            centroids[c] = copy_point(data[idx])
                        end
                        return centroids
                    end

                    -- Run single k-means iteration
                    local function run_kmeans(initial_centroids)
                        local centroids = initial_centroids
                        local labels = {}
                        local prev_inertia = math.huge
                        local n_iter = 0

                        for iter = 1, max_iter do
                            n_iter = iter

                            -- Assignment step: assign each point to nearest centroid
                            local clusters = {}
                            for c = 1, k do clusters[c] = {} end

                            local inertia = 0
                            for i = 1, n do
                                local min_dist = math.huge
                                local best_c = 1
                                for c = 1, k do
                                    local d = squared_distance(data[i], centroids[c])
                                    if d < min_dist then
                                        min_dist = d
                                        best_c = c
                                    end
                                end
                                labels[i] = best_c
                                table.insert(clusters[best_c], data[i])
                                inertia = inertia + min_dist
                            end

                            -- Update step: recompute centroids
                            local new_centroids = {}
                            for c = 1, k do
                                if #clusters[c] > 0 then
                                    new_centroids[c] = compute_centroid(clusters[c])
                                else
                                    -- Empty cluster: keep old centroid or reinitialize
                                    new_centroids[c] = centroids[c]
                                end
                            end

                            -- Check for convergence
                            local max_shift = 0
                            for c = 1, k do
                                local shift = euclidean_distance(centroids[c], new_centroids[c])
                                if shift > max_shift then max_shift = shift end
                            end

                            centroids = new_centroids

                            if max_shift < tol then
                                break
                            end

                            prev_inertia = inertia
                        end

                        -- Compute final inertia
                        local final_inertia = 0
                        for i = 1, n do
                            final_inertia = final_inertia + squared_distance(data[i], centroids[labels[i]])
                        end

                        return labels, centroids, final_inertia, n_iter
                    end

                    -- Run n_init times and keep best result
                    local best_labels, best_centroids, best_inertia, best_n_iter
                    best_inertia = math.huge

                    for run = 1, n_init do
                        local initial_centroids
                        if init_method == "k-means++" then
                            initial_centroids = kmeans_plus_plus_init()
                        else
                            initial_centroids = random_init()
                        end

                        local labels, centroids, inertia, n_iter = run_kmeans(initial_centroids)

                        if inertia < best_inertia then
                            best_labels = labels
                            best_centroids = centroids
                            best_inertia = inertia
                            best_n_iter = n_iter
                        end
                    end

                    return {
                        labels = best_labels,
                        centroids = best_centroids,
                        inertia = best_inertia,
                        n_iter = best_n_iter
                    }
                end

                ----------------------------------------------------------------
                -- hierarchical: Hierarchical/agglomerative clustering
                --
                -- Arguments:
                --   data: array of data points
                --   options: {
                --     linkage: linkage method ("ward", "complete", "average", "single")
                --     n_clusters: number of clusters to form (optional)
                --     distance_threshold: distance threshold for cutting (optional)
                --   }
                --
                -- Returns:
                --   linkage_matrix: n-1 x 4 matrix [cluster1, cluster2, distance, size]
                --   labels: cluster labels (if n_clusters or distance_threshold specified)
                --   n_leaves: number of original data points
                ----------------------------------------------------------------
                function cluster.hierarchical(data, options)
                    options = options or {}
                    local linkage_method = (options.linkage or "ward"):lower()
                    local n_clusters = options.n_clusters
                    local distance_threshold = options.distance_threshold

                    local n = #data
                    if n == 0 then
                        return {
                            linkage_matrix = {},
                            labels = {},
                            n_leaves = 0
                        }
                    end

                    -- Initialize: each point is its own cluster
                    local clusters = {}
                    for i = 1, n do
                        clusters[i] = {
                            id = i,
                            points = {i},  -- indices into original data
                            centroid = copy_point(data[i]),
                            size = 1,
                            active = true
                        }
                    end

                    -- Distance cache between clusters
                    local function cluster_distance(c1, c2)
                        if linkage_method == "single" then
                            -- Minimum distance between any two points
                            local min_d = math.huge
                            for _, i in ipairs(c1.points) do
                                for _, j in ipairs(c2.points) do
                                    local d = squared_distance(data[i], data[j])
                                    if d < min_d then min_d = d end
                                end
                            end
                            return math.sqrt(min_d)

                        elseif linkage_method == "complete" then
                            -- Maximum distance between any two points
                            local max_d = 0
                            for _, i in ipairs(c1.points) do
                                for _, j in ipairs(c2.points) do
                                    local d = squared_distance(data[i], data[j])
                                    if d > max_d then max_d = d end
                                end
                            end
                            return math.sqrt(max_d)

                        elseif linkage_method == "average" then
                            -- Average distance between all pairs
                            local total = 0
                            local count = 0
                            for _, i in ipairs(c1.points) do
                                for _, j in ipairs(c2.points) do
                                    total = total + euclidean_distance(data[i], data[j])
                                    count = count + 1
                                end
                            end
                            return total / count

                        elseif linkage_method == "ward" then
                            -- Ward's method: increase in total within-cluster variance
                            local n1, n2 = c1.size, c2.size
                            local centroid_dist = squared_distance(c1.centroid, c2.centroid)
                            return math.sqrt(2 * n1 * n2 / (n1 + n2) * centroid_dist)
                        end

                        -- Default to Euclidean between centroids
                        return euclidean_distance(c1.centroid, c2.centroid)
                    end

                    -- Build linkage matrix
                    local linkage_matrix = {}
                    local next_cluster_id = n + 1

                    for merge = 1, n - 1 do
                        -- Find closest pair of active clusters
                        local min_dist = math.huge
                        local best_i, best_j = nil, nil

                        for i = 1, #clusters do
                            if clusters[i].active then
                                for j = i + 1, #clusters do
                                    if clusters[j].active then
                                        local d = cluster_distance(clusters[i], clusters[j])
                                        if d < min_dist then
                                            min_dist = d
                                            best_i, best_j = i, j
                                        end
                                    end
                                end
                            end
                        end

                        if not best_i then break end

                        local c1, c2 = clusters[best_i], clusters[best_j]

                        -- Merge clusters
                        local merged_points = {}
                        for _, p in ipairs(c1.points) do table.insert(merged_points, p) end
                        for _, p in ipairs(c2.points) do table.insert(merged_points, p) end

                        -- Compute new centroid
                        local new_size = c1.size + c2.size
                        local new_centroid = {}
                        for d = 1, #c1.centroid do
                            new_centroid[d] = (c1.centroid[d] * c1.size + c2.centroid[d] * c2.size) / new_size
                        end

                        -- Record in linkage matrix [cluster1_id, cluster2_id, distance, size]
                        table.insert(linkage_matrix, {c1.id, c2.id, min_dist, new_size})

                        -- Deactivate merged clusters
                        clusters[best_i].active = false
                        clusters[best_j].active = false

                        -- Create new cluster
                        table.insert(clusters, {
                            id = next_cluster_id,
                            points = merged_points,
                            centroid = new_centroid,
                            size = new_size,
                            active = true
                        })
                        next_cluster_id = next_cluster_id + 1
                    end

                    -- Cut tree to get labels if requested
                    local labels = nil
                    if n_clusters or distance_threshold then
                        -- Find the cut point
                        local cut_idx
                        if n_clusters then
                            cut_idx = n - n_clusters
                        else
                            -- Find first merge above threshold
                            cut_idx = 0
                            for i, merge in ipairs(linkage_matrix) do
                                if merge[3] > distance_threshold then
                                    cut_idx = i - 1
                                    break
                                end
                                cut_idx = i
                            end
                        end

                        -- Assign labels based on cut
                        labels = {}
                        for i = 1, n do labels[i] = i end  -- Initially each point is its own cluster

                        -- Apply merges up to cut point
                        local cluster_map = {}
                        for i = 1, n do cluster_map[i] = i end

                        local next_label = n + 1
                        for i = 1, cut_idx do
                            local merge = linkage_matrix[i]
                            local c1_id, c2_id = merge[1], merge[2]

                            -- Find all points in c1 and c2, assign them to new cluster
                            for p = 1, n do
                                if cluster_map[p] == c1_id or cluster_map[p] == c2_id then
                                    cluster_map[p] = next_label
                                end
                            end
                            next_label = next_label + 1
                        end

                        -- Convert to consecutive labels starting from 1
                        local unique_labels = {}
                        local label_map = {}
                        local next_new_label = 1
                        for i = 1, n do
                            local old_label = cluster_map[i]
                            if not label_map[old_label] then
                                label_map[old_label] = next_new_label
                                next_new_label = next_new_label + 1
                            end
                            labels[i] = label_map[old_label]
                        end
                    end

                    return {
                        linkage_matrix = linkage_matrix,
                        labels = labels,
                        n_leaves = n
                    }
                end

                ----------------------------------------------------------------
                -- dbscan: Density-Based Spatial Clustering of Applications with Noise
                --
                -- Arguments:
                --   data: array of data points
                --   options: {
                --     eps: maximum distance between two samples in same neighborhood (default: 0.5)
                --     min_samples: minimum samples in neighborhood to be core point (default: 5)
                --     metric: distance metric ("euclidean", default: "euclidean")
                --   }
                --
                -- Returns:
                --   labels: cluster labels (-1 for noise points)
                --   core_samples: indices of core sample points
                --   n_clusters: number of clusters found
                ----------------------------------------------------------------
                function cluster.dbscan(data, options)
                    options = options or {}
                    local eps = options.eps or 0.5
                    local min_samples = options.min_samples or 5

                    local n = #data
                    if n == 0 then
                        return {
                            labels = {},
                            core_samples = {},
                            n_clusters = 0
                        }
                    end

                    -- Find neighbors within eps for each point
                    local function get_neighbors(point_idx)
                        local neighbors = {}
                        for i = 1, n do
                            if euclidean_distance(data[point_idx], data[i]) <= eps then
                                table.insert(neighbors, i)
                            end
                        end
                        return neighbors
                    end

                    -- Identify core points
                    local is_core = {}
                    local neighbors_cache = {}
                    for i = 1, n do
                        neighbors_cache[i] = get_neighbors(i)
                        is_core[i] = #neighbors_cache[i] >= min_samples
                    end

                    -- Initialize labels: 0 = unvisited, -1 = noise, >0 = cluster id
                    local labels = {}
                    for i = 1, n do labels[i] = 0 end

                    local current_cluster = 0
                    local core_samples = {}

                    for i = 1, n do
                        if labels[i] ~= 0 then
                            -- Already processed
                        elseif not is_core[i] then
                            -- Not a core point, mark as noise (might be updated later)
                            labels[i] = -1
                        else
                            -- Start a new cluster from this core point
                            current_cluster = current_cluster + 1
                            table.insert(core_samples, i)

                            -- BFS to expand cluster
                            local queue = {i}
                            labels[i] = current_cluster

                            while #queue > 0 do
                                local current = table.remove(queue, 1)
                                local current_neighbors = neighbors_cache[current]

                                for _, neighbor in ipairs(current_neighbors) do
                                    if labels[neighbor] == -1 then
                                        -- Was noise, now border point
                                        labels[neighbor] = current_cluster
                                    elseif labels[neighbor] == 0 then
                                        -- Unvisited
                                        labels[neighbor] = current_cluster

                                        if is_core[neighbor] then
                                            -- Add core point to queue
                                            table.insert(queue, neighbor)
                                            table.insert(core_samples, neighbor)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    return {
                        labels = labels,
                        core_samples = core_samples,
                        n_clusters = current_cluster
                    }
                end

                ----------------------------------------------------------------
                -- silhouette_score: Compute silhouette coefficient
                --
                -- Arguments:
                --   data: array of data points
                --   labels: cluster assignments
                --
                -- Returns:
                --   score: mean silhouette coefficient (-1 to 1, higher is better)
                ----------------------------------------------------------------
                function cluster.silhouette_score(data, labels)
                    local n = #data
                    if n < 2 then return 0 end

                    -- Find unique clusters (excluding noise -1)
                    local clusters = {}
                    for i = 1, n do
                        local label = labels[i]
                        if label > 0 then
                            if not clusters[label] then clusters[label] = {} end
                            table.insert(clusters[label], i)
                        end
                    end

                    -- Need at least 2 clusters
                    local cluster_count = 0
                    for _ in pairs(clusters) do cluster_count = cluster_count + 1 end
                    if cluster_count < 2 then return 0 end

                    local total_silhouette = 0
                    local count = 0

                    for i = 1, n do
                        local label_i = labels[i]
                        if label_i > 0 then
                            -- Compute a(i): mean distance to same cluster
                            local same_cluster = clusters[label_i]
                            local a_i = 0
                            if #same_cluster > 1 then
                                for _, j in ipairs(same_cluster) do
                                    if j ~= i then
                                        a_i = a_i + euclidean_distance(data[i], data[j])
                                    end
                                end
                                a_i = a_i / (#same_cluster - 1)
                            end

                            -- Compute b(i): min mean distance to other clusters
                            local b_i = math.huge
                            for other_label, other_cluster in pairs(clusters) do
                                if other_label ~= label_i then
                                    local mean_dist = 0
                                    for _, j in ipairs(other_cluster) do
                                        mean_dist = mean_dist + euclidean_distance(data[i], data[j])
                                    end
                                    mean_dist = mean_dist / #other_cluster
                                    if mean_dist < b_i then b_i = mean_dist end
                                end
                            end

                            -- Silhouette coefficient
                            local s_i = 0
                            if math.max(a_i, b_i) > 0 then
                                s_i = (b_i - a_i) / math.max(a_i, b_i)
                            end

                            total_silhouette = total_silhouette + s_i
                            count = count + 1
                        end
                    end

                    return count > 0 and (total_silhouette / count) or 0
                end

                ----------------------------------------------------------------
                -- elbow_method: Find optimal k using elbow method
                --
                -- Arguments:
                --   data: array of data points
                --   max_k: maximum k to test (default: 10)
                --
                -- Returns:
                --   inertias: array of inertia values for k=1..max_k
                --   suggested_k: suggested optimal k (simple heuristic)
                ----------------------------------------------------------------
                function cluster.elbow_method(data, max_k)
                    max_k = max_k or 10
                    max_k = math.min(max_k, #data)

                    local inertias = {}
                    for k = 1, max_k do
                        local result = cluster.kmeans(data, k, {n_init = 3})
                        inertias[k] = result.inertia
                    end

                    -- Simple heuristic: find point of maximum curvature
                    -- Using the "elbow" as point where adding more clusters doesn't help much
                    local suggested_k = 1
                    local max_diff_ratio = 0

                    for k = 2, max_k - 1 do
                        local diff1 = inertias[k-1] - inertias[k]
                        local diff2 = inertias[k] - inertias[k+1]
                        if diff2 > 0 then
                            local ratio = diff1 / diff2
                            if ratio > max_diff_ratio then
                                max_diff_ratio = ratio
                                suggested_k = k
                            end
                        end
                    end

                    return {
                        inertias = inertias,
                        suggested_k = suggested_k
                    }
                end

                -- Store the module
                luaswift.cluster = cluster

                -- Also update math.cluster if math table exists
                if math then
                    math.cluster = cluster
                end
                """)
        } catch {
            // Silently fail
        }
    }
}
