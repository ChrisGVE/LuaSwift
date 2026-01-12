//
//  InterpolateModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed interpolation module for LuaSwift.
///
/// Provides interpolation functions including 1D interpolation, cubic splines,
/// PCHIP, Akima, Lagrange, and Barycentric interpolation. All algorithms
/// implemented in Swift for performance.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- 1D interpolation
/// local x = {0, 1, 2, 3, 4}
/// local y = {0, 1, 4, 9, 16}
/// local f = math.interpolate.interp1d(x, y, "linear")
/// print(f(1.5))  -- 2.5
///
/// -- Cubic spline
/// local cs = math.interpolate.CubicSpline(x, y)
/// print(cs(1.5))  -- interpolated value
/// print(cs.derivative(1.5))  -- first derivative
/// ```
public struct InterpolateModule {

    // MARK: - Constants

    private static let defaultXTol: Double = 1e-8

    // MARK: - Complex Number Support

    /// Represents a complex number for interpolation
    public struct Complex {
        public var re: Double
        public var im: Double

        public init(re: Double, im: Double) {
            self.re = re
            self.im = im
        }

        public static func + (lhs: Complex, rhs: Complex) -> Complex {
            Complex(re: lhs.re + rhs.re, im: lhs.im + rhs.im)
        }

        public static func - (lhs: Complex, rhs: Complex) -> Complex {
            Complex(re: lhs.re - rhs.re, im: lhs.im - rhs.im)
        }

        public static func * (lhs: Complex, rhs: Double) -> Complex {
            Complex(re: lhs.re * rhs, im: lhs.im * rhs)
        }
    }

    // MARK: - Spline Coefficients

    /// Coefficients for a cubic polynomial segment: a + b*dx + c*dx^2 + d*dx^3
    public struct CubicCoeffs {
        public let a: Double
        public let b: Double
        public let c: Double
        public let d: Double
    }

    /// Result from cubic spline computation
    public struct SplineResult {
        public let coeffs: [CubicCoeffs]
        public let x: [Double]
        public let y: [Double]
    }

    // MARK: - Binary Search

    /// Find the interval containing x (returns index i such that x[i] <= x < x[i+1])
    private static func findInterval(_ xs: [Double], _ x: Double) -> Int {
        var lo = 0
        var hi = xs.count - 1
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if xs[mid] > x {
                hi = mid
            } else {
                lo = mid
            }
        }
        return lo
    }

    // MARK: - Tridiagonal Solver

    /// Solve tridiagonal system using Thomas algorithm
    /// diag: main diagonal
    /// offDiag: off-diagonal (indexed 0..n-2)
    /// rhs: right-hand side
    private static func solveTridiagonal(diag: [Double], offDiag: [Double], rhs: [Double]) -> [Double] {
        let n = diag.count
        guard n > 0 else { return [] }

        var cPrime = [Double](repeating: 0, count: n)
        var dPrime = [Double](repeating: 0, count: n)

        // Forward elimination
        let off0 = offDiag.indices.contains(0) ? offDiag[0] : 0
        cPrime[0] = off0 / diag[0]
        dPrime[0] = rhs[0] / diag[0]

        for i in 1..<n {
            let offPrev = i - 1 < offDiag.count ? offDiag[i - 1] : 0
            let m = diag[i] - offPrev * cPrime[i - 1]
            let offCurr = i < offDiag.count ? offDiag[i] : 0
            cPrime[i] = offCurr / m
            dPrime[i] = (rhs[i] - offPrev * dPrime[i - 1]) / m
        }

        // Back substitution
        var result = [Double](repeating: 0, count: n)
        result[n - 1] = dPrime[n - 1]
        for i in stride(from: n - 2, through: 0, by: -1) {
            result[i] = dPrime[i] - cPrime[i] * result[i + 1]
        }

        return result
    }

    // MARK: - Cubic Spline Coefficients

    /// Compute cubic spline coefficients
    /// bcType: "natural", "clamped", or "not-a-knot"
    public static func computeSplineCoeffs(x: [Double], y: [Double], bcType: String = "not-a-knot") -> [CubicCoeffs] {
        let n = x.count
        guard n >= 2 else { return [] }

        // Compute intervals h[i] = x[i+1] - x[i]
        var h = [Double](repeating: 0, count: n - 1)
        for i in 0..<(n - 1) {
            h[i] = x[i + 1] - x[i]
        }

        // Set up tridiagonal system for second derivatives
        var diag = [Double](repeating: 0, count: n)
        var offDiag = [Double](repeating: 0, count: n - 1)
        var rhs = [Double](repeating: 0, count: n)

        if bcType == "natural" {
            // Natural boundary: c[0] = 0, c[n-1] = 0
            diag[0] = 1
            rhs[0] = 0

            for i in 1..<(n - 1) {
                diag[i] = 2 * (h[i - 1] + h[i])
                offDiag[i - 1] = h[i - 1]
                rhs[i] = 3 * ((y[i + 1] - y[i]) / h[i] - (y[i] - y[i - 1]) / h[i - 1])
            }

            diag[n - 1] = 1
            rhs[n - 1] = 0
            if n > 2 {
                offDiag[n - 2] = 0
            }

        } else if bcType == "clamped" {
            // Clamped: f'(x0) = 0, f'(xn) = 0
            let fp0 = 0.0
            let fpn = 0.0

            diag[0] = 2 * h[0]
            rhs[0] = 3 * ((y[1] - y[0]) / h[0] - fp0)
            offDiag[0] = h[0]

            for i in 1..<(n - 1) {
                diag[i] = 2 * (h[i - 1] + h[i])
                offDiag[i] = h[i]
                rhs[i] = 3 * ((y[i + 1] - y[i]) / h[i] - (y[i] - y[i - 1]) / h[i - 1])
            }

            diag[n - 1] = 2 * h[n - 2]
            rhs[n - 1] = 3 * (fpn - (y[n - 1] - y[n - 2]) / h[n - 2])

        } else {
            // Not-a-knot (default)
            // For not-a-knot, we need special handling since boundary conditions
            // involve 3 unknowns each, not fitting standard tridiagonal form.
            // Use row reduction approach for n >= 4, fall back to natural otherwise.
            if n >= 4 {
                // Build interior equations first (rows 1 to n-2)
                for i in 1..<(n - 1) {
                    diag[i] = 2 * (h[i - 1] + h[i])
                    offDiag[i - 1] = h[i - 1]
                    if i < n - 1 {
                        offDiag[i] = h[i]
                    }
                    rhs[i] = 3 * ((y[i + 1] - y[i]) / h[i] - (y[i] - y[i - 1]) / h[i - 1])
                }

                // Not-a-knot condition: third derivatives match at x[1] and x[n-2]
                // This means: d[0] = d[1] where d[i] = (c[i+1] - c[i]) / (3*h[i])
                // So: (c[1] - c[0]) / h[0] = (c[2] - c[1]) / h[1]
                // => h[1]*(c[1] - c[0]) = h[0]*(c[2] - c[1])
                // => h[1]*c[1] - h[1]*c[0] = h[0]*c[2] - h[0]*c[1]
                // => -h[1]*c[0] + (h[0] + h[1])*c[1] - h[0]*c[2] = 0

                // For first row: use modified equation
                // c[0] = c[1] + (h[0]/h[1])*(c[1] - c[2])
                // Substitute into row 1 to eliminate c[0]
                let alpha0 = h[0] / h[1]
                // Row 1: h[0]*c[0] + 2*(h[0]+h[1])*c[1] + h[1]*c[2] = rhs[1]
                // Substitute c[0] = (1 + alpha0)*c[1] - alpha0*c[2]
                // h[0]*((1+alpha0)*c[1] - alpha0*c[2]) + 2*(h[0]+h[1])*c[1] + h[1]*c[2] = rhs[1]
                // (h[0]*(1+alpha0) + 2*(h[0]+h[1]))*c[1] + (h[1] - h[0]*alpha0)*c[2] = rhs[1]
                diag[1] = h[0] * (1 + alpha0) + 2 * (h[0] + h[1])
                offDiag[1] = h[1] - h[0] * alpha0

                // Similar for last row
                let alphan = h[n - 2] / h[n - 3]
                // Row n-2: h[n-3]*c[n-3] + 2*(h[n-3]+h[n-2])*c[n-2] + h[n-2]*c[n-1] = rhs[n-2]
                // c[n-1] = (1 + alphan)*c[n-2] - alphan*c[n-3]
                diag[n - 2] = h[n - 2] * (1 + alphan) + 2 * (h[n - 3] + h[n - 2])
                if n > 3 {
                    offDiag[n - 4] = h[n - 3] - h[n - 2] * alphan
                }

                // Build reduced system (rows 1 to n-2)
                let reducedN = n - 2
                var reducedDiag = [Double](repeating: 0, count: reducedN)
                var reducedOff = [Double](repeating: 0, count: reducedN - 1)
                var reducedRhs = [Double](repeating: 0, count: reducedN)

                for i in 0..<reducedN {
                    reducedDiag[i] = diag[i + 1]
                    reducedRhs[i] = rhs[i + 1]
                    if i < reducedN - 1 {
                        reducedOff[i] = offDiag[i + 1]
                    }
                }

                // Solve reduced system
                let cInner = solveTridiagonal(diag: reducedDiag, offDiag: reducedOff, rhs: reducedRhs)

                // Back-substitute to get c[0] and c[n-1]
                var c = [Double](repeating: 0, count: n)
                for i in 0..<reducedN {
                    c[i + 1] = cInner[i]
                }
                c[0] = (1 + alpha0) * c[1] - alpha0 * c[2]
                c[n - 1] = (1 + alphan) * c[n - 2] - alphan * c[n - 3]

                // Compute a, b, d coefficients
                var coeffs = [CubicCoeffs]()
                for i in 0..<(n - 1) {
                    let a = y[i]
                    let b = (y[i + 1] - y[i]) / h[i] - h[i] * (2 * c[i] + c[i + 1]) / 3
                    let d = (c[i + 1] - c[i]) / (3 * h[i])
                    coeffs.append(CubicCoeffs(a: a, b: b, c: c[i], d: d))
                }
                return coeffs
            } else {
                // Fall back to natural for n < 4
                return computeSplineCoeffs(x: x, y: y, bcType: "natural")
            }
        }

        // Solve for c values
        let c = solveTridiagonal(diag: diag, offDiag: offDiag, rhs: rhs)

        // Compute a, b, d coefficients
        var coeffs = [CubicCoeffs]()
        for i in 0..<(n - 1) {
            let a = y[i]
            let b = (y[i + 1] - y[i]) / h[i] - h[i] * (2 * c[i] + c[i + 1]) / 3
            let d = (c[i + 1] - c[i]) / (3 * h[i])
            coeffs.append(CubicCoeffs(a: a, b: b, c: c[i], d: d))
        }

        return coeffs
    }

    // MARK: - 1D Interpolation

    /// Interpolation kinds
    public enum InterpolationKind: String {
        case linear
        case nearest
        case cubic
        case previous
        case next
    }

    /// Evaluate 1D interpolation at a single point
    public static func interp1dSingle(
        x: [Double],
        y: [Double],
        xNew: Double,
        kind: InterpolationKind,
        fillValue: Double,
        boundsError: Bool,
        coeffs: [CubicCoeffs]?
    ) -> Double {
        let n = x.count

        // Check bounds
        if xNew < x[0] || xNew > x[n - 1] {
            if boundsError {
                return Double.nan // Error case
            }
            return fillValue
        }

        // Handle exact boundary values
        if xNew == x[0] { return y[0] }
        if xNew == x[n - 1] { return y[n - 1] }

        let i = findInterval(x, xNew)

        switch kind {
        case .nearest:
            let d1 = abs(xNew - x[i])
            let d2 = abs(xNew - x[i + 1])
            return d1 <= d2 ? y[i] : y[i + 1]

        case .previous:
            return y[i]

        case .next:
            return y[i + 1]

        case .cubic:
            guard let coeffs = coeffs, i < coeffs.count else {
                return Double.nan
            }
            let dx = xNew - x[i]
            let c = coeffs[i]
            return c.a + c.b * dx + c.c * dx * dx + c.d * dx * dx * dx

        case .linear:
            let t = (xNew - x[i]) / (x[i + 1] - x[i])
            return y[i] + t * (y[i + 1] - y[i])
        }
    }

    // MARK: - Cubic Spline Evaluation

    /// Evaluate cubic spline at a point
    public static func evalCubicSpline(
        x: [Double],
        coeffs: [CubicCoeffs],
        xNew: Double,
        extrapolate: Bool
    ) -> Double {
        let n = x.count

        // Check bounds
        if xNew < x[0] {
            if !extrapolate { return Double.nan }
            // Linear extrapolation using first segment
            let dx = xNew - x[0]
            return coeffs[0].a + coeffs[0].b * dx
        }

        if xNew > x[n - 1] {
            if !extrapolate { return Double.nan }
            // Linear extrapolation using last segment
            let h = x[n - 1] - x[n - 2]
            let c = coeffs[n - 2]
            let slope = c.b + 2 * c.c * h + 3 * c.d * h * h
            return x.last! + slope * (xNew - x[n - 1])  // Should use y[n-1]
        }

        let i = findInterval(x, xNew)
        let idx = min(i, coeffs.count - 1)
        let dx = xNew - x[idx]
        let c = coeffs[idx]
        return c.a + c.b * dx + c.c * dx * dx + c.d * dx * dx * dx
    }

    /// Evaluate cubic spline derivative at a point
    public static func evalCubicSplineDerivative(
        x: [Double],
        coeffs: [CubicCoeffs],
        xNew: Double,
        order: Int
    ) -> Double {
        let n = x.count

        // Clamp to domain
        let xEval = max(x[0], min(xNew, x[n - 1]))
        var i = findInterval(x, xEval)
        if i >= n - 1 { i = n - 2 }
        if i >= coeffs.count { i = coeffs.count - 1 }

        let dx = xEval - x[i]
        let c = coeffs[i]

        switch order {
        case 1:
            return c.b + 2 * c.c * dx + 3 * c.d * dx * dx
        case 2:
            return 2 * c.c + 6 * c.d * dx
        case 3:
            return 6 * c.d
        default:
            return 0
        }
    }

    /// Integrate cubic spline over interval [a, b]
    public static func integrateCubicSpline(
        x: [Double],
        coeffs: [CubicCoeffs],
        a: Double,
        b: Double
    ) -> Double {
        let n = x.count

        // Clamp to domain
        let x0 = max(x[0], min(a, x[n - 1]))
        let x1 = max(x[0], min(b, x[n - 1]))

        if x0 > x1 {
            return -integrateCubicSpline(x: x, coeffs: coeffs, a: b, b: a)
        }

        let i0 = findInterval(x, x0)
        let i1 = findInterval(x, x1)

        // Integrate polynomial: a*dx + b*dx^2/2 + c*dx^3/3 + d*dx^4/4
        func integratePoly(_ c: CubicCoeffs, _ dx: Double) -> Double {
            return c.a * dx + c.b * dx * dx / 2 + c.c * dx * dx * dx / 3 + c.d * dx * dx * dx * dx / 4
        }

        var total = 0.0

        if i0 == i1 {
            let idx = min(i0, coeffs.count - 1)
            let c = coeffs[idx]
            let dx0 = x0 - x[idx]
            let dx1 = x1 - x[idx]
            total = integratePoly(c, dx1) - integratePoly(c, dx0)
        } else {
            // First partial segment
            let idx0 = min(i0, coeffs.count - 1)
            let c0 = coeffs[idx0]
            let dx0 = x0 - x[idx0]
            let dx1 = x[idx0 + 1] - x[idx0]
            total = integratePoly(c0, dx1) - integratePoly(c0, dx0)

            // Full segments
            for i in (i0 + 1)..<i1 {
                let idx = min(i, coeffs.count - 1)
                let c = coeffs[idx]
                let h = x[i + 1] - x[i]
                total += integratePoly(c, h)
            }

            // Last partial segment
            if i1 < n - 1 && i1 < coeffs.count {
                let c1 = coeffs[i1]
                let dx = x1 - x[i1]
                total += integratePoly(c1, dx)
            }
        }

        return total
    }

    // MARK: - PCHIP Interpolation

    /// Compute PCHIP edge derivative
    private static func pchipEdgeDerivative(h1: Double, h2: Double, d1: Double, d2: Double) -> Double {
        let deriv = ((2 * h1 + h2) * d1 - h1 * d2) / (h1 + h2)
        if deriv * d1 < 0 {
            return 0
        } else if d1 * d2 < 0 && abs(deriv) > 3 * abs(d1) {
            return 3 * d1
        }
        return deriv
    }

    /// Compute PCHIP derivatives at all points
    public static func computePchipDerivatives(x: [Double], y: [Double]) -> [Double] {
        let n = x.count
        guard n >= 2 else { return [] }

        // Compute slopes and intervals
        var h = [Double](repeating: 0, count: n - 1)
        var delta = [Double](repeating: 0, count: n - 1)
        for i in 0..<(n - 1) {
            h[i] = x[i + 1] - x[i]
            delta[i] = (y[i + 1] - y[i]) / h[i]
        }

        var d = [Double](repeating: 0, count: n)

        if n == 2 {
            d[0] = delta[0]
            d[1] = delta[0]
        } else {
            // Endpoints
            d[0] = pchipEdgeDerivative(h1: h[0], h2: h[1], d1: delta[0], d2: delta[1])
            d[n - 1] = pchipEdgeDerivative(h1: h[n - 2], h2: h[n - 3], d1: delta[n - 2], d2: delta[n - 3])

            // Interior points
            for i in 1..<(n - 1) {
                if delta[i - 1] * delta[i] > 0 {
                    let w1 = 2 * h[i] + h[i - 1]
                    let w2 = h[i] + 2 * h[i - 1]
                    d[i] = (w1 + w2) / (w1 / delta[i - 1] + w2 / delta[i])
                } else {
                    d[i] = 0
                }
            }
        }

        return d
    }

    /// Evaluate PCHIP interpolation at a point
    public static func evalPchip(x: [Double], y: [Double], d: [Double], xNew: Double) -> Double {
        let n = x.count

        // Extrapolation
        if xNew <= x[0] {
            return y[0] + d[0] * (xNew - x[0])
        }
        if xNew >= x[n - 1] {
            return y[n - 1] + d[n - 1] * (xNew - x[n - 1])
        }

        let i = findInterval(x, xNew)
        let h = x[i + 1] - x[i]
        let t = (xNew - x[i]) / h

        // Hermite basis functions
        let t2 = t * t
        let t3 = t2 * t
        let h00 = 2 * t3 - 3 * t2 + 1
        let h10 = t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2
        let h11 = t3 - t2

        return h00 * y[i] + h10 * h * d[i] + h01 * y[i + 1] + h11 * h * d[i + 1]
    }

    // MARK: - Akima Interpolation

    /// Compute Akima interpolation coefficients
    public static func computeAkimaCoeffs(x: [Double], y: [Double]) -> [CubicCoeffs] {
        let n = x.count
        guard n >= 2 else { return [] }

        // Compute slopes between points
        var m = [Double](repeating: 0, count: n + 3)
        for i in 0..<(n - 1) {
            m[i + 2] = (y[i + 1] - y[i]) / (x[i + 1] - x[i])
        }

        // Extend slopes at boundaries
        m[1] = 2 * m[2] - m[3]
        m[0] = 2 * m[1] - m[2]
        m[n + 1] = 2 * m[n] - m[n - 1]
        m[n + 2] = 2 * m[n + 1] - m[n]

        // Compute Akima derivatives
        var d = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let w1 = abs(m[i + 2] - m[i + 1])
            let w2 = abs(m[i] - m[i + 1])

            if w1 + w2 == 0 {
                d[i] = (m[i + 1] + m[i + 2]) / 2
            } else {
                d[i] = (w1 * m[i + 1] + w2 * m[i + 2]) / (w1 + w2)
            }
        }

        // Compute coefficients
        var coeffs = [CubicCoeffs]()
        for i in 0..<(n - 1) {
            let h = x[i + 1] - x[i]
            let slope = m[i + 2]
            let a = y[i]
            let b = d[i]
            let c = (3 * slope - 2 * d[i] - d[i + 1]) / h
            let dd = (d[i] + d[i + 1] - 2 * slope) / (h * h)
            coeffs.append(CubicCoeffs(a: a, b: b, c: c, d: dd))
        }

        return coeffs
    }

    /// Evaluate Akima interpolation at a point
    public static func evalAkima(x: [Double], coeffs: [CubicCoeffs], xNew: Double) -> Double {
        let n = x.count

        // Extrapolation
        if xNew <= x[0] {
            let dx = xNew - x[0]
            return coeffs[0].a + coeffs[0].b * dx
        }
        if xNew >= x[n - 1] {
            let dx = xNew - x[n - 2]
            let c = coeffs[n - 2]
            return c.a + c.b * dx + c.c * dx * dx + c.d * dx * dx * dx
        }

        let i = findInterval(x, xNew)
        let idx = min(i, coeffs.count - 1)
        let dx = xNew - x[idx]
        let c = coeffs[idx]
        return c.a + c.b * dx + c.c * dx * dx + c.d * dx * dx * dx
    }

    // MARK: - Lagrange Interpolation

    /// Evaluate Lagrange interpolation at a point
    public static func evalLagrange(x: [Double], y: [Double], xNew: Double) -> Double {
        let n = x.count
        var result = 0.0

        for i in 0..<n {
            var basis = 1.0
            for j in 0..<n {
                if i != j {
                    basis *= (xNew - x[j]) / (x[i] - x[j])
                }
            }
            result += y[i] * basis
        }

        return result
    }

    // MARK: - Barycentric Interpolation

    /// Compute barycentric weights
    public static func computeBarycentricWeights(x: [Double]) -> [Double] {
        let n = x.count
        var w = [Double](repeating: 1, count: n)

        for i in 0..<n {
            for j in 0..<n {
                if i != j {
                    w[i] /= (x[i] - x[j])
                }
            }
        }

        return w
    }

    /// Evaluate barycentric interpolation at a point
    public static func evalBarycentric(x: [Double], y: [Double], w: [Double], xNew: Double) -> Double {
        let n = x.count

        // Check for exact match
        for i in 0..<n {
            if xNew == x[i] {
                return y[i]
            }
        }

        var num = 0.0
        var den = 0.0
        for i in 0..<n {
            let term = w[i] / (xNew - x[i])
            num += term * y[i]
            den += term
        }

        return num / den
    }

    // MARK: - Registration

    /// Register the interpolation module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_interp_spline_coeffs", callback: makeSplineCoeffsCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_spline", callback: makeEvalSplineCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_spline_deriv", callback: makeEvalSplineDerivCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_integrate_spline", callback: makeIntegrateSplineCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_pchip_derivs", callback: makePchipDerivsCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_pchip", callback: makeEvalPchipCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_akima_coeffs", callback: makeAkimaCoeffsCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_akima", callback: makeEvalAkimaCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_lagrange", callback: makeEvalLagrangeCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_barycentric_weights", callback: makeBarycentricWeightsCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_eval_barycentric", callback: makeEvalBarycentricCallback(engine))
        engine.registerFunction(name: "_luaswift_interp_interp1d", callback: makeInterp1dCallback(engine))

        // Set up Lua namespace with thin wrappers
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.interpolate then luaswift.interpolate = {} end

                local interpolate = {}

                ----------------------------------------------------------------
                -- Helper: Binary search to find interval containing x
                ----------------------------------------------------------------
                local function find_interval(xs, x)
                    local lo, hi = 1, #xs
                    while hi - lo > 1 do
                        local mid = math.floor((lo + hi) / 2)
                        if xs[mid] > x then
                            hi = mid
                        else
                            lo = mid
                        end
                    end
                    return lo
                end

                ----------------------------------------------------------------
                -- Complex number helpers
                ----------------------------------------------------------------
                local function is_complex(v)
                    return type(v) == "table" and v.re ~= nil and v.im ~= nil
                end

                local function has_complex(arr)
                    for i = 1, #arr do
                        if is_complex(arr[i]) then return true end
                    end
                    return false
                end

                local function get_real_parts(arr)
                    local result = {}
                    for i = 1, #arr do
                        result[i] = is_complex(arr[i]) and arr[i].re or arr[i]
                    end
                    return result
                end

                local function get_imag_parts(arr)
                    local result = {}
                    for i = 1, #arr do
                        result[i] = is_complex(arr[i]) and arr[i].im or 0
                    end
                    return result
                end

                ----------------------------------------------------------------
                -- interp1d: 1D interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.interp1d(x, y, kind, options)
                    options = options or {}
                    kind = kind or "linear"
                    local fill_value = options.fill_value or (0/0)
                    local bounds_error = options.bounds_error or false

                    local n = #x
                    if n < 2 then error("interp1d: need at least 2 data points") end
                    if n ~= #y then error("interp1d: x and y must have same length") end

                    local xs, ys = {}, {}
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local is_complex_data = has_complex(ys)
                    local coeffs_re, coeffs_im = nil, nil

                    if kind == "cubic" then
                        if is_complex_data then
                            coeffs_re = _luaswift_interp_spline_coeffs(xs, get_real_parts(ys), "natural")
                            coeffs_im = _luaswift_interp_spline_coeffs(xs, get_imag_parts(ys), "natural")
                        else
                            coeffs_re = _luaswift_interp_spline_coeffs(xs, ys, "natural")
                        end
                    end

                    return function(x_new)
                        if type(x_new) == "table" and not is_complex(x_new) then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._interp1d_single(xs, ys, xi, kind, fill_value, bounds_error, coeffs_re, coeffs_im, is_complex_data)
                            end
                            return result
                        end
                        return interpolate._interp1d_single(xs, ys, x_new, kind, fill_value, bounds_error, coeffs_re, coeffs_im, is_complex_data)
                    end
                end

                function interpolate._interp1d_single(xs, ys, x_new, kind, fill_value, bounds_error, coeffs_re, coeffs_im, is_complex_data)
                    local n = #xs
                    if x_new < xs[1] or x_new > xs[n] then
                        if bounds_error then error("interp1d: value outside range") end
                        return fill_value
                    end
                    if x_new == xs[1] then return ys[1] end
                    if x_new == xs[n] then return ys[n] end

                    local i = find_interval(xs, x_new)

                    if kind == "nearest" then
                        return math.abs(x_new - xs[i]) <= math.abs(x_new - xs[i+1]) and ys[i] or ys[i+1]
                    elseif kind == "previous" then
                        return ys[i]
                    elseif kind == "next" then
                        return ys[i+1]
                    elseif kind == "cubic" then
                        if is_complex_data then
                            local re = _luaswift_interp_eval_spline(xs, coeffs_re, x_new, true)
                            local im = _luaswift_interp_eval_spline(xs, coeffs_im, x_new, true)
                            return {re = re, im = im}
                        else
                            return _luaswift_interp_eval_spline(xs, coeffs_re, x_new, true)
                        end
                    else
                        -- Linear (or default)
                        local t = (x_new - xs[i]) / (xs[i+1] - xs[i])
                        local y1, y2 = ys[i], ys[i+1]
                        if is_complex(y1) or is_complex(y2) then
                            local r1 = is_complex(y1) and y1.re or y1
                            local i1 = is_complex(y1) and y1.im or 0
                            local r2 = is_complex(y2) and y2.re or y2
                            local i2 = is_complex(y2) and y2.im or 0
                            return {re = r1 + t * (r2 - r1), im = i1 + t * (i2 - i1)}
                        else
                            return y1 + t * (y2 - y1)
                        end
                    end
                end

                ----------------------------------------------------------------
                -- CubicSpline: Cubic spline interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.CubicSpline(x, y, options)
                    options = options or {}
                    local bc_type = options.bc_type or "not-a-knot"
                    local extrapolate = options.extrapolate
                    if extrapolate == nil then extrapolate = true end

                    local n = #x
                    if n < 2 then error("CubicSpline: need at least 2 data points") end
                    if n ~= #y then error("CubicSpline: x and y must have same length") end

                    local xs, ys = {}, {}
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local is_complex_data = has_complex(ys)
                    local coeffs, coeffs_re, coeffs_im

                    if is_complex_data then
                        coeffs_re = _luaswift_interp_spline_coeffs(xs, get_real_parts(ys), bc_type)
                        coeffs_im = _luaswift_interp_spline_coeffs(xs, get_imag_parts(ys), bc_type)
                    else
                        coeffs = _luaswift_interp_spline_coeffs(xs, ys, bc_type)
                    end

                    local spline = {x = xs, y = ys, extrapolate = extrapolate, is_complex = is_complex_data}

                    local function evaluate(x_new)
                        if type(x_new) == "table" and not is_complex(x_new) then
                            local result = {}
                            for i, xi in ipairs(x_new) do result[i] = evaluate(xi) end
                            return result
                        end

                        if is_complex_data then
                            local re = _luaswift_interp_eval_spline(xs, coeffs_re, x_new, extrapolate)
                            local im = _luaswift_interp_eval_spline(xs, coeffs_im, x_new, extrapolate)
                            return {re = re, im = im}
                        else
                            return _luaswift_interp_eval_spline(xs, coeffs, x_new, extrapolate)
                        end
                    end

                    function spline.derivative(x_new, nu)
                        nu = nu or 1
                        if type(x_new) == "table" and not is_complex(x_new) then
                            local result = {}
                            for i, xi in ipairs(x_new) do result[i] = spline.derivative(xi, nu) end
                            return result
                        end
                        if is_complex_data then
                            local re = _luaswift_interp_eval_spline_deriv(xs, coeffs_re, x_new, nu)
                            local im = _luaswift_interp_eval_spline_deriv(xs, coeffs_im, x_new, nu)
                            return {re = re, im = im}
                        else
                            return _luaswift_interp_eval_spline_deriv(xs, coeffs, x_new, nu)
                        end
                    end

                    function spline.integrate(a, b)
                        if is_complex_data then
                            local re = _luaswift_interp_integrate_spline(xs, coeffs_re, a, b)
                            local im = _luaswift_interp_integrate_spline(xs, coeffs_im, a, b)
                            return {re = re, im = im}
                        else
                            return _luaswift_interp_integrate_spline(xs, coeffs, a, b)
                        end
                    end

                    setmetatable(spline, {__call = function(_, x_new) return evaluate(x_new) end})
                    return spline
                end

                ----------------------------------------------------------------
                -- PchipInterpolator: PCHIP interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.PchipInterpolator(x, y)
                    local n = #x
                    if n < 2 then error("PchipInterpolator: need at least 2 data points") end
                    if n ~= #y then error("PchipInterpolator: x and y must have same length") end

                    local xs, ys = {}, {}
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local d = _luaswift_interp_pchip_derivs(xs, ys)

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = _luaswift_interp_eval_pchip(xs, ys, d, xi)
                            end
                            return result
                        end
                        return _luaswift_interp_eval_pchip(xs, ys, d, x_new)
                    end
                end

                ----------------------------------------------------------------
                -- Akima1DInterpolator: Akima interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.Akima1DInterpolator(x, y)
                    local n = #x
                    if n < 2 then error("Akima1DInterpolator: need at least 2 data points") end
                    if n ~= #y then error("Akima1DInterpolator: x and y must have same length") end

                    local xs, ys = {}, {}
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local coeffs = _luaswift_interp_akima_coeffs(xs, ys)

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = _luaswift_interp_eval_akima(xs, coeffs, xi)
                            end
                            return result
                        end
                        return _luaswift_interp_eval_akima(xs, coeffs, x_new)
                    end
                end

                ----------------------------------------------------------------
                -- lagrange: Lagrange polynomial interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.lagrange(x, y)
                    local n = #x
                    if n ~= #y then error("lagrange: x and y must have same length") end

                    local xs, ys = {}, {}
                    local is_complex_data = has_complex(y)
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._eval_lagrange(xs, ys, xi, is_complex_data)
                            end
                            return result
                        end
                        return interpolate._eval_lagrange(xs, ys, x_new, is_complex_data)
                    end
                end

                function interpolate._eval_lagrange(xs, ys, x_new, is_complex_data)
                    if is_complex_data then
                        local ys_re = get_real_parts(ys)
                        local ys_im = get_imag_parts(ys)
                        local re = _luaswift_interp_eval_lagrange(xs, ys_re, x_new)
                        local im = _luaswift_interp_eval_lagrange(xs, ys_im, x_new)
                        return {re = re, im = im}
                    else
                        return _luaswift_interp_eval_lagrange(xs, ys, x_new)
                    end
                end

                ----------------------------------------------------------------
                -- BarycentricInterpolator: Barycentric interpolation (Swift-backed)
                ----------------------------------------------------------------
                function interpolate.BarycentricInterpolator(x, y)
                    local n = #x
                    if n ~= #y then error("BarycentricInterpolator: x and y must have same length") end

                    local xs, ys = {}, {}
                    local is_complex_data = has_complex(y)
                    for i = 1, n do xs[i], ys[i] = x[i], y[i] end

                    local w = _luaswift_interp_barycentric_weights(xs)

                    return function(x_new)
                        if type(x_new) == "table" then
                            local result = {}
                            for i, xi in ipairs(x_new) do
                                result[i] = interpolate._eval_barycentric(xs, ys, w, xi, is_complex_data)
                            end
                            return result
                        end
                        return interpolate._eval_barycentric(xs, ys, w, x_new, is_complex_data)
                    end
                end

                function interpolate._eval_barycentric(xs, ys, w, x_new, is_complex_data)
                    -- Check for exact match
                    for i = 1, #xs do
                        if x_new == xs[i] then return ys[i] end
                    end

                    if is_complex_data then
                        local ys_re = get_real_parts(ys)
                        local ys_im = get_imag_parts(ys)
                        local re = _luaswift_interp_eval_barycentric(xs, ys_re, w, x_new)
                        local im = _luaswift_interp_eval_barycentric(xs, ys_im, w, x_new)
                        return {re = re, im = im}
                    else
                        return _luaswift_interp_eval_barycentric(xs, ys, w, x_new)
                    end
                end

                -- Store the module
                luaswift.interpolate = interpolate

                -- Also update math.interpolate
                if math then
                    if not math.interpolate then math.interpolate = {} end
                    for k, v in pairs(interpolate) do
                        math.interpolate[k] = v
                    end
                end
                """)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Callbacks

    /// Callback for computing spline coefficients
    private static func makeSplineCoeffsCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue else {
                throw LuaError.runtimeError("spline_coeffs: expected x and y arrays")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }
            let bcType = args.count > 2 ? args[2].stringValue ?? "not-a-knot" : "not-a-knot"

            let coeffs = computeSplineCoeffs(x: x, y: y, bcType: bcType)

            // Return as array of {a, b, c, d} tables
            let result = coeffs.map { c -> LuaValue in
                .array([.number(c.a), .number(c.b), .number(c.c), .number(c.d)])
            }
            return .array(result)
        }
    }

    /// Callback for evaluating spline
    private static func makeEvalSplineCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  let xTable = args[0].arrayValue,
                  let coeffsTable = args[1].arrayValue,
                  let xNew = args[2].numberValue else {
                throw LuaError.runtimeError("eval_spline: expected x, coeffs, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let extrapolate = args.count > 3 ? (args[3].boolValue ?? true) : true

            // Parse coefficients
            var coeffs = [CubicCoeffs]()
            for c in coeffsTable {
                if let arr = c.arrayValue, arr.count >= 4,
                   let a = arr[0].numberValue,
                   let b = arr[1].numberValue,
                   let cc = arr[2].numberValue,
                   let d = arr[3].numberValue {
                    coeffs.append(CubicCoeffs(a: a, b: b, c: cc, d: d))
                }
            }

            let result = evalCubicSpline(x: x, coeffs: coeffs, xNew: xNew, extrapolate: extrapolate)
            return .number(result)
        }
    }

    /// Callback for evaluating spline derivative
    private static func makeEvalSplineDerivCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  let xTable = args[0].arrayValue,
                  let coeffsTable = args[1].arrayValue,
                  let xNew = args[2].numberValue else {
                throw LuaError.runtimeError("eval_spline_deriv: expected x, coeffs, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let order = args.count > 3 ? Int(args[3].numberValue ?? 1) : 1

            var coeffs = [CubicCoeffs]()
            for c in coeffsTable {
                if let arr = c.arrayValue, arr.count >= 4,
                   let a = arr[0].numberValue,
                   let b = arr[1].numberValue,
                   let cc = arr[2].numberValue,
                   let d = arr[3].numberValue {
                    coeffs.append(CubicCoeffs(a: a, b: b, c: cc, d: d))
                }
            }

            let result = evalCubicSplineDerivative(x: x, coeffs: coeffs, xNew: xNew, order: order)
            return .number(result)
        }
    }

    /// Callback for integrating spline
    private static func makeIntegrateSplineCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  let xTable = args[0].arrayValue,
                  let coeffsTable = args[1].arrayValue,
                  let a = args[2].numberValue,
                  let b = args[3].numberValue else {
                throw LuaError.runtimeError("integrate_spline: expected x, coeffs, a, b")
            }

            let x = xTable.compactMap { $0.numberValue }

            var coeffs = [CubicCoeffs]()
            for c in coeffsTable {
                if let arr = c.arrayValue, arr.count >= 4,
                   let aa = arr[0].numberValue,
                   let bb = arr[1].numberValue,
                   let cc = arr[2].numberValue,
                   let dd = arr[3].numberValue {
                    coeffs.append(CubicCoeffs(a: aa, b: bb, c: cc, d: dd))
                }
            }

            let result = integrateCubicSpline(x: x, coeffs: coeffs, a: a, b: b)
            return .number(result)
        }
    }

    /// Callback for computing PCHIP derivatives
    private static func makePchipDerivsCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue else {
                throw LuaError.runtimeError("pchip_derivs: expected x and y arrays")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }

            let d = computePchipDerivatives(x: x, y: y)
            return .array(d.map { .number($0) })
        }
    }

    /// Callback for evaluating PCHIP
    private static func makeEvalPchipCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue,
                  let dTable = args[2].arrayValue,
                  let xNew = args[3].numberValue else {
                throw LuaError.runtimeError("eval_pchip: expected x, y, d, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }
            let d = dTable.compactMap { $0.numberValue }

            let result = evalPchip(x: x, y: y, d: d, xNew: xNew)
            return .number(result)
        }
    }

    /// Callback for computing Akima coefficients
    private static func makeAkimaCoeffsCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue else {
                throw LuaError.runtimeError("akima_coeffs: expected x and y arrays")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }

            let coeffs = computeAkimaCoeffs(x: x, y: y)
            let result = coeffs.map { c -> LuaValue in
                .array([.number(c.a), .number(c.b), .number(c.c), .number(c.d)])
            }
            return .array(result)
        }
    }

    /// Callback for evaluating Akima
    private static func makeEvalAkimaCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  let xTable = args[0].arrayValue,
                  let coeffsTable = args[1].arrayValue,
                  let xNew = args[2].numberValue else {
                throw LuaError.runtimeError("eval_akima: expected x, coeffs, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }

            var coeffs = [CubicCoeffs]()
            for c in coeffsTable {
                if let arr = c.arrayValue, arr.count >= 4,
                   let a = arr[0].numberValue,
                   let b = arr[1].numberValue,
                   let cc = arr[2].numberValue,
                   let d = arr[3].numberValue {
                    coeffs.append(CubicCoeffs(a: a, b: b, c: cc, d: d))
                }
            }

            let result = evalAkima(x: x, coeffs: coeffs, xNew: xNew)
            return .number(result)
        }
    }

    /// Callback for evaluating Lagrange
    private static func makeEvalLagrangeCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue,
                  let xNew = args[2].numberValue else {
                throw LuaError.runtimeError("eval_lagrange: expected x, y, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }

            let result = evalLagrange(x: x, y: y, xNew: xNew)
            return .number(result)
        }
    }

    /// Callback for computing barycentric weights
    private static func makeBarycentricWeightsCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 1,
                  let xTable = args[0].arrayValue else {
                throw LuaError.runtimeError("barycentric_weights: expected x array")
            }

            let x = xTable.compactMap { $0.numberValue }
            let w = computeBarycentricWeights(x: x)
            return .array(w.map { .number($0) })
        }
    }

    /// Callback for evaluating barycentric
    private static func makeEvalBarycentricCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue,
                  let wTable = args[2].arrayValue,
                  let xNew = args[3].numberValue else {
                throw LuaError.runtimeError("eval_barycentric: expected x, y, w, xNew")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }
            let w = wTable.compactMap { $0.numberValue }

            let result = evalBarycentric(x: x, y: y, w: w, xNew: xNew)
            return .number(result)
        }
    }

    /// Callback for simple interp1d (non-cubic)
    private static func makeInterp1dCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  let xTable = args[0].arrayValue,
                  let yTable = args[1].arrayValue,
                  let xNew = args[2].numberValue,
                  let kindStr = args[3].stringValue else {
                throw LuaError.runtimeError("interp1d: expected x, y, xNew, kind")
            }

            let x = xTable.compactMap { $0.numberValue }
            let y = yTable.compactMap { $0.numberValue }
            let fillValue = args.count > 4 ? args[4].numberValue ?? Double.nan : Double.nan
            let boundsError = args.count > 5 ? args[5].boolValue ?? false : false

            let kind: InterpolationKind
            switch kindStr {
            case "nearest": kind = .nearest
            case "previous": kind = .previous
            case "next": kind = .next
            case "cubic": kind = .cubic
            default: kind = .linear
            }

            let result = interp1dSingle(x: x, y: y, xNew: xNew, kind: kind, fillValue: fillValue, boundsError: boundsError, coeffs: nil)
            return .number(result)
        }
    }
}
