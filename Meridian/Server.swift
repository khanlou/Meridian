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

struct RouteGroup: ExpressibleByArrayLiteral {

    var routes: [Route.Type]
    var customErrorRenderer: ErrorRenderer.Type?

    init() {
        self.routes = []
        self.customErrorRenderer = nil
    }

    init(arrayLiteral elements: Route.Type...) {
        self.routes = elements
        self.customErrorRenderer = nil
    }

    mutating func append(_ route: Route.Type) {
        self.routes.append(route)
    }

    mutating func append(contentsOf routes: [Route.Type]) {
        self.routes.append(contentsOf: routes)
    }

}

public final class Server {

    let options = ServeOptions.parseOrExit()

    let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    var router: Router

    public init(errorRenderer: ErrorRenderer.Type) {
        self.router = Router(routesByPrefix: [:], defaultErrorRenderer: errorRenderer)
    }

    @discardableResult
    public func register(_ routes: Route.Type..., errorRenderer: ErrorRenderer.Type? = nil) -> Self {
        self.router.register(routes, errorRenderer: errorRenderer)
        return self
    }

    @discardableResult
    public func group(prefix: String, _ routes: Route.Type..., errorRenderer: ErrorRenderer.Type? = nil) -> Self {
        self.router.group(prefix: prefix, routes, errorRenderer: errorRenderer)
        return self
    }

    public func listen() {

        EnvironmentValues.shared[RouterEnvironmentKey.self] = self.router
        
        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)

        let bootstrap = ServerBootstrap(group: loopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            .childChannelInitializer({ channel in
                channel.pipeline.configureHTTPServerPipeline()
                    .flatMap({
                        channel.pipeline.addHandler(HTTPHandler(router: self.router))
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
        EnvironmentValues.shared.objects.append(object)
        return self
    }

    public func environment<Key: EnvironmentKey>(_ key: Key, _ value: Key.Value) -> Self {
//        EnvironmentValues.shared.keyedObjects[key] = value
        return self
    }
}
