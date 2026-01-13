import Foundation
import SwiftData

/// Represents a recipe that can be voted on and added to meal plans
@Model
final class Recipe {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Recipe title
    var title: String

    /// Detailed cooking instructions
    var instructions: String

    /// Recipe description or summary
    var recipeDescription: String?

    /// Preparation time in minutes
    var prepTime: Int

    /// Cooking time in minutes
    var cookTime: Int

    /// Total time (prep + cook) in minutes
    var totalTime: Int

    /// Number of servings this recipe makes
    var servings: Int

    /// Difficulty level
    var difficulty: DifficultyLevel

    /// Cuisine type (e.g., Italian, Mexican, Thai)
    var cuisine: String?

    /// Meal type (breakfast, lunch, dinner, snack)
    var mealType: MealType

    /// Source URL if imported from web
    var sourceURL: String?

    /// Image URL or local asset name
    var imageURL: String?

    /// Image data stored locally
    @Attribute(.externalStorage) var imageData: Data?

    /// Estimated cost per serving in cents (USD)
    var estimatedCostPerServing: Int?

    /// Total estimated cost in cents (USD)
    var totalEstimatedCost: Int?

    /// Date recipe was added
    var createdAt: Date

    /// Date recipe was last modified
    var modifiedAt: Date

    /// Whether this is a favorite recipe
    var isFavorite: Bool

    /// Number of times this recipe has been made
    var timesCooked: Int

    /// Average rating from family members (0-5)
    var averageRating: Double?

    /// Tags for categorization (e.g., "quick", "vegetarian", "kid-friendly")
    var tags: [String]

    /// Nutritional information (stored as JSON string)
    var nutritionJSON: String?

    /// Reference to family group
    var familyGroup: FamilyGroup?

    /// Ingredients for this recipe
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient]?

    /// Votes for this recipe
    @Relationship(deleteRule: .cascade, inverse: \Vote.recipe)
    var votes: [Vote]?

    /// Meal sessions this recipe is part of
    var mealSessions: [MealSession]?

    /// Scheduled meal plan entries
    @Relationship(deleteRule: .nullify, inverse: \ScheduledMeal.recipe)
    var scheduledMeals: [ScheduledMeal]?

    init(
        id: UUID = UUID(),
        title: String,
        instructions: String,
        recipeDescription: String? = nil,
        prepTime: Int = 0,
        cookTime: Int = 0,
        servings: Int = 4,
        difficulty: DifficultyLevel = .medium,
        cuisine: String? = nil,
        mealType: MealType = .dinner,
        sourceURL: String? = nil,
        imageURL: String? = nil,
        imageData: Data? = nil,
        estimatedCostPerServing: Int? = nil,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.recipeDescription = recipeDescription
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = prepTime + cookTime
        self.servings = servings
        self.difficulty = difficulty
        self.cuisine = cuisine
        self.mealType = mealType
        self.sourceURL = sourceURL
        self.imageURL = imageURL
        self.imageData = imageData
        self.estimatedCostPerServing = estimatedCostPerServing
        self.totalEstimatedCost = estimatedCostPerServing.map { $0 * servings }
        self.createdAt = createdAt
        self.modifiedAt = createdAt
        self.isFavorite = isFavorite
        self.timesCooked = 0
        self.tags = tags
        self.ingredients = []
        self.votes = []
        self.scheduledMeals = []
    }

    /// Calculate aggregate vote score for this recipe
    func calculateVoteScore() -> Int {
        guard let votes = votes, !votes.isEmpty else { return 0 }
        return votes.reduce(0) { $0 + $1.voteType.score }
    }

    /// Get vote counts by type
    func getVoteCounts() -> (likes: Int, dislikes: Int, oks: Int, superLikes: Int) {
        guard let votes = votes else { return (0, 0, 0, 0) }

        var likes = 0
        var dislikes = 0
        var oks = 0
        var superLikes = 0

        for vote in votes {
            switch vote.voteType {
            case .superLike:
                superLikes += 1
            case .like:
                likes += 1
            case .ok:
                oks += 1
            case .dislike:
                dislikes += 1
            case .veto:
                // Vetos are handled separately in consensus algorithm
                break
            }
        }

        return (likes, dislikes, oks, superLikes)
    }

    /// Check if any family member has vetoed this recipe
    func hasVeto() -> Bool {
        guard let votes = votes else { return false }
        return votes.contains { $0.voteType == .veto }
    }
}

/// Difficulty level for recipes
enum DifficultyLevel: String, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
}

/// Type of meal
enum MealType: String, Codable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    case dessert = "dessert"
}

/// Nutritional information structure
struct NutritionInfo: Codable {
    var calories: Int?
    var protein: Double?      // grams
    var carbohydrates: Double? // grams
    var fat: Double?          // grams
    var fiber: Double?        // grams
    var sugar: Double?        // grams
    var sodium: Double?       // milligrams
}
