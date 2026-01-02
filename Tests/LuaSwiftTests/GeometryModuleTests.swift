//
//  GeometryModuleTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Testing
@testable import LuaSwift

@Suite("Geometry Module Tests")
struct GeometryModuleTests {

    // MARK: - Vec2 Tests

    @Test("Vec2 creation and properties")
    func vec2Creation() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec2(3, 4)
            return {v.x, v.y, tostring(v)}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 3)
        #expect(arr[1].numberValue == 4)
        #expect(arr[2].stringValue?.contains("vec2") == true)
    }

    @Test("Vec2 length and normalize")
    func vec2LengthNormalize() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec2(3, 4)
            local len = v:length()
            local norm = v:normalize()
            return {len, norm.x, norm.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001)
        #expect(abs(arr[1].numberValue! - 0.6) < 0.0001)
        #expect(abs(arr[2].numberValue! - 0.8) < 0.0001)
    }

    @Test("Vec2 dot product")
    func vec2Dot() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec2(1, 2)
            local v2 = geo.vec2(3, 4)
            return v1:dot(v2)
        """)

        #expect(result.numberValue == 11)
    }

    @Test("Vec2 cross product")
    func vec2Cross() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec2(1, 0)
            local v2 = geo.vec2(0, 1)
            return v1:cross(v2)
        """)

        #expect(result.numberValue == 1)
    }

    @Test("Vec2 rotate")
    func vec2Rotate() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec2(1, 0)
            local rotated = v:rotate(math.pi / 2)
            return {rotated.x, rotated.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001)
        #expect(abs(arr[1].numberValue! - 1.0) < 0.0001)
    }

    @Test("Vec2 operators")
    func vec2Operators() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec2(1, 2)
            local v2 = geo.vec2(3, 4)
            local add = v1 + v2
            local sub = v1 - v2
            local mul = v1 * 2
            local div = v2 / 2
            local neg = -v1
            return {add.x, add.y, sub.x, sub.y, mul.x, mul.y, div.x, div.y, neg.x, neg.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 4)  // add.x
        #expect(arr[1].numberValue == 6)  // add.y
        #expect(arr[2].numberValue == -2) // sub.x
        #expect(arr[3].numberValue == -2) // sub.y
        #expect(arr[4].numberValue == 2)  // mul.x
        #expect(arr[5].numberValue == 4)  // mul.y
        #expect(arr[6].numberValue == 1.5) // div.x
        #expect(arr[7].numberValue == 2)  // div.y
        #expect(arr[8].numberValue == -1) // neg.x
        #expect(arr[9].numberValue == -2) // neg.y
    }

    @Test("Vec2 lerp")
    func vec2Lerp() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec2(0, 0)
            local v2 = geo.vec2(10, 10)
            local mid = v1:lerp(v2, 0.5)
            return {mid.x, mid.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 5)
        #expect(arr[1].numberValue == 5)
    }

    // MARK: - Vec3 Tests

    @Test("Vec3 creation and properties")
    func vec3Creation() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec3(1, 2, 3)
            return {v.x, v.y, v.z, tostring(v)}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 2)
        #expect(arr[2].numberValue == 3)
        #expect(arr[3].stringValue?.contains("vec3") == true)
    }

    @Test("Vec3 length and normalize")
    func vec3LengthNormalize() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec3(1, 2, 2)
            local len = v:length()
            local norm = v:normalize()
            return {len, norm:length()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 3.0) < 0.0001)
        #expect(abs(arr[1].numberValue! - 1.0) < 0.0001)
    }

    @Test("Vec3 cross product")
    func vec3Cross() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec3(1, 0, 0)
            local v2 = geo.vec3(0, 1, 0)
            local cross = v1:cross(v2)
            return {cross.x, cross.y, cross.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 0)
        #expect(arr[1].numberValue == 0)
        #expect(arr[2].numberValue == 1)
    }

    @Test("Vec3 operators")
    func vec3Operators() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec3(1, 2, 3)
            local v2 = geo.vec3(4, 5, 6)
            local add = v1 + v2
            local sub = v2 - v1
            return {add.x, add.y, add.z, sub.x, sub.y, sub.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 5)
        #expect(arr[1].numberValue == 7)
        #expect(arr[2].numberValue == 9)
        #expect(arr[3].numberValue == 3)
        #expect(arr[4].numberValue == 3)
        #expect(arr[5].numberValue == 3)
    }

    // MARK: - Quaternion Tests

    @Test("Quaternion identity")
    func quatIdentity() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local q = geo.quaternion.identity()
            return {q.w, q.x, q.y, q.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 0)
        #expect(arr[2].numberValue == 0)
        #expect(arr[3].numberValue == 0)
    }

    @Test("Quaternion from axis-angle")
    func quatFromAxisAngle() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local axis = geo.vec3(0, 1, 0)
            local q = geo.quaternion.from_axis_angle(axis, math.pi)
            local len = q:length()
            return len
        """)

        #expect(abs(result.numberValue! - 1.0) < 0.0001)
    }

    @Test("Quaternion rotate vector")
    func quatRotateVector() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local axis = geo.vec3(0, 0, 1)  -- Z-axis
            local q = geo.quaternion.from_axis_angle(axis, math.pi / 2)  -- 90 degrees
            local v = geo.vec3(1, 0, 0)  -- X-axis unit vector
            local rotated = q:rotate(v)
            return {rotated.x, rotated.y, rotated.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001)
        #expect(abs(arr[1].numberValue! - 1.0) < 0.0001)
        #expect(abs(arr[2].numberValue!) < 0.0001)
    }

    @Test("Quaternion slerp")
    func quatSlerp() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local q1 = geo.quaternion.identity()
            local axis = geo.vec3(0, 0, 1)
            local q2 = geo.quaternion.from_axis_angle(axis, math.pi)
            local mid = q1:slerp(q2, 0.5)
            return mid:length()
        """)

        #expect(abs(result.numberValue! - 1.0) < 0.0001)
    }

    // MARK: - Transform3D Tests

    @Test("Transform3D identity")
    func transform3DIdentity() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local t = geo.transform3d()
            local v = geo.vec3(1, 2, 3)
            local result = t:apply(v)
            return {result.x, result.y, result.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 2)
        #expect(arr[2].numberValue == 3)
    }

    @Test("Transform3D translate")
    func transform3DTranslate() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local t = geo.transform3d():translate(10, 20, 30)
            local v = geo.vec3(1, 2, 3)
            local result = t:apply(v)
            return {result.x, result.y, result.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 11)
        #expect(arr[1].numberValue == 22)
        #expect(arr[2].numberValue == 33)
    }

    @Test("Transform3D scale")
    func transform3DScale() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local t = geo.transform3d():scale(2, 3, 4)
            local v = geo.vec3(1, 1, 1)
            local result = t:apply(v)
            return {result.x, result.y, result.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 2)
        #expect(arr[1].numberValue == 3)
        #expect(arr[2].numberValue == 4)
    }

    // MARK: - Geometric Calculations Tests

    @Test("Distance calculation")
    func distanceCalc() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec2(0, 0)
            local v2 = geo.vec2(3, 4)
            return geo.distance(v1, v2)
        """)

        #expect(result.numberValue == 5)
    }

    @Test("Convex hull")
    func convexHull() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                {x = 0, y = 0},
                {x = 2, y = 0},
                {x = 2, y = 2},
                {x = 0, y = 2},
                {x = 1, y = 1}  -- interior point
            }
            local hull = geo.convex_hull(points)
            return #hull
        """)

        #expect(result.numberValue == 4)  // 4 hull points (square corners)
    }

    @Test("Point in polygon")
    func pointInPolygon() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local polygon = {
                {x = 0, y = 0},
                {x = 4, y = 0},
                {x = 4, y = 4},
                {x = 0, y = 4}
            }
            local inside = geo.point_in_polygon({x = 2, y = 2}, polygon)
            local outside = geo.point_in_polygon({x = 5, y = 5}, polygon)
            return {inside, outside}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)
        #expect(arr[1].boolValue == false)
    }

    @Test("Line intersection")
    func lineIntersection() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local line1 = {{x = 0, y = 0}, {x = 2, y = 2}}
            local line2 = {{x = 0, y = 2}, {x = 2, y = 0}}
            local point = geo.line_intersection(line1, line2)
            return {point.x, point.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 1)
    }

    @Test("Triangle area")
    func areaTriangle() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p1 = {x = 0, y = 0}
            local p2 = {x = 4, y = 0}
            local p3 = {x = 0, y = 3}
            return geo.area_triangle(p1, p2, p3)
        """)

        #expect(result.numberValue == 6)
    }

    @Test("Centroid calculation")
    func centroid() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                {x = 0, y = 0},
                {x = 3, y = 0},
                {x = 0, y = 3}
            }
            local c = geo.centroid(points)
            return {c.x, c.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 1)
    }

    @Test("Circle from 3 points")
    func circleFrom3Points() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p1 = {x = 0, y = 1}
            local p2 = {x = 1, y = 0}
            local p3 = {x = -1, y = 0}
            local circle = geo.circle_from_3_points(p1, p2, p3)
            return {circle.center.x, circle.center.y, circle.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001)
        #expect(abs(arr[1].numberValue!) < 0.0001)
        #expect(abs(arr[2].numberValue! - 1.0) < 0.0001)
    }

    @Test("Plane from 3 points")
    func planeFrom3Points() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p1 = geo.vec3(0, 0, 0)
            local p2 = geo.vec3(1, 0, 0)
            local p3 = geo.vec3(0, 1, 0)
            local plane = geo.plane_from_3_points(p1, p2, p3)
            return {plane.normal.x, plane.normal.y, plane.normal.z, plane.d}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001)
        #expect(abs(arr[1].numberValue!) < 0.0001)
        #expect(abs(arr[2].numberValue! - 1.0) < 0.0001)
        #expect(abs(arr[3].numberValue!) < 0.0001)
    }
}
