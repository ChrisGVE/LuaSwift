//
//  IOModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed sandboxed IO module for LuaSwift.
///
/// Provides sandboxed file system operations restricted to allowed directories.
/// By default, no directories are allowed - you must explicitly configure them.
///
/// ## Lua API
///
/// ```lua
/// local iox = require("luaswift.iox")
///
/// -- File operations
/// local content = iox.read_file("/allowed/path/file.txt")
/// iox.write_file("/allowed/path/out.txt", "content")
/// iox.append_file("/allowed/path/log.txt", "line\n")
///
/// -- Path checks
/// if iox.exists("/allowed/path/file.txt") then ... end
/// if iox.is_file(path) then ... end
/// if iox.is_dir(path) then ... end
///
/// -- Directory operations
/// local files = iox.list_dir("/allowed/path")
/// iox.mkdir("/allowed/path/newdir")
/// iox.remove("/allowed/path/file.txt")
/// iox.rename("/allowed/path/old.txt", "/allowed/path/new.txt")
///
/// -- File info
/// local info = iox.stat("/allowed/path/file.txt")
/// -- info.size, info.is_file, info.is_dir, info.modified, info.created
///
/// -- Path utilities
/// local full = iox.path.join("dir", "subdir", "file.txt")
/// local name = iox.path.basename("/path/to/file.txt")  -- "file.txt"
/// local dir = iox.path.dirname("/path/to/file.txt")    -- "/path/to"
/// local ext = iox.path.extension("/path/to/file.txt")  -- "txt"
/// local abs = iox.path.absolute("relative/path")
/// local norm = iox.path.normalize("/path/../to/./file")
/// ```
///
/// ## Security
///
/// All file operations are restricted to directories configured via
/// `IOModule.setAllowedDirectories()`. Attempts to access paths outside
/// these directories will throw an error. Path traversal attacks (using ..)
/// are detected and blocked.
public struct IOModule {

    /// Allowed directories for file operations (thread-local per engine)
    private static let allowedDirectoriesKey = "LuaSwift.IOModule.AllowedDirectories"

    // MARK: - Configuration

    /// Set the allowed directories for file operations.
    ///
    /// Call this before running Lua code that uses the IO module.
    /// Paths are normalized and symlinks are resolved for security.
    ///
    /// - Parameters:
    ///   - directories: Array of directory paths to allow
    ///   - engine: The LuaEngine to configure
    public static func setAllowedDirectories(_ directories: [String], for engine: LuaEngine) {
        let normalized = directories.map { (path: String) -> String in
            let expanded = NSString(string: path).expandingTildeInPath
            // Resolve symlinks to get the actual filesystem path
            return URL(fileURLWithPath: expanded).standardizedFileURL.resolvingSymlinksInPath().path
        }
        // Store in engine's user info (we'll use object association)
        objc_setAssociatedObject(engine, &AssociatedKeys.allowedDirectories, normalized, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Get the allowed directories for an engine.
    public static func getAllowedDirectories(for engine: LuaEngine) -> [String] {
        return objc_getAssociatedObject(engine, &AssociatedKeys.allowedDirectories) as? [String] ?? []
    }

    // MARK: - Registration

    /// Register the IO module with a LuaEngine.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register file operation callbacks
        engine.registerFunction(name: "_luaswift_iox_read_file", callback: readFileCallback)
        engine.registerFunction(name: "_luaswift_iox_write_file", callback: writeFileCallback)
        engine.registerFunction(name: "_luaswift_iox_append_file", callback: appendFileCallback)
        engine.registerFunction(name: "_luaswift_iox_exists", callback: existsCallback)
        engine.registerFunction(name: "_luaswift_iox_is_file", callback: isFileCallback)
        engine.registerFunction(name: "_luaswift_iox_is_dir", callback: isDirCallback)
        engine.registerFunction(name: "_luaswift_iox_list_dir", callback: listDirCallback)
        engine.registerFunction(name: "_luaswift_iox_mkdir", callback: mkdirCallback)
        engine.registerFunction(name: "_luaswift_iox_remove", callback: removeCallback)
        engine.registerFunction(name: "_luaswift_iox_rename", callback: renameCallback)
        engine.registerFunction(name: "_luaswift_iox_stat", callback: statCallback)

        // Register path utility callbacks
        engine.registerFunction(name: "_luaswift_iox_path_join", callback: pathJoinCallback)
        engine.registerFunction(name: "_luaswift_iox_path_basename", callback: pathBasenameCallback)
        engine.registerFunction(name: "_luaswift_iox_path_dirname", callback: pathDirnameCallback)
        engine.registerFunction(name: "_luaswift_iox_path_extension", callback: pathExtensionCallback)
        engine.registerFunction(name: "_luaswift_iox_path_absolute", callback: pathAbsoluteCallback)
        engine.registerFunction(name: "_luaswift_iox_path_normalize", callback: pathNormalizeCallback)

        // Set up the luaswift.iox namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                luaswift.iox = {
                    -- File operations
                    read_file = _luaswift_iox_read_file,
                    write_file = _luaswift_iox_write_file,
                    append_file = _luaswift_iox_append_file,
                    exists = _luaswift_iox_exists,
                    is_file = _luaswift_iox_is_file,
                    is_dir = _luaswift_iox_is_dir,
                    list_dir = _luaswift_iox_list_dir,
                    mkdir = _luaswift_iox_mkdir,
                    remove = _luaswift_iox_remove,
                    rename = _luaswift_iox_rename,
                    stat = _luaswift_iox_stat,

                    -- Path utilities namespace
                    path = {
                        join = _luaswift_iox_path_join,
                        basename = _luaswift_iox_path_basename,
                        dirname = _luaswift_iox_path_dirname,
                        extension = _luaswift_iox_path_extension,
                        absolute = _luaswift_iox_path_absolute,
                        normalize = _luaswift_iox_path_normalize
                    }
                }

                -- Clean up temporary globals
                _luaswift_iox_read_file = nil
                _luaswift_iox_write_file = nil
                _luaswift_iox_append_file = nil
                _luaswift_iox_exists = nil
                _luaswift_iox_is_file = nil
                _luaswift_iox_is_dir = nil
                _luaswift_iox_list_dir = nil
                _luaswift_iox_mkdir = nil
                _luaswift_iox_remove = nil
                _luaswift_iox_rename = nil
                _luaswift_iox_stat = nil
                _luaswift_iox_path_join = nil
                _luaswift_iox_path_basename = nil
                _luaswift_iox_path_dirname = nil
                _luaswift_iox_path_extension = nil
                _luaswift_iox_path_absolute = nil
                _luaswift_iox_path_normalize = nil

                -- Register for require()
                package.loaded["luaswift.iox"] = luaswift.iox
                """)
        } catch {
            #if DEBUG
            print("[LuaSwift] IOModule setup failed: \(error)")
            #endif
        }
    }

    // MARK: - Path Validation

    /// Validate that a path is within allowed directories.
    ///
    /// This method resolves symlinks to prevent sandbox escape attacks where
    /// a symlink inside an allowed directory points to a location outside.
    ///
    /// For paths where the final component doesn't exist (e.g., writing a new file),
    /// we resolve the parent directory's symlinks and append the filename.
    ///
    /// - Parameters:
    ///   - path: The path to validate
    ///   - engine: The engine with allowed directories configured
    /// - Returns: The normalized absolute path with symlinks resolved
    /// - Throws: If the path is outside allowed directories
    private static func validatePath(_ path: String, engine: LuaEngine) throws -> String {
        let allowedDirs = getAllowedDirectories(for: engine)

        guard !allowedDirs.isEmpty else {
            throw IOError.accessDenied("No directories are allowed for IO operations. Configure with IOModule.setAllowedDirectories()")
        }

        // Normalize the path
        let expanded = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded).standardizedFileURL

        // Resolve symlinks. If the full path exists, resolve it directly.
        // If not, resolve the parent directory and append the last component.
        // This handles the case of writing to a new file via a symlink directory.
        let normalizedPath: String
        if FileManager.default.fileExists(atPath: url.path) {
            normalizedPath = url.resolvingSymlinksInPath().path
        } else {
            // File doesn't exist - resolve parent directory symlinks
            let parentURL = url.deletingLastPathComponent()
            let lastComponent = url.lastPathComponent
            let resolvedParent = parentURL.resolvingSymlinksInPath()
            normalizedPath = resolvedParent.appendingPathComponent(lastComponent).path
        }

        // Check if resolved path is within any allowed directory
        for allowedDir in allowedDirs {
            if normalizedPath.hasPrefix(allowedDir + "/") || normalizedPath == allowedDir {
                return normalizedPath
            }
        }

        throw IOError.accessDenied("Path '\(path)' is outside allowed directories")
    }

    /// Validate path for reading (must exist within allowed directories)
    private static func validateReadPath(_ path: String, engine: LuaEngine) throws -> String {
        let normalized = try validatePath(path, engine: engine)

        guard FileManager.default.fileExists(atPath: normalized) else {
            throw IOError.notFound("File not found: \(path)")
        }

        return normalized
    }

    // MARK: - File Operation Callbacks

    private static func readFileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.read_file requires a path string")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.read_file: no engine context")
        }

        let normalizedPath = try validateReadPath(path, engine: engine)

        do {
            let content = try String(contentsOfFile: normalizedPath, encoding: .utf8)
            return .string(content)
        } catch {
            throw LuaError.callbackError("iox.read_file error: \(error.localizedDescription)")
        }
    }

    private static func writeFileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let path = args[0].stringValue,
              let content = args[1].stringValue else {
            throw LuaError.callbackError("iox.write_file requires path and content strings")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.write_file: no engine context")
        }

        let normalizedPath = try validatePath(path, engine: engine)

        do {
            try content.write(toFile: normalizedPath, atomically: true, encoding: .utf8)
            return .bool(true)
        } catch {
            throw LuaError.callbackError("iox.write_file error: \(error.localizedDescription)")
        }
    }

    private static func appendFileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let path = args[0].stringValue,
              let content = args[1].stringValue else {
            throw LuaError.callbackError("iox.append_file requires path and content strings")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.append_file: no engine context")
        }

        let normalizedPath = try validatePath(path, engine: engine)

        do {
            if FileManager.default.fileExists(atPath: normalizedPath) {
                let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: normalizedPath))
                defer { try? handle.close() }
                try handle.seekToEnd()
                if let data = content.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
            } else {
                try content.write(toFile: normalizedPath, atomically: true, encoding: .utf8)
            }
            return .bool(true)
        } catch {
            throw LuaError.callbackError("iox.append_file error: \(error.localizedDescription)")
        }
    }

    private static func existsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.exists requires a path string")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.exists: no engine context")
        }

        do {
            let normalizedPath = try validatePath(path, engine: engine)
            return .bool(FileManager.default.fileExists(atPath: normalizedPath))
        } catch {
            // Path outside allowed directories - return false
            return .bool(false)
        }
    }

    private static func isFileCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.is_file requires a path string")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.is_file: no engine context")
        }

        do {
            let normalizedPath = try validatePath(path, engine: engine)
            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: normalizedPath, isDirectory: &isDir)
            return .bool(exists && !isDir.boolValue)
        } catch {
            return .bool(false)
        }
    }

    private static func isDirCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.is_dir requires a path string")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.is_dir: no engine context")
        }

        do {
            let normalizedPath = try validatePath(path, engine: engine)
            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: normalizedPath, isDirectory: &isDir)
            return .bool(exists && isDir.boolValue)
        } catch {
            return .bool(false)
        }
    }

    private static func listDirCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.list_dir requires a path string")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.list_dir: no engine context")
        }

        let normalizedPath = try validateReadPath(path, engine: engine)

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: normalizedPath)
            return .array(contents.map { .string($0) })
        } catch {
            throw LuaError.callbackError("iox.list_dir error: \(error.localizedDescription)")
        }
    }

    private static func mkdirCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.mkdir requires a path string")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.mkdir: no engine context")
        }

        let normalizedPath = try validatePath(path, engine: engine)

        // Check if parents option is set
        var createIntermediates = false
        if args.count > 1, let options = args[1].tableValue {
            createIntermediates = options["parents"]?.boolValue ?? false
        }

        do {
            try FileManager.default.createDirectory(atPath: normalizedPath, withIntermediateDirectories: createIntermediates, attributes: nil)
            return .bool(true)
        } catch {
            throw LuaError.callbackError("iox.mkdir error: \(error.localizedDescription)")
        }
    }

    private static func removeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.remove requires a path string")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.remove: no engine context")
        }

        let normalizedPath = try validatePath(path, engine: engine)

        do {
            try FileManager.default.removeItem(atPath: normalizedPath)
            return .bool(true)
        } catch {
            throw LuaError.callbackError("iox.remove error: \(error.localizedDescription)")
        }
    }

    private static func renameCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let oldPath = args[0].stringValue,
              let newPath = args[1].stringValue else {
            throw LuaError.callbackError("iox.rename requires old and new path strings")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.rename: no engine context")
        }

        let normalizedOld = try validateReadPath(oldPath, engine: engine)
        let normalizedNew = try validatePath(newPath, engine: engine)

        do {
            try FileManager.default.moveItem(atPath: normalizedOld, toPath: normalizedNew)
            return .bool(true)
        } catch {
            throw LuaError.callbackError("iox.rename error: \(error.localizedDescription)")
        }
    }

    private static func statCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.stat requires a path string")
        }

        guard let engine = LuaEngine.currentEngine else {
            throw LuaError.callbackError("iox.stat: no engine context")
        }

        let normalizedPath = try validateReadPath(path, engine: engine)

        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: normalizedPath)
            var result: [String: LuaValue] = [:]

            if let size = attrs[.size] as? Int {
                result["size"] = .number(Double(size))
            }

            if let type = attrs[.type] as? FileAttributeType {
                result["is_file"] = .bool(type == .typeRegular)
                result["is_dir"] = .bool(type == .typeDirectory)
                result["is_symlink"] = .bool(type == .typeSymbolicLink)
            }

            if let modified = attrs[.modificationDate] as? Date {
                result["modified"] = .number(modified.timeIntervalSince1970)
            }

            if let created = attrs[.creationDate] as? Date {
                result["created"] = .number(created.timeIntervalSince1970)
            }

            if let permissions = attrs[.posixPermissions] as? Int {
                result["permissions"] = .number(Double(permissions))
            }

            return .table(result)
        } catch {
            throw LuaError.callbackError("iox.stat error: \(error.localizedDescription)")
        }
    }

    // MARK: - Path Utility Callbacks

    private static func pathJoinCallback(_ args: [LuaValue]) throws -> LuaValue {
        let components = args.compactMap { $0.stringValue }
        guard !components.isEmpty else {
            throw LuaError.callbackError("iox.path.join requires at least one path component")
        }

        var url = URL(fileURLWithPath: components[0])
        for component in components.dropFirst() {
            url.appendPathComponent(component)
        }

        return .string(url.path)
    }

    private static func pathBasenameCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.path.basename requires a path string")
        }

        let url = URL(fileURLWithPath: path)
        return .string(url.lastPathComponent)
    }

    private static func pathDirnameCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.path.dirname requires a path string")
        }

        let url = URL(fileURLWithPath: path)
        return .string(url.deletingLastPathComponent().path)
    }

    private static func pathExtensionCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.path.extension requires a path string")
        }

        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension
        return ext.isEmpty ? .nil : .string(ext)
    }

    private static func pathAbsoluteCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.path.absolute requires a path string")
        }

        let expanded = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        return .string(url.standardizedFileURL.path)
    }

    private static func pathNormalizeCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard let path = args.first?.stringValue else {
            throw LuaError.callbackError("iox.path.normalize requires a path string")
        }

        let url = URL(fileURLWithPath: path)
        return .string(url.standardizedFileURL.path)
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var allowedDirectories: UInt8 = 0
}

// MARK: - Errors

private enum IOError: Error, LocalizedError {
    case accessDenied(String)
    case notFound(String)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied(let message):
            return "Access denied: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}
