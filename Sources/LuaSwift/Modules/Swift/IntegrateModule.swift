//
//  IntegrateModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Accelerate

/// Swift-backed numerical integration module for LuaSwift.
///
/// Provides numerical integration functions including adaptive quadrature,
/// multiple integration, and ODE solvers. All algorithms implemented in Swift
/// for performance, with thin Lua bindings.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- Single integration (adaptive Gauss-Kronrod)
/// local result, error = math.integrate.quad(function(x) return x^2 end, 0, 1)
/// print(result, error)  -- 0.333..., ~1e-14
///
/// -- Double integration
/// local result, error = math.integrate.dblquad(
///     function(y, x) return x * y end,
///     0, 1,   -- x limits
///     0, 1    -- y limits
/// )
///
/// -- Triple integration
/// local result, error = math.integrate.tplquad(
///     function(z, y, x) return x * y * z end,
///     0, 1, 0, 1, 0, 1
/// )
/// ```
public struct IntegrateModule {

    // MARK: - Constants

    /// Default absolute tolerance
    public static let defaultEpsAbs: Double = 1.49e-8

    /// Default relative tolerance
    public static let defaultEpsRel: Double = 1.49e-8

    /// Default maximum subdivisions for adaptive quadrature
    public static let defaultLimit: Int = 50

    // MARK: - Gauss-Kronrod Quadrature Weights

    /// Gauss-Kronrod 15-point abscissae (symmetric, only positive half stored)
    private static let xgk: [Double] = [
        0.991455371120813,
        0.949107912342759,
        0.864864423359769,
        0.741531185599394,
        0.586087235467691,
        0.405845151377397,
        0.207784955007898,
        0.0
    ]

    /// Weights for 15-point Kronrod rule
    private static let wgk: [Double] = [
        0.022935322010529,
        0.063092092629979,
        0.104790010322250,
        0.140653259715525,
        0.169004726639267,
        0.190350578064785,
        0.204432940075298,
        0.209482141084728
    ]

    /// Weights for 7-point Gauss rule (embedded in K15)
    private static let wg: [Double] = [
        0.129484966168870,
        0.279705391489277,
        0.381830050505119,
        0.417959183673469
    ]

    // MARK: - Gauss-Legendre Points and Weights

    /// Gauss-Legendre quadrature points and weights for n=1 to 10
    private static let gaussLegendre: [Int: [(x: Double, w: Double)]] = [
        1: [(0, 2)],
        2: [(-0.5773502691896257, 1), (0.5773502691896257, 1)],
        3: [(-0.7745966692414834, 0.5555555555555556),
            (0, 0.8888888888888888),
            (0.7745966692414834, 0.5555555555555556)],
        4: [(-0.8611363115940526, 0.3478548451374538),
            (-0.3399810435848563, 0.6521451548625461),
            (0.3399810435848563, 0.6521451548625461),
            (0.8611363115940526, 0.3478548451374538)],
        5: [(-0.9061798459386640, 0.2369268850561891),
            (-0.5384693101056831, 0.4786286704993665),
            (0, 0.5688888888888889),
            (0.5384693101056831, 0.4786286704993665),
            (0.9061798459386640, 0.2369268850561891)],
        6: [(-0.9324695142031521, 0.1713244923791704),
            (-0.6612093864662645, 0.3607615730481386),
            (-0.2386191860831969, 0.4679139345726910),
            (0.2386191860831969, 0.4679139345726910),
            (0.6612093864662645, 0.3607615730481386),
            (0.9324695142031521, 0.1713244923791704)],
        7: [(-0.9491079123427585, 0.1294849661688697),
            (-0.7415311855993945, 0.2797053914892766),
            (-0.4058451513773972, 0.3818300505051189),
            (0, 0.4179591836734694),
            (0.4058451513773972, 0.3818300505051189),
            (0.7415311855993945, 0.2797053914892766),
            (0.9491079123427585, 0.1294849661688697)],
        8: [(-0.9602898564975363, 0.1012285362903763),
            (-0.7966664774136267, 0.2223810344533745),
            (-0.5255324099163290, 0.3137066458778873),
            (-0.1834346424956498, 0.3626837833783620),
            (0.1834346424956498, 0.3626837833783620),
            (0.5255324099163290, 0.3137066458778873),
            (0.7966664774136267, 0.2223810344533745),
            (0.9602898564975363, 0.1012285362903763)],
        9: [(-0.9681602395076261, 0.0812743883615744),
            (-0.8360311073266358, 0.1806481606948574),
            (-0.6133714327005904, 0.2606106964029354),
            (-0.3242534234038089, 0.3123470770400029),
            (0, 0.3302393550012598),
            (0.3242534234038089, 0.3123470770400029),
            (0.6133714327005904, 0.2606106964029354),
            (0.8360311073266358, 0.1806481606948574),
            (0.9681602395076261, 0.0812743883615744)],
        10: [(-0.9739065285171717, 0.0666713443086881),
             (-0.8650633666889845, 0.1494513491505806),
             (-0.6794095682990244, 0.2190863625159820),
             (-0.4333953941292472, 0.2692667193099963),
             (-0.1488743389816312, 0.2955242247147529),
             (0.1488743389816312, 0.2955242247147529),
             (0.4333953941292472, 0.2692667193099963),
             (0.6794095682990244, 0.2190863625159820),
             (0.8650633666889845, 0.1494513491505806),
             (0.9739065285171717, 0.0666713443086881)]
    ]

    // MARK: - Dormand-Prince RK45 Coefficients

    /// Dormand-Prince A matrix (lower triangular part)
    private static let dpA: [[Double]] = [
        [],
        [1.0/5.0],
        [3.0/40.0, 9.0/40.0],
        [44.0/45.0, -56.0/15.0, 32.0/9.0],
        [19372.0/6561.0, -25360.0/2187.0, 64448.0/6561.0, -212.0/729.0],
        [9017.0/3168.0, -355.0/33.0, 46732.0/5247.0, 49.0/176.0, -5103.0/18656.0],
        [35.0/384.0, 0, 500.0/1113.0, 125.0/192.0, -2187.0/6784.0, 11.0/84.0]
    ]

    /// Dormand-Prince C coefficients (nodes)
    private static let dpC: [Double] = [0, 1.0/5.0, 3.0/10.0, 4.0/5.0, 8.0/9.0, 1, 1]

    /// Dormand-Prince B coefficients (5th order weights)
    private static let dpB: [Double] = [35.0/384.0, 0, 500.0/1113.0, 125.0/192.0, -2187.0/6784.0, 11.0/84.0, 0]

    /// Dormand-Prince E coefficients (error estimate: 5th - 4th order)
    private static let dpE: [Double] = [71.0/57600.0, 0, -71.0/16695.0, 71.0/1920.0, -17253.0/339200.0, 22.0/525.0, -1.0/40.0]

    // MARK: - Bogacki-Shampine RK23 Coefficients

    private static let bsA: [[Double]] = [
        [],
        [1.0/2.0],
        [0, 3.0/4.0],
        [2.0/9.0, 1.0/3.0, 4.0/9.0]
    ]

    private static let bsC: [Double] = [0, 1.0/2.0, 3.0/4.0, 1]
    private static let bsB: [Double] = [2.0/9.0, 1.0/3.0, 4.0/9.0, 0]
    private static let bsE: [Double] = [-5.0/72.0, 1.0/12.0, 1.0/9.0, -1.0/8.0]

    // MARK: - Integration Result Types

    /// Result of a quadrature integration
    public struct QuadResult {
        /// Computed integral value
        public let value: Double
        /// Estimated absolute error
        public let error: Double
        /// Number of function evaluations
        public let neval: Int
    }

    /// Result of an ODE integration
    public struct ODEResult {
        /// Time points
        public let t: [Double]
        /// Solution values at each time point (y[i] is array of components at t[i])
        public let y: [[Double]]
        /// Whether integration was successful
        public let success: Bool
        /// Status message
        public let message: String
        /// Number of function evaluations
        public let nfev: Int
    }

    // MARK: - Single Integration (Gauss-Kronrod 15-point)

    /// Single Gauss-Kronrod 15-point quadrature step
    /// - Parameters:
    ///   - f: Function to integrate
    ///   - a: Lower limit
    ///   - b: Upper limit
    /// - Returns: (result, error estimate)
    private static func gk15(_ f: (Double) -> Double, _ a: Double, _ b: Double) -> (Double, Double) {
        let center = 0.5 * (a + b)
        let halfLength = 0.5 * (b - a)
        let fCenter = f(center)

        var resultKronrod = fCenter * wgk[7]
        var resultGauss = fCenter * wg[3]

        for i in 0..<7 {
            let x = halfLength * xgk[i]
            let fval1 = f(center - x)
            let fval2 = f(center + x)
            let fsum = fval1 + fval2

            resultKronrod += fsum * wgk[i]

            // Gauss points (even indices in 0-based correspond to odd in 1-based)
            if (i + 1) % 2 == 0 {
                resultGauss += fsum * wg[(i + 1) / 2 - 1]
            }
        }

        resultKronrod *= halfLength
        resultGauss *= halfLength

        let absError = abs(resultKronrod - resultGauss)
        return (resultKronrod, absError)
    }

    /// Adaptive quadrature using Gauss-Kronrod rule
    /// - Parameters:
    ///   - f: Function to integrate
    ///   - a: Lower limit (can be -∞)
    ///   - b: Upper limit (can be +∞)
    ///   - epsabs: Absolute tolerance
    ///   - epsrel: Relative tolerance
    ///   - limit: Maximum number of subdivisions
    /// - Returns: QuadResult with value, error, and evaluation count
    public static func quad(
        _ f: @escaping (Double) -> Double,
        _ a: Double,
        _ b: Double,
        epsabs: Double = defaultEpsAbs,
        epsrel: Double = defaultEpsRel,
        limit: Int = defaultLimit
    ) -> QuadResult {
        var actualA = a
        var actualB = b
        var fTransformed = f

        // Handle infinite limits with variable transformations
        if a == -.infinity && b == .infinity {
            // Transform: x = t / (1 - t²), t in (-1, 1)
            fTransformed = { t in
                if abs(t) >= 1 { return 0 }
                let x = t / (1 - t * t)
                let dxdt = (1 + t * t) / pow(1 - t * t, 2)
                return f(x) * dxdt
            }
            actualA = -1
            actualB = 1
        } else if a == -.infinity {
            // Transform: x = b - (1-t)/t, t in (0, 1)
            let bOrig = b
            fTransformed = { t in
                if t <= 0 { return 0 }
                let x = bOrig - (1 - t) / t
                let dxdt = 1 / (t * t)
                return f(x) * dxdt
            }
            actualA = 0
            actualB = 1
        } else if b == .infinity {
            // Transform: x = a + t/(1-t), t in (0, 1)
            let aOrig = a
            fTransformed = { t in
                if t >= 1 { return 0 }
                let x = aOrig + t / (1 - t)
                let dxdt = 1 / pow(1 - t, 2)
                return f(x) * dxdt
            }
            actualA = 0
            actualB = 1
        }

        // Stack-based adaptive integration
        var stack: [(Double, Double)] = [(actualA, actualB)]
        var totalResult: Double = 0
        var totalError: Double = 0
        var neval = 0
        var subdivisions = 0

        while !stack.isEmpty && subdivisions < limit {
            let (ia, ib) = stack.removeLast()
            let (result, absError) = gk15(fTransformed, ia, ib)
            neval += 15

            let tolerance = max(epsabs, epsrel * abs(result))

            if absError <= tolerance || (ib - ia) < 1e-15 {
                totalResult += result
                totalError += absError
            } else {
                subdivisions += 1
                let mid = 0.5 * (ia + ib)
                stack.append((ia, mid))
                stack.append((mid, ib))
            }
        }

        // Process remaining intervals if limit reached
        while !stack.isEmpty {
            let (ia, ib) = stack.removeLast()
            let (result, absError) = gk15(fTransformed, ia, ib)
            totalResult += result
            totalError += absError
            neval += 15
        }

        return QuadResult(value: totalResult, error: totalError, neval: neval)
    }

    // MARK: - Double Integration

    /// Double integration over a rectangular or non-rectangular region
    /// - Parameters:
    ///   - f: Function f(y, x) to integrate
    ///   - xa: Lower x limit
    ///   - xb: Upper x limit
    ///   - ya: Lower y limit (constant or function of x)
    ///   - yb: Upper y limit (constant or function of x)
    ///   - epsabs: Absolute tolerance
    ///   - epsrel: Relative tolerance
    /// - Returns: QuadResult with value and error
    public static func dblquad(
        _ f: @escaping (Double, Double) -> Double,
        xa: Double,
        xb: Double,
        ya: @escaping (Double) -> Double,
        yb: @escaping (Double) -> Double,
        epsabs: Double = defaultEpsAbs,
        epsrel: Double = defaultEpsRel
    ) -> QuadResult {
        let inner: (Double) -> Double = { x in
            let yLower = ya(x)
            let yUpper = yb(x)
            let result = quad({ y in f(y, x) }, yLower, yUpper, epsabs: epsabs, epsrel: epsrel)
            return result.value
        }
        return quad(inner, xa, xb, epsabs: epsabs, epsrel: epsrel)
    }

    /// Double integration over a rectangular region (constant limits)
    public static func dblquad(
        _ f: @escaping (Double, Double) -> Double,
        xa: Double,
        xb: Double,
        ya: Double,
        yb: Double,
        epsabs: Double = defaultEpsAbs,
        epsrel: Double = defaultEpsRel
    ) -> QuadResult {
        return dblquad(f, xa: xa, xb: xb, ya: { _ in ya }, yb: { _ in yb }, epsabs: epsabs, epsrel: epsrel)
    }

    // MARK: - Triple Integration

    /// Triple integration
    /// - Parameters:
    ///   - f: Function f(z, y, x) to integrate
    ///   - xa, xb: x limits
    ///   - ya, yb: y limits (functions of x)
    ///   - za, zb: z limits (functions of x, y)
    public static func tplquad(
        _ f: @escaping (Double, Double, Double) -> Double,
        xa: Double,
        xb: Double,
        ya: @escaping (Double) -> Double,
        yb: @escaping (Double) -> Double,
        za: @escaping (Double, Double) -> Double,
        zb: @escaping (Double, Double) -> Double,
        epsabs: Double = defaultEpsAbs,
        epsrel: Double = defaultEpsRel
    ) -> QuadResult {
        let innerXY: (Double, Double) -> Double = { y, x in
            let zLower = za(x, y)
            let zUpper = zb(x, y)
            let result = quad({ z in f(z, y, x) }, zLower, zUpper, epsabs: epsabs, epsrel: epsrel)
            return result.value
        }
        return dblquad(innerXY, xa: xa, xb: xb, ya: ya, yb: yb, epsabs: epsabs, epsrel: epsrel)
    }

    /// Triple integration over rectangular region (constant limits)
    public static func tplquad(
        _ f: @escaping (Double, Double, Double) -> Double,
        xa: Double, xb: Double,
        ya: Double, yb: Double,
        za: Double, zb: Double,
        epsabs: Double = defaultEpsAbs,
        epsrel: Double = defaultEpsRel
    ) -> QuadResult {
        return tplquad(f, xa: xa, xb: xb,
                       ya: { _ in ya }, yb: { _ in yb },
                       za: { _, _ in za }, zb: { _, _ in zb },
                       epsabs: epsabs, epsrel: epsrel)
    }

    // MARK: - Fixed-Order Gaussian Quadrature

    /// Fixed-order Gauss-Legendre quadrature
    /// - Parameters:
    ///   - f: Function to integrate
    ///   - a: Lower limit
    ///   - b: Upper limit
    ///   - n: Number of points (1-10)
    /// - Returns: Integral approximation
    public static func fixedQuad(_ f: (Double) -> Double, _ a: Double, _ b: Double, n: Int = 5) -> Double {
        let order = min(max(n, 1), 10)
        guard let points = gaussLegendre[order] else { return 0 }

        let center = 0.5 * (a + b)
        let halfLength = 0.5 * (b - a)
        var result: Double = 0

        for point in points {
            let x = center + halfLength * point.x
            result += point.w * f(x)
        }

        return result * halfLength
    }

    // MARK: - Romberg Integration

    /// Romberg integration using Richardson extrapolation
    /// - Parameters:
    ///   - f: Function to integrate
    ///   - a: Lower limit
    ///   - b: Upper limit
    ///   - tol: Tolerance for convergence
    ///   - divmax: Maximum number of extrapolation steps
    /// - Returns: QuadResult
    public static func romberg(
        _ f: (Double) -> Double,
        _ a: Double,
        _ b: Double,
        tol: Double = 1e-8,
        divmax: Int = 10
    ) -> QuadResult {
        var R: [[Double]] = Array(repeating: [], count: divmax + 2)
        var h = b - a

        // R[0][0] = trapezoidal rule
        R[0] = [0.5 * h * (f(a) + f(b))]

        for i in 1...(divmax) {
            h /= 2
            R[i] = []

            // Composite trapezoidal rule
            var sum: Double = 0
            let n = 1 << (i - 1)  // 2^(i-1)
            for k in 1...n {
                sum += f(a + Double(2 * k - 1) * h)
            }
            R[i].append(0.5 * R[i-1][0] + h * sum)

            // Richardson extrapolation
            for j in 1...i {
                let factor = pow(4.0, Double(j))
                let value = (factor * R[i][j-1] - R[i-1][j-1]) / (factor - 1)
                R[i].append(value)
            }

            // Check convergence
            let error = abs(R[i][i] - R[i-1][i-1])
            if error < tol {
                return QuadResult(value: R[i][i], error: error, neval: (1 << (i + 1)) - 1)
            }
        }

        let finalError = abs(R[divmax][divmax] - R[divmax-1][divmax-1])
        return QuadResult(value: R[divmax][divmax], error: finalError, neval: (1 << (divmax + 1)) - 1)
    }

    // MARK: - Simpson's Rule

    /// Simpson's rule integration from array of values
    /// - Parameters:
    ///   - y: Array of function values
    ///   - dx: Step size (default 1)
    /// - Returns: Integral approximation
    public static func simps(_ y: [Double], dx: Double = 1) -> Double {
        let n = y.count
        guard n >= 3 else { return 0 }

        var result = y[0] + y[n - 1]

        if n % 2 == 1 {
            // Odd number of points (even number of intervals)
            for i in 1..<(n - 1) {
                result += (i % 2 == 1 ? 4 : 2) * y[i]
            }
            return result * dx / 3
        } else {
            // Even number of points - use Simpson's for n-1 points, trapezoid for last
            for i in 1..<(n - 2) {
                result += (i % 2 == 1 ? 4 : 2) * y[i]
            }
            result = (y[0] + 4 * y[1] + y[2]) * dx / 3
            for i in stride(from: 2, to: n - 2, by: 2) {
                result += (y[i] + 4 * y[i + 1] + y[i + 2]) * dx / 3
            }
            // Add last interval with trapezoid if needed
            if (n - 1) % 2 == 1 {
                result += dx * (y[n - 2] + y[n - 1]) / 2
            }
            return result
        }
    }

    /// Simpson's rule integration with x values
    public static func simps(_ y: [Double], x: [Double]) -> Double {
        guard y.count == x.count && y.count >= 3 else { return 0 }
        let dx = (x[x.count - 1] - x[0]) / Double(x.count - 1)
        return simps(y, dx: dx)
    }

    // MARK: - Trapezoidal Rule

    /// Trapezoidal rule integration from array of values
    public static func trapz(_ y: [Double], dx: Double = 1) -> Double {
        guard y.count >= 2 else { return 0 }
        var result: Double = 0
        for i in 0..<(y.count - 1) {
            result += 0.5 * (y[i] + y[i + 1]) * dx
        }
        return result
    }

    /// Trapezoidal rule with non-uniform spacing
    public static func trapz(_ y: [Double], x: [Double]) -> Double {
        guard y.count == x.count && y.count >= 2 else { return 0 }
        var result: Double = 0
        for i in 0..<(y.count - 1) {
            result += 0.5 * (y[i] + y[i + 1]) * (x[i + 1] - x[i])
        }
        return result
    }

    // MARK: - ODE Solvers

    /// Single RK4 step (classical 4th order Runge-Kutta)
    private static func rk4Step(
        _ f: ([Double], Double) -> [Double],
        _ t: Double,
        _ y: [Double],
        _ h: Double
    ) -> [Double] {
        let n = y.count
        let k1 = f(y, t)

        var y2 = [Double](repeating: 0, count: n)
        for i in 0..<n { y2[i] = y[i] + 0.5 * h * k1[i] }
        let k2 = f(y2, t + 0.5 * h)

        var y3 = [Double](repeating: 0, count: n)
        for i in 0..<n { y3[i] = y[i] + 0.5 * h * k2[i] }
        let k3 = f(y3, t + 0.5 * h)

        var y4 = [Double](repeating: 0, count: n)
        for i in 0..<n { y4[i] = y[i] + h * k3[i] }
        let k4 = f(y4, t + h)

        var yNew = [Double](repeating: 0, count: n)
        for i in 0..<n {
            yNew[i] = y[i] + (h / 6) * (k1[i] + 2*k2[i] + 2*k3[i] + k4[i])
        }
        return yNew
    }

    /// Single Dormand-Prince RK45 step
    private static func rk45Step(
        _ f: ([Double], Double) -> [Double],
        _ t: Double,
        _ y: [Double],
        _ h: Double
    ) -> (yNew: [Double], error: [Double]) {
        let n = y.count
        var k: [[Double]] = []

        k.append(f(y, t))

        for stage in 1..<7 {
            var yStage = [Double](repeating: 0, count: n)
            for i in 0..<n {
                var sum = y[i]
                for j in 0..<stage {
                    if j < dpA[stage].count {
                        sum += h * dpA[stage][j] * k[j][i]
                    }
                }
                yStage[i] = sum
            }
            k.append(f(yStage, t + dpC[stage] * h))
        }

        // Compute 5th order solution
        var yNew = [Double](repeating: 0, count: n)
        for i in 0..<n {
            var sum = y[i]
            for j in 0..<7 {
                sum += h * dpB[j] * k[j][i]
            }
            yNew[i] = sum
        }

        // Compute error estimate
        var err = [Double](repeating: 0, count: n)
        for i in 0..<n {
            var sum: Double = 0
            for j in 0..<7 {
                sum += h * dpE[j] * k[j][i]
            }
            err[i] = sum
        }

        return (yNew, err)
    }

    /// Single Bogacki-Shampine RK23 step
    private static func rk23Step(
        _ f: ([Double], Double) -> [Double],
        _ t: Double,
        _ y: [Double],
        _ h: Double
    ) -> (yNew: [Double], error: [Double]) {
        let n = y.count
        var k: [[Double]] = []

        k.append(f(y, t))

        for stage in 1..<4 {
            var yStage = [Double](repeating: 0, count: n)
            for i in 0..<n {
                var sum = y[i]
                for j in 0..<stage {
                    if j < bsA[stage].count {
                        sum += h * bsA[stage][j] * k[j][i]
                    }
                }
                yStage[i] = sum
            }
            k.append(f(yStage, t + bsC[stage] * h))
        }

        // 3rd order solution
        var yNew = [Double](repeating: 0, count: n)
        for i in 0..<n {
            var sum = y[i]
            for j in 0..<4 {
                sum += h * bsB[j] * k[j][i]
            }
            yNew[i] = sum
        }

        // Error estimate
        var err = [Double](repeating: 0, count: n)
        for i in 0..<n {
            var sum: Double = 0
            for j in 0..<4 {
                sum += h * bsE[j] * k[j][i]
            }
            err[i] = sum
        }

        return (yNew, err)
    }

    /// Solve initial value problem for ODE system
    /// - Parameters:
    ///   - fun: Function(t, y) returning dy/dt
    ///   - tSpan: (t0, tf) initial and final time
    ///   - y0: Initial state
    ///   - method: "RK45", "RK23", or "RK4"
    ///   - tEval: Optional specific times for output
    ///   - maxStep: Maximum step size
    ///   - rtol: Relative tolerance
    ///   - atol: Absolute tolerance
    ///   - firstStep: Initial step size (nil for auto)
    /// - Returns: ODEResult
    public static func solveIVP(
        _ fun: @escaping ([Double], Double) -> [Double],
        tSpan: (Double, Double),
        y0: [Double],
        method: String = "RK45",
        tEval: [Double]? = nil,
        maxStep: Double = .infinity,
        rtol: Double = 1e-3,
        atol: Double = 1e-6,
        firstStep: Double? = nil
    ) -> ODEResult {
        let t0 = tSpan.0
        let tf = tSpan.1
        let direction: Double = tf >= t0 ? 1 : -1
        let n = y0.count

        var t = t0
        var y = y0
        var tList = [t0]
        var yList = [y0]
        var nfev = 0

        // Initial step size estimation
        var h: Double
        if let first = firstStep {
            h = first
        } else {
            let f0 = fun(y0, t0)
            nfev += 1
            let d0 = max(y0.map { abs($0) }.max() ?? 1, 1e-5)
            let d1 = max(f0.map { abs($0) }.max() ?? 1, 1e-5)
            h = 0.01 * d0 / d1
            h = min(h, abs(tf - t0) / 10)
        }
        h = direction * min(abs(h), maxStep)

        let maxIter = 10000
        var iter = 0

        while direction * (tf - t) > 1e-12 * abs(tf) && iter < maxIter {
            iter += 1

            // Don't overshoot tf
            if direction * (t + h - tf) > 0 {
                h = tf - t
            }

            if method == "RK4" {
                y = rk4Step(fun, t, y, h)
                nfev += 4
                t += h
                tList.append(t)
                yList.append(y)
            } else {
                let (yNew, err) = method == "RK23"
                    ? rk23Step(fun, t, y, h)
                    : rk45Step(fun, t, y, h)
                nfev += method == "RK23" ? 4 : 7

                // Error control
                var errNorm: Double = 0
                for i in 0..<n {
                    let scale = atol + rtol * max(abs(y[i]), abs(yNew[i]))
                    errNorm += pow(err[i] / scale, 2)
                }
                errNorm = sqrt(errNorm / Double(n))

                if errNorm <= 1 {
                    t += h
                    y = yNew
                    tList.append(t)
                    yList.append(y)

                    // Increase step size
                    if errNorm > 0 {
                        let factor = min(5, 0.9 * pow(1 / errNorm, 0.2))
                        h = direction * min(abs(h * factor), maxStep)
                    } else {
                        h = direction * min(abs(h * 5), maxStep)
                    }
                } else {
                    // Reject step, decrease step size
                    let factor = max(0.1, 0.9 * pow(1 / errNorm, 0.25))
                    h *= factor
                }
            }
        }

        // Interpolate to tEval if specified
        var resultT: [Double]
        var resultY: [[Double]]

        if let evalTimes = tEval {
            resultT = evalTimes
            resultY = []
            for tE in evalTimes {
                // Find bracketing interval
                var idx = 0
                for j in 0..<(tList.count - 1) {
                    if (tList[j] <= tE && tE <= tList[j + 1]) ||
                       (tList[j] >= tE && tE >= tList[j + 1]) {
                        idx = j
                        break
                    }
                }

                // Linear interpolation
                let t1 = tList[idx]
                let t2 = tList[min(idx + 1, tList.count - 1)]
                let frac = abs(t2 - t1) > 1e-15 ? (tE - t1) / (t2 - t1) : 0

                var yInterp = [Double](repeating: 0, count: n)
                for i in 0..<n {
                    yInterp[i] = yList[idx][i] + frac * (yList[min(idx + 1, yList.count - 1)][i] - yList[idx][i])
                }
                resultY.append(yInterp)
            }
        } else {
            resultT = tList
            resultY = yList
        }

        let success = direction * (tf - t) <= 1e-12 * abs(tf)

        return ODEResult(
            t: resultT,
            y: resultY,
            success: success,
            message: success ? "Integration successful" : "Max iterations reached",
            nfev: nfev
        )
    }

    /// odeint-style ODE integration (scipy.integrate.odeint compatible)
    /// - Parameters:
    ///   - func_: Function(y, t) returning dy/dt (note: y first, then t)
    ///   - y0: Initial state
    ///   - t: Array of times at which to compute solution
    ///   - rtol: Relative tolerance
    ///   - atol: Absolute tolerance
    /// - Returns: Array of solutions y[time_index][component_index]
    public static func odeint(
        _ func_: @escaping ([Double], Double) -> [Double],
        y0: [Double],
        t: [Double],
        rtol: Double = 1.49e-8,
        atol: Double = 1.49e-8
    ) -> [[Double]] {
        guard t.count >= 2 else { return [y0] }

        var result: [[Double]] = [y0]
        var currentY = y0

        for j in 0..<(t.count - 1) {
            let sol = solveIVP(
                { y, tVal in func_(y, tVal) },
                tSpan: (t[j], t[j + 1]),
                y0: currentY,
                method: "RK45",
                rtol: rtol,
                atol: atol
            )
            currentY = sol.y.last ?? currentY
            result.append(currentY)
        }

        return result
    }

    // MARK: - Registration

    /// Register the integration module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks - use closures that capture the engine
        engine.registerFunction(name: "_luaswift_integrate_quad", callback: makeQuadCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_dblquad", callback: makeDblquadCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_tplquad", callback: makeTplquadCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_fixed_quad", callback: makeFixedQuadCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_romberg", callback: makeRombergCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_simps", callback: simpsCallback)
        engine.registerFunction(name: "_luaswift_integrate_trapz", callback: trapzCallback)
        engine.registerFunction(name: "_luaswift_integrate_solve_ivp", callback: makeSolveIVPCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_odeint", callback: makeOdeintCallback(engine))

        // Set up Lua namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.integrate then luaswift.integrate = {} end

                local integrate = luaswift.integrate

                -- quad: Adaptive quadrature
                -- Returns: value, error (scipy-style)
                function integrate.quad(f, a, b, options)
                    options = options or {}
                    local result = _luaswift_integrate_quad(f, a, b,
                        options.epsabs or 1.49e-8,
                        options.epsrel or 1.49e-8,
                        options.limit or 50)
                    return result.value, result.error
                end

                -- dblquad: Double integration
                -- Returns: value, error (scipy-style)
                function integrate.dblquad(f, xa, xb, ya, yb, options)
                    options = options or {}
                    local result = _luaswift_integrate_dblquad(f, xa, xb, ya, yb,
                        options.epsabs or 1.49e-8,
                        options.epsrel or 1.49e-8)
                    return result.value, result.error
                end

                -- tplquad: Triple integration
                -- Returns: value, error (scipy-style)
                function integrate.tplquad(f, xa, xb, ya, yb, za, zb, options)
                    options = options or {}
                    local result = _luaswift_integrate_tplquad(f, xa, xb, ya, yb, za, zb,
                        options.epsabs or 1.49e-8,
                        options.epsrel or 1.49e-8)
                    return result.value, result.error
                end

                -- fixed_quad: Fixed-order Gauss quadrature
                -- Returns: single value (scipy-style)
                function integrate.fixed_quad(f, a, b, n)
                    return _luaswift_integrate_fixed_quad(f, a, b, n or 5)
                end

                -- romberg: Romberg integration
                -- Returns: value, error (scipy-style)
                function integrate.romberg(f, a, b, options)
                    options = options or {}
                    local result = _luaswift_integrate_romberg(f, a, b,
                        options.tol or 1e-8,
                        options.divmax or 10)
                    return result.value, result.error
                end

                -- simps: Simpson's rule
                function integrate.simps(y, x, dx)
                    return _luaswift_integrate_simps(y, x, dx)
                end

                -- trapz: Trapezoidal rule
                function integrate.trapz(y, x, dx)
                    return _luaswift_integrate_trapz(y, x, dx)
                end

                -- solve_ivp: ODE solver
                function integrate.solve_ivp(fun, t_span, y0, options)
                    options = options or {}
                    return _luaswift_integrate_solve_ivp(fun, t_span, y0,
                        options.method or "RK45",
                        options.t_eval,
                        options.max_step or math.huge,
                        options.rtol or 1e-3,
                        options.atol or 1e-6,
                        options.first_step)
                end

                -- odeint: scipy-style ODE solver
                function integrate.odeint(func, y0, t, options)
                    options = options or {}
                    return _luaswift_integrate_odeint(func, y0, t,
                        options.rtol or 1.49e-8,
                        options.atol or 1.49e-8)
                end

                -- Also update math.integrate if it exists
                if math then
                    if not math.integrate then math.integrate = {} end
                    for k, v in pairs(integrate) do
                        math.integrate[k] = v
                    end
                end
                """)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Lua Callbacks

    /// Helper to create a Swift closure from a Lua function reference
    private static func makeLuaFunction(_ engine: LuaEngine, _ funcRef: Int32) -> (Double) -> Double {
        return { x in
            do {
                let result = try engine.callLuaFunction(ref: funcRef, args: [.number(x)])
                return result.numberValue ?? 0
            } catch {
                return 0
            }
        }
    }

    /// Factory function for quad callback
    private static func makeQuadCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let a = args[1].numberValue,
                  let b = args[2].numberValue else {
                throw LuaError.runtimeError("quad: expected function, lower, upper")
            }

            let epsabs = args.count > 3 ? args[3].numberValue ?? defaultEpsAbs : defaultEpsAbs
            let epsrel = args.count > 4 ? args[4].numberValue ?? defaultEpsRel : defaultEpsRel
            let limit = args.count > 5 ? Int(args[5].numberValue ?? Double(defaultLimit)) : defaultLimit

            let f = makeLuaFunction(engine, funcRef)
            let result = quad(f, a, b, epsabs: epsabs, epsrel: epsrel, limit: limit)

            return .table([
                "value": .number(result.value),
                "error": .number(result.error),
                "neval": .number(Double(result.neval))
            ])
        }
    }

    /// Factory function for dblquad callback
    private static func makeDblquadCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 5,
                  case .luaFunction(let funcRef) = args[0],
                  let xa = args[1].numberValue,
                  let xb = args[2].numberValue else {
                throw LuaError.runtimeError("dblquad: expected function, xa, xb, ya, yb")
            }

            let epsabs = args.count > 5 ? args[5].numberValue ?? defaultEpsAbs : defaultEpsAbs
            let epsrel = args.count > 6 ? args[6].numberValue ?? defaultEpsRel : defaultEpsRel

            // ya and yb can be numbers or functions
            let yaFunc: (Double) -> Double
            let ybFunc: (Double) -> Double

            if let yaNum = args[3].numberValue {
                yaFunc = { _ in yaNum }
            } else if case .luaFunction(let ref) = args[3] {
                yaFunc = makeLuaFunction(engine, ref)
            } else {
                throw LuaError.runtimeError("dblquad: ya must be number or function")
            }

            if let ybNum = args[4].numberValue {
                ybFunc = { _ in ybNum }
            } else if case .luaFunction(let ref) = args[4] {
                ybFunc = makeLuaFunction(engine, ref)
            } else {
                throw LuaError.runtimeError("dblquad: yb must be number or function")
            }

            let f: (Double, Double) -> Double = { y, x in
                do {
                    let result = try engine.callLuaFunction(ref: funcRef, args: [.number(y), .number(x)])
                    return result.numberValue ?? 0
                } catch {
                    return 0
                }
            }

            let result = dblquad(f, xa: xa, xb: xb, ya: yaFunc, yb: ybFunc, epsabs: epsabs, epsrel: epsrel)

            return .table([
                "value": .number(result.value),
                "error": .number(result.error),
                "neval": .number(Double(result.neval))
            ])
        }
    }

    /// Factory function for tplquad callback
    private static func makeTplquadCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 7,
                  case .luaFunction(let funcRef) = args[0],
                  let xa = args[1].numberValue,
                  let xb = args[2].numberValue else {
                throw LuaError.runtimeError("tplquad: expected function, xa, xb, ya, yb, za, zb")
            }

            let epsabs = args.count > 7 ? args[7].numberValue ?? defaultEpsAbs : defaultEpsAbs
            let epsrel = args.count > 8 ? args[8].numberValue ?? defaultEpsRel : defaultEpsRel

            // Parse ya, yb (functions of x or constants)
            let yaFunc: (Double) -> Double
            let ybFunc: (Double) -> Double

            if let yaNum = args[3].numberValue {
                yaFunc = { _ in yaNum }
            } else if case .luaFunction(let ref) = args[3] {
                yaFunc = makeLuaFunction(engine, ref)
            } else {
                throw LuaError.runtimeError("tplquad: ya must be number or function")
            }

            if let ybNum = args[4].numberValue {
                ybFunc = { _ in ybNum }
            } else if case .luaFunction(let ref) = args[4] {
                ybFunc = makeLuaFunction(engine, ref)
            } else {
                throw LuaError.runtimeError("tplquad: yb must be number or function")
            }

            // Parse za, zb (functions of x,y or constants)
            let zaFunc: (Double, Double) -> Double
            let zbFunc: (Double, Double) -> Double

            if let zaNum = args[5].numberValue {
                zaFunc = { _, _ in zaNum }
            } else if case .luaFunction(let ref) = args[5] {
                zaFunc = { x, y in
                    do {
                        let result = try engine.callLuaFunction(ref: ref, args: [.number(x), .number(y)])
                        return result.numberValue ?? 0
                    } catch {
                        return 0
                    }
                }
            } else {
                throw LuaError.runtimeError("tplquad: za must be number or function")
            }

            if let zbNum = args[6].numberValue {
                zbFunc = { _, _ in zbNum }
            } else if case .luaFunction(let ref) = args[6] {
                zbFunc = { x, y in
                    do {
                        let result = try engine.callLuaFunction(ref: ref, args: [.number(x), .number(y)])
                        return result.numberValue ?? 0
                    } catch {
                        return 0
                    }
                }
            } else {
                throw LuaError.runtimeError("tplquad: zb must be number or function")
            }

            let f: (Double, Double, Double) -> Double = { z, y, x in
                do {
                    let result = try engine.callLuaFunction(ref: funcRef, args: [.number(z), .number(y), .number(x)])
                    return result.numberValue ?? 0
                } catch {
                    return 0
                }
            }

            let result = tplquad(f, xa: xa, xb: xb, ya: yaFunc, yb: ybFunc, za: zaFunc, zb: zbFunc, epsabs: epsabs, epsrel: epsrel)

            return .table([
                "value": .number(result.value),
                "error": .number(result.error),
                "neval": .number(Double(result.neval))
            ])
        }
    }

    /// Factory function for fixed_quad callback
    private static func makeFixedQuadCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let a = args[1].numberValue,
                  let b = args[2].numberValue else {
                throw LuaError.runtimeError("fixed_quad: expected function, a, b")
            }

            let n = args.count > 3 ? Int(args[3].numberValue ?? 5) : 5

            let f = makeLuaFunction(engine, funcRef)
            let result = fixedQuad(f, a, b, n: n)

            return .number(result)
        }
    }

    /// Factory function for romberg callback
    private static func makeRombergCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let a = args[1].numberValue,
                  let b = args[2].numberValue else {
                throw LuaError.runtimeError("romberg: expected function, a, b")
            }

            let tol = args.count > 3 ? args[3].numberValue ?? 1e-8 : 1e-8
            let divmax = args.count > 4 ? Int(args[4].numberValue ?? 10) : 10

            let f = makeLuaFunction(engine, funcRef)
            let result = romberg(f, a, b, tol: tol, divmax: divmax)

            return .table([
                "value": .number(result.value),
                "error": .number(result.error),
                "neval": .number(Double(result.neval))
            ])
        }
    }

    /// Static callback for simps (doesn't need engine - no Lua functions)
    private static func simpsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1,
              let yTable = args[0].arrayValue else {
            throw LuaError.runtimeError("simps: expected array of values")
        }

        let y = yTable.compactMap { $0.numberValue }
        guard y.count >= 3 else {
            throw LuaError.runtimeError("simps: need at least 3 points")
        }

        if args.count > 1, let xTable = args[1].arrayValue {
            let x = xTable.compactMap { $0.numberValue }
            return .number(simps(y, x: x))
        } else {
            let dx = args.count > 2 ? args[2].numberValue ?? 1 : 1
            return .number(simps(y, dx: dx))
        }
    }

    /// Static callback for trapz (doesn't need engine - no Lua functions)
    private static func trapzCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1,
              let yTable = args[0].arrayValue else {
            throw LuaError.runtimeError("trapz: expected array of values")
        }

        let y = yTable.compactMap { $0.numberValue }
        guard y.count >= 2 else {
            throw LuaError.runtimeError("trapz: need at least 2 points")
        }

        if args.count > 1, let xTable = args[1].arrayValue {
            let x = xTable.compactMap { $0.numberValue }
            return .number(trapz(y, x: x))
        } else {
            let dx = args.count > 2 ? args[2].numberValue ?? 1 : 1
            return .number(trapz(y, dx: dx))
        }
    }

    /// Factory function for solve_ivp callback
    private static func makeSolveIVPCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let tSpanTable = args[1].arrayValue,
                  tSpanTable.count >= 2,
                  let t0 = tSpanTable[0].numberValue,
                  let tf = tSpanTable[1].numberValue,
                  let y0Table = args[2].arrayValue else {
                throw LuaError.runtimeError("solve_ivp: expected function, t_span, y0")
            }

            let y0 = y0Table.compactMap { $0.numberValue }
            guard !y0.isEmpty else {
                throw LuaError.runtimeError("solve_ivp: y0 must be non-empty array")
            }

            let method = args.count > 3 ? args[3].stringValue ?? "RK45" : "RK45"
            let tEval: [Double]? = args.count > 4 ? args[4].arrayValue?.compactMap { $0.numberValue } : nil
            let maxStep = args.count > 5 ? args[5].numberValue ?? .infinity : .infinity
            let rtol = args.count > 6 ? args[6].numberValue ?? 1e-3 : 1e-3
            let atol = args.count > 7 ? args[7].numberValue ?? 1e-6 : 1e-6
            let firstStep: Double? = args.count > 8 ? args[8].numberValue : nil

            let f: ([Double], Double) -> [Double] = { y, t in
                do {
                    let yLua = LuaValue.array(y.map { .number($0) })
                    let result = try engine.callLuaFunction(ref: funcRef, args: [.number(t), yLua])
                    if let arr = result.arrayValue {
                        return arr.compactMap { $0.numberValue }
                    }
                    return y
                } catch {
                    return y
                }
            }

            let result = solveIVP(f, tSpan: (t0, tf), y0: y0, method: method, tEval: tEval,
                                  maxStep: maxStep, rtol: rtol, atol: atol, firstStep: firstStep)

            return .table([
                "t": .array(result.t.map { .number($0) }),
                "y": .array(result.y.map { row in .array(row.map { .number($0) }) }),
                "success": .bool(result.success),
                "message": .string(result.message),
                "nfev": .number(Double(result.nfev))
            ])
        }
    }

    /// Factory function for odeint callback
    private static func makeOdeintCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let y0Table = args[1].arrayValue,
                  let tTable = args[2].arrayValue else {
                throw LuaError.runtimeError("odeint: expected function, y0, t")
            }

            let y0 = y0Table.compactMap { $0.numberValue }
            let t = tTable.compactMap { $0.numberValue }

            guard !y0.isEmpty && t.count >= 2 else {
                throw LuaError.runtimeError("odeint: y0 must be non-empty, t must have at least 2 points")
            }

            let rtol = args.count > 3 ? args[3].numberValue ?? 1.49e-8 : 1.49e-8
            let atol = args.count > 4 ? args[4].numberValue ?? 1.49e-8 : 1.49e-8

            // odeint uses func(y, t) not func(t, y)
            let f: ([Double], Double) -> [Double] = { y, tVal in
                do {
                    let yLua = LuaValue.array(y.map { .number($0) })
                    let result = try engine.callLuaFunction(ref: funcRef, args: [yLua, .number(tVal)])
                    if let arr = result.arrayValue {
                        return arr.compactMap { $0.numberValue }
                    }
                    return y
                } catch {
                    return y
                }
            }

            let result = odeint(f, y0: y0, t: t, rtol: rtol, atol: atol)

            return .array(result.map { row in .array(row.map { .number($0) }) })
        }
    }
}
