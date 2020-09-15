//
//  ThreadEnvironment.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

@propertyWrapper
class ParameterBox<T> {

    var storage: T?

    var wrappedValue: T? {
        get {
            storage
        }
        set {
            storage = newValue
        }
    }
}

protocol PropertyWrapper {
    func update(_ requestContext: RequestContext, errors: inout [Error])
}
