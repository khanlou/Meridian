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
        
    func testBasic() {
        let matcher = RouteMatcher.path("/testing")

        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        XCTAssertNotNil(matcher.matches(RequestHeader(method: HTTPMethod.primaryMethods.randomElement()!, uri: "/testing", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testin", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testingg", headers: [])))
    }

    func testTrailingSlashes() {
        let matcher = RouteMatcher.path("/testing/")
        let matcher2 = RouteMatcher.path("/testing")
        let matcher3 = RouteMatcher.path("testing")

        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/", headers: [])))
        XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "/testing/", headers: [])))
        XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "/testing/", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testin", headers: [])))
    }

    func testStringLiterals() {
        let matcher: RouteMatcher = "/testing"
        
        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        XCTAssertNotNil(matcher.matches(RequestHeader(method: HTTPMethod.primaryMethods.randomElement()!, uri: "/testing", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testin", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testingg", headers: [])))
    }
    
    func testSpecificMatcher() {
        let matcher = RouteMatcher.get(.path("/testing"))
        
        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: nonGETMethods.randomElement()!, uri: "/testing", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testin", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testingg", headers: [])))
    }
    
    func testAny() {
        let matcher = RouteMatcher.any
        
        XCTAssertNotNil(matcher.matches(RequestHeader(method: HTTPMethod.primaryMethods.randomElement()!, uri: "/" + randomString, headers: [])))
    }
    
    func testMultipleMatchers() {
        let matcher: RouteMatcher = [
            .get("/hello"),
            .post("/hi"),
        ]
        
        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/hello", headers: [])))
        XCTAssertNotNil(matcher.matches(RequestHeader(method: .POST, uri: "/hi", headers: [])))
        
        XCTAssertNil(matcher.matches(RequestHeader(method: nonGETMethods.randomElement()!, uri: "/" + randomString, headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: nonGETMethods.randomElement()!, uri: "/" + randomString, headers: [])))
    }
    
    func testURLParameters() {
        let matcher: RouteMatcher = "/testing/\(\.tester)"
        
        let matchedRoute = matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: []))
        
        XCTAssertNotNil(matchedRoute)
        
        XCTAssertEqual(try matchedRoute?.parameter(for: TesterParameterKey.self), "123")
        
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/456", headers: [])))
    }
    
    func testTwoURLParameters() {
        let matcher: RouteMatcher = "/testing/\(\.tester)/sub/\(\.secondTester)"
        
        let matchedRoute = matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello", headers: []))
        
        XCTAssertNotNil(matchedRoute)
        
        XCTAssertEqual(try matchedRoute?.parameter(for: TesterParameterKey.self), "123")
        XCTAssertEqual(try matchedRoute?.parameter(for: SecondTesterParameterKey.self), "hello")
        
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/456", headers: [])))
    }

    func testTwoURLParametersWithNonNormalSlashes() {
        let matcher: RouteMatcher = "/testing/\(\.tester)/sub/\(\.secondTester)"
        let matcher2: RouteMatcher = "testing/\(\.tester)/sub/\(\.secondTester)"
        let matcher3: RouteMatcher = "/testing/\(\.tester)/sub/\(\.secondTester)/"
        let matcher4: RouteMatcher = "testing/\(\.tester)/sub/\(\.secondTester)/"

        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello", headers: [])))
        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello/", headers: [])))
        XCTAssertNotNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello/", headers: [])))
        XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello", headers: [])))
        XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello/", headers: [])))
        XCTAssertNotNil(matcher2.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello/", headers: [])))
        XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello", headers: [])))
        XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello/", headers: [])))
        XCTAssertNotNil(matcher3.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello/", headers: [])))
        XCTAssertNotNil(matcher4.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello", headers: [])))
        XCTAssertNotNil(matcher4.matches(RequestHeader(method: .GET, uri: "testing/123/sub/hello/", headers: [])))
        XCTAssertNotNil(matcher4.matches(RequestHeader(method: .GET, uri: "/testing/123/sub/hello/", headers: [])))

        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123", headers: [])))
        XCTAssertNil(matcher.matches(RequestHeader(method: .GET, uri: "/testing/123/456", headers: [])))
    }

    
}
