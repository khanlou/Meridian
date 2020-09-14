//
//  Router.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

final class Router {
    var routesByPrefix: [String: RouteGroup]

    var defaultErrorRenderer: ErrorRenderer.Type

    init(routesByPrefix: [String: RouteGroup], defaultErrorRenderer: ErrorRenderer.Type) {
        self.routesByPrefix = routesByPrefix
        self.defaultErrorRenderer = defaultErrorRenderer
    }

    func register(_ routes: [Responder.Type], errorRenderer: ErrorRenderer.Type? = nil) {
        self.add(routes: routes, prefix: "", errorRenderer: errorRenderer)
    }

    func group(prefix: String, _ routes: [Responder.Type], errorRenderer: ErrorRenderer.Type? = nil) {
        self.add(routes: routes, prefix: prefix, errorRenderer: errorRenderer)
    }

    private func add(routes: [Responder.Type], prefix: String, errorRenderer: ErrorRenderer.Type?) {
        self.routesByPrefix[prefix, default: RouteGroup()].append(contentsOf: routes)
        if let errorRenderer = errorRenderer {
            self.routesByPrefix[prefix, default: RouteGroup()].customErrorRenderer = errorRenderer
        }
    }

    func route(for header: RequestHeader) -> ((Responder.Type, MatchedRoute)?, ErrorRenderer.Type) {
        let originalPath = header.path

        var header = header

        var errorHandlerBestGuess = defaultErrorRenderer

        for (prefix, routeGroup) in self.routesByPrefix {
            header.path = originalPath
            if header.path.hasPrefix(prefix) {
                errorHandlerBestGuess = routeGroup.customErrorRenderer ?? defaultErrorRenderer
                header.path.removeFirst(prefix.count)
                for route in routeGroup.routes {
                    if let matchedRoute = route.route.matches(header) {
                        return ((route, matchedRoute), errorHandlerBestGuess)
                    }
                }
            }
        }

        if header.method == .OPTIONS {
            return ((OptionsRoute.self, MatchedRoute()), errorHandlerBestGuess)
        }

        return (nil, errorHandlerBestGuess)
    }

    func methods(for path: String) -> Set<HTTPMethod> {
        var matchingMethods = Set<HTTPMethod>()

        for (prefix, routeGroup) in routesByPrefix {
            for method in HTTPMethod.primaryMethods {
                var header = RequestHeader(method: method, uri: path, headers: [])
                if header.path.hasPrefix(prefix) {
                    header.path.removeFirst(prefix.count)
                    for route in routeGroup.routes {
                        if route.route.matches(header) != nil {
                            matchingMethods.insert(method)
                        }
                    }
                }
            }
        }
        return matchingMethods
    }
}

