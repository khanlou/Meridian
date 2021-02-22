//
//  RequestHeader.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public struct UnparseableRequest: ReportableError {
    public let message = "This request was unprocessable."

    public let statusCode: StatusCode = .badRequest
}

public struct RequestHeader: CustomStringConvertible {
    public let method: HTTPMethod
    public let headers: Headers

    private var urlComponents: URLComponents

    public init(method: HTTPMethod, uri: String, headers: [(String, String)]) throws {
        self.method = method
        self.headers = Headers(storage: headers)
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
        "\(Self.self)(method: \(method), uri: \(path))"
    }
}
