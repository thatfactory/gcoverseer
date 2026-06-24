// swift-tools-version:6.4

import PackageDescription

let package = Package(
    name: "GCOverseer",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .tvOS(.v26)
    ],
    products: [
        .library(
            name: "GCOverseer",
            targets: ["GCOverseer"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/thatfactory/applogger",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/apple/swift-testing.git",
            branch: "swift-6.2.1-RELEASE"
        )
    ],
    targets: [
        .target(
            name: "GCOverseer",
            dependencies: [
                .product(
                    name: "AppLogger",
                    package: "applogger"
                )
            ]
        ),
        .testTarget(
            name: "GCOverseerTests",
            dependencies: [
                "GCOverseer",
                .product(
                    name: "Testing",
                    package: "swift-testing"
                )
            ]
        )
    ]
)
