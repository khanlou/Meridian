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
                channel.eventLoop.makeSucceededFuture(HTTPHeaders())
            },
            upgradePipelineHandler: { channel, req in
                return WebSocket.server(on: channel, onUpgrade: { ws in
                    print("upgraded! \(ws) \(req)")
                    ws.onPing({ ws2 in
                        print("got ping! pong sent automatically")
                    })

                    ws.onText({ ws, string in
                        print("Received: \(string)")
                        Task {
                            if #available(macOS 13.0, *) {
                                try await Task.sleep(for: .seconds(1))
                            }

                            ws.send("Just received: \(string)")
                        }
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
