//
//  Method.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public typealias RequestMethod = Custom<HTTPMethodExtractor>

public struct HTTPMethodExtractor: NonParameterizedExtractor {
    public static func extract(from context: RequestContext) throws -> HTTPMethod {
        return context.header.method
    }

    public static func openAPIParameters() -> [OpenAPIParameter] {
        []
    }
}
