//
//  JSONBodyRouteTests.swift
//  
//
//  Created by Soroush Khanlou on 9/3/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct JSONExample: Codable {
    struct InnerObject: Codable {
        let thing: Int
    }

    var objects: [InnerObject]
}

struct JSONBodyTestRoute: Route {
    static let route: RouteMatcher = "/json_body"

    @JSONBody var content: JSONExample

    func execute() throws -> Response {
        "The ints are \(content.objects.map({ $0.thing }))"
    }
}

final class JSONBodyRouteTests: XCTestCase {

    func makeWorld() throws -> (EmbeddedChannel, RecordingHandler<HTTPServerRequestPart, HTTPServerResponsePart>) {
        let handler = HTTPHandler(routes: [
            JSONBodyTestRoute.self,
        ], errorRenderer: BasicErrorRenderer.self)
        let recorder = RecordingHandler<HTTPServerRequestPart, HTTPServerResponsePart>()

        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(recorder).wait()
        try channel.pipeline.addHandler(handler).wait()

        return (channel, recorder)
    }

    func testBasic() throws {

        let (channel, recorder) = try self.makeWorld()

        let json = """
        {
            "objects": [
                { "thing": 3 },
                { "thing": 8 },
                { "thing": 13 },
            ]
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        let request = HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ints are [3, 8, 13]")
    }

    func testMissingHeader() throws {

        let (channel, recorder) = try self.makeWorld()

        let json = """
        {
            "objects": [
                { "thing": 3 },
                { "thing": 8 },
                { "thing": 13 },
            ]
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        let request = HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: [:], bodyData: data)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint requires a JSON body and a \"Content-Type\" of \"application/json\".")
    }

    func testBadMethod() throws {

        let (channel, recorder) = try self.makeWorld()

        let json = """
        {
            "objects": [
                { "thing": 3 },
                { "thing": 8 },
                { "thing": 13 },
            ]
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        let request = HTTPRequestBuilder(uri: "/json_body", method: .GET, headers: ["Content-Type": "application/json"], bodyData: data)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a body and a method of POST. However, it received a GET.")
    }

    func testBadJSON() throws {

        let (channel, recorder) = try self.makeWorld()

        let json = """
        {
            "objects": [
                { "badThing": 3 },
                { "thing": 8 },
                { "thing": 13 },
            ]
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        let request = HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects JSON with a value at the objects[0].thing, but it was missing.")
    }

    func testMissingBody() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: Data())
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a JSON body.")
    }
}
