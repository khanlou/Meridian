//
//  RequestStateTests.swift
//  Meridian
//
//  Created by Soroush Khanlou on 5/18/26.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct RequestStateMessageKey: RequestStateKey {
    static var defaultValue: String? {
        nil
    }
}

struct RequestStateTraceKey: RequestStateKey {
    static var defaultValue: [String] {
        []
    }
}

extension RequestStateValues {
    var message: String? {
        get {
            self[RequestStateMessageKey.self]
        }
        set {
            self[RequestStateMessageKey.self] = newValue
        }
    }

    var trace: [String] {
        get {
            self[RequestStateTraceKey.self]
        }
        set {
            self[RequestStateTraceKey.self] = newValue
        }
    }
}

struct StoreRequestStateMiddleware: Middleware {

    @RequestState(\.message) var message
    @RequestState(\.trace) var trace

    func execute(next: Responder) async throws -> Response {
        message = "stored in middleware"
        trace = trace + ["first"]
        return try await next.execute()
    }
}

struct ReadRequestStateMiddleware: Middleware {

    @RequestState(\.message) var message
    @RequestState(\.trace) var trace

    func execute(next: Responder) async throws -> Response {
        trace = trace + ["second:\(message ?? "missing")"]
        return try await next.execute()
    }
}

struct HeaderRequestStateMiddleware: Middleware {

    @RequestState(\.trace) var trace

    func execute(next: Responder) async throws -> Response {
        let response = try await next.execute()
        return response.additionalHeaders(["Trace": trace.joined(separator: ",")])
    }
}

struct RequestStateTestRoute: Responder {

    @RequestState(\.message) var message
    @RequestState(\.trace) var trace

    func execute() throws -> Response {
        trace = trace + ["route:\(message ?? "missing")"]
        return trace.joined(separator: ",")
    }
}

final class RequestStateTests: XCTestCase {

    let expectedTrace = "first,second:stored in middleware,route:stored in middleware"

    func makeWorld() throws -> World {
        try World(builder: {
            RequestStateTestRoute()
                .on("/request-state")
        }, middlewareProducers: [
            StoreRequestStateMiddleware.init,
            ReadRequestStateMiddleware.init,
            HeaderRequestStateMiddleware.init,
        ])
    }

    func testRequestStateIsSharedAcrossMiddlewaresAndRoute() async throws {
        let world = try makeWorld()

        try await world.send(HTTPRequestBuilder(uri: "/request-state", method: .GET))

        let response = try await world.receive()

        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, expectedTrace)
        XCTAssertEqual(response.headers.first(where: { $0.name == "Trace" })?.value, expectedTrace)
    }

    func testRequestStateDoesNotLeakBetweenRequests() async throws {
        let world = try makeWorld()

        try await world.send(HTTPRequestBuilder(uri: "/request-state", method: .GET))
        let firstResponse = try await world.receive()

        try await world.send(HTTPRequestBuilder(uri: "/request-state", method: .GET))
        let secondResponse = try await world.receive()

        XCTAssertEqual(firstResponse.bodyString, expectedTrace)
        XCTAssertEqual(secondResponse.bodyString, expectedTrace)
    }
}
