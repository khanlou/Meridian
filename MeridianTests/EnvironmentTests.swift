//
//  EnvironmentTests.swift
//  
//
//  Created by Soroush Khanlou on 9/3/20.
//

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

struct NumberFormatterEnvironmentKey: EnvironmentKey {
    static var defaultValue = NumberFormatter()
}

extension EnvironmentValues {
    var formatter: NumberFormatter {
        get {
            self[NumberFormatterEnvironmentKey.self]
        }
        set {
            self[NumberFormatterEnvironmentKey.self] = newValue
        }
    }
}


struct EnvironmentKeyTestRoute: Responder {

    @Environment(\.formatter) var formatter
    
    func execute() throws -> Response {
        formatter.string(from: 343) ?? "formatter couldn't format"
    }
}

struct Todo: Codable, Equatable {
    let label: String
    let done: Bool
}

final class Database {
    let todos: [Todo]
    
    init() {
        todos = [
            Todo(label: "Finish environment property wrappers", done: true),
            Todo(label: "Implement an endpoint with a \"database\"", done: true),
            Todo(label: "Profit!", done: false),
        ]
    }
}

struct EnvironmentObjectTestRoute: Responder {

    @EnvironmentObject var database: Database
    
    func execute() throws -> Response {
        JSON(database.todos)
    }
}

final class EnvironmentTests: XCTestCase {
    
    func makeWorld() throws -> World {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .spellOut
        EnvironmentValues.shared[NumberFormatterEnvironmentKey.self] = formatter

        EnvironmentValues.shared.storage[ObjectIdentifier(Database.self)] = Database()

        return try World(routes: [
            EnvironmentKeyTestRoute()
                .on("/environmentKey"),
            EnvironmentObjectTestRoute()
                .on("/environmentObject"),
        ])
    }

    func testEnvironmentKeys() async throws {
        
        let world = try self.makeWorld()

        try await world.send(HTTPRequestBuilder(uri: "/environmentKey", method: .GET))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "three hundred forty-three")
    }
    
    func testEnivironmentObjects() async throws {
        
        let world = try self.makeWorld()
        
        try await world.send(HTTPRequestBuilder(uri: "/environmentObject", method: .GET))

        let response = try await world.receive()
        XCTAssertEqual(response.statusCode, .ok)
        let body = try XCTUnwrap(response.bodyString)

        let data = try XCTUnwrap(Data(body.utf8))

        let decoded = try JSONDecoder().decode([Todo].self, from: data)

        XCTAssertEqual(decoded, Database().todos)

    }
}
