// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swift-tools-version:5.7
// MIT License Copyright (c) 2024 Ayush Srivastava

import PackageDescription

let package = Package(
    name: "OpenAPItoSymbolGraph",
    products: [
        .executable(name: "openapi-to-symbolgraph", targets: ["CLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "3.1.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-symbolkit.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "SymbolKit", package: "swift-docc-symbolkit")
            ],
            path: "Sources/Core"
        ),
        .executableTarget(
            name: "CLI",
            dependencies: [
                "Core",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "SymbolKit", package: "swift-docc-symbolkit")
            ],
            path: "Sources/CLI"
        ),
        .testTarget(
            name: "OpenAPItoSymbolGraphTests",
            dependencies: ["Core", "CLI"],
            path: "Tests"
        )
    ]
)
