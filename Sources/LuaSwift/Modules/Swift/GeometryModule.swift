//
//  GeometryModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Accelerate
import simd

/// Optimized geometry module for LuaSwift.
///
/// Provides high-performance 2D/3D geometry operations using SIMD and Accelerate.
///
/// ## Usage
///
/// ```lua
/// local geo = require("luaswift.geometry")
///
/// local v1 = geo.vec2(3, 4)
/// print(v1:length())  -- 5
///
/// local q = geo.quaternion.from_euler(0, math.pi/2, 0)
/// local rotated = q:rotate(geo.vec3(1, 0, 0))
/// ```
public struct GeometryModule {

    // MARK: - Registration

    /// Register the geometry module in the given engine.
    public static func register(in engine: LuaEngine) {
        // Vec2 operations
        engine.registerFunction(name: "_luaswift_geo_vec2_create", callback: vec2CreateCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_length", callback: vec2LengthCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_length_squared", callback: vec2LengthSquaredCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_normalize", callback: vec2NormalizeCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_dot", callback: vec2DotCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_cross", callback: vec2CrossCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_angle", callback: vec2AngleCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_rotate", callback: vec2RotateCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_lerp", callback: vec2LerpCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_add", callback: vec2AddCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_sub", callback: vec2SubCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_mul", callback: vec2MulCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_div", callback: vec2DivCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_neg", callback: vec2NegCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_project", callback: vec2ProjectCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_reflect", callback: vec2ReflectCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_perpendicular", callback: vec2PerpendicularCallback)

        // Vec3 operations
        engine.registerFunction(name: "_luaswift_geo_vec3_create", callback: vec3CreateCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_length", callback: vec3LengthCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_length_squared", callback: vec3LengthSquaredCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_normalize", callback: vec3NormalizeCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_dot", callback: vec3DotCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_cross", callback: vec3CrossCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_rotate", callback: vec3RotateCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_lerp", callback: vec3LerpCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_add", callback: vec3AddCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_sub", callback: vec3SubCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_mul", callback: vec3MulCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_div", callback: vec3DivCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_neg", callback: vec3NegCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_project", callback: vec3ProjectCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_reflect", callback: vec3ReflectCallback)

        // Quaternion operations
        engine.registerFunction(name: "_luaswift_geo_quat_create", callback: quatCreateCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_identity", callback: quatIdentityCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_from_euler", callback: quatFromEulerCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_from_axis_angle", callback: quatFromAxisAngleCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_normalize", callback: quatNormalizeCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_conjugate", callback: quatConjugateCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_inverse", callback: quatInverseCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_mul", callback: quatMulCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_rotate", callback: quatRotateCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_slerp", callback: quatSlerpCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_to_euler", callback: quatToEulerCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_to_axis_angle", callback: quatToAxisAngleCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_to_matrix", callback: quatToMatrixCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_dot", callback: quatDotCallback)
        engine.registerFunction(name: "_luaswift_geo_quat_length", callback: quatLengthCallback)

        // Matrix 4x4 operations
        engine.registerFunction(name: "_luaswift_geo_mat4_identity", callback: mat4IdentityCallback)
        engine.registerFunction(name: "_luaswift_geo_mat4_translate", callback: mat4TranslateCallback)
        engine.registerFunction(name: "_luaswift_geo_mat4_rotate_x", callback: mat4RotateXCallback)
        engine.registerFunction(name: "_luaswift_geo_mat4_rotate_y", callback: mat4RotateYCallback)
        engine.registerFunction(name: "_luaswift_geo_mat4_rotate_z", callback: mat4RotateZCallback)
        engine.registerFunction(name: "_luaswift_geo_mat4_rotate_axis", callback: mat4RotateAxisCallback)
        engine.registerFunction(name: "_luaswift_geo_mat4_scale", callback: mat4ScaleCallback)
        engine.registerFunction(name: "_luaswift_geo_mat4_multiply", callback: mat4MultiplyCallback)
        engine.registerFunction(name: "_luaswift_geo_mat4_apply", callback: mat4ApplyCallback)

        // Coordinate conversions
        engine.registerFunction(name: "_luaswift_geo_vec2_to_polar", callback: vec2ToPolarCallback)
        engine.registerFunction(name: "_luaswift_geo_vec2_from_polar", callback: vec2FromPolarCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_to_spherical", callback: vec3ToSphericalCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_from_spherical", callback: vec3FromSphericalCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_to_cylindrical", callback: vec3ToCylindricalCallback)
        engine.registerFunction(name: "_luaswift_geo_vec3_from_cylindrical", callback: vec3FromCylindricalCallback)

        // Geometric calculations
        engine.registerFunction(name: "_luaswift_geo_distance", callback: distanceCallback)
        engine.registerFunction(name: "_luaswift_geo_angle_between", callback: angleBetweenCallback)
        engine.registerFunction(name: "_luaswift_geo_convex_hull", callback: convexHullCallback)
        engine.registerFunction(name: "_luaswift_geo_in_polygon", callback: inPolygonCallback)
        engine.registerFunction(name: "_luaswift_geo_line_intersection", callback: lineIntersectionCallback)
        engine.registerFunction(name: "_luaswift_geo_area_triangle", callback: areaTriangleCallback)
        engine.registerFunction(name: "_luaswift_geo_centroid", callback: centroidCallback)
        engine.registerFunction(name: "_luaswift_geo_circle_from_3_points", callback: circleFrom3PointsCallback)
        engine.registerFunction(name: "_luaswift_geo_plane_from_3_points", callback: planeFrom3PointsCallback)
        engine.registerFunction(name: "_luaswift_geo_point_plane_distance", callback: pointPlaneDistanceCallback)
        engine.registerFunction(name: "_luaswift_geo_line_plane_intersection", callback: linePlaneIntersectionCallback)
        engine.registerFunction(name: "_luaswift_geo_plane_plane_intersection", callback: planePlaneIntersectionCallback)
        engine.registerFunction(name: "_luaswift_geo_intersection", callback: intersectionCallback)
        engine.registerFunction(name: "_luaswift_geo_sphere_from_4_points", callback: sphereFrom4PointsCallback)

        // Set up the luaswift.geometry namespace
        do {
            try engine.run(geometryLuaWrapper)
        } catch {
            // Module setup failed - functions still available as globals
        }
    }

    // MARK: - Helper Types and Conversions

    /// Extract vec2 from Lua table
    private static func extractVec2(_ value: LuaValue) -> simd_double2? {
        guard let table = value.tableValue else { return nil }
        guard let x = table["x"]?.numberValue ?? table["1"]?.numberValue,
              let y = table["y"]?.numberValue ?? table["2"]?.numberValue else { return nil }
        return simd_double2(x, y)
    }

    /// Extract vec3 from Lua table
    private static func extractVec3(_ value: LuaValue) -> simd_double3? {
        guard let table = value.tableValue else { return nil }
        guard let x = table["x"]?.numberValue ?? table["1"]?.numberValue,
              let y = table["y"]?.numberValue ?? table["2"]?.numberValue,
              let z = table["z"]?.numberValue ?? table["3"]?.numberValue else { return nil }
        return simd_double3(x, y, z)
    }

    /// Extract quaternion from Lua table
    private static func extractQuat(_ value: LuaValue) -> simd_quatd? {
        guard let table = value.tableValue else { return nil }
        guard let w = table["w"]?.numberValue ?? table["1"]?.numberValue,
              let x = table["x"]?.numberValue ?? table["2"]?.numberValue,
              let y = table["y"]?.numberValue ?? table["3"]?.numberValue,
              let z = table["z"]?.numberValue ?? table["4"]?.numberValue else { return nil }
        return simd_quatd(ix: x, iy: y, iz: z, r: w)
    }

    /// Extract 4x4 matrix from Lua table (row-major, 1-indexed)
    private static func extractMat4(_ value: LuaValue) -> simd_double4x4? {
        guard let table = value.tableValue else { return nil }
        var elements = [Double](repeating: 0, count: 16)
        for i in 1...16 {
            guard let v = table[String(i)]?.numberValue else { return nil }
            elements[i - 1] = v
        }
        // Convert from row-major Lua to column-major SIMD
        return simd_double4x4(
            simd_double4(elements[0], elements[4], elements[8], elements[12]),
            simd_double4(elements[1], elements[5], elements[9], elements[13]),
            simd_double4(elements[2], elements[6], elements[10], elements[14]),
            simd_double4(elements[3], elements[7], elements[11], elements[15])
        )
    }

    /// Convert vec2 to Lua table
    private static func vec2ToLua(_ v: simd_double2) -> LuaValue {
        return .table(["x": .number(v.x), "y": .number(v.y)])
    }

    /// Convert vec3 to Lua table
    private static func vec3ToLua(_ v: simd_double3) -> LuaValue {
        return .table(["x": .number(v.x), "y": .number(v.y), "z": .number(v.z)])
    }

    /// Convert quaternion to Lua table
    private static func quatToLua(_ q: simd_quatd) -> LuaValue {
        return .table(["w": .number(q.real), "x": .number(q.imag.x), "y": .number(q.imag.y), "z": .number(q.imag.z)])
    }

    /// Convert 4x4 matrix to Lua table (row-major, 1-indexed)
    private static func mat4ToLua(_ m: simd_double4x4) -> LuaValue {
        // Convert from column-major SIMD to row-major Lua
        var result: [String: LuaValue] = [:]
        for row in 0..<4 {
            for col in 0..<4 {
                let index = row * 4 + col + 1
                result[String(index)] = .number(m[col][row])
            }
        }
        return .table(result)
    }

    // MARK: - Vec2 Callbacks

    private static let vec2CreateCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let x = args[0].numberValue,
              let y = args[1].numberValue else {
            return .nil
        }
        return vec2ToLua(simd_double2(x, y))
    }

    private static let vec2LengthCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec2(args[0]) else { return .nil }
        return .number(simd_length(v))
    }

    private static let vec2LengthSquaredCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec2(args[0]) else { return .nil }
        return .number(simd_length_squared(v))
    }

    private static let vec2NormalizeCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec2(args[0]) else { return .nil }
        let len = simd_length(v)
        if len == 0 { return vec2ToLua(simd_double2(0, 0)) }
        return vec2ToLua(simd_normalize(v))
    }

    private static let vec2DotCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v1 = extractVec2(args[0]),
              let v2 = extractVec2(args[1]) else { return .nil }
        return .number(simd_dot(v1, v2))
    }

    private static let vec2CrossCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v1 = extractVec2(args[0]),
              let v2 = extractVec2(args[1]) else { return .nil }
        // 2D cross product returns scalar (z-component of 3D cross)
        return .number(v1.x * v2.y - v1.y * v2.x)
    }

    private static let vec2AngleCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec2(args[0]) else { return .nil }
        return .number(atan2(v.y, v.x))
    }

    private static let vec2RotateCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec2(args[0]),
              let theta = args[1].numberValue else { return .nil }
        let c = cos(theta)
        let s = sin(theta)
        return vec2ToLua(simd_double2(v.x * c - v.y * s, v.x * s + v.y * c))
    }

    private static let vec2LerpCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let v1 = extractVec2(args[0]),
              let v2 = extractVec2(args[1]),
              let t = args[2].numberValue else { return .nil }
        return vec2ToLua(simd_mix(v1, v2, simd_double2(repeating: t)))
    }

    private static let vec2AddCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v1 = extractVec2(args[0]),
              let v2 = extractVec2(args[1]) else { return .nil }
        return vec2ToLua(v1 + v2)
    }

    private static let vec2SubCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v1 = extractVec2(args[0]),
              let v2 = extractVec2(args[1]) else { return .nil }
        return vec2ToLua(v1 - v2)
    }

    private static let vec2MulCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec2(args[0]),
              let s = args[1].numberValue else { return .nil }
        return vec2ToLua(v * s)
    }

    private static let vec2DivCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec2(args[0]),
              let s = args[1].numberValue, s != 0 else { return .nil }
        return vec2ToLua(v / s)
    }

    private static let vec2NegCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec2(args[0]) else { return .nil }
        return vec2ToLua(-v)
    }

    private static let vec2ProjectCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec2(args[0]),
              let onto = extractVec2(args[1]) else { return .nil }
        let lenSq = simd_length_squared(onto)
        if lenSq == 0 { return vec2ToLua(simd_double2(0, 0)) }
        return vec2ToLua(onto * (simd_dot(v, onto) / lenSq))
    }

    private static let vec2ReflectCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec2(args[0]),
              let normal = extractVec2(args[1]) else { return .nil }
        return vec2ToLua(simd_reflect(v, normal))
    }

    private static let vec2PerpendicularCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec2(args[0]) else { return .nil }
        return vec2ToLua(simd_double2(-v.y, v.x))
    }

    // MARK: - Vec3 Callbacks

    private static let vec3CreateCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let x = args[0].numberValue,
              let y = args[1].numberValue,
              let z = args[2].numberValue else {
            return .nil
        }
        return vec3ToLua(simd_double3(x, y, z))
    }

    private static let vec3LengthCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec3(args[0]) else { return .nil }
        return .number(simd_length(v))
    }

    private static let vec3LengthSquaredCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec3(args[0]) else { return .nil }
        return .number(simd_length_squared(v))
    }

    private static let vec3NormalizeCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec3(args[0]) else { return .nil }
        let len = simd_length(v)
        if len == 0 { return vec3ToLua(simd_double3(0, 0, 0)) }
        return vec3ToLua(simd_normalize(v))
    }

    private static let vec3DotCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v1 = extractVec3(args[0]),
              let v2 = extractVec3(args[1]) else { return .nil }
        return .number(simd_dot(v1, v2))
    }

    private static let vec3CrossCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v1 = extractVec3(args[0]),
              let v2 = extractVec3(args[1]) else { return .nil }
        return vec3ToLua(simd_cross(v1, v2))
    }

    private static let vec3RotateCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let v = extractVec3(args[0]),
              let axis = extractVec3(args[1]),
              let angle = args[2].numberValue else { return .nil }
        let q = simd_quatd(angle: angle, axis: simd_normalize(axis))
        return vec3ToLua(q.act(v))
    }

    private static let vec3LerpCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let v1 = extractVec3(args[0]),
              let v2 = extractVec3(args[1]),
              let t = args[2].numberValue else { return .nil }
        return vec3ToLua(simd_mix(v1, v2, simd_double3(repeating: t)))
    }

    private static let vec3AddCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v1 = extractVec3(args[0]),
              let v2 = extractVec3(args[1]) else { return .nil }
        return vec3ToLua(v1 + v2)
    }

    private static let vec3SubCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v1 = extractVec3(args[0]),
              let v2 = extractVec3(args[1]) else { return .nil }
        return vec3ToLua(v1 - v2)
    }

    private static let vec3MulCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec3(args[0]),
              let s = args[1].numberValue else { return .nil }
        return vec3ToLua(v * s)
    }

    private static let vec3DivCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec3(args[0]),
              let s = args[1].numberValue, s != 0 else { return .nil }
        return vec3ToLua(v / s)
    }

    private static let vec3NegCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec3(args[0]) else { return .nil }
        return vec3ToLua(-v)
    }

    private static let vec3ProjectCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec3(args[0]),
              let onto = extractVec3(args[1]) else { return .nil }
        let lenSq = simd_length_squared(onto)
        if lenSq == 0 { return vec3ToLua(simd_double3(0, 0, 0)) }
        return vec3ToLua(onto * (simd_dot(v, onto) / lenSq))
    }

    private static let vec3ReflectCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let v = extractVec3(args[0]),
              let normal = extractVec3(args[1]) else { return .nil }
        return vec3ToLua(simd_reflect(v, normal))
    }

    // MARK: - Quaternion Callbacks

    private static let quatCreateCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 4,
              let w = args[0].numberValue,
              let x = args[1].numberValue,
              let y = args[2].numberValue,
              let z = args[3].numberValue else {
            return .nil
        }
        return quatToLua(simd_quatd(ix: x, iy: y, iz: z, r: w))
    }

    private static let quatIdentityCallback: ([LuaValue]) -> LuaValue = { _ in
        return quatToLua(simd_quatd(ix: 0, iy: 0, iz: 0, r: 1))
    }

    private static let quatFromEulerCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let yaw = args[0].numberValue,
              let pitch = args[1].numberValue,
              let roll = args[2].numberValue else { return .nil }

        // Convert Euler angles (yaw, pitch, roll) to quaternion
        let cy = cos(yaw * 0.5)
        let sy = sin(yaw * 0.5)
        let cp = cos(pitch * 0.5)
        let sp = sin(pitch * 0.5)
        let cr = cos(roll * 0.5)
        let sr = sin(roll * 0.5)

        let w = cr * cp * cy + sr * sp * sy
        let x = sr * cp * cy - cr * sp * sy
        let y = cr * sp * cy + sr * cp * sy
        let z = cr * cp * sy - sr * sp * cy

        return quatToLua(simd_quatd(ix: x, iy: y, iz: z, r: w))
    }

    private static let quatFromAxisAngleCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let axis = extractVec3(args[0]),
              let angle = args[1].numberValue else { return .nil }
        return quatToLua(simd_quatd(angle: angle, axis: simd_normalize(axis)))
    }

    private static let quatNormalizeCallback: ([LuaValue]) -> LuaValue = { args in
        guard let q = extractQuat(args[0]) else { return .nil }
        return quatToLua(simd_normalize(q))
    }

    private static let quatConjugateCallback: ([LuaValue]) -> LuaValue = { args in
        guard let q = extractQuat(args[0]) else { return .nil }
        return quatToLua(q.conjugate)
    }

    private static let quatInverseCallback: ([LuaValue]) -> LuaValue = { args in
        guard let q = extractQuat(args[0]) else { return .nil }
        return quatToLua(q.inverse)
    }

    private static let quatMulCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let q1 = extractQuat(args[0]),
              let q2 = extractQuat(args[1]) else { return .nil }
        return quatToLua(q1 * q2)
    }

    private static let quatRotateCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let q = extractQuat(args[0]),
              let v = extractVec3(args[1]) else { return .nil }
        return vec3ToLua(q.act(v))
    }

    private static let quatSlerpCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let q1 = extractQuat(args[0]),
              let q2 = extractQuat(args[1]),
              let t = args[2].numberValue else { return .nil }
        return quatToLua(simd_slerp(q1, q2, t))
    }

    private static let quatToEulerCallback: ([LuaValue]) -> LuaValue = { args in
        guard let q = extractQuat(args[0]) else { return .nil }

        // Convert quaternion to Euler angles (yaw, pitch, roll)
        let sinr_cosp = 2 * (q.real * q.imag.x + q.imag.y * q.imag.z)
        let cosr_cosp = 1 - 2 * (q.imag.x * q.imag.x + q.imag.y * q.imag.y)
        let roll = atan2(sinr_cosp, cosr_cosp)

        let sinp = 2 * (q.real * q.imag.y - q.imag.z * q.imag.x)
        let pitch: Double
        if abs(sinp) >= 1 {
            pitch = copysign(Double.pi / 2, sinp)
        } else {
            pitch = asin(sinp)
        }

        let siny_cosp = 2 * (q.real * q.imag.z + q.imag.x * q.imag.y)
        let cosy_cosp = 1 - 2 * (q.imag.y * q.imag.y + q.imag.z * q.imag.z)
        let yaw = atan2(siny_cosp, cosy_cosp)

        return .array([.number(yaw), .number(pitch), .number(roll)])
    }

    private static let quatToAxisAngleCallback: ([LuaValue]) -> LuaValue = { args in
        guard let q = extractQuat(args[0]) else { return .nil }
        let angle = 2 * acos(q.real)
        let s = sqrt(1 - q.real * q.real)
        let axis: simd_double3
        if s < 0.001 {
            axis = simd_double3(1, 0, 0)
        } else {
            axis = q.imag / s
        }
        return .array([vec3ToLua(axis), .number(angle)])
    }

    private static let quatToMatrixCallback: ([LuaValue]) -> LuaValue = { args in
        guard let q = extractQuat(args[0]) else { return .nil }

        let x = q.imag.x, y = q.imag.y, z = q.imag.z, w = q.real
        let x2 = x + x, y2 = y + y, z2 = z + z
        let xx = x * x2, xy = x * y2, xz = x * z2
        let yy = y * y2, yz = y * z2, zz = z * z2
        let wx = w * x2, wy = w * y2, wz = w * z2

        // Return as 3x3 matrix (9 elements, row-major)
        return .array([
            .number(1 - (yy + zz)), .number(xy - wz), .number(xz + wy),
            .number(xy + wz), .number(1 - (xx + zz)), .number(yz - wx),
            .number(xz - wy), .number(yz + wx), .number(1 - (xx + yy))
        ])
    }

    private static let quatDotCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let q1 = extractQuat(args[0]),
              let q2 = extractQuat(args[1]) else { return .nil }
        return .number(q1.real * q2.real + simd_dot(q1.imag, q2.imag))
    }

    private static let quatLengthCallback: ([LuaValue]) -> LuaValue = { args in
        guard let q = extractQuat(args[0]) else { return .nil }
        return .number(q.length)
    }

    // MARK: - Matrix 4x4 Callbacks

    private static let mat4IdentityCallback: ([LuaValue]) -> LuaValue = { _ in
        return mat4ToLua(matrix_identity_double4x4)
    }

    private static let mat4TranslateCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 4,
              let m = extractMat4(args[0]),
              let dx = args[1].numberValue,
              let dy = args[2].numberValue,
              let dz = args[3].numberValue else { return .nil }

        var translation = matrix_identity_double4x4
        translation[3] = simd_double4(dx, dy, dz, 1)
        return mat4ToLua(simd_mul(m, translation))
    }

    private static let mat4RotateXCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let m = extractMat4(args[0]),
              let angle = args[1].numberValue else { return .nil }

        let c = cos(angle), s = sin(angle)
        var rotation = matrix_identity_double4x4
        rotation[1][1] = c; rotation[1][2] = s
        rotation[2][1] = -s; rotation[2][2] = c
        return mat4ToLua(simd_mul(m, rotation))
    }

    private static let mat4RotateYCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let m = extractMat4(args[0]),
              let angle = args[1].numberValue else { return .nil }

        let c = cos(angle), s = sin(angle)
        var rotation = matrix_identity_double4x4
        rotation[0][0] = c; rotation[0][2] = -s
        rotation[2][0] = s; rotation[2][2] = c
        return mat4ToLua(simd_mul(m, rotation))
    }

    private static let mat4RotateZCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let m = extractMat4(args[0]),
              let angle = args[1].numberValue else { return .nil }

        let c = cos(angle), s = sin(angle)
        var rotation = matrix_identity_double4x4
        rotation[0][0] = c; rotation[0][1] = s
        rotation[1][0] = -s; rotation[1][1] = c
        return mat4ToLua(simd_mul(m, rotation))
    }

    private static let mat4RotateAxisCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let m = extractMat4(args[0]),
              let axis = extractVec3(args[1]),
              let angle = args[2].numberValue else { return .nil }

        let n = simd_normalize(axis)
        let c = cos(angle), s = sin(angle), t = 1 - c

        var rotation = matrix_identity_double4x4
        rotation[0][0] = t * n.x * n.x + c
        rotation[0][1] = t * n.x * n.y + s * n.z
        rotation[0][2] = t * n.x * n.z - s * n.y
        rotation[1][0] = t * n.x * n.y - s * n.z
        rotation[1][1] = t * n.y * n.y + c
        rotation[1][2] = t * n.y * n.z + s * n.x
        rotation[2][0] = t * n.x * n.z + s * n.y
        rotation[2][1] = t * n.y * n.z - s * n.x
        rotation[2][2] = t * n.z * n.z + c

        return mat4ToLua(simd_mul(m, rotation))
    }

    private static let mat4ScaleCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let m = extractMat4(args[0]) else { return .nil }

        let sx = args[1].numberValue ?? 1
        let sy = args.count > 2 ? (args[2].numberValue ?? sx) : sx
        let sz = args.count > 3 ? (args[3].numberValue ?? sx) : sx

        var scale = matrix_identity_double4x4
        scale[0][0] = sx; scale[1][1] = sy; scale[2][2] = sz
        return mat4ToLua(simd_mul(m, scale))
    }

    private static let mat4MultiplyCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let m1 = extractMat4(args[0]),
              let m2 = extractMat4(args[1]) else { return .nil }
        return mat4ToLua(simd_mul(m1, m2))
    }

    private static let mat4ApplyCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let m = extractMat4(args[0]),
              let v = extractVec3(args[1]) else { return .nil }

        let v4 = simd_double4(v.x, v.y, v.z, 1)
        let result = simd_mul(m, v4)
        return vec3ToLua(simd_double3(result.x, result.y, result.z))
    }

    // MARK: - Geometric Calculation Callbacks

    private static let distanceCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2 else { return .nil }

        // Try quaternion first (4D), then 3D, then 2D
        if let q1 = extractQuat(args[0]), let q2 = extractQuat(args[1]) {
            // Quaternion distance: Euclidean distance in 4D
            let dw = q1.real - q2.real
            let dx = q1.imag.x - q2.imag.x
            let dy = q1.imag.y - q2.imag.y
            let dz = q1.imag.z - q2.imag.z
            return .number(sqrt(dw * dw + dx * dx + dy * dy + dz * dz))
        } else if let v1 = extractVec3(args[0]), let v2 = extractVec3(args[1]) {
            return .number(simd_distance(v1, v2))
        } else if let v1 = extractVec2(args[0]), let v2 = extractVec2(args[1]) {
            return .number(simd_distance(v1, v2))
        }
        return .nil
    }

    /// Angle between two vectors (implicit origin translation)
    private static let angleBetweenCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2 else { return .nil }

        // Try 3D first, then 2D
        if let v1 = extractVec3(args[0]), let v2 = extractVec3(args[1]) {
            let len1 = simd_length(v1)
            let len2 = simd_length(v2)
            guard len1 > 0 && len2 > 0 else { return .nil }
            let dotProduct = simd_dot(v1, v2)
            // Clamp to avoid numerical issues with acos
            let cosAngle = max(-1.0, min(1.0, dotProduct / (len1 * len2)))
            return .number(acos(cosAngle))
        } else if let v1 = extractVec2(args[0]), let v2 = extractVec2(args[1]) {
            let len1 = simd_length(v1)
            let len2 = simd_length(v2)
            guard len1 > 0 && len2 > 0 else { return .nil }
            // Use atan2 for signed angle in 2D
            let cross = v1.x * v2.y - v1.y * v2.x
            let dot = simd_dot(v1, v2)
            return .number(atan2(cross, dot))
        }
        return .nil
    }

    private static let convexHullCallback: ([LuaValue]) -> LuaValue = { args in
        guard let arr = args[0].arrayValue else { return .nil }

        // Extract points
        var points: [(x: Double, y: Double, idx: Int)] = []
        for (idx, p) in arr.enumerated() {
            if let v = extractVec2(p) {
                points.append((v.x, v.y, idx))
            } else if let tbl = p.tableValue,
                      let x = tbl["x"]?.numberValue,
                      let y = tbl["y"]?.numberValue {
                points.append((x, y, idx))
            }
        }

        guard points.count >= 3 else {
            return .array(arr)
        }

        // Pre-compute polar angles (optimization: avoid atan2 in sort)
        // Find bottom-most point (and leftmost if tie)
        var startIdx = 0
        for i in 1..<points.count {
            if points[i].y < points[startIdx].y ||
               (points[i].y == points[startIdx].y && points[i].x < points[startIdx].x) {
                startIdx = i
            }
        }
        let start = points[startIdx]
        points.remove(at: startIdx)

        // Pre-compute angles using vectorized operations
        var angles = [Double](repeating: 0, count: points.count)
        var distances = [Double](repeating: 0, count: points.count)
        for i in 0..<points.count {
            let dx = points[i].x - start.x
            let dy = points[i].y - start.y
            angles[i] = atan2(dy, dx)
            distances[i] = dx * dx + dy * dy
        }

        // Sort by angle (then by distance for collinear points)
        let indices = (0..<points.count).sorted { i, j in
            if abs(angles[i] - angles[j]) < 1e-10 {
                return distances[i] < distances[j]
            }
            return angles[i] < angles[j]
        }

        // Graham scan
        var hull: [(x: Double, y: Double)] = [(start.x, start.y)]

        func ccw(_ a: (x: Double, y: Double), _ b: (x: Double, y: Double), _ c: (x: Double, y: Double)) -> Double {
            return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }

        for idx in indices {
            let p = (points[idx].x, points[idx].y)
            while hull.count >= 2 && ccw(hull[hull.count - 2], hull[hull.count - 1], p) <= 0 {
                hull.removeLast()
            }
            hull.append(p)
        }

        // Convert back to Lua
        return .array(hull.map { vec2ToLua(simd_double2($0.x, $0.y)) })
    }

    private static let inPolygonCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let point = extractVec2(args[0]),
              let polyArr = args[1].arrayValue else { return .nil }

        var polygon: [simd_double2] = []
        for p in polyArr {
            if let v = extractVec2(p) {
                polygon.append(v)
            }
        }

        guard polygon.count >= 3 else { return .bool(false) }

        // Ray casting algorithm
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) &&
               (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x) {
                inside = !inside
            }
            j = i
        }

        return .bool(inside)
    }

    private static let lineIntersectionCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let l1 = args[0].arrayValue, l1.count >= 2,
              let l2 = args[1].arrayValue, l2.count >= 2,
              let p1 = extractVec2(l1[0]), let p2 = extractVec2(l1[1]),
              let p3 = extractVec2(l2[0]), let p4 = extractVec2(l2[1]) else { return .nil }

        let d1 = p2 - p1
        let d2 = p4 - p3
        let cross = d1.x * d2.y - d1.y * d2.x

        if abs(cross) < 1e-10 { return .nil } // Parallel

        let d3 = p3 - p1
        let t = (d3.x * d2.y - d3.y * d2.x) / cross

        return vec2ToLua(p1 + d1 * t)
    }

    private static let areaTriangleCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let p1 = extractVec2(args[0]),
              let p2 = extractVec2(args[1]),
              let p3 = extractVec2(args[2]) else { return .nil }

        let dx1 = p2.x - p1.x
        let dy1 = p3.y - p1.y
        let dx2 = p3.x - p1.x
        let dy2 = p2.y - p1.y
        let area = abs(dx1 * dy1 - dx2 * dy2) / 2.0
        return .number(area)
    }

    private static let centroidCallback: ([LuaValue]) -> LuaValue = { args in
        guard let arr = args[0].arrayValue, !arr.isEmpty else { return .nil }

        // Try 3D first
        if let first = extractVec3(arr[0]) {
            var sum = first
            var count = 1
            for i in 1..<arr.count {
                if let v = extractVec3(arr[i]) {
                    sum += v
                    count += 1
                }
            }
            return vec3ToLua(sum / Double(count))
        }

        // Try 2D
        if let first = extractVec2(arr[0]) {
            var sum = first
            var count = 1
            for i in 1..<arr.count {
                if let v = extractVec2(arr[i]) {
                    sum += v
                    count += 1
                }
            }
            return vec2ToLua(sum / Double(count))
        }

        return .nil
    }

    private static let circleFrom3PointsCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let p1 = extractVec2(args[0]),
              let p2 = extractVec2(args[1]),
              let p3 = extractVec2(args[2]) else { return .nil }

        let ax = p1.x, ay = p1.y
        let bx = p2.x, by = p2.y
        let cx = p3.x, cy = p3.y

        let d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
        if abs(d) < 1e-10 { return .nil } // Collinear

        let ux = ((ax*ax + ay*ay) * (by - cy) + (bx*bx + by*by) * (cy - ay) + (cx*cx + cy*cy) * (ay - by)) / d
        let uy = ((ax*ax + ay*ay) * (cx - bx) + (bx*bx + by*by) * (ax - cx) + (cx*cx + cy*cy) * (bx - ax)) / d
        let center = simd_double2(ux, uy)
        let radius = simd_distance(center, p1)

        return .table([
            "center": vec2ToLua(center),
            "radius": .number(radius)
        ])
    }

    private static let planeFrom3PointsCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let p1 = extractVec3(args[0]),
              let p2 = extractVec3(args[1]),
              let p3 = extractVec3(args[2]) else { return .nil }

        let v1 = p2 - p1
        let v2 = p3 - p1
        let normal = simd_normalize(simd_cross(v1, v2))
        let d = -simd_dot(normal, p1)

        return .table([
            "normal": vec3ToLua(normal),
            "d": .number(d)
        ])
    }

    private static let pointPlaneDistanceCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let point = extractVec3(args[0]),
              let plane = args[1].tableValue,
              let normal = extractVec3(plane["normal"] ?? .nil),
              let d = plane["d"]?.numberValue else { return .nil }

        return .number(abs(simd_dot(normal, point) + d))
    }

    private static let linePlaneIntersectionCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let line = args[0].tableValue,
              let origin = extractVec3(line["origin"] ?? line["1"] ?? .nil),
              let direction = extractVec3(line["direction"] ?? line["2"] ?? .nil),
              let plane = args[1].tableValue,
              let normal = extractVec3(plane["normal"] ?? .nil),
              let d = plane["d"]?.numberValue else { return .nil }

        let denom = simd_dot(normal, direction)
        if abs(denom) < 1e-10 { return .nil } // Parallel

        let t = -(simd_dot(normal, origin) + d) / denom
        return vec3ToLua(origin + direction * t)
    }

    /// Plane-plane intersection returns a line (origin + direction)
    private static let planePlaneIntersectionCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let plane1 = args[0].tableValue,
              let n1 = extractVec3(plane1["normal"] ?? .nil),
              let d1 = plane1["d"]?.numberValue,
              let plane2 = args[1].tableValue,
              let n2 = extractVec3(plane2["normal"] ?? .nil),
              let d2 = plane2["d"]?.numberValue else { return .nil }

        // Line direction is cross product of normals
        let direction = simd_cross(n1, n2)
        let dirLen = simd_length(direction)
        if dirLen < 1e-10 { return .nil } // Parallel planes

        // Find a point on the intersection line using the formula:
        // point = ((d2*n1 - d1*n2) × direction) / |direction|^2
        let cross = simd_cross(n2 * (-d1) - n1 * (-d2), direction)
        let origin = cross / (dirLen * dirLen)

        return .table([
            "origin": vec3ToLua(origin),
            "direction": vec3ToLua(simd_normalize(direction))
        ])
    }

    /// Polymorphic intersection: line-line, line-plane, or plane-plane
    private static let intersectionCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2 else { return .nil }

        // Check if first arg is a plane (has "normal" and "d")
        let isPlane1 = args[0].tableValue?["normal"] != nil && args[0].tableValue?["d"] != nil
        let isPlane2 = args[1].tableValue?["normal"] != nil && args[1].tableValue?["d"] != nil

        // Check if first arg is a line (has "origin" and "direction" or is an array of 2 points)
        let isLine1 = (args[0].tableValue?["origin"] != nil && args[0].tableValue?["direction"] != nil)
                   || (args[0].arrayValue?.count == 2)
        let isLine2 = (args[1].tableValue?["origin"] != nil && args[1].tableValue?["direction"] != nil)
                   || (args[1].arrayValue?.count == 2)

        if isPlane1 && isPlane2 {
            // Plane-plane intersection
            return planePlaneIntersectionCallback(args)
        } else if isLine1 && isPlane2 {
            // Line-plane intersection
            return linePlaneIntersectionCallback(args)
        } else if isLine1 && isLine2 {
            // Line-line intersection (2D)
            return lineIntersectionCallback(args)
        }

        return .nil
    }

    private static let sphereFrom4PointsCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 4,
              let p1 = extractVec3(args[0]),
              let p2 = extractVec3(args[1]),
              let p3 = extractVec3(args[2]),
              let p4 = extractVec3(args[3]) else { return .nil }

        // Use Accelerate for 4x4 determinant computation
        // Set up the matrix for sphere center calculation
        let a: [Double] = [
            p1.x, p1.y, p1.z, 1,
            p2.x, p2.y, p2.z, 1,
            p3.x, p3.y, p3.z, 1,
            p4.x, p4.y, p4.z, 1
        ]

        // Calculate determinant using LAPACK
        var matrix = a
        var n: __CLPK_integer = 4
        var m: __CLPK_integer = 4
        var lda: __CLPK_integer = 4
        var ipiv = [__CLPK_integer](repeating: 0, count: 4)
        var info: __CLPK_integer = 0

        dgetrf_(&n, &m, &matrix, &lda, &ipiv, &info)
        if info != 0 { return .nil }

        var det = 1.0
        for i in 0..<4 {
            det *= matrix[i * 4 + i]
            if ipiv[i] != Int32(i + 1) { det = -det }
        }

        if abs(det) < 1e-10 { return .nil } // Coplanar

        // Calculate sphere center using Cramer's rule with pre-computed squared distances
        let sq1 = simd_length_squared(p1)
        let sq2 = simd_length_squared(p2)
        let sq3 = simd_length_squared(p3)
        let sq4 = simd_length_squared(p4)

        // Helper function for 3x3 determinant
        func det3(_ m: [[Double]]) -> Double {
            return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
                 - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
                 + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
        }

        let dx = det3([
            [sq1, p1.y, p1.z],
            [sq2, p2.y, p2.z],
            [sq3, p3.y, p3.z]
        ]) - det3([
            [sq1, p1.y, p1.z],
            [sq2, p2.y, p2.z],
            [sq4, p4.y, p4.z]
        ]) + det3([
            [sq1, p1.y, p1.z],
            [sq3, p3.y, p3.z],
            [sq4, p4.y, p4.z]
        ]) - det3([
            [sq2, p2.y, p2.z],
            [sq3, p3.y, p3.z],
            [sq4, p4.y, p4.z]
        ])

        let dy = -(det3([
            [sq1, p1.x, p1.z],
            [sq2, p2.x, p2.z],
            [sq3, p3.x, p3.z]
        ]) - det3([
            [sq1, p1.x, p1.z],
            [sq2, p2.x, p2.z],
            [sq4, p4.x, p4.z]
        ]) + det3([
            [sq1, p1.x, p1.z],
            [sq3, p3.x, p3.z],
            [sq4, p4.x, p4.z]
        ]) - det3([
            [sq2, p2.x, p2.z],
            [sq3, p3.x, p3.z],
            [sq4, p4.x, p4.z]
        ]))

        let dz = det3([
            [sq1, p1.x, p1.y],
            [sq2, p2.x, p2.y],
            [sq3, p3.x, p3.y]
        ]) - det3([
            [sq1, p1.x, p1.y],
            [sq2, p2.x, p2.y],
            [sq4, p4.x, p4.y]
        ]) + det3([
            [sq1, p1.x, p1.y],
            [sq3, p3.x, p3.y],
            [sq4, p4.x, p4.y]
        ]) - det3([
            [sq2, p2.x, p2.y],
            [sq3, p3.x, p3.y],
            [sq4, p4.x, p4.y]
        ])

        let center = simd_double3(dx / (2 * det), dy / (2 * det), dz / (2 * det))
        let radius = simd_distance(center, p1)

        return .table([
            "center": vec3ToLua(center),
            "radius": .number(radius)
        ])
    }

    // MARK: - Coordinate Conversion Callbacks

    /// Convert vec2 (x, y) to polar (r, theta)
    private static let vec2ToPolarCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec2(args[0]) else { return .nil }
        let r = simd_length(v)
        let theta = atan2(v.y, v.x)
        return .table(["r": .number(r), "theta": .number(theta)])
    }

    /// Create vec2 from polar (r, theta)
    private static let vec2FromPolarCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let r = args[0].numberValue,
              let theta = args[1].numberValue else { return .nil }
        let x = r * cos(theta)
        let y = r * sin(theta)
        return vec2ToLua(simd_double2(x, y))
    }

    /// Convert vec3 (x, y, z) to spherical (r, theta, phi)
    /// theta = azimuthal angle (from x-axis in xy-plane)
    /// phi = polar angle (from z-axis)
    private static let vec3ToSphericalCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec3(args[0]) else { return .nil }
        let r = simd_length(v)
        let theta = atan2(v.y, v.x)
        let phi = r > 0 ? acos(v.z / r) : 0
        return .table(["r": .number(r), "theta": .number(theta), "phi": .number(phi)])
    }

    /// Create vec3 from spherical (r, theta, phi)
    private static let vec3FromSphericalCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let r = args[0].numberValue,
              let theta = args[1].numberValue,
              let phi = args[2].numberValue else { return .nil }
        let x = r * sin(phi) * cos(theta)
        let y = r * sin(phi) * sin(theta)
        let z = r * cos(phi)
        return vec3ToLua(simd_double3(x, y, z))
    }

    /// Convert vec3 (x, y, z) to cylindrical (rho, theta, z)
    /// rho = radial distance in xy-plane
    /// theta = azimuthal angle (from x-axis)
    private static let vec3ToCylindricalCallback: ([LuaValue]) -> LuaValue = { args in
        guard let v = extractVec3(args[0]) else { return .nil }
        let rho = sqrt(v.x * v.x + v.y * v.y)
        let theta = atan2(v.y, v.x)
        return .table(["rho": .number(rho), "theta": .number(theta), "z": .number(v.z)])
    }

    /// Create vec3 from cylindrical (rho, theta, z)
    private static let vec3FromCylindricalCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 3,
              let rho = args[0].numberValue,
              let theta = args[1].numberValue,
              let z = args[2].numberValue else { return .nil }
        let x = rho * cos(theta)
        let y = rho * sin(theta)
        return vec3ToLua(simd_double3(x, y, z))
    }

    // MARK: - Lua Wrapper Code

    private static let geometryLuaWrapper = """
    -- Create luaswift.geometry namespace
    if not luaswift then luaswift = {} end
    luaswift.geometry = {}
    local geo = luaswift.geometry

    -- Store references to Swift functions
    local _vec2_create = _luaswift_geo_vec2_create
    local _vec2_length = _luaswift_geo_vec2_length
    local _vec2_length_squared = _luaswift_geo_vec2_length_squared
    local _vec2_normalize = _luaswift_geo_vec2_normalize
    local _vec2_dot = _luaswift_geo_vec2_dot
    local _vec2_cross = _luaswift_geo_vec2_cross
    local _vec2_angle = _luaswift_geo_vec2_angle
    local _vec2_rotate = _luaswift_geo_vec2_rotate
    local _vec2_lerp = _luaswift_geo_vec2_lerp
    local _vec2_add = _luaswift_geo_vec2_add
    local _vec2_sub = _luaswift_geo_vec2_sub
    local _vec2_mul = _luaswift_geo_vec2_mul
    local _vec2_div = _luaswift_geo_vec2_div
    local _vec2_neg = _luaswift_geo_vec2_neg
    local _vec2_project = _luaswift_geo_vec2_project
    local _vec2_reflect = _luaswift_geo_vec2_reflect
    local _vec2_perpendicular = _luaswift_geo_vec2_perpendicular

    local _vec3_create = _luaswift_geo_vec3_create
    local _vec3_length = _luaswift_geo_vec3_length
    local _vec3_length_squared = _luaswift_geo_vec3_length_squared
    local _vec3_normalize = _luaswift_geo_vec3_normalize
    local _vec3_dot = _luaswift_geo_vec3_dot
    local _vec3_cross = _luaswift_geo_vec3_cross
    local _vec3_rotate = _luaswift_geo_vec3_rotate
    local _vec3_lerp = _luaswift_geo_vec3_lerp
    local _vec3_add = _luaswift_geo_vec3_add
    local _vec3_sub = _luaswift_geo_vec3_sub
    local _vec3_mul = _luaswift_geo_vec3_mul
    local _vec3_div = _luaswift_geo_vec3_div
    local _vec3_neg = _luaswift_geo_vec3_neg
    local _vec3_project = _luaswift_geo_vec3_project
    local _vec3_reflect = _luaswift_geo_vec3_reflect

    local _quat_create = _luaswift_geo_quat_create
    local _quat_identity = _luaswift_geo_quat_identity
    local _quat_from_euler = _luaswift_geo_quat_from_euler
    local _quat_from_axis_angle = _luaswift_geo_quat_from_axis_angle
    local _quat_normalize = _luaswift_geo_quat_normalize
    local _quat_conjugate = _luaswift_geo_quat_conjugate
    local _quat_inverse = _luaswift_geo_quat_inverse
    local _quat_mul = _luaswift_geo_quat_mul
    local _quat_rotate = _luaswift_geo_quat_rotate
    local _quat_slerp = _luaswift_geo_quat_slerp
    local _quat_to_euler = _luaswift_geo_quat_to_euler
    local _quat_to_axis_angle = _luaswift_geo_quat_to_axis_angle
    local _quat_to_matrix = _luaswift_geo_quat_to_matrix
    local _quat_dot = _luaswift_geo_quat_dot
    local _quat_length = _luaswift_geo_quat_length

    local _mat4_identity = _luaswift_geo_mat4_identity
    local _mat4_translate = _luaswift_geo_mat4_translate
    local _mat4_rotate_x = _luaswift_geo_mat4_rotate_x
    local _mat4_rotate_y = _luaswift_geo_mat4_rotate_y
    local _mat4_rotate_z = _luaswift_geo_mat4_rotate_z
    local _mat4_rotate_axis = _luaswift_geo_mat4_rotate_axis
    local _mat4_scale = _luaswift_geo_mat4_scale
    local _mat4_multiply = _luaswift_geo_mat4_multiply
    local _mat4_apply = _luaswift_geo_mat4_apply

    local _distance = _luaswift_geo_distance
    local _angle_between = _luaswift_geo_angle_between
    local _convex_hull = _luaswift_geo_convex_hull
    local _in_polygon = _luaswift_geo_in_polygon
    local _line_intersection = _luaswift_geo_line_intersection
    local _area_triangle = _luaswift_geo_area_triangle
    local _centroid = _luaswift_geo_centroid
    local _circle_from_3_points = _luaswift_geo_circle_from_3_points
    local _plane_from_3_points = _luaswift_geo_plane_from_3_points
    local _point_plane_distance = _luaswift_geo_point_plane_distance
    local _line_plane_intersection = _luaswift_geo_line_plane_intersection
    local _plane_plane_intersection = _luaswift_geo_plane_plane_intersection
    local _intersection = _luaswift_geo_intersection
    local _sphere_from_4_points = _luaswift_geo_sphere_from_4_points

    local _vec2_to_polar = _luaswift_geo_vec2_to_polar
    local _vec2_from_polar = _luaswift_geo_vec2_from_polar
    local _vec3_to_spherical = _luaswift_geo_vec3_to_spherical
    local _vec3_from_spherical = _luaswift_geo_vec3_from_spherical
    local _vec3_to_cylindrical = _luaswift_geo_vec3_to_cylindrical
    local _vec3_from_cylindrical = _luaswift_geo_vec3_from_cylindrical

    -- Vec2 type
    local vec2_mt = {
        __add = function(a, b) return geo.vec2(_vec2_add(a, b).x, _vec2_add(a, b).y) end,
        __sub = function(a, b) return geo.vec2(_vec2_sub(a, b).x, _vec2_sub(a, b).y) end,
        __mul = function(a, b)
            if type(b) == "number" then
                local r = _vec2_mul(a, b)
                return geo.vec2(r.x, r.y)
            else
                local r = _vec2_mul(b, a)
                return geo.vec2(r.x, r.y)
            end
        end,
        __div = function(a, b)
            local r = _vec2_div(a, b)
            return geo.vec2(r.x, r.y)
        end,
        __unm = function(a)
            local r = _vec2_neg(a)
            return geo.vec2(r.x, r.y)
        end,
        __eq = function(a, b)
            return a.x == b.x and a.y == b.y
        end,
        __tostring = function(a)
            return string.format("vec2(%.4f, %.4f)", a.x, a.y)
        end,
        __index = {
            length = function(self) return _vec2_length(self) end,
            lengthSquared = function(self) return _vec2_length_squared(self) end,
            normalize = function(self)
                local r = _vec2_normalize(self)
                return geo.vec2(r.x, r.y)
            end,
            dot = function(self, other) return _vec2_dot(self, other) end,
            cross = function(self, other) return _vec2_cross(self, other) end,
            angle = function(self) return _vec2_angle(self) end,
            rotate = function(self, theta)
                local r = _vec2_rotate(self, theta)
                return geo.vec2(r.x, r.y)
            end,
            lerp = function(self, other, t)
                local r = _vec2_lerp(self, other, t)
                return geo.vec2(r.x, r.y)
            end,
            project = function(self, onto)
                local r = _vec2_project(self, onto)
                return geo.vec2(r.x, r.y)
            end,
            reflect = function(self, normal)
                local r = _vec2_reflect(self, normal)
                return geo.vec2(r.x, r.y)
            end,
            perpendicular = function(self)
                local r = _vec2_perpendicular(self)
                return geo.vec2(r.x, r.y)
            end,
            to_polar = function(self)
                return _vec2_to_polar(self)
            end,
            clone = function(self) return geo.vec2(self.x, self.y) end,
            -- Sugar methods for common operations
            distance = function(self, other) return _distance(self, other) end,
            angle_to = function(self, other) return _angle_between(self, other) end,
            in_polygon = function(self, polygon) return _in_polygon(self, polygon) end
        }
    }

    function geo.vec2(x, y)
        local v = {x = x, y = y, __luaswift_type = "vec2"}
        setmetatable(v, vec2_mt)
        return v
    end

    -- Vec3 type
    local vec3_mt = {
        __add = function(a, b) return geo.vec3(_vec3_add(a, b).x, _vec3_add(a, b).y, _vec3_add(a, b).z) end,
        __sub = function(a, b) return geo.vec3(_vec3_sub(a, b).x, _vec3_sub(a, b).y, _vec3_sub(a, b).z) end,
        __mul = function(a, b)
            if type(b) == "number" then
                local r = _vec3_mul(a, b)
                return geo.vec3(r.x, r.y, r.z)
            else
                local r = _vec3_mul(b, a)
                return geo.vec3(r.x, r.y, r.z)
            end
        end,
        __div = function(a, b)
            local r = _vec3_div(a, b)
            return geo.vec3(r.x, r.y, r.z)
        end,
        __unm = function(a)
            local r = _vec3_neg(a)
            return geo.vec3(r.x, r.y, r.z)
        end,
        __eq = function(a, b)
            return a.x == b.x and a.y == b.y and a.z == b.z
        end,
        __tostring = function(a)
            return string.format("vec3(%.4f, %.4f, %.4f)", a.x, a.y, a.z)
        end,
        __index = {
            length = function(self) return _vec3_length(self) end,
            lengthSquared = function(self) return _vec3_length_squared(self) end,
            normalize = function(self)
                local r = _vec3_normalize(self)
                return geo.vec3(r.x, r.y, r.z)
            end,
            dot = function(self, other) return _vec3_dot(self, other) end,
            cross = function(self, other)
                local r = _vec3_cross(self, other)
                return geo.vec3(r.x, r.y, r.z)
            end,
            rotate = function(self, axis, angle)
                local r = _vec3_rotate(self, axis, angle)
                return geo.vec3(r.x, r.y, r.z)
            end,
            lerp = function(self, other, t)
                local r = _vec3_lerp(self, other, t)
                return geo.vec3(r.x, r.y, r.z)
            end,
            project = function(self, onto)
                local r = _vec3_project(self, onto)
                return geo.vec3(r.x, r.y, r.z)
            end,
            reflect = function(self, normal)
                local r = _vec3_reflect(self, normal)
                return geo.vec3(r.x, r.y, r.z)
            end,
            to_spherical = function(self)
                return _vec3_to_spherical(self)
            end,
            to_cylindrical = function(self)
                return _vec3_to_cylindrical(self)
            end,
            clone = function(self) return geo.vec3(self.x, self.y, self.z) end,
            -- Sugar methods for common operations
            distance = function(self, other) return _distance(self, other) end,
            angle_to = function(self, other) return _angle_between(self, other) end
        }
    }

    function geo.vec3(x, y, z)
        local v = {x = x, y = y, z = z, __luaswift_type = "vec3"}
        setmetatable(v, vec3_mt)
        return v
    end

    -- Circle type with chainable transformations
    local circle_mt = {
        __eq = function(a, b)
            return a.center.x == b.center.x and a.center.y == b.center.y and a.radius == b.radius
        end,
        __tostring = function(a)
            return string.format("circle(center=vec2(%.4f, %.4f), radius=%.4f)", a.center.x, a.center.y, a.radius)
        end,
        __index = {
            -- Chainable transformations
            translate = function(self, dx, dy)
                return geo.circle(self.center.x + dx, self.center.y + dy, self.radius)
            end,
            scale = function(self, factor)
                return geo.circle(self.center.x, self.center.y, self.radius * factor)
            end,
            scale_from = function(self, factor, origin)
                -- Scale from a specific origin point
                local ox = origin and origin.x or 0
                local oy = origin and origin.y or 0
                local newX = ox + (self.center.x - ox) * factor
                local newY = oy + (self.center.y - oy) * factor
                return geo.circle(newX, newY, self.radius * factor)
            end,
            -- Queries
            contains = function(self, point)
                local dx = point.x - self.center.x
                local dy = point.y - self.center.y
                return (dx * dx + dy * dy) <= (self.radius * self.radius)
            end,
            area = function(self)
                return math.pi * self.radius * self.radius
            end,
            circumference = function(self)
                return 2 * math.pi * self.radius
            end,
            diameter = function(self)
                return 2 * self.radius
            end,
            -- Point generation
            point_at = function(self, angle)
                -- Returns point on circle at given angle (radians from positive x-axis)
                local x = self.center.x + self.radius * math.cos(angle)
                local y = self.center.y + self.radius * math.sin(angle)
                return geo.vec2(x, y)
            end,
            -- Bounding box
            bounds = function(self)
                return {
                    min = geo.vec2(self.center.x - self.radius, self.center.y - self.radius),
                    max = geo.vec2(self.center.x + self.radius, self.center.y + self.radius)
                }
            end,
            -- Clone
            clone = function(self)
                return geo.circle(self.center.x, self.center.y, self.radius)
            end
        }
    }

    -- Circle constructor: geo.circle(center, radius) or geo.circle(x, y, radius)
    function geo.circle(a, b, c)
        local center, radius
        if type(a) == "table" and a.x ~= nil and a.y ~= nil then
            -- geo.circle(center_vec2, radius)
            center = geo.vec2(a.x, a.y)
            radius = b
        elseif type(a) == "number" and type(b) == "number" and type(c) == "number" then
            -- geo.circle(x, y, radius)
            center = geo.vec2(a, b)
            radius = c
        else
            return nil
        end
        local circle = {
            center = center,
            radius = radius,
            __luaswift_type = "circle"
        }
        setmetatable(circle, circle_mt)
        return circle
    end

    -- Quaternion type
    local quat_mt = {
        __mul = function(a, b)
            if type(b) == "table" and b.w ~= nil then
                local r = _quat_mul(a, b)
                return geo.quaternion(r.w, r.x, r.y, r.z)
            else
                return nil
            end
        end,
        __eq = function(a, b)
            return a.w == b.w and a.x == b.x and a.y == b.y and a.z == b.z
        end,
        __tostring = function(a)
            return string.format("quaternion(%.4f, %.4f, %.4f, %.4f)", a.w, a.x, a.y, a.z)
        end,
        __index = {
            normalize = function(self)
                local r = _quat_normalize(self)
                return geo.quaternion(r.w, r.x, r.y, r.z)
            end,
            conjugate = function(self)
                local r = _quat_conjugate(self)
                return geo.quaternion(r.w, r.x, r.y, r.z)
            end,
            inverse = function(self)
                local r = _quat_inverse(self)
                return geo.quaternion(r.w, r.x, r.y, r.z)
            end,
            rotate = function(self, v)
                local r = _quat_rotate(self, v)
                return geo.vec3(r.x, r.y, r.z)
            end,
            slerp = function(self, other, t)
                local r = _quat_slerp(self, other, t)
                return geo.quaternion(r.w, r.x, r.y, r.z)
            end,
            to_euler = function(self)
                return _quat_to_euler(self)
            end,
            to_axis_angle = function(self)
                return _quat_to_axis_angle(self)
            end,
            to_matrix = function(self)
                return _quat_to_matrix(self)
            end,
            dot = function(self, other)
                return _quat_dot(self, other)
            end,
            length = function(self)
                return _quat_length(self)
            end,
            clone = function(self) return geo.quaternion(self.w, self.x, self.y, self.z) end,
            -- Sugar method for distance
            distance = function(self, other) return _distance(self, other) end
        }
    }

    local function make_quaternion(w, x, y, z)
        local q = {w = w, x = x, y = y, z = z, __luaswift_type = "quaternion"}
        setmetatable(q, quat_mt)
        return q
    end

    -- Create quaternion as a callable table with static methods
    geo.quaternion = setmetatable({
        identity = function()
            local r = _quat_identity()
            return make_quaternion(r.w, r.x, r.y, r.z)
        end,
        from_euler = function(yaw, pitch, roll)
            local r = _quat_from_euler(yaw, pitch, roll)
            return make_quaternion(r.w, r.x, r.y, r.z)
        end,
        from_axis_angle = function(axis, angle)
            local r = _quat_from_axis_angle(axis, angle)
            return make_quaternion(r.w, r.x, r.y, r.z)
        end
    }, {
        __call = function(_, w, x, y, z)
            return make_quaternion(w, x, y, z)
        end
    })

    -- Transform3D (4x4 matrix) type
    local transform3d_mt = {
        __mul = function(a, b)
            if type(b) == "table" and b._type == "transform3d" then
                local r = _mat4_multiply(a._m, b._m)
                return geo.transform3d(r)
            else
                return nil
            end
        end,
        __tostring = function(a)
            return "transform3d"
        end,
        __index = {
            translate = function(self, dx, dy, dz)
                local r = _mat4_translate(self._m, dx, dy, dz)
                return geo.transform3d(r)
            end,
            rotate_x = function(self, angle)
                local r = _mat4_rotate_x(self._m, angle)
                return geo.transform3d(r)
            end,
            rotate_y = function(self, angle)
                local r = _mat4_rotate_y(self._m, angle)
                return geo.transform3d(r)
            end,
            rotate_z = function(self, angle)
                local r = _mat4_rotate_z(self._m, angle)
                return geo.transform3d(r)
            end,
            rotate_axis = function(self, axis, angle)
                local r = _mat4_rotate_axis(self._m, axis, angle)
                return geo.transform3d(r)
            end,
            scale = function(self, sx, sy, sz)
                local r = _mat4_scale(self._m, sx, sy, sz)
                return geo.transform3d(r)
            end,
            apply = function(self, v)
                local r = _mat4_apply(self._m, v)
                return geo.vec3(r.x, r.y, r.z)
            end,
            clone = function(self) return geo.transform3d(self._m) end
        }
    }

    function geo.transform3d(matrix)
        local t = {_m = matrix or _mat4_identity(), _type = "transform3d", __luaswift_type = "transform3d"}
        setmetatable(t, transform3d_mt)
        return t
    end

    -- Expose Swift-optimized functions with proper wrapping
    geo.distance = function(v1, v2)
        return _distance(v1, v2)
    end

    -- Angle between two vectors (implicit origin translation)
    -- For 2D: returns signed angle using atan2
    -- For 3D: returns unsigned angle using acos(dot/lengths)
    geo.angle_between = function(v1, v2)
        return _angle_between(v1, v2)
    end

    geo.convex_hull = function(points)
        local result = _convex_hull(points)
        if result then
            local wrapped = {}
            for i, p in ipairs(result) do
                wrapped[i] = geo.vec2(p.x, p.y)
            end
            return wrapped
        end
        return nil
    end

    geo.in_polygon = function(point, polygon)
        return _in_polygon(point, polygon)
    end
    -- Backward compatibility alias
    geo.point_in_polygon = geo.in_polygon

    geo.line_intersection = function(line1, line2)
        local r = _line_intersection(line1, line2)
        if r then
            return geo.vec2(r.x, r.y)
        end
        return nil
    end

    geo.area_triangle = function(p1, p2, p3)
        return _area_triangle(p1, p2, p3)
    end

    geo.centroid = function(points)
        local r = _centroid(points)
        if r then
            if r.z then
                return geo.vec3(r.x, r.y, r.z)
            else
                return geo.vec2(r.x, r.y)
            end
        end
        return nil
    end

    geo.circle_from_3_points = function(p1, p2, p3)
        local r = _circle_from_3_points(p1, p2, p3)
        if r then
            return geo.circle(r.center.x, r.center.y, r.radius)
        end
        return nil
    end

    geo.plane_from_3_points = function(p1, p2, p3)
        local r = _plane_from_3_points(p1, p2, p3)
        if r then
            return {
                normal = geo.vec3(r.normal.x, r.normal.y, r.normal.z),
                d = r.d
            }
        end
        return nil
    end

    geo.point_plane_distance = function(point, plane)
        return _point_plane_distance(point, plane)
    end

    geo.line_plane_intersection = function(line, plane)
        local r = _line_plane_intersection(line, plane)
        if r then
            return geo.vec3(r.x, r.y, r.z)
        end
        return nil
    end

    geo.plane_plane_intersection = function(plane1, plane2)
        local r = _plane_plane_intersection(plane1, plane2)
        if r then
            return {
                origin = geo.vec3(r.origin.x, r.origin.y, r.origin.z),
                direction = geo.vec3(r.direction.x, r.direction.y, r.direction.z)
            }
        end
        return nil
    end

    -- Polymorphic intersection: auto-detects line-line, line-plane, or plane-plane
    geo.intersection = function(a, b)
        local r = _intersection(a, b)
        if r == nil then return nil end

        -- Check if result is a vec2 (line-line intersection)
        if r.x ~= nil and r.y ~= nil and r.z == nil then
            return geo.vec2(r.x, r.y)
        end

        -- Check if result is a vec3 (line-plane intersection)
        if r.x ~= nil and r.y ~= nil and r.z ~= nil then
            return geo.vec3(r.x, r.y, r.z)
        end

        -- Check if result is a line (plane-plane intersection)
        if r.origin ~= nil and r.direction ~= nil then
            return {
                origin = geo.vec3(r.origin.x, r.origin.y, r.origin.z),
                direction = geo.vec3(r.direction.x, r.direction.y, r.direction.z)
            }
        end

        return r
    end

    geo.sphere_from_4_points = function(p1, p2, p3, p4)
        local r = _sphere_from_4_points(p1, p2, p3, p4)
        if r then
            return {
                center = geo.vec3(r.center.x, r.center.y, r.center.z),
                radius = r.radius
            }
        end
        return nil
    end

    -- Coordinate conversion factory functions
    geo.from_polar = function(r, theta)
        local v = _vec2_from_polar(r, theta)
        if v then
            return geo.vec2(v.x, v.y)
        end
        return nil
    end

    geo.from_spherical = function(r, theta, phi)
        local v = _vec3_from_spherical(r, theta, phi)
        if v then
            return geo.vec3(v.x, v.y, v.z)
        end
        return nil
    end

    geo.from_cylindrical = function(rho, theta, z)
        local v = _vec3_from_cylindrical(rho, theta, z)
        if v then
            return geo.vec3(v.x, v.y, v.z)
        end
        return nil
    end

    -- Aliases for coordinate conversions (for backward compatibility with mathx)
    geo.polar_to_cart = function(r, theta)
        local v = _vec2_from_polar(r, theta)
        if v then
            return v.x, v.y
        end
        return nil
    end

    geo.cart_to_polar = function(x, y)
        local p = _vec2_to_polar({x = x, y = y})
        if p then
            return p.r, p.theta
        end
        return nil
    end

    geo.spherical_to_cart = function(r, theta, phi)
        local v = _vec3_from_spherical(r, theta, phi)
        if v then
            return v.x, v.y, v.z
        end
        return nil
    end

    geo.cart_to_spherical = function(x, y, z)
        local s = _vec3_to_spherical({x = x, y = y, z = z})
        if s then
            return s.r, s.theta, s.phi
        end
        return nil
    end

    -- Make available via require
    package.loaded["luaswift.geometry"] = geo
    """
}
