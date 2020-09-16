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

struct NoURLParameterRoute: Responder {

    func execute() throws -> Response {
        "This is a sample request with no url parameters."
    }
}

struct StringURLParameterRoute: Responder {

    @URLParameter(\.id) var id

    func execute() throws -> Response {
        "The ID is \(id)"
    }
}

struct IntURLParameterRoute: Responder {

    @URLParameter(\.number) var id

    func execute() throws -> Response {
        "The ID+1 is \(id+1)"
    }
}

struct MultipleURLParameterRoute: Responder {

    @URLParameter(\.number) var id
    @URLParameter(\.letter) var letter

    func execute() throws -> Response {
        "The ID+2 is \(id+2) and the letter is \(letter)"
    }
}

struct LetterURLParameterRoute: Responder {

    @URLParameter(\.letter) var grade

    func execute() throws -> Response {
        "The letter grade is \(grade)"
    }
}

class URLParameterRouteTests: XCTestCase {

    func makeWorld() throws -> World {
        return try World(routes: [
            StringURLParameterRoute()
                .on("/string/\(\.id)"),
            IntURLParameterRoute()
                .on("/int/\(\.number)"),
            LetterURLParameterRoute()
                .on("/letter/\(\.letter)"),
            MultipleURLParameterRoute()
                .on("/int/\(\.number)/letter/\(\.letter)"),
            NoURLParameterRoute()
                .on("/sample"),
        ])
    }

    func testString() throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/string/456", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ID is 456")
    }

    func testInt() throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/int/789", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ID+1 is 790")
    }

    func testIntFailing() throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/int/456a", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a url parameter that can decode to type Int.")
    }

    func testCustomType() throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/letter/B", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The letter grade is B")
    } 

    func testCustomTypeFails() throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/letter/E", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a url parameter that can decode to type LetterGrade.")
    }

    func testMultipleParametersSucceeds() throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/int/835/letter/D", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The ID+2 is 837 and the letter is D")
    }

    func testMultipleParametersFails() throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/int/835/letter/E", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a url parameter that can decode to type LetterGrade.")
    }

    func testNoURLParameters() throws {

        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/sample", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "This is a sample request with no url parameters.")
    }

    func testNotMatching() throws {
        let world = try self.makeWorld()

        let request = HTTPRequestBuilder(uri: "/not_found", method: .GET)
        try world.send(request)

        let response = try world.receive()
        XCTAssertEqual(response.statusCode, .notFound)
        XCTAssertEqual(response.bodyString, "No matching route was found.")
    }

}
