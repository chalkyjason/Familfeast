// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MealMeld",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MealMeld",
            targets: ["MealMeld"]
        )
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .target(
            name: "MealMeld",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "MealMeldTests",
            dependencies: ["MealMeld"],
            path: "Tests"
        )
    ]
)
