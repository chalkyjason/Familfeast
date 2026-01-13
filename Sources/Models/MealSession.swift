import Foundation
import SwiftData

/// Represents a meal planning session (e.g., "Week of Jan 15-21")
/// This is where voting and consensus occurs
@Model
final class MealSession {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Session name (e.g., "Week of Jan 15")
    var name: String

    /// Start date of the meal plan
    var startDate: Date

    /// End date of the meal plan
    var endDate: Date

    /// Current status of the session
    var status: SessionStatus

    /// Number of meals to plan for this session
    var numberOfMeals: Int

    /// Date session was created
    var createdAt: Date

    /// Date session was finalized
    var finalizedAt: Date?

    /// Budget limit for this session in cents
    var budgetLimit: Int?

    /// Actual spending in cents
    var actualSpending: Int?

    /// Notes for this session
    var notes: String?

    /// Reference to family group
    var familyGroup: FamilyGroup?

    /// Candidate recipes for voting
    var candidateRecipes: [Recipe]?

    /// Finalized recipes (winners of voting)
    @Relationship(deleteRule: .cascade, inverse: \ScheduledMeal.mealSession)
    var scheduledMeals: [ScheduledMeal]?

    /// Votes cast during this session
    @Relationship(deleteRule: .cascade, inverse: \Vote.mealSession)
    var votes: [Vote]?

    /// Shopping list generated from this session
    @Relationship(deleteRule: .cascade, inverse: \ShoppingList.mealSession)
    var shoppingLists: [ShoppingList]?

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        status: SessionStatus = .planning,
        numberOfMeals: Int = 7,
        budgetLimit: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.numberOfMeals = numberOfMeals
        self.budgetLimit = budgetLimit
        self.createdAt = createdAt
        self.candidateRecipes = []
        self.scheduledMeals = []
        self.votes = []
        self.shoppingLists = []
    }

    /// Duration of the session in days
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    /// Check if voting is complete (all members have voted)
    func isVotingComplete(totalMembers: Int) -> Bool {
        guard let votes = votes, let candidates = candidateRecipes else { return false }

        // Calculate expected votes: totalMembers * number of candidates
        let expectedVotes = totalMembers * candidates.count

        // Check if we have enough votes
        return votes.count >= expectedVotes
    }

    /// Calculate total estimated cost of scheduled meals
    func calculateEstimatedCost() -> Int {
        guard let scheduled = scheduledMeals else { return 0 }
        return scheduled.compactMap { $0.recipe?.totalEstimatedCost }.reduce(0, +)
    }

    /// Get remaining budget
    func remainingBudget() -> Int? {
        guard let limit = budgetLimit else { return nil }
        let estimated = calculateEstimatedCost()
        return limit - estimated
    }

    /// Budget status
    func budgetStatus() -> BudgetStatus {
        guard let limit = budgetLimit else { return .noBudget }
        let estimated = calculateEstimatedCost()

        if estimated > limit {
            return .overBudget(by: estimated - limit)
        } else if Double(estimated) > Double(limit) * 0.9 {
            return .nearLimit
        } else {
            return .underBudget
        }
    }
}

/// Status of a meal planning session
enum SessionStatus: String, Codable {
    case planning = "planning"        // Setting up candidates
    case voting = "voting"            // Members are voting
    case finalizing = "finalizing"    // Calculating winners and scheduling
    case finalized = "finalized"      // Complete, meals scheduled
    case active = "active"            // Currently executing this week
    case completed = "completed"      // Week has passed
    case cancelled = "cancelled"      // Session was cancelled
}

/// Budget tracking status
enum BudgetStatus: Equatable {
    case noBudget
    case underBudget
    case nearLimit
    case overBudget(by: Int)

    var displayText: String {
        switch self {
        case .noBudget:
            return "No budget set"
        case .underBudget:
            return "Under budget"
        case .nearLimit:
            return "Near budget limit"
        case .overBudget(let amount):
            let dollars = Double(amount) / 100.0
            return "Over budget by $\(String(format: "%.2f", dollars))"
        }
    }

    var icon: String {
        switch self {
        case .noBudget:
            return "dollarsign.circle"
        case .underBudget:
            return "checkmark.circle.fill"
        case .nearLimit:
            return "exclamationmark.triangle.fill"
        case .overBudget:
            return "xmark.circle.fill"
        }
    }
}

/// Represents a specific meal scheduled for a specific date
@Model
final class ScheduledMeal {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Date and time this meal is scheduled
    var scheduledDate: Date

    /// Type of meal (breakfast, lunch, dinner)
    var mealType: MealType

    /// The recipe to prepare
    var recipe: Recipe?

    /// Reference to the meal session
    var mealSession: MealSession?

    /// Whether this meal has been prepared
    var isPrepared: Bool

    /// Notes for this specific meal
    var notes: String?

    /// Actual rating after cooking (0-5)
    var actualRating: Double?

    init(
        id: UUID = UUID(),
        scheduledDate: Date,
        mealType: MealType = .dinner,
        isPrepared: Bool = false
    ) {
        self.id = id
        self.scheduledDate = scheduledDate
        self.mealType = mealType
        self.isPrepared = isPrepared
    }

    /// Day of week for display
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: scheduledDate)
    }

    /// Short date string for display
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: scheduledDate)
    }
}
