import SwiftUI
import SwiftData

struct RecipeListView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let familyGroup: FamilyGroup?

    // MARK: - Queries

    @Query(sort: \Recipe.title) private var recipes: [Recipe]

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedFilter: RecipeFilter = .all
    @State private var showingAddRecipe = false
    @State private var showingURLImport = false
    @State private var showingAISuggestions = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Filters
                filterScrollView

                // Recipe list
                if filteredRecipes.isEmpty {
                    emptyStateView
                } else {
                    recipeList
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddRecipe = true }) {
                            Label("Manual Entry", systemImage: "plus.circle")
                        }
                        Button(action: { showingURLImport = true }) {
                            Label("Import from URL", systemImage: "link")
                        }
                        Button(action: { showingAISuggestions = true }) {
                            Label("AI Suggestion", systemImage: "sparkles")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView(familyGroup: familyGroup)
            }
            .sheet(isPresented: $showingURLImport) {
                RecipeURLImportView(familyGroup: familyGroup)
            }
            .sheet(isPresented: $showingAISuggestions) {
                AISuggestionsView(familyGroup: familyGroup)
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search recipes...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RecipeFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var recipeList: some View {
        List {
            ForEach(filteredRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeRow(recipe: recipe)
                }
            }
            .onDelete(perform: deleteRecipes)
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Recipes Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first recipe to get started!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingAddRecipe = true }) {
                Text("Add Recipe")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue.gradient)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var filteredRecipes: [Recipe] {
        var result = recipes

        // Filter by family group
        if let group = familyGroup {
            result = result.filter { $0.familyGroup?.id == group.id }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { recipe in
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                recipe.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                (recipe.cuisine?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .quick:
            result = result.filter { $0.totalTime <= 30 }
        case .easy:
            result = result.filter { $0.difficulty == .easy }
        case .breakfast:
            result = result.filter { $0.mealType == .breakfast }
        case .lunch:
            result = result.filter { $0.mealType == .lunch }
        case .dinner:
            result = result.filter { $0.mealType == .dinner }
        }

        return result
    }

    // MARK: - Methods

    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            let recipe = filteredRecipes[index]
            modelContext.delete(recipe)
        }
    }
}

// MARK: - Supporting Views

struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.gray.opacity(0.5))
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("\(recipe.totalTime)m", systemImage: "clock")
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                    if recipe.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if !recipe.tags.isEmpty {
                    Text(recipe.tags.prefix(3).joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Supporting Types

enum RecipeFilter: CaseIterable {
    case all, favorites, quick, easy, breakfast, lunch, dinner

    var title: String {
        switch self {
        case .all: return "All"
        case .favorites: return "Favorites"
        case .quick: return "Quick"
        case .easy: return "Easy"
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        }
    }
}

// MARK: - Recipe Detail View

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

                // Nutrition info (Phase 3)
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

    // MARK: - Nutrition (Phase 3)

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

// MARK: - Add Recipe View

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

// MARK: - Preview

#Preview {
    RecipeListView(familyGroup: nil)
        .modelContainer(for: Recipe.self, inMemory: true)
}
