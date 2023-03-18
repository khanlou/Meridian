//
//  AdditionalHeaderResponse.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

struct AdditionalHeaderResponse: Response {

    let addedHeaders: [String : String]

    let wrapping: Response

    init(additionalHeaders: [String : String], wrapping: Response) {
        self.addedHeaders = additionalHeaders
        self.wrapping = wrapping
    }

    var additionalHeaders: [String : String] {
        addedHeaders.merging(wrapping.additionalHeaders, uniquingKeysWith: { first, second in first })
    }

    func body() throws -> Data {
        try wrapping.body()
    }

    var statusCode: StatusCode {
        wrapping.statusCode
    }

}

extension Response {
    public func additionalHeaders(_ additionalHeaders: [String : String]) -> Response {
        return AdditionalHeaderResponse(additionalHeaders: additionalHeaders, wrapping: self)
    }
}
