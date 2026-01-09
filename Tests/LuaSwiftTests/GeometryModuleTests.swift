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

    @Test("Circle constructor with vec2")
    func circleConstructorVec2() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local center = geo.vec2(3, 4)
            local c = geo.circle(center, 5)
            return {c.center.x, c.center.y, c.radius, c.__luaswift_type}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 3)
        #expect(arr[1].numberValue == 4)
        #expect(arr[2].numberValue == 5)
        #expect(arr[3].stringValue == "circle")
    }

    @Test("Circle constructor with xyz")
    func circleConstructorXYZ() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local c = geo.circle(1, 2, 3)
            return {c.center.x, c.center.y, c.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 2)
        #expect(arr[2].numberValue == 3)
    }

    @Test("Circle chainable translate")
    func circleTranslate() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local c = geo.circle(0, 0, 5):translate(3, 4)
            return {c.center.x, c.center.y, c.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 3)
        #expect(arr[1].numberValue == 4)
        #expect(arr[2].numberValue == 5)
    }

    @Test("Circle chainable scale")
    func circleScale() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local c = geo.circle(5, 5, 10):scale(2)
            return {c.center.x, c.center.y, c.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 5)
        #expect(arr[1].numberValue == 5)
        #expect(arr[2].numberValue == 20)
    }

    @Test("Circle contains point")
    func circleContains() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local c = geo.circle(0, 0, 5)
            local p_inside = geo.vec2(3, 0)
            local p_on = geo.vec2(5, 0)
            local p_outside = geo.vec2(6, 0)
            return {c:contains(p_inside), c:contains(p_on), c:contains(p_outside)}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)
        #expect(arr[1].boolValue == true)
        #expect(arr[2].boolValue == false)
    }

    @Test("Circle area and circumference")
    func circleAreaCircumference() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local c = geo.circle(0, 0, 2)
            return {c:area(), c:circumference(), c:diameter()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 4 * Double.pi) < 0.0001)
        #expect(abs(arr[1].numberValue! - 4 * Double.pi) < 0.0001)
        #expect(arr[2].numberValue == 4)
    }

    @Test("Circle point_at")
    func circlePointAt() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local c = geo.circle(0, 0, 1)
            local p0 = c:point_at(0)
            local p90 = c:point_at(math.pi / 2)
            return {p0.x, p0.y, p90.x, p90.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 1.0) < 0.0001)
        #expect(abs(arr[1].numberValue!) < 0.0001)
        #expect(abs(arr[2].numberValue!) < 0.0001)
        #expect(abs(arr[3].numberValue! - 1.0) < 0.0001)
    }

    @Test("Circle bounds")
    func circleBounds() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local c = geo.circle(5, 5, 2)
            local b = c:bounds()
            return {b.min.x, b.min.y, b.max.x, b.max.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 3)
        #expect(arr[1].numberValue == 3)
        #expect(arr[2].numberValue == 7)
        #expect(arr[3].numberValue == 7)
    }

    @Test("Circle from 3 points returns circle object")
    func circleFrom3PointsReturnsCircleObject() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p1 = {x = 0, y = 1}
            local p2 = {x = 1, y = 0}
            local p3 = {x = -1, y = 0}
            local c = geo.circle_from_3_points(p1, p2, p3)
            -- Verify it has circle methods
            return {c:area() > 0, c.__luaswift_type}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)
        #expect(arr[1].stringValue == "circle")
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

    // MARK: - Polynomial Tests

    @Test("Polynomial constructor and evaluate")
    func polynomialConstructorEvaluate() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // p(x) = 2 + 3x + x^2 = 2 + 3(2) + 4 = 12 at x=2
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p = geo.polynomial({2, 3, 1})  -- 2 + 3x + x^2
            return {p:evaluate(0), p:evaluate(1), p:evaluate(2)}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 2)   // p(0) = 2
        #expect(arr[1].numberValue == 6)   // p(1) = 2 + 3 + 1 = 6
        #expect(arr[2].numberValue == 12)  // p(2) = 2 + 6 + 4 = 12
    }

    @Test("Polynomial degree and coefficients")
    func polynomialDegreeCoefficients() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p = geo.polynomial({1, 0, 0, 5})  -- 1 + 5x^3 (degree 3)
            local coeffs = p:coefficients()
            return {p:degree(), coeffs[1], coeffs[2], coeffs[3], coeffs[4]}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 3)   // degree 3
        #expect(arr[1].numberValue == 1)   // a_0 = 1
        #expect(arr[2].numberValue == 0)   // a_1 = 0
        #expect(arr[3].numberValue == 0)   // a_2 = 0
        #expect(arr[4].numberValue == 5)   // a_3 = 5
    }

    @Test("Polynomial derivative")
    func polynomialDerivative() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // p(x) = 1 + 2x + 3x^2 → p'(x) = 2 + 6x
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p = geo.polynomial({1, 2, 3})
            local dp = p:derivative()
            return {dp:evaluate(0), dp:evaluate(1), dp:degree()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 2)   // dp(0) = 2
        #expect(arr[1].numberValue == 8)   // dp(1) = 2 + 6 = 8
        #expect(arr[2].numberValue == 1)   // degree 1
    }

    @Test("Polynomial tostring")
    func polynomialToString() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p = geo.polynomial({3, 0, 1})  -- 3 + x^2
            return tostring(p)
        """)

        let str = try #require(result.stringValue)
        #expect(str.contains("poly"))
        #expect(str.contains("3"))
        #expect(str.contains("x^2"))
    }

    @Test("geo.polyeval direct evaluation")
    func polyevalDirect() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // Evaluate 1 + 2x + 3x^2 at x = 2: 1 + 4 + 12 = 17
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            return geo.polyeval({1, 2, 3}, 2)
        """)

        #expect(result.numberValue == 17)
    }

    @Test("polyfit linear fit exact")
    func polyfitLinearExact() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)
        LinAlgModule.register(in: engine)

        // Fit a line to 3 collinear points: y = 2x + 1
        // Points: (0, 1), (1, 3), (2, 5)
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 1}, {1, 3}, {2, 5}}
            local p = geo.polyfit(points, 1)
            local coeffs = p:coefficients()
            return {coeffs[1], coeffs[2], p.r_squared}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 1.0) < 0.0001)   // intercept ≈ 1
        #expect(abs(arr[1].numberValue! - 2.0) < 0.0001)   // slope ≈ 2
        #expect(abs(arr[2].numberValue! - 1.0) < 0.0001)   // R² ≈ 1 (exact fit)
    }

    @Test("polyfit quadratic fit exact")
    func polyfitQuadraticExact() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)
        LinAlgModule.register(in: engine)

        // Fit quadratic to 3 points on y = x^2: (0, 0), (1, 1), (2, 4)
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 0}, {1, 1}, {2, 4}}
            local p = geo.polyfit(points, 2)
            local coeffs = p:coefficients()
            return {coeffs[1], coeffs[2], coeffs[3], p.r_squared}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001)         // a_0 ≈ 0
        #expect(abs(arr[1].numberValue!) < 0.0001)         // a_1 ≈ 0
        #expect(abs(arr[2].numberValue! - 1.0) < 0.0001)   // a_2 ≈ 1
        #expect(abs(arr[3].numberValue! - 1.0) < 0.0001)   // R² ≈ 1
    }

    @Test("polyfit with separate xs ys arrays")
    func polyfitSeparateArrays() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)
        LinAlgModule.register(in: engine)

        // Fit y = 3x + 2 using separate arrays
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local xs = {0, 1, 2, 3}
            local ys = {2, 5, 8, 11}  -- y = 3x + 2
            local p = geo.polyfit(xs, ys, 1)
            return {p:evaluate(5), p.r_squared}  -- should be 17
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 17.0) < 0.0001)  // 3*5 + 2 = 17
        #expect(abs(arr[1].numberValue! - 1.0) < 0.0001)   // R² ≈ 1
    }

    @Test("polyfit evaluates fitted polynomial at original points")
    func polyfitEvaluateOriginalPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)
        LinAlgModule.register(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{1, 2}, {2, 5}, {3, 10}}  -- y = x^2 + x
            local p = geo.polyfit(points, 2)
            return {
                math.abs(p:evaluate(1) - 2),
                math.abs(p:evaluate(2) - 5),
                math.abs(p:evaluate(3) - 10)
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue! < 0.0001)
        #expect(arr[1].numberValue! < 0.0001)
        #expect(arr[2].numberValue! < 0.0001)
    }

    @Test("polynomial roots for quadratic")
    func polynomialRootsQuadratic() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // p(x) = x^2 - 3x + 2 = (x-1)(x-2), roots at x=1 and x=2
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local p = geo.polynomial({2, -3, 1})  -- 2 - 3x + x^2
            local roots = p:roots()
            return {#roots, roots[1], roots[2]}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 2)                   // 2 roots
        #expect(abs(arr[1].numberValue! - 1.0) < 0.0001)   // root at 1
        #expect(abs(arr[2].numberValue! - 2.0) < 0.0001)   // root at 2
    }

    // MARK: - Cubic Spline Tests

    @Test("cubic_spline interpolates through all knots exactly")
    func cubicSplineInterpolatesKnots() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 1}, {1, 2}, {2, 0}, {3, 3}, {4, 1}}
            local s = geo.cubic_spline(points)

            -- Check that spline passes through each knot
            local errors = {}
            for i, pt in ipairs(points) do
                errors[i] = math.abs(s:evaluate(pt[1]) - pt[2])
            end
            return errors
        """)

        let arr = try #require(result.arrayValue)
        for (i, err) in arr.enumerated() {
            #expect(err.numberValue! < 1e-10, "Knot \(i+1) should be interpolated exactly")
        }
    }

    @Test("cubic_spline with two separate arrays")
    func cubicSplineTwoArrays() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local xs = {0, 1, 2, 3}
            local ys = {0, 1, 0, 1}
            local s = geo.cubic_spline(xs, ys)
            return {
                s:evaluate(0),
                s:evaluate(1),
                s:evaluate(2),
                s:evaluate(3)
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 0.0) < 1e-10)
        #expect(abs(arr[1].numberValue! - 1.0) < 1e-10)
        #expect(abs(arr[2].numberValue! - 0.0) < 1e-10)
        #expect(abs(arr[3].numberValue! - 1.0) < 1e-10)
    }

    @Test("cubic_spline smooth interpolation between knots")
    func cubicSplineInterpolation() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // For y = x^2 sampled at points, the cubic spline should
        // closely approximate the true function between knots
        // (Using x^2 because natural boundary conditions match better)
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 0}, {1, 1}, {2, 4}, {3, 9}}  -- y = x^2
            local s = geo.cubic_spline(points)

            -- Test at midpoints
            local function square(x) return x * x end
            return {
                math.abs(s:evaluate(0.5) - square(0.5)),
                math.abs(s:evaluate(1.5) - square(1.5)),
                math.abs(s:evaluate(2.5) - square(2.5))
            }
        """)

        let arr = try #require(result.arrayValue)
        // Natural cubic spline should be reasonably close to quadratic
        #expect(arr[0].numberValue! < 0.2)  // Near boundary, larger error expected
        #expect(arr[1].numberValue! < 0.1)  // Interior should be more accurate
        #expect(arr[2].numberValue! < 0.2)  // Near boundary
    }

    @Test("cubic_spline natural boundary conditions")
    func cubicSplineNaturalBoundary() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // Natural cubic spline has S''(x_0) = 0 and S''(x_n) = 0
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 0}, {1, 1}, {2, 0}, {3, 1}}
            local s = geo.cubic_spline(points)

            -- Second derivative at boundaries should be 0
            return {
                math.abs(s:second_derivative(0)),
                math.abs(s:second_derivative(3))
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue! < 1e-10, "Second derivative at left boundary should be 0")
        #expect(arr[1].numberValue! < 1e-10, "Second derivative at right boundary should be 0")
    }

    @Test("cubic_spline derivative is continuous")
    func cubicSplineDerivativeContinuous() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // First derivative should be continuous at knots
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 1}, {1, 2}, {2, 0}, {3, 3}}
            local s = geo.cubic_spline(points)

            -- Check continuity at interior knots
            local eps = 1e-6
            local errors = {}
            for i = 2, #points - 1 do
                local x = points[i][1]
                local left_deriv = s:derivative(x - eps)
                local right_deriv = s:derivative(x + eps)
                errors[i-1] = math.abs(left_deriv - right_deriv)
            end
            return errors
        """)

        let arr = try #require(result.arrayValue)
        for (i, err) in arr.enumerated() {
            #expect(err.numberValue! < 1e-4, "Derivative at knot \(i+2) should be continuous")
        }
    }

    @Test("cubic_spline domain method")
    func cubicSplineDomain() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{-2, 1}, {0, 0}, {3, 2}, {5, 1}}
            local s = geo.cubic_spline(points)
            local x_min, x_max = s:domain()
            return {x_min, x_max}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == -2)
        #expect(arr[1].numberValue == 5)
    }

    @Test("cubic_spline knots and values accessors")
    func cubicSplineKnotsValues() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{1, 10}, {2, 20}, {3, 30}}
            local s = geo.cubic_spline(points)
            local k = s:knots()
            local v = s:values()
            return {k[1], k[2], k[3], v[1], v[2], v[3]}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 2)
        #expect(arr[2].numberValue == 3)
        #expect(arr[3].numberValue == 10)
        #expect(arr[4].numberValue == 20)
        #expect(arr[5].numberValue == 30)
    }

    @Test("cubic_spline segments count")
    func cubicSplineSegments() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 0}, {1, 1}, {2, 0}, {3, 1}, {4, 0}}
            local s = geo.cubic_spline(points)
            return s:segments()
        """)

        #expect(result.numberValue == 4)  // 5 points = 4 segments
    }

    @Test("cubic_spline tostring representation")
    func cubicSplineTostring() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 1}, {1, 2}, {2, 3}}
            local s = geo.cubic_spline(points)
            return tostring(s)
        """)

        let str = try #require(result.stringValue)
        #expect(str.contains("cubic_spline"))
        #expect(str.contains("3 points"))
    }

    @Test("cubic_spline evaluate_array batch evaluation")
    func cubicSplineEvaluateArray() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 0}, {1, 1}, {2, 4}, {3, 9}}  -- approximately y = x^2
            local s = geo.cubic_spline(points)
            local xs = {0, 0.5, 1, 1.5, 2, 2.5, 3}
            local ys = s:evaluate_array(xs)
            return {ys[1], ys[3], ys[5], ys[7]}  -- values at 0, 1, 2, 3
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 0.0) < 1e-10)
        #expect(abs(arr[1].numberValue! - 1.0) < 1e-10)
        #expect(abs(arr[2].numberValue! - 4.0) < 1e-10)
        #expect(abs(arr[3].numberValue! - 9.0) < 1e-10)
    }

    @Test("cubic_spline with two points gives linear interpolation")
    func cubicSplineTwoPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 0}, {2, 4}}
            local s = geo.cubic_spline(points)
            return {
                s:evaluate(0),
                s:evaluate(1),  -- midpoint should be 2
                s:evaluate(2),
                s:derivative(1)  -- slope should be 2
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 0.0) < 1e-10)
        #expect(abs(arr[1].numberValue! - 2.0) < 1e-10)  // linear interpolation
        #expect(abs(arr[2].numberValue! - 4.0) < 1e-10)
        #expect(abs(arr[3].numberValue! - 2.0) < 1e-10)  // slope = (4-0)/(2-0) = 2
    }

    @Test("cubic_spline extrapolates outside domain")
    func cubicSplineExtrapolation() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // Extrapolation should use endpoint segments
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {{0, 0}, {1, 1}, {2, 0}}
            local s = geo.cubic_spline(points)

            -- Evaluate outside domain (extrapolation)
            local left = s:evaluate(-0.5)
            local right = s:evaluate(2.5)
            return {left, right}
        """)

        // Just check it doesn't error - extrapolation values will depend on spline
        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue != nil)
        #expect(arr[1].numberValue != nil)
    }

    // MARK: - B-Spline Tests

    @Test("bspline degree 1 is piecewise linear")
    func bsplineDegree1Linear() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // Degree 1 B-spline with 3 control points should be piecewise linear
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local pts = {geo.vec2(0, 0), geo.vec2(1, 2), geo.vec2(2, 0)}
            local b = geo.bspline(pts, 1)

            -- At t=0: should be at first control point
            -- At t=0.5: should be at second control point
            -- At t=1: should be at last control point
            local p0 = b:evaluate(0)
            local p_mid = b:evaluate(0.5)
            local p1 = b:evaluate(1)

            return {p0.x, p0.y, p_mid.x, p_mid.y, p1.x, p1.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 0) < 1e-10)  // p0.x = 0
        #expect(abs(arr[1].numberValue! - 0) < 1e-10)  // p0.y = 0
        #expect(abs(arr[2].numberValue! - 1) < 1e-10)  // p_mid.x = 1
        #expect(abs(arr[3].numberValue! - 2) < 1e-10)  // p_mid.y = 2
        #expect(abs(arr[4].numberValue! - 2) < 1e-10)  // p1.x = 2
        #expect(abs(arr[5].numberValue! - 0) < 1e-10)  // p1.y = 0
    }

    @Test("bspline basis functions sum to 1 (partition of unity)")
    func bsplineBasisPartitionOfUnity() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local n = 5  -- number of control points
            local p = 3  -- degree
            local knots = geo.bspline_uniform_knots(n, p)

            -- Test at several t values
            local errors = {}
            for _, t in ipairs({0, 0.25, 0.5, 0.75, 1.0}) do
                local sum = 0
                for i = 1, n do
                    sum = sum + geo.bspline_basis(knots, i, p, t)
                end
                table.insert(errors, math.abs(sum - 1.0))
            end
            return errors
        """)

        let arr = try #require(result.arrayValue)
        for (i, err) in arr.enumerated() {
            #expect(err.numberValue! < 1e-10, "Basis sum at point \(i) should be 1")
        }
    }

    @Test("bspline cubic with 4 control points")
    func bsplineCubic4Points() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // Cubic B-spline with 4 control points is a single Bezier curve
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local pts = {
                geo.vec2(0, 0),
                geo.vec2(1, 2),
                geo.vec2(2, 2),
                geo.vec2(3, 0)
            }
            local b = geo.bspline(pts, 3)  -- cubic

            -- Endpoints should match first and last control points (clamped)
            local p0 = b:evaluate(0)
            local p1 = b:evaluate(1)

            return {p0.x, p0.y, p1.x, p1.y, b:degree()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 0) < 1e-10)  // Start at (0, 0)
        #expect(abs(arr[1].numberValue! - 0) < 1e-10)
        #expect(abs(arr[2].numberValue! - 3) < 1e-10)  // End at (3, 0)
        #expect(abs(arr[3].numberValue! - 0) < 1e-10)
        #expect(arr[4].numberValue == 3)               // degree = 3
    }

    @Test("bspline sample generates points")
    func bsplineSample() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local pts = {
                geo.vec2(0, 0),
                geo.vec2(1, 1),
                geo.vec2(2, 0),
                geo.vec2(3, 1)
            }
            local b = geo.bspline(pts, 2)  -- quadratic
            local samples = b:sample(5)

            return {
                #samples,
                samples[1].x, samples[1].y,  -- first point
                samples[5].x, samples[5].y   -- last point
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 5)  // 5 samples
        // First sample should be at t=0 (start)
        #expect(arr[1].numberValue != nil)
        #expect(arr[2].numberValue != nil)
        // Last sample should be at t=1 (end)
        #expect(arr[3].numberValue != nil)
        #expect(arr[4].numberValue != nil)
    }

    @Test("bspline 3D curve")
    func bspline3D() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local pts = {
                geo.vec3(0, 0, 0),
                geo.vec3(1, 1, 1),
                geo.vec3(2, 0, 2),
                geo.vec3(3, 1, 0)
            }
            local b = geo.bspline(pts, 2)

            local p0 = b:evaluate(0)
            local p1 = b:evaluate(1)

            return {
                b:is_3d(),
                p0.x, p0.y, p0.z,
                p1.x, p1.y, p1.z
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)  // is 3D
        #expect(abs(arr[1].numberValue! - 0) < 1e-10)  // Start at (0,0,0)
        #expect(abs(arr[2].numberValue! - 0) < 1e-10)
        #expect(abs(arr[3].numberValue! - 0) < 1e-10)
        #expect(abs(arr[4].numberValue! - 3) < 1e-10)  // End at (3,1,0)
        #expect(abs(arr[5].numberValue! - 1) < 1e-10)
        #expect(abs(arr[6].numberValue! - 0) < 1e-10)
    }

    @Test("bspline derivative")
    func bsplineDerivative() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        // For linear B-spline, derivative should be constant within each segment
        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local pts = {geo.vec2(0, 0), geo.vec2(2, 4), geo.vec2(4, 0)}
            local b = geo.bspline(pts, 1)  -- linear

            -- Derivative at t=0.25 (first segment)
            local d1 = b:derivative(0.25)

            return {d1.x, d1.y}
        """)

        let arr = try #require(result.arrayValue)
        // For first segment from (0,0) to (2,4), slope should be (4, 8) scaled
        #expect(arr[0].numberValue != nil)
        #expect(arr[1].numberValue != nil)
    }

    @Test("bspline domain method")
    func bsplineDomain() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local pts = {
                geo.vec2(0, 0),
                geo.vec2(1, 1),
                geo.vec2(2, 0),
                geo.vec2(3, 1)
            }
            local b = geo.bspline(pts, 2)  -- quadratic
            local t_min, t_max = b:domain()
            return {t_min, t_max}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 0)  // clamped starts at 0
        #expect(arr[1].numberValue == 1)  // clamped ends at 1
    }

    @Test("bspline control_points accessor")
    func bsplineControlPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local pts = {geo.vec2(1, 2), geo.vec2(3, 4), geo.vec2(5, 6)}
            local b = geo.bspline(pts, 1)
            local cps = b:control_points()
            return {#cps, cps[1].x, cps[1].y, cps[3].x, cps[3].y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 3)
        #expect(arr[1].numberValue == 1)
        #expect(arr[2].numberValue == 2)
        #expect(arr[3].numberValue == 5)
        #expect(arr[4].numberValue == 6)
    }

    @Test("bspline tostring representation")
    func bsplineTostring() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local pts = {geo.vec2(0, 0), geo.vec2(1, 1), geo.vec2(2, 0), geo.vec2(3, 1)}
            local b = geo.bspline(pts, 3)
            return tostring(b)
        """)

        let str = try #require(result.stringValue)
        #expect(str.contains("bspline"))
        #expect(str.contains("degree=3"))
        #expect(str.contains("4 control points"))
    }

    @Test("bspline_uniform_knots generates correct size")
    func bsplineUniformKnots() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local knots = geo.bspline_uniform_knots(5, 3)  -- 5 control points, degree 3
            -- Should have n + p + 1 = 5 + 3 + 1 = 9 knots
            return {#knots, knots[1], knots[4], knots[9]}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 9)   // 9 knots
        #expect(arr[1].numberValue == 0)   // First knot is 0 (clamped)
        #expect(arr[2].numberValue == 0)   // Knot 4 is still 0 (p+1 zeros)
        #expect(arr[3].numberValue == 1)   // Last knot is 1 (clamped)
    }

    // MARK: - Circle Fitting Tests

    @Test("circle_fit exact points recovers original circle")
    func circleFitExactPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Generate exact points on circle with center (5, 3), radius 4
            local cx, cy, r = 5, 3, 4
            local points = {}
            for i = 0, 7 do
                local angle = i * math.pi / 4
                points[#points + 1] = geo.vec2(cx + r * math.cos(angle), cy + r * math.sin(angle))
            end
            local fitted = geo.circle_fit(points)
            return {fitted.cx, fitted.cy, fitted.r, fitted:rmse()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001)   // cx
        #expect(abs(arr[1].numberValue! - 3.0) < 0.0001)   // cy
        #expect(abs(arr[2].numberValue! - 4.0) < 0.0001)   // r
        #expect(arr[3].numberValue! < 1e-10)               // RMSE should be ~0
    }

    @Test("circle_fit with noisy points gives approximate result")
    func circleFitNoisyPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Generate points on circle with small perturbations
            local cx, cy, r = 10, -5, 7
            local points = {}
            local seed = 12345
            local function noise()
                seed = (seed * 1103515245 + 12345) % 2147483648
                return (seed / 2147483648 - 0.5) * 0.2  -- noise in [-0.1, 0.1]
            end
            for i = 0, 15 do
                local angle = i * math.pi / 8
                local x = cx + (r + noise()) * math.cos(angle)
                local y = cy + (r + noise()) * math.sin(angle)
                points[#points + 1] = geo.vec2(x, y)
            end
            local fitted = geo.circle_fit(points)
            return {fitted.cx, fitted.cy, fitted.r, fitted:rmse()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 10.0) < 0.5)   // cx within 0.5
        #expect(abs(arr[1].numberValue! - (-5.0)) < 0.5) // cy within 0.5
        #expect(abs(arr[2].numberValue! - 7.0) < 0.5)    // r within 0.5
        #expect(arr[3].numberValue! < 0.2)               // RMSE should be small
    }

    @Test("circle_fit taubin method")
    func circleFitTaubin() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local cx, cy, r = 2, 4, 3
            local points = {}
            for i = 0, 11 do
                local angle = i * math.pi / 6
                points[#points + 1] = geo.vec2(cx + r * math.cos(angle), cy + r * math.sin(angle))
            end
            local fitted = geo.circle_fit(points, 'taubin')
            return {fitted.cx, fitted.cy, fitted.r, fitted:fit_method()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 2.0) < 0.0001)   // cx
        #expect(abs(arr[1].numberValue! - 4.0) < 0.0001)   // cy
        #expect(abs(arr[2].numberValue! - 3.0) < 0.0001)   // r
        #expect(arr[3].stringValue == "taubin")
    }

    @Test("circle_fit collinear points returns nil")
    func circleFitCollinear() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Three collinear points
            local points = {
                geo.vec2(0, 0),
                geo.vec2(1, 1),
                geo.vec2(2, 2)
            }
            local fitted = geo.circle_fit(points)
            return fitted == nil
        """)

        #expect(result.boolValue == true)
    }

    @Test("circle_fit residuals method")
    func circleFitResiduals() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec2(1, 0),
                geo.vec2(0, 1),
                geo.vec2(-1, 0),
                geo.vec2(0, -1)
            }
            local fitted = geo.circle_fit(points)
            local res = fitted:residuals()
            return {#res, res[1], res[2], res[3], res[4]}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 4)   // 4 residuals
        // Exact points should have near-zero residuals
        #expect(abs(arr[1].numberValue!) < 1e-10)
        #expect(abs(arr[2].numberValue!) < 1e-10)
        #expect(abs(arr[3].numberValue!) < 1e-10)
        #expect(abs(arr[4].numberValue!) < 1e-10)
    }

    @Test("circle_fit fit_points method")
    func circleFitFitPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec2(3, 0),
                geo.vec2(0, 3),
                geo.vec2(-3, 0),
                geo.vec2(0, -3)
            }
            local fitted = geo.circle_fit(points)
            local pts = fitted:fit_points()
            return {#pts, pts[1].x, pts[1].y, pts[3].x, pts[3].y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 4)   // 4 points
        #expect(arr[1].numberValue == 3)   // first point x
        #expect(arr[2].numberValue == 0)   // first point y
        #expect(arr[3].numberValue == -3)  // third point x
        #expect(arr[4].numberValue == 0)   // third point y
    }

    @Test("circle_fit algebraic vs taubin comparison")
    func circleFitMethodComparison() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Create arc (not full circle) - this shows bias differences
            local cx, cy, r = 0, 0, 5
            local points = {}
            for i = 0, 5 do
                local angle = i * math.pi / 10  -- 0 to π/2 arc
                points[#points + 1] = geo.vec2(cx + r * math.cos(angle), cy + r * math.sin(angle))
            end
            local alg = geo.circle_fit(points, 'algebraic')
            local tau = geo.circle_fit(points, 'taubin')
            return {
                alg:fit_method(),
                tau:fit_method(),
                alg.r,
                tau.r
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].stringValue == "algebraic")
        #expect(arr[1].stringValue == "taubin")
        // Both should get radius close to 5
        #expect(abs(arr[2].numberValue! - 5.0) < 0.5)
        #expect(abs(arr[3].numberValue! - 5.0) < 0.5)
    }

    @Test("circle_fit with array-style points")
    func circleFitArrayPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Use {x, y} array format instead of vec2
            local points = {
                {5, 0},
                {0, 5},
                {-5, 0},
                {0, -5}
            }
            local fitted = geo.circle_fit(points)
            return {fitted.cx, fitted.cy, fitted.r}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001)        // cx ≈ 0
        #expect(abs(arr[1].numberValue!) < 0.0001)        // cy ≈ 0
        #expect(abs(arr[2].numberValue! - 5.0) < 0.0001)  // r ≈ 5
    }

    @Test("circle_fit with minimum 3 points")
    func circleFitMinPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Exactly 3 non-collinear points uniquely define a circle
            local points = {
                geo.vec2(0, 0),
                geo.vec2(2, 0),
                geo.vec2(1, 1)
            }
            local fitted = geo.circle_fit(points)
            -- Center should be at (1, 0) with r = 1
            return {fitted.cx, fitted.cy, fitted.r}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 1.0) < 0.0001)  // cx ≈ 1
        #expect(abs(arr[1].numberValue!) < 0.0001)        // cy ≈ 0
        #expect(abs(arr[2].numberValue! - 1.0) < 0.0001)  // r ≈ 1
    }

    @Test("circle_fit fitted circle inherits circle methods")
    func circleFitInheritsMethods() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec2(3, 0),
                geo.vec2(0, 3),
                geo.vec2(-3, 0),
                geo.vec2(0, -3)
            }
            local fitted = geo.circle_fit(points)
            -- Test inherited circle methods
            local area = fitted:area()
            local circumference = fitted:circumference()
            local contains = fitted:contains(geo.vec2(0, 0))
            return {area, circumference, contains}
        """)

        let arr = try #require(result.arrayValue)
        // area = π * 3² ≈ 28.27
        #expect(abs(arr[0].numberValue! - 28.2743) < 0.01)
        // circumference = 2π * 3 ≈ 18.85
        #expect(abs(arr[1].numberValue! - 18.8495) < 0.01)
        // center (0,0) is inside circle of radius 3
        #expect(arr[2].boolValue == true)
    }

    // MARK: - Ellipse Tests

    @Test("ellipse constructor with center vec2")
    func ellipseConstructorVec2() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(geo.vec2(1, 2), 5, 3, math.pi/4)
            return {e.center.x, e.center.y, e.semi_major, e.semi_minor, e.rotation}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 2)
        #expect(arr[2].numberValue == 5)
        #expect(arr[3].numberValue == 3)
        #expect(abs(arr[4].numberValue! - Double.pi/4) < 0.0001)
    }

    @Test("ellipse constructor with coordinates")
    func ellipseConstructorCoords() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(1, 2, 5, 3)  -- no rotation
            return {e.center.x, e.center.y, e.semi_major, e.semi_minor, e.rotation}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 2)
        #expect(arr[2].numberValue == 5)
        #expect(arr[3].numberValue == 3)
        #expect(arr[4].numberValue == 0)
    }

    @Test("ellipse area and circumference")
    func ellipseAreaCircumference() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(0, 0, 5, 3)  -- a=5, b=3
            return {e:area(), e:circumference()}
        """)

        let arr = try #require(result.arrayValue)
        // area = π * 5 * 3 ≈ 47.12
        #expect(abs(arr[0].numberValue! - 47.1238) < 0.01)
        // circumference using Ramanujan's approximation ≈ 25.9
        #expect(abs(arr[1].numberValue! - 25.9) < 0.5)
    }

    @Test("ellipse contains point")
    func ellipseContains() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(0, 0, 5, 3)  -- axis-aligned ellipse
            local inside = e:contains(geo.vec2(2, 1))
            local outside = e:contains(geo.vec2(6, 0))
            return {inside, outside}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)   // (2,1) inside
        #expect(arr[1].boolValue == false)  // (6,0) outside
    }

    @Test("ellipse eccentricity")
    func ellipseEccentricity() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(0, 0, 5, 3)
            return e:eccentricity()
        """)

        // e = sqrt(1 - b²/a²) = sqrt(1 - 9/25) = sqrt(16/25) = 0.8
        #expect(abs(result.numberValue! - 0.8) < 0.0001)
    }

    @Test("ellipse point_at generates points on ellipse")
    func ellipsePointAt() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(0, 0, 5, 3)  -- axis-aligned
            local p0 = e:point_at(0)         -- should be (5, 0)
            local p1 = e:point_at(math.pi/2) -- should be (0, 3)
            return {p0.x, p0.y, p1.x, p1.y}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001)  // x at t=0
        #expect(abs(arr[1].numberValue!) < 0.0001)         // y at t=0
        #expect(abs(arr[2].numberValue!) < 0.0001)         // x at t=π/2
        #expect(abs(arr[3].numberValue! - 3.0) < 0.0001)  // y at t=π/2
    }

    @Test("ellipse foci")
    func ellipseFoci() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(0, 0, 5, 3)  -- c = sqrt(25-9) = 4
            local f1, f2 = e:foci()
            return {f1.x, f1.y, f2.x, f2.y}
        """)

        let arr = try #require(result.arrayValue)
        // Foci at (±4, 0) for axis-aligned ellipse
        #expect(abs(arr[0].numberValue! - 4.0) < 0.0001)
        #expect(abs(arr[1].numberValue!) < 0.0001)
        #expect(abs(arr[2].numberValue! + 4.0) < 0.0001)
        #expect(abs(arr[3].numberValue!) < 0.0001)
    }

    @Test("ellipse tostring")
    func ellipseTostring() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(1, 2, 5, 3)
            return tostring(e)
        """)

        let str = try #require(result.stringValue)
        #expect(str.contains("ellipse"))
        #expect(str.contains("5.0000"))  // semi_major
        #expect(str.contains("3.0000"))  // semi_minor
    }

    @Test("ellipse_fit exact points recovers original ellipse")
    func ellipseFitExactPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Generate points on ellipse: center (2, 3), a=5, b=3, rotation=0
            local cx, cy, a, b = 2, 3, 5, 3
            local points = {}
            for i = 0, 15 do
                local t = i * math.pi * 2 / 16
                local x = cx + a * math.cos(t)
                local y = cy + b * math.sin(t)
                points[#points + 1] = geo.vec2(x, y)
            end
            local fitted = geo.ellipse_fit(points)
            if fitted == nil then return "nil" end
            return {fitted.cx, fitted.cy, fitted.a, fitted.b, fitted:rmse()}
        """)

        if result.stringValue == "nil" {
            // Fitting failed - this is a potential issue but let's check the algorithm
            Issue.record("ellipse_fit returned nil for exact points")
            return
        }

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 2.0) < 0.1)   // cx
        #expect(abs(arr[1].numberValue! - 3.0) < 0.1)   // cy
        #expect(abs(arr[2].numberValue! - 5.0) < 0.1)   // a
        #expect(abs(arr[3].numberValue! - 3.0) < 0.1)   // b
        #expect(arr[4].numberValue! < 0.1)              // RMSE should be small
    }

    @Test("ellipse_fit with rotated ellipse")
    func ellipseFitRotated() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Generate points on rotated ellipse
            local cx, cy, a, b, theta = 0, 0, 4, 2, math.pi/6  -- 30 degree rotation
            local points = {}
            for i = 0, 19 do
                local t = i * math.pi * 2 / 20
                local x_local = a * math.cos(t)
                local y_local = b * math.sin(t)
                local x = cx + x_local * math.cos(theta) - y_local * math.sin(theta)
                local y = cy + x_local * math.sin(theta) + y_local * math.cos(theta)
                points[#points + 1] = geo.vec2(x, y)
            end
            local fitted = geo.ellipse_fit(points)
            if fitted == nil then return "nil" end
            return {fitted.a, fitted.b, fitted:fit_method()}
        """)

        if result.stringValue == "nil" {
            Issue.record("ellipse_fit returned nil for rotated ellipse points")
            return
        }

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 4.0) < 0.2)   // a ≈ 4
        #expect(abs(arr[1].numberValue! - 2.0) < 0.2)   // b ≈ 2
        #expect(arr[2].stringValue == "direct")
    }

    @Test("ellipse_fit with circle returns equal semi-axes")
    func ellipseFitCircle() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Generate points on a circle (special case of ellipse)
            local cx, cy, r = 5, -2, 3
            local points = {}
            for i = 0, 11 do
                local t = i * math.pi * 2 / 12
                points[#points + 1] = geo.vec2(cx + r * math.cos(t), cy + r * math.sin(t))
            end
            local fitted = geo.ellipse_fit(points)
            if fitted == nil then return "nil" end
            return {fitted.a, fitted.b, math.abs(fitted.a - fitted.b)}
        """)

        if result.stringValue == "nil" {
            Issue.record("ellipse_fit returned nil for circle points")
            return
        }

        let arr = try #require(result.arrayValue)
        // For a circle, a and b should be approximately equal
        let aDiff = arr[2].numberValue!
        #expect(aDiff < 0.1)  // a ≈ b
        #expect(abs(arr[0].numberValue! - 3.0) < 0.1)  // a ≈ 3
        #expect(abs(arr[1].numberValue! - 3.0) < 0.1)  // b ≈ 3
    }

    @Test("ellipse_fit with collinear points returns nil")
    func ellipseFitCollinear() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- 5 collinear points
            local points = {}
            for i = 1, 5 do
                points[i] = geo.vec2(i, i)
            end
            local fitted = geo.ellipse_fit(points)
            return fitted == nil
        """)

        #expect(result.boolValue == true)
    }

    @Test("ellipse to_conic conversion")
    func ellipseToConic() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(0, 0, 5, 3)  -- axis-aligned at origin
            local conic = e:to_conic()
            -- For axis-aligned ellipse at origin: x²/a² + y²/b² = 1
            -- → (1/25)x² + (1/9)y² - 1 = 0
            -- A = 1/25 = 0.04, B = 0, C = 1/9 ≈ 0.111, D = 0, E = 0, F = -1
            return {conic[1], conic[2], conic[3], conic[4], conic[5], conic[6]}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 0.04) < 0.001)  // A = 1/25
        #expect(abs(arr[1].numberValue!) < 0.001)         // B = 0
        #expect(abs(arr[2].numberValue! - 1.0/9) < 0.001) // C = 1/9
        #expect(abs(arr[3].numberValue!) < 0.001)         // D = 0
        #expect(abs(arr[4].numberValue!) < 0.001)         // E = 0
        #expect(abs(arr[5].numberValue! + 1.0) < 0.001)   // F = -1
    }

    @Test("ellipse chainable transformations")
    func ellipseChainable() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local e = geo.ellipse(0, 0, 4, 2)
            local translated = e:translate(5, 3)
            local scaled = e:scale(2)
            local rotated = e:rotate(math.pi/4)
            return {
                translated.center.x, translated.center.y,
                scaled.semi_major, scaled.semi_minor,
                rotated.rotation
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 5)  // translated center x
        #expect(arr[1].numberValue == 3)  // translated center y
        #expect(arr[2].numberValue == 8)  // scaled semi_major
        #expect(arr[3].numberValue == 4)  // scaled semi_minor
        #expect(abs(arr[4].numberValue! - Double.pi/4) < 0.0001)  // rotated angle
    }

    // MARK: - Sphere Tests

    @Test("sphere constructor with center vec3")
    func sphereConstructorWithVec3() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local center = geo.vec3(1, 2, 3)
            local s = geo.sphere(center, 5)
            return {s.center.x, s.center.y, s.center.z, s.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)
        #expect(arr[1].numberValue == 2)
        #expect(arr[2].numberValue == 3)
        #expect(arr[3].numberValue == 5)
    }

    @Test("sphere constructor with coordinates")
    func sphereConstructorWithCoordinates() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(4, 5, 6, 3)
            return {s.center.x, s.center.y, s.center.z, s.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 4)
        #expect(arr[1].numberValue == 5)
        #expect(arr[2].numberValue == 6)
        #expect(arr[3].numberValue == 3)
    }

    @Test("sphere volume and surface area")
    func sphereVolumeAndSurfaceArea() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(0, 0, 0, 2)  -- radius 2
            return {s:volume(), s:surface_area()}
        """)

        let arr = try #require(result.arrayValue)
        // Volume = 4/3 * π * r³ = 4/3 * π * 8 = 32π/3 ≈ 33.51
        #expect(abs(arr[0].numberValue! - 4.0/3.0 * Double.pi * 8) < 0.001)
        // Surface area = 4 * π * r² = 4 * π * 4 = 16π ≈ 50.27
        #expect(abs(arr[1].numberValue! - 4.0 * Double.pi * 4) < 0.001)
    }

    @Test("sphere contains point")
    func sphereContainsPoint() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(0, 0, 0, 5)
            local inside = s:contains(geo.vec3(1, 1, 1))    -- dist = sqrt(3) ≈ 1.73 < 5
            local outside = s:contains(geo.vec3(4, 4, 4))   -- dist = sqrt(48) ≈ 6.93 > 5
            local on_surface = s:contains(geo.vec3(5, 0, 0)) -- dist = 5, on surface
            return {inside, outside, on_surface}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)   // inside
        #expect(arr[1].boolValue == false)  // outside
        #expect(arr[2].boolValue == true)   // on surface (within tolerance)
    }

    @Test("sphere point_at generates points on sphere")
    func spherePointAt() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(1, 2, 3, 4)
            -- theta=0, phi=0 should give point at (cx, cy, cz + r)
            local p1 = s:point_at(0, 0)
            -- theta=pi/2, phi=0 should give point at (cx + r, cy, cz)
            local p2 = s:point_at(math.pi/2, 0)
            -- theta=pi/2, phi=pi/2 should give point at (cx, cy + r, cz)
            local p3 = s:point_at(math.pi/2, math.pi/2)

            -- Verify all points are on the sphere
            local d1 = math.sqrt((p1.x - 1)^2 + (p1.y - 2)^2 + (p1.z - 3)^2)
            local d2 = math.sqrt((p2.x - 1)^2 + (p2.y - 2)^2 + (p2.z - 3)^2)
            local d3 = math.sqrt((p3.x - 1)^2 + (p3.y - 2)^2 + (p3.z - 3)^2)

            return {d1, d2, d3}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 4.0) < 0.0001)  // all distances should equal radius
        #expect(abs(arr[1].numberValue! - 4.0) < 0.0001)
        #expect(abs(arr[2].numberValue! - 4.0) < 0.0001)
    }

    @Test("sphere_fit exact points recovers original sphere")
    func sphereFitExactPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Create points exactly on a sphere centered at (1, 2, 3) with radius 5
            local points = {
                geo.vec3(6, 2, 3),   -- +x
                geo.vec3(-4, 2, 3),  -- -x
                geo.vec3(1, 7, 3),   -- +y
                geo.vec3(1, -3, 3),  -- -y
                geo.vec3(1, 2, 8),   -- +z
                geo.vec3(1, 2, -2)   -- -z
            }
            local fitted = geo.sphere_fit(points)
            return {
                fitted.center.x, fitted.center.y, fitted.center.z,
                fitted.radius, fitted:rmse()
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 1.0) < 0.0001)  // center x
        #expect(abs(arr[1].numberValue! - 2.0) < 0.0001)  // center y
        #expect(abs(arr[2].numberValue! - 3.0) < 0.0001)  // center z
        #expect(abs(arr[3].numberValue! - 5.0) < 0.0001)  // radius
        #expect(arr[4].numberValue! < 0.0001)             // rmse should be ~0
    }

    @Test("sphere_fit with noisy points")
    func sphereFitNoisyPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Points approximately on a unit sphere at origin
            local points = {
                geo.vec3(1.02, 0, 0),
                geo.vec3(-0.98, 0, 0),
                geo.vec3(0, 1.01, 0),
                geo.vec3(0, -0.99, 0),
                geo.vec3(0, 0, 1.03),
                geo.vec3(0, 0, -0.97),
                geo.vec3(0.71, 0.71, 0),
                geo.vec3(0, 0.71, 0.71)
            }
            local fitted = geo.sphere_fit(points)
            return {
                fitted.center.x, fitted.center.y, fitted.center.z,
                fitted.radius, fitted:rmse()
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.05)   // center x ≈ 0
        #expect(abs(arr[1].numberValue!) < 0.05)   // center y ≈ 0
        #expect(abs(arr[2].numberValue!) < 0.05)   // center z ≈ 0
        #expect(abs(arr[3].numberValue! - 1.0) < 0.1)  // radius ≈ 1
        #expect(arr[4].numberValue! < 0.1)         // rmse should be small
    }

    @Test("sphere_fit with coplanar points returns nil")
    func sphereFitCoplanarPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- All points in z=0 plane - coplanar, can't fit sphere
            local points = {
                geo.vec3(1, 0, 0),
                geo.vec3(0, 1, 0),
                geo.vec3(-1, 0, 0),
                geo.vec3(0, -1, 0),
                geo.vec3(0.5, 0.5, 0)
            }
            local fitted = geo.sphere_fit(points)
            return fitted == nil
        """)

        #expect(result.boolValue == true)
    }

    @Test("sphere_fit with too few points returns nil")
    func sphereFitTooFewPoints() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec3(1, 0, 0),
                geo.vec3(0, 1, 0),
                geo.vec3(0, 0, 1)
            }
            local fitted = geo.sphere_fit(points)
            return fitted == nil
        """)

        #expect(result.boolValue == true)
    }

    @Test("sphere_from_4_points returns proper sphere object")
    func sphereFrom4PointsReturnsSphereObject() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere_from_4_points(
                geo.vec3(1, 0, 0),
                geo.vec3(0, 1, 0),
                geo.vec3(0, 0, 1),
                geo.vec3(-1, 0, 0)
            )
            -- Verify it's a proper sphere object with methods
            local has_volume = type(s.volume) == "function"
            local has_contains = type(s.contains) == "function"
            local has_center = s.center ~= nil
            local has_radius = s.radius ~= nil
            return {has_volume, has_contains, has_center, has_radius, s.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)  // has volume method
        #expect(arr[1].boolValue == true)  // has contains method
        #expect(arr[2].boolValue == true)  // has center
        #expect(arr[3].boolValue == true)  // has radius
        #expect(arr[4].numberValue! > 0)   // radius is positive
    }

    @Test("sphere translate")
    func sphereTranslate() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(0, 0, 0, 5)
            local translated = s:translate(1, 2, 3)
            return {
                translated.center.x, translated.center.y, translated.center.z,
                translated.radius,
                s.center.x  -- original unchanged
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)  // translated x
        #expect(arr[1].numberValue == 2)  // translated y
        #expect(arr[2].numberValue == 3)  // translated z
        #expect(arr[3].numberValue == 5)  // radius unchanged
        #expect(arr[4].numberValue == 0)  // original unchanged
    }

    @Test("sphere scale")
    func sphereScale() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(1, 2, 3, 4)
            local scaled = s:scale(2)
            return {scaled.radius, s.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 8)  // scaled radius
        #expect(arr[1].numberValue == 4)  // original unchanged
    }

    @Test("sphere bounds")
    func sphereBounds() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(1, 2, 3, 5)
            local b = s:bounds()
            return {b.min.x, b.min.y, b.min.z, b.max.x, b.max.y, b.max.z}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == -4)  // min x = 1 - 5
        #expect(arr[1].numberValue == -3)  // min y = 2 - 5
        #expect(arr[2].numberValue == -2)  // min z = 3 - 5
        #expect(arr[3].numberValue == 6)   // max x = 1 + 5
        #expect(arr[4].numberValue == 7)   // max y = 2 + 5
        #expect(arr[5].numberValue == 8)   // max z = 3 + 5
    }

    @Test("sphere distance to point")
    func sphereDistanceToPoint() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(0, 0, 0, 5)
            local outside = s:distance(geo.vec3(10, 0, 0))  -- 10 - 5 = 5
            local inside = s:distance(geo.vec3(2, 0, 0))    -- 2 - 5 = -3 (negative = inside)
            local on_surface = s:distance(geo.vec3(5, 0, 0))
            return {outside, inside, on_surface}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 5.0) < 0.0001)   // outside
        #expect(abs(arr[1].numberValue! + 3.0) < 0.0001)   // inside (negative)
        #expect(abs(arr[2].numberValue!) < 0.0001)         // on surface
    }

    @Test("sphere clone")
    func sphereClone() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local s = geo.sphere(1, 2, 3, 4)
            local cloned = s:clone()
            -- Modify original to ensure clone is independent
            local translated = s:translate(10, 10, 10)
            return {
                cloned.center.x, cloned.center.y, cloned.center.z, cloned.radius,
                s.center.x  -- original shouldn't be affected by translate
            }
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)  // clone unchanged
        #expect(arr[1].numberValue == 2)
        #expect(arr[2].numberValue == 3)
        #expect(arr[3].numberValue == 4)
        #expect(arr[4].numberValue == 1)  // original unchanged (translate returns new)
    }

    // MARK: - Unified geo.fit() Tests

    @Test("geo.fit with 'line' fits linear polynomial")
    func geoFitLine() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)
        ModuleRegistry.installLinAlgModule(in: engine)  // Required for polyfit

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec2(0, 1),
                geo.vec2(1, 3),
                geo.vec2(2, 5),
                geo.vec2(3, 7)
            }
            local fit = geo.fit(points, 'line')
            -- y = 2x + 1
            return {fit:evaluate(0), fit:evaluate(1), fit:evaluate(2), fit:degree()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 1.0) < 0.0001)  // y(0) = 1
        #expect(abs(arr[1].numberValue! - 3.0) < 0.0001)  // y(1) = 3
        #expect(abs(arr[2].numberValue! - 5.0) < 0.0001)  // y(2) = 5
        #expect(arr[3].numberValue == 1)  // degree 1 polynomial
    }

    @Test("geo.fit with 'polynomial' and degree option")
    func geoFitPolynomial() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)
        ModuleRegistry.installLinAlgModule(in: engine)  // Required for polyfit

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- y = x^2
            local points = {
                geo.vec2(0, 0),
                geo.vec2(1, 1),
                geo.vec2(2, 4),
                geo.vec2(-1, 1),
                geo.vec2(-2, 4)
            }
            local fit = geo.fit(points, 'polynomial', {degree = 2})
            return {fit:evaluate(3), fit:degree()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 9.0) < 0.0001)  // 3^2 = 9
        #expect(arr[1].numberValue == 2)  // degree 2
    }

    @Test("geo.fit with 'circle'")
    func geoFitCircle() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec2(1, 0),
                geo.vec2(0, 1),
                geo.vec2(-1, 0),
                geo.vec2(0, -1)
            }
            local circle = geo.fit(points, 'circle')
            return {circle.center.x, circle.center.y, circle.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001)       // center x = 0
        #expect(abs(arr[1].numberValue!) < 0.0001)       // center y = 0
        #expect(abs(arr[2].numberValue! - 1.0) < 0.0001) // radius = 1
    }

    @Test("geo.fit with 'ellipse'")
    func geoFitEllipse() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Points on axis-aligned ellipse with a=2, b=1
            local points = {
                geo.vec2(2, 0),
                geo.vec2(-2, 0),
                geo.vec2(0, 1),
                geo.vec2(0, -1),
                geo.vec2(1.414, 0.707)  -- approximately
            }
            local ellipse = geo.fit(points, 'ellipse')
            return {ellipse.center.x, ellipse.center.y, ellipse.semi_major, ellipse.semi_minor}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.1)  // center x ≈ 0
        #expect(abs(arr[1].numberValue!) < 0.1)  // center y ≈ 0
        // semi_major and semi_minor should be approximately 2 and 1
        let a = arr[2].numberValue!
        let b = arr[3].numberValue!
        #expect((abs(a - 2.0) < 0.2 && abs(b - 1.0) < 0.2) || (abs(a - 1.0) < 0.2 && abs(b - 2.0) < 0.2))
    }

    @Test("geo.fit with 'sphere'")
    func geoFitSphere() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec3(1, 0, 0),
                geo.vec3(-1, 0, 0),
                geo.vec3(0, 1, 0),
                geo.vec3(0, -1, 0),
                geo.vec3(0, 0, 1),
                geo.vec3(0, 0, -1)
            }
            local sphere = geo.fit(points, 'sphere')
            return {sphere.center.x, sphere.center.y, sphere.center.z, sphere.radius}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue!) < 0.0001)       // center x = 0
        #expect(abs(arr[1].numberValue!) < 0.0001)       // center y = 0
        #expect(abs(arr[2].numberValue!) < 0.0001)       // center z = 0
        #expect(abs(arr[3].numberValue! - 1.0) < 0.0001) // radius = 1
    }

    @Test("geo.fit with 'spline' creates cubic spline")
    func geoFitSpline() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec2(0, 0),
                geo.vec2(1, 1),
                geo.vec2(2, 0),
                geo.vec2(3, 1)
            }
            local spline = geo.fit(points, 'spline')
            -- Evaluate at knot points using evaluate method
            return {spline:evaluate(0), spline:evaluate(1), spline:evaluate(2), spline:evaluate(3)}
        """)

        let arr = try #require(result.arrayValue)
        #expect(abs(arr[0].numberValue! - 0.0) < 0.0001)  // passes through (0,0)
        #expect(abs(arr[1].numberValue! - 1.0) < 0.0001)  // passes through (1,1)
        #expect(abs(arr[2].numberValue! - 0.0) < 0.0001)  // passes through (2,0)
        #expect(abs(arr[3].numberValue! - 1.0) < 0.0001)  // passes through (3,1)
    }

    @Test("geo.fit with 'bspline' creates B-spline")
    func geoFitBspline() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            -- Control points for a B-spline
            local control_points = {
                geo.vec2(0, 0),
                geo.vec2(1, 2),
                geo.vec2(2, 2),
                geo.vec2(3, 0)
            }
            local bspline = geo.fit(control_points, 'bspline', {degree = 2})
            -- Check that we can evaluate it using evaluate method
            local p = bspline:evaluate(0.5)
            return {type(p) == "table", p.x ~= nil, p.y ~= nil, bspline:degree()}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].boolValue == true)  // returns table
        #expect(arr[1].boolValue == true)  // has x
        #expect(arr[2].boolValue == true)  // has y
        #expect(arr[3].numberValue == 2)   // degree 2
    }

    @Test("geo.fit with unknown shape throws error")
    func geoFitUnknownShape() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)

        do {
            _ = try engine.evaluate("""
                local geo = luaswift.geometry
                local points = {geo.vec2(0, 0)}
                geo.fit(points, 'unknown_shape')
            """)
            Issue.record("Expected error for unknown shape")
        } catch {
            let errorMessage = String(describing: error)
            #expect(errorMessage.contains("Unknown shape"))
        }
    }

    @Test("geo.fit aliases work correctly")
    func geoFitAliases() throws {
        let engine = try LuaEngine()
        ModuleRegistry.installGeometryModule(in: engine)
        ModuleRegistry.installLinAlgModule(in: engine)  // Required for polyfit

        let result = try engine.evaluate("""
            local geo = luaswift.geometry
            local points = {
                geo.vec2(0, 0),
                geo.vec2(1, 1),
                geo.vec2(2, 4)
            }
            -- Test 'linear' alias for 'line'
            local linear_fit = geo.fit(points, 'linear')
            -- Test 'poly' alias for 'polynomial'
            local poly_fit = geo.fit(points, 'poly', {degree = 2})
            -- Test 'cubic_spline' alias for 'spline'
            local spline_fit = geo.fit(points, 'cubic_spline')
            return {linear_fit:degree(), poly_fit:degree(), type(spline_fit)}
        """)

        let arr = try #require(result.arrayValue)
        #expect(arr[0].numberValue == 1)          // linear = degree 1
        #expect(arr[1].numberValue == 2)          // poly with degree=2
        #expect(arr[2].stringValue == "table")    // spline is a table/object
    }
}
