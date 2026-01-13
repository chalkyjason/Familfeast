// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FamilyFeast",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FamilyFeast",
            targets: ["FamilyFeast"]
        )
    ],
    dependencies: [
        // Add external dependencies here if needed
    ],
    targets: [
        .target(
            name: "FamilyFeast",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "FamilyFeastTests",
            dependencies: ["FamilyFeast"],
            path: "Tests"
        )
    ]
)
