import Foundation
import CloudKit
import SwiftData

/// Service for managing CloudKit operations
/// Handles sharing, synchronization, and multi-user collaboration
actor CloudKitService {

    // MARK: - Properties

    private var _container: CKContainer?

    private func ensureContainer() throws -> CKContainer {
        guard let container = _container else {
            throw CloudKitError.notAuthenticated
        }
        return container
    }

    private var _isAvailable: Bool = false
    var isAvailable: Bool { _isAvailable }

    // MARK: - Initialization

    init(containerIdentifier: String? = nil) {
        // Do NOT create CKContainer here — it traps without entitlements.
        // Container is created lazily on first successful ensureContainer() call.
    }

    /// Explicitly activate CloudKit — call only when you know entitlements are present.
    /// Without calling this, all CloudKit methods will throw .notAuthenticated.
    func activateCloudKit(identifier: String? = nil) {
        guard _container == nil else { return }
        if let id = identifier {
            _container = CKContainer(identifier: id)
        } else {
            _container = CKContainer.default()
        }
        _isAvailable = true
    }

    // MARK: - Account Status

    /// Check if user is logged into iCloud
    func checkAccountStatus() async throws -> CKAccountStatus {
        let container = try ensureContainer()
        return try await container.accountStatus()
    }

    /// Request application permission
    func requestApplicationPermission(_ permission: CKContainer.ApplicationPermissions) async throws -> CKContainer.ApplicationPermissionStatus {
        let container = try ensureContainer()
        return try await container.applicationPermissionStatus(for: permission)
    }

    // MARK: - User Identity

    /// Fetch current user record ID
    func fetchUserRecordID() async throws -> CKRecord.ID {
        let container = try ensureContainer()
        return try await container.userRecordID()
    }

    /// Fetch user identity
    func fetchUserIdentity() async throws -> CKUserIdentity? {
        let container = try ensureContainer()
        let recordID = try await fetchUserRecordID()
        let lookupInfo = CKUserIdentity.LookupInfo(userRecordID: recordID)

        return try await withCheckedThrowingContinuation { continuation in
            var foundIdentity: CKUserIdentity?
            let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [lookupInfo])
            operation.userIdentityDiscoveredBlock = { identity, _ in
                foundIdentity = identity
            }
            operation.discoverUserIdentitiesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: foundIdentity)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            container.add(operation)
        }
    }

    // MARK: - Sharing

    /// Create a share for a family group
    func createShare(for recordZone: CKRecordZone) async throws -> CKShare {
        let container = try ensureContainer()
        let share = CKShare(recordZoneID: recordZone.zoneID)

        share[CKShare.SystemFieldKey.title] = "FamilyFeast Meal Plan" as CKRecordValue
        share[CKShare.SystemFieldKey.shareType] = "com.familyfeast.mealplan" as CKRecordValue

        // Set permissions
        share.publicPermission = .none // Private sharing only

        // Save the share
        let record = try await container.privateCloudDatabase.save(share)

        guard let savedShare = record as? CKShare else {
            throw CloudKitError.invalidShare
        }

        return savedShare
    }

    /// Add participant to a share
    func addParticipant(
        email: String,
        to share: CKShare,
        permission: CKShare.ParticipantPermission = .readWrite
    ) async throws -> CKShare {
        let container = try ensureContainer()
        let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: email)

        // Discover user identity via async continuation
        let _: CKUserIdentity = try await withCheckedThrowingContinuation { continuation in
            var foundIdentity: CKUserIdentity?
            let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [lookupInfo])
            operation.userIdentityDiscoveredBlock = { identity, _ in
                foundIdentity = identity
            }
            operation.discoverUserIdentitiesResultBlock = { result in
                switch result {
                case .success:
                    if let identity = foundIdentity {
                        continuation.resume(returning: identity)
                    } else {
                        continuation.resume(throwing: CloudKitError.userNotFound)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            container.add(operation)
        }

        // Fetch share participant via async continuation
        let fetchedParticipant: CKShare.Participant? = try await withCheckedThrowingContinuation { continuation in
            var participant: CKShare.Participant?
            let fetchOp = CKFetchShareParticipantsOperation(userIdentityLookupInfos: [lookupInfo])
            fetchOp.perShareParticipantResultBlock = { _, result in
                if case .success(let p) = result {
                    participant = p
                }
            }
            fetchOp.fetchShareParticipantsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: participant)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            container.add(fetchOp)
        }

        if let participant = fetchedParticipant {
            participant.permission = permission
            share.addParticipant(participant)
        }

        // Save updated share
        let record = try await container.privateCloudDatabase.save(share)
        guard let updatedShare = record as? CKShare else {
            throw CloudKitError.invalidShare
        }

        return updatedShare
    }

    /// Remove participant from share
    func removeParticipant(
        _ participant: CKShare.Participant,
        from share: CKShare
    ) async throws {
        let container = try ensureContainer()
        share.removeParticipant(participant)
        _ = try await container.privateCloudDatabase.save(share)
    }

    /// Fetch shares in a zone
    func fetchShares(in zoneID: CKRecordZone.ID) async throws -> [CKShare] {
        let container = try ensureContainer()
        let query = CKQuery(
            recordType: CKRecord.SystemType.share,
            predicate: NSPredicate(value: true)
        )

        let results = try await container.privateCloudDatabase.records(matching: query, inZoneWith: zoneID)

        return results.matchResults.compactMap { result in
            try? result.1.get() as? CKShare
        }
    }

    /// Accept a share invitation
    func acceptShare(metadata: CKShare.Metadata) async throws -> CKShare {
        let container = try ensureContainer()
        return try await container.accept(metadata)
    }

    // MARK: - Record Zones

    /// Create a custom record zone for family data
    func createFamilyZone(name: String) async throws -> CKRecordZone {
        let container = try ensureContainer()
        let zoneID = CKRecordZone.ID(zoneName: name, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        return try await container.privateCloudDatabase.save(zone)
    }

    /// Fetch all custom zones
    func fetchAllZones() async throws -> [CKRecordZone] {
        let container = try ensureContainer()
        return try await container.privateCloudDatabase.allRecordZones()
    }

    /// Delete a record zone
    func deleteZone(_ zoneID: CKRecordZone.ID) async throws {
        let container = try ensureContainer()
        _ = try await container.privateCloudDatabase.deleteRecordZone(withID: zoneID)
    }

    // MARK: - Subscriptions

    /// Subscribe to changes in a zone
    func subscribeToZoneChanges(zoneID: CKRecordZone.ID) async throws -> CKSubscription {
        let container = try ensureContainer()
        let subscription = CKRecordZoneSubscription(
            zoneID: zoneID,
            subscriptionID: "zone-changes-\(zoneID.zoneName)"
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        return try await container.privateCloudDatabase.save(subscription)
    }

    /// Fetch all subscriptions
    func fetchAllSubscriptions() async throws -> [CKSubscription] {
        let container = try ensureContainer()
        return try await container.privateCloudDatabase.allSubscriptions()
    }

    /// Delete subscription
    func deleteSubscription(withID subscriptionID: CKSubscription.ID) async throws {
        let container = try ensureContainer()
        _ = try await container.privateCloudDatabase.deleteSubscription(withID: subscriptionID)
    }

    // MARK: - Sync

    /// Fetch changes from server
    func fetchChanges(
        in zoneID: CKRecordZone.ID,
        since token: CKServerChangeToken?
    ) async throws -> (changedRecords: [CKRecord], deletedRecordIDs: [CKRecord.ID], newToken: CKServerChangeToken?) {
        let container = try ensureContainer()

        var changedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []
        var newToken: CKServerChangeToken?

        let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        configuration.previousServerChangeToken = token

        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID],
            configurationsByRecordZoneID: [zoneID: configuration]
        )

        operation.recordWasChangedBlock = { recordID, result in
            switch result {
            case .success(let record):
                changedRecords.append(record)
            case .failure(let error):
                print("Error fetching record \(recordID): \(error)")
            }
        }

        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            deletedRecordIDs.append(recordID)
        }

        operation.recordZoneFetchResultBlock = { zoneID, result in
            switch result {
            case .success(let data):
                newToken = data.serverChangeToken
            case .failure(let error):
                print("Error fetching zone \(zoneID): \(error)")
            }
        }

        try await container.privateCloudDatabase.add(operation)

        return (changedRecords, deletedRecordIDs, newToken)
    }

    // MARK: - Record Operations

    /// Save a record to CloudKit
    func save(_ record: CKRecord) async throws -> CKRecord {
        let container = try ensureContainer()
        return try await container.privateCloudDatabase.save(record)
    }

    /// Fetch a record by ID
    func fetch(recordID: CKRecord.ID) async throws -> CKRecord {
        let container = try ensureContainer()
        return try await container.privateCloudDatabase.record(for: recordID)
    }

    /// Delete a record
    func delete(recordID: CKRecord.ID) async throws {
        let container = try ensureContainer()
        _ = try await container.privateCloudDatabase.deleteRecord(withID: recordID)
    }

    /// Query records
    func query(
        _ query: CKQuery,
        in zoneID: CKRecordZone.ID? = nil
    ) async throws -> [CKRecord] {
        let container = try ensureContainer()
        let db = container.privateCloudDatabase

        let results: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)

        if let zoneID = zoneID {
            results = try await db.records(matching: query, inZoneWith: zoneID)
        } else {
            results = try await db.records(matching: query)
        }

        return results.matchResults.compactMap { result in
            try? result.1.get()
        }
    }

    // MARK: - Conflict Resolution

    /// Resolve conflict by choosing client or server version
    func resolveConflict(
        clientRecord: CKRecord,
        serverRecord: CKRecord,
        resolution: ConflictResolution
    ) -> CKRecord {

        switch resolution {
        case .useClient:
            return clientRecord

        case .useServer:
            return serverRecord

        case .merge:
            // Merge strategy: take server record and apply client changes
            let merged = serverRecord

            // Copy all client values to merged record
            for key in clientRecord.allKeys() {
                // Skip system fields
                if !key.hasPrefix("CD_") {
                    merged[key] = clientRecord[key]
                }
            }

            return merged
        }
    }
}

// MARK: - Supporting Types

enum ConflictResolution {
    case useClient
    case useServer
    case merge
}

enum CloudKitError: Error, LocalizedError {
    case invalidShare
    case userNotFound
    case notAuthenticated
    case permissionDenied
    case networkError
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidShare:
            return "Invalid CloudKit share"
        case .userNotFound:
            return "User not found in iCloud"
        case .notAuthenticated:
            return "Not signed into iCloud"
        case .permissionDenied:
            return "Permission denied"
        case .networkError:
            return "Network error"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - CloudKit Sharing Helper

/// Helper class for presenting sharing UI
#if os(iOS)
import UIKit

extension CloudKitService {
    /// Create UICloudSharingController for presenting share sheet
    @MainActor
    func createSharingController(
        share: CKShare,
        container: CKContainer
    ) -> UICloudSharingController {

        let controller = UICloudSharingController(
            share: share,
            container: container
        )

        return controller
    }
}
#endif
