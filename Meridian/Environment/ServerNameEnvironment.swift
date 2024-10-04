//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 5/6/23.
//

import Foundation

public struct ServerNameEnvironmentKey: EnvironmentKey {
    public static let defaultValue = "Meridian"
}

extension EnvironmentValues {
    public var serverName: String {
        get {
            self[ServerNameEnvironmentKey.self]
        }
        set {
            self[ServerNameEnvironmentKey.self] = newValue
        }
    }
}

extension Server {
    public func serverName(_ string: String) -> Server {
        self.environment(\.serverName, string)
    }
}

