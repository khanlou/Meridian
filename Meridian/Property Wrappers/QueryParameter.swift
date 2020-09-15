//
//  QueryParameter.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public struct Present: Codable {
    public init() {

    }
}

extension Optional where Wrapped == Present {
    public var isPresent: Bool {
        self != nil
    }

    public var isNotPresent: Bool {
        self == nil
    }
}

private struct Holder<Contained: Decodable>: Decodable {
    let value: Contained
}

func decodeFragment<T: Decodable>(_ type: T.Type, from value: String) throws -> T {
    do {
        let newString = "{\"value\": \(value) }"
        let decoder = JSONDecoder()
        return try decoder.decode(Holder<T>.self, from: newString.data(using: .utf8)!).value
    } catch {
        let newString = "{\"value\": \"\(value)\" }"
        let decoder = JSONDecoder()
        return try decoder.decode(Holder<T>.self, from: newString.data(using: .utf8)!).value
    }
}

@propertyWrapper
public struct QueryParameter<Type: Decodable>: PropertyWrapper {

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
            guard let item = context.queryParameters.first(where: { $0.name == key }) else {
                throw MissingQueryParameterError(key: key)
            }
            guard let value = item.value else {
                throw NoValueQueryParameterError(key: key)
            }
            do {
                return try decodeFragment(Type.self, from: value)
            } catch {
                throw QueryParameterDecodingError(type: Type.self, key: key)
            }
        }
    }

    public init<Inner>(_ key: String) where Type == Inner? {
        self.extractor = { context in
            guard let value = context.queryParameters.first(where: { $0.name == key })?.value else {
                return nil
            }
            do {
                return try decodeFragment(Type.self, from: value)
            } catch {
                throw QueryParameterDecodingError(type: Type.self, key: key)
            }
        }
    }
}

extension QueryParameter where Type == Present {
    public init(_ key: String) {
        self.extractor = { context in
            guard context.queryParameters.first(where: { $0.name == key }) != nil else {
                throw MissingQueryParameterError(key: key)
            }
            return Present()
        }
    }
}

extension QueryParameter where Type == Present? {
    public init(_ key: String) {
        self.extractor = { context in
            guard context.queryParameters.first(where: { $0.name == key }) != nil else {
                return nil
            }
            return Present()
        }
    }
}
