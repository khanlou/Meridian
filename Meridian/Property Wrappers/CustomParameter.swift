//
//  CustomParameter.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation
import OpenAPIKit

public typealias OpenAPIParameter = OpenAPI.Parameter

public protocol ParameterizedExtractor {
    associatedtype Output
    associatedtype Parameters

    static func extract(from context: RequestContext, parameters: Parameters) async throws -> Output

    static func openAPIParameters(_ input: Parameters) -> [OpenAPIParameter]
}

public protocol NonParameterizedExtractor {
    associatedtype Output

    static func extract(from context: RequestContext) async throws -> Output

    static func openAPIParameters() -> [OpenAPIParameter]
}

@propertyWrapper
public struct CustomWithParameters<Extractor: ParameterizedExtractor>: PropertyWrapper {

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

    func openAPIParameters() -> [OpenAPIParameter] {
        Extractor.openAPIParameters(parameters)
    }
}

@propertyWrapper
public struct Custom<Extractor: NonParameterizedExtractor>: PropertyWrapper {

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

    func openAPIParameters() -> [OpenAPIParameter] {
        Extractor.openAPIParameters()
    }
}
