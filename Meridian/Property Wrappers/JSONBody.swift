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
        guard _currentRequest.header.method != .GET else {
            _errors.append(UnexpectedGETRequestError())
            self.finalValue = nil
            return
        }

        guard let contentType = _currentRequest.header.headers["Content-Type"], contentType.contains("application/json") else {
            _errors.append(JSONContentTypeError())
            self.finalValue = nil
            return
        }

        guard !_currentRequest.postBody.isEmpty else {
            self.finalValue = .some(.none)
            return
        }
        do {
            self.finalValue = try decoder.decode(Type.self, from: _currentRequest.postBody)
        } catch {
            self.finalValue = nil
            _errors.append(JSONBodyDecodingError(type: Type.self, underlyingError: error as? DecodingError))
        }
    }
    
    @_disfavoredOverload
    public init(decoder: JSONDecoder = .init()) {
        guard _currentRequest.header.method != .GET else {
            _errors.append(UnexpectedGETRequestError())
            self.finalValue = nil
            return
        }

        guard let contentType = _currentRequest.header.headers["Content-Type"], contentType.contains("application/json") else {
            _errors.append(JSONContentTypeError())
            self.finalValue = nil
            return
        }

        guard !_currentRequest.postBody.isEmpty else {
            _errors.append(MissingBodyError())
            self.finalValue = nil
            return
        }
        do {
            self.finalValue = try decoder.decode(Type.self, from: _currentRequest.postBody)
        } catch {
            self.finalValue = nil
            _errors.append(JSONBodyDecodingError(type: Type.self, underlyingError: error as? DecodingError))
        }
    }

    public var wrappedValue: Type {
        return finalValue!
    }
}

