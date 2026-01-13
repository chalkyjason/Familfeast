import Foundation

/// Service for AI-powered features using OpenAI API
/// Handles recipe suggestions, ingredient parsing, and meal planning assistance
actor AIService {

    // MARK: - Configuration

    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4o-mini" // Cost-effective model for most tasks

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Recipe Suggestions

    /// Generate recipe suggestions based on available ingredients and constraints
    func suggestRecipes(
        availableIngredients: [String],
        dietaryRestrictions: [String] = [],
        cuisinePreferences: [String] = [],
        budget: Int? = nil,
        numberOfRecipes: Int = 5
    ) async throws -> [RecipeSuggestion] {

        let budgetText = budget.map { "Budget: $\(Double($0) / 100.0) total" } ?? "No specific budget"

        let prompt = """
        You are an expert meal planner. Generate \(numberOfRecipes) distinct dinner recipes based on the following:

        Available ingredients: \(availableIngredients.joined(separator: ", "))
        Dietary restrictions: \(dietaryRestrictions.isEmpty ? "None" : dietaryRestrictions.joined(separator: ", "))
        Cuisine preferences: \(cuisinePreferences.isEmpty ? "Any" : cuisinePreferences.joined(separator: ", "))
        \(budgetText)

        For each recipe, provide:
        1. A creative title
        2. Brief description (2-3 sentences)
        3. Estimated preparation time (minutes)
        4. Estimated cooking time (minutes)
        5. Difficulty level (easy/medium/hard)
        6. Estimated cost per serving (USD)
        7. List of ingredients with quantities
        8. Step-by-step instructions
        9. Cuisine type
        10. Number of servings

        Return ONLY valid JSON array with this structure:
        [
          {
            "title": "Recipe Name",
            "description": "Brief description",
            "prepTime": 15,
            "cookTime": 30,
            "difficulty": "medium",
            "estimatedCostPerServing": 3.50,
            "servings": 4,
            "cuisine": "Italian",
            "ingredients": [
              {
                "name": "chicken breast",
                "quantity": 2,
                "unit": "pounds",
                "category": "meat"
              }
            ],
            "instructions": "Step 1: ... Step 2: ..."
          }
        ]
        """

        let response = try await sendChatCompletion(prompt: prompt)

        // Parse JSON response
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode([RecipeSuggestion].self, from: data)
    }

    /// Generate a single recipe from a description
    func generateRecipeFromDescription(_ description: String) async throws -> RecipeSuggestion {

        let prompt = """
        Generate a complete recipe based on this description: "\(description)"

        Return ONLY valid JSON with this structure:
        {
          "title": "Recipe Name",
          "description": "Brief description",
          "prepTime": 15,
          "cookTime": 30,
          "difficulty": "medium",
          "estimatedCostPerServing": 3.50,
          "servings": 4,
          "cuisine": "Italian",
          "ingredients": [
            {
              "name": "ingredient name",
              "quantity": 2,
              "unit": "cups",
              "category": "produce"
            }
          ],
          "instructions": "Step 1: ... Step 2: ..."
        }
        """

        let response = try await sendChatCompletion(prompt: prompt)

        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(RecipeSuggestion.self, from: data)
    }

    // MARK: - Ingredient Parsing

    /// Parse ingredient text into structured format
    /// Handles natural language like "2 large onions, diced" or "1 cup of flour"
    func parseIngredients(_ ingredientTexts: [String]) async throws -> [ParsedIngredient] {

        let prompt = """
        Parse these ingredient strings into structured data:

        \(ingredientTexts.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))

        Return ONLY valid JSON array:
        [
          {
            "name": "onion",
            "quantity": 2,
            "unit": "count",
            "category": "produce",
            "preparation": "diced",
            "originalText": "2 large onions, diced"
          }
        ]

        Categories: produce, meat, seafood, dairy, bakery, frozen, canned, grains, spices, condiments, snacks, beverages, other
        """

        let response = try await sendChatCompletion(prompt: prompt)

        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode([ParsedIngredient].self, from: data)
    }

    /// Parse a recipe from URL or text
    func parseRecipeFromText(_ text: String) async throws -> RecipeSuggestion {

        let prompt = """
        Extract recipe information from this text:

        \(text)

        Return ONLY valid JSON:
        {
          "title": "Recipe Name",
          "description": "Brief description",
          "prepTime": 15,
          "cookTime": 30,
          "difficulty": "medium",
          "estimatedCostPerServing": 3.50,
          "servings": 4,
          "cuisine": "Italian",
          "ingredients": [
            {
              "name": "ingredient",
              "quantity": 2,
              "unit": "cups",
              "category": "produce"
            }
          ],
          "instructions": "Step 1: ... Step 2: ..."
        }
        """

        let response = try await sendChatCompletion(prompt: prompt)

        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(RecipeSuggestion.self, from: data)
    }

    // MARK: - Meal Planning

    /// Suggest a weekly meal plan
    func suggestWeeklyMealPlan(
        numberOfDays: Int = 7,
        preferences: MealPlanPreferences
    ) async throws -> [RecipeSuggestion] {

        let prompt = """
        Create a \(numberOfDays)-day meal plan with the following preferences:

        Budget: $\(Double(preferences.budgetCents) / 100.0)
        Dietary restrictions: \(preferences.dietaryRestrictions.joined(separator: ", "))
        Cuisines: \(preferences.cuisinePreferences.joined(separator: ", "))
        Difficulty levels: \(preferences.difficultyLevels.joined(separator: ", "))
        Serving size: \(preferences.servings) people

        Ensure variety in cuisines and ingredients. Balance easy and complex meals throughout the week.

        Return ONLY valid JSON array of \(numberOfDays) recipes with the same structure as before.
        """

        let response = try await sendChatCompletion(prompt: prompt)

        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode([RecipeSuggestion].self, from: data)
    }

    // MARK: - Private Methods

    private func sendChatCompletion(prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse OpenAI response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }

        // Clean up response (remove markdown code blocks if present)
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }
}

// MARK: - Supporting Types

struct RecipeSuggestion: Codable {
    let title: String
    let description: String
    let prepTime: Int
    let cookTime: Int
    let difficulty: String
    let estimatedCostPerServing: Double
    let servings: Int
    let cuisine: String
    let ingredients: [ParsedIngredient]
    let instructions: String
}

struct ParsedIngredient: Codable {
    let name: String
    let quantity: Double
    let unit: String
    let category: String
    let preparation: String?
    let originalText: String?
}

struct MealPlanPreferences {
    let budgetCents: Int
    let dietaryRestrictions: [String]
    let cuisinePreferences: [String]
    let difficultyLevels: [String]
    let servings: Int
}

enum AIServiceError: Error, LocalizedError {
    case invalidResponse
    case networkError
    case apiError(statusCode: Int)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkError:
            return "Network error occurred"
        case .apiError(let code):
            return "API error with status code: \(code)"
        case .parsingError:
            return "Failed to parse AI response"
        }
    }
}
