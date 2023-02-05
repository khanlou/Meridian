//
//  RedirectResponseTests.swift
//  
//
//  Created by Soroush Khanlou on 9/3/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct RedirectResponseTestRoute: Responder {
    
    func execute() throws -> Response {
        Redirect.temporary(url: URL(string: "https://example.com")!)
    }
}

final class RedirectRouteTests: XCTestCase {
    
    func makeWorld() throws -> World {
        return try World(routes: [
            RedirectResponseTestRoute()
                .on("/redirect"),
        ])
    }

    func testBasic() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/redirect", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssert(response.headers.contains(where: { $0.name == "Location" && $0.value == "https://example.com" }))
        XCTAssertEqual(response.statusCode, .temporaryRedirect)
        XCTAssertEqual(response.bodyString, "")
    }
}
