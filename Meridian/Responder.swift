//
//  Responder.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public protocol Responder {
    func execute() throws -> Response

    init()
}
