//
//  File.swift
//  
//
//  Created by Soroush Khanlou on 5/20/24.
//

import OpenAPIKit
import Foundation

func schema<T>(from type: T.Type) -> JSONSchema {
    if [String.self, Substring.self].contains(where: { $0 == T.self }) {
        return .string
    } else if T.self is any BinaryInteger.Type {
        return .integer
    } else if T.self is any BinaryFloatingPoint.Type {
        return .number
    } else if T.self is Bool.Type {
        return .boolean
    } else {
        return .null()
    }
}

public struct OpenAPIGenerator {
    public let router: Router

    public init(router: Router) {
        self.router = router
    }

    var info: OpenAPI.Document.Info {
        .init(
            title: Bundle.main.executablePath?.components(separatedBy: "/").last ?? "unknown",
            summary: nil,
            description: nil,
            termsOfService: nil,
            contact: nil,
            license: nil,
            version: "1.0"
        )
    }

    var servers: [OpenAPI.Server] {
        [
            OpenAPI.Server(
                url: URL(string: "https://choreboard.nicethings.com")! 
            )
        ]
    }

    var paths: OpenAPI.PathItem.Map {
        router.makeTrie()
            .flatMap({ node in
                node.node.routes.map({ (route: $0, node: node) })
            })
            .reduce(into: OpenAPI.PathItem.Map(), { dict, nodeAndRoute in
                let (route, node) = nodeAndRoute
                let path = OpenAPI.Path(rawValue: node.path.joined() + route.matcher.path)
                var val = dict[path]?.pathItemValue ?? .init()

                guard let methodString = route.matcher.httpMethod?.name, let method = OpenAPI.HttpMethod(rawValue: methodString) else {
                    return
                }

                val.set(
                    operation: .init(
                        operationId: opID(for: route),
                        parameters: parameters(for: route),
                        requestBody: nil,
                        responses: .init()
                    ),
                    for: method
                )

                dict[path] = .pathItem(val)
            })
    }

    public func document() -> OpenAPI.Document {
        OpenAPI.Document(
            info: info,
            servers: servers,
            paths: paths,
            components: .init()
        )
    }

    func opID(for route: Route) -> String {
        String(describing: type(of: route.responder))
    }

    func parameters(for route: Route) -> OpenAPI.Parameter.Array {
        let m = Mirror(reflecting: route.responder)
        return m.children
            .compactMap({ $0.value as? PropertyWrapper })
            .flatMap({ $0.openAPIParameters() })
            .map({ .parameter($0) })
    }
}
