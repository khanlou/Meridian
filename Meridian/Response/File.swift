//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 2/12/21.
//

import Foundation

public struct File: Response {
    public let url: URL

    public func body() throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw error
        }
    }
}
