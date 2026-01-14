//
//  Requests.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/3.
//

import Foundation
import SwiftyJSON

public protocol URLConvertible {
    var url: URL? { get }
}

extension URL: URLConvertible {
    public var url: URL? { self }
}

extension String: URLConvertible {
    public var url: URL? { URL(string: self) }
}

/// HTTP 请求工具类。
public enum Requests {
    public enum EncodeMethod {
        case json
        case urlEncoded
    }
    
    public class Response {
        public let statusCode: Int
        public let headers: [String: String]
        public let data: Data
        
        fileprivate init(data: Data, response: HTTPURLResponse, isCached: Bool = false) {
            self.statusCode = response.statusCode
            self.headers = Self.parseHeaders(response.allHeaderFields)
            self.data = data
        }
        
        public func json() throws -> JSON {
            return try JSON(data: data)
        }
        
        public func decode<T: Decodable>(_ type: T.Type) throws -> T {
            return try JSONDecoder.shared.decode(type, from: data)
        }
        
        private static func parseHeaders(_ headers: [AnyHashable: Any]) -> [String: String] {
            return headers.reduce(into: [:]) { result, entry in
                if let key = entry.key as? String, let value = entry.value as? String {
                    result[key] = value
                }
            }
        }
    }
    
    /// 向目标 URL 发送请求。
    /// - Parameters:
    ///   - url: 目标 URL，可以是 `String` 与 `URL`。
    ///   - method: 请求方法，如 `GET`、`POST`。
    ///   - headers: 请求头。
    ///   - body: 请求体，在请求方法为 `GET` 时被视为 URL params。
    ///   - encodeMethod: 请求体的编码方式。
    ///   - noCache: 是否禁用缓存。
    /// - Returns: 返回的响应。
    public static func request(
        url: URLConvertible,
        method: String,
        headers: [String: String]?,
        body: [String: Any]?,
        using encodeMethod: EncodeMethod,
        noCache: Bool
    ) async throws -> Response {
        guard let url = url.url else { throw URLError.invalidURL }
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { throw URLError.invalidType }
        
        var request: URLRequest = .init(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        if noCache {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        
        if let body {
            if method == "GET" {
                // url params
                var components: URLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                components.queryItems = body.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
                request.url = components.url
            } else {
                let (bodyData, contentType) = try encode(body, using: encodeMethod)
                request.httpBody = bodyData
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError.badResponse
        }
        return Response(data: data, response: response)
    }
    
    /// 向目标 URL 发送 `GET` 请求。
    /// - Parameters:
    ///   - url: 目标 URL，可以是 `String` 与 `URL`。
    ///   - headers: 请求头。
    ///   - params: 请求的 URL params。
    ///   - noCache: 是否禁用缓存。
    /// - Returns: 返回的响应。
    public static func get(
        _ url: URLConvertible,
        headers: [String: String]? = nil,
        params: [String: String]? = nil,
        noCache: Bool = false
    ) async throws -> Response {
        return try await request(url: url, method: "GET", headers: headers, body: params, using: .urlEncoded, noCache: noCache)
    }
    
    /// 向目标 URL 发送 `POST` 请求。
    /// - Parameters:
    ///   - url: 目标 URL，可以是 `String` 与 `URL`。
    ///   - headers: 请求头。
    ///   - body: 请求体。
    ///   - encodeMethod: 请求体的编码方式。
    /// - Returns: 返回的响应。
    public static func post(
        _ url: URLConvertible,
        headers: [String: String]? = nil,
        body: [String: Any]?,
        using encodeMethod: EncodeMethod
    ) async throws -> Response {
        return try await request(url: url, method: "POST", headers: headers, body: body, using: encodeMethod, noCache: false)
    }
    
    private static func encode(_ body: [String: Any], using method: EncodeMethod) throws -> (Data, String) {
        switch method {
        case .json:
            return (try JSONSerialization.data(withJSONObject: body), "application/json")
        case .urlEncoded:
            return (try body.map { "\($0)=\($1)" }.joined(separator: "&").data(using: .utf8).unwrap(), "application/x-www-form-urlencoded")
        }
    }
}
