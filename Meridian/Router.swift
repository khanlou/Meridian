//
//  Router.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

final class Router {
    var routesByPrefix: [String: RouteGroup]

    var defaultErrorRenderer: ErrorRenderer

    init(routesByPrefix: [String: RouteGroup], defaultErrorRenderer: ErrorRenderer) {
        self.routesByPrefix = routesByPrefix
        self.defaultErrorRenderer = defaultErrorRenderer
    }

    func register(prefix: String, errorRenderer: ErrorRenderer?, _ routes: @escaping () -> [Route]) {
        let normalizedPrefix = normalizePath(prefix)
        routesByPrefix[normalizedPrefix, default: RouteGroup()].append(contentsOf: routes)
        if let errorRenderer = errorRenderer {
            self.routesByPrefix[normalizedPrefix, default: RouteGroup()].customErrorRenderer = errorRenderer
        }

    }

    func route(for header: RequestHeader) -> ((Responder, MatchedRoute)?, ErrorRenderer) {
        let originalPath = header.path

        var header = header

        var errorHandlerBestGuess = defaultErrorRenderer

        for (prefix, routeGroup) in self.routesByPrefix {
            header.path = originalPath
            if header.path.hasPrefix(prefix) {
                errorHandlerBestGuess = routeGroup.customErrorRenderer ?? defaultErrorRenderer
                header.path.removeFirst(prefix.count)
                for route in routeGroup.makeAllRoutes() {
                    if let matchedRoute = route.matcher.matches(header) {
                        return ((route.responder, matchedRoute), errorHandlerBestGuess)
                    }
                }
            }
        }

        if header.method == .OPTIONS {
            return ((OptionsRoute(), MatchedRoute()), errorHandlerBestGuess)
        }

        return (nil, errorHandlerBestGuess)
    }

    func methods(for path: String) throws -> Set<HTTPMethod> {
        var matchingMethods = Set<HTTPMethod>()

        for (prefix, routeGroup) in routesByPrefix {
            for method in HTTPMethod.primaryMethods {
                var header = try RequestHeader(method: method, uri: path, headers: [])
                if header.path.hasPrefix(prefix) {
                    header.path.removeFirst(prefix.count)
                    for route in routeGroup.makeAllRoutes() {
                        if route.matcher.matches(header) != nil {
                            matchingMethods.insert(method)
                        }
                    }
                }
            }
        }
        return matchingMethods
    }
}

