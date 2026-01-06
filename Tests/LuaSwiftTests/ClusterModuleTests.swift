//
//  ClusterModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class ClusterModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installModules(in: engine)
            try engine.run("luaswift.extend_stdlib()")
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - kmeans Tests

    func testKmeansTwoClusters() throws {
        // Two well-separated clusters
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {0.5, 0}, {0, 0.5}, {0.5, 0.5},
                {5, 5}, {5.5, 5}, {5, 5.5}, {5.5, 5.5}
            }
            local result = math.cluster.kmeans(data, 2)
            -- All first 4 points should be in same cluster, last 4 in another
            local first_label = result.labels[1]
            local second_label = result.labels[5]
            local same_first = (result.labels[1] == result.labels[2] and
                               result.labels[2] == result.labels[3] and
                               result.labels[3] == result.labels[4])
            local same_second = (result.labels[5] == result.labels[6] and
                                result.labels[6] == result.labels[7] and
                                result.labels[7] == result.labels[8])
            local different = (first_label ~= second_label)
            return (same_first and same_second and different) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testKmeansThreeClusters() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {0.1, 0.1},
                {5, 0}, {5.1, 0.1},
                {2.5, 4}, {2.5, 4.1}
            }
            local result = math.cluster.kmeans(data, 3)
            -- Should have 3 distinct clusters
            local unique = {}
            for _, label in ipairs(result.labels) do
                unique[label] = true
            end
            local count = 0
            for _ in pairs(unique) do count = count + 1 end
            return count
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testKmeansReturnsLabels() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {5, 5}, {6, 6}}
            local result = math.cluster.kmeans(data, 2)
            return #result.labels
            """)
        XCTAssertEqual(result.numberValue, 4)
    }

    func testKmeansReturnsCentroids() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {5, 5}, {6, 6}}
            local result = math.cluster.kmeans(data, 2)
            return #result.centroids
            """)
        XCTAssertEqual(result.numberValue, 2)
    }

    func testKmeansReturnsInertia() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {0, 0}, {5, 5}, {5, 5}}
            local result = math.cluster.kmeans(data, 2)
            -- Perfect clustering should have 0 inertia
            return result.inertia
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-6)
    }

    func testKmeansConvergence() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {5, 5}, {6, 6}}
            local result = math.cluster.kmeans(data, 2)
            return result.n_iter > 0 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testKmeansKPlusPlusInit() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {10, 10}, {11, 11}}
            local result = math.cluster.kmeans(data, 2, {init = "k-means++"})
            return result.inertia < 10 and 1 or 0  -- Should find good clusters
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testKmeansRandomInit() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {10, 10}, {11, 11}}
            local result = math.cluster.kmeans(data, 2, {init = "random", n_init = 5})
            return #result.labels
            """)
        XCTAssertEqual(result.numberValue, 4)
    }

    func testKmeansEmptyData() throws {
        let result = try engine.evaluate("""
            local data = {}
            local result = math.cluster.kmeans(data, 2)
            return #result.labels == 0 and #result.centroids == 0 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testKmeansSinglePoint() throws {
        let result = try engine.evaluate("""
            local data = {{5, 5}}
            local result = math.cluster.kmeans(data, 1)
            return result.labels[1] == 1 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - hierarchical Tests

    func testHierarchicalTwoClusters() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {0.5, 0.5},
                {10, 10}, {10.5, 10.5}
            }
            local result = math.cluster.hierarchical(data, {n_clusters = 2})
            -- First two points should be one cluster, last two another
            local same_first = (result.labels[1] == result.labels[2])
            local same_second = (result.labels[3] == result.labels[4])
            local different = (result.labels[1] ~= result.labels[3])
            return (same_first and same_second and different) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testHierarchicalLinkageMatrix() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {5, 5}, {6, 6}}
            local result = math.cluster.hierarchical(data)
            -- Linkage matrix should have n-1 rows
            return #result.linkage_matrix
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testHierarchicalLinkageMatrixColumns() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {5, 5}}
            local result = math.cluster.hierarchical(data)
            -- Each row should have 4 columns: [cluster1, cluster2, distance, size]
            return #result.linkage_matrix[1]
            """)
        XCTAssertEqual(result.numberValue, 4)
    }

    func testHierarchicalWardLinkage() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {10, 10}, {11, 11}}
            local result = math.cluster.hierarchical(data, {linkage = "ward", n_clusters = 2})
            return result.labels ~= nil and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testHierarchicalCompleteLinkage() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {10, 10}, {11, 11}}
            local result = math.cluster.hierarchical(data, {linkage = "complete", n_clusters = 2})
            return result.labels ~= nil and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testHierarchicalAverageLinkage() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {10, 10}, {11, 11}}
            local result = math.cluster.hierarchical(data, {linkage = "average", n_clusters = 2})
            return result.labels ~= nil and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testHierarchicalSingleLinkage() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {10, 10}, {11, 11}}
            local result = math.cluster.hierarchical(data, {linkage = "single", n_clusters = 2})
            return result.labels ~= nil and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testHierarchicalDistanceThreshold() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {0.1, 0.1}, {10, 10}, {10.1, 10.1}}
            local result = math.cluster.hierarchical(data, {distance_threshold = 5})
            -- Should cut tree to form at least 2 clusters
            local unique = {}
            for _, label in ipairs(result.labels) do unique[label] = true end
            local count = 0
            for _ in pairs(unique) do count = count + 1 end
            return count >= 2 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testHierarchicalNLeaves() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}}
            local result = math.cluster.hierarchical(data)
            return result.n_leaves
            """)
        XCTAssertEqual(result.numberValue, 5)
    }

    func testHierarchicalEmptyData() throws {
        let result = try engine.evaluate("""
            local data = {}
            local result = math.cluster.hierarchical(data)
            return result.n_leaves == 0 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - DBSCAN Tests

    func testDbscanTwoClusters() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {0.1, 0}, {0, 0.1},
                {5, 5}, {5.1, 5}, {5, 5.1}
            }
            local result = math.cluster.dbscan(data, {eps = 0.5, min_samples = 2})
            return result.n_clusters
            """)
        XCTAssertEqual(result.numberValue, 2)
    }

    func testDbscanNoiseDetection() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {0.1, 0}, {0, 0.1},
                {10, 10}  -- Isolated point = noise
            }
            local result = math.cluster.dbscan(data, {eps = 0.5, min_samples = 3})
            -- Last point should be noise (-1)
            return result.labels[4]
            """)
        XCTAssertEqual(result.numberValue, -1)
    }

    func testDbscanCorePointsIdentified() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {0.1, 0}, {0, 0.1}, {0.1, 0.1}
            }
            local result = math.cluster.dbscan(data, {eps = 0.5, min_samples = 3})
            return #result.core_samples > 0 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testDbscanReturnsLabels() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {2, 2}}
            local result = math.cluster.dbscan(data, {eps = 2, min_samples = 2})
            return #result.labels
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testDbscanAllNoise() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {10, 10}, {20, 20}}
            local result = math.cluster.dbscan(data, {eps = 0.1, min_samples = 2})
            -- All points should be noise
            local all_noise = true
            for _, label in ipairs(result.labels) do
                if label ~= -1 then all_noise = false end
            end
            return all_noise and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testDbscanSingleCluster() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {0.1, 0.1}, {0.2, 0.2}, {0.3, 0.3}}
            local result = math.cluster.dbscan(data, {eps = 0.5, min_samples = 2})
            -- All points should be in same cluster
            local first_label = result.labels[1]
            local all_same = true
            for _, label in ipairs(result.labels) do
                if label ~= first_label then all_same = false end
            end
            return (all_same and first_label > 0) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testDbscanEmptyData() throws {
        let result = try engine.evaluate("""
            local data = {}
            local result = math.cluster.dbscan(data)
            return result.n_clusters == 0 and #result.labels == 0 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testDbscanDefaultParameters() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {0.1, 0}, {0, 0.1}}
            local result = math.cluster.dbscan(data)  -- Uses defaults
            return result.labels ~= nil and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - silhouette_score Tests

    func testSilhouetteScorePerfectClusters() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {0.1, 0.1}, {10, 10}, {10.1, 10.1}}
            local labels = {1, 1, 2, 2}
            local score = math.cluster.silhouette_score(data, labels)
            -- Perfect separation should give high score (close to 1)
            return score > 0.8 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testSilhouetteScoreRange() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {5, 5}, {6, 6}}
            local labels = {1, 1, 2, 2}
            local score = math.cluster.silhouette_score(data, labels)
            -- Score should be between -1 and 1
            return (score >= -1 and score <= 1) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testSilhouetteScoreSingleCluster() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {2, 2}}
            local labels = {1, 1, 1}
            local score = math.cluster.silhouette_score(data, labels)
            -- Single cluster returns 0
            return score
            """)
        XCTAssertEqual(result.numberValue, 0)
    }

    func testSilhouetteScoreIgnoresNoise() throws {
        let result = try engine.evaluate("""
            local data = {{0, 0}, {1, 1}, {5, 5}, {6, 6}, {100, 100}}
            local labels = {1, 1, 2, 2, -1}  -- Last point is noise
            local score = math.cluster.silhouette_score(data, labels)
            return (score >= -1 and score <= 1) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - elbow_method Tests

    func testElbowMethodReturnsInertias() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {0.5, 0.5}, {1, 1},
                {5, 5}, {5.5, 5.5}, {6, 6}
            }
            local result = math.cluster.elbow_method(data, 4)
            return #result.inertias
            """)
        XCTAssertEqual(result.numberValue, 4)
    }

    func testElbowMethodDecreasingInertia() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {1, 1}, {5, 5}, {6, 6}
            }
            local result = math.cluster.elbow_method(data, 3)
            -- Inertia should decrease as k increases
            return (result.inertias[1] >= result.inertias[2] and
                    result.inertias[2] >= result.inertias[3]) and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testElbowMethodSuggestsK() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0}, {0.1, 0.1},
                {5, 5}, {5.1, 5.1}
            }
            local result = math.cluster.elbow_method(data, 4)
            return result.suggested_k >= 1 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - Namespace Tests

    func testMathClusterNamespace() throws {
        let result = try engine.evaluate("return type(math.cluster)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testLuaswiftClusterNamespace() throws {
        let result = try engine.evaluate("return type(luaswift.cluster)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testKmeansExists() throws {
        let result = try engine.evaluate("return type(math.cluster.kmeans)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testHierarchicalExists() throws {
        let result = try engine.evaluate("return type(math.cluster.hierarchical)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testDbscanExists() throws {
        let result = try engine.evaluate("return type(math.cluster.dbscan)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testSilhouetteScoreExists() throws {
        let result = try engine.evaluate("return type(math.cluster.silhouette_score)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testElbowMethodExists() throws {
        let result = try engine.evaluate("return type(math.cluster.elbow_method)")
        XCTAssertEqual(result.stringValue, "function")
    }

    // MARK: - 3D Data Tests

    func testKmeans3D() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0, 0}, {0.1, 0.1, 0.1},
                {5, 5, 5}, {5.1, 5.1, 5.1}
            }
            local result = math.cluster.kmeans(data, 2)
            return #result.centroids[1]  -- Should be 3D centroids
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testDbscan3D() throws {
        let result = try engine.evaluate("""
            local data = {
                {0, 0, 0}, {0.1, 0, 0}, {0, 0.1, 0},
                {5, 5, 5}, {5.1, 5, 5}, {5, 5.1, 5}
            }
            local result = math.cluster.dbscan(data, {eps = 0.5, min_samples = 2})
            return result.n_clusters
            """)
        XCTAssertEqual(result.numberValue, 2)
    }
}
