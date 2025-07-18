// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BabySoundsCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BabySoundsCore",
            targets: ["BabySoundsCore"]
        )
    ],
    dependencies: [
        // No external dependencies - self-contained core
    ],
    targets: [
        .target(
            name: "BabySoundsCore",
            dependencies: []
        ),
        .testTarget(
            name: "BabySoundsCoreTests",
            dependencies: ["BabySoundsCore"]
        )
    ]
) 