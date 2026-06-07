//
//  ComplexMathDispatchTests.swift
//  LuaSwiftTests
//
//  Tests for task #115: complex-aware NDArray trig and unified math dispatch.
//
//  Created by Christian C. Berclaz on 2026-05-29.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

#if LUASWIFT_ARRAYSWIFT && LUASWIFT_NUMERICSWIFT
  import XCTest
  @testable import LuaSwift

  // MARK: - Complex Array Trig Tests

  final class ComplexArrayTrigTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        try ArrayModule.install(in: engine)
        try ComplexModule.install(in: engine)
        try MathXModule.install(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testComplexArraySin() throws {
      // sin(0 + 0i) = 0
      let result = try engine.evaluate("""
        local np = luaswift.array
        local real = np.zeros({1})
        local imag = np.zeros({1})
        local z = np.complex_array(real, imag)
        local s = np.sin(z)
        return {dtype = s:dtype(), re = s:real():get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["re"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
    }

    func testComplexArrayCos() throws {
      // cos(0) = 1
      let result = try engine.evaluate("""
        local np = luaswift.array
        local real = np.zeros({1})
        local imag = np.zeros({1})
        local z = np.complex_array(real, imag)
        local c = np.cos(z)
        return {dtype = c:dtype(), re = c:real():get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["re"]?.numberValue ?? 0, 1.0, accuracy: 1e-10)
    }

    func testComplexArrayTan() throws {
      // tan(0) = 0
      let result = try engine.evaluate("""
        local np = luaswift.array
        local real = np.zeros({1})
        local imag = np.zeros({1})
        local z = np.complex_array(real, imag)
        local t = np.tan(z)
        return {dtype = t:dtype(), re = t:real():get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["re"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
    }

    func testComplexArraySinh() throws {
      // sinh(0) = 0
      let result = try engine.evaluate("""
        local np = luaswift.array
        local real = np.zeros({1})
        local imag = np.zeros({1})
        local z = np.complex_array(real, imag)
        local s = np.sinh(z)
        return {dtype = s:dtype(), re = s:real():get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["re"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
    }

    func testComplexArrayCosh() throws {
      // cosh(0) = 1
      let result = try engine.evaluate("""
        local np = luaswift.array
        local real = np.zeros({1})
        local imag = np.zeros({1})
        local z = np.complex_array(real, imag)
        local c = np.cosh(z)
        return {dtype = c:dtype(), re = c:real():get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["re"]?.numberValue ?? 0, 1.0, accuracy: 1e-10)
    }

    func testComplexArrayTanh() throws {
      // tanh(0) = 0
      let result = try engine.evaluate("""
        local np = luaswift.array
        local real = np.zeros({1})
        local imag = np.zeros({1})
        local z = np.complex_array(real, imag)
        local t = np.tanh(z)
        return {dtype = t:dtype(), re = t:real():get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["re"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
    }

    func testComplexArraySinNonZero() throws {
      // sin(i) = i*sinh(1) ≈ 1.1752i
      let result = try engine.evaluate("""
        local np = luaswift.array
        local real = np.zeros({1})
        local imag = np.ones({1})
        local z = np.complex_array(real, imag)
        local s = np.sin(z)
        -- sin(0+1i) = i*sinh(1)
        return {re = s:real():get(1), im = s:imag():get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["re"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
      XCTAssertEqual(t["im"]?.numberValue ?? 0, 1.1752011936438014, accuracy: 1e-8)
    }
  }

  // MARK: - Unified Math Dispatch Tests

  final class UnifiedMathDispatchTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        try ComplexModule.install(in: engine)
        try MathXModule.install(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testMathXSinComplexDispatch() throws {
      // math.sin of a complex number should delegate to complex sin
      let result = try engine.evaluate("""
        local c = luaswift.complex
        local z = c.new(0, 1)  -- i
        local s = luaswift.mathx.sin(z)
        -- sin(i) = i*sinh(1) ≈ 0 + 1.1752i
        return {re = s.re, im = s.im}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["re"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
      XCTAssertEqual(t["im"]?.numberValue ?? 0, 1.1752011936438014, accuracy: 1e-8)
    }

    func testMathXCosComplexDispatch() throws {
      let result = try engine.evaluate("""
        local c = luaswift.complex
        local z = c.new(0, 0)  -- 0
        local r = luaswift.mathx.cos(z)
        return {re = r.re, im = r.im}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["re"]?.numberValue ?? 0, 1.0, accuracy: 1e-10)
      XCTAssertEqual(t["im"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
    }

    func testMathXSinRealUnchanged() throws {
      // Real numbers should go through unmodified
      let result = try engine.evaluate("""
        return luaswift.mathx.sin(0)
      """)
      XCTAssertEqual(result.numberValue ?? 999, 0.0, accuracy: 1e-15)
    }

    func testMathXExpComplexDispatch() throws {
      // exp(0+pi*i) = -1 + 0i (Euler's identity)
      let result = try engine.evaluate("""
        local c = luaswift.complex
        local z = c.new(0, math.pi)
        local r = luaswift.mathx.exp(z)
        return {re = r.re, im = r.im}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["re"]?.numberValue ?? 0, -1.0, accuracy: 1e-10)
      XCTAssertEqual(t["im"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
    }

    func testMathXLogComplexDispatch() throws {
      // log(e + 0i) = 1
      let result = try engine.evaluate("""
        local c = luaswift.complex
        local z = c.new(math.exp(1), 0)
        local r = luaswift.mathx.log(z)
        return {re = r.re, im = r.im}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["re"]?.numberValue ?? 0, 1.0, accuracy: 1e-10)
      XCTAssertEqual(t["im"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
    }

    func testMathXSqrtComplexDispatch() throws {
      // sqrt(-1 + 0i) = 0 + 1i
      let result = try engine.evaluate("""
        local c = luaswift.complex
        local z = c.new(-1, 0)
        local r = luaswift.mathx.sqrt(z)
        return {re = r.re, im = r.im}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["re"]?.numberValue ?? 999, 0.0, accuracy: 1e-10)
      XCTAssertEqual(t["im"]?.numberValue ?? 0, 1.0, accuracy: 1e-10)
    }
  }

  // MARK: - Complex Linear Solve Tests

  final class ComplexLinAlgTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        try LinAlgModule.install(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testCsolveLuaBindingExists() throws {
      // Verify linalg.csolve is callable from Lua
      let result = try engine.evaluate("""
        return type(luaswift.linalg.csolve)
      """)
      XCTAssertEqual(result.stringValue, "function")
    }

    func testCsolveSimpleSystem() throws {
      // Solve [1 0; 0 1] * x = [3; 4] → x = [3; 4]
      let result = try engine.evaluate("""
        local la = luaswift.linalg
        local A = {
            rows = 2, cols = 2, dtype = "complex128",
            real = {1, 0, 0, 1}, imag = {0, 0, 0, 0}
        }
        local b = {
            rows = 2, cols = 1, dtype = "complex128",
            real = {3, 4}, imag = {0, 0}
        }
        local x = la.csolve(A, b)
        return {rows = x.rows, re1 = x.real[1], re2 = x.real[2]}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["rows"]?.numberValue, 2)
      XCTAssertEqual(t["re1"]?.numberValue ?? 0, 3.0, accuracy: 1e-10)
      XCTAssertEqual(t["re2"]?.numberValue ?? 0, 4.0, accuracy: 1e-10)
    }
  }

#endif  // LUASWIFT_ARRAYSWIFT && LUASWIFT_NUMERICSWIFT
