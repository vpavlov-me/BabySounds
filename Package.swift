// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BabySounds",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "BabySounds",
            targets: ["BabySounds"]
        ),
        .library(
            name: "BabySoundsCore",
            targets: ["BabySoundsCore"]
        ),
        .library(
            name: "BabySoundsUI",
            targets: ["BabySoundsUI"]
        )
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .target(
            name: "BabySounds",
            dependencies: [
                "BabySoundsCore",
                "BabySoundsUI"
            ],
            path: "BabySounds/Sources/BabySounds"
        ),
        .target(
            name: "BabySoundsCore",
            dependencies: [],
            path: "Packages/BabySoundsCore/Sources"
        ),
        .target(
            name: "BabySoundsUI",
            dependencies: ["BabySoundsCore"],
            path: "Packages/BabySoundsUI/Sources"
        ),
        .testTarget(
            name: "BabySoundsTests",
            dependencies: ["BabySounds"],
            path: "BabySounds/Tests"
        ),
        .testTarget(
            name: "BabySoundsCoreTests",
            dependencies: ["BabySoundsCore"],
            path: "Packages/BabySoundsCore/Tests"
        ),
        .testTarget(
            name: "BabySoundsUITests",
            dependencies: ["BabySoundsUI"],
            path: "Packages/BabySoundsUI/Tests"
        )
    ]
) 