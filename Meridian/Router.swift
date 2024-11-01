//
//  Router.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public struct RouterTrieNode {
    var children: [String: RouterTrieNode]
    var routes: [Route]
    var middleware: Middleware
    var errorRenderer: ErrorRenderer?

    static let empty: RouterTrieNode = .init(children: [:], routes: [], middleware: EmptyMiddleware(), errorRenderer: nil)

    mutating func insert(_ buildableRoute: _BuildableRoute) {
        if let route = buildableRoute as? Route {
            self.routes.append(route)
        } else if let group = buildableRoute as? Group {
            if group.prefix.path.isEmpty {
                self.errorRenderer = group.errorRenderer
                for route in group.routes() {
                    self.insert(route)
                }
                return
            }
            var group = group
            let prefix = group.prefix.path.removeFirst()
            if group.prefix.isEmpty {
                for buildableRoute in group.routes() {
                    self.children[String(prefix), default: .empty].insert(buildableRoute)
                }
                self.children[String(prefix), default: .empty].errorRenderer = group.errorRenderer
            } else {
                self.children[String(prefix), default: .empty].insert(group)
            }
        }
    }

    func bestRouteMatching(header: RequestHeader, errorHandler: inout ErrorRenderer) -> (Route, MatchedRoute)? {

        if let errorRenderer {
            errorHandler = errorRenderer
        }

        if routes.isEmpty && header.path.path.isEmpty {
            return nil
        }
        for route in routes {
            if let matchedRoute = route.matcher.matches(header) {
                return (route, matchedRoute)
            }
        }

        if header.path.path.isEmpty { return nil }
        var mutableHeader = header
        let next = mutableHeader.path.path.removeFirst()

        return self.children[String(next)]?.bestRouteMatching(header: mutableHeader, errorHandler: &errorHandler)
    }

    func methods(matching path: String) throws -> Set<HTTPMethod> {

        var matchingMethods = Set<HTTPMethod>()

        for route in routes {
            for method in HTTPMethod.primaryMethods {
                let header = try RequestHeader(method: method, uri: path, headers: [])
                if route.matcher.matches(header) != nil {
                    matchingMethods.insert(method)
                }
            }
        }

        guard !path.isEmpty else { return matchingMethods }

        var path = path

        let next = path.removeFirst()

        let fromChildren = try children[String(next), default: .empty].methods(matching: String(path))

        return matchingMethods.union(fromChildren)
    }
}

final class Router {

    var registeredRoutes: [() -> [_BuildableRoute]] = []

    var defaultErrorRenderer: ErrorRenderer

    var middlewareProducers: [() -> Middleware]

    init(defaultErrorRenderer: ErrorRenderer, middlewareProducers: [() -> Middleware] = []) {
        self.defaultErrorRenderer = defaultErrorRenderer
        self.middlewareProducers = middlewareProducers
    }

    func register(_ routes: @escaping () -> [_BuildableRoute]) {
        registeredRoutes.append(routes)
    }

    func makeTrie() -> RouterTrieNode {
        var root = RouterTrieNode.empty
        for route in registeredRoutes.flatMap({ $0() }) {
            root.insert(route)
        }
        return root
    }

    func route(for header: RequestHeader) -> ((Responder, MatchedRoute)?, ErrorRenderer) {
        let root = makeTrie()

        var errorHandlerBestGuess = defaultErrorRenderer

        if let (route, matchedRoute) = root.bestRouteMatching(header: header, errorHandler: &errorHandlerBestGuess) {
            return ((route.responder, matchedRoute), errorHandlerBestGuess)
        }

        if header.method == .OPTIONS {
            return ((OptionsRoute(), MatchedRoute()), errorHandlerBestGuess)
        }

        return (nil, errorHandlerBestGuess)
    }

    func methods(for path: String) throws -> Set<HTTPMethod> {
        return try makeTrie().methods(matching: path)
    }
}

private extension String {
    var path: [Substring] {
        get {
            self.split(separator: "/")
        }
        set {
            self = newValue.joined(separator: "/")
        }
    }
}

