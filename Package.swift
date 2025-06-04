// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpaceMazeUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SpaceMazeUI",
            targets: ["SpaceMazeUI"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SpaceMazeUI",
            dependencies: []),
    ]
) 