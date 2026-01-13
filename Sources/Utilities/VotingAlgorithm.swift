import Foundation
import SwiftData

/// Implements consensus voting algorithms for meal selection
/// Supports Borda Count (Modified Score Voting) and Schulze Method
struct VotingAlgorithm {

    // MARK: - Borda Count / Score Voting

    /// Calculate recipe scores using Modified Borda Count
    /// Returns recipes sorted by score (highest first)
    static func calculateBordaScores(
        recipes: [Recipe],
        votes: [Vote]
    ) -> [(recipe: Recipe, score: Int, hasVeto: Bool)] {

        var results: [(recipe: Recipe, score: Int, hasVeto: Bool)] = []

        for recipe in recipes {
            // Get all votes for this recipe
            let recipeVotes = votes.filter { $0.recipe?.id == recipe.id }

            // Check for veto
            let hasVeto = recipeVotes.contains { $0.voteType == .veto }

            // Calculate total score
            let score = recipeVotes.reduce(0) { $0 + $1.voteType.score }

            results.append((recipe: recipe, score: score, hasVeto: hasVeto))
        }

        // Sort by score (descending)
        // Vetoed recipes go to the bottom
        results.sort { lhs, rhs in
            if lhs.hasVeto != rhs.hasVeto {
                return !lhs.hasVeto // Non-vetoed first
            }
            return lhs.score > rhs.score
        }

        return results
    }

    /// Select top N recipes for the meal plan
    /// Excludes vetoed recipes and ensures positive or neutral scores
    static func selectTopRecipes(
        from recipes: [Recipe],
        votes: [Vote],
        count: Int
    ) -> [Recipe] {

        let scoredRecipes = calculateBordaScores(recipes: recipes, votes: votes)

        // Filter out vetoed recipes and negative scores
        let validRecipes = scoredRecipes.filter { !$0.hasVeto && $0.score >= 0 }

        // Take top N
        return Array(validRecipes.prefix(count).map { $0.recipe })
    }

    // MARK: - Schulze Method (Condorcet)

    /// Calculate pairwise preferences for Schulze method
    /// Returns a matrix where [i][j] represents how many voters prefer recipe i over recipe j
    static func calculatePairwisePreferences(
        recipes: [Recipe],
        votes: [Vote]
    ) -> [[Int]] {

        let n = recipes.count
        var matrix = Array(repeating: Array(repeating: 0, count: n), count: n)

        // Get all unique voters
        let voters = Set(votes.compactMap { $0.member?.id })

        for voter in voters {
            let voterVotes = votes.filter { $0.member?.id == voter }

            // For each pair of recipes, determine preference
            for i in 0..<n {
                for j in 0..<n where i != j {
                    let recipeI = recipes[i]
                    let recipeJ = recipes[j]

                    let voteI = voterVotes.first { $0.recipe?.id == recipeI.id }
                    let voteJ = voterVotes.first { $0.recipe?.id == recipeJ.id }

                    let scoreI = voteI?.voteType.score ?? 0
                    let scoreJ = voteJ?.voteType.score ?? 0

                    // If voter prefers i over j
                    if scoreI > scoreJ {
                        matrix[i][j] += 1
                    }
                }
            }
        }

        return matrix
    }

    /// Calculate strongest paths using Schulze method
    static func calculateStrongestPaths(pairwisePreferences: [[Int]]) -> [[Int]] {
        let n = pairwisePreferences.count
        var paths = pairwisePreferences

        // Floyd-Warshall algorithm to find strongest paths
        for i in 0..<n {
            for j in 0..<n where i != j {
                for k in 0..<n where i != k && j != k {
                    paths[j][k] = max(paths[j][k], min(paths[j][i], paths[i][k]))
                }
            }
        }

        return paths
    }

    /// Rank recipes using Schulze method
    /// Returns recipes sorted by Schulze ranking
    static func schulzeRanking(
        recipes: [Recipe],
        votes: [Vote]
    ) -> [Recipe] {

        guard !recipes.isEmpty else { return [] }

        let pairwise = calculatePairwisePreferences(recipes: recipes, votes: votes)
        let paths = calculateStrongestPaths(pairwisePreferences: pairwise)

        let n = recipes.count

        // Calculate wins for each recipe
        var wins = Array(repeating: 0, count: n)

        for i in 0..<n {
            for j in 0..<n where i != j {
                if paths[i][j] > paths[j][i] {
                    wins[i] += 1
                }
            }
        }

        // Create indexed array and sort by wins
        let indexed = recipes.enumerated().map { ($0.offset, $0.element, wins[$0.offset]) }
        let sorted = indexed.sorted { $0.2 > $1.2 }

        return sorted.map { $0.1 }
    }

    // MARK: - Consensus Analysis

    /// Calculate consensus metrics for a recipe
    static func calculateConsensusMetrics(
        recipe: Recipe,
        votes: [Vote]
    ) -> ConsensusMetrics {

        let recipeVotes = votes.filter { $0.recipe?.id == recipe.id }

        guard !recipeVotes.isEmpty else {
            return ConsensusMetrics(
                totalVotes: 0,
                bordaScore: 0,
                consensusLevel: 0,
                positivePercentage: 0,
                hasVeto: false,
                voteCounts: [:]
            )
        }

        let bordaScore = recipeVotes.reduce(0) { $0 + $1.voteType.score }
        let consensusLevel = recipeVotes.consensusLevel()
        let positivePercentage = recipeVotes.positivePercentage()
        let hasVeto = recipeVotes.contains { $0.voteType == .veto }
        let voteCounts = recipeVotes.countByType()

        return ConsensusMetrics(
            totalVotes: recipeVotes.count,
            bordaScore: bordaScore,
            consensusLevel: consensusLevel,
            positivePercentage: positivePercentage,
            hasVeto: hasVeto,
            voteCounts: voteCounts
        )
    }

    /// Find recipes that satisfy minimum consensus threshold
    static func filterByConsensus(
        recipes: [Recipe],
        votes: [Vote],
        minimumConsensus: Double = 60.0
    ) -> [Recipe] {

        return recipes.filter { recipe in
            let metrics = calculateConsensusMetrics(recipe: recipe, votes: votes)
            return !metrics.hasVeto && metrics.consensusLevel >= minimumConsensus
        }
    }

    // MARK: - Smart Selection

    /// Intelligent recipe selection considering multiple factors
    /// - Consensus score
    /// - Budget constraints
    /// - Nutritional variety
    /// - Cuisine diversity
    static func smartSelection(
        recipes: [Recipe],
        votes: [Vote],
        count: Int,
        budgetLimit: Int? = nil,
        preferVariety: Bool = true
    ) -> [Recipe] {

        // Start with Borda scores
        var scoredRecipes = calculateBordaScores(recipes: recipes, votes: votes)

        // Remove vetoed recipes
        scoredRecipes = scoredRecipes.filter { !$0.hasVeto }

        // Remove negative scores
        scoredRecipes = scoredRecipes.filter { $0.score >= 0 }

        // Apply budget constraint if specified
        if let budget = budgetLimit {
            scoredRecipes = filterByBudget(scoredRecipes, budget: budget, count: count)
        }

        // Apply variety preference
        if preferVariety {
            scoredRecipes = maximizeVariety(scoredRecipes, count: count)
        }

        // Return top N
        return Array(scoredRecipes.prefix(count).map { $0.recipe })
    }

    /// Filter recipes to fit within budget
    private static func filterByBudget(
        _ scoredRecipes: [(recipe: Recipe, score: Int, hasVeto: Bool)],
        budget: Int,
        count: Int
    ) -> [(recipe: Recipe, score: Int, hasVeto: Bool)] {

        // Sort by score
        let sorted = scoredRecipes.sorted { $0.score > $1.score }

        // Greedy selection within budget
        var selected: [(recipe: Recipe, score: Int, hasVeto: Bool)] = []
        var totalCost = 0

        for item in sorted {
            let cost = item.recipe.totalEstimatedCost ?? 0
            if totalCost + cost <= budget {
                selected.append(item)
                totalCost += cost
                if selected.count >= count {
                    break
                }
            }
        }

        return selected
    }

    /// Maximize cuisine and difficulty variety in selection
    private static func maximizeVariety(
        _ scoredRecipes: [(recipe: Recipe, score: Int, hasVeto: Bool)],
        count: Int
    ) -> [(recipe: Recipe, score: Int, hasVeto: Bool)] {

        var selected: [(recipe: Recipe, score: Int, hasVeto: Bool)] = []
        var cuisineCount: [String: Int] = [:]
        var difficultyCount: [DifficultyLevel: Int] = [:]

        // Sort by score first
        let sorted = scoredRecipes.sorted { $0.score > $1.score }

        for item in sorted {
            if selected.count >= count {
                break
            }

            let cuisine = item.recipe.cuisine ?? "unknown"
            let difficulty = item.recipe.difficulty

            // Prefer recipes that add variety
            let cuisineRarity = cuisineCount[cuisine] ?? 0
            let difficultyRarity = difficultyCount[difficulty] ?? 0

            // Simple heuristic: prefer recipes with less common cuisines/difficulties
            // But still prioritize score
            let varietyBonus = (cuisineRarity == 0 ? 10 : 0) + (difficultyRarity == 0 ? 5 : 0)

            selected.append(item)
            cuisineCount[cuisine, default: 0] += 1
            difficultyCount[difficulty, default: 0] += 1
        }

        return selected
    }
}

// MARK: - Supporting Structures

/// Metrics for analyzing consensus on a recipe
struct ConsensusMetrics {
    let totalVotes: Int
    let bordaScore: Int
    let consensusLevel: Double      // 0-100, higher = more agreement
    let positivePercentage: Double  // 0-100, percentage of like/superlike
    let hasVeto: Bool
    let voteCounts: [VoteType: Int]

    var description: String {
        """
        Total Votes: \(totalVotes)
        Borda Score: \(bordaScore)
        Consensus Level: \(String(format: "%.1f", consensusLevel))%
        Positive: \(String(format: "%.1f", positivePercentage))%
        Vetoed: \(hasVeto)
        """
    }

    /// Overall recommendation strength (0-100)
    var recommendationStrength: Double {
        guard !hasVeto else { return 0 }

        // Weighted combination of factors
        let scoreWeight = 0.4
        let consensusWeight = 0.3
        let positiveWeight = 0.3

        // Normalize Borda score to 0-100 (assuming max realistic score is 20)
        let normalizedScore = min(Double(bordaScore) / 20.0 * 100.0, 100.0)

        return (normalizedScore * scoreWeight) +
               (consensusLevel * consensusWeight) +
               (positivePercentage * positiveWeight)
    }
}
