import Foundation
import SwiftData

/// Represents a shopping list generated from meal plans
@Model
final class ShoppingList {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// List name
    var name: String

    /// Date created
    var createdAt: Date

    /// Date last modified
    var modifiedAt: Date

    /// Whether this list is complete
    var isComplete: Bool

    /// Store name or location
    var store: String?

    /// Estimated total cost in cents
    var estimatedTotal: Int?

    /// Actual total spent in cents
    var actualTotal: Int?

    /// Reference to family group
    var familyGroup: FamilyGroup?

    /// Reference to meal session this list was generated from
    var mealSession: MealSession?

    /// Items in this shopping list
    @Relationship(deleteRule: .cascade, inverse: \ShoppingListItem.shoppingList)
    var items: [ShoppingListItem]?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        isComplete: Bool = false,
        store: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = createdAt
        self.isComplete = isComplete
        self.store = store
        self.items = []
    }

    /// Calculate total estimated cost
    func calculateEstimatedTotal() -> Int {
        guard let items = items else { return 0 }
        return items.compactMap { $0.estimatedCost }.reduce(0, +)
    }

    /// Get items grouped by category
    func itemsByCategory() -> [FoodCategory: [ShoppingListItem]] {
        guard let items = items else { return [:] }
        return Dictionary(grouping: items) { $0.category }
    }

    /// Get completion percentage
    func completionPercentage() -> Double {
        guard let items = items, !items.isEmpty else { return 0 }
        let checkedCount = items.filter { $0.isChecked }.count
        return Double(checkedCount) / Double(items.count) * 100
    }

    /// Number of items remaining
    func remainingItems() -> Int {
        guard let items = items else { return 0 }
        return items.filter { !$0.isChecked }.count
    }
}

/// Represents an item in a shopping list
@Model
final class ShoppingListItem {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Item name
    var name: String

    /// Quantity needed
    var quantity: Double

    /// Unit of measurement
    var unit: String

    /// Category for grouping
    var category: FoodCategory

    /// Whether item has been purchased
    var isChecked: Bool

    /// Estimated cost in cents
    var estimatedCost: Int?

    /// Actual cost in cents
    var actualCost: Int?

    /// Notes for this item
    var notes: String?

    /// Aisle location
    var aisle: String?

    /// Date added to list
    var addedAt: Date

    /// Date checked off
    var checkedAt: Date?

    /// Reference to the shopping list
    var shoppingList: ShoppingList?

    /// Reference to the original ingredient (if from recipe)
    var ingredient: Ingredient?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        category: FoodCategory = .other,
        isChecked: Bool = false,
        estimatedCost: Int? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.estimatedCost = estimatedCost
        self.addedAt = addedAt
    }

    /// Display string for the item
    var displayString: String {
        let quantityString = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity)
            : String(format: "%.2f", quantity)

        return "\(quantityString) \(unit) \(name)"
    }

    /// Toggle checked status
    func toggle() {
        isChecked.toggle()
        if isChecked {
            checkedAt = Date()
        } else {
            checkedAt = nil
        }
    }
}

/// Extension for aggregating ingredients into shopping list
extension ShoppingList {
    /// Create shopping list from meal session recipes
    static func createFrom(mealSession: MealSession, context: ModelContext) -> ShoppingList {
        let list = ShoppingList(
            name: "Shopping for \(mealSession.name)",
            store: nil
        )
        list.mealSession = mealSession
        list.familyGroup = mealSession.familyGroup

        // Aggregate ingredients from all scheduled meals
        guard let scheduledMeals = mealSession.scheduledMeals else {
            return list
        }

        // Dictionary to aggregate quantities: [ingredientName: (quantity, unit, category, ingredients)]
        var aggregatedIngredients: [String: (quantity: Double, unit: String, category: FoodCategory, cost: Int?, ingredients: [Ingredient])] = [:]

        for scheduledMeal in scheduledMeals {
            guard let recipe = scheduledMeal.recipe,
                  let ingredients = recipe.ingredients else { continue }

            for ingredient in ingredients where !ingredient.isPantryStaple {
                let key = ingredient.name.lowercased()

                if var existing = aggregatedIngredients[key] {
                    // Aggregate quantity if same unit
                    if existing.unit.lowercased() == ingredient.unit.lowercased() {
                        existing.quantity += ingredient.quantity
                        existing.ingredients.append(ingredient)
                        if let cost = ingredient.estimatedCost {
                            existing.cost = (existing.cost ?? 0) + cost
                        }
                        aggregatedIngredients[key] = existing
                    } else {
                        // Different unit, create separate item
                        let item = ShoppingListItem(
                            name: ingredient.name,
                            quantity: ingredient.quantity,
                            unit: ingredient.unit,
                            category: ingredient.category,
                            estimatedCost: ingredient.estimatedCost
                        )
                        item.ingredient = ingredient
                        item.shoppingList = list
                        context.insert(item)
                    }
                } else {
                    // First occurrence of this ingredient
                    aggregatedIngredients[key] = (
                        quantity: ingredient.quantity,
                        unit: ingredient.unit,
                        category: ingredient.category,
                        cost: ingredient.estimatedCost,
                        ingredients: [ingredient]
                    )
                }
            }
        }

        // Create shopping list items from aggregated ingredients
        for (name, data) in aggregatedIngredients {
            let item = ShoppingListItem(
                name: data.ingredients.first?.name ?? name,
                quantity: data.quantity,
                unit: data.unit,
                category: data.category,
                estimatedCost: data.cost
            )
            item.ingredient = data.ingredients.first
            item.shoppingList = list
            context.insert(item)
        }

        list.estimatedTotal = list.calculateEstimatedTotal()

        return list
    }
}
