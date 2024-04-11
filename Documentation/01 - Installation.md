# 01 - Installation

Meridian uses Swift Package Manager for installation. 

Add Meridian as a dependency for your package:

    .package(url: "https://github.com/khanlou/Meridian.git", from: "0.2.5"),

The version should be the latest tag on GitHub.

Add Meridian as a dependency for your target as well:

    .product(name: "Meridian", package: "Meridian"),

If you haven't used Swift Package Manager much, here's a complete Package.swift:

    // swift-tools-version:5.9

    import PackageDescription
    
    let package = Package(
        name: "MyFirstApp",
        platforms: [.macOS(.v14)],
        products: [
            .executable(name: "App", targets: ["App"]),
            .library(name: "MyFirstApp", targets: ["MyFirstApp"]),
        ],
        dependencies: [
            .package(url: "https://github.com/khanlou/Meridian.git", from: "0.2.5"),
            .package(url: "https://github.com/swift-server/swift-backtrace.git", from: "1.2.0"),
        ],
        targets: [
            .executableTarget(name: "App", dependencies: ["MyFirstApp"]),
            .target(name: "MyFirstApp", dependencies: [
                .product(name: "Meridian", package: "Meridian"),
                .product(name: "Backtrace", package: "swift-backtrace"),
            ]),
        .testTarget(name: "MyFirstAppTests", dependencies: ["MyFirstApp"]),
        ]
    )


A few notes:

1. Executables can't be tested, so separating your app code into a library will enable you to test any code inside it. Anything in your library will need to be marked as public to be used from the App target.
2. Backtrace is a package that will print the stack trace whenever a crash occurs. This is invaluable for debugging and should be included in every server application.
