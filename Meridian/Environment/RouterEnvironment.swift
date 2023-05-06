//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 5/6/23.
//

import Foundation

struct RouterEnvironmentKey: EnvironmentKey {
    static var defaultValue = Router(routesByPrefix: [:], defaultErrorRenderer: BasicErrorRenderer())
}

extension EnvironmentValues {
    var router: Router {
        get {
            self[RouterEnvironmentKey.self]
        }
        set {
            self[RouterEnvironmentKey.self] = newValue
        }
    }
}

