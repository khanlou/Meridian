//
//  Path.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public typealias Path = Custom<PathExtractor>

public struct PathExtractor: NonParameterizedExtractor {
    public static func extract(from context: RequestContext) throws -> String {
        return context.header.path
    }

    public static func openAPIParameters() -> [OpenAPIParameter] {
        []
    }
}
