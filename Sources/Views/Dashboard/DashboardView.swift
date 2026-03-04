import SwiftUI
import SwiftData

struct DashboardView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let familyGroup: FamilyGroup?
    @Binding var selectedTab: AppTab

    // MARK: - Queries

    @Query(sort: \MealSession.createdAt, order: .reverse)
    private var mealSessions: [MealSession]

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var recentRecipes: [Recipe]

    @Query private var shoppingLists: [ShoppingList]

    // MARK: - State

    @State private var showingNewSessionSheet = false
    @State private var showingAddRecipe = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header
                    welcomeHeader

                    // Active meal session
                    if let activeSession = activeMealSession {
                        activeMealSessionCard(activeSession)
                    }

                    // Quick actions
                    quickActionsGrid

                    // Recent recipes
                    if !recentRecipes.isEmpty {
                        recentRecipesSection
                    }

                    // Active shopping list
                    if let activeList = activeShoppingList {
                        activeShoppingListCard(activeList)
                    }

                    // Statistics
                    statisticsSection
                }
                .padding()
            }
            .navigationTitle("FamilyFeast")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingNewSessionSheet = true }) {
                            Label("New Meal Session", systemImage: "plus.circle")
                        }
                        Button(action: { showingAddRecipe = true }) {
                            Label("Add Recipe", systemImage: "book")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewSessionSheet) {
                if let group = familyGroup {
                    CreateMealSessionView(familyGroup: group)
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView(familyGroup: familyGroup)
            }
        }
    }

    // MARK: - Subviews

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title)
                .fontWeight(.bold)

            if let group = familyGroup {
                Text(group.name)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activeMealSessionCard(_ session: MealSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)

                Text("Active Meal Plan")
                    .font(.headline)

                Spacer()

                Text(session.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }

            Text(session.name)
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                VStack(alignment: .leading) {
                    Text("Meals Planned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.scheduledMeals?.count ?? 0) / \(session.numberOfMeals)")
                        .font(.headline)
                }

                Spacer()

                if let budget = session.budgetLimit {
                    VStack(alignment: .trailing) {
                        Text("Budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(budget.asDollarString)
                            .font(.headline)
                    }
                }
            }

            if let group = familyGroup {
                NavigationLink(destination: MealPlanningView(familyGroup: group)) {
                    Text("View Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .cardStyle()
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            QuickActionCard(
                title: "Vote on Meals",
                icon: "hand.thumbsup.fill",
                color: .green
            ) {
                selectedTab = .plan
            }

            QuickActionCard(
                title: "Add Recipe",
                icon: "plus.circle.fill",
                color: .blue
            ) {
                showingAddRecipe = true
            }

            QuickActionCard(
                title: "Shopping List",
                icon: "cart.fill",
                color: .orange
            ) {
                selectedTab = .shopping
            }

            QuickActionCard(
                title: "Family",
                icon: "person.3.fill",
                color: .purple
            ) {
                selectedTab = .family
            }
        }
    }

    private var recentRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Recipes")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(recentRecipes.prefix(5))) { recipe in
                        RecipeCard(recipe: recipe)
                    }
                }
            }
        }
    }

    private func activeShoppingListCard(_ list: ShoppingList) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(.orange)

                Text("Shopping List")
                    .font(.headline)

                Spacer()

                Text("\(list.remainingItems()) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: list.completionPercentage() / 100.0)
                .tint(.orange)

            Text("\(Int(list.completionPercentage()))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)

            NavigationLink(destination: ShoppingListView(familyGroup: familyGroup)) {
                Text("Continue Shopping")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.orange.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .cardStyle()
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.headline)

            HStack(spacing: 12) {
                StatCard(
                    value: "\(recentRecipes.count)",
                    label: "Recipes",
                    icon: "book.fill",
                    color: .blue
                )

                StatCard(
                    value: "\(mealSessions.count)",
                    label: "Sessions",
                    icon: "calendar",
                    color: .green
                )

                StatCard(
                    value: "\(familyGroup?.members?.count ?? 0)",
                    label: "Members",
                    icon: "person.3.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var activeMealSession: MealSession? {
        mealSessions.first { $0.status == .active || $0.status == .voting }
    }

    private var activeShoppingList: ShoppingList? {
        shoppingLists.first { !$0.isComplete }
    }
}

// MARK: - Preview

#Preview {
    DashboardView(familyGroup: nil, selectedTab: .constant(.home))
        .modelContainer(for: [FamilyGroup.self, MealSession.self, Recipe.self], inMemory: true)
}
