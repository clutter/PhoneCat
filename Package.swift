// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhoneCat",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/yaslab/CSV.swift", .upToNextMinor(from: "2.4.3"))
    ],
    targets: [
        .target(
            name: "PhoneCat",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CSV", package: "CSV.swift")
            ]
        ),
        .testTarget(
            name: "PhoneCatTests",
            dependencies: ["PhoneCat"]),
    ]
)
