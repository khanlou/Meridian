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
