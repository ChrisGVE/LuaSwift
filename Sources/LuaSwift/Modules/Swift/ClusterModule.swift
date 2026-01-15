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
import Accelerate
import NumericSwift

/// Swift-backed clustering module for LuaSwift.
///
/// Provides clustering algorithms including k-means, hierarchical clustering,
/// and DBSCAN. All algorithms are implemented in Swift with BLAS/vDSP
/// optimization for maximum performance.
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

    // MARK: - Constants

    private static let DEFAULT_MAX_ITER = 300
    private static let DEFAULT_TOL = 1e-4
    private static let DEFAULT_N_INIT = 10

    // MARK: - Registration

    /// Register the cluster module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_cluster_kmeans", callback: kmeansCallback)
        engine.registerFunction(name: "_luaswift_cluster_hierarchical", callback: hierarchicalCallback)
        engine.registerFunction(name: "_luaswift_cluster_dbscan", callback: dbscanCallback)
        engine.registerFunction(name: "_luaswift_cluster_silhouette_score", callback: silhouetteScoreCallback)
        engine.registerFunction(name: "_luaswift_cluster_elbow_method", callback: elbowMethodCallback)

        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.cluster then luaswift.cluster = {} end

                local cluster = {}

                ----------------------------------------------------------------
                -- kmeans: K-means clustering (Swift-backed)
                ----------------------------------------------------------------
                function cluster.kmeans(data, k, options)
                    return _luaswift_cluster_kmeans(data, k, options or {})
                end

                ----------------------------------------------------------------
                -- hierarchical: Hierarchical/agglomerative clustering (Swift-backed)
                ----------------------------------------------------------------
                function cluster.hierarchical(data, options)
                    return _luaswift_cluster_hierarchical(data, options or {})
                end

                ----------------------------------------------------------------
                -- dbscan: DBSCAN clustering (Swift-backed)
                ----------------------------------------------------------------
                function cluster.dbscan(data, options)
                    return _luaswift_cluster_dbscan(data, options or {})
                end

                ----------------------------------------------------------------
                -- silhouette_score: Compute silhouette coefficient (Swift-backed)
                ----------------------------------------------------------------
                function cluster.silhouette_score(data, labels)
                    return _luaswift_cluster_silhouette_score(data, labels)
                end

                ----------------------------------------------------------------
                -- elbow_method: Find optimal k using elbow method (Swift-backed)
                ----------------------------------------------------------------
                function cluster.elbow_method(data, max_k)
                    return _luaswift_cluster_elbow_method(data, max_k or 10)
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

    // MARK: - Data Extraction Helpers

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

    /// Extract array of points from LuaValue
    private static func extractPoints(_ value: LuaValue) -> [[Double]]? {
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
        if case .table(let dict) = value, dict.isEmpty {
            return []
        }
        return nil
    }

    /// Extract array of integers (labels) from LuaValue
    private static func extractLabels(_ value: LuaValue) -> [Int]? {
        guard let arr = value.arrayValue else { return nil }
        var result: [Int] = []
        result.reserveCapacity(arr.count)
        for val in arr {
            guard let num = val.numberValue else { return nil }
            result.append(Int(num))
        }
        return result
    }

    /// Extract options table
    private static func extractOptions(_ value: LuaValue) -> [String: LuaValue] {
        if case .table(let dict) = value {
            return dict
        }
        return [:]
    }

    // MARK: - Distance Functions (BLAS-optimized)

    /// Euclidean distance using BLAS
    private static func euclideanDistance(_ p1: [Double], _ p2: [Double]) -> Double {
        let n = min(p1.count, p2.count)
        var diff = [Double](repeating: 0, count: n)
        vDSP_vsubD(p2, 1, p1, 1, &diff, 1, vDSP_Length(n))
        return cblas_dnrm2(Int32(n), diff, 1)
    }

    /// Squared Euclidean distance using vDSP
    private static func squaredDistance(_ p1: [Double], _ p2: [Double]) -> Double {
        let n = min(p1.count, p2.count)
        var diff = [Double](repeating: 0, count: n)
        vDSP_vsubD(p2, 1, p1, 1, &diff, 1, vDSP_Length(n))
        var result: Double = 0
        vDSP_dotprD(diff, 1, diff, 1, &result, vDSP_Length(n))
        return result
    }

    /// Compute centroid of a set of points using vDSP
    private static func computeCentroid(_ points: [[Double]]) -> [Double]? {
        guard !points.isEmpty else { return nil }
        let dim = points[0].count
        var centroid = [Double](repeating: 0, count: dim)

        for point in points {
            vDSP_vaddD(centroid, 1, point, 1, &centroid, 1, vDSP_Length(dim))
        }

        var divisor = Double(points.count)
        vDSP_vsdivD(centroid, 1, &divisor, &centroid, 1, vDSP_Length(dim))

        return centroid
    }

    // MARK: - K-Means Implementation

    private static func kmeansCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let data = extractPoints(args[0]),
              let k = args[1].numberValue.map({ Int($0) }) else {
            throw LuaError.runtimeError("kmeans: expected data array and k")
        }

        let options = args.count >= 3 ? extractOptions(args[2]) : [:]
        let maxIter = options["max_iter"]?.numberValue.map { Int($0) } ?? DEFAULT_MAX_ITER
        let tol = options["tol"]?.numberValue ?? DEFAULT_TOL
        let nInit = options["n_init"]?.numberValue.map { Int($0) } ?? DEFAULT_N_INIT
        let initMethod = options["init"]?.stringValue ?? "k-means++"

        let n = data.count
        if n == 0 {
            return .table([
                "labels": .array([]),
                "centroids": .array([]),
                "inertia": .number(0),
                "n_iter": .number(0)
            ])
        }

        let dim = data[0].count

        // Run n_init times and keep best result
        var bestLabels: [Int] = []
        var bestCentroids: [[Double]] = []
        var bestInertia = Double.infinity
        var bestNIter = 0

        for _ in 0..<nInit {
            // Initialize centroids
            var centroids: [[Double]]
            if initMethod == "k-means++" {
                centroids = kmeansPlusPlusInit(data: data, k: k, dim: dim)
            } else {
                centroids = randomInit(data: data, k: k)
            }

            // Run k-means
            let (labels, finalCentroids, inertia, nIter) = runKMeans(
                data: data, k: k, initialCentroids: centroids,
                maxIter: maxIter, tol: tol
            )

            if inertia < bestInertia {
                bestLabels = labels
                bestCentroids = finalCentroids
                bestInertia = inertia
                bestNIter = nIter
            }
        }

        return .table([
            "labels": .array(bestLabels.map { .number(Double($0)) }),
            "centroids": .array(bestCentroids.map { centroid in
                .array(centroid.map { .number($0) })
            }),
            "inertia": .number(bestInertia),
            "n_iter": .number(Double(bestNIter))
        ])
    }

    /// K-means++ initialization
    private static func kmeansPlusPlusInit(data: [[Double]], k: Int, dim: Int) -> [[Double]] {
        let n = data.count
        var centroids: [[Double]] = []

        // Choose first centroid randomly
        let firstIdx = Int.random(in: 0..<n)
        centroids.append(data[firstIdx])

        for _ in 1..<k {
            // Compute D(x)^2 for each point
            var distances = [Double](repeating: 0, count: n)
            var totalDist: Double = 0

            for i in 0..<n {
                var minDist = Double.infinity
                for centroid in centroids {
                    let d = squaredDistance(data[i], centroid)
                    if d < minDist { minDist = d }
                }
                distances[i] = minDist
                totalDist += minDist
            }

            // Choose next centroid with probability proportional to D(x)^2
            let r = Double.random(in: 0..<totalDist)
            var cumsum: Double = 0
            var chosenIdx = n - 1

            for i in 0..<n {
                cumsum += distances[i]
                if cumsum >= r {
                    chosenIdx = i
                    break
                }
            }

            centroids.append(data[chosenIdx])
        }

        return centroids
    }

    /// Random initialization
    private static func randomInit(data: [[Double]], k: Int) -> [[Double]] {
        let n = data.count
        var used = Set<Int>()
        var centroids: [[Double]] = []

        while centroids.count < k && used.count < n {
            let idx = Int.random(in: 0..<n)
            if !used.contains(idx) {
                used.insert(idx)
                centroids.append(data[idx])
            }
        }

        return centroids
    }

    /// Run single k-means iteration
    private static func runKMeans(
        data: [[Double]], k: Int, initialCentroids: [[Double]],
        maxIter: Int, tol: Double
    ) -> (labels: [Int], centroids: [[Double]], inertia: Double, nIter: Int) {
        let n = data.count
        var centroids = initialCentroids
        var labels = [Int](repeating: 0, count: n)
        var nIter = 0

        for iter in 1...maxIter {
            nIter = iter

            // Assignment step
            var clusters: [[Int]] = Array(repeating: [], count: k)
            var inertia: Double = 0

            for i in 0..<n {
                var minDist = Double.infinity
                var bestC = 0
                for c in 0..<k {
                    let d = squaredDistance(data[i], centroids[c])
                    if d < minDist {
                        minDist = d
                        bestC = c
                    }
                }
                labels[i] = bestC + 1  // 1-indexed for Lua
                clusters[bestC].append(i)
                inertia += minDist
            }

            // Update step
            var newCentroids: [[Double]] = []
            for c in 0..<k {
                if clusters[c].isEmpty {
                    newCentroids.append(centroids[c])
                } else {
                    let clusterPoints = clusters[c].map { data[$0] }
                    if let centroid = computeCentroid(clusterPoints) {
                        newCentroids.append(centroid)
                    } else {
                        newCentroids.append(centroids[c])
                    }
                }
            }

            // Check convergence
            var maxShift: Double = 0
            for c in 0..<k {
                let shift = euclideanDistance(centroids[c], newCentroids[c])
                if shift > maxShift { maxShift = shift }
            }

            centroids = newCentroids

            if maxShift < tol {
                break
            }
        }

        // Compute final inertia
        var finalInertia: Double = 0
        for i in 0..<n {
            finalInertia += squaredDistance(data[i], centroids[labels[i] - 1])
        }

        return (labels, centroids, finalInertia, nIter)
    }

    // MARK: - Hierarchical Clustering Implementation

    private static func hierarchicalCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let data = extractPoints(args[0]) else {
            throw LuaError.runtimeError("hierarchical: expected data array")
        }

        let options = args.count >= 2 ? extractOptions(args[1]) : [:]
        let linkageMethod = (options["linkage"]?.stringValue ?? "ward").lowercased()
        let nClusters = options["n_clusters"]?.numberValue.map { Int($0) }
        let distanceThreshold = options["distance_threshold"]?.numberValue

        let n = data.count
        if n == 0 {
            return .table([
                "linkage_matrix": .array([]),
                "labels": .nil,
                "n_leaves": .number(0)
            ])
        }

        // Initialize clusters
        var clusters: [HierarchicalCluster] = []
        for i in 0..<n {
            clusters.append(HierarchicalCluster(
                id: i + 1,  // 1-indexed
                points: [i],
                centroid: data[i],
                size: 1,
                active: true
            ))
        }

        // Build linkage matrix
        var linkageMatrix: [[Double]] = []
        var nextClusterId = n + 1

        for _ in 0..<(n - 1) {
            // Find closest pair
            var minDist = Double.infinity
            var bestI = -1, bestJ = -1

            for i in 0..<clusters.count {
                guard clusters[i].active else { continue }
                for j in (i + 1)..<clusters.count {
                    guard clusters[j].active else { continue }

                    let d = clusterDistance(
                        c1: clusters[i], c2: clusters[j],
                        data: data, method: linkageMethod
                    )
                    if d < minDist {
                        minDist = d
                        bestI = i
                        bestJ = j
                    }
                }
            }

            guard bestI >= 0 else { break }

            let c1 = clusters[bestI]
            let c2 = clusters[bestJ]

            // Merge clusters
            var mergedPoints = c1.points
            mergedPoints.append(contentsOf: c2.points)

            let newSize = c1.size + c2.size
            var newCentroid = [Double](repeating: 0, count: c1.centroid.count)
            for d in 0..<newCentroid.count {
                newCentroid[d] = (c1.centroid[d] * Double(c1.size) + c2.centroid[d] * Double(c2.size)) / Double(newSize)
            }

            // Record in linkage matrix
            linkageMatrix.append([Double(c1.id), Double(c2.id), minDist, Double(newSize)])

            // Deactivate merged clusters
            clusters[bestI].active = false
            clusters[bestJ].active = false

            // Create new cluster
            clusters.append(HierarchicalCluster(
                id: nextClusterId,
                points: mergedPoints,
                centroid: newCentroid,
                size: newSize,
                active: true
            ))
            nextClusterId += 1
        }

        // Cut tree if requested
        var labels: LuaValue = .nil
        if nClusters != nil || distanceThreshold != nil {
            let cutIdx: Int
            if let nc = nClusters {
                cutIdx = n - nc
            } else if let dt = distanceThreshold {
                var idx = 0
                for (i, merge) in linkageMatrix.enumerated() {
                    if merge[2] > dt {
                        idx = i
                        break
                    }
                    idx = i + 1
                }
                cutIdx = idx
            } else {
                cutIdx = 0
            }

            // Assign labels
            var clusterMap = [Int](0..<n)
            var nextLabel = n

            for i in 0..<cutIdx {
                let c1Id = Int(linkageMatrix[i][0])
                let c2Id = Int(linkageMatrix[i][1])

                for p in 0..<n {
                    if clusterMap[p] + 1 == c1Id || clusterMap[p] + 1 == c2Id {
                        clusterMap[p] = nextLabel
                    }
                }
                nextLabel += 1
            }

            // Convert to consecutive labels
            var labelMap: [Int: Int] = [:]
            var nextNewLabel = 1
            var resultLabels = [Int](repeating: 0, count: n)

            for i in 0..<n {
                let oldLabel = clusterMap[i]
                if labelMap[oldLabel] == nil {
                    labelMap[oldLabel] = nextNewLabel
                    nextNewLabel += 1
                }
                resultLabels[i] = labelMap[oldLabel]!
            }

            labels = .array(resultLabels.map { .number(Double($0)) })
        }

        return .table([
            "linkage_matrix": .array(linkageMatrix.map { row in
                .array(row.map { .number($0) })
            }),
            "labels": labels,
            "n_leaves": .number(Double(n))
        ])
    }

    /// Helper struct for hierarchical clustering
    private struct HierarchicalCluster {
        let id: Int
        var points: [Int]
        var centroid: [Double]
        var size: Int
        var active: Bool
    }

    /// Compute distance between clusters based on linkage method
    private static func clusterDistance(
        c1: HierarchicalCluster, c2: HierarchicalCluster,
        data: [[Double]], method: String
    ) -> Double {
        switch method {
        case "single":
            var minD = Double.infinity
            for i in c1.points {
                for j in c2.points {
                    let d = squaredDistance(data[i], data[j])
                    if d < minD { minD = d }
                }
            }
            return sqrt(minD)

        case "complete":
            var maxD: Double = 0
            for i in c1.points {
                for j in c2.points {
                    let d = squaredDistance(data[i], data[j])
                    if d > maxD { maxD = d }
                }
            }
            return sqrt(maxD)

        case "average":
            var total: Double = 0
            var count = 0
            for i in c1.points {
                for j in c2.points {
                    total += euclideanDistance(data[i], data[j])
                    count += 1
                }
            }
            return total / Double(count)

        case "ward":
            let n1 = Double(c1.size)
            let n2 = Double(c2.size)
            let centroidDist = squaredDistance(c1.centroid, c2.centroid)
            return sqrt(2 * n1 * n2 / (n1 + n2) * centroidDist)

        default:
            return euclideanDistance(c1.centroid, c2.centroid)
        }
    }

    // MARK: - DBSCAN Implementation

    private static func dbscanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let data = extractPoints(args[0]) else {
            throw LuaError.runtimeError("dbscan: expected data array")
        }

        let options = args.count >= 2 ? extractOptions(args[1]) : [:]
        let eps = options["eps"]?.numberValue ?? 0.5
        let minSamples = options["min_samples"]?.numberValue.map { Int($0) } ?? 5

        let n = data.count
        if n == 0 {
            return .table([
                "labels": .array([]),
                "core_samples": .array([]),
                "n_clusters": .number(0)
            ])
        }

        // Find neighbors for each point
        var neighborsCache: [[Int]] = []
        var isCore = [Bool](repeating: false, count: n)

        for i in 0..<n {
            var neighbors: [Int] = []
            for j in 0..<n {
                if euclideanDistance(data[i], data[j]) <= eps {
                    neighbors.append(j)
                }
            }
            neighborsCache.append(neighbors)
            isCore[i] = neighbors.count >= minSamples
        }

        // Assign clusters
        var labels = [Int](repeating: 0, count: n)  // 0 = unvisited
        var currentCluster = 0
        var coreSamples: [Int] = []

        for i in 0..<n {
            if labels[i] != 0 {
                continue
            }
            if !isCore[i] {
                labels[i] = -1  // Noise
                continue
            }

            // Start new cluster
            currentCluster += 1
            coreSamples.append(i + 1)  // 1-indexed

            // BFS expansion
            var queue = [i]
            labels[i] = currentCluster

            while !queue.isEmpty {
                let current = queue.removeFirst()

                for neighbor in neighborsCache[current] {
                    if labels[neighbor] == -1 {
                        // Was noise, now border
                        labels[neighbor] = currentCluster
                    } else if labels[neighbor] == 0 {
                        labels[neighbor] = currentCluster
                        if isCore[neighbor] {
                            queue.append(neighbor)
                            coreSamples.append(neighbor + 1)
                        }
                    }
                }
            }
        }

        return .table([
            "labels": .array(labels.map { .number(Double($0)) }),
            "core_samples": .array(coreSamples.map { .number(Double($0)) }),
            "n_clusters": .number(Double(currentCluster))
        ])
    }

    // MARK: - Silhouette Score Implementation

    private static func silhouetteScoreCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let data = extractPoints(args[0]),
              let labels = extractLabels(args[1]) else {
            throw LuaError.runtimeError("silhouette_score: expected data and labels")
        }

        let n = data.count
        if n < 2 { return .number(0) }

        // Group points by cluster (excluding noise -1)
        var clusters: [Int: [Int]] = [:]
        for (i, label) in labels.enumerated() {
            if label > 0 {
                clusters[label, default: []].append(i)
            }
        }

        // Need at least 2 clusters
        if clusters.count < 2 { return .number(0) }

        var totalSilhouette: Double = 0
        var count = 0

        for i in 0..<n {
            let labelI = labels[i]
            if labelI <= 0 { continue }

            guard let sameCluster = clusters[labelI] else { continue }

            // a(i): mean distance to same cluster
            var aI: Double = 0
            if sameCluster.count > 1 {
                for j in sameCluster {
                    if j != i {
                        aI += euclideanDistance(data[i], data[j])
                    }
                }
                aI /= Double(sameCluster.count - 1)
            }

            // b(i): min mean distance to other clusters
            var bI = Double.infinity
            for (otherLabel, otherCluster) in clusters {
                if otherLabel != labelI {
                    var meanDist: Double = 0
                    for j in otherCluster {
                        meanDist += euclideanDistance(data[i], data[j])
                    }
                    meanDist /= Double(otherCluster.count)
                    if meanDist < bI { bI = meanDist }
                }
            }

            // Silhouette coefficient
            let maxAB = max(aI, bI)
            let sI = maxAB > 0 ? (bI - aI) / maxAB : 0

            totalSilhouette += sI
            count += 1
        }

        return .number(count > 0 ? totalSilhouette / Double(count) : 0)
    }

    // MARK: - Elbow Method Implementation

    private static func elbowMethodCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let data = extractPoints(args[0]) else {
            throw LuaError.runtimeError("elbow_method: expected data array")
        }

        var maxK = args.count >= 2 ? (args[1].numberValue.map { Int($0) } ?? 10) : 10
        maxK = min(maxK, data.count)

        var inertias: [Double] = []

        for k in 1...maxK {
            // Run k-means with reduced n_init for speed
            let centroids = kmeansPlusPlusInit(data: data, k: k, dim: data.first?.count ?? 0)
            let (_, _, inertia, _) = runKMeans(
                data: data, k: k, initialCentroids: centroids,
                maxIter: DEFAULT_MAX_ITER, tol: DEFAULT_TOL
            )
            inertias.append(inertia)
        }

        // Simple heuristic: find elbow using maximum curvature
        var suggestedK = 1
        var maxDiffRatio: Double = 0

        for k in 2..<(maxK - 1) {
            let diff1 = inertias[k - 2] - inertias[k - 1]
            let diff2 = inertias[k - 1] - inertias[k]
            if diff2 > 0 {
                let ratio = diff1 / diff2
                if ratio > maxDiffRatio {
                    maxDiffRatio = ratio
                    suggestedK = k
                }
            }
        }

        return .table([
            "inertias": .array(inertias.map { .number($0) }),
            "suggested_k": .number(Double(suggestedK))
        ])
    }
}
