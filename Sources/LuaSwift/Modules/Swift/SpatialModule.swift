//
//  SpatialModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed spatial algorithms module for LuaSwift.
///
/// Provides spatial data structures and algorithms including KDTree for
/// nearest neighbor queries, distance computations, Voronoi diagrams,
/// and Delaunay triangulation.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- KDTree for nearest neighbor queries
/// local points = {{0, 0}, {1, 1}, {2, 2}, {5, 5}}
/// local tree = math.spatial.KDTree(points)
/// local nearest = tree:query({0.5, 0.5}, 2)  -- 2 nearest neighbors
/// local in_radius = tree:query_radius({0, 0}, 3)  -- All within radius 3
///
/// -- Distance functions
/// local d = math.spatial.distance.euclidean({0, 0}, {3, 4})  -- 5.0
/// local dists = math.spatial.cdist(set1, set2)  -- pairwise distances
/// local pdists = math.spatial.pdist(points)     -- condensed distance matrix
///
/// -- Voronoi diagram
/// local vor = math.spatial.Voronoi(points)
/// print(vor.vertices, vor.regions, vor.ridge_vertices)
///
/// -- Delaunay triangulation
/// local tri = math.spatial.Delaunay(points)
/// print(tri.simplices, tri.neighbors)
/// ```
public struct SpatialModule {

    // MARK: - Registration

    /// Register the spatial module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.spatial then luaswift.spatial = {} end

                local spatial = {}

                ----------------------------------------------------------------
                -- Distance functions
                ----------------------------------------------------------------
                spatial.distance = {}

                -- Euclidean distance
                function spatial.distance.euclidean(p1, p2)
                    local sum = 0
                    for i = 1, #p1 do
                        local diff = p1[i] - (p2[i] or 0)
                        sum = sum + diff * diff
                    end
                    return math.sqrt(sum)
                end

                -- Squared Euclidean distance (faster, avoids sqrt)
                function spatial.distance.sqeuclidean(p1, p2)
                    local sum = 0
                    for i = 1, #p1 do
                        local diff = p1[i] - (p2[i] or 0)
                        sum = sum + diff * diff
                    end
                    return sum
                end

                -- Manhattan (cityblock) distance
                function spatial.distance.cityblock(p1, p2)
                    local sum = 0
                    for i = 1, #p1 do
                        sum = sum + math.abs(p1[i] - (p2[i] or 0))
                    end
                    return sum
                end

                -- Chebyshev distance (max along any dimension)
                function spatial.distance.chebyshev(p1, p2)
                    local max_diff = 0
                    for i = 1, #p1 do
                        local diff = math.abs(p1[i] - (p2[i] or 0))
                        if diff > max_diff then max_diff = diff end
                    end
                    return max_diff
                end

                -- Minkowski distance (generalized)
                function spatial.distance.minkowski(p1, p2, p)
                    p = p or 2
                    local sum = 0
                    for i = 1, #p1 do
                        sum = sum + math.abs(p1[i] - (p2[i] or 0))^p
                    end
                    return sum^(1/p)
                end

                -- Cosine distance (1 - cosine similarity)
                function spatial.distance.cosine(p1, p2)
                    local dot = 0
                    local norm1 = 0
                    local norm2 = 0
                    for i = 1, #p1 do
                        dot = dot + p1[i] * (p2[i] or 0)
                        norm1 = norm1 + p1[i] * p1[i]
                        norm2 = norm2 + (p2[i] or 0) * (p2[i] or 0)
                    end
                    local denom = math.sqrt(norm1) * math.sqrt(norm2)
                    if denom < 1e-15 then return 1 end
                    return 1 - dot / denom
                end

                -- Correlation distance
                function spatial.distance.correlation(p1, p2)
                    local n = #p1
                    local mean1, mean2 = 0, 0
                    for i = 1, n do
                        mean1 = mean1 + p1[i]
                        mean2 = mean2 + (p2[i] or 0)
                    end
                    mean1, mean2 = mean1 / n, mean2 / n

                    local num, denom1, denom2 = 0, 0, 0
                    for i = 1, n do
                        local d1 = p1[i] - mean1
                        local d2 = (p2[i] or 0) - mean2
                        num = num + d1 * d2
                        denom1 = denom1 + d1 * d1
                        denom2 = denom2 + d2 * d2
                    end
                    local denom = math.sqrt(denom1) * math.sqrt(denom2)
                    if denom < 1e-15 then return 1 end
                    return 1 - num / denom
                end

                -- Get distance function by name
                local function get_distance_func(metric)
                    metric = metric or "euclidean"
                    return spatial.distance[metric] or spatial.distance.euclidean
                end

                ----------------------------------------------------------------
                -- cdist: Compute pairwise distances between two sets
                --
                -- Arguments:
                --   XA: array of m points
                --   XB: array of n points
                --   metric: distance metric (default: "euclidean")
                --
                -- Returns: m x n distance matrix
                ----------------------------------------------------------------
                function spatial.cdist(XA, XB, metric)
                    local dist_func = get_distance_func(metric)
                    local m, n = #XA, #XB
                    local result = {}
                    for i = 1, m do
                        result[i] = {}
                        for j = 1, n do
                            result[i][j] = dist_func(XA[i], XB[j])
                        end
                    end
                    return result
                end

                ----------------------------------------------------------------
                -- pdist: Compute pairwise distances within one set
                --
                -- Arguments:
                --   X: array of n points
                --   metric: distance metric (default: "euclidean")
                --
                -- Returns: condensed distance vector (length n*(n-1)/2)
                ----------------------------------------------------------------
                function spatial.pdist(X, metric)
                    local dist_func = get_distance_func(metric)
                    local n = #X
                    local result = {}
                    local k = 1
                    for i = 1, n - 1 do
                        for j = i + 1, n do
                            result[k] = dist_func(X[i], X[j])
                            k = k + 1
                        end
                    end
                    return result
                end

                ----------------------------------------------------------------
                -- squareform: Convert between condensed and square distance matrix
                ----------------------------------------------------------------
                function spatial.squareform(X)
                    if #X == 0 then return {} end

                    -- Check if it's a condensed vector or square matrix
                    if type(X[1]) == "table" then
                        -- Square to condensed
                        local n = #X
                        local result = {}
                        local k = 1
                        for i = 1, n - 1 do
                            for j = i + 1, n do
                                result[k] = X[i][j]
                                k = k + 1
                            end
                        end
                        return result
                    else
                        -- Condensed to square
                        local m = #X
                        -- n*(n-1)/2 = m => n = (1 + sqrt(1+8m))/2
                        local n = math.floor((1 + math.sqrt(1 + 8 * m)) / 2)
                        local result = {}
                        for i = 1, n do
                            result[i] = {}
                            for j = 1, n do
                                result[i][j] = 0
                            end
                        end
                        local k = 1
                        for i = 1, n - 1 do
                            for j = i + 1, n do
                                result[i][j] = X[k]
                                result[j][i] = X[k]
                                k = k + 1
                            end
                        end
                        return result
                    end
                end

                ----------------------------------------------------------------
                -- KDTree: K-dimensional tree for nearest neighbor queries
                ----------------------------------------------------------------
                local KDTree = {}
                KDTree.__index = KDTree

                function spatial.KDTree(points)
                    local self = setmetatable({}, KDTree)
                    self.points = points
                    self.dim = points[1] and #points[1] or 0
                    self.n = #points

                    -- Build tree
                    local indices = {}
                    for i = 1, self.n do indices[i] = i end
                    self.root = self:_build(indices, 0)

                    return self
                end

                function KDTree:_build(indices, depth)
                    if #indices == 0 then return nil end

                    local axis = (depth % self.dim) + 1

                    -- Sort by axis
                    table.sort(indices, function(a, b)
                        return self.points[a][axis] < self.points[b][axis]
                    end)

                    local mid = math.floor(#indices / 2) + 1
                    local node = {
                        idx = indices[mid],
                        point = self.points[indices[mid]],
                        axis = axis
                    }

                    -- Build subtrees
                    local left_indices = {}
                    for i = 1, mid - 1 do left_indices[i] = indices[i] end
                    local right_indices = {}
                    for i = mid + 1, #indices do
                        right_indices[#right_indices + 1] = indices[i]
                    end

                    node.left = self:_build(left_indices, depth + 1)
                    node.right = self:_build(right_indices, depth + 1)

                    return node
                end

                function KDTree:_distance(p1, p2)
                    local sum = 0
                    for i = 1, self.dim do
                        local diff = p1[i] - p2[i]
                        sum = sum + diff * diff
                    end
                    return math.sqrt(sum)
                end

                -- Query k nearest neighbors
                function KDTree:query(point, k)
                    k = k or 1
                    local best = {}

                    local function insert_best(idx, dist)
                        local pos = #best + 1
                        for i = 1, #best do
                            if dist < best[i].dist then
                                pos = i
                                break
                            end
                        end
                        table.insert(best, pos, {idx = idx, dist = dist})
                        if #best > k then
                            table.remove(best)
                        end
                    end

                    local function search(node)
                        if not node then return end

                        local dist = self:_distance(point, node.point)
                        if #best < k or dist < best[#best].dist then
                            insert_best(node.idx, dist)
                        end

                        local axis = node.axis
                        local diff = point[axis] - node.point[axis]

                        local near = diff < 0 and node.left or node.right
                        local far = diff < 0 and node.right or node.left

                        search(near)

                        -- Check if we need to search the far branch
                        if #best < k or math.abs(diff) < best[#best].dist then
                            search(far)
                        end
                    end

                    search(self.root)

                    -- Return indices and distances
                    local indices = {}
                    local distances = {}
                    for i, b in ipairs(best) do
                        indices[i] = b.idx
                        distances[i] = b.dist
                    end
                    return indices, distances
                end

                -- Query all points within radius
                function KDTree:query_radius(point, r)
                    local result = {}

                    local function search(node)
                        if not node then return end

                        local dist = self:_distance(point, node.point)
                        if dist <= r then
                            table.insert(result, {idx = node.idx, dist = dist})
                        end

                        local axis = node.axis
                        local diff = point[axis] - node.point[axis]

                        -- Always search the near branch if it might contain points
                        if diff - r <= 0 and node.left then
                            search(node.left)
                        end
                        if diff + r >= 0 and node.right then
                            search(node.right)
                        end
                    end

                    search(self.root)

                    -- Sort by distance
                    table.sort(result, function(a, b) return a.dist < b.dist end)

                    local indices = {}
                    local distances = {}
                    for i, r in ipairs(result) do
                        indices[i] = r.idx
                        distances[i] = r.dist
                    end
                    return indices, distances
                end

                -- Query all pairs within distance
                function KDTree:query_pairs(r)
                    local pairs = {}

                    for i = 1, self.n do
                        local indices, distances = self:query_radius(self.points[i], r)
                        for j, idx in ipairs(indices) do
                            if idx > i then
                                table.insert(pairs, {i, idx, distances[j]})
                            end
                        end
                    end

                    return pairs
                end

                ----------------------------------------------------------------
                -- Voronoi: Voronoi diagram computation
                --
                -- NOTE: Full Voronoi diagram computation is complex.
                -- This provides a basic implementation for 2D points.
                ----------------------------------------------------------------
                function spatial.Voronoi(points)
                    local n = #points
                    if n == 0 then
                        return {
                            points = {},
                            vertices = {},
                            regions = {},
                            ridge_vertices = {},
                            ridge_points = {}
                        }
                    end

                    -- For Voronoi, we need Delaunay first (dual relationship)
                    local delaunay = spatial.Delaunay(points)

                    -- Compute circumcenters of Delaunay triangles = Voronoi vertices
                    local vertices = {}
                    local simplex_to_vertex = {}

                    for i, simplex in ipairs(delaunay.simplices) do
                        local p1 = points[simplex[1]]
                        local p2 = points[simplex[2]]
                        local p3 = simplex[3] and points[simplex[3]]

                        if p3 then
                            -- 2D circumcenter
                            local ax, ay = p1[1], p1[2]
                            local bx, by = p2[1], p2[2]
                            local cx, cy = p3[1], p3[2]

                            local d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
                            if math.abs(d) > 1e-10 then
                                local a2 = ax * ax + ay * ay
                                local b2 = bx * bx + by * by
                                local c2 = cx * cx + cy * cy

                                local ux = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / d
                                local uy = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d

                                table.insert(vertices, {ux, uy})
                                simplex_to_vertex[i] = #vertices
                            end
                        end
                    end

                    -- Build regions for each input point
                    local regions = {}
                    for i = 1, n do regions[i] = {} end

                    -- For each Delaunay simplex, its circumcenter belongs to all
                    -- point regions that are part of that simplex
                    for i, simplex in ipairs(delaunay.simplices) do
                        local v_idx = simplex_to_vertex[i]
                        if v_idx then
                            for _, pt_idx in ipairs(simplex) do
                                table.insert(regions[pt_idx], v_idx)
                            end
                        end
                    end

                    -- Build ridge information
                    local ridge_vertices = {}
                    local ridge_points = {}

                    -- Ridges are edges between adjacent Voronoi vertices
                    -- They correspond to shared edges in Delaunay triangulation
                    for i, simplex in ipairs(delaunay.simplices) do
                        local neighbor_idx = delaunay.neighbors[i]
                        local v1 = simplex_to_vertex[i]

                        if neighbor_idx and v1 then
                            for _, n_idx in ipairs(neighbor_idx) do
                                if n_idx > i then  -- Avoid duplicates
                                    local v2 = simplex_to_vertex[n_idx]
                                    if v2 then
                                        -- Find shared edge (the two points shared between simplices)
                                        local shared = {}
                                        for _, p1 in ipairs(simplex) do
                                            for _, p2 in ipairs(delaunay.simplices[n_idx]) do
                                                if p1 == p2 then
                                                    table.insert(shared, p1)
                                                end
                                            end
                                        end
                                        if #shared >= 2 then
                                            table.insert(ridge_vertices, {v1, v2})
                                            table.insert(ridge_points, {shared[1], shared[2]})
                                        end
                                    end
                                end
                            end
                        end
                    end

                    return {
                        points = points,
                        vertices = vertices,
                        regions = regions,
                        ridge_vertices = ridge_vertices,
                        ridge_points = ridge_points
                    }
                end

                ----------------------------------------------------------------
                -- Delaunay: Delaunay triangulation
                --
                -- Uses Bowyer-Watson algorithm for 2D triangulation.
                ----------------------------------------------------------------
                function spatial.Delaunay(points)
                    local n = #points
                    if n < 3 then
                        return {
                            points = points,
                            simplices = {},
                            neighbors = {}
                        }
                    end

                    -- Check if all points are on a line
                    local collinear = true
                    if n >= 3 then
                        local p1, p2, p3 = points[1], points[2], points[3]
                        local cross = (p2[1] - p1[1]) * (p3[2] - p1[2]) -
                                      (p2[2] - p1[2]) * (p3[1] - p1[1])
                        if math.abs(cross) > 1e-10 then
                            collinear = false
                        end
                    end

                    if collinear and n >= 3 then
                        -- All points on a line - return line segments instead
                        local simplices = {}
                        local sorted_indices = {}
                        for i = 1, n do sorted_indices[i] = i end
                        table.sort(sorted_indices, function(a, b)
                            return points[a][1] < points[b][1] or
                                   (points[a][1] == points[b][1] and points[a][2] < points[b][2])
                        end)
                        for i = 1, n - 1 do
                            table.insert(simplices, {sorted_indices[i], sorted_indices[i+1]})
                        end
                        return {
                            points = points,
                            simplices = simplices,
                            neighbors = {}
                        }
                    end

                    -- Find bounding box
                    local min_x, max_x = points[1][1], points[1][1]
                    local min_y, max_y = points[1][2], points[1][2]
                    for i = 2, n do
                        min_x = math.min(min_x, points[i][1])
                        max_x = math.max(max_x, points[i][1])
                        min_y = math.min(min_y, points[i][2])
                        max_y = math.max(max_y, points[i][2])
                    end

                    -- Create super-triangle
                    local dx = max_x - min_x
                    local dy = max_y - min_y
                    local delta = math.max(dx, dy) * 10

                    local p_super = {
                        {min_x - delta, min_y - delta},
                        {min_x + dx / 2, max_y + delta * 2},
                        {max_x + delta, min_y - delta}
                    }

                    -- Extended points array (original + super triangle)
                    local all_points = {}
                    for i = 1, n do all_points[i] = points[i] end
                    for i = 1, 3 do all_points[n + i] = p_super[i] end

                    -- Initial triangle (super triangle)
                    local triangles = {{n + 1, n + 2, n + 3}}

                    -- Helper: check if point is inside circumcircle
                    local function in_circumcircle(px, py, tri)
                        local ax, ay = all_points[tri[1]][1], all_points[tri[1]][2]
                        local bx, by = all_points[tri[2]][1], all_points[tri[2]][2]
                        local cx, cy = all_points[tri[3]][1], all_points[tri[3]][2]

                        local d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
                        if math.abs(d) < 1e-15 then return false end

                        local a2 = ax * ax + ay * ay
                        local b2 = bx * bx + by * by
                        local c2 = cx * cx + cy * cy

                        local ux = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / d
                        local uy = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d

                        local r2 = (ax - ux)^2 + (ay - uy)^2
                        local dist2 = (px - ux)^2 + (py - uy)^2

                        return dist2 < r2
                    end

                    -- Insert each point
                    for i = 1, n do
                        local px, py = points[i][1], points[i][2]
                        local bad_triangles = {}
                        local polygon = {}

                        -- Find all triangles whose circumcircle contains the point
                        for j, tri in ipairs(triangles) do
                            if in_circumcircle(px, py, tri) then
                                table.insert(bad_triangles, j)
                            end
                        end

                        -- Find boundary edges of the hole
                        local edge_count = {}
                        for _, j in ipairs(bad_triangles) do
                            local tri = triangles[j]
                            local edges = {
                                {tri[1], tri[2]},
                                {tri[2], tri[3]},
                                {tri[3], tri[1]}
                            }
                            for _, e in ipairs(edges) do
                                local key = math.min(e[1], e[2]) .. "," .. math.max(e[1], e[2])
                                edge_count[key] = (edge_count[key] or 0) + 1
                            end
                        end

                        -- Boundary edges appear only once
                        for _, j in ipairs(bad_triangles) do
                            local tri = triangles[j]
                            local edges = {
                                {tri[1], tri[2]},
                                {tri[2], tri[3]},
                                {tri[3], tri[1]}
                            }
                            for _, e in ipairs(edges) do
                                local key = math.min(e[1], e[2]) .. "," .. math.max(e[1], e[2])
                                if edge_count[key] == 1 then
                                    table.insert(polygon, e)
                                end
                            end
                        end

                        -- Remove bad triangles (reverse order to preserve indices)
                        table.sort(bad_triangles, function(a, b) return a > b end)
                        for _, j in ipairs(bad_triangles) do
                            table.remove(triangles, j)
                        end

                        -- Create new triangles from boundary edges to the new point
                        for _, e in ipairs(polygon) do
                            table.insert(triangles, {e[1], e[2], i})
                        end
                    end

                    -- Remove triangles that include super-triangle vertices
                    local final_triangles = {}
                    for _, tri in ipairs(triangles) do
                        local valid = true
                        for _, v in ipairs(tri) do
                            if v > n then
                                valid = false
                                break
                            end
                        end
                        if valid then
                            table.insert(final_triangles, tri)
                        end
                    end

                    -- Build neighbor information
                    local neighbors = {}
                    for i = 1, #final_triangles do
                        neighbors[i] = {}
                    end

                    for i = 1, #final_triangles do
                        local tri_i = final_triangles[i]
                        for j = i + 1, #final_triangles do
                            local tri_j = final_triangles[j]
                            -- Count shared vertices
                            local shared = 0
                            for _, vi in ipairs(tri_i) do
                                for _, vj in ipairs(tri_j) do
                                    if vi == vj then shared = shared + 1 end
                                end
                            end
                            if shared == 2 then
                                table.insert(neighbors[i], j)
                                table.insert(neighbors[j], i)
                            end
                        end
                    end

                    return {
                        points = points,
                        simplices = final_triangles,
                        neighbors = neighbors
                    }
                end

                ----------------------------------------------------------------
                -- ConvexHull: Compute convex hull of points
                --
                -- Uses Graham scan algorithm for 2D points.
                ----------------------------------------------------------------
                function spatial.ConvexHull(points)
                    local n = #points
                    if n < 3 then
                        local vertices = {}
                        for i = 1, n do vertices[i] = i end
                        return {
                            points = points,
                            vertices = vertices,
                            simplices = {}
                        }
                    end

                    -- Find lowest point (and leftmost if tie)
                    local start_idx = 1
                    for i = 2, n do
                        if points[i][2] < points[start_idx][2] or
                           (points[i][2] == points[start_idx][2] and points[i][1] < points[start_idx][1]) then
                            start_idx = i
                        end
                    end

                    local start = points[start_idx]

                    -- Sort by polar angle
                    local indices = {}
                    for i = 1, n do
                        if i ~= start_idx then
                            table.insert(indices, i)
                        end
                    end

                    table.sort(indices, function(a, b)
                        local angle_a = math.atan(points[a][2] - start[2], points[a][1] - start[1])
                        local angle_b = math.atan(points[b][2] - start[2], points[b][1] - start[1])
                        if math.abs(angle_a - angle_b) < 1e-10 then
                            -- Same angle, sort by distance
                            local dist_a = (points[a][1] - start[1])^2 + (points[a][2] - start[2])^2
                            local dist_b = (points[b][1] - start[1])^2 + (points[b][2] - start[2])^2
                            return dist_a < dist_b
                        end
                        return angle_a < angle_b
                    end)

                    -- Graham scan
                    local function ccw(p1, p2, p3)
                        return (p2[1] - p1[1]) * (p3[2] - p1[2]) - (p2[2] - p1[2]) * (p3[1] - p1[1])
                    end

                    local hull = {start_idx}
                    for _, idx in ipairs(indices) do
                        while #hull >= 2 and ccw(points[hull[#hull-1]], points[hull[#hull]], points[idx]) <= 0 do
                            table.remove(hull)
                        end
                        table.insert(hull, idx)
                    end

                    -- Build simplices (edges)
                    local simplices = {}
                    for i = 1, #hull do
                        local next_i = (i % #hull) + 1
                        table.insert(simplices, {hull[i], hull[next_i]})
                    end

                    return {
                        points = points,
                        vertices = hull,
                        simplices = simplices
                    }
                end

                -- Store the module
                luaswift.spatial = spatial

                -- Also update math.spatial if math table exists
                if math then
                    math.spatial = spatial
                end
                """)
        } catch {
            // Silently fail
        }
    }
}
