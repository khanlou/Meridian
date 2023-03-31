//
//  ErrorRenderer.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/30/20.
//

import Foundation

public struct BlockResponder: Responder {

    let block: () async throws -> Response

    public init(block: @escaping () async throws -> Response) {
        self.block = block
    }

    public func execute() async throws -> Response {
        try await block()
    }
}

public protocol Middleware {
    func execute(next: Responder) async throws -> Response
}

public extension Middleware {
    func makeResponder(wrapping next: Responder) async throws -> Responder {
        return BlockResponder(block: {
            return try await self.execute(next: next)
        })
    }
}

struct MiddlewareGroup: Middleware {
    let middlewares: [Middleware]

    func execute(next: Responder) async throws -> Response {
        var responder = next
        for middleware in middlewares.reversed() {
            responder = try await middleware.makeResponder(wrapping: responder)
        }
        return try await responder.execute()
    }
}

public struct LoggingMiddleware: Middleware {

    @Path var path
    @RequestMethod var method

    public init() { }

    public func execute(next: Responder) async throws -> Response {
        print("Request: \(method) \(path)")
        let result = try await next.execute()
        return result
    }
}

public struct TimingMiddleware: Middleware {

    public init() { }

    public func execute(next: Responder) async throws -> Response {
        let start = Date()
        let result = try await next.execute()
        let duration = -start.timeIntervalSinceNow
        print("Request took \(duration)s")
        return result
    }
}

struct HeaderExtractor: NonParameterizedExtractor {
    static func extract(from context: RequestContext) async throws -> RequestHeader {
        return context.header
    }
}

struct RoutingMiddleware: Middleware {
    let hydration: Hydration

    let route: Responder?
    let matchedRoute: MatchedRoute?
    let errorRenderer: ErrorRenderer

    init(router: Router, hydration: Hydration) {
        let result = router.route(for: hydration.context.header)
        self.route = result.0?.0
        self.matchedRoute = result.0?.1
        self.errorRenderer = result.1
        self.hydration = hydration
    }

    func execute(next: Responder) async throws -> Response {
        if let route {
            try await hydration.hydrate(route)
            if let firstError = hydration.errors.first {
                return try await errorRenderer.render(primaryError: firstError, context: .init(allErrors: hydration.errors))
            }
            try await route.validate()
            return try await route.execute()
        } else {
            return try await next.execute()
        }
    }
}

struct ErrorRescueMiddleware: Middleware {

    let errorRenderer: ErrorRenderer

    func execute(next: Responder) async throws -> Response {
        do {
            return try await next.execute()
        } catch {
            return try await errorRenderer
                .render(primaryError: error, context: .init(error: error))
        }
    }
}

struct BottomRoute: Responder {
    func execute() async throws -> Response {
        throw NoRouteFound()
    }
}
