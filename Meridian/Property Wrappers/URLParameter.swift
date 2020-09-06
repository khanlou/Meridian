//
//  URLParameter.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public typealias URLParameter<Type: LosslessStringConvertible> = Custom<URLParameterExtractor<Type>>

public struct URLParameterExtractor<Type: LosslessStringConvertible>: ParameterExtractor {

    public static func extract(from context: RequestContext, parameters: URLParameterKey) throws -> Type {
        guard let substring = _currentRequest.urlParameters[parameters] else {
            throw MissingURLParameterError()
        }
        let value = String(substring)
        if Type.self == String.self {
            return value as! Type
        } else if let finalValue = Type(value) {
            return finalValue
        } else {
            throw URLParameterDecodingError(type: Type.self)
        }
    }
}
