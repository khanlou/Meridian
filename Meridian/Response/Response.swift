//
//  Response.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

public protocol Response {

    var statusCode: StatusCode  { get }

    var additionalHeaders: [String: String] { get }

    func body() throws -> Data
}

public extension Response {
    var additionalHeaders: [String : String] {
        [:]
    }

    var statusCode: StatusCode {
        .ok
    }
}
