import SwiftUI
import SwiftData

struct ContentView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.cloudKitService) private var cloudKitService

    // MARK: - State

    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    @State private var currentFamilyGroup: FamilyGroup?
    @State private var isCloudKitAvailable = false

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
            DashboardView(familyGroup: currentFamilyGroup)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Recipes
            RecipeListView(familyGroup: currentFamilyGroup)
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(1)

            // Voting / Meal Planning
            if let group = currentFamilyGroup {
                MealPlanningView(familyGroup: group)
                    .tabItem {
                        Label("Plan", systemImage: "calendar")
                    }
                    .tag(2)
            }

            // Shopping List
            ShoppingListView(familyGroup: currentFamilyGroup)
                .tabItem {
                    Label("Shopping", systemImage: "cart.fill")
                }
                .tag(3)

            // Family / Settings
            FamilySettingsView(familyGroup: currentFamilyGroup)
                .tabItem {
                    Label("Family", systemImage: "person.3.fill")
                }
                .tag(4)
        }
    }

    // MARK: - Private Methods

    private func checkSetup() {
        // Check if user has a family group
        if familyGroups.isEmpty {
            showingOnboarding = true
        } else {
            currentFamilyGroup = familyGroups.first
        }

        // Check CloudKit availability
        Task {
            do {
                let status = try await cloudKitService.checkAccountStatus()
                await MainActor.run {
                    isCloudKitAvailable = (status == .available)
                }
            } catch {
                print("CloudKit not available: \(error)")
            }
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
