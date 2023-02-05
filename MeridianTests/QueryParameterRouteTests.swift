//
//  QueryParameterRouteTests.swift
//  
//
//  Created by Soroush Khanlou on 9/2/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct StringQueryParameterRoute: Responder {
    
    @QueryParameter("name") var name: String
    
    func execute() throws -> Response {
        "The name is \(name)"
    }
}

struct IntQueryParameterRoute: Responder {

    @QueryParameter("number") var number: Int
    
    func execute() throws -> Response {
        "The number + 1 is \(number+1)"
    }
}

struct MusicNoteQueryParameterRoute: Responder {

    @QueryParameter("note") var note: MusicNote
    
    func execute() throws -> Response {
        "The note is \(note)"
    }
}

struct OptionalParameterRoute: Responder {

    @QueryParameter("note") var note: MusicNote?

    func execute() throws -> Response {
        if let note = note {
            return "The note was present and is \(note)"
        } else {
            return "The note was not included"
        }
    }
}

struct OptionalWithDefaultParameterRoute: Responder {

    @QueryParameter("note") var note: MusicNote = .E

    func execute() throws -> Response {
        return "The note was \(note)"
    }
}

struct MultipleParameterRoute: Responder {
    
    @QueryParameter("note") var note: MusicNote
    @QueryParameter("number") var number: Int
    
    func execute() throws -> Response {
        "The note is \(note) and the number+3 is \(number+3)"
    }
}

struct OptionalFlagParameterRoute: Responder {
    
    @QueryParameter("flag") var flag: Present?
    
    func execute() throws -> Response {
        if flag.isPresent {
            return "The flag was present"
        } else {
            return "The flag was missing"
        }
    }
}

struct RequiredFlagParameterRoute: Responder {

    @QueryParameter("flag") var flag: Present

    func execute() throws -> Response {
        "The flag is required to get to here"
    }
}

class QueryParameterRouteTests: XCTestCase {
    
    func makeWorld() throws -> World {
        return try World(routes: [
            StringQueryParameterRoute()
                .on("/string"),
            IntQueryParameterRoute()
                .on("/int"),
            MusicNoteQueryParameterRoute()
                .on("/play"),
            OptionalParameterRoute()
                .on("/play_optional"),
            OptionalWithDefaultParameterRoute()
                .on("/optional_with_default"),
            MultipleParameterRoute()
                .on("/multiple_parameter"),
            OptionalFlagParameterRoute()
                .on("/optional_flag"),
            RequiredFlagParameterRoute()
                .on("/required_flag"),
        ])
    }

    func testString() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/string?name=testing", method: .GET)
        try await world.send(request)
        
        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The name is testing")
    }
    
    func testInt() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/int?number=451", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The number + 1 is 452")
    }
    
    func testIntFailing() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/int?number=456a", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a query parameter named \"number\" to decode to type Int.")
    }
    
    func testCustomType() async throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/play?note=B", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note is B")
    }

    func testOptionalCustomTypeWithDefaultPresent() async throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/optional_with_default?note=B", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was B")
    }

    func testOptionalCustomTypeWithDefaultMissing() async throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/optional_with_default", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was E")
    }

    func testCustomTypeFails() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/play?note=H", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a query parameter named \"note\" to decode to type MusicNote.")
    }
    
    func testMultiple() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/multiple_parameter?note=F&number=30", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note is F and the number+3 is 33")
    }
    
    func testOptionalMissing() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/play_optional", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was not included")
    }
    
    func testOptionalPresent() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/play_optional?note=A", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was present and is A")
    }
    
    func testOptionalFlagPresent() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/optional_flag?flag", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The flag was present")
    }
    
    func testOptionalFlagMissing() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/optional_flag", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The flag was missing")
    }
    
    func testRequiredFlagPresent() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/required_flag?flag", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The flag is required to get to here")
    }
    
    func testRequiredFlagWithUnneededValue() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/required_flag?flag=this_is_discarded", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The flag is required to get to here")
    }
    
    func testRequiredFlagMissing() async throws {
        
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/required_flag", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a query parameter named \"flag\", but it was missing.")
    }
    
    func testNotMatching() async throws {
        let world = try self.makeWorld()
        
        let request = HTTPRequestBuilder(uri: "/not_found", method: .GET)
        try await world.send(request)

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .notFound)
        XCTAssertEqual(response.bodyString, "No matching route was found.")
    }
    
}
