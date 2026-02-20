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
    var errorRenderer: ErrorRenderer?
    var middlewareProducers: [() -> Middleware] = []

    public init(_ prefix: String = "", @RouteBuilder _ builder: @escaping () -> [_BuildableRoute]) {
        self.prefix = prefix
        self.routes = builder
    }

    internal init(prefix: String = "", routes: @autoclosure @escaping () -> [Group]) {
        self.prefix = prefix
        self.routes = routes
    }

    internal init(prefix: String = "", routes: @escaping () -> [_BuildableRoute], errorRenderer: ErrorRenderer? = nil, middlewareProducers: [() -> Middleware] = []) {
        self.prefix = prefix
        self.routes = routes
        self.errorRenderer = errorRenderer
        self.middlewareProducers = middlewareProducers
    }

    public func errorRenderer(_ renderer: ErrorRenderer?) -> Self {
        .init(prefix: prefix, routes: routes, errorRenderer: renderer, middlewareProducers: middlewareProducers)
    }

    public func middleware(_ middlewareProducer: @autoclosure @escaping () -> Middleware) -> Self {
        .init(prefix: prefix, routes: routes, errorRenderer: errorRenderer, middlewareProducers: self.middlewareProducers + [middlewareProducer])
    }
}

@resultBuilder
public struct RouteBuilder {
    public typealias Build = _BuildableRoute
    public typealias Component = [any _BuildableRoute]

    public static func buildExpression(_ expression: Build) -> Component {
        [expression]
    }

    public static func buildBlock(_ components: Component...) -> Component {
        components.flatMap({ $0 })
    }

    public static func buildOptional(_ component: Component?) -> Component {
        component ?? []
    }

    public static func buildLimitedAvailability(_ component: Component) -> Component {
        component
    }

    public static func buildEither(first component: Component) -> Component {
        component
    }

    public static func buildEither(second component: Component) -> Component {
        component
    }
}
