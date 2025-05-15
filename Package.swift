// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swift-tools-version:5.7
// MIT License Copyright (c) 2024 Ayush Srivastava

import PackageDescription

let package = Package(
    name: "openapi-integration-with-docc",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "OpenAPItoSymbolGraph",
            targets: ["OpenAPItoSymbolGraph"]),
        .executable(
            name: "openapi-to-symbolgraph",
            targets: ["CLI"]),
        .executable(
            name: "symbol-graph-debug",
            targets: ["SymbolGraphDebug"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-docc-symbolkit.git", from: "1.0.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "SymbolKit", package: "swift-docc-symbolkit")
            ],
            path: "Sources/Core",
            exclude: ["README.md"]
        ),
        .target(
            name: "OpenAPI",
            dependencies: ["Yams", "Core"],
            path: "Sources/OpenAPI",
            exclude: ["README.md"]
        ),
        .target(
            name: "DocC",
            dependencies: ["OpenAPI", "Core"],
            path: "Sources/DocC",
            exclude: ["README.md"]
        ),
        .target(
            name: "Integration",
            dependencies: [
                "OpenAPI",
                "DocC",
                "Core",
                .product(name: "SymbolKit", package: "swift-docc-symbolkit")
            ],
            path: "Sources/Integration",
            exclude: ["README.md"]
        ),
        .target(
            name: "OpenAPItoSymbolGraph",
            dependencies: [
                "OpenAPI",
                "DocC",
                "Integration",
                "Core",
                .product(name: "SymbolKit", package: "swift-docc-symbolkit")
            ],
            path: "Sources/OpenAPItoSymbolGraph",
            exclude: [
                "README.md",
                "Utils/README.md",
                "Utils/DocC/README.md",
                "Mapping/README.md"
            ],
            sources: [".", "Utils", "Utils/DocC", "Mapping"]
        ),
        .executableTarget(
            name: "CLI",
            dependencies: [
                "OpenAPItoSymbolGraph",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/CLI",
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "SymbolGraphDebug",
            dependencies: [
                "OpenAPItoSymbolGraph",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SymbolKit", package: "swift-docc-symbolkit")
            ],
            path: "Sources/SymbolGraphDebug"
        ),
        .testTarget(
            name: "OpenAPItoSymbolGraphTests",
            dependencies: [
                "OpenAPI",
                "DocC",
                "Integration",
                "OpenAPItoSymbolGraph",
                "Core",
                "CLI",
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            exclude: ["TestFiles/petstore.yaml"]
        ),
    ]
)
