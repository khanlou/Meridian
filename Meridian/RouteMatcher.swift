//
//  RouteMatcher.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public struct MatchedRoute {
    public let parameters: [URLParameterKey: Substring]

    public init(parameters: [URLParameterKey: Substring] = [:]) {
        self.parameters = parameters
    }
}

public struct RouteMatcher {
    public let matches: (RequestHeader) -> MatchedRoute?

    public static func path(_ string: String) -> RouteMatcher {
        RouteMatcher(matches: { header in
            if (header.path == string) {
                return MatchedRoute()
            } else {
                return nil
            }
        })
    }

    public static let any = RouteMatcher(matches: { _ in MatchedRoute() })

    public static func method(_ method: HTTPMethod, _ matcher: RouteMatcher) -> RouteMatcher {
        RouteMatcher(matches: { header in
            if header.method == method {
                return matcher.matches(header)
            }
            return nil
        })
    }

    public static func get(_ matcher: RouteMatcher) -> RouteMatcher {
        self.method(.GET, matcher)
    }

    public static func post(_ matcher: RouteMatcher) -> RouteMatcher {
        self.method(.POST, matcher)
    }

    public static func patch(_ matcher: RouteMatcher) -> RouteMatcher {
        self.method(.PATCH, matcher)
    }

    public static func delete(_ matcher: RouteMatcher) -> RouteMatcher {
        self.method(.DELETE, matcher)
    }
}

public struct URLParameterKey: Hashable {

    public let id = UUID()

    public init() {

    }

    public static let id = URLParameterKey()
}


extension RouteMatcher: ExpressibleByStringInterpolation {

    public struct RegexMatcher: StringInterpolationProtocol {

        var regexString = ""

        var mapping: [URLParameterKey] = []

        public init(literalCapacity: Int, interpolationCount: Int) {

        }

        mutating public func appendLiteral(_ literal: String) {
            regexString.append(literal) // escape for regex
        }

        public mutating func appendInterpolation(_ urlParameter: URLParameterKey) {

            regexString.append("([^/]+)")

            mapping.append(urlParameter)
        }
    }

    public init(stringLiteral value: String) {
        self = Self.path(value)
    }

    public init(stringInterpolation: RegexMatcher) {
        let regex = try! NSRegularExpression(pattern: "^\(stringInterpolation.regexString)$")

        self.matches = { header in
            let matches = regex.matches(in: header.path, range: NSRange(location: 0, length: header.path.utf16.count))

            if matches.isEmpty {
                return nil
            }

            var result: [URLParameterKey: Substring] = [:]

            for match in matches {
                let ranges = (0..<match.numberOfRanges)
                    .dropFirst() /*ignore the first match*/
                    .map({ match.range(at: $0) })

                zip(stringInterpolation.mapping, ranges).forEach({ urlParameter, range in
                    guard let betterRange = Range(range, in: header.path) else { fatalError("Should be able to convert ranges") }
                    result[urlParameter] = header.path[betterRange]
                })
            }

            return MatchedRoute(parameters: result)
        }
    }
}

extension RouteMatcher: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: RouteMatcher...) {
        self.matches = { header in
            elements.lazy.compactMap({ $0.matches(header) }).first
        }
    }
}
