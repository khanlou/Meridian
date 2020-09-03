//
//  StatusCodeResponse.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

struct StatusCodeResponse: Response, ResponseDetails {

    let statusCode: StatusCode

    let wrapping: Response

    var additionalHeaders: [String : String] {
        (wrapping as? ResponseDetails)?.additionalHeaders ?? [:]
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
