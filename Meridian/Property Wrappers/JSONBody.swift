//
//  JSONBody.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

@propertyWrapper
public struct JSONBody<Type: Decodable>: PropertyWrapper {

    @ParameterStorage var finalValue: Type

    let extractor: (RequestContext) throws -> Type

    public init<Inner>(decoder: JSONDecoder? = nil) where Type == Inner? {
        self.extractor = { context in
            try Self.checkMethod(context)

            try Self.checkHeader(context)

            guard !context.postBody.isEmpty else {
                return nil
            }

            return try (decoder ?? context.environment.jsonDecoder)
                .decode(Type.self, from: context.postBody)
        }
    }

    @_disfavoredOverload
    public init(decoder: JSONDecoder? = nil) {
        self.extractor = { context in
            try Self.checkMethod(context)

            try Self.checkHeader(context)

            guard !context.postBody.isEmpty else {
                throw MissingBodyError()
            }

            return try (decoder ?? context.environment.jsonDecoder)
                .decode(Type.self, from: context.postBody)
        }
    }

    func update(_ requestContext: RequestContext, errors: inout [Error]) {
        do {
            self.finalValue = try self.extractor(requestContext)
        } catch let error as DecodingError {
            errors.append(JSONBodyDecodingError(type: Type.self, underlyingError: error))
        } catch let error as ReportableError {
            errors.append(error)
        } catch {
            errors.append(BasicError(message: "An unknown error occurred in \(JSONBody.self).")) // maybe fatal
        }
    }

    public var wrappedValue: Type {
        return finalValue
    }

    static func checkHeader(_ context: RequestContext) throws {
        guard let contentType = context.header.headers["Content-Type"], contentType.contains("application/json") else {
            throw JSONContentTypeError()
        }
    }

    static func checkMethod(_ context: RequestContext) throws {
        guard context.header.method != .GET else {
            throw UnexpectedGETRequestError()
        }
    }

}

