import Foundation
import SwiftData
import CloudKit

/// The root container for shared family data in CloudKit
/// This entity represents a family unit that shares meal planning data
@Model
final class FamilyGroup {
    /// Unique identifier for the family group
    @Attribute(.unique) var id: UUID

    /// Name of the family group (e.g., "Smith Family")
    var name: String

    /// The CloudKit record ID for this group (stored as string)
    var cloudKitRecordID: String?

    /// The CloudKit share reference (stored as data)
    var shareData: Data?

    /// Subscription status for CloudKit notifications
    var subscriptionStatus: SubscriptionStatus

    /// Date the group was created
    var createdAt: Date

    /// The user who created this group (owner)
    var ownerUserID: String

    /// Members of this family group
    @Relationship(deleteRule: .cascade, inverse: \FamilyMember.familyGroup)
    var members: [FamilyMember]?

    /// Meal sessions associated with this group
    @Relationship(deleteRule: .cascade, inverse: \MealSession.familyGroup)
    var mealSessions: [MealSession]?

    /// Recipes saved by this family
    @Relationship(deleteRule: .cascade, inverse: \Recipe.familyGroup)
    var recipes: [Recipe]?

    /// Shopping lists for this family
    @Relationship(deleteRule: .cascade, inverse: \ShoppingList.familyGroup)
    var shoppingLists: [ShoppingList]?

    init(
        id: UUID = UUID(),
        name: String,
        ownerUserID: String,
        subscriptionStatus: SubscriptionStatus = .inactive,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.ownerUserID = ownerUserID
        self.subscriptionStatus = subscriptionStatus
        self.createdAt = createdAt
        self.members = []
        self.mealSessions = []
        self.recipes = []
        self.shoppingLists = []
    }
}

/// Subscription status for CloudKit notifications
enum SubscriptionStatus: String, Codable {
    case active = "active"
    case inactive = "inactive"
    case pending = "pending"
}

/// Represents a member of the family group
@Model
final class FamilyMember {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// iCloud user record name (CKRecord.ID)
    var userRecordID: String

    /// Display name
    var displayName: String

    /// Email or phone number (optional)
    var contactInfo: String?

    /// Role in the family
    var role: FamilyRole

    /// Date joined the group
    var joinedAt: Date

    /// Whether this member has accepted the invitation
    var hasAcceptedInvite: Bool

    /// Reference to the family group
    var familyGroup: FamilyGroup?

    /// Votes cast by this member
    @Relationship(deleteRule: .cascade, inverse: \Vote.member)
    var votes: [Vote]?

    init(
        id: UUID = UUID(),
        userRecordID: String,
        displayName: String,
        contactInfo: String? = nil,
        role: FamilyRole = .member,
        joinedAt: Date = Date(),
        hasAcceptedInvite: Bool = false
    ) {
        self.id = id
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.contactInfo = contactInfo
        self.role = role
        self.joinedAt = joinedAt
        self.hasAcceptedInvite = hasAcceptedInvite
        self.votes = []
    }
}

/// Role of a family member
enum FamilyRole: String, Codable {
    case owner = "owner"              // Creator of the group, full permissions
    case headOfHousehold = "hoh"      // Can create meal sessions and manage recipes
    case member = "member"            // Can vote and view
    case child = "child"              // Limited permissions
}
