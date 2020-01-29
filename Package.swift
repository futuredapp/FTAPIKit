// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FTAPIKit",
    products: [
        .library(
            name: "FTAPIKit",
            targets: ["FTAPIKit"]),
    ],
    targets: [
        .target(
            name: "FTAPIKit",
            dependencies: []),
        .testTarget(
            name: "FTAPIKitTests",
            dependencies: ["FTAPIKit"])
    ]
)
