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

// MARK: - Validating package searcher

/// A module name is acceptable only when it is one or more `[A-Za-z0-9_]`
/// segments separated by single dots. This forbids path separators and `..`
/// traversal, so a confined searcher cannot be tricked into escaping its
/// directory via a crafted `require("../../etc/x")`.
private func isValidSandboxModuleName(_ name: String) -> Bool {
    guard !name.isEmpty else { return false }
    var segmentHasChar = false
    var lastWasDot = false
    for ch in name.unicodeScalars {
        if ch == "." {
            if !segmentHasChar { return false }  // leading dot or empty segment ("..")
            lastWasDot = true
            segmentHasChar = false
        } else if ch == "_" || (ch >= "0" && ch <= "9")
                    || (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z") {
            segmentHasChar = true
            lastWasDot = false
        } else {
            return false
        }
    }
    return !lastWasDot && segmentHasChar  // reject a trailing dot / empty final segment
}

/// `require` searcher installed under a sandbox that has a configured
/// `packagePath`.
///
/// It resolves modules ONLY within the frozen directory captured as upvalue 1
/// and **ignores `package.path` entirely**. That is what makes the confinement
/// robust: a script cannot redirect loading by reassigning `package.path` —
/// not via plain assignment, not via `rawset`, not after replacing the
/// `package` metatable — because no searcher consults `package.path` anymore.
/// Module names are validated (``isValidSandboxModuleName``) so they cannot
/// contain separators or `..`, and files are loaded text-only on 5.2+ so
/// untrusted bytecode cannot be loaded from disk. Returns `(loader, path)` on
/// success or a single explanatory string on failure, per the searcher
/// protocol.
private func sandboxPackageSearcher(_ L: OpaquePointer?) -> Int32 {
    guard let L = L else { return 0 }
    guard let nameC = lua_tostring(L, 1) else {
        lua_pushstring(L, "\n\t[sandbox] invalid module name")
        return 1
    }
    let name = String(cString: nameC)
    guard isValidSandboxModuleName(name) else {
        lua_pushstring(L, "\n\t[sandbox] module name '\(name)' is not permitted")
        return 1
    }
    guard let dirC = lua_tostring(L, lua_upvalueindex(1)) else {
        lua_pushstring(L, "\n\t[sandbox] package searcher misconfigured")
        return 1
    }
    let dir = String(cString: dirC)
    let rel = name.replacingOccurrences(of: ".", with: "/")
    let fullPath = "\(dir)/\(rel).lua"

    #if LUA_VERSION_51
    let status = luaL_loadfile(L, fullPath)
    #else
    let status = luaL_loadfilex(L, fullPath, "t")  // text-only: reject bytecode
    #endif
    if status == LUA_OK {
        lua_pushstring(L, fullPath)  // loader chunk (already on stack) + resolved path
        return 2
    }
    lua_pop(L, 1)  // discard the load-error object
    lua_pushstring(L, "\n\t[sandbox] no file '\(fullPath)'")
    return 1
}

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
    /// Apply the configured `packagePath`.
    ///
    /// `confine` is the engine's sandbox flag. When **false** (unsandboxed),
    /// this just sets `package.path` and leaves the default searchers intact, so
    /// normal `package.path` template semantics (multiple `;`-separated `?`
    /// patterns, runtime reassignment) keep working. When **true** (sandboxed),
    /// the configured path is treated as a single confined **directory**: the
    /// default file searchers are replaced by a validating searcher bound to
    /// that directory, so module loading cannot be redirected by mutating
    /// `package.path`.
    internal func setPackagePath(_ path: String, confine: Bool) {
        guard let L = L else { return }

        // Built via the C API rather than generated Lua source so the path is
        // treated as data: quotes or other Lua-meaningful characters in the
        // path cannot break or inject into a string literal (issue #16).
        lua_getglobal(L, "package")
        guard lua_istable(L, -1) else {
            // No package table (e.g. removed by the host): silently do
            // nothing, matching the previous luaL_dostring failure behavior
            lua_pop(L, 1)
            return
        }

        lua_pushstring(L, "\(path)/?.lua")
        lua_setfield(L, -2, "path")  // [package]

        // Unsandboxed: keep the default searchers and normal package.path
        // semantics (this is also the path used by hosts that pass a full
        // multi-entry package.path template, e.g. test harnesses).
        guard confine else {
            lua_pop(L, 1)  // package
            return
        }

        // Sandboxed: package.path is now set only for visibility/inspection
        // (the #16/#024 injection tests read it back); it is NO LONGER
        // authoritative. The validating searcher below resolves only within the
        // frozen directory and ignores package.path, so a script reassigning
        // package.path — by plain assignment, rawset, or after swapping the
        // package metatable — cannot redirect module loading outside the sandbox.

        // Fetch the searcher list (5.2+ "searchers", 5.1 "loaders").
        lua_getfield(L, -1, "searchers")  // [package, searchers?]
        if lua_istable(L, -1) == false {
            lua_pop(L, 1)
            lua_getfield(L, -1, "loaders")  // [package, loaders?]
        }
        guard lua_istable(L, -1) else {
            lua_pop(L, 2)  // (searchers? non-table) + package
            return
        }

        // Replace index 2 — the default `.lua` file searcher that reads the
        // mutable package.path — with the validating searcher (frozen dir as
        // upvalue), and drop every searcher beyond it (the C-library /
        // all-in-one searchers that consult package.path / package.cpath).
        // Index 1 (the preload searcher) is preserved.
        lua_pushstring(L, path)                          // [package, searchers, dir]
        lua_pushcclosure(L, sandboxPackageSearcher, 1)   // [package, searchers, closure]
        lua_rawseti(L, -2, 2)                            // searchers[2] = closure

        let count = lua_rawlen(L, -1)
        if count > 2 {
            for i in stride(from: count, to: 2, by: -1) {
                lua_pushnil(L)
                lua_rawseti(L, -2, lua_Integer(i))
            }
        }

        lua_pop(L, 2)  // searchers + package
    }
}
