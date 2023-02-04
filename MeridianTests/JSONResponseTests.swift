//
//  JSONResponseTests.swift
//
//
//  Created by Soroush Khanlou on 9/3/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct JSONResponseTestRoute: Responder {
    
    func execute() throws -> Response {
        JSON(JSONExample(objects: [JSONExample.InnerObject(thing: 3)]))
    }
}

final class JSONResponseRouteTests: XCTestCase {
    
    func makeWorld() throws -> World {
        return try World(routes: [
            JSONResponseTestRoute()
                .on("/customJSON"),
        ])
    }

    func testBasic() async throws {
        
        let world = try self.makeWorld()
        
        try world.send(HTTPRequestBuilder(uri: "/customJSON", method: .GET))
        
        let response = try await world.receive()
        XCTAssert(response.headers.contains(where: { $0.name == "Content-Type" && $0.value == "application/json" }))
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "{\"objects\":[{\"thing\":3}]}")
    }
}
