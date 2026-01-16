//
//  SpatialModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
import Foundation
import Accelerate
import NumericSwift

/// Swift-backed spatial algorithms module for LuaSwift.
///
/// Provides spatial data structures and algorithms including KDTree for
/// nearest neighbor queries, distance computations, Voronoi diagrams,
/// and Delaunay triangulation.
///
/// All algorithms are implemented in Swift with BLAS/vDSP optimization
/// for maximum performance. Only Lua API entry points are in Lua.
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
        // Register Swift callbacks for distance functions
        engine.registerFunction(name: "_luaswift_spatial_euclidean", callback: euclideanCallback)
        engine.registerFunction(name: "_luaswift_spatial_sqeuclidean", callback: sqeuclideanCallback)
        engine.registerFunction(name: "_luaswift_spatial_cityblock", callback: cityblockCallback)
        engine.registerFunction(name: "_luaswift_spatial_chebyshev", callback: chebyshevCallback)
        engine.registerFunction(name: "_luaswift_spatial_minkowski", callback: minkowskiCallback)
        engine.registerFunction(name: "_luaswift_spatial_cosine", callback: cosineCallback)
        engine.registerFunction(name: "_luaswift_spatial_correlation", callback: correlationCallback)

        // Register Swift callbacks for batch distance functions
        engine.registerFunction(name: "_luaswift_spatial_cdist", callback: cdistCallback)
        engine.registerFunction(name: "_luaswift_spatial_pdist", callback: pdistCallback)
        engine.registerFunction(name: "_luaswift_spatial_squareform", callback: squareformCallback)

        // Register Swift callbacks for spatial data structures
        engine.registerFunction(name: "_luaswift_spatial_kdtree_build", callback: kdtreeBuildCallback)
        engine.registerFunction(name: "_luaswift_spatial_kdtree_query", callback: kdtreeQueryCallback)
        engine.registerFunction(name: "_luaswift_spatial_kdtree_query_radius", callback: kdtreeQueryRadiusCallback)
        engine.registerFunction(name: "_luaswift_spatial_kdtree_query_pairs", callback: kdtreeQueryPairsCallback)

        // Register Swift callbacks for geometric algorithms
        engine.registerFunction(name: "_luaswift_spatial_delaunay", callback: delaunayCallback)
        engine.registerFunction(name: "_luaswift_spatial_voronoi", callback: voronoiCallback)
        engine.registerFunction(name: "_luaswift_spatial_convexhull", callback: convexhullCallback)

        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.spatial then luaswift.spatial = {} end

                local spatial = {}

                ----------------------------------------------------------------
                -- Distance functions (Swift-backed with BLAS)
                ----------------------------------------------------------------
                spatial.distance = {}

                function spatial.distance.euclidean(p1, p2)
                    return _luaswift_spatial_euclidean(p1, p2)
                end

                function spatial.distance.sqeuclidean(p1, p2)
                    return _luaswift_spatial_sqeuclidean(p1, p2)
                end

                function spatial.distance.cityblock(p1, p2)
                    return _luaswift_spatial_cityblock(p1, p2)
                end

                function spatial.distance.chebyshev(p1, p2)
                    return _luaswift_spatial_chebyshev(p1, p2)
                end

                function spatial.distance.minkowski(p1, p2, p)
                    return _luaswift_spatial_minkowski(p1, p2, p or 2)
                end

                function spatial.distance.cosine(p1, p2)
                    return _luaswift_spatial_cosine(p1, p2)
                end

                function spatial.distance.correlation(p1, p2)
                    return _luaswift_spatial_correlation(p1, p2)
                end

                ----------------------------------------------------------------
                -- cdist: Compute pairwise distances between two sets (Swift-backed)
                ----------------------------------------------------------------
                function spatial.cdist(XA, XB, metric)
                    return _luaswift_spatial_cdist(XA, XB, metric or "euclidean")
                end

                ----------------------------------------------------------------
                -- pdist: Compute pairwise distances within one set (Swift-backed)
                ----------------------------------------------------------------
                function spatial.pdist(X, metric)
                    return _luaswift_spatial_pdist(X, metric or "euclidean")
                end

                ----------------------------------------------------------------
                -- squareform: Convert between condensed and square distance matrix
                ----------------------------------------------------------------
                function spatial.squareform(X)
                    return _luaswift_spatial_squareform(X)
                end

                ----------------------------------------------------------------
                -- KDTree: K-dimensional tree (Swift-backed)
                ----------------------------------------------------------------
                local KDTree = {}
                KDTree.__index = KDTree

                function spatial.KDTree(points)
                    local self = setmetatable({}, KDTree)
                    self._handle = _luaswift_spatial_kdtree_build(points)
                    self.points = points
                    self.n = #points
                    self.dim = points[1] and #points[1] or 0
                    return self
                end

                function KDTree:query(point, k)
                    k = k or 1
                    local result = _luaswift_spatial_kdtree_query(self._handle, point, k)
                    return result[1], result[2]  -- indices, distances
                end

                function KDTree:query_radius(point, r)
                    local result = _luaswift_spatial_kdtree_query_radius(self._handle, point, r)
                    return result[1], result[2]  -- indices, distances
                end

                function KDTree:query_pairs(r)
                    return _luaswift_spatial_kdtree_query_pairs(self._handle, r)
                end

                ----------------------------------------------------------------
                -- Voronoi: Voronoi diagram computation (Swift-backed)
                ----------------------------------------------------------------
                function spatial.Voronoi(points)
                    return _luaswift_spatial_voronoi(points)
                end

                ----------------------------------------------------------------
                -- Delaunay: Delaunay triangulation (Swift-backed)
                ----------------------------------------------------------------
                function spatial.Delaunay(points)
                    return _luaswift_spatial_delaunay(points)
                end

                ----------------------------------------------------------------
                -- ConvexHull: Convex hull computation (Swift-backed)
                ----------------------------------------------------------------
                function spatial.ConvexHull(points)
                    return _luaswift_spatial_convexhull(points)
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

    // MARK: - Distance Function Callbacks

    /// Extract point from LuaValue (array of numbers)
    private static func extractPoint(_ value: LuaValue) -> [Double]? {
        guard let arr = value.arrayValue else { return nil }
        var result: [Double] = []
        result.reserveCapacity(arr.count)
        for val in arr {
            guard let num = val.numberValue else { return nil }
            result.append(num)
        }
        return result.isEmpty ? nil : result
    }

    /// Euclidean distance using BLAS
    private static func euclideanDistance(_ p1: [Double], _ p2: [Double]) -> Double {
        let n = min(p1.count, p2.count)
        var diff = [Double](repeating: 0, count: n)

        // Compute difference vector: diff = p1 - p2
        vDSP_vsubD(p2, 1, p1, 1, &diff, 1, vDSP_Length(n))

        // Compute Euclidean norm using BLAS
        return cblas_dnrm2(Int32(n), diff, 1)
    }

    /// Squared Euclidean distance using vDSP
    private static func sqeuclideanDistance(_ p1: [Double], _ p2: [Double]) -> Double {
        let n = min(p1.count, p2.count)
        var diff = [Double](repeating: 0, count: n)

        // Compute difference vector
        vDSP_vsubD(p2, 1, p1, 1, &diff, 1, vDSP_Length(n))

        // Compute sum of squares using vDSP
        var result: Double = 0
        vDSP_dotprD(diff, 1, diff, 1, &result, vDSP_Length(n))
        return result
    }

    /// Manhattan (cityblock) distance using vDSP
    private static func cityblockDistance(_ p1: [Double], _ p2: [Double]) -> Double {
        let n = min(p1.count, p2.count)
        var diff = [Double](repeating: 0, count: n)
        var absDiff = [Double](repeating: 0, count: n)

        // Compute difference vector
        vDSP_vsubD(p2, 1, p1, 1, &diff, 1, vDSP_Length(n))

        // Compute absolute values
        vDSP_vabsD(diff, 1, &absDiff, 1, vDSP_Length(n))

        // Sum using vDSP
        var result: Double = 0
        vDSP_sveD(absDiff, 1, &result, vDSP_Length(n))
        return result
    }

    /// Chebyshev distance using vDSP
    private static func chebyshevDistance(_ p1: [Double], _ p2: [Double]) -> Double {
        let n = min(p1.count, p2.count)
        var diff = [Double](repeating: 0, count: n)
        var absDiff = [Double](repeating: 0, count: n)

        // Compute difference vector
        vDSP_vsubD(p2, 1, p1, 1, &diff, 1, vDSP_Length(n))

        // Compute absolute values
        vDSP_vabsD(diff, 1, &absDiff, 1, vDSP_Length(n))

        // Find maximum using vDSP
        var result: Double = 0
        vDSP_maxvD(absDiff, 1, &result, vDSP_Length(n))
        return result
    }

    /// Minkowski distance
    private static func minkowskiDistance(_ p1: [Double], _ p2: [Double], _ p: Double) -> Double {
        let n = min(p1.count, p2.count)
        var sum: Double = 0

        for i in 0..<n {
            sum += pow(abs(p1[i] - p2[i]), p)
        }
        return pow(sum, 1.0 / p)
    }

    /// Cosine distance using BLAS
    private static func cosineDistance(_ p1: [Double], _ p2: [Double]) -> Double {
        let n = Int32(min(p1.count, p2.count))

        // Compute dot product using BLAS
        let dot = cblas_ddot(n, p1, 1, p2, 1)

        // Compute norms using BLAS
        let norm1 = cblas_dnrm2(n, p1, 1)
        let norm2 = cblas_dnrm2(n, p2, 1)

        let denom = norm1 * norm2
        if denom < 1e-15 { return 1.0 }
        return 1.0 - dot / denom
    }

    /// Correlation distance
    private static func correlationDistance(_ p1: [Double], _ p2: [Double]) -> Double {
        let n = min(p1.count, p2.count)
        guard n > 0 else { return 1.0 }

        // Compute means using vDSP
        var mean1: Double = 0
        var mean2: Double = 0
        vDSP_meanvD(p1, 1, &mean1, vDSP_Length(n))
        vDSP_meanvD(p2, 1, &mean2, vDSP_Length(n))

        // Center the vectors
        var centered1 = [Double](repeating: 0, count: n)
        var centered2 = [Double](repeating: 0, count: n)
        var negMean1 = -mean1
        var negMean2 = -mean2
        vDSP_vsaddD(p1, 1, &negMean1, &centered1, 1, vDSP_Length(n))
        vDSP_vsaddD(p2, 1, &negMean2, &centered2, 1, vDSP_Length(n))

        // Compute correlation using BLAS
        let dot = cblas_ddot(Int32(n), centered1, 1, centered2, 1)
        let norm1 = cblas_dnrm2(Int32(n), centered1, 1)
        let norm2 = cblas_dnrm2(Int32(n), centered2, 1)

        let denom = norm1 * norm2
        if denom < 1e-15 { return 1.0 }
        return 1.0 - dot / denom
    }

    // MARK: - Distance Callbacks

    private static func euclideanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let p1 = extractPoint(args[0]),
              let p2 = extractPoint(args[1]) else {
            throw LuaError.runtimeError("euclidean: expected two point arrays")
        }
        return .number(euclideanDistance(p1, p2))
    }

    private static func sqeuclideanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let p1 = extractPoint(args[0]),
              let p2 = extractPoint(args[1]) else {
            throw LuaError.runtimeError("sqeuclidean: expected two point arrays")
        }
        return .number(sqeuclideanDistance(p1, p2))
    }

    private static func cityblockCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let p1 = extractPoint(args[0]),
              let p2 = extractPoint(args[1]) else {
            throw LuaError.runtimeError("cityblock: expected two point arrays")
        }
        return .number(cityblockDistance(p1, p2))
    }

    private static func chebyshevCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let p1 = extractPoint(args[0]),
              let p2 = extractPoint(args[1]) else {
            throw LuaError.runtimeError("chebyshev: expected two point arrays")
        }
        return .number(chebyshevDistance(p1, p2))
    }

    private static func minkowskiCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let p1 = extractPoint(args[0]),
              let p2 = extractPoint(args[1]) else {
            throw LuaError.runtimeError("minkowski: expected two point arrays")
        }
        let p = args.count >= 3 ? (args[2].numberValue ?? 2.0) : 2.0
        return .number(minkowskiDistance(p1, p2, p))
    }

    private static func cosineCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let p1 = extractPoint(args[0]),
              let p2 = extractPoint(args[1]) else {
            throw LuaError.runtimeError("cosine: expected two point arrays")
        }
        return .number(cosineDistance(p1, p2))
    }

    private static func correlationCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let p1 = extractPoint(args[0]),
              let p2 = extractPoint(args[1]) else {
            throw LuaError.runtimeError("correlation: expected two point arrays")
        }
        return .number(correlationDistance(p1, p2))
    }

    // MARK: - Batch Distance Callbacks

    /// Extract array of points from LuaValue
    private static func extractPoints(_ value: LuaValue) -> [[Double]]? {
        // Handle array case
        if let arr = value.arrayValue {
            if arr.isEmpty { return [] }
            var result: [[Double]] = []
            result.reserveCapacity(arr.count)
            for val in arr {
                guard let point = extractPoint(val) else { return nil }
                result.append(point)
            }
            return result
        }
        // Handle empty table {} which may come as .table([:])
        if case .table(let dict) = value, dict.isEmpty {
            return []
        }
        return nil
    }

    /// Get distance function by metric name
    private static func getDistanceFunction(_ metric: String) -> (([Double], [Double]) -> Double) {
        switch metric.lowercased() {
        case "sqeuclidean": return sqeuclideanDistance
        case "cityblock", "manhattan": return cityblockDistance
        case "chebyshev": return chebyshevDistance
        case "cosine": return cosineDistance
        case "correlation": return correlationDistance
        default: return euclideanDistance
        }
    }

    private static func cdistCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let XA = extractPoints(args[0]),
              let XB = extractPoints(args[1]) else {
            throw LuaError.runtimeError("cdist: expected two arrays of points")
        }

        let metric = args.count >= 3 ? (args[2].stringValue ?? "euclidean") : "euclidean"
        let distFunc = getDistanceFunction(metric)

        let m = XA.count
        let n = XB.count

        // Compute distance matrix
        var result: [[Double]] = Array(repeating: Array(repeating: 0, count: n), count: m)

        // Use concurrent processing for large matrices
        if m * n > 1000 {
            DispatchQueue.concurrentPerform(iterations: m) { i in
                for j in 0..<n {
                    result[i][j] = distFunc(XA[i], XB[j])
                }
            }
        } else {
            for i in 0..<m {
                for j in 0..<n {
                    result[i][j] = distFunc(XA[i], XB[j])
                }
            }
        }

        // Convert to Lua table
        return matrixToLuaTable(result)
    }

    private static func pdistCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let X = extractPoints(args[0]) else {
            throw LuaError.runtimeError("pdist: expected array of points")
        }

        let metric = args.count >= 2 ? (args[1].stringValue ?? "euclidean") : "euclidean"
        let distFunc = getDistanceFunction(metric)

        let n = X.count
        let numPairs = n * (n - 1) / 2
        var result = [Double](repeating: 0, count: numPairs)

        var k = 0
        for i in 0..<(n - 1) {
            for j in (i + 1)..<n {
                result[k] = distFunc(X[i], X[j])
                k += 1
            }
        }

        // Convert to Lua array
        return arrayToLuaTable(result)
    }

    private static func squareformCallback(_ args: [LuaValue]) throws -> LuaValue {
        // Check if it's a 2D matrix or 1D condensed form
        if let arr = args[0].arrayValue, !arr.isEmpty, arr[0].arrayValue != nil {
            // Square to condensed (2D array)
            guard let matrix = extractPoints(args[0]) else {
                throw LuaError.runtimeError("squareform: invalid matrix")
            }
            let n = matrix.count
            var result: [Double] = []
            for i in 0..<(n - 1) {
                for j in (i + 1)..<n {
                    result.append(matrix[i][j])
                }
            }
            return arrayToLuaTable(result)
        } else {
            // Condensed to square (1D array)
            guard let condensed = extractPoint(args[0]) else {
                throw LuaError.runtimeError("squareform: invalid condensed form")
            }
            let m = condensed.count
            // n*(n-1)/2 = m => n = (1 + sqrt(1+8m))/2
            let n = Int((1.0 + sqrt(1.0 + 8.0 * Double(m))) / 2.0)
            var result = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)

            var k = 0
            for i in 0..<(n - 1) {
                for j in (i + 1)..<n {
                    result[i][j] = condensed[k]
                    result[j][i] = condensed[k]
                    k += 1
                }
            }
            return matrixToLuaTable(result)
        }
    }

    // MARK: - KDTree Implementation

    /// KDTree node structure
    private class KDTreeNode {
        let idx: Int
        let point: [Double]
        let axis: Int
        var left: KDTreeNode?
        var right: KDTreeNode?

        init(idx: Int, point: [Double], axis: Int) {
            self.idx = idx
            self.point = point
            self.axis = axis
        }
    }

    /// KDTree handle stored in engine
    private class KDTreeHandle {
        let points: [[Double]]
        let root: KDTreeNode?
        let dim: Int

        init(points: [[Double]]) {
            self.points = points
            self.dim = points.first?.count ?? 0

            var indices = Array(0..<points.count)
            self.root = KDTreeHandle.buildTree(points: points, indices: &indices, depth: 0, dim: dim)
        }

        private static func buildTree(points: [[Double]], indices: inout [Int], depth: Int, dim: Int) -> KDTreeNode? {
            guard !indices.isEmpty else { return nil }

            let axis = depth % dim

            // Sort by axis
            indices.sort { points[$0][axis] < points[$1][axis] }

            let mid = indices.count / 2
            let node = KDTreeNode(idx: indices[mid], point: points[indices[mid]], axis: axis)

            var leftIndices = Array(indices[0..<mid])
            var rightIndices = Array(indices[(mid + 1)...])

            node.left = buildTree(points: points, indices: &leftIndices, depth: depth + 1, dim: dim)
            node.right = buildTree(points: points, indices: &rightIndices, depth: depth + 1, dim: dim)

            return node
        }

        func query(point: [Double], k: Int) -> (indices: [Int], distances: [Double]) {
            var best: [(idx: Int, dist: Double)] = []

            func search(_ node: KDTreeNode?) {
                guard let node = node else { return }

                let dist = euclideanDistance(point, node.point)

                // Insert into best list maintaining sorted order
                if best.count < k || dist < best.last!.dist {
                    var pos = best.count
                    for i in 0..<best.count {
                        if dist < best[i].dist {
                            pos = i
                            break
                        }
                    }
                    best.insert((node.idx, dist), at: pos)
                    if best.count > k {
                        best.removeLast()
                    }
                }

                let diff = point[node.axis] - node.point[node.axis]
                let near = diff < 0 ? node.left : node.right
                let far = diff < 0 ? node.right : node.left

                search(near)

                // Check if we need to search far branch
                if best.count < k || abs(diff) < best.last!.dist {
                    search(far)
                }
            }

            search(root)

            return (best.map { $0.idx + 1 }, best.map { $0.dist })  // 1-indexed for Lua
        }

        func queryRadius(point: [Double], r: Double) -> (indices: [Int], distances: [Double]) {
            var result: [(idx: Int, dist: Double)] = []

            func search(_ node: KDTreeNode?) {
                guard let node = node else { return }

                let dist = euclideanDistance(point, node.point)
                if dist <= r {
                    result.append((node.idx, dist))
                }

                let diff = point[node.axis] - node.point[node.axis]

                if diff - r <= 0 {
                    search(node.left)
                }
                if diff + r >= 0 {
                    search(node.right)
                }
            }

            search(root)

            // Sort by distance
            result.sort { $0.dist < $1.dist }

            return (result.map { $0.idx + 1 }, result.map { $0.dist })  // 1-indexed for Lua
        }

        func queryPairs(r: Double) -> [(Int, Int, Double)] {
            var pairs: [(Int, Int, Double)] = []

            for i in 0..<points.count {
                let (indices, distances) = queryRadius(point: points[i], r: r)
                for (j, idx) in indices.enumerated() {
                    let zeroIdx = idx - 1  // Convert back to 0-indexed
                    if zeroIdx > i {
                        pairs.append((i + 1, idx, distances[j]))  // 1-indexed for Lua
                    }
                }
            }

            return pairs
        }
    }

    /// Thread-safe storage for KDTree handles
    private static var kdtreeHandles: [Int: KDTreeHandle] = [:]
    private static var nextHandleId = 1
    private static let handleLock = NSLock()

    private static func kdtreeBuildCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let points = extractPoints(args[0]) else {
            throw LuaError.runtimeError("KDTree: expected array of points")
        }

        let handle = KDTreeHandle(points: points)

        handleLock.lock()
        let handleId = nextHandleId
        nextHandleId += 1
        kdtreeHandles[handleId] = handle
        handleLock.unlock()

        return .number(Double(handleId))
    }

    private static func kdtreeQueryCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let handleId = args[0].numberValue.map({ Int($0) }),
              let point = extractPoint(args[1]) else {
            throw LuaError.runtimeError("KDTree.query: invalid arguments")
        }

        let k = args.count >= 3 ? Int(args[2].numberValue ?? 1) : 1

        handleLock.lock()
        guard let handle = kdtreeHandles[handleId] else {
            handleLock.unlock()
            throw LuaError.runtimeError("KDTree.query: invalid handle")
        }
        handleLock.unlock()

        let (indices, distances) = handle.query(point: point, k: k)

        return .array([
            .array(indices.map { .number(Double($0)) }),
            .array(distances.map { .number($0) })
        ])
    }

    private static func kdtreeQueryRadiusCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3,
              let handleId = args[0].numberValue.map({ Int($0) }),
              let point = extractPoint(args[1]),
              let r = args[2].numberValue else {
            throw LuaError.runtimeError("KDTree.query_radius: invalid arguments")
        }

        handleLock.lock()
        guard let handle = kdtreeHandles[handleId] else {
            handleLock.unlock()
            throw LuaError.runtimeError("KDTree.query_radius: invalid handle")
        }
        handleLock.unlock()

        let (indices, distances) = handle.queryRadius(point: point, r: r)

        return .array([
            .array(indices.map { .number(Double($0)) }),
            .array(distances.map { .number($0) })
        ])
    }

    private static func kdtreeQueryPairsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let handleId = args[0].numberValue.map({ Int($0) }),
              let r = args[1].numberValue else {
            throw LuaError.runtimeError("KDTree.query_pairs: invalid arguments")
        }

        handleLock.lock()
        guard let handle = kdtreeHandles[handleId] else {
            handleLock.unlock()
            throw LuaError.runtimeError("KDTree.query_pairs: invalid handle")
        }
        handleLock.unlock()

        let pairs = handle.queryPairs(r: r)

        let resultArray = pairs.map { pair -> LuaValue in
            .array([
                .number(Double(pair.0)),
                .number(Double(pair.1)),
                .number(pair.2)
            ])
        }

        return .array(resultArray)
    }

    // MARK: - Geometric Algorithms

    private static func delaunayCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let points = extractPoints(args[0]) else {
            throw LuaError.runtimeError("Delaunay: expected array of points")
        }

        let n = points.count
        if n < 3 {
            return .table([
                "points": pointsToLuaTable(points),
                "simplices": .table([:]),
                "neighbors": .table([:])
            ])
        }

        // Check for collinear points
        if n >= 3 {
            let p1 = points[0], p2 = points[1], p3 = points[2]
            let cross = (p2[0] - p1[0]) * (p3[1] - p1[1]) - (p2[1] - p1[1]) * (p3[0] - p1[0])
            if abs(cross) < 1e-10 {
                // Collinear - return line segments
                var sortedIndices = Array(0..<n)
                sortedIndices.sort {
                    points[$0][0] < points[$1][0] ||
                    (points[$0][0] == points[$1][0] && points[$0][1] < points[$1][1])
                }

                var simplices: [[Int]] = []
                for i in 0..<(n - 1) {
                    simplices.append([sortedIndices[i] + 1, sortedIndices[i + 1] + 1])  // 1-indexed
                }

                return .table([
                    "points": pointsToLuaTable(points),
                    "simplices": simplicesToLuaTable(simplices),
                    "neighbors": .table([:])
                ])
            }
        }

        // Bowyer-Watson algorithm
        let (simplices, neighbors) = bowyerWatson(points: points)

        return .table([
            "points": pointsToLuaTable(points),
            "simplices": simplicesToLuaTable(simplices),
            "neighbors": neighborsToLuaTable(neighbors)
        ])
    }

    /// Bowyer-Watson algorithm for Delaunay triangulation
    private static func bowyerWatson(points: [[Double]]) -> (simplices: [[Int]], neighbors: [[Int]]) {
        let n = points.count

        // Find bounding box
        var minX = points[0][0], maxX = points[0][0]
        var minY = points[0][1], maxY = points[0][1]

        for p in points {
            minX = min(minX, p[0])
            maxX = max(maxX, p[0])
            minY = min(minY, p[1])
            maxY = max(maxY, p[1])
        }

        // Create super-triangle
        let dx = maxX - minX
        let dy = maxY - minY
        let delta = max(dx, dy) * 10.0

        let superTriangle: [[Double]] = [
            [minX - delta, minY - delta],
            [minX + dx / 2.0, maxY + delta * 2.0],
            [maxX + delta, minY - delta]
        ]

        // All points including super-triangle vertices
        let allPoints = points + superTriangle

        // Initial triangulation with super-triangle (using 0-indexed)
        var triangles: [[Int]] = [[n, n + 1, n + 2]]

        // Insert each point
        for i in 0..<n {
            let px = points[i][0]
            let py = points[i][1]

            var badTriangles: [Int] = []

            // Find triangles whose circumcircle contains the point
            for (j, tri) in triangles.enumerated() {
                if inCircumcircle(px: px, py: py, tri: tri, points: allPoints) {
                    badTriangles.append(j)
                }
            }

            // Find boundary edges of the hole
            var edgeCount: [String: Int] = [:]
            for j in badTriangles {
                let tri = triangles[j]
                let edges = [[tri[0], tri[1]], [tri[1], tri[2]], [tri[2], tri[0]]]
                for e in edges {
                    let key = "\(min(e[0], e[1])),\(max(e[0], e[1]))"
                    edgeCount[key, default: 0] += 1
                }
            }

            // Collect boundary edges (those appearing only once)
            var polygon: [[Int]] = []
            for j in badTriangles {
                let tri = triangles[j]
                let edges = [[tri[0], tri[1]], [tri[1], tri[2]], [tri[2], tri[0]]]
                for e in edges {
                    let key = "\(min(e[0], e[1])),\(max(e[0], e[1]))"
                    if edgeCount[key] == 1 {
                        polygon.append(e)
                    }
                }
            }

            // Remove bad triangles (in reverse order to preserve indices)
            for j in badTriangles.sorted().reversed() {
                triangles.remove(at: j)
            }

            // Create new triangles from boundary edges to new point
            for e in polygon {
                triangles.append([e[0], e[1], i])
            }
        }

        // Remove triangles containing super-triangle vertices
        var finalTriangles: [[Int]] = []
        for tri in triangles {
            var valid = true
            for v in tri {
                if v >= n {
                    valid = false
                    break
                }
            }
            if valid {
                // Convert to 1-indexed for Lua
                finalTriangles.append(tri.map { $0 + 1 })
            }
        }

        // Build neighbor information
        var neighbors: [[Int]] = Array(repeating: [], count: finalTriangles.count)
        for i in 0..<finalTriangles.count {
            let triI = finalTriangles[i]
            for j in (i + 1)..<finalTriangles.count {
                let triJ = finalTriangles[j]
                // Count shared vertices
                var shared = 0
                for vi in triI {
                    for vj in triJ {
                        if vi == vj { shared += 1 }
                    }
                }
                if shared == 2 {
                    neighbors[i].append(j + 1)  // 1-indexed
                    neighbors[j].append(i + 1)
                }
            }
        }

        return (finalTriangles, neighbors)
    }

    /// Check if point is inside circumcircle of triangle
    private static func inCircumcircle(px: Double, py: Double, tri: [Int], points: [[Double]]) -> Bool {
        let ax = points[tri[0]][0], ay = points[tri[0]][1]
        let bx = points[tri[1]][0], by = points[tri[1]][1]
        let cx = points[tri[2]][0], cy = points[tri[2]][1]

        let d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
        if abs(d) < 1e-15 { return false }

        let a2 = ax * ax + ay * ay
        let b2 = bx * bx + by * by
        let c2 = cx * cx + cy * cy

        let ux = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / d
        let uy = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d

        let r2 = (ax - ux) * (ax - ux) + (ay - uy) * (ay - uy)
        let dist2 = (px - ux) * (px - ux) + (py - uy) * (py - uy)

        return dist2 < r2
    }

    private static func voronoiCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let points = extractPoints(args[0]) else {
            throw LuaError.runtimeError("Voronoi: expected array of points")
        }

        let n = points.count
        if n == 0 {
            return .table([
                "points": .table([:]),
                "vertices": .table([:]),
                "regions": .table([:]),
                "ridge_vertices": .table([:]),
                "ridge_points": .table([:])
            ])
        }

        // Compute Delaunay first (Voronoi is dual)
        let (delaunaySimplices, delaunayNeighbors) = bowyerWatson(points: points)

        // Compute circumcenters of Delaunay triangles = Voronoi vertices
        var vertices: [[Double]] = []
        var simplexToVertex: [Int: Int] = [:]

        for (i, simplex) in delaunaySimplices.enumerated() {
            if simplex.count == 3 {
                let p1 = points[simplex[0] - 1]  // Convert from 1-indexed
                let p2 = points[simplex[1] - 1]
                let p3 = points[simplex[2] - 1]

                let ax = p1[0], ay = p1[1]
                let bx = p2[0], by = p2[1]
                let cx = p3[0], cy = p3[1]

                let d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
                if abs(d) > 1e-10 {
                    let a2 = ax * ax + ay * ay
                    let b2 = bx * bx + by * by
                    let c2 = cx * cx + cy * cy

                    let ux = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / d
                    let uy = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d

                    vertices.append([ux, uy])
                    simplexToVertex[i] = vertices.count  // 1-indexed
                }
            }
        }

        // Build regions for each input point
        var regions: [[Int]] = Array(repeating: [], count: n)
        for (i, simplex) in delaunaySimplices.enumerated() {
            if let vIdx = simplexToVertex[i] {
                for ptIdx in simplex {
                    regions[ptIdx - 1].append(vIdx)  // Convert from 1-indexed
                }
            }
        }

        // Build ridge information
        var ridgeVertices: [[Int]] = []
        var ridgePoints: [[Int]] = []

        for (i, simplex) in delaunaySimplices.enumerated() {
            if let v1 = simplexToVertex[i] {
                for nIdx in delaunayNeighbors[i] {
                    if nIdx > i + 1 {  // nIdx is 1-indexed, i is 0-indexed
                        if let v2 = simplexToVertex[nIdx - 1] {
                            // Find shared edge
                            var shared: [Int] = []
                            for p1 in simplex {
                                for p2 in delaunaySimplices[nIdx - 1] {
                                    if p1 == p2 { shared.append(p1) }
                                }
                            }
                            if shared.count >= 2 {
                                ridgeVertices.append([v1, v2])
                                ridgePoints.append([shared[0], shared[1]])
                            }
                        }
                    }
                }
            }
        }

        return .table([
            "points": pointsToLuaTable(points),
            "vertices": pointsToLuaTable(vertices),
            "regions": regionsToLuaTable(regions),
            "ridge_vertices": simplicesToLuaTable(ridgeVertices),
            "ridge_points": simplicesToLuaTable(ridgePoints)
        ])
    }

    private static func convexhullCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let points = extractPoints(args[0]) else {
            throw LuaError.runtimeError("ConvexHull: expected array of points")
        }

        let n = points.count
        if n < 3 {
            let vertices = Array(1...n)
            return .table([
                "points": pointsToLuaTable(points),
                "vertices": arrayToLuaTable(vertices.map { Double($0) }),
                "simplices": .table([:])
            ])
        }

        // Graham scan algorithm
        // Find lowest point (and leftmost if tie)
        var startIdx = 0
        for i in 1..<n {
            if points[i][1] < points[startIdx][1] ||
               (points[i][1] == points[startIdx][1] && points[i][0] < points[startIdx][0]) {
                startIdx = i
            }
        }

        let start = points[startIdx]

        // Sort by polar angle
        var indices = Array(0..<n).filter { $0 != startIdx }
        indices.sort { a, b in
            let angleA = atan2(points[a][1] - start[1], points[a][0] - start[0])
            let angleB = atan2(points[b][1] - start[1], points[b][0] - start[0])
            if abs(angleA - angleB) < 1e-10 {
                let distA = sqeuclideanDistance(points[a], start)
                let distB = sqeuclideanDistance(points[b], start)
                return distA < distB
            }
            return angleA < angleB
        }

        // Graham scan with CCW check
        func ccw(_ p1: [Double], _ p2: [Double], _ p3: [Double]) -> Double {
            return (p2[0] - p1[0]) * (p3[1] - p1[1]) - (p2[1] - p1[1]) * (p3[0] - p1[0])
        }

        var hull = [startIdx]
        for idx in indices {
            while hull.count >= 2 && ccw(points[hull[hull.count - 2]], points[hull[hull.count - 1]], points[idx]) <= 0 {
                hull.removeLast()
            }
            hull.append(idx)
        }

        // Build simplices (edges)
        var simplices: [[Int]] = []
        for i in 0..<hull.count {
            let nextI = (i + 1) % hull.count
            simplices.append([hull[i] + 1, hull[nextI] + 1])  // 1-indexed
        }

        return .table([
            "points": pointsToLuaTable(points),
            "vertices": arrayToLuaTable(hull.map { Double($0 + 1) }),  // 1-indexed
            "simplices": simplicesToLuaTable(simplices)
        ])
    }

    // MARK: - Helper Functions for Lua Table Conversion

    private static func arrayToLuaTable(_ arr: [Double]) -> LuaValue {
        return .array(arr.map { .number($0) })
    }

    private static func matrixToLuaTable(_ matrix: [[Double]]) -> LuaValue {
        return .array(matrix.map { row in
            .array(row.map { .number($0) })
        })
    }

    private static func pointsToLuaTable(_ points: [[Double]]) -> LuaValue {
        return .array(points.map { point in
            .array(point.map { .number($0) })
        })
    }

    private static func simplicesToLuaTable(_ simplices: [[Int]]) -> LuaValue {
        return .array(simplices.map { simplex in
            .array(simplex.map { .number(Double($0)) })
        })
    }

    private static func neighborsToLuaTable(_ neighbors: [[Int]]) -> LuaValue {
        return .array(neighbors.map { neighborList in
            .array(neighborList.map { .number(Double($0)) })
        })
    }

    private static func regionsToLuaTable(_ regions: [[Int]]) -> LuaValue {
        return .array(regions.map { region in
            .array(region.map { .number(Double($0)) })
        })
    }
}

#endif  // LUASWIFT_NUMERICSWIFT
