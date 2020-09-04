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

struct StringQueryParameterRoute: Route {
    static let route: RouteMatcher = "/string"
    
    @QueryParameter("name") var name: String
    
    func execute() throws -> Response {
        "The name is \(name)"
    }
}

struct IntQueryParameterRoute: Route {
    static let route: RouteMatcher = "/int"
    
    @QueryParameter("number") var number: Int
    
    func execute() throws -> Response {
        "The number + 1 is \(number+1)"
    }
}

struct LetterQueryParameterRoute: Route {
    static let route: RouteMatcher = "/play"
    
    @QueryParameter("note") var note: MusicNote
    
    func execute() throws -> Response {
        "The note is \(note)"
    }
}

struct OptionalParameterRoute: Route {
    static let route: RouteMatcher = "/play_optional"
    
    @QueryParameter("note") var note: MusicNote?
    
    func execute() throws -> Response {
        if let note = note {
            return "The note was present and is \(note)"
        } else {
            return "The note was not included"
        }
    }
}

struct MultipleParameterRoute: Route {
    static let route: RouteMatcher = "/multiple_parameter"
    
    @QueryParameter("note") var note: MusicNote
    @QueryParameter("number") var number: Int
    
    func execute() throws -> Response {
        "The note is \(note) and the number+3 is \(number+3)"
    }
}

struct OptionalFlagParameterRoute: Route {
    static let route: RouteMatcher = "/optional_flag"
    
    @QueryParameter("flag") var flag: Present?
    
    func execute() throws -> Response {
        if flag.isPresent {
            return "The flag was present"
        } else {
            return "The flag was missing"
        }
    }
}

struct RequiredFlagParameterRoute: Route {
    static let route: RouteMatcher = "/required_flag"
    
    @QueryParameter("flag") var flag: Present
    
    func execute() throws -> Response {
        "The flag is required to get to here"
    }
}

class QueryParameterRouteTests: XCTestCase {
    
    func makeChannel() throws -> EmbeddedChannel {
        let handler = HTTPHandler(routes: [
            StringQueryParameterRoute.self,
            IntQueryParameterRoute.self,
            LetterQueryParameterRoute.self,
            OptionalParameterRoute.self,
            MultipleParameterRoute.self,
            OptionalFlagParameterRoute.self,
            RequiredFlagParameterRoute.self,
        ], errorRenderer: BasicErrorRenderer.self)
        
        let channel = EmbeddedChannel()
        try channel.pipeline.addHandler(handler).wait()
        
        return channel
    }
    
    func testString() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/string?name=testing", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The name is testing")
    }
    
    func testInt() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/int?number=451", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The number + 1 is 452")
    }
    
    func testIntFailing() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/int?number=456a", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a query parameter named \"number\" to decode to type Int.")
    }
    
    func testCustomType() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/play?note=B", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note is B")
    }
    
    func testCustomTypeFails() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/play?note=H", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a query parameter named \"note\" to decode to type MusicNote.")
    }
    
    func testMultiple() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/multiple_parameter?note=F&number=30", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note is F and the number+3 is 33")
    }
    
    func testOptionalMissing() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/play_optional", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was not included")
    }
    
    func testOptionalPresent() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/play_optional?note=A", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The note was present and is A")
    }
    
    func testOptionalFlagPresent() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/optional_flag?flag", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The flag was present")
    }
    
    func testOptionalFlagMissing() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/optional_flag", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The flag was missing")
    }
    
    func testRequiredFlagPresent() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/required_flag?flag", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The flag is required to get to here")
    }
    
    func testRequiredFlagWithUnneededValue() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/required_flag?flag=this_is_discarded", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .ok)
        XCTAssertEqual(response.bodyString, "The flag is required to get to here")
    }
    
    func testRequiredFlagMissing() throws {
        
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/required_flag", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .badRequest)
        XCTAssertEqual(response.bodyString, "The endpoint expects a query parameter named \"flag\", but it was missing.")
    }
    
    func testNotMatching() throws {
        let channel = try self.makeChannel()
        
        let request = HTTPRequestBuilder(uri: "/not_found", method: .GET)
        try channel.writeInbound(request.head)
        try channel.writeInbound(request.body)
        try channel.writeInbound(request.end)
        
        let response = try HTTPResponseReader(head: try channel.readOutbound(), body: try channel.readOutbound(), end: try channel.readOutbound())
        XCTAssertEqual(response.statusCode, .notFound)
        XCTAssertEqual(response.bodyString, "No matching route was found.")
    }
    
}
