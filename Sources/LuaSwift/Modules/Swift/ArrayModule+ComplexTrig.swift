//
//  ArrayModule+ComplexTrig.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/Modules/Swift/ArrayModule+ComplexTrig.swift
//
//  Context: Complex trig dispatch on arrays — requires both ArraySwift
//  and NumericSwift. installComplexTrig is called from installPhase2
//  (ArrayModule+Phase2.swift) when NumericSwift is compiled in; it
//  overrides luaswift.array's real-only tan/sinh/cosh/tanh with
//  versions that dispatch element-wise to NumericSwift's Complex for
//  complex128 arrays and fall back to the Foundation scalar functions
//  otherwise. Argument/result conversion uses extractNDArray and
//  ndArrayToLua (ArrayModule+Phase2.swift).
//

// MARK: - Complex trig dispatch on arrays (requires both ArraySwift + NumericSwift)

#if LUASWIFT_ARRAYSWIFT && LUASWIFT_NUMERICSWIFT

  import Foundation
  import ArraySwift
  import NumericSwift

  extension ArrayModule {

    /// Install complex trig overrides. Call from ``ArrayModule/installPhase2(in:)``
    /// only when NumericSwift is also available.
    ///
    /// - Throws: An error if the complex-trig Lua wiring fails to run.
    internal static func installComplexTrig(in engine: LuaEngine) throws {
      engine.registerFunction(name: "_luaswift_array_cx_tan",  callback: cxTanCallback)
      engine.registerFunction(name: "_luaswift_array_cx_sinh", callback: cxSinhCallback)
      engine.registerFunction(name: "_luaswift_array_cx_cosh", callback: cxCoshCallback)
      engine.registerFunction(name: "_luaswift_array_cx_tanh", callback: cxTanhCallback)

      try engine.run(complexTrigWrapper)
    }

    // MARK: - Complex trig callbacks

    private static func complexTrigOp(
      _ args: [LuaValue],
      name: String,
      realFn: (Double) -> Double,
      complexFn: (Complex) -> Complex
    ) throws -> LuaValue {
      guard let arg = args.first else {
        throw LuaError.callbackError("array.\(name): missing argument")
      }
      let arr = try extractNDArray(arg)
      if arr.dtype == .complex128, let im = arr.imag {
        // Element-wise complex operation
        let r = arr.real
        let n = r.count
        var outR = [Double](repeating: 0, count: n)
        var outI = [Double](repeating: 0, count: n)
        for i in 0..<n {
          let result = complexFn(Complex(re: r[i], im: im[i]))
          outR[i] = result.re
          outI[i] = result.im
        }
        return ndArrayToLua(NDArray(
          shape: arr.shape, dtype: .complex128, real: outR, imag: outI))
      } else {
        // Real path: apply scalar function element-wise
        let result = arr.real.map { realFn($0) }
        return ndArrayToLua(NDArray(shape: arr.shape, data: result))
      }
    }

    private static let cxTanCallback: ([LuaValue]) throws -> LuaValue = { args in
      try complexTrigOp(args, name: "tan",
        realFn: { Foundation.tan($0) },
        complexFn: { $0.tan })
    }

    private static let cxSinhCallback: ([LuaValue]) throws -> LuaValue = { args in
      try complexTrigOp(args, name: "sinh",
        realFn: { Foundation.sinh($0) },
        complexFn: { $0.sinh })
    }

    private static let cxCoshCallback: ([LuaValue]) throws -> LuaValue = { args in
      try complexTrigOp(args, name: "cosh",
        realFn: { Foundation.cosh($0) },
        complexFn: { $0.cosh })
    }

    private static let cxTanhCallback: ([LuaValue]) throws -> LuaValue = { args in
      try complexTrigOp(args, name: "tanh",
        realFn: { Foundation.tanh($0) },
        complexFn: { $0.tanh })
    }

    // MARK: - Lua wrapper to override existing real-only trig

    private static let complexTrigWrapper = """
    -- Override tan/sinh/cosh/tanh to support complex arrays
    local np = luaswift.array

    local _cx_tan  = _luaswift_array_cx_tan
    local _cx_sinh = _luaswift_array_cx_sinh
    local _cx_cosh = _luaswift_array_cx_cosh
    local _cx_tanh = _luaswift_array_cx_tanh

    np.tan  = function(a) return np._wrap(_cx_tan(a._data)) end
    np.sinh = function(a) return np._wrap(_cx_sinh(a._data)) end
    np.cosh = function(a) return np._wrap(_cx_cosh(a._data)) end
    np.tanh = function(a) return np._wrap(_cx_tanh(a._data)) end

    _luaswift_array_cx_tan  = nil
    _luaswift_array_cx_sinh = nil
    _luaswift_array_cx_cosh = nil
    _luaswift_array_cx_tanh = nil
    """
  }

#endif  // LUASWIFT_ARRAYSWIFT && LUASWIFT_NUMERICSWIFT
