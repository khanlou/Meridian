//
//  ErrorRenderer.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/30/20.
//

import Foundation

public protocol ErrorRenderer {

    func render(primaryError: Error, otherErrors: [Error]) throws -> Response

}

struct ErrorContainer: Codable {
    let message: String
}

public struct JSONErrorRenderer: ErrorRenderer {

    public init() { }

    public func render(primaryError error: Error, otherErrors: [Error]) throws -> Response {
        JSON(ErrorContainer(message: (error as? ReportableError)?.message ?? "An error occurred."))
            .statusCode((error as? ReportableError)?.statusCode ?? .internalServerError)
    }
}

public struct BasicErrorRenderer: ErrorRenderer {

    public init() { }

    public func render(primaryError error: Error, otherErrors: [Error]) throws -> Response {
        return ((error as? ReportableError)?.message ?? "An error occurred.")
            .statusCode((error as? ReportableError)?.statusCode ?? .internalServerError)
    }
}
