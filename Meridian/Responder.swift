//
//  Responder.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public protocol Responder {

    func validate() throws

    func execute() throws -> Response

}

extension Responder {
    public func validate() throws{
        
    }
}
