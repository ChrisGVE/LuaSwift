//
//  ClusterModule.swift
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

/// Swift-backed clustering module for LuaSwift.
///
/// Provides clustering algorithms including k-means, hierarchical clustering,
/// and DBSCAN. Uses NumericSwift's Accelerate-optimized implementations.
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

    // MARK: - K-Means Implementation

    private static func kmeansCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let data = extractPoints(args[0]),
              let k = args[1].numberValue.map({ Int($0) }) else {
            throw LuaError.runtimeError("kmeans: expected data array and k")
        }

        if data.isEmpty {
            return .table([
                "labels": .array([]),
                "centroids": .array([]),
                "inertia": .number(0),
                "n_iter": .number(0)
            ])
        }

        let options = args.count >= 3 ? extractOptions(args[2]) : [:]
        let maxIter = options["max_iter"]?.numberValue.map { Int($0) } ?? DEFAULT_MAX_ITER
        let tol = options["tol"]?.numberValue ?? DEFAULT_TOL
        let nInit = options["n_init"]?.numberValue.map { Int($0) } ?? DEFAULT_N_INIT
        let initMethod = options["init"]?.stringValue ?? "k-means++"

        // Use NumericSwift's kmeans implementation
        let result = kmeans(
            data,
            k: k,
            maxIterations: maxIter,
            tolerance: tol,
            nInit: nInit,
            initMethod: initMethod == "random" ? "random" : "kmeans++"
        )

        // Convert 0-indexed labels to 1-indexed for Lua
        let luaLabels: [LuaValue] = result.labels.map { .number(Double($0 + 1)) }

        return .table([
            "labels": .array(luaLabels),
            "centroids": .array(result.centroids.map { centroid in
                .array(centroid.map { .number($0) })
            }),
            "inertia": .number(result.inertia),
            "n_iter": .number(Double(result.iterations))
        ])
    }

    // MARK: - Hierarchical Clustering Implementation

    private static func hierarchicalCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let data = extractPoints(args[0]) else {
            throw LuaError.runtimeError("hierarchical: expected data array")
        }

        if data.isEmpty {
            return .table([
                "linkage_matrix": .array([]),
                "labels": .nil,
                "n_leaves": .number(0)
            ])
        }

        let options = args.count >= 2 ? extractOptions(args[1]) : [:]
        let linkageStr = (options["linkage"]?.stringValue ?? "ward").lowercased()
        let nClusters = options["n_clusters"]?.numberValue.map { Int($0) }
        let distanceThreshold = options["distance_threshold"]?.numberValue

        // Map string to NumericSwift linkage method
        let linkage: LinkageMethod
        switch linkageStr {
        case "single": linkage = .single
        case "complete": linkage = .complete
        case "average": linkage = .average
        default: linkage = .ward
        }

        // Use NumericSwift's hierarchical clustering
        let result = hierarchicalClustering(
            data,
            linkage: linkage,
            nClusters: nClusters,
            distanceThreshold: distanceThreshold
        )

        // Convert linkage matrix to 1-indexed for Lua
        // NumericSwift returns 0-indexed cluster IDs, we need 1-indexed
        let luaLinkage = result.linkageMatrix.map { row in
            LuaValue.array([
                .number(row[0] + 1),  // cluster1 (1-indexed)
                .number(row[1] + 1),  // cluster2 (1-indexed)
                .number(row[2]),       // distance
                .number(row[3])        // size
            ])
        }

        // Convert labels to 1-indexed if present
        var labels: LuaValue = .nil
        if let resultLabels = result.labels {
            labels = .array(resultLabels.map { .number(Double($0 + 1)) })
        }

        return .table([
            "linkage_matrix": .array(luaLinkage),
            "labels": labels,
            "n_leaves": .number(Double(result.nLeaves))
        ])
    }

    // MARK: - DBSCAN Implementation

    private static func dbscanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let data = extractPoints(args[0]) else {
            throw LuaError.runtimeError("dbscan: expected data array")
        }

        if data.isEmpty {
            return .table([
                "labels": .array([]),
                "core_samples": .array([]),
                "n_clusters": .number(0)
            ])
        }

        let options = args.count >= 2 ? extractOptions(args[1]) : [:]
        let eps = options["eps"]?.numberValue ?? 0.5
        let minSamples = options["min_samples"]?.numberValue.map { Int($0) } ?? 5

        // Use NumericSwift's DBSCAN implementation
        let result = dbscan(data, eps: eps, minSamples: minSamples)

        // Convert labels: NumericSwift uses -1 for noise, 0+ for clusters
        // Lua API expects -1 for noise, 1+ for clusters
        let luaLabels = result.labels.map { label in
            LuaValue.number(Double(label >= 0 ? label + 1 : label))
        }

        // Convert core samples to 1-indexed for Lua
        let luaCoreSamples: [LuaValue] = result.coreSamples.map { .number(Double($0 + 1)) }

        return .table([
            "labels": .array(luaLabels),
            "core_samples": .array(luaCoreSamples),
            "n_clusters": .number(Double(result.nClusters))
        ])
    }

    // MARK: - Silhouette Score Implementation

    private static func silhouetteScoreCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let data = extractPoints(args[0]),
              let labels = extractLabels(args[1]) else {
            throw LuaError.runtimeError("silhouette_score: expected data and labels")
        }

        if data.count < 2 { return .number(0) }

        // Convert Lua 1-indexed labels to 0-indexed for NumericSwift
        // Lua uses: -1 for noise, 1+ for clusters
        // NumericSwift expects: -1 for noise, 0+ for clusters
        let swiftLabels = labels.map { label in
            label <= 0 ? label : label - 1
        }

        // Use NumericSwift's silhouette score implementation
        let score = silhouetteScore(data, labels: swiftLabels)
        return .number(score)
    }

    // MARK: - Elbow Method Implementation

    private static func elbowMethodCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let data = extractPoints(args[0]) else {
            throw LuaError.runtimeError("elbow_method: expected data array")
        }

        if data.isEmpty {
            return .table([
                "inertias": .array([]),
                "suggested_k": .number(1)
            ])
        }

        let maxK = args.count >= 2 ? (args[1].numberValue.map { Int($0) } ?? 10) : 10

        // Use NumericSwift's elbow method implementation
        let result = elbowMethod(data, maxK: maxK)

        return .table([
            "inertias": .array(result.inertias.map { .number($0) }),
            "suggested_k": .number(Double(result.suggestedK))
        ])
    }
}

#endif  // LUASWIFT_NUMERICSWIFT
