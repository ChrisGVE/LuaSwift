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
}
