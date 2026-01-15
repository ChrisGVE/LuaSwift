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
import NumericSwift

/// Swift-backed linear algebra module for LuaSwift.
///
/// This is a thin shim that delegates to NumericSwift.LinAlg for all computations.
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
        engine.registerFunction(name: "_luaswift_linalg_ceig", callback: ceigCallback)
        engine.registerFunction(name: "_luaswift_linalg_ceigvals", callback: ceigvalsCallback)
        engine.registerFunction(name: "_luaswift_linalg_cdet", callback: cdetCallback)
        engine.registerFunction(name: "_luaswift_linalg_cinv", callback: cinvCallback)

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
                local _ceig = _luaswift_linalg_ceig
                local _ceigvals = _luaswift_linalg_ceigvals
                local _cdet = _luaswift_linalg_cdet
                local _cinv = _luaswift_linalg_cinv
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
                    ceig = function(A)
                        local result = _ceig(A)
                        return result[1], result[2]
                    end,
                    ceigvals = function(A)
                        return _ceigvals(A)
                    end,
                    cdet = function(A)
                        return _cdet(A)
                    end,
                    cinv = function(A)
                        return _cinv(A)
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
                _luaswift_linalg_ceig = nil
                _luaswift_linalg_ceigvals = nil
                _luaswift_linalg_cdet = nil
                _luaswift_linalg_cinv = nil
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
    private static func trackMatrixAllocation(count: Int) throws {
        let bytes = count * MemoryLayout<Double>.size
        if let engine = LuaEngine.currentEngine {
            try engine.trackAllocation(bytes: bytes)
        }
    }

    // MARK: - LuaValue <-> LinAlg.Matrix Conversion

    private static func createMatrixTable(rows: Int, cols: Int, data: [Double]) -> LuaValue {
        return .table([
            "type": .string(cols == 1 ? "vector" : "matrix"),
            "rows": .number(Double(rows)),
            "cols": .number(Double(cols)),
            "data": .array(data.map { .number($0) })
        ])
    }

    private static func createMatrixTableFrom(_ m: LinAlg.Matrix) -> LuaValue {
        return createMatrixTable(rows: m.rows, cols: m.cols, data: m.data)
    }

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

    private static func extractMatrix(_ value: LuaValue) throws -> LinAlg.Matrix {
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

        return LinAlg.Matrix(rows: rows, cols: cols, data: data)
    }

    private static func extractComplexMatrix(_ value: LuaValue) throws -> LinAlg.ComplexMatrix {
        guard case .table(let dict) = value else {
            throw LuaError.callbackError("linalg: expected complex matrix table")
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

            return LinAlg.ComplexMatrix(rows: rows, cols: cols, real: real, imag: imag)
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
                real.append(num)
                imag.append(0)
            } else {
                throw LuaError.callbackError("linalg: complex matrix elements must be {re=, im=} tables or numbers")
            }
        }

        return LinAlg.ComplexMatrix(rows: rows, cols: cols, real: real, imag: imag)
    }

    private static func extractComplexMatrixForCeig(_ value: LuaValue) throws -> LinAlg.ComplexMatrix {
        guard let table = value.tableValue,
              let shapeVal = table["shape"]?.arrayValue,
              shapeVal.count == 2,
              let rows = shapeVal[0].intValue,
              let cols = shapeVal[1].intValue,
              let realVals = table["real"]?.arrayValue,
              let imagVals = table["imag"]?.arrayValue else {
            throw LuaError.callbackError("linalg: requires a complex matrix")
        }

        guard rows == cols else {
            throw LuaError.callbackError("linalg: matrix must be square")
        }

        var real: [Double] = []
        var imag: [Double] = []
        real.reserveCapacity(rows * cols)
        imag.reserveCapacity(rows * cols)

        for i in 0..<rows {
            guard let rowReal = realVals[i].arrayValue,
                  let rowImag = imagVals[i].arrayValue else {
                throw LuaError.callbackError("linalg: invalid matrix format")
            }
            for j in 0..<cols {
                real.append(rowReal[j].numberValue ?? 0)
                imag.append(rowImag[j].numberValue ?? 0)
            }
        }

        return LinAlg.ComplexMatrix(rows: rows, cols: cols, real: real, imag: imag)
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

        try trackMatrixAllocation(count: rows * cols)
        let m = LinAlg.zeros(rows, cols)
        return createMatrixTableFrom(m)
    }

    private static func onesCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let rows = args.first?.intValue else {
            throw LuaError.callbackError("linalg.ones requires at least one size argument")
        }

        let cols = args.count > 1 ? (args[1].intValue ?? 1) : 1

        guard rows > 0 && cols > 0 else {
            throw LuaError.callbackError("linalg.ones: dimensions must be positive")
        }

        try trackMatrixAllocation(count: rows * cols)
        let m = LinAlg.ones(rows, cols)
        return createMatrixTableFrom(m)
    }

    private static func eyeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let n = args.first?.intValue else {
            throw LuaError.callbackError("linalg.eye requires a size argument")
        }

        guard n > 0 else {
            throw LuaError.callbackError("linalg.eye: size must be positive")
        }

        try trackMatrixAllocation(count: n * n)
        let m = LinAlg.eye(n)
        return createMatrixTableFrom(m)
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
        try trackMatrixAllocation(count: n * n)
        let m = LinAlg.diag(diagVals)
        return createMatrixTableFrom(m)
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

        let m = LinAlg.arange(start, stop, step)
        return createMatrixTableFrom(m)
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
        let m = LinAlg.linspace(start, stop, n)
        return createMatrixTableFrom(m)
    }

    // MARK: - Property Functions

    private static func rowsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.rows: missing argument")
        }
        let m = try extractMatrix(arg)
        return .number(Double(m.rows))
    }

    private static func colsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.cols: missing argument")
        }
        let m = try extractMatrix(arg)
        return .number(Double(m.cols))
    }

    private static func shapeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.shape: missing argument")
        }
        let m = try extractMatrix(arg)
        if m.cols == 1 {
            return .array([.number(Double(m.rows))])
        }
        return .array([.number(Double(m.rows)), .number(Double(m.cols))])
    }

    private static func sizeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.size: missing argument")
        }
        let m = try extractMatrix(arg)
        return .number(Double(m.size))
    }

    private static func getCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let i = args[1].intValue else {
            throw LuaError.callbackError("linalg.get: requires matrix and index")
        }

        let m = try extractMatrix(args[0])

        if m.cols == 1 {
            guard i >= 1 && i <= m.rows else {
                throw LuaError.callbackError("linalg.get: index out of bounds")
            }
            return .number(m[i - 1])
        } else {
            guard args.count >= 3,
                  let j = args[2].intValue else {
                throw LuaError.callbackError("linalg.get: matrix requires two indices")
            }
            guard i >= 1 && i <= m.rows && j >= 1 && j <= m.cols else {
                throw LuaError.callbackError("linalg.get: indices out of bounds")
            }
            return .number(m[i - 1, j - 1])
        }
    }

    private static func setCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("linalg.set: requires matrix, index, and value")
        }

        var m = try extractMatrix(args[0])

        if m.cols == 1 {
            guard let i = args[1].intValue,
                  let value = args[2].numberValue else {
                throw LuaError.callbackError("linalg.set: requires numeric index and value")
            }
            guard i >= 1 && i <= m.rows else {
                throw LuaError.callbackError("linalg.set: index out of bounds")
            }
            m[i - 1] = value
        } else {
            guard args.count >= 4,
                  let i = args[1].intValue,
                  let j = args[2].intValue,
                  let value = args[3].numberValue else {
                throw LuaError.callbackError("linalg.set: matrix requires two indices and value")
            }
            guard i >= 1 && i <= m.rows && j >= 1 && j <= m.cols else {
                throw LuaError.callbackError("linalg.set: indices out of bounds")
            }
            m[i - 1, j - 1] = value
        }

        return createMatrixTableFrom(m)
    }

    private static func rowCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let i = args[1].intValue else {
            throw LuaError.callbackError("linalg.row: requires matrix and row index")
        }

        let m = try extractMatrix(args[0])

        guard i >= 1 && i <= m.rows else {
            throw LuaError.callbackError("linalg.row: index out of bounds")
        }

        let row = m.row(i - 1)
        return createMatrixTableFrom(row)
    }

    private static func colCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let j = args[1].intValue else {
            throw LuaError.callbackError("linalg.col: requires matrix and column index")
        }

        let m = try extractMatrix(args[0])

        guard j >= 1 && j <= m.cols else {
            throw LuaError.callbackError("linalg.col: index out of bounds")
        }

        let col = m.col(j - 1)
        return createMatrixTableFrom(col)
    }

    private static func transposeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.transpose: missing argument")
        }

        let m = try extractMatrix(arg)
        return createMatrixTableFrom(m.T)
    }

    private static func toArrayCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.toarray: missing argument")
        }

        let m = try extractMatrix(arg)

        if m.cols == 1 {
            return .array(m.data.map { .number($0) })
        } else {
            let arr2d = m.toArray()
            return .array(arr2d.map { row in
                .array(row.map { .number($0) })
            })
        }
    }

    // MARK: - Arithmetic Operations

    private static func addCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.add: requires two arguments")
        }

        let m1 = try extractMatrix(args[0])
        let m2 = try extractMatrix(args[1])

        guard m1.rows == m2.rows && m1.cols == m2.cols else {
            throw LuaError.callbackError("linalg.add: matrices must have same dimensions")
        }

        return createMatrixTableFrom(LinAlg.add(m1, m2))
    }

    private static func subCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.sub: requires two arguments")
        }

        let m1 = try extractMatrix(args[0])
        let m2 = try extractMatrix(args[1])

        guard m1.rows == m2.rows && m1.cols == m2.cols else {
            throw LuaError.callbackError("linalg.sub: matrices must have same dimensions")
        }

        return createMatrixTableFrom(LinAlg.sub(m1, m2))
    }

    private static func mulCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.mul: requires two arguments")
        }

        // Check if second argument is a scalar
        if let scalar = args[1].numberValue {
            let m = try extractMatrix(args[0])
            return createMatrixTableFrom(LinAlg.mul(m, scalar))
        }

        // Check if first argument is a scalar
        if let scalar = args[0].numberValue {
            let m = try extractMatrix(args[1])
            return createMatrixTableFrom(LinAlg.mul(scalar, m))
        }

        // Matrix multiplication
        return try dotCallback(args)
    }

    private static func divCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.div: requires two arguments")
        }

        guard let scalar = args[1].numberValue else {
            throw LuaError.callbackError("linalg.div: second argument must be a scalar")
        }

        guard scalar != 0 else {
            throw LuaError.callbackError("linalg.div: division by zero")
        }

        let m = try extractMatrix(args[0])
        return createMatrixTableFrom(LinAlg.div(m, scalar))
    }

    private static func dotCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.dot: requires two arguments")
        }

        let m1 = try extractMatrix(args[0])
        let m2 = try extractMatrix(args[1])

        // Vector dot product returns scalar
        if m1.cols == 1 && m2.cols == 1 {
            guard m1.rows == m2.rows else {
                throw LuaError.callbackError("linalg.dot: vectors must have same length")
            }
            // Compute scalar dot product
            var sum = 0.0
            for i in 0..<m1.rows {
                sum += m1[i] * m2[i]
            }
            return .number(sum)
        }

        // Matrix/vector multiplication
        guard m1.cols == m2.rows else {
            throw LuaError.callbackError("linalg.dot: incompatible dimensions")
        }

        return createMatrixTableFrom(LinAlg.dot(m1, m2))
    }

    private static func hadamardCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.hadamard: requires two arguments")
        }

        let m1 = try extractMatrix(args[0])
        let m2 = try extractMatrix(args[1])

        guard m1.rows == m2.rows && m1.cols == m2.cols else {
            throw LuaError.callbackError("linalg.hadamard: matrices must have same dimensions")
        }

        return createMatrixTableFrom(LinAlg.hadamard(m1, m2))
    }

    // MARK: - Linear Algebra Operations

    private static func detCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.det: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.det: matrix must be square")
        }

        return .number(LinAlg.det(m))
    }

    private static func invCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.inv: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.inv: matrix must be square")
        }

        guard let result = LinAlg.inv(m) else {
            throw LuaError.callbackError("linalg.inv: matrix is singular")
        }

        return createMatrixTableFrom(result)
    }

    private static func traceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.trace: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.trace: matrix must be square")
        }

        return .number(LinAlg.trace(m))
    }

    private static func normCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.norm: missing argument")
        }

        let m = try extractMatrix(arg)
        let p = args.count > 1 ? (args[1].numberValue ?? 2) : 2

        return .number(LinAlg.norm(m, p))
    }

    private static func rankCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.rank: missing argument")
        }

        let m = try extractMatrix(arg)
        return .number(Double(LinAlg.rank(m)))
    }

    private static func condCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.cond: missing argument")
        }

        let m = try extractMatrix(arg)
        return .number(LinAlg.cond(m))
    }

    private static func pinvCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.pinv: missing argument")
        }

        let m = try extractMatrix(arg)
        let rcond = args.count > 1 ? (args[1].numberValue ?? 1e-15) : 1e-15

        return createMatrixTableFrom(LinAlg.pinv(m, rcond: rcond))
    }

    // MARK: - Decompositions

    private static func luCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.lu: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.lu: matrix must be square")
        }

        let (L, U, P) = LinAlg.lu(m)
        return .array([
            createMatrixTableFrom(L),
            createMatrixTableFrom(U),
            createMatrixTableFrom(P)
        ])
    }

    private static func qrCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.qr: missing argument")
        }

        let m = try extractMatrix(arg)
        let (Q, R) = LinAlg.qr(m)

        return .array([
            createMatrixTableFrom(Q),
            createMatrixTableFrom(R)
        ])
    }

    private static func svdCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.svd: missing argument")
        }

        let m = try extractMatrix(arg)
        let return1D = args.count > 1 && (args[1].boolValue ?? false)

        let (s, U, Vt) = LinAlg.svd(m)

        let sValue: LuaValue
        if return1D {
            sValue = createMatrixTable(rows: s.count, cols: 1, data: s)
        } else {
            // Return as diagonal matrix for backward compatibility
            var S = [Double](repeating: 0, count: m.rows * m.cols)
            let minDim = min(m.rows, m.cols)
            for i in 0..<minDim {
                S[i * m.cols + i] = s[i]
            }
            sValue = createMatrixTable(rows: m.rows, cols: m.cols, data: S)
        }

        // Note: LinAlg.svd returns Vt (transpose), so transpose to get V
        return .array([
            createMatrixTableFrom(U),
            sValue,
            createMatrixTableFrom(Vt.T)
        ])
    }

    private static func eigCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.eig: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.eig: matrix must be square")
        }

        let (values, imagParts, vectors) = LinAlg.eig(m)

        // Check for complex eigenvalues
        let hasComplex = imagParts.contains { abs($0) > 1e-14 }

        if hasComplex {
            return .array([
                createComplexMatrixTable(rows: m.rows, cols: 1, real: values, imag: imagParts),
                createMatrixTableFrom(vectors)
            ])
        } else {
            return .array([
                createMatrixTable(rows: m.rows, cols: 1, data: values),
                createMatrixTableFrom(vectors)
            ])
        }
    }

    private static func eigvalsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.eigvals: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.eigvals: matrix must be square")
        }

        let (real, imag) = LinAlg.eigvals(m)

        // Check for complex eigenvalues
        let hasComplex = imag.contains { abs($0) > 1e-14 }

        if hasComplex {
            return createComplexMatrixTable(rows: m.rows, cols: 1, real: real, imag: imag)
        } else {
            return createMatrixTable(rows: m.rows, cols: 1, data: real)
        }
    }

    private static func cholCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.chol: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.chol: matrix must be square")
        }

        guard let result = LinAlg.cholesky(m) else {
            throw LuaError.callbackError("linalg.chol: matrix is not positive definite")
        }

        return createMatrixTableFrom(result)
    }

    // MARK: - Solvers

    private static func solveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.solve: requires A and b arguments")
        }

        let A = try extractMatrix(args[0])
        let b = try extractMatrix(args[1])

        guard A.rows == A.cols else {
            throw LuaError.callbackError("linalg.solve: A must be square")
        }

        guard A.rows == b.rows else {
            throw LuaError.callbackError("linalg.solve: A and b must have compatible dimensions")
        }

        guard let result = LinAlg.solve(A, b) else {
            throw LuaError.callbackError("linalg.solve: system is singular or computation failed")
        }

        return createMatrixTableFrom(result)
    }

    private static func lstsqCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.lstsq: requires A and b arguments")
        }

        let A = try extractMatrix(args[0])
        let b = try extractMatrix(args[1])

        guard A.rows == b.rows else {
            throw LuaError.callbackError("linalg.lstsq: A and b must have compatible dimensions")
        }

        guard let result = LinAlg.lstsq(A, b) else {
            throw LuaError.callbackError("linalg.lstsq: computation failed")
        }

        return createMatrixTableFrom(result)
    }

    // MARK: - Complex Linear Algebra

    private static func csolveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.csolve: requires A and b arguments")
        }

        let A = try extractComplexMatrix(args[0])
        let b = try extractComplexMatrix(args[1])

        guard A.rows == A.cols else {
            throw LuaError.callbackError("linalg.csolve: A must be square")
        }

        guard A.rows == b.rows else {
            throw LuaError.callbackError("linalg.csolve: A and b must have compatible dimensions")
        }

        guard let result = LinAlg.csolve(A, b) else {
            throw LuaError.callbackError("linalg.csolve: system is singular or computation failed")
        }

        return createComplexMatrixTable(rows: result.rows, cols: result.cols, real: result.real, imag: result.imag)
    }

    private static func csvdCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.csvd: missing argument")
        }

        let m = try extractComplexMatrix(arg)

        guard let (s, U, Vt) = LinAlg.csvd(m) else {
            throw LuaError.callbackError("linalg.csvd: computation failed")
        }

        // S is real
        let sValue = createMatrixTable(rows: s.count, cols: 1, data: s)

        return .array([
            createComplexMatrixTable(rows: U.rows, cols: U.cols, real: U.real, imag: U.imag),
            sValue,
            createComplexMatrixTable(rows: Vt.rows, cols: Vt.cols, real: Vt.real, imag: Vt.imag)
        ])
    }

    private static func ceigCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.ceig: missing argument")
        }

        let m = try extractComplexMatrixForCeig(arg)

        guard let (values, vectors) = LinAlg.ceig(m) else {
            throw LuaError.callbackError("linalg.ceig: computation failed")
        }

        return .array([
            createComplexMatrixTable(rows: values.rows, cols: values.cols, real: values.real, imag: values.imag),
            createComplexMatrixTable(rows: vectors.rows, cols: vectors.cols, real: vectors.real, imag: vectors.imag)
        ])
    }

    private static func ceigvalsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.ceigvals: missing argument")
        }

        let m = try extractComplexMatrixForCeig(arg)

        guard let result = LinAlg.ceigvals(m) else {
            throw LuaError.callbackError("linalg.ceigvals: computation failed")
        }

        return createComplexMatrixTable(rows: result.rows, cols: result.cols, real: result.real, imag: result.imag)
    }

    private static func cdetCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.cdet: missing argument")
        }

        let m = try extractComplexMatrixForCeig(arg)

        guard let (re, im) = LinAlg.cdet(m) else {
            return .table(["re": .number(0), "im": .number(0)])
        }

        return .table(["re": .number(re), "im": .number(im)])
    }

    private static func cinvCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.cinv: missing argument")
        }

        let m = try extractComplexMatrixForCeig(arg)

        guard let result = LinAlg.cinv(m) else {
            throw LuaError.callbackError("linalg.cinv: matrix is singular")
        }

        return createComplexMatrixTable(rows: result.rows, cols: result.cols, real: result.real, imag: result.imag)
    }

    // MARK: - Advanced Solvers

    private static func solveTriangularCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.solve_triangular: requires A and b arguments")
        }

        let A = try extractMatrix(args[0])
        let b = try extractMatrix(args[1])

        guard A.rows == A.cols else {
            throw LuaError.callbackError("linalg.solve_triangular: A must be square")
        }

        guard A.rows == b.rows else {
            throw LuaError.callbackError("linalg.solve_triangular: A and b must have compatible dimensions")
        }

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

        guard let result = LinAlg.solveTriangular(A, b, lower: lower, trans: trans) else {
            throw LuaError.callbackError("linalg.solve_triangular: system is singular or computation failed")
        }

        return createMatrixTableFrom(result)
    }

    private static func choSolveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.cho_solve: requires L and b arguments")
        }

        let L = try extractMatrix(args[0])
        let b = try extractMatrix(args[1])

        guard L.rows == L.cols else {
            throw LuaError.callbackError("linalg.cho_solve: L must be square")
        }

        guard L.rows == b.rows else {
            throw LuaError.callbackError("linalg.cho_solve: L and b must have compatible dimensions")
        }

        guard let result = LinAlg.choSolve(L, b) else {
            throw LuaError.callbackError("linalg.cho_solve: computation failed")
        }

        return createMatrixTableFrom(result)
    }

    private static func luSolveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 4 else {
            throw LuaError.callbackError("linalg.lu_solve: requires L, U, P, and b arguments")
        }

        let L = try extractMatrix(args[0])
        let U = try extractMatrix(args[1])
        let P = try extractMatrix(args[2])
        let b = try extractMatrix(args[3])

        guard L.rows == L.cols && U.rows == U.cols && P.rows == P.cols else {
            throw LuaError.callbackError("linalg.lu_solve: L, U, P must be square")
        }

        guard L.rows == U.rows && L.rows == P.rows else {
            throw LuaError.callbackError("linalg.lu_solve: L, U, P must have same dimensions")
        }

        guard L.rows == b.rows else {
            throw LuaError.callbackError("linalg.lu_solve: dimensions must be compatible with b")
        }

        let result = LinAlg.luSolve(L, U, P, b)
        return createMatrixTableFrom(result)
    }

    // MARK: - Matrix Functions

    private static func expmCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.expm: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.expm: matrix must be square")
        }

        return createMatrixTableFrom(LinAlg.expm(m))
    }

    private static func logmCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.logm: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.logm: matrix must be square")
        }

        guard let result = LinAlg.logm(m) else {
            throw LuaError.callbackError("linalg.logm: matrix has non-positive eigenvalues, logarithm undefined")
        }

        return createMatrixTableFrom(result)
    }

    private static func sqrtmCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("linalg.sqrtm: missing argument")
        }

        let m = try extractMatrix(arg)

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.sqrtm: matrix must be square")
        }

        guard let result = LinAlg.sqrtm(m) else {
            throw LuaError.callbackError("linalg.sqrtm: matrix has negative eigenvalues, real square root undefined")
        }

        return createMatrixTableFrom(result)
    }

    private static func funmCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("linalg.funm: requires matrix and function arguments")
        }

        let m = try extractMatrix(args[0])

        guard m.rows == m.cols else {
            throw LuaError.callbackError("linalg.funm: matrix must be square")
        }

        guard case let .string(funcName) = args[1] else {
            throw LuaError.callbackError("linalg.funm: function must be a string name (sin, cos, exp, log, sqrt, sinh, cosh, tanh)")
        }

        let matrixFunc: LinAlg.MatrixFunction
        switch funcName {
        case "sin":
            matrixFunc = .sin
        case "cos":
            matrixFunc = .cos
        case "exp":
            matrixFunc = .exp
        case "log":
            matrixFunc = .log
        case "sqrt":
            matrixFunc = .sqrt
        case "sinh":
            matrixFunc = .sinh
        case "cosh":
            matrixFunc = .cosh
        case "tanh":
            matrixFunc = .tanh
        case "abs":
            matrixFunc = .abs
        default:
            throw LuaError.callbackError("linalg.funm: unsupported function '\(funcName)'. Use: sin, cos, exp, log, sqrt, sinh, cosh, tanh, abs")
        }

        guard let result = LinAlg.funm(m, matrixFunc) else {
            throw LuaError.callbackError("linalg.funm: function application failed (check eigenvalue constraints)")
        }

        return createMatrixTableFrom(result)
    }
}
