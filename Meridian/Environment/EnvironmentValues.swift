//
//  EnvironmentStorage.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation
import NIO
import NIOConcurrencyHelpers

public protocol EnvironmentKey {

    associatedtype Value: Sendable

    static var defaultValue: Value { get }

}

public final class EnvironmentValues: @unchecked Sendable {

    static let shared = EnvironmentValues()

    private let lock = NIOLock()
    private var storage: [ObjectIdentifier: Sendable] = [:]

    public subscript<Key: EnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            lock.withLock {
                let id = ObjectIdentifier(key)
                return (storage[id] as? Key.Value) ?? Key.defaultValue
            }
        }
        set {
            lock.withLock {
                storage[ObjectIdentifier(key)] = newValue
            }
        }
    }

    public func object<MyType: Sendable>(ofType: MyType.Type) -> MyType? {
        lock.withLock {
            storage[ObjectIdentifier(MyType.self)] as? MyType
        }
    }

    public func setObject<MyType: Sendable>(_ object: MyType, for type: MyType.Type) {
        lock.withLock {
            storage[ObjectIdentifier(type)] = object
        }
    }

    public func set<Value>(_ keyPath: ReferenceWritableKeyPath<EnvironmentValues, Value>, _ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        self[keyPath: keyPath] = value
    }
}
