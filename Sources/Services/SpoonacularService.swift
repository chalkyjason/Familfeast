import Foundation

/// Service for Spoonacular API integration
/// Provides recipe data, ingredient information, and price estimates
actor SpoonacularService {

    // MARK: - Configuration

    private let apiKey: String
    private let baseURL = "https://api.spoonacular.com"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Recipe Search

    /// Search for recipes by ingredients
    func searchRecipesByIngredients(
        ingredients: [String],
        number: Int = 10,
        ranking: Int = 1 // 1 = maximize used ingredients, 2 = minimize missing ingredients
    ) async throws -> [SpoonacularRecipe] {

        let ingredientsParam = ingredients.joined(separator: ",")
        let urlString = "\(baseURL)/recipes/findByIngredients?ingredients=\(ingredientsParam)&number=\(number)&ranking=\(ranking)&apiKey=\(apiKey)"

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            throw SpoonacularError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode([SpoonacularRecipe].self, from: data)
    }

    /// Get detailed recipe information
    func getRecipeInformation(id: Int) async throws -> RecipeDetail {

        let urlString = "\(baseURL)/recipes/\(id)/information?includeNutrition=true&apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw SpoonacularError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(RecipeDetail.self, from: data)
    }

    /// Search recipes with complex query
    func searchRecipes(
        query: String,
        cuisine: String? = nil,
        diet: String? = nil,
        maxReadyTime: Int? = nil,
        number: Int = 10
    ) async throws -> SearchRecipesResponse {

        var components = URLComponents(string: "\(baseURL)/recipes/complexSearch")!

        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "number", value: "\(number)"),
            URLQueryItem(name: "addRecipeInformation", value: "true"),
            URLQueryItem(name: "fillIngredients", value: "true"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]

        if let cuisine = cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        if let diet = diet {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }
        if let maxTime = maxReadyTime {
            queryItems.append(URLQueryItem(name: "maxReadyTime", value: "\(maxTime)"))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw SpoonacularError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(SearchRecipesResponse.self, from: data)
    }

    // MARK: - Ingredient Analysis

    /// Parse ingredient text into structured data
    func parseIngredients(_ ingredientTexts: [String], servings: Int = 1) async throws -> [ParsedSpoonacularIngredient] {

        let urlString = "\(baseURL)/recipes/parseIngredients?apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw SpoonacularError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Build form data
        var formData = "servings=\(servings)"
        for (index, ingredient) in ingredientTexts.enumerated() {
            formData += "&ingredientList=\(ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        request.httpBody = formData.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode([ParsedSpoonacularIngredient].self, from: data)
    }

    /// Get ingredient substitutes
    func getIngredientSubstitutes(ingredientName: String) async throws -> SubstituteResponse {

        let urlString = "\(baseURL)/food/ingredients/substitutes?ingredientName=\(ingredientName)&apiKey=\(apiKey)"

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            throw SpoonacularError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(SubstituteResponse.self, from: data)
    }

    // MARK: - Price Estimation

    /// Get price breakdown for a recipe
    func getRecipePriceBreakdown(id: Int) async throws -> PriceBreakdown {

        let urlString = "\(baseURL)/recipes/\(id)/priceBreakdownWidget.json?apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw SpoonacularError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(PriceBreakdown.self, from: data)
    }

    /// Estimate ingredient cost (approximate when Spoonacular data unavailable)
    func estimateIngredientCost(name: String, quantity: Double, unit: String) -> Int {
        // Simple estimation based on common ingredient costs
        // In production, this would use a more sophisticated pricing database

        let costPer100g: [String: Double] = [
            "chicken": 0.50,
            "beef": 0.80,
            "pork": 0.60,
            "fish": 0.90,
            "rice": 0.10,
            "pasta": 0.15,
            "potato": 0.08,
            "onion": 0.12,
            "tomato": 0.20,
            "cheese": 0.60,
            "milk": 0.05,
            "egg": 0.15,
            "flour": 0.08,
            "sugar": 0.10,
            "salt": 0.02,
            "oil": 0.30
        ]

        // Find matching ingredient
        let lowercased = name.lowercased()
        var baseCost = 0.25 // Default cost per 100g

        for (key, cost) in costPer100g {
            if lowercased.contains(key) {
                baseCost = cost
                break
            }
        }

        // Rough conversion to grams based on unit
        var grams = quantity
        switch unit.lowercased() {
        case "kg", "kilogram", "kilograms":
            grams = quantity * 1000
        case "lb", "pound", "pounds":
            grams = quantity * 453.592
        case "oz", "ounce", "ounces":
            grams = quantity * 28.3495
        case "cup", "cups":
            grams = quantity * 200 // Approximate
        case "tablespoon", "tablespoons", "tbsp":
            grams = quantity * 15
        case "teaspoon", "teaspoons", "tsp":
            grams = quantity * 5
        default:
            grams = quantity * 100 // Assume 100g per unit
        }

        let estimatedCost = (grams / 100.0) * baseCost
        return Int(estimatedCost * 100) // Convert to cents
    }

    // MARK: - Meal Planning

    /// Generate meal plan for a week
    func generateMealPlan(
        timeFrame: String = "week",
        targetCalories: Int? = nil,
        diet: String? = nil
    ) async throws -> MealPlan {

        var urlString = "\(baseURL)/mealplanner/generate?timeFrame=\(timeFrame)&apiKey=\(apiKey)"

        if let calories = targetCalories {
            urlString += "&targetCalories=\(calories)"
        }
        if let diet = diet {
            urlString += "&diet=\(diet)"
        }

        guard let url = URL(string: urlString) else {
            throw SpoonacularError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(MealPlan.self, from: data)
    }
}

// MARK: - Response Models

struct SpoonacularRecipe: Codable {
    let id: Int
    let title: String
    let image: String?
    let imageType: String?
    let usedIngredientCount: Int?
    let missedIngredientCount: Int?
}

struct RecipeDetail: Codable {
    let id: Int
    let title: String
    let image: String?
    let servings: Int
    let readyInMinutes: Int
    let preparationMinutes: Int?
    let cookingMinutes: Int?
    let pricePerServing: Double?
    let sourceName: String?
    let sourceUrl: String?
    let spoonacularSourceUrl: String?
    let instructions: String?
    let extendedIngredients: [ExtendedIngredient]?
    let cuisines: [String]?
    let dishTypes: [String]?
    let diets: [String]?
    let summary: String?
    let nutrition: Nutrition?
}

struct ExtendedIngredient: Codable {
    let id: Int
    let name: String
    let amount: Double
    let unit: String
    let original: String
    let aisle: String?
}

struct Nutrition: Codable {
    let nutrients: [Nutrient]
}

struct Nutrient: Codable {
    let name: String
    let amount: Double
    let unit: String
}

struct SearchRecipesResponse: Codable {
    let results: [RecipeDetail]
    let offset: Int
    let number: Int
    let totalResults: Int
}

struct ParsedSpoonacularIngredient: Codable {
    let id: Int
    let original: String
    let name: String
    let amount: Double
    let unit: String
    let aisle: String?
    let nutrition: Nutrition?
}

struct SubstituteResponse: Codable {
    let ingredient: String
    let substitutes: [String]
    let message: String
}

struct PriceBreakdown: Codable {
    let ingredients: [IngredientPrice]
    let totalCost: Double
    let totalCostPerServing: Double
}

struct IngredientPrice: Codable {
    let name: String
    let amount: Amount
    let price: Double
}

struct Amount: Codable {
    let metric: Measurement
    let us: Measurement
}

struct Measurement: Codable {
    let value: Double
    let unit: String
}

struct MealPlan: Codable {
    let meals: [PlannedMeal]
    let nutrients: Nutrients
}

struct PlannedMeal: Codable {
    let id: Int
    let title: String
    let readyInMinutes: Int
    let servings: Int
    let sourceUrl: String?
}

struct Nutrients: Codable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbohydrates: Double
}

enum SpoonacularError: Error, LocalizedError {
    case invalidURL
    case networkError
    case invalidResponse
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error occurred"
        case .invalidResponse:
            return "Invalid response from Spoonacular API"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
