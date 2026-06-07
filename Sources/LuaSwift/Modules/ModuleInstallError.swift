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
///
/// A non-empty ``failures`` list is an invariant: the public initializer
/// rejects an empty array (see ``init(failures:)``), so a `ModuleInstallError`
/// that names zero failures is unrepresentable.
public struct ModuleInstallError: Error, LocalizedError, Sendable, Equatable {
    /// One module's installation failure: the failed module's name paired
    /// with the error its setup raised.
    public struct Failure: Sendable {
        /// The name of the module that failed to install — its
        /// ``LuaSwiftModule/moduleName``.
        public let module: String

        /// The error raised by the module's `install(in:)` setup.
        public let underlyingError: Error

        public init(module: String, underlyingError: Error) {
            self.module = module
            self.underlyingError = underlyingError
        }
    }

    /// The modules that failed to install, in installation order. Guaranteed
    /// non-empty (enforced by ``init(failures:)``).
    public let failures: [Failure]

    /// Create an aggregate failure.
    ///
    /// - Parameter failures: The per-module failures, in installation order.
    /// - Precondition: `failures` must not be empty — an error that names no
    ///   failed module is meaningless, so the empty state is rejected here
    ///   rather than being silently representable.
    public init(failures: [Failure]) {
        precondition(!failures.isEmpty, "ModuleInstallError requires at least one failure")
        self.failures = failures
    }

    public var errorDescription: String? {
        let details = failures
            .map { "\($0.module): \($0.underlyingError.localizedDescription)" }
            .joined(separator: "; ")
        let plural = failures.count == 1 ? "module" : "modules"
        return "\(failures.count) \(plural) failed to install — \(details)"
    }

    /// Two errors are equal when they name the same failed modules in the same
    /// order.
    ///
    /// - Note: Comparison is on ``Failure/module`` names only. The underlying
    ///   `any Error` values are excluded because `Error` is not `Equatable`.
    public static func == (lhs: ModuleInstallError, rhs: ModuleInstallError) -> Bool {
        lhs.failures.map(\.module) == rhs.failures.map(\.module)
    }
}
