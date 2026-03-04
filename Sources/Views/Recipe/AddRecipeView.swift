import SwiftUI
import SwiftData

struct AddRecipeView: View {
    let familyGroup: FamilyGroup?
    var suggestion: RecipeSuggestion? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Basic Info
    @State private var title = ""
    @State private var recipeDescription = ""
    @State private var mealType: MealType = .dinner
    @State private var difficulty: DifficultyLevel = .medium
    @State private var cuisine = ""

    // Timing & Servings
    @State private var prepTime = 15
    @State private var cookTime = 30
    @State private var servings = 4

    // Ingredients
    @State private var ingredientLines: [String] = [""]

    // Instructions
    @State private var instructions = ""

    // Tags
    @State private var tagsText = ""

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Basic Info") {
                    TextField("Title", text: $title)
                    TextEditor(text: $recipeDescription)
                        .frame(minHeight: 60)
                        .overlay(alignment: .topLeading) {
                            if recipeDescription.isEmpty {
                                Text("Description (optional)")
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                    Picker("Meal Type", selection: $mealType) {
                        Text("Breakfast").tag(MealType.breakfast)
                        Text("Lunch").tag(MealType.lunch)
                        Text("Dinner").tag(MealType.dinner)
                        Text("Snack").tag(MealType.snack)
                        Text("Dessert").tag(MealType.dessert)
                    }
                    Picker("Difficulty", selection: $difficulty) {
                        Text("Easy").tag(DifficultyLevel.easy)
                        Text("Medium").tag(DifficultyLevel.medium)
                        Text("Hard").tag(DifficultyLevel.hard)
                    }
                    TextField("Cuisine (e.g. Italian)", text: $cuisine)
                }

                // Timing & Servings
                Section("Timing & Servings") {
                    Stepper("Prep: \(prepTime) min", value: $prepTime, in: 0...300, step: 5)
                    Stepper("Cook: \(cookTime) min", value: $cookTime, in: 0...300, step: 5)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                }

                // Ingredients
                Section("Ingredients") {
                    ForEach(ingredientLines.indices, id: \.self) { index in
                        TextField("e.g. 2 cups flour", text: $ingredientLines[index])
                    }
                    .onDelete { offsets in
                        ingredientLines.remove(atOffsets: offsets)
                        if ingredientLines.isEmpty {
                            ingredientLines = [""]
                        }
                    }

                    Button(action: { ingredientLines.append("") }) {
                        Label("Add Ingredient", systemImage: "plus.circle")
                    }
                }

                // Instructions
                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if instructions.isEmpty {
                                Text("Step-by-step instructions...")
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                // Tags
                Section("Tags") {
                    TextField("e.g. quick, vegetarian, kid-friendly", text: $tagsText)
                }
            }
            .navigationTitle("New Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRecipe() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let s = suggestion {
                    title = s.title
                    recipeDescription = s.description
                    cuisine = s.cuisine
                    prepTime = s.prepTime
                    cookTime = s.cookTime
                    servings = s.servings
                    instructions = s.instructions
                    ingredientLines = s.ingredients.map { ing in
                        let qty = ing.quantity.truncatingRemainder(dividingBy: 1) == 0
                            ? String(format: "%.0f", ing.quantity)
                            : String(format: "%.2f", ing.quantity)
                        return "\(qty) \(ing.unit) \(ing.name)"
                    }
                    if ingredientLines.isEmpty { ingredientLines = [""] }
                    switch s.difficulty.lowercased() {
                    case "easy": difficulty = .easy
                    case "hard": difficulty = .hard
                    default: difficulty = .medium
                    }
                }
            }
        }
    }

    private func saveRecipe() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let recipe = Recipe(
            title: trimmedTitle,
            instructions: instructions,
            recipeDescription: recipeDescription.isEmpty ? nil : recipeDescription,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            difficulty: difficulty,
            cuisine: cuisine.isEmpty ? nil : cuisine,
            mealType: mealType,
            tags: tags
        )
        recipe.familyGroup = familyGroup

        modelContext.insert(recipe)

        // Parse and attach ingredients
        for line in ingredientLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if let ingredient = Ingredient.parse(from: trimmed) {
                ingredient.recipe = recipe
                modelContext.insert(ingredient)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}
