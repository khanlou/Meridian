//
//  CORS.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

extension Response {
    public func allowCORS() -> Response {
        return self.additionalHeaders([
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "X-Requested-With, Origin, Content-Type, Accept",
            "Access-Control-Allow-Methods": "POST, GET, PUT, OPTIONS, DELETE, PATCH",
        ])
    }
}
