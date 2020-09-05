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

struct EmptyResponseTestRoute: Route {
    static let route: RouteMatcher = "/emptyResponse"
    
    func execute() throws -> Response {
        EmptyResponse()
    }
}

final class EmptyResponseRouteTests: XCTestCase {
    
    func makeChannel() throws -> EmbeddedChannel {
        let handler = HTTPHandler(routesByPrefix: ["": [
            EmptyResponseTestRoute.self,
        ]], errorRenderer: BasicErrorRenderer.self)
        
        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(handler).wait()
        
        return channel
    }
    
    func testBasic() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/emptyResponse", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .noContent)
        XCTAssertEqual(response.bodyString, "")
    }
}
