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

struct CustomResponseHeaderTestRoute: Responder {
    func execute() throws -> Response {
        "Hello"
            .additionalHeaders(["X-Custom-Header": "testing"])
            .additionalHeaders(["X-Custom-Header": "testing2"])
    }
}

final class CustomResponseHeaderTests: XCTestCase {
    
    func makeWorld() throws -> World {
        return try World(routes: [
            CustomResponseHeaderTestRoute()
                .on("/customHeader"),
        ])
    }
    
    func testBasic() async throws {
        
        let world = try self.makeWorld()
        
        try await world.send(HTTPRequestBuilder(uri: "/customHeader", method: .GET))

        let response = try await world.receive()

        XCTAssertEqual(response.headers.first(where: { name, value in name == "X-Custom-Header"})?.value, "testing2", "The last header in the stack should win.")
        XCTAssertEqual(response.bodyString, "Hello")
    }
}
