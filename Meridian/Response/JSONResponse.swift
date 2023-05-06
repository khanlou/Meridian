//
//  JSONResponse.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

struct AnyEncodable: Encodable {
    let base: Encodable

    func encode(to encoder: Encoder) throws {
        try base.encode(to: encoder)
    }
}

public struct JSON: Response {

    let encodable: AnyEncodable

    let encoder: JSONEncoder?

    @Environment(\.jsonEncoder) var defaultEncoder

    public init<T: Encodable>(_ encodable: T, encoder: JSONEncoder? = nil) {
        self.encodable = AnyEncodable(base: encodable)
        self.encoder = encoder
    }

    public var additionalHeaders: [String : String] {
        ["Content-Type": "application/json"]
    }

    public func body() throws -> Data {
        return try (encoder ?? defaultEncoder).encode(encodable)
    }
}

