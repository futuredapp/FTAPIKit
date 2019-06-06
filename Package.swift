// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FTAPIKit",
    products: [
        .library(
            name: "FTAPIKit",
            targets: ["FTAPIKit"]),
        .library(
            name: "FTAPIKitPromises",
            targets: ["FTAPIKitPromises"])
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "6.8.4"),
    ],
    targets: [
        .target(
            name: "FTAPIKit",
            dependencies: []),
        .target(
            name: "FTAPIKitPromises",
            dependencies: ["FTAPIKit", "PromiseKit"]),
        .testTarget(
            name: "FTAPIKitTests",
            dependencies: ["FTAPIKit"])
    ]
)
