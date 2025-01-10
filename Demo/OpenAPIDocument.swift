//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 5/20/24.
//

import Meridian
import OpenAPIKit
import Foundation

struct OpenAPIDocument: Responder {

    public init() { }

    @Environment(\.router) var router

    public func execute() async throws -> any Response {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting.insert(.sortedKeys)
        let output = OpenAPIGenerator(router: router).document()
        try output.validate()
        return JSON(output, encoder: jsonEncoder)
    }
}
