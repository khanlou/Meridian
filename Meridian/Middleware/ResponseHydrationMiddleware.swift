//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 3/17/23.
//

import Foundation

struct ResponseHydrationMiddleware: Middleware {

    var hydration: Hydration

    func execute(next: Responder) async throws -> Response {
        let response = try await next.execute()
        try await hydration.hydrate(response)
        return response
    }
}
