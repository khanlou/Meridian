//
//  ErrorRenderer.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/30/20.
//

import Foundation

public struct ErrorsContext {
    public let allErrors: [Error]

    public init(allErrors: [Error]) {
        self.allErrors = allErrors
    }

    public init(error: Error) {
        self.allErrors = [error]
    }

    public var reportableErrors: [ReportableError] {
        allErrors.compactMap({ $0 as? ReportableError })
    }

    public var errorMessage: String {
        reportableErrors.first?.message ?? "An error occurred."
    }

    public var errorMessages: [String] {
        var errorMessages = reportableErrors
            .map({ $0.message })

        if errorMessages.isEmpty {
            errorMessages.append("An error occurred.")
        }

        return errorMessages
    }

    public var statusCode: StatusCode {
        reportableErrors.first?.statusCode ?? .internalServerError
    }
}

public protocol ErrorRenderer: Sendable {

    func render(primaryError: Error, context: ErrorsContext) async throws -> Response

}

struct ErrorContainer: Codable {
    let errors: [String]
}

public struct JSONErrorRenderer: ErrorRenderer {

    public init() { }

    public func render(primaryError error: Error, context: ErrorsContext) throws -> Response {
        return JSON(ErrorContainer(errors: context.errorMessages))
            .statusCode(context.statusCode)
    }
}

public struct BasicErrorRenderer: ErrorRenderer {

    public init() { }

    public func render(primaryError error: Error, context: ErrorsContext) throws -> Response {
        return (context.errorMessage)
            .statusCode(context.statusCode)
    }
}
