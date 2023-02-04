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

struct JSONValueRoute: Responder {
    
    @JSONValue("name") var name: String
    
    func execute() throws -> Response {
        "The name is \(name)"
    }
}

struct OptionalJSONValueRoute: Responder {

    @JSONValue("note") var note: MusicNote?

    func execute() throws -> Response {
        if let note = note {
            return "The note was present and is \(note)"
        } else {
            return "The note was not included"
        }
    }
}

struct MultipleJSONValueRoute: Responder {

    @JSONValue("note") var note: MusicNote
    @JSONValue("person.age") var age: Int

    func execute() throws -> Response {
        "The note is \(note) and the age+3 is \(age+3)"
    }
}

struct BoolJSONValueRoute: Responder {

    @JSONValue("sayHi") var shouldSayHello: Bool

    func execute() throws -> Response {
        if shouldSayHello {
            return "Hi"
        } else {
            return "Not saying hi"
        }
    }
}

struct OptionalBoolJSONValueRoute: Responder {

    @JSONValue("shouldUpdate") var shouldUpdate: Bool?

    func execute() throws -> Response {
        switch shouldUpdate {
        case true?:
            return "Updating"
        case false?:
            return "Not updating"
        case nil:
            return "Not specified"
        }
    }
}


class JSONValueRouteTests: XCTestCase {
    
    func makeWorld() throws -> World {
        return try World(routes: [
            JSONValueRoute()
                .on("/json_value"),
            OptionalJSONValueRoute()
                .on("/optional"),
            MultipleJSONValueRoute()
                .on("/multiple"),
            BoolJSONValueRoute()
                .on("/hi"),
            OptionalBoolJSONValueRoute()
                .on("/optional_bool")
        ])
    }

    func testString() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "name": "hello"
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/json_value", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The name is hello")
    }

    func testBodyMissing() async throws {

        let world = try self.makeWorld()

        try world.send(HTTPRequestBuilder(uri: "/json_value", method: .POST, headers: ["Content-Type": "application/json"]))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a JSON body.")
    }

    func testKeyMissing() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "name2": "hello"
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/json_value", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a JSON body with a value of type String at key path \"name\" but did not find one.")
    }

    func testMultiple() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "person": {
                "age": 2
            },
            "note": "F"
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/multiple", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note is F and the age+3 is 5")
    }

    func testNestedMissing() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "person2": {
                "age": 2
            },
            "note": "F"
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/multiple", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a JSON body with a value of type Int at key path \"person.age\" but did not find one.")
    }

    func testNestedWrongType() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "person": {
                "age": "test"
            },
            "note": "F"
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/multiple", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a JSON body with a value at key path \"person.age\" with the expected type Int, but did not find the right type.")
    }

    func testOptionalMissing() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "age": 2
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/optional", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was not included")
    }

    func testOptionalPresent() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "age": 2,
            "note": "D",
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/optional", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was present and is D")
    }

    func testOptionalPresentButNotDecoding() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "age": 2,
            "note": "H",
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/optional", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a JSON body with a value at key path \"note\" with the expected type Optional<MusicNote>, but did not find the right type.")
    }

    func testBool() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "sayHi": true
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/hi", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "Hi")
    }

    func testOptionalBoolTrue() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "shouldUpdate": true
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/optional_bool", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "Updating")
    }

    func testOptionalBoolFalse() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "shouldUpdate": false
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/optional_bool", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "Not updating")
    }

    func testOptionalBoolMissing() async throws {

        let world = try self.makeWorld()

        let json = """
        {
            "someOtherKey": 1,
        }
        """

        let data = json.data(using: .utf8) ?? Data()

        try world.send(HTTPRequestBuilder(uri: "/optional_bool", method: .POST, headers: ["Content-Type": "application/json"], bodyData: data))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "Not specified")
    }
}
