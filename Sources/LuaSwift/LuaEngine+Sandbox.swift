//
//  LuaEngine+Sandbox.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Sandbox.swift
//
//  Context: Sandboxing concern of LuaEngine. Both methods are called
//  once from LuaEngine.init (LuaEngine.swift), driven by
//  LuaEngineConfiguration.sandboxed and .packagePath
//  (LuaEngineConfiguration.swift): applySandbox removes dangerous
//  globals and hardens require(), setPackagePath confines module
//  loading to the configured directory. The function list removed here
//  is documented on LuaEngineConfiguration's sandboxing section.
//

import Foundation
import CLua

extension LuaEngine {

    /// Remove dangerous functions and harden the package system.
    ///
    /// Applied during initialization when
    /// ``LuaEngineConfiguration/sandboxed`` is `true`.
    internal func applySandbox(hasPackagePath: Bool) {
        guard let L = L else { return }

        // Remove dangerous functions and harden package system
        // This multi-step approach ensures:
        // 1. Dangerous globals are removed
        // 2. package.loaded entries are cleared so require() can't restore them
        // 3. package.loadlib is disabled to prevent dynamic library loading
        // 4. If no packagePath configured, searchers are cleared to prevent disk loading
        //    If packagePath configured, searchers kept but path cleared (will be set later)
        let dangerous = """
            -- Remove dangerous globals
            os.execute = nil
            os.exit = nil
            os.remove = nil
            os.rename = nil
            os.tmpname = nil
            os.getenv = nil
            os.setlocale = nil
            io = nil
            debug = nil
            loadfile = nil
            dofile = nil
            load = nil
            loadstring = nil

            -- Clear package.loaded for restricted libraries to prevent require() bypass
            package.loaded.io = nil
            package.loaded.debug = nil
            -- Note: os is partially restricted, leave in loaded but with dangerous funcs removed

            -- Disable dynamic library loading (App Store compliance)
            package.loadlib = nil
            package.cpath = ''

            -- Clear package.path (will be set to configured path if packagePath provided)
            package.path = ''
        """

        luaL_dostring(L, dangerous)

        // If no packagePath is configured, also remove file-based searchers
        // This prevents any file loading via require()
        // If packagePath IS configured, keep searchers so files can be loaded from
        // the explicitly allowed directory
        if !hasPackagePath {
            let removeSearchers = """
                -- Clear file-based searchers, keeping only preload searcher
                -- Lua 5.2+ uses package.searchers, Lua 5.1 uses package.loaders
                local searchers = package.searchers or package.loaders
                if searchers then
                    -- Keep only the preload searcher (index 1), remove file searchers
                    for i = #searchers, 2, -1 do
                        searchers[i] = nil
                    end
                end
            """
            luaL_dostring(L, removeSearchers)
        }
    }

    /// Confine `require()` to the configured package directory.
    ///
    /// Applied during initialization when
    /// ``LuaEngineConfiguration/packagePath`` is set.
    internal func setPackagePath(_ path: String) {
        guard let L = L else { return }

        // Set package.path to the specified path only (don't append to existing)
        // This is intentional: in sandboxed mode, we've cleared package.path
        // and only want to allow loading from explicitly specified directories
        //
        // Built via the C API rather than generated Lua source so the path is
        // treated as data: quotes or other Lua-meaningful characters in the
        // path cannot break or inject into a string literal (issue #16)
        lua_getglobal(L, "package")
        guard lua_istable(L, -1) else {
            // No package table (e.g. removed by the host): silently do
            // nothing, matching the previous luaL_dostring failure behavior
            lua_pop(L, 1)
            return
        }
        lua_pushstring(L, "\(path)/?.lua")
        lua_setfield(L, -2, "path")
        lua_pop(L, 1)
    }
}
