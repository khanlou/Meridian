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
        guard let value = EnvironmentStorage.shared.objects.lazy.compactMap({ $0 as? Type }).first else {
            throw MissingEnvironmentObject(type: Type.self)
        }
        return value
    }
}

public typealias Environment<Type> = CustomWithParameters<EnvironmentKeyExtractor<Type>>

public struct EnvironmentKeyExtractor<Type>: ParameterizedExtractor {
    public static func extract(from context: RequestContext, parameters: EnvironmentKey) throws -> Type {
        if let value = EnvironmentStorage.shared.keyedObjects[parameters] as? Type {
            return value
        } else {
            throw MissingEnvironmentObject(type: Type.self)
        }
    }
}
