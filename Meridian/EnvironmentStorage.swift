//
//  EnvironmentStorage.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public struct EnvironmentKey: Hashable {
    private let id = UUID()

    public init() {

    }
}

extension EnvironmentKey {
    public static let dateFormatter = EnvironmentKey()
}

final class EnvironmentStorage {

    static let shared = EnvironmentStorage()

    var objects: [AnyObject] = []

    var keyedObjects: [EnvironmentKey: AnyObject] = [:]

}
