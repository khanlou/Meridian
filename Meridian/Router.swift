//
//  Router.swift
//  
//
//  Created by Soroush Khanlou on 9/6/20.
//

import Foundation

struct RouterTrieNode: Sendable {
    var children: [String: RouterTrieNode]
    var routes: [Route]
    var middlewareProducers: [@Sendable () -> Middleware]
    var errorRenderer: ErrorRenderer?

    static let empty: RouterTrieNode = .init(children: [:], routes: [], middlewareProducers: [], errorRenderer: nil)

    mutating func insert(_ buildableRoute: _BuildableRoute) {
        if let route = buildableRoute as? Route {
            self.routes.append(route)
        } else if let group = buildableRoute as? Group {
            if group.prefix.path.isEmpty {
                self.errorRenderer = group.errorRenderer
                self.middlewareProducers.append(contentsOf: group.middlewareProducers)
                for route in group.routes() {
                    self.insert(route)
                }
                return
            }
            var group = group
            let prefix = group.prefix.path.removeFirst()
            if group.prefix.isEmpty {
                for buildableRoute in group.routes() {
                    self.children[String(prefix), default: .empty].insert(buildableRoute)
                }
                self.children[String(prefix), default: .empty].errorRenderer = group.errorRenderer
                self.children[String(prefix), default: .empty].middlewareProducers.append(contentsOf: group.middlewareProducers)
            } else {
                self.children[String(prefix), default: .empty].insert(group)
            }
        }
    }

    func bestRouteMatching(header: RequestHeader, errorHandler: inout ErrorRenderer) -> (Route, [Middleware], MatchedRoute)? {

        return self
            .flatMap({ node in
                node.node.routes.map({ (route: $0, node: node) })
            })
            .compactMap({ route, node -> (Route, [Middleware], MatchedRoute)? in
                var mutableHeader = header
                guard node.path.count <= mutableHeader.path.path.count, zip(node.path, mutableHeader.path.path).allSatisfy({ $0 == $1 }) else {
                    return nil
                }
                mutableHeader.path.path.removeFirst(node.path.count)
                errorHandler = (node.errorRenderer ?? errorHandler)
                guard let matchedRoute = route.matcher.matches(mutableHeader) else {
                    return nil
                }
                return (route, node.middlewareProducers.map({ $0() }), matchedRoute)
            })
            .first
    }

    func methods(matching path: String) throws -> Set<HTTPMethod> {

        return try self
            .flatMap({ node in
                node.node.routes.map({ (route: $0, node: node) })
            })
            .reduce(into: Set<HTTPMethod>()) { matchingMethods, routeAndNode in
                for method in HTTPMethod.primaryMethods {
                    var header = try RequestHeader(method: method, uri: path, headers: [])
                    guard routeAndNode.node.path.count <= header.path.path.count, zip(routeAndNode.node.path, header.path.path).allSatisfy({ $0 == $1 }) else {
                        return
                    }
                    header.path.path.removeFirst(routeAndNode.node.path.count)

                    if routeAndNode.route.matcher.matches(header) != nil {
                        matchingMethods.insert(method)
                    }
                }
            }
    }
}

extension RouterTrieNode: Sequence {

    struct RoutableNode {
        let node: RouterTrieNode
        let errorRenderer: ErrorRenderer?
        let middlewareProducers: [() -> Middleware]
        let path: [String]
    }

    func makeIterator() -> Iterator {
        Iterator(startingNode: self)
    }

    struct Iterator: IteratorProtocol {
        var nodeStack: [RoutableNode] = []

        init(startingNode: RouterTrieNode) {
            nodeStack.append(RoutableNode(node: startingNode, errorRenderer: startingNode.errorRenderer, middlewareProducers: startingNode.middlewareProducers, path: []))
        }

        public mutating func next() -> RoutableNode? {
            guard !nodeStack.isEmpty else { return nil }
            let next = nodeStack.removeFirst()
            nodeStack.append(contentsOf: next.node.children.map({ pathComponent, node in
                RoutableNode(
                    node: node,
                    errorRenderer: node.errorRenderer ?? next.errorRenderer,
                    middlewareProducers: node.middlewareProducers + next.middlewareProducers,
                    path: next.path + [pathComponent]
                )
            }))
            return next
        }
    }
}

final class Router: @unchecked Sendable {

    var registeredRoutes: [() -> [_BuildableRoute]] = []

    var defaultErrorRenderer: ErrorRenderer

    var middlewareProducers: [() -> Middleware]

    init(defaultErrorRenderer: ErrorRenderer, middlewareProducers: [() -> Middleware] = []) {
        self.defaultErrorRenderer = defaultErrorRenderer
        self.middlewareProducers = middlewareProducers
    }

    func register(_ routes: @escaping () -> [_BuildableRoute]) {
        registeredRoutes.append(routes)
    }

    func makeTrie() -> RouterTrieNode {
        var root = RouterTrieNode.empty
        root.middlewareProducers = self.middlewareProducers
        for route in registeredRoutes.flatMap({ $0() }) {
            root.insert(route)
        }
        return root
    }

    func route(for header: RequestHeader) -> ((Responder, MatchedRoute)?, [Middleware], ErrorRenderer) {
        let root = makeTrie()

        var errorHandlerBestGuess = defaultErrorRenderer

        if let (route, middleware, matchedRoute) = root.bestRouteMatching(header: header, errorHandler: &errorHandlerBestGuess) {
            return ((route.responder, matchedRoute), middleware, errorHandlerBestGuess)
        }

        return (nil, middlewareProducers.map({ $0() }), errorHandlerBestGuess)
    }

    func handle(request: RequestContext) async throws -> Response {
        let hydration = Hydration(context: request)

        let routing = RoutingMiddleware(router: self, hydration: hydration)

        hydration.context.matchedRoute = routing.matchedRoute

        return try await routing.execute(next: BottomRoute())
            .additionalHeaders(["Server": EnvironmentValues().serverName])
    }

    func methods(for path: String) throws -> Set<HTTPMethod> {
        return try makeTrie().methods(matching: path)
    }
}

private extension String {
    var path: [Substring] {
        get {
            self.split(separator: "/")
        }
        set {
            self = newValue.joined(separator: "/")
        }
    }
}

