//
//  HTTPMethod.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public struct HTTPMethod: Equatable {
    public let name: String

    public static let GET = HTTPMethod(name: "GET")
    public static let PUT = HTTPMethod(name: "PUT")
    public static let ACL = HTTPMethod(name: "ACL")
    public static let HEAD = HTTPMethod(name: "HEAD")
    public static let POST = HTTPMethod(name: "POST")
    public static let COPY = HTTPMethod(name: "COPY")
    public static let LOCK = HTTPMethod(name: "LOCK")
    public static let MOVE = HTTPMethod(name: "MOVE")
    public static let BIND = HTTPMethod(name: "BIND")
    public static let LINK = HTTPMethod(name: "LINK")
    public static let PATCH = HTTPMethod(name: "PATCH")
    public static let TRACE = HTTPMethod(name: "TRACE")
    public static let MKCOL = HTTPMethod(name: "MKCOL")
    public static let MERGE = HTTPMethod(name: "MERGE")
    public static let PURGE = HTTPMethod(name: "PURGE")
    public static let NOTIFY = HTTPMethod(name: "NOTIFY")
    public static let SEARCH = HTTPMethod(name: "SEARCH")
    public static let UNLOCK = HTTPMethod(name: "UNLOCK")
    public static let REBIND = HTTPMethod(name: "REBIND")
    public static let UNBIND = HTTPMethod(name: "UNBIND")
    public static let REPORT = HTTPMethod(name: "REPORT")
    public static let DELETE = HTTPMethod(name: "DELETE")
    public static let UNLINK = HTTPMethod(name: "UNLINK")
    public static let CONNECT = HTTPMethod(name: "CONNECT")
    public static let MSEARCH = HTTPMethod(name: "MSEARCH")
    public static let OPTIONS = HTTPMethod(name: "OPTIONS")
    public static let PROPFIND = HTTPMethod(name: "PROPFIND")
    public static let CHECKOUT = HTTPMethod(name: "CHECKOUT")
    public static let PROPPATCH = HTTPMethod(name: "PROPPATCH")
    public static let SUBSCRIBE = HTTPMethod(name: "SUBSCRIBE")
    public static let MKCALENDAR = HTTPMethod(name: "MKCALENDAR")
    public static let MKACTIVITY = HTTPMethod(name: "MKACTIVITY")
    public static let UNSUBSCRIBE = HTTPMethod(name: "UNSUBSCRIBE")
    public static let SOURCE = HTTPMethod(name: "SOURCE")

    public static let primaryMethods = [HTTPMethod.GET, .POST, .PUT, .DELETE, .OPTIONS, .HEAD]
}
