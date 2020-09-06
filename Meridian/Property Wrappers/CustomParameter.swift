//
//  CustomParameter.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public protocol ParameterExtractor {
    associatedtype Output

    static func extract(from context: RequestContext) throws -> Output

}

@propertyWrapper
public struct Custom<Extractor: ParameterExtractor> {

    let finalValue: Extractor.Output?

    public init() {
        do {
            self.finalValue = try Extractor.extract(from: _currentRequest)
        } catch let error as ReportableError {
            _errors.append(error)
            self.finalValue = nil
        } catch {
            _errors.append(BasicError(message: "An unknown error occurred in \(Extractor.self)."))
            self.finalValue = nil
        }
    }

    public var wrappedValue: Extractor.Output {
        finalValue!
    }
}
