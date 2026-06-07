//
//  ModuleInstallError.swift
//  Sources/LuaSwift/Modules
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Context: Aggregate error thrown by ModuleRegistry.install(in:) (sibling
//  file) when one or more LuaSwiftModule installations fail. The registry
//  keeps installing the remaining modules and reports every failure here,
//  so a single broken module does not hide the state of the others.
//

import Foundation

/// Aggregate error describing the modules that failed during
/// ``ModuleRegistry/install(in:)``.
///
/// The registry installs every module in its set even when some fail, then
/// throws this error listing each failed module together with the underlying
/// error. Modules not listed in ``failures`` were installed successfully.
public struct ModuleInstallError: Error, LocalizedError {
    /// The modules that failed to install, in installation order, each
    /// paired with the error its setup raised.
    public let failures: [(module: String, error: Error)]

    public init(failures: [(module: String, error: Error)]) {
        self.failures = failures
    }

    public var errorDescription: String? {
        let details = failures
            .map { "\($0.module): \($0.error.localizedDescription)" }
            .joined(separator: "; ")
        let plural = failures.count == 1 ? "module" : "modules"
        return "\(failures.count) \(plural) failed to install — \(details)"
    }
}
