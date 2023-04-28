//
//  File 2.swift
//  
//
//  Created by Soroush Khanlou on 4/27/23.
//

import Foundation

public protocol WebSocketResponder: Responder {

}

public struct WebSocket: Response {

    let onText: (String) async throws -> Void

    let onData: (Data) async throws -> Void

    let onPing: () async throws -> Void

    let onPong: () async throws -> Void


    public init(onText: @escaping (String) -> Void = { _ in },
         onData: @escaping (Data) -> Void = { _ in },
         onPing: @escaping () -> Void = { },
         onPong: @escaping () -> Void = { }) {
        self.onText = onText
        self.onData = onData
        self.onPing = onPing
        self.onPong = onPong
    }

    public func body() throws -> Data {
        Data()
    }

    public var statusCode: StatusCode {
        .switchingProtocols
    }
}
