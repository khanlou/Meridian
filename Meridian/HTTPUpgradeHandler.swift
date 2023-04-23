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

final class HTTPUpgradeHandler: ChannelInboundHandler {
    typealias InboundIn = ParsedHTTPRequest

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let parsed = unwrapInboundIn(data)
        let connectionHeaders = Set(parsed.head.headers["Connection"])

        print(parsed.head)

        let channel = context.channel
        if connectionHeaders.contains("Upgrade") {
            Task {
                let result = try await NIOWebSocketServerUpgrader(
                    maxFrameSize: 1 << 14,
                    automaticErrorHandling: false,
                    shouldUpgrade: { _, _ in
                        channel.eventLoop.makeSucceededFuture(HTTPHeaders())
                    },
                    upgradePipelineHandler: { channel, req in
                        return WebSocket.server(on: channel, onUpgrade: { ws in print("upgraded! \(ws)") })
                    }
                )
                .buildUpgradeResponse(
                    channel: channel,
                    upgradeRequest: parsed.head,
                    initialResponseHeaders: [:]
                ).get()

                let head = HTTPResponseHead(
                    version: parsed.head.version,
                    status: HTTPResponseStatus.switchingProtocols,
                    headers: result
                )

                print(head)

                try await sendHead(head, to: channel)
            }
            return
        }

        context.fireChannelRead(data)
    }

    func sendHead(_ head: HTTPResponseHead, to channel: Channel) async throws {

        let part = HTTPServerResponsePart.head(head)

        _ = channel.write(part)

        let empty = channel.allocator.buffer(bytes: [])
        let bodyPart = HTTPServerResponsePart.body(.byteBuffer(empty))
        _ = channel.write(bodyPart)

        let endPart = HTTPServerResponsePart.end(nil)

        do {
            _ = try await channel.writeAndFlush(endPart)
        } catch {
            try? await channel.close()
        }

    }
}
