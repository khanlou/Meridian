//
//  EmptyResponse.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

public struct EmptyResponse: Response {

    public init() {

    }

    public var statusCode: StatusCode {
        .noContent
    }

    public func body() throws -> Data {
        Data()
    }
}

