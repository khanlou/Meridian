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

struct JSONBodyTestRoute: Responder {

    @JSONBody var content: JSONExample

    func execute() throws -> Response {
        "The ints are \(content.objects.map({ $0.thing }))"
    }
}

struct OptionalJSONBodyTestRoute: Responder {

    @JSONBody var content: JSONExample?

    func execute() throws -> Response {
        if let content = content {
            return "The value is present and the ints are \(content.objects.map({ $0.thing }))"
        } else {
            return "The value is missing"
        }
    }
}

final class JSONBodyRouteTests: XCTestCase {
    
    func makeChannel() throws -> EmbeddedChannel {
        let handler = HTTPHandler(routesByPrefix: ["": [
            JSONBodyTestRoute()
                .on("/json_body"),
            OptionalJSONBodyTestRoute()
                .on("/optional_json_body"),
        ]], errorRenderer: BasicErrorRenderer.self)
        
        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(handler).wait()
        
        return channel
    }
    
    func testBasic() throws {
        
        let channel = try self.makeChannel()
        
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
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ints are [3, 8, 13]")
    }
    
    func testMissingHeader() throws {
        
        let channel = try self.makeChannel()
        
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
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint requires a JSON body and a \"Content-Type\" of \"application/json\".")
    }
    
    func testBadMethod() throws {
        
        let channel = try self.makeChannel()
        
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
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a body and a method of POST. However, it received a GET.")
    }
    
    func testBadJSON() throws {
        
        let channel = try self.makeChannel()
        
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
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects JSON with a value at the objects[0].thing, but it was missing.")
    }
    
    func testMissingBody() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: Data())
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a JSON body.")
    }

    func testOptionalBodyMissing() throws {

        let channel = try self.makeChannel()

        let request = HTTPRequestBuilder(uri: "/optional_json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: Data())
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The value is missing")
    }

    func testOptionalBodyPresent() throws {

        let channel = try self.makeChannel()

        let json = """
        {
            "objects": [
                { "thing": 8 },
                { "thing": 13 },
            ]
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        let request = HTTPRequestBuilder(uri: "/optional_json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)

        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The value is present and the ints are [8, 13]")
    }

}
