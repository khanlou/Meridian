//
//  ErrorRenderer.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/30/20.
//

import Foundation

public protocol ErrorRenderer {

    func render(error: Error) throws -> Response

}

struct ErrorContainer: Codable {
    let message: String
}

public struct JSONErrorRenderer: ErrorRenderer {

    public init() { }

    public func render(error: Error) throws -> Response {
        JSON(ErrorContainer(message: (error as? ErrorWithMessage)?.message ?? "An error occurred"))
            .statusCode( (error as? ErrorWithStatusCode)?.statusCode ?? .badRequest)
    }
}

public struct BasicErrorRenderer: ErrorRenderer {

    public init() { }

    public func render(error: Error) throws -> Response {
        return ((error as? ErrorWithMessage)?.message ?? "An error occurred")
            .statusCode( (error as? ErrorWithStatusCode)?.statusCode ?? .badRequest)
    }
}

