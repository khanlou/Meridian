//
//  RouteBuilder.swift
//  
//
//  Created by Soroush Khanlou on 9/14/20.
//

import Foundation

public struct Route {
    public let matcher: RouteMatcher
    public let responder: Responder

    public init(matcher: RouteMatcher, responder: Responder) {
        self.matcher = matcher
        self.responder = responder
    }
}

extension Responder {
    public func on(_ matcher: RouteMatcher) -> Route {
        Route(matcher: matcher, responder: self)
    }
}

@resultBuilder
public struct RouteBuilder {
    public static func buildBlock(_ routes: Route...) -> [Route] {
        return routes
    }
}
