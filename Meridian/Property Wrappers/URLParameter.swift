//
//  URLParameter.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public typealias URLParameter<SpecificURLParameterKey: URLParameterKey> = CustomWithParameters<URLParameterExtractor<SpecificURLParameterKey>>

public struct URLParameterExtractor<SpecificURLParameterKey: URLParameterKey>: ParameterizedExtractor {
    public static func extract(from context: RequestContext, parameters: KeyPath<ParameterKeys, SpecificURLParameterKey>) throws -> SpecificURLParameterKey.DecodeType {
        guard let matchedRoute = context.matchedRoute else {
             throw NoRouteFound()
         }
         return try matchedRoute.parameter(for: SpecificURLParameterKey.self)    }
}
