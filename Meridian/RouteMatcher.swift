//
//  RouteMatcher.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

func normalizePath(_ string: String) -> String {
    return normalizePath(string.split(separator: "/"))
}

func normalizePath(_ path: [Substring]) -> String {
    var result = path.joined(separator: "/")
    if !result.starts(with: "/") {
        result.insert("/", at: result.startIndex)
    }
    return result
}

public struct MatchedRoute: Sendable {
    let parameters: [String: Substring]

    public init(parameters: [String: Substring] = [:]) {
        self.parameters = parameters
    }

    public func parameter<Key: URLParameterKey>(for key: Key.Type) throws -> Key.DecodeType {
        guard let substring = self.parameters[Key.stringKey] else {
            throw MissingURLParameterError()
        }
        let value = String(substring)
        if Key.DecodeType.self == String.self {
            return value as! Key.DecodeType
        } else if let finalValue = Key.DecodeType(value) {
            return finalValue
        } else {
            throw URLParameterDecodingError(type: Key.DecodeType.self)
        }

    }
}

public indirect enum RouteMatcher: Sendable {
    case any
    case root
    case path(String)
    case interpolated(InterpolatedPath)
    case custom(matches: @Sendable (RequestHeader) -> MatchedRoute?)
    case method(HTTPMethod, RouteMatcher)
    case multiple([RouteMatcher])

    public init(matches: @Sendable @escaping (RequestHeader) -> MatchedRoute?) {
        self = .custom(matches: matches)
    }

    public func matches(_ header: RequestHeader) -> MatchedRoute? {
        switch self {
        case .path(let string) where normalizePath(header.path) == normalizePath(string):
            return MatchedRoute()
        case .path:
            return nil

        case .root where normalizePath(header.path) == normalizePath(""):
            return MatchedRoute()
        case .root:
            return nil

        case let .method(method, matcher) where method == header.method:
            return matcher.matches(header)
        case .method:
            return nil

        case let .interpolated(interpolatedPath):
            return interpolatedPath.matches(header)

        case let .multiple(matchers):
            return matchers.lazy.compactMap({ $0.matches(header) }).first

        case .any:
            return MatchedRoute()

        case .custom(let matches):
            return matches(header)
        }
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

extension RouteMatcher: ExpressibleByStringInterpolation {

    public init(stringLiteral value: String) {
        self = .path(value)
    }

    public init(stringInterpolation: InterpolatedPath) {
        self = .interpolated(stringInterpolation)
    }
}

extension RouteMatcher: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: RouteMatcher...) {
        self = .multiple(elements)
    }
}

public struct InterpolatedPath: StringInterpolationProtocol, Sendable {
    enum Component: Sendable {
        case literal(String)
        case parameter(name: String, type: LosslessStringConvertible.Type)
    }

    var components: [Component] = []

    public init(literalCapacity: Int, interpolationCount: Int) {

    }

    mutating public func appendLiteral(_ literal: String) {
        components.append(.literal(literal))
    }

    public mutating func appendInterpolation<SpecificKey: URLParameterKey>(_ urlParameter: KeyPath<ParameterKeys, SpecificKey>) {

        components.append(.parameter(name: SpecificKey.stringKey, type: SpecificKey.DecodeType.self))
    }

    var regex: NSRegularExpression {
        let regexString = components
            .map({ component -> String in
                switch component {
                case .literal(let string):
                    return string
                case .parameter:
                    return "([^/]+)"
                }
            })
            .joined()

        return try! NSRegularExpression(pattern: "^\(normalizePath(regexString))$")
    }

    var mapping: [(String, LosslessStringConvertible.Type)] {
        components.compactMap({ component in
            switch component {
            case .literal(_):
                nil
            case .parameter(let name, let type):
                (name, type)
            }
        })
    }

    var pathString: String {
        components.compactMap({ component in
            switch component {
            case let .literal(string):
                string
            case .parameter(let name, _):
                "{\(name.split(separator: ".").last ?? name[...])}"
            }
        })
        .joined()
    }

    func matches(_ header: RequestHeader) -> MatchedRoute? {
        let path = normalizePath(header.path)
        let matches = regex.matches(in: path, range: NSRange(location: 0, length: path.utf16.count))

        if matches.isEmpty {
            return nil
        }

        var result: [String: Substring] = [:]

        for match in matches {
            let ranges = (0..<match.numberOfRanges)
                .dropFirst() /*ignore the first match*/
                .map({ match.range(at: $0) })

            for (mapping, range) in zip(mapping, ranges) {
                let (urlParameterName, type) = mapping
                guard let nativeRange = Range(range, in: path) else { fatalError("Should be able to convert ranges") }
                let substring = path[nativeRange]
                let valueIsConvertible = type.init(String(substring)) != nil
                guard valueIsConvertible else { return nil }
                result[urlParameterName] = substring
            }
        }

        return MatchedRoute(parameters: result)
    }
}
