//
//  BundledFiles.swift
//  
//
//  Created by Soroush Khanlou on 2/12/21.
//

import Foundation

public struct Forbidden: ReportableError {
    public let statusCode: StatusCode = .forbidden

    public let message = "This path cannot be accessed."
}

public struct _StaticFiles: Responder {

    public let bundle: Bundle

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    @Path var path

    public func execute() throws -> Response {

        guard var path = self.path.removingPercentEncoding else {
            throw Forbidden()
        }

        path = String(path.drop(while: { $0 == "/" }))

        guard !path.contains("../") else {
            throw NoRouteFound() // should be 403
        }

        guard let filePath = bundle.url(forResource: path, withExtension: nil) else {
            throw NoRouteFound()
        }

        return File(url: filePath)
    }
}

public func BundledFiles(bundle: Bundle) -> Route {
    return _StaticFiles(bundle: bundle)
        .on(RouteMatcher(matches: { header in
            if bundle.url(forResource: header.path, withExtension: nil) != nil {
                return MatchedRoute(parameters: [:])
            } else {
                return nil
            }
        }))
}
