//
//  Redirect.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

public struct Redirect: Response {

    public let url: URL

    public let statusCode: StatusCode

    public var additionalHeaders: [String : String] {
        ["Location": url.absoluteString]
    }

    public func body() throws -> Data {
        Data()
    }

    public static func temporary(url: URL) -> Redirect {
        Redirect(url: url, statusCode: .temporaryRedirect)
    }

    public static func permanent(url: URL) -> Redirect {
        Redirect(url: url, statusCode: .permanentRedirect)
    }
 
    public static func seeOther(url: URL) -> Redirect {
        Redirect(url: url, statusCode: .seeOther)
    }

    public static func movedPermanently(url: URL) -> Redirect {
        Redirect(url: url, statusCode: .movedPermanently)
    }
}
