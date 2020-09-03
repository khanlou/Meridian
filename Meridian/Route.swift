//
//  Route.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public protocol Route {
    static var route: RouteMatcher { get }

    func execute() throws -> Response

    init()
}
