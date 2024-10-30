//
//  RoutingTests.swift
//  
//
//  Created by Soroush Khanlou on 9/1/20.
//

import XCTest
import Meridian

final class RoutingTests: XCTestCase {
    
    let nonGETMethods = HTTPMethod.primaryMethods.filter({ $0 != .GET })
        
    func testBasic() async throws {
        let matcher = RouteMatcher.path("/testing")

        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: HTTPMethod.primaryMethods.randomElement()!, uri: "/testing", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testin", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testingg", headers: [])))
    }

    func testTrailingSlashes() async throws{
        let matcher = RouteMatcher.path("/testing/")
        let matcher2 = RouteMatcher.path("/testing")
        let matcher3 = RouteMatcher.path("testing")

        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/", headers: [])))
        try XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        try XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "/testing/", headers: [])))
        try XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        try XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "/testing/", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testin", headers: [])))
    }

    func testStringLiterals() async throws {
        let matcher: RouteMatcher = "/testing"
        
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: HTTPMethod.primaryMethods.randomElement()!, uri: "/testing", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testin", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testingg", headers: [])))
    }
    
    func testSpecificMatcher() async throws {
        let matcher = RouteMatcher.get(.path("/testing"))
        
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: nonGETMethods.randomElement()!, uri: "/testing", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testin", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testingg", headers: [])))
    }
    
    func testAny() async throws {
        let matcher = RouteMatcher.any
        
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: HTTPMethod.primaryMethods.randomElement()!, uri: "/" + makeRandomString(), headers: [])))
    }
    
    func testMultipleMatchers() async throws {
        let matcher: RouteMatcher = [
            .get("/hello"),
            .post("/hi"),
        ]
        
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/hello", headers: [])))
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .POST, uri: "/hi", headers: [])))
        
        try XCTAssertNil(matcher.matches(RequestHeader(method: nonGETMethods.randomElement()!, uri: "/" + makeRandomString(), headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: nonGETMethods.randomElement()!, uri: "/" + makeRandomString(), headers: [])))
    }
    
    func testURLParameters() async throws {
        let matcher: RouteMatcher = "/testing/\(\.tester)"
        
        let matchedRoute = try matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: []))
        
        XCTAssertNotNil(matchedRoute)
        
        XCTAssertEqual(try matchedRoute?.parameter(for: TesterParameterKey.self), "123")
        
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/456", headers: [])))
    }
    
    func testTwoURLParameters() async throws {
        let matcher: RouteMatcher = "/testing/\(\.tester)/sub/\(\.secondTester)"
        
        let matchedRoute = try matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello", headers: []))
        
        XCTAssertNotNil(matchedRoute)
        
        XCTAssertEqual(try matchedRoute?.parameter(for: TesterParameterKey.self), "123")
        XCTAssertEqual(try matchedRoute?.parameter(for: SecondTesterParameterKey.self), "hello")
        
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/456", headers: [])))
    }

    func testTwoURLParametersWithNonNormalSlashes() async throws {
        let matcher: RouteMatcher = "/testing/\(\.tester)/sub/\(\.secondTester)"
        let matcher2: RouteMatcher = "testing/\(\.tester)/sub/\(\.secondTester)"
        let matcher3: RouteMatcher = "/testing/\(\.tester)/sub/\(\.secondTester)/"
        let matcher4: RouteMatcher = "testing/\(\.tester)/sub/\(\.secondTester)/"

        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello", headers: [])))
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello/", headers: [])))
        try XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello/", headers: [])))
        try XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello", headers: [])))
        try XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello/", headers: [])))
        try XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello/", headers: [])))
        try XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello", headers: [])))
        try XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello/", headers: [])))
        try XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello/", headers: [])))
        try XCTAssertNotNil(matcher4.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello", headers: [])))
        try XCTAssertNotNil(matcher4.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello/", headers: [])))
        try XCTAssertNotNil(matcher4.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello/", headers: [])))

        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: [])))
        try XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/456", headers: [])))
    }

    
}
