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

let upgrader = NIOWebSocketServerUpgrader(
    maxFrameSize: 1 << 14,
    automaticErrorHandling: false,
    shouldUpgrade: { channel, head in
        channel.eventLoop.makeSucceededFuture(HTTPHeaders())
    },
    upgradePipelineHandler: { channel, req in
        return WebSocket.server(on: channel, onUpgrade: { ws in
            print("upgraded! \(ws)")
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
