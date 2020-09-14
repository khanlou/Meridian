//
//  Environment.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public typealias EnvironmentObject<Type> = Custom<EnvironmentObjectExtractor<Type>>

public struct EnvironmentObjectExtractor<Type>: NonParameterizedExtractor {
    public static func extract(from context: RequestContext) throws -> Type {
        guard let value = EnvironmentValues.shared.storage[ObjectIdentifier(Type.self)] as? Type else {
            throw MissingEnvironmentObject(type: Type.self)
        }
        return value
    }
}

public typealias Environment<Value> = CustomWithParameters<EnvironmentKeyExtractor<Value>>

public struct EnvironmentKeyExtractor<Value>: ParameterizedExtractor {
    public static func extract(from context: RequestContext, parameters: KeyPath<EnvironmentValues, Value>) throws -> Value {
        EnvironmentValues.shared[keyPath: parameters]
    }
}
