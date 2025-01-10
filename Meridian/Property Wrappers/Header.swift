//
//  Header.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public typealias Header = CustomWithParameters<HTTPHeaderExtractor>

public struct HTTPHeaderExtractor: ParameterizedExtractor {
    public static func extract(from context: RequestContext, parameters: String) throws -> String {
        return context.header.headers[parameters] ?? ""
    }

    public static func openAPIParameters(_ parameters: Parameters) -> [OpenAPIParameter] {
        [.init(name: parameters, context: .header(required: false), schema: schema(from: Output.self))]
    }
}
