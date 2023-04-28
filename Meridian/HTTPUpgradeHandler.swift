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

final class WebSocketUpgrader: HTTPServerProtocolUpgrader {

    let innerUpgrader: NIOWebSocketServerUpgrader

    init(router: Router) {
        var storedResponder: WebSocketResponder?

        @Sendable func responder(for head: HTTPRequestHead) -> WebSocketResponder? {
            guard let header = try? RequestHeader(nioHead: head) else {
                return nil
            }

            let (match, _) = router.route(for: header)

            guard let match else {
                return nil
            }

            guard let responder = match.0 as? WebSocketResponder else {
                return nil
            }

            return responder
        }

        self.innerUpgrader = NIOWebSocketServerUpgrader(
            maxFrameSize: 1 << 14,
            automaticErrorHandling: false,
            shouldUpgrade: { channel, head in
                if let responder = responder(for: head) {
                    storedResponder = responder
                    return channel.eventLoop.makeSucceededFuture(HTTPHeaders())
                } else {
                    return channel.eventLoop.makeSucceededFuture(nil)
                }
            },
            upgradePipelineHandler: { channel, head in
                return WebSocketKit.WebSocket.server(on: channel, onUpgrade: { ws in
                    guard let route = storedResponder else {
                        fatalError("should never get to here, should already be validated")
                    }
                    
                    Task {
                        do {
                            let websocket = Meridian.WebSocket(inner: ws)
                            try await route.connected(to: websocket)
                        } catch {

                        }
                    }

                })
            }
        )
    }

    var supportedProtocol: String {
        innerUpgrader.supportedProtocol
    }

    var requiredUpgradeHeaders: [String] {
        innerUpgrader.requiredUpgradeHeaders
    }

    func buildUpgradeResponse(channel: NIOCore.Channel, upgradeRequest: NIOHTTP1.HTTPRequestHead, initialResponseHeaders: NIOHTTP1.HTTPHeaders) -> NIOCore.EventLoopFuture<NIOHTTP1.HTTPHeaders> {
        innerUpgrader.buildUpgradeResponse(channel: channel, upgradeRequest: upgradeRequest, initialResponseHeaders: initialResponseHeaders)
    }

    func upgrade(context: NIOCore.ChannelHandlerContext, upgradeRequest: NIOHTTP1.HTTPRequestHead) -> NIOCore.EventLoopFuture<Void> {
        innerUpgrader.upgrade(context: context, upgradeRequest: upgradeRequest)
    }

}
