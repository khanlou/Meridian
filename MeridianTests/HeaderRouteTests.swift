//
//  HeaderRouteTests.swift
//  
//
//  Created by Soroush Khanlou on 9/15/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct HeaderTestRoute: Responder {

    @Header("X-Custom-Header") var header: String

    func execute() throws -> Response {
        "The header was \(header)"
    }
}

final class HeaderRouteTests: XCTestCase {

    func makeWorld() throws -> World {
        return try World(routes: [
            HeaderTestRoute()
                .on("/header"),
        ])
    }

    func testRandomly() async throws {

        let world = try self.makeWorld()

        let string = makeRandomString()
        try world.send(HTTPRequestBuilder(uri: "/header", method: .GET, headers: ["X-Custom-Header": string]))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The header was \(string)")
    }
}
