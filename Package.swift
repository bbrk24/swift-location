// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftLocation",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "SwiftLocation",
            targets: ["SwiftLocation"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftLocation"
        ),
        .testTarget(
            name: "SwiftLocationTests",
            dependencies: ["SwiftLocation"],
        )
    ]
)
