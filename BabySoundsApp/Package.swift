// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BabySoundsApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "BabySoundsApp",
            targets: ["BabySoundsApp"]
        )
    ],
    dependencies: [
        .package(path: "../Packages/BabySoundsCore"),
        .package(path: "../Packages/BabySoundsUI")
    ],
    targets: [
        .executableTarget(
            name: "BabySoundsApp",
            dependencies: [
                .product(name: "BabySoundsCore", package: "BabySoundsCore"),
                .product(name: "BabySoundsUI", package: "BabySoundsUI")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BabySoundsAppTests",
            dependencies: ["BabySoundsApp"],
            path: "Tests"
        )
    ]
) 