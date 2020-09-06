//
//  OptionsRoute.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

extension EnvironmentKey {
    static let routes = EnvironmentKey()
}

struct OptionsRoute: Route {
    static var route = RouteMatcher(matches: { header in
        header.method == .OPTIONS ? MatchedRoute() : nil
    })

    @Environment(.routes) var routes: Router

    @Path var path: String

    func execute() throws -> Response {
        var matchingMethods: Array<HTTPMethod> = []

        for (prefix, routeGroup) in routes.routes {
            for method in HTTPMethod.primaryMethods {
                var header = RequestHeader(method: method, uri: path, headers: [])
                if header.path.hasPrefix(prefix) {
                    header.path.removeFirst(prefix.count)
                    for route in routeGroup.routes {
                        if route.route.matches(header) != nil {
                            matchingMethods.append(method)
                        }
                    }
                }
            }
        }

        return EmptyResponse()
            .additionalHeaders([
                "Allow": HTTPMethod.primaryMethods.filter(matchingMethods.contains).map({ $0.name }).joined(separator: ", ")
            ])
            .allowCORS()
    }
}
