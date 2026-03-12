// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "FTAPIKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
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
