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

    @Environment(.routes) var router: Router

    @Path var path: String

    func execute() throws -> Response {

        let matchingMethods = self.router.methods(for: path)

        return EmptyResponse()
            .additionalHeaders([
                "Allow": HTTPMethod.primaryMethods.filter(matchingMethods.contains).map({ $0.name }).joined(separator: ", ")
            ])
            .allowCORS()
    }
}
