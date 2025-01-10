//
//  URLParameterKey.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public enum ParameterKeys {

}

public protocol URLParameterKey {
    associatedtype DecodeType: LosslessStringConvertible
}

extension URLParameterKey {
    static var stringKey: String {
        String(reflecting: self)
    }

    static var stringKeyMinusModuleName: String {
        String(stringKey.split(separator: ".").last ?? stringKey[...])
    }
}
