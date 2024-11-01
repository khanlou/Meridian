//
//  RouteBuilder.swift
//  
//
//  Created by Soroush Khanlou on 9/14/20.
//

import Foundation

public protocol _BuildableRoute { }

public struct Route: _BuildableRoute {
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

public struct Group: _BuildableRoute {
    var prefix: String = ""
    var routes: () -> [_BuildableRoute]

    public init(_ prefix: String = "", @RouteBuilder _ builder: @escaping () -> [_BuildableRoute]) {
        self.prefix = prefix
        self.routes = builder
    }

    internal init(prefix: String = "", routes: @autoclosure @escaping () -> [Group]) {
        self.prefix = prefix
        self.routes = routes
    }
}

@resultBuilder
public struct RouteBuilder {
    public static func buildBlock(_ routes: _BuildableRoute...) -> [_BuildableRoute] {
        routes
    }
}
