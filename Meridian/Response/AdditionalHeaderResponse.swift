//
//  AdditionalHeaderResponse.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/31/20.
//

import Foundation

struct AdditionalHeaderResponse: Response, ResponseDetails {

    let addedHeaders: [String : String]

    let wrapping: Response

    init(additionalHeaders: [String : String], wrapping: Response) {
        self.addedHeaders = additionalHeaders
        self.wrapping = wrapping
    }

    var additionalHeaders: [String : String] {
        addedHeaders.merging((wrapping as? ResponseDetails)?.additionalHeaders ?? [:], uniquingKeysWith: { first, second in first })
    }

    func body() throws -> Data {
        try wrapping.body()
    }

}

extension Response {
    public func additionalHeaders(_ additionalHeaders: [String : String]) -> Response {
        return AdditionalHeaderResponse(additionalHeaders: additionalHeaders, wrapping: self)
    }
}
