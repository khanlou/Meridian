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
}

func private components(from keyPath: String) throws -> Array<KeyPathComponent> {
    let separators = CharacterSet(charactersIn: ".[")
    var pieces = keyPath.components(separatedBy: separators)
    return try pieces
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
        assert(self is NSArray || self is NSDictionary)
        guard let first = forKeyPath.first else { return self }
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
public struct JSONValue<Type: Decodable> {

    let finalValue: Type?

    public init<Inner>(_ keyPath: String) where Type == Inner? {
        do {
            guard _currentRequest.header.method != .GET else {
                throw UnexpectedGETRequestError()
            }

            guard let contentType = _currentRequest.header.headers["Content-Type"], contentType.contains("application/json") else {
                throw JSONContentTypeError()
            }

            guard !_currentRequest.postBody.isEmpty else {
                self.finalValue = .some(.none)
                return
            }

            let object = try JSONSerialization.jsonObject(with: _currentRequest.postBody, options: []) as? NSDictionary ?? .init()
            let result = try? object._value(forKeyPath: keyPath) as? Inner
            if let value = result {
                self.finalValue = value
            } else {
                self.finalValue = .some(.none)
            }
        } catch let error as ReportableError {
            _errors.append(error)
            self.finalValue = nil
        } catch {
            _errors.append(BasicError(message: "An unknown error occurred in \(JSONValue.self)."))
            self.finalValue = nil
        }
    }

    @_disfavoredOverload
    public init(_ keyPath: String) {
        do {
            guard _currentRequest.header.method != .GET else {
                throw UnexpectedGETRequestError()
            }

            guard let contentType = _currentRequest.header.headers["Content-Type"], contentType.contains("application/json") else {
                throw JSONContentTypeError()
            }

            guard !_currentRequest.postBody.isEmpty else {
                throw MissingBodyError()
            }

            let object = try JSONSerialization.jsonObject(with: _currentRequest.postBody, options: []) as? NSDictionary ?? .init()
            let result = try object._value(forKeyPath: keyPath) as? Type
            guard let value = result else {
                throw JSONKeyNotFoundError(keyPath: keyPath)
            }
            self.finalValue = value
        } catch let error as ReportableError {
            _errors.append(error)
            self.finalValue = nil
        } catch {
            _errors.append(BasicError(message: "An unknown error occurred in \(JSONValue.self)."))
            self.finalValue = nil
        }
    }

    public var wrappedValue: Type {
        return finalValue!
    }
}

