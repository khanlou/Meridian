//
//  StatusCodeResponse.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

struct StatusCodeResponse: Response {

    let statusCode: StatusCode

    let wrapping: Response

    var additionalHeaders: [String : String] {
        wrapping.additionalHeaders
    }

    func body() throws -> Data {
        try wrapping.body()
    }

}

extension Response {
    public func statusCode(_ statusCode: StatusCode) -> Response {
        return StatusCodeResponse(statusCode: statusCode, wrapping: self)
    }
}
