//
//  Path.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public typealias URI = Custom<URIExtractor>

public struct URIExtractor: NonParameterizedExtractor {
    public static func extract(from context: RequestContext) throws -> String {
        return context.header.uri
    }

    public static func openAPIParameters() -> [OpenAPIParameter] {
        []
    }
}
