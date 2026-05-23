//
//  RequestIDTests.swift
//  Meridian
//
//  Created by Soroush Khanlou on 5/18/26.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct RequestIDTestRoute: Responder {

    @RequestID var requestID

    func execute() throws -> Response {
        requestID
    }
}

final class RequestIDTests: XCTestCase {

    func makeWorld() throws -> World {
        try World(builder: {
            RequestIDTestRoute()
                .on("/request-id")
        })
    }

    func testIgnoresIncomingRequestID() async throws {
        let world = try makeWorld()
        let incomingRequestID = makeRandomString()

        try await world.send(HTTPRequestBuilder(
            uri: "/request-id",
            method: .GET,
            headers: ["X-Request-ID": incomingRequestID]
        ))

        let response = try await world.receive()
        let requestID = try XCTUnwrap(response.bodyString)

        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertNotEqual(requestID, incomingRequestID)
        XCTAssertNotNil(UUID(uuidString: requestID))
        XCTAssertNil(response.headers.first(where: { $0.name == "X-Request-ID" }))
    }

    func testGeneratesRequestIDPerRequest() async throws {
        let world = try makeWorld()

        try await world.send(HTTPRequestBuilder(uri: "/request-id", method: .GET))
        let firstResponse = try await world.receive()

        try await world.send(HTTPRequestBuilder(uri: "/request-id", method: .GET))
        let secondResponse = try await world.receive()

        let firstID = try XCTUnwrap(firstResponse.bodyString)
        let secondID = try XCTUnwrap(secondResponse.bodyString)

        XCTAssertNotNil(UUID(uuidString: firstID))
        XCTAssertNotNil(UUID(uuidString: secondID))
        XCTAssertNotEqual(firstID, secondID)
        XCTAssertNil(firstResponse.headers.first(where: { $0.name == "X-Request-ID" }))
        XCTAssertNil(secondResponse.headers.first(where: { $0.name == "X-Request-ID" }))
    }
}
