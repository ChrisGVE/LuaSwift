//
//  ArrayModule+Phase2.swift
//  LuaSwift
//
//  Phase-2 bindings: dtype creation, bool ops, int64 reductions,
//  FFT, set operations, and advanced indexing.
//
//  Created by Christian C. Berclaz on 2026-05-29.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
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
    private static func extractNDArray(_ value: LuaValue) throws -> NDArray {
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
    private static func ndArrayToLua(_ arr: NDArray) -> LuaValue {
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

    // MARK: - Phase-2 Creation Callbacks

    /// `zeros(shape, dtype)` — honours int64/bool/complex128 dtype.
    private static let p2ZerosCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let arg = args.first else {
        throw LuaError.callbackError("array.zeros: missing shape argument")
      }
      var shape: [Int] = []
      if let arr = arg.arrayValue {
        shape = arr.compactMap { $0.intValue }
      } else if let tbl = arg.tableValue {
        var i = 1; while let d = tbl[String(i)]?.intValue { shape.append(d); i += 1 }
      } else if let n = arg.intValue {
        shape = [n]
      }
      guard !shape.isEmpty else { throw LuaError.callbackError("array.zeros: invalid shape") }
      let dtype = ArrayDType(from: args.count > 1 ? args[1].stringValue : nil)
      return ndArrayToLua(NDArray.zeros(shape, dtype: dtype))
    }

    /// `ones(shape, dtype)` — honours int64/bool/complex128 dtype.
    private static let p2OnesCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let arg = args.first else {
        throw LuaError.callbackError("array.ones: missing shape argument")
      }
      var shape: [Int] = []
      if let arr = arg.arrayValue {
        shape = arr.compactMap { $0.intValue }
      } else if let tbl = arg.tableValue {
        var i = 1; while let d = tbl[String(i)]?.intValue { shape.append(d); i += 1 }
      } else if let n = arg.intValue {
        shape = [n]
      }
      guard !shape.isEmpty else { throw LuaError.callbackError("array.ones: invalid shape") }
      let dtype = ArrayDType(from: args.count > 1 ? args[1].stringValue : nil)
      return ndArrayToLua(NDArray.ones(shape, dtype: dtype))
    }

    /// `full(shape, value, dtype)` — honours int64/bool/complex128 dtype.
    private static let p2FullCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2, let value = args[1].numberValue else {
        throw LuaError.callbackError("array.full: requires shape and value")
      }
      var shape: [Int] = []
      if let arr = args[0].arrayValue {
        shape = arr.compactMap { $0.intValue }
      } else if let tbl = args[0].tableValue {
        var i = 1; while let d = tbl[String(i)]?.intValue { shape.append(d); i += 1 }
      } else if let n = args[0].intValue {
        shape = [n]
      }
      guard !shape.isEmpty else { throw LuaError.callbackError("array.full: invalid shape") }
      let dtype = ArrayDType(from: args.count > 2 ? args[2].stringValue : nil)
      return ndArrayToLua(NDArray.full(shape, value: value, dtype: dtype))
    }

    // MARK: - Bool Op Callbacks

    /// Convert a float64 NDArray to bool dtype by treating non-zero as true.
    private static func ensureBoolDtype(_ arr: NDArray) -> NDArray {
      if arr.dtype == .bool { return arr }
      return NDArray(shape: arr.shape, boolData: arr.real.map { $0 != 0 })
    }

    private static let logicalAndCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.logical_and: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      // Ensure bool dtype inputs so logicalAnd returns .bool storage
      let result = ensureBoolDtype(a).logicalAnd(ensureBoolDtype(b))
      return ndArrayToLua(result)
    }

    private static let logicalOrCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.logical_or: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      let result = ensureBoolDtype(a).logicalOr(ensureBoolDtype(b))
      return ndArrayToLua(result)
    }

    private static let logicalXorCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.logical_xor: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      let result = ensureBoolDtype(a).logicalXor(ensureBoolDtype(b))
      return ndArrayToLua(result)
    }

    private static let logicalNotCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.logical_not: requires an argument")
      }
      let a = try extractNDArray(first)
      let result = ensureBoolDtype(a).logicalNot()
      return ndArrayToLua(result)
    }

    // MARK: - Int64 Reduction Callbacks

    private static let argmaxArrayCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.argmax_array: requires an argument")
      }
      let a = try extractNDArray(first)
      // NDArray.argmaxArray() returns 0-based; convert to 1-based for Lua convention
      let zeroBased = a.argmaxArray()
      if let d = zeroBased.int64Data {
        return ndArrayToLua(NDArray(shape: zeroBased.shape, int64Data: d.map { $0 + 1 }))
      }
      return ndArrayToLua(zeroBased)
    }

    private static let argminArrayCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.argmin_array: requires an argument")
      }
      let a = try extractNDArray(first)
      // NDArray.argminArray() returns 0-based; convert to 1-based for Lua convention
      let zeroBased = a.argminArray()
      if let d = zeroBased.int64Data {
        return ndArrayToLua(NDArray(shape: zeroBased.shape, int64Data: d.map { $0 + 1 }))
      }
      return ndArrayToLua(zeroBased)
    }

    private static let argsortNDCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.argsort (nd): requires an argument")
      }
      let a = try extractNDArray(first)
      // NDArray.argsort() returns 0-based int64 indices.
      // Convert to 1-based to match Lua convention (consistent with the existing argsortCallback).
      let zeroBased = a.argsort()
      if let d = zeroBased.int64Data {
        let oneBased = d.map { $0 + 1 }
        return ndArrayToLua(NDArray(shape: zeroBased.shape, int64Data: oneBased))
      }
      return ndArrayToLua(zeroBased)
    }

    // MARK: - FFT Callbacks

    private static let fftCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.fft: requires a complex128 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.fft: input must be complex128 (use complex_array)")
      }
      return ndArrayToLua(NDArray.fft(a))
    }

    private static let ifftCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.ifft: requires a complex128 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.ifft: input must be complex128")
      }
      return ndArrayToLua(NDArray.ifft(a))
    }

    private static let rfftCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.rfft: requires a float64 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .float64 else {
        throw LuaError.callbackError("array.rfft: input must be float64")
      }
      return ndArrayToLua(NDArray.rfft(a))
    }

    private static let fft2Callback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.fft2: requires a 2-D complex128 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.fft2: input must be complex128")
      }
      return ndArrayToLua(NDArray.fft2(a))
    }

    private static let ifft2Callback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.ifft2: requires a 2-D complex128 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.ifft2: input must be complex128")
      }
      return ndArrayToLua(NDArray.ifft2(a))
    }

    private static let fftnCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.fftn/ifftn: requires a complex128 array")
      }
      // Second arg (optional): true for forward, false/absent for forward by default
      // We share this callback for fftn and ifftn; caller disambiguates via Lua wrapper.
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.fftn/ifftn: input must be complex128")
      }
      // args[1] = "inverse" flag if present
      let inverse = args.count > 1 && args[1].boolValue == true
      return ndArrayToLua(inverse ? NDArray.ifftn(a) : NDArray.fftn(a))
    }

    private static let fftfreqCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let nVal = args.first?.numberValue else {
        throw LuaError.callbackError("array.fftfreq: requires n (integer)")
      }
      let n = Int(nVal)
      guard n > 0 else {
        throw LuaError.callbackError("array.fftfreq: n must be > 0")
      }
      let d = args.count > 1 ? (args[1].numberValue ?? 1.0) : 1.0
      return ndArrayToLua(NDArray.fftfreq(n, d: d))
    }

    // MARK: - Set Op Callbacks

    private static let intersect1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.intersect1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.intersect1d(a, b))
    }

    private static let union1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.union1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.union1d(a, b))
    }

    private static let setdiff1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.setdiff1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.setdiff1d(a, b))
    }

    private static let setxor1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.setxor1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.setxor1d(a, b))
    }

    private static let in1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.in1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.in1d(a, b))
    }

    // MARK: - Advanced Indexing Callbacks

    private static let getmaskCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.getmask: requires array and mask arguments")
      }
      var a = try extractNDArray(args[0])
      let maskND = try extractNDArray(args[1])
      // Convert mask to bool dtype if it isn't already
      let boolMask: NDArray
      if maskND.dtype == .bool {
        boolMask = maskND
      } else {
        let flags = maskND.real.map { $0 != 0 }
        boolMask = NDArray(shape: maskND.shape, boolData: flags)
      }
      return ndArrayToLua(a.booleanIndex(boolMask))
    }

    private static let gatherCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.gather: requires array and indices arguments")
      }
      let a = try extractNDArray(args[0])
      // Accept Lua table of 1-based indices
      var indices: [Int] = []
      if let arr = args[1].arrayValue {
        indices = arr.compactMap { val in
          guard let n = val.intValue else { return nil }
          // Convert 1-based Lua index to 0-based
          return n > 0 ? n - 1 : (a.size + n)
        }
      } else if let tbl = args[1].tableValue {
        var i = 1
        while let val = tbl[String(i)] {
          if let n = val.intValue {
            indices.append(n > 0 ? n - 1 : a.size + n)
          }
          i += 1
        }
      }
      return ndArrayToLua(a[indices: indices])
    }

    private static let getNegCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2, let idx = args[1].intValue else {
        throw LuaError.callbackError("array.get_neg: requires array and integer index")
      }
      let a = try extractNDArray(args[0])
      // Lua negative index: -1 = last, -2 = second-to-last; convert to 0-based
      let zeroBasedIdx = idx < 0 ? a.size + idx : idx - 1
      guard zeroBasedIdx >= 0 && zeroBasedIdx < a.size else {
        throw LuaError.callbackError("array.get_neg: index \(idx) out of bounds for size \(a.size)")
      }
      return .number(a.real[zeroBasedIdx])
    }

    private static let masksetCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 3,
            let value = args[2].numberValue else {
        throw LuaError.callbackError("array.maskset: requires array, mask, and scalar value")
      }
      var a = try extractNDArray(args[0])
      let maskND = try extractNDArray(args[1])
      let boolMask: NDArray
      if maskND.dtype == .bool {
        boolMask = maskND
      } else {
        let flags = maskND.real.map { $0 != 0 }
        boolMask = NDArray(shape: maskND.shape, boolData: flags)
      }
      a.maskSet(boolMask, value: value)
      return ndArrayToLua(a)
    }

    // MARK: - Lua Wrapper

    private static let luaPhase2Wrapper = """
    -- Phase-2 bindings: expose new Swift functions in the luaswift.array namespace

    local np = luaswift.array

    -- Capture Swift functions
    local _logical_and  = _luaswift_array_logical_and
    local _logical_or   = _luaswift_array_logical_or
    local _logical_xor  = _luaswift_array_logical_xor
    local _logical_not  = _luaswift_array_logical_not
    local _argmax_array = _luaswift_array_argmax_array
    local _argmin_array = _luaswift_array_argmin_array
    local _argsort_nd   = _luaswift_array_argsort_nd
    local _fft          = _luaswift_array_fft
    local _ifft         = _luaswift_array_ifft
    local _rfft         = _luaswift_array_rfft
    local _fft2         = _luaswift_array_fft2
    local _ifft2        = _luaswift_array_ifft2
    local _fftn         = _luaswift_array_fftn
    local _ifftn        = _luaswift_array_ifftn
    local _fftfreq      = _luaswift_array_fftfreq
    local _intersect1d  = _luaswift_array_intersect1d
    local _union1d      = _luaswift_array_union1d
    local _setdiff1d    = _luaswift_array_setdiff1d
    local _setxor1d     = _luaswift_array_setxor1d
    local _in1d         = _luaswift_array_in1d
    local _getmask      = _luaswift_array_getmask
    local _gather       = _luaswift_array_gather
    local _get_neg      = _luaswift_array_get_neg
    local _maskset      = _luaswift_array_maskset

    -- Helper: wrap raw table as array object
    local function W(raw) return np._wrap(raw) end

    -- Bool ops (namespace functions)
    np.logical_and  = function(a, b) return W(_logical_and(a._data, b._data)) end
    np.logical_or   = function(a, b) return W(_logical_or(a._data, b._data)) end
    np.logical_xor  = function(a, b) return W(_logical_xor(a._data, b._data)) end
    np.logical_not  = function(a)    return W(_logical_not(a._data)) end

    -- Int64 reductions
    np.argmax_array = function(a) return W(_argmax_array(a._data)) end
    np.argmin_array = function(a) return W(_argmin_array(a._data)) end
    -- Override argsort to return int64 NDArray (0-based flat indices)
    np.argsort = function(a)
        return W(_argsort_nd(a._data))
    end

    -- FFT namespace
    np.fft = {
        fft     = function(a)    return W(_fft(a._data)) end,
        ifft    = function(a)    return W(_ifft(a._data)) end,
        rfft    = function(a)    return W(_rfft(a._data)) end,
        fft2    = function(a)    return W(_fft2(a._data)) end,
        ifft2   = function(a)    return W(_ifft2(a._data)) end,
        fftn    = function(a)    return W(_fftn(a._data, false)) end,
        ifftn   = function(a)    return W(_fftn(a._data, true)) end,
        fftfreq = function(n, d) return W(_fftfreq(n, d or 1.0)) end,
    }

    -- Set operations
    np.intersect1d = function(a, b) return W(_intersect1d(a._data, b._data)) end
    np.union1d     = function(a, b) return W(_union1d(a._data, b._data)) end
    np.setdiff1d   = function(a, b) return W(_setdiff1d(a._data, b._data)) end
    np.setxor1d    = function(a, b) return W(_setxor1d(a._data, b._data)) end
    np.in1d        = function(a, b) return W(_in1d(a._data, b._data)) end

    -- Advanced indexing
    np.getmask = function(a, mask) return W(_getmask(a._data, mask._data)) end
    np.gather  = function(a, idx)  return W(_gather(a._data, idx)) end
    np.get_neg = function(a, idx)  return _get_neg(a._data, idx) end
    np.maskset = function(a, mask, val)
        local new_data = _maskset(a._data, mask._data, val)
        a._data = new_data
        return a
    end

    -- Extend array metatable to add method forms for bool ops.
    -- Wrap any existing array to get the metatable without extra memory allocation.
    do
        local probe = np.zeros({0})  -- shape=[0] → 0 bytes allocated
        local mt = getmetatable(probe)
        if mt and mt.__index then
            local orig_index = mt.__index
            mt.__index = function(self, key)
                if key == "logical_and" then
                    return function(_, b) return W(_logical_and(self._data, b._data)) end
                elseif key == "logical_or" then
                    return function(_, b) return W(_logical_or(self._data, b._data)) end
                elseif key == "logical_xor" then
                    return function(_, b) return W(_logical_xor(self._data, b._data)) end
                elseif key == "logical_not" then
                    return function(_) return W(_logical_not(self._data)) end
                end
                return orig_index(self, key)
            end
        end
    end

    -- Extend zeros/ones/full to accept optional dtype string.
    -- The Phase-2 registration adds _p2_zeros/_p2_ones/_p2_full callbacks that
    -- accept an explicit dtype argument; the originals (registered by the main
    -- ArrayModule) are already captured as locals and nil'd from globals, so we
    -- use the Phase-2 variants here.
    local _p2_zeros = _luaswift_array_p2_zeros
    local _p2_ones  = _luaswift_array_p2_ones
    local _p2_full  = _luaswift_array_p2_full

    local _zeros_orig = np.zeros
    np.zeros = function(shape, dtype)
        if not dtype then return _zeros_orig(shape) end
        return W(_p2_zeros(shape, dtype))
    end

    local _ones_orig = np.ones
    np.ones = function(shape, dtype)
        if not dtype then return _ones_orig(shape) end
        return W(_p2_ones(shape, dtype))
    end

    local _full_orig = np.full
    np.full = function(shape, value, dtype)
        if not dtype then return _full_orig(shape, value) end
        return W(_p2_full(shape, value, dtype))
    end

    -- np.dtype(a) accessor function — delegates to the :dtype() method
    np.dtype = function(a)
        if type(a) == "table" and a.dtype then
            return a:dtype()
        end
        return nil
    end

    -- Clean up temporaries
    _luaswift_array_logical_and  = nil
    _luaswift_array_logical_or   = nil
    _luaswift_array_logical_xor  = nil
    _luaswift_array_logical_not  = nil
    _luaswift_array_argmax_array = nil
    _luaswift_array_argmin_array = nil
    _luaswift_array_argsort_nd   = nil
    _luaswift_array_fft          = nil
    _luaswift_array_ifft         = nil
    _luaswift_array_rfft         = nil
    _luaswift_array_fft2         = nil
    _luaswift_array_ifft2        = nil
    _luaswift_array_fftn         = nil
    _luaswift_array_ifftn        = nil
    _luaswift_array_fftfreq      = nil
    _luaswift_array_intersect1d  = nil
    _luaswift_array_union1d      = nil
    _luaswift_array_setdiff1d    = nil
    _luaswift_array_setxor1d     = nil
    _luaswift_array_in1d         = nil
    _luaswift_array_getmask      = nil
    _luaswift_array_gather       = nil
    _luaswift_array_get_neg      = nil
    _luaswift_array_maskset      = nil
    _luaswift_array_p2_zeros     = nil
    _luaswift_array_p2_ones      = nil
    _luaswift_array_p2_full      = nil
    """
  }

#endif  // LUASWIFT_ARRAYSWIFT

// MARK: - Complex trig dispatch on arrays (requires both ArraySwift + NumericSwift)

#if LUASWIFT_ARRAYSWIFT && LUASWIFT_NUMERICSWIFT

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
