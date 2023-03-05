//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 3/4/23.
//

import Foundation

public typealias Body = Custom<BodyExtractor>

public struct BodyExtractor: NonParameterizedExtractor {
    public static func extract(from context: RequestContext) async throws -> Data {
        return context.postBody
    }
}
