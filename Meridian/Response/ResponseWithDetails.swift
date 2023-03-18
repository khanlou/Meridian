//
//  ResponseWithDetails.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

public func _statusCode(_ response: Response) -> StatusCode {
    response.statusCode
}

public func _additionalHeaders(_ response: Response) -> [String: String] {
    response.additionalHeaders
}
