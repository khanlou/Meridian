//
//  Headers.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/30/20.
//

import Foundation

public struct Headers {
    let storage: [(name: String, value: String)]

    public subscript(name: String) -> String? {
        return storage
            .first(where: { pair in
                return pair.name.lowercased() == name.lowercased()
            })?
            .value
    }

    public var allHeaders: [(name: String, value: String)] {
        storage
    }
}
