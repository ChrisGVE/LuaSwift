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
import Foundation
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

    @Test("Distance with quaternions")
    func distanceQuaternion() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local q1 = geo.quaternion.identity()
            local q2 = geo.quaternion.identity()
            return geo.distance(q1, q2)
        """)

        #expect(result.numberValue == 0)
    }

    @Test("Distance sugar syntax vec2")
    func distanceSugarVec2() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec2(0, 0)
            local v2 = geo.vec2(3, 4)
            return v1:distance(v2)
        """)

        #expect(result.numberValue == 5)
    }

    @Test("Distance sugar syntax vec3")
    func distanceSugarVec3() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec3(0, 0, 0)
            local v2 = geo.vec3(1, 2, 2)
            return v1:distance(v2)
        """)

        #expect(result.numberValue == 3)
    }

    @Test("Distance sugar syntax quaternion")
    func distanceSugarQuat() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local q1 = geo.quaternion.identity()
            local q2 = geo.quaternion(1, 0, 0, 0)
            return q1:distance(q2)
        """)

        #expect(result.numberValue == 0)
    }

    @Test("Angle between vec2")
    func angleBetweenVec2() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec2(1, 0)
            local v2 = geo.vec2(0, 1)
            return geo.angle_between(v1, v2)
        """)

        let angle = try #require(result.numberValue)
        #expect(abs(angle - Double.pi / 2) < 1e-10)
    }

    @Test("Angle between vec3")
    func angleBetweenVec3() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec3(1, 0, 0)
            local v2 = geo.vec3(0, 1, 0)
            return geo.angle_between(v1, v2)
        """)

        let angle = try #require(result.numberValue)
        #expect(abs(angle - Double.pi / 2) < 1e-10)
    }

    @Test("Angle sugar syntax vec2")
    func angleSugarVec2() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec2(1, 0)
            local v2 = geo.vec2(0, 1)
            return v1:angle_to(v2)
        """)

        let angle = try #require(result.numberValue)
        #expect(abs(angle - Double.pi / 2) < 1e-10)
    }

    @Test("Angle sugar syntax vec3")
    func angleSugarVec3() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec3(1, 0, 0)
            local v2 = geo.vec3(0, 1, 0)
            return v1:angle_to(v2)
        """)

        let angle = try #require(result.numberValue)
        #expect(abs(angle - Double.pi / 2) < 1e-10)
    }

    @Test("Angle between parallel vectors")
    func angleBetweenParallel() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec3(1, 0, 0)
            local v2 = geo.vec3(2, 0, 0)
            return geo.angle_between(v1, v2)
        """)

        let angle = try #require(result.numberValue)
        #expect(abs(angle) < 1e-10)
    }

    @Test("Angle between opposite vectors")
    func angleBetweenOpposite() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v1 = geo.vec3(1, 0, 0)
            local v2 = geo.vec3(-1, 0, 0)
            return geo.angle_between(v1, v2)
        """)

        let angle = try #require(result.numberValue)
        #expect(abs(angle - Double.pi) < 1e-10)
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

    @Test("In polygon modern API")
    func inPolygonModern() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local polygon = {
                geo.vec2(0, 0),
                geo.vec2(4, 0),
                geo.vec2(4, 4),
                geo.vec2(0, 4)
            }
            local inside = geo.in_polygon(geo.vec2(2, 2), polygon)
            local outside = geo.in_polygon(geo.vec2(5, 5), polygon)
            return {inside, outside}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)
        #expect(arr[1].boolValue == false)
    }

    @Test("In polygon sugar syntax")
    func inPolygonSugar() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local polygon = {
                geo.vec2(0, 0),
                geo.vec2(4, 0),
                geo.vec2(4, 4),
                geo.vec2(0, 4)
            }
            local p1 = geo.vec2(2, 2)
            local p2 = geo.vec2(5, 5)
            return {p1:in_polygon(polygon), p2:in_polygon(polygon)}
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

    @Test("Plane-plane intersection")
    func planePlaneIntersection() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- XY plane (z=0)
            local plane1 = {normal = geo.vec3(0, 0, 1), d = 0}
            -- XZ plane (y=0)
            local plane2 = {normal = geo.vec3(0, 1, 0), d = 0}
            local line = geo.plane_plane_intersection(plane1, plane2)
            -- Intersection should be the x-axis
            return {line.direction.x, line.direction.y, line.direction.z}
        """)

        let arr = try #require(result.arrayValue)
        // Direction should be along x-axis (±1, 0, 0)
        #expect(abs(abs(arr[0].numberValue!) - 1.0) < 0.0001)
        #expect(abs(arr[1].numberValue!) < 0.0001)
        #expect(abs(arr[2].numberValue!) < 0.0001)
    }

    @Test("Polymorphic intersection line-line")
    func intersectionLineLine() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local line1 = {{x = 0, y = 0}, {x = 2, y = 2}}
            local line2 = {{x = 0, y = 2}, {x = 2, y = 0}}
            local point = geo.intersection(line1, line2)
            return {point.x, point.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 1)
    }

    @Test("Polymorphic intersection line-plane")
    func intersectionLinePlane() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Line from (0,0,0) in direction (1,1,1)
            local line = {origin = geo.vec3(0, 0, 0), direction = geo.vec3(1, 1, 1)}
            -- Plane z=1
            local plane = {normal = geo.vec3(0, 0, 1), d = -1}
            local point = geo.intersection(line, plane)
            return {point.x, point.y, point.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 1.0) < 0.0001)
        #expect(abs(arr[1].numberValue! - 1.0) < 0.0001)
        #expect(abs(arr[2].numberValue! - 1.0) < 0.0001)
    }

    @Test("Polymorphic intersection plane-plane")
    func intersectionPlanePlane() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- XY plane (z=0)
            local plane1 = {normal = geo.vec3(0, 0, 1), d = 0}
            -- XZ plane (y=0)
            local plane2 = {normal = geo.vec3(0, 1, 0), d = 0}
            local line = geo.intersection(plane1, plane2)
            -- Intersection should be the x-axis
            return {line.direction.x, line.direction.y, line.direction.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(abs(arr[0].numberValue!) - 1.0) < 0.0001)
        #expect(abs(arr[1].numberValue!) < 0.0001)
        #expect(abs(arr[2].numberValue!) < 0.0001)
    }

    @Test("Parallel planes no intersection")
    func parallelPlanesNoIntersection() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Two parallel XY planes at z=0 and z=1
            local plane1 = {normal = geo.vec3(0, 0, 1), d = 0}
            local plane2 = {normal = geo.vec3(0, 0, 1), d = -1}
            local line = geo.intersection(plane1, plane2)
            return line == nil
        """)

        #expect(result.boolValue == true)
    }

    // MARK: - Type Marker Tests

    @Test("Vec2 has __luaswift_type marker")
    func vec2TypeMarker() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec2(1, 2)
            return v.__luaswift_type
        """)

        #expect(result.stringValue == "vec2")
    }

    @Test("Vec3 has __luaswift_type marker")
    func vec3TypeMarker() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec3(1, 2, 3)
            return v.__luaswift_type
        """)

        #expect(result.stringValue == "vec3")
    }

    @Test("Quaternion has __luaswift_type marker")
    func quaternionTypeMarker() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local q = geo.quaternion(1, 0, 0, 0)
            return q.__luaswift_type
        """)

        #expect(result.stringValue == "quaternion")
    }

    @Test("Transform3D has __luaswift_type marker")
    func transform3DTypeMarker() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local t = geo.transform3d()
            return t.__luaswift_type
        """)

        #expect(result.stringValue == "transform3d")
    }

    // MARK: - Coordinate Conversion Tests

    @Test("Vec2 to_polar method")
    func vec2ToPolar() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec2(3, 4)
            local polar = v:to_polar()
            return {polar.r, polar.theta}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // r = sqrt(9 + 16) = 5
        #expect(abs(arr[1].numberValue! - 0.9273) < 0.001) // theta = atan2(4, 3) ≈ 0.9273
    }

    @Test("Vec2 to_polar at origin")
    func vec2ToPolarOrigin() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec2(0, 0)
            local polar = v:to_polar()
            return {polar.r, polar.theta}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001) // r = 0
        #expect(arr[1].numberValue == 0) // theta = 0
    }

    @Test("Vec2 to_polar on x-axis")
    func vec2ToPolarXAxis() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec2(5, 0)
            local polar = v:to_polar()
            return {polar.r, polar.theta}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // r = 5
        #expect(abs(arr[1].numberValue!) < 0.0001) // theta = 0
    }

    @Test("Vec2 to_polar on y-axis")
    func vec2ToPolarYAxis() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec2(0, 5)
            local polar = v:to_polar()
            return {polar.r, polar.theta}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // r = 5
        #expect(abs(arr[1].numberValue! - Double.pi / 2) < 0.0001) // theta = pi/2
    }

    @Test("from_polar factory function")
    func fromPolar() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.from_polar(5, 0)
            return {v.x, v.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // x = 5
        #expect(abs(arr[1].numberValue!) < 0.0001) // y = 0
    }

    @Test("from_polar at 45 degrees")
    func fromPolar45Degrees() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.from_polar(math.sqrt(2), math.pi / 4)
            return {v.x, v.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 1.0) < 0.0001) // x = 1
        #expect(abs(arr[1].numberValue! - 1.0) < 0.0001) // y = 1
    }

    @Test("Vec2 polar round-trip")
    func vec2PolarRoundTrip() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local original = geo.vec2(3, 4)
            local polar = original:to_polar()
            local restored = geo.from_polar(polar.r, polar.theta)
            return {math.abs(original.x - restored.x), math.abs(original.y - restored.y)}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue! < 0.0001)
        #expect(arr[1].numberValue! < 0.0001)
    }

    @Test("Vec3 to_spherical method")
    func vec3ToSpherical() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec3(0, 0, 5)
            local spherical = v:to_spherical()
            return {spherical.r, spherical.theta, spherical.phi}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // r = 5
        #expect(abs(arr[1].numberValue!) < 0.0001) // theta = 0 (undefined but atan2(0,0)=0)
        #expect(abs(arr[2].numberValue!) < 0.0001) // phi = 0 (pointing along z-axis)
    }

    @Test("Vec3 to_spherical on x-axis")
    func vec3ToSphericalXAxis() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec3(5, 0, 0)
            local spherical = v:to_spherical()
            return {spherical.r, spherical.theta, spherical.phi}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // r = 5
        #expect(abs(arr[1].numberValue!) < 0.0001) // theta = 0
        #expect(abs(arr[2].numberValue! - Double.pi / 2) < 0.0001) // phi = pi/2 (perpendicular to z)
    }

    @Test("from_spherical factory function")
    func fromSpherical() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.from_spherical(5, 0, 0)
            return {v.x, v.y, v.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001) // x = 0
        #expect(abs(arr[1].numberValue!) < 0.0001) // y = 0
        #expect(abs(arr[2].numberValue! - 5.0) < 0.0001) // z = 5
    }

    @Test("from_spherical at equator")
    func fromSphericalEquator() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.from_spherical(5, 0, math.pi / 2)
            return {v.x, v.y, v.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // x = 5
        #expect(abs(arr[1].numberValue!) < 0.0001) // y = 0
        #expect(abs(arr[2].numberValue!) < 0.0001) // z = 0
    }

    @Test("Vec3 spherical round-trip")
    func vec3SphericalRoundTrip() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local original = geo.vec3(1, 2, 3)
            local spherical = original:to_spherical()
            local restored = geo.from_spherical(spherical.r, spherical.theta, spherical.phi)
            return {
                math.abs(original.x - restored.x),
                math.abs(original.y - restored.y),
                math.abs(original.z - restored.z)
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue! < 0.0001)
        #expect(arr[1].numberValue! < 0.0001)
        #expect(arr[2].numberValue! < 0.0001)
    }

    @Test("Vec3 to_cylindrical method")
    func vec3ToCylindrical() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.vec3(3, 4, 5)
            local cylindrical = v:to_cylindrical()
            return {cylindrical.rho, cylindrical.theta, cylindrical.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // rho = sqrt(9 + 16) = 5
        #expect(abs(arr[1].numberValue! - 0.9273) < 0.001) // theta = atan2(4, 3)
        #expect(abs(arr[2].numberValue! - 5.0) < 0.0001) // z = 5
    }

    @Test("from_cylindrical factory function")
    func fromCylindrical() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local v = geo.from_cylindrical(5, 0, 10)
            return {v.x, v.y, v.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001) // x = 5
        #expect(abs(arr[1].numberValue!) < 0.0001) // y = 0
        #expect(abs(arr[2].numberValue! - 10.0) < 0.0001) // z = 10
    }

    @Test("Vec3 cylindrical round-trip")
    func vec3CylindricalRoundTrip() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local original = geo.vec3(3, 4, 5)
            local cylindrical = original:to_cylindrical()
            local restored = geo.from_cylindrical(cylindrical.rho, cylindrical.theta, cylindrical.z)
            return {
                math.abs(original.x - restored.x),
                math.abs(original.y - restored.y),
                math.abs(original.z - restored.z)
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue! < 0.0001)
        #expect(arr[1].numberValue! < 0.0001)
        #expect(arr[2].numberValue! < 0.0001)
    }

    @Test("geo.polar_to_cart function")
    func geoPolarToCart() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local x, y = geo.polar_to_cart(5, 0)
            return {x, y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001)
        #expect(abs(arr[1].numberValue!) < 0.0001)
    }

    @Test("geo.cart_to_polar function")
    func geoCartToPolar() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local r, theta = geo.cart_to_polar(3, 4)
            return {r, theta}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001)
        #expect(abs(arr[1].numberValue! - 0.9273) < 0.001)
    }

    @Test("geo.spherical_to_cart function")
    func geoSphericalToCart() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local x, y, z = geo.spherical_to_cart(5, 0, math.pi / 2)
            return {x, y, z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001)
        #expect(abs(arr[1].numberValue!) < 0.0001)
        #expect(abs(arr[2].numberValue!) < 0.0001)
    }

    @Test("geo.cart_to_spherical function")
    func geoCartToSpherical() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local r, theta, phi = geo.cart_to_spherical(1, 1, 1)
            return {r, theta, phi}
        """)

        let arr = try #require(result.arrayValue)
        let expected_r = sqrt(3.0)
        let expected_theta = Double.pi / 4  // atan2(1, 1)
        let expected_phi = acos(1.0 / sqrt(3.0))  // acos(z/r)
        #expect(abs(arr[0].numberValue! - expected_r) < 0.0001)
        #expect(abs(arr[1].numberValue! - expected_theta) < 0.0001)
        #expect(abs(arr[2].numberValue! - expected_phi) < 0.0001)
    }
}
