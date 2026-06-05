//
//  RequestHeader.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation
import NIOHTTP1

public struct UnparseableRequest: ReportableError {
    public let message = "This request was unprocessable."

    public let statusCode: StatusCode = .badRequest
}

public struct RequestHeader: CustomStringConvertible, Sendable {
    public let method: HTTPMethod
    public let httpVersion: HTTPVersion
    public let headers: Headers
    public let uri: String

    private var urlComponents: URLComponents

    public init(nioHead: HTTPRequestHead) throws {
        try self.init(
            method: HTTPMethod(name: nioHead.method.rawValue),
            httpVersion: nioHead.version,
            uri: nioHead.uri,
            headers: nioHead.headers.map({ ($0, $1) })
        )
    }

    public init(method: HTTPMethod, httpVersion: HTTPVersion = .http1_1, uri: String, headers: [(String, String)]) throws {
        self.method = method
        self.httpVersion = httpVersion
        self.headers = Headers(storage: headers)
        self.uri = uri
        guard let components = URLComponents(string: uri) else {
            throw UnparseableRequest()
        }
        self.urlComponents = components
    }

    internal(set) public var path: String {
        get {
            urlComponents.path
        }
        set {
            urlComponents.path = newValue
        }
    }

    public var queryParameters: [URLQueryItem] {
        urlComponents.queryItems ?? []
    }

    public var description: String {
        "\(Self.self)(method: \(method), uri: \(uri))"
    }
}
