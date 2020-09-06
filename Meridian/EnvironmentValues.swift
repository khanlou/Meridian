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

    var objects: [AnyObject] = []

    var keyedObjects: [Any] = []

    public subscript<Key: EnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            keyedObjects.lazy.compactMap({ $0 as? Key.Value }).first ?? Key.defaultValue
        }
        set {
            keyedObjects.append(newValue)
        }
    }
}
