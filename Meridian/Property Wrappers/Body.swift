//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 3/4/23.
//

import Foundation

typealias Body = Custom<BodyExtractor>

struct BodyExtractor: NonParameterizedExtractor {
    static func extract(from context: RequestContext) async throws -> Data {
        return context.postBody
    }
}
