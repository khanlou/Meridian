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

struct CustomStatusCodeTestRoute: Responder {
    func execute() throws -> Response {
        "Hello"
            .statusCode(.conflict)
            .statusCode(.imATeapot)
    }
}

final class CustomStatusCodeRouteTests: XCTestCase {
    
    func makeWorld() throws -> World {
        return try World(routes: [
            CustomStatusCodeTestRoute()
                .on("/statusCode"),
        ])
    }
    
    func testBasic() async throws {
        
        let world = try self.makeWorld()
        
        try world.send(HTTPRequestBuilder(uri: "/statusCode", method: .GET))

        let response = try await world.receive()

        XCTAssertEqual(response.statusCode, .imATeapot)
        XCTAssertEqual(response.bodyString, "Hello")
    }
}
