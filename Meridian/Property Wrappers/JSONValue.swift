//
//  QueryParameter.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

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
            let result = object.value(forKeyPath: keyPath) as? Inner
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
            let result = object.value(forKeyPath: keyPath) as? Type
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

