//
//  TestHelpers.swift
//  
//
//  Created by Soroush Khanlou on 9/2/20.
//

import Foundation
import NIOHTTP1
import NIO
@testable import Meridian

let http11 = HTTPVersion.init(major: 1, minor: 1)

struct HTTPRequestBuilder {
    let uri: String
    let method: NIOHTTP1.HTTPMethod
    let headers: [String: String]
    let bodyData: Data

    init(uri: String, method: NIOHTTP1.HTTPMethod, headers: [String: String] = [:], bodyString: String) {
        let data = bodyString.data(using: .utf8) ?? Data()
        self.init(uri: uri, method: method, headers: headers, bodyData: data)
    }

    
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
    
    init(head: HTTPClientResponsePart?, body: HTTPClientResponsePart?, end: HTTPClientResponsePart?) throws {
        if case let .head(info)? = head {
            self.statusCode = info.status
            self.headers = info.headers.map({ ($0, $1) })
        } else {
            throw ResponseDestructuringError()
        }
        if case let .body(byteBuffer)? = body {
            self.body = Data(byteBuffer.readableBytesView)
        } else {
            throw ResponseDestructuringError()
        }
    }
}

class IODataToByteBufferConverter: ChannelOutboundHandler {
    typealias OutboundIn = HTTPPart<HTTPResponseHead, IOData>
    typealias OutboundOut = HTTPPart<HTTPResponseHead, ByteBuffer>

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?)
    {
        let part: OutboundOut = switch self.unwrapOutboundIn(data) {
        case .head(let head): .head(head)
        case .body(.byteBuffer(let body)): .body(body)
        case .body: fatalError()
        case .end(let tail): .end(tail)
        }

        context.write(self.wrapOutboundOut(part), promise: promise)
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

struct LetterParameterKey: URLParameterKey {
    typealias DecodeType = LetterGrade
}

struct TesterParameterKey: URLParameterKey {
    typealias DecodeType = String
}

struct SecondTesterParameterKey: URLParameterKey {
    typealias DecodeType = String
}

struct StringIDParameter: URLParameterKey {
    public typealias DecodeType = String
}

struct NumberParameter: URLParameterKey {
    public typealias DecodeType = Int
}

extension ParameterKeys {
    var letter: LetterParameterKey { .init() }
    var tester: TesterParameterKey { .init() }
    var secondTester: SecondTesterParameterKey { .init() }
    var id: StringIDParameter { .init() }
    var number: NumberParameter { .init() }
}

func makeRandomString() -> String {
    let letters = "abcdefghijklmnopqrstuvwxyz"
    return String((0..<7).map{ _ in letters.randomElement()! })
}

final class World {

    let channel: NIOAsyncTestingChannel

    init(errorRenderer: ErrorRenderer = BasicErrorRenderer(), @RouteBuilder builder: @escaping () -> [_BuildableRoute], middlewareProducers: [() -> Middleware] = []) throws {
        var router = Router(defaultErrorRenderer: errorRenderer, middlewareProducers: middlewareProducers)
        router.register(builder)
        let handler = HTTPHandler(router: router)

        EnvironmentValues.shared.router = handler.router

        let channel = NIOAsyncTestingChannel()
        try channel.pipeline.addHandler(HTTPRequestParsingHandler()).wait()
        try channel.pipeline.addHandler(handler).wait()
        try channel.pipeline.addHandler(IODataToByteBufferConverter()).wait()

        self.channel = channel
    }

    func send(_ request: HTTPRequestBuilder) async throws {
        try await channel.writeInbound(request.head)
        try await channel.writeInbound(request.body)
        try await channel.writeInbound(request.end)
    }

    func receive() async throws -> HTTPResponseReader {
        return try await HTTPResponseReader(
            head: channel.waitForOutboundWrite(),
            body: channel.waitForOutboundWrite(),
            end: channel.waitForOutboundWrite()
        )
    }
}
