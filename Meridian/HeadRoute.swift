//
//  HeadRoute.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

struct FullRequestContextExtractor: NonParameterizedExtractor {
    static func extract(from context: RequestContext) async throws -> RequestContext {
        context
    }
}

struct HeadResponse: Response {
    let getResponse: any Response
    let contentLength: Int

    init(getResponse: any Response) throws {
        self.getResponse = getResponse
        self.contentLength = try getResponse.body().count
    }

    func body() throws -> Data {
        Data()
    }

    var additionalHeaders: [String : String] {
        var headers = getResponse.additionalHeaders
        headers["Content-Length"] = String(contentLength)
        return headers
    }

    var statusCode: StatusCode {
        getResponse.statusCode
    }
}

struct HeadRoute: Responder {

    @Environment(\.router) var router

    @Custom<FullRequestContextExtractor> var fullContext

    func execute() async throws -> Response {

        let request = try RequestContext(
            header: .init(method: .GET, httpVersion: fullContext.header.httpVersion, uri: fullContext.header.uri, headers: fullContext.header.headers.allHeaders),
            matchedRoute: nil,
            postBody: .init()
        )

        let response = try await self.router.handle(request: request)

        return try HeadResponse(getResponse: response)
    }
}
