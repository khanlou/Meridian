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
    public let header: RequestHeader
    public let matchedRoute: MatchedRoute
    public let postBody: Data
    public let environment: EnvironmentValues

    public init(header: RequestHeader, matchedRoute: MatchedRoute, postBody: Data = Data()) {
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
            var errorRenderer = self.router.defaultErrorRenderer

            do {

                let header = try RequestHeader(
                    method: HTTPMethod(name: head.method.rawValue),
                    httpVersion: head.version,
                    uri: head.uri,
                    headers: head.headers.map({ ($0, $1) })
                )

                let results: (Responder, MatchedRoute)?
                (results, errorRenderer) = router.route(for: header)

                guard let (route, matchedRoute) = results else {
                    throw NoRouteFound()
                }

                let requestContext = RequestContext(
                    header: header,
                    matchedRoute: matchedRoute,
                    postBody: body
                )

                var errors: [Error] = []

                let middlewares = self.middlewareProducers.map({ $0() })

                for middleware in middlewares {
                    try await hydratePropertyWrappers(on: middleware, context: requestContext, errors: &errors)
                }

                try await hydratePropertyWrappers(on: route, context: requestContext, errors: &errors)

                let middleware = MiddlewareGroup(middlewares: middlewares)

                if let firstError = errors.first {

                    let response = try await errorRenderer.render(primaryError: firstError, context: ErrorsContext(allErrors: errors))

                    try await send(response, requestContext.header.httpVersion, to: channel)

                } else {

                    try await route.validate()

                    let response = try await middleware.execute(next: route)

                    try await send(response, requestContext.header.httpVersion, to: channel)
                }

            } catch {

                do {
                    let response = try await errorRenderer.render(primaryError: error, context: ErrorsContext(error: error))
                    try await send(response, head.version, to: channel)
                } catch {
                    _ = try await channel.close()
                }
            }
        }
    }

    fileprivate func send(_ response: Response, _ version: HTTPVersion, to channel: Channel) async throws {
        let statusCode = response.statusCode
        let additionalHeaders = response.additionalHeaders
        let body = try response.body()

        var head = HTTPResponseHead(version: version, status: HTTPResponseStatus(statusCode: statusCode.code))

        for (name, value) in additionalHeaders {
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

    func hydratePropertyWrappers(on object: Any, context: RequestContext, errors: inout [Error]) async throws {
        let m = Mirror(reflecting: object)
        for (_, child) in m.children {
            if let prop = child as? PropertyWrapper {
                await prop.update(context, errors: &errors)
            }
        }
    }
}
