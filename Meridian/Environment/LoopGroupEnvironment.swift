//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 5/6/23.
//

import Foundation
import NIO

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

