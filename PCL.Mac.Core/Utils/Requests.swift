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

public enum Requests {
    public enum EncodeMethod {
        case json
        case urlEncoded
    }
    
    public class Response {
        public let statusCode: Int
        public let headers: [String: String]
        public let data: Data
        
        fileprivate init(data: Data, response: HTTPURLResponse) {
            self.statusCode = response.statusCode
            self.headers = Self.parseHeaders(response.allHeaderFields)
            self.data = data
        }
        
        public func json() throws -> JSON {
            return try JSON(data: data)
        }
        
        private static func parseHeaders(_ headers: [AnyHashable: Any]) -> [String: String] {
            return headers.reduce(into: [:]) { result, entry in
                if let key = entry.key as? String, let value = entry.value as? String {
                    result[key] = value
                }
            }
        }
    }
    
    public static func request(
        url: URLConvertible,
        method: String,
        headers: [String: String]?,
        body: [String: Any]?,
        using encodeMethod: EncodeMethod
    ) async throws -> Response {
        guard let url = url.url else { throw URLError.invalidURL }
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { throw URLError.invalidType }
        
        var request: URLRequest = .init(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        
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
    
    public static func get(
        _ url: URLConvertible,
        headers: [String: String]? = nil,
        params: [String: String]? = nil
    ) async throws -> Response {
        return try await request(url: url, method: "GET", headers: headers, body: params, using: .urlEncoded)
    }
    
    public static func post(
        _ url: URLConvertible,
        headers: [String: String]? = nil,
        body: [String: String]?,
        using encodeMethod: EncodeMethod
    ) async throws -> Response {
        return try await request(url: url, method: "POST", headers: headers, body: body, using: encodeMethod)
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
