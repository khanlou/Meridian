//
//  HTTPMethodRouteTests.swift
//  
//
//  Created by Soroush Khanlou on 9/15/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct HTTPMethodTestRoute: Responder {

    @RequestMethod var method

    func execute() throws -> Response {
        "The method was \(method)"
    }
}

final class HTTPMethodRouteTests: XCTestCase {

    func makeWorld() throws -> World {
        return try World(routes: [
            HTTPMethodTestRoute()
                .on("/method"),
        ])
    }

    func testRandomly() async throws {

        let world = try self.makeWorld()

        let method = Meridian.HTTPMethod.primaryMethods.randomElement()!

        try await world.send(HTTPRequestBuilder(uri: "/method", method: NIOHTTP1.HTTPMethod(rawValue: method.name)))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The method was \(method)")
    }
}
