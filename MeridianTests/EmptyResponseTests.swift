//
//  EmptyResponseTests.swift
//
//
//  Created by Soroush Khanlou on 9/3/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct EmptyResponseTestRoute: Responder {    
    func execute() throws -> Response {
        EmptyResponse()
    }
}

final class EmptyResponseRouteTests: XCTestCase {
    
    func makeWorld() throws -> World {
        return try World(routes: [
            EmptyResponseTestRoute()
                .on("/emptyResponse"),
        ])
    }
    
    func testBasic() async throws {
        
        let world = try self.makeWorld()
        
        try await world.send(HTTPRequestBuilder(uri: "/emptyResponse", method: .GET))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .noContent)
        XCTAssertEqual(response.bodyString, "")
    }
}
