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

struct JSONResponseTestRoute: Route {
    static let route: RouteMatcher = "/customJSON"
    
    func execute() throws -> Response {
        JSON(JSONExample(objects: [JSONExample.InnerObject(thing: 3)]))
    }
}

final class JSONResponseRouteTests: XCTestCase {
    
    func makeChannel() throws -> EmbeddedChannel {
        let handler = HTTPHandler(routes: [
            JSONResponseTestRoute.self,
        ], errorRenderer: BasicErrorRenderer.self)
        
        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(handler).wait()
        
        return channel
    }
    
    func testBasic() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/customJSON", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssert(response.headers.contains(where: { $0.name == "Content-Type" && $0.value == "application/json" }))
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "{\"objects\":[{\"thing\":3}]}")
    }
}
