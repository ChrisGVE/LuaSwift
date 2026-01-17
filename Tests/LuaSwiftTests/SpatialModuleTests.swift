//
//  SpatialModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

#if LUASWIFT_NUMERICSWIFT
import XCTest
@testable import LuaSwift

final class SpatialModuleTests: XCTestCase {
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

    // MARK: - Distance Function Tests

    func testEuclideanDistance() throws {
        let result = try engine.evaluate("""
            return math.spatial.distance.euclidean({0, 0}, {3, 4})
            """)
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testEuclideanDistance3D() throws {
        let result = try engine.evaluate("""
            return math.spatial.distance.euclidean({0, 0, 0}, {1, 2, 2})
            """)
        XCTAssertEqual(result.numberValue!, 3.0, accuracy: 1e-10)
    }

    func testSquaredEuclideanDistance() throws {
        let result = try engine.evaluate("""
            return math.spatial.distance.sqeuclidean({0, 0}, {3, 4})
            """)
        XCTAssertEqual(result.numberValue!, 25.0, accuracy: 1e-10)
    }

    func testCityblockDistance() throws {
        let result = try engine.evaluate("""
            return math.spatial.distance.cityblock({0, 0}, {3, 4})
            """)
        XCTAssertEqual(result.numberValue!, 7.0, accuracy: 1e-10)
    }

    func testChebyshevDistance() throws {
        let result = try engine.evaluate("""
            return math.spatial.distance.chebyshev({0, 0}, {3, 4})
            """)
        XCTAssertEqual(result.numberValue!, 4.0, accuracy: 1e-10)
    }

    func testMinkowskiDistance() throws {
        // p=1 should match cityblock
        let result = try engine.evaluate("""
            return math.spatial.distance.minkowski({0, 0}, {3, 4}, 1)
            """)
        XCTAssertEqual(result.numberValue!, 7.0, accuracy: 1e-10)
    }

    func testCosineDistance() throws {
        // Identical vectors should have cosine distance 0
        let result = try engine.evaluate("""
            return math.spatial.distance.cosine({1, 0}, {1, 0})
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testCosineDistanceOrthogonal() throws {
        // Orthogonal vectors should have cosine distance 1
        let result = try engine.evaluate("""
            return math.spatial.distance.cosine({1, 0}, {0, 1})
            """)
        XCTAssertEqual(result.numberValue!, 1.0, accuracy: 1e-10)
    }

    func testCorrelationDistance() throws {
        // Perfectly correlated vectors should have correlation distance 0
        let result = try engine.evaluate("""
            return math.spatial.distance.correlation({1, 2, 3}, {2, 4, 6})
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    // MARK: - cdist Tests

    func testCdistBasic() throws {
        let result = try engine.evaluate("""
            local A = {{0, 0}, {1, 1}}
            local B = {{0, 0}, {2, 2}}
            local dists = math.spatial.cdist(A, B)
            return #dists
            """)
        XCTAssertEqual(result.numberValue, 2)
    }

    func testCdistDimensions() throws {
        let result = try engine.evaluate("""
            local A = {{0, 0}, {1, 1}, {2, 2}}
            local B = {{0, 0}, {3, 3}}
            local dists = math.spatial.cdist(A, B)
            return #dists[1]  -- Should have 2 columns
            """)
        XCTAssertEqual(result.numberValue, 2)
    }

    func testCdistValues() throws {
        let result = try engine.evaluate("""
            local A = {{0, 0}}
            local B = {{3, 4}}
            local dists = math.spatial.cdist(A, B)
            return dists[1][1]
            """)
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testCdistCityblock() throws {
        let result = try engine.evaluate("""
            local A = {{0, 0}}
            local B = {{3, 4}}
            local dists = math.spatial.cdist(A, B, "cityblock")
            return dists[1][1]
            """)
        XCTAssertEqual(result.numberValue!, 7.0, accuracy: 1e-10)
    }

    // MARK: - pdist Tests

    func testPdistBasic() throws {
        let result = try engine.evaluate("""
            local X = {{0, 0}, {1, 0}, {0, 1}}
            local dists = math.spatial.pdist(X)
            return #dists  -- Should have n*(n-1)/2 = 3 elements
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testPdistValues() throws {
        let result = try engine.evaluate("""
            local X = {{0, 0}, {3, 4}}
            local dists = math.spatial.pdist(X)
            return dists[1]
            """)
        XCTAssertEqual(result.numberValue!, 5.0, accuracy: 1e-10)
    }

    func testPdistMetric() throws {
        let result = try engine.evaluate("""
            local X = {{0, 0}, {3, 4}}
            local dists = math.spatial.pdist(X, "cityblock")
            return dists[1]
            """)
        XCTAssertEqual(result.numberValue!, 7.0, accuracy: 1e-10)
    }

    // MARK: - squareform Tests

    func testSquareformCondensedToSquare() throws {
        let result = try engine.evaluate("""
            local condensed = {1, 2, 3}  -- 3 points
            local square = math.spatial.squareform(condensed)
            return #square
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testSquareformSymmetric() throws {
        let result = try engine.evaluate("""
            local condensed = {1, 2, 3}
            local square = math.spatial.squareform(condensed)
            return square[1][2] == square[2][1] and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testSquareformDiagonalZero() throws {
        let result = try engine.evaluate("""
            local condensed = {1, 2, 3}
            local square = math.spatial.squareform(condensed)
            return square[1][1] == 0 and square[2][2] == 0 and square[3][3] == 0 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testSquareformRoundTrip() throws {
        let result = try engine.evaluate("""
            local condensed = {1, 2, 3, 4, 5, 6}  -- 4 points
            local square = math.spatial.squareform(condensed)
            local back = math.spatial.squareform(square)
            local same = true
            for i = 1, #condensed do
                if math.abs(condensed[i] - back[i]) > 1e-10 then same = false end
            end
            return same and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - KDTree Tests

    func testKDTreeCreation() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 1}, {2, 2}}
            local tree = math.spatial.KDTree(points)
            return tree.n
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testKDTreeQueryOne() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {5, 5}, {10, 10}}
            local tree = math.spatial.KDTree(points)
            local indices, distances = tree:query({0.1, 0.1}, 1)
            return indices[1]  -- Should be point 1
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testKDTreeQueryTwo() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {5, 5}, {10, 10}}
            local tree = math.spatial.KDTree(points)
            local indices, distances = tree:query({4, 4}, 2)
            return #indices
            """)
        XCTAssertEqual(result.numberValue, 2)
    }

    func testKDTreeQueryDistance() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {3, 4}}
            local tree = math.spatial.KDTree(points)
            local indices, distances = tree:query({0, 0}, 2)
            -- Distance to first point should be 0
            return distances[1]
            """)
        XCTAssertEqual(result.numberValue!, 0.0, accuracy: 1e-10)
    }

    func testKDTreeQueryRadius() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {2, 0}, {10, 0}}
            local tree = math.spatial.KDTree(points)
            local indices, distances = tree:query_radius({0, 0}, 2.5)
            return #indices  -- Should include first 3 points
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testKDTreeQueryRadiusEmpty() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {5, 5}, {10, 10}}
            local tree = math.spatial.KDTree(points)
            local indices, distances = tree:query_radius({100, 100}, 1)
            return #indices
            """)
        XCTAssertEqual(result.numberValue, 0)
    }

    func testKDTreeQueryPairs() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {10, 10}}
            local tree = math.spatial.KDTree(points)
            local pairs = tree:query_pairs(2)
            return #pairs  -- Only first two points within distance 2
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testKDTree3D() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0, 0}, {1, 1, 1}, {2, 2, 2}}
            local tree = math.spatial.KDTree(points)
            local indices, distances = tree:query({0, 0, 0}, 1)
            return indices[1]
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - Delaunay Tests

    func testDelaunayBasic() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {0.5, 1}}
            local tri = math.spatial.Delaunay(points)
            return #tri.simplices
            """)
        XCTAssertEqual(result.numberValue, 1)  // One triangle
    }

    func testDelaunaySquare() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}
            local tri = math.spatial.Delaunay(points)
            return #tri.simplices
            """)
        XCTAssertEqual(result.numberValue, 2)  // Two triangles
    }

    func testDelaunaySimplicesHaveThreePoints() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {0.5, 1}}
            local tri = math.spatial.Delaunay(points)
            return #tri.simplices[1]
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testDelaunayNeighbors() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {2, 0}, {1, 1}, {1, -1}}
            local tri = math.spatial.Delaunay(points)
            return tri.neighbors ~= nil and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testDelaunayTooFewPoints() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 1}}
            local tri = math.spatial.Delaunay(points)
            return #tri.simplices == 0 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testDelaunayCollinear() throws {
        // Collinear points should return line segments
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 1}, {2, 2}}
            local tri = math.spatial.Delaunay(points)
            return #tri.simplices
            """)
        XCTAssertEqual(result.numberValue, 2)  // Two line segments
    }

    // MARK: - Voronoi Tests

    func testVoronoiBasic() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {0.5, 1}}
            local vor = math.spatial.Voronoi(points)
            return vor.points ~= nil and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    func testVoronoiVertices() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {2, 0}, {1, 2}}
            local vor = math.spatial.Voronoi(points)
            return type(vor.vertices)
            """)
        XCTAssertEqual(result.stringValue, "table")
    }

    func testVoronoiRegions() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {2, 0}, {1, 2}}
            local vor = math.spatial.Voronoi(points)
            return #vor.regions
            """)
        XCTAssertEqual(result.numberValue, 3)  // One region per point
    }

    func testVoronoiEmptyPoints() throws {
        let result = try engine.evaluate("""
            local vor = math.spatial.Voronoi({})
            return #vor.vertices == 0 and #vor.regions == 0 and 1 or 0
            """)
        XCTAssertEqual(result.numberValue, 1)
    }

    // MARK: - ConvexHull Tests

    func testConvexHullTriangle() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {0.5, 1}}
            local hull = math.spatial.ConvexHull(points)
            return #hull.vertices
            """)
        XCTAssertEqual(result.numberValue, 3)
    }

    func testConvexHullSquare() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}
            local hull = math.spatial.ConvexHull(points)
            return #hull.vertices
            """)
        XCTAssertEqual(result.numberValue, 4)
    }

    func testConvexHullWithInterior() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {2, 0}, {2, 2}, {0, 2}, {1, 1}}
            local hull = math.spatial.ConvexHull(points)
            return #hull.vertices  -- Interior point not on hull
            """)
        XCTAssertEqual(result.numberValue, 4)
    }

    func testConvexHullSimplices() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}
            local hull = math.spatial.ConvexHull(points)
            return #hull.simplices  -- Should have 4 edges
            """)
        XCTAssertEqual(result.numberValue, 4)
    }

    func testConvexHullTwoPoints() throws {
        let result = try engine.evaluate("""
            local points = {{0, 0}, {1, 1}}
            local hull = math.spatial.ConvexHull(points)
            return #hull.vertices
            """)
        XCTAssertEqual(result.numberValue, 2)
    }

    // MARK: - Namespace Tests

    func testMathSpatialNamespace() throws {
        let result = try engine.evaluate("return type(math.spatial)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testLuaswiftSpatialNamespace() throws {
        let result = try engine.evaluate("return type(luaswift.spatial)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testDistanceNamespace() throws {
        let result = try engine.evaluate("return type(math.spatial.distance)")
        XCTAssertEqual(result.stringValue, "table")
    }

    func testKDTreeExists() throws {
        let result = try engine.evaluate("return type(math.spatial.KDTree)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testCdistExists() throws {
        let result = try engine.evaluate("return type(math.spatial.cdist)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testPdistExists() throws {
        let result = try engine.evaluate("return type(math.spatial.pdist)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testDelaunayExists() throws {
        let result = try engine.evaluate("return type(math.spatial.Delaunay)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testVoronoiExists() throws {
        let result = try engine.evaluate("return type(math.spatial.Voronoi)")
        XCTAssertEqual(result.stringValue, "function")
    }

    func testConvexHullExists() throws {
        let result = try engine.evaluate("return type(math.spatial.ConvexHull)")
        XCTAssertEqual(result.stringValue, "function")
    }
}
#endif  // LUASWIFT_NUMERICSWIFT
