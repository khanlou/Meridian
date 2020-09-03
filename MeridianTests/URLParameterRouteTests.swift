//
//  URLParameterRouteTests.swift
//  
//
//  Created by Soroush Khanlou on 9/2/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct NoURLParameterRoute: Route {
    static let route: RouteMatcher = "/sample"

    func execute() throws -> Response {
        "This is a sample request with no url parameters."
    }
}

struct StringURLParameterRoute: Route {
    static let route: RouteMatcher = "/string/\(.id)"

    @URLParameter(key: .id) var id: String

    func execute() throws -> Response {
        "The ID is \(id)"
    }
}

struct IntURLParameterRoute: Route {
    static let route: RouteMatcher = "/int/\(.id)"

    @URLParameter(key: .id) var id: Int

    func execute() throws -> Response {
        "The ID+1 is \(id+1)"
    }
}

struct MultipleURLParameterRoute: Route {
    static let route: RouteMatcher = "/int/\(.id)/letter/\(.letter)"

    @URLParameter(key: .id) var id: Int
    @URLParameter(key: .letter) var letter: LetterGrade

    func execute() throws -> Response {
        "The ID+2 is \(id+2) and the letter is \(letter)"
    }
}

struct LetterURLParameterRoute: Route {
    static let route: RouteMatcher = "/letter/\(.letter)"

    @URLParameter(key: .letter) var grade: LetterGrade

    func execute() throws -> Response {
        "The letter grade is \(grade)"
    }
}

class URLParameterRouteTests: XCTestCase {

    func makeWorld() throws -> (EmbeddedChannel, RecordingHandler<HTTPServerRequestPart, HTTPServerResponsePart>) {
        let handler = HTTPHandler(routes: [
            StringURLParameterRoute.self,
            IntURLParameterRoute.self,
            LetterURLParameterRoute.self,
            MultipleURLParameterRoute.self,
            NoURLParameterRoute.self,
        ], errorRenderer: BasicErrorRenderer.self)
        let recorder = RecordingHandler<HTTPServerRequestPart, HTTPServerResponsePart>()

        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(recorder).wait()
        try channel.pipeline.addHandler(handler).wait()

        return (channel, recorder)
    }

    func testString() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/string/456", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ID is 456")
    }

    func testInt() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/int/789", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ID+1 is 790")
    }

    func testIntFailing() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/int/456a", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a url parameter that can decode to type Int.")
    }

    func testCustomType() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/letter/B", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The letter grade is B")
    }

    func testCustomTypeFails() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/letter/E", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a url parameter that can decode to type LetterGrade.")
    }

    func testMultipleParametersSucceeds() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/int/835/letter/D", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ID+2 is 837 and the letter is D")
    }

    func testMultipleParametersFails() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/int/835/letter/E", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a url parameter that can decode to type LetterGrade.")
    }

    func testNoURLParameters() throws {

        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/sample", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "This is a sample request with no url parameters.")
    }

    func testNotMatching() throws {
        let (channel, recorder) = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/not_found", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: recorder.writes[0], body: recorder.writes[1], end: recorder.writes[2])
        XCTAssertEqual(response.statusCode, .notFound)
        XCTAssertEqual(response.bodyString, "No matching route was found.")
    }

}
