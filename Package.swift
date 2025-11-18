// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "FTAPIKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "FTAPIKit",
            targets: ["FTAPIKit"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FTAPIKit",
            dependencies: []
        ),
        .testTarget(
            name: "FTAPIKitTests",
            dependencies: ["FTAPIKit"])
    ]
)
