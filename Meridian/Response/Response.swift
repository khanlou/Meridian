//
//  Response.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

public protocol Response {
    func body() throws -> Data
}
