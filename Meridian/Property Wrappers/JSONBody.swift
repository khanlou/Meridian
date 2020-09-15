//
//  JSONBody.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

@propertyWrapper
public struct JSONBody<Type: Decodable>: PropertyWrapper {

    @ParameterBox var finalValue: Type?

    let decoder: JSONDecoder

    let extractor: (RequestContext) throws -> Type?

    public init<Inner>(decoder: JSONDecoder = .init()) where Type == Inner? {
        self.decoder = decoder
        self.extractor = { context in
            guard context.header.method != .GET else {
                throw UnexpectedGETRequestError()
            }

            guard let contentType = context.header.headers["Content-Type"], contentType.contains("application/json") else {
                throw JSONContentTypeError()
            }

            guard !context.postBody.isEmpty else {
                return .some(.none)
            }

            return try decoder.decode(Type.self, from: context.postBody)
        }
    }

    @_disfavoredOverload
    public init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
        self.extractor = { context in
            guard context.header.method != .GET else {
                throw UnexpectedGETRequestError()
            }

            guard let contentType = context.header.headers["Content-Type"], contentType.contains("application/json") else {
                throw JSONContentTypeError()
            }

            guard !context.postBody.isEmpty else {
                throw MissingBodyError()
            }

            return try decoder.decode(Type.self, from: context.postBody)
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
        return finalValue!
    }
}

