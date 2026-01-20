//
//  IOModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class IOModuleTests: XCTestCase {
    var engine: LuaEngine!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()

        // Create a temporary directory for testing
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("LuaSwiftIOTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Configure allowed directories and install module
        IOModule.setAllowedDirectories([tempDir.path], for: engine)
        ModuleRegistry.installIOModule(in: engine)
    }

    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDir)
        engine = nil
        super.tearDown()
    }

    // MARK: - Configuration Tests

    func testNoAllowedDirectoriesError() throws {
        let newEngine = try LuaEngine()
        ModuleRegistry.installIOModule(in: newEngine)

        XCTAssertThrowsError(try newEngine.run("""
            local iox = luaswift.iox
            iox.read_file("/some/path/file.txt")
        """)) { error in
            XCTAssertTrue(String(describing: error).contains("No directories are allowed"))
        }
    }

    func testAllowedDirectoriesConfiguration() throws {
        let dirs = IOModule.getAllowedDirectories(for: engine)
        XCTAssertEqual(dirs.count, 1)
        XCTAssertTrue(dirs[0].contains("LuaSwiftIOTests"))
    }

    // MARK: - Write and Read Tests

    func testWriteAndReadFile() throws {
        let filePath = tempDir.appendingPathComponent("test.txt").path

        try engine.run("""
            local iox = luaswift.iox
            iox.write_file("\(filePath)", "Hello, World!")
        """)

        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.read_file("\(filePath)")
        """)

        XCTAssertEqual(result.stringValue, "Hello, World!")
    }

    func testAppendFile() throws {
        let filePath = tempDir.appendingPathComponent("append.txt").path

        try engine.run("""
            local iox = luaswift.iox
            iox.write_file("\(filePath)", "Line 1\\n")
            iox.append_file("\(filePath)", "Line 2\\n")
        """)

        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.read_file("\(filePath)")
        """)

        XCTAssertEqual(result.stringValue, "Line 1\nLine 2\n")
    }

    func testReadNonexistentFile() throws {
        XCTAssertThrowsError(try engine.run("""
            local iox = luaswift.iox
            iox.read_file("\(tempDir.path)/nonexistent.txt")
        """)) { error in
            XCTAssertTrue(String(describing: error).contains("not found") || String(describing: error).contains("Not found"))
        }
    }

    // MARK: - Path Check Tests

    func testExists() throws {
        let filePath = tempDir.appendingPathComponent("exists.txt").path
        FileManager.default.createFile(atPath: filePath, contents: nil)

        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return {
                iox.exists("\(filePath)"),
                iox.exists("\(tempDir.path)/nonexistent.txt")
            }
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }
        XCTAssertEqual(arr[0].boolValue, true)
        XCTAssertEqual(arr[1].boolValue, false)
    }

    func testIsFile() throws {
        let filePath = tempDir.appendingPathComponent("file.txt").path
        FileManager.default.createFile(atPath: filePath, contents: nil)

        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return {
                iox.is_file("\(filePath)"),
                iox.is_file("\(tempDir.path)")
            }
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }
        XCTAssertEqual(arr[0].boolValue, true)
        XCTAssertEqual(arr[1].boolValue, false)
    }

    func testIsDir() throws {
        let subDir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        let filePath = tempDir.appendingPathComponent("file.txt").path
        FileManager.default.createFile(atPath: filePath, contents: nil)

        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return {
                iox.is_dir("\(subDir.path)"),
                iox.is_dir("\(filePath)")
            }
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }
        XCTAssertEqual(arr[0].boolValue, true)
        XCTAssertEqual(arr[1].boolValue, false)
    }

    // MARK: - Directory Operation Tests

    func testListDir() throws {
        // Create some files
        FileManager.default.createFile(atPath: tempDir.appendingPathComponent("a.txt").path, contents: nil)
        FileManager.default.createFile(atPath: tempDir.appendingPathComponent("b.txt").path, contents: nil)
        try FileManager.default.createDirectory(at: tempDir.appendingPathComponent("subdir"), withIntermediateDirectories: true)

        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.list_dir("\(tempDir.path)")
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }
        let names = arr.compactMap { $0.stringValue }
        XCTAssertTrue(names.contains("a.txt"))
        XCTAssertTrue(names.contains("b.txt"))
        XCTAssertTrue(names.contains("subdir"))
    }

    func testMkdir() throws {
        let newDir = tempDir.appendingPathComponent("newdir")

        try engine.run("""
            local iox = luaswift.iox
            iox.mkdir("\(newDir.path)")
        """)

        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: newDir.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    func testMkdirWithParents() throws {
        let deepDir = tempDir.appendingPathComponent("a/b/c")

        try engine.run("""
            local iox = luaswift.iox
            iox.mkdir("\(deepDir.path)", {parents = true})
        """)

        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: deepDir.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    func testRemove() throws {
        let filePath = tempDir.appendingPathComponent("toremove.txt")
        FileManager.default.createFile(atPath: filePath.path, contents: nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path))

        try engine.run("""
            local iox = luaswift.iox
            iox.remove("\(filePath.path)")
        """)

        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath.path))
    }

    func testRename() throws {
        let oldPath = tempDir.appendingPathComponent("old.txt")
        let newPath = tempDir.appendingPathComponent("new.txt")
        FileManager.default.createFile(atPath: oldPath.path, contents: "content".data(using: .utf8))

        try engine.run("""
            local iox = luaswift.iox
            iox.rename("\(oldPath.path)", "\(newPath.path)")
        """)

        XCTAssertFalse(FileManager.default.fileExists(atPath: oldPath.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: newPath.path))
    }

    // MARK: - Stat Tests

    func testStat() throws {
        let filePath = tempDir.appendingPathComponent("statfile.txt")
        try "test content".write(to: filePath, atomically: true, encoding: .utf8)

        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.stat("\(filePath.path)")
        """)

        guard let info = result.tableValue else {
            XCTFail("Expected table")
            return
        }
        XCTAssertEqual(info["is_file"]?.boolValue, true)
        XCTAssertEqual(info["is_dir"]?.boolValue, false)
        XCTAssertNotNil(info["size"]?.numberValue)
        XCTAssertNotNil(info["modified"]?.numberValue)
    }

    func testStatDir() throws {
        let subDir = tempDir.appendingPathComponent("statdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.stat("\(subDir.path)")
        """)

        guard let info = result.tableValue else {
            XCTFail("Expected table")
            return
        }
        XCTAssertEqual(info["is_file"]?.boolValue, false)
        XCTAssertEqual(info["is_dir"]?.boolValue, true)
    }

    // MARK: - Path Utility Tests

    func testPathJoin() throws {
        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.path.join("dir", "subdir", "file.txt")
        """)

        // path.join resolves relative to cwd, so check suffix
        XCTAssertTrue(result.stringValue?.hasSuffix("dir/subdir/file.txt") ?? false)
    }

    func testPathBasename() throws {
        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.path.basename("/path/to/file.txt")
        """)

        XCTAssertEqual(result.stringValue, "file.txt")
    }

    func testPathDirname() throws {
        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.path.dirname("/path/to/file.txt")
        """)

        XCTAssertEqual(result.stringValue, "/path/to")
    }

    func testPathExtension() throws {
        let result1 = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.path.extension("/path/to/file.txt")
        """)

        let result2 = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.path.extension("/path/to/file")
        """)

        XCTAssertEqual(result1.stringValue, "txt")
        XCTAssertTrue(result2 == .nil)
    }

    func testPathNormalize() throws {
        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.path.normalize("/path/../to/./file.txt")
        """)

        XCTAssertEqual(result.stringValue, "/to/file.txt")
    }

    // MARK: - Security Tests

    func testPathTraversalBlocked() throws {
        // Try to escape the allowed directory
        XCTAssertThrowsError(try engine.run("""
            local iox = luaswift.iox
            iox.read_file("\(tempDir.path)/../../../etc/passwd")
        """)) { error in
            let errorStr = String(describing: error)
            XCTAssertTrue(errorStr.contains("outside allowed") || errorStr.contains("Access denied") || errorStr.contains("not found"))
        }
    }

    func testAbsolutePathOutsideAllowed() throws {
        XCTAssertThrowsError(try engine.run("""
            local iox = luaswift.iox
            iox.read_file("/etc/passwd")
        """)) { error in
            let errorStr = String(describing: error)
            XCTAssertTrue(errorStr.contains("outside allowed") || errorStr.contains("Access denied"))
        }
    }

    func testExistsReturnsFalseForDisallowedPaths() throws {
        // exists() should return false for paths outside allowed directories (not throw)
        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.exists("/etc/passwd")
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    // MARK: - Require Tests

    func testRequireModule() throws {
        let result = try engine.evaluate("""
            local iox = require("luaswift.iox")
            return type(iox.read_file)
        """)

        XCTAssertEqual(result.stringValue, "function")
    }

    func testRequirePathSubmodule() throws {
        let result = try engine.evaluate("""
            local iox = require("luaswift.iox")
            return type(iox.path.join)
        """)

        XCTAssertEqual(result.stringValue, "function")
    }

    // MARK: - Symlink Escape Tests

    func testSymlinkEscapeBlocked() throws {
        // Create a directory outside the allowed directory
        let outsideDir = FileManager.default.temporaryDirectory.appendingPathComponent("LuaSwiftIOTests-outside-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outsideDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outsideDir) }

        // Create a secret file outside allowed directory
        let secretFile = outsideDir.appendingPathComponent("secret.txt")
        try "secret data".write(to: secretFile, atomically: true, encoding: .utf8)

        // Create a symlink inside the allowed directory pointing outside
        let symlink = tempDir.appendingPathComponent("escape_link")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: outsideDir)

        // Attempting to read via the symlink should fail
        XCTAssertThrowsError(try engine.run("""
            local iox = luaswift.iox
            iox.read_file("\(symlink.path)/secret.txt")
        """)) { error in
            let errorStr = String(describing: error)
            XCTAssertTrue(errorStr.contains("outside allowed") || errorStr.contains("Access denied"),
                          "Expected access denied error, got: \(errorStr)")
        }
    }

    func testSymlinkChainEscapeBlocked() throws {
        // Create directories for the chain
        let outsideDir = FileManager.default.temporaryDirectory.appendingPathComponent("LuaSwiftIOTests-outside2-\(UUID().uuidString)")
        let middleDir = tempDir.appendingPathComponent("middle")
        try FileManager.default.createDirectory(at: outsideDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: middleDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outsideDir) }

        // Create a secret file outside
        let secretFile = outsideDir.appendingPathComponent("secret.txt")
        try "secret".write(to: secretFile, atomically: true, encoding: .utf8)

        // Create a chain: allowed/link1 -> allowed/middle, allowed/middle/link2 -> outside
        let link2 = middleDir.appendingPathComponent("link2")
        try FileManager.default.createSymbolicLink(at: link2, withDestinationURL: outsideDir)

        // Accessing via the chain should fail
        XCTAssertThrowsError(try engine.run("""
            local iox = luaswift.iox
            iox.read_file("\(middleDir.path)/link2/secret.txt")
        """)) { error in
            let errorStr = String(describing: error)
            XCTAssertTrue(errorStr.contains("outside allowed") || errorStr.contains("Access denied"),
                          "Expected access denied error for symlink chain, got: \(errorStr)")
        }
    }

    func testExistsReturnsFalseForSymlinkEscape() throws {
        // Create outside directory and symlink
        let outsideDir = FileManager.default.temporaryDirectory.appendingPathComponent("LuaSwiftIOTests-outside3-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outsideDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outsideDir) }

        let secretFile = outsideDir.appendingPathComponent("secret.txt")
        try "secret".write(to: secretFile, atomically: true, encoding: .utf8)

        let symlink = tempDir.appendingPathComponent("escape_link2")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: outsideDir)

        // exists() should return false for symlink escape (not throw)
        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.exists("\(symlink.path)/secret.txt")
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testSymlinkWithinAllowedDirectoryWorks() throws {
        // Create a subdirectory and file
        let subdir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        let realFile = subdir.appendingPathComponent("real.txt")
        try "real content".write(to: realFile, atomically: true, encoding: .utf8)

        // Create a symlink within allowed directory pointing to another allowed location
        let symlink = tempDir.appendingPathComponent("internal_link")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: subdir)

        // This should work - symlink stays within allowed directory
        let result = try engine.evaluate("""
            local iox = luaswift.iox
            return iox.read_file("\(symlink.path)/real.txt")
        """)

        XCTAssertEqual(result.stringValue, "real content")
    }

    func testWriteViaSymlinkEscapeBlocked() throws {
        // Create outside directory
        let outsideDir = FileManager.default.temporaryDirectory.appendingPathComponent("LuaSwiftIOTests-outside4-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outsideDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outsideDir) }

        // Create symlink pointing outside
        let symlink = tempDir.appendingPathComponent("write_escape_link")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: outsideDir)

        // Attempting to write via the symlink should fail
        XCTAssertThrowsError(try engine.run("""
            local iox = luaswift.iox
            iox.write_file("\(symlink.path)/hacked.txt", "hacked!")
        """)) { error in
            let errorStr = String(describing: error)
            XCTAssertTrue(errorStr.contains("outside allowed") || errorStr.contains("Access denied"),
                          "Expected access denied error for write via symlink, got: \(errorStr)")
        }

        // Verify the file was NOT created outside
        let wouldBeFile = outsideDir.appendingPathComponent("hacked.txt")
        XCTAssertFalse(FileManager.default.fileExists(atPath: wouldBeFile.path),
                       "File should not have been created outside allowed directory")
    }
}
