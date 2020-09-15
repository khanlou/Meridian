//
//  QueryParameter.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

enum KeyPathComponent {
    case name(String)
    case index(Int)
}

enum KeyPathError: Error {
    case invalidKeyPath(String)
    case notAnArray(NSObject)
    case typeError
}

private func components(from keyPath: String) throws -> Array<KeyPathComponent> {
    let separators = CharacterSet(charactersIn: ".[")
    return try keyPath
        .components(separatedBy: separators)
        .drop(while: { $0.isEmpty })
        .map({ piece in
            if piece.hasSuffix("]") {
                let trimmed = piece.dropLast()
                guard let num = Int(trimmed) else {
                    throw KeyPathError.invalidKeyPath("[" + piece)
                }
                return .index(num)
            }

            guard !piece.isEmpty else {
                throw KeyPathError.invalidKeyPath(keyPath)
            }
            return .name(piece)
        })
}

extension NSObject {
    func _value(forKeyPath keyPath: String) throws -> Any {
        let path = try components(from: keyPath)
        return try _value(forKeyPath: path)
    }

    private func _value(forKeyPath: Array<KeyPathComponent>) throws -> Any {
        guard let first = forKeyPath.first else { return self }
        guard self is NSArray || self is NSDictionary else {
            throw KeyPathError.typeError
        }
        switch first {
            case .name(let property):
                guard let object = (self as? NSDictionary)?[property] as? NSObject else {
                    throw KeyPathError.invalidKeyPath(property)
                }
                return try object._value(forKeyPath: Array(forKeyPath.dropFirst()))
            case .index(let i):
                guard let array = self as? NSArray else {
                    throw KeyPathError.notAnArray(self)
                }
                let object = array[i] as! NSObject
                return try object._value(forKeyPath: Array(forKeyPath.dropFirst()))
        }
    }
}

@propertyWrapper
public struct JSONValue<Type: Decodable>: PropertyWrapper {

    @ParameterStorage var finalValue: Type

    let extractor: (RequestContext) throws -> Type

    func update(_ requestContext: RequestContext, errors: inout [Error]) {
        do {
            self.finalValue = try extractor(requestContext)
        } catch let error as ReportableError {
            errors.append(error)
        } catch {
            errors.append(BasicError(message: "An unknown error occurred in \(JSONValue.self)."))
        }
    }

    public init<Inner>(_ keyPath: String) where Type == Inner? {
        self.extractor = { requestContext in
            guard requestContext.header.method != .GET else {
                throw UnexpectedGETRequestError()
            }

            guard let contentType = requestContext.header.headers["Content-Type"], contentType.contains("application/json") else {
                throw JSONContentTypeError()
            }

            guard !requestContext.postBody.isEmpty else {
                return nil
            }

            let object = try JSONSerialization.jsonObject(with: requestContext.postBody, options: []) as? NSDictionary ?? .init()
            let result = try? object._value(forKeyPath: keyPath) as? Inner
            if let value = result {
                return value
            } else {
                return nil
            }
        }
    }


    @_disfavoredOverload
    public init(_ keyPath: String) {
        self.extractor = { requestContext in
            guard requestContext.header.method != .GET else {
                throw UnexpectedGETRequestError()
            }

            guard let contentType = requestContext.header.headers["Content-Type"], contentType.contains("application/json") else {
                throw JSONContentTypeError()
            }

            guard !requestContext.postBody.isEmpty else {
                throw MissingBodyError()
            }

            let object = try JSONSerialization.jsonObject(with: requestContext.postBody, options: []) as? NSDictionary ?? .init()
            let result = try object._value(forKeyPath: keyPath) as? Type
            guard let value = result else {
                throw JSONKeyNotFoundError(keyPath: keyPath)
            }
            return value
        }
    }

    public var wrappedValue: Type {
        return finalValue
    }
}

