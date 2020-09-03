//
//  ErrorRenderer.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/30/20.
//

import Foundation

public protocol ErrorRenderer {

    init(error: Error)

    func render() throws -> Response

}

struct ErrorContainer: Codable {
    let message: String
}

public struct JSONErrorRenderer: ErrorRenderer {

    public let error: Error

    public init(error: Error) {
        self.error = error
    }

    public func render() throws -> Response {
        JSON(ErrorContainer(message: (error as? ErrorWithMessage)?.message ?? "An error occurred"))
            .statusCode( (error as? ErrorWithStatusCode)?.statusCode ?? .badRequest)
    }
}
