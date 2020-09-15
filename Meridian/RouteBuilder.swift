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
}

extension Responder {
    public func on(_ matcher: RouteMatcher) -> Route {
        Route(matcher: matcher, responder: self)
    }
}

@_functionBuilder
public struct RouteBuilder {
    public static func buildBlock(_ routes: Route...) -> [Route] {
        return routes
    }
}
