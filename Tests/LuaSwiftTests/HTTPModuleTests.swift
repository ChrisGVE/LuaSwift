//
//  HTTPModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

final class HTTPModuleTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        ModuleRegistry.installHTTPModule(in: engine)
        ModuleRegistry.installJSONModule(in: engine)  // For json parsing in tests
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Module Registration Tests

    func testModuleRegistration() throws {
        let result = try engine.evaluate("""
            local http = luaswift.http
            return {
                type(http.get),
                type(http.post),
                type(http.put),
                type(http.patch),
                type(http.delete),
                type(http.head),
                type(http.options),
                type(http.request)
            }
        """)

        guard let arr = result.arrayValue else {
            XCTFail("Expected array")
            return
        }
        for (i, val) in arr.enumerated() {
            XCTAssertEqual(val.stringValue, "function", "Method \(i) should be a function")
        }
    }

    func testRequireModule() throws {
        let result = try engine.evaluate("""
            local http = require("luaswift.http")
            return type(http.get)
        """)

        XCTAssertEqual(result.stringValue, "function")
    }

    // MARK: - Error Handling Tests

    func testInvalidURL() throws {
        // Use URL with space in scheme - definitely invalid
        XCTAssertThrowsError(try engine.run("""
            local http = luaswift.http
            http.get("ht tp://example.com")
        """)) { error in
            XCTAssertTrue(String(describing: error).contains("Invalid URL"))
        }
    }

    func testMissingURL() throws {
        XCTAssertThrowsError(try engine.run("""
            local http = luaswift.http
            http.request("GET")
        """)) { error in
            XCTAssertTrue(String(describing: error).contains("requires"))
        }
    }

    // MARK: - Live HTTP Tests (requires network)
    // These tests make real network requests to httpbin.org

    func testSimpleGet() throws {
        // Skip if no network
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/get")
            return {resp.status, resp.ok, type(resp.body), type(resp.headers)}
        """)

        guard let arr = result.arrayValue, arr.count >= 4 else {
            XCTFail("Expected array with 4 elements")
            return
        }
        XCTAssertEqual(arr[0].numberValue, 200)
        XCTAssertEqual(arr[1].boolValue, true)
        XCTAssertEqual(arr[2].stringValue, "string")
        XCTAssertEqual(arr[3].stringValue, "table")
    }

    func testGetWithHeaders() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local json = luaswift.json
            local resp = http.get("https://httpbin.org/headers", {
                headers = {["X-Custom-Header"] = "test-value"}
            })
            local data = json.decode(resp.body)
            return data.headers["X-Custom-Header"]
        """)

        XCTAssertEqual(result.stringValue, "test-value")
    }

    func testPostWithBody() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local json = luaswift.json
            local resp = http.post("https://httpbin.org/post", {
                headers = {["Content-Type"] = "text/plain"},
                body = "Hello, World!"
            })
            local data = json.decode(resp.body)
            return data.data
        """)

        XCTAssertEqual(result.stringValue, "Hello, World!")
    }

    func testPostWithJSON() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local json = luaswift.json
            local resp = http.post("https://httpbin.org/post", {
                json = {name = "John", age = 30}
            })
            local data = json.decode(resp.body)
            local parsed = json.decode(data.data)
            return {parsed.name, parsed.age}
        """)

        guard let arr = result.arrayValue, arr.count >= 2 else {
            XCTFail("Expected array with 2 elements")
            return
        }
        XCTAssertEqual(arr[0].stringValue, "John")
        XCTAssertEqual(arr[1].numberValue, 30)
    }

    func testPutRequest() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local json = luaswift.json
            local resp = http.put("https://httpbin.org/put", {
                json = {updated = true}
            })
            local data = json.decode(resp.body)
            return data.json.updated
        """)

        XCTAssertEqual(result.boolValue, true)
    }

    func testDeleteRequest() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.delete("https://httpbin.org/delete")
            return resp.status
        """)

        XCTAssertEqual(result.numberValue, 200)
    }

    func testHeadRequest() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.head("https://httpbin.org/get")
            return {resp.status, resp.body}
        """)

        guard let arr = result.arrayValue, arr.count >= 2 else {
            XCTFail("Expected array with 2 elements")
            return
        }
        XCTAssertEqual(arr[0].numberValue, 200)
        // HEAD requests should have empty body
        XCTAssertTrue(arr[1].stringValue?.isEmpty ?? true)
    }

    func testStatusCode404() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/status/404")
            return {resp.status, resp.ok}
        """)

        guard let arr = result.arrayValue, arr.count >= 2 else {
            XCTFail("Expected array with 2 elements")
            return
        }
        XCTAssertEqual(arr[0].numberValue, 404)
        XCTAssertEqual(arr[1].boolValue, false)
    }

    func testResponseHeaders() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        // HTTP headers are case-insensitive, so check both possible casings
        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/response-headers?X-Test=hello")
            -- Check for header with various casings (HTTP headers are case-insensitive)
            return resp.headers["X-Test"] or resp.headers["x-test"] or resp.headers["X-test"]
        """)

        XCTAssertEqual(result.stringValue, "hello")
    }

    func testTimeout() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        XCTAssertThrowsError(try engine.run("""
            local http = luaswift.http
            -- httpbin.org/delay/10 delays for 10 seconds
            http.get("https://httpbin.org/delay/10", {timeout = 1})
        """)) { error in
            let errorStr = String(describing: error)
            XCTAssertTrue(errorStr.contains("timed out") || errorStr.contains("timeout") || errorStr.contains("cancelled"))
        }
    }

    // MARK: - Redirect Tests

    func testFollowRedirectsTrue() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/redirect/1", {
                follow_redirects = true
            })
            return {resp.status, resp.ok}
        """)

        guard let arr = result.arrayValue, arr.count >= 2 else {
            XCTFail("Expected array with 2 elements")
            return
        }
        XCTAssertEqual(arr[0].numberValue, 200, "Should follow redirect and get 200")
        XCTAssertEqual(arr[1].boolValue, true, "Response should be ok")
    }

    func testFollowRedirectsFalse() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/redirect/1", {
                follow_redirects = false
            })
            return {resp.status, resp.ok}
        """)

        guard let arr = result.arrayValue, arr.count >= 2 else {
            XCTFail("Expected array with 2 elements")
            return
        }
        XCTAssertEqual(arr[0].numberValue, 302, "Should not follow redirect and get 302")
        XCTAssertEqual(arr[1].boolValue, false, "Response should not be ok")
    }

    func testFollowRedirectsDefaultBehavior() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        // Default behavior should follow redirects
        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/redirect/1")
            return resp.status
        """)

        XCTAssertEqual(result.numberValue, 200, "Default should follow redirect")
    }

    func testFollowRedirectsChain() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        // Test that multiple redirects are followed
        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/redirect/3", {
                follow_redirects = true
            })
            return resp.status
        """)

        XCTAssertEqual(result.numberValue, 200, "Should follow redirect chain")
    }

    func testFollowRedirectsFalseReturnsLocationHeader() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/redirect/1", {
                follow_redirects = false
            })
            -- Check for Location header (case may vary)
            return resp.headers["Location"] or resp.headers["location"]
        """)

        XCTAssertNotNil(result.stringValue, "Should have Location header")
        // httpbin returns relative URL "/get" for redirect
        XCTAssertTrue(result.stringValue?.contains("/get") ?? false,
                      "Location header should point to redirect target, got: \(result.stringValue ?? "nil")")
    }

    // MARK: - Session Reuse Tests

    /// Test that multiple requests from the same engine reuse URLSession.
    /// This is a behavioral test - we can't directly verify session reuse,
    /// but we can verify that multiple concurrent requests work correctly.
    func testMultipleRequestsReuseSession() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        // Multiple requests should all succeed using reused session
        let result = try engine.evaluate("""
            local http = luaswift.http

            -- Make multiple requests sequentially
            local r1 = http.get("https://httpbin.org/get")
            local r2 = http.get("https://httpbin.org/headers")
            local r3 = http.get("https://httpbin.org/ip")

            return {
                r1_ok = r1.ok,
                r2_ok = r2.ok,
                r3_ok = r3.ok,
                r1_status = r1.status,
                r2_status = r2.status,
                r3_status = r3.status
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        XCTAssertEqual(table["r1_ok"]?.boolValue, true, "First request should succeed")
        XCTAssertEqual(table["r2_ok"]?.boolValue, true, "Second request should succeed")
        XCTAssertEqual(table["r3_ok"]?.boolValue, true, "Third request should succeed")
        XCTAssertEqual(table["r1_status"]?.numberValue, 200)
        XCTAssertEqual(table["r2_status"]?.numberValue, 200)
        XCTAssertEqual(table["r3_status"]?.numberValue, 200)
    }

    /// Test that requests with different redirect settings use appropriate sessions.
    func testMixedRedirectSettingsReuseCorrectSessions() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        let result = try engine.evaluate("""
            local http = luaswift.http

            -- Mix of following and not following redirects
            local r1 = http.get("https://httpbin.org/redirect/1", {follow_redirects = true})
            local r2 = http.get("https://httpbin.org/redirect/1", {follow_redirects = false})
            local r3 = http.get("https://httpbin.org/redirect/1", {follow_redirects = true})
            local r4 = http.get("https://httpbin.org/redirect/1", {follow_redirects = false})

            return {
                r1_status = r1.status,
                r2_status = r2.status,
                r3_status = r3.status,
                r4_status = r4.status
            }
        """)

        guard let table = result.tableValue else {
            XCTFail("Expected table result")
            return
        }

        // Requests with follow_redirects=true should return 200
        XCTAssertEqual(table["r1_status"]?.numberValue, 200, "Should follow redirect")
        XCTAssertEqual(table["r3_status"]?.numberValue, 200, "Should follow redirect")

        // Requests with follow_redirects=false should return 302
        XCTAssertEqual(table["r2_status"]?.numberValue, 302, "Should not follow redirect")
        XCTAssertEqual(table["r4_status"]?.numberValue, 302, "Should not follow redirect")
    }

    /// Test that different engines get separate sessions.
    func testDifferentEnginesHaveSeparateSessions() throws {
        guard hasNetworkAccess() else {
            throw XCTSkip("No network access")
        }

        // Create a second engine
        let engine2 = try LuaEngine()
        ModuleRegistry.installHTTPModule(in: engine2)

        // Both engines should be able to make requests independently
        let result1 = try engine.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/get")
            return resp.ok
        """)

        let result2 = try engine2.evaluate("""
            local http = luaswift.http
            local resp = http.get("https://httpbin.org/get")
            return resp.ok
        """)

        XCTAssertEqual(result1.boolValue, true, "First engine request should succeed")
        XCTAssertEqual(result2.boolValue, true, "Second engine request should succeed")
    }

    // MARK: - Helper Methods

    private func hasNetworkAccess() -> Bool {
        // Simple check - try to resolve a hostname
        let host = "httpbin.org"
        let hostRef = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
        var resolved = DarwinBoolean(false)
        CFHostStartInfoResolution(hostRef, .addresses, nil)
        CFHostGetAddressing(hostRef, &resolved)
        return resolved.boolValue
    }
}
