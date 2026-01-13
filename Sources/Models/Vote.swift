import Foundation
import SwiftData

/// Represents a family member's vote on a recipe
@Model
final class Vote {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Type of vote
    var voteType: VoteType

    /// When the vote was cast
    var timestamp: Date

    /// Optional comment or note
    var comment: String?

    /// Reference to the family member who voted
    var member: FamilyMember?

    /// Reference to the recipe being voted on
    var recipe: Recipe?

    /// Reference to the meal session this vote belongs to
    var mealSession: MealSession?

    init(
        id: UUID = UUID(),
        voteType: VoteType,
        timestamp: Date = Date(),
        comment: String? = nil
    ) {
        self.id = id
        self.voteType = voteType
        self.timestamp = timestamp
        self.comment = comment
    }
}

/// Vote types with associated scoring
enum VoteType: String, Codable, CaseIterable {
    case superLike = "superLike"    // Love it! (+2 points)
    case like = "like"              // Like it (+1 point)
    case ok = "ok"                  // Neutral (0 points)
    case dislike = "dislike"        // Don't like it (-100 points, soft veto)
    case veto = "veto"              // Absolute no (hard constraint, e.g., allergy)

    /// Numeric score for consensus algorithm
    var score: Int {
        switch self {
        case .superLike: return 2
        case .like: return 1
        case .ok: return 0
        case .dislike: return -100
        case .veto: return Int.min  // Effectively infinite negative
        }
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .superLike: return "Love It!"
        case .like: return "Like"
        case .ok: return "It's OK"
        case .dislike: return "Dislike"
        case .veto: return "Never"
        }
    }

    /// Icon for UI
    var icon: String {
        switch self {
        case .superLike: return "heart.fill"
        case .like: return "hand.thumbsup.fill"
        case .ok: return "hand.raised.fill"
        case .dislike: return "hand.thumbsdown.fill"
        case .veto: return "xmark.circle.fill"
        }
    }

    /// Color for UI
    var color: String {
        switch self {
        case .superLike: return "pink"
        case .like: return "green"
        case .ok: return "yellow"
        case .dislike: return "orange"
        case .veto: return "red"
        }
    }
}

/// Extension for vote statistics
extension Array where Element == Vote {
    /// Calculate aggregate Borda count score
    func bordaScore() -> Int {
        reduce(0) { $0 + $1.voteType.score }
    }

    /// Check if there are any vetos
    func hasVeto() -> Bool {
        contains { $0.voteType == .veto }
    }

    /// Count votes by type
    func countByType() -> [VoteType: Int] {
        var counts: [VoteType: Int] = [:]
        for vote in self {
            counts[vote.voteType, default: 0] += 1
        }
        return counts
    }

    /// Get percentage of positive votes (like + superLike)
    func positivePercentage() -> Double {
        guard !isEmpty else { return 0 }
        let positive = filter { $0.voteType == .like || $0.voteType == .superLike }.count
        return Double(positive) / Double(count) * 100
    }

    /// Get consensus level (0-100)
    /// Higher means more agreement
    func consensusLevel() -> Double {
        guard !isEmpty else { return 0 }

        let counts = countByType()
        let maxCount = counts.values.max() ?? 0

        // If most people agree on the same vote type, consensus is high
        return Double(maxCount) / Double(count) * 100
    }
}
