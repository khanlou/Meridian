//
//  ThreadEnvironment.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

@propertyWrapper
class ParameterStorage<T> {

    var storage: T?

    var wrappedValue: T {
        get {
            guard let storage = storage else {
                fatalError("The property wrapper's value was accessed at an invalid type.")
            }
            return storage
        }
        set {
            storage = newValue
        }
    }
}

protocol PropertyWrapper {
    func update(_ requestContext: RequestContext, errors: inout [Error]) async
}
