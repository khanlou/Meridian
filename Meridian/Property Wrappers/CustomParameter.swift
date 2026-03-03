//
//  CustomParameter.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

public protocol ParameterizedExtractor {
    associatedtype Output
    associatedtype Parameters: Sendable

    static func extract(from context: RequestContext, parameters: Parameters) async throws -> Output

}

public protocol NonParameterizedExtractor {
    associatedtype Output

    static func extract(from context: RequestContext) async throws -> Output

}

@propertyWrapper
public struct CustomWithParameters<Extractor: ParameterizedExtractor>: PropertyWrapper, Sendable {

    let parameters: Extractor.Parameters

    public init(_ parameters: Extractor.Parameters) {
        self.parameters = parameters
    }

    @ParameterStorage var finalValue: Extractor.Output

    func update(_ requestContext: RequestContext, errors: inout [Error]) async {
        do {
            self.finalValue = try await Extractor.extract(from: requestContext, parameters: parameters)
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
public struct Custom<Extractor: NonParameterizedExtractor>: PropertyWrapper, Sendable {

    public init() { }

    @ParameterStorage var finalValue: Extractor.Output

    func update(_ requestContext: RequestContext, errors: inout [Error]) async {
        do {
            self.finalValue = try await Extractor.extract(from: requestContext)
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
