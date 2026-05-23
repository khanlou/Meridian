//
//  RequestID.swift
//  Meridian
//
//  Created by Soroush Khanlou on 5/18/26.
//

import Foundation

public typealias RequestID = Custom<RequestIDExtractor>

public struct RequestIDExtractor: NonParameterizedExtractor {
    public static func extract(from context: RequestContext) throws -> String {
        context.requestID
    }
}
