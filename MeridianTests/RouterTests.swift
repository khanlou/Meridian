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

    struct Wrench: Error { }

    struct ThrowingExtractor: NonParameterizedExtractor {
        static func extract(from context: RequestContext) async throws -> String {
            throw Wrench()
        }
    }

    struct ThrowingResponder: Responder {
        @Custom<ThrowingExtractor> var string
        func execute() async throws -> any Response {
            "Should not return"
        }
    }

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

    struct AddHeaderMiddleware: Middleware {
        let key: String
        let value: String
        func execute(next: any Responder) async throws -> any Response {
            try await next.execute()
                .additionalHeaders([key: value])
        }
    }

    struct StringWithDependency: Response {
        let string: String
        @Environment(\.jsonEncoder) var defaultEncoder
        func body() throws -> Data {
            _ = defaultEncoder
            return Data("\(string) (Error with dependency)".utf8)
        }
    }

    struct BasicErrorRendererWithDependency: ErrorRenderer {
        func render(primaryError: any Error, context: ErrorsContext) async throws -> any Response {
            StringWithDependency(string: context.errorMessage)
                .statusCode(context.statusCode)
        }
    }

    func makeWorld() throws -> World {
        return try World(errorRenderer: BasicErrorRendererWithDependency(), builder: {

            StringResponder(string: "root paths should work")
                .on(.root)

            StringResponder(string: "matching a subpath should work")
                .on("/a")

            ThrowingResponder()
                .on("/throws")

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
                    .middleware(AddHeaderMiddleware(key: "Middleware", value: "C"))

                    Group("e/f") {
                        StringResponder(string: "two path components in the prefix should work")
                            .on(.root)

                    }
                }
                .errorRenderer(StringErrorRenderer(string: "error renderer on group b"))
                .middleware(AddHeaderMiddleware(key: "Shared-Middleware", value: "B"))
                .middleware(AddHeaderMiddleware(key: "Middleware", value: "B"))
            }
            .middleware(AddHeaderMiddleware(key: "GroupWithNoNameMiddleware", value: "A"))
        }, middlewareProducers: [{ AddHeaderMiddleware(key: "Middleware", value: "A") }])
    }

    enum Expectation {
        case body(String)
        case header(String, String)
        case headerNil(String)
        case notFound
    }

    func testBasic() async throws {
        try await atPath("/", expect: .body("root paths should work"))
        try await atPath("/", expect: .headerNil("Shared-Middleware"))
        try await atPath("/a", expect: .header("Middleware", "A"))
        try await atPath("/", expect: .headerNil("Shared-Middleware"))
        try await atPath("/a", expect: .body("matching a subpath should work"))
        try await atPath("/throws", expect: .body("An unknown error occurred in ThrowingExtractor. (Error with dependency)"))
        try await atPath("/b", expect: .body("an group with no prefix should work"))
        try await atPath("/b", expect: .header("GroupWithNoNameMiddleware", "A"))
        try await atPath("/c", expect: .body("another group with no prefix should work"))
        try await atPath("/c", expect: .headerNil("Shared-Middleware"))
        try await atPath("/z", expect: .notFound)
        try await atPath("/z", expect: .body("No matching route was found. (Error with dependency)"))
        try await atPath("/b/a", expect: .body("a group with a prefix should work"))
        try await atPath("/b/a", expect: .header("Middleware", "B"))
        try await atPath("/b/a", expect: .header("Shared-Middleware", "B"))
        try await atPath("/b/c", expect: .header("Middleware", "C"))
        try await atPath("/b/c", expect: .body("a nested group with a prefix should work"))
        try await atPath("/b/c", expect: .header("Shared-Middleware", "B"))
        try await atPath("/b/e/f", expect: .body("two path components in the prefix should work"))
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
        case let .headerNil(key):
            XCTAssertNil(response.headers.first(where: { $0.name == key }), file: file, line: line)
        case let .header(key, value):
            XCTAssertEqual(response.headers.first(where: { $0.name == key })?.value, value, file: file, line: line)
        }
    }
}
