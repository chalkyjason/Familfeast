import XCTest
import SwiftData
@testable import FamilyFeast

/// Unit tests for the VotingAlgorithm
final class VotingAlgorithmTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        // Create in-memory container for testing
        let schema = Schema([Recipe.self, Vote.self, FamilyMember.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Borda Count Tests

    func testBordaScore_AllLikes() throws {
        // Given: 3 recipes, 3 members, all vote "like"
        let recipes = createTestRecipes(count: 3)
        let members = createTestMembers(count: 3)
        var votes: [Vote] = []

        for recipe in recipes {
            for member in members {
                let vote = Vote(voteType: .like)
                vote.recipe = recipe
                vote.member = member
                votes.append(vote)
            }
        }

        // When: Calculate Borda scores
        let results = VotingAlgorithm.calculateBordaScores(recipes: recipes, votes: votes)

        // Then: All recipes should have score of 3 (3 likes × 1 point each)
        for result in results {
            XCTAssertEqual(result.score, 3, "Each recipe should have score of 3")
            XCTAssertFalse(result.hasVeto, "No recipe should have veto")
        }
    }

    func testBordaScore_WithVeto() throws {
        // Given: 1 recipe with a veto
        let recipe = createTestRecipes(count: 1)[0]
        let members = createTestMembers(count: 3)

        let votes = [
            createVote(type: .like, recipe: recipe, member: members[0]),
            createVote(type: .like, recipe: recipe, member: members[1]),
            createVote(type: .veto, recipe: recipe, member: members[2])
        ]

        // When: Calculate Borda scores
        let results = VotingAlgorithm.calculateBordaScores(recipes: [recipe], votes: votes)

        // Then: Recipe should be marked as vetoed
        XCTAssertTrue(results[0].hasVeto, "Recipe should have veto flag")
    }

    func testBordaScore_MixedVotes() throws {
        // Given: 1 recipe with mixed votes
        let recipe = createTestRecipes(count: 1)[0]
        let members = createTestMembers(count: 4)

        let votes = [
            createVote(type: .superLike, recipe: recipe, member: members[0]), // +2
            createVote(type: .like, recipe: recipe, member: members[1]),      // +1
            createVote(type: .ok, recipe: recipe, member: members[2]),        // 0
            createVote(type: .dislike, recipe: recipe, member: members[3])    // -100
        ]

        // When: Calculate Borda scores
        let results = VotingAlgorithm.calculateBordaScores(recipes: [recipe], votes: votes)

        // Then: Score should be 2 + 1 + 0 - 100 = -97
        XCTAssertEqual(results[0].score, -97, "Score should account for all vote types")
    }

    func testSelectTopRecipes_ExcludesVetoed() throws {
        // Given: 3 recipes, one is vetoed
        let recipes = createTestRecipes(count: 3)
        let member = createTestMembers(count: 1)[0]

        let votes = [
            createVote(type: .like, recipe: recipes[0], member: member),
            createVote(type: .like, recipe: recipes[1], member: member),
            createVote(type: .veto, recipe: recipes[2], member: member)
        ]

        // When: Select top 3 recipes
        let selected = VotingAlgorithm.selectTopRecipes(
            from: recipes,
            votes: votes,
            count: 3
        )

        // Then: Only 2 recipes should be selected (vetoed one excluded)
        XCTAssertEqual(selected.count, 2, "Vetoed recipe should be excluded")
        XCTAssertFalse(selected.contains { $0.id == recipes[2].id }, "Vetoed recipe should not be selected")
    }

    func testSelectTopRecipes_ExcludesNegativeScores() throws {
        // Given: 3 recipes, one with negative score
        let recipes = createTestRecipes(count: 3)
        let members = createTestMembers(count: 2)

        var votes: [Vote] = []

        // Recipe 0: 2 likes = +2
        votes.append(createVote(type: .like, recipe: recipes[0], member: members[0]))
        votes.append(createVote(type: .like, recipe: recipes[0], member: members[1]))

        // Recipe 1: 1 like, 1 ok = +1
        votes.append(createVote(type: .like, recipe: recipes[1], member: members[0]))
        votes.append(createVote(type: .ok, recipe: recipes[1], member: members[1]))

        // Recipe 2: 1 dislike, 1 ok = -100
        votes.append(createVote(type: .dislike, recipe: recipes[2], member: members[0]))
        votes.append(createVote(type: .ok, recipe: recipes[2], member: members[1]))

        // When: Select top recipes
        let selected = VotingAlgorithm.selectTopRecipes(
            from: recipes,
            votes: votes,
            count: 3
        )

        // Then: Only recipes with non-negative scores should be selected
        XCTAssertEqual(selected.count, 2, "Negative score recipe should be excluded")
    }

    // MARK: - Schulze Method Tests

    func testSchulzeRanking_SimpleCase() throws {
        // Given: 3 recipes with clear preference order
        let recipes = createTestRecipes(count: 3)
        let members = createTestMembers(count: 3)

        var votes: [Vote] = []

        // Member 0 prefers: A > B > C
        votes.append(createVote(type: .superLike, recipe: recipes[0], member: members[0]))
        votes.append(createVote(type: .like, recipe: recipes[1], member: members[0]))
        votes.append(createVote(type: .ok, recipe: recipes[2], member: members[0]))

        // Member 1 prefers: A > B > C
        votes.append(createVote(type: .like, recipe: recipes[0], member: members[1]))
        votes.append(createVote(type: .like, recipe: recipes[1], member: members[1]))
        votes.append(createVote(type: .ok, recipe: recipes[2], member: members[1]))

        // Member 2 prefers: A > B > C
        votes.append(createVote(type: .like, recipe: recipes[0], member: members[2]))
        votes.append(createVote(type: .ok, recipe: recipes[1], member: members[2]))
        votes.append(createVote(type: .dislike, recipe: recipes[2], member: members[2]))

        // When: Apply Schulze ranking
        let ranked = VotingAlgorithm.schulzeRanking(recipes: recipes, votes: votes)

        // Then: Order should be A, B, C
        XCTAssertEqual(ranked[0].id, recipes[0].id, "Recipe A should be first")
        XCTAssertEqual(ranked[1].id, recipes[1].id, "Recipe B should be second")
        XCTAssertEqual(ranked[2].id, recipes[2].id, "Recipe C should be third")
    }

    // MARK: - Consensus Metrics Tests

    func testConsensusMetrics_HighConsensus() throws {
        // Given: All members vote the same
        let recipe = createTestRecipes(count: 1)[0]
        let members = createTestMembers(count: 4)

        let votes = members.map { member in
            createVote(type: .like, recipe: recipe, member: member)
        }

        // When: Calculate metrics
        let metrics = VotingAlgorithm.calculateConsensusMetrics(recipe: recipe, votes: votes)

        // Then: Consensus should be 100%
        XCTAssertEqual(metrics.consensusLevel, 100.0, "Full agreement should give 100% consensus")
        XCTAssertEqual(metrics.positivePercentage, 100.0, "All likes should give 100% positive")
    }

    func testConsensusMetrics_LowConsensus() throws {
        // Given: Mixed votes
        let recipe = createTestRecipes(count: 1)[0]
        let members = createTestMembers(count: 4)

        let votes = [
            createVote(type: .superLike, recipe: recipe, member: members[0]),
            createVote(type: .like, recipe: recipe, member: members[1]),
            createVote(type: .ok, recipe: recipe, member: members[2]),
            createVote(type: .dislike, recipe: recipe, member: members[3])
        ]

        // When: Calculate metrics
        let metrics = VotingAlgorithm.calculateConsensusMetrics(recipe: recipe, votes: votes)

        // Then: Consensus should be low (25% since all different)
        XCTAssertEqual(metrics.consensusLevel, 25.0, "All different votes should give 25% consensus")
        XCTAssertEqual(metrics.positivePercentage, 50.0, "2/4 positive should give 50%")
    }

    // MARK: - Smart Selection Tests

    func testSmartSelection_BudgetConstraint() throws {
        // Given: 3 recipes with different costs
        let recipes = createTestRecipes(count: 3)
        recipes[0].totalEstimatedCost = 1000 // $10.00
        recipes[1].totalEstimatedCost = 2000 // $20.00
        recipes[2].totalEstimatedCost = 1500 // $15.00

        let member = createTestMembers(count: 1)[0]

        // All recipes equally liked
        let votes = recipes.map { recipe in
            createVote(type: .like, recipe: recipe, member: member)
        }

        // When: Select with budget limit of $25
        let selected = VotingAlgorithm.smartSelection(
            recipes: recipes,
            votes: votes,
            count: 3,
            budgetLimit: 2500, // $25.00 in cents
            preferVariety: false
        )

        // Then: Should select recipes that fit budget
        let totalCost = selected.compactMap { $0.totalEstimatedCost }.reduce(0, +)
        XCTAssertLessThanOrEqual(totalCost, 2500, "Total cost should not exceed budget")
    }

    // MARK: - Helper Methods

    private func createTestRecipes(count: Int) -> [Recipe] {
        (0..<count).map { i in
            Recipe(
                title: "Test Recipe \(i)",
                instructions: "Test instructions",
                prepTime: 10,
                cookTime: 20
            )
        }
    }

    private func createTestMembers(count: Int) -> [FamilyMember] {
        (0..<count).map { i in
            FamilyMember(
                userRecordID: "user\(i)",
                displayName: "Member \(i)",
                role: .member,
                hasAcceptedInvite: true
            )
        }
    }

    private func createVote(type: VoteType, recipe: Recipe, member: FamilyMember) -> Vote {
        let vote = Vote(voteType: type)
        vote.recipe = recipe
        vote.member = member
        return vote
    }
}

// MARK: - Performance Tests

extension VotingAlgorithmTests {

    func testPerformance_BordaScore_LargeDataset() throws {
        // Given: Large dataset
        let recipes = createTestRecipes(count: 100)
        let members = createTestMembers(count: 20)
        var votes: [Vote] = []

        for recipe in recipes {
            for member in members {
                let voteType: VoteType = Bool.random() ? .like : .ok
                votes.append(createVote(type: voteType, recipe: recipe, member: member))
            }
        }

        // When/Then: Measure performance
        measure {
            _ = VotingAlgorithm.calculateBordaScores(recipes: recipes, votes: votes)
        }
    }

    func testPerformance_SchulzeMethod_MediumDataset() throws {
        // Given: Medium dataset (Schulze is O(n³))
        let recipes = createTestRecipes(count: 20)
        let members = createTestMembers(count: 10)
        var votes: [Vote] = []

        for recipe in recipes {
            for member in members {
                let voteType: VoteType = Bool.random() ? .like : .ok
                votes.append(createVote(type: voteType, recipe: recipe, member: member))
            }
        }

        // When/Then: Measure performance
        measure {
            _ = VotingAlgorithm.schulzeRanking(recipes: recipes, votes: votes)
        }
    }
}
