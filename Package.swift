// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Triff",
    products: [
        .library(
            name: "Triff",
            targets: ["Triff"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Triff",
            dependencies: []),
        .testTarget(
            name: "TriffTests",
            dependencies: ["Triff"]),
    ]
)
