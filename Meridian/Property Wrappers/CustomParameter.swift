//
//  CustomParameter.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public protocol ParameterExtractor {
    associatedtype Output
    associatedtype Parameters

    static func extract(from context: RequestContext, parameters: Parameters) throws -> Output

}

@propertyWrapper
public struct Custom<Extractor: ParameterExtractor> {

    let finalValue: Extractor.Output?

    public init(_ parameters: Extractor.Parameters) {
        do {
            self.finalValue = try Extractor.extract(from: _currentRequest, parameters: parameters)
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

extension Custom where Extractor.Parameters == Void {
    init() {
        self.init(())
    }
}
