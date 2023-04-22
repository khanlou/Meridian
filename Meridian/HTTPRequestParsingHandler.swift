//
//  HTTPHandler.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/26/20.
//

import Foundation
import NIO
import NIOHTTP1

enum HTTPRequestParserUnrecoverableError: LocalizedError {
    case unexpectedPart(HTTPRequestParsingHandler.State, HTTPServerRequestPart)

    var errorDescription: String? {
        switch self {
        case .unexpectedPart(let state, let httpServerRequestPart):
            return "A part of \(httpServerRequestPart) was received while in the \(state) state."
        }
    }
}

struct ParsedHTTPRequest {
    let head: HTTPRequestHead
    let data: Data
}

final class HTTPRequestParsingHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = ParsedHTTPRequest

    enum State {
        case idle
        case headerReceived(HTTPRequestHead)
        case inProgress(HTTPRequestHead, Data)
        case complete(HTTPRequestHead, Data)
    }

    private var state = State.idle

    func updateState(with data: NIOAny) throws {
        let part = unwrapInboundIn(data)

        switch part {
        case let .head(head):
            switch state {
            case .idle:
                self.state = .headerReceived(head)
            default:
                throw HTTPRequestParserUnrecoverableError.unexpectedPart(state, part)
            }
        case let .body(byteBuffer):
            switch state {
            case let .headerReceived(head):
                self.state = .inProgress(head, Data(byteBuffer.readableBytesView))
            case let .inProgress(head, body):
                var body = body
                body.append(contentsOf: byteBuffer.readableBytesView)
                self.state = .inProgress(head, body)
            default:
                throw HTTPRequestParserUnrecoverableError.unexpectedPart(state, part)
            }
        case .end(_):
            switch state {
            case let .headerReceived(head):
                // what's the content length? can .body come twice?
                self.state = .complete(head, Data())
            case let .inProgress(head, body):
                self.state = .complete(head, body)
            default:
                throw HTTPRequestParserUnrecoverableError.unexpectedPart(state, part)
            }
        }
    }

    func dataIfReady() -> (HTTPRequestHead, Data)? {
        if case let .complete(head, data) = state {
            return (head, data)
        } else {
            return nil
        }
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {

        let channel = context.channel

        do {
            try self.updateState(with: data)
        } catch {
            assertionFailure(error.localizedDescription)
            try? channel.close().wait()
            return
        }
        if let (head, body) = dataIfReady() {
            let parsed = ParsedHTTPRequest(head: head, data: body)
            context.fireChannelRead(self.wrapInboundOut(parsed))
            self.state = .idle
        }
    }
}
