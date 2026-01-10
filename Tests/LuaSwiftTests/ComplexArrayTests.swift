//
//  ComplexArrayTests.swift
//  LuaSwiftTests
//
//  Comprehensive test suite for complex array functionality.
//  Tests cover: split storage format, arithmetic, math functions,
//  LinAlg operations, edge cases, type promotion, and MathExpr integration.
//
//  Created by Claude on 2026-01-10.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

import XCTest
@testable import LuaSwift

final class ComplexArrayTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        do {
            engine = try LuaEngine()
            ModuleRegistry.installArrayModule(in: engine)
            ModuleRegistry.installLinAlgModule(in: engine)
            ComplexModule.register(in: engine)
            MathExprModule.register(in: engine)
        } catch {
            XCTFail("Failed to initialize engine: \(error)")
        }
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Core Storage Tests

    func testComplexArrayCreation() throws {
        let result = try engine.evaluate("""
            local np = luaswift.array
            local real = np.array({1, 2, 3})
            local imag = np.array({4, 5, 6})
            local z = np.complex_array(real, imag)
            return {dtype = z:dtype(), size = z:size(), iscomplex = z:iscomplex()}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["dtype"]?.stringValue, "complex128")
        XCTAssertEqual(table["size"]?.numberValue, 3)
        XCTAssertEqual(table["iscomplex"]?.boolValue, true)
    }

    func testComplexFromPolarCreation() throws {
        // Test creating complex array using from_polar
        let result = try engine.evaluate("""
            local np = luaswift.array
            local r = np.array({1, 1, 1})
            local theta = np.array({0, math.pi/2, math.pi})
            local z = np.from_polar(r, theta)
            return {dtype = z:dtype(), size = z:size(), iscomplex = z:iscomplex()}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["dtype"]?.stringValue, "complex128")
        XCTAssertEqual(table["size"]?.numberValue, 3)
        XCTAssertEqual(table["iscomplex"]?.boolValue, true)
    }

    func testFromPolar() throws {
        // Test creating complex array from polar coordinates
        // r=1, theta=pi/2 should give 0+1i
        let result = try engine.evaluate("""
            local np = luaswift.array
            local r = np.array({1, 2, 1})
            local theta = np.array({math.pi/2, 0, math.pi})
            local z = np.from_polar(r, theta)
            local real_part = z:real()
            local imag_part = z:imag()
            return {
                re1 = real_part:get(1),
                im1 = imag_part:get(1),
                re2 = real_part:get(2),
                im2 = imag_part:get(2),
                re3 = real_part:get(3),
                im3 = imag_part:get(3)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // r=1, theta=pi/2 -> 0+1i
        XCTAssertEqual(table["re1"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["im1"]?.numberValue ?? 0, 1, accuracy: 1e-10)
        // r=2, theta=0 -> 2+0i
        XCTAssertEqual(table["re2"]?.numberValue ?? 0, 2, accuracy: 1e-10)
        XCTAssertEqual(table["im2"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        // r=1, theta=pi -> -1+0i
        XCTAssertEqual(table["re3"]?.numberValue ?? 0, -1, accuracy: 1e-10)
        XCTAssertEqual(table["im3"]?.numberValue ?? 0, 0, accuracy: 1e-10)
    }

    func testRealImagExtraction() throws {
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({1, 2, 3}), np.array({4, 5, 6}))
            local r = z:real()
            local i = z:imag()
            return {
                r1 = r:get(1), r2 = r:get(2), r3 = r:get(3),
                i1 = i:get(1), i2 = i:get(2), i3 = i:get(3),
                r_dtype = r:dtype(), i_dtype = i:dtype()
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["r1"]?.numberValue, 1)
        XCTAssertEqual(table["r2"]?.numberValue, 2)
        XCTAssertEqual(table["r3"]?.numberValue, 3)
        XCTAssertEqual(table["i1"]?.numberValue, 4)
        XCTAssertEqual(table["i2"]?.numberValue, 5)
        XCTAssertEqual(table["i3"]?.numberValue, 6)
        XCTAssertEqual(table["r_dtype"]?.stringValue, "float64")
        XCTAssertEqual(table["i_dtype"]?.stringValue, "float64")
    }

    func testRealArrayImagExtraction() throws {
        // Extracting imag from a real array should return zeros
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.array({1, 2, 3})
            local i = a:imag()
            return {
                i1 = i:get(1), i2 = i:get(2), i3 = i:get(3),
                iscomplex = a:iscomplex()
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["i1"]?.numberValue, 0)
        XCTAssertEqual(table["i2"]?.numberValue, 0)
        XCTAssertEqual(table["i3"]?.numberValue, 0)
        XCTAssertEqual(table["iscomplex"]?.boolValue, false)
    }

    // MARK: - Complex Arithmetic Tests

    func testComplexAddition() throws {
        // (1+2i) + (3+4i) = (4+6i)
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.complex_array(np.array({1}), np.array({2}))
            local b = np.complex_array(np.array({3}), np.array({4}))
            local c = a + b
            return {re = c:real():get(1), im = c:imag():get(1)}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue, 4)
        XCTAssertEqual(table["im"]?.numberValue, 6)
    }

    func testComplexSubtraction() throws {
        // (5+3i) - (2+1i) = (3+2i)
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.complex_array(np.array({5}), np.array({3}))
            local b = np.complex_array(np.array({2}), np.array({1}))
            local c = a - b
            return {re = c:real():get(1), im = c:imag():get(1)}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue, 3)
        XCTAssertEqual(table["im"]?.numberValue, 2)
    }

    func testComplexMultiplication() throws {
        // (1+2i) * (3+4i) = (3+4i+6i+8i²) = (3-8) + (4+6)i = -5+10i
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.complex_array(np.array({1}), np.array({2}))
            local b = np.complex_array(np.array({3}), np.array({4}))
            local c = a * b
            return {re = c:real():get(1), im = c:imag():get(1)}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, -5, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 10, accuracy: 1e-10)
    }

    func testComplexDivision() throws {
        // (1+2i) / (1+1i) = (1+2i)(1-1i) / 2 = (3+1i) / 2 = 1.5+0.5i
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.complex_array(np.array({1}), np.array({2}))
            local b = np.complex_array(np.array({1}), np.array({1}))
            local c = a / b
            return {re = c:real():get(1), im = c:imag():get(1)}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, 1.5, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 0.5, accuracy: 1e-10)
    }

    func testComplexConjugate() throws {
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({1, 2}), np.array({3, -4}))
            local conj = z:conj()
            return {
                re1 = conj:real():get(1), im1 = conj:imag():get(1),
                re2 = conj:real():get(2), im2 = conj:imag():get(2)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re1"]?.numberValue, 1)
        XCTAssertEqual(table["im1"]?.numberValue, -3)
        XCTAssertEqual(table["re2"]?.numberValue, 2)
        XCTAssertEqual(table["im2"]?.numberValue, 4)
    }

    func testComplexAbsolute() throws {
        // |3+4i| = 5
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({3, 0}), np.array({4, 1}))
            local abs_z = np.abs(z)
            return {
                abs1 = abs_z:get(1),
                abs2 = abs_z:get(2),
                dtype = abs_z:dtype()
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["abs1"]?.numberValue ?? 0, 5, accuracy: 1e-10)
        XCTAssertEqual(table["abs2"]?.numberValue ?? 0, 1, accuracy: 1e-10)
        XCTAssertEqual(table["dtype"]?.stringValue, "float64")  // abs returns real
    }

    func testComplexArg() throws {
        // arg(1+1i) = pi/4
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({1, -1}), np.array({1, 0}))
            local arg_z = z:arg()
            return {
                arg1 = arg_z:get(1),
                arg2 = arg_z:get(2),
                dtype = arg_z:dtype()
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["arg1"]?.numberValue ?? 0, Double.pi / 4, accuracy: 1e-10)
        XCTAssertEqual(table["arg2"]?.numberValue ?? 0, Double.pi, accuracy: 1e-10)
        XCTAssertEqual(table["dtype"]?.stringValue, "float64")  // arg returns real
    }

    // MARK: - Type Promotion Tests

    func testRealPlusComplex() throws {
        // real + complex -> complex
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.array({1, 2, 3})
            local b = np.complex_array(np.array({4, 5, 6}), np.array({1, 1, 1}))
            local c = a + b
            return {
                dtype = c:dtype(),
                re1 = c:real():get(1),
                im1 = c:imag():get(1)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["dtype"]?.stringValue, "complex128")
        XCTAssertEqual(table["re1"]?.numberValue, 5)
        XCTAssertEqual(table["im1"]?.numberValue, 1)
    }

    func testComplexPlusReal() throws {
        // complex + real -> complex
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.complex_array(np.array({1, 2}), np.array({3, 4}))
            local b = np.array({10, 20})
            local c = a + b
            return {
                dtype = c:dtype(),
                re1 = c:real():get(1),
                im1 = c:imag():get(1)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["dtype"]?.stringValue, "complex128")
        XCTAssertEqual(table["re1"]?.numberValue, 11)
        XCTAssertEqual(table["im1"]?.numberValue, 3)
    }

    func testRealTimesReal() throws {
        // real * real -> real (no promotion)
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.array({1, 2, 3})
            local b = np.array({4, 5, 6})
            local c = a * b
            return {dtype = c:dtype(), iscomplex = c:iscomplex()}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["dtype"]?.stringValue, "float64")
        XCTAssertEqual(table["iscomplex"]?.boolValue, false)
    }

    // MARK: - Complex Math Functions Tests

    func testComplexExp() throws {
        // exp(0+i*pi) = -1 (Euler's identity)
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({0}), np.array({math.pi}))
            local exp_z = np.exp(z)
            return {
                re = exp_z:real():get(1),
                im = exp_z:imag():get(1)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, -1, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 0, accuracy: 1e-10)
    }

    func testComplexLog() throws {
        // log(e) = 1, log(-1) = i*pi
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({math.exp(1), -1}), np.array({0, 0}))
            local log_z = np.log(z)
            return {
                re1 = log_z:real():get(1),
                im1 = log_z:imag():get(1),
                re2 = log_z:real():get(2),
                im2 = log_z:imag():get(2)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re1"]?.numberValue ?? 0, 1, accuracy: 1e-10)
        XCTAssertEqual(table["im1"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["re2"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["im2"]?.numberValue ?? 0, Double.pi, accuracy: 1e-10)
    }

    func testComplexSqrt() throws {
        // sqrt(0+1i) should give (1+i)/sqrt(2) ~ 0.707+0.707i
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({0}), np.array({1}))
            local sqrt_z = np.sqrt(z)
            return {
                re = sqrt_z:real():get(1),
                im = sqrt_z:imag():get(1)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        let expected = 1.0 / sqrt(2.0)
        XCTAssertEqual(table["re"]?.numberValue ?? 0, expected, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, expected, accuracy: 1e-10)
    }

    func testCsqrtNegativeReal() throws {
        // csqrt(-4) = 2i
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.array({-4, -9, 4})
            local sqrt_a = np.csqrt(a)
            return {
                re1 = sqrt_a:real():get(1),
                im1 = sqrt_a:imag():get(1),
                re2 = sqrt_a:real():get(2),
                im2 = sqrt_a:imag():get(2),
                re3 = sqrt_a:real():get(3),
                im3 = sqrt_a:imag():get(3),
                dtype = sqrt_a:dtype()
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // csqrt(-4) = 2i
        XCTAssertEqual(table["re1"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["im1"]?.numberValue ?? 0, 2, accuracy: 1e-10)
        // csqrt(-9) = 3i
        XCTAssertEqual(table["re2"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["im2"]?.numberValue ?? 0, 3, accuracy: 1e-10)
        // csqrt(4) = 2 (real)
        XCTAssertEqual(table["re3"]?.numberValue ?? 0, 2, accuracy: 1e-10)
        XCTAssertEqual(table["im3"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["dtype"]?.stringValue, "complex128")
    }

    func testClogNegativeReal() throws {
        // clog(-1) = i*pi
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.array({-1, -math.exp(1)})
            local log_a = np.clog(a)
            return {
                re1 = log_a:real():get(1),
                im1 = log_a:imag():get(1),
                re2 = log_a:real():get(2),
                im2 = log_a:imag():get(2)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // clog(-1) = i*pi
        XCTAssertEqual(table["re1"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["im1"]?.numberValue ?? 0, Double.pi, accuracy: 1e-10)
        // clog(-e) = 1 + i*pi
        XCTAssertEqual(table["re2"]?.numberValue ?? 0, 1, accuracy: 1e-10)
        XCTAssertEqual(table["im2"]?.numberValue ?? 0, Double.pi, accuracy: 1e-10)
    }

    func testComplexSinCos() throws {
        // sin(i*x) = i*sinh(x), cos(i*x) = cosh(x)
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({0}), np.array({1}))  -- i
            local sin_z = np.sin(z)
            local cos_z = np.cos(z)
            return {
                sin_re = sin_z:real():get(1),
                sin_im = sin_z:imag():get(1),
                cos_re = cos_z:real():get(1),
                cos_im = cos_z:imag():get(1)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // sin(i) = i*sinh(1)
        XCTAssertEqual(table["sin_re"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["sin_im"]?.numberValue ?? 0, sinh(1.0), accuracy: 1e-10)
        // cos(i) = cosh(1)
        XCTAssertEqual(table["cos_re"]?.numberValue ?? 0, cosh(1.0), accuracy: 1e-10)
        XCTAssertEqual(table["cos_im"]?.numberValue ?? 0, 0, accuracy: 1e-10)
    }

    // MARK: - Complex LinAlg Tests

    func testComplexEigenvalues() throws {
        // Rotation matrix [[0,-1],[1,0]] has eigenvalues +i, -i
        // Use proper complex matrix format with dtype and nested arrays
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = {
                rows = 2,
                shape = {2, 2},
                dtype = "complex128",
                real = {{0, -1}, {1, 0}},
                imag = {{0, 0}, {0, 0}}
            }
            local vals = linalg.ceigvals(A)
            return {
                re1 = vals.real[1], im1 = vals.imag[1],
                re2 = vals.real[2], im2 = vals.imag[2]
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // Eigenvalues should be +i and -i (order may vary)
        let re1 = table["re1"]?.numberValue ?? 0
        let im1 = table["im1"]?.numberValue ?? 0
        let re2 = table["re2"]?.numberValue ?? 0
        let im2 = table["im2"]?.numberValue ?? 0

        // Both real parts should be 0
        XCTAssertEqual(re1, 0, accuracy: 1e-10)
        XCTAssertEqual(re2, 0, accuracy: 1e-10)
        // Imaginary parts should be +1 and -1
        XCTAssertEqual(Swift.abs(im1), 1, accuracy: 1e-10)
        XCTAssertEqual(Swift.abs(im2), 1, accuracy: 1e-10)
        XCTAssertEqual(im1 + im2, 0, accuracy: 1e-10)  // Sum should be 0
    }

    func testComplexSVD() throws {
        // SVD of complex matrix - use row-major flat format
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- A = [[1, 2+i], [3+i, 4]] in row-major flat format
            local A = {rows = 2, cols = 2, real = {1, 2, 3, 4}, imag = {0, 1, 1, 0}}
            local U, S, Vt = linalg.csvd(A)
            -- Singular values should be real and positive
            return {
                s1 = S.data[1], s2 = S.data[2],
                s1_positive = S.data[1] > 0,
                s2_positive = S.data[2] > 0
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["s1_positive"]?.boolValue, true)
        XCTAssertEqual(table["s2_positive"]?.boolValue, true)
    }

    func testComplexDeterminant() throws {
        // det of diagonal complex matrix [[1+i, 0], [0, 2-i]] = (1+i)(2-i) = 3+i
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = {
                real = {{1, 0}, {0, 2}},
                imag = {{1, 0}, {0, -1}},
                shape = {2, 2},
                dtype = 'complex128'
            }
            local det = linalg.cdet(A)
            return {re = det.re, im = det.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // (1+i)(2-i) = 2 - i + 2i - i² = 2 + i + 1 = 3 + i
        XCTAssertEqual(table["re"]?.numberValue ?? 0, 3, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 1, accuracy: 1e-10)
    }

    func testComplexInverse() throws {
        // A * A^(-1) = I
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            local A = {
                real = {{1, 0}, {0, 2}},
                imag = {{1, 0}, {0, -1}},
                shape = {2, 2},
                dtype = 'complex128'
            }
            local Ainv = linalg.cinv(A)
            -- Compute A * Ainv, should be identity
            -- For diagonal: (1+i)^(-1) = (1-i)/2, (2-i)^(-1) = (2+i)/5
            return {
                inv_re_11 = Ainv.real[1],
                inv_im_11 = Ainv.imag[1],
                inv_re_22 = Ainv.real[4],
                inv_im_22 = Ainv.imag[4]
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // (1+i)^(-1) = (1-i)/((1+i)(1-i)) = (1-i)/2
        XCTAssertEqual(table["inv_re_11"]?.numberValue ?? 0, 0.5, accuracy: 1e-10)
        XCTAssertEqual(table["inv_im_11"]?.numberValue ?? 0, -0.5, accuracy: 1e-10)
        // (2-i)^(-1) = (2+i)/((2-i)(2+i)) = (2+i)/5
        XCTAssertEqual(table["inv_re_22"]?.numberValue ?? 0, 0.4, accuracy: 1e-10)
        XCTAssertEqual(table["inv_im_22"]?.numberValue ?? 0, 0.2, accuracy: 1e-10)
    }

    func testComplexSolve() throws {
        // Solve Ax = b for complex system
        // A = [[1+i, 0], [0, 1-i]], b = [2+2i, 2-2i]
        // Solution: x1 = (2+2i)/(1+i) = 2, x2 = (2-2i)/(1-i) = 2
        let result = try engine.evaluate("""
            local linalg = luaswift.linalg
            -- Row-major flat format: A[1,1]=1+i, A[1,2]=0, A[2,1]=0, A[2,2]=1-i
            local A = {rows = 2, cols = 2, real = {1, 0, 0, 1}, imag = {1, 0, 0, -1}}
            local b = {rows = 2, cols = 1, real = {2, 2}, imag = {2, -2}}
            local x = linalg.csolve(A, b)
            return {
                x1_re = x.real[1], x1_im = x.imag[1],
                x2_re = x.real[2], x2_im = x.imag[2]
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["x1_re"]?.numberValue ?? 0, 2, accuracy: 1e-10)
        XCTAssertEqual(table["x1_im"]?.numberValue ?? 0, 0, accuracy: 1e-10)
        XCTAssertEqual(table["x2_re"]?.numberValue ?? 0, 2, accuracy: 1e-10)
        XCTAssertEqual(table["x2_im"]?.numberValue ?? 0, 0, accuracy: 1e-10)
    }

    // MARK: - Scalar-Array Interop Tests

    func testComplexScalarTimesArray() throws {
        // complex scalar * real array -> complex array
        // Using {re, im} table format for complex scalars
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = {re = 2, im = 3}  -- 2+3i
            local a = np.array({1, 2, 3})
            local c = z * a
            return {
                dtype = c:dtype(),
                re1 = c:real():get(1), im1 = c:imag():get(1),
                re2 = c:real():get(2), im2 = c:imag():get(2)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["dtype"]?.stringValue, "complex128")
        // (2+3i) * 1 = 2+3i
        XCTAssertEqual(table["re1"]?.numberValue ?? 0, 2, accuracy: 1e-10)
        XCTAssertEqual(table["im1"]?.numberValue ?? 0, 3, accuracy: 1e-10)
        // (2+3i) * 2 = 4+6i
        XCTAssertEqual(table["re2"]?.numberValue ?? 0, 4, accuracy: 1e-10)
        XCTAssertEqual(table["im2"]?.numberValue ?? 0, 6, accuracy: 1e-10)
    }

    func testRealScalarTimesComplexArray() throws {
        // real scalar * complex array -> complex array
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({1, 2}), np.array({3, 4}))
            local c = 2 * z
            return {
                re1 = c:real():get(1), im1 = c:imag():get(1),
                re2 = c:real():get(2), im2 = c:imag():get(2)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // 2 * (1+3i) = 2+6i
        XCTAssertEqual(table["re1"]?.numberValue ?? 0, 2, accuracy: 1e-10)
        XCTAssertEqual(table["im1"]?.numberValue ?? 0, 6, accuracy: 1e-10)
        // 2 * (2+4i) = 4+8i
        XCTAssertEqual(table["re2"]?.numberValue ?? 0, 4, accuracy: 1e-10)
        XCTAssertEqual(table["im2"]?.numberValue ?? 0, 8, accuracy: 1e-10)
    }

    // MARK: - MathExpr Integration Tests

    func testMathExprComplexLiteral() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("2+3i")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue, 2)
        XCTAssertEqual(table["im"]?.numberValue, 3)
    }

    func testMathExprImaginaryUnit() throws {
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("1i^2")
            if type(z) == "table" then
                return z.re
            else
                return z
            end
        """)

        XCTAssertEqual(result.numberValue ?? 0, -1, accuracy: 1e-10)
    }

    func testMathExprComplexArithmetic() throws {
        // (1+2i) * (3+4i) = -5+10i
        let result = try engine.evaluate("""
            local mathexpr = require("luaswift.mathexpr")
            local z = mathexpr.eval("(1+2i)*(3+4i)")
            return {re = z.re, im = z.im}
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re"]?.numberValue ?? 0, -5, accuracy: 1e-10)
        XCTAssertEqual(table["im"]?.numberValue ?? 0, 10, accuracy: 1e-10)
    }

    // MARK: - Edge Cases Tests

    func testComplexDivisionByZero() throws {
        let result = try engine.evaluate("""
            local np = luaswift.array
            local a = np.complex_array(np.array({1}), np.array({1}))
            local b = np.complex_array(np.array({0}), np.array({0}))
            local c = a / b
            local re = c:real():get(1)
            local im = c:imag():get(1)
            return {
                re_is_inf = re == math.huge or re ~= re,  -- inf or nan
                im_is_inf = im == math.huge or im ~= im
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        // Division by zero should produce inf or nan
        XCTAssertEqual(table["re_is_inf"]?.boolValue, true)
    }

    func testSingleElementComplexArray() throws {
        // Test creating a single-element complex array
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({5}), np.array({7}))
            return {
                size = z:size(),
                dtype = z:dtype(),
                re = z:real():get(1),
                im = z:imag():get(1)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["size"]?.numberValue, 1)
        XCTAssertEqual(table["dtype"]?.stringValue, "complex128")
        XCTAssertEqual(table["re"]?.numberValue, 5)
        XCTAssertEqual(table["im"]?.numberValue, 7)
    }

    func testComplexNanHandling() throws {
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({0/0, 1}), np.array({1, 0/0}))
            local re = z:real()
            local im = z:imag()
            return {
                re1_is_nan = re:get(1) ~= re:get(1),
                im2_is_nan = im:get(2) ~= im:get(2)
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re1_is_nan"]?.boolValue, true)
        XCTAssertEqual(table["im2_is_nan"]?.boolValue, true)
    }

    func testComplexInfHandling() throws {
        let result = try engine.evaluate("""
            local np = luaswift.array
            local z = np.complex_array(np.array({math.huge, 1}), np.array({1, math.huge}))
            local re = z:real()
            local im = z:imag()
            return {
                re1_is_inf = re:get(1) == math.huge,
                im2_is_inf = im:get(2) == math.huge
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table")
            return
        }

        XCTAssertEqual(table["re1_is_inf"]?.boolValue, true)
        XCTAssertEqual(table["im2_is_inf"]?.boolValue, true)
    }

    // MARK: - Performance Benchmark Tests

    func testComplexArithmeticPerformance() throws {
        // Benchmark complex arithmetic on 10,000 elements
        measure {
            do {
                _ = try engine.evaluate("""
                    local np = luaswift.array
                    local n = 10000
                    local re_data = {}
                    local im_data = {}
                    for i = 1, n do
                        re_data[i] = i
                        im_data[i] = i * 0.5
                    end
                    local a = np.complex_array(np.array(re_data), np.array(im_data))
                    local b = np.complex_array(np.array(im_data), np.array(re_data))
                    local c = a * b + a - b
                    return c:size()
                """)
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }

    func testComplexMathFunctionsPerformance() throws {
        // Benchmark complex exp on 5,000 elements
        measure {
            do {
                _ = try engine.evaluate("""
                    local np = luaswift.array
                    local n = 5000
                    local re_data = {}
                    local im_data = {}
                    for i = 1, n do
                        re_data[i] = math.cos(i * 0.01)
                        im_data[i] = math.sin(i * 0.01)
                    end
                    local z = np.complex_array(np.array(re_data), np.array(im_data))
                    local exp_z = np.exp(z)
                    return exp_z:size()
                """)
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
}
