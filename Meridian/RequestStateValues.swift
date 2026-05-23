//
//  RequestStateValues.swift
//  Meridian
//
//  Created by Soroush Khanlou on 5/18/26.
//

import Foundation

public protocol RequestStateKey {

    associatedtype Value

    static var defaultValue: Value { get }

}

public final class RequestStateValues {

    private var storage: [ObjectIdentifier: Any] = [:]

    public init() {

    }

    public subscript<Key: RequestStateKey>(key: Key.Type) -> Key.Value {
        get {
            let id = ObjectIdentifier(key)
            return (storage[id] as? Key.Value) ?? Key.defaultValue
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }

}
