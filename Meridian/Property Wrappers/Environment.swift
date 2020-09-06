//
//  Environment.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public typealias EnvironmentObject<Type> = Custom<EnvironmentExtractor<Type>>

public struct EnvironmentExtractor<Type>: NonParameterizedExtractor {
    public static func extract(from context: RequestContext) throws -> Type {
        guard let value = EnvironmentStorage.shared.objects.lazy.compactMap({ $0 as? Type }).first else {
            throw MissingEnvironmentObject(type: Type.self)
        }
        return value
    }
}

@propertyWrapper
public struct Environment<Type> {

    let key: EnvironmentKey

    let finalValue: Type?

    public init(_ key: EnvironmentKey) {
        self.key = key

        if let value = EnvironmentStorage.shared.keyedObjects[key] as? Type {
            self.finalValue = value
        } else {
            self.finalValue = nil
            _errors.append(MissingEnvironmentObject(type: Type.self))
        }
    }

    public var wrappedValue: Type {
        return finalValue!
    }
}



