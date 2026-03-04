import SwiftUI
import SwiftData

struct AISuggestionsView: View {

    // MARK: - Environment

    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let familyGroup: FamilyGroup?

    // MARK: - State

    @State private var promptText = ""
    @State private var ingredientsText = ""
    @State private var suggestions: [RecipeSuggestion] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var savedTitles: Set<String> = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Input section
                    inputSection

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Results
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Getting AI suggestions...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else if !suggestions.isEmpty {
                        suggestionsSection
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("AI Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What are you in the mood for?")
                    .font(.headline)

                TextField("e.g. a quick weeknight pasta dish", text: $promptText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Ingredients on hand (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("e.g. chicken, rice, broccoli", text: $ingredientsText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(10)
            }

            Button(action: getSuggestions) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Generating...")
                    }
                } else {
                    Label("Get AI Suggestions", systemImage: "sparkles")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSubmit ? Color.purple.gradient : Color.gray.gradient)
            .cornerRadius(12)
            .disabled(!canSubmit)

            if aiService == nil {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("AI service not configured. Set OPENAI_API_KEY to enable suggestions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestions")
                .font(.headline)

            ForEach(suggestions.indices, id: \.self) { index in
                suggestionCard(suggestions[index])
            }
        }
    }

    private func suggestionCard(_ suggestion: RecipeSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row
            HStack {
                Text(suggestion.title)
                    .font(.headline)
                Spacer()
                if savedTitles.contains(suggestion.title) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Description
            Text(suggestion.description)
                .font(.body)
                .foregroundColor(.secondary)

            // Meta info
            HStack(spacing: 16) {
                Label("\(suggestion.prepTime + suggestion.cookTime)m", systemImage: "clock")
                Label(suggestion.difficulty.capitalized, systemImage: "chart.bar")
                Label("$\(String(format: "%.2f", suggestion.estimatedCostPerServing))/serving", systemImage: "dollarsign.circle")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Cuisine + servings
            HStack(spacing: 12) {
                Text(suggestion.cuisine)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)

                Text("\(suggestion.servings) servings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Save button
            if !savedTitles.contains(suggestion.title) {
                Button(action: { saveRecipe(suggestion) }) {
                    Label("Save Recipe", systemImage: "square.and.arrow.down")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.purple.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.purple.opacity(0.5))

            Text("Describe what you'd like to eat")
                .font(.title3)
                .fontWeight(.medium)

            Text("Our AI will suggest personalized recipes based on your preferences")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    // MARK: - Computed Properties

    private var canSubmit: Bool {
        !promptText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading && aiService != nil
    }

    // MARK: - Methods

    private func getSuggestions() {
        guard let aiService = aiService else {
            errorMessage = "AI service is not configured"
            return
        }

        isLoading = true
        errorMessage = nil

        let prompt = promptText.trimmingCharacters(in: .whitespaces)
        let ingredients = ingredientsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        Task {
            do {
                let results: [RecipeSuggestion]
                if ingredients.isEmpty {
                    // Use description-based generation
                    let single = try await aiService.generateRecipeFromDescription(prompt)
                    results = [single]
                } else {
                    results = try await aiService.suggestRecipes(
                        availableIngredients: ingredients,
                        numberOfRecipes: 5
                    )
                }

                await MainActor.run {
                    isLoading = false
                    suggestions = results
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to get suggestions: \(error.localizedDescription)"
                }
            }
        }
    }

    private func saveRecipe(_ suggestion: RecipeSuggestion) {
        let difficultyLevel: DifficultyLevel = switch suggestion.difficulty.lowercased() {
        case "easy": .easy
        case "hard": .hard
        default: .medium
        }

        let recipe = Recipe(
            title: suggestion.title,
            instructions: suggestion.instructions,
            recipeDescription: suggestion.description,
            prepTime: suggestion.prepTime,
            cookTime: suggestion.cookTime,
            servings: suggestion.servings,
            difficulty: difficultyLevel,
            cuisine: suggestion.cuisine,
            estimatedCostPerServing: Int(suggestion.estimatedCostPerServing * 100)
        )
        recipe.familyGroup = familyGroup

        modelContext.insert(recipe)

        // Create Ingredient objects
        for parsed in suggestion.ingredients {
            let category = FoodCategory(rawValue: parsed.category) ?? .other
            let ingredient = Ingredient(
                name: parsed.name,
                quantity: parsed.quantity,
                unit: parsed.unit,
                category: category,
                preparation: parsed.preparation
            )
            ingredient.recipe = recipe
            modelContext.insert(ingredient)
        }

        try? modelContext.save()
        savedTitles.insert(suggestion.title)
    }
}
