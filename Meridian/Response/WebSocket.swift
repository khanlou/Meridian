//
//  File 2.swift
//  
//
//  Created by Soroush Khanlou on 4/27/23.
//

import Foundation
import WebSocketKit

public protocol WebSocketResponder: Responder {
    func shouldConnect() async throws -> Bool
    
    func connected(to websocket: Meridian.WebSocket) async throws
}

public extension WebSocketResponder {
    func shouldConnect() async throws -> Bool {
        true
    }
    
    func execute() async throws -> Response {
        WebSocketResponse()
    }
}

public struct WebSocketResponse: Response {

    public func body() throws -> Data {
        Data()
    }

    public var statusCode: StatusCode {
        .switchingProtocols
    }
}

public final class WebSocket {
    public enum Message {
        case text(String)
        case data(Data)
    }

    let _messages: AsyncStream<Message>

    let inner: WebSocketKit.WebSocket

    init(inner: WebSocketKit.WebSocket) {
        self.inner = inner
        _messages = AsyncStream(Message.self, { continuation in
            inner.onBinary({ ws, bytes in
                continuation.yield(.data(Data(bytes.readableBytesView)))
            })

            inner.onText({ ws, text in
                continuation.yield(.text(text))
            })

            inner.onClose
                .whenComplete({ _ in
                    continuation.finish()
                })
        })
    }

    public var messages: AsyncStream<Message> {
        _messages
    }

    public var textMessages: AsyncCompactMapSequence<AsyncStream<WebSocket.Message>, String> {
        return _messages.compactMap({ message in
            switch message {
            case let .text(text):
                return text
            default:
                return nil
            }
        })
    }

    public func send(text: String) {
        inner.send(text)
    }

    public func send(data: Data) {
        inner.send(Array(data))
    }
}
