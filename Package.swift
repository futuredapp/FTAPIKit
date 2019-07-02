// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FTAPIKit",
    products: [
        .library(
            name: "FTAPIKit",
            targets: ["FTAPIKit"]),
        .library(
            name: "FTAPIKitPromiseKit",
            targets: ["FTAPIKitPromiseKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "6.8.4"),
    ],
    targets: [
        .target(
            name: "FTAPIKit",
            dependencies: []),
        .target(
            name: "FTAPIKitPromiseKit",
            dependencies: ["FTAPIKit", "PromiseKit"]),
        .testTarget(
            name: "FTAPIKitTests",
            dependencies: ["FTAPIKit"])
    ]
)
