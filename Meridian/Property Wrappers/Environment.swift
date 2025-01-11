//
//  Environment.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

extension KeyPath: @unchecked @retroactive Sendable {}

public typealias EnvironmentObject<Type> = Custom<EnvironmentObjectExtractor<Type>>

public struct EnvironmentObjectExtractor<Type: Sendable>: NonParameterizedExtractor {
    public static func extract(from context: RequestContext) async throws -> Type {
        guard let value = EnvironmentValues.shared.object(ofType: Type.self) else {
            throw MissingEnvironmentObject(type: Type.self)
        }
        return value
    }
}

public typealias Environment<Value> = CustomWithParameters<EnvironmentKeyExtractor<Value>>

public struct EnvironmentKeyExtractor<Value: Sendable>: ParameterizedExtractor {
    public static func extract(from context: RequestContext, parameters: KeyPath<EnvironmentValues, Value>) throws -> Value {
        EnvironmentValues.shared[keyPath: parameters]
    }
}
