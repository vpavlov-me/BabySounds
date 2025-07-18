// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BabySoundsUI",
    platforms: [
        .iOS(.v17)
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
            ]
        ),
        .testTarget(
            name: "BabySoundsUITests",
            dependencies: ["BabySoundsUI"]
        )
    ]
) 