// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BabySoundsUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BabySoundsUI",
            targets: ["BabySoundsUI"]
        )
    ],
    dependencies: [
        .package(path: "../BabySoundsCore")
    ],
    targets: [
        .target(
            name: "BabySoundsUI",
            dependencies: [
                .product(name: "BabySoundsCore", package: "BabySoundsCore")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "BabySoundsUITests",
            dependencies: ["BabySoundsUI"],
            path: "Tests"
        )
    ]
) 