import Foundation
import SwiftData

/// Represents an ingredient needed for a recipe
@Model
final class Ingredient {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Ingredient name (e.g., "Onion", "Chicken Breast")
    var name: String

    /// Quantity needed
    var quantity: Double

    /// Unit of measurement (e.g., "cup", "tablespoon", "grams")
    var unit: String

    /// Original text from recipe (e.g., "2 large onions, diced")
    var originalText: String?

    /// Food category for shopping organization
    var category: FoodCategory

    /// Aisle location in store
    var aisle: String?

    /// Whether this ingredient is optional
    var isOptional: Bool

    /// Preparation notes (e.g., "diced", "minced", "room temperature")
    var preparation: String?

    /// Estimated cost in cents
    var estimatedCost: Int?

    /// Whether this is a pantry staple (already owned)
    var isPantryStaple: Bool

    /// Reference to the recipe
    var recipe: Recipe?

    /// Shopping list items that reference this ingredient
    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.ingredient)
    var shoppingListItems: [ShoppingListItem]?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        originalText: String? = nil,
        category: FoodCategory = .other,
        aisle: String? = nil,
        isOptional: Bool = false,
        preparation: String? = nil,
        estimatedCost: Int? = nil,
        isPantryStaple: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.originalText = originalText
        self.category = category
        self.aisle = aisle
        self.isOptional = isOptional
        self.preparation = preparation
        self.estimatedCost = estimatedCost
        self.isPantryStaple = isPantryStaple
        self.shoppingListItems = []
    }

    /// Display string for the ingredient (e.g., "2 cups flour")
    var displayString: String {
        let quantityString = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity)
            : String(format: "%.2f", quantity)

        var result = "\(quantityString) \(unit) \(name)"

        if let prep = preparation, !prep.isEmpty {
            result += ", \(prep)"
        }

        return result
    }
}

/// Food categories for organizing shopping lists
enum FoodCategory: String, Codable, CaseIterable {
    case produce = "produce"
    case meat = "meat"
    case seafood = "seafood"
    case dairy = "dairy"
    case bakery = "bakery"
    case frozen = "frozen"
    case canned = "canned"
    case grains = "grains"
    case spices = "spices"
    case condiments = "condiments"
    case snacks = "snacks"
    case beverages = "beverages"
    case other = "other"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .produce: return "Produce"
        case .meat: return "Meat & Poultry"
        case .seafood: return "Seafood"
        case .dairy: return "Dairy & Eggs"
        case .bakery: return "Bakery"
        case .frozen: return "Frozen"
        case .canned: return "Canned Goods"
        case .grains: return "Grains & Pasta"
        case .spices: return "Spices & Herbs"
        case .condiments: return "Condiments & Sauces"
        case .snacks: return "Snacks"
        case .beverages: return "Beverages"
        case .other: return "Other"
        }
    }

    /// Icon for UI display
    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .meat: return "fork.knife"
        case .seafood: return "fish.fill"
        case .dairy: return "waterbottle.fill"
        case .bakery: return "birthday.cake.fill"
        case .frozen: return "snowflake"
        case .canned: return "cylinder.fill"
        case .grains: return "rectangle.stack.fill"
        case .spices: return "sparkles"
        case .condiments: return "drop.fill"
        case .snacks: return "bag.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .other: return "cart.fill"
        }
    }
}

/// Extension for ingredient parsing and normalization
extension Ingredient {
    /// Parse an ingredient string using AI or regex patterns
    static func parse(from text: String) -> Ingredient? {
        // This will be implemented with AI service
        // For now, create a basic parser

        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Try to extract quantity and unit using regex
        let pattern = #"^(\d+(?:\.\d+)?|\d+/\d+)?\s*([a-zA-Z]+)?\s+(.+)$"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed))
        else {
            // If no match, treat entire string as ingredient name
            return Ingredient(
                name: trimmed,
                quantity: 1,
                unit: "unit",
                originalText: text,
                category: .other
            )
        }

        var quantity: Double = 1.0
        var unit = "unit"
        var name = trimmed

        // Extract quantity
        if let quantityRange = Range(match.range(at: 1), in: trimmed) {
            let quantityStr = String(trimmed[quantityRange])
            if quantityStr.contains("/") {
                // Handle fractions like "1/2"
                let parts = quantityStr.split(separator: "/").compactMap { Double($0) }
                if parts.count == 2 {
                    quantity = parts[0] / parts[1]
                }
            } else {
                quantity = Double(quantityStr) ?? 1.0
            }
        }

        // Extract unit
        if let unitRange = Range(match.range(at: 2), in: trimmed) {
            unit = String(trimmed[unitRange])
        }

        // Extract name
        if let nameRange = Range(match.range(at: 3), in: trimmed) {
            name = String(trimmed[nameRange])
        }

        // Categorize ingredient
        let category = categorize(ingredientName: name)

        return Ingredient(
            name: name,
            quantity: quantity,
            unit: unit,
            originalText: text,
            category: category
        )
    }

    /// Categorize ingredient based on name
    private static func categorize(ingredientName: String) -> FoodCategory {
        let lowercased = ingredientName.lowercased()

        let categoryKeywords: [FoodCategory: [String]] = [
            .produce: ["lettuce", "tomato", "onion", "garlic", "carrot", "potato", "pepper", "apple", "banana", "lemon", "lime", "spinach", "kale", "cucumber", "celery"],
            .meat: ["chicken", "beef", "pork", "turkey", "ham", "bacon", "sausage", "lamb", "veal"],
            .seafood: ["fish", "salmon", "tuna", "shrimp", "crab", "lobster", "cod", "tilapia"],
            .dairy: ["milk", "cheese", "yogurt", "butter", "cream", "egg", "sour cream"],
            .bakery: ["bread", "bun", "roll", "tortilla", "bagel", "croissant"],
            .frozen: ["frozen", "ice cream", "popsicle"],
            .canned: ["canned", "can", "jar"],
            .grains: ["rice", "pasta", "flour", "oats", "quinoa", "couscous", "noodle"],
            .spices: ["salt", "pepper", "cumin", "paprika", "oregano", "basil", "thyme", "cinnamon", "vanilla", "garlic powder"],
            .condiments: ["ketchup", "mustard", "mayo", "sauce", "dressing", "vinegar", "oil", "soy sauce"],
            .snacks: ["chip", "cracker", "cookie", "candy", "nut"],
            .beverages: ["juice", "soda", "coffee", "tea", "water", "wine", "beer"]
        ]

        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { lowercased.contains($0) }) {
                return category
            }
        }

        return .other
    }
}
