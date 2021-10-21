// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FTAPIKit",
    platforms: [.iOS(.v12), .macOS(.v10_10), .tvOS(.v12), .watchOS(.v5)],
    products: [
        .library(
            name: "FTAPIKit",
            targets: ["FTAPIKit"])
    ],
    targets: [
        .target(
            name: "FTAPIKit",
            dependencies: []
        ),
        .testTarget(
            name: "FTAPIKitTests",
            dependencies: ["FTAPIKit"]
        )
    ]
)
