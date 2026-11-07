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
    dependencies: [
        .package(
            url: "https://github.com/moreSwift/AndroidKit",
            .upToNextMinor(from: "0.8.1")
        ),
        .package(
            url: "https://github.com/stackotter/swift-java",
            .upToNextMinor(from: "0.5.1")
        ),
    ],
    targets: [
        .target(
            name: "SwiftLocation",
            dependencies: [
                .product(
                    name: "AndroidKit",
                    package: "AndroidKit",
                    condition: .when(platforms: [.android])
                ),
                .product(
                    name: "SwiftJava",
                    package: "swift-java",
                    condition: .when(platforms: [.android])
                ),
            ]
        ),
        .testTarget(
            name: "SwiftLocationTests",
            dependencies: ["SwiftLocation"],
        )
    ]
)
