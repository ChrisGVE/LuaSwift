//
//  DebugModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-05.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if DEBUG

import Foundation
import os.log

/// Swift-backed Debug module for LuaSwift.
///
/// Provides comprehensive debugging utilities for Lua scripts including logging,
/// console output, stack traces, and performance timing.
///
/// **IMPORTANT**: This module is only available in DEBUG builds. In release builds,
/// all debug functionality is completely excluded from the binary.
///
/// ## Lua API
///
/// ```lua
/// local debug = require("luaswift.debug")
///
/// -- Logging with levels
/// debug.log.debug("Debug message")
/// debug.log.info("Info message")
/// debug.log.warn("Warning message")
/// debug.log.error("Error message")
/// debug.log.setLevel("INFO")  -- Set minimum log level
///
/// -- Console output
/// debug.console.print("Hello", "World", 123)
/// debug.console.inspect({key = "value", nested = {a = 1}})
/// debug.console.trace()
/// debug.console.assert(x > 0, "x must be positive")
///
/// -- Performance timing
/// debug.console.time("operation")
/// -- ... some code ...
/// debug.console.timeEnd("operation")  -- Prints elapsed time
/// ```
public struct DebugModule {

    /// Current minimum log level
    private static var logLevel: LogLevel = .debug

    /// Performance timer storage
    private static var timers: [String: Date] = [:]

    /// Lock for thread-safe timer access
    private static let timerLock = NSLock()

    /// Log levels in order of severity
    private enum LogLevel: String, Comparable {
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
        case off = "OFF"

        var rank: Int {
            switch self {
            case .debug: return 0
            case .info: return 1
            case .warn: return 2
            case .error: return 3
            case .off: return 4
            }
        }

        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.rank < rhs.rank
        }

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warn: return .default
            case .error: return .error
            case .off: return .info
            }
        }
    }

    /// Register the Debug module with a LuaEngine.
    ///
    /// This creates a global table `luaswift` with a nested `debug` table containing
    /// logging and console debugging functions.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register log callbacks
        engine.registerFunction(name: "_luaswift_debug_log_debug", callback: logDebugCallback)
        engine.registerFunction(name: "_luaswift_debug_log_info", callback: logInfoCallback)
        engine.registerFunction(name: "_luaswift_debug_log_warn", callback: logWarnCallback)
        engine.registerFunction(name: "_luaswift_debug_log_error", callback: logErrorCallback)
        engine.registerFunction(name: "_luaswift_debug_log_setLevel", callback: setLogLevelCallback)

        // Register console callbacks
        engine.registerFunction(name: "_luaswift_debug_console_print", callback: consolePrintCallback)
        engine.registerFunction(name: "_luaswift_debug_console_inspect", callback: consoleInspectCallback)
        engine.registerFunction(name: "_luaswift_debug_console_trace", callback: consoleTraceCallback)
        engine.registerFunction(name: "_luaswift_debug_console_time", callback: consoleTimeCallback)
        engine.registerFunction(name: "_luaswift_debug_console_timeEnd", callback: consoleTimeEndCallback)
        engine.registerFunction(name: "_luaswift_debug_console_assert", callback: consoleAssertCallback)

        // Set up the luaswift.debug namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Store references to C functions before clearing globals
                local log_debug_fn = _luaswift_debug_log_debug
                local log_info_fn = _luaswift_debug_log_info
                local log_warn_fn = _luaswift_debug_log_warn
                local log_error_fn = _luaswift_debug_log_error
                local log_setLevel_fn = _luaswift_debug_log_setLevel
                local console_print_fn = _luaswift_debug_console_print
                local console_inspect_fn = _luaswift_debug_console_inspect
                local console_trace_fn = _luaswift_debug_console_trace
                local console_time_fn = _luaswift_debug_console_time
                local console_timeEnd_fn = _luaswift_debug_console_timeEnd
                local console_assert_fn = _luaswift_debug_console_assert

                luaswift.debug = {
                    log = {
                        debug = log_debug_fn,
                        info = log_info_fn,
                        warn = log_warn_fn,
                        error = log_error_fn,
                        setLevel = log_setLevel_fn
                    },
                    console = {
                        print = console_print_fn,
                        inspect = console_inspect_fn,
                        trace = console_trace_fn,
                        time = console_time_fn,
                        timeEnd = console_timeEnd_fn,
                        assert = console_assert_fn
                    }
                }

                -- Create top-level global alias (avoid conflict with Lua's debug table)
                debug_module = luaswift.debug

                -- Clean up global namespace
                _luaswift_debug_log_debug = nil
                _luaswift_debug_log_info = nil
                _luaswift_debug_log_warn = nil
                _luaswift_debug_log_error = nil
                _luaswift_debug_log_setLevel = nil
                _luaswift_debug_console_print = nil
                _luaswift_debug_console_inspect = nil
                _luaswift_debug_console_trace = nil
                _luaswift_debug_console_time = nil
                _luaswift_debug_console_timeEnd = nil
                _luaswift_debug_console_assert = nil
                """)
        } catch {
            // Silently fail if setup fails - callbacks are still registered
        }
    }

    // MARK: - Log Callbacks

    /// Log a debug message
    private static func logDebugCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let message = args.first?.stringValue else {
            throw LuaError.callbackError("log.debug requires a message argument")
        }

        logMessage(message, level: .debug)
        return .nil
    }

    /// Log an info message
    private static func logInfoCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let message = args.first?.stringValue else {
            throw LuaError.callbackError("log.info requires a message argument")
        }

        logMessage(message, level: .info)
        return .nil
    }

    /// Log a warning message
    private static func logWarnCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let message = args.first?.stringValue else {
            throw LuaError.callbackError("log.warn requires a message argument")
        }

        logMessage(message, level: .warn)
        return .nil
    }

    /// Log an error message
    private static func logErrorCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let message = args.first?.stringValue else {
            throw LuaError.callbackError("log.error requires a message argument")
        }

        logMessage(message, level: .error)
        return .nil
    }

    /// Set the minimum log level
    private static func setLogLevelCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let levelStr = args.first?.stringValue,
              let level = LogLevel(rawValue: levelStr.uppercased()) else {
            throw LuaError.callbackError("log.setLevel requires valid level: DEBUG, INFO, WARN, ERROR, or OFF")
        }

        logLevel = level
        return .nil
    }

    /// Internal log message handler
    private static func logMessage(_ message: String, level: LogLevel) {
        guard level >= logLevel else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formattedMessage = "[\(timestamp)] [\(level.rawValue)] \(message)"

        // Output to Swift print
        print(formattedMessage)

        // Also output to os_log for better integration with system logs
        if #available(macOS 11.0, iOS 14.0, *) {
            let logger = Logger(subsystem: "com.luaswift", category: "lua-script")
            logger.log(level: level.osLogType, "\(formattedMessage)")
        } else {
            os_log("%{public}@", log: OSLog(subsystem: "com.luaswift", category: "lua-script"), type: level.osLogType, formattedMessage)
        }
    }

    // MARK: - Console Callbacks

    /// Print formatted output
    private static func consolePrintCallback(_ args: [LuaValue]) throws -> LuaValue {
        let parts = args.map { valueToString($0) }
        print(parts.joined(separator: "\t"))
        return .nil
    }

    /// Deep inspection of a value
    private static func consoleInspectCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let value = args.first else {
            print("nil")
            return .nil
        }

        let inspected = inspectValue(value, depth: 0, maxDepth: 10)
        print(inspected)
        return .nil
    }

    /// Print stack trace
    private static func consoleTraceCallback(_ args: [LuaValue]) throws -> LuaValue {
        // Get Lua stack trace using debug.traceback
        // Since we're in Swift, we'll print a simple message
        print("Stack trace requested from Lua script")

        // Print Swift call stack
        let stackSymbols = Thread.callStackSymbols
        for (index, symbol) in stackSymbols.enumerated() {
            print("  \(index): \(symbol)")
        }

        return .nil
    }

    /// Start a performance timer
    private static func consoleTimeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let label = args.first?.stringValue else {
            throw LuaError.callbackError("console.time requires a label argument")
        }

        timerLock.lock()
        defer { timerLock.unlock() }

        timers[label] = Date()
        return .nil
    }

    /// End a performance timer and print elapsed time
    private static func consoleTimeEndCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let label = args.first?.stringValue else {
            throw LuaError.callbackError("console.timeEnd requires a label argument")
        }

        timerLock.lock()
        defer { timerLock.unlock() }

        guard let startTime = timers[label] else {
            print("Timer '\(label)' does not exist")
            return .nil
        }

        let elapsed = Date().timeIntervalSince(startTime)
        print("\(label): \(String(format: "%.3fms", elapsed * 1000))")

        timers.removeValue(forKey: label)
        return .nil
    }

    /// Assert a condition with optional message
    private static func consoleAssertCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let condition = args.first?.boolValue else {
            throw LuaError.callbackError("console.assert requires a boolean condition")
        }

        if !condition {
            let message = args.count > 1 ? args[1].stringValue ?? "Assertion failed" : "Assertion failed"
            print("Assertion failed: \(message)")

            // Print stack trace for assertion failures
            let stackSymbols = Thread.callStackSymbols
            for (index, symbol) in stackSymbols.enumerated() {
                print("  \(index): \(symbol)")
            }
        }

        return .nil
    }

    // MARK: - Helper Functions

    /// Convert a LuaValue to a readable string
    private static func valueToString(_ value: LuaValue) -> String {
        switch value {
        case .nil:
            return "nil"
        case .bool(let b):
            return b ? "true" : "false"
        case .number(let n):
            // Format number nicely
            if n.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", n)
            } else {
                return String(n)
            }
        case .string(let s):
            return s
        case .table(_):
            return "[table]"
        case .array(_):
            return "[array]"
        }
    }

    /// Deep inspection of a value
    private static func inspectValue(_ value: LuaValue, depth: Int, maxDepth: Int) -> String {
        let indent = String(repeating: "  ", count: depth)

        if depth >= maxDepth {
            return "\(indent)..."
        }

        switch value {
        case .nil:
            return "nil"
        case .bool(let b):
            return b ? "true" : "false"
        case .number(let n):
            if n.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", n)
            } else {
                return String(n)
            }
        case .string(let s):
            return "\"\(s)\""
        case .array(let arr):
            if arr.isEmpty {
                return "[]"
            }
            var lines = ["["]
            for (index, item) in arr.enumerated() {
                let itemStr = inspectValue(item, depth: depth + 1, maxDepth: maxDepth)
                lines.append("\(indent)  [\(index)] = \(itemStr)")
            }
            lines.append("\(indent)]")
            return lines.joined(separator: "\n")
        case .table(let dict):
            if dict.isEmpty {
                return "{}"
            }
            var lines = ["{"]
            for (key, val) in dict.sorted(by: { $0.key < $1.key }) {
                let valStr = inspectValue(val, depth: depth + 1, maxDepth: maxDepth)
                lines.append("\(indent)  \(key) = \(valStr)")
            }
            lines.append("\(indent)}")
            return lines.joined(separator: "\n")
        }
    }
}

#endif
