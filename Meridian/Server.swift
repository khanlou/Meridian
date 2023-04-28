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
    let result = setvbuf(stdout, nil, _IOLBF, 16 * 1024)
    precondition(result == 0)
}

struct ServeOptions: ParsableArguments {
    @Option var port: Int = 3000
    @Option var host: String = "localhost"
}

struct RouteGroup: ExpressibleByArrayLiteral {

    var routes: [() -> [Route]]
    var customErrorRenderer: ErrorRenderer?

    init() {
        self.routes = []
        self.customErrorRenderer = nil
    }

    init(arrayLiteral elements: Route...) {
        self.routes = [{ elements }]
        self.customErrorRenderer = nil
    }

    mutating func append(_ route: Route) {
        self.routes.append({ [route] })
    }

    mutating func append(contentsOf routes: @escaping () -> [Route]) {
        self.routes.append(routes)
    }

    func makeAllRoutes() -> [Route] {
        routes.flatMap({ $0() })
    }
}

public final class Server {

    let options = ServeOptions.parseOrExit()

    let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    var router: Router

    var middlewareProducers: [() -> Middleware] = []

    public init(errorRenderer: ErrorRenderer) {
        enableLineBufferedLogging()
        self.router = Router(routesByPrefix: [:], defaultErrorRenderer: errorRenderer)
        EnvironmentValues.shared[RouterEnvironmentKey.self] = self.router
        EnvironmentValues.shared.loopGroup = self.loopGroup
   }

    @discardableResult
    public func register(errorRenderer: ErrorRenderer? = nil, @RouteBuilder _ builder: @escaping () -> [Route]) -> Self {
        self.router.register(prefix: "", errorRenderer: errorRenderer, builder)
        return self
    }

    @discardableResult
    public func group(prefix: String, errorRenderer: ErrorRenderer? = nil, @RouteBuilder _ builder: @escaping () -> [Route]) -> Self {
        self.router.register(prefix: prefix, errorRenderer: errorRenderer, builder)
        return self
    }

    public func listen() {

        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)

        let bootstrap = ServerBootstrap(group: loopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            .childChannelInitializer({ channel in

                let parsing = HTTPRequestParsingHandler()

                let http = HTTPHandler(router: self.router, middlewareProducers: self.middlewareProducers)

                return channel.pipeline
                    .configureHTTPServerPipeline(withServerUpgrade: (upgraders: [WebSocketUpgrader(router: self.router)], completionHandler: { context in
                        _ = context.pipeline.removeHandler(parsing)
                            .and(context.pipeline.removeHandler(http))
                    }))
                    .flatMap({
                        channel.pipeline.addHandlers([parsing, http])
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

    public func environmentObject<T: AnyObject>(with constructor: (EnvironmentValues) -> T) -> Self {
        let object = constructor(EnvironmentValues.shared)
        EnvironmentValues.shared.storage[ObjectIdentifier(T.self)] = object
        return self
    }

    public func environment<Value>(_ keyPath: WritableKeyPath<EnvironmentValues, Value>, _ value: Value) -> Self {
        EnvironmentValues.shared[keyPath: keyPath] = value
        return self
    }
}

extension Server {
    public func middleware(_ middleware: @autoclosure @escaping () -> Middleware) -> Self {
        self.middlewareProducers.append(middleware)
        return self
    }
}
