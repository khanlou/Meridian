//
//  HTTPHandler.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/26/20.
//

import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket
import WebSocketKit

final class HTTPUpgradeHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = ParsedHTTPRequest

    private enum UpgradeState {
        case ready
        case pending(ParsedHTTPRequest, UpgradeBufferHandler)
        case upgraded
    }

    private var upgradeState: UpgradeState = .ready

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let parsed = unwrapInboundIn(data)
        let connectionHeaders = Set(parsed.head.headers["Connection"])

        let channel = context.channel
        if connectionHeaders.contains("Upgrade") {

            let upgrader = NIOWebSocketServerUpgrader(
                maxFrameSize: 1 << 14,
                automaticErrorHandling: false,
                shouldUpgrade: { _, _ in
                    channel.eventLoop.makeSucceededFuture(HTTPHeaders())
                },
                upgradePipelineHandler: { channel, req in
                    return WebSocket.server(on: channel, onUpgrade: { ws in
                        print("upgraded! \(ws)")
                    })
                }
            )

            channel.pipeline
                .handler(type: HTTPRequestParsingHandler.self)
                .map({ parsingHandler -> EventLoopFuture<Void> in
                    let buffer = UpgradeBufferHandler()
                    return context.channel.pipeline.addHandler(buffer, position: .before(parsingHandler))
                        .flatMap({ () -> EventLoopFuture<HTTPHeaders> in
                            upgrader
                                .buildUpgradeResponse(
                                    channel: channel,
                                    upgradeRequest: parsed.head,
                                    initialResponseHeaders: [:]
                                )
                        })
                        .flatMap({ headers in
                            let head = HTTPResponseHead(
                                version: parsed.head.version,
                                status: HTTPResponseStatus.switchingProtocols,
                                headers: headers
                            )

                            return self.sendHead(head, to: channel)
                        })
                        .flatMap({
                            let handlers: [RemovableChannelHandler] = [self, parsingHandler]

                            return .andAllComplete(handlers.map { handler in
                                return context.pipeline.removeHandler(handler)
                            }, on: context.eventLoop)
                        }).flatMap({
                            upgrader.upgrade(context: context, upgradeRequest: parsed.head)
                        }).flatMap({
                            context.pipeline.removeHandler(buffer)
                        })
                })
                .whenFailure({ error in
                    print(error)
                    channel.close(promise: nil)
                })
            return
        }

        context.fireChannelRead(data)
    }

    func sendHead(_ head: HTTPResponseHead, to channel: Channel) -> EventLoopFuture<Void> {

        let part = HTTPServerResponsePart.head(head)

        _ = channel.write(part)

        let empty = channel.allocator.buffer(bytes: [])
        let bodyPart = HTTPServerResponsePart.body(.byteBuffer(empty))
        _ = channel.write(bodyPart)

        let endPart = HTTPServerResponsePart.end(nil)

        return channel.writeAndFlush(endPart)

    }
}

private final class UpgradeBufferHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = ByteBuffer

    var buffer: [ByteBuffer]

    init() {
        self.buffer = []
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)
        self.buffer.append(data)
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        for data in self.buffer {
            context.fireChannelRead(NIOAny(data))
        }
    }
}
