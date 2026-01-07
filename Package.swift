// swift-tools-version:5.5

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
    dependencies: [
        .package(url: "https://github.com/futuredapp/FTNetworkTracer", from: "0.2.1")
    ],
    targets: [
        .target(
            name: "FTAPIKit",
            dependencies: [
                .product(name: "FTNetworkTracer", package: "FTNetworkTracer")
            ]
        ),
        .testTarget(
            name: "FTAPIKitTests",
            dependencies: ["FTAPIKit"])
    ]
)
