//
//  HTTPHandler.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/26/20.
//

import Foundation
import NIO
import NIOHTTP1

public struct RequestContext {
    public var header: RequestHeader
    public var matchedRoute: MatchedRoute?
    public var postBody: Data
    public var environment: EnvironmentValues

    public init(header: RequestHeader, matchedRoute: MatchedRoute?, postBody: Data = Data()) {
        self.header = header
        self.matchedRoute = matchedRoute
        self.postBody = postBody
        self.environment = EnvironmentValues.shared
    }

    public var queryParameters: [URLQueryItem] {
        header.queryParameters
    }
}

final class HTTPHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = ParsedHTTPRequest

    enum State {
        case idle
        case headerReceived(HTTPRequestHead)
        case inProgress(HTTPRequestHead, Data)
        case complete(HTTPRequestHead, Data)
    }

    let router: Router


    convenience init(errorRenderer: ErrorRenderer, middlewareProducers: [() -> Middleware] = []) {
        self.init(router: Router(defaultErrorRenderer: errorRenderer, middlewareProducers: middlewareProducers))
    }

    init(router: Router, middlewareProducers: [() -> Middleware] = []) {
        self.router = router
        self.router.middlewareProducers = middlewareProducers
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {

        let channel = context.channel

        let parsedRequest = unwrapInboundIn(data)
        let head = parsedRequest.head
        let body = parsedRequest.data

        Task {

            do {

                let hydration = try Hydration(context: .init(
                    header: .init(nioHead: head),
                    matchedRoute: nil,
                    postBody: body
                ))

                let routing = RoutingMiddleware(router: self.router, hydration: hydration)

                hydration.context.matchedRoute = routing.matchedRoute

                let errorRenderer = routing.errorRenderer

                let middlewares = self.router.middlewareProducers
                    .flatMap({ middlewareProducer in
                        [
                            ResponseHydrationMiddleware(hydration: hydration),
                            ErrorRescueMiddleware(errorRenderer: errorRenderer),
                            middlewareProducer(),
                        ]
                    }) +
                [
                    ResponseHydrationMiddleware(hydration: hydration),
                    ErrorRescueMiddleware(errorRenderer: errorRenderer),
                    routing,
                ]

                for middleware in middlewares {
                    try await hydration.hydrate(middleware)
                }

                let middleware = MiddlewareGroup(middlewares: middlewares)

                let response = try await middleware.execute(next: BottomRoute())
                    .additionalHeaders(["Server": EnvironmentValues().serverName])

                let statusCode = response.statusCode
                let headers = response.additionalHeaders
                let body = try response.body()

                try await send(
                    statusCode: statusCode,
                    headers: headers,
                    body: body,
                    version: head.version,
                    to: channel
                )
            } catch {
                _ = try await channel.close()
            }
        }
    }

    fileprivate func send(statusCode: StatusCode, headers: [String: String], body: Data, version: HTTPVersion, to channel: Channel) async throws {

        var head = HTTPResponseHead(version: version, status: HTTPResponseStatus(statusCode: statusCode.code))

        for (name, value) in headers {
            head.headers.add(name: name, value: value)
        }

        let part = HTTPServerResponsePart.head(head)

        _ = channel.write(part)

        var buffer = channel.allocator.buffer(capacity: body.count)
        buffer.writeBytes(body)

        let bodyPart = HTTPServerResponsePart.body(.byteBuffer(buffer))
        _ = channel.write(bodyPart)

        let endPart = HTTPServerResponsePart.end(nil)

        do {
            _ = try await channel.writeAndFlush(endPart)
        } catch {
            try? await channel.close()
        }
    }

}

final class Hydration {
    var context: RequestContext
    var errors: [Error]

    init(context: RequestContext, errors: [Error] = []) {
        self.context = context
        self.errors = errors
    }

    func hydrate(_ object: Any) async throws {
        let m = Mirror(reflecting: object)
        for (_, child) in m.children {
            if let response = child as? Response {
                // Responses can be wrapped by other Responses, so we need to recurse
                try await self.hydrate(response)
            }
            if let prop = child as? PropertyWrapper {
                await prop.update(context, errors: &errors)
            }
        }
    }
}
