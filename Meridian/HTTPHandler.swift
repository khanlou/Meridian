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

enum HTTPHandlerUnrecoverableError: LocalizedError {
    case unexpectedPart(HTTPHandler.State, HTTPServerRequestPart)

    var errorDescription: String? {
        switch self {
        case .unexpectedPart(let state, let httpServerRequestPart):
            return "A part of \(httpServerRequestPart) was received while in the \(state) state."
        }
    }
}

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart

    enum State {
        case idle
        case headerReceived(HTTPRequestHead)
        case inProgress(HTTPRequestHead, Data)
        case complete(HTTPRequestHead, Data)
    }

    let router: Router

    let middlewareProducers: [() -> Middleware]

    var state = State.idle

    convenience init(routesByPrefix: [String: RouteGroup], errorRenderer: ErrorRenderer, middlewareProducers: [() -> Middleware] = []) {
        self.init(router: Router(routesByPrefix: routesByPrefix, defaultErrorRenderer: errorRenderer), middlewareProducers: middlewareProducers)
    }

    init(router: Router, middlewareProducers: [() -> Middleware]) {
        self.router = router
        self.middlewareProducers = middlewareProducers
    }

    func updateState(with data: NIOAny) throws {
        let part = unwrapInboundIn(data)

        switch part {
        case let .head(head):
            switch state {
            case .idle:
                self.state = .headerReceived(head)
            default:
                throw HTTPHandlerUnrecoverableError.unexpectedPart(state, part)
            }
        case let .body(byteBuffer):
            switch state {
            case let .headerReceived(head):
                self.state = .inProgress(head, Data(byteBuffer.readableBytesView))
            case let .inProgress(head, body):
                var body = body
                body.append(contentsOf: byteBuffer.readableBytesView)
                self.state = .inProgress(head, body)
            default:
                throw HTTPHandlerUnrecoverableError.unexpectedPart(state, part)
            }
        case .end(_):
            switch state {
            case let .headerReceived(head):
                // what's the content length? can .body come twice?
                self.state = .complete(head, Data())
            case let .inProgress(head, body):
                self.state = .complete(head, body)
            default:
                throw HTTPHandlerUnrecoverableError.unexpectedPart(state, part)
            }
        }
    }

    func dataIfReady() -> (HTTPRequestHead, Data)? {
        if case let .complete(head, data) = state {
            return (head, data)
        } else {
            return nil
        }
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {

        let channel = context.channel

        do {
            try self.updateState(with: data)
        } catch {
            assertionFailure(error.localizedDescription)
            try? channel.close().wait()
            return
        }

        guard let (head, body) = dataIfReady() else {
            return
        }

        Task {

            do {

                let hydration = try Hydration(context: .init(
                    header: .init(
                        method: HTTPMethod(name: head.method.rawValue),
                        httpVersion: head.version,
                        uri: head.uri,
                        headers: head.headers.map({ ($0, $1) })
                    ),
                    matchedRoute: nil,
                    postBody: body
                ))

                let routing = RoutingMiddleware(router: self.router, hydration: hydration)

                hydration.context.matchedRoute = routing.matchedRoute

                let errorRenderer = routing.errorRenderer

                let middlewares = self.middlewareProducers
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
            self.state = .idle
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
