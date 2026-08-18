// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-utils",
    defaultLocalization: "en",
    platforms: [.macOS(.v13), .iOS(.v16),],
    products: [
        .library(
            name: "SPFKUtils",
            targets: ["SPFKUtils",]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-audio-base", from: "1.6.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-filesystem", from: "1.2.2"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "1.1.0"),
        .package(url: "https://github.com/tadija/AEXML", from: "4.6.0"),
    ],
    targets: [
        .target(
            name: "SPFKUtils",
            dependencies: [
                .product(name: "SPFKFileSystem", package: "spfk-filesystem"),
                .product(name: "AEXML", package: "AEXML"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SPFKUtilsTests",
            dependencies: [
                .targetItem(name: "SPFKUtils", condition: nil),
                .product(name: "SPFKAudioBase", package: "spfk-audio-base"),
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ]
)
