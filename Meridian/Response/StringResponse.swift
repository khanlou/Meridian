//
//  StringResponse.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

public struct StringResponseError: Error {

}

extension String: Response {
    public func body() throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw StringResponseError()
        }
        return data
    }
}

