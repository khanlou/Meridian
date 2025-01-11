// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Meridian",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Demo", targets: ["Demo"]),
        .library(name: "Meridian", targets: ["Meridian"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: "2.64.0"),
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/swift-backtrace.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .executableTarget(name: "Demo", dependencies: [
            .target(name: "Meridian"),
            .product(name: "Backtrace", package: "swift-backtrace"),
        ], path: "Demo"),
        .target(name: "Meridian", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            .product(name: "NIOWebSocket", package: "swift-nio"),
            .product(name: "WebSocketKit", package: "websocket-kit"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ], path: "Meridian"),
        .testTarget(name: "MeridianTests", dependencies: ["Meridian"], path: "MeridianTests"),
    ]
)
