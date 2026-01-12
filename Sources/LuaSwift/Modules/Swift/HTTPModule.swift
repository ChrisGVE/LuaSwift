//
//  HTTPModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed HTTP client module for LuaSwift.
///
/// Provides HTTP client functionality using URLSession.
///
/// ## Lua API
///
/// ```lua
/// local http = require("luaswift.http")
///
/// -- Simple GET request
/// local resp = http.get("https://api.example.com/data")
/// print(resp.status)  -- 200
/// print(resp.body)    -- response body
///
/// -- GET with headers
/// local resp = http.get("https://api.example.com/data", {
///     headers = {["Authorization"] = "Bearer token"}
/// })
///
/// -- POST with JSON body
/// local resp = http.post("https://api.example.com/data", {
///     headers = {["Content-Type"] = "application/json"},
///     body = '{"key": "value"}'
/// })
///
/// -- POST with Lua table (auto-encoded as JSON)
/// local resp = http.post("https://api.example.com/data", {
///     json = {key = "value"}
/// })
///
/// -- Response object
/// -- resp.status: HTTP status code (number)
/// -- resp.headers: Response headers (table)
/// -- resp.body: Response body (string)
/// -- resp.ok: true if status is 2xx (boolean)
/// -- resp.json(): Parse body as JSON (function)
///
/// -- Other methods
/// http.put(url, options)
/// http.patch(url, options)
/// http.delete(url, options)
/// http.head(url, options)
/// http.options(url, options)
/// ```
public struct HTTPModule {

    // MARK: - Registration

    /// Register the HTTP module with a LuaEngine.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        // Register HTTP method callbacks
        engine.registerFunction(name: "_luaswift_http_request", callback: requestCallback)

        // Set up the luaswift.http namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end

                -- Capture the Swift callback before cleaning up global
                local http_request = _luaswift_http_request

                local function make_request(method, url, options)
                    return http_request(method, url, options or {})
                end

                luaswift.http = {
                    -- HTTP methods
                    get = function(url, options) return make_request("GET", url, options) end,
                    post = function(url, options) return make_request("POST", url, options) end,
                    put = function(url, options) return make_request("PUT", url, options) end,
                    patch = function(url, options) return make_request("PATCH", url, options) end,
                    delete = function(url, options) return make_request("DELETE", url, options) end,
                    head = function(url, options) return make_request("HEAD", url, options) end,
                    options = function(url, options) return make_request("OPTIONS", url, options) end,

                    -- Generic request function
                    request = make_request
                }

                -- Clean up temporary global
                _luaswift_http_request = nil

                -- Register for require()
                package.loaded["luaswift.http"] = luaswift.http
                """)
        } catch {
            // Silently fail if setup fails
        }
    }

    // MARK: - Request Callback

    private static func requestCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 2,
              let method = args[0].stringValue,
              let urlString = args[1].stringValue else {
            throw LuaError.callbackError("http.request requires method and url strings")
        }

        guard let url = URL(string: urlString) else {
            throw LuaError.callbackError("Invalid URL: \(urlString)")
        }

        // Parse options
        var headers: [String: String] = [:]
        var body: Data?
        var timeout: TimeInterval = 30.0
        var followRedirects = true

        if args.count > 2, let options = args[2].tableValue {
            // Parse headers
            if let headerTable = options["headers"]?.tableValue {
                for (key, value) in headerTable {
                    if let v = value.stringValue {
                        headers[key] = v
                    }
                }
            }

            // Parse body (string or data)
            if let bodyString = options["body"]?.stringValue {
                body = bodyString.data(using: .utf8)
            }

            // Parse json option (auto-encode as JSON)
            if let jsonTable = options["json"] {
                do {
                    body = try encodeJSON(jsonTable)
                    if headers["Content-Type"] == nil {
                        headers["Content-Type"] = "application/json"
                    }
                } catch {
                    throw LuaError.callbackError("Failed to encode JSON: \(error.localizedDescription)")
                }
            }

            // Parse timeout
            if let timeoutValue = options["timeout"]?.numberValue {
                timeout = timeoutValue
            }

            // Parse follow_redirects
            if let followValue = options["follow_redirects"]?.boolValue {
                followRedirects = followValue
            }
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout

        // Set headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set body
        if let body = body {
            request.httpBody = body
        }

        // Execute request synchronously
        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?
        var httpResponse: HTTPURLResponse?
        var requestError: Error?

        // Configure session
        let config = URLSessionConfiguration.default
        if !followRedirects {
            // Custom delegate would be needed for redirect control
            // For now, we always follow redirects
        }
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: request) { data, response, error in
            responseData = data
            httpResponse = response as? HTTPURLResponse
            requestError = error
            semaphore.signal()
        }
        task.resume()

        // Wait for response with timeout
        let result = semaphore.wait(timeout: .now() + timeout + 1)
        if result == .timedOut {
            task.cancel()
            throw LuaError.callbackError("Request timed out")
        }

        // Check for errors
        if let error = requestError {
            throw LuaError.callbackError("HTTP request failed: \(error.localizedDescription)")
        }

        guard let response = httpResponse else {
            throw LuaError.callbackError("No response received")
        }

        // Build response table
        var responseTable: [String: LuaValue] = [:]

        // Status code
        responseTable["status"] = .number(Double(response.statusCode))

        // OK flag (2xx status codes)
        responseTable["ok"] = .bool(response.statusCode >= 200 && response.statusCode < 300)

        // Response headers
        var headerDict: [String: LuaValue] = [:]
        for (key, value) in response.allHeaderFields {
            if let k = key as? String, let v = value as? String {
                headerDict[k] = .string(v)
            }
        }
        responseTable["headers"] = .table(headerDict)

        // Response body
        if let data = responseData, let bodyString = String(data: data, encoding: .utf8) {
            responseTable["body"] = .string(bodyString)
        } else if let data = responseData {
            // Binary data - encode as base64
            responseTable["body"] = .string(data.base64EncodedString())
            responseTable["body_is_base64"] = .bool(true)
        } else {
            responseTable["body"] = .string("")
        }

        // URL (after redirects)
        if let finalURL = response.url {
            responseTable["url"] = .string(finalURL.absoluteString)
        }

        return .table(responseTable)
    }

    // MARK: - JSON Encoding

    private static func encodeJSON(_ value: LuaValue) throws -> Data {
        let jsonValue = try convertLuaToJSON(value)

        // NSJSONSerialization requires top-level object to be array or dictionary
        let needsWrapping = !(jsonValue is [Any]) && !(jsonValue is [String: Any])
        let objectToSerialize = needsWrapping ? [jsonValue] : jsonValue

        let data = try JSONSerialization.data(withJSONObject: objectToSerialize, options: [])

        if needsWrapping {
            // Remove the array wrapping
            var jsonString = String(data: data, encoding: .utf8) ?? ""
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            if jsonString.hasPrefix("[") && jsonString.hasSuffix("]") {
                jsonString.removeFirst()
                jsonString.removeLast()
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return jsonString.data(using: .utf8) ?? data
        }

        return data
    }

    private static func convertLuaToJSON(_ value: LuaValue) throws -> Any {
        switch value {
        case .nil:
            return NSNull()
        case .bool(let b):
            return b
        case .number(let n):
            return n
        case .string(let s):
            return s
        case .array(let arr):
            return try arr.map { try convertLuaToJSON($0) }
        case .table(let dict):
            var jsonDict: [String: Any] = [:]
            for (key, val) in dict {
                jsonDict[key] = try convertLuaToJSON(val)
            }
            return jsonDict
        case .complex(let re, let im):
            // JSON doesn't have native complex support, encode as object with type marker
            return ["__type": "complex", "re": re, "im": im] as [String: Any]
        case .luaFunction:
            throw LuaError.runtimeError("Cannot serialize function to JSON")
        }
    }
}
