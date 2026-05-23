//
//  RequestState.swift
//  Meridian
//
//  Created by Soroush Khanlou on 5/18/26.
//

import Foundation

@propertyWrapper
public struct RequestState<Value: Sendable>: PropertyWrapper {

    private let keyPath: ReferenceWritableKeyPath<RequestStateValues, Value>

    @ParameterStorage private var values: RequestStateValues

    public init(_ keyPath: ReferenceWritableKeyPath<RequestStateValues, Value>) {
        self.keyPath = keyPath
    }

    func update(_ requestContext: RequestContext, errors: inout [Error]) async {
        self.values = requestContext.requestState
    }

    public var wrappedValue: Value {
        get {
            values[keyPath: keyPath]
        }
        nonmutating set {
            values[keyPath: keyPath] = newValue
        }
    }
}
