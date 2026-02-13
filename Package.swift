// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleAgent",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "SimpleAgent",
            targets: ["SimpleAgent"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SimpleAgent",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
            ]
        ),
        .testTarget(
            name: "SimpleAgentTests",
            dependencies: ["SimpleAgent"]
        ),
    ]
)
