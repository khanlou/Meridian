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

struct RedirectResponseTestRoute: Route {
    static let route: RouteMatcher = "/redirect"
    
    func execute() throws -> Response {
        Redirect.temporary(url: URL(string: "https://example.com")!)
    }
}

final class RedirectRouteTests: XCTestCase {
    
    func makeChannel() throws -> EmbeddedChannel {
        let handler = HTTPHandler(routes: [
            RedirectResponseTestRoute.self,
        ], errorRenderer: BasicErrorRenderer.self)
        
        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(handler).wait()
        
        return channel
    }
    
    func testBasic() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/redirect", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssert(response.headers.contains(where: { $0.name == "Location" && $0.value == "https://example.com" }))
        XCTAssertEqual(response.statusCode, .temporaryRedirect)
        XCTAssertEqual(response.bodyString, "")
    }
}
