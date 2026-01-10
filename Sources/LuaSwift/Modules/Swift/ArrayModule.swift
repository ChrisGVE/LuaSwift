//
//  ArrayModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-01.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import Accelerate

/// NumPy-like array module for LuaSwift.
///
/// Provides N-dimensional array operations with efficient storage using Apple Accelerate.
///
/// ## Usage
///
/// ```lua
/// local np = require("luaswift.array")
///
/// local a = np.array({1, 2, 3, 4, 5, 6})
/// local b = np.zeros({3, 4})
/// local c = np.reshape(a, {2, 3})
///
/// print(c:shape())  -- {2, 3}
/// print(np.sum(c))  -- 21
/// ```
public struct ArrayModule {
    /// Register the array module in the given engine.
    public static func register(in engine: LuaEngine) {
        // Register creation functions
        engine.registerFunction(name: "_luaswift_array_create", callback: createCallback)
        engine.registerFunction(name: "_luaswift_array_zeros", callback: zerosCallback)
        engine.registerFunction(name: "_luaswift_array_ones", callback: onesCallback)
        engine.registerFunction(name: "_luaswift_array_arange", callback: arangeCallback)
        engine.registerFunction(name: "_luaswift_array_linspace", callback: linspaceCallback)
        engine.registerFunction(name: "_luaswift_array_rand", callback: randCallback)
        engine.registerFunction(name: "_luaswift_array_randn", callback: randnCallback)
        engine.registerFunction(name: "_luaswift_array_full", callback: fullCallback)

        // Register property accessors
        engine.registerFunction(name: "_luaswift_array_shape", callback: shapeCallback)
        engine.registerFunction(name: "_luaswift_array_ndim", callback: ndimCallback)
        engine.registerFunction(name: "_luaswift_array_size", callback: sizeCallback)
        engine.registerFunction(name: "_luaswift_array_get", callback: getCallback)
        engine.registerFunction(name: "_luaswift_array_set", callback: setCallback)

        // Register reshaping operations
        engine.registerFunction(name: "_luaswift_array_reshape", callback: reshapeCallback)
        engine.registerFunction(name: "_luaswift_array_flatten", callback: flattenCallback)
        engine.registerFunction(name: "_luaswift_array_squeeze", callback: squeezeCallback)
        engine.registerFunction(name: "_luaswift_array_expand_dims", callback: expandDimsCallback)
        engine.registerFunction(name: "_luaswift_array_transpose", callback: transposeCallback)

        // Register arithmetic operations
        engine.registerFunction(name: "_luaswift_array_add", callback: addCallback)
        engine.registerFunction(name: "_luaswift_array_sub", callback: subCallback)
        engine.registerFunction(name: "_luaswift_array_mul", callback: mulCallback)
        engine.registerFunction(name: "_luaswift_array_div", callback: divCallback)
        engine.registerFunction(name: "_luaswift_array_pow", callback: powCallback)
        engine.registerFunction(name: "_luaswift_array_neg", callback: negCallback)

        // Register math functions
        engine.registerFunction(name: "_luaswift_array_abs", callback: absCallback)
        engine.registerFunction(name: "_luaswift_array_sqrt", callback: sqrtCallback)
        engine.registerFunction(name: "_luaswift_array_exp", callback: expCallback)
        engine.registerFunction(name: "_luaswift_array_log", callback: logCallback)
        engine.registerFunction(name: "_luaswift_array_log2", callback: log2Callback)
        engine.registerFunction(name: "_luaswift_array_log10", callback: log10Callback)
        engine.registerFunction(name: "_luaswift_array_log1p", callback: log1pCallback)
        engine.registerFunction(name: "_luaswift_array_expm1", callback: expm1Callback)
        engine.registerFunction(name: "_luaswift_array_power", callback: powerCallback)
        engine.registerFunction(name: "_luaswift_array_sin", callback: sinCallback)
        engine.registerFunction(name: "_luaswift_array_cos", callback: cosCallback)
        engine.registerFunction(name: "_luaswift_array_tan", callback: tanCallback)

        // Register hyperbolic functions
        engine.registerFunction(name: "_luaswift_array_sinh", callback: sinhCallback)
        engine.registerFunction(name: "_luaswift_array_cosh", callback: coshCallback)
        engine.registerFunction(name: "_luaswift_array_tanh", callback: tanhCallback)
        engine.registerFunction(name: "_luaswift_array_asinh", callback: asinhCallback)
        engine.registerFunction(name: "_luaswift_array_acosh", callback: acoshCallback)
        engine.registerFunction(name: "_luaswift_array_atanh", callback: atanhCallback)

        // Register inverse trig functions
        engine.registerFunction(name: "_luaswift_array_arcsin", callback: arcsinCallback)
        engine.registerFunction(name: "_luaswift_array_arccos", callback: arccosCallback)
        engine.registerFunction(name: "_luaswift_array_arctan", callback: arctanCallback)
        engine.registerFunction(name: "_luaswift_array_arctan2", callback: arctan2Callback)

        // Register element-wise operations
        engine.registerFunction(name: "_luaswift_array_floor", callback: floorCallback)
        engine.registerFunction(name: "_luaswift_array_ceil", callback: ceilCallback)
        engine.registerFunction(name: "_luaswift_array_round", callback: roundCallback)
        engine.registerFunction(name: "_luaswift_array_clip", callback: clipCallback)
        engine.registerFunction(name: "_luaswift_array_sign", callback: signCallback)
        engine.registerFunction(name: "_luaswift_array_mod", callback: modCallback)
        engine.registerFunction(name: "_luaswift_array_fmod", callback: fmodCallback)

        // Register reduction operations
        engine.registerFunction(name: "_luaswift_array_sum", callback: sumCallback)
        engine.registerFunction(name: "_luaswift_array_mean", callback: meanCallback)
        engine.registerFunction(name: "_luaswift_array_std", callback: stdCallback)
        engine.registerFunction(name: "_luaswift_array_var", callback: varCallback)
        engine.registerFunction(name: "_luaswift_array_min", callback: minCallback)
        engine.registerFunction(name: "_luaswift_array_max", callback: maxCallback)
        engine.registerFunction(name: "_luaswift_array_argmin", callback: argminCallback)
        engine.registerFunction(name: "_luaswift_array_argmax", callback: argmaxCallback)
        engine.registerFunction(name: "_luaswift_array_prod", callback: prodCallback)

        // Register comparison operations
        engine.registerFunction(name: "_luaswift_array_equal", callback: equalCallback)
        engine.registerFunction(name: "_luaswift_array_greater", callback: greaterCallback)
        engine.registerFunction(name: "_luaswift_array_less", callback: lessCallback)
        engine.registerFunction(name: "_luaswift_array_greater_equal", callback: greaterEqualCallback)
        engine.registerFunction(name: "_luaswift_array_less_equal", callback: lessEqualCallback)
        engine.registerFunction(name: "_luaswift_array_not_equal", callback: notEqualCallback)
        engine.registerFunction(name: "_luaswift_array_isnan", callback: isnanCallback)
        engine.registerFunction(name: "_luaswift_array_isinf", callback: isinfCallback)
        engine.registerFunction(name: "_luaswift_array_isfinite", callback: isfiniteCallback)
        engine.registerFunction(name: "_luaswift_array_where", callback: whereCallback)

        // Register boolean reductions
        engine.registerFunction(name: "_luaswift_array_all", callback: allCallback)
        engine.registerFunction(name: "_luaswift_array_any", callback: anyCallback)
        engine.registerFunction(name: "_luaswift_array_cumsum", callback: cumsumCallback)
        engine.registerFunction(name: "_luaswift_array_cumprod", callback: cumprodCallback)

        // Register sorting and searching
        engine.registerFunction(name: "_luaswift_array_sort", callback: sortCallback)
        engine.registerFunction(name: "_luaswift_array_argsort", callback: argsortCallback)
        engine.registerFunction(name: "_luaswift_array_searchsorted", callback: searchsortedCallback)
        engine.registerFunction(name: "_luaswift_array_argwhere", callback: argwhereCallback)
        engine.registerFunction(name: "_luaswift_array_nonzero", callback: nonzeroCallback)
        engine.registerFunction(name: "_luaswift_array_unique", callback: uniqueCallback)

        // Register statistics functions
        engine.registerFunction(name: "_luaswift_array_median", callback: medianCallback)
        engine.registerFunction(name: "_luaswift_array_percentile", callback: percentileCallback)
        engine.registerFunction(name: "_luaswift_array_quantile", callback: quantileCallback)
        engine.registerFunction(name: "_luaswift_array_histogram", callback: histogramCallback)
        engine.registerFunction(name: "_luaswift_array_bincount", callback: bincountCallback)
        engine.registerFunction(name: "_luaswift_array_ptp", callback: ptpCallback)

        // Register LinAlg overlap functions
        engine.registerFunction(name: "_luaswift_array_trace", callback: traceCallback)
        engine.registerFunction(name: "_luaswift_array_diagonal", callback: diagonalCallback)
        engine.registerFunction(name: "_luaswift_array_diag", callback: diagCallback)
        engine.registerFunction(name: "_luaswift_array_outer", callback: outerCallback)

        // Register creation functions (Phase 3.1)
        engine.registerFunction(name: "_luaswift_array_eye", callback: eyeCallback)
        engine.registerFunction(name: "_luaswift_array_identity", callback: identityCallback)
        engine.registerFunction(name: "_luaswift_array_empty", callback: emptyCallback)
        engine.registerFunction(name: "_luaswift_array_zeros_like", callback: zerosLikeCallback)
        engine.registerFunction(name: "_luaswift_array_ones_like", callback: onesLikeCallback)
        engine.registerFunction(name: "_luaswift_array_full_like", callback: fullLikeCallback)

        // Register serialization
        engine.registerFunction(name: "_luaswift_array_tolist", callback: toListCallback)
        engine.registerFunction(name: "_luaswift_array_copy", callback: copyCallback)

        // Register dot product
        engine.registerFunction(name: "_luaswift_array_dot", callback: dotCallback)

        // Register array manipulation
        engine.registerFunction(name: "_luaswift_array_concatenate", callback: concatenateCallback)
        engine.registerFunction(name: "_luaswift_array_stack", callback: stackCallback)
        engine.registerFunction(name: "_luaswift_array_split", callback: splitCallback)

        // Register array manipulation (Phase 3.2)
        engine.registerFunction(name: "_luaswift_array_tile", callback: tileCallback)
        engine.registerFunction(name: "_luaswift_array_repeat", callback: repeatCallback)
        engine.registerFunction(name: "_luaswift_array_flip", callback: flipCallback)
        engine.registerFunction(name: "_luaswift_array_roll", callback: rollCallback)
        engine.registerFunction(name: "_luaswift_array_pad", callback: padCallback)
        engine.registerFunction(name: "_luaswift_array_insert", callback: insertCallback)
        engine.registerFunction(name: "_luaswift_array_delete", callback: deleteCallback)
        engine.registerFunction(name: "_luaswift_array_diff", callback: diffCallback)

        // Register signal processing (Phase 3.3)
        engine.registerFunction(name: "_luaswift_array_correlate", callback: correlateCallback)
        engine.registerFunction(name: "_luaswift_array_convolve", callback: convolveCallback)
        engine.registerFunction(name: "_luaswift_array_gradient", callback: gradientCallback)
        engine.registerFunction(name: "_luaswift_array_interp", callback: interpCallback)

        // Set up the luaswift.array namespace with Lua wrapper code
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Capture function references before they're cleaned up
                local _create = _luaswift_array_create
                local _zeros = _luaswift_array_zeros
                local _ones = _luaswift_array_ones
                local _arange = _luaswift_array_arange
                local _linspace = _luaswift_array_linspace
                local _rand = _luaswift_array_rand
                local _randn = _luaswift_array_randn
                local _full = _luaswift_array_full
                local _shape = _luaswift_array_shape
                local _ndim = _luaswift_array_ndim
                local _size = _luaswift_array_size
                local _get = _luaswift_array_get
                local _set = _luaswift_array_set
                local _reshape = _luaswift_array_reshape
                local _flatten = _luaswift_array_flatten
                local _squeeze = _luaswift_array_squeeze
                local _expand_dims = _luaswift_array_expand_dims
                local _transpose = _luaswift_array_transpose
                local _add = _luaswift_array_add
                local _sub = _luaswift_array_sub
                local _mul = _luaswift_array_mul
                local _div = _luaswift_array_div
                local _pow = _luaswift_array_pow
                local _neg = _luaswift_array_neg
                local _abs = _luaswift_array_abs
                local _sqrt = _luaswift_array_sqrt
                local _exp = _luaswift_array_exp
                local _log = _luaswift_array_log
                local _log2 = _luaswift_array_log2
                local _log10 = _luaswift_array_log10
                local _log1p = _luaswift_array_log1p
                local _expm1 = _luaswift_array_expm1
                local _power = _luaswift_array_power
                local _sin = _luaswift_array_sin
                local _cos = _luaswift_array_cos
                local _tan = _luaswift_array_tan
                local _sinh = _luaswift_array_sinh
                local _cosh = _luaswift_array_cosh
                local _tanh = _luaswift_array_tanh
                local _asinh = _luaswift_array_asinh
                local _acosh = _luaswift_array_acosh
                local _atanh = _luaswift_array_atanh
                local _arcsin = _luaswift_array_arcsin
                local _arccos = _luaswift_array_arccos
                local _arctan = _luaswift_array_arctan
                local _arctan2 = _luaswift_array_arctan2
                local _floor = _luaswift_array_floor
                local _ceil = _luaswift_array_ceil
                local _round = _luaswift_array_round
                local _clip = _luaswift_array_clip
                local _sign = _luaswift_array_sign
                local _mod = _luaswift_array_mod
                local _fmod = _luaswift_array_fmod
                local _sum = _luaswift_array_sum
                local _mean = _luaswift_array_mean
                local _std = _luaswift_array_std
                local _var = _luaswift_array_var
                local _min = _luaswift_array_min
                local _max = _luaswift_array_max
                local _argmin = _luaswift_array_argmin
                local _argmax = _luaswift_array_argmax
                local _prod = _luaswift_array_prod
                local _equal = _luaswift_array_equal
                local _greater = _luaswift_array_greater
                local _less = _luaswift_array_less
                local _greater_equal = _luaswift_array_greater_equal
                local _less_equal = _luaswift_array_less_equal
                local _not_equal = _luaswift_array_not_equal
                local _isnan = _luaswift_array_isnan
                local _isinf = _luaswift_array_isinf
                local _isfinite = _luaswift_array_isfinite
                local _where = _luaswift_array_where
                local _all = _luaswift_array_all
                local _any = _luaswift_array_any
                local _cumsum = _luaswift_array_cumsum
                local _cumprod = _luaswift_array_cumprod
                local _sort = _luaswift_array_sort
                local _argsort = _luaswift_array_argsort
                local _searchsorted = _luaswift_array_searchsorted
                local _argwhere = _luaswift_array_argwhere
                local _nonzero = _luaswift_array_nonzero
                local _unique = _luaswift_array_unique
                local _median = _luaswift_array_median
                local _percentile = _luaswift_array_percentile
                local _quantile = _luaswift_array_quantile
                local _histogram = _luaswift_array_histogram
                local _bincount = _luaswift_array_bincount
                local _ptp = _luaswift_array_ptp
                local _trace = _luaswift_array_trace
                local _diagonal = _luaswift_array_diagonal
                local _diag = _luaswift_array_diag
                local _outer = _luaswift_array_outer
                local _eye = _luaswift_array_eye
                local _identity = _luaswift_array_identity
                local _empty = _luaswift_array_empty
                local _zeros_like = _luaswift_array_zeros_like
                local _ones_like = _luaswift_array_ones_like
                local _full_like = _luaswift_array_full_like
                local _tolist = _luaswift_array_tolist
                local _copy = _luaswift_array_copy
                local _dot = _luaswift_array_dot
                local _concatenate = _luaswift_array_concatenate
                local _stack = _luaswift_array_stack
                local _split = _luaswift_array_split
                local _tile = _luaswift_array_tile
                local _repeat = _luaswift_array_repeat
                local _flip = _luaswift_array_flip
                local _roll = _luaswift_array_roll
                local _pad = _luaswift_array_pad
                local _insert = _luaswift_array_insert
                local _delete = _luaswift_array_delete
                local _diff = _luaswift_array_diff
                local _correlate = _luaswift_array_correlate
                local _convolve = _luaswift_array_convolve
                local _gradient = _luaswift_array_gradient
                local _interp = _luaswift_array_interp

                -- Define array metatable
                local array_mt = {
                    __index = function(self, key)
                        local methods = {
                            shape = function(_) return _shape(self._data) end,
                            ndim = function(_) return _ndim(self._data) end,
                            size = function(_) return _size(self._data) end,
                            get = function(_, ...) return _get(self._data, ...) end,
                            set = function(_, ...)
                                self._data = _set(self._data, ...)
                                return self
                            end,
                            reshape = function(_, new_shape)
                                return luaswift.array._wrap(_reshape(self._data, new_shape))
                            end,
                            flatten = function(_)
                                return luaswift.array._wrap(_flatten(self._data))
                            end,
                            squeeze = function(_)
                                return luaswift.array._wrap(_squeeze(self._data))
                            end,
                            expand_dims = function(_, axis)
                                return luaswift.array._wrap(_expand_dims(self._data, axis))
                            end,
                            T = function(_)
                                return luaswift.array._wrap(_transpose(self._data))
                            end,
                            transpose = function(_, axes)
                                return luaswift.array._wrap(_transpose(self._data, axes))
                            end,
                            tolist = function(_) return _tolist(self._data) end,
                            copy = function(_)
                                return luaswift.array._wrap(_copy(self._data))
                            end,
                            sum = function(_, axis)
                                local result = _sum(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            mean = function(_, axis)
                                local result = _mean(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            std = function(_, axis)
                                local result = _std(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            var = function(_, axis)
                                local result = _var(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            min = function(_, axis)
                                local result = _min(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            max = function(_, axis)
                                local result = _max(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            argmin = function(_, axis)
                                local result = _argmin(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            argmax = function(_, axis)
                                local result = _argmax(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            prod = function(_, axis)
                                local result = _prod(self._data, axis)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                            dot = function(_, other)
                                local other_data = type(other) == "table" and other._data or other
                                local result = _dot(self._data, other_data)
                                if type(result) == "number" then return result end
                                return luaswift.array._wrap(result)
                            end,
                        }
                        return methods[key]
                    end,
                    __add = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_add(a_data, b_data))
                    end,
                    __sub = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_sub(a_data, b_data))
                    end,
                    __mul = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_mul(a_data, b_data))
                    end,
                    __div = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_div(a_data, b_data))
                    end,
                    __pow = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_pow(a_data, b_data))
                    end,
                    __unm = function(a)
                        return luaswift.array._wrap(_neg(a._data))
                    end,
                    __tostring = function(self)
                        local shape = _shape(self._data)
                        local parts = {}
                        for i, v in ipairs(shape) do
                            parts[i] = string.format("%d", v)
                        end
                        local shapeStr = "(" .. table.concat(parts, ", ") .. ")"
                        return "array" .. shapeStr
                    end,
                    __eq = function(a, b)
                        if type(a) ~= "table" or type(b) ~= "table" then return false end
                        if not a._data or not b._data then return false end
                        local shape_a = _shape(a._data)
                        local shape_b = _shape(b._data)
                        if #shape_a ~= #shape_b then return false end
                        for i, v in ipairs(shape_a) do
                            if v ~= shape_b[i] then return false end
                        end
                        -- Compare data
                        local list_a = _tolist(a._data)
                        local list_b = _tolist(b._data)
                        local function deepCompare(t1, t2)
                            if type(t1) ~= type(t2) then return false end
                            if type(t1) ~= "table" then
                                return math.abs(t1 - t2) < 1e-10
                            end
                            for k, v in pairs(t1) do
                                if not deepCompare(v, t2[k]) then return false end
                            end
                            return true
                        end
                        return deepCompare(list_a, list_b)
                    end,
                }

                -- Random namespace
                local random_ns = {
                    rand = function(shape)
                        return luaswift.array._wrap(_rand(shape))
                    end,
                    randn = function(shape)
                        return luaswift.array._wrap(_randn(shape))
                    end,
                }

                luaswift.array = {
                    _wrap = function(data)
                        local wrapped = setmetatable({_data = data}, array_mt)
                        wrapped.__luaswift_type = "array"
                        return wrapped
                    end,
                    array = function(data)
                        return luaswift.array._wrap(_create(data))
                    end,
                    zeros = function(shape)
                        return luaswift.array._wrap(_zeros(shape))
                    end,
                    ones = function(shape)
                        return luaswift.array._wrap(_ones(shape))
                    end,
                    full = function(shape, value)
                        return luaswift.array._wrap(_full(shape, value))
                    end,
                    arange = function(start, stop, step)
                        return luaswift.array._wrap(_arange(start, stop, step or 1))
                    end,
                    linspace = function(start, stop, num)
                        return luaswift.array._wrap(_linspace(start, stop, num or 50))
                    end,
                    random = random_ns,

                    -- Element-wise functions
                    abs = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_abs(data))
                    end,
                    sqrt = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_sqrt(data))
                    end,
                    exp = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_exp(data))
                    end,
                    log = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_log(data))
                    end,
                    log2 = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_log2(data))
                    end,
                    log10 = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_log10(data))
                    end,
                    log1p = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_log1p(data))
                    end,
                    expm1 = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_expm1(data))
                    end,
                    power = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_power(a_data, b_data))
                    end,
                    sin = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_sin(data))
                    end,
                    cos = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_cos(data))
                    end,
                    tan = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_tan(data))
                    end,

                    -- Hyperbolic functions
                    sinh = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_sinh(data))
                    end,
                    cosh = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_cosh(data))
                    end,
                    tanh = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_tanh(data))
                    end,
                    asinh = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_asinh(data))
                    end,
                    acosh = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_acosh(data))
                    end,
                    atanh = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_atanh(data))
                    end,

                    -- Inverse trigonometric functions
                    arcsin = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_arcsin(data))
                    end,
                    arccos = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_arccos(data))
                    end,
                    arctan = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_arctan(data))
                    end,
                    arctan2 = function(y, x)
                        local y_data = type(y) == "table" and y._data or y
                        local x_data = type(x) == "table" and x._data or x
                        return luaswift.array._wrap(_arctan2(y_data, x_data))
                    end,
                    -- Aliases for convenience
                    asin = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_arcsin(data))
                    end,
                    acos = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_arccos(data))
                    end,
                    atan = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_arctan(data))
                    end,
                    atan2 = function(y, x)
                        local y_data = type(y) == "table" and y._data or y
                        local x_data = type(x) == "table" and x._data or x
                        return luaswift.array._wrap(_arctan2(y_data, x_data))
                    end,

                    -- Element-wise operations
                    floor = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_floor(data))
                    end,
                    ceil = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_ceil(data))
                    end,
                    round = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_round(data))
                    end,
                    clip = function(a, min_val, max_val)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_clip(data, min_val, max_val))
                    end,
                    sign = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_sign(data))
                    end,
                    mod = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_mod(a_data, b_data))
                    end,
                    fmod = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_fmod(a_data, b_data))
                    end,

                    -- Reductions
                    sum = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _sum(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    mean = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _mean(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    std = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _std(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    var = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _var(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    min = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _min(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    max = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _max(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    argmin = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _argmin(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    argmax = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _argmax(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    prod = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _prod(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,

                    -- Comparison
                    equal = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_equal(a_data, b_data))
                    end,
                    greater = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_greater(a_data, b_data))
                    end,
                    less = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_less(a_data, b_data))
                    end,
                    greater_equal = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_greater_equal(a_data, b_data))
                    end,
                    less_equal = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_less_equal(a_data, b_data))
                    end,
                    not_equal = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_not_equal(a_data, b_data))
                    end,
                    isnan = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_isnan(data))
                    end,
                    isinf = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_isinf(data))
                    end,
                    isfinite = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_isfinite(data))
                    end,
                    where = function(cond, x, y)
                        local cond_data = type(cond) == "table" and cond._data or cond
                        local x_data = type(x) == "table" and x._data or x
                        local y_data = type(y) == "table" and y._data or y
                        return luaswift.array._wrap(_where(cond_data, x_data, y_data))
                    end,

                    -- Boolean reductions
                    all = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _all(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    any = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _any(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    cumsum = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_cumsum(data, axis))
                    end,
                    cumprod = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_cumprod(data, axis))
                    end,

                    -- Sorting and searching
                    sort = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_sort(data, axis))
                    end,
                    argsort = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_argsort(data, axis))
                    end,
                    searchsorted = function(a, v, side)
                        local a_data = type(a) == "table" and a._data or a
                        local v_data = type(v) == "table" and v._data or v
                        local result = _searchsorted(a_data, v_data, side)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    argwhere = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_argwhere(data))
                    end,
                    nonzero = function(a)
                        local data = type(a) == "table" and a._data or a
                        local results = _nonzero(data)
                        local wrapped = {}
                        for i, r in ipairs(results) do
                            wrapped[i] = luaswift.array._wrap(r)
                        end
                        return wrapped
                    end,
                    unique = function(a, return_index, return_inverse, return_counts)
                        local data = type(a) == "table" and a._data or a
                        local results = _unique(data, return_index, return_inverse, return_counts)
                        if type(results) == "table" and results[1] then
                            local wrapped = {}
                            for i, r in ipairs(results) do
                                wrapped[i] = luaswift.array._wrap(r)
                            end
                            return table.unpack(wrapped)
                        end
                        return luaswift.array._wrap(results)
                    end,

                    -- Statistics
                    median = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _median(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    percentile = function(a, q, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _percentile(data, q, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    quantile = function(a, q, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _quantile(data, q, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    histogram = function(a, bins, range)
                        local data = type(a) == "table" and a._data or a
                        local results = _histogram(data, bins, range)
                        -- Results is a table with [1]=counts, [2]=edges
                        if type(results) == "table" and results[1] then
                            return luaswift.array._wrap(results[1]), luaswift.array._wrap(results[2])
                        end
                        return results
                    end,
                    bincount = function(a, weights, minlength)
                        local data = type(a) == "table" and a._data or a
                        local weights_data = weights and (type(weights) == "table" and weights._data or weights) or nil
                        return luaswift.array._wrap(_bincount(data, weights_data, minlength))
                    end,
                    ptp = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _ptp(data, axis)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                    trace = function(a, offset)
                        local data = type(a) == "table" and a._data or a
                        return _trace(data, offset)
                    end,
                    diagonal = function(a, offset)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_diagonal(data, offset))
                    end,
                    diag = function(a, k)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_diag(data, k))
                    end,
                    outer = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        return luaswift.array._wrap(_outer(a_data, b_data))
                    end,
                    matmul = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        local result = _dot(a_data, b_data)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,

                    -- Creation functions (Phase 3.1)
                    eye = function(n, m, k)
                        return luaswift.array._wrap(_eye(n, m, k))
                    end,
                    identity = function(n)
                        return luaswift.array._wrap(_identity(n))
                    end,
                    empty = function(shape)
                        return luaswift.array._wrap(_empty(shape))
                    end,
                    zeros_like = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_zeros_like(data))
                    end,
                    ones_like = function(a)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_ones_like(data))
                    end,
                    full_like = function(a, fill_value)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_full_like(data, fill_value))
                    end,

                    -- Linear algebra
                    dot = function(a, b)
                        local a_data = type(a) == "table" and a._data or a
                        local b_data = type(b) == "table" and b._data or b
                        local result = _dot(a_data, b_data)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,

                    -- Reshaping
                    reshape = function(a, new_shape)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_reshape(data, new_shape))
                    end,

                    -- Array manipulation
                    concatenate = function(arrays, axis)
                        local arr_data = {}
                        for i, a in ipairs(arrays) do
                            arr_data[i] = type(a) == "table" and a._data or a
                        end
                        return luaswift.array._wrap(_concatenate(arr_data, axis))
                    end,
                    stack = function(arrays, axis)
                        local arr_data = {}
                        for i, a in ipairs(arrays) do
                            arr_data[i] = type(a) == "table" and a._data or a
                        end
                        return luaswift.array._wrap(_stack(arr_data, axis))
                    end,
                    vstack = function(arrays)
                        local arr_data = {}
                        for i, a in ipairs(arrays) do
                            arr_data[i] = type(a) == "table" and a._data or a
                        end
                        return luaswift.array._wrap(_concatenate(arr_data, 1))
                    end,
                    hstack = function(arrays)
                        local arr_data = {}
                        for i, a in ipairs(arrays) do
                            -- For 1D arrays, concatenate along axis 1 (the only axis)
                            local data = type(a) == "table" and a._data or a
                            arr_data[i] = data
                        end
                        return luaswift.array._wrap(_concatenate(arr_data, 2))
                    end,
                    split = function(a, indices_or_sections, axis)
                        local data = type(a) == "table" and a._data or a
                        local results = _split(data, indices_or_sections, axis)
                        local wrapped = {}
                        for i, r in ipairs(results) do
                            wrapped[i] = luaswift.array._wrap(r)
                        end
                        return wrapped
                    end,
                    vsplit = function(a, indices_or_sections)
                        local data = type(a) == "table" and a._data or a
                        local results = _split(data, indices_or_sections, 1)
                        local wrapped = {}
                        for i, r in ipairs(results) do
                            wrapped[i] = luaswift.array._wrap(r)
                        end
                        return wrapped
                    end,
                    hsplit = function(a, indices_or_sections)
                        local data = type(a) == "table" and a._data or a
                        local results = _split(data, indices_or_sections, 2)
                        local wrapped = {}
                        for i, r in ipairs(results) do
                            wrapped[i] = luaswift.array._wrap(r)
                        end
                        return wrapped
                    end,

                    -- Array manipulation (Phase 3.2)
                    tile = function(a, reps)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_tile(data, reps))
                    end,
                    -- Note: 'repeat' is a Lua keyword, so we use 'rep' as alias
                    rep = function(a, repeats, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_repeat(data, repeats, axis))
                    end,
                    flip = function(a, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_flip(data, axis))
                    end,
                    roll = function(a, shift, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_roll(data, shift, axis))
                    end,
                    pad = function(a, pad_width, mode, constant_value)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_pad(data, pad_width, mode, constant_value))
                    end,
                    insert = function(a, indices, values, axis)
                        local data = type(a) == "table" and a._data or a
                        local vals = type(values) == "table" and values._data or values
                        return luaswift.array._wrap(_insert(data, indices, vals, axis))
                    end,
                    delete = function(a, indices, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_delete(data, indices, axis))
                    end,
                    diff = function(a, n, axis)
                        local data = type(a) == "table" and a._data or a
                        return luaswift.array._wrap(_diff(data, n, axis))
                    end,

                    -- Signal processing (Phase 3.3)
                    correlate = function(a, v, mode)
                        local a_data = type(a) == "table" and a._data or a
                        local v_data = type(v) == "table" and v._data or v
                        return luaswift.array._wrap(_correlate(a_data, v_data, mode))
                    end,
                    convolve = function(a, v, mode)
                        local a_data = type(a) == "table" and a._data or a
                        local v_data = type(v) == "table" and v._data or v
                        return luaswift.array._wrap(_convolve(a_data, v_data, mode))
                    end,
                    gradient = function(a, spacing, axis)
                        local data = type(a) == "table" and a._data or a
                        local result = _gradient(data, spacing, axis)
                        -- Check for multi-axis result (table with string keys from Swift)
                        if type(result) == "table" and result["1"] then
                            local wrapped = {}
                            local i = 1
                            while result[tostring(i)] do
                                wrapped[i] = luaswift.array._wrap(result[tostring(i)])
                                i = i + 1
                            end
                            return table.unpack(wrapped)
                        end
                        return luaswift.array._wrap(result)
                    end,
                    interp = function(x, xp, fp, left, right)
                        local x_data = type(x) == "table" and x._data or x
                        local xp_data = type(xp) == "table" and xp._data or xp
                        local fp_data = type(fp) == "table" and fp._data or fp
                        local result = _interp(x_data, xp_data, fp_data, left, right)
                        if type(result) == "number" then return result end
                        return luaswift.array._wrap(result)
                    end,
                }

                -- Clean up temporary globals
                _luaswift_array_create = nil
                _luaswift_array_zeros = nil
                _luaswift_array_ones = nil
                _luaswift_array_arange = nil
                _luaswift_array_linspace = nil
                _luaswift_array_rand = nil
                _luaswift_array_randn = nil
                _luaswift_array_full = nil
                _luaswift_array_shape = nil
                _luaswift_array_ndim = nil
                _luaswift_array_size = nil
                _luaswift_array_get = nil
                _luaswift_array_set = nil
                _luaswift_array_reshape = nil
                _luaswift_array_flatten = nil
                _luaswift_array_squeeze = nil
                _luaswift_array_expand_dims = nil
                _luaswift_array_transpose = nil
                _luaswift_array_add = nil
                _luaswift_array_sub = nil
                _luaswift_array_mul = nil
                _luaswift_array_div = nil
                _luaswift_array_pow = nil
                _luaswift_array_neg = nil
                _luaswift_array_abs = nil
                _luaswift_array_sqrt = nil
                _luaswift_array_exp = nil
                _luaswift_array_log = nil
                _luaswift_array_sin = nil
                _luaswift_array_cos = nil
                _luaswift_array_tan = nil
                _luaswift_array_sinh = nil
                _luaswift_array_cosh = nil
                _luaswift_array_tanh = nil
                _luaswift_array_asinh = nil
                _luaswift_array_acosh = nil
                _luaswift_array_atanh = nil
                _luaswift_array_arcsin = nil
                _luaswift_array_arccos = nil
                _luaswift_array_arctan = nil
                _luaswift_array_arctan2 = nil
                _luaswift_array_floor = nil
                _luaswift_array_ceil = nil
                _luaswift_array_round = nil
                _luaswift_array_clip = nil
                _luaswift_array_sign = nil
                _luaswift_array_mod = nil
                _luaswift_array_fmod = nil
                _luaswift_array_sum = nil
                _luaswift_array_mean = nil
                _luaswift_array_std = nil
                _luaswift_array_var = nil
                _luaswift_array_min = nil
                _luaswift_array_max = nil
                _luaswift_array_argmin = nil
                _luaswift_array_argmax = nil
                _luaswift_array_prod = nil
                _luaswift_array_equal = nil
                _luaswift_array_greater = nil
                _luaswift_array_less = nil
                _luaswift_array_where = nil
                _luaswift_array_tolist = nil
                _luaswift_array_copy = nil
                _luaswift_array_dot = nil
                _luaswift_array_concatenate = nil
                _luaswift_array_stack = nil
                _luaswift_array_split = nil
                _luaswift_array_tile = nil
                _luaswift_array_repeat = nil
                _luaswift_array_flip = nil
                _luaswift_array_roll = nil
                _luaswift_array_pad = nil
                _luaswift_array_insert = nil
                _luaswift_array_delete = nil
                _luaswift_array_diff = nil
                _luaswift_array_correlate = nil
                _luaswift_array_convolve = nil
                _luaswift_array_gradient = nil
                _luaswift_array_interp = nil
                """)
        } catch {
            print("ArrayModule: Failed to initialize Lua wrapper: \(error)")
        }
    }

    // MARK: - Memory Tracking

    /// Track memory allocation for array data.
    ///
    /// Call this before creating large arrays to respect memory limits.
    /// - Parameter count: Number of Double elements to allocate
    /// - Throws: `LuaError.memoryError` if the allocation would exceed limits
    private static func trackArrayAllocation(count: Int) throws {
        let bytes = count * MemoryLayout<Double>.size
        if let engine = LuaEngine.currentEngine {
            try engine.trackAllocation(bytes: bytes)
        }
    }

    /// Track memory deallocation for array data.
    ///
    /// Call this when array data is being released.
    /// - Parameter count: Number of Double elements being freed
    private static func trackArrayDeallocation(count: Int) {
        let bytes = count * MemoryLayout<Double>.size
        if let engine = LuaEngine.currentEngine {
            engine.trackDeallocation(bytes: bytes)
        }
    }

    // MARK: - Array Data Types

    /// Data type enumeration for array elements
    /// Supports real (float64) and complex (complex128) numbers
    public enum ArrayDType: String, CaseIterable {
        /// Real numbers - 64-bit floating point (default)
        case float64 = "float64"
        /// Complex numbers - two 64-bit floats (real + imaginary)
        case complex128 = "complex128"

        /// Bytes per element for this dtype
        var bytesPerElement: Int {
            switch self {
            case .float64: return 8
            case .complex128: return 16
            }
        }

        /// Whether this dtype represents complex numbers
        var isComplex: Bool { self == .complex128 }

        /// Create dtype from string, defaulting to float64 for unknown values
        init(from string: String?) {
            switch string?.lowercased() {
            case "complex128", "complex": self = .complex128
            default: self = .float64
            }
        }
    }

    // MARK: - Array Data Structure

    /// Internal array representation with split storage for complex support
    /// Uses separate real/imag arrays for optimal vDSP vectorization
    private struct ArrayData {
        var shape: [Int]
        var dtype: ArrayDType
        var real: [Double]           // Real part (always present)
        var imag: [Double]?          // Imaginary part (only for complex128)

        var ndim: Int { shape.count }
        var size: Int { real.count }
        var isComplex: Bool { dtype.isComplex }

        /// Backward compatibility: access real data as 'data'
        var data: [Double] {
            get { real }
            set { real = newValue }
        }

        /// Calculate strides for row-major (C-style) ordering
        var strides: [Int] {
            var result = [Int](repeating: 1, count: shape.count)
            for i in stride(from: shape.count - 2, through: 0, by: -1) {
                result[i] = result[i + 1] * shape[i + 1]
            }
            return result
        }

        /// Convert multi-dimensional index to flat index
        func flatIndex(_ indices: [Int]) -> Int {
            let strides = self.strides
            var index = 0
            for i in 0..<indices.count {
                index += indices[i] * strides[i]
            }
            return index
        }

        // MARK: - Initializers

        /// Create a real (float64) array - backward compatible initializer
        init(shape: [Int], data: [Double]) {
            self.shape = shape
            self.dtype = .float64
            self.real = data
            self.imag = nil
        }

        /// Create array with explicit dtype
        init(shape: [Int], dtype: ArrayDType, real: [Double], imag: [Double]?) {
            self.shape = shape
            self.dtype = dtype
            self.real = real
            self.imag = imag
        }
    }

    // MARK: - Helper Functions

    /// Extract array data from a LuaValue
    private static func extractArrayData(_ value: LuaValue) throws -> ArrayData {
        guard let table = value.tableValue,
              let shapeValue = table["shape"],
              let dataValue = table["data"] else {
            throw LuaError.callbackError("array: expected array table with shape and data")
        }

        // Extract shape
        var shape: [Int] = []
        if let shapeArray = shapeValue.arrayValue {
            shape = shapeArray.compactMap { $0.intValue }
        } else if let shapeTable = shapeValue.tableValue {
            var i = 1
            while let dim = shapeTable[String(i)]?.intValue {
                shape.append(dim)
                i += 1
            }
        }

        // Extract data
        var data: [Double] = []
        if let dataArray = dataValue.arrayValue {
            data = dataArray.compactMap { $0.numberValue }
        } else if let dataTable = dataValue.tableValue {
            var i = 1
            while let val = dataTable[String(i)]?.numberValue {
                data.append(val)
                i += 1
            }
        }

        guard !shape.isEmpty else {
            throw LuaError.callbackError("array: shape must be non-empty")
        }

        let expectedSize = shape.reduce(1, *)
        guard data.count == expectedSize else {
            throw LuaError.callbackError("array: data size \(data.count) doesn't match shape \(shape) (expected \(expectedSize))")
        }

        return ArrayData(shape: shape, data: data)
    }

    /// Create a LuaValue table from ArrayData
    private static func createArrayTable(_ arrayData: ArrayData) -> LuaValue {
        return .table([
            "shape": .array(arrayData.shape.map { .number(Double($0)) }),
            "data": .array(arrayData.data.map { .number($0) })
        ])
    }

    /// Flatten nested Lua table to 1D array with inferred shape
    private static func flattenLuaTable(_ value: LuaValue) throws -> (data: [Double], shape: [Int]) {
        var data: [Double] = []
        var shape: [Int] = []

        func flatten(_ val: LuaValue, depth: Int) throws {
            if let num = val.numberValue {
                data.append(num)
                return
            }

            if let arr = val.arrayValue {
                if depth >= shape.count {
                    shape.append(arr.count)
                } else if shape[depth] != arr.count {
                    throw LuaError.callbackError("array: inconsistent dimensions at depth \(depth)")
                }
                for item in arr {
                    try flatten(item, depth: depth + 1)
                }
                return
            }

            if let tbl = val.tableValue {
                // Check if it's array-like (1-indexed sequential keys)
                var items: [(Int, LuaValue)] = []
                for (key, value) in tbl {
                    if let idx = Int(key), idx >= 1 {
                        items.append((idx, value))
                    }
                }
                items.sort { $0.0 < $1.0 }

                if items.isEmpty {
                    throw LuaError.callbackError("array: empty or non-array table")
                }

                if depth >= shape.count {
                    shape.append(items.count)
                } else if shape[depth] != items.count {
                    throw LuaError.callbackError("array: inconsistent dimensions at depth \(depth)")
                }

                for (_, item) in items {
                    try flatten(item, depth: depth + 1)
                }
                return
            }

            throw LuaError.callbackError("array: invalid element type")
        }

        try flatten(value, depth: 0)
        return (data, shape)
    }

    /// Broadcast two shapes and return the result shape
    private static func broadcastShapes(_ shape1: [Int], _ shape2: [Int]) throws -> [Int] {
        let maxDim = max(shape1.count, shape2.count)
        var result = [Int](repeating: 1, count: maxDim)

        let pad1 = maxDim - shape1.count
        let pad2 = maxDim - shape2.count

        for i in 0..<maxDim {
            let dim1 = i >= pad1 ? shape1[i - pad1] : 1
            let dim2 = i >= pad2 ? shape2[i - pad2] : 1

            if dim1 == dim2 {
                result[i] = dim1
            } else if dim1 == 1 {
                result[i] = dim2
            } else if dim2 == 1 {
                result[i] = dim1
            } else {
                throw LuaError.callbackError("array: cannot broadcast shapes \(shape1) and \(shape2)")
            }
        }

        return result
    }

    /// Broadcast an array to a new shape
    private static func broadcastTo(_ arrayData: ArrayData, shape: [Int]) -> ArrayData {
        let newSize = shape.reduce(1, *)
        var newData = [Double](repeating: 0, count: newSize)

        let strides = arrayData.strides

        // For each element in the output
        for i in 0..<newSize {
            // Calculate multi-dimensional index in output
            var remaining = i
            var outputIndices = [Int](repeating: 0, count: shape.count)
            for d in stride(from: shape.count - 1, through: 0, by: -1) {
                outputIndices[d] = remaining % shape[d]
                remaining /= shape[d]
            }

            // Map to input index
            var inputIndex = 0
            for d in 0..<shape.count {
                let srcDim = d - (shape.count - arrayData.shape.count)
                if srcDim >= 0 {
                    let srcIdx = arrayData.shape[srcDim] == 1 ? 0 : outputIndices[d]
                    inputIndex += srcIdx * strides[srcDim]
                }
            }

            newData[i] = arrayData.data[inputIndex]
        }

        return ArrayData(shape: shape, data: newData)
    }

    // MARK: - Creation Callbacks

    private static func createCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.array: missing argument")
        }

        let (data, shape) = try flattenLuaTable(arg)
        return createArrayTable(ArrayData(shape: shape, data: data))
    }

    private static func zerosCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.zeros: missing shape argument")
        }

        var shape: [Int] = []
        if let arr = arg.arrayValue {
            shape = arr.compactMap { $0.intValue }
        } else if let tbl = arg.tableValue {
            var i = 1
            while let dim = tbl[String(i)]?.intValue {
                shape.append(dim)
                i += 1
            }
        } else if let n = arg.intValue {
            shape = [n]
        }

        guard !shape.isEmpty else {
            throw LuaError.callbackError("array.zeros: invalid shape")
        }

        let size = shape.reduce(1, *)
        try trackArrayAllocation(count: size)
        return createArrayTable(ArrayData(shape: shape, data: [Double](repeating: 0, count: size)))
    }

    private static func onesCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.ones: missing shape argument")
        }

        var shape: [Int] = []
        if let arr = arg.arrayValue {
            shape = arr.compactMap { $0.intValue }
        } else if let tbl = arg.tableValue {
            var i = 1
            while let dim = tbl[String(i)]?.intValue {
                shape.append(dim)
                i += 1
            }
        } else if let n = arg.intValue {
            shape = [n]
        }

        guard !shape.isEmpty else {
            throw LuaError.callbackError("array.ones: invalid shape")
        }

        let size = shape.reduce(1, *)
        try trackArrayAllocation(count: size)
        return createArrayTable(ArrayData(shape: shape, data: [Double](repeating: 1, count: size)))
    }

    private static func fullCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.full: missing shape or value argument")
        }

        var shape: [Int] = []
        if let arr = args[0].arrayValue {
            shape = arr.compactMap { $0.intValue }
        } else if let tbl = args[0].tableValue {
            var i = 1
            while let dim = tbl[String(i)]?.intValue {
                shape.append(dim)
                i += 1
            }
        } else if let n = args[0].intValue {
            shape = [n]
        }

        guard !shape.isEmpty else {
            throw LuaError.callbackError("array.full: invalid shape")
        }

        guard let value = args[1].numberValue else {
            throw LuaError.callbackError("array.full: value must be a number")
        }

        let size = shape.reduce(1, *)
        try trackArrayAllocation(count: size)
        return createArrayTable(ArrayData(shape: shape, data: [Double](repeating: value, count: size)))
    }

    private static func arangeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let start = args[0].numberValue,
              let stop = args[1].numberValue else {
            throw LuaError.callbackError("array.arange: requires start and stop")
        }

        let step = args.count >= 3 ? (args[2].numberValue ?? 1.0) : 1.0

        guard step != 0 else {
            throw LuaError.callbackError("array.arange: step cannot be zero")
        }

        // Estimate size for memory tracking
        let estimatedSize = max(0, Int(ceil(abs(stop - start) / abs(step))))
        try trackArrayAllocation(count: estimatedSize)

        var data: [Double] = []
        data.reserveCapacity(estimatedSize)
        if step > 0 {
            var val = start
            while val < stop {
                data.append(val)
                val += step
            }
        } else {
            var val = start
            while val > stop {
                data.append(val)
                val += step
            }
        }

        return createArrayTable(ArrayData(shape: [data.count], data: data))
    }

    private static func linspaceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let start = args[0].numberValue,
              let stop = args[1].numberValue else {
            throw LuaError.callbackError("array.linspace: requires start and stop")
        }

        let num = args.count >= 3 ? (args[2].intValue ?? 50) : 50

        guard num >= 2 else {
            throw LuaError.callbackError("array.linspace: num must be >= 2")
        }

        try trackArrayAllocation(count: num)
        var data = [Double](repeating: 0, count: num)
        let step = (stop - start) / Double(num - 1)
        for i in 0..<num {
            data[i] = start + Double(i) * step
        }

        return createArrayTable(ArrayData(shape: [num], data: data))
    }

    private static func randCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.random.rand: missing shape argument")
        }

        var shape: [Int] = []
        if let arr = arg.arrayValue {
            shape = arr.compactMap { $0.intValue }
        } else if let tbl = arg.tableValue {
            var i = 1
            while let dim = tbl[String(i)]?.intValue {
                shape.append(dim)
                i += 1
            }
        } else if let n = arg.intValue {
            shape = [n]
        }

        guard !shape.isEmpty else {
            throw LuaError.callbackError("array.random.rand: invalid shape")
        }

        let size = shape.reduce(1, *)
        try trackArrayAllocation(count: size)
        var data = [Double](repeating: 0, count: size)
        for i in 0..<size {
            data[i] = Double.random(in: 0..<1)
        }

        return createArrayTable(ArrayData(shape: shape, data: data))
    }

    private static func randnCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.random.randn: missing shape argument")
        }

        var shape: [Int] = []
        if let arr = arg.arrayValue {
            shape = arr.compactMap { $0.intValue }
        } else if let tbl = arg.tableValue {
            var i = 1
            while let dim = tbl[String(i)]?.intValue {
                shape.append(dim)
                i += 1
            }
        } else if let n = arg.intValue {
            shape = [n]
        }

        guard !shape.isEmpty else {
            throw LuaError.callbackError("array.random.randn: invalid shape")
        }

        let size = shape.reduce(1, *)
        try trackArrayAllocation(count: size)
        var data = [Double](repeating: 0, count: size)

        // Box-Muller transform for normal distribution
        for i in stride(from: 0, to: size - 1, by: 2) {
            let u1 = Double.random(in: Double.leastNonzeroMagnitude..<1)
            let u2 = Double.random(in: 0..<1)
            let r = sqrt(-2 * log(u1))
            let theta = 2 * .pi * u2
            data[i] = r * cos(theta)
            if i + 1 < size {
                data[i + 1] = r * sin(theta)
            }
        }
        if size % 2 == 1 {
            let u1 = Double.random(in: Double.leastNonzeroMagnitude..<1)
            let u2 = Double.random(in: 0..<1)
            data[size - 1] = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
        }

        return createArrayTable(ArrayData(shape: shape, data: data))
    }

    // MARK: - Property Accessors

    private static func shapeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.shape: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        return .array(arrayData.shape.map { .number(Double($0)) })
    }

    private static func ndimCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.ndim: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        return .number(Double(arrayData.ndim))
    }

    private static func sizeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.size: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        return .number(Double(arrayData.size))
    }

    private static func getCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.get: missing indices")
        }

        let arrayData = try extractArrayData(args[0])

        // Extract indices
        var indices: [Int] = []
        for i in 1..<args.count {
            guard let idx = args[i].intValue else {
                throw LuaError.callbackError("array.get: indices must be integers")
            }
            indices.append(idx - 1)  // Convert to 0-based
        }

        guard indices.count == arrayData.ndim else {
            throw LuaError.callbackError("array.get: expected \(arrayData.ndim) indices, got \(indices.count)")
        }

        // Validate indices
        for (i, idx) in indices.enumerated() {
            guard idx >= 0 && idx < arrayData.shape[i] else {
                throw LuaError.callbackError("array.get: index out of bounds")
            }
        }

        let flatIdx = arrayData.flatIndex(indices)
        return .number(arrayData.data[flatIdx])
    }

    private static func setCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("array.set: missing indices or value")
        }

        var arrayData = try extractArrayData(args[0])

        // Last argument is the value
        guard let value = args[args.count - 1].numberValue else {
            throw LuaError.callbackError("array.set: value must be a number")
        }

        // Extract indices (all but first and last arguments)
        var indices: [Int] = []
        for i in 1..<(args.count - 1) {
            guard let idx = args[i].intValue else {
                throw LuaError.callbackError("array.set: indices must be integers")
            }
            indices.append(idx - 1)  // Convert to 0-based
        }

        guard indices.count == arrayData.ndim else {
            throw LuaError.callbackError("array.set: expected \(arrayData.ndim) indices, got \(indices.count)")
        }

        // Validate indices
        for (i, idx) in indices.enumerated() {
            guard idx >= 0 && idx < arrayData.shape[i] else {
                throw LuaError.callbackError("array.set: index out of bounds")
            }
        }

        let flatIdx = arrayData.flatIndex(indices)
        arrayData.data[flatIdx] = value

        return createArrayTable(arrayData)
    }

    // MARK: - Reshaping Operations

    private static func reshapeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.reshape: missing shape argument")
        }

        let arrayData = try extractArrayData(args[0])

        var newShape: [Int] = []
        if let arr = args[1].arrayValue {
            newShape = arr.compactMap { $0.intValue }
        } else if let tbl = args[1].tableValue {
            var i = 1
            while let dim = tbl[String(i)]?.intValue {
                newShape.append(dim)
                i += 1
            }
        }

        guard !newShape.isEmpty else {
            throw LuaError.callbackError("array.reshape: invalid shape")
        }

        let newSize = newShape.reduce(1, *)
        guard newSize == arrayData.size else {
            throw LuaError.callbackError("array.reshape: cannot reshape array of size \(arrayData.size) to shape \(newShape)")
        }

        return createArrayTable(ArrayData(shape: newShape, data: arrayData.data))
    }

    private static func flattenCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.flatten: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        return createArrayTable(ArrayData(shape: [arrayData.size], data: arrayData.data))
    }

    private static func squeezeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.squeeze: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        let newShape = arrayData.shape.filter { $0 != 1 }

        if newShape.isEmpty {
            return createArrayTable(ArrayData(shape: [1], data: arrayData.data))
        }

        return createArrayTable(ArrayData(shape: newShape, data: arrayData.data))
    }

    private static func expandDimsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let axis = args[1].intValue else {
            throw LuaError.callbackError("array.expand_dims: missing axis argument")
        }

        let arrayData = try extractArrayData(args[0])

        let adjustedAxis = axis >= 0 ? axis : arrayData.ndim + 1 + axis
        guard adjustedAxis >= 0 && adjustedAxis <= arrayData.ndim else {
            throw LuaError.callbackError("array.expand_dims: axis out of bounds")
        }

        var newShape = arrayData.shape
        newShape.insert(1, at: adjustedAxis)

        return createArrayTable(ArrayData(shape: newShape, data: arrayData.data))
    }

    private static func transposeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.transpose: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // Default: reverse all axes
        var axes: [Int] = Array((0..<arrayData.ndim).reversed())

        // Optional custom axes
        if args.count >= 2 {
            if let axesArr = args[1].arrayValue {
                axes = axesArr.compactMap { $0.intValue }
                axes = axes.map { $0 - 1 }  // Convert to 0-based
            } else if let axesTbl = args[1].tableValue {
                var i = 1
                axes = []
                while let ax = axesTbl[String(i)]?.intValue {
                    axes.append(ax - 1)  // Convert to 0-based
                    i += 1
                }
            }
        }

        guard axes.count == arrayData.ndim else {
            throw LuaError.callbackError("array.transpose: axes must have same length as ndim")
        }

        let newShape = axes.map { arrayData.shape[$0] }
        var newData = [Double](repeating: 0, count: arrayData.size)

        var newStrides = [Int](repeating: 1, count: arrayData.ndim)
        for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
            newStrides[i] = newStrides[i + 1] * newShape[i + 1]
        }

        for i in 0..<arrayData.size {
            // Convert flat index to old multi-dim index
            var remaining = i
            var oldIndices = [Int](repeating: 0, count: arrayData.ndim)
            for d in stride(from: arrayData.ndim - 1, through: 0, by: -1) {
                oldIndices[d] = remaining % arrayData.shape[d]
                remaining /= arrayData.shape[d]
            }

            // Permute indices
            let newIndices = axes.map { oldIndices[$0] }

            // Convert new indices to flat index
            var newFlatIdx = 0
            for d in 0..<arrayData.ndim {
                newFlatIdx += newIndices[d] * newStrides[d]
            }

            newData[newFlatIdx] = arrayData.data[i]
        }

        return createArrayTable(ArrayData(shape: newShape, data: newData))
    }

    // MARK: - Arithmetic Operations

    private static func addCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try binaryOp(args, op: { $0 + $1 }, name: "add")
    }

    private static func subCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try binaryOp(args, op: { $0 - $1 }, name: "sub")
    }

    private static func mulCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try binaryOp(args, op: { $0 * $1 }, name: "mul")
    }

    private static func divCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try binaryOp(args, op: { $0 / $1 }, name: "div")
    }

    private static func powCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try binaryOp(args, op: { pow($0, $1) }, name: "pow")
    }

    private static func negCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.neg: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = [Double](repeating: 0, count: arrayData.size)
        vDSP_vnegD(arrayData.data, 1, &result, 1, vDSP_Length(arrayData.size))

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    /// Binary operation with Accelerate optimization for add, sub, mul, div
    private static func binaryOp(_ args: [LuaValue], op: (Double, Double) -> Double, name: String) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.\(name): requires two arguments")
        }

        // Handle scalar operands
        let isScalar1 = args[0].numberValue != nil
        let isScalar2 = args[1].numberValue != nil

        if isScalar1 && isScalar2 {
            let val = op(args[0].numberValue!, args[1].numberValue!)
            return createArrayTable(ArrayData(shape: [1], data: [val]))
        }

        if isScalar1 {
            var scalar = args[0].numberValue!
            let arrayData = try extractArrayData(args[1])
            var result = [Double](repeating: 0, count: arrayData.size)
            let n = vDSP_Length(arrayData.size)

            // Use Accelerate for scalar + array operations
            switch name {
            case "add":
                vDSP_vsaddD(arrayData.data, 1, &scalar, &result, 1, n)
            case "sub":
                // scalar - array = -(array - scalar) = -array + scalar
                vDSP_vnegD(arrayData.data, 1, &result, 1, n)
                vDSP_vsaddD(result, 1, &scalar, &result, 1, n)
            case "mul":
                vDSP_vsmulD(arrayData.data, 1, &scalar, &result, 1, n)
            case "div":
                // scalar / array: use vDSP_svdivD
                vDSP_svdivD(&scalar, arrayData.data, 1, &result, 1, n)
            default:
                for i in 0..<arrayData.size {
                    result[i] = op(scalar, arrayData.data[i])
                }
            }
            return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
        }

        if isScalar2 {
            let arrayData = try extractArrayData(args[0])
            var scalar = args[1].numberValue!
            var result = [Double](repeating: 0, count: arrayData.size)
            let n = vDSP_Length(arrayData.size)

            // Use Accelerate for array + scalar operations
            switch name {
            case "add":
                vDSP_vsaddD(arrayData.data, 1, &scalar, &result, 1, n)
            case "sub":
                var negScalar = -scalar
                vDSP_vsaddD(arrayData.data, 1, &negScalar, &result, 1, n)
            case "mul":
                vDSP_vsmulD(arrayData.data, 1, &scalar, &result, 1, n)
            case "div":
                vDSP_vsdivD(arrayData.data, 1, &scalar, &result, 1, n)
            default:
                for i in 0..<arrayData.size {
                    result[i] = op(arrayData.data[i], scalar)
                }
            }
            return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
        }

        // Both are arrays - broadcast
        let arr1 = try extractArrayData(args[0])
        let arr2 = try extractArrayData(args[1])

        let resultShape = try broadcastShapes(arr1.shape, arr2.shape)
        let broadcast1 = broadcastTo(arr1, shape: resultShape)
        let broadcast2 = broadcastTo(arr2, shape: resultShape)

        let size = resultShape.reduce(1, *)
        var result = [Double](repeating: 0, count: size)
        let n = vDSP_Length(size)

        // Use Accelerate for array + array operations
        switch name {
        case "add":
            vDSP_vaddD(broadcast1.data, 1, broadcast2.data, 1, &result, 1, n)
        case "sub":
            // vDSP_vsubD computes B - A, so we swap order
            vDSP_vsubD(broadcast2.data, 1, broadcast1.data, 1, &result, 1, n)
        case "mul":
            vDSP_vmulD(broadcast1.data, 1, broadcast2.data, 1, &result, 1, n)
        case "div":
            // vDSP_vdivD computes B / A, so we swap order
            vDSP_vdivD(broadcast2.data, 1, broadcast1.data, 1, &result, 1, n)
        default:
            for i in 0..<size {
                result[i] = op(broadcast1.data[i], broadcast2.data[i])
            }
        }

        return createArrayTable(ArrayData(shape: resultShape, data: result))
    }

    // MARK: - Math Functions

    private static func absCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.abs: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = [Double](repeating: 0, count: arrayData.size)
        vDSP_vabsD(arrayData.data, 1, &result, 1, vDSP_Length(arrayData.size))

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func sqrtCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.sqrt: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvsqrt(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func expCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.exp: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvexp(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func logCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.log: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvlog(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func log2Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.log2: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvlog2(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func log10Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.log10: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvlog10(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func log1pCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.log1p: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvlog1p(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func expm1Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.expm1: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvexpm1(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func powerCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try binaryOp(args, op: pow, name: "power")
    }

    private static func sinCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.sin: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvsin(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func cosCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.cos: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvcos(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func tanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.tan: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvtan(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    // MARK: - Hyperbolic Functions

    private static func sinhCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.sinh: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvsinh(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func coshCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.cosh: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvcosh(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func tanhCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.tanh: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvtanh(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func asinhCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.asinh: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvasinh(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func acoshCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.acosh: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvacosh(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func atanhCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.atanh: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvatanh(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    // MARK: - Inverse Trigonometric Functions

    private static func arcsinCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.arcsin: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvasin(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func arccosCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.arccos: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvacos(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func arctanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.arctan: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvatan(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func arctan2Callback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.arctan2: requires two arguments (y, x)")
        }

        // Handle scalar operands
        let isScalar1 = args[0].numberValue != nil
        let isScalar2 = args[1].numberValue != nil

        if isScalar1 && isScalar2 {
            let y = args[0].numberValue!
            let x = args[1].numberValue!
            return createArrayTable(ArrayData(shape: [1], data: [atan2(y, x)]))
        }

        if isScalar1 {
            let scalar = args[0].numberValue!
            let arrayData = try extractArrayData(args[1])
            var yData = [Double](repeating: scalar, count: arrayData.size)
            var result = [Double](repeating: 0, count: arrayData.size)
            var count = Int32(arrayData.size)
            vvatan2(&result, &yData, arrayData.data, &count)
            return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
        }

        if isScalar2 {
            let arrayData = try extractArrayData(args[0])
            let scalar = args[1].numberValue!
            var xData = [Double](repeating: scalar, count: arrayData.size)
            var result = [Double](repeating: 0, count: arrayData.size)
            var count = Int32(arrayData.size)
            vvatan2(&result, arrayData.data, &xData, &count)
            return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
        }

        // Both are arrays - broadcast
        let arr1 = try extractArrayData(args[0])  // y
        let arr2 = try extractArrayData(args[1])  // x

        let resultShape = try broadcastShapes(arr1.shape, arr2.shape)
        let broadcast1 = broadcastTo(arr1, shape: resultShape)
        let broadcast2 = broadcastTo(arr2, shape: resultShape)

        var result = [Double](repeating: 0, count: resultShape.reduce(1, *))
        var count = Int32(result.count)
        vvatan2(&result, broadcast1.data, broadcast2.data, &count)

        return createArrayTable(ArrayData(shape: resultShape, data: result))
    }

    // MARK: - Element-wise Operations

    private static func floorCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.floor: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvfloor(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func ceilCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.ceil: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvceil(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func roundCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.round: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        var result = arrayData.data
        var count = Int32(arrayData.size)
        vvnint(&result, arrayData.data, &count)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func clipCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("array.clip: requires array, min, max")
        }

        let arrayData = try extractArrayData(args[0])
        guard let minVal = args[1].numberValue,
              let maxVal = args[2].numberValue else {
            throw LuaError.callbackError("array.clip: min and max must be numbers")
        }

        var result = arrayData.data
        var low = minVal
        var high = maxVal
        vDSP_vclipD(arrayData.data, 1, &low, &high, &result, 1, vDSP_Length(arrayData.size))

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func signCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.sign: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        let n = vDSP_Length(arrayData.size)

        // Vectorized sign using Accelerate:
        // sign(x) = x / (abs(x) + epsilon), then round to handle epsilon artifacts
        // For zeros: 0 / epsilon = 0 ✓

        // Step 1: Compute abs(x)
        var absX = [Double](repeating: 0, count: arrayData.size)
        vDSP_vabsD(arrayData.data, 1, &absX, 1, n)

        // Step 2: Add tiny epsilon to avoid division by zero
        // Using Double.leastNonzeroMagnitude ensures 0/eps ≈ 0
        var epsilon = Double.leastNonzeroMagnitude
        vDSP_vsaddD(absX, 1, &epsilon, &absX, 1, n)

        // Step 3: Divide x by (abs(x) + epsilon)
        // vDSP_vdivD computes B/A, so: result = data / absX
        var result = [Double](repeating: 0, count: arrayData.size)
        vDSP_vdivD(absX, 1, arrayData.data, 1, &result, 1, n)

        // Step 4: Round to nearest integer to get exactly -1, 0, or 1
        // This handles any floating point artifacts from the division
        var intResult = [Double](repeating: 0, count: arrayData.size)
        vvnint(&intResult, result, [Int32(arrayData.size)])

        return createArrayTable(ArrayData(shape: arrayData.shape, data: intResult))
    }

    private static func modCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.mod: requires two arguments")
        }

        // Python-style mod: a - floor(a/b) * b
        return try binaryOp(args, op: { a, b in
            if b == 0 { return .nan }
            return a - Foundation.floor(a / b) * b
        }, name: "mod")
    }

    private static func fmodCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.fmod: requires two arguments")
        }

        // C-style fmod: same sign as dividend
        return try binaryOp(args, op: { a, b in
            if b == 0 { return .nan }
            return Foundation.fmod(a, b)
        }, name: "fmod")
    }

    // MARK: - Reduction Operations

    private static func sumCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.sum: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return total sum
        if args.count < 2 || args[1] == .nil {
            var result: Double = 0
            vDSP_sveD(arrayData.data, 1, &result, vDSP_Length(arrayData.size))
            return .number(result)
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.sum: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var result: Double = 0
            vDSP_sveD(slice, 1, &result, vDSP_Length(slice.count))
            return result
        }
    }

    private static func meanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.mean: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return total mean
        if args.count < 2 || args[1] == .nil {
            var result: Double = 0
            vDSP_meanvD(arrayData.data, 1, &result, vDSP_Length(arrayData.size))
            return .number(result)
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.mean: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var result: Double = 0
            vDSP_meanvD(slice, 1, &result, vDSP_Length(slice.count))
            return result
        }
    }

    private static func stdCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.std: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return total std
        if args.count < 2 || args[1] == .nil {
            var mean: Double = 0
            vDSP_meanvD(arrayData.data, 1, &mean, vDSP_Length(arrayData.size))

            var variance: Double = 0
            var temp = [Double](repeating: 0, count: arrayData.size)
            var negMean = -mean
            vDSP_vsaddD(arrayData.data, 1, &negMean, &temp, 1, vDSP_Length(arrayData.size))
            vDSP_svesqD(temp, 1, &variance, vDSP_Length(arrayData.size))
            variance /= Double(arrayData.size)

            return .number(sqrt(variance))
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.std: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var mean: Double = 0
            vDSP_meanvD(slice, 1, &mean, vDSP_Length(slice.count))

            var variance: Double = 0
            var temp = [Double](repeating: 0, count: slice.count)
            var negMean = -mean
            vDSP_vsaddD(slice, 1, &negMean, &temp, 1, vDSP_Length(slice.count))
            vDSP_svesqD(temp, 1, &variance, vDSP_Length(slice.count))
            variance /= Double(slice.count)

            return sqrt(variance)
        }
    }

    private static func varCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.var: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return total variance
        if args.count < 2 || args[1] == .nil {
            var mean: Double = 0
            vDSP_meanvD(arrayData.data, 1, &mean, vDSP_Length(arrayData.size))

            var variance: Double = 0
            var temp = [Double](repeating: 0, count: arrayData.size)
            var negMean = -mean
            vDSP_vsaddD(arrayData.data, 1, &negMean, &temp, 1, vDSP_Length(arrayData.size))
            vDSP_svesqD(temp, 1, &variance, vDSP_Length(arrayData.size))
            variance /= Double(arrayData.size)

            return .number(variance)
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.var: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var mean: Double = 0
            vDSP_meanvD(slice, 1, &mean, vDSP_Length(slice.count))

            var variance: Double = 0
            var temp = [Double](repeating: 0, count: slice.count)
            var negMean = -mean
            vDSP_vsaddD(slice, 1, &negMean, &temp, 1, vDSP_Length(slice.count))
            vDSP_svesqD(temp, 1, &variance, vDSP_Length(slice.count))
            variance /= Double(slice.count)

            return variance
        }
    }

    private static func minCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.min: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return total min
        if args.count < 2 || args[1] == .nil {
            var result: Double = 0
            vDSP_minvD(arrayData.data, 1, &result, vDSP_Length(arrayData.size))
            return .number(result)
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.min: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var result: Double = 0
            vDSP_minvD(slice, 1, &result, vDSP_Length(slice.count))
            return result
        }
    }

    private static func maxCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.max: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return total max
        if args.count < 2 || args[1] == .nil {
            var result: Double = 0
            vDSP_maxvD(arrayData.data, 1, &result, vDSP_Length(arrayData.size))
            return .number(result)
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.max: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var result: Double = 0
            vDSP_maxvD(slice, 1, &result, vDSP_Length(slice.count))
            return result
        }
    }

    private static func argminCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.argmin: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return flat index of min
        if args.count < 2 || args[1] == .nil {
            var minVal: Double = 0
            var minIdx: vDSP_Length = 0
            vDSP_minviD(arrayData.data, 1, &minVal, &minIdx, vDSP_Length(arrayData.size))
            return .number(Double(minIdx + 1))  // 1-based
        }

        // Axis-wise argmin
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.argmin: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var minVal: Double = 0
            var minIdx: vDSP_Length = 0
            vDSP_minviD(slice, 1, &minVal, &minIdx, vDSP_Length(slice.count))
            return Double(minIdx + 1)  // 1-based
        }
    }

    private static func argmaxCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.argmax: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return flat index of max
        if args.count < 2 || args[1] == .nil {
            var maxVal: Double = 0
            var maxIdx: vDSP_Length = 0
            vDSP_maxviD(arrayData.data, 1, &maxVal, &maxIdx, vDSP_Length(arrayData.size))
            return .number(Double(maxIdx + 1))  // 1-based
        }

        // Axis-wise argmax
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.argmax: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var maxVal: Double = 0
            var maxIdx: vDSP_Length = 0
            vDSP_maxviD(slice, 1, &maxVal, &maxIdx, vDSP_Length(slice.count))
            return Double(maxIdx + 1)  // 1-based
        }
    }

    private static func prodCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.prod: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // If no axis specified, return total product
        if args.count < 2 || args[1] == .nil {
            var result: Double = 1
            for val in arrayData.data {
                result *= val
            }
            return .number(result)
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.prod: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { slice in
            var result: Double = 1
            for val in slice {
                result *= val
            }
            return result
        }
    }

    /// Helper function for axis-wise reduction
    private static func reduceAlongAxis(_ arrayData: ArrayData, axis: Int, reduction: ([Double]) -> Double) throws -> LuaValue {
        guard axis >= 0 && axis < arrayData.ndim else {
            throw LuaError.callbackError("array: axis out of bounds")
        }

        var newShape = arrayData.shape
        let axisSize = newShape.remove(at: axis)

        if newShape.isEmpty {
            newShape = [1]
        }

        let newSize = newShape.reduce(1, *)
        var result = [Double](repeating: 0, count: newSize)

        // Calculate strides for original array
        let strides = arrayData.strides

        // For each position in the result
        for i in 0..<newSize {
            // Calculate position in newShape
            var remaining = i
            var indices = [Int](repeating: 0, count: newShape.count)
            for d in stride(from: newShape.count - 1, through: 0, by: -1) {
                indices[d] = remaining % newShape[d]
                remaining /= newShape[d]
            }

            // Insert axis dimension and collect slice
            var slice = [Double](repeating: 0, count: axisSize)
            for j in 0..<axisSize {
                var fullIndices = indices
                fullIndices.insert(j, at: axis)

                var flatIdx = 0
                for d in 0..<arrayData.ndim {
                    flatIdx += fullIndices[d] * strides[d]
                }
                slice[j] = arrayData.data[flatIdx]
            }

            result[i] = reduction(slice)
        }

        return createArrayTable(ArrayData(shape: newShape, data: result))
    }

    // MARK: - Comparison Operations

    private static func equalCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try comparisonOp(args, op: { $0 == $1 ? 1.0 : 0.0 }, name: "equal")
    }

    private static func greaterCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try comparisonOp(args, op: { $0 > $1 ? 1.0 : 0.0 }, name: "greater")
    }

    private static func lessCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try comparisonOp(args, op: { $0 < $1 ? 1.0 : 0.0 }, name: "less")
    }

    private static func greaterEqualCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try comparisonOp(args, op: { $0 >= $1 ? 1.0 : 0.0 }, name: "greater_equal")
    }

    private static func lessEqualCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try comparisonOp(args, op: { $0 <= $1 ? 1.0 : 0.0 }, name: "less_equal")
    }

    private static func notEqualCallback(_ args: [LuaValue]) throws -> LuaValue {
        return try comparisonOp(args, op: { $0 != $1 ? 1.0 : 0.0 }, name: "not_equal")
    }

    private static func isnanCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.isnan: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        var result = [Double](repeating: 0, count: arrayData.size)
        for i in 0..<arrayData.size {
            result[i] = arrayData.data[i].isNaN ? 1.0 : 0.0
        }
        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func isinfCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.isinf: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        var result = [Double](repeating: 0, count: arrayData.size)
        for i in 0..<arrayData.size {
            result[i] = arrayData.data[i].isInfinite ? 1.0 : 0.0
        }
        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func isfiniteCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.isfinite: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        var result = [Double](repeating: 0, count: arrayData.size)
        for i in 0..<arrayData.size {
            result[i] = arrayData.data[i].isFinite ? 1.0 : 0.0
        }
        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func comparisonOp(_ args: [LuaValue], op: (Double, Double) -> Double, name: String) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.\(name): requires two arguments")
        }

        // Handle scalar operands
        let isScalar1 = args[0].numberValue != nil
        let isScalar2 = args[1].numberValue != nil

        if isScalar1 && isScalar2 {
            let val = op(args[0].numberValue!, args[1].numberValue!)
            return createArrayTable(ArrayData(shape: [1], data: [val]))
        }

        if isScalar1 {
            let scalar = args[0].numberValue!
            let arrayData = try extractArrayData(args[1])
            var result = [Double](repeating: 0, count: arrayData.size)
            for i in 0..<arrayData.size {
                result[i] = op(scalar, arrayData.data[i])
            }
            return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
        }

        if isScalar2 {
            let arrayData = try extractArrayData(args[0])
            let scalar = args[1].numberValue!
            var result = [Double](repeating: 0, count: arrayData.size)
            for i in 0..<arrayData.size {
                result[i] = op(arrayData.data[i], scalar)
            }
            return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
        }

        // Both are arrays - broadcast
        let arr1 = try extractArrayData(args[0])
        let arr2 = try extractArrayData(args[1])

        let resultShape = try broadcastShapes(arr1.shape, arr2.shape)
        let broadcast1 = broadcastTo(arr1, shape: resultShape)
        let broadcast2 = broadcastTo(arr2, shape: resultShape)

        var result = [Double](repeating: 0, count: resultShape.reduce(1, *))
        for i in 0..<result.count {
            result[i] = op(broadcast1.data[i], broadcast2.data[i])
        }

        return createArrayTable(ArrayData(shape: resultShape, data: result))
    }

    private static func whereCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("array.where: requires condition, x, and y")
        }

        let condData = try extractArrayData(args[0])

        // Handle scalar x and y
        let isScalarX = args[1].numberValue != nil
        let isScalarY = args[2].numberValue != nil

        let xData: ArrayData
        let yData: ArrayData

        if isScalarX {
            let scalar = args[1].numberValue!
            xData = ArrayData(shape: condData.shape, data: [Double](repeating: scalar, count: condData.size))
        } else {
            xData = try extractArrayData(args[1])
        }

        if isScalarY {
            let scalar = args[2].numberValue!
            yData = ArrayData(shape: condData.shape, data: [Double](repeating: scalar, count: condData.size))
        } else {
            yData = try extractArrayData(args[2])
        }

        // Broadcast all to common shape
        let shape1 = try broadcastShapes(condData.shape, xData.shape)
        let resultShape = try broadcastShapes(shape1, yData.shape)

        let condBroadcast = broadcastTo(condData, shape: resultShape)
        let xBroadcast = broadcastTo(xData, shape: resultShape)
        let yBroadcast = broadcastTo(yData, shape: resultShape)

        var result = [Double](repeating: 0, count: resultShape.reduce(1, *))
        for i in 0..<result.count {
            result[i] = condBroadcast.data[i] != 0 ? xBroadcast.data[i] : yBroadcast.data[i]
        }

        return createArrayTable(ArrayData(shape: resultShape, data: result))
    }

    // MARK: - Boolean Reductions

    private static func allCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.all: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let axis = args.count > 1 ? args[1].intValue : nil

        if let axis = axis {
            // Reduce along axis
            return try reduceAlongAxis(arrayData, axis: axis) { slice in
                for val in slice {
                    if val == 0 { return 0.0 }
                }
                return 1.0
            }
        } else {
            // Global reduction
            for val in arrayData.data {
                if val == 0 { return .number(0) }
            }
            return .number(1)
        }
    }

    private static func anyCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.any: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let axis = args.count > 1 ? args[1].intValue : nil

        if let axis = axis {
            // Reduce along axis
            return try reduceAlongAxis(arrayData, axis: axis) { slice in
                for val in slice {
                    if val != 0 { return 1.0 }
                }
                return 0.0
            }
        } else {
            // Global reduction
            for val in arrayData.data {
                if val != 0 { return .number(1) }
            }
            return .number(0)
        }
    }

    private static func cumsumCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.cumsum: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let axis = args.count > 1 ? args[1].intValue : nil

        if axis == nil {
            // Flatten and compute cumulative sum
            var result = [Double](repeating: 0, count: arrayData.size)
            var cumsum = 0.0
            for i in 0..<arrayData.size {
                cumsum += arrayData.data[i]
                result[i] = cumsum
            }
            return createArrayTable(ArrayData(shape: [arrayData.size], data: result))
        } else {
            // Compute along axis
            return try cumulativeAlongAxis(arrayData, axis: axis!, initialValue: 0.0) { cumsum, val in
                cumsum + val
            }
        }
    }

    private static func cumprodCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.cumprod: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let axis = args.count > 1 ? args[1].intValue : nil

        if axis == nil {
            // Flatten and compute cumulative product
            var result = [Double](repeating: 0, count: arrayData.size)
            var cumprod = 1.0
            for i in 0..<arrayData.size {
                cumprod *= arrayData.data[i]
                result[i] = cumprod
            }
            return createArrayTable(ArrayData(shape: [arrayData.size], data: result))
        } else {
            // Compute along axis
            return try cumulativeAlongAxis(arrayData, axis: axis!, initialValue: 1.0) { cumprod, val in
                cumprod * val
            }
        }
    }

    /// Cumulative operation along a specific axis
    private static func cumulativeAlongAxis(_ arrayData: ArrayData, axis: Int, initialValue: Double, op: (Double, Double) -> Double) throws -> LuaValue {
        let axisIndex = axis - 1  // Convert to 0-based
        guard axisIndex >= 0 && axisIndex < arrayData.ndim else {
            throw LuaError.callbackError("array.cum*: axis out of range")
        }

        let axisSize = arrayData.shape[axisIndex]
        var result = [Double](repeating: 0, count: arrayData.size)

        // Compute strides
        var strides = [Int](repeating: 1, count: arrayData.ndim)
        for d in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
            strides[d] = strides[d + 1] * arrayData.shape[d + 1]
        }

        // Calculate iteration pattern
        let innerSize = strides[axisIndex]  // Elements after axis position
        let outerCount = arrayData.size / (axisSize * innerSize)  // Complete outer blocks

        for outerIdx in 0..<outerCount {
            for innerIdx in 0..<innerSize {
                var cumVal = initialValue

                for axisPos in 0..<axisSize {
                    let flatIdx = outerIdx * (axisSize * innerSize) + axisPos * innerSize + innerIdx
                    cumVal = op(cumVal, arrayData.data[flatIdx])
                    result[flatIdx] = cumVal
                }
            }
        }

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    // MARK: - Sorting and Searching

    private static func sortCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.sort: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let axis = args.count > 1 ? args[1].intValue : nil

        if axis == nil {
            // Sort flattened array
            let sorted = arrayData.data.sorted()
            return createArrayTable(ArrayData(shape: [arrayData.size], data: sorted))
        } else {
            // Sort along axis
            return try sortAlongAxis(arrayData, axis: axis!)
        }
    }

    private static func sortAlongAxis(_ arrayData: ArrayData, axis: Int) throws -> LuaValue {
        let axisIndex = axis - 1  // Convert to 0-based
        guard axisIndex >= 0 && axisIndex < arrayData.ndim else {
            throw LuaError.callbackError("array.sort: axis out of range")
        }

        let axisSize = arrayData.shape[axisIndex]
        var result = arrayData.data  // Copy

        // Compute strides
        var strides = [Int](repeating: 1, count: arrayData.ndim)
        for d in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
            strides[d] = strides[d + 1] * arrayData.shape[d + 1]
        }

        let innerSize = strides[axisIndex]
        let outerCount = arrayData.size / (axisSize * innerSize)

        for outerIdx in 0..<outerCount {
            for innerIdx in 0..<innerSize {
                // Collect slice values
                var slice = [Double](repeating: 0, count: axisSize)
                for axisPos in 0..<axisSize {
                    let flatIdx = outerIdx * (axisSize * innerSize) + axisPos * innerSize + innerIdx
                    slice[axisPos] = result[flatIdx]
                }

                // Sort and write back
                slice.sort()
                for axisPos in 0..<axisSize {
                    let flatIdx = outerIdx * (axisSize * innerSize) + axisPos * innerSize + innerIdx
                    result[flatIdx] = slice[axisPos]
                }
            }
        }

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func argsortCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.argsort: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let axis = args.count > 1 ? args[1].intValue : nil

        if axis == nil {
            // Argsort flattened array - return 1-based indices
            let indices = arrayData.data.enumerated()
                .sorted { $0.element < $1.element }
                .map { Double($0.offset + 1) }  // 1-based
            return createArrayTable(ArrayData(shape: [arrayData.size], data: indices))
        } else {
            // Argsort along axis
            return try argsortAlongAxis(arrayData, axis: axis!)
        }
    }

    private static func argsortAlongAxis(_ arrayData: ArrayData, axis: Int) throws -> LuaValue {
        let axisIndex = axis - 1
        guard axisIndex >= 0 && axisIndex < arrayData.ndim else {
            throw LuaError.callbackError("array.argsort: axis out of range")
        }

        let axisSize = arrayData.shape[axisIndex]
        var result = [Double](repeating: 0, count: arrayData.size)

        var strides = [Int](repeating: 1, count: arrayData.ndim)
        for d in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
            strides[d] = strides[d + 1] * arrayData.shape[d + 1]
        }

        let innerSize = strides[axisIndex]
        let outerCount = arrayData.size / (axisSize * innerSize)

        for outerIdx in 0..<outerCount {
            for innerIdx in 0..<innerSize {
                // Collect slice with indices
                var indexed = [(idx: Int, val: Double)](repeating: (0, 0), count: axisSize)
                for axisPos in 0..<axisSize {
                    let flatIdx = outerIdx * (axisSize * innerSize) + axisPos * innerSize + innerIdx
                    indexed[axisPos] = (axisPos + 1, arrayData.data[flatIdx])  // 1-based index
                }

                // Sort by value
                indexed.sort { $0.val < $1.val }

                // Write sorted indices
                for axisPos in 0..<axisSize {
                    let flatIdx = outerIdx * (axisSize * innerSize) + axisPos * innerSize + innerIdx
                    result[flatIdx] = Double(indexed[axisPos].idx)
                }
            }
        }

        return createArrayTable(ArrayData(shape: arrayData.shape, data: result))
    }

    private static func searchsortedCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.searchsorted: requires sorted array and values")
        }

        let sortedData = try extractArrayData(args[0])
        guard sortedData.ndim == 1 else {
            throw LuaError.callbackError("array.searchsorted: input must be 1D array")
        }

        let sortedArray = sortedData.data
        let side = args.count > 2 ? args[2].stringValue ?? "left" : "left"
        let leftSide = side != "right"

        // Handle scalar or array input
        if let scalar = args[1].numberValue {
            let idx = binarySearch(sortedArray, value: scalar, left: leftSide)
            return .number(Double(idx))
        }

        let values = try extractArrayData(args[1])
        var result = [Double](repeating: 0, count: values.size)

        for i in 0..<values.size {
            result[i] = Double(binarySearch(sortedArray, value: values.data[i], left: leftSide))
        }

        return createArrayTable(ArrayData(shape: values.shape, data: result))
    }

    private static func binarySearch(_ arr: [Double], value: Double, left: Bool) -> Int {
        var lo = 0
        var hi = arr.count

        while lo < hi {
            let mid = (lo + hi) / 2
            let cmp = left ? (arr[mid] < value) : (arr[mid] <= value)
            if cmp {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo + 1  // 1-based index
    }

    private static func argwhereCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.argwhere: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])

        // Find all non-zero indices
        var indices: [[Int]] = []
        for i in 0..<arrayData.size {
            if arrayData.data[i] != 0 {
                // Convert flat index to multi-dimensional index (1-based)
                var idx = i
                var multiIdx = [Int](repeating: 0, count: arrayData.ndim)
                for d in stride(from: arrayData.ndim - 1, through: 0, by: -1) {
                    multiIdx[d] = (idx % arrayData.shape[d]) + 1  // 1-based
                    idx /= arrayData.shape[d]
                }
                indices.append(multiIdx)
            }
        }

        if indices.isEmpty {
            return createArrayTable(ArrayData(shape: [0, arrayData.ndim], data: []))
        }

        // Return as (N, ndim) array where N is number of non-zero elements
        let data = indices.flatMap { $0.map { Double($0) } }
        return createArrayTable(ArrayData(shape: [indices.count, arrayData.ndim], data: data))
    }

    private static func nonzeroCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.nonzero: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])

        // For each dimension, collect indices where non-zero
        var dimIndices = [[Double]](repeating: [], count: arrayData.ndim)

        for i in 0..<arrayData.size {
            if arrayData.data[i] != 0 {
                var idx = i
                for d in stride(from: arrayData.ndim - 1, through: 0, by: -1) {
                    dimIndices[d].append(Double((idx % arrayData.shape[d]) + 1))  // 1-based
                    idx /= arrayData.shape[d]
                }
            }
        }

        // Return tuple of arrays, one per dimension
        var result: [LuaValue] = []
        for d in 0..<arrayData.ndim {
            let dimArray = createArrayTable(ArrayData(shape: [dimIndices[d].count], data: dimIndices[d]))
            result.append(dimArray)
        }

        return .array(result)
    }

    private static func uniqueCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.unique: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let returnIndex = args.count > 1 ? args[1].boolValue ?? false : false
        let returnInverse = args.count > 2 ? args[2].boolValue ?? false : false
        let returnCounts = args.count > 3 ? args[3].boolValue ?? false : false

        // Get unique values while tracking first indices
        var seen: [Double: (index: Int, count: Int)] = [:]
        var uniqueValues: [Double] = []

        for (i, val) in arrayData.data.enumerated() {
            if let existing = seen[val] {
                seen[val] = (existing.index, existing.count + 1)
            } else {
                seen[val] = (i + 1, 1)  // 1-based index
                uniqueValues.append(val)
            }
        }

        // Sort unique values
        uniqueValues.sort()

        let uniqueArray = createArrayTable(ArrayData(shape: [uniqueValues.count], data: uniqueValues))

        if !returnIndex && !returnInverse && !returnCounts {
            return uniqueArray
        }

        var results: [LuaValue] = [uniqueArray]

        if returnIndex {
            // First occurrence indices (1-based)
            let indices = uniqueValues.map { Double(seen[$0]!.index) }
            results.append(createArrayTable(ArrayData(shape: [indices.count], data: indices)))
        }

        if returnInverse {
            // For each original element, index into unique array (1-based)
            var valueToUniqueIdx: [Double: Int] = [:]
            for (i, v) in uniqueValues.enumerated() {
                valueToUniqueIdx[v] = i + 1  // 1-based
            }
            let inverse = arrayData.data.map { Double(valueToUniqueIdx[$0]!) }
            results.append(createArrayTable(ArrayData(shape: arrayData.shape, data: inverse)))
        }

        if returnCounts {
            let counts = uniqueValues.map { Double(seen[$0]!.count) }
            results.append(createArrayTable(ArrayData(shape: [counts.count], data: counts)))
        }

        return .array(results)
    }

    // MARK: - Statistics Functions

    private static func medianCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.median: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])

        // If no axis specified, return global median
        if args.count < 2 || args[1] == .nil {
            let sorted = arrayData.data.sorted()
            let n = sorted.count
            if n % 2 == 1 {
                return .number(sorted[n / 2])
            } else {
                return .number((sorted[n / 2 - 1] + sorted[n / 2]) / 2.0)
            }
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.median: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { values in
            let sorted = values.sorted()
            let n = sorted.count
            if n % 2 == 1 {
                return sorted[n / 2]
            } else {
                return (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
            }
        }
    }

    private static func percentileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.percentile: requires array and percentile arguments")
        }

        let arrayData = try extractArrayData(args[0])
        guard let q = args[1].numberValue else {
            throw LuaError.callbackError("array.percentile: percentile must be a number")
        }

        if q < 0 || q > 100 {
            throw LuaError.callbackError("array.percentile: percentile must be between 0 and 100")
        }

        // Convert percentile (0-100) to fraction (0-1)
        let fraction = q / 100.0

        // If no axis specified, return global percentile
        if args.count < 3 || args[2] == .nil {
            let sorted = arrayData.data.sorted()
            return .number(computeQuantile(sorted, fraction: fraction))
        }

        // Axis-wise reduction
        guard let axis = args[2].intValue else {
            throw LuaError.callbackError("array.percentile: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { values in
            computeQuantile(values.sorted(), fraction: fraction)
        }
    }

    private static func quantileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.quantile: requires array and quantile arguments")
        }

        let arrayData = try extractArrayData(args[0])
        guard let q = args[1].numberValue else {
            throw LuaError.callbackError("array.quantile: quantile must be a number")
        }

        if q < 0 || q > 1 {
            throw LuaError.callbackError("array.quantile: quantile must be between 0 and 1")
        }

        // If no axis specified, return global quantile
        if args.count < 3 || args[2] == .nil {
            let sorted = arrayData.data.sorted()
            return .number(computeQuantile(sorted, fraction: q))
        }

        // Axis-wise reduction
        guard let axis = args[2].intValue else {
            throw LuaError.callbackError("array.quantile: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { values in
            computeQuantile(values.sorted(), fraction: q)
        }
    }

    /// Helper function to compute quantile using linear interpolation
    private static func computeQuantile(_ sorted: [Double], fraction: Double) -> Double {
        let n = sorted.count
        if n == 0 { return Double.nan }
        if n == 1 { return sorted[0] }

        // Use linear interpolation (NumPy default method)
        let index = fraction * Double(n - 1)
        let lower = Int(index)
        let upper = min(lower + 1, n - 1)
        let weight = index - Double(lower)

        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }

    private static func histogramCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.histogram: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let data = arrayData.data

        // Default to 10 bins
        let numBins: Int
        if args.count > 1, let binsArg = args[1].intValue {
            numBins = binsArg
        } else {
            numBins = 10
        }

        // Determine range
        var minVal: Double
        var maxVal: Double
        if args.count > 2, let range = args[2].arrayValue, range.count >= 2 {
            minVal = range[0].numberValue ?? data.min()!
            maxVal = range[1].numberValue ?? data.max()!
        } else {
            minVal = data.min() ?? 0
            maxVal = data.max() ?? 0
        }

        // Handle edge case where min == max
        if minVal == maxVal {
            minVal -= 0.5
            maxVal += 0.5
        }

        let binWidth = (maxVal - minVal) / Double(numBins)

        // Calculate bin edges (numBins + 1 edges)
        var edges: [Double] = []
        for i in 0...numBins {
            edges.append(minVal + Double(i) * binWidth)
        }

        // Count values in each bin
        var counts = [Double](repeating: 0, count: numBins)
        for val in data {
            if val < minVal || val > maxVal { continue }
            var binIdx = Int((val - minVal) / binWidth)
            // Handle edge case where val == maxVal
            if binIdx >= numBins { binIdx = numBins - 1 }
            counts[binIdx] += 1
        }

        // Return counts and edges as separate arrays
        let countsArray = createArrayTable(ArrayData(shape: [counts.count], data: counts))
        let edgesArray = createArrayTable(ArrayData(shape: [edges.count], data: edges))

        return .array([countsArray, edgesArray])
    }

    private static func bincountCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.bincount: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])

        // Get optional weights
        var weights: [Double]? = nil
        if args.count > 1 && args[1] != .nil {
            let weightsData = try extractArrayData(args[1])
            if weightsData.size != arrayData.size {
                throw LuaError.callbackError("array.bincount: weights must have same size as input")
            }
            weights = weightsData.data
        }

        // Get optional minlength
        let minlength = args.count > 2 ? (args[2].intValue ?? 0) : 0

        // Find max value to determine output size
        var maxVal = 0
        for val in arrayData.data {
            if val < 0 || val.truncatingRemainder(dividingBy: 1) != 0 {
                throw LuaError.callbackError("array.bincount: input must contain non-negative integers")
            }
            maxVal = max(maxVal, Int(val))
        }

        let outputSize = max(maxVal + 1, minlength)
        var counts = [Double](repeating: 0, count: outputSize)

        // Count occurrences (with optional weights)
        for (i, val) in arrayData.data.enumerated() {
            let idx = Int(val)
            if let w = weights {
                counts[idx] += w[i]
            } else {
                counts[idx] += 1
            }
        }

        return createArrayTable(ArrayData(shape: [counts.count], data: counts))
    }

    private static func ptpCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.ptp: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])

        // If no axis specified, return global ptp
        if args.count < 2 || args[1] == .nil {
            guard let minV = arrayData.data.min(), let maxV = arrayData.data.max() else {
                return .number(0)
            }
            return .number(maxV - minV)
        }

        // Axis-wise reduction
        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.ptp: axis must be an integer")
        }

        return try reduceAlongAxis(arrayData, axis: axis - 1) { values in
            guard let minV = values.min(), let maxV = values.max() else { return 0 }
            return maxV - minV
        }
    }

    // MARK: - LinAlg Overlap Functions

    private static func traceCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.trace: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])

        guard arrayData.ndim == 2 else {
            throw LuaError.callbackError("array.trace: input must be 2D")
        }

        let rows = arrayData.shape[0]
        let cols = arrayData.shape[1]
        let offset = args.count > 1 ? (args[1].intValue ?? 0) : 0

        var trace = 0.0
        let n = min(rows, cols)
        for i in 0..<n {
            let row = i
            let col = i + offset
            if col >= 0 && col < cols && row >= 0 && row < rows {
                trace += arrayData.data[row * cols + col]
            }
        }

        return .number(trace)
    }

    private static func diagonalCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.diagonal: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])

        guard arrayData.ndim == 2 else {
            throw LuaError.callbackError("array.diagonal: input must be 2D")
        }

        let rows = arrayData.shape[0]
        let cols = arrayData.shape[1]
        let offset = args.count > 1 ? (args[1].intValue ?? 0) : 0

        var diagonal: [Double] = []

        if offset >= 0 {
            // Upper diagonal or main diagonal
            let n = min(rows, cols - offset)
            for i in 0..<n {
                diagonal.append(arrayData.data[i * cols + (i + offset)])
            }
        } else {
            // Lower diagonal
            let n = min(rows + offset, cols)
            for i in 0..<n {
                diagonal.append(arrayData.data[(i - offset) * cols + i])
            }
        }

        return createArrayTable(ArrayData(shape: [diagonal.count], data: diagonal))
    }

    private static func diagCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.diag: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        let k = args.count > 1 ? (args[1].intValue ?? 0) : 0

        if arrayData.ndim == 1 {
            // Create diagonal matrix from 1D array
            let n = arrayData.size + abs(k)
            var result = [Double](repeating: 0, count: n * n)

            for i in 0..<arrayData.size {
                let row = k >= 0 ? i : i - k
                let col = k >= 0 ? i + k : i
                result[row * n + col] = arrayData.data[i]
            }

            return createArrayTable(ArrayData(shape: [n, n], data: result))
        } else if arrayData.ndim == 2 {
            // Extract diagonal from 2D matrix (same as diagonal)
            let rows = arrayData.shape[0]
            let cols = arrayData.shape[1]

            var diagonal: [Double] = []

            if k >= 0 {
                let n = min(rows, cols - k)
                for i in 0..<n {
                    diagonal.append(arrayData.data[i * cols + (i + k)])
                }
            } else {
                let n = min(rows + k, cols)
                for i in 0..<n {
                    diagonal.append(arrayData.data[(i - k) * cols + i])
                }
            }

            return createArrayTable(ArrayData(shape: [diagonal.count], data: diagonal))
        } else {
            throw LuaError.callbackError("array.diag: input must be 1D or 2D")
        }
    }

    private static func outerCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.outer: requires two arguments")
        }

        let arr1 = try extractArrayData(args[0])
        let arr2 = try extractArrayData(args[1])

        guard arr1.ndim == 1 && arr2.ndim == 1 else {
            throw LuaError.callbackError("array.outer: both inputs must be 1D")
        }

        let m = arr1.size
        let n = arr2.size
        var result = [Double](repeating: 0, count: m * n)

        for i in 0..<m {
            for j in 0..<n {
                result[i * n + j] = arr1.data[i] * arr2.data[j]
            }
        }

        return createArrayTable(ArrayData(shape: [m, n], data: result))
    }

    // MARK: - Creation Functions (Phase 3.1)

    private static func eyeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1, let n = args[0].intValue else {
            throw LuaError.callbackError("array.eye: requires n (number of rows)")
        }

        let m = args.count > 1 ? (args[1].intValue ?? n) : n
        let k = args.count > 2 ? (args[2].intValue ?? 0) : 0

        let size = n * m
        try trackArrayAllocation(count: size)
        var data = [Double](repeating: 0, count: size)

        let diagLen = min(n, m)
        for i in 0..<diagLen {
            let row = i
            let col = i + k
            if col >= 0 && col < m && row >= 0 && row < n {
                data[row * m + col] = 1.0
            }
        }

        return createArrayTable(ArrayData(shape: [n, m], data: data))
    }

    private static func identityCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1, let n = args[0].intValue else {
            throw LuaError.callbackError("array.identity: requires n (size)")
        }

        let size = n * n
        try trackArrayAllocation(count: size)
        var data = [Double](repeating: 0, count: size)
        for i in 0..<n {
            data[i * n + i] = 1.0
        }

        return createArrayTable(ArrayData(shape: [n, n], data: data))
    }

    private static func emptyCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.empty: requires shape argument")
        }

        var shape: [Int] = []
        if let arr = arg.arrayValue {
            shape = arr.compactMap { $0.intValue }
        } else if let tbl = arg.tableValue {
            var i = 1
            while let dim = tbl[String(i)]?.intValue {
                shape.append(dim)
                i += 1
            }
        } else if let n = arg.intValue {
            shape = [n]
        }

        guard !shape.isEmpty else {
            throw LuaError.callbackError("array.empty: invalid shape")
        }

        let size = shape.reduce(1, *)
        try trackArrayAllocation(count: size)
        // In our implementation, empty is the same as zeros (no uninitialized memory)
        let data = [Double](repeating: 0, count: size)

        return createArrayTable(ArrayData(shape: shape, data: data))
    }

    private static func zerosLikeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.zeros_like: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        try trackArrayAllocation(count: arrayData.size)
        let data = [Double](repeating: 0, count: arrayData.size)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: data))
    }

    private static func onesLikeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1 else {
            throw LuaError.callbackError("array.ones_like: requires an array argument")
        }

        let arrayData = try extractArrayData(args[0])
        try trackArrayAllocation(count: arrayData.size)
        let data = [Double](repeating: 1, count: arrayData.size)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: data))
    }

    private static func fullLikeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.full_like: requires array and fill_value arguments")
        }

        let arrayData = try extractArrayData(args[0])
        guard let fillValue = args[1].numberValue else {
            throw LuaError.callbackError("array.full_like: fill_value must be a number")
        }

        try trackArrayAllocation(count: arrayData.size)
        let data = [Double](repeating: fillValue, count: arrayData.size)

        return createArrayTable(ArrayData(shape: arrayData.shape, data: data))
    }

    // MARK: - Utility Functions

    private static func toListCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.tolist: missing argument")
        }

        let arrayData = try extractArrayData(arg)

        // Reconstruct nested structure
        func buildNested(_ data: [Double], shape: [Int], offset: inout Int) -> LuaValue {
            if shape.count == 1 {
                var arr: [LuaValue] = []
                for _ in 0..<shape[0] {
                    arr.append(.number(data[offset]))
                    offset += 1
                }
                return .array(arr)
            }

            var arr: [LuaValue] = []
            let subShape = Array(shape.dropFirst())
            for _ in 0..<shape[0] {
                arr.append(buildNested(data, shape: subShape, offset: &offset))
            }
            return .array(arr)
        }

        var offset = 0
        return buildNested(arrayData.data, shape: arrayData.shape, offset: &offset)
    }

    private static func copyCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arg = args.first else {
            throw LuaError.callbackError("array.copy: missing argument")
        }

        let arrayData = try extractArrayData(arg)
        return createArrayTable(ArrayData(shape: arrayData.shape, data: arrayData.data))
    }

    private static func dotCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.dot: requires two arguments")
        }

        let arr1 = try extractArrayData(args[0])
        let arr2 = try extractArrayData(args[1])

        // 1D . 1D = scalar (inner product)
        if arr1.ndim == 1 && arr2.ndim == 1 {
            guard arr1.size == arr2.size else {
                throw LuaError.callbackError("array.dot: vectors must have same length")
            }
            var result: Double = 0
            vDSP_dotprD(arr1.data, 1, arr2.data, 1, &result, vDSP_Length(arr1.size))
            return .number(result)
        }

        // 2D . 2D = matrix multiplication
        if arr1.ndim == 2 && arr2.ndim == 2 {
            guard arr1.shape[1] == arr2.shape[0] else {
                throw LuaError.callbackError("array.dot: incompatible shapes for matrix multiplication")
            }

            let M = arr1.shape[0]
            let K = arr1.shape[1]
            let N = arr2.shape[1]

            var result = [Double](repeating: 0, count: M * N)
            cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                        Int32(M), Int32(N), Int32(K),
                        1.0, arr1.data, Int32(K),
                        arr2.data, Int32(N),
                        0.0, &result, Int32(N))

            return createArrayTable(ArrayData(shape: [M, N], data: result))
        }

        // 2D . 1D = matrix-vector multiplication
        if arr1.ndim == 2 && arr2.ndim == 1 {
            guard arr1.shape[1] == arr2.size else {
                throw LuaError.callbackError("array.dot: incompatible shapes")
            }

            let M = arr1.shape[0]
            let N = arr1.shape[1]

            var result = [Double](repeating: 0, count: M)
            cblas_dgemv(CblasRowMajor, CblasNoTrans,
                        Int32(M), Int32(N),
                        1.0, arr1.data, Int32(N),
                        arr2.data, 1,
                        0.0, &result, 1)

            return createArrayTable(ArrayData(shape: [M], data: result))
        }

        throw LuaError.callbackError("array.dot: unsupported operand dimensions")
    }

    // MARK: - Array Manipulation

    private static func concatenateCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arraysArg = args.first else {
            throw LuaError.callbackError("array.concatenate: missing arrays argument")
        }

        // Get axis (default 0, but 1-based in Lua so default 1)
        let axis = (args.count >= 2 ? args[1].intValue : nil) ?? 1
        let axis0 = axis - 1  // Convert to 0-based

        // Extract arrays from table
        var arrays: [ArrayData] = []
        if let tbl = arraysArg.tableValue {
            var i = 1
            while let arr = tbl[String(i)] {
                arrays.append(try extractArrayData(arr))
                i += 1
            }
        } else if let arr = arraysArg.arrayValue {
            for item in arr {
                arrays.append(try extractArrayData(item))
            }
        }

        guard arrays.count >= 1 else {
            throw LuaError.callbackError("array.concatenate: need at least one array")
        }

        let ndim = arrays[0].ndim
        guard axis0 >= 0 && axis0 < ndim else {
            throw LuaError.callbackError("array.concatenate: axis out of bounds")
        }

        // Verify all arrays have same shape except along axis
        let baseShape = arrays[0].shape
        for arr in arrays.dropFirst() {
            guard arr.ndim == ndim else {
                throw LuaError.callbackError("array.concatenate: all arrays must have same ndim")
            }
            for d in 0..<ndim where d != axis0 {
                guard arr.shape[d] == baseShape[d] else {
                    throw LuaError.callbackError("array.concatenate: arrays must match on all axes except concatenation axis")
                }
            }
        }

        // Calculate result shape
        var resultShape = baseShape
        resultShape[axis0] = arrays.reduce(0) { $0 + $1.shape[axis0] }

        let resultSize = resultShape.reduce(1, *)
        var resultData = [Double](repeating: 0, count: resultSize)

        // Calculate strides for result
        var resultStrides = [Int](repeating: 1, count: ndim)
        for i in stride(from: ndim - 2, through: 0, by: -1) {
            resultStrides[i] = resultStrides[i + 1] * resultShape[i + 1]
        }

        // Copy data from each array
        var axisOffset = 0
        for arr in arrays {
            // For each element in this array
            for i in 0..<arr.size {
                // Calculate multi-dim index in source array
                var remaining = i
                var srcIndices = [Int](repeating: 0, count: ndim)
                for d in stride(from: ndim - 1, through: 0, by: -1) {
                    srcIndices[d] = remaining % arr.shape[d]
                    remaining /= arr.shape[d]
                }

                // Calculate destination index (offset along concat axis)
                var dstIndices = srcIndices
                dstIndices[axis0] += axisOffset

                var dstFlatIdx = 0
                for d in 0..<ndim {
                    dstFlatIdx += dstIndices[d] * resultStrides[d]
                }

                resultData[dstFlatIdx] = arr.data[i]
            }

            axisOffset += arr.shape[axis0]
        }

        return createArrayTable(ArrayData(shape: resultShape, data: resultData))
    }

    private static func stackCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let arraysArg = args.first else {
            throw LuaError.callbackError("array.stack: missing arrays argument")
        }

        let axis = (args.count >= 2 ? args[1].intValue : nil) ?? 1
        let axis0 = axis - 1

        // Extract arrays
        var arrays: [ArrayData] = []
        if let tbl = arraysArg.tableValue {
            var i = 1
            while let arr = tbl[String(i)] {
                arrays.append(try extractArrayData(arr))
                i += 1
            }
        } else if let arr = arraysArg.arrayValue {
            for item in arr {
                arrays.append(try extractArrayData(item))
            }
        }

        guard arrays.count >= 1 else {
            throw LuaError.callbackError("array.stack: need at least one array")
        }

        // All arrays must have same shape
        let baseShape = arrays[0].shape
        for arr in arrays.dropFirst() {
            guard arr.shape == baseShape else {
                throw LuaError.callbackError("array.stack: all arrays must have same shape")
            }
        }

        // Insert new axis
        var resultShape = baseShape
        resultShape.insert(arrays.count, at: axis0)

        let resultSize = resultShape.reduce(1, *)
        var resultData = [Double](repeating: 0, count: resultSize)

        // Calculate strides
        var resultStrides = [Int](repeating: 1, count: resultShape.count)
        for i in stride(from: resultShape.count - 2, through: 0, by: -1) {
            resultStrides[i] = resultStrides[i + 1] * resultShape[i + 1]
        }

        // Copy data
        for (arrIdx, arr) in arrays.enumerated() {
            for i in 0..<arr.size {
                // Calculate source indices
                var remaining = i
                var srcIndices = [Int](repeating: 0, count: baseShape.count)
                for d in stride(from: baseShape.count - 1, through: 0, by: -1) {
                    srcIndices[d] = remaining % baseShape[d]
                    remaining /= baseShape[d]
                }

                // Insert array index at axis position
                var dstIndices = srcIndices
                dstIndices.insert(arrIdx, at: axis0)

                var dstFlatIdx = 0
                for d in 0..<resultShape.count {
                    dstFlatIdx += dstIndices[d] * resultStrides[d]
                }

                resultData[dstFlatIdx] = arr.data[i]
            }
        }

        return createArrayTable(ArrayData(shape: resultShape, data: resultData))
    }

    private static func splitCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.split: requires array and indices_or_sections")
        }

        let arrayData = try extractArrayData(args[0])
        let axis = (args.count >= 3 ? args[2].intValue : nil) ?? 1
        let axis0 = axis - 1

        guard axis0 >= 0 && axis0 < arrayData.ndim else {
            throw LuaError.callbackError("array.split: axis out of bounds")
        }

        let axisSize = arrayData.shape[axis0]
        var splitPoints: [Int] = []

        // Determine split points
        if let sections = args[1].intValue {
            // Equal split
            guard axisSize % sections == 0 else {
                throw LuaError.callbackError("array.split: array not evenly divisible")
            }
            let chunkSize = axisSize / sections
            for i in 1..<sections {
                splitPoints.append(i * chunkSize)
            }
        } else if let indices = args[1].arrayValue {
            splitPoints = indices.compactMap { $0.intValue }
        } else if let tbl = args[1].tableValue {
            var i = 1
            while let idx = tbl[String(i)]?.intValue {
                splitPoints.append(idx)
                i += 1
            }
        }

        // Create split arrays
        var resultArrays: [LuaValue] = []
        var prevIdx = 0
        let allPoints = splitPoints + [axisSize]

        for endIdx in allPoints {
            // Create sub-array shape
            var subShape = arrayData.shape
            subShape[axis0] = endIdx - prevIdx
            let subSize = subShape.reduce(1, *)
            var subData = [Double](repeating: 0, count: subSize)

            // Copy data for this slice
            var subStrides = [Int](repeating: 1, count: arrayData.ndim)
            for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
                subStrides[i] = subStrides[i + 1] * subShape[i + 1]
            }

            for i in 0..<subSize {
                var remaining = i
                var subIndices = [Int](repeating: 0, count: arrayData.ndim)
                for d in stride(from: arrayData.ndim - 1, through: 0, by: -1) {
                    subIndices[d] = remaining % subShape[d]
                    remaining /= subShape[d]
                }

                var srcIndices = subIndices
                srcIndices[axis0] += prevIdx

                let srcFlatIdx = arrayData.flatIndex(srcIndices)
                subData[i] = arrayData.data[srcFlatIdx]
            }

            resultArrays.append(createArrayTable(ArrayData(shape: subShape, data: subData)))
            prevIdx = endIdx
        }

        return .array(resultArrays)
    }

    // MARK: - Phase 3.2 Array Manipulation

    /// tile: Construct an array by repeating A the number of times given by reps
    private static func tileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.tile: requires array and reps arguments")
        }

        let arrayData = try extractArrayData(args[0])

        // Parse reps - can be a single integer or array of integers
        var reps: [Int] = []
        if let singleRep = args[1].intValue {
            reps = [singleRep]
        } else if let repArray = args[1].arrayValue {
            reps = repArray.compactMap { $0.intValue }
        } else if let repTable = args[1].tableValue {
            var i = 1
            while let rep = repTable[String(i)]?.intValue {
                reps.append(rep)
                i += 1
            }
        }

        guard !reps.isEmpty else {
            throw LuaError.callbackError("array.tile: reps must be non-empty")
        }

        // Extend reps to match array dimensions (prepend 1s if needed)
        while reps.count < arrayData.ndim {
            reps.insert(1, at: 0)
        }

        // If reps has more dimensions, prepend 1s to shape
        var sourceShape = arrayData.shape
        while sourceShape.count < reps.count {
            sourceShape.insert(1, at: 0)
        }

        // Calculate result shape
        var resultShape = [Int]()
        for i in 0..<sourceShape.count {
            resultShape.append(sourceShape[i] * reps[i])
        }

        let resultSize = resultShape.reduce(1, *)
        var resultData = [Double](repeating: 0, count: resultSize)

        // Calculate strides for result
        var resultStrides = [Int](repeating: 1, count: resultShape.count)
        for i in stride(from: resultShape.count - 2, through: 0, by: -1) {
            resultStrides[i] = resultStrides[i + 1] * resultShape[i + 1]
        }

        // Calculate strides for source (with prepended dimensions)
        var sourceStrides = [Int](repeating: 1, count: sourceShape.count)
        for i in stride(from: sourceShape.count - 2, through: 0, by: -1) {
            sourceStrides[i] = sourceStrides[i + 1] * sourceShape[i + 1]
        }

        // Fill result by tiling
        for i in 0..<resultSize {
            var remaining = i
            var srcIdx = 0
            for d in 0..<resultShape.count {
                let dstCoord = remaining / resultStrides[d]
                remaining = remaining % resultStrides[d]
                // Wrap to source coordinate
                let srcCoord = dstCoord % sourceShape[d]
                srcIdx += srcCoord * sourceStrides[d]
            }
            // Adjust srcIdx for original array data (accounting for any prepended dimensions)
            let adjustedIdx = srcIdx % arrayData.size
            resultData[i] = arrayData.data[adjustedIdx]
        }

        return createArrayTable(ArrayData(shape: resultShape, data: resultData))
    }

    /// repeat: Repeat each element of an array
    private static func repeatCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.rep: requires array and repeats arguments")
        }

        let arrayData = try extractArrayData(args[0])

        guard let repeats = args[1].intValue, repeats > 0 else {
            throw LuaError.callbackError("array.rep: repeats must be a positive integer")
        }

        // If axis is specified
        if args.count >= 3 && args[2] != .nil {
            guard let axis = args[2].intValue else {
                throw LuaError.callbackError("array.rep: axis must be an integer")
            }
            let axis0 = axis - 1
            guard axis0 >= 0 && axis0 < arrayData.ndim else {
                throw LuaError.callbackError("array.rep: axis out of bounds")
            }

            var resultShape = arrayData.shape
            resultShape[axis0] *= repeats

            let resultSize = resultShape.reduce(1, *)
            var resultData = [Double](repeating: 0, count: resultSize)

            // Calculate strides
            var srcStrides = [Int](repeating: 1, count: arrayData.ndim)
            for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
                srcStrides[i] = srcStrides[i + 1] * arrayData.shape[i + 1]
            }

            var dstStrides = [Int](repeating: 1, count: arrayData.ndim)
            for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
                dstStrides[i] = dstStrides[i + 1] * resultShape[i + 1]
            }

            // For each element in source, repeat along axis
            for srcIdx in 0..<arrayData.size {
                var remaining = srcIdx
                var coords = [Int](repeating: 0, count: arrayData.ndim)
                for d in 0..<arrayData.ndim {
                    coords[d] = remaining / srcStrides[d]
                    remaining = remaining % srcStrides[d]
                }

                // Repeat this element along the axis
                for rep in 0..<repeats {
                    var dstCoords = coords
                    dstCoords[axis0] = coords[axis0] * repeats + rep
                    var dstIdx = 0
                    for d in 0..<arrayData.ndim {
                        dstIdx += dstCoords[d] * dstStrides[d]
                    }
                    resultData[dstIdx] = arrayData.data[srcIdx]
                }
            }

            return createArrayTable(ArrayData(shape: resultShape, data: resultData))
        } else {
            // No axis: flatten and repeat each element
            var resultData = [Double]()
            for val in arrayData.data {
                for _ in 0..<repeats {
                    resultData.append(val)
                }
            }
            return createArrayTable(ArrayData(shape: [resultData.count], data: resultData))
        }
    }

    /// flip: Reverse the order of elements along the given axis
    private static func flipCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard !args.isEmpty else {
            throw LuaError.callbackError("array.flip: requires array argument")
        }

        let arrayData = try extractArrayData(args[0])

        // If no axis specified, reverse all elements (flatten)
        if args.count < 2 || args[1] == .nil {
            let reversedData = Array(arrayData.data.reversed())
            return createArrayTable(ArrayData(shape: arrayData.shape, data: reversedData))
        }

        guard let axis = args[1].intValue else {
            throw LuaError.callbackError("array.flip: axis must be an integer")
        }
        let axis0 = axis - 1
        guard axis0 >= 0 && axis0 < arrayData.ndim else {
            throw LuaError.callbackError("array.flip: axis out of bounds")
        }

        var resultData = [Double](repeating: 0, count: arrayData.size)

        // Calculate strides
        var strides = [Int](repeating: 1, count: arrayData.ndim)
        for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
            strides[i] = strides[i + 1] * arrayData.shape[i + 1]
        }

        for i in 0..<arrayData.size {
            var remaining = i
            var coords = [Int](repeating: 0, count: arrayData.ndim)
            for d in 0..<arrayData.ndim {
                coords[d] = remaining / strides[d]
                remaining = remaining % strides[d]
            }

            // Flip the coordinate along the specified axis
            coords[axis0] = arrayData.shape[axis0] - 1 - coords[axis0]

            var srcIdx = 0
            for d in 0..<arrayData.ndim {
                srcIdx += coords[d] * strides[d]
            }

            resultData[i] = arrayData.data[srcIdx]
        }

        return createArrayTable(ArrayData(shape: arrayData.shape, data: resultData))
    }

    /// roll: Roll array elements along a given axis
    private static func rollCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.roll: requires array and shift arguments")
        }

        let arrayData = try extractArrayData(args[0])

        guard let shift = args[1].intValue else {
            throw LuaError.callbackError("array.roll: shift must be an integer")
        }

        // If no axis specified, roll over flattened array
        if args.count < 3 || args[2] == .nil {
            var resultData = [Double](repeating: 0, count: arrayData.size)
            let n = arrayData.size
            let normalizedShift = ((shift % n) + n) % n  // Handle negative shifts
            for i in 0..<n {
                let newIdx = (i + normalizedShift) % n
                resultData[newIdx] = arrayData.data[i]
            }
            return createArrayTable(ArrayData(shape: arrayData.shape, data: resultData))
        }

        guard let axis = args[2].intValue else {
            throw LuaError.callbackError("array.roll: axis must be an integer")
        }
        let axis0 = axis - 1
        guard axis0 >= 0 && axis0 < arrayData.ndim else {
            throw LuaError.callbackError("array.roll: axis out of bounds")
        }

        var resultData = [Double](repeating: 0, count: arrayData.size)

        // Calculate strides
        var strides = [Int](repeating: 1, count: arrayData.ndim)
        for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
            strides[i] = strides[i + 1] * arrayData.shape[i + 1]
        }

        let axisSize = arrayData.shape[axis0]
        let normalizedShift = ((shift % axisSize) + axisSize) % axisSize

        for i in 0..<arrayData.size {
            var remaining = i
            var coords = [Int](repeating: 0, count: arrayData.ndim)
            for d in 0..<arrayData.ndim {
                coords[d] = remaining / strides[d]
                remaining = remaining % strides[d]
            }

            // Roll the coordinate along the specified axis
            var newCoords = coords
            newCoords[axis0] = (coords[axis0] + normalizedShift) % axisSize

            var dstIdx = 0
            for d in 0..<arrayData.ndim {
                dstIdx += newCoords[d] * strides[d]
            }

            resultData[dstIdx] = arrayData.data[i]
        }

        return createArrayTable(ArrayData(shape: arrayData.shape, data: resultData))
    }

    /// pad: Pad an array with constant values
    private static func padCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.pad: requires array and pad_width arguments")
        }

        let arrayData = try extractArrayData(args[0])

        // Parse pad_width: can be single int, or array of pairs
        var padBefore = [Int](repeating: 0, count: arrayData.ndim)
        var padAfter = [Int](repeating: 0, count: arrayData.ndim)

        if let singlePad = args[1].intValue {
            // Same padding for all axes
            for i in 0..<arrayData.ndim {
                padBefore[i] = singlePad
                padAfter[i] = singlePad
            }
        } else if let padArray = args[1].arrayValue {
            // Can be [before, after] for all or [[b1,a1], [b2,a2], ...] for each axis
            if padArray.count == 2 && padArray[0].intValue != nil {
                // [before, after] for all axes
                let before = padArray[0].intValue ?? 0
                let after = padArray[1].intValue ?? 0
                for i in 0..<arrayData.ndim {
                    padBefore[i] = before
                    padAfter[i] = after
                }
            } else {
                // [[b1,a1], [b2,a2], ...] for each axis
                for (i, padVal) in padArray.enumerated() {
                    if i >= arrayData.ndim { break }
                    if let pair = padVal.arrayValue, pair.count >= 2 {
                        padBefore[i] = pair[0].intValue ?? 0
                        padAfter[i] = pair[1].intValue ?? 0
                    }
                }
            }
        } else if let padTable = args[1].tableValue {
            // Handle table format
            var i = 1
            var axisIdx = 0
            while let pair = padTable[String(i)], axisIdx < arrayData.ndim {
                if let pairArray = pair.arrayValue, pairArray.count >= 2 {
                    padBefore[axisIdx] = pairArray[0].intValue ?? 0
                    padAfter[axisIdx] = pairArray[1].intValue ?? 0
                }
                i += 1
                axisIdx += 1
            }
        }

        // Get mode (default: "constant")
        let mode = args.count >= 3 ? (args[2].stringValue ?? "constant") : "constant"

        // Get constant value (default: 0)
        let constantValue = args.count >= 4 ? (args[3].numberValue ?? 0.0) : 0.0

        // Calculate result shape
        var resultShape = [Int]()
        for i in 0..<arrayData.ndim {
            resultShape.append(arrayData.shape[i] + padBefore[i] + padAfter[i])
        }

        let resultSize = resultShape.reduce(1, *)
        var resultData = [Double](repeating: constantValue, count: resultSize)

        // Calculate strides
        var srcStrides = [Int](repeating: 1, count: arrayData.ndim)
        for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
            srcStrides[i] = srcStrides[i + 1] * arrayData.shape[i + 1]
        }

        var dstStrides = [Int](repeating: 1, count: arrayData.ndim)
        for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
            dstStrides[i] = dstStrides[i + 1] * resultShape[i + 1]
        }

        // Copy source data to appropriate position
        if mode == "constant" {
            for srcIdx in 0..<arrayData.size {
                var remaining = srcIdx
                var srcCoords = [Int](repeating: 0, count: arrayData.ndim)
                for d in 0..<arrayData.ndim {
                    srcCoords[d] = remaining / srcStrides[d]
                    remaining = remaining % srcStrides[d]
                }

                // Offset by pad_before
                var dstIdx = 0
                for d in 0..<arrayData.ndim {
                    dstIdx += (srcCoords[d] + padBefore[d]) * dstStrides[d]
                }

                resultData[dstIdx] = arrayData.data[srcIdx]
            }
        } else if mode == "edge" {
            // Edge padding: extend edge values
            for dstIdx in 0..<resultSize {
                var remaining = dstIdx
                var dstCoords = [Int](repeating: 0, count: arrayData.ndim)
                for d in 0..<arrayData.ndim {
                    dstCoords[d] = remaining / dstStrides[d]
                    remaining = remaining % dstStrides[d]
                }

                // Clamp to source array bounds
                var srcIdx = 0
                for d in 0..<arrayData.ndim {
                    let srcCoord = max(0, min(arrayData.shape[d] - 1, dstCoords[d] - padBefore[d]))
                    srcIdx += srcCoord * srcStrides[d]
                }

                resultData[dstIdx] = arrayData.data[srcIdx]
            }
        } else if mode == "wrap" {
            // Wrap padding: circular wrap
            for dstIdx in 0..<resultSize {
                var remaining = dstIdx
                var dstCoords = [Int](repeating: 0, count: arrayData.ndim)
                for d in 0..<arrayData.ndim {
                    dstCoords[d] = remaining / dstStrides[d]
                    remaining = remaining % dstStrides[d]
                }

                var srcIdx = 0
                for d in 0..<arrayData.ndim {
                    let shifted = dstCoords[d] - padBefore[d]
                    let srcCoord = ((shifted % arrayData.shape[d]) + arrayData.shape[d]) % arrayData.shape[d]
                    srcIdx += srcCoord * srcStrides[d]
                }

                resultData[dstIdx] = arrayData.data[srcIdx]
            }
        } else if mode == "reflect" {
            // Reflect padding
            for dstIdx in 0..<resultSize {
                var remaining = dstIdx
                var dstCoords = [Int](repeating: 0, count: arrayData.ndim)
                for d in 0..<arrayData.ndim {
                    dstCoords[d] = remaining / dstStrides[d]
                    remaining = remaining % dstStrides[d]
                }

                var srcIdx = 0
                for d in 0..<arrayData.ndim {
                    var srcCoord = dstCoords[d] - padBefore[d]
                    let size = arrayData.shape[d]
                    if size > 1 {
                        // Reflect
                        let period = 2 * (size - 1)
                        srcCoord = ((srcCoord % period) + period) % period
                        if srcCoord >= size {
                            srcCoord = period - srcCoord
                        }
                    } else {
                        srcCoord = 0
                    }
                    srcIdx += srcCoord * srcStrides[d]
                }

                resultData[dstIdx] = arrayData.data[srcIdx]
            }
        }

        return createArrayTable(ArrayData(shape: resultShape, data: resultData))
    }

    /// insert: Insert values along the given axis before the given indices
    private static func insertCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("array.insert: requires array, indices, and values arguments")
        }

        let arrayData = try extractArrayData(args[0])

        // Parse indices
        var indices: [Int] = []
        if let singleIdx = args[1].intValue {
            indices = [singleIdx - 1]  // Convert to 0-based
        } else if let idxArray = args[1].arrayValue {
            indices = idxArray.compactMap { ($0.intValue ?? 0) - 1 }
        } else if let idxTable = args[1].tableValue {
            var i = 1
            while let idx = idxTable[String(i)]?.intValue {
                indices.append(idx - 1)
                i += 1
            }
        }

        // Parse values
        var values: [Double] = []
        if let singleVal = args[2].numberValue {
            values = [singleVal]
        } else if let valArray = args[2].arrayValue {
            values = valArray.compactMap { $0.numberValue }
        } else if let valTable = args[2].tableValue {
            // Could be array data
            if let _ = valTable["shape"], let _ = valTable["data"] {
                let valArrayData = try extractArrayData(args[2])
                values = valArrayData.data
            } else {
                var i = 1
                while let val = valTable[String(i)]?.numberValue {
                    values.append(val)
                    i += 1
                }
            }
        }

        guard !indices.isEmpty else {
            throw LuaError.callbackError("array.insert: indices must be non-empty")
        }

        // If axis specified
        if args.count >= 4 && args[3] != .nil {
            guard let axis = args[3].intValue else {
                throw LuaError.callbackError("array.insert: axis must be an integer")
            }
            let axis0 = axis - 1
            guard axis0 >= 0 && axis0 < arrayData.ndim else {
                throw LuaError.callbackError("array.insert: axis out of bounds")
            }

            // For multi-dimensional insert along axis
            let numInserts = indices.count
            var resultShape = arrayData.shape
            resultShape[axis0] += numInserts

            let resultSize = resultShape.reduce(1, *)
            var resultData = [Double](repeating: 0, count: resultSize)

            // Calculate strides
            var srcStrides = [Int](repeating: 1, count: arrayData.ndim)
            for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
                srcStrides[i] = srcStrides[i + 1] * arrayData.shape[i + 1]
            }

            var dstStrides = [Int](repeating: 1, count: arrayData.ndim)
            for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
                dstStrides[i] = dstStrides[i + 1] * resultShape[i + 1]
            }

            // Build mapping from source axis coord to dest axis coord
            let sortedIndices = indices.sorted()
            var srcToDst = [Int]()
            var dstCoord = 0
            var insertIdx = 0
            for srcCoord in 0..<arrayData.shape[axis0] {
                while insertIdx < sortedIndices.count && sortedIndices[insertIdx] <= srcCoord {
                    dstCoord += 1
                    insertIdx += 1
                }
                srcToDst.append(dstCoord)
                dstCoord += 1
            }

            // Copy source data with coordinate mapping
            for srcIdx in 0..<arrayData.size {
                var remaining = srcIdx
                var srcCoords = [Int](repeating: 0, count: arrayData.ndim)
                for d in 0..<arrayData.ndim {
                    srcCoords[d] = remaining / srcStrides[d]
                    remaining = remaining % srcStrides[d]
                }

                var dstCoords = srcCoords
                dstCoords[axis0] = srcToDst[srcCoords[axis0]]

                var dstFlatIdx = 0
                for d in 0..<arrayData.ndim {
                    dstFlatIdx += dstCoords[d] * dstStrides[d]
                }

                resultData[dstFlatIdx] = arrayData.data[srcIdx]
            }

            // Insert the values at the specified positions
            var insertCount = [Int: Int]()
            for idx in sortedIndices {
                insertCount[idx, default: 0] += 1
            }

            var totalOffset = 0
            for (idx, count) in insertCount.sorted(by: { $0.key < $1.key }) {
                for c in 0..<count {
                    let valIdx = totalOffset + c
                    let val = valIdx < values.count ? values[valIdx] : values.last ?? 0.0
                    let targetAxisCoord = idx + totalOffset + c

                    // Fill all positions at this axis coordinate
                    // Calculate number of elements in a slice orthogonal to axis
                    var sliceShape = resultShape
                    sliceShape.remove(at: axis0)
                    let sliceSize = sliceShape.isEmpty ? 1 : sliceShape.reduce(1, *)

                    for sliceIdx in 0..<sliceSize {
                        var coords = [Int](repeating: 0, count: arrayData.ndim)
                        var remaining = sliceIdx
                        var sliceD = 0
                        for d in 0..<arrayData.ndim {
                            if d == axis0 {
                                coords[d] = targetAxisCoord
                            } else {
                                if sliceD < sliceShape.count {
                                    coords[d] = remaining % sliceShape[sliceD]
                                    remaining /= sliceShape[sliceD]
                                    sliceD += 1
                                }
                            }
                        }

                        var flatIdx = 0
                        for d in 0..<arrayData.ndim {
                            flatIdx += coords[d] * dstStrides[d]
                        }

                        resultData[flatIdx] = val
                    }
                }
                totalOffset += count
            }

            return createArrayTable(ArrayData(shape: resultShape, data: resultData))
        } else {
            // No axis: flatten and insert
            var resultData = arrayData.data
            // Sort indices in ascending order and track offset
            for (offset, idx) in indices.sorted().enumerated() {
                let insertPos = min(max(0, idx + offset), resultData.count)
                let val = offset < values.count ? values[offset] : values.last ?? 0.0
                resultData.insert(val, at: insertPos)
            }
            return createArrayTable(ArrayData(shape: [resultData.count], data: resultData))
        }
    }

    /// delete: Return a new array with sub-arrays along an axis deleted
    private static func deleteCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.delete: requires array and indices arguments")
        }

        let arrayData = try extractArrayData(args[0])

        // Parse indices
        var indices: [Int] = []
        if let singleIdx = args[1].intValue {
            indices = [singleIdx - 1]  // Convert to 0-based
        } else if let idxArray = args[1].arrayValue {
            indices = idxArray.compactMap { ($0.intValue ?? 0) - 1 }
        } else if let idxTable = args[1].tableValue {
            var i = 1
            while let idx = idxTable[String(i)]?.intValue {
                indices.append(idx - 1)
                i += 1
            }
        }

        guard !indices.isEmpty else {
            throw LuaError.callbackError("array.delete: indices must be non-empty")
        }

        // If axis specified
        if args.count >= 3 && args[2] != .nil {
            guard let axis = args[2].intValue else {
                throw LuaError.callbackError("array.delete: axis must be an integer")
            }
            let axis0 = axis - 1
            guard axis0 >= 0 && axis0 < arrayData.ndim else {
                throw LuaError.callbackError("array.delete: axis out of bounds")
            }

            let deleteSet = Set(indices.map { $0 >= 0 ? $0 : arrayData.shape[axis0] + $0 })
            var resultShape = arrayData.shape
            resultShape[axis0] -= deleteSet.count

            guard resultShape[axis0] > 0 else {
                throw LuaError.callbackError("array.delete: cannot delete all elements along axis")
            }

            let resultSize = resultShape.reduce(1, *)
            var resultData = [Double](repeating: 0, count: resultSize)

            // Calculate strides
            var srcStrides = [Int](repeating: 1, count: arrayData.ndim)
            for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
                srcStrides[i] = srcStrides[i + 1] * arrayData.shape[i + 1]
            }

            var dstStrides = [Int](repeating: 1, count: arrayData.ndim)
            for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
                dstStrides[i] = dstStrides[i + 1] * resultShape[i + 1]
            }

            // Build mapping from source axis coord to dest axis coord
            var srcToDst = [Int?]()
            var dstCoord = 0
            for srcCoord in 0..<arrayData.shape[axis0] {
                if deleteSet.contains(srcCoord) {
                    srcToDst.append(nil)
                } else {
                    srcToDst.append(dstCoord)
                    dstCoord += 1
                }
            }

            // Copy data, skipping deleted indices
            for srcIdx in 0..<arrayData.size {
                var remaining = srcIdx
                var srcCoords = [Int](repeating: 0, count: arrayData.ndim)
                for d in 0..<arrayData.ndim {
                    srcCoords[d] = remaining / srcStrides[d]
                    remaining = remaining % srcStrides[d]
                }

                guard let mappedCoord = srcToDst[srcCoords[axis0]] else { continue }

                var dstCoords = srcCoords
                dstCoords[axis0] = mappedCoord

                var dstFlatIdx = 0
                for d in 0..<arrayData.ndim {
                    dstFlatIdx += dstCoords[d] * dstStrides[d]
                }

                resultData[dstFlatIdx] = arrayData.data[srcIdx]
            }

            return createArrayTable(ArrayData(shape: resultShape, data: resultData))
        } else {
            // No axis: flatten and delete
            let deleteSet = Set(indices.map { $0 >= 0 ? $0 : arrayData.size + $0 })
            var resultData = [Double]()
            for (i, val) in arrayData.data.enumerated() {
                if !deleteSet.contains(i) {
                    resultData.append(val)
                }
            }
            return createArrayTable(ArrayData(shape: [resultData.count], data: resultData))
        }
    }

    /// diff: Calculate the n-th discrete difference along the given axis
    private static func diffCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard !args.isEmpty else {
            throw LuaError.callbackError("array.diff: requires array argument")
        }

        let arrayData = try extractArrayData(args[0])

        // Get n (default 1)
        let n = args.count >= 2 ? (args[1].intValue ?? 1) : 1
        guard n >= 1 else {
            throw LuaError.callbackError("array.diff: n must be positive")
        }

        // Get axis (default: last axis, i.e., -1)
        var axis0: Int
        if args.count >= 3 && args[2] != .nil {
            guard let axis = args[2].intValue else {
                throw LuaError.callbackError("array.diff: axis must be an integer")
            }
            axis0 = axis - 1
        } else {
            axis0 = arrayData.ndim - 1  // Default to last axis
        }

        guard axis0 >= 0 && axis0 < arrayData.ndim else {
            throw LuaError.callbackError("array.diff: axis out of bounds")
        }

        guard arrayData.shape[axis0] > n else {
            throw LuaError.callbackError("array.diff: axis size must be greater than n")
        }

        // Apply n differences iteratively
        var currentData = arrayData.data
        var currentShape = arrayData.shape

        for _ in 0..<n {
            var newShape = currentShape
            newShape[axis0] -= 1

            let newSize = newShape.reduce(1, *)
            var newData = [Double](repeating: 0, count: newSize)

            // Calculate strides
            var srcStrides = [Int](repeating: 1, count: currentShape.count)
            for i in stride(from: currentShape.count - 2, through: 0, by: -1) {
                srcStrides[i] = srcStrides[i + 1] * currentShape[i + 1]
            }

            var dstStrides = [Int](repeating: 1, count: newShape.count)
            for i in stride(from: newShape.count - 2, through: 0, by: -1) {
                dstStrides[i] = dstStrides[i + 1] * newShape[i + 1]
            }

            // Compute differences
            for dstIdx in 0..<newSize {
                var remaining = dstIdx
                var dstCoords = [Int](repeating: 0, count: newShape.count)
                for d in 0..<newShape.count {
                    dstCoords[d] = remaining / dstStrides[d]
                    remaining = remaining % dstStrides[d]
                }

                // Get value at [i+1] - value at [i] along axis
                let srcCoordsLow = dstCoords
                var srcCoordsHigh = dstCoords
                srcCoordsHigh[axis0] += 1

                var srcIdxLow = 0
                var srcIdxHigh = 0
                for d in 0..<currentShape.count {
                    srcIdxLow += srcCoordsLow[d] * srcStrides[d]
                    srcIdxHigh += srcCoordsHigh[d] * srcStrides[d]
                }

                newData[dstIdx] = currentData[srcIdxHigh] - currentData[srcIdxLow]
            }

            currentData = newData
            currentShape = newShape
        }

        return createArrayTable(ArrayData(shape: currentShape, data: currentData))
    }

    // MARK: - Signal Processing (Phase 3.3)

    /// correlate: Cross-correlation of two 1D sequences
    /// Modes: "full" (default), "same", "valid"
    private static func correlateCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.correlate: requires two array arguments")
        }

        let aData = try extractArrayData(args[0])
        let vData = try extractArrayData(args[1])

        // Both must be 1D
        guard aData.ndim == 1 && vData.ndim == 1 else {
            throw LuaError.callbackError("array.correlate: both inputs must be 1D arrays")
        }

        let mode = args.count >= 3 ? (args[2].stringValue ?? "full") : "full"

        let a = aData.data
        let v = vData.data
        let n = a.count
        let m = v.count

        // Calculate output size based on mode
        let fullSize = n + m - 1
        let outputSize: Int
        let outputOffset: Int

        switch mode {
        case "full":
            outputSize = fullSize
            outputOffset = 0
        case "same":
            outputSize = max(n, m)
            outputOffset = (fullSize - outputSize) / 2
        case "valid":
            outputSize = max(0, max(n, m) - min(n, m) + 1)
            outputOffset = min(n, m) - 1
        default:
            throw LuaError.callbackError("array.correlate: mode must be 'full', 'same', or 'valid'")
        }

        // Compute full cross-correlation using vDSP if possible
        // For cross-correlation, we reverse v and compute convolution
        var vReversed = [Double](repeating: 0, count: m)
        for i in 0..<m {
            vReversed[i] = v[m - 1 - i]
        }

        // Pad 'a' with zeros for full convolution
        var aPadded = [Double](repeating: 0, count: n + 2 * (m - 1))
        for i in 0..<n {
            aPadded[i + m - 1] = a[i]
        }

        // Compute convolution using vDSP_conv
        var fullResult = [Double](repeating: 0, count: fullSize)
        vDSP_convD(aPadded, 1, vReversed, 1, &fullResult, 1, vDSP_Length(fullSize), vDSP_Length(m))

        // Extract the requested portion
        var result = [Double](repeating: 0, count: outputSize)
        for i in 0..<outputSize {
            result[i] = fullResult[outputOffset + i]
        }

        return createArrayTable(ArrayData(shape: [outputSize], data: result))
    }

    /// convolve: Discrete linear convolution of two 1D sequences
    /// Modes: "full" (default), "same", "valid"
    private static func convolveCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2 else {
            throw LuaError.callbackError("array.convolve: requires two array arguments")
        }

        let aData = try extractArrayData(args[0])
        let vData = try extractArrayData(args[1])

        // Both must be 1D
        guard aData.ndim == 1 && vData.ndim == 1 else {
            throw LuaError.callbackError("array.convolve: both inputs must be 1D arrays")
        }

        let mode = args.count >= 3 ? (args[2].stringValue ?? "full") : "full"

        let a = aData.data
        let v = vData.data
        let n = a.count
        let m = v.count

        // Calculate output size based on mode
        let fullSize = n + m - 1
        let outputSize: Int
        let outputOffset: Int

        switch mode {
        case "full":
            outputSize = fullSize
            outputOffset = 0
        case "same":
            outputSize = max(n, m)
            outputOffset = (fullSize - outputSize) / 2
        case "valid":
            outputSize = max(0, max(n, m) - min(n, m) + 1)
            outputOffset = min(n, m) - 1
        default:
            throw LuaError.callbackError("array.convolve: mode must be 'full', 'same', or 'valid'")
        }

        // Pad 'a' with zeros for full convolution
        var aPadded = [Double](repeating: 0, count: n + 2 * (m - 1))
        for i in 0..<n {
            aPadded[i + m - 1] = a[i]
        }

        // Use vDSP_conv for convolution (no reversal needed for standard convolution)
        // Actually vDSP_conv computes correlation, so we need to reverse v for convolution
        var vReversed = [Double](repeating: 0, count: m)
        for i in 0..<m {
            vReversed[i] = v[m - 1 - i]
        }

        var fullResult = [Double](repeating: 0, count: fullSize)
        vDSP_convD(aPadded, 1, vReversed, 1, &fullResult, 1, vDSP_Length(fullSize), vDSP_Length(m))

        // Extract the requested portion
        var result = [Double](repeating: 0, count: outputSize)
        for i in 0..<outputSize {
            result[i] = fullResult[outputOffset + i]
        }

        return createArrayTable(ArrayData(shape: [outputSize], data: result))
    }

    /// gradient: Return the gradient of an N-dimensional array
    /// Uses second-order central differences in the interior and first-order one-sides at boundaries
    private static func gradientCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard !args.isEmpty else {
            throw LuaError.callbackError("array.gradient: requires array argument")
        }

        let arrayData = try extractArrayData(args[0])

        // Get spacing (default 1.0)
        let spacing: Double
        if args.count >= 2 && args[1] != .nil {
            if let s = args[1].numberValue {
                spacing = s
            } else {
                spacing = 1.0
            }
        } else {
            spacing = 1.0
        }

        // Get axis (optional) - if not specified, compute gradient along all axes
        let specifiedAxis: Int?
        if args.count >= 3 && args[2] != .nil {
            if let a = args[2].intValue {
                specifiedAxis = a - 1  // Convert to 0-based
            } else {
                specifiedAxis = nil
            }
        } else {
            specifiedAxis = nil
        }

        // Helper function to compute gradient along a specific axis
        func computeGradientAlongAxis(_ axis0: Int) -> ArrayData {
            let axisSize = arrayData.shape[axis0]
            var resultData = [Double](repeating: 0, count: arrayData.size)

            // Calculate strides
            var strides = [Int](repeating: 1, count: arrayData.ndim)
            for i in stride(from: arrayData.ndim - 2, through: 0, by: -1) {
                strides[i] = strides[i + 1] * arrayData.shape[i + 1]
            }

            let axisStride = strides[axis0]

            for flatIdx in 0..<arrayData.size {
                // Convert flat index to coordinates
                var remaining = flatIdx
                var coords = [Int](repeating: 0, count: arrayData.ndim)
                for d in 0..<arrayData.ndim {
                    coords[d] = remaining / strides[d]
                    remaining = remaining % strides[d]
                }

                let i = coords[axis0]

                if axisSize == 1 {
                    // Can't compute gradient with only one point
                    resultData[flatIdx] = 0
                } else if i == 0 {
                    // Forward difference at left boundary
                    let nextIdx = flatIdx + axisStride
                    resultData[flatIdx] = (arrayData.data[nextIdx] - arrayData.data[flatIdx]) / spacing
                } else if i == axisSize - 1 {
                    // Backward difference at right boundary
                    let prevIdx = flatIdx - axisStride
                    resultData[flatIdx] = (arrayData.data[flatIdx] - arrayData.data[prevIdx]) / spacing
                } else {
                    // Central difference in interior
                    let prevIdx = flatIdx - axisStride
                    let nextIdx = flatIdx + axisStride
                    resultData[flatIdx] = (arrayData.data[nextIdx] - arrayData.data[prevIdx]) / (2 * spacing)
                }
            }

            return ArrayData(shape: arrayData.shape, data: resultData)
        }

        if let axis0 = specifiedAxis {
            // Single axis specified
            guard axis0 >= 0 && axis0 < arrayData.ndim else {
                throw LuaError.callbackError("array.gradient: axis out of bounds")
            }
            let gradData = computeGradientAlongAxis(axis0)
            return createArrayTable(gradData)
        } else {
            // Compute gradient along all axes and return as table of arrays
            if arrayData.ndim == 1 {
                // For 1D array, just return the gradient (not wrapped in table)
                let gradData = computeGradientAlongAxis(0)
                return createArrayTable(gradData)
            } else {
                // For N-D array, return table of gradients
                var results: [LuaValue] = []
                for axis0 in 0..<arrayData.ndim {
                    let gradData = computeGradientAlongAxis(axis0)
                    results.append(createArrayTable(gradData))
                }

                // Return as table with integer keys (1-indexed)
                var resultTable: [String: LuaValue] = [:]
                for (i, grad) in results.enumerated() {
                    resultTable[String(i + 1)] = grad
                }
                return .table(resultTable)
            }
        }
    }

    /// interp: 1D linear interpolation
    /// Returns interpolated values for the given x coordinates
    private static func interpCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 3 else {
            throw LuaError.callbackError("array.interp: requires x, xp, and fp arguments")
        }

        // x can be a scalar or array
        let xIsScalar: Bool
        let xValues: [Double]
        if let scalar = args[0].numberValue {
            xIsScalar = true
            xValues = [scalar]
        } else {
            xIsScalar = false
            let xData = try extractArrayData(args[0])
            xValues = xData.data
        }

        let xpData = try extractArrayData(args[1])
        let fpData = try extractArrayData(args[2])

        // xp and fp must be 1D and same length
        guard xpData.ndim == 1 && fpData.ndim == 1 else {
            throw LuaError.callbackError("array.interp: xp and fp must be 1D arrays")
        }
        guard xpData.size == fpData.size else {
            throw LuaError.callbackError("array.interp: xp and fp must have the same length")
        }
        guard xpData.size >= 1 else {
            throw LuaError.callbackError("array.interp: xp and fp must not be empty")
        }

        let xp = xpData.data
        let fp = fpData.data

        // Get left and right extrapolation values (default to boundary values)
        let leftVal: Double
        if args.count >= 4 && args[3] != .nil {
            leftVal = args[3].numberValue ?? fp[0]
        } else {
            leftVal = fp[0]
        }

        let rightVal: Double
        if args.count >= 5 && args[4] != .nil {
            rightVal = args[4].numberValue ?? fp[fp.count - 1]
        } else {
            rightVal = fp[fp.count - 1]
        }

        // Perform interpolation using binary search for efficiency
        var result = [Double](repeating: 0, count: xValues.count)

        for (i, x) in xValues.enumerated() {
            if x <= xp[0] {
                result[i] = leftVal
            } else if x >= xp[xp.count - 1] {
                result[i] = rightVal
            } else {
                // Binary search to find the right interval
                var lo = 0
                var hi = xp.count - 1
                while hi - lo > 1 {
                    let mid = (lo + hi) / 2
                    if xp[mid] <= x {
                        lo = mid
                    } else {
                        hi = mid
                    }
                }

                // Linear interpolation between xp[lo] and xp[hi]
                let t = (x - xp[lo]) / (xp[hi] - xp[lo])
                result[i] = fp[lo] + t * (fp[hi] - fp[lo])
            }
        }

        if xIsScalar {
            return .number(result[0])
        } else {
            return createArrayTable(ArrayData(shape: [result.count], data: result))
        }
    }
}
