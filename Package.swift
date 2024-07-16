// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaceLivenessDetection",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "FaceLivenessDetection",
            targets: ["FaceLivenessDetection"]),
    ],
    targets: [
        .target(
            name: "FaceLivenessDetection",
            dependencies: ["HistogramCalculator"],
            resources: [
                .process("Resources/"),
                .copy("Metal/")
            ]
        ),
        .target(name: "HistogramCalculator"),
        .testTarget(
            name: "FaceLivenessDetectionTests",
            dependencies: ["FaceLivenessDetection"]),
        
    ]
)
