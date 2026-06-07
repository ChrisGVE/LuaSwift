//
//  ArrayModule+Phase2Wiring.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/Modules/Swift/ArrayModule+Phase2Wiring.swift
//
//  Context: Lua-side wiring of the Phase-2 array bindings. The
//  luaPhase2Wrapper source is run once by installPhase2
//  (ArrayModule+Phase2.swift) after the Swift callbacks
//  (ArrayModule+Phase2Callbacks.swift) are registered: it captures the
//  temporary `_luaswift_array_*` globals as locals, exposes them as
//  luaswift.array namespace functions and metatable methods, extends
//  zeros/ones/full with an optional dtype argument, and nils the
//  temporary globals out again.
//

#if LUASWIFT_ARRAYSWIFT

  import Foundation

  extension ArrayModule {

    // MARK: - Lua Wrapper

    /// internal: run by installPhase2 in ArrayModule+Phase2.swift
    internal static let luaPhase2Wrapper = """
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
