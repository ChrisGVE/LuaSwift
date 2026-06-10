//
//  MockHTTPServer.swift
//  LuaSwiftTests
//
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  An in-process, httpbin-compatible HTTP/1.1 server used by HTTPModuleTests.
//
//  Rationale: the HTTP client tests previously hit live third-party hosts
//  (httpbin.org and fallbacks). Those hosts rate-limit and return 503/time out,
//  which made the suite flaky and non-deterministic. This server reimplements
//  exactly the httpbin endpoints the tests exercise, bound to 127.0.0.1 on an
//  ephemeral port, so the tests are hermetic and always green without ignoring
//  or skipping anything.
//
//  Endpoints implemented (faithful to httpbin.org semantics where the tests
//  depend on them): /get, /ip, /headers, /post, /put, /patch, /delete,
//  /status/{code}, /response-headers, /redirect/{n}, /delay/{n}.

import Foundation
import Network

/// Minimal httpbin-compatible HTTP/1.1 server backed by Network.framework.
///
/// One request per connection (responses set `Connection: close`); this keeps
/// the wire parsing simple while remaining fully compatible with URLSession,
/// which transparently opens new connections as needed.
final class MockHTTPServer {

    /// `http://127.0.0.1:<port>` once the server is listening.
    private(set) var baseURL: String = ""

    private let listener: NWListener
    private let queue = DispatchQueue(label: "MockHTTPServer", attributes: .concurrent)
    private let started = DispatchSemaphore(value: 0)

    /// Hard cap on accumulated request bytes. The tests never send bodies near
    /// this size; the cap exists purely to bound memory if a misbehaving (or
    /// malicious-on-loopback) client streams an oversized request or lies about
    /// `Content-Length`. Connections exceeding it are dropped.
    private static let maxRequestBytes = 8 * 1024 * 1024

    init() throws {
        let params = NWParameters.tcp
        // Loopback only. Note: on a real iOS device the loopback interface is
        // not generally available to third-party apps, so NWListener would fail
        // here and the static `mockServer` in HTTPModuleTests becomes nil,
        // surfacing as a test failure (not a silent skip). The HTTP suite is
        // therefore expected to run on macOS / the iOS Simulator.
        params.requiredInterfaceType = .loopback
        listener = try NWListener(using: params)

        listener.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                if let port = self.listener.port {
                    self.baseURL = "http://127.0.0.1:\(port.rawValue)"
                }
                self.started.signal()
            case .failed:
                self.started.signal()
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }

        listener.start(queue: queue)
        // Wait until the listener is ready (or failed) so baseURL is populated.
        _ = started.wait(timeout: .now() + 5)
    }

    deinit {
        listener.cancel()
    }

    // MARK: - Connection handling

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(connection, buffer: Data())
    }

    /// Accumulate bytes until a full request (headers + any declared body) is
    /// available, then route it.
    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) {
            [weak self] data, _, isComplete, error in
            guard let self = self else { return }

            var accumulated = buffer
            if let data = data { accumulated.append(data) }

            if let request = HTTPRequest(parsing: accumulated) {
                self.route(request, on: connection)
                return
            }

            if error != nil || isComplete || accumulated.count > Self.maxRequestBytes {
                connection.cancel()
                return
            }

            // Need more bytes.
            self.receive(connection, buffer: accumulated)
        }
    }

    // MARK: - Routing

    private func route(_ request: HTTPRequest, on connection: NWConnection) {
        let path = request.path
        let components = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)

        // /status/{code}
        if components.count == 2, components[0] == "status", let code = Int(components[1]) {
            send(HTTPResponse(status: code, body: Data()), method: request.method, on: connection)
            return
        }

        // /redirect/{n}
        if components.count == 2, components[0] == "redirect", let n = Int(components[1]) {
            let location = n > 1 ? "/redirect/\(n - 1)" : "/get"
            var resp = HTTPResponse(status: 302, body: Data())
            resp.headers["Location"] = location
            send(resp, method: request.method, on: connection)
            return
        }

        // /bytes/{n} — respond with exactly n bytes of body (size-cap tests).
        if components.count == 2, components[0] == "bytes", let n = Int(components[1]) {
            let body = Data(repeating: UInt8(ascii: "x"), count: max(0, n))
            send(HTTPResponse(status: 200, body: body), method: request.method, on: connection)
            return
        }

        // /delay/{n} — respond after n seconds (tests use this to force a timeout).
        if components.count == 2, components[0] == "delay", let n = Double(components[1]) {
            let body = self.jsonBody(["url": request.absoluteURL(base: baseURL)])
            queue.asyncAfter(deadline: .now() + n) { [weak self] in
                guard let self = self else { return }
                self.send(HTTPResponse(status: 200, body: body), method: request.method, on: connection)
            }
            return
        }

        switch components.first {
        case "get", "ip", "headers":
            send(HTTPResponse(status: 200, body: infoBody(for: request)),
                 method: request.method, on: connection)

        case "post", "put", "patch", "delete":
            send(HTTPResponse(status: 200, body: infoBody(for: request, includeData: true)),
                 method: request.method, on: connection)

        case "response-headers":
            var resp = HTTPResponse(status: 200, body: Data())
            var echoed: [String: Any] = [:]
            for (key, value) in request.queryItems {
                resp.headers[key] = value
                echoed[key] = value
            }
            resp.body = jsonBody(echoed)
            send(resp, method: request.method, on: connection)

        default:
            send(HTTPResponse(status: 404, body: Data()), method: request.method, on: connection)
        }
    }

    // MARK: - httpbin-style response bodies

    /// Build an httpbin-style JSON body. `includeData` adds the `data`/`json`
    /// fields populated from the request body (as /post, /put etc. do).
    private func infoBody(for request: HTTPRequest, includeData: Bool = false) -> Data {
        var object: [String: Any] = [
            "url": request.absoluteURL(base: baseURL),
            "headers": request.headers,           // already title-cased like httpbin
            "args": request.queryItems,
            "origin": "127.0.0.1",
        ]

        if includeData {
            let bodyString = String(data: request.body, encoding: .utf8) ?? ""
            object["data"] = bodyString
            if let parsed = try? JSONSerialization.jsonObject(with: request.body, options: [.fragmentsAllowed]) {
                object["json"] = parsed
            } else {
                object["json"] = NSNull()
            }
        }

        return jsonBody(object)
    }

    private func jsonBody(_ object: Any) -> Data {
        (try? JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed])) ?? Data("{}".utf8)
    }

    // MARK: - Sending

    private func send(_ response: HTTPResponse, method: String, on connection: NWConnection) {
        let isHead = method.uppercased() == "HEAD"
        let data = response.serialized(includeBody: !isHead)
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

// MARK: - Request parsing

private struct HTTPRequest {
    let method: String
    let target: String          // raw request target, may include query
    let path: String            // path component, percent-decoded
    let queryItems: [String: String]
    let headers: [String: String]   // title-cased keys, httpbin-style
    let body: Data

    /// Parse a complete request from `data`, or return nil if more bytes are
    /// needed (incomplete header block, or body shorter than Content-Length).
    init?(parsing data: Data) {
        // Locate end of header block.
        let crlfcrlf = Data("\r\n\r\n".utf8)
        guard let headerEnd = data.range(of: crlfcrlf) else { return nil }

        let headerData = data.subdata(in: data.startIndex..<headerEnd.lowerBound)
        guard let headerText = String(data: headerData, encoding: .utf8) else { return nil }

        var lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        lines.removeFirst()

        let requestParts = requestLine.split(separator: " ")
        guard requestParts.count >= 2 else { return nil }
        method = String(requestParts[0])
        target = String(requestParts[1])

        // Split target into path + query.
        var parsedQuery: [String: String] = [:]
        let pathAndQuery = target.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let rawPath = String(pathAndQuery[0])
        path = rawPath.removingPercentEncoding ?? rawPath
        if pathAndQuery.count == 2 {
            for pair in pathAndQuery[1].split(separator: "&") {
                let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                let key = String(kv[0]).removingPercentEncoding ?? String(kv[0])
                let value = kv.count == 2 ? (String(kv[1]).removingPercentEncoding ?? String(kv[1])) : ""
                parsedQuery[key] = value
            }
        }
        queryItems = parsedQuery

        // Parse headers (title-cased to mirror httpbin).
        var parsedHeaders: [String: String] = [:]
        var contentLength = 0
        for line in lines where !line.isEmpty {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let rawName = String(line[line.startIndex..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            let name = HTTPRequest.titleCase(rawName)
            parsedHeaders[name] = value
            if name == "Content-Length", let len = Int(value) {
                contentLength = len
            }
        }
        headers = parsedHeaders

        // Body: must have contentLength bytes after the header terminator.
        let bodyStart = headerEnd.upperBound
        let available = data.distance(from: bodyStart, to: data.endIndex)
        if available < contentLength { return nil }     // wait for more
        body = data.subdata(in: bodyStart..<data.index(bodyStart, offsetBy: contentLength))
    }

    func absoluteURL(base: String) -> String {
        base + target
    }

    /// httpbin canonicalises header names to Title-Case (e.g. `X-Custom-Header`).
    static func titleCase(_ name: String) -> String {
        name.split(separator: "-", omittingEmptySubsequences: false).map { part -> String in
            guard let first = part.first else { return String(part) }
            return first.uppercased() + part.dropFirst().lowercased()
        }.joined(separator: "-")
    }
}

// MARK: - Response serialisation

private struct HTTPResponse {
    var status: Int
    var headers: [String: String] = [:]
    var body: Data

    init(status: Int, body: Data) {
        self.status = status
        self.body = body
    }

    func serialized(includeBody: Bool) -> Data {
        var head = "HTTP/1.1 \(status) \(HTTPResponse.reason(status))\r\n"
        var allHeaders = headers
        // Default content type for our JSON bodies; harmless for empty bodies.
        if allHeaders["Content-Type"] == nil {
            allHeaders["Content-Type"] = "application/json"
        }
        allHeaders["Content-Length"] = String(body.count)
        allHeaders["Connection"] = "close"
        for (key, value) in allHeaders {
            head += "\(key): \(value)\r\n"
        }
        head += "\r\n"

        var data = Data(head.utf8)
        if includeBody {
            data.append(body)
        }
        return data
    }

    static func reason(_ status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 201: return "Created"
        case 202: return "Accepted"
        case 204: return "No Content"
        case 301: return "Moved Permanently"
        case 302: return "Found"
        case 304: return "Not Modified"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 418: return "I'm a teapot"
        case 429: return "Too Many Requests"
        case 500: return "Internal Server Error"
        case 502: return "Bad Gateway"
        case 503: return "Service Unavailable"
        case 504: return "Gateway Timeout"
        default:
            // Generic class-based phrase keeps the status line a valid token
            // for any code httpbin's /status/{code} might be asked to emit.
            switch status / 100 {
            case 1: return "Informational"
            case 2: return "Success"
            case 3: return "Redirection"
            case 4: return "Client Error"
            case 5: return "Server Error"
            default: return "Unknown"
            }
        }
    }
}
