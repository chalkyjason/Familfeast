import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.modelContext) private var modelContext

    // Phase 2: Recipe scaling
    @State private var scaledServings: Int = 0

    // Phase 4: Cooking mode
    @State private var showingCookingMode = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack(spacing: 12) {
                        if let cuisine = recipe.cuisine, !cuisine.isEmpty {
                            Text(cuisine)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }

                        Text(recipe.mealType.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(8)

                        Text(recipe.difficulty.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                }

                // Stats row with scaling stepper
                HStack(spacing: 0) {
                    statItem(icon: "clock", label: "Prep", value: "\(recipe.prepTime)m")
                    Spacer()
                    statItem(icon: "flame", label: "Cook", value: "\(recipe.cookTime)m")
                    Spacer()
                    statItem(icon: "timer", label: "Total", value: "\(recipe.totalTime)m")
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Stepper("\(scaledServings)", value: $scaledServings, in: 1...50)
                            .labelsHidden()
                            .fixedSize()
                        Text("\(scaledServings) servings")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.gray.opacity(0.05))
                .cornerRadius(12)

                // Description
                if let desc = recipe.recipeDescription, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                // Ingredients (scaled)
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.headline)

                        ForEach(ingredients) { ingredient in
                            HStack(spacing: 10) {
                                Image(systemName: ingredient.category.icon)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text(scaledDisplayString(for: ingredient))
                                    .font(.body)
                                Spacer()
                            }
                        }
                    }
                }

                // Instructions
                if !recipe.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.headline)
                        Text(recipe.instructions)
                            .font(.body)
                    }
                }

                // Nutrition info
                if let info = nutritionInfo {
                    nutritionSection(info)
                }

                // Tags
                if !recipe.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }

                // Metadata footer
                HStack {
                    Text("Added \(recipe.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    Text("\u{2022}")
                    Text("Cooked \(recipe.timesCooked) times")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { showingCookingMode = true }) {
                        Image(systemName: "play.circle")
                    }
                    Button(action: toggleFavorite) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(recipe.isFavorite ? .red : .secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCookingMode) {
            NavigationStack {
                CookingModeView(recipe: recipe)
            }
        }
        .onAppear {
            scaledServings = recipe.servings
        }
    }

    // MARK: - Scaling Helper

    private func scaledDisplayString(for ingredient: Ingredient) -> String {
        guard recipe.servings > 0 else { return ingredient.displayString }
        let scale = Double(scaledServings) / Double(recipe.servings)
        let scaledQuantity = ingredient.quantity * scale

        let quantityString = scaledQuantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", scaledQuantity)
            : String(format: "%.2f", scaledQuantity)

        var result = "\(quantityString) \(ingredient.unit) \(ingredient.name)"
        if let prep = ingredient.preparation, !prep.isEmpty {
            result += ", \(prep)"
        }
        return result
    }

    // MARK: - Nutrition

    private var nutritionInfo: NutritionInfo? {
        guard let json = recipe.nutritionJSON,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(NutritionInfo.self, from: data)
    }

    private func nutritionSection(_ info: NutritionInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition (per serving)")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let cal = info.calories {
                    nutritionItem(label: "Calories", value: "\(cal)", unit: "kcal")
                }
                if let protein = info.protein {
                    nutritionItem(label: "Protein", value: String(format: "%.1f", protein), unit: "g")
                }
                if let carbs = info.carbohydrates {
                    nutritionItem(label: "Carbs", value: String(format: "%.1f", carbs), unit: "g")
                }
                if let fat = info.fat {
                    nutritionItem(label: "Fat", value: String(format: "%.1f", fat), unit: "g")
                }
                if let fiber = info.fiber {
                    nutritionItem(label: "Fiber", value: String(format: "%.1f", fiber), unit: "g")
                }
                if let sodium = info.sodium {
                    nutritionItem(label: "Sodium", value: String(format: "%.0f", sodium), unit: "mg")
                }
            }
        }
    }

    private func nutritionItem(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text("\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func toggleFavorite() {
        recipe.isFavorite.toggle()
        try? modelContext.save()
    }
}
