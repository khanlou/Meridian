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
    
    func makeWorld() throws -> World {
        return try World(routes: [
            JSONBodyTestRoute()
                .on("/json_body"),
            OptionalJSONBodyTestRoute()
                .on("/optional_json_body"),
        ])
    }

    func testBasic() async throws {
        
        let world = try self.makeWorld()

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
        
        try world.send(HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ints are [3, 8, 13]")
    }
    
    func testMissingHeader() async throws {
        
        let world = try self.makeWorld()

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
        
        try world.send(HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: [:], bodyData: data))
        
        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint requires a JSON body and a \"Content-Type\" of \"application/json\".")
    }
    
    func testBadMethod() async throws {
        
        let world = try self.makeWorld()

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
        
        try world.send(HTTPRequestBuilder(uri: "/json_body", method: .GET, headers: ["Content-Type": "application/json"], bodyData: data))
        
        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a body and a method of POST. However, it received a GET.")
    }
    
    func testBadJSON() async throws {
        
        let world = try self.makeWorld()

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
        
        try world.send(HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))
        
        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects JSON with a value at the objects[0].thing, but it was missing.")
    }
    
    func testMissingBody() async throws {
        
        let world = try self.makeWorld()

        try world.send(HTTPRequestBuilder(uri: "/json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: Data()))
        
        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a JSON body.")
    }

    func testOptionalBodyMissing() async throws {

        let world = try self.makeWorld()

        try world.send(HTTPRequestBuilder(uri: "/optional_json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: Data()))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The value is missing")
    }

    func testOptionalBodyPresent() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "objects": [
                { "thing": 8 },
                { "thing": 13 },
            ]
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/optional_json_body", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The value is present and the ints are [8, 13]")
    }

}
