//
//  ArrayModule+Phase2.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-05-29.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/Modules/Swift/ArrayModule+Phase2.swift
//
//  Context: Entry point of the Phase-2 array bindings (dtype creation,
//  bool ops, int64 reductions, FFT, set operations, advanced indexing).
//  installPhase2 — called from ArrayModule.install(in:)
//  (ArrayModule.swift) — registers the Swift callbacks defined in
//  ArrayModule+Phase2Callbacks.swift, runs the Lua-side wiring from
//  ArrayModule+Phase2Wiring.swift, and, when NumericSwift is available,
//  installs the complex-trig overrides from ArrayModule+ComplexTrig.swift.
//  The shared NDArray <-> Lua-table bridge helpers (extractNDArray,
//  ndArrayToLua) live here because both callback files depend on them.
//

#if LUASWIFT_ARRAYSWIFT

  import Foundation
  import ArraySwift

  // MARK: - Registration extension

  extension ArrayModule {

    /// Install all Phase-2 bindings into `engine`.
    ///
    /// Call from ``ArrayModule/install(in:)`` after the core registrations.
    ///
    /// - Throws: An error if the Phase-2 Lua wiring fails to run.
    internal static func installPhase2(in engine: LuaEngine) throws {
      // Phase-2 creation with dtype (separate registrations so the main wrapper's cleanup doesn't affect us)
      engine.registerFunction(name: "_luaswift_array_p2_zeros", callback: p2ZerosCallback)
      engine.registerFunction(name: "_luaswift_array_p2_ones", callback: p2OnesCallback)
      engine.registerFunction(name: "_luaswift_array_p2_full", callback: p2FullCallback)

      // Bool ops
      engine.registerFunction(name: "_luaswift_array_logical_and", callback: logicalAndCallback)
      engine.registerFunction(name: "_luaswift_array_logical_or", callback: logicalOrCallback)
      engine.registerFunction(name: "_luaswift_array_logical_xor", callback: logicalXorCallback)
      engine.registerFunction(name: "_luaswift_array_logical_not", callback: logicalNotCallback)

      // Int64 array-returning reductions
      engine.registerFunction(name: "_luaswift_array_argmax_array", callback: argmaxArrayCallback)
      engine.registerFunction(name: "_luaswift_array_argmin_array", callback: argminArrayCallback)
      engine.registerFunction(name: "_luaswift_array_argsort_nd", callback: argsortNDCallback)

      // FFT
      engine.registerFunction(name: "_luaswift_array_fft", callback: fftCallback)
      engine.registerFunction(name: "_luaswift_array_ifft", callback: ifftCallback)
      engine.registerFunction(name: "_luaswift_array_rfft", callback: rfftCallback)
      engine.registerFunction(name: "_luaswift_array_fft2", callback: fft2Callback)
      engine.registerFunction(name: "_luaswift_array_ifft2", callback: ifft2Callback)
      engine.registerFunction(name: "_luaswift_array_fftn", callback: fftnCallback)
      engine.registerFunction(name: "_luaswift_array_ifftn", callback: fftnCallback)
      engine.registerFunction(name: "_luaswift_array_fftfreq", callback: fftfreqCallback)

      // Set operations
      engine.registerFunction(name: "_luaswift_array_intersect1d", callback: intersect1dCallback)
      engine.registerFunction(name: "_luaswift_array_union1d", callback: union1dCallback)
      engine.registerFunction(name: "_luaswift_array_setdiff1d", callback: setdiff1dCallback)
      engine.registerFunction(name: "_luaswift_array_setxor1d", callback: setxor1dCallback)
      engine.registerFunction(name: "_luaswift_array_in1d", callback: in1dCallback)

      // Advanced indexing
      engine.registerFunction(name: "_luaswift_array_getmask", callback: getmaskCallback)
      engine.registerFunction(name: "_luaswift_array_gather", callback: gatherCallback)
      engine.registerFunction(name: "_luaswift_array_get_neg", callback: getNegCallback)
      engine.registerFunction(name: "_luaswift_array_maskset", callback: masksetCallback)

      // Lua-side wiring: wire new functions into luaswift.array namespace
      try engine.run(luaPhase2Wrapper)

      // Complex trig dispatch (requires NumericSwift)
      #if LUASWIFT_NUMERICSWIFT
      try installComplexTrig(in: engine)
      #endif
    }

    // MARK: - NDArray extraction helper

    /// Extract an `NDArray` from a Lua array table, preserving dtype.
    /// internal: shared with ArrayModule+Phase2Callbacks/+ComplexTrig
    internal static func extractNDArray(_ value: LuaValue) throws -> NDArray {
      guard let table = value.tableValue,
        let shapeValue = table["shape"],
        let dataValue = table["data"]
      else {
        throw LuaError.callbackError("array: expected array table")
      }

      // Shape
      var shape: [Int] = []
      if let arr = shapeValue.arrayValue {
        shape = arr.compactMap { $0.intValue }
      } else if let tbl = shapeValue.tableValue {
        var i = 1
        while let d = tbl[String(i)]?.intValue { shape.append(d); i += 1 }
      }
      guard !shape.isEmpty else {
        throw LuaError.callbackError("array: empty shape")
      }

      let dtypeStr = table["dtype"]?.stringValue
      let dtype = ArrayDType(from: dtypeStr)

      // Real data
      var realData: [Double] = []
      if let arr = dataValue.arrayValue {
        realData = arr.compactMap { $0.numberValue }
      } else if let tbl = dataValue.tableValue {
        var i = 1
        while let v = tbl[String(i)]?.numberValue { realData.append(v); i += 1 }
      }

      switch dtype {
      case .int64:
        return NDArray(shape: shape, int64Data: realData.map { Int64($0) })
      case .bool:
        return NDArray(shape: shape, boolData: realData.map { $0 != 0 })
      case .complex128:
        var imagData: [Double] = []
        if let imagValue = table["imag"] {
          if let arr = imagValue.arrayValue {
            imagData = arr.compactMap { $0.numberValue }
          } else if let tbl = imagValue.tableValue {
            var i = 1
            while let v = tbl[String(i)]?.numberValue { imagData.append(v); i += 1 }
          }
        }
        if imagData.count != realData.count {
          imagData = [Double](repeating: 0, count: realData.count)
        }
        return NDArray(shape: shape, dtype: .complex128, real: realData, imag: imagData)
      default:
        return NDArray(shape: shape, data: realData)
      }
    }

    /// Serialize an `NDArray` to a Lua value table, preserving dtype.
    /// internal: shared with ArrayModule+Phase2Callbacks/+ComplexTrig
    internal static func ndArrayToLua(_ arr: NDArray) -> LuaValue {
      var table: [String: LuaValue] = [
        "shape": .array(arr.shape.map { .number(Double($0)) }),
        "dtype": .string(arr.dtype.rawValue),
        "data": .array(arr.real.map { .number($0) }),
      ]

      // For complex arrays, include the imaginary part
      if arr.dtype == .complex128, let im = arr.imag {
        table["imag"] = .array(im.map { .number($0) })
      }

      return .table(table)
    }
  }

#endif  // LUASWIFT_ARRAYSWIFT
