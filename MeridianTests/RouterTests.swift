//
//  File.swift
//  Meridian
//
//  Created by Soroush Khanlou on 10/29/24.
//

import Foundation

import XCTest
import NIO
import NIOHTTP1
@testable import Meridian

final class RouterTests: XCTestCase {

    struct StringResponder: Responder {
        let string: String

        func execute() async throws -> any Response {
            string
        }
    }

    struct StringErrorRenderer: ErrorRenderer {
        let string: String

        func render(primaryError: any Error, context: ErrorsContext) async throws -> any Response {
            string
                .statusCode(context.statusCode)
        }
    }

    func makeWorld() throws -> World {
        return try World(builder: {

            StringResponder(string: "root paths should work")
                .on(.root)

            StringResponder(string: "matching a subpath should work")
                .on("/a")

            Group {
                StringResponder(string: "an group with no prefix should work")
                    .on("/b")

                StringResponder(string: "another group with no prefix should work")
                    .on("/c")

                Group("b") {
                    StringResponder(string: "a group with a prefix should work")
                        .on("/a")

                    Group("c") {
                        StringResponder(string: "a nested group with a prefix should work")
                            .on(.root)
                    }
                    .errorRenderer(StringErrorRenderer(string: "error renderer on group c"))

                }
                .errorRenderer(StringErrorRenderer(string: "error renderer on group b"))
            }
        })
    }

    enum Expectation {
        case body(String)
        case notFound
    }

    func testBasic() async throws {
        try await atPath("/", expect: .body("root paths should work"))
        try await atPath("/a", expect: .body("matching a subpath should work"))
        try await atPath("/b", expect: .body("an group with no prefix should work"))
        try await atPath("/c", expect: .body("another group with no prefix should work"))
        try await atPath("/z", expect: .notFound)
        try await atPath("/z", expect: .body("No matching route was found."))
        try await atPath("/b/a", expect: .body("a group with a prefix should work"))
        try await atPath("/b/c", expect: .body("a nested group with a prefix should work"))
        try await atPath("/b/b", expect: .notFound)
        try await atPath("/b/z", expect: .notFound)
        try await atPath("/b/z", expect: .body("error renderer on group b"))
        try await atPath("/b/c/z", expect: .notFound)
        try await atPath("/b/c/z", expect: .body("error renderer on group c"))
    }

    func atPath(_ path: String, expect: Expectation, file: StaticString = #file, line: UInt = #line) async throws {
        let world = try self.makeWorld()

        try await world.send(HTTPRequestBuilder(uri: path, method: .GET))

        let response = try await world.receive()

        switch expect {
        case .body(let string):
            XCTAssertEqual(response.bodyString, string, file: file, line: line)
        case .notFound:
            XCTAssertEqual(response.statusCode, .notFound, file: file, line: line)
        }
    }
}
