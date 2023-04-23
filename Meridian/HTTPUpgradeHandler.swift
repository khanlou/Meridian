//
//  HTTPHandler.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/26/20.
//

import Foundation
import NIO
import NIOHTTP1

final class HTTPUpgradeHandler: ChannelInboundHandler {
    typealias InboundIn = ParsedHTTPRequest

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let parsed = unwrapInboundIn(data)
        let connectionHeaders = Set(parsed.head.headers["Connection"])

        if connectionHeaders.contains("Upgrade") {
            
            print("let's upgrade!")
        }

        context.fireChannelRead(data)
    }
}
