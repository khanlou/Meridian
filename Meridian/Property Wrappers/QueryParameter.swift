//
//  QueryParameter.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation
import OpenAPIKit

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

private struct QueryParameterHolder<Contained: Decodable>: Decodable {
    let value: Contained
}

func decodeFragment<T: Decodable>(_ type: T.Type, from value: String) throws -> T {
    do {
        let newString = "{\"value\": \(value) }"
        let decoder = JSONDecoder()
        return try decoder.decode(QueryParameterHolder<T>.self, from: newString.data(using: .utf8)!).value
    } catch {
        let newString = "{\"value\": \"\(value)\" }"
        let decoder = JSONDecoder()
        return try decoder.decode(QueryParameterHolder<T>.self, from: newString.data(using: .utf8)!).value
    }
}

@propertyWrapper
public struct QueryParameter<Type: Decodable>: PropertyWrapper {

    @ParameterStorage var finalValue: Type

    let parameterDescription: OpenAPIParameter

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
        self.parameterDescription = .init(name: key, context: .query(required: true, allowEmptyValue: false), schema: schema(from: Type.self))
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
        self.parameterDescription = .init(name: key, context: .query(required: false, allowEmptyValue: false), schema: schema(from: Inner.self))
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

    public init(wrappedValue: Type, _ key: String) {
        self.parameterDescription = .init(name: key, context: .query(required: false, allowEmptyValue: false), schema: schema(from: Type.self))
        self.extractor = { context in
            guard let value = context.queryParameters.first(where: { $0.name == key })?.value else {
                return wrappedValue
            }
            do {
                return try decodeFragment(Type.self, from: value)
            } catch {
                throw QueryParameterDecodingError(type: Type.self, key: key)
            }
        }
    }

    func openAPIParameters() -> [OpenAPI.Parameter] {
        [parameterDescription]
    }
}

extension QueryParameter where Type == Present {
    public init(_ key: String) {
        self.parameterDescription = .init(name: key, context: .query(required: true, allowEmptyValue: false), schema: .null())
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
        self.parameterDescription = .init(name: key, context: .query(required: false, allowEmptyValue: false), schema: .null())
        self.extractor = { context in
            guard context.queryParameters.first(where: { $0.name == key }) != nil else {
                return nil
            }
            return Present()
        }
    }
}
