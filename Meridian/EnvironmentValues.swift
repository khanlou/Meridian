//
//  EnvironmentStorage.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public protocol EnvironmentKey {

    associatedtype Value

    static var defaultValue: Value { get }

}

public final class EnvironmentValues {

    static let shared = EnvironmentValues()

    var storage: [ObjectIdentifier: Any] = [:]

    public subscript<Key: EnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            let id = ObjectIdentifier(key)
            return (storage[id] as? Key.Value) ?? Key.defaultValue
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }
}
