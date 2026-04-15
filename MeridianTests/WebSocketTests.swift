//
//  WebSocketTests.swift
//
//
//  Created by Soroush Khanlou on 4/14/26.
//

import XCTest
import NIO
import NIOHTTP1
import WebSocketKit
@testable import Meridian

// MARK: - Test WebSocket Responders

struct EchoWebSocket: WebSocketResponder {
    func connected(to webSocket: Meridian.WebSocket) async throws {
        for await message in webSocket.textMessages {
            webSocket.send(text: "Echo: \(message)")
        }
    }
}

struct EchoWithPathWebSocket: WebSocketResponder {
    @Path var path

    func connected(to webSocket: Meridian.WebSocket) async throws {
        for await message in webSocket.textMessages {
            webSocket.send(text: "Received \(message) at \(path)")
        }
    }
}

struct RejectingWebSocket: WebSocketResponder {
    func shouldConnect() async throws -> Bool {
        false
    }

    func connected(to webSocket: Meridian.WebSocket) async throws {
        // Should never be called
        XCTFail("connected() should not be called when shouldConnect returns false")
    }
}

// MARK: - Test Server Helper

final class WebSocketTestServer {
    let channel: Channel
    let port: Int
    let eventLoopGroup: MultiThreadedEventLoopGroup

    init(eventLoopGroup: MultiThreadedEventLoopGroup, @RouteBuilder routes: @Sendable @escaping () -> [_BuildableRoute]) throws {
        self.eventLoopGroup = eventLoopGroup

        var router = Router(defaultErrorRenderer: BasicErrorRenderer())
        router.register(routes)

        EnvironmentValues.shared.router = router
        EnvironmentValues.shared.loopGroup = eventLoopGroup

        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)

        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            .childChannelInitializer({ channel in
                let parsing = HTTPRequestParsingHandler()
                let http = HTTPHandler(router: router)

                return channel.pipeline
                    .configureHTTPServerPipeline(withServerUpgrade: (
                        upgraders: [WebSocketUpgrader(router: router)],
                        completionHandler: { context in
                            _ = context.pipeline.removeHandler(parsing)
                                .and(context.pipeline.removeHandler(http))
                        }
                    ))
                    .flatMap {
                        channel.pipeline.addHandlers([parsing, http])
                    }
            })
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(reuseAddrOpt, value: 1)

        self.channel = try bootstrap.bind(host: "127.0.0.1", port: 0).wait()

        guard let port = channel.localAddress?.port else {
            throw TestError.couldNotGetPort
        }
        self.port = port
    }

    func shutdown() throws {
        try channel.close().wait()
    }

    enum TestError: Error {
        case couldNotGetPort
    }
}

// MARK: - Tests

final class WebSocketTests: XCTestCase {

    var eventLoopGroup: MultiThreadedEventLoopGroup!

    override func setUp() {
        super.setUp()
        // Need at least 2 threads to avoid deadlock between client and server
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    }

    override func tearDown() {
        try? eventLoopGroup.syncShutdownGracefully()
        super.tearDown()
    }

    func testWebSocketEcho() async throws {
        let server = try WebSocketTestServer(eventLoopGroup: eventLoopGroup) {
            EchoWebSocket()
                .on(.get("/ws"))
        }
        defer { try? server.shutdown() }

        let receivedPromise = eventLoopGroup.next().makePromise(of: String.self)
        let closePromise = eventLoopGroup.next().makePromise(of: Void.self)

        WebSocketKit.WebSocket.connect(
            to: "ws://127.0.0.1:\(server.port)/ws",
            on: eventLoopGroup
        ) { ws in
            ws.onText { ws, text in
                receivedPromise.succeed(text)
                ws.close(promise: closePromise)
            }
            ws.send("Hello")
        }.whenFailure { error in
            receivedPromise.fail(error)
        }

        let received = try await receivedPromise.futureResult.get()
        XCTAssertEqual(received, "Echo: Hello")

        try await closePromise.futureResult.get()
    }

    func testWebSocketMultipleMessages() async throws {
        let server = try WebSocketTestServer(eventLoopGroup: eventLoopGroup) {
            EchoWebSocket()
                .on(.get("/ws"))
        }
        defer { try? server.shutdown() }

        let messagesPromise = eventLoopGroup.next().makePromise(of: [String].self)
        let closePromise = eventLoopGroup.next().makePromise(of: Void.self)

        let testMessages = ["First", "Second", "Third"]

        WebSocketKit.WebSocket.connect(
            to: "ws://127.0.0.1:\(server.port)/ws",
            on: eventLoopGroup
        ) { ws in
            var received: [String] = []
            let expectedCount = testMessages.count

            ws.onText { ws, text in
                received.append(text)
                if received.count >= expectedCount {
                    messagesPromise.succeed(received)
                    ws.close(promise: closePromise)
                }
            }

            for message in testMessages {
                ws.send(message)
            }
        }.whenFailure { error in
            messagesPromise.fail(error)
        }

        let received = try await messagesPromise.futureResult.get()
        XCTAssertEqual(received, ["Echo: First", "Echo: Second", "Echo: Third"])

        try await closePromise.futureResult.get()
    }

    func testWebSocketWithPathParameter() async throws {
        let server = try WebSocketTestServer(eventLoopGroup: eventLoopGroup) {
            EchoWithPathWebSocket()
                .on(.get("/ws"))
        }
        defer { try? server.shutdown() }

        let receivedPromise = eventLoopGroup.next().makePromise(of: String.self)
        let closePromise = eventLoopGroup.next().makePromise(of: Void.self)

        WebSocketKit.WebSocket.connect(
            to: "ws://127.0.0.1:\(server.port)/ws",
            on: eventLoopGroup
        ) { ws in
            ws.onText { ws, text in
                receivedPromise.succeed(text)
                ws.close(promise: closePromise)
            }
            ws.send("Test")
        }.whenFailure { error in
            receivedPromise.fail(error)
        }

        let received = try await receivedPromise.futureResult.get()
        XCTAssertEqual(received, "Received Test at /ws")

        try await closePromise.futureResult.get()
    }

    func testWebSocketConnectionRejected() async throws {
        let server = try WebSocketTestServer(eventLoopGroup: eventLoopGroup) {
            RejectingWebSocket()
                .on(.get("/ws"))
        }
        defer { try? server.shutdown() }

        let connectionPromise = eventLoopGroup.next().makePromise(of: Bool.self)

        WebSocketKit.WebSocket.connect(
            to: "ws://127.0.0.1:\(server.port)/ws",
            on: eventLoopGroup
        ) { ws in
            // If we get here, connection succeeded (which we don't expect)
            connectionPromise.succeed(true)
            ws.close(promise: nil)
        }.whenFailure { error in
            // Connection should fail because shouldConnect returns false
            connectionPromise.succeed(false)
        }

        let connected = try await connectionPromise.futureResult.get()
        XCTAssertFalse(connected, "WebSocket connection should have been rejected")
    }

    func testWebSocketNonExistentRoute() async throws {
        let server = try WebSocketTestServer(eventLoopGroup: eventLoopGroup) {
            EchoWebSocket()
                .on(.get("/ws"))
        }
        defer { try? server.shutdown() }

        let connectionPromise = eventLoopGroup.next().makePromise(of: Bool.self)

        WebSocketKit.WebSocket.connect(
            to: "ws://127.0.0.1:\(server.port)/nonexistent",
            on: eventLoopGroup
        ) { ws in
            // If we get here, connection succeeded (which we don't expect)
            connectionPromise.succeed(true)
            ws.close(promise: nil)
        }.whenFailure { error in
            // Connection should fail because route doesn't exist
            connectionPromise.succeed(false)
        }

        let connected = try await connectionPromise.futureResult.get()
        XCTAssertFalse(connected, "WebSocket connection to non-existent route should fail")
    }
}
