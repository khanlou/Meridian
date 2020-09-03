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

    func makeWorld() throws -> (EmbeddedChannel, RecordingHandler<HTTPServerRequestPart, HTTPServerResponsePart>) {
        let handler = HTTPHandler(routes: [
            EmptyResponseTestRoute.self,
        ], errorRenderer: BasicErrorRenderer.self)
        let recorder = RecordingHandler<HTTPServerRequestPart, HTTPServerResponsePart>()

        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(recorder).wait()
        try channel.pipeline.addHandler(handler).wait()

        return (channel, recorder)
    }

    func testBasic() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/emptyResponse", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .noContent)
        XCTAssertEqual(response.bodyString, "")
    }
}
