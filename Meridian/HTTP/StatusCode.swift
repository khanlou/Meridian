//
//  StatusCode.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public struct StatusCode: CustomStringConvertible, Equatable, Hashable {
    public let code: Int
    public let name: String

    public init(code: Int, name: String) {
        self.code = code
        self.name = name
    }

    public var description: String {
        "\(code) \(name)"
    }
}

extension StatusCode {

    public static let `continue` = StatusCode(code: 100, name: "Continue")
    public static let switchingProtocols = StatusCode(code: 101, name: "Switching Protocols")
    public static let processing = StatusCode(code: 102, name: "Processing")
    public static let earlyHints = StatusCode(code: 103, name: "Early Hints")

    public static let ok = StatusCode(code: 200, name: "OK")
    public static let created = StatusCode(code: 201, name: "Created")
    public static let accepted = StatusCode(code: 202, name: "Accepted")
    public static let nonAuthoritativeInformation = StatusCode(code: 203, name: "Non-Authoritative Information")
    public static let noContent = StatusCode(code: 204, name: "No Content")
    public static let resetContent = StatusCode(code: 205, name: "Reset Content")
    public static let partialContent = StatusCode(code: 206, name: "Partial Content")
    public static let multiStatus = StatusCode(code: 207, name: "Multi-Status")
    public static let alreadyReported = StatusCode(code: 208, name: "Already Reported")
    public static let imUsed = StatusCode(code: 226, name: "IM Used")

    public static let multipleChoices = StatusCode(code: 300, name: "Multiple Choices")
    public static let movedPermanently = StatusCode(code: 301, name: "Moved Permanently")
    public static let found = StatusCode(code: 302, name: "Found")
    public static let seeOther = StatusCode(code: 303, name: "See Other")
    public static let notModified = StatusCode(code: 304, name: "Not Modified")
    public static let useProxy = StatusCode(code: 305, name: "Use Proxy")
    public static let temporaryRedirect = StatusCode(code: 307, name: "Temporary Redirect")
    public static let permanentRedirect = StatusCode(code: 308, name: "Permanent Redirect")

    public static let badRequest = StatusCode(code: 400, name: "Bad Request")
    public static let unauthorized = StatusCode(code: 401, name: "Unauthorized")
    public static let paymentRequired = StatusCode(code: 402, name: "Payment Required")
    public static let forbidden = StatusCode(code: 403, name: "Forbidden")
    public static let notFound = StatusCode(code: 404, name: "Not Found")
    public static let methodNotAllowed = StatusCode(code: 405, name: "Method Not Allowed")
    public static let notAcceptable = StatusCode(code: 406, name: "Not Acceptable")
    public static let proxyAuthenticationRequired = StatusCode(code: 407, name: "Proxy Authentication Required")
    public static let requestTimeout = StatusCode(code: 408, name: "Request Timeout")
    public static let conflict = StatusCode(code: 409, name: "Conflict")
    public static let gone = StatusCode(code: 410, name: "Gone")
    public static let lengthRequired = StatusCode(code: 411, name: "Length Required")
    public static let preconditionFailed = StatusCode(code: 412, name: "Precondition Failed")
    public static let payloadTooLarge = StatusCode(code: 413, name: "Payload Too Large")
    public static let uriTooLong = StatusCode(code: 414, name: "URI Too Long")
    public static let unsupportedMediaType = StatusCode(code: 415, name: "Unsupported Media Type")
    public static let rangeNotSatisfiable = StatusCode(code: 416, name: "Range Not Satisfiable")
    public static let expectationFailed = StatusCode(code: 417, name: "Expectation Failed")
    public static let imATeapot = StatusCode(code: 418, name: "I'm a teapot")
    public static let misdirectedRequest = StatusCode(code: 421, name: "Misdirected Request")
    public static let unprocessableEntity = StatusCode(code: 422, name: "Unprocessable Entity")
    public static let locked = StatusCode(code: 423, name: "Locked")
    public static let failedDependency = StatusCode(code: 424, name: "Failed Dependency")
    public static let tooEarly = StatusCode(code: 425, name: "Too Early")
    public static let upgradeRequired = StatusCode(code: 426, name: "Upgrade Required")
    public static let preconditionRequired = StatusCode(code: 428, name: "Precondition Required")
    public static let tooManyRequests = StatusCode(code: 429, name: "Too Many Requests")
    public static let requestHeaderFieldsTooLarge = StatusCode(code: 431, name: "Request Header Fields Too Large")
    public static let unavailableForLegalReasons = StatusCode(code: 451, name: "Unavailable For Legal Reasons")

    public static let internalServerError = StatusCode(code: 500, name: "Internal Server Error")
    public static let notImplemented = StatusCode(code: 501, name: "Not Implemented")
    public static let badGateway = StatusCode(code: 502, name: "Bad Gateway")
    public static let serviceUnavailable = StatusCode(code: 503, name: "Service Unavailable")
    public static let gatewayTimeout = StatusCode(code: 504, name: "Gateway Timeout")
    public static let httpVersionNotSupported = StatusCode(code: 505, name: "HTTP Version Not Supported")
    public static let variantAlsoNegotiates = StatusCode(code: 506, name: "Variant Also Negotiates")
    public static let insufficientStorage = StatusCode(code: 507, name: "Insufficient Storage")
    public static let loopDetected = StatusCode(code: 508, name: "Loop Detected")
    public static let notExtended = StatusCode(code: 510, name: "Not Extended")
    public static let networkAuthenticationRequired = StatusCode(code: 511, name: "Network Authentication Required")
}

extension StatusCode: CaseIterable {
    static public var allCases: [StatusCode] = [
        .`continue`, .switchingProtocols, .processing, .earlyHints,  .ok, .created, .accepted, .nonAuthoritativeInformation, .noContent, .resetContent, .partialContent, .multiStatus, .alreadyReported, .imUsed,  .multipleChoices, .movedPermanently, .found, .seeOther, .notModified, .useProxy, .temporaryRedirect, .permanentRedirect,  .badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound, .methodNotAllowed, .notAcceptable, .proxyAuthenticationRequired, .requestTimeout, .conflict, .gone, .lengthRequired, .preconditionFailed, .payloadTooLarge, .uriTooLong, .unsupportedMediaType, .rangeNotSatisfiable, .expectationFailed, .imATeapot, .misdirectedRequest, .unprocessableEntity, .locked, .failedDependency, .tooEarly, .upgradeRequired, .preconditionRequired, .tooManyRequests, .requestHeaderFieldsTooLarge, .unavailableForLegalReasons,  .internalServerError, .notImplemented, .badGateway, .serviceUnavailable, .gatewayTimeout, .httpVersionNotSupported, .variantAlsoNegotiates, .insufficientStorage, .loopDetected, .notExtended, .networkAuthenticationRequired,
     ]
}
