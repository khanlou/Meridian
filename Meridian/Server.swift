//
//  Server.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/26/20.
//

import Foundation
import NIO
import NIOHTTP1
import ArgumentParser

struct ServeOptions: ParsableArguments {
    @Option var port: Int = 3000
    @Option var host: String = "localhost"
}

public final class Server {

    let options = ServeOptions.parseOrExit()

    let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    var routesByPrefix: [String: [Route.Type]]
    let errorRenderer: ErrorRenderer.Type

    public init(errorRenderer: ErrorRenderer.Type) {
        self.routesByPrefix = [:]
        self.errorRenderer = errorRenderer
    }

    @discardableResult
    public func register(_ routes: Route.Type...) -> Self {
        self.routesByPrefix["", default: []].append(contentsOf: routes)
        return self
    }

    @discardableResult
    public func group(prefix: String, _ routes: Route.Type...) -> Self {
        self.routesByPrefix[prefix, default: []].append(contentsOf: routes)
        return self
    }

    public func listen() {
        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)

        let bootstrap = ServerBootstrap(group: loopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            .childChannelInitializer({ channel in
                channel.pipeline.configureHTTPServerPipeline()
                    .flatMap({
                        channel.pipeline.addHandler(HTTPHandler(routesByPrefix: self.routesByPrefix, errorRenderer: self.errorRenderer))
                    })
            })
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(reuseAddrOpt, value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

        do {
            let serverChannel = try bootstrap
                .bind(host: options.host, port: options.port)
                .wait()

            print("Server running on \(serverChannel.localAddress!)")

            try serverChannel.closeFuture.wait() // run forever
        } catch {
            fatalError("Failed to start server: \(error)")
        }
    }
}

extension Server {
    public func environmentObject(_ object: AnyObject) -> Self {
        EnvironmentStorage.shared.objects.append(object)
        return self
    }

    public func environment(_ key: EnvironmentKey, _ value: AnyObject) -> Self {
        EnvironmentStorage.shared.keyedObjects[key] = value
        return self
    }
}
