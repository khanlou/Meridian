//
//  JSONBody.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

@propertyWrapper
public struct JSONBody<Type: Decodable> {

    let finalValue: Type?

    public init<Inner>(decoder: JSONDecoder = .init()) where Type == Inner? {
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

            self.finalValue = try decoder.decode(Type.self, from: _currentRequest.postBody)
        } catch let error as DecodingError {
            self.finalValue = nil
            _errors.append(JSONBodyDecodingError(type: Type.self, underlyingError: error))
        } catch let error as ReportableError {
            _errors.append(error)
            self.finalValue = nil
        } catch {
            _errors.append(BasicError(message: "An unknown error occurred in \(JSONBody.self)."))
            self.finalValue = nil
        }

    }
    
    @_disfavoredOverload
    public init(decoder: JSONDecoder = .init()) {
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

            self.finalValue = try decoder.decode(Type.self, from: _currentRequest.postBody)
        } catch let error as DecodingError {
            self.finalValue = nil
            _errors.append(JSONBodyDecodingError(type: Type.self, underlyingError: error))
        } catch let error as ReportableError {
            _errors.append(error)
            self.finalValue = nil
        } catch {
            _errors.append(BasicError(message: "An unknown error occurred in \(JSONBody.self).")) // maybe fatal
            self.finalValue = nil
        }

    }

    public var wrappedValue: Type {
        return finalValue!
    }
}

