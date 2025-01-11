//
//  EnvironmentStorage.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation
import NIO

public protocol EnvironmentKey {

    associatedtype Value: Sendable

    static var defaultValue: Value { get }

}

public final class EnvironmentValues: @unchecked Sendable {

    nonisolated(unsafe) static var shared = EnvironmentValues()

    var storage: [ObjectIdentifier: Sendable] = [:]

    public subscript<Key: EnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            let id = ObjectIdentifier(key)
            return (storage[id] as? Key.Value) ?? Key.defaultValue
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }

    public func object<MyType: Sendable>(ofType: MyType.Type) -> MyType? {
        storage[ObjectIdentifier(MyType.self)] as? MyType
    }
}
