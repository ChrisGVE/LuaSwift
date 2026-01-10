//
//  LinAlgModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Accelerate

/// Swift-backed linear algebra module for LuaSwift.
///
/// Provides matrix and vector operations using the Accelerate framework
/// for hardware-accelerated computation.
///
/// ## Naming Convention
///
/// This module follows NumPy-inspired naming with explicit variants for clarity:
/// - `diagonal` (alias: `diag`) - Create diagonal matrix from vector
/// - `eigen` (alias: `eig`) - Compute eigenvalues and eigenvectors
/// - `least_squares` (alias: `lstsq`) - Solve least squares problem
///
/// Legacy short aliases remain available for backward compatibility.
///
/// ## Lua API
///
/// ```lua
/// local linalg = require("luaswift.linalg")
///
/// -- Vector creation
/// local v = linalg.vector({1, 2, 3, 4})
/// local v = linalg.zeros(4)
/// local v = linalg.ones(4)
/// local v = linalg.range(1, 10, 2)
/// local v = linalg.linspace(0, 1, 5)
///
/// -- Matrix creation
/// local m = linalg.matrix({{1,2},{3,4}})
/// local m = linalg.zeros(3, 3)
/// local m = linalg.ones(2, 3)
/// local m = linalg.eye(3)
/// local m = linalg.diagonal({1,2,3})  -- diag also works
///
/// -- Matrix operations
/// print(m:rows(), m:cols())
/// print(m:get(1, 2))
/// m:set(1, 2, 5.0)
/// local t = m:transpose()
/// local det = m:det()
/// local inv = m:inv()
/// local product = m:dot(m2)
///
/// -- Decompositions
/// local L, U, P = m:lu()
/// local Q, R = m:qr()
/// local vals, vecs = m:eigen()  -- eig also works
/// ```
public struct LinAlgModule {

    /// Register the linear algebra module with a LuaEngine.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register creation functions
        engine.registerFunction(name: "_luaswift_linalg_vector", callback: vectorCallback)
        engine.registerFunction(name: "_luaswift_linalg_matrix", callback: matrixCallback)
        engine.registerFunction(name: "_luaswift_linalg_zeros", callback: zerosCallback)
        engine.registerFunction(name: "_luaswift_linalg_ones", callback: onesCallback)
        engine.registerFunction(name: "_luaswift_linalg_eye", callback: eyeCallback)
        engine.registerFunction(name: "_luaswift_linalg_diag", callback: diagCallback)
        engine.registerFunction(name: "_luaswift_linalg_range", callback: rangeCallback)
        engine.registerFunction(name: "_luaswift_linalg_linspace", callback: linspaceCallback)

        // Register matrix/vector methods
        engine.registerFunction(name: "_luaswift_linalg_rows", callback: rowsCallback)
        engine.registerFunction(name: "_luaswift_linalg_cols", callback: colsCallback)
        engine.registerFunction(name: "_luaswift_linalg_shape", callback: shapeCallback)
        engine.registerFunction(name: "_luaswift_linalg_size", callback: sizeCallback)
        engine.registerFunction(name: "_luaswift_linalg_get", callback: getCallback)
        engine.registerFunction(name: "_luaswift_linalg_set", callback: setCallback)
        engine.registerFunction(name: "_luaswift_linalg_row", callback: rowCallback)
        engine.registerFunction(name: "_luaswift_linalg_col", callback: colCallback)
        engine.registerFunction(name: "_luaswift_linalg_transpose", callback: transposeCallback)
        engine.registerFunction(name: "_luaswift_linalg_toarray", callback: toArrayCallback)

        // Register arithmetic operations
        engine.registerFunction(name: "_luaswift_linalg_add", callback: addCallback)
        engine.registerFunction(name: "_luaswift_linalg_sub", callback: subCallback)
        engine.registerFunction(name: "_luaswift_linalg_mul", callback: mulCallback)
        engine.registerFunction(name: "_luaswift_linalg_div", callback: divCallback)
        engine.registerFunction(name: "_luaswift_linalg_dot", callback: dotCallback)
        engine.registerFunction(name: "_luaswift_linalg_hadamard", callback: hadamardCallback)

        // Register linear algebra operations
        engine.registerFunction(name: "_luaswift_linalg_det", callback: detCallback)
        engine.registerFunction(name: "_luaswift_linalg_inv", callback: invCallback)
        engine.registerFunction(name: "_luaswift_linalg_trace", callback: traceCallback)
        engine.registerFunction(name: "_luaswift_linalg_norm", callback: normCallback)
        engine.registerFunction(name: "_luaswift_linalg_rank", callback: rankCallback)
        engine.registerFunction(name: "_luaswift_linalg_cond", callback: condCallback)
        engine.registerFunction(name: "_luaswift_linalg_pinv", callback: pinvCallback)

        // Register decompositions
        engine.registerFunction(name: "_luaswift_linalg_lu", callback: luCallback)
        engine.registerFunction(name: "_luaswift_linalg_qr", callback: qrCallback)
        engine.registerFunction(name: "_luaswift_linalg_svd", callback: svdCallback)
        engine.registerFunction(name: "_luaswift_linalg_eig", callback: eigCallback)
        engine.registerFunction(name: "_luaswift_linalg_eigvals", callback: eigvalsCallback)
        engine.registerFunction(name: "_luaswift_linalg_chol", callback: cholCallback)

        // Register solvers
        engine.registerFunction(name: "_luaswift_linalg_solve", callback: solveCallback)
        engine.registerFunction(name: "_luaswift_linalg_lstsq", callback: lstsqCallback)

        // Register complex solvers
        engine.registerFunction(name: "_luaswift_linalg_csolve", callback: csolveCallback)
        engine.registerFunction(name: "_luaswift_linalg_csvd", callback: csvdCallback)

        // Register advanced solvers
        engine.registerFunction(name: "_luaswift_linalg_solve_triangular", callback: solveTriangularCallback)
        engine.registerFunction(name: "_luaswift_linalg_cho_solve", callback: choSolveCallback)
        engine.registerFunction(name: "_luaswift_linalg_lu_solve", callback: luSolveCallback)

        // Register matrix functions
        engine.registerFunction(name: "_luaswift_linalg_expm", callback: expmCallback)
        engine.registerFunction(name: "_luaswift_linalg_logm", callback: logmCallback)
        engine.registerFunction(name: "_luaswift_linalg_sqrtm", callback: sqrtmCallback)
        engine.registerFunction(name: "_luaswift_linalg_funm", callback: funmCallback)

        // Set up the luaswift.linalg namespace with Lua wrapper code
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Capture function references as locals before nilling globals
                local _vector = _luaswift_linalg_vector
                local _matrix = _luaswift_linalg_matrix
                local _zeros = _luaswift_linalg_zeros
                local _ones = _luaswift_linalg_ones
                local _eye = _luaswift_linalg_eye
                local _diag = _luaswift_linalg_diag
                local _range = _luaswift_linalg_range
                local _linspace = _luaswift_linalg_linspace
                local _rows = _luaswift_linalg_rows
                local _cols = _luaswift_linalg_cols
                local _shape = _luaswift_linalg_shape
                local _size = _luaswift_linalg_size
                local _get = _luaswift_linalg_get
                local _set = _luaswift_linalg_set
                local _row = _luaswift_linalg_row
                local _col = _luaswift_linalg_col
                local _transpose = _luaswift_linalg_transpose
                local _toarray = _luaswift_linalg_toarray
                local _add = _luaswift_linalg_add
                local _sub = _luaswift_linalg_sub
                local _mul = _luaswift_linalg_mul
                local _div = _luaswift_linalg_div
                local _dot = _luaswift_linalg_dot
                local _hadamard = _luaswift_linalg_hadamard
                local _det = _luaswift_linalg_det
                local _inv = _luaswift_linalg_inv
                local _trace = _luaswift_linalg_trace
                local _norm = _luaswift_linalg_norm
                local _rank = _luaswift_linalg_rank
                local _lu = _luaswift_linalg_lu
                local _qr = _luaswift_linalg_qr
                local _svd = _luaswift_linalg_svd
                local _eig = _luaswift_linalg_eig
                local _eigvals = _luaswift_linalg_eigvals
                local _chol = _luaswift_linalg_chol
                local _solve = _luaswift_linalg_solve
                local _lstsq = _luaswift_linalg_lstsq
                local _csolve = _luaswift_linalg_csolve
                local _csvd = _luaswift_linalg_csvd
                local _solve_triangular = _luaswift_linalg_solve_triangular
                local _cho_solve = _luaswift_linalg_cho_solve
                local _lu_solve = _luaswift_linalg_lu_solve
                local _expm = _luaswift_linalg_expm
                local _logm = _luaswift_linalg_logm
                local _sqrtm = _luaswift_linalg_sqrtm
                local _funm = _luaswift_linalg_funm
                local _cond = _luaswift_linalg_cond
                local _pinv = _luaswift_linalg_pinv

                -- Matrix/Vector metatable
                local linalg_mt = {
                    __index = function(self, key)
                        local methods = {
                            rows = function(_) return _rows(self._data) end,
                            cols = function(_) return _cols(self._data) end,
                            shape = function(_) return _shape(self._data) end,
                            size = function(_) return _size(self._data) end,
                            get = function(_, i, j) return _get(self._data, i, j) end,
                            set = function(_, i, j, v) self._data = _set(self._data, i, j, v) return self end,
                            row = function(_, i) return luaswift.linalg._wrap(_row(self._data, i)) end,
                            col = function(_, j) return luaswift.linalg._wrap(_col(self._data, j)) end,
                            transpose = function(_) return luaswift.linalg._wrap(_transpose(self._data)) end,
                            T = function(_) return luaswift.linalg._wrap(_transpose(self._data)) end,
                            toarray = function(_) return _toarray(self._data) end,
                            dot = function(_, other)
                                local other_data = type(other) == "table" and other._data or other
                                local result = _dot(self._data, other_data)
                                -- Scalar result (vector dot product) returns number directly
                                if type(result) == "number" then return result end
                                return luaswift.linalg._wrap(result)
                            end,
                            hadamard = function(_, other)
                                local other_data = type(other) == "table" and other._data or other
                                return luaswift.linalg._wrap(_hadamard(self._data, other_data))
                            end,
                            det = function(_) return _det(self._data) end,
                            inv = function(_) return luaswift.linalg._wrap(_inv(self._data)) end,
                            trace = function(_) return _trace(self._data) end,
                            norm = function(_, p) return _norm(self._data, p or 2) end,
                            rank = function(_) return _rank(self._data) end,
                            lu = function(_)
                                local result = _lu(self._data)
                                return luaswift.linalg._wrap(result[1]), luaswift.linalg._wrap(result[2]), luaswift.linalg._wrap(result[3])
                            end,
                            qr = function(_)
                                local result = _qr(self._data)
                                return luaswift.linalg._wrap(result[1]), luaswift.linalg._wrap(result[2])
                            end,
                            svd = function(_, return1D)
                                local result = _svd(self._data, return1D)
                                return luaswift.linalg._wrap(result[1]), luaswift.linalg._wrap(result[2]), luaswift.linalg._wrap(result[3])
                            end,
                            eigen = function(_)
                                local result = _eig(self._data)
                                return luaswift.linalg._wrap(result[1]), luaswift.linalg._wrap(result[2])
                            end,
                            eig = function(_)  -- Legacy alias
                                local result = _eig(self._data)
                                return luaswift.linalg._wrap(result[1]), luaswift.linalg._wrap(result[2])
                            end,
                            eigvals = function(_)
                                return luaswift.linalg._wrap(_eigvals(self._data))
                            end,
                            chol = function(_) return luaswift.linalg._wrap(_chol(self._data)) end,
                            expm = function(_) return luaswift.linalg._wrap(_expm(self._data)) end,
                            logm = function(_) return luaswift.linalg._wrap(_logm(self._data)) end,
                            sqrtm = function(_) return luaswift.linalg._wrap(_sqrtm(self._data)) end,
                            funm = function(_, f) return luaswift.linalg._wrap(_funm(self._data, f)) end,
                            cond = function(_, p) return _cond(self._data, p) end,
                            pinv = function(_, rcond) return luaswift.linalg._wrap(_pinv(self._data, rcond)) end,
                        }
                        return methods[key]
                    end,
                    __add = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_add(a_data, b_data))
                    end,
                    __sub = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_sub(a_data, b_data))
                    end,
                    __mul = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_mul(a_data, b_data))
                    end,
                    __div = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_div(a_data, b_data))
                    end,
                    __unm = function(a)
                        return luaswift.linalg._wrap(_mul(a._data, -1))
                    end,
                    __tostring = function(self)
                        local shape = _shape(self._data)
                        if #shape == 1 then
                            return string.format("vector(%d)", shape[1])
                        else
                            return string.format("matrix(%dx%d)", shape[1], shape[2])
                        end
                    end,
                    __eq = function(a, b)
                        if type(a) ~= "table" or type(b) ~= "table" then return false end
                        if not a._data or not b._data then return false end
                        local ashape = _shape(a._data)
                        local bshape = _shape(b._data)
                        if #ashape ~= #bshape then return false end
                        for i, v in ipairs(ashape) do
                            if v ~= bshape[i] then return false end
                        end
                        local adata = _toarray(a._data)
                        local bdata = _toarray(b._data)
                        for i, v in ipairs(adata) do
                            if type(v) == "table" then
                                for j, w in ipairs(v) do
                                    if math.abs(w - bdata[i][j]) > 1e-10 then return false end
                                end
                            else
                                if math.abs(v - bdata[i]) > 1e-10 then return false end
                            end
                        end
                        return true
                    end,
                }

                luaswift.linalg = {
                    _wrap = function(data)
                        local wrapped = setmetatable({_data = data}, linalg_mt)
                        wrapped.__luaswift_type = data.type == "vector" and "linalg.vector" or "linalg.matrix"
                        return wrapped
                    end,
                    vector = function(arr)
                        return luaswift.linalg._wrap(_vector(arr))
                    end,
                    matrix = function(arr)
                        return luaswift.linalg._wrap(_matrix(arr))
                    end,
                    zeros = function(rows, cols)
                        return luaswift.linalg._wrap(_zeros(rows, cols))
                    end,
                    ones = function(rows, cols)
                        return luaswift.linalg._wrap(_ones(rows, cols))
                    end,
                    eye = function(n)
                        return luaswift.linalg._wrap(_eye(n))
                    end,
                    diagonal = function(arr)
                        return luaswift.linalg._wrap(_diag(arr))
                    end,
                    diag = function(arr)  -- Legacy alias
                        return luaswift.linalg._wrap(_diag(arr))
                    end,
                    range = function(start, stop, step)
                        return luaswift.linalg._wrap(_range(start, stop, step or 1))
                    end,
                    linspace = function(start, stop, n)
                        return luaswift.linalg._wrap(_linspace(start, stop, n))
                    end,
                    solve = function(A, b)
                        local A_data = type(A) == "table" and A._data or A
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_solve(A_data, b_data))
                    end,
                    least_squares = function(A, b)
                        local A_data = type(A) == "table" and A._data or A
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_lstsq(A_data, b_data))
                    end,
                    lstsq = function(A, b)  -- Legacy alias
                        local A_data = type(A) == "table" and A._data or A
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_lstsq(A_data, b_data))
                    end,
                    solve_triangular = function(A, b, opts)
                        local A_data = type(A) == "table" and A._data or A
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_solve_triangular(A_data, b_data, opts))
                    end,
                    cho_solve = function(L, b)
                        local L_data = type(L) == "table" and L._data or L
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_cho_solve(L_data, b_data))
                    end,
                    lu_solve = function(L, U, P, b)
                        local L_data = type(L) == "table" and L._data or L
                        local U_data = type(U) == "table" and U._data or U
                        local P_data = type(P) == "table" and P._data or P
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.linalg._wrap(_lu_solve(L_data, U_data, P_data, b_data))
                    end,
                    expm = function(A)
                        local A_data = type(A) == "table" and A._data or A
                        return luaswift.linalg._wrap(_expm(A_data))
                    end,
                    logm = function(A)
                        local A_data = type(A) == "table" and A._data or A
                        return luaswift.linalg._wrap(_logm(A_data))
                    end,
                    sqrtm = function(A)
                        local A_data = type(A) == "table" and A._data or A
                        return luaswift.linalg._wrap(_sqrtm(A_data))
                    end,
                    funm = function(A, f)
                        local A_data = type(A) == "table" and A._data or A
                        return luaswift.linalg._wrap(_funm(A_data, f))
                    end,
                    cond = function(A, p)
                        local A_data = type(A) == "table" and A._data or A
                        return _cond(A_data, p)
                    end,
                    pinv = function(A, rcond)
                        local A_data = type(A) == "table" and A._data or A
                        return luaswift.linalg._wrap(_pinv(A_data, rcond))
                    end,
                    -- Complex matrix operations
                    csolve = function(A, b)
                        return _csolve(A, b)
                    end,
                    csvd = function(A)
                        local result = _csvd(A)
                        return result[1], result[2], result[3]
                    end,
                    eig = function(A)
                        local A_data = type(A) == "table" and A._data or A
                        local result = _eig(A_data)
                        return luaswift.linalg._wrap(result[1]), luaswift.linalg._wrap(result[2])
                    end,
                    eigvals = function(A)
                        local A_data = type(A) == "table" and A._data or A
                        return luaswift.linalg._wrap(_eigvals(A_data))
                    end,
                }

                -- Clean up temporary globals
                _luaswift_linalg_vector = nil
                _luaswift_linalg_matrix = nil
                _luaswift_linalg_zeros = nil
                _luaswift_linalg_ones = nil
                _luaswift_linalg_eye = nil
                _luaswift_linalg_diag = nil
                _luaswift_linalg_range = nil
                _luaswift_linalg_linspace = nil
                _luaswift_linalg_rows = nil
                _luaswift_linalg_cols = nil
                _luaswift_linalg_shape = nil
                _luaswift_linalg_size = nil
                _luaswift_linalg_get = nil
                _luaswift_linalg_set = nil
                _luaswift_linalg_row = nil
                _luaswift_linalg_col = nil
                _luaswift_linalg_transpose = nil
                _luaswift_linalg_toarray = nil
                _luaswift_linalg_add = nil
                _luaswift_linalg_sub = nil
                _luaswift_linalg_mul = nil
                _luaswift_linalg_div = nil
                _luaswift_linalg_dot = nil
                _luaswift_linalg_hadamard = nil
                _luaswift_linalg_det = nil
                _luaswift_linalg_inv = nil
                _luaswift_linalg_trace = nil
                _luaswift_linalg_norm = nil
                _luaswift_linalg_rank = nil
                _luaswift_linalg_lu = nil
                _luaswift_linalg_qr = nil
                _luaswift_linalg_svd = nil
                _luaswift_linalg_eig = nil
                _luaswift_linalg_eigvals = nil
                _luaswift_linalg_chol = nil
                _luaswift_linalg_solve = nil
                _luaswift_linalg_lstsq = nil
                _luaswift_linalg_csolve = nil
                _luaswift_linalg_csvd = nil
                _luaswift_linalg_solve_triangular = nil
                _luaswift_linalg_cho_solve = nil
                _luaswift_linalg_lu_solve = nil
                _luaswift_linalg_expm = nil
                _luaswift_linalg_logm = nil
                _luaswift_linalg_sqrtm = nil
                _luaswift_linalg_funm = nil
                _luaswift_linalg_cond = nil
                _luaswift_linalg_pinv = nil
                """)
        } catch {
            // Silently fail if setup fails
        }
    }

    // MARK: - Internal Data Representation

    /// Data is stored as a table: {type = "matrix"|"vector", rows = n, cols = m, data = {...}}
    /// Vector: cols = 1
    /// Matrix: rows >= 1, cols >= 1
    /// Data is stored in row-major order

    // MARK: - Memory Tracking

    /// Track memory allocation for matrix/vector data.
    ///
    /// Call this before creating large matrices/vectors to respect memory limits.
    /// - Parameter count: Number of Double elements to allocate
    /// - Throws: `LuaError.memoryError` if the allocation would exceed limits
    private static func trackMatrixAllocation(count: Int) throws {
        let bytes = count * MemoryLayout<Double>.size
        if let engine = LuaEngine.currentEngine {
            try engine.trackAllocation(bytes: bytes)
        }
    }

    /// Track memory deallocation for matrix/vector data.
    ///
    /// Call this when matrix/vector data is being released.
    /// - Parameter count: Number of Double elements being freed
    private static func trackMatrixDeallocation(count: Int) {
        let bytes = count * MemoryLayout<Double>.size
        if let engine = LuaEngine.currentEngine {
            engine.trackDeallocation(bytes: bytes)
        }
    }

    // MARK: - Data Structures

    private static func createMatrixTable(rows: Int, cols: Int, data: [Double]) -> LuaValue {
        return .table([
            "type": .string(cols == 1 ? "vector" : "matrix"),
            "rows": .number(Double(rows)),
            "cols": .number(Double(cols)),
            "data": .array(data.map { .number($0) })
        ])
    }

    /// Create a complex matrix/vector table with real and imaginary parts
    private static func createComplexMatrixTable(rows: Int, cols: Int, real: [Double], imag: [Double]) -> LuaValue {
        return .table([
            "type": .string(cols == 1 ? "complex_vector" : "complex_matrix"),
            "dtype": .string("complex128"),
            "rows": .number(Double(rows)),
            "cols": .number(Double(cols)),
            "real": .array(real.map { .number($0) }),
            "imag": .array(imag.map { .number($0) })
        ])
    }

    private static func extractMatrixData(_ value: LuaValue) throws -> (rows: Int, cols: Int, data: [Double]) {
        guard case .table(let dict) = value else {
            throw LuaError.callbackError("linalg: expected matrix/vector table")
        }

        guard let rowsVal = dict["rows"]?.numberValue,
              let colsVal = dict["cols"]?.numberValue,
              let dataArr = dict["data"]?.arrayValue else {
            throw LuaError.callbackError("linalg: invalid matrix/vector structure")
        }

        let rows = Int(rowsVal)
        let cols = Int(colsVal)
        var data: [Double] = []
        data.reserveCapacity(dataArr.count)

        for val in dataArr {
            guard let num = val.numberValue else {
                throw LuaError.callbackError("linalg: matrix data must be numeric")
            }
            data.append(num)
        }

        return (rows, cols, data)
    }

    // MARK: - Creation Functions

    private static func vectorCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arr = args.first?.arrayValue else {
            throw LuaError.callbackError("linalg.vector requires an array argument")
        }

        var data: [Double] = []
        data.reserveCapacity(arr.count)

        for (i, val) in arr.enumerated() {
            guard let num = val.numberValue else {
                throw LuaError.callbackError("linalg.vector: element \(i+1) is not a number")
            }
            data.append(num)
        }

        return createMatrixTable(rows: data.count, cols: 1, data: data)
    }

    private static func matrixCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arr = args.first?.arrayValue else {
            throw LuaError.callbackError("linalg.matrix requires a 2D array argument")
        }

        guard !arr.isEmpty else {
            throw LuaError.callbackError("linalg.matrix: array cannot be empty")
        }

        var rows: [[Double]] = []
        var cols = 0

        for (i, rowVal) in arr.enumerated() {
            guard let row = rowVal.arrayValue else {
                throw LuaError.callbackError("linalg.matrix: row \(i+1) is not an array")
            }

            if i == 0 {
                cols = row.count
            } else if row.count != cols {
                throw LuaError.callbackError("linalg.matrix: all rows must have same length")
            }

            var rowData: [Double] = []
            rowData.reserveCapacity(row.count)

            for (j, val) in row.enumerated() {
                guard let num = val.numberValue else {
                    throw LuaError.callbackError("linalg.matrix: element (\(i+1),\(j+1)) is not a number")
                }
                rowData.append(num)
            }
            rows.append(rowData)
        }

        let data = rows.flatMap { $0 }
        return createMatrixTable(rows: rows.count, cols: cols, data: data)
    }

    private static func zerosCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let rows = args.first?.intValue else {
            throw LuaError.callbackError("linalg.zeros requires at least one size argument")
        }

        let cols = args.count > 1 ? (args[1].intValue ?? 1) : 1

        guard rows > 0 && cols > 0 else {
            throw LuaError.callbackError("linalg.zeros: dimensions must be positive")
        }

        let size = rows * cols
        try trackMatrixAllocation(count: size)
        let data = [Double](repeating: 0.0, count: size)
        return createMatrixTable(rows: rows, cols: cols, data: data)
    }

    private static func onesCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let rows = args.first?.intValue else {
            throw LuaError.callbackError("linalg.ones requires at least one size argument")
        }

        let cols = args.count > 1 ? (args[1].intValue ?? 1) : 1

        guard rows > 0 && cols > 0 else {
            throw LuaError.callbackError("linalg.ones: dimensions must be positive")
        }

        let size = rows * cols
        try trackMatrixAllocation(count: size)
        let data = [Double](repeating: 1.0, count: size)
        return createMatrixTable(rows: rows, cols: cols, data: data)
    }

    private static func eyeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let n = args.first?.intValue else {
            throw LuaError.callbackError("linalg.eye requires a size argument")
        }

        guard n > 0 else {
            throw LuaError.callbackError("linalg.eye: size must be positive")
        }

        let size = n * n
        try trackMatrixAllocation(count: size)
        var data = [Double](repeating: 0.0, count: size)
        for i in 0..<n {
            data[i * n + i] = 1.0
        }

        return createMatrixTable(rows: n, cols: n, data: data)
    }

    private static func diagCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arr = args.first?.arrayValue else {
            throw LuaError.callbackError("linalg.diag requires an array argument")
        }

        var diagVals: [Double] = []
        diagVals.reserveCapacity(arr.count)

        for (i, val) in arr.enumerated() {
            guard let num = val.numberValue else {
                throw LuaError.callbackError("linalg.diag: element \(i+1) is not a number")
            }
            diagVals.append(num)
        }

        let n = diagVals.count
        let size = n * n
        try trackMatrixAllocation(count: size)
        var data = [Double](repeating: 0.0, count: size)
        for i in 0..<n {
            data[i * n + i] = diagVals[i]
        }

        return createMatrixTable(rows: n, cols: n, data: data)
    }

    private static func rangeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let start = args[0].numberValue,
              let stop = args[1].numberValue else {
            throw LuaError.callbackError("linalg.range requires start and stop arguments")
        }

        let step = args.count > 2 ? (args[2].numberValue ?? 1.0) : 1.0

        guard step != 0 else {
            throw LuaError.callbackError("linalg.range: step cannot be zero")
        }

        // Estimate size for memory tracking
        let estimatedSize = max(0, Int(ceil(abs(stop - start) / abs(step))))
        try trackMatrixAllocation(count: estimatedSize)

        var data: [Double] = []
        data.reserveCapacity(estimatedSize)
        var current = start

        if step > 0 {
            while current < stop {
                data.append(current)
                current += step
            }
        } else {
            while current > stop {
                data.append(current)
                current += step
            }
        }

        return createMatrixTable(rows: data.count, cols: 1, data: data)
    }

    private static func linspaceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3,
              let start = args[0].numberValue,
              let stop = args[1].numberValue,
              let n = args[2].intValue else {
            throw LuaError.callbackError("linalg.linspace requires start, stop, and count arguments")
        }

        guard n >= 2 else {
            throw LuaError.callbackError("linalg.linspace: count must be at least 2")
        }

        try trackMatrixAllocation(count: n)
        var data: [Double] = []
        data.reserveCapacity(n)

        let step = (stop - start) / Double(n - 1)
        for i in 0..<n {
            data.append(start + Double(i) * step)
        }

        return createMatrixTable(rows: n, cols: 1, data: data)
    }

    // MARK: - Property Functions

    private static func rowsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.rows: missing argument")
        }
        let (rows, _, _) = try extractMatrixData(arg)
        return .number(Double(rows))
    }

    private static func colsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.cols: missing argument")
        }
        let (_, cols, _) = try extractMatrixData(arg)
        return .number(Double(cols))
    }

    private static func shapeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.shape: missing argument")
        }
        let (rows, cols, _) = try extractMatrixData(arg)
        if cols == 1 {
            return .array([.number(Double(rows))])
        }
        return .array([.number(Double(rows)), .number(Double(cols))])
    }

    private static func sizeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.size: missing argument")
        }
        let (rows, cols, _) = try extractMatrixData(arg)
        return .number(Double(rows * cols))
    }

    private static func getCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let i = args[1].intValue else {
            throw LuaError.callbackError("linalg.get: requires matrix and index")
        }

        let (rows, cols, data) = try extractMatrixData(args[0])

        if cols == 1 {
            // Vector: single index
            guard i >= 1 && i <= rows else {
                throw LuaError.callbackError("linalg.get: index out of bounds")
            }
            return .number(data[i - 1])
        } else {
            // Matrix: two indices
            guard args.count >= 3,
                  let j = args[2].intValue else {
                throw LuaError.callbackError("linalg.get: matrix requires two indices")
            }
            guard i >= 1 && i <= rows && j >= 1 && j <= cols else {
                throw LuaError.callbackError("linalg.get: indices out of bounds")
            }
            return .number(data[(i - 1) * cols + (j - 1)])
        }
    }

    private static func setCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("linalg.set: requires matrix, index, and value")
        }

        var (rows, cols, data) = try extractMatrixData(args[0])

        if cols == 1 {
            // Vector: single index
            guard let i = args[1].intValue,
                  let value = args[2].numberValue else {
                throw LuaError.callbackError("linalg.set: requires numeric index and value")
            }
            guard i >= 1 && i <= rows else {
                throw LuaError.callbackError("linalg.set: index out of bounds")
            }
            data[i - 1] = value
        } else {
            // Matrix: two indices
            guard args.count >= 4,
                  let i = args[1].intValue,
                  let j = args[2].intValue,
                  let value = args[3].numberValue else {
                throw LuaError.callbackError("linalg.set: matrix requires two indices and value")
            }
            guard i >= 1 && i <= rows && j >= 1 && j <= cols else {
                throw LuaError.callbackError("linalg.set: indices out of bounds")
            }
            data[(i - 1) * cols + (j - 1)] = value
        }

        return createMatrixTable(rows: rows, cols: cols, data: data)
    }

    private static func rowCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let i = args[1].intValue else {
            throw LuaError.callbackError("linalg.row: requires matrix and row index")
        }

        let (rows, cols, data) = try extractMatrixData(args[0])

        guard i >= 1 && i <= rows else {
            throw LuaError.callbackError("linalg.row: index out of bounds")
        }

        let start = (i - 1) * cols
        let rowData = Array(data[start..<(start + cols)])

        return createMatrixTable(rows: 1, cols: cols, data: rowData)
    }

    private static func colCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let j = args[1].intValue else {
            throw LuaError.callbackError("linalg.col: requires matrix and column index")
        }

        let (rows, cols, data) = try extractMatrixData(args[0])

        guard j >= 1 && j <= cols else {
            throw LuaError.callbackError("linalg.col: index out of bounds")
        }

        var colData: [Double] = []
        colData.reserveCapacity(rows)
        for i in 0..<rows {
            colData.append(data[i * cols + (j - 1)])
        }

        return createMatrixTable(rows: rows, cols: 1, data: colData)
    }

    private static func transposeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.transpose: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        var transposed = [Double](repeating: 0.0, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                transposed[j * rows + i] = data[i * cols + j]
            }
        }

        return createMatrixTable(rows: cols, cols: rows, data: transposed)
    }

    private static func toArrayCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.toarray: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        if cols == 1 {
            // Vector: return 1D array
            return .array(data.map { .number($0) })
        } else {
            // Matrix: return 2D array
            var result: [LuaValue] = []
            for i in 0..<rows {
                var row: [LuaValue] = []
                for j in 0..<cols {
                    row.append(.number(data[i * cols + j]))
                }
                result.append(.array(row))
            }
            return .array(result)
        }
    }

    // MARK: - Arithmetic Operations

    private static func addCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.add: requires two arguments")
        }

        let (rows1, cols1, data1) = try extractMatrixData(args[0])
        let (rows2, cols2, data2) = try extractMatrixData(args[1])

        guard rows1 == rows2 && cols1 == cols2 else {
            throw LuaError.callbackError("linalg.add: matrices must have same dimensions")
        }

        var result = [Double](repeating: 0.0, count: data1.count)
        vDSP_vaddD(data1, 1, data2, 1, &result, 1, vDSP_Length(data1.count))

        return createMatrixTable(rows: rows1, cols: cols1, data: result)
    }

    private static func subCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.sub: requires two arguments")
        }

        let (rows1, cols1, data1) = try extractMatrixData(args[0])
        let (rows2, cols2, data2) = try extractMatrixData(args[1])

        guard rows1 == rows2 && cols1 == cols2 else {
            throw LuaError.callbackError("linalg.sub: matrices must have same dimensions")
        }

        var result = [Double](repeating: 0.0, count: data1.count)
        vDSP_vsubD(data2, 1, data1, 1, &result, 1, vDSP_Length(data1.count))

        return createMatrixTable(rows: rows1, cols: cols1, data: result)
    }

    private static func mulCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.mul: requires two arguments")
        }

        // Check if second argument is a scalar
        if let scalar = args[1].numberValue {
            let (rows, cols, data) = try extractMatrixData(args[0])
            var result = [Double](repeating: 0.0, count: data.count)
            var scalarVal = scalar
            vDSP_vsmulD(data, 1, &scalarVal, &result, 1, vDSP_Length(data.count))
            return createMatrixTable(rows: rows, cols: cols, data: result)
        }

        // Check if first argument is a scalar
        if let scalar = args[0].numberValue {
            let (rows, cols, data) = try extractMatrixData(args[1])
            var result = [Double](repeating: 0.0, count: data.count)
            var scalarVal = scalar
            vDSP_vsmulD(data, 1, &scalarVal, &result, 1, vDSP_Length(data.count))
            return createMatrixTable(rows: rows, cols: cols, data: result)
        }

        // Matrix multiplication
        return try dotCallback(args)
    }

    private static func divCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.div: requires two arguments")
        }

        // Only support division by scalar
        guard let scalar = args[1].numberValue else {
            throw LuaError.callbackError("linalg.div: second argument must be a scalar")
        }

        guard scalar != 0 else {
            throw LuaError.callbackError("linalg.div: division by zero")
        }

        let (rows, cols, data) = try extractMatrixData(args[0])
        var result = [Double](repeating: 0.0, count: data.count)
        var divisor = scalar
        vDSP_vsdivD(data, 1, &divisor, &result, 1, vDSP_Length(data.count))

        return createMatrixTable(rows: rows, cols: cols, data: result)
    }

    private static func dotCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.dot: requires two arguments")
        }

        let (rows1, cols1, data1) = try extractMatrixData(args[0])
        let (rows2, cols2, data2) = try extractMatrixData(args[1])

        // Vector dot product
        if cols1 == 1 && cols2 == 1 {
            guard rows1 == rows2 else {
                throw LuaError.callbackError("linalg.dot: vectors must have same length")
            }
            var result: Double = 0
            vDSP_dotprD(data1, 1, data2, 1, &result, vDSP_Length(rows1))
            return .number(result)
        }

        // Matrix-vector multiplication
        if cols2 == 1 {
            guard cols1 == rows2 else {
                throw LuaError.callbackError("linalg.dot: incompatible dimensions for matrix-vector multiplication")
            }
            var result = [Double](repeating: 0.0, count: rows1)
            cblas_dgemv(CblasRowMajor, CblasNoTrans,
                        Int32(rows1), Int32(cols1),
                        1.0, data1, Int32(cols1),
                        data2, 1,
                        0.0, &result, 1)
            return createMatrixTable(rows: rows1, cols: 1, data: result)
        }

        // Matrix multiplication
        guard cols1 == rows2 else {
            throw LuaError.callbackError("linalg.dot: incompatible dimensions for matrix multiplication")
        }

        var result = [Double](repeating: 0.0, count: rows1 * cols2)
        cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                    Int32(rows1), Int32(cols2), Int32(cols1),
                    1.0, data1, Int32(cols1),
                    data2, Int32(cols2),
                    0.0, &result, Int32(cols2))

        return createMatrixTable(rows: rows1, cols: cols2, data: result)
    }

    private static func hadamardCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.hadamard: requires two arguments")
        }

        let (rows1, cols1, data1) = try extractMatrixData(args[0])
        let (rows2, cols2, data2) = try extractMatrixData(args[1])

        guard rows1 == rows2 && cols1 == cols2 else {
            throw LuaError.callbackError("linalg.hadamard: matrices must have same dimensions")
        }

        var result = [Double](repeating: 0.0, count: data1.count)
        vDSP_vmulD(data1, 1, data2, 1, &result, 1, vDSP_Length(data1.count))

        return createMatrixTable(rows: rows1, cols: cols1, data: result)
    }

    // MARK: - Linear Algebra Operations

    private static func detCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.det: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.det: matrix must be square")
        }

        // Use LU decomposition to compute determinant
        var a = data
        var n1 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(rows)
        var lda = __CLPK_integer(rows)
        var ipiv = [__CLPK_integer](repeating: 0, count: rows)
        var info: __CLPK_integer = 0

        dgetrf_(&n1, &n2, &a, &lda, &ipiv, &info)

        if info != 0 {
            return .number(0.0)  // Singular matrix
        }

        // Determinant is product of diagonal elements, with sign from permutation
        var det = 1.0
        var sign = 1
        for i in 0..<rows {
            det *= a[i * rows + i]
            if ipiv[i] != Int32(i + 1) {
                sign *= -1
            }
        }

        return .number(det * Double(sign))
    }

    private static func invCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.inv: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.inv: matrix must be square")
        }

        var a = data
        var n1 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(rows)
        var lda = __CLPK_integer(rows)
        var ipiv = [__CLPK_integer](repeating: 0, count: rows)
        var info: __CLPK_integer = 0

        // LU factorization
        dgetrf_(&n1, &n2, &a, &lda, &ipiv, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.inv: matrix is singular")
        }

        // Query workspace size
        var ngetri = __CLPK_integer(rows)
        var ldagetri = __CLPK_integer(rows)
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        dgetri_(&ngetri, &a, &ldagetri, &ipiv, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        // Compute inverse
        var ngetri2 = __CLPK_integer(rows)
        var ldagetri2 = __CLPK_integer(rows)
        dgetri_(&ngetri2, &a, &ldagetri2, &ipiv, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.inv: inversion failed")
        }

        return createMatrixTable(rows: rows, cols: cols, data: a)
    }

    private static func traceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.trace: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.trace: matrix must be square")
        }

        var trace = 0.0
        for i in 0..<rows {
            trace += data[i * cols + i]
        }

        return .number(trace)
    }

    private static func normCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.norm: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        // Get norm type (default = 2)
        let normType = args.count > 1 ? args[1] : .number(2)

        if cols == 1 {
            // Vector norm
            if let p = normType.numberValue {
                if p == 1 {
                    // L1 norm
                    var result = 0.0
                    vDSP_svemgD(data, 1, &result, vDSP_Length(rows))
                    return .number(result)
                } else if p == 2 {
                    // L2 norm (Euclidean)
                    var result = 0.0
                    vDSP_dotprD(data, 1, data, 1, &result, vDSP_Length(rows))
                    return .number(sqrt(result))
                } else if p == Double.infinity {
                    // Infinity norm
                    var result = 0.0
                    vDSP_maxmgvD(data, 1, &result, vDSP_Length(rows))
                    return .number(result)
                } else {
                    // General p-norm
                    var sum = 0.0
                    for val in data {
                        sum += pow(abs(val), p)
                    }
                    return .number(pow(sum, 1.0/p))
                }
            }
        } else {
            // Matrix norm
            if let p = normType.numberValue {
                if p == 1 {
                    // Column sum norm
                    var maxSum = 0.0
                    for j in 0..<cols {
                        var colSum = 0.0
                        for i in 0..<rows {
                            colSum += abs(data[i * cols + j])
                        }
                        maxSum = max(maxSum, colSum)
                    }
                    return .number(maxSum)
                } else if p == Double.infinity {
                    // Row sum norm
                    var maxSum = 0.0
                    for i in 0..<rows {
                        var rowSum = 0.0
                        for j in 0..<cols {
                            rowSum += abs(data[i * cols + j])
                        }
                        maxSum = max(maxSum, rowSum)
                    }
                    return .number(maxSum)
                }
            } else if let str = normType.stringValue, str == "fro" {
                // Frobenius norm
                var result = 0.0
                vDSP_dotprD(data, 1, data, 1, &result, vDSP_Length(data.count))
                return .number(sqrt(result))
            }
        }

        // Default: Frobenius/L2 norm
        var result = 0.0
        vDSP_dotprD(data, 1, data, 1, &result, vDSP_Length(data.count))
        return .number(sqrt(result))
    }

    private static func rankCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.rank: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        // Use SVD to compute rank
        var a = data
        var m1 = __CLPK_integer(rows)
        var n1 = __CLPK_integer(cols)
        var lda1 = __CLPK_integer(rows)
        let minDim = min(rows, cols)
        var s = [Double](repeating: 0, count: minDim)
        var u = [Double](repeating: 0, count: 1)  // Not needed
        var vt = [Double](repeating: 0, count: 1)  // Not needed
        var ldu: __CLPK_integer = 1
        var ldvt: __CLPK_integer = 1
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var jobu = Int8(UInt8(ascii: "N"))
        var jobvt = Int8(UInt8(ascii: "N"))

        dgesvd_(&jobu, &jobvt, &m1, &n1, &a, &lda1, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        var m2 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(cols)
        var lda2 = __CLPK_integer(rows)
        dgesvd_(&jobu, &jobvt, &m2, &n2, &a, &lda2, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.rank: SVD computation failed")
        }

        // Count non-zero singular values (with tolerance)
        let tol = max(Double(rows), Double(cols)) * s[0] * 2.220446049250313e-16
        var rank = 0
        for sv in s {
            if sv > tol {
                rank += 1
            }
        }

        return .number(Double(rank))
    }

    private static func condCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.cond: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        // Optional p parameter for norm type (default: 2-norm condition number)
        // p = 2: uses SVD (default)
        // p = 1: uses 1-norm
        // p = -1 (fro): uses Frobenius norm
        // Note: We implement 2-norm via SVD which is the standard approach
        // Future: implement other norm types
        let _ = args.count > 1 ? args[1].numberValue : nil

        // Convert to column-major for LAPACK (SVD)
        var a = [Double](repeating: 0, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                a[j * rows + i] = data[i * cols + j]
            }
        }

        var m1 = __CLPK_integer(rows)
        var n1 = __CLPK_integer(cols)
        var lda1 = __CLPK_integer(rows)
        let minDim = min(rows, cols)
        var s = [Double](repeating: 0, count: minDim)
        var u = [Double](repeating: 0, count: 1)  // Not needed
        var vt = [Double](repeating: 0, count: 1)  // Not needed
        var ldu: __CLPK_integer = 1
        var ldvt: __CLPK_integer = 1
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var jobu = Int8(UInt8(ascii: "N"))
        var jobvt = Int8(UInt8(ascii: "N"))

        dgesvd_(&jobu, &jobvt, &m1, &n1, &a, &lda1, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        var m2 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(cols)
        var lda2 = __CLPK_integer(rows)
        dgesvd_(&jobu, &jobvt, &m2, &n2, &a, &lda2, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.cond: SVD computation failed")
        }

        // Singular values are sorted in descending order
        let sMax = s[0]
        let sMin = s[minDim - 1]  // Last (smallest) singular value

        // Tolerance for considering a singular value as zero
        let tol = max(Double(rows), Double(cols)) * sMax * 2.220446049250313e-16

        // If minimum singular value is essentially zero, matrix is singular
        if sMin <= tol {
            return .number(Double.infinity)
        }

        // Condition number = max(s) / min(s)
        return .number(sMax / sMin)
    }

    private static func pinvCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.pinv: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)
        let minDim = min(rows, cols)

        // Optional rcond parameter for cutoff ratio
        let rcond = args.count > 1 ? (args[1].numberValue ?? 1e-15) : 1e-15

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                a[j * rows + i] = data[i * cols + j]
            }
        }

        var m1 = __CLPK_integer(rows)
        var n1 = __CLPK_integer(cols)
        var lda1 = __CLPK_integer(rows)
        var s = [Double](repeating: 0, count: minDim)
        var u = [Double](repeating: 0, count: rows * rows)
        var vt = [Double](repeating: 0, count: cols * cols)
        var ldu = __CLPK_integer(rows)
        var ldvt = __CLPK_integer(cols)
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var jobu = Int8(UInt8(ascii: "A"))
        var jobvt = Int8(UInt8(ascii: "A"))

        dgesvd_(&jobu, &jobvt, &m1, &n1, &a, &lda1, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        var m2 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(cols)
        var lda2 = __CLPK_integer(rows)
        dgesvd_(&jobu, &jobvt, &m2, &n2, &a, &lda2, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.pinv: SVD computation failed")
        }

        // Compute tolerance for singular value cutoff
        let tol = rcond * s[0]

        // Compute V * Σ^(-1) * U^T
        // Result is cols x rows matrix
        var result = [Double](repeating: 0, count: cols * rows)

        for i in 0..<cols {       // result row
            for j in 0..<rows {   // result col
                var sum = 0.0
                for k in 0..<minDim {
                    if s[k] > tol {
                        // Vt is stored in column-major (cols x cols)
                        // V = Vt^T, so V[i,k] = Vt[k,i] = vt[i * cols + k]
                        // U is stored in column-major (rows x rows)
                        // U[j,k] = u[k * rows + j]
                        let v_ik = vt[i * cols + k]
                        let u_jk = u[k * rows + j]
                        sum += v_ik * (1.0 / s[k]) * u_jk
                    }
                }
                result[i * rows + j] = sum
            }
        }

        return createMatrixTable(rows: cols, cols: rows, data: result)
    }

    // MARK: - Decompositions

    private static func luCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.lu: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.lu: matrix must be square")
        }

        var a = data
        var n1 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(rows)
        var lda = __CLPK_integer(rows)
        var ipiv = [__CLPK_integer](repeating: 0, count: rows)
        var info: __CLPK_integer = 0

        dgetrf_(&n1, &n2, &a, &lda, &ipiv, &info)

        if info < 0 {
            throw LuaError.callbackError("linalg.lu: invalid argument")
        }

        // Extract L and U from the combined matrix
        var L = [Double](repeating: 0, count: rows * rows)
        var U = [Double](repeating: 0, count: rows * rows)

        for i in 0..<rows {
            for j in 0..<rows {
                if i > j {
                    L[i * rows + j] = a[i * rows + j]
                } else if i == j {
                    L[i * rows + j] = 1.0
                    U[i * rows + j] = a[i * rows + j]
                } else {
                    U[i * rows + j] = a[i * rows + j]
                }
            }
        }

        // Create permutation matrix
        var P = [Double](repeating: 0, count: rows * rows)
        var perm = Array(0..<rows)
        for i in 0..<rows {
            let pivot = Int(ipiv[i]) - 1
            if pivot != i {
                perm.swapAt(i, pivot)
            }
        }
        for i in 0..<rows {
            P[i * rows + perm[i]] = 1.0
        }

        return .array([
            createMatrixTable(rows: rows, cols: rows, data: L),
            createMatrixTable(rows: rows, cols: rows, data: U),
            createMatrixTable(rows: rows, cols: rows, data: P)
        ])
    }

    private static func qrCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.qr: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)
        let minDim = min(rows, cols)

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                a[j * rows + i] = data[i * cols + j]
            }
        }

        var m1 = __CLPK_integer(rows)
        var n1 = __CLPK_integer(cols)
        var lda1 = __CLPK_integer(rows)
        var tau = [Double](repeating: 0, count: minDim)
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        dgeqrf_(&m1, &n1, &a, &lda1, &tau, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        // Compute QR
        var m2 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(cols)
        var lda2 = __CLPK_integer(rows)
        dgeqrf_(&m2, &n2, &a, &lda2, &tau, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.qr: computation failed")
        }

        // Extract R (upper triangular)
        var R = [Double](repeating: 0, count: minDim * cols)
        for i in 0..<minDim {
            for j in i..<cols {
                R[i * cols + j] = a[j * rows + i]
            }
        }

        // Generate Q
        var m3 = __CLPK_integer(rows)
        var k1 = __CLPK_integer(minDim)
        var k2 = __CLPK_integer(minDim)
        var lda3 = __CLPK_integer(rows)
        lwork = -1
        dorgqr_(&m3, &k1, &k2, &a, &lda3, &tau, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))
        var m4 = __CLPK_integer(rows)
        var k3 = __CLPK_integer(minDim)
        var k4 = __CLPK_integer(minDim)
        var lda4 = __CLPK_integer(rows)
        dorgqr_(&m4, &k3, &k4, &a, &lda4, &tau, &work, &lwork, &info)

        // Convert Q back to row-major
        var Q = [Double](repeating: 0, count: rows * minDim)
        for i in 0..<rows {
            for j in 0..<minDim {
                Q[i * minDim + j] = a[j * rows + i]
            }
        }

        return .array([
            createMatrixTable(rows: rows, cols: minDim, data: Q),
            createMatrixTable(rows: minDim, cols: cols, data: R)
        ])
    }

    private static func svdCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.svd: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)
        let minDim = min(rows, cols)

        // Optional second argument: if true, return singular values as 1D vector (numpy-compatible)
        // Default is false for backward compatibility (returns diagonal matrix)
        let return1D = args.count > 1 && (args[1].boolValue ?? false)

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                a[j * rows + i] = data[i * cols + j]
            }
        }

        var m1 = __CLPK_integer(rows)
        var n1 = __CLPK_integer(cols)
        var lda1 = __CLPK_integer(rows)
        var s = [Double](repeating: 0, count: minDim)
        var u = [Double](repeating: 0, count: rows * rows)
        var vt = [Double](repeating: 0, count: cols * cols)
        var ldu = __CLPK_integer(rows)
        var ldvt = __CLPK_integer(cols)
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var jobu = Int8(UInt8(ascii: "A"))
        var jobvt = Int8(UInt8(ascii: "A"))

        dgesvd_(&jobu, &jobvt, &m1, &n1, &a, &lda1, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        var m2 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(cols)
        var lda2 = __CLPK_integer(rows)
        dgesvd_(&jobu, &jobvt, &m2, &n2, &a, &lda2, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.svd: computation failed")
        }

        // Convert U to row-major
        var U = [Double](repeating: 0, count: rows * rows)
        for i in 0..<rows {
            for j in 0..<rows {
                U[i * rows + j] = u[j * rows + i]
            }
        }

        // S: either 1D vector (numpy-compatible) or diagonal matrix (backward-compatible)
        let sValue: LuaValue
        if return1D {
            // Return as 1D vector (numpy.linalg.svd default behavior)
            sValue = createMatrixTable(rows: minDim, cols: 1, data: s)
        } else {
            // Return as diagonal matrix (current behavior for backward compatibility)
            var S = [Double](repeating: 0, count: rows * cols)
            for i in 0..<minDim {
                S[i * cols + i] = s[i]
            }
            sValue = createMatrixTable(rows: rows, cols: cols, data: S)
        }

        // Convert Vt to row-major (and it's already transposed)
        var V = [Double](repeating: 0, count: cols * cols)
        for i in 0..<cols {
            for j in 0..<cols {
                V[i * cols + j] = vt[j * cols + i]
            }
        }

        return .array([
            createMatrixTable(rows: rows, cols: rows, data: U),
            sValue,
            createMatrixTable(rows: cols, cols: cols, data: V)
        ])
    }

    private static func eigCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.eig: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.eig: matrix must be square")
        }

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                a[j * rows + i] = data[i * cols + j]
            }
        }

        var n1 = __CLPK_integer(rows)
        var lda1 = __CLPK_integer(rows)
        var wr = [Double](repeating: 0, count: rows)  // Real parts
        var wi = [Double](repeating: 0, count: rows)  // Imaginary parts
        var vl = [Double](repeating: 0, count: 1)  // Left eigenvectors (not computed)
        var vr = [Double](repeating: 0, count: rows * rows)  // Right eigenvectors
        var ldvl: __CLPK_integer = 1
        var ldvr = __CLPK_integer(rows)
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var jobvl = Int8(UInt8(ascii: "N"))
        var jobvr = Int8(UInt8(ascii: "V"))

        dgeev_(&jobvl, &jobvr, &n1, &a, &lda1, &wr, &wi, &vl, &ldvl, &vr, &ldvr, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        var n2 = __CLPK_integer(rows)
        var lda2 = __CLPK_integer(rows)
        dgeev_(&jobvl, &jobvr, &n2, &a, &lda2, &wr, &wi, &vl, &ldvl, &vr, &ldvr, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.eig: computation failed")
        }

        // Check if there are any complex eigenvalues
        let hasComplexEigenvalues = wi.contains { abs($0) > 1e-14 }

        // Convert eigenvectors to row-major
        var vecs = [Double](repeating: 0, count: rows * rows)
        for i in 0..<rows {
            for j in 0..<rows {
                vecs[i * rows + j] = vr[j * rows + i]
            }
        }

        if hasComplexEigenvalues {
            // Return complex eigenvalues and eigenvectors
            // Note: For complex conjugate pairs, LAPACK stores eigenvectors specially
            // For simplicity, we return the eigenvalues as complex and vectors as real
            // (full complex eigenvector support would require more complex handling)
            return .array([
                createComplexMatrixTable(rows: rows, cols: 1, real: wr, imag: wi),
                createMatrixTable(rows: rows, cols: rows, data: vecs)
            ])
        } else {
            // All real eigenvalues
            return .array([
                createMatrixTable(rows: rows, cols: 1, data: wr),
                createMatrixTable(rows: rows, cols: rows, data: vecs)
            ])
        }
    }

    /// Returns only eigenvalues (more efficient when eigenvectors not needed)
    private static func eigvalsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.eigvals: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.eigvals: matrix must be square")
        }

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                a[j * rows + i] = data[i * cols + j]
            }
        }

        var n1 = __CLPK_integer(rows)
        var lda1 = __CLPK_integer(rows)
        var wr = [Double](repeating: 0, count: rows)
        var wi = [Double](repeating: 0, count: rows)
        var vl = [Double](repeating: 0, count: 1)
        var vr = [Double](repeating: 0, count: 1)  // Don't compute eigenvectors
        var ldvl: __CLPK_integer = 1
        var ldvr: __CLPK_integer = 1
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var jobvl = Int8(UInt8(ascii: "N"))
        var jobvr = Int8(UInt8(ascii: "N"))  // Don't compute eigenvectors

        dgeev_(&jobvl, &jobvr, &n1, &a, &lda1, &wr, &wi, &vl, &ldvl, &vr, &ldvr, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        var n2 = __CLPK_integer(rows)
        var lda2 = __CLPK_integer(rows)
        dgeev_(&jobvl, &jobvr, &n2, &a, &lda2, &wr, &wi, &vl, &ldvl, &vr, &ldvr, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.eigvals: computation failed")
        }

        // Check if there are any complex eigenvalues
        let hasComplexEigenvalues = wi.contains { abs($0) > 1e-14 }

        if hasComplexEigenvalues {
            return createComplexMatrixTable(rows: rows, cols: 1, real: wr, imag: wi)
        } else {
            return createMatrixTable(rows: rows, cols: 1, data: wr)
        }
    }

    private static func cholCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.chol: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.chol: matrix must be square")
        }

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                a[j * rows + i] = data[i * cols + j]
            }
        }

        var n1 = __CLPK_integer(rows)
        var lda1 = __CLPK_integer(rows)
        var info: __CLPK_integer = 0
        var uplo = Int8(UInt8(ascii: "L"))

        dpotrf_(&uplo, &n1, &a, &lda1, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.chol: matrix is not positive definite")
        }

        // Convert L to row-major and zero out upper triangle
        var L = [Double](repeating: 0, count: rows * rows)
        for i in 0..<rows {
            for j in 0...i {
                L[i * rows + j] = a[j * rows + i]
            }
        }

        return createMatrixTable(rows: rows, cols: rows, data: L)
    }

    // MARK: - Solvers

    private static func solveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.solve: requires A and b arguments")
        }

        let (rowsA, colsA, dataA) = try extractMatrixData(args[0])
        let (rowsB, colsB, dataB) = try extractMatrixData(args[1])

        guard rowsA == colsA else {
            throw LuaError.callbackError("linalg.solve: A must be square")
        }

        guard rowsA == rowsB else {
            throw LuaError.callbackError("linalg.solve: A and b must have compatible dimensions")
        }

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rowsA * colsA)
        for i in 0..<rowsA {
            for j in 0..<colsA {
                a[j * rowsA + i] = dataA[i * colsA + j]
            }
        }

        var b = [Double](repeating: 0, count: rowsB * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                b[j * rowsB + i] = dataB[i * colsB + j]
            }
        }

        var n1 = __CLPK_integer(rowsA)
        var nrhs = __CLPK_integer(colsB)
        var lda = __CLPK_integer(rowsA)
        var ipiv = [__CLPK_integer](repeating: 0, count: rowsA)
        var ldb = __CLPK_integer(rowsA)
        var info: __CLPK_integer = 0

        dgesv_(&n1, &nrhs, &a, &lda, &ipiv, &b, &ldb, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.solve: system is singular or computation failed")
        }

        // Convert back to row-major
        var result = [Double](repeating: 0, count: rowsB * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                result[i * colsB + j] = b[j * rowsB + i]
            }
        }

        return createMatrixTable(rows: rowsB, cols: colsB, data: result)
    }

    private static func lstsqCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.lstsq: requires A and b arguments")
        }

        let (rowsA, colsA, dataA) = try extractMatrixData(args[0])
        let (rowsB, colsB, dataB) = try extractMatrixData(args[1])

        guard rowsA == rowsB else {
            throw LuaError.callbackError("linalg.lstsq: A and b must have compatible dimensions")
        }

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rowsA * colsA)
        for i in 0..<rowsA {
            for j in 0..<colsA {
                a[j * rowsA + i] = dataA[i * colsA + j]
            }
        }

        let maxDim = max(rowsA, colsA)
        var b = [Double](repeating: 0, count: maxDim * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                b[j * maxDim + i] = dataB[i * colsB + j]
            }
        }

        var m1 = __CLPK_integer(rowsA)
        var n1 = __CLPK_integer(colsA)
        var nrhs1 = __CLPK_integer(colsB)
        var lda1 = __CLPK_integer(rowsA)
        var ldb1 = __CLPK_integer(maxDim)
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var trans = Int8(UInt8(ascii: "N"))

        dgels_(&trans, &m1, &n1, &nrhs1, &a, &lda1, &b, &ldb1, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        var m2 = __CLPK_integer(rowsA)
        var n2 = __CLPK_integer(colsA)
        var nrhs2 = __CLPK_integer(colsB)
        var lda2 = __CLPK_integer(rowsA)
        var ldb2 = __CLPK_integer(maxDim)
        dgels_(&trans, &m2, &n2, &nrhs2, &a, &lda2, &b, &ldb2, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.lstsq: computation failed")
        }

        // Extract solution (first colsA rows of b)
        var result = [Double](repeating: 0, count: colsA * colsB)
        for i in 0..<colsA {
            for j in 0..<colsB {
                result[i * colsB + j] = b[j * maxDim + i]
            }
        }

        return createMatrixTable(rows: colsA, cols: colsB, data: result)
    }

    // MARK: - Complex Linear Algebra

    /// Extract complex matrix data from Lua table.
    /// Expects either:
    /// 1. A table with 'real' and 'imag' arrays (like createComplexMatrixTable output)
    /// 2. A nested array of {re=, im=} complex numbers
    private static func extractComplexMatrixData(_ value: LuaValue) throws -> (rows: Int, cols: Int, real: [Double], imag: [Double]) {
        guard case .table(let dict) = value else {
            throw LuaError.callbackError("linalg.csolve: expected complex matrix table")
        }

        // Try format 1: {rows=, cols=, real=[], imag=[]}
        if let rowsVal = dict["rows"]?.numberValue,
           let colsVal = dict["cols"]?.numberValue,
           let realArr = dict["real"]?.arrayValue,
           let imagArr = dict["imag"]?.arrayValue {
            let rows = Int(rowsVal)
            let cols = Int(colsVal)
            var real: [Double] = []
            var imag: [Double] = []
            real.reserveCapacity(realArr.count)
            imag.reserveCapacity(imagArr.count)

            for val in realArr {
                guard let num = val.numberValue else {
                    throw LuaError.callbackError("linalg: complex matrix real data must be numeric")
                }
                real.append(num)
            }
            for val in imagArr {
                guard let num = val.numberValue else {
                    throw LuaError.callbackError("linalg: complex matrix imag data must be numeric")
                }
                imag.append(num)
            }

            return (rows, cols, real, imag)
        }

        // Try format 2: nested array of {re=, im=}
        guard let rowsVal = dict["rows"]?.numberValue,
              let colsVal = dict["cols"]?.numberValue,
              let dataArr = dict["data"]?.arrayValue else {
            throw LuaError.callbackError("linalg: invalid complex matrix structure")
        }

        let rows = Int(rowsVal)
        let cols = Int(colsVal)
        var real: [Double] = []
        var imag: [Double] = []
        real.reserveCapacity(dataArr.count)
        imag.reserveCapacity(dataArr.count)

        for val in dataArr {
            if let table = val.tableValue,
               let re = table["re"]?.numberValue,
               let im = table["im"]?.numberValue {
                real.append(re)
                imag.append(im)
            } else if let num = val.numberValue {
                // Real number, imaginary part is 0
                real.append(num)
                imag.append(0)
            } else {
                throw LuaError.callbackError("linalg: complex matrix elements must be {re=, im=} tables or numbers")
            }
        }

        return (rows, cols, real, imag)
    }

    /// Solve complex linear system Ax = b using LAPACK zgesv
    private static func csolveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.csolve: requires A and b arguments")
        }

        let (rowsA, colsA, realA, imagA) = try extractComplexMatrixData(args[0])
        let (rowsB, colsB, realB, imagB) = try extractComplexMatrixData(args[1])

        guard rowsA == colsA else {
            throw LuaError.callbackError("linalg.csolve: A must be square")
        }

        guard rowsA == rowsB else {
            throw LuaError.callbackError("linalg.csolve: A and b must have compatible dimensions")
        }

        // Convert to column-major interleaved complex for LAPACK
        // LAPACK uses __CLPK_doublecomplex which is {r: Double, i: Double}
        var a = [__CLPK_doublecomplex](repeating: __CLPK_doublecomplex(r: 0, i: 0), count: rowsA * colsA)
        for i in 0..<rowsA {
            for j in 0..<colsA {
                let srcIdx = i * colsA + j
                let dstIdx = j * rowsA + i  // Column-major
                a[dstIdx] = __CLPK_doublecomplex(r: realA[srcIdx], i: imagA[srcIdx])
            }
        }

        var b = [__CLPK_doublecomplex](repeating: __CLPK_doublecomplex(r: 0, i: 0), count: rowsB * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                let srcIdx = i * colsB + j
                let dstIdx = j * rowsB + i  // Column-major
                b[dstIdx] = __CLPK_doublecomplex(r: realB[srcIdx], i: imagB[srcIdx])
            }
        }

        var n1 = __CLPK_integer(rowsA)
        var nrhs = __CLPK_integer(colsB)
        var lda = __CLPK_integer(rowsA)
        var ipiv = [__CLPK_integer](repeating: 0, count: rowsA)
        var ldb = __CLPK_integer(rowsA)
        var info: __CLPK_integer = 0

        zgesv_(&n1, &nrhs, &a, &lda, &ipiv, &b, &ldb, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.csolve: system is singular or computation failed (info=\(info))")
        }

        // Convert back to row-major separate real/imag arrays
        var resultReal = [Double](repeating: 0, count: rowsB * colsB)
        var resultImag = [Double](repeating: 0, count: rowsB * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                let srcIdx = j * rowsB + i  // Column-major source
                let dstIdx = i * colsB + j  // Row-major destination
                resultReal[dstIdx] = b[srcIdx].r
                resultImag[dstIdx] = b[srcIdx].i
            }
        }

        return createComplexMatrixTable(rows: rowsB, cols: colsB, real: resultReal, imag: resultImag)
    }

    /// Compute complex SVD using LAPACK zgesdd
    private static func csvdCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.csvd: missing argument")
        }

        let (rows, cols, real, imag) = try extractComplexMatrixData(arg)
        let minDim = min(rows, cols)

        // Convert to column-major interleaved complex for LAPACK
        var a = [__CLPK_doublecomplex](repeating: __CLPK_doublecomplex(r: 0, i: 0), count: rows * cols)
        for i in 0..<rows {
            for j in 0..<cols {
                let srcIdx = i * cols + j
                let dstIdx = j * rows + i  // Column-major
                a[dstIdx] = __CLPK_doublecomplex(r: real[srcIdx], i: imag[srcIdx])
            }
        }

        var m1 = __CLPK_integer(rows)
        var n1 = __CLPK_integer(cols)
        var lda1 = __CLPK_integer(rows)
        var s = [Double](repeating: 0, count: minDim)
        var u = [__CLPK_doublecomplex](repeating: __CLPK_doublecomplex(r: 0, i: 0), count: rows * rows)
        var vt = [__CLPK_doublecomplex](repeating: __CLPK_doublecomplex(r: 0, i: 0), count: cols * cols)
        var ldu = __CLPK_integer(rows)
        var ldvt = __CLPK_integer(cols)
        var info: __CLPK_integer = 0

        // zgesdd requires workspace query
        var lwork: __CLPK_integer = -1
        var work = [__CLPK_doublecomplex](repeating: __CLPK_doublecomplex(r: 0, i: 0), count: 1)
        var rwork = [Double](repeating: 0, count: max(1, 5 * minDim * minDim + 7 * minDim))
        var iwork = [__CLPK_integer](repeating: 0, count: 8 * minDim)
        var jobz = Int8(UInt8(ascii: "A"))

        zgesdd_(&jobz, &m1, &n1, &a, &lda1, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &rwork, &iwork, &info)

        lwork = __CLPK_integer(work[0].r)
        work = [__CLPK_doublecomplex](repeating: __CLPK_doublecomplex(r: 0, i: 0), count: Int(lwork))

        var m2 = __CLPK_integer(rows)
        var n2 = __CLPK_integer(cols)
        var lda2 = __CLPK_integer(rows)

        zgesdd_(&jobz, &m2, &n2, &a, &lda2, &s, &u, &ldu, &vt, &ldvt, &work, &lwork, &rwork, &iwork, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.csvd: computation failed (info=\(info))")
        }

        // Convert U to row-major
        var Ureal = [Double](repeating: 0, count: rows * rows)
        var Uimag = [Double](repeating: 0, count: rows * rows)
        for i in 0..<rows {
            for j in 0..<rows {
                let srcIdx = j * rows + i  // Column-major source
                let dstIdx = i * rows + j  // Row-major destination
                Ureal[dstIdx] = u[srcIdx].r
                Uimag[dstIdx] = u[srcIdx].i
            }
        }

        // S is real - return as 1D vector
        let sValue = createMatrixTable(rows: minDim, cols: 1, data: s)

        // Convert Vt to row-major (it's already the conjugate transpose)
        var Vtreal = [Double](repeating: 0, count: cols * cols)
        var Vtimag = [Double](repeating: 0, count: cols * cols)
        for i in 0..<cols {
            for j in 0..<cols {
                let srcIdx = j * cols + i  // Column-major source
                let dstIdx = i * cols + j  // Row-major destination
                Vtreal[dstIdx] = vt[srcIdx].r
                Vtimag[dstIdx] = vt[srcIdx].i
            }
        }

        return .array([
            createComplexMatrixTable(rows: rows, cols: rows, real: Ureal, imag: Uimag),
            sValue,
            createComplexMatrixTable(rows: cols, cols: cols, real: Vtreal, imag: Vtimag)
        ])
    }

    // MARK: - Advanced Solvers

    /// Solve triangular system: solve L*x = b (lower) or U*x = b (upper)
    private static func solveTriangularCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.solve_triangular: requires A and b arguments")
        }

        let (rowsA, colsA, dataA) = try extractMatrixData(args[0])
        let (rowsB, colsB, dataB) = try extractMatrixData(args[1])

        guard rowsA == colsA else {
            throw LuaError.callbackError("linalg.solve_triangular: A must be square")
        }

        guard rowsA == rowsB else {
            throw LuaError.callbackError("linalg.solve_triangular: A and b must have compatible dimensions")
        }

        // Options: lower (default true), trans (default false)
        var lower = true
        var trans = false

        if args.count >= 3, case .table(let opts) = args[2] {
            if let lowerVal = opts["lower"]?.boolValue {
                lower = lowerVal
            }
            if let transVal = opts["trans"]?.boolValue {
                trans = transVal
            }
        }

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rowsA * colsA)
        for i in 0..<rowsA {
            for j in 0..<colsA {
                a[j * rowsA + i] = dataA[i * colsA + j]
            }
        }

        var b = [Double](repeating: 0, count: rowsB * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                b[j * rowsB + i] = dataB[i * colsB + j]
            }
        }

        var uplo = Int8(UInt8(ascii: lower ? "L" : "U"))
        var transChar = Int8(UInt8(ascii: trans ? "T" : "N"))
        var diag = Int8(UInt8(ascii: "N"))  // Non-unit diagonal
        var n1 = __CLPK_integer(rowsA)
        var nrhs = __CLPK_integer(colsB)
        var lda = __CLPK_integer(rowsA)
        var ldb = __CLPK_integer(rowsB)
        var info: __CLPK_integer = 0

        dtrtrs_(&uplo, &transChar, &diag, &n1, &nrhs, &a, &lda, &b, &ldb, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.solve_triangular: system is singular or computation failed")
        }

        // Convert back to row-major
        var result = [Double](repeating: 0, count: rowsB * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                result[i * colsB + j] = b[j * rowsB + i]
            }
        }

        return createMatrixTable(rows: rowsB, cols: colsB, data: result)
    }

    /// Solve using Cholesky factorization: solve L*L^T*x = b
    /// Takes L (lower triangular Cholesky factor) and b
    private static func choSolveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.cho_solve: requires L and b arguments")
        }

        let (rowsL, colsL, dataL) = try extractMatrixData(args[0])
        let (rowsB, colsB, dataB) = try extractMatrixData(args[1])

        guard rowsL == colsL else {
            throw LuaError.callbackError("linalg.cho_solve: L must be square")
        }

        guard rowsL == rowsB else {
            throw LuaError.callbackError("linalg.cho_solve: L and b must have compatible dimensions")
        }

        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: rowsL * colsL)
        for i in 0..<rowsL {
            for j in 0..<colsL {
                a[j * rowsL + i] = dataL[i * colsL + j]
            }
        }

        var b = [Double](repeating: 0, count: rowsB * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                b[j * rowsB + i] = dataB[i * colsB + j]
            }
        }

        var uplo = Int8(UInt8(ascii: "L"))
        var n1 = __CLPK_integer(rowsL)
        var nrhs = __CLPK_integer(colsB)
        var lda = __CLPK_integer(rowsL)
        var ldb = __CLPK_integer(rowsB)
        var info: __CLPK_integer = 0

        dpotrs_(&uplo, &n1, &nrhs, &a, &lda, &b, &ldb, &info)

        if info != 0 {
            throw LuaError.callbackError("linalg.cho_solve: computation failed")
        }

        // Convert back to row-major
        var result = [Double](repeating: 0, count: rowsB * colsB)
        for i in 0..<rowsB {
            for j in 0..<colsB {
                result[i * colsB + j] = b[j * rowsB + i]
            }
        }

        return createMatrixTable(rows: rowsB, cols: colsB, data: result)
    }

    /// Solve using LU factorization: solve P*L*U*x = b
    /// Takes (L, U, P) from lu() decomposition and b
    private static func luSolveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 4 else {
            throw LuaError.callbackError("linalg.lu_solve: requires L, U, P, and b arguments")
        }

        let (rowsL, colsL, dataL) = try extractMatrixData(args[0])
        let (rowsU, colsU, dataU) = try extractMatrixData(args[1])
        let (rowsP, colsP, dataP) = try extractMatrixData(args[2])
        let (rowsB, colsB, dataB) = try extractMatrixData(args[3])

        guard rowsL == colsL && rowsU == colsU && rowsP == colsP else {
            throw LuaError.callbackError("linalg.lu_solve: L, U, P must be square")
        }

        guard rowsL == rowsU && rowsL == rowsP else {
            throw LuaError.callbackError("linalg.lu_solve: L, U, P must have same dimensions")
        }

        guard rowsL == rowsB else {
            throw LuaError.callbackError("linalg.lu_solve: dimensions must be compatible with b")
        }

        let n = rowsL

        // Apply P to b: P * b (permutation)
        var pb = [Double](repeating: 0, count: rowsB * colsB)
        for j in 0..<colsB {
            for i in 0..<n {
                var sum = 0.0
                for k in 0..<n {
                    sum += dataP[i * n + k] * dataB[k * colsB + j]
                }
                pb[i * colsB + j] = sum
            }
        }

        // Solve L * y = P * b (forward substitution)
        var y = pb
        for j in 0..<colsB {
            for i in 0..<n {
                var sum = y[i * colsB + j]
                for k in 0..<i {
                    sum -= dataL[i * n + k] * y[k * colsB + j]
                }
                y[i * colsB + j] = sum / dataL[i * n + i]
            }
        }

        // Solve U * x = y (back substitution)
        var x = y
        for j in 0..<colsB {
            for i in stride(from: n - 1, through: 0, by: -1) {
                var sum = x[i * colsB + j]
                for k in (i + 1)..<n {
                    sum -= dataU[i * n + k] * x[k * colsB + j]
                }
                x[i * colsB + j] = sum / dataU[i * n + i]
            }
        }

        return createMatrixTable(rows: rowsB, cols: colsB, data: x)
    }

    // MARK: - Matrix Functions

    /// Matrix exponential using Padé approximation with scaling and squaring
    private static func expmCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.expm: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.expm: matrix must be square")
        }

        let n = rows

        // Compute matrix norm (Frobenius) using BLAS
        // cblas_dnrm2 computes sqrt(sum(x_i^2)) which is exactly the Frobenius norm
        let normA = cblas_dnrm2(Int32(n * n), data, 1)

        // Determine scaling factor s such that ||A/2^s|| < 1
        var s = 0
        var scale = 1.0
        while normA / scale > 1.0 {
            scale *= 2.0
            s += 1
        }

        // Scale the matrix using vDSP for vectorized division
        var A = [Double](repeating: 0, count: n * n)
        var scaleVal = scale
        vDSP_vsdivD(data, 1, &scaleVal, &A, 1, vDSP_Length(n * n))

        // Padé approximation of order [6/6]
        // coefficients
        let c = [1.0, 0.5, 0.12, 0.01833333333333333,
                 0.001992063492063492, 0.0001575312500000000,
                 0.00000918114788107536]

        // Build Padé numerator and denominator
        // U = A * (c1*I + A^2 * (c3*I + A^2 * (c5*I + c7*A^2)))
        // V = c0*I + A^2 * (c2*I + A^2 * (c4*I + c6*A^2))

        // Compute A^2
        let A2 = matmul(A, A, n)

        // Compute A^4
        let A4 = matmul(A2, A2, n)

        // Compute A^6
        let A6 = matmul(A2, A4, n)

        // V = c[0]*I + c[2]*A^2 + c[4]*A^4 + c[6]*A^6
        // Using vDSP for vectorized linear combinations
        var V = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            V[i * n + i] = c[0]  // c0 * I (diagonal)
        }
        // V += c[2]*A2 using vDSP_vsmaD (scalar multiply and add)
        var c2 = c[2]
        vDSP_vsmaD(A2, 1, &c2, V, 1, &V, 1, vDSP_Length(n * n))
        // V += c[4]*A4
        var c4 = c[4]
        vDSP_vsmaD(A4, 1, &c4, V, 1, &V, 1, vDSP_Length(n * n))
        // V += c[6]*A6
        var c6 = c[6]
        vDSP_vsmaD(A6, 1, &c6, V, 1, &V, 1, vDSP_Length(n * n))

        // U_inner = c[1]*I + c[3]*A^2 + c[5]*A^4
        var Uinner = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            Uinner[i * n + i] = c[1]  // c1 * I (diagonal)
        }
        // Uinner += c[3]*A2
        var c3 = c[3]
        vDSP_vsmaD(A2, 1, &c3, Uinner, 1, &Uinner, 1, vDSP_Length(n * n))
        // Uinner += c[5]*A4
        var c5 = c[5]
        vDSP_vsmaD(A4, 1, &c5, Uinner, 1, &Uinner, 1, vDSP_Length(n * n))

        // U = A * U_inner
        let U = matmul(A, Uinner, n)

        // Padé approximant: exp(A) ≈ (V - U)^(-1) * (V + U)
        // R = (V - U)^(-1) * (V + U)

        // Compute V - U and V + U using vDSP for vectorized operations
        var VminusU = [Double](repeating: 0, count: n * n)
        var VplusU = [Double](repeating: 0, count: n * n)
        vDSP_vsubD(U, 1, V, 1, &VminusU, 1, vDSP_Length(n * n))  // VminusU = V - U
        vDSP_vaddD(V, 1, U, 1, &VplusU, 1, vDSP_Length(n * n))   // VplusU = V + U

        // Solve (V - U) * R = (V + U) using LU factorization
        var R = solveLinearSystem(VminusU, VplusU, n)

        // Squaring: exp(A) = (exp(A/2^s))^(2^s)
        for _ in 0..<s {
            R = matmul(R, R, n)
        }

        return createMatrixTable(rows: n, cols: n, data: R)
    }

    /// Helper: Matrix multiplication C = A * B for n x n matrices
    /// Uses BLAS cblas_dgemm for hardware-accelerated, cache-optimized multiplication
    private static func matmul(_ A: [Double], _ B: [Double], _ n: Int) -> [Double] {
        var C = [Double](repeating: 0, count: n * n)
        // cblas_dgemm: C = alpha * A * B + beta * C
        // CblasRowMajor: matrices are in row-major order
        // CblasNoTrans: no transpose on A or B
        cblas_dgemm(
            CblasRowMajor,           // Row-major storage
            CblasNoTrans,            // Don't transpose A
            CblasNoTrans,            // Don't transpose B
            Int32(n),                // M: rows of A (and C)
            Int32(n),                // N: cols of B (and C)
            Int32(n),                // K: cols of A, rows of B
            1.0,                     // alpha: scalar multiplier for A*B
            A,                       // Matrix A
            Int32(n),                // lda: leading dimension of A
            B,                       // Matrix B
            Int32(n),                // ldb: leading dimension of B
            0.0,                     // beta: scalar multiplier for C (0 = overwrite)
            &C,                      // Matrix C (output)
            Int32(n)                 // ldc: leading dimension of C
        )
        return C
    }

    /// Helper: Solve A * X = B for X, where A and B are n x n matrices
    private static func solveLinearSystem(_ A: [Double], _ B: [Double], _ n: Int) -> [Double] {
        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                a[j * n + i] = A[i * n + j]
            }
        }

        var b = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                b[j * n + i] = B[i * n + j]
            }
        }

        var n1 = __CLPK_integer(n)
        var nrhs = __CLPK_integer(n)
        var lda = __CLPK_integer(n)
        var ipiv = [__CLPK_integer](repeating: 0, count: n)
        var ldb = __CLPK_integer(n)
        var info: __CLPK_integer = 0

        dgesv_(&n1, &nrhs, &a, &lda, &ipiv, &b, &ldb, &info)

        // Convert back to row-major
        var result = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                result[i * n + j] = b[j * n + i]
            }
        }

        return result
    }

    // MARK: - Matrix Logarithm (logm)

    /// Matrix logarithm using eigendecomposition
    /// log(A) = V * diag(log(λ)) * V^(-1) for diagonalizable matrices
    private static func logmCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.logm: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.logm: matrix must be square")
        }

        let n = rows

        // Compute eigendecomposition using LAPACK dgeev
        let (eigenvalues, eigenvectors) = try computeEigendecomposition(data, n)

        // Check for non-positive eigenvalues
        for ev in eigenvalues {
            if ev <= 0 {
                throw LuaError.callbackError("linalg.logm: matrix has non-positive eigenvalues, logarithm undefined")
            }
        }

        // Apply log to eigenvalues
        let logEigenvalues = eigenvalues.map { log($0) }

        // Reconstruct: logA = V * diag(log(λ)) * V^(-1)
        let result = reconstructFromEigen(eigenvectors, logEigenvalues, n)

        return createMatrixTable(rows: n, cols: n, data: result)
    }

    // MARK: - Matrix Square Root (sqrtm)

    /// Matrix square root using eigendecomposition
    /// sqrt(A) = V * diag(sqrt(λ)) * V^(-1) for diagonalizable matrices
    private static func sqrtmCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.sqrtm: missing argument")
        }

        let (rows, cols, data) = try extractMatrixData(arg)

        guard rows == cols else {
            throw LuaError.callbackError("linalg.sqrtm: matrix must be square")
        }

        let n = rows

        // Compute eigendecomposition using LAPACK dgeev
        let (eigenvalues, eigenvectors) = try computeEigendecomposition(data, n)

        // Check for negative eigenvalues
        for ev in eigenvalues {
            if ev < 0 {
                throw LuaError.callbackError("linalg.sqrtm: matrix has negative eigenvalues, real square root undefined")
            }
        }

        // Apply sqrt to eigenvalues
        let sqrtEigenvalues = eigenvalues.map { sqrt($0) }

        // Reconstruct: sqrtA = V * diag(sqrt(λ)) * V^(-1)
        let result = reconstructFromEigen(eigenvectors, sqrtEigenvalues, n)

        return createMatrixTable(rows: n, cols: n, data: result)
    }

    // MARK: - General Matrix Function (funm)

    /// General matrix function using eigendecomposition
    /// f(A) = V * diag(f(λ)) * V^(-1) for diagonalizable matrices
    /// Note: For this implementation, we support common built-in functions
    /// (sin, cos, exp, log, sqrt) as string identifiers
    private static func funmCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.funm: requires matrix and function arguments")
        }

        let (rows, cols, data) = try extractMatrixData(args[0])

        guard rows == cols else {
            throw LuaError.callbackError("linalg.funm: matrix must be square")
        }

        let n = rows

        // Get the function name or use a built-in
        let funcName: String
        if case let .string(name) = args[1] {
            funcName = name
        } else {
            throw LuaError.callbackError("linalg.funm: function must be a string name (sin, cos, exp, log, sqrt, sinh, cosh, tanh)")
        }

        // Compute eigendecomposition using LAPACK dgeev
        let (eigenvalues, eigenvectors) = try computeEigendecomposition(data, n)

        // Apply the function to eigenvalues
        let transformedEigenvalues: [Double]
        switch funcName {
        case "sin":
            transformedEigenvalues = eigenvalues.map { sin($0) }
        case "cos":
            transformedEigenvalues = eigenvalues.map { cos($0) }
        case "exp":
            transformedEigenvalues = eigenvalues.map { exp($0) }
        case "log":
            for ev in eigenvalues {
                if ev <= 0 {
                    throw LuaError.callbackError("linalg.funm: log requires positive eigenvalues")
                }
            }
            transformedEigenvalues = eigenvalues.map { log($0) }
        case "sqrt":
            for ev in eigenvalues {
                if ev < 0 {
                    throw LuaError.callbackError("linalg.funm: sqrt requires non-negative eigenvalues")
                }
            }
            transformedEigenvalues = eigenvalues.map { sqrt($0) }
        case "sinh":
            transformedEigenvalues = eigenvalues.map { sinh($0) }
        case "cosh":
            transformedEigenvalues = eigenvalues.map { cosh($0) }
        case "tanh":
            transformedEigenvalues = eigenvalues.map { tanh($0) }
        case "abs":
            transformedEigenvalues = eigenvalues.map { abs($0) }
        default:
            throw LuaError.callbackError("linalg.funm: unsupported function '\(funcName)'. Use: sin, cos, exp, log, sqrt, sinh, cosh, tanh, abs")
        }

        // Reconstruct: f(A) = V * diag(f(λ)) * V^(-1)
        let result = reconstructFromEigen(eigenvectors, transformedEigenvalues, n)

        return createMatrixTable(rows: n, cols: n, data: result)
    }

    // MARK: - Eigendecomposition Helpers

    /// Compute eigendecomposition and return (eigenvalues, eigenvectors)
    /// Returns real eigenvalues only; throws if complex eigenvalues are present
    private static func computeEigendecomposition(_ data: [Double], _ n: Int) throws -> ([Double], [Double]) {
        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                a[j * n + i] = data[i * n + j]
            }
        }

        var n1 = __CLPK_integer(n)
        var lda1 = __CLPK_integer(n)
        var wr = [Double](repeating: 0, count: n)  // Real parts
        var wi = [Double](repeating: 0, count: n)  // Imaginary parts
        var vl = [Double](repeating: 0, count: 1)  // Left eigenvectors (not computed)
        var vr = [Double](repeating: 0, count: n * n)  // Right eigenvectors
        var ldvl: __CLPK_integer = 1
        var ldvr = __CLPK_integer(n)
        var info: __CLPK_integer = 0

        // Query workspace
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var jobvl = Int8(UInt8(ascii: "N"))
        var jobvr = Int8(UInt8(ascii: "V"))

        dgeev_(&jobvl, &jobvr, &n1, &a, &lda1, &wr, &wi, &vl, &ldvl, &vr, &ldvr, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        // Reset a for actual computation
        for i in 0..<n {
            for j in 0..<n {
                a[j * n + i] = data[i * n + j]
            }
        }

        var n2 = __CLPK_integer(n)
        var lda2 = __CLPK_integer(n)
        dgeev_(&jobvl, &jobvr, &n2, &a, &lda2, &wr, &wi, &vl, &ldvl, &vr, &ldvr, &work, &lwork, &info)

        if info != 0 {
            throw LuaError.callbackError("eigendecomposition failed")
        }

        // Check for complex eigenvalues
        for im in wi {
            if abs(im) > 1e-10 {
                throw LuaError.callbackError("matrix has complex eigenvalues; real-only implementation")
            }
        }

        // Convert eigenvectors to row-major
        var vecs = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                vecs[i * n + j] = vr[j * n + i]
            }
        }

        return (wr, vecs)
    }

    /// Reconstruct matrix from eigendecomposition: A = V * diag(λ) * V^(-1)
    private static func reconstructFromEigen(_ V: [Double], _ eigenvalues: [Double], _ n: Int) -> [Double] {
        // Compute V^(-1)
        let Vinv = invertMatrix(V, n)

        // Compute V * diag(λ)
        var VD = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                VD[i * n + j] = V[i * n + j] * eigenvalues[j]
            }
        }

        // Compute (V * diag(λ)) * V^(-1)
        return matmul(VD, Vinv, n)
    }

    /// Invert matrix using LU decomposition
    private static func invertMatrix(_ M: [Double], _ n: Int) -> [Double] {
        // Convert to column-major for LAPACK
        var a = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                a[j * n + i] = M[i * n + j]
            }
        }

        var n1 = __CLPK_integer(n)
        var n1b = __CLPK_integer(n)
        var lda = __CLPK_integer(n)
        var ipiv = [__CLPK_integer](repeating: 0, count: n)
        var info: __CLPK_integer = 0

        // LU factorization
        dgetrf_(&n1, &n1b, &a, &lda, &ipiv, &info)

        if info != 0 {
            return M // Return original if factorization fails
        }

        // Query workspace for inversion
        var lwork: __CLPK_integer = -1
        var work = [Double](repeating: 0, count: 1)
        var n2 = __CLPK_integer(n)
        var lda2 = __CLPK_integer(n)

        dgetri_(&n2, &a, &lda2, &ipiv, &work, &lwork, &info)

        lwork = __CLPK_integer(work[0])
        work = [Double](repeating: 0, count: Int(lwork))

        // Compute inverse
        var n3 = __CLPK_integer(n)
        var lda3 = __CLPK_integer(n)
        dgetri_(&n3, &a, &lda3, &ipiv, &work, &lwork, &info)

        // Convert back to row-major
        var result = [Double](repeating: 0, count: n * n)
        for i in 0..<n {
            for j in 0..<n {
                result[i * n + j] = a[j * n + i]
            }
        }

        return result
    }
}
