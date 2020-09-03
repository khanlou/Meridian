//
//  HTTPHandler.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/26/20.
//

import Foundation
import NIO
import NIOHTTP1

let CurrentRequestKey = "CurrentRequestContext"
let RequestErrorsKey = "RequestErrors"

public struct RequestContext {
    public let header: RequestHeader
    public let urlParameters: [URLParameterKey: Substring]
    public let postBody: Data

    public init(header: RequestHeader, urlParameters: [URLParameterKey: Substring] = [:], postBody: Data = Data()) {
        self.header = header
        self.urlParameters = urlParameters
        self.postBody = postBody
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

    let routes: [Route.Type]

    let errorRenderer: ErrorRenderer.Type

    var state = State.initial

    init(routes: [Route.Type], errorRenderer: ErrorRenderer.Type) {
        self.routes = routes
        self.errorRenderer = errorRenderer
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

            let header = RequestHeader(
                method: HTTPMethod(name: head.method.rawValue),
                uri: head.uri,
                headers: head.headers.map({ ($0, $1) })
            )

            var optionalRouteType: (Route.Type, MatchedRoute)?

            for route in routes {
                if let matchedRoute = route.route.matches(header) {
                    optionalRouteType = (route, matchedRoute)
                    break
                }
            }

            do {
                guard let (routeType, matchedRoute) = optionalRouteType else {
                    throw NoRouteFound()
                }

                let requestContext = RequestContext(
                    header: header,
                    urlParameters: matchedRoute.parameters,
                    postBody: body
                )

                print("request: \(requestContext)")

                Thread.current.threadDictionary[CurrentRequestKey] = requestContext

                let route = routeType.init()

                if let errors = Thread.current.threadDictionary[RequestErrorsKey] as? [Error], !errors.isEmpty {

                    let reportables = errors.compactMap({ $0 as? ReportableError })
                    throw BasicError(statusCode: reportables.first!.statusCode, message: reportables.map({ $0.message }).joined(separator: "\n"))

                }

                let response = try route.execute()

                var statusCode = StatusCode.ok
                var additionalHeaders: [String: String] = [:]
                if let responseWithDetails = response as? ResponseDetails {
                    statusCode = responseWithDetails.statusCode
                    additionalHeaders = responseWithDetails.additionalHeaders
                }
                var head = HTTPResponseHead(version: head.version, status: HTTPResponseStatus(statusCode: statusCode.code))

                for (name, value) in additionalHeaders {
                    head.headers.add(name: name, value: value)
                }

                let part = HTTPServerResponsePart.head(head)

                let future = channel.write(part)

                var buffer = channel.allocator.buffer(capacity: 100)
                buffer.writeBytes(try response.body())

                let bodyPart = HTTPServerResponsePart.body(.byteBuffer(buffer))
                let future2 = channel.write(bodyPart)

                let endPart = HTTPServerResponsePart.end(nil)
                let future3 = channel.writeAndFlush(endPart)

                _ = future.and(future2).and(future3)
                    .flatMap({ (_) -> EventLoopFuture<Void> in
                        Thread.current.threadDictionary[CurrentRequestKey] = nil
                        Thread.current.threadDictionary[RequestErrorsKey] = nil

                        return channel.close()
                    })

            } catch {
                let errorRenderer = self.errorRenderer.init(error: error)

                let response = try! errorRenderer.render()

                var statusCode = StatusCode.ok
                var additionalHeaders: [String: String] = [:]
                if let responseWithDetails = response as? ResponseDetails {
                    statusCode = responseWithDetails.statusCode
                    additionalHeaders = responseWithDetails.additionalHeaders
                }
                var head = HTTPResponseHead(version: head.version, status: HTTPResponseStatus(statusCode: statusCode.code))

                for (name, value) in additionalHeaders {
                    head.headers.add(name: name, value: value)
                }

                let part = HTTPServerResponsePart.head(head)

                let future = channel.write(part)

                var buffer = channel.allocator.buffer(capacity: 100)
                buffer.writeBytes(try! response.body())

                let bodyPart = HTTPServerResponsePart.body(.byteBuffer(buffer))
                let future2 = channel.write(bodyPart)

                let endPart = HTTPServerResponsePart.end(nil)
                let future3 = channel.writeAndFlush(endPart)

                _ = future.and(future2).and(future3)
                    .flatMap({ (_) -> EventLoopFuture<Void> in
                        Thread.current.threadDictionary[CurrentRequestKey] = nil
                        Thread.current.threadDictionary[RequestErrorsKey] = nil

                        return channel.close()
                    })

            }

        }
    }
}
