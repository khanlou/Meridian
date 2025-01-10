//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 5/6/23.
//

import Foundation

struct RouterEnvironmentKey: EnvironmentKey {
    static let defaultValue = Router(defaultErrorRenderer: BasicErrorRenderer(), middlewareProducers: [])
}

extension EnvironmentValues {
    public var router: Router {
        get {
            self[RouterEnvironmentKey.self]
        }
        set {
            self[RouterEnvironmentKey.self] = newValue
        }
    }
}

