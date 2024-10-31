//
//  Router.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

struct RouterTrieNode {
    var children: [String: RouterTrieNode]
    var routes: [() -> [Route]]
    var middleware: Middleware
    var errorRenderer: ErrorRenderer?

    static let empty: RouterTrieNode = .init(children: [:], routes: [], middleware: EmptyMiddleware(), errorRenderer: nil)

    mutating func insert(_ routes: @escaping () -> [Route], errorRenderer: ErrorRenderer?, atPath path: some Collection<Substring>) {
        if let first = path.first {
            self.children[String(first), default: .empty].insert(routes, errorRenderer: errorRenderer, atPath: path.dropFirst())
        } else {
            self.routes.append(routes)
            if let errorRenderer {
                self.errorRenderer = errorRenderer
            }
        }
    }

    func bestRouteMatching(header: RequestHeader, errorHandler: inout ErrorRenderer) -> (Route, MatchedRoute)? {

        if routes.isEmpty && header.path.isEmpty {
            return nil
        }
        for route in routes.flatMap({ $0() }) {
            if let matchedRoute = route.matcher.matches(header) {
                return (route, matchedRoute)
            }
        }

        let index = header.path.dropFirst().firstIndex(of: "/")
        let next = header.path.dropFirst()[..<(index ?? header.path.endIndex)]

        var mutableHeader = header
        mutableHeader.path.removeFirst(next.count)

        return self.children[String(next)]?.bestRouteMatching(header: mutableHeader, errorHandler: &errorHandler)
    }

    func methods(matching path: String) throws -> Set<HTTPMethod> {

        var matchingMethods = Set<HTTPMethod>()

        for route in routes.flatMap({ $0() }) {
            for method in HTTPMethod.primaryMethods {
                let header = try RequestHeader(method: method, uri: path, headers: [])
                if route.matcher.matches(header) != nil {
                    matchingMethods.insert(method)
                }
            }
        }

        guard !path.isEmpty else { return matchingMethods }

        let index = path.dropFirst().firstIndex(of: "/")
        let next = path.dropFirst()[..<(index ?? path.endIndex)]

        let newPath = path.dropFirst(next.count + 1)

        let fromChildren = try children[String(next), default: .empty].methods(matching: String(newPath))

        return matchingMethods.union(fromChildren)
    }
}

final class Router {
    var root: RouterTrieNode

    var defaultErrorRenderer: ErrorRenderer

    var middlewareProducers: [() -> Middleware]

    init(defaultErrorRenderer: ErrorRenderer, middlewareProducers: [() -> Middleware] = []) {
        self.root = .empty
        self.defaultErrorRenderer = defaultErrorRenderer
        self.middlewareProducers = middlewareProducers
    }

    func register(prefix: String, errorRenderer: ErrorRenderer?, _ routes: @escaping () -> [Route]) {
        root.insert(routes, errorRenderer: errorRenderer, atPath: normalizePath(prefix).split(separator: "/"))
    }

    func route(for header: RequestHeader) -> ((Responder, MatchedRoute)?, ErrorRenderer) {
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
        return try root.methods(matching: path)
    }
}

