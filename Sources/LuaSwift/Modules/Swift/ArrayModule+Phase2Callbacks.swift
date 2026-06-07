//
//  ArrayModule+Phase2Callbacks.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/Modules/Swift/ArrayModule+Phase2Callbacks.swift
//
//  Context: Swift sides of the Phase-2 array functions — dtype-aware
//  creation, bool ops, int64 reductions, FFT, set operations, and
//  advanced indexing. Each callback converts its Lua arguments with
//  extractNDArray, delegates to ArraySwift's NDArray, and serializes
//  the result with ndArrayToLua (both in ArrayModule+Phase2.swift,
//  which also registers every callback here under its
//  `_luaswift_array_*` global — hence the internal visibility). The
//  Lua-side functions that call these globals are wired by
//  ArrayModule+Phase2Wiring.swift.
//

#if LUASWIFT_ARRAYSWIFT

  import Foundation
  import ArraySwift

  extension ArrayModule {

    // MARK: - Phase-2 Creation Callbacks

    /// `zeros(shape, dtype)` — honours int64/bool/complex128 dtype.
    internal static let p2ZerosCallback: ([LuaValue]) throws -> LuaValue = { args in
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
    internal static let p2OnesCallback: ([LuaValue]) throws -> LuaValue = { args in
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
    internal static let p2FullCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let logicalAndCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.logical_and: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      // Ensure bool dtype inputs so logicalAnd returns .bool storage
      let result = ensureBoolDtype(a).logicalAnd(ensureBoolDtype(b))
      return ndArrayToLua(result)
    }

    internal static let logicalOrCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.logical_or: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      let result = ensureBoolDtype(a).logicalOr(ensureBoolDtype(b))
      return ndArrayToLua(result)
    }

    internal static let logicalXorCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.logical_xor: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      let result = ensureBoolDtype(a).logicalXor(ensureBoolDtype(b))
      return ndArrayToLua(result)
    }

    internal static let logicalNotCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.logical_not: requires an argument")
      }
      let a = try extractNDArray(first)
      let result = ensureBoolDtype(a).logicalNot()
      return ndArrayToLua(result)
    }

    // MARK: - Int64 Reduction Callbacks

    internal static let argmaxArrayCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let argminArrayCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let argsortNDCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let fftCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.fft: requires a complex128 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.fft: input must be complex128 (use complex_array)")
      }
      return ndArrayToLua(NDArray.fft(a))
    }

    internal static let ifftCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.ifft: requires a complex128 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.ifft: input must be complex128")
      }
      return ndArrayToLua(NDArray.ifft(a))
    }

    internal static let rfftCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.rfft: requires a float64 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .float64 else {
        throw LuaError.callbackError("array.rfft: input must be float64")
      }
      return ndArrayToLua(NDArray.rfft(a))
    }

    internal static let fft2Callback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.fft2: requires a 2-D complex128 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.fft2: input must be complex128")
      }
      return ndArrayToLua(NDArray.fft2(a))
    }

    internal static let ifft2Callback: ([LuaValue]) throws -> LuaValue = { args in
      guard let first = args.first else {
        throw LuaError.callbackError("array.ifft2: requires a 2-D complex128 array")
      }
      let a = try extractNDArray(first)
      guard a.dtype == .complex128 else {
        throw LuaError.callbackError("array.ifft2: input must be complex128")
      }
      return ndArrayToLua(NDArray.ifft2(a))
    }

    internal static let fftnCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let fftfreqCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let intersect1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.intersect1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.intersect1d(a, b))
    }

    internal static let union1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.union1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.union1d(a, b))
    }

    internal static let setdiff1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.setdiff1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.setdiff1d(a, b))
    }

    internal static let setxor1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.setxor1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.setxor1d(a, b))
    }

    internal static let in1dCallback: ([LuaValue]) throws -> LuaValue = { args in
      guard args.count >= 2 else {
        throw LuaError.callbackError("array.in1d: requires two arguments")
      }
      let a = try extractNDArray(args[0])
      let b = try extractNDArray(args[1])
      return ndArrayToLua(NDArray.in1d(a, b))
    }

    // MARK: - Advanced Indexing Callbacks

    internal static let getmaskCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let gatherCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let getNegCallback: ([LuaValue]) throws -> LuaValue = { args in
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

    internal static let masksetCallback: ([LuaValue]) throws -> LuaValue = { args in
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
  }

#endif  // LUASWIFT_ARRAYSWIFT
