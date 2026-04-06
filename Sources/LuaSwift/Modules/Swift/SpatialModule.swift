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
            #if DEBUG
            print("[LuaSwift] SpatialModule setup failed: \(error)")
            #endif
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
    // MARK: - Distance Callbacks
    // Note: Distance functions (euclideanDistance, squaredEuclideanDistance, cityblockDistance,
    // chebyshevDistance, minkowskiDistance, cosineDistance, correlationDistance) are provided
    // by NumericSwift.

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
        return .number(squaredEuclideanDistance(p1, p2))
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
        return .number(minkowskiDistance(p1, p2, p: p))
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

    /// Get distance function by metric name (uses NumericSwift distance functions)
    private static func getDistanceFunction(_ metric: String) -> (([Double], [Double]) -> Double) {
        switch metric.lowercased() {
        case "sqeuclidean": return squaredEuclideanDistance
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

    // MARK: - KDTree Callbacks
    // Note: Uses NumericSwift's KDTree class for spatial queries.
    // Lua indices are 1-based, so we add 1 to 0-indexed results.

    /// Thread-safe storage for KDTree handles (uses NumericSwift's KDTree)
    private static var kdtreeHandles: [Int: KDTree] = [:]
    private static var nextHandleId = 1
    private static let handleLock = NSLock()

    private static func kdtreeBuildCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let points = extractPoints(args[0]) else {
            throw LuaError.runtimeError("KDTree: expected array of points")
        }

        let handle = KDTree(points)

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

        let (indices, distances) = handle.query(point, k: k)

        // Convert 0-indexed to 1-indexed for Lua
        return .array([
            .array(indices.map { .number(Double($0 + 1)) }),
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

        let (indices, distances) = handle.queryRadius(point, radius: r)

        // Convert 0-indexed to 1-indexed for Lua
        return .array([
            .array(indices.map { .number(Double($0 + 1)) }),
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

        let pairs = handle.queryPairs(radius: r)

        // Convert 0-indexed to 1-indexed for Lua
        let resultArray = pairs.map { pair -> LuaValue in
            .array([
                .number(Double(pair.0 + 1)),
                .number(Double(pair.1 + 1)),
                .number(pair.2)
            ])
        }

        return .array(resultArray)
    }

    // MARK: - Geometric Algorithms
    // Note: Delaunay, Voronoi, and ConvexHull use NumericSwift implementations.
    // Lua indices are 1-based, so we add 1 to 0-indexed results.

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

        // Check for collinear points - return line segments (backwards compatibility)
        let p1 = points[0], p2 = points[1], p3 = points[2]
        let cross = (p2[0] - p1[0]) * (p3[1] - p1[1]) - (p2[1] - p1[1]) * (p3[0] - p1[0])
        if abs(cross) < 1e-10 {
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

        // Use NumericSwift's delaunay function
        let result = delaunay(points)

        // Convert 0-indexed to 1-indexed for Lua
        let simplices1 = result.simplices.map { tri in tri.map { $0 + 1 } }
        let neighbors1 = result.neighbors.map { neighborList in neighborList.map { $0 + 1 } }

        return .table([
            "points": pointsToLuaTable(points),
            "simplices": simplicesToLuaTable(simplices1),
            "neighbors": neighborsToLuaTable(neighbors1)
        ])
    }

    private static func voronoiCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let points = extractPoints(args[0]) else {
            throw LuaError.runtimeError("Voronoi: expected array of points")
        }

        if points.isEmpty {
            return .table([
                "points": .table([:]),
                "vertices": .table([:]),
                "regions": .table([:]),
                "ridge_vertices": .table([:]),
                "ridge_points": .table([:])
            ])
        }

        // Use NumericSwift's voronoi function
        let result = voronoi(points)

        // Convert 0-indexed to 1-indexed for Lua
        let regions1 = result.regions.map { region in region.map { $0 + 1 } }
        let ridgeVertices1 = result.ridgeVertices.map { rv in rv.map { $0 + 1 } }
        let ridgePoints1 = result.ridgePoints.map { rp in rp.map { $0 + 1 } }

        return .table([
            "points": pointsToLuaTable(points),
            "vertices": pointsToLuaTable(result.vertices),
            "regions": regionsToLuaTable(regions1),
            "ridge_vertices": simplicesToLuaTable(ridgeVertices1),
            "ridge_points": simplicesToLuaTable(ridgePoints1)
        ])
    }

    private static func convexhullCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let points = extractPoints(args[0]) else {
            throw LuaError.runtimeError("ConvexHull: expected array of points")
        }

        let n = points.count
        if n < 3 {
            let vertices = Array(1...max(1, n))
            return .table([
                "points": pointsToLuaTable(points),
                "vertices": arrayToLuaTable(vertices.map { Double($0) }),
                "simplices": .table([:])
            ])
        }

        // Use NumericSwift's convexHull function
        let result = convexHull(points)

        // Convert 0-indexed to 1-indexed for Lua
        let vertices1 = result.vertices.map { $0 + 1 }
        let simplices1 = result.simplices.map { edge in edge.map { $0 + 1 } }

        return .table([
            "points": pointsToLuaTable(points),
            "vertices": arrayToLuaTable(vertices1.map { Double($0) }),
            "simplices": simplicesToLuaTable(simplices1)
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
