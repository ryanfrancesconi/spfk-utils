// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-utils",
    platforms: [.macOS(.v13), .iOS(.v16),],
    products: [
        .library(
            name: "SPFKUtils",
            targets: ["SPFKUtils",]
        ),

        // Image conversion throughput and memory -- see Sources/ImageConversionBench. An executable
        // because the numbers only mean anything compiled `-O`.
        .executable(name: "spfk-image-conversion-bench", targets: ["ImageConversionBench"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-audio-base", from: "1.6.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-filesystem", from: "1.2.2"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-image", from: "0.1.0"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-base", from: "1.2.2"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "1.1.0"),
        .package(url: "https://github.com/tadija/AEXML", from: "4.6.0"),
    ],
    targets: [
        .target(
            name: "SPFKUtils",
            dependencies: [
                .product(name: "SPFKFileSystem", package: "spfk-filesystem"),
                .product(name: "SPFKImage", package: "spfk-image"),
                .product(name: "AEXML", package: "AEXML"),
            ]
        ),
        .executableTarget(
            name: "ImageConversionBench",
            dependencies: [
                .targetItem(name: "SPFKUtils", condition: nil),
                .product(name: "SPFKImage", package: "spfk-image"),
                .product(name: "SPFKBench", package: "spfk-testing"),
            ]
        ),
        .testTarget(
            name: "SPFKUtilsTests",
            dependencies: [
                .targetItem(name: "SPFKUtils", condition: nil),
                .product(name: "SPFKImage", package: "spfk-image"),
                .product(name: "SPFKAudioBase", package: "spfk-audio-base"),
                .product(name: "SPFKBase", package: "spfk-base"),
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ]
)
