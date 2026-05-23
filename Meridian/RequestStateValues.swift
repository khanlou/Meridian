//
//  RequestStateValues.swift
//  Meridian
//
//  Created by Soroush Khanlou on 5/18/26.
//

import Foundation
import NIOConcurrencyHelpers

public protocol RequestStateKey {

    associatedtype Value: Sendable

    static var defaultValue: Value { get }

}

public final class RequestStateValues: @unchecked Sendable {

    private let lock = NIOLock()
    private var storage: [ObjectIdentifier: Sendable] = [:]

    public init() {

    }

    public subscript<Key: RequestStateKey>(key: Key.Type) -> Key.Value {
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

}
