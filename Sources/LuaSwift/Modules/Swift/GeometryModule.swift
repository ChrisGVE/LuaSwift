//
//  GeometryModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
import Foundation
import Accelerate
import simd
import NumericSwift

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

        // Curve fitting operations
        engine.registerFunction(name: "_luaswift_geo_cubic_spline_coeffs", callback: cubicSplineCoeffsCallback)
        engine.registerFunction(name: "_luaswift_geo_bspline_evaluate", callback: bsplineEvaluateCallback)
        engine.registerFunction(name: "_luaswift_geo_bspline_basis", callback: bsplineBasisCallback)
        engine.registerFunction(name: "_luaswift_geo_bspline_uniform_knots", callback: bsplineUniformKnotsCallback)
        engine.registerFunction(name: "_luaswift_geo_bspline_derivative", callback: bsplineDerivativeCallback)
        engine.registerFunction(name: "_luaswift_geo_circle_fit_algebraic", callback: circleFitAlgebraicCallback)
        engine.registerFunction(name: "_luaswift_geo_circle_fit_taubin", callback: circleFitTaubinCallback)
        engine.registerFunction(name: "_luaswift_geo_ellipse_fit_direct", callback: ellipseFitDirectCallback)
        engine.registerFunction(name: "_luaswift_geo_sphere_fit_algebraic", callback: sphereFitAlgebraicCallback)
        engine.registerFunction(name: "_luaswift_geo_bspline_fit", callback: bsplineFitCallback)

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
        let sinr_cosp: Double = 2.0 * (q.real * q.imag.x + q.imag.y * q.imag.z)
        let cosr_cosp: Double = 1.0 - 2.0 * (q.imag.x * q.imag.x + q.imag.y * q.imag.y)
        let roll = atan2(sinr_cosp, cosr_cosp)

        let sinp: Double = 2.0 * (q.real * q.imag.y - q.imag.z * q.imag.x)
        let pitch: Double
        if abs(sinp) >= 1 {
            pitch = copysign(Double.pi / 2, sinp)
        } else {
            pitch = asin(sinp)
        }

        let siny_cosp: Double = 2.0 * (q.real * q.imag.z + q.imag.x * q.imag.y)
        let cosy_cosp: Double = 1.0 - 2.0 * (q.imag.y * q.imag.y + q.imag.z * q.imag.z)
        let yaw = atan2(siny_cosp, cosy_cosp)

        return .array([.number(yaw), .number(pitch), .number(roll)])
    }

    private static let quatToAxisAngleCallback: ([LuaValue]) -> LuaValue = { args in
        guard let q = extractQuat(args[0]) else { return .nil }
        let angle: Double = 2.0 * acos(q.real)
        let s: Double = sqrt(1.0 - q.real * q.real)
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

    /// Compute convex hull of 2D points via NumericSwift
    private static let convexHullCallback: ([LuaValue]) -> LuaValue = { args in
        guard let arr = args[0].arrayValue else { return .nil }

        // Extract points
        var points: [Vec2] = []
        for p in arr {
            if let v = extractVec2(p) {
                points.append(v)
            }
        }

        guard points.count >= 3 else {
            return .array(arr)
        }

        // Use NumericSwift's Graham scan implementation
        let hull = convexHull2D(points)
        return .array(hull.map { vec2ToLua($0) })
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

        let d: Double = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
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

    // MARK: - Curve Fitting Callbacks

    /// Compute cubic spline coefficients via NumericSwift
    /// Input: either array of {x, y} points OR two arrays (xs, ys)
    /// Output: {knots, values, coeffs} where coeffs[i] = {a, b, c, d} for each segment
    private static let cubicSplineCoeffsCallback: ([LuaValue]) throws -> LuaValue = { args in
        var points: [(x: Double, y: Double)] = []

        // Check if we have two array arguments (xs, ys format)
        if args.count >= 2,
           let xsArray = args[0].arrayValue,
           let ysArray = args[1].arrayValue {
            let count = min(xsArray.count, ysArray.count)
            for i in 0..<count {
                if let x = xsArray[i].numberValue,
                   let y = ysArray[i].numberValue {
                    points.append((x, y))
                }
            }
        } else if let pointsArray = args.first?.arrayValue {
            for pt in pointsArray {
                guard let table = pt.tableValue else { continue }
                let x = table["x"]?.numberValue ?? table["1"]?.numberValue
                let y = table["y"]?.numberValue ?? table["2"]?.numberValue
                if let x = x, let y = y {
                    points.append((x, y))
                }
            }
        } else {
            throw LuaError.callbackError("cubic_spline requires array of points or two arrays (xs, ys)")
        }

        guard points.count >= 2 else {
            throw LuaError.callbackError("cubic_spline requires at least 2 points")
        }

        // Use NumericSwift's cubic spline implementation
        guard let result = cubicSplineCoeffs(points: points) else {
            throw LuaError.callbackError("cubic_spline: computation failed")
        }

        let coeffsArray: [LuaValue] = result.coeffs.map { seg in
            .table(["a": .number(seg.a), "b": .number(seg.b), "c": .number(seg.c), "d": .number(seg.d)])
        }

        return .table([
            "knots": .array(result.knots.map { .number($0) }),
            "values": .array(result.values.map { .number($0) }),
            "coeffs": .array(coeffsArray)
        ])
    }

    /// Evaluate B-spline curve via NumericSwift
    private static let bsplineEvaluateCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 4,
              let controlPointsArray = args[0].arrayValue,
              let degree = args[1].numberValue.map({ Int($0) }),
              let knotsArray = args[2].arrayValue,
              let t = args[3].numberValue else {
            throw LuaError.callbackError("bspline_evaluate requires (control_points, degree, knots, t)")
        }

        let knots = knotsArray.compactMap { $0.numberValue }

        // Check if 3D by looking for z coordinate
        var is3D = false
        for pt in controlPointsArray {
            if let table = pt.tableValue,
               table["z"]?.numberValue != nil || table["3"]?.numberValue != nil {
                is3D = true
                break
            }
        }

        if is3D {
            var points3D: [Vec3] = []
            for pt in controlPointsArray {
                if let v = extractVec3(pt) {
                    points3D.append(v)
                }
            }
            let result = bsplineEvaluate3D(controlPoints: points3D, degree: degree, t: t, knots: knots)
            return vec3ToLua(result)
        } else {
            var points2D: [Vec2] = []
            for pt in controlPointsArray {
                if let v = extractVec2(pt) {
                    points2D.append(v)
                }
            }
            let result = bsplineEvaluate(controlPoints: points2D, degree: degree, t: t, knots: knots)
            return vec2ToLua(result)
        }
    }

    /// Compute B-spline basis function N_{i,p}(t) via NumericSwift
    private static let bsplineBasisCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 4,
              let knotsArray = args[0].arrayValue,
              let i = args[1].numberValue.map({ Int($0) - 1 }),  // Convert to 0-indexed
              let p = args[2].numberValue.map({ Int($0) }),
              let t = args[3].numberValue else {
            throw LuaError.callbackError("bspline_basis requires (knots, i, p, t)")
        }

        let knots = knotsArray.compactMap { $0.numberValue }
        guard knots.count >= 2 else {
            return .number(0.0)
        }

        return .number(bsplineBasis(i: i, degree: p, t: t, knots: knots))
    }

    /// Generate uniform knot vector for B-spline via NumericSwift
    private static let bsplineUniformKnotsCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let n = args[0].numberValue.map({ Int($0) }),
              let p = args[1].numberValue.map({ Int($0) }) else {
            throw LuaError.callbackError("bspline_uniform_knots requires (n, p)")
        }

        let knots = bsplineUniformKnots(n: n, degree: p)
        return .array(knots.map { .number($0) })
    }

    /// Evaluate B-spline derivative via NumericSwift
    private static let bsplineDerivativeCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 4,
              let controlPointsArray = args[0].arrayValue,
              let degree = args[1].numberValue.map({ Int($0) }),
              let knotsArray = args[2].arrayValue,
              let t = args[3].numberValue else {
            throw LuaError.callbackError("bspline_derivative requires (control_points, degree, knots, t)")
        }

        let order = args.count > 4 ? Int(args[4].numberValue ?? 1) : 1
        let knots = knotsArray.compactMap { $0.numberValue }

        // Check if 3D by looking for z coordinate
        var is3D = false
        for pt in controlPointsArray {
            if let table = pt.tableValue,
               table["z"]?.numberValue != nil || table["3"]?.numberValue != nil {
                is3D = true
                break
            }
        }

        if is3D {
            var points3D: [Vec3] = []
            for pt in controlPointsArray {
                if let v = extractVec3(pt) {
                    points3D.append(v)
                }
            }
            let result = bsplineDerivativeOrder3D(controlPoints: points3D, degree: degree, t: t, knots: knots, order: order)
            return vec3ToLua(result)
        } else {
            var points2D: [Vec2] = []
            for pt in controlPointsArray {
                if let v = extractVec2(pt) {
                    points2D.append(v)
                }
            }
            let result = bsplineDerivativeOrder(controlPoints: points2D, degree: degree, t: t, knots: knots, order: order)
            return vec2ToLua(result)
        }
    }

    // MARK: - Circle Fitting Callbacks

    /// Fit circle to points using algebraic (Kåsa) method
    /// Minimizes Σ(x² + y² + Dx + Ey + F)² - a linear least squares problem
    /// Input: array of points [{x, y}, ...]
    /// Output: {cx, cy, r, residuals, method}
    private static let circleFitAlgebraicCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let pointsArray = args.first?.arrayValue else {
            throw LuaError.callbackError("circle_fit requires array of points")
        }

        // Extract points as Vec2
        var points: [Vec2] = []
        for pt in pointsArray {
            if let v = extractVec2(pt) {
                points.append(v)
            }
        }

        guard points.count >= 3 else {
            throw LuaError.callbackError("circle_fit requires at least 3 points")
        }

        // Use NumericSwift's circle fit
        guard let result = circleFitAlgebraic(points) else {
            return .nil
        }

        // Compute RMSE from residuals
        let n = Double(result.residuals.count)
        let sumResidualsSq = result.residuals.reduce(0.0) { $0 + $1 * $1 }
        let rmse = sqrt(sumResidualsSq / n)

        return .table([
            "cx": .number(result.center.x),
            "cy": .number(result.center.y),
            "r": .number(result.radius),
            "residuals": .array(result.residuals.map { .number($0) }),
            "rmse": .number(rmse),
            "method": .string("algebraic")
        ])
    }

    /// Fit circle using Taubin's method (modified algebraic with normalization)
    /// More accurate than Kåsa for noisy data
    private static let circleFitTaubinCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let pointsArray = args.first?.arrayValue else {
            throw LuaError.callbackError("circle_fit requires array of points")
        }

        // Extract points as Vec2
        var points: [Vec2] = []
        for pt in pointsArray {
            if let v = extractVec2(pt) {
                points.append(v)
            }
        }

        guard points.count >= 3 else {
            throw LuaError.callbackError("circle_fit requires at least 3 points")
        }

        // Use NumericSwift's Taubin circle fit
        guard let result = circleFitTaubin(points) else {
            return .nil
        }

        // Compute RMSE from residuals
        let n = Double(result.residuals.count)
        let sumResidualsSq = result.residuals.reduce(0.0) { $0 + $1 * $1 }
        let rmse = sqrt(sumResidualsSq / n)

        return .table([
            "cx": .number(result.center.x),
            "cy": .number(result.center.y),
            "r": .number(result.radius),
            "residuals": .array(result.residuals.map { .number($0) }),
            "rmse": .number(rmse),
            "method": .string("taubin")
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

    // MARK: - Ellipse Fitting Callbacks

    /// Fit ellipse using Fitzgibbon's direct least squares method via NumericSwift
    private static let ellipseFitDirectCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let pointsArray = args.first?.arrayValue else {
            throw LuaError.callbackError("ellipse_fit requires array of points")
        }

        // Extract points as Vec2
        var points: [Vec2] = []
        for pt in pointsArray {
            if let v = extractVec2(pt) {
                points.append(v)
            }
        }

        guard points.count >= 5 else {
            throw LuaError.callbackError("ellipse_fit requires at least 5 points")
        }

        // Use NumericSwift's ellipse fit implementation
        guard let result = ellipseFitDirect(points: points) else {
            return .nil
        }

        return .table([
            "cx": .number(result.cx),
            "cy": .number(result.cy),
            "a": .number(result.a),
            "b": .number(result.b),
            "theta": .number(result.theta),
            "conic": .array(result.conic.map { .number($0) }),
            "residuals": .array(result.residuals.map { .number($0) }),
            "rmse": .number(result.rmse),
            "method": .string("direct")
        ])
    }

    // MARK: - Sphere Fitting Callbacks

    /// Fit sphere to 3D points using algebraic least squares via NumericSwift
    private static let sphereFitAlgebraicCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let pointsArray = args.first?.arrayValue else {
            throw LuaError.callbackError("sphere_fit requires array of 3D points")
        }

        // Extract points as Vec3
        var points: [Vec3] = []
        for pt in pointsArray {
            if let v = extractVec3(pt) {
                points.append(v)
            }
        }

        guard points.count >= 4 else {
            return .nil // Need at least 4 points
        }

        // Use NumericSwift's sphere fit implementation
        guard let result = sphereFitAlgebraic(points) else {
            return .nil
        }

        // Compute RMSE and max error from residuals
        let n = Double(result.residuals.count)
        let sumResidualsSq = result.residuals.reduce(0.0) { $0 + $1 * $1 }
        let rmse = sqrt(sumResidualsSq / n)
        let maxResidual = result.residuals.map { abs($0) }.max() ?? 0

        return .table([
            "cx": .number(result.center.x),
            "cy": .number(result.center.y),
            "cz": .number(result.center.z),
            "r": .number(result.radius),
            "residuals": .array(result.residuals.map { .number($0) }),
            "rmse": .number(rmse),
            "max_error": .number(maxResidual),
            "method": .string("algebraic")
        ])
    }

    /// Fit a B-spline curve to data points using least squares via NumericSwift
    /// Input: points (array of {x,y} or {x,y,z}), degree, n_control_points, [parameterization]
    /// Output: {control_points, knots, degree, residuals, rmse, max_error, parameters}
    private static let bsplineFitCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let pointsArray = args[0].arrayValue,
              let degree = args[1].numberValue.map({ Int($0) }),
              let nControl = args[2].numberValue.map({ Int($0) }) else {
            throw LuaError.callbackError("bspline_fit requires (points, degree, n_control_points)")
        }

        // Optional parameterization method: "chord" (default), "uniform", "centripetal"
        let paramMethod = args.count > 3 ? (args[3].stringValue ?? "chord") : "chord"

        // Map string to NumericSwift parameterization enum
        let parameterization: BSplineParameterization
        switch paramMethod {
        case "uniform":
            parameterization = .uniform
        case "centripetal":
            parameterization = .centripetal
        default:
            parameterization = .chordLength
        }

        // Extract points (2D or 3D)
        var points2D: [Vec2] = []
        var points3D: [Vec3] = []
        var is3D = false

        for pt in pointsArray {
            if let table = pt.tableValue {
                let x = table["x"]?.numberValue ?? table["1"]?.numberValue
                let y = table["y"]?.numberValue ?? table["2"]?.numberValue
                let z = table["z"]?.numberValue ?? table["3"]?.numberValue

                if let x = x, let y = y {
                    if let z = z {
                        is3D = true
                        points3D.append(Vec3(x, y, z))
                    } else {
                        points2D.append(Vec2(x, y))
                    }
                }
            }
        }

        // Call NumericSwift bsplineFit
        if is3D {
            guard let result = bsplineFit3D(points: points3D, degree: degree,
                                            numControlPoints: nControl,
                                            parameterization: parameterization) else {
                throw LuaError.callbackError("bspline_fit: fitting failed")
            }

            return .table([
                "control_points": .array(result.controlPoints.map { vec3ToLua($0) }),
                "knots": .array(result.knots.map { .number($0) }),
                "degree": .number(Double(result.degree)),
                "residuals": .array(result.residuals.map { .number($0) }),
                "rmse": .number(result.rmse),
                "max_error": .number(result.maxError),
                "parameters": .array(result.parameters.map { .number($0) })
            ])
        } else {
            guard let result = bsplineFit(points: points2D, degree: degree,
                                          numControlPoints: nControl,
                                          parameterization: parameterization) else {
                throw LuaError.callbackError("bspline_fit: fitting failed")
            }

            return .table([
                "control_points": .array(result.controlPoints.map { vec2ToLua($0) }),
                "knots": .array(result.knots.map { .number($0) }),
                "degree": .number(Double(result.degree)),
                "residuals": .array(result.residuals.map { .number($0) }),
                "rmse": .number(result.rmse),
                "max_error": .number(result.maxError),
                "parameters": .array(result.parameters.map { .number($0) })
            ])
        }
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

    local _cubic_spline_coeffs = _luaswift_geo_cubic_spline_coeffs
    local _bspline_evaluate = _luaswift_geo_bspline_evaluate
    local _bspline_basis = _luaswift_geo_bspline_basis
    local _bspline_uniform_knots = _luaswift_geo_bspline_uniform_knots
    local _bspline_derivative = _luaswift_geo_bspline_derivative
    local _circle_fit_algebraic = _luaswift_geo_circle_fit_algebraic
    local _circle_fit_taubin = _luaswift_geo_circle_fit_taubin
    local _ellipse_fit_direct = _luaswift_geo_ellipse_fit_direct
    local _sphere_fit_algebraic = _luaswift_geo_sphere_fit_algebraic
    local _bspline_fit = _luaswift_geo_bspline_fit

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
            angle = function(self, other)
                if other then
                    return _angle_between(self, other)
                else
                    return _vec2_angle(self)
                end
            end,
            in_polygon = function(self, polygon) return _in_polygon(self, polygon) end,
            -- Create circle centered at this point
            circle = function(self, radius) return geo.circle(self, radius) end
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
            angle_to = function(self, other) return _angle_between(self, other) end,
            angle = function(self, other) return _angle_between(self, other) end
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

    -- Ellipse type with center, semi-axes, and rotation
    local ellipse_mt = {
        __eq = function(a, b)
            return a.center.x == b.center.x and a.center.y == b.center.y
                and a.semi_major == b.semi_major and a.semi_minor == b.semi_minor
                and a.rotation == b.rotation
        end,
        __tostring = function(a)
            return string.format("ellipse(center=vec2(%.4f, %.4f), a=%.4f, b=%.4f, θ=%.4f)",
                a.center.x, a.center.y, a.semi_major, a.semi_minor, a.rotation)
        end,
        __index = {
            -- Chainable transformations
            translate = function(self, dx, dy)
                return geo.ellipse(self.center.x + dx, self.center.y + dy,
                    self.semi_major, self.semi_minor, self.rotation)
            end,
            scale = function(self, factor)
                return geo.ellipse(self.center.x, self.center.y,
                    self.semi_major * factor, self.semi_minor * factor, self.rotation)
            end,
            rotate = function(self, angle)
                return geo.ellipse(self.center.x, self.center.y,
                    self.semi_major, self.semi_minor, self.rotation + angle)
            end,
            -- Queries
            contains = function(self, point)
                -- Transform point to ellipse-local coordinates
                local dx = point.x - self.center.x
                local dy = point.y - self.center.y
                local cos_r = math.cos(-self.rotation)
                local sin_r = math.sin(-self.rotation)
                local x_local = dx * cos_r - dy * sin_r
                local y_local = dx * sin_r + dy * cos_r
                -- Check if inside ellipse: (x/a)² + (y/b)² <= 1
                return (x_local * x_local) / (self.semi_major * self.semi_major) +
                       (y_local * y_local) / (self.semi_minor * self.semi_minor) <= 1
            end,
            area = function(self)
                return math.pi * self.semi_major * self.semi_minor
            end,
            circumference = function(self)
                -- Ramanujan's approximation
                local a, b = self.semi_major, self.semi_minor
                local h = ((a - b) / (a + b))^2
                return math.pi * (a + b) * (1 + 3 * h / (10 + math.sqrt(4 - 3 * h)))
            end,
            eccentricity = function(self)
                local a, b = self.semi_major, self.semi_minor
                return math.sqrt(1 - (b * b) / (a * a))
            end,
            -- Point generation
            point_at = function(self, t)
                -- Returns point on ellipse at parameter t (0 to 2π)
                local x_local = self.semi_major * math.cos(t)
                local y_local = self.semi_minor * math.sin(t)
                local cos_r = math.cos(self.rotation)
                local sin_r = math.sin(self.rotation)
                local x = self.center.x + x_local * cos_r - y_local * sin_r
                local y = self.center.y + x_local * sin_r + y_local * cos_r
                return geo.vec2(x, y)
            end,
            -- Focal points
            foci = function(self)
                local c = math.sqrt(self.semi_major^2 - self.semi_minor^2)
                local cos_r = math.cos(self.rotation)
                local sin_r = math.sin(self.rotation)
                local f1 = geo.vec2(self.center.x + c * cos_r, self.center.y + c * sin_r)
                local f2 = geo.vec2(self.center.x - c * cos_r, self.center.y - c * sin_r)
                return f1, f2
            end,
            -- Bounding box
            bounds = function(self)
                -- For rotated ellipse, compute axis-aligned bounding box
                local cos_r = math.cos(self.rotation)
                local sin_r = math.sin(self.rotation)
                local a, b = self.semi_major, self.semi_minor
                local halfW = math.sqrt(a*a * cos_r*cos_r + b*b * sin_r*sin_r)
                local halfH = math.sqrt(a*a * sin_r*sin_r + b*b * cos_r*cos_r)
                return {
                    min = geo.vec2(self.center.x - halfW, self.center.y - halfH),
                    max = geo.vec2(self.center.x + halfW, self.center.y + halfH)
                }
            end,
            -- Clone
            clone = function(self)
                return geo.ellipse(self.center.x, self.center.y,
                    self.semi_major, self.semi_minor, self.rotation)
            end,
            -- Convert to conic form [A, B, C, D, E, F] for Ax² + Bxy + Cy² + Dx + Ey + F = 0
            to_conic = function(self)
                local a, b = self.semi_major, self.semi_minor
                local cx, cy = self.center.x, self.center.y
                local cos_r = math.cos(self.rotation)
                local sin_r = math.sin(self.rotation)
                local cos2 = cos_r * cos_r
                local sin2 = sin_r * sin_r
                local sincos = sin_r * cos_r
                local a2, b2 = a * a, b * b

                local A = cos2 / a2 + sin2 / b2
                local B = 2 * sincos * (1/a2 - 1/b2)
                local C = sin2 / a2 + cos2 / b2
                local D = -2 * A * cx - B * cy
                local E = -2 * C * cy - B * cx
                local F = A * cx * cx + B * cx * cy + C * cy * cy - 1

                return {A, B, C, D, E, F}
            end
        }
    }

    -- Ellipse constructor: geo.ellipse(center, a, b, [theta]) or geo.ellipse(cx, cy, a, b, [theta])
    function geo.ellipse(a, b, c, d, e)
        local center, semi_major, semi_minor, rotation
        if type(a) == "table" and a.x ~= nil and a.y ~= nil then
            -- geo.ellipse(center_vec2, semi_major, semi_minor, [rotation])
            center = geo.vec2(a.x, a.y)
            semi_major = b
            semi_minor = c
            rotation = d or 0
        elseif type(a) == "number" and type(b) == "number" and type(c) == "number" and type(d) == "number" then
            -- geo.ellipse(cx, cy, semi_major, semi_minor, [rotation])
            center = geo.vec2(a, b)
            semi_major = c
            semi_minor = d
            rotation = e or 0
        else
            return nil
        end

        -- Ensure semi_major >= semi_minor
        if semi_minor > semi_major then
            semi_major, semi_minor = semi_minor, semi_major
            rotation = rotation + math.pi / 2
        end

        local ellipse = {
            center = center,
            semi_major = semi_major,
            semi_minor = semi_minor,
            rotation = rotation,
            __luaswift_type = "ellipse"
        }
        setmetatable(ellipse, ellipse_mt)
        return ellipse
    end

    -- Fit ellipse to points using least squares
    -- method: 'direct' (default, Fitzgibbon's method)
    -- Returns ellipse object with additional fit diagnostics
    function geo.ellipse_fit(points, method)
        method = method or 'direct'

        -- Convert points to array format if needed
        local pts = {}
        for i, pt in ipairs(points) do
            pts[i] = {x = pt.x or pt[1], y = pt.y or pt[2]}
        end

        -- Call fitting method
        local result
        if method == 'direct' then
            result = _ellipse_fit_direct(pts)
        else
            result = _ellipse_fit_direct(pts)  -- Default to direct
        end

        if not result then
            return nil  -- Fitting failed
        end

        -- Create ellipse object with fit diagnostics
        local ellipse = geo.ellipse(result.cx, result.cy, result.a, result.b, result.theta)
        ellipse._fit_residuals = result.residuals
        ellipse._fit_rmse = result.rmse
        ellipse._fit_method = result.method
        ellipse._fit_conic = result.conic
        ellipse._fit_points = pts

        -- Add fit diagnostic methods to this specific ellipse
        local mt = getmetatable(ellipse)
        local old_index = mt.__index

        local new_mt = {}
        for k, v in pairs(mt) do
            new_mt[k] = v
        end
        new_mt.__index = function(t, k)
            if k == "residuals" then
                return function() return t._fit_residuals end
            elseif k == "rmse" then
                return function() return t._fit_rmse end
            elseif k == "fit_method" then
                return function() return t._fit_method end
            elseif k == "fit_points" then
                return function() return t._fit_points end
            elseif k == "fit_conic" then
                return function() return t._fit_conic end
            elseif k == "cx" then
                return t.center.x
            elseif k == "cy" then
                return t.center.y
            elseif k == "a" then
                return t.semi_major
            elseif k == "b" then
                return t.semi_minor
            elseif k == "theta" then
                return t.rotation
            else
                return old_index[k]
            end
        end
        setmetatable(ellipse, new_mt)

        return ellipse
    end

    -- Sphere type with center (vec3) and radius
    local sphere_mt = {
        __eq = function(a, b)
            return a.center.x == b.center.x and a.center.y == b.center.y
                and a.center.z == b.center.z and a.radius == b.radius
        end,
        __tostring = function(a)
            return string.format("sphere(center=vec3(%.4f, %.4f, %.4f), radius=%.4f)",
                a.center.x, a.center.y, a.center.z, a.radius)
        end,
        __index = {
            -- Chainable transformations
            translate = function(self, dx, dy, dz)
                return geo.sphere(self.center.x + dx, self.center.y + dy, self.center.z + dz, self.radius)
            end,
            scale = function(self, factor)
                return geo.sphere(self.center.x, self.center.y, self.center.z, self.radius * factor)
            end,
            -- Queries
            contains = function(self, point)
                local dx = point.x - self.center.x
                local dy = point.y - self.center.y
                local dz = point.z - self.center.z
                return (dx * dx + dy * dy + dz * dz) <= (self.radius * self.radius)
            end,
            volume = function(self)
                return (4/3) * math.pi * self.radius^3
            end,
            surface_area = function(self)
                return 4 * math.pi * self.radius^2
            end,
            -- Point generation (spherical coordinates)
            point_at = function(self, theta, phi)
                -- theta: azimuthal angle (0 to 2π), phi: polar angle (0 to π)
                local x = self.center.x + self.radius * math.sin(phi) * math.cos(theta)
                local y = self.center.y + self.radius * math.sin(phi) * math.sin(theta)
                local z = self.center.z + self.radius * math.cos(phi)
                return geo.vec3(x, y, z)
            end,
            -- Bounding box
            bounds = function(self)
                return {
                    min = geo.vec3(self.center.x - self.radius, self.center.y - self.radius, self.center.z - self.radius),
                    max = geo.vec3(self.center.x + self.radius, self.center.y + self.radius, self.center.z + self.radius)
                }
            end,
            -- Clone
            clone = function(self)
                return geo.sphere(self.center.x, self.center.y, self.center.z, self.radius)
            end,
            -- Distance from point to surface (positive = outside, negative = inside)
            distance = function(self, point)
                local dx = point.x - self.center.x
                local dy = point.y - self.center.y
                local dz = point.z - self.center.z
                return math.sqrt(dx * dx + dy * dy + dz * dz) - self.radius
            end
        }
    }

    -- Sphere constructor: geo.sphere(center, radius) or geo.sphere(cx, cy, cz, radius)
    function geo.sphere(a, b, c, d)
        local center, radius
        if type(a) == "table" and a.x ~= nil and a.y ~= nil and a.z ~= nil then
            -- geo.sphere(center_vec3, radius)
            center = geo.vec3(a.x, a.y, a.z)
            radius = b
        elseif type(a) == "number" and type(b) == "number" and type(c) == "number" and type(d) == "number" then
            -- geo.sphere(cx, cy, cz, radius)
            center = geo.vec3(a, b, c)
            radius = d
        else
            return nil
        end

        local sphere = {
            center = center,
            radius = radius,
            __luaswift_type = "sphere"
        }
        setmetatable(sphere, sphere_mt)
        return sphere
    end

    -- Fit sphere to 3D points using least squares
    -- method: 'algebraic' (default)
    -- Returns sphere object with additional fit diagnostics
    function geo.sphere_fit(points, method)
        method = method or 'algebraic'

        -- Convert points to array format if needed
        local pts = {}
        for i, pt in ipairs(points) do
            pts[i] = {x = pt.x or pt[1], y = pt.y or pt[2], z = pt.z or pt[3]}
        end

        -- Call fitting method
        local result = _sphere_fit_algebraic(pts)

        if not result then
            return nil  -- Fitting failed (coplanar points, etc.)
        end

        -- Create sphere object with fit diagnostics
        local sphere = geo.sphere(result.cx, result.cy, result.cz, result.r)
        sphere._fit_residuals = result.residuals
        sphere._fit_rmse = result.rmse
        sphere._fit_max_error = result.max_error
        sphere._fit_method = result.method
        sphere._fit_points = pts

        -- Add fit diagnostic methods to this specific sphere
        local mt = getmetatable(sphere)
        local old_index = mt.__index

        local new_mt = {}
        for k, v in pairs(mt) do
            new_mt[k] = v
        end
        new_mt.__index = function(t, k)
            if k == "residuals" then
                return function() return t._fit_residuals end
            elseif k == "rmse" then
                return function() return t._fit_rmse end
            elseif k == "max_error" then
                return function() return t._fit_max_error end
            elseif k == "fit_method" then
                return function() return t._fit_method end
            elseif k == "fit_points" then
                return function() return t._fit_points end
            elseif k == "cx" then
                return t.center.x
            elseif k == "cy" then
                return t.center.y
            elseif k == "cz" then
                return t.center.z
            elseif k == "r" then
                return t.radius
            else
                return old_index[k]
            end
        end
        setmetatable(sphere, new_mt)

        return sphere
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
    -- Alias for convenience
    geo.angle = geo.angle_between

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
            return geo.sphere(r.center.x, r.center.y, r.center.z, r.radius)
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

    -- Polynomial type for curve fitting results
    local poly_mt = {
        __tostring = function(self)
            local terms = {}
            for i, c in ipairs(self._coeffs) do
                local deg = i - 1
                if c ~= 0 then
                    local term
                    if deg == 0 then
                        term = string.format("%.4g", c)
                    elseif deg == 1 then
                        if c == 1 then term = "x"
                        elseif c == -1 then term = "-x"
                        else term = string.format("%.4g*x", c) end
                    else
                        if c == 1 then term = string.format("x^%d", deg)
                        elseif c == -1 then term = string.format("-x^%d", deg)
                        else term = string.format("%.4g*x^%d", c, deg) end
                    end
                    table.insert(terms, term)
                end
            end
            if #terms == 0 then return "poly(0)" end
            return "poly(" .. table.concat(terms, " + "):gsub(" %+ %-", " - ") .. ")"
        end,
        __eq = function(a, b)
            if #a._coeffs ~= #b._coeffs then return false end
            for i = 1, #a._coeffs do
                if math.abs(a._coeffs[i] - b._coeffs[i]) > 1e-10 then return false end
            end
            return true
        end,
        __index = {
            -- Evaluate polynomial at x: a_0 + a_1*x + a_2*x^2 + ...
            evaluate = function(self, x)
                local result = 0
                local x_pow = 1
                for _, c in ipairs(self._coeffs) do
                    result = result + c * x_pow
                    x_pow = x_pow * x
                end
                return result
            end,

            -- Get polynomial degree
            degree = function(self)
                return #self._coeffs - 1
            end,

            -- Get coefficients array [a_0, a_1, ..., a_n]
            coefficients = function(self)
                local result = {}
                for i, c in ipairs(self._coeffs) do
                    result[i] = c
                end
                return result
            end,

            -- Return derivative polynomial
            derivative = function(self)
                if #self._coeffs <= 1 then
                    return geo.polynomial({0})
                end
                local new_coeffs = {}
                for i = 2, #self._coeffs do
                    new_coeffs[i-1] = self._coeffs[i] * (i - 1)
                end
                return geo.polynomial(new_coeffs)
            end,

            -- Find real roots using Newton's method (simple implementation)
            -- Returns array of roots found
            roots = function(self, options)
                options = options or {}
                local tol = options.tol or 1e-10
                local max_iter = options.max_iter or 100
                local roots = {}
                local seen = {}

                -- Try finding roots starting from various initial points
                local deriv = self:derivative()
                for _, x0 in ipairs({0, 1, -1, 2, -2, 5, -5, 10, -10}) do
                    local x = x0
                    for _ = 1, max_iter do
                        local fx = self:evaluate(x)
                        if math.abs(fx) < tol then
                            -- Check if this root is new
                            local is_new = true
                            for _, r in ipairs(roots) do
                                if math.abs(x - r) < tol * 100 then
                                    is_new = false
                                    break
                                end
                            end
                            if is_new then
                                table.insert(roots, x)
                            end
                            break
                        end
                        local dfx = deriv:evaluate(x)
                        if math.abs(dfx) < 1e-15 then break end
                        x = x - fx / dfx
                    end
                end
                table.sort(roots)
                return roots
            end,

            -- Clone this polynomial
            clone = function(self)
                return geo.polynomial(self:coefficients())
            end
        }
    }

    -- Polynomial constructor from coefficients [a_0, a_1, ..., a_n]
    function geo.polynomial(coeffs)
        local p = {
            _coeffs = {},
            __luaswift_type = "polynomial"
        }
        for i, c in ipairs(coeffs) do
            p._coeffs[i] = c
        end
        -- Remove trailing zeros (but keep at least one coefficient)
        while #p._coeffs > 1 and p._coeffs[#p._coeffs] == 0 do
            table.remove(p._coeffs)
        end
        setmetatable(p, poly_mt)
        return p
    end

    -- Evaluate polynomial directly from coefficients
    function geo.polyeval(coeffs, x)
        local result = 0
        local x_pow = 1
        for _, c in ipairs(coeffs) do
            result = result + c * x_pow
            x_pow = x_pow * x
        end
        return result
    end

    -- Fit polynomial to points using least squares
    -- points: array of {x, y} or {{x, y}, ...} or (xs, ys)
    -- degree: polynomial degree
    -- Returns polynomial object with additional diagnostics
    function geo.polyfit(points_or_xs, degree_or_ys, maybe_degree)
        local xs, ys, degree

        -- Parse arguments
        if type(degree_or_ys) == "number" then
            -- geo.polyfit(points, degree)
            local points = points_or_xs
            degree = degree_or_ys
            xs, ys = {}, {}
            for i, pt in ipairs(points) do
                xs[i] = pt.x or pt[1]
                ys[i] = pt.y or pt[2]
            end
        else
            -- geo.polyfit(xs, ys, degree)
            xs = points_or_xs
            ys = degree_or_ys
            degree = maybe_degree
        end

        if #xs < degree + 1 then
            error("polyfit: need at least " .. (degree + 1) .. " points for degree " .. degree .. " polynomial")
        end

        -- Check if linalg module is available
        local linalg = luaswift and luaswift.linalg
        if not linalg then
            error("polyfit: requires luaswift.linalg module to be loaded")
        end

        -- Build Vandermonde matrix A[i,j] = x_i^j (as 2D array for linalg.matrix)
        local n = #xs
        local A_rows = {}
        for i = 1, n do
            local x = xs[i]
            local row = {}
            local x_pow = 1
            for j = 1, degree + 1 do
                row[j] = x_pow
                x_pow = x_pow * x
            end
            A_rows[i] = row
        end

        -- Create linalg matrix and vector objects
        local A = linalg.matrix(A_rows)
        local b = linalg.vector(ys)

        -- Solve using least squares
        local result = linalg.least_squares(A, b)

        -- Extract coefficients (result is a vector)
        local coeffs = {}
        for i = 1, degree + 1 do
            coeffs[i] = result:get(i, 1)
        end

        -- Create polynomial object
        local poly = geo.polynomial(coeffs)

        -- Calculate R-squared and residuals
        local y_mean = 0
        for _, y in ipairs(ys) do y_mean = y_mean + y end
        y_mean = y_mean / n

        local ss_tot = 0
        local ss_res = 0
        for i = 1, n do
            local y_pred = poly:evaluate(xs[i])
            local residual = ys[i] - y_pred
            ss_res = ss_res + residual * residual
            ss_tot = ss_tot + (ys[i] - y_mean) * (ys[i] - y_mean)
        end

        poly.r_squared = 1 - ss_res / ss_tot
        poly.residual_sum = ss_res
        poly.xs = xs
        poly.ys = ys

        return poly
    end

    -- Cubic Spline type for smooth interpolation
    -- Each segment i uses: S_i(x) = a + b*(x-x_i) + c*(x-x_i)^2 + d*(x-x_i)^3
    local spline_mt = {
        __tostring = function(self)
            local n = #self._knots
            return string.format("cubic_spline(%d points, domain [%.4g, %.4g])",
                n, self._knots[1], self._knots[n])
        end,
        __index = {
            -- Evaluate spline at x
            evaluate = function(self, x)
                local knots = self._knots
                local n = #knots

                -- Handle out of bounds
                if x <= knots[1] then
                    -- Extrapolate using first segment
                    local c = self._coeffs[1]
                    local dx = x - knots[1]
                    return c.a + c.b * dx + c.c * dx * dx + c.d * dx * dx * dx
                end
                if x >= knots[n] then
                    -- Extrapolate using last segment
                    local c = self._coeffs[n - 1]
                    local dx = x - knots[n - 1]
                    return c.a + c.b * dx + c.c * dx * dx + c.d * dx * dx * dx
                end

                -- Binary search for the correct segment
                local lo, hi = 1, n - 1
                while lo < hi do
                    local mid = math.floor((lo + hi + 1) / 2)
                    if knots[mid] <= x then
                        lo = mid
                    else
                        hi = mid - 1
                    end
                end

                -- Evaluate cubic polynomial for segment
                local c = self._coeffs[lo]
                local dx = x - knots[lo]
                return c.a + c.b * dx + c.c * dx * dx + c.d * dx * dx * dx
            end,

            -- First derivative at x
            derivative = function(self, x)
                local knots = self._knots
                local n = #knots

                -- Find segment (same as evaluate)
                local seg = 1
                if x <= knots[1] then
                    seg = 1
                elseif x >= knots[n] then
                    seg = n - 1
                else
                    local lo, hi = 1, n - 1
                    while lo < hi do
                        local mid = math.floor((lo + hi + 1) / 2)
                        if knots[mid] <= x then
                            lo = mid
                        else
                            hi = mid - 1
                        end
                    end
                    seg = lo
                end

                -- Derivative: b + 2*c*(x-x_i) + 3*d*(x-x_i)^2
                local c = self._coeffs[seg]
                local dx = x - knots[seg]
                return c.b + 2 * c.c * dx + 3 * c.d * dx * dx
            end,

            -- Second derivative at x
            second_derivative = function(self, x)
                local knots = self._knots
                local n = #knots

                -- Find segment
                local seg = 1
                if x <= knots[1] then
                    seg = 1
                elseif x >= knots[n] then
                    seg = n - 1
                else
                    local lo, hi = 1, n - 1
                    while lo < hi do
                        local mid = math.floor((lo + hi + 1) / 2)
                        if knots[mid] <= x then
                            lo = mid
                        else
                            hi = mid - 1
                        end
                    end
                    seg = lo
                end

                -- Second derivative: 2*c + 6*d*(x-x_i)
                local c = self._coeffs[seg]
                local dx = x - knots[seg]
                return 2 * c.c + 6 * c.d * dx
            end,

            -- Batch evaluate for efficiency
            evaluate_array = function(self, xs)
                local results = {}
                for i, x in ipairs(xs) do
                    results[i] = self:evaluate(x)
                end
                return results
            end,

            -- Return domain [x_min, x_max]
            domain = function(self)
                local n = #self._knots
                return self._knots[1], self._knots[n]
            end,

            -- Get knots (interpolation x-values)
            knots = function(self)
                local result = {}
                for i, k in ipairs(self._knots) do
                    result[i] = k
                end
                return result
            end,

            -- Get values (interpolation y-values)
            values = function(self)
                local result = {}
                for i, v in ipairs(self._values) do
                    result[i] = v
                end
                return result
            end,

            -- Get number of segments
            segments = function(self)
                return #self._coeffs
            end,

            -- Get coefficients for a specific segment (1-indexed)
            segment_coeffs = function(self, i)
                local c = self._coeffs[i]
                if not c then return nil end
                return {a = c.a, b = c.b, c = c.c, d = c.d}
            end
        }
    }

    -- Construct a cubic spline from data points
    -- Signatures:
    --   geo.cubic_spline(points, [options])        - points as {x,y} pairs
    --   geo.cubic_spline(xs, ys, [options])        - separate x and y arrays
    -- Options:
    --   bc_type: "natural" (default), "clamped", "not-a-knot"
    --   extrapolate: boolean (default true)
    -- For "natural" bc_type, uses fast Swift/LAPACK implementation.
    -- For "clamped" or "not-a-knot", delegates to math.interpolate.CubicSpline.
    function geo.cubic_spline(points_or_xs, maybe_ys_or_options, maybe_options)
        local xs, ys = {}, {}
        local options = {}

        -- Parse input format
        if type(maybe_ys_or_options) == "table" and #maybe_ys_or_options == 0 and not maybe_ys_or_options[1] then
            -- Second arg is options table (no numeric keys)
            options = maybe_ys_or_options
            -- First arg is array of {x, y} pairs
            for i, pt in ipairs(points_or_xs) do
                xs[i] = pt[1] or pt.x
                ys[i] = pt[2] or pt.y
            end
        elseif type(maybe_ys_or_options) == "table" and (maybe_ys_or_options[1] or #maybe_ys_or_options > 0) then
            -- Two separate arrays: xs, ys
            for i, x in ipairs(points_or_xs) do
                xs[i] = x
            end
            for i, y in ipairs(maybe_ys_or_options) do
                ys[i] = y
            end
            options = maybe_options or {}
        elseif maybe_ys_or_options == nil then
            -- First arg is array of {x, y} pairs, no options
            for i, pt in ipairs(points_or_xs) do
                xs[i] = pt[1] or pt.x
                ys[i] = pt[2] or pt.y
            end
        else
            error("cubic_spline: invalid arguments")
        end

        if #xs < 2 then
            error("cubic_spline requires at least 2 points")
        end

        local bc_type = options.bc_type or "natural"

        -- For non-natural boundary conditions, delegate to math.interpolate.CubicSpline
        if bc_type ~= "natural" then
            -- Use InterpolateModule which supports clamped and not-a-knot
            return math.interpolate.CubicSpline(xs, ys, options)
        end

        -- Natural boundary: use fast Swift/LAPACK implementation
        local result = _cubic_spline_coeffs(xs, ys)

        -- Build spline object
        local spline = {
            _knots = result.knots,
            _values = result.values,
            _coeffs = result.coeffs,
            __luaswift_type = "cubic_spline"
        }

        setmetatable(spline, spline_mt)
        return spline
    end

    -- B-Spline type for smooth parametric curves
    local bspline_mt = {
        __tostring = function(self)
            return string.format("bspline(degree=%d, %d control points, domain [%.4g, %.4g])",
                self._degree, #self._control_points,
                self._knots[self._degree + 1], self._knots[#self._knots - self._degree])
        end,
        __index = {
            -- Evaluate B-spline at parameter t (in [0, 1] for clamped splines)
            evaluate = function(self, t)
                local pt = _bspline_evaluate(self._control_points, self._degree, self._knots, t)
                if self._is3d then
                    return geo.vec3(pt.x, pt.y, pt.z)
                else
                    return geo.vec2(pt.x, pt.y)
                end
            end,

            -- First derivative at t
            derivative = function(self, t, order)
                order = order or 1
                local pt = _bspline_derivative(self._control_points, self._degree, self._knots, t, order)
                if self._is3d then
                    return geo.vec3(pt.x, pt.y, pt.z)
                else
                    return geo.vec2(pt.x, pt.y)
                end
            end,

            -- Sample n uniformly spaced points along the curve
            sample = function(self, n)
                n = n or 100
                local t_min = self._knots[self._degree + 1]
                local t_max = self._knots[#self._knots - self._degree]
                local points = {}
                for i = 1, n do
                    local t = t_min + (t_max - t_min) * (i - 1) / (n - 1)
                    points[i] = self:evaluate(t)
                end
                return points
            end,

            -- Get parameter domain [t_min, t_max]
            domain = function(self)
                local t_min = self._knots[self._degree + 1]
                local t_max = self._knots[#self._knots - self._degree]
                return t_min, t_max
            end,

            -- Get control points
            control_points = function(self)
                local result = {}
                for i, cp in ipairs(self._control_points) do
                    if self._is3d then
                        result[i] = geo.vec3(cp.x, cp.y, cp.z)
                    else
                        result[i] = geo.vec2(cp.x, cp.y)
                    end
                end
                return result
            end,

            -- Get knot vector
            knots = function(self)
                local result = {}
                for i, k in ipairs(self._knots) do
                    result[i] = k
                end
                return result
            end,

            -- Get degree
            degree = function(self)
                return self._degree
            end,

            -- Evaluate basis function N_{i,p}(t)
            basis = function(self, i, t)
                return _bspline_basis(self._knots, i, self._degree, t)
            end,

            -- Check if 3D spline
            is_3d = function(self)
                return self._is3d
            end
        }
    }

    -- B-spline constructor
    -- control_points: array of vec2 or vec3
    -- degree: polynomial degree (1-5, default 3 for cubic)
    -- knot_vector: optional custom knots (clamped uniform if not provided)
    function geo.bspline(control_points, degree, knot_vector)
        degree = degree or 3

        -- Validate degree
        if degree < 1 or degree > 5 then
            error("B-spline degree must be between 1 and 5")
        end

        local n = #control_points
        if n < degree + 1 then
            error("Need at least " .. (degree + 1) .. " control points for degree " .. degree)
        end

        -- Detect if 3D
        local is3d = false
        local first = control_points[1]
        if first.z ~= nil then
            is3d = true
        end

        -- Normalize control points to table format
        local cps = {}
        for i, pt in ipairs(control_points) do
            if is3d then
                cps[i] = {x = pt.x or pt[1], y = pt.y or pt[2], z = pt.z or pt[3]}
            else
                cps[i] = {x = pt.x or pt[1], y = pt.y or pt[2]}
            end
        end

        -- Generate knot vector if not provided
        local knots
        if knot_vector then
            knots = {}
            for i, k in ipairs(knot_vector) do
                knots[i] = k
            end
        else
            -- Generate clamped uniform knot vector
            local result = _bspline_uniform_knots(n, degree)
            knots = {}
            for i, k in ipairs(result) do
                knots[i] = k
            end
        end

        -- Validate knot vector size
        local expected_knots = n + degree + 1
        if #knots ~= expected_knots then
            error("Knot vector must have " .. expected_knots .. " elements (n + degree + 1)")
        end

        local spline = {
            _control_points = cps,
            _degree = degree,
            _knots = knots,
            _is3d = is3d,
            __luaswift_type = "bspline"
        }

        setmetatable(spline, bspline_mt)
        return spline
    end

    -- Utility: evaluate basis function directly
    function geo.bspline_basis(knots, i, p, t)
        return _bspline_basis(knots, i, p, t)
    end

    -- Utility: generate uniform knot vector
    function geo.bspline_uniform_knots(n, degree)
        local result = _bspline_uniform_knots(n, degree)
        local knots = {}
        for i, k in ipairs(result) do
            knots[i] = k
        end
        return knots
    end

    -- Fit B-spline to data points using least squares
    -- points: array of {x,y} or {x,y,z} points
    -- degree: B-spline degree (1-5)
    -- n_control_points: number of control points (>= degree+1)
    -- options: {parameterization = "chord" | "uniform" | "centripetal"}
    -- Returns a B-spline object with fit diagnostics
    function geo.bspline_fit(points, degree, n_control_points, options)
        options = options or {}
        local param = options.parameterization or "chord"

        -- Convert points to array format if needed
        local pts = {}
        local is3d = false
        for i, pt in ipairs(points) do
            local x = pt.x or pt[1]
            local y = pt.y or pt[2]
            local z = pt.z or pt[3]
            if z then
                is3d = true
                pts[i] = {x = x, y = y, z = z}
            else
                pts[i] = {x = x, y = y}
            end
        end

        -- Call Swift fitting callback
        local result = _bspline_fit(pts, degree, n_control_points, param)

        -- Build B-spline object from fit result
        local control_points = {}
        for i, cp in ipairs(result.control_points) do
            if is3d then
                control_points[i] = geo.vec3(cp.x, cp.y, cp.z)
            else
                control_points[i] = geo.vec2(cp.x, cp.y)
            end
        end

        -- Create the B-spline using the fitted control points
        local spline = geo.bspline(control_points, degree, result.knots)

        -- Attach fit diagnostics
        spline._residuals = result.residuals
        spline._rmse = result.rmse
        spline._max_error = result.max_error
        spline._parameters = result.parameters

        return spline
    end

    -- Fit circle to points using least squares
    -- method: 'algebraic' (default, fast), 'taubin' (more accurate for noise)
    -- Returns circle object with additional fit diagnostics
    function geo.circle_fit(points, method)
        method = method or 'algebraic'

        -- Convert points to array format if needed
        local pts = {}
        for i, pt in ipairs(points) do
            pts[i] = {x = pt.x or pt[1], y = pt.y or pt[2]}
        end

        -- Call appropriate fitting method
        local result
        if method == 'taubin' then
            result = _circle_fit_taubin(pts)
        else
            result = _circle_fit_algebraic(pts)
        end

        if not result then
            return nil  -- Fitting failed (collinear points, etc.)
        end

        -- Create circle object with fit diagnostics
        local circle = geo.circle(result.cx, result.cy, result.r)
        circle._fit_residuals = result.residuals
        circle._fit_rmse = result.rmse
        circle._fit_method = result.method
        circle._fit_points = pts

        -- Add residuals method to this specific circle
        local mt = getmetatable(circle)
        local old_index = mt.__index

        -- Create new metatable with extended __index
        local new_mt = {}
        for k, v in pairs(mt) do
            new_mt[k] = v
        end
        new_mt.__index = function(t, k)
            if k == "residuals" then
                return function() return t._fit_residuals end
            elseif k == "rmse" then
                return function() return t._fit_rmse end
            elseif k == "fit_method" then
                return function() return t._fit_method end
            elseif k == "fit_points" then
                return function() return t._fit_points end
            elseif k == "cx" then
                return t.center.x
            elseif k == "cy" then
                return t.center.y
            elseif k == "r" then
                return t.radius
            else
                return old_index[k]
            end
        end
        setmetatable(circle, new_mt)

        return circle
    end

    -- Unified fitting function
    -- geo.fit(points, shape, [options]) - fits various shapes to point data
    -- shape: 'line', 'polynomial', 'circle', 'ellipse', 'sphere', 'spline', 'bspline'
    -- options: shape-specific options (degree for polynomial/bspline, method for circle/ellipse/sphere)
    function geo.fit(points, shape, options)
        options = options or {}

        if shape == 'line' or shape == 'linear' then
            -- Linear fit is degree-1 polynomial
            return geo.polyfit(points, 1)
        elseif shape == 'polynomial' or shape == 'poly' then
            local degree = options.degree or 2
            return geo.polyfit(points, degree)
        elseif shape == 'circle' then
            local method = options.method or 'algebraic'
            return geo.circle_fit(points, method)
        elseif shape == 'ellipse' then
            local method = options.method or 'direct'
            return geo.ellipse_fit(points, method)
        elseif shape == 'sphere' then
            local method = options.method or 'algebraic'
            return geo.sphere_fit(points, method)
        elseif shape == 'spline' or shape == 'cubic_spline' then
            return geo.cubic_spline(points)
        elseif shape == 'bspline' then
            local degree = options.degree or 3
            local knots = options.knots  -- may be nil for uniform
            return geo.bspline(points, degree, knots)
        else
            error("Unknown shape for geo.fit: " .. tostring(shape) .. ". Use 'line', 'polynomial', 'circle', 'ellipse', 'sphere', 'spline', or 'bspline'.")
        end
    end

    -- Make available via require
    package.loaded["luaswift.geometry"] = geo
    """
}

#endif  // LUASWIFT_NUMERICSWIFT
