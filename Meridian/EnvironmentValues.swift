//
//  EnvironmentStorage.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation
import NIO

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

    public func object<MyType>(ofType: MyType.Type) -> MyType? {
        storage[ObjectIdentifier(MyType.self)] as? MyType
    }

}

struct LoopGroupEnvironmentKey: EnvironmentKey {
    static var defaultValue: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 0)
}

extension EnvironmentValues {
    public var loopGroup: EventLoopGroup {
        get {
            self[LoopGroupEnvironmentKey.self]
        }
        set {
            self[LoopGroupEnvironmentKey.self] = newValue
        }
    }
}

