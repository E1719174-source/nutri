// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NutriApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "NutriApp",
            targets: ["NutriApp"]),
    ],
    targets: [
        .target(
            name: "NutriApp",
            path: "Sources"
        )
    ]
)
