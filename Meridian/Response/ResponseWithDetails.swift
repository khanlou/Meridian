//
//  ResponseWithDetails.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

protocol ResponseDetails {

    var additionalHeaders: [String: String] { get }

    var statusCode: StatusCode { get }

}

extension ResponseDetails {
    public var additionalHeaders: [String: String] {
        [:]
    }

    public var statusCode: StatusCode {
        .ok
    }
}

public func _statusCode(_ response: Response) -> StatusCode {
    if let responseWithDetails = response as? ResponseDetails {
        return responseWithDetails.statusCode
    } else {
        return .ok
    }
}

public func _additionalHeaders(_ response: Response) -> [String: String] {
    if let responseWithDetails = response as? ResponseDetails {
        return responseWithDetails.additionalHeaders
    } else {
        return [:]
    }
}
