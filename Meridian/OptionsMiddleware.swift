//
//  OptionsRoute.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public struct OptionsMiddleware: Middleware {

    public init() { }

    @Environment(\.router) var router

    @Path var path: String

    @RequestMethod var method: HTTPMethod

    public func execute(next: Responder) async throws -> Response {

        guard method == .OPTIONS else { return try await next.execute() }

        let matchingMethods = try self.router.methods(for: path)

        return EmptyResponse()
            .additionalHeaders([
                "Allow": HTTPMethod.primaryMethods.filter(matchingMethods.contains).map({ $0.name }).joined(separator: ", ")
            ])
            .allowCORS()
            .statusCode(matchingMethods.isEmpty ? .notFound : .noContent)
    }
}
