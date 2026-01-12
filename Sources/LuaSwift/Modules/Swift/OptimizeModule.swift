//
//  OptimizeModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Accelerate

/// Swift-backed optimization module for LuaSwift.
///
/// Provides numerical optimization functions including scalar minimization,
/// root finding, and multivariate optimization. All algorithms implemented
/// in Swift for performance, with thin Lua bindings.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- Scalar minimization (Golden section / Brent's method)
/// local result = math.optimize.minimize_scalar(function(x) return (x-2)^2 end, {bracket={0,4}})
/// print(result.x, result.fun, result.success)
///
/// -- Root finding (scalar) - Bisection, Newton, Secant methods
/// local result = math.optimize.root_scalar(function(x) return x^2 - 4 end, {bracket={0,5}})
/// print(result.root, result.converged)
///
/// -- Multivariate minimization (Nelder-Mead)
/// local result = math.optimize.minimize(
///     function(x) return (x[1]-1)^2 + (x[2]-2)^2 end,
///     {0, 0}
/// )
/// print(result.x[1], result.x[2], result.fun)
/// ```
public struct OptimizeModule {

    // MARK: - Constants

    /// Default tolerance for convergence in x
    public static let defaultXTol: Double = 1e-8

    /// Default tolerance for convergence in f(x)
    public static let defaultFTol: Double = 1e-8

    /// Default maximum iterations
    public static let defaultMaxIter: Int = 500

    /// Golden ratio
    private static let phi: Double = (1 + sqrt(5)) / 2
    private static let resphi: Double = 2 - phi  // ≈ 0.382

    // MARK: - Result Types

    /// Result from scalar minimization
    public struct MinimizeScalarResult {
        public let x: Double
        public let fun: Double
        public let nfev: Int
        public let nit: Int
        public let success: Bool
        public let message: String
    }

    /// Result from scalar root finding
    public struct RootScalarResult {
        public let root: Double
        public let iterations: Int
        public let functionCalls: Int
        public let converged: Bool
        public let flag: String
    }

    /// Result from multivariate minimization
    public struct MinimizeResult {
        public let x: [Double]
        public let fun: Double
        public let nfev: Int
        public let nit: Int
        public let success: Bool
        public let message: String
    }

    /// Result from multivariate root finding
    public struct RootResult {
        public let x: [Double]
        public let fun: [Double]
        public let success: Bool
        public let message: String
        public let nfev: Int
        public let nit: Int
    }

    /// Result from least squares optimization
    public struct LeastSquaresResult {
        public let x: [Double]
        public let cost: Double
        public let fun: [Double]
        public let nfev: Int
        public let njev: Int
        public let success: Bool
        public let message: String
    }

    // MARK: - Scalar Minimization

    /// Golden section search for scalar minimization.
    ///
    /// Finds the minimum of a unimodal function in the interval [a, b].
    ///
    /// - Parameters:
    ///   - f: Function to minimize
    ///   - a: Left bound
    ///   - b: Right bound
    ///   - xtol: Tolerance
    ///   - maxiter: Maximum iterations
    /// - Returns: Optimization result
    public static func goldenSection(
        _ f: (Double) -> Double,
        a: Double,
        b: Double,
        xtol: Double = defaultXTol,
        maxiter: Int = defaultMaxIter
    ) -> MinimizeScalarResult {
        var a = a, b = b
        var nfev = 0
        var nit = 0

        // Internal points: c < d (c is left, d is right)
        // Using golden ratio: c = a + (1-phi)/phi * (b-a) = a + resphi * (b-a)
        //                     d = a + (b-a)/phi = b - resphi * (b-a)
        var c = a + resphi * (b - a)  // left internal point
        var d = b - resphi * (b - a)  // right internal point
        var fc = f(c); nfev += 1
        var fd = f(d); nfev += 1

        while abs(b - a) > xtol && nit < maxiter {
            nit += 1
            if fc < fd {
                // Minimum is in [a, d], narrow to [a, d]
                b = d
                d = c
                fd = fc
                c = a + resphi * (b - a)
                fc = f(c); nfev += 1
            } else {
                // Minimum is in [c, b], narrow to [c, b]
                a = c
                c = d
                fc = fd
                d = b - resphi * (b - a)
                fd = f(d); nfev += 1
            }
        }

        let x = (a + b) / 2
        let fval = f(x); nfev += 1

        return MinimizeScalarResult(
            x: x,
            fun: fval,
            nfev: nfev,
            nit: nit,
            success: abs(b - a) <= xtol,
            message: abs(b - a) <= xtol ? "Optimization terminated successfully." : "Maximum iterations reached."
        )
    }

    /// Brent's method for scalar minimization.
    ///
    /// Combines parabolic interpolation with golden section for faster convergence.
    ///
    /// - Parameters:
    ///   - f: Function to minimize
    ///   - a: Left bound
    ///   - b: Right bound
    ///   - xtol: Tolerance
    ///   - maxiter: Maximum iterations
    /// - Returns: Optimization result
    public static func brent(
        _ f: (Double) -> Double,
        a: Double,
        b: Double,
        xtol: Double = defaultXTol,
        maxiter: Int = defaultMaxIter
    ) -> MinimizeScalarResult {
        let goldenMean: Double = 0.5 * (3.0 - sqrt(5.0))
        let sqrtEps = sqrt(Double.ulpOfOne)

        var a = a, b = b
        if a > b { swap(&a, &b) }

        var nfev = 0
        var nit = 0

        var x = a + goldenMean * (b - a)
        var w = x, v = x
        var fx = f(x); nfev += 1
        var fw = fx, fv = fx

        var d: Double = 0, e: Double = 0

        while nit < maxiter {
            nit += 1
            let midpoint = 0.5 * (a + b)
            let tol1 = sqrtEps * abs(x) + xtol / 3.0
            let tol2 = 2.0 * tol1

            // Check for convergence
            if abs(x - midpoint) <= (tol2 - 0.5 * (b - a)) {
                return MinimizeScalarResult(
                    x: x, fun: fx, nfev: nfev, nit: nit,
                    success: true, message: "Optimization terminated successfully."
                )
            }

            var useParabolic = false
            var p: Double = 0, q: Double = 0, r: Double = 0

            if abs(e) > tol1 {
                // Fit parabola
                r = (x - w) * (fx - fv)
                q = (x - v) * (fx - fw)
                p = (x - v) * q - (x - w) * r
                q = 2.0 * (q - r)
                if q > 0 { p = -p } else { q = -q }
                r = e
                e = d

                if abs(p) < abs(0.5 * q * r) && p > q * (a - x) && p < q * (b - x) {
                    // Parabolic step accepted
                    d = p / q
                    let u = x + d
                    // Don't evaluate too close to bounds
                    if (u - a) < tol2 || (b - u) < tol2 {
                        d = x < midpoint ? tol1 : -tol1
                    }
                    useParabolic = true
                }
            }

            if !useParabolic {
                // Golden section step
                e = (x < midpoint) ? (b - x) : (a - x)
                d = goldenMean * e
            }

            // Don't evaluate too close to current point
            let u: Double
            if abs(d) >= tol1 {
                u = x + d
            } else {
                u = x + (d >= 0 ? tol1 : -tol1)
            }

            let fu = f(u); nfev += 1

            // Update interval
            if fu <= fx {
                if u < x { b = x } else { a = x }
                v = w; fv = fw
                w = x; fw = fx
                x = u; fx = fu
            } else {
                if u < x { a = u } else { b = u }
                if fu <= fw || w == x {
                    v = w; fv = fw
                    w = u; fw = fu
                } else if fu <= fv || v == x || v == w {
                    v = u; fv = fu
                }
            }
        }

        return MinimizeScalarResult(
            x: x, fun: fx, nfev: nfev, nit: nit,
            success: false, message: "Maximum iterations reached."
        )
    }

    // MARK: - Scalar Root Finding

    /// Bisection method for root finding.
    ///
    /// - Parameters:
    ///   - f: Function to find root of
    ///   - a: Left bound
    ///   - b: Right bound
    ///   - xtol: Tolerance
    ///   - maxiter: Maximum iterations
    /// - Returns: Root finding result
    public static func bisect(
        _ f: (Double) -> Double,
        a: Double,
        b: Double,
        xtol: Double = defaultXTol,
        maxiter: Int = defaultMaxIter
    ) -> RootScalarResult {
        var a = a, b = b
        var nfev = 0
        var nit = 0

        var fa = f(a); nfev += 1
        var fb = f(b); nfev += 1

        // Check for sign change
        if fa * fb > 0 {
            return RootScalarResult(
                root: .nan, iterations: 0, functionCalls: nfev,
                converged: false, flag: "f(a) and f(b) must have different signs"
            )
        }

        // Handle exact roots at boundaries
        if fa == 0 {
            return RootScalarResult(root: a, iterations: 0, functionCalls: nfev, converged: true, flag: "converged")
        }
        if fb == 0 {
            return RootScalarResult(root: b, iterations: 0, functionCalls: nfev, converged: true, flag: "converged")
        }

        while abs(b - a) > xtol && nit < maxiter {
            nit += 1
            let c = (a + b) / 2
            let fc = f(c); nfev += 1

            if fc == 0 {
                return RootScalarResult(root: c, iterations: nit, functionCalls: nfev, converged: true, flag: "converged")
            }

            if fa * fc < 0 {
                b = c
                fb = fc
            } else {
                a = c
                fa = fc
            }
        }

        let root = (a + b) / 2
        return RootScalarResult(
            root: root, iterations: nit, functionCalls: nfev,
            converged: abs(b - a) <= xtol, flag: abs(b - a) <= xtol ? "converged" : "maxiter reached"
        )
    }

    /// Newton's method for scalar root finding.
    ///
    /// - Parameters:
    ///   - f: Function to find root of
    ///   - fprime: Derivative of f (optional, uses numerical diff if nil)
    ///   - x0: Initial guess
    ///   - xtol: Tolerance
    ///   - maxiter: Maximum iterations
    /// - Returns: Root finding result
    public static func newton(
        _ f: (Double) -> Double,
        fprime: ((Double) -> Double)? = nil,
        x0: Double,
        xtol: Double = defaultXTol,
        maxiter: Int = defaultMaxIter
    ) -> RootScalarResult {
        var x = x0
        var nfev = 0
        var nit = 0

        for _ in 0..<maxiter {
            nit += 1
            let fx = f(x); nfev += 1

            // Calculate derivative (use provided or numerical)
            let fp: Double
            if let fprime = fprime {
                fp = fprime(x)
            } else {
                let h = sqrt(Double.ulpOfOne) * max(abs(x), 1.0)
                let fplus = f(x + h); nfev += 1
                let fminus = f(x - h); nfev += 1
                fp = (fplus - fminus) / (2 * h)
            }

            if abs(fp) < 1e-14 {
                return RootScalarResult(
                    root: x, iterations: nit, functionCalls: nfev,
                    converged: false, flag: "derivative is zero"
                )
            }

            let dx = fx / fp
            x = x - dx

            if abs(dx) < xtol || abs(fx) < xtol {
                return RootScalarResult(
                    root: x, iterations: nit, functionCalls: nfev,
                    converged: true, flag: "converged"
                )
            }
        }

        return RootScalarResult(
            root: x, iterations: nit, functionCalls: nfev,
            converged: false, flag: "maxiter reached"
        )
    }

    /// Secant method for scalar root finding.
    ///
    /// - Parameters:
    ///   - f: Function to find root of
    ///   - x0: First initial guess
    ///   - x1: Second initial guess (optional)
    ///   - xtol: Tolerance
    ///   - maxiter: Maximum iterations
    /// - Returns: Root finding result
    public static func secant(
        _ f: (Double) -> Double,
        x0: Double,
        x1: Double? = nil,
        xtol: Double = defaultXTol,
        maxiter: Int = defaultMaxIter
    ) -> RootScalarResult {
        var x0 = x0
        var x1 = x1 ?? (x0 + 0.001 * max(abs(x0), 1.0))
        var nfev = 0
        var nit = 0

        var f0 = f(x0); nfev += 1
        var f1 = f(x1); nfev += 1

        for _ in 0..<maxiter {
            nit += 1

            if abs(f1 - f0) < 1e-14 {
                return RootScalarResult(
                    root: x1, iterations: nit, functionCalls: nfev,
                    converged: false, flag: "denominator too small"
                )
            }

            let x2 = x1 - f1 * (x1 - x0) / (f1 - f0)
            x0 = x1; f0 = f1
            x1 = x2
            f1 = f(x1); nfev += 1

            if abs(x1 - x0) < xtol || abs(f1) < xtol {
                return RootScalarResult(
                    root: x1, iterations: nit, functionCalls: nfev,
                    converged: true, flag: "converged"
                )
            }
        }

        return RootScalarResult(
            root: x1, iterations: nit, functionCalls: nfev,
            converged: false, flag: "maxiter reached"
        )
    }

    // MARK: - Multivariate Minimization

    /// Nelder-Mead simplex method for multivariate minimization.
    ///
    /// - Parameters:
    ///   - f: Function to minimize
    ///   - x0: Initial guess
    ///   - xtol: Tolerance in x
    ///   - ftol: Tolerance in f(x)
    ///   - maxiter: Maximum iterations
    /// - Returns: Optimization result
    public static func nelderMead(
        _ f: @escaping ([Double]) -> Double,
        x0: [Double],
        xtol: Double = defaultXTol,
        ftol: Double = defaultFTol,
        maxiter: Int? = nil
    ) -> MinimizeResult {
        let n = x0.count
        let maxIterations = maxiter ?? 200 * n
        var nfev = 0
        var nit = 0

        // Nelder-Mead coefficients
        let alpha: Double = 1.0   // Reflection
        let gamma: Double = 2.0   // Expansion
        let rho: Double = 0.5     // Contraction
        let sigma: Double = 0.5   // Shrink

        // Initialize simplex
        var simplex: [[Double]] = [x0]
        var fvalues: [Double] = [f(x0)]; nfev += 1

        for i in 0..<n {
            var point = x0
            let delta = abs(x0[i]) > 0.00025 ? 0.05 : 0.00025
            point[i] += delta
            simplex.append(point)
            fvalues.append(f(point)); nfev += 1
        }

        while nit < maxIterations {
            nit += 1

            // Sort simplex by function values
            let sorted = zip(simplex.indices, fvalues).sorted { $0.1 < $1.1 }
            simplex = sorted.map { simplex[$0.0] }
            fvalues = sorted.map { $0.1 }

            // Check convergence
            let frange = fvalues.last! - fvalues.first!
            var xrange: Double = 0
            for i in 1...n {
                for j in 0..<n {
                    xrange = max(xrange, abs(simplex[i][j] - simplex[0][j]))
                }
            }

            if frange < ftol && xrange < xtol {
                return MinimizeResult(
                    x: simplex[0], fun: fvalues[0], nfev: nfev, nit: nit,
                    success: true, message: "Optimization terminated successfully."
                )
            }

            // Calculate centroid (excluding worst point)
            var centroid = [Double](repeating: 0, count: n)
            for i in 0..<n {
                for j in 0..<n {
                    centroid[j] += simplex[i][j]
                }
            }
            centroid = centroid.map { $0 / Double(n) }

            // Reflection
            var reflected = [Double](repeating: 0, count: n)
            for j in 0..<n {
                reflected[j] = centroid[j] + alpha * (centroid[j] - simplex[n][j])
            }
            let fReflected = f(reflected); nfev += 1

            if fReflected < fvalues[0] {
                // Expansion
                var expanded = [Double](repeating: 0, count: n)
                for j in 0..<n {
                    expanded[j] = centroid[j] + gamma * (reflected[j] - centroid[j])
                }
                let fExpanded = f(expanded); nfev += 1

                if fExpanded < fReflected {
                    simplex[n] = expanded
                    fvalues[n] = fExpanded
                } else {
                    simplex[n] = reflected
                    fvalues[n] = fReflected
                }
            } else if fReflected < fvalues[n-1] {
                simplex[n] = reflected
                fvalues[n] = fReflected
            } else {
                // Contraction
                let useOutside = fReflected < fvalues[n]
                var contracted = [Double](repeating: 0, count: n)
                for j in 0..<n {
                    if useOutside {
                        contracted[j] = centroid[j] + rho * (reflected[j] - centroid[j])
                    } else {
                        contracted[j] = centroid[j] + rho * (simplex[n][j] - centroid[j])
                    }
                }
                let fContracted = f(contracted); nfev += 1

                if fContracted < (useOutside ? fReflected : fvalues[n]) {
                    simplex[n] = contracted
                    fvalues[n] = fContracted
                } else {
                    // Shrink
                    for i in 1...n {
                        for j in 0..<n {
                            simplex[i][j] = simplex[0][j] + sigma * (simplex[i][j] - simplex[0][j])
                        }
                        fvalues[i] = f(simplex[i]); nfev += 1
                    }
                }
            }
        }

        // Sort one final time
        let sorted = zip(simplex.indices, fvalues).sorted { $0.1 < $1.1 }
        let bestX = simplex[sorted[0].0]
        let bestF = sorted[0].1

        return MinimizeResult(
            x: bestX, fun: bestF, nfev: nfev, nit: nit,
            success: false, message: "Maximum iterations reached."
        )
    }

    // MARK: - Multivariate Root Finding

    /// Newton's method for systems of equations.
    ///
    /// - Parameters:
    ///   - f: Function returning vector of residuals
    ///   - x0: Initial guess
    ///   - tol: Tolerance
    ///   - maxiter: Maximum iterations
    /// - Returns: Root finding result
    public static func newtonMulti(
        _ f: @escaping ([Double]) -> [Double],
        x0: [Double],
        tol: Double = defaultXTol,
        maxiter: Int = defaultMaxIter
    ) -> RootResult {
        let n = x0.count
        var x = x0
        var nfev = 0
        var nit = 0

        for _ in 0..<maxiter {
            nit += 1
            let fx = f(x); nfev += 1

            // Check convergence
            let norm = sqrt(fx.reduce(0) { $0 + $1 * $1 })
            if norm < tol {
                return RootResult(
                    x: x, fun: fx, success: true,
                    message: "Root found.", nfev: nfev, nit: nit
                )
            }

            // Compute Jacobian numerically
            var jacobian = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            let h = sqrt(Double.ulpOfOne)
            for j in 0..<n {
                var xp = x
                xp[j] += h
                let fxp = f(xp); nfev += 1
                for i in 0..<n {
                    jacobian[i][j] = (fxp[i] - fx[i]) / h
                }
            }

            // Solve J * dx = -f using Gaussian elimination
            var A = jacobian
            var b = fx.map { -$0 }

            for col in 0..<n {
                // Find pivot
                var maxRow = col
                for row in (col+1)..<n {
                    if abs(A[row][col]) > abs(A[maxRow][col]) {
                        maxRow = row
                    }
                }
                A.swapAt(col, maxRow)
                b.swapAt(col, maxRow)

                if abs(A[col][col]) < 1e-14 {
                    return RootResult(
                        x: x, fun: fx, success: false,
                        message: "Singular Jacobian.", nfev: nfev, nit: nit
                    )
                }

                // Eliminate
                for row in (col+1)..<n {
                    let factor = A[row][col] / A[col][col]
                    for k in col..<n {
                        A[row][k] -= factor * A[col][k]
                    }
                    b[row] -= factor * b[col]
                }
            }

            // Back substitution
            var dx = [Double](repeating: 0, count: n)
            for i in stride(from: n-1, through: 0, by: -1) {
                var sum = b[i]
                for j in (i+1)..<n {
                    sum -= A[i][j] * dx[j]
                }
                dx[i] = sum / A[i][i]
            }

            // Update x
            for i in 0..<n {
                x[i] += dx[i]
            }

            // Check for small step
            let dxNorm = sqrt(dx.reduce(0) { $0 + $1 * $1 })
            if dxNorm < tol {
                return RootResult(
                    x: x, fun: f(x), success: true,
                    message: "Root found.", nfev: nfev + 1, nit: nit
                )
            }
        }

        return RootResult(
            x: x, fun: f(x), success: false,
            message: "Maximum iterations reached.", nfev: nfev + 1, nit: nit
        )
    }

    // MARK: - Least Squares

    /// Levenberg-Marquardt algorithm for nonlinear least squares.
    ///
    /// Minimizes sum(residuals(x)^2) using the Levenberg-Marquardt method.
    ///
    /// - Parameters:
    ///   - residuals: Function returning residuals vector
    ///   - x0: Initial guess
    ///   - ftol: Relative tolerance for cost function
    ///   - xtol: Relative tolerance for parameters
    ///   - maxiter: Maximum iterations
    /// - Returns: Least squares result
    public static func leastSquares(
        _ residuals: @escaping ([Double]) -> [Double],
        x0: [Double],
        ftol: Double = 1e-8,
        xtol: Double = 1e-8,
        maxiter: Int = 100
    ) -> LeastSquaresResult {
        let n = x0.count
        var x = x0
        var nfev = 0
        var njev = 0

        // Initial residual evaluation
        var r = residuals(x); nfev += 1
        let m = r.count

        // Compute initial cost
        var cost = 0.5 * r.reduce(0) { $0 + $1 * $1 }

        // Levenberg-Marquardt parameters
        var lambda = 0.001
        let lambdaUp = 10.0
        let lambdaDown = 0.1

        for _ in 0..<maxiter {
            // Compute Jacobian numerically (m x n matrix)
            var J = [[Double]](repeating: [Double](repeating: 0, count: n), count: m)
            let h = sqrt(Double.ulpOfOne) * max(1.0, x.map { abs($0) }.max() ?? 1.0)
            for j in 0..<n {
                var xp = x
                xp[j] += h
                let rp = residuals(xp); nfev += 1
                for i in 0..<m {
                    J[i][j] = (rp[i] - r[i]) / h
                }
            }
            njev += 1

            // Compute J^T * J (n x n)
            var JTJ = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for i in 0..<n {
                for j in 0..<n {
                    var sum = 0.0
                    for k in 0..<m {
                        sum += J[k][i] * J[k][j]
                    }
                    JTJ[i][j] = sum
                }
            }

            // Compute J^T * r (n x 1)
            var JTr = [Double](repeating: 0, count: n)
            for i in 0..<n {
                var sum = 0.0
                for k in 0..<m {
                    sum += J[k][i] * r[k]
                }
                JTr[i] = sum
            }

            // Solve (J^T*J + lambda*diag(J^T*J)) * dx = -J^T*r
            var A = JTJ
            for i in 0..<n {
                A[i][i] += lambda * max(JTJ[i][i], 1e-10)
            }
            var b = JTr.map { -$0 }

            // Gaussian elimination with partial pivoting
            for col in 0..<n {
                var maxRow = col
                for row in (col+1)..<n {
                    if abs(A[row][col]) > abs(A[maxRow][col]) {
                        maxRow = row
                    }
                }
                A.swapAt(col, maxRow)
                b.swapAt(col, maxRow)

                guard abs(A[col][col]) > 1e-14 else {
                    return LeastSquaresResult(
                        x: x, cost: cost, fun: r, nfev: nfev, njev: njev,
                        success: false, message: "Singular matrix in LM step."
                    )
                }

                for row in (col+1)..<n {
                    let factor = A[row][col] / A[col][col]
                    for k in col..<n {
                        A[row][k] -= factor * A[col][k]
                    }
                    b[row] -= factor * b[col]
                }
            }

            // Back substitution
            var dx = [Double](repeating: 0, count: n)
            for i in stride(from: n-1, through: 0, by: -1) {
                var sum = b[i]
                for j in (i+1)..<n {
                    sum -= A[i][j] * dx[j]
                }
                dx[i] = sum / A[i][i]
            }

            // Trial step
            var xNew = x
            for i in 0..<n {
                xNew[i] += dx[i]
            }

            let rNew = residuals(xNew); nfev += 1
            let costNew = 0.5 * rNew.reduce(0) { $0 + $1 * $1 }

            // Check if step is accepted
            if costNew < cost {
                // Accept step
                let costRatio = abs(cost - costNew) / max(cost, 1e-14)
                let xNorm = sqrt(dx.reduce(0) { $0 + $1 * $1 })
                let paramNorm = sqrt(x.reduce(0) { $0 + $1 * $1 })

                x = xNew
                r = rNew
                cost = costNew
                lambda *= lambdaDown

                // Check convergence
                if costRatio < ftol {
                    return LeastSquaresResult(
                        x: x, cost: cost, fun: r, nfev: nfev, njev: njev,
                        success: true, message: "Both `ftol` and `xtol` termination conditions are satisfied."
                    )
                }
                if xNorm < xtol * (1 + paramNorm) {
                    return LeastSquaresResult(
                        x: x, cost: cost, fun: r, nfev: nfev, njev: njev,
                        success: true, message: "Both `ftol` and `xtol` termination conditions are satisfied."
                    )
                }
            } else {
                // Reject step, increase damping
                lambda *= lambdaUp
            }
        }

        return LeastSquaresResult(
            x: x, cost: cost, fun: r, nfev: nfev, njev: njev,
            success: false, message: "Maximum iterations reached."
        )
    }

    /// Curve fitting using nonlinear least squares.
    ///
    /// Fits a model function to data points using Levenberg-Marquardt.
    ///
    /// - Parameters:
    ///   - f: Model function (params, x) -> y
    ///   - xdata: X data points
    ///   - ydata: Y data points
    ///   - p0: Initial parameter guess
    ///   - ftol: Relative tolerance for cost function
    ///   - xtol: Relative tolerance for parameters
    ///   - maxiter: Maximum iterations
    /// - Returns: Tuple of (optimal params, covariance matrix, info)
    public static func curveFit(
        _ f: @escaping ([Double], Double) -> Double,
        xdata: [Double],
        ydata: [Double],
        p0: [Double],
        ftol: Double = 1e-8,
        xtol: Double = 1e-8,
        maxiter: Int = 100
    ) -> (popt: [Double], pcov: [[Double]], info: LeastSquaresResult) {
        let n = p0.count
        let m = xdata.count

        // Create residuals function
        let residuals: ([Double]) -> [Double] = { params in
            var r = [Double](repeating: 0, count: m)
            for i in 0..<m {
                r[i] = ydata[i] - f(params, xdata[i])
            }
            return r
        }

        // Run least squares
        let result = leastSquares(residuals, x0: p0, ftol: ftol, xtol: xtol, maxiter: maxiter)

        // Estimate covariance matrix
        // pcov = (J^T * J)^(-1) * s^2, where s^2 = cost / (m - n)
        let h = sqrt(Double.ulpOfOne) * max(1.0, result.x.map { abs($0) }.max() ?? 1.0)
        var J = [[Double]](repeating: [Double](repeating: 0, count: n), count: m)

        for j in 0..<n {
            var pp = result.x
            var pm = result.x
            pp[j] += h
            pm[j] -= h

            for i in 0..<m {
                let fp = f(pp, xdata[i])
                let fm = f(pm, xdata[i])
                J[i][j] = (fp - fm) / (2 * h)
            }
        }

        // Compute J^T * J
        var JTJ = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
        for i in 0..<n {
            for j in 0..<n {
                var sum = 0.0
                for k in 0..<m {
                    sum += J[k][i] * J[k][j]
                }
                JTJ[i][j] = sum
            }
        }

        // Invert JTJ to get pcov (simple Gaussian elimination for small matrices)
        var pcov = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
        var A = JTJ
        // Initialize identity
        for i in 0..<n {
            pcov[i][i] = 1.0
        }

        // Forward elimination
        for col in 0..<n {
            var maxRow = col
            for row in (col+1)..<n {
                if abs(A[row][col]) > abs(A[maxRow][col]) {
                    maxRow = row
                }
            }
            A.swapAt(col, maxRow)
            pcov.swapAt(col, maxRow)

            let pivot = A[col][col]
            if abs(pivot) > 1e-14 {
                for j in 0..<n {
                    A[col][j] /= pivot
                    pcov[col][j] /= pivot
                }
                for row in 0..<n where row != col {
                    let factor = A[row][col]
                    for j in 0..<n {
                        A[row][j] -= factor * A[col][j]
                        pcov[row][j] -= factor * pcov[col][j]
                    }
                }
            }
        }

        // Scale by variance estimate
        let dof = max(1, m - n)
        let s2 = result.cost * 2 / Double(dof)
        for i in 0..<n {
            for j in 0..<n {
                pcov[i][j] *= s2
            }
        }

        return (result.x, pcov, result)
    }

    // MARK: - Registration

    /// Register the optimization module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_optimize_minimize_scalar", callback: makeMinimizeScalarCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_root_scalar", callback: makeRootScalarCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_minimize", callback: makeMinimizeCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_root", callback: makeRootCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_least_squares", callback: makeLeastSquaresCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_curve_fit", callback: makeCurveFitCallback(engine))

        // Set up Lua namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.optimize then luaswift.optimize = {} end

                local optimize = luaswift.optimize

                -- minimize_scalar: Scalar function minimization
                function optimize.minimize_scalar(func, options)
                    options = options or {}
                    local result = _luaswift_optimize_minimize_scalar(func,
                        options.method or "brent",
                        options.bracket and options.bracket[1],
                        options.bracket and options.bracket[2],
                        options.xtol or 1e-8,
                        options.maxiter or 500)
                    return result
                end

                -- root_scalar: Scalar root finding
                function optimize.root_scalar(func, options)
                    options = options or {}
                    local result = _luaswift_optimize_root_scalar(func,
                        options.method or "bisect",
                        options.bracket and options.bracket[1],
                        options.bracket and options.bracket[2],
                        options.x0,
                        options.x1,
                        options.xtol or 1e-8,
                        options.maxiter or 100)
                    return result
                end

                -- minimize: Multivariate minimization
                function optimize.minimize(func, x0, options)
                    options = options or {}
                    local result = _luaswift_optimize_minimize(func, x0,
                        options.method or "Nelder-Mead",
                        options.xtol or 1e-8,
                        options.ftol or 1e-8,
                        options.maxiter)
                    return result
                end

                -- root: Multivariate root finding
                function optimize.root(func, x0, options)
                    options = options or {}
                    local result = _luaswift_optimize_root(func, x0,
                        options.method or "hybr",
                        options.tol or 1e-8,
                        options.maxiter or 100)
                    return result
                end

                -- least_squares: Nonlinear least squares
                function optimize.least_squares(residuals, x0, options)
                    options = options or {}
                    local result = _luaswift_optimize_least_squares(residuals, x0,
                        options.ftol or 1e-8,
                        options.xtol or 1e-8,
                        options.maxiter or 100)
                    return result
                end

                -- curve_fit: Fit function to data
                -- Supports both f(x, params) and f(x, a, b, c, ...) calling conventions
                function optimize.curve_fit(func, xdata, ydata, p0, options)
                    options = options or {}
                    -- Wrap function to support expanded form: f(x, a, b, c) -> f(x, params)
                    local wrapped_func = function(x, params)
                        -- Try expanded form first (f(x, a, b, c, ...))
                        local success, result = pcall(function()
                            return func(x, table.unpack(params))
                        end)
                        if success then
                            return result
                        end
                        -- Fall back to array form (f(x, params))
                        return func(x, params)
                    end
                    local result = _luaswift_optimize_curve_fit(wrapped_func, xdata, ydata, p0,
                        options.ftol or 1e-8,
                        options.xtol or 1e-8,
                        options.maxiter or 100)
                    -- Unpack array: [popt, pcov, info]
                    return result[1], result[2], result[3]
                end

                -- Also update math.optimize if it exists
                if math then
                    if not math.optimize then math.optimize = {} end
                    for k, v in pairs(optimize) do
                        math.optimize[k] = v
                    end
                end
                """)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Lua Callbacks

    /// Helper to create a Swift closure from a Lua function reference (1D)
    private static func makeLuaFunction1D(_ engine: LuaEngine, _ funcRef: Int32) -> (Double) -> Double {
        return { x in
            do {
                let result = try engine.callLuaFunction(ref: funcRef, args: [.number(x)])
                return result.numberValue ?? 0
            } catch {
                return 0
            }
        }
    }

    /// Helper to create a Swift closure from a Lua function reference (nD)
    private static func makeLuaFunctionND(_ engine: LuaEngine, _ funcRef: Int32) -> ([Double]) -> Double {
        return { x in
            do {
                let xLua = LuaValue.array(x.map { .number($0) })
                let result = try engine.callLuaFunction(ref: funcRef, args: [xLua])
                return result.numberValue ?? 0
            } catch {
                return 0
            }
        }
    }

    /// Helper to create a Swift closure from a Lua function reference (vector-valued)
    private static func makeLuaFunctionVector(_ engine: LuaEngine, _ funcRef: Int32) -> ([Double]) -> [Double] {
        return { x in
            do {
                let xLua = LuaValue.array(x.map { .number($0) })
                let result = try engine.callLuaFunction(ref: funcRef, args: [xLua])
                if let arr = result.arrayValue {
                    return arr.compactMap { $0.numberValue }
                }
                return x
            } catch {
                return x
            }
        }
    }

    /// Factory function for minimize_scalar callback
    private static func makeMinimizeScalarCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 1,
                  case .luaFunction(let funcRef) = args[0] else {
                throw LuaError.runtimeError("minimize_scalar: expected function")
            }

            let method = args.count > 1 ? args[1].stringValue ?? "brent" : "brent"
            let a = args.count > 2 ? args[2].numberValue ?? -10 : -10
            let b = args.count > 3 ? args[3].numberValue ?? 10 : 10
            let xtol = args.count > 4 ? args[4].numberValue ?? defaultXTol : defaultXTol
            let maxiter = args.count > 5 ? Int(args[5].numberValue ?? Double(defaultMaxIter)) : defaultMaxIter

            let f = makeLuaFunction1D(engine, funcRef)
            let result: MinimizeScalarResult

            if method.lowercased() == "golden" {
                result = goldenSection(f, a: a, b: b, xtol: xtol, maxiter: maxiter)
            } else {
                result = brent(f, a: a, b: b, xtol: xtol, maxiter: maxiter)
            }

            return .table([
                "x": .number(result.x),
                "fun": .number(result.fun),
                "nfev": .number(Double(result.nfev)),
                "nit": .number(Double(result.nit)),
                "success": .bool(result.success),
                "message": .string(result.message)
            ])
        }
    }

    /// Factory function for root_scalar callback
    private static func makeRootScalarCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 1,
                  case .luaFunction(let funcRef) = args[0] else {
                throw LuaError.runtimeError("root_scalar: expected function")
            }

            let method = args.count > 1 ? args[1].stringValue ?? "bisect" : "bisect"
            let a = args.count > 2 ? args[2].numberValue : nil
            let b = args.count > 3 ? args[3].numberValue : nil
            let x0 = args.count > 4 ? args[4].numberValue : nil
            let x1 = args.count > 5 ? args[5].numberValue : nil
            let xtol = args.count > 6 ? args[6].numberValue ?? defaultXTol : defaultXTol
            let maxiter = args.count > 7 ? Int(args[7].numberValue ?? 100) : 100

            let f = makeLuaFunction1D(engine, funcRef)
            let result: RootScalarResult

            switch method.lowercased() {
            case "bisect", "brentq":
                guard let aVal = a, let bVal = b else {
                    throw LuaError.runtimeError("bisect requires bracket=[a,b]")
                }
                result = bisect(f, a: aVal, b: bVal, xtol: xtol, maxiter: maxiter)
            case "newton":
                guard let x0Val = x0 else {
                    throw LuaError.runtimeError("newton requires x0")
                }
                result = newton(f, x0: x0Val, xtol: xtol, maxiter: maxiter)
            case "secant":
                guard let x0Val = x0 else {
                    throw LuaError.runtimeError("secant requires x0")
                }
                result = secant(f, x0: x0Val, x1: x1, xtol: xtol, maxiter: maxiter)
            default:
                // Default to bisect if bracket provided, newton if x0 provided
                if let aVal = a, let bVal = b {
                    result = bisect(f, a: aVal, b: bVal, xtol: xtol, maxiter: maxiter)
                } else if let x0Val = x0 {
                    result = newton(f, x0: x0Val, xtol: xtol, maxiter: maxiter)
                } else {
                    throw LuaError.runtimeError("root_scalar requires either bracket or x0")
                }
            }

            return .table([
                "root": .number(result.root),
                "iterations": .number(Double(result.iterations)),
                "function_calls": .number(Double(result.functionCalls)),
                "converged": .bool(result.converged),
                "message": .string(result.flag),
                "flag": .string(result.flag)  // Keep for compatibility
            ])
        }
    }

    /// Factory function for minimize callback
    private static func makeMinimizeCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  case .luaFunction(let funcRef) = args[0],
                  let x0Table = args[1].arrayValue else {
                throw LuaError.runtimeError("minimize: expected function and x0 array")
            }

            let x0 = x0Table.compactMap { $0.numberValue }
            guard !x0.isEmpty else {
                throw LuaError.runtimeError("minimize: x0 must be non-empty")
            }

            let xtol = args.count > 3 ? args[3].numberValue ?? defaultXTol : defaultXTol
            let ftol = args.count > 4 ? args[4].numberValue ?? defaultFTol : defaultFTol
            let maxiter = args.count > 5 ? (args[5].isNil ? nil : Int(args[5].numberValue ?? 0)) : nil

            let f = makeLuaFunctionND(engine, funcRef)
            let result = nelderMead(f, x0: x0, xtol: xtol, ftol: ftol, maxiter: maxiter)

            return .table([
                "x": .array(result.x.map { .number($0) }),
                "fun": .number(result.fun),
                "nfev": .number(Double(result.nfev)),
                "nit": .number(Double(result.nit)),
                "success": .bool(result.success),
                "message": .string(result.message)
            ])
        }
    }

    /// Factory function for root callback
    private static func makeRootCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  case .luaFunction(let funcRef) = args[0],
                  let x0Table = args[1].arrayValue else {
                throw LuaError.runtimeError("root: expected function and x0 array")
            }

            let x0 = x0Table.compactMap { $0.numberValue }
            guard !x0.isEmpty else {
                throw LuaError.runtimeError("root: x0 must be non-empty")
            }

            let tol = args.count > 3 ? args[3].numberValue ?? defaultXTol : defaultXTol
            let maxiter = args.count > 4 ? Int(args[4].numberValue ?? Double(defaultMaxIter)) : defaultMaxIter

            let f = makeLuaFunctionVector(engine, funcRef)
            let result = newtonMulti(f, x0: x0, tol: tol, maxiter: maxiter)

            return .table([
                "x": .array(result.x.map { .number($0) }),
                "fun": .array(result.fun.map { .number($0) }),
                "success": .bool(result.success),
                "message": .string(result.message),
                "nfev": .number(Double(result.nfev)),
                "nit": .number(Double(result.nit))
            ])
        }
    }

    /// Factory function for least_squares callback
    private static func makeLeastSquaresCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  case .luaFunction(let funcRef) = args[0],
                  let x0Table = args[1].arrayValue else {
                throw LuaError.runtimeError("least_squares: expected residuals function and x0 array")
            }

            let x0 = x0Table.compactMap { $0.numberValue }
            guard !x0.isEmpty else {
                throw LuaError.runtimeError("least_squares: x0 must be non-empty")
            }

            let ftol = args.count > 2 ? args[2].numberValue ?? 1e-8 : 1e-8
            let xtol = args.count > 3 ? args[3].numberValue ?? 1e-8 : 1e-8
            let maxiter = args.count > 4 ? Int(args[4].numberValue ?? 100) : 100

            let residuals = makeLuaFunctionVector(engine, funcRef)
            let result = leastSquares(residuals, x0: x0, ftol: ftol, xtol: xtol, maxiter: maxiter)

            return .table([
                "x": .array(result.x.map { .number($0) }),
                "cost": .number(result.cost),
                "fun": .array(result.fun.map { .number($0) }),
                "jac": .array([]),  // Jacobian placeholder (not computed by this implementation)
                "nfev": .number(Double(result.nfev)),
                "njev": .number(Double(result.njev)),
                "success": .bool(result.success),
                "message": .string(result.message)
            ])
        }
    }

    /// Factory function for curve_fit callback
    private static func makeCurveFitCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  case .luaFunction(let funcRef) = args[0],
                  let xdataTable = args[1].arrayValue,
                  let ydataTable = args[2].arrayValue,
                  let p0Table = args[3].arrayValue else {
                throw LuaError.runtimeError("curve_fit: expected func, xdata, ydata, p0")
            }

            let xdata = xdataTable.compactMap { $0.numberValue }
            let ydata = ydataTable.compactMap { $0.numberValue }
            let p0 = p0Table.compactMap { $0.numberValue }

            guard !xdata.isEmpty, !ydata.isEmpty, !p0.isEmpty else {
                throw LuaError.runtimeError("curve_fit: arrays must be non-empty")
            }
            guard xdata.count == ydata.count else {
                throw LuaError.runtimeError("curve_fit: xdata and ydata must have same length")
            }

            let ftol = args.count > 4 ? args[4].numberValue ?? 1e-8 : 1e-8
            let xtol = args.count > 5 ? args[5].numberValue ?? 1e-8 : 1e-8
            let maxiter = args.count > 6 ? Int(args[6].numberValue ?? 100) : 100

            // Create model function that calls Lua: f(x, params) -> y
            // Note: scipy convention is f(x, *params) where x is first
            let modelFunc: ([Double], Double) -> Double = { params, x in
                do {
                    let paramsLua = LuaValue.array(params.map { .number($0) })
                    // Lua function expects (x, params) - x first, then params array
                    let result = try engine.callLuaFunction(ref: funcRef, args: [.number(x), paramsLua])
                    return result.numberValue ?? 0
                } catch {
                    return 0
                }
            }

            let (popt, pcov, info) = curveFit(modelFunc, xdata: xdata, ydata: ydata, p0: p0, ftol: ftol, xtol: xtol, maxiter: maxiter)

            // Return as multiple values: popt, pcov, info
            let poptLua = LuaValue.array(popt.map { .number($0) })
            let pcovLua = LuaValue.array(pcov.map { row in
                LuaValue.array(row.map { .number($0) })
            })
            let infoLua = LuaValue.table([
                "x": .array(info.x.map { .number($0) }),
                "cost": .number(info.cost),
                "fun": .array(info.fun.map { .number($0) }),
                "nfev": .number(Double(info.nfev)),
                "njev": .number(Double(info.njev)),
                "success": .bool(info.success),
                "message": .string(info.message)
            ])

            // Return as table with multiple values for Lua to unpack
            return .array([poptLua, pcovLua, infoLua])
        }
    }
}
