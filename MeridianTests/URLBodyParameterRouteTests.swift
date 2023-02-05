//
//  URLBodyParameterRouteTests.swift
//  
//
//  Created by Soroush Khanlou on 9/2/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct StringBodyParameterRoute: Responder {
    
    @URLBodyParameter("name") var name: String
    
    func execute() throws -> Response {
        "The name is \(name)"
    }
}

struct IntBodyParameterRoute: Responder {

    @URLBodyParameter("number") var number: Int
    
    func execute() throws -> Response {
        "The number + 1 is \(number+1)"
    }
}

struct MusicNoteBodyParameterRoute: Responder {

    @URLBodyParameter("note") var note: MusicNote
    
    func execute() throws -> Response {
        "The note is \(note)"
    }
}

struct OptionalBodyParameterRoute: Responder {

    @URLBodyParameter("note") var note: MusicNote?

    func execute() throws -> Response {
        if let note = note {
            return "The note was present and is \(note)"
        } else {
            return "The note was not included"
        }
    }
}

struct OptionalWithDefaultBodyParameterRoute: Responder {

    @URLBodyParameter("note") var note: MusicNote = .E

    func execute() throws -> Response {
        return "The note was \(note)"
    }
}

struct MultipleBodyParameterRoute: Responder {
    
    @URLBodyParameter("note") var note: MusicNote
    @URLBodyParameter("number") var number: Int
    
    func execute() throws -> Response {
        "The note is \(note) and the number+3 is \(number+3)"
    }
}

class URLBodyParameterRouteTests: XCTestCase {

    let headers = ["Content-Type": "application/x-www-form-urlencoded"]

    func makeWorld() throws -> World {
        return try World(routes: [
            StringBodyParameterRoute()
                .on("/string"),
            IntBodyParameterRoute()
                .on("/int"),
            MusicNoteBodyParameterRoute()
                .on("/play"),
            OptionalBodyParameterRoute()
                .on("/play_optional"),
            OptionalWithDefaultBodyParameterRoute()
                .on("/optional_with_default"),
            MultipleBodyParameterRoute()
                .on("/multiple_parameter"),
        ])
    }

    func testString() async throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/string", method: .GET, headers: headers, bodyString: "name=testing")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The name is testing")
    }

    func testEmptyStringIsValidValue() async throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/string", method: .GET, headers: headers, bodyString: "name=")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The name is ")
    }

    func testMissingHeaders() async throws {
        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/string", method: .GET, bodyString: "name=testing")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint requires a URL-encoded body and a \"Content-Type\" of \"application/x-www-form-urlencoded\".")

    }
    
    func testInt() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/int", method: .GET, headers: headers, bodyString: "number=451")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The number + 1 is 452")
    }
    
    func testIntFailing() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/int", method: .GET, headers: headers, bodyString: "number=456a")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a URL encoded parameter named \"number\" to decode to type Int.")
    }
    
    func testCustomType() async throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/play", method: .GET, headers: headers, bodyString: "note=B")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note is B")
    }

    func testOptionalCustomTypeWithDefaultPresent() async throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/optional_with_default", method: .GET, headers: headers, bodyString: "note=B")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was B")
    }

    func testOptionalCustomTypeWithDefaultMissing() async throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/optional_with_default", method: .GET, headers: headers, bodyString: "")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was E")
    }

    func testCustomTypeFails() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/play", method: .GET, headers: headers, bodyString: "note=H")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a URL encoded parameter named \"note\" to decode to type MusicNote.")
    }
    
    func testMultiple() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/multiple_parameter", method: .GET, headers: headers, bodyString: "note=F&number=30")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note is F and the number+3 is 33")
    }
    
    func testOptionalMissing() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/play_optional", method: .GET, headers: headers, bodyString: "")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was not included")
    }
    
    func testOptionalPresent() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/play_optional", method: .GET, headers: headers, bodyString: "note=A")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was present and is A")
    }
    
    func testNotMatching() async throws {
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/not_found", method: .GET, headers: headers, bodyString: "")
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .notFound)
        XCTAssertEqual(response.bodyString, "No matching route was found.")
    }
    
}
