//
//  LuaError.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Errors that can occur during Lua execution.
public enum LuaError: Error, LocalizedError {
    /// Failed to create the Lua state
    case initializationFailed

    /// Lua syntax error during parsing
    case syntaxError(String)

    /// Runtime error during execution
    case runtimeError(String)

    /// Memory allocation error
    case memoryError(String)

    /// Error in error handler
    case errorHandlerError(String)

    /// Type conversion error
    case typeError(expected: String, actual: String)

    /// Value server path resolution error
    case pathResolutionError(path: String)

    /// Attempted to use a prohibited function
    case prohibitedFunction(name: String)

    /// Unknown error
    case unknown(code: Int, message: String?)

    public var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize Lua state"
        case .syntaxError(let message):
            return "Lua syntax error: \(message)"
        case .runtimeError(let message):
            return "Lua runtime error: \(message)"
        case .memoryError(let message):
            return "Lua memory error: \(message)"
        case .errorHandlerError(let message):
            return "Lua error handler error: \(message)"
        case .typeError(let expected, let actual):
            return "Type error: expected \(expected), got \(actual)"
        case .pathResolutionError(let path):
            return "Failed to resolve path: \(path)"
        case .prohibitedFunction(let name):
            return "Attempted to use prohibited function: \(name)"
        case .unknown(let code, let message):
            if let message = message {
                return "Lua error (code \(code)): \(message)"
            }
            return "Unknown Lua error (code \(code))"
        }
    }
}
