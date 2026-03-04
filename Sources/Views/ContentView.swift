import SwiftUI
import SwiftData

enum AppTab: Int {
    case home = 0
    case recipes = 1
    case plan = 2
    case shopping = 3
    case family = 4
}

struct ContentView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedTab: AppTab = .home
    @State private var showingOnboarding = false
    @State private var currentFamilyGroup: FamilyGroup?

    // MARK: - Queries

    @Query private var familyGroups: [FamilyGroup]

    // MARK: - Body

    var body: some View {
        Group {
            if showingOnboarding || currentFamilyGroup == nil {
                OnboardingView(
                    isPresented: $showingOnboarding,
                    onComplete: { group in
                        currentFamilyGroup = group
                        showingOnboarding = false
                    }
                )
            } else {
                mainTabView
            }
        }
        .onAppear {
            checkSetup()
        }
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Home / Dashboard
            DashboardView(familyGroup: currentFamilyGroup, selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            // Recipes
            RecipeListView(familyGroup: currentFamilyGroup)
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(AppTab.recipes)

            // Voting / Meal Planning
            if let group = currentFamilyGroup {
                MealPlanningView(familyGroup: group)
                    .tabItem {
                        Label("Plan", systemImage: "calendar")
                    }
                    .tag(AppTab.plan)
            }

            // Shopping List
            ShoppingListView(familyGroup: currentFamilyGroup)
                .tabItem {
                    Label("Shopping", systemImage: "cart.fill")
                }
                .tag(AppTab.shopping)

            // Family / Settings
            FamilySettingsView(familyGroup: currentFamilyGroup)
                .tabItem {
                    Label("Family", systemImage: "person.3.fill")
                }
                .tag(AppTab.family)
        }
    }

    // MARK: - Private Methods

    private func checkSetup() {
        if familyGroups.isEmpty {
            showingOnboarding = true
        } else {
            currentFamilyGroup = familyGroups.first
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            FamilyGroup.self,
            Recipe.self,
            MealSession.self
        ], inMemory: true)
}
