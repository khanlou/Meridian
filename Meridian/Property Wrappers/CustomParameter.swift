//
//  CustomParameter.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public protocol ParameterizedExtractor {
    associatedtype Output
    associatedtype Parameters

    static func extract(from context: RequestContext, parameters: Parameters) throws -> Output

}

public protocol NonParameterizedExtractor {
    associatedtype Output

    static func extract(from context: RequestContext) throws -> Output

}

@propertyWrapper
public struct CustomWithParameters<Extractor: ParameterizedExtractor>: PropertyWrapper {

    let parameters: Extractor.Parameters

    public init(_ parameters: Extractor.Parameters) {
        self.parameters = parameters
    }

    @ParameterStorage var finalValue: Extractor.Output

    func update(_ requestContext: RequestContext, errors: inout [Error]) {
        do {
            self.finalValue = try Extractor.extract(from: requestContext, parameters: parameters)
        } catch let error as ReportableError {
            errors.append(error)
        } catch {
            errors.append(BasicError(message: "An unknown error occurred in \(Extractor.self)."))
        }
    }

    public var wrappedValue: Extractor.Output {
        finalValue
    }
}

@propertyWrapper
public struct Custom<Extractor: NonParameterizedExtractor>: PropertyWrapper {

    public init() { }

    @ParameterStorage var finalValue: Extractor.Output

    func update(_ requestContext: RequestContext, errors: inout [Error]) {
        do {
            self.finalValue = try Extractor.extract(from: requestContext)
        } catch let error as ReportableError {
            errors.append(error)
        } catch {
            errors.append(BasicError(message: "An unknown error occurred in \(Extractor.self)."))
        }
    }

    public var wrappedValue: Extractor.Output {
        finalValue
    }
}
