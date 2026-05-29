//
//  ArrayDTypeTests.swift
//  LuaSwiftTests
//
//  Tests for tasks #3/#4: dtype support on creation, bool ops,
//  int64 reductions, FFT, set ops, and advanced indexing.
//
//  Created by Christian C. Berclaz on 2026-05-29.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//

#if LUASWIFT_ARRAYSWIFT
  import XCTest
  @testable import LuaSwift

  // MARK: - Dtype Creation Tests

  final class ArrayDTypeCreationTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        ModuleRegistry.installArrayModule(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testZerosInt64Dtype() throws {
      let result = try engine.evaluate("""
        local a = luaswift.array.zeros({3}, "int64")
        return a:dtype()
      """)
      XCTAssertEqual(result.stringValue, "int64")
    }

    func testZerosBoolDtype() throws {
      let result = try engine.evaluate("""
        local a = luaswift.array.zeros({4}, "bool")
        return a:dtype()
      """)
      XCTAssertEqual(result.stringValue, "bool")
    }

    func testOnesInt64Dtype() throws {
      let result = try engine.evaluate("""
        local a = luaswift.array.ones({3}, "int64")
        return {dtype = a:dtype(), v = a:get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "int64")
      XCTAssertEqual(t["v"]?.numberValue, 1)
    }

    func testFullInt64Dtype() throws {
      let result = try engine.evaluate("""
        local a = luaswift.array.full({2, 2}, 7, "int64")
        return {dtype = a:dtype(), v = a:get(1, 1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "int64")
      XCTAssertEqual(t["v"]?.numberValue, 7)
    }

    func testFullBoolDtype() throws {
      let result = try engine.evaluate("""
        local a = luaswift.array.full({3}, 1, "bool")
        return a:dtype()
      """)
      XCTAssertEqual(result.stringValue, "bool")
    }

    func testZerosFloat64DefaultDtype() throws {
      // Without dtype arg, existing behavior must be preserved
      let result = try engine.evaluate("""
        local a = luaswift.array.zeros({3})
        return a:dtype()
      """)
      XCTAssertEqual(result.stringValue, "float64")
    }

    func testDtypeAccessorOnFloat64() throws {
      let result = try engine.evaluate("""
        local a = luaswift.array.array({1, 2, 3})
        return a:dtype()
      """)
      XCTAssertEqual(result.stringValue, "float64")
    }

    func testNpDtypeFunction() throws {
      let result = try engine.evaluate("""
        local a = luaswift.array.zeros({3}, "int64")
        return luaswift.array.dtype(a)
      """)
      XCTAssertEqual(result.stringValue, "int64")
    }
  }

  // MARK: - Bool Ops Tests

  final class ArrayBoolOpsTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        ModuleRegistry.installArrayModule(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testLogicalAnd() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 0, 1, 0})
        local b = np.array({1, 1, 0, 0})
        local c = np.logical_and(a, b)
        return {dtype = c:dtype(), v1 = c:get(1), v2 = c:get(2), v3 = c:get(3), v4 = c:get(4)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "bool")
      XCTAssertEqual(t["v1"]?.numberValue, 1)  // 1 AND 1 = 1
      XCTAssertEqual(t["v2"]?.numberValue, 0)  // 0 AND 1 = 0
      XCTAssertEqual(t["v3"]?.numberValue, 0)  // 1 AND 0 = 0
      XCTAssertEqual(t["v4"]?.numberValue, 0)  // 0 AND 0 = 0
    }

    func testLogicalOr() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 0, 1, 0})
        local b = np.array({1, 1, 0, 0})
        local c = np.logical_or(a, b)
        return {v1 = c:get(1), v2 = c:get(2), v3 = c:get(3), v4 = c:get(4)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["v1"]?.numberValue, 1)  // 1 OR 1 = 1
      XCTAssertEqual(t["v2"]?.numberValue, 1)  // 0 OR 1 = 1
      XCTAssertEqual(t["v3"]?.numberValue, 1)  // 1 OR 0 = 1
      XCTAssertEqual(t["v4"]?.numberValue, 0)  // 0 OR 0 = 0
    }

    func testLogicalXor() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 0, 1, 0})
        local b = np.array({1, 1, 0, 0})
        local c = np.logical_xor(a, b)
        return {v1 = c:get(1), v2 = c:get(2), v3 = c:get(3), v4 = c:get(4)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["v1"]?.numberValue, 0)  // 1 XOR 1 = 0
      XCTAssertEqual(t["v2"]?.numberValue, 1)  // 0 XOR 1 = 1
      XCTAssertEqual(t["v3"]?.numberValue, 1)  // 1 XOR 0 = 1
      XCTAssertEqual(t["v4"]?.numberValue, 0)  // 0 XOR 0 = 0
    }

    func testLogicalNot() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 0, 1, 0})
        local c = np.logical_not(a)
        return {dtype = c:dtype(), v1 = c:get(1), v2 = c:get(2)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "bool")
      XCTAssertEqual(t["v1"]?.numberValue, 0)  // NOT 1 = 0
      XCTAssertEqual(t["v2"]?.numberValue, 1)  // NOT 0 = 1
    }

    func testIsnanReturnsBoolDtype() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 0/0, 2})
        local mask = np.isnan(a)
        return {dtype = mask:dtype(), v1 = mask:get(1), v2 = mask:get(2), v3 = mask:get(3)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "bool")
      XCTAssertEqual(t["v1"]?.numberValue, 0)
      XCTAssertEqual(t["v2"]?.numberValue, 1)
      XCTAssertEqual(t["v3"]?.numberValue, 0)
    }

    func testIsinfReturnsBoolDtype() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, math.huge, 2})
        local mask = np.isinf(a)
        return {dtype = mask:dtype(), v2 = mask:get(2)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "bool")
      XCTAssertEqual(t["v2"]?.numberValue, 1)
    }

    func testIsfiniteReturnsBoolDtype() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, math.huge, 2, 0/0})
        local mask = np.isfinite(a)
        return {dtype = mask:dtype(), v1 = mask:get(1), v2 = mask:get(2), v3 = mask:get(3)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "bool")
      XCTAssertEqual(t["v1"]?.numberValue, 1)
      XCTAssertEqual(t["v2"]?.numberValue, 0)
      XCTAssertEqual(t["v3"]?.numberValue, 1)
    }

    func testLogicalAndMethodForm() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 0, 1})
        local b = np.array({1, 1, 0})
        local c = a:logical_and(b)
        return c:get(1)
      """)
      XCTAssertEqual(result.numberValue, 1)
    }
  }

  // MARK: - Int64 Reduction Tests

  final class ArrayInt64ReductionTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        ModuleRegistry.installArrayModule(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testArgmaxArrayReturnsInt64() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({3, 1, 4, 1, 5, 9, 2})
        local idx = np.argmax_array(a)
        return {dtype = idx:dtype(), v = idx:get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "int64")
      XCTAssertEqual(t["v"]?.numberValue, 6)  // index 6 (1-based) = value 9
    }

    func testArgminArrayReturnsInt64() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({3, 1, 4, 1, 5, 9, 2})
        local idx = np.argmin_array(a)
        return {dtype = idx:dtype(), v = idx:get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "int64")
      XCTAssertEqual(t["v"]?.numberValue, 2)  // index 2 (1-based) = first value 1
    }

    func testArgsortReturnsInt64() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({3, 1, 4, 1, 5})
        local idx = np.argsort(a)
        return {dtype = idx:dtype(), size = idx:size(), first = idx:get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "int64")
      XCTAssertEqual(t["size"]?.numberValue, 5)
      XCTAssertEqual(t["first"]?.numberValue, 2)  // smallest value 1 is at index 2 (1-based)
    }
  }

  // MARK: - FFT Tests

  final class ArrayFFTTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        ModuleRegistry.installArrayModule(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testFFTRoundTrip() throws {
      // fft then ifft should recover input
      let result = try engine.evaluate("""
        local np = luaswift.array
        local real = np.array({1, 2, 3, 4})
        local imag = np.zeros({4})
        local z = np.complex_array(real, imag)
        local F = np.fft.fft(z)
        local x = np.fft.ifft(F)
        -- x.real should be close to {1,2,3,4}
        return {dtype = x:dtype(), r1 = x:real():get(1), r2 = x:real():get(2)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["r1"]?.numberValue ?? 0, 1.0, accuracy: 1e-10)
      XCTAssertEqual(t["r2"]?.numberValue ?? 0, 2.0, accuracy: 1e-10)
    }

    func testRFFT() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local x = np.array({1, 2, 3, 4})
        local F = np.fft.rfft(x)
        return {dtype = F:dtype(), size = F:size()}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["size"]?.numberValue, 3)  // n/2 + 1 = 4/2 + 1 = 3
    }

    func testFFTFreq() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local f = np.fft.fftfreq(4)
        return {dtype = f:dtype(), size = f:size(), v1 = f:get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "float64")
      XCTAssertEqual(t["size"]?.numberValue, 4)
      XCTAssertEqual(t["v1"]?.numberValue ?? 0, 0.0, accuracy: 1e-15)  // DC bin
    }

    func testFFT2() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        -- 2x2 complex array
        local real = np.array({{1, 0}, {0, 0}})
        local imag = np.zeros({2, 2})
        local z = np.complex_array(real, imag)
        local F = np.fft.fft2(z)
        return {dtype = F:dtype(), size = F:size()}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "complex128")
      XCTAssertEqual(t["size"]?.numberValue, 4)
    }
  }

  // MARK: - Set Ops Tests

  final class ArraySetOpsTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        ModuleRegistry.installArrayModule(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testIntersect1d() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 2, 3, 4})
        local b = np.array({2, 4, 6})
        local c = np.intersect1d(a, b)
        return {size = c:size(), v1 = c:get(1), v2 = c:get(2)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["size"]?.numberValue, 2)
      XCTAssertEqual(t["v1"]?.numberValue, 2)
      XCTAssertEqual(t["v2"]?.numberValue, 4)
    }

    func testUnion1d() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 2, 3})
        local b = np.array({3, 4, 5})
        local c = np.union1d(a, b)
        return {size = c:size()}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["size"]?.numberValue, 5)
    }

    func testSetdiff1d() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 2, 3, 4, 5})
        local b = np.array({2, 4})
        local c = np.setdiff1d(a, b)
        return {size = c:size(), v1 = c:get(1), v2 = c:get(2), v3 = c:get(3)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["size"]?.numberValue, 3)
      XCTAssertEqual(t["v1"]?.numberValue, 1)
      XCTAssertEqual(t["v2"]?.numberValue, 3)
      XCTAssertEqual(t["v3"]?.numberValue, 5)
    }

    func testSetxor1d() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 2, 3})
        local b = np.array({2, 3, 4})
        local c = np.setxor1d(a, b)
        return {size = c:size(), v1 = c:get(1), v2 = c:get(2)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["size"]?.numberValue, 2)
      XCTAssertEqual(t["v1"]?.numberValue, 1)
      XCTAssertEqual(t["v2"]?.numberValue, 4)
    }

    func testIn1d() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local ar1 = np.array({1, 2, 3, 4})
        local ar2 = np.array({2, 4})
        local mask = np.in1d(ar1, ar2)
        return {dtype = mask:dtype(), v1 = mask:get(1), v2 = mask:get(2),
                v3 = mask:get(3), v4 = mask:get(4)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["dtype"]?.stringValue, "bool")
      XCTAssertEqual(t["v1"]?.numberValue, 0)  // 1 not in {2,4}
      XCTAssertEqual(t["v2"]?.numberValue, 1)  // 2 in {2,4}
      XCTAssertEqual(t["v3"]?.numberValue, 0)  // 3 not in {2,4}
      XCTAssertEqual(t["v4"]?.numberValue, 1)  // 4 in {2,4}
    }
  }

  // MARK: - Advanced Indexing Tests

  final class ArrayAdvancedIndexingTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
      super.setUp()
      do {
        engine = try LuaEngine()
        ModuleRegistry.installArrayModule(in: engine)
      } catch {
        XCTFail("Failed to initialize engine: \(error)")
      }
    }

    override func tearDown() {
      engine = nil
      super.tearDown()
    }

    func testBoolMaskGather() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({10, 20, 30, 40, 50})
        local mask = np.array({1, 0, 1, 0, 1})
        local b = np.getmask(a, mask)
        return {size = b:size(), v1 = b:get(1), v2 = b:get(2), v3 = b:get(3)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["size"]?.numberValue, 3)
      XCTAssertEqual(t["v1"]?.numberValue, 10)
      XCTAssertEqual(t["v2"]?.numberValue, 30)
      XCTAssertEqual(t["v3"]?.numberValue, 50)
    }

    func testFancyIndexGather() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({10, 20, 30, 40, 50})
        -- Gather indices 1, 3, 5 (1-based via Lua convention)
        local b = np.gather(a, {1, 3, 5})
        return {size = b:size(), v1 = b:get(1), v2 = b:get(2), v3 = b:get(3)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["size"]?.numberValue, 3)
      XCTAssertEqual(t["v1"]?.numberValue, 10)
      XCTAssertEqual(t["v2"]?.numberValue, 30)
      XCTAssertEqual(t["v3"]?.numberValue, 50)
    }

    func testNegativeIndex() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({10, 20, 30, 40, 50})
        return {last = np.get_neg(a, -1), second_last = np.get_neg(a, -2)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["last"]?.numberValue, 50)
      XCTAssertEqual(t["second_last"]?.numberValue, 40)
    }

    func testMaskSet() throws {
      let result = try engine.evaluate("""
        local np = luaswift.array
        local a = np.array({1, 2, 3, 4, 5})
        local mask = np.array({0, 1, 0, 1, 0})
        np.maskset(a, mask, 99)
        return {v2 = a:get(2), v4 = a:get(4), v1 = a:get(1)}
      """)
      guard let t = result.tableValue else { XCTFail("Expected table"); return }
      XCTAssertEqual(t["v2"]?.numberValue, 99)
      XCTAssertEqual(t["v4"]?.numberValue, 99)
      XCTAssertEqual(t["v1"]?.numberValue, 1)  // unchanged
    }
  }

#endif  // LUASWIFT_ARRAYSWIFT
