//
//  TestHelpers.swift
//  
//
//  Created by Soroush Khanlou on 9/2/20.
//

import Foundation
import NIOHTTP1
import NIO
import Meridian

let http11 = HTTPVersion.init(major: 1, minor: 1)

extension URLParameterKey {
    static let tester = URLParameterKey()
    static let secondTester = URLParameterKey()
}

struct BasicErrorRenderer: ErrorRenderer {
    
    let error: Error
    
    init(error: Error) {
        self.error = error
    }
    
    func render() throws -> Response {
        return ((error as? ErrorWithMessage)?.message ?? "An error occurred")
            .statusCode( (error as? ErrorWithStatusCode)?.statusCode ?? .badRequest)
    }
}

struct HTTPRequestBuilder {
    let uri: String
    let method: NIOHTTP1.HTTPMethod
    let headers: [String: String]
    let bodyData: Data
    
    init(uri: String, method: NIOHTTP1.HTTPMethod, headers: [String: String] = [:], bodyData: Data = Data()) {
        self.uri = uri
        self.method = method
        self.headers = headers
        self.bodyData = bodyData
    }
    
    var head: HTTPServerRequestPart {
        var headers = HTTPHeaders()
        for (name, value) in self.headers {
            headers.add(name: name, value: value)
        }
        return HTTPServerRequestPart.head(HTTPRequestHead(version: http11, method: method, uri: uri, headers: headers))
    }
    
    var body: HTTPServerRequestPart {
        HTTPServerRequestPart.body(ByteBuffer(bytes: bodyData))
    }
    
    var end: HTTPServerRequestPart {
        HTTPServerRequestPart.end(nil)
    }
}

struct HTTPResponseReader {
    
    struct ResponseDestructuringError: Error {
        
    }
    
    let statusCode: HTTPResponseStatus
    
    let body: Data
    
    let headers: [(name: String, value: String)]
    
    var bodyString: String? {
        String(data: body, encoding: .utf8)
    }
    
    init(head: HTTPServerResponsePart?, body: HTTPServerResponsePart?, end: HTTPServerResponsePart?) throws {
        if case let .head(info)? = head {
            self.statusCode = info.status
            self.headers = info.headers.map({ ($0, $1) })
        } else {
            throw ResponseDestructuringError()
        }
        if case let .body(content)? = body, case let .byteBuffer(byteBuffer) = content {
            self.body = Data(byteBuffer.readableBytesView)
        } else {
            throw ResponseDestructuringError()
        }
    }
}

enum LetterGrade: String, LosslessStringConvertible {
    var description: String {
        return rawValue
    }
    
    init?(_ description: String) {
        self.init(rawValue: description)
    }
    
    case A, B, C, D, F
}

enum MusicNote: String, Decodable {
    case C, D, E, F, G, A, B
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let note = Self.init(rawValue: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a valid MusicNote.")
        }
        self = note
    }
}

extension URLParameterKey {
    static let letter = URLParameterKey()
}
