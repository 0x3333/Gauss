// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GaussEngine",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GaussEngine", targets: ["GaussEngine"]),
    ],
    targets: [
        .target(
            name: "GaussEngine",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "GaussEngineTests",
            dependencies: ["GaussEngine"]
        ),
    ]
)
