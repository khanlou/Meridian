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

    init() {
        self.innerUpgrader = NIOWebSocketServerUpgrader(
            maxFrameSize: 1 << 14,
            automaticErrorHandling: false,
            shouldUpgrade: { channel, head in
                // check if theres a registered websocket route
                channel.eventLoop.makeSucceededFuture(HTTPHeaders())
            },
            upgradePipelineHandler: { channel, req in
                return WebSocket.server(on: channel, onUpgrade: { ws in
                    // bind the websocket to its route somehow, so that messages that come in here can go into the route
                    print("upgraded! \(ws) \(req)")
                    ws.onPing({ ws2 in
                        print("got ping! pong sent automatically")
                    })

                    ws.onText({ ws, string in
                        print("Received: \(string)")
                        ws.send("Just received: \(string) has \(string.count) characters")
                    })

                    ws.onBinary({ _, _ in
                        print("got some binary")
                    })

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
