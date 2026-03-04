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

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var numberOfMeals = 7
    @State private var budgetLimit = ""
    @State private var selectedRecipeIDs: Set<UUID> = []
    @State private var showingRecipePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    TextField("Name (e.g. Week of Jan 15)", text: $name)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section("Meals") {
                    Stepper("Number of meals: \(numberOfMeals)", value: $numberOfMeals, in: 1...21)
                    TextField("Budget (optional, e.g. 150.00)", text: $budgetLimit)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }

                Section("Candidate Recipes") {
                    Button(action: { showingRecipePicker = true }) {
                        HStack {
                            Text("Select Recipes")
                            Spacer()
                            Text("\(selectedRecipeIDs.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Meal Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createSession() }
                }
            }
            .sheet(isPresented: $showingRecipePicker) {
                RecipePickerView(selectedRecipeIDs: $selectedRecipeIDs)
            }
        }
    }

    private func createSession() {
        let sessionName = name.isEmpty ? "Week of \(startDate.formatted(date: .abbreviated, time: .omitted))" : name

        let session = MealSession(
            name: sessionName,
            startDate: startDate,
            endDate: endDate,
            numberOfMeals: numberOfMeals
        )

        // Parse budget
        if let budgetValue = Double(budgetLimit), budgetValue > 0 {
            session.budgetLimit = Int(budgetValue * 100)
        }

        session.familyGroup = familyGroup

        // Fetch selected recipes and attach as candidates
        if !selectedRecipeIDs.isEmpty {
            let allIDs = selectedRecipeIDs
            var descriptor = FetchDescriptor<Recipe>()
            descriptor.predicate = #Predicate<Recipe> { recipe in
                allIDs.contains(recipe.id)
            }
            if let recipes = try? modelContext.fetch(descriptor) {
                session.candidateRecipes = recipes
                session.status = .voting
            }
        }

        modelContext.insert(session)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to create session: \(error)")
        }
    }
}

struct RecipePickerView: View {
    @Binding var selectedRecipeIDs: Set<UUID>

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.title) private var recipes: [Recipe]

    @State private var searchText = ""

    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty { return recipes }
        return recipes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredRecipes) { recipe in
                Button(action: { toggleRecipe(recipe) }) {
                    HStack {
                        RecipeRow(recipe: recipe)
                        Spacer()
                        if selectedRecipeIDs.contains(recipe.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Select Recipes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func toggleRecipe(_ recipe: Recipe) {
        if selectedRecipeIDs.contains(recipe.id) {
            selectedRecipeIDs.remove(recipe.id)
        } else {
            selectedRecipeIDs.insert(recipe.id)
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
