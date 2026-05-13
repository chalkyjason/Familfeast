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
    @State private var showingAISuggestions = false
    @State private var showingURLImport = false

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
                            Label("Manual Add", systemImage: "pencil")
                        }
                        
                        Button(action: { showingAISuggestions = true }) {
                            Label("AI Suggestions", systemImage: "sparkles")
                        }
                        
                        Button(action: { showingURLImport = true }) {
                            Label("Import URL", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView(familyGroup: familyGroup)
            }
            .sheet(isPresented: $showingAISuggestions) {
                AISuggestionsView(familyGroup: familyGroup)
            }
            .sheet(isPresented: $showingURLImport) {
                RecipeURLImportView(familyGroup: familyGroup)
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
                    RecipeRowView(recipe: recipe) {
                        toggleFavorite(recipe)
                    }
                }
            }
            .onDelete(perform: deleteRecipes)
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "book.closed",
            title: "No Recipes Yet",
            subtitle: "Add your first recipe to get started!",
            buttonTitle: "Add Recipe"
        ) {
            showingAddRecipe = true
        }
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

    private func toggleFavorite(_ recipe: Recipe) {
        recipe.isFavorite.toggle()
        try? modelContext.save()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Supporting Views

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
                .background(isSelected ? Theme.primary : Color.gray.opacity(0.1))
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

// MARK: - Preview

#Preview {
    RecipeListView(familyGroup: nil)
        .modelContainer(for: Recipe.self, inMemory: true)
}
