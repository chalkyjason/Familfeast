import SwiftUI
import SwiftData

struct MealPlanningView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let familyGroup: FamilyGroup

    // MARK: - Queries

    @Query(sort: \MealSession.startDate, order: .reverse)
    private var mealSessions: [MealSession]

    // MARK: - State

    @State private var selectedSession: MealSession?
    @State private var showingNewSession = false
    @State private var showingVoting = false
    @State private var currentMember: FamilyMember?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Session selector
            sessionPicker

            if let session = selectedSession {
                ScrollView {
                    VStack(spacing: 20) {
                        // Session info card
                        sessionInfoCard(session)

                        // Voting status
                        if session.status == .voting {
                            votingStatusCard(session)
                        }

                        // Weekly calendar view
                        if session.status == .finalized || session.status == .active {
                            weeklyCalendarView(session)
                        }

                        // Results / Winners
                        if !session.candidateRecipes.isEmptyOrNil {
                            candidateRecipesSection(session)
                        }
                    }
                    .padding()
                }
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Meal Planning")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewSession = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewSession) {
            CreateMealSessionView(familyGroup: familyGroup)
        }
        .sheet(isPresented: $showingVoting) {
            if let session = selectedSession, let member = currentMember {
                NavigationStack {
                    VotingSessionView(mealSession: session, currentMember: member)
                }
            }
        }
        .onAppear {
            if selectedSession == nil {
                selectedSession = activeMealSession
            }
            if currentMember == nil {
                currentMember = familyGroup.members?.first
            }
        }
    }

    // MARK: - Subviews

    private var sessionPicker: some View {
        Picker("Session", selection: $selectedSession) {
            ForEach(mealSessions) { session in
                Text(session.name).tag(session as MealSession?)
            }
        }
        .pickerStyle(.menu)
        .padding()
        .background(.regularMaterial)
    }

    private func sessionInfoCard(_ session: MealSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(session.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(session.startDate.formatted(date: .abbreviated, time: .omitted)) - \(session.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: session.status)
            }

            Divider()

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Meals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.scheduledMeals?.count ?? 0) / \(session.numberOfMeals)")
                        .font(.headline)
                }

                if let budget = session.budgetLimit {
                    VStack(alignment: .leading) {
                        Text("Budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(budget.asDollarString)
                            .font(.headline)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Candidates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.candidateRecipes?.count ?? 0)")
                        .font(.headline)
                }
            }
        }
        .cardStyle()
    }

    private func votingStatusCard(_ session: MealSession) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "hand.thumbsup.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)

                VStack(alignment: .leading) {
                    Text("Voting in Progress")
                        .font(.headline)
                    Text("Cast your votes for this week's meals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button(action: { showingVoting = true }) {
                Text("Start Voting")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green.gradient)
                    .cornerRadius(12)
            }

            if let votes = session.votes, !votes.isEmpty {
                Button(action: { finalizeSession(session) }) {
                    Text("Finalize Votes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.gradient)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(.green.opacity(0.1))
        .cornerRadius(16)
    }

    private func weeklyCalendarView(_ session: MealSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Schedule")
                .font(.headline)

            if let scheduledMeals = session.scheduledMeals {
                ForEach(scheduledMeals) { meal in
                    ScheduledMealRow(meal: meal)
                }
            } else {
                Text("No meals scheduled yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }

    private func candidateRecipesSection(_ session: MealSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Candidate Recipes")
                .font(.headline)

            if let recipes = session.candidateRecipes {
                ForEach(recipes) { recipe in
                    VStack(spacing: 0) {
                        CandidateRecipeCard(recipe: recipe, votes: session.votes ?? [])

                        let conflicts = dietaryConflicts(for: recipe, in: familyGroup)
                        if !conflicts.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(conflicts.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.orange.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }

    /// Check recipe against family members' allergens and dietary restrictions
    private func dietaryConflicts(for recipe: Recipe, in group: FamilyGroup) -> [String] {
        guard let members = group.members else { return [] }

        var conflicts: [String] = []
        let recipeText = (recipe.title + " " + (recipe.recipeDescription ?? "") + " " + recipe.tags.joined(separator: " ")).lowercased()

        for member in members {
            for allergen in member.allergens {
                if recipeText.contains(allergen.lowercased()) {
                    conflicts.append("\(member.displayName): \(allergen)")
                }
            }
        }

        return conflicts
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "calendar.badge.plus",
            title: "No Meal Sessions",
            subtitle: "Create a new session to start planning meals",
            buttonTitle: "Create Session"
        ) {
            showingNewSession = true
        }
    }

    // MARK: - Computed Properties

    private var activeMealSession: MealSession? {
        mealSessions.first { $0.status == .active || $0.status == .voting }
    }

    // MARK: - Methods

    private func finalizeSession(_ session: MealSession) {
        guard let candidates = session.candidateRecipes,
              let votes = session.votes else { return }

        let winners = VotingAlgorithm.smartSelection(
            recipes: candidates,
            votes: votes,
            count: session.numberOfMeals,
            budgetLimit: session.budgetLimit,
            preferVariety: true
        )

        // Spread scheduled meals across the date range
        let totalDays = max(1, Calendar.current.dateComponents([.day], from: session.startDate, to: session.endDate).day ?? 1)
        let interval = max(1, totalDays / max(1, winners.count))

        for (index, recipe) in winners.enumerated() {
            let mealDate = Calendar.current.date(byAdding: .day, value: index * interval, to: session.startDate) ?? session.startDate
            let scheduledMeal = ScheduledMeal(scheduledDate: mealDate, mealType: .dinner)
            scheduledMeal.recipe = recipe
            scheduledMeal.mealSession = session
            modelContext.insert(scheduledMeal)
        }

        session.status = .finalized
        session.finalizedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Failed to finalize session: \(error)")
        }
    }
}

// MARK: - Extensions

extension Optional where Wrapped: Collection {
    var isEmptyOrNil: Bool {
        self?.isEmpty ?? true
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: MealSession.self, FamilyGroup.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let group = FamilyGroup(name: "Test Family", ownerUserID: "test")
    container.mainContext.insert(group)

    return NavigationStack {
        MealPlanningView(familyGroup: group)
            .modelContainer(container)
    }
}
