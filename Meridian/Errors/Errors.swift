//
//  Errors.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public protocol ReportableError: Error {
    var statusCode: StatusCode { get }
    var message: String { get }
    var externallyVisible: Bool { get }
}

extension ReportableError {
    var statusCode: StatusCode {
        .internalServerError
    }

    var message: String {
        "An error occurred."
    }

    var externallyVisible: Bool {
        false
    }
}

public struct MissingEnvironmentObject: ReportableError {
    public var externallyVisible = false

    public let statusCode: StatusCode = .badRequest

    public let message: String

    init<Type>(type: Type.Type) {
        self.message = "This endpoint expects an object with type \(Type.self) to be in the environment."
    }
}

public struct MissingURLParameterError: ReportableError {
    public var externallyVisible = true

    public let statusCode: StatusCode = .badRequest

    public let message = "The endpoint expects a url parameter."

}

public struct URLParameterDecodingError: ReportableError {
    public var externallyVisible = true

    public let statusCode: StatusCode = .badRequest

    public let message: String
    
    init<Type>(type: Type.Type) {
        self.message = "The endpoint expects a url parameter that can decode to type \(Type.self)."
    }

}

public struct UnexpectedGETRequestError: ReportableError {
    public var externallyVisible = true

    public let statusCode: StatusCode = .badRequest

    public let message = "The endpoint expects a body and a method of POST. However, it received a GET."
}

public struct JSONContentTypeError: ReportableError {
    public var externallyVisible = true

    public let statusCode: StatusCode = .badRequest

    public let message = "The endpoint requires a JSON body and a \"Content-Type\" of \"application/json\"."
}

public struct MissingBodyError: ReportableError {
    public var externallyVisible = true

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
    public var externallyVisible = true

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

public struct JSONKeyNotFoundError: ReportableError {

    public let statusCode: StatusCode = .badRequest

    public let externallyVisible = true

    public let message: String

    init<Type>(type: Type.Type, keyPath: String) {
        self.message = "The endpoint expects a JSON body with a value of type \(Type.self) at key path \"\(keyPath)\" but did not find one."
    }
}


public struct JSONKeyTypeMismatchError: ReportableError {
    public let statusCode: StatusCode = .badRequest

    public let externallyVisible = true

    public let message: String

    init<Type>(type: Type.Type, keyPath: String) {
        self.message = "The endpoint expects a JSON body with a value at key path \"\(keyPath)\" with the expected type \(Type.self), but did not find the right type."
    }
}

public struct QueryParameterDecodingError: ReportableError {
    public var externallyVisible = true

    public let statusCode: StatusCode = .badRequest

    public let message: String

    init<Type>(type: Type.Type, key: String) {
        self.message = "The endpoint expects a query parameter named \"\(key)\" to decode to type \(Type.self)."
    }

}

public struct NoValueQueryParameterError: ReportableError {
    public var externallyVisible = true

    public let statusCode: StatusCode = .badRequest

    public let key: String

    public var message: String {
        "The endpoint expects a query parameter named \"\(key)\" with no value."
    }
}

public struct MissingQueryParameterError: ReportableError {
    public var externallyVisible = true

    public let key: String

    public let statusCode: StatusCode = .badRequest

    public var message: String {
        "The endpoint expects a query parameter named \"\(key)\", but it was missing."
    }
}

struct URLBodyDecodingError: ReportableError {
    var statusCode: StatusCode = .badRequest

    var message: String = "The endpoint expects a URL-encoded body."

    var externallyVisible: Bool = true

}

struct MissingURLBodyParameterError: ReportableError {
    var statusCode: StatusCode = .badRequest

    var message: String { "The endpoint expects a URL body parameter named \"\(key)\", but it was missing." }

    var externallyVisible: Bool = true

    let key: String
}

public struct URLBodyParameterValueDecodingError: ReportableError {
    public var externallyVisible = true

    public let statusCode: StatusCode = .badRequest

    public let message: String

    init<Type>(type: Type.Type, key: String) {
        self.message = "The endpoint expects a URL encoded parameter named \"\(key)\" to decode to type \(Type.self)."
    }

}

public struct BasicError: ReportableError {
    public var externallyVisible: Bool

    public var statusCode: StatusCode

    public var message: String

    public init(externallyVisible: Bool = false, statusCode: StatusCode = .internalServerError, message: String = "An error occurred.") {
        self.externallyVisible = externallyVisible
        self.statusCode = statusCode
        self.message = message
    }
}

public struct NoRouteFound: ReportableError {
    public var externallyVisible = true

    public init() {

    }

    public let statusCode = StatusCode.notFound

    public let message = "No matching route was found."
}
