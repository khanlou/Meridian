//
//  RequestHeader.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public struct RequestHeader {
    public let method: HTTPMethod
    public let headers: Headers

    private var urlComponents: URLComponents

    public init(method: HTTPMethod, uri: String, headers: [(String, String)]) {
        self.method = method
        self.headers = Headers(storage: headers)
        self.urlComponents = URLComponents(string: uri)!
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

}
