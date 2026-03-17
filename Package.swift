// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "FTAPIKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
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
