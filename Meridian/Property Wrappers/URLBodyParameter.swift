//
//  URLBodyParameter.swift
//
//
//  Created by Soroush Khanlou on 12/30/20.
//

import Foundation

private struct URLBodyHolder<Contained: Decodable>: Decodable {
    let value: Contained
}

@propertyWrapper
public struct URLBodyParameter<Type: Decodable>: PropertyWrapper {

    @ParameterStorage var finalValue: Type

    let extractor: (RequestContext) throws -> Type

    func update(_ requestContext: RequestContext, errors: inout [Error]) {
        do {
            self.finalValue = try extractor(requestContext)
        } catch {
            errors.append(error)
        }
    }

    public var wrappedValue: Type {
        return finalValue
    }

    @_disfavoredOverload
    public init(_ key: String) {
        self.extractor = { context in
            if let value: Type = try Self.value(forKey: key, inBody: context.postBody) {
                return value
            } else {
                throw MissingURLBodyParameterError(key: key)
            }
        }
    }

    public init<Inner>(_ key: String) where Type == Inner? {
        self.extractor = { context in
            if let value: Type = try Self.value(forKey: key, inBody: context.postBody) {
                return value
            } else {
                return nil
            }
        }
    }

    public init(wrappedValue: Type, _ key: String) {
        self.extractor = { context in
            if let value: Type = try Self.value(forKey: key, inBody: context.postBody) {
                return value
            } else {
                return wrappedValue
            }
        }
    }

    static func stringValue(forKey key: String, inBody body: Data) throws -> String? {
        guard let body = String(data: body, encoding: .utf8) else {
            throw URLBodyDecodingError()
        }

        let kvPairs = body.split(separator: "&")
        for kv in kvPairs {
            let pair = kv.split(separator: "=", maxSplits: 1)
            if pair.count == 2 {
                let innerKey = pair[0]
                let value = pair[1]
                if key == innerKey {
                    return String(value)
                }
            }
        }
        return nil

    }

    static func value<T: Decodable>(forKey key: String, inBody body: Data) throws -> T? {
        guard let stringValue = try stringValue(forKey: key, inBody: body) else {
            return nil
        }
        guard let decoded = stringValue.removingPercentEncoding else {
            return nil
        }
        do {
            return try decodeFragment(T.self, from: decoded.replacingOccurrences(of: "+", with: " "))
        } catch {
            throw URLBodyParameterValueDecodingError(type: Type.self, key: key)
        }
    }
}

extension URLBodyParameter where Type == Present {
    public init(_ key: String) {
        self.extractor = { context in
            if try Self.stringValue(forKey: key, inBody: context.postBody) != nil {
                return Present()
            } else {
                throw MissingURLBodyParameterError(key: key)
            }
        }
    }
}

extension URLBodyParameter where Type == Present? {
    public init(_ key: String) {
        self.extractor = { context in
            if try Self.stringValue(forKey: key, inBody: context.postBody) != nil {
                return Present()
            } else {
                return nil
            }
        }
    }
}
