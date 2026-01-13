import SwiftUI
import SwiftData

struct VotingSessionView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let mealSession: MealSession
    let currentMember: FamilyMember

    // MARK: - Queries

    @Query private var votes: [Vote]

    // MARK: - State

    @State private var currentRecipeIndex = 0
    @State private var candidateRecipes: [Recipe] = []
    @State private var showingCompletion = false
    @State private var votingProgress: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Progress bar
                ProgressView(value: votingProgress, total: 1.0)
                    .padding(.horizontal)
                    .tint(.blue)

                Spacer()

                // Card stack
                if currentRecipeIndex < candidateRecipes.count {
                    ZStack {
                        // Show next 3 cards in stack
                        ForEach(Array(candidateRecipes.enumerated()), id: \.element.id) { index, recipe in
                            if index >= currentRecipeIndex && index < currentRecipeIndex + 3 {
                                VotingCardView(recipe: recipe) { voteType in
                                    handleVote(voteType: voteType, for: recipe)
                                }
                                .zIndex(Double(candidateRecipes.count - index))
                                .offset(y: CGFloat(index - currentRecipeIndex) * 10)
                                .scaleEffect(1.0 - CGFloat(index - currentRecipeIndex) * 0.05)
                            }
                        }
                    }
                    .padding(20)
                } else {
                    // All recipes voted
                    completionView
                }

                // Action buttons
                if currentRecipeIndex < candidateRecipes.count {
                    VotingActionButtons(
                        onVeto: { handleVote(voteType: .veto, for: candidateRecipes[currentRecipeIndex]) },
                        onDislike: { handleVote(voteType: .dislike, for: candidateRecipes[currentRecipeIndex]) },
                        onOk: { handleVote(voteType: .ok, for: candidateRecipes[currentRecipeIndex]) },
                        onLike: { handleVote(voteType: .like, for: candidateRecipes[currentRecipeIndex]) },
                        onSuperLike: { handleVote(voteType: .superLike, for: candidateRecipes[currentRecipeIndex]) }
                    )
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle("Vote on Meals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadCandidates()
            updateProgress()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(mealSession.name)
                .font(.headline)

            HStack(spacing: 20) {
                Label("\(candidateRecipes.count - currentRecipeIndex) left", systemImage: "list.bullet")
                Label("\(currentRecipeIndex) voted", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }

    private var completionView: View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)

            Text("Voting Complete!")
                .font(.title)
                .fontWeight(.bold)

            Text("You've voted on all \(candidateRecipes.count) recipes. Check back later to see the results!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green.gradient)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Private Methods

    private func loadCandidates() {
        guard let recipes = mealSession.candidateRecipes else { return }
        candidateRecipes = recipes

        // Filter out already voted recipes
        let memberVotes = votes.filter { $0.member?.id == currentMember.id }
        let votedRecipeIDs = Set(memberVotes.compactMap { $0.recipe?.id })

        candidateRecipes.removeAll { votedRecipeIDs.contains($0.id) }
        currentRecipeIndex = 0
    }

    private func handleVote(voteType: VoteType, for recipe: Recipe) {
        // Create vote
        let vote = Vote(voteType: voteType)
        vote.member = currentMember
        vote.recipe = recipe
        vote.mealSession = mealSession

        // Save to context
        modelContext.insert(vote)

        do {
            try modelContext.save()

            // Move to next recipe
            withAnimation {
                currentRecipeIndex += 1
                updateProgress()
            }

        } catch {
            print("Failed to save vote: \(error)")
        }
    }

    private func updateProgress() {
        if candidateRecipes.isEmpty {
            votingProgress = 0
        } else {
            votingProgress = Double(currentRecipeIndex) / Double(candidateRecipes.count)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let container = try! ModelContainer(
            for: MealSession.self, FamilyMember.self, Recipe.self, Vote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = container.mainContext

        // Create test data
        let member = FamilyMember(
            userRecordID: "test-user",
            displayName: "Test User",
            role: .member,
            hasAcceptedInvite: true
        )

        let session = MealSession(
            name: "Week of Jan 15",
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            numberOfMeals: 7
        )

        let recipe1 = Recipe(
            title: "Spaghetti Carbonara",
            instructions: "Cook pasta...",
            prepTime: 10,
            cookTime: 20
        )

        let recipe2 = Recipe(
            title: "Chicken Stir Fry",
            instructions: "Stir fry chicken...",
            prepTime: 15,
            cookTime: 15
        )

        session.candidateRecipes = [recipe1, recipe2]

        context.insert(member)
        context.insert(session)
        context.insert(recipe1)
        context.insert(recipe2)

        return VotingSessionView(mealSession: session, currentMember: member)
            .modelContainer(container)
    }
}
