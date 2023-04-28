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
                if responder(for: head) != nil {
                    return channel.eventLoop.makeSucceededFuture(HTTPHeaders())
                } else {
                    return channel.eventLoop.makeSucceededFuture(nil)
                }
            },
            upgradePipelineHandler: { channel, head in
                return WebSocketKit.WebSocket.server(on: channel, onUpgrade: { ws in
                    Task {

                        do {
                            guard let route = responder(for: head) else {
                                fatalError("should never get to here, should already be validated")
                            }

                            guard let webSocket = try await route.execute() as? WebSocket else {
                                fatalError("invalid")
                            }

                            ws.onText({ ws, text in
                                Task {
                                    do {
                                        try await webSocket.onText(text)
                                    } catch {
                                        print(error)
                                    }
                                }
                            })

                            ws.onBinary({ ws, bytes in
                                Task {
                                    do {
                                        try await webSocket.onData(Data(buffer: bytes, byteTransferStrategy: .automatic))
                                    } catch {
                                        print(error)
                                    }
                                }
                            })

                            ws.onPing({ ws in
                                Task {
                                    do {
                                        try await webSocket.onPing()
                                    } catch {
                                        print(error)
                                    }
                                }
                            })

                            ws.onPong({ ws in
                                Task {
                                    do {
                                        try await webSocket.onPong()
                                    } catch {
                                        print(error)
                                    }
                                }
                            })

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
