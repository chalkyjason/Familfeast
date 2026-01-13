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
        .onAppear {
            if selectedSession == nil {
                selectedSession = activeMealSession
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
                        Text("$\(String(format: "%.2f", Double(budget) / 100.0))")
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
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func candidateRecipesSection(_ session: MealSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Candidate Recipes")
                .font(.headline)

            if let recipes = session.candidateRecipes {
                ForEach(recipes) { recipe in
                    CandidateRecipeCard(recipe: recipe, votes: session.votes ?? [])
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Meal Sessions")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a new session to start planning meals")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingNewSession = true }) {
                Text("Create Session")
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

    private var activeMealSession: MealSession? {
        mealSessions.first { $0.status == .active || $0.status == .voting }
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(12)
    }

    private var backgroundColor: Color {
        switch status {
        case .planning: return .blue
        case .voting: return .green
        case .finalizing: return .orange
        case .finalized: return .purple
        case .active: return .pink
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

struct ScheduledMealRow: View {
    let meal: ScheduledMeal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.dayOfWeek)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(meal.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)

            if let recipe = meal.recipe {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .foregroundColor(.gray)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Text("\(recipe.totalTime) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            } else {
                Text("No recipe assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CandidateRecipeCard: View {
    let recipe: Recipe
    let votes: [Vote]

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.gray)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(1)

                // Vote counts
                let recipeVotes = votes.filter { $0.recipe?.id == recipe.id }
                let voteCounts = recipeVotes.countByType()

                HStack(spacing: 8) {
                    if let likes = voteCounts[.like] {
                        Label("\(likes)", systemImage: "hand.thumbsup.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    if let dislikes = voteCounts[.dislike] {
                        Label("\(dislikes)", systemImage: "hand.thumbsdown.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Text("Score: \(recipeVotes.bordaScore())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct CreateMealSessionView: View {
    let familyGroup: FamilyGroup
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    TextField("Name", text: .constant("Week of Jan 15"))
                    DatePicker("Start Date", selection: .constant(Date()), displayedComponents: .date)
                    DatePicker("End Date", selection: .constant(Date().addingTimeInterval(7*24*60*60)), displayedComponents: .date)
                }
            }
            .navigationTitle("New Meal Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { dismiss() }
                }
            }
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
