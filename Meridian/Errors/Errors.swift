//
//  Errors.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public protocol ErrorWithStatusCode: Error {
    var statusCode: StatusCode { get }
}

public protocol ErrorWithMessage: Error {
    var message: String { get }
}

public typealias ReportableError = ErrorWithStatusCode & ErrorWithMessage

public struct MissingEnvironmentObject: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let message: String

    init<Type>(type: Type.Type) {
        self.message = "This endpoint expects an object with type \(Type.self) to be in the environment."
    }
}

public struct MissingURLParameterError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let message = "The endpoint expects a url parameter."

}

public struct URLParameterDecodingError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let message: String
    
    init<Type>(type: Type.Type) {
        self.message = "The endpoint expects a url parameter that can decode to type \(Type.self)."
    }

}

public struct UnexpectedGETRequestError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let message = "The endpoint expects a body and a method of POST. However, it received a GET."
}

public struct JSONContentTypeError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let message = "The endpoint requires a JSON body and a \"Content-Type\" of \"application/json\"."
}

public struct MissingBodyError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let message = "The endpoint expects a JSON body."
}

extension DecodingError.Context {
    var pathDescription: String {
        pathDescription(for: codingPath)
    }

    func path(including final: CodingKey) -> String {
        pathDescription(for: codingPath + [final])
    }

    private func pathDescription(for path: [CodingKey]) -> String {
        guard !path.isEmpty else {
            return "root"
        }
        return path
            .enumerated()
            .map { (offset, key) -> String in
                if let idx = key.intValue {
                    return "[\(idx)]"
                } else {
                    return offset > 0 ? ".\(key.stringValue)" : key.stringValue
                }
            }
            .joined()
    }
}

public struct JSONBodyDecodingError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let message: String

    init<Type>(type: Type.Type, underlyingError: DecodingError?) {
        switch underlyingError {
        case .dataCorrupted:
            self.message = "The endpoint expects a JSON body, which was not valid JSON."
        case let .keyNotFound(key, context):
            self.message = "The endpoint expects JSON with a value at the \(context.path(including: key)), but it was missing."
        case let .typeMismatch(type, context):
            var typeName = "\(type)"
            if typeName.contains("UnkeyedDecodingContainer") {
                typeName = "Array"
            } else if typeName.contains("KeyedDecodingContainer") {
                typeName = "Object"
            }
            self.message = "The endpoint expects JSON with a value of type \"\(typeName)\" at the \(context.pathDescription), but a different type was found."
        case let .valueNotFound(type, context):
            var typeName = "\(type)"
            if typeName.contains("UnkeyedDecodingContainer") {
                typeName = "Array"
            } else if typeName.contains("KeyedDecodingContainer") {
                typeName = "Object"
            }
            self.message = "The endpoint expects JSON with a value of type \"\(typeName)\" at the \(context.pathDescription), but null was found."
        default:
            self.message = "The endpoint expects JSON, which could not be decoded."
        }
    }
}

public struct QueryParameterDecodingError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let message: String

    init<Type>(type: Type.Type, key: String) {
        self.message = "The endpoint expects a query parameter named \"\(key)\" to decode to type \(Type.self)."
    }

}

public struct NoValueQueryParameterError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let key: String

    public var message: String {
        "The endpoint expects a query parameter named \"\(key)\" with no value."
    }
}

public struct MissingQueryParameterError: ReportableError {

    public let key: String

    public let statusCode: StatusCode = .badRequest

    public var message: String {
        "The endpoint expects a query parameter named \"\(key)\", but it was missing."
    }
}


struct BasicError: ReportableError {

    public var statusCode: StatusCode = .badRequest

    public let message: String

}

public struct NoRouteFound: ReportableError {

    public init() {

    }

    public let statusCode = StatusCode.notFound

    public let message = "No matching route was found."
}
