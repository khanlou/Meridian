//
//  Environment.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

@propertyWrapper
public struct EnvironmentObject<Type> {

    let finalValue: Type?

    public init() {
        guard let value = EnvironmentStorage.shared.objects.lazy.compactMap({ $0 as? Type }).first else {
            self.finalValue = nil
            _errors.append(MissingEnvironmentObject(type: Type.self))
            return
        }
        self.finalValue = value
    }

    public var wrappedValue: Type {
        return finalValue!
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



