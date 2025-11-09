// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BabySounds",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "BabySounds",
            targets: ["BabySounds"]
        ),
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .target(
            name: "BabySounds",
            dependencies: [],
            path: "BabySounds/Sources/BabySounds",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "BabySoundsTests",
            dependencies: ["BabySounds"],
            path: "BabySounds/Tests"
        ),
    ]
)
