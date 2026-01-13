import SwiftUI
import SwiftData
import PhotosUI

struct AddRecipeView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let familyGroup: FamilyGroup?

    // MARK: - State

    @State private var recipe = RecipeFormData()
    @State private var selectedTab = 0
    @State private var showingAISuggestion = false
    @State private var showingURLImport = false
    @State private var isGenerating = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                basicInfoTab
                    .tag(0)

                ingredientsTab
                    .tag(1)

                instructionsTab
                    .tag(2)

                detailsTab
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .navigationTitle("New Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(!recipe.isValid)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAISuggestion = true }) {
                            Label("AI Suggestion", systemImage: "sparkles")
                        }
                        Button(action: { showingURLImport = true }) {
                            Label("Import from URL", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAISuggestion) {
                AISuggestionView(onRecipeGenerated: { suggestion in
                    applyAISuggestion(suggestion)
                })
            }
            .sheet(isPresented: $showingURLImport) {
                URLImportView(onRecipeImported: { suggestion in
                    applyAISuggestion(suggestion)
                })
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Tabs

    private var basicInfoTab: some View {
        Form {
            Section("Basic Information") {
                TextField("Recipe Title", text: $recipe.title)
                    .font(.headline)

                TextField("Description (Optional)", text: $recipe.description, axis: .vertical)
                    .lineLimit(3...6)

                Picker("Meal Type", selection: $recipe.mealType) {
                    ForEach([MealType.breakfast, .lunch, .dinner, .snack, .dessert], id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }

                Picker("Difficulty", selection: $recipe.difficulty) {
                    ForEach([DifficultyLevel.easy, .medium, .hard], id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }
            }

            Section("Image") {
                ImagePickerSection(
                    imageData: $recipe.imageData,
                    imageURL: $recipe.imageURL
                )
            }

            Section("Timing") {
                HStack {
                    Text("Prep Time")
                    Spacer()
                    TextField("Minutes", value: $recipe.prepTime, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("min")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Cook Time")
                    Spacer()
                    TextField("Minutes", value: $recipe.cookTime, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("min")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Total Time")
                    Spacer()
                    Text("\(recipe.prepTime + recipe.cookTime) min")
                        .foregroundColor(.secondary)
                }
            }

            Section("Servings") {
                Stepper(value: $recipe.servings, in: 1...20) {
                    Text("\(recipe.servings) servings")
                }
            }

            Section("Categories") {
                TextField("Cuisine (e.g., Italian, Mexican)", text: $recipe.cuisine)

                TagInputView(tags: $recipe.tags)
            }
        }
    }

    private var ingredientsTab: some View {
        Form {
            Section {
                Button(action: addIngredient) {
                    Label("Add Ingredient", systemImage: "plus.circle.fill")
                }

                Button(action: { showingAISuggestion = true }) {
                    Label("AI Parse Ingredients", systemImage: "sparkles")
                }
            }

            Section("Ingredients") {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    IngredientRowEditor(
                        ingredient: binding(for: index),
                        onDelete: { deleteIngredient(at: index) }
                    )
                }
                .onMove(perform: moveIngredients)
            }
        }
    }

    private var instructionsTab: some View {
        Form {
            Section("Instructions") {
                TextEditor(text: $recipe.instructions)
                    .frame(minHeight: 200)
                    .font(.body)
            }

            Section {
                Toggle("Add to Favorites", isOn: $recipe.isFavorite)
            }
        }
    }

    private var detailsTab: some View {
        Form {
            Section("Source") {
                TextField("Source URL (Optional)", text: $recipe.sourceURL)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocapitalization(.none)
            }

            Section("Budget") {
                HStack {
                    Text("Estimated Cost per Serving")
                    Spacer()
                    TextField("$", value: $recipe.costPerServing, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                if recipe.costPerServing > 0 {
                    HStack {
                        Text("Total Cost")
                        Spacer()
                        Text("$\(String(format: "%.2f", recipe.costPerServing * Double(recipe.servings)))")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $recipe.notes)
                    .frame(minHeight: 100)
            }
        }
    }

    // MARK: - Methods

    private func binding(for index: Int) -> Binding<IngredientFormData> {
        Binding(
            get: { recipe.ingredients[index] },
            set: { recipe.ingredients[index] = $0 }
        )
    }

    private func addIngredient() {
        recipe.ingredients.append(IngredientFormData())
    }

    private func deleteIngredient(at index: Int) {
        recipe.ingredients.remove(at: index)
    }

    private func moveIngredients(from source: IndexSet, to destination: Int) {
        recipe.ingredients.move(fromOffsets: source, toOffset: destination)
    }

    private func applyAISuggestion(_ suggestion: RecipeSuggestion) {
        recipe.title = suggestion.title
        recipe.description = suggestion.description
        recipe.prepTime = suggestion.prepTime
        recipe.cookTime = suggestion.cookTime
        recipe.difficulty = DifficultyLevel(rawValue: suggestion.difficulty) ?? .medium
        recipe.servings = suggestion.servings
        recipe.cuisine = suggestion.cuisine
        recipe.instructions = suggestion.instructions

        recipe.ingredients = suggestion.ingredients.map { parsed in
            IngredientFormData(
                name: parsed.name,
                quantity: parsed.quantity,
                unit: parsed.unit,
                category: FoodCategory(rawValue: parsed.category) ?? .other,
                preparation: parsed.preparation
            )
        }

        if suggestion.estimatedCostPerServing > 0 {
            recipe.costPerServing = suggestion.estimatedCostPerServing
        }
    }

    private func saveRecipe() {
        let newRecipe = Recipe(
            title: recipe.title,
            instructions: recipe.instructions,
            recipeDescription: recipe.description.isEmpty ? nil : recipe.description,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            servings: recipe.servings,
            difficulty: recipe.difficulty,
            cuisine: recipe.cuisine.isEmpty ? nil : recipe.cuisine,
            mealType: recipe.mealType,
            sourceURL: recipe.sourceURL.isEmpty ? nil : recipe.sourceURL,
            imageData: recipe.imageData,
            estimatedCostPerServing: recipe.costPerServing > 0 ? Int(recipe.costPerServing * 100) : nil,
            isFavorite: recipe.isFavorite,
            tags: recipe.tags
        )

        newRecipe.familyGroup = familyGroup

        // Add ingredients
        for ingredientData in recipe.ingredients where !ingredientData.name.isEmpty {
            let ingredient = Ingredient(
                name: ingredientData.name,
                quantity: ingredientData.quantity,
                unit: ingredientData.unit,
                category: ingredientData.category,
                preparation: ingredientData.preparation.isEmpty ? nil : ingredientData.preparation,
                estimatedCost: ingredientData.estimatedCost > 0 ? Int(ingredientData.estimatedCost * 100) : nil
            )
            ingredient.recipe = newRecipe
            modelContext.insert(ingredient)
        }

        modelContext.insert(newRecipe)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save recipe: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views

struct ImagePickerSection: View {
    @Binding var imageData: Data?
    @Binding var imageURL: String

    @State private var selectedItem: PhotosPickerItem?
    @State private var showingURLEntry = false

    var body: some View {
        VStack(spacing: 12) {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Button("Change Photo", action: {})
                    Button("Remove", role: .destructive) {
                        imageData = nil
                    }
                }
                .buttonStyle(.bordered)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)

                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text("Choose Photo")
                                    .font(.headline)
                            }

                            Button("Enter URL") {
                                showingURLEntry = true
                            }
                        }
                    }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
        .alert("Image URL", isPresented: $showingURLEntry) {
            TextField("https://...", text: $imageURL)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                // Image will be loaded from URL when displaying
            }
        }
    }
}

struct TagInputView: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing tags
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                        TagChip(text: tag) {
                            tags.remove(at: index)
                        }
                    }
                }
            }

            // Add new tag
            HStack {
                TextField("Add tag (e.g., 'quick', 'vegetarian')", text: $newTag)
                    .textFieldStyle(.roundedBorder)

                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newTag.isEmpty)
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }

        tags.append(trimmed)
        newTag = ""
    }
}

struct TagChip: View {
    let text: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.bounds
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var bounds = CGSize.zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
                bounds.width = max(bounds.width, x - spacing)
                bounds.height = y + rowHeight
            }
        }
    }
}

struct IngredientRowEditor: View {
    @Binding var ingredient: IngredientFormData
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Name", text: $ingredient.name)
                    .font(.headline)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                TextField("Qty", value: $ingredient.quantity, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)

                TextField("Unit", text: $ingredient.unit)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)

                Picker("Category", selection: $ingredient.category) {
                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            TextField("Preparation (e.g., 'diced', 'minced')", text: $ingredient.preparation)
                .font(.caption)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Form Data Models

struct RecipeFormData {
    var title = ""
    var description = ""
    var prepTime = 0
    var cookTime = 0
    var servings = 4
    var difficulty: DifficultyLevel = .medium
    var cuisine = ""
    var mealType: MealType = .dinner
    var sourceURL = ""
    var imageURL = ""
    var imageData: Data?
    var instructions = ""
    var notes = ""
    var isFavorite = false
    var tags: [String] = []
    var ingredients: [IngredientFormData] = []
    var costPerServing: Double = 0.0

    var isValid: Bool {
        !title.isEmpty && !instructions.isEmpty
    }
}

struct IngredientFormData: Identifiable {
    let id = UUID()
    var name = ""
    var quantity: Double = 1.0
    var unit = "unit"
    var category: FoodCategory = .other
    var preparation = ""
    var estimatedCost: Double = 0.0
}

// MARK: - AI Views

struct AISuggestionView: View {
    let onRecipeGenerated: (RecipeSuggestion) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Describe Your Recipe") {
                    TextField("I want to make...", text: $prompt, axis: .vertical)
                        .lineLimit(3...10)
                }

                Section {
                    Button("Generate Recipe") {
                        generateRecipe()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(prompt.isEmpty || isGenerating)
                }

                if isGenerating {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Generating...")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("AI Recipe Generator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func generateRecipe() {
        isGenerating = true

        Task {
            // AI generation would happen here
            // For now, placeholder
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
                isGenerating = false
                // Mock recipe
                let suggestion = RecipeSuggestion(
                    title: "AI Generated Recipe",
                    description: "Generated from your prompt",
                    prepTime: 15,
                    cookTime: 30,
                    difficulty: "medium",
                    estimatedCostPerServing: 3.50,
                    servings: 4,
                    cuisine: "American",
                    ingredients: [],
                    instructions: "AI generated instructions..."
                )
                onRecipeGenerated(suggestion)
                dismiss()
            }
        }
    }
}

struct URLImportView: View {
    let onRecipeImported: (RecipeSuggestion) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var url = ""
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe URL") {
                    TextField("https://...", text: $url)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                }

                Section {
                    Button("Import Recipe") {
                        importRecipe()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(url.isEmpty || isImporting)
                }
            }
            .navigationTitle("Import from URL")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func importRecipe() {
        isImporting = true
        // URL import would happen here
        // Placeholder
        isImporting = false
    }
}

// MARK: - Preview

#Preview {
    AddRecipeView(familyGroup: nil)
        .modelContainer(for: Recipe.self, inMemory: true)
}
