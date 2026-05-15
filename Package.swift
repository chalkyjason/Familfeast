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
    dependencies: [],
    targets: [
        .target(
            name: "MealMeld",
            dependencies: [],
            path: "Sources",
            exclude: [
                "App",
                "Assets.xcassets",
                "Models/AppError.swift",
                "Services",
                "Utilities/CurrencyFormatter.swift",
                "Utilities/Config.swift",
                "Utilities/Logger+Extension.swift",
                "Utilities/Theme.swift",
                "Views"
            ],
            sources: [
                "Models/FamilyGroup.swift",
                "Models/Ingredient.swift",
                "Models/MealSession.swift",
                "Models/Recipe.swift",
                "Models/ShoppingList.swift",
                "Models/Vote.swift",
                "Utilities/VotingAlgorithm.swift"
            ]
        ),
        .testTarget(
            name: "MealMeldTests",
            dependencies: ["MealMeld"],
            path: "Tests"
        )
    ]
)
