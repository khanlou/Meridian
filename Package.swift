// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Meridian",
    products: [
        .executable(name: "Demo", targets: ["Demo"]),
        .library(name: "Meridian", targets: ["Meridian"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: "2.22.0"),
        .package(url: "https://github.com/swift-server/swift-backtrace.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .target(name: "Demo", dependencies: [
            .product(name: "Meridian", package: "Meridian"),
            .product(name: "Backtrace", package: "swift-backtrace"),
        ], path: "Demo"),
        .target(name: "Meridian", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ], path: "Meridian"),
        .testTarget(name: "MeridianTests", dependencies: ["Meridian"], path: "MeridianTests"),
    ]
)
