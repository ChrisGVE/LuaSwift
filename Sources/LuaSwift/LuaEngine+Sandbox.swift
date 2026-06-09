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

// MARK: - Sandbox Lua Snippets

/// Lua that hardens a sandboxed engine, run once from ``LuaEngine/applySandbox(hasPackagePath:)``.
///
/// The multi-step hardening ensures: dangerous globals are removed;
/// `package.loaded` entries for restricted libraries are cleared so `require()`
/// cannot restore them; `package.loadlib` is disabled (no dynamic libraries, App
/// Store compliance); and `package.path`/`cpath` are cleared (the configured
/// path, if any, is set afterwards by ``LuaEngine/setPackagePath(_:)``). The
/// removed-function list is mirrored in ``LuaEngineConfiguration``'s sandboxing
/// documentation.
private let sandboxHardeningScript = """
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

    -- Remove warn (Lua 5.4+): combined with the wired warning handlers a
    -- sandboxed script could enable warnings then flood stderr. The
    -- guard makes this a no-op on 5.1-5.3 where warn does not exist.
    if warn ~= nil then warn = nil end

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

/// Lua that strips the file-based `require()` searchers, keeping only the
/// preload searcher. Run from ``LuaEngine/applySandbox(hasPackagePath:)`` ONLY
/// when no `packagePath` is configured — with a path set, the file searchers are
/// retained so modules can load from the explicitly allowed directory.
private let sandboxRemoveSearchersScript = """
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

extension LuaEngine {

    /// Remove dangerous functions and harden the package system.
    ///
    /// Applied during initialization when
    /// ``LuaEngineConfiguration/sandboxed`` is `true`.
    ///
    /// - Throws: ``LuaError/sandboxInstallationFailed(_:)`` if either hardening
    ///   snippet fails to run. Surfacing the failure is a security requirement:
    ///   a silent failure would leave dangerous globals live while the engine
    ///   still reports itself as sandboxed. This became reachable once a tight
    ///   ``LuaEngineConfiguration/vmMemoryLimit`` could make the sandbox Lua
    ///   fail to allocate.
    internal func applySandbox(hasPackagePath: Bool) throws {
        guard let L = L else { return }

        // Remove dangerous globals and harden the package system. A failure must
        // surface (see the throws doc) rather than leave a "sandboxed" engine
        // with live dangerous globals.
        if luaL_dostring(L, sandboxHardeningScript) != LUA_OK {
            throw LuaError.sandboxInstallationFailed(Self.takeError(L))
        }

        // Without a configured packagePath, also strip the file-based searchers
        // so require() cannot load from disk at all. With a path set, the
        // searchers stay (the path is applied later by setPackagePath).
        if !hasPackagePath {
            if luaL_dostring(L, sandboxRemoveSearchersScript) != LUA_OK {
                throw LuaError.sandboxInstallationFailed(Self.takeError(L))
            }
        }
    }

    /// Pop and return the error object left on the stack by a failed
    /// `luaL_dostring`. The value type is guarded before conversion (a failed
    /// chunk may leave a non-string error object) and exactly one slot is
    /// always popped so the stack is left balanced.
    private static func takeError(_ L: OpaquePointer) -> String {
        let message: String
        if lua_type(L, -1) == LUA_TSTRING, let cstr = lua_tostring(L, -1) {
            message = String(cString: cstr)
        } else {
            message = "Unknown error"
        }
        lua_pop(L, 1)
        return message
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
