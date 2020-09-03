//
//  URLParameter.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

@propertyWrapper
public struct URLParameter<Type: LosslessStringConvertible> {

    let finalValue: Type?

    public init(key: URLParameterKey) {
        guard let substring = _currentRequest.urlParameters[key] else {
            _errors.append(MissingURLParameterError())
            self.finalValue = nil
            return
        }
        let value = String(substring)
        if Type.self == String.self {
            self.finalValue = value as? Type
        } else if let finalValue = Type(value) {
            self.finalValue = finalValue
        } else {
            self.finalValue = nil
            _errors.append(URLParameterDecodingError(type: Type.self))
        }
    }

    public var wrappedValue: Type {
        return finalValue!
    }
}
