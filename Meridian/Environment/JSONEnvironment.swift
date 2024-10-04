//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 5/6/23.
//

import Foundation

struct JSONDecoderEnvironmentKey: EnvironmentKey {
    static let defaultValue = JSONDecoder()
}

extension EnvironmentValues {
    public var jsonDecoder: JSONDecoder {
        get {
            self[JSONDecoderEnvironmentKey.self]
        }
        set {
            self[JSONDecoderEnvironmentKey.self] = newValue
        }
    }
}

struct JSONEncoderEnvironmentKey: EnvironmentKey {
    static let defaultValue = JSONEncoder()
}

extension EnvironmentValues {
    public var jsonEncoder: JSONEncoder {
        get {
            self[JSONEncoderEnvironmentKey.self]
        }
        set {
            self[JSONEncoderEnvironmentKey.self] = newValue
        }
    }
}


