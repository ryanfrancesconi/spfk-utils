// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-utils",
    platforms: [.macOS(.v12), .iOS(.v15),],
    products: [
        .library(
            name: "SPFKUtils",
            targets: ["SPFKUtils",]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-audio-base", from: "0.0.5"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "0.0.5"),
        .package(url: "https://github.com/tadija/AEXML", from: "4.6.0"),
        .package(url: "https://github.com/rnine/Checksum", from: "1.0.2"),
        .package(url: "https://github.com/jozefizso/swift-xattr", from: "3.0.1")
    ],
    targets: [
        .target(
            name: "SPFKUtils",
            dependencies: [
                .product(name: "SPFKAudioBase", package: "spfk-audio-base"),
                .product(name: "AEXML", package: "AEXML"),
                .product(name: "Checksum", package: "Checksum"),
                .product(name: "XAttr", package: "swift-xattr"),
            ]
        ),
        .testTarget(
            name: "SPFKUtilsTests",
            dependencies: [
                .targetItem(name: "SPFKUtils", condition: nil),
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ]
)
