//
//  CustomStatusCodeTests.swift
//  
//
//  Created by Soroush Khanlou on 9/3/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct BasicRoute: Responder {
    func execute() throws -> Response {
        "Hello"
    }
}

final class OptionsRouteTests: XCTestCase {

    func makeWorld() throws -> World {
        return try World(builder: {
            BasicRoute()
                .on(.get("/"))
        })
    }

    func testBasic() async throws {
        
        let world = try self.makeWorld()
        
        try await world.send(HTTPRequestBuilder(uri: "/", method: .OPTIONS))

        let response = try await world.receive()

        XCTAssertEqual(response.statusCode, .noContent)
        XCTAssertEqual(response.bodyString, "")
        XCTAssertEqual(response.headers.first(where: { $0.name == "Allow" })?.value, "GET")
    }
}
