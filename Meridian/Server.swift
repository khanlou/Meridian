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

func enableLineBufferedLogging() {
    assert(setvbuf(stdout, nil, _IOLBF, 16 * 1024) != 0)
}

struct ServeOptions: ParsableArguments {
    @Option var port: Int = 3000
    @Option var host: String = "localhost"
}

struct RouteGroup: ExpressibleByArrayLiteral {

    var routes: [Route]
    var customErrorRenderer: ErrorRenderer?

    init() {
        self.routes = []
        self.customErrorRenderer = nil
    }

    init(arrayLiteral elements: Route...) {
        self.routes = elements
        self.customErrorRenderer = nil
    }

    mutating func append(_ route: Route) {
        self.routes.append(route)
    }

    mutating func append(contentsOf routes: [Route]) {
        self.routes.append(contentsOf: routes)
    }

}

public final class Server {

    let options = ServeOptions.parseOrExit()

    let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    var router: Router

    public init(errorRenderer: ErrorRenderer) {
        enableLineBufferedLogging()
        self.router = Router(routesByPrefix: [:], defaultErrorRenderer: errorRenderer)
    }

    @discardableResult
    public func register(errorRenderer: ErrorRenderer? = nil, @RouteBuilder _ builder: () -> [Route]) -> Self {
        self.router.register(prefix: "", errorRenderer: errorRenderer, builder())
        return self
    }

    @discardableResult
    public func group(prefix: String, errorRenderer: ErrorRenderer? = nil, @RouteBuilder _ builder: () -> [Route]) -> Self {
        self.router.register(prefix: prefix, errorRenderer: errorRenderer, builder())
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
    public func environmentObject<T: AnyObject>(_ object: T) -> Self {
        EnvironmentValues.shared.storage[ObjectIdentifier(T.self)] = object
        return self
    }

    public func environment<Key: EnvironmentKey>(_ key: Key, _ value: Key.Value) -> Self {
        EnvironmentValues.shared[Key.self] = value
        return self
    }
}
