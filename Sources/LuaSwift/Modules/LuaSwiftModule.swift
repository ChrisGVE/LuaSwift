//
//  LuaSwiftModule.swift
//  Sources/LuaSwift/Modules
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Context: Common interface for the Swift-backed Lua modules that live in
//  Modules/Swift. Each module adopts this protocol; ModuleRegistry (sibling
//  file) drives installation of the whole module set and aggregates failures
//  into ModuleInstallError (see ModuleInstallError.swift).
//

/// A Swift-backed Lua module that can be installed into a ``LuaEngine``.
///
/// Conforming types expose their registration logic through ``install(in:)``,
/// which propagates Lua setup failures to the caller. The older
/// `register(in:)` entry points swallowed those failures and are deprecated.
public protocol LuaSwiftModule {
    /// A stable, human-readable identifier for the module.
    ///
    /// ``ModuleRegistry`` uses this name to drive installation and to label
    /// any failure it collects into ``ModuleInstallError``. By convention it
    /// is the conforming type's own name (for example, `"JSONModule"`), so the
    /// failure report matches the type a caller would reach for.
    static var moduleName: String { get }

    /// Install the module in the given engine, registering its Swift
    /// callbacks and running its Lua setup code.
    ///
    /// - Parameter engine: The Lua engine to install the module in.
    /// - Throws: An error if the module's Lua setup code fails to run.
    static func install(in engine: LuaEngine) throws
}
