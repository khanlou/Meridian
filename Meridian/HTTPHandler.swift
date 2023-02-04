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

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart

    enum State {
        case initial
        case headerReceived(HTTPRequestHead)
        case complete(HTTPRequestHead, Data)
    }

    let router: Router

    var state = State.initial

    convenience init(routesByPrefix: [String: RouteGroup], errorRenderer: ErrorRenderer) {
        self.init(router: Router(routesByPrefix: routesByPrefix, defaultErrorRenderer: errorRenderer))
    }

    init(router: Router) {
        self.router = router
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)

        switch part {
        case let .head(head):
            self.state = .headerReceived(head)
        case let .body(byteBuffer):
            switch state {
            case .initial:
                fatalError("Unexpected state: \(self.state)")
            case let .headerReceived(head):
                // what's the content length? can .body come twice?
                self.state = .complete(head, Data(byteBuffer.readableBytesView))
            case let .complete(head, body):
                var body = body
                body.append(contentsOf: byteBuffer.readableBytesView)
                self.state = .complete(head, body)
            }
        case .end:
            let head: HTTPRequestHead
            let body: Data
            switch state {
            case let .complete(header2, body2):
                head = header2
                body = body2
            case let .headerReceived(header2):
                head = header2
                body = Data()
            case .initial:
                fatalError("Unexpected state: \(self.state)")
            }

            let channel = context.channel
            Task {
                var errorRenderer = self.router.defaultErrorRenderer
                print("Request: \(head.method.rawValue) \(head.uri)")
                do {
                    
                    let header = try RequestHeader(
                        method: HTTPMethod(name: head.method.rawValue),
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
                    
                    let m = Mirror(reflecting: route)
                    for (_, child) in m.children {
                        if let prop = child as? PropertyWrapper {
                            await prop.update(requestContext, errors: &errors)
                        }
                    }
                    
                    if let firstError = errors.first {
                        
                        let response = try await errorRenderer.render(primaryError: firstError, context: ErrorsContext(allErrors: errors))
                        
                        try await send(response, head.version, to: channel)
                        
                    } else {
                        
                        try await route.validate()
                        
                        let response = try await route.execute()
                        
                        try await send(response, head.version, to: channel)
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
    }

    fileprivate func send(_ response: Response, _ version: HTTPVersion, to channel: Channel) async throws {
        var statusCode = StatusCode.ok
        var additionalHeaders: [String: String] = [:]
        if let responseWithDetails = response as? ResponseDetails {
            statusCode = responseWithDetails.statusCode
            additionalHeaders = responseWithDetails.additionalHeaders
        }
        var head = HTTPResponseHead(version: version, status: HTTPResponseStatus(statusCode: statusCode.code))

        for (name, value) in additionalHeaders {
            head.headers.add(name: name, value: value)
        }

        let part = HTTPServerResponsePart.head(head)

        _ = channel.write(part)

        var buffer = channel.allocator.buffer(capacity: 100)
        buffer.writeBytes(try response.body())

        let bodyPart = HTTPServerResponsePart.body(.byteBuffer(buffer))
        _ = channel.write(bodyPart)

        let endPart = HTTPServerResponsePart.end(nil)
        _ = try await channel.writeAndFlush(endPart)

        try await channel.close()
    }

}
