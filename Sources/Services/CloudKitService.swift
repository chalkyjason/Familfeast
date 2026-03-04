import Foundation
import CloudKit
import SwiftData

/// Service for managing CloudKit operations
/// Handles sharing, synchronization, and multi-user collaboration
actor CloudKitService {

    // MARK: - Properties

    private var _container: CKContainer?
    // These are only accessed after _isAvailable guard, so force-unwrap is safe
    private var container: CKContainer { _container! }
    private var privateDatabase: CKDatabase { _container!.privateCloudDatabase }
    private var sharedDatabase: CKDatabase { _container!.sharedCloudDatabase }

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
        guard _isAvailable else { throw CloudKitError.notAuthenticated }
        return try await container.accountStatus()
    }

    /// Request application permission
    func requestApplicationPermission(_ permission: CKContainer.ApplicationPermissions) async throws -> CKContainer.ApplicationPermissionStatus {
        guard _isAvailable else { throw CloudKitError.notAuthenticated }
        return try await container.applicationPermissionStatus(for: permission)
    }

    // MARK: - User Identity

    /// Fetch current user record ID
    func fetchUserRecordID() async throws -> CKRecord.ID {
        guard _isAvailable else { throw CloudKitError.notAuthenticated }
        return try await container.userRecordID()
    }

    /// Fetch user identity
    func fetchUserIdentity() async throws -> CKUserIdentity? {
        let recordID = try await fetchUserRecordID()
        let lookupInfo = CKUserIdentity.LookupInfo(userRecordID: recordID)
        var foundIdentity: CKUserIdentity?
        let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [lookupInfo])
        operation.userIdentityDiscoveredBlock = { identity, _ in
            foundIdentity = identity
        }
        let semaphore = DispatchSemaphore(value: 0)
        operation.discoverUserIdentitiesResultBlock = { _ in
            semaphore.signal()
        }
        container.add(operation)
        semaphore.wait()
        return foundIdentity
    }

    // MARK: - Sharing

    /// Create a share for a family group
    func createShare(for recordZone: CKRecordZone) async throws -> CKShare {
        let share = CKShare(recordZoneID: recordZone.zoneID)

        share[CKShare.SystemFieldKey.title] = "FamilyFeast Meal Plan" as CKRecordValue
        share[CKShare.SystemFieldKey.shareType] = "com.familyfeast.mealplan" as CKRecordValue

        // Set permissions
        share.publicPermission = .none // Private sharing only

        // Save the share
        let record = try await privateDatabase.save(share)

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

        let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: email)

        // Discover user identity via operation
        var foundIdentity: CKUserIdentity?
        let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [lookupInfo])
        operation.userIdentityDiscoveredBlock = { identity, _ in
            foundIdentity = identity
        }
        let semaphore = DispatchSemaphore(value: 0)
        operation.discoverUserIdentitiesResultBlock = { _ in
            semaphore.signal()
        }
        container.add(operation)
        semaphore.wait()

        guard let identity = foundIdentity else {
            throw CloudKitError.userNotFound
        }

        let fetchOp = CKFetchShareParticipantsOperation(userIdentityLookupInfos: [lookupInfo])
        var fetchedParticipant: CKShare.Participant?
        fetchOp.perShareParticipantResultBlock = { _, result in
            if case .success(let participant) = result {
                fetchedParticipant = participant
            }
        }
        let sem2 = DispatchSemaphore(value: 0)
        fetchOp.fetchShareParticipantsResultBlock = { _ in
            sem2.signal()
        }
        container.add(fetchOp)
        sem2.wait()

        if let participant = fetchedParticipant {
            participant.permission = permission
            share.addParticipant(participant)
        }

        // Save updated share
        let updatedShare = try await privateDatabase.save(share) as! CKShare

        return updatedShare
    }

    /// Remove participant from share
    func removeParticipant(
        _ participant: CKShare.Participant,
        from share: CKShare
    ) async throws {

        share.removeParticipant(participant)

        // Save updated share
        _ = try await privateDatabase.save(share)
    }

    /// Fetch shares in a zone
    func fetchShares(in zoneID: CKRecordZone.ID) async throws -> [CKShare] {
        let query = CKQuery(
            recordType: CKRecord.SystemType.share,
            predicate: NSPredicate(value: true)
        )

        let results = try await privateDatabase.records(matching: query, inZoneWith: zoneID)

        return results.matchResults.compactMap { result in
            try? result.1.get() as? CKShare
        }
    }

    /// Accept a share invitation
    func acceptShare(metadata: CKShare.Metadata) async throws -> CKShare {
        let share = try await container.accept(metadata)
        return share
    }

    // MARK: - Record Zones

    /// Create a custom record zone for family data
    func createFamilyZone(name: String) async throws -> CKRecordZone {
        let zoneID = CKRecordZone.ID(zoneName: name, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)

        let savedZone = try await privateDatabase.save(zone)
        return savedZone
    }

    /// Fetch all custom zones
    func fetchAllZones() async throws -> [CKRecordZone] {
        try await privateDatabase.allRecordZones()
    }

    /// Delete a record zone
    func deleteZone(_ zoneID: CKRecordZone.ID) async throws {
        _ = try await privateDatabase.deleteRecordZone(withID: zoneID)
    }

    // MARK: - Subscriptions

    /// Subscribe to changes in a zone
    func subscribeToZoneChanges(zoneID: CKRecordZone.ID) async throws -> CKSubscription {
        let subscription = CKRecordZoneSubscription(
            zoneID: zoneID,
            subscriptionID: "zone-changes-\(zoneID.zoneName)"
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        let savedSubscription = try await privateDatabase.save(subscription)
        return savedSubscription
    }

    /// Fetch all subscriptions
    func fetchAllSubscriptions() async throws -> [CKSubscription] {
        try await privateDatabase.allSubscriptions()
    }

    /// Delete subscription
    func deleteSubscription(withID subscriptionID: CKSubscription.ID) async throws {
        _ = try await privateDatabase.deleteSubscription(withID: subscriptionID)
    }

    // MARK: - Sync

    /// Fetch changes from server
    func fetchChanges(
        in zoneID: CKRecordZone.ID,
        since token: CKServerChangeToken?
    ) async throws -> (changedRecords: [CKRecord], deletedRecordIDs: [CKRecord.ID], newToken: CKServerChangeToken?) {

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

        try await privateDatabase.add(operation)

        return (changedRecords, deletedRecordIDs, newToken)
    }

    // MARK: - Record Operations

    /// Save a record to CloudKit
    func save(_ record: CKRecord) async throws -> CKRecord {
        try await privateDatabase.save(record)
    }

    /// Fetch a record by ID
    func fetch(recordID: CKRecord.ID) async throws -> CKRecord {
        try await privateDatabase.record(for: recordID)
    }

    /// Delete a record
    func delete(recordID: CKRecord.ID) async throws {
        _ = try await privateDatabase.deleteRecord(withID: recordID)
    }

    /// Query records
    func query(
        _ query: CKQuery,
        in zoneID: CKRecordZone.ID? = nil
    ) async throws -> [CKRecord] {

        let results: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)

        if let zoneID = zoneID {
            results = try await privateDatabase.records(matching: query, inZoneWith: zoneID)
        } else {
            results = try await privateDatabase.records(matching: query)
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

        case .custom(let handler):
            return handler(clientRecord, serverRecord)
        }
    }
}

// MARK: - Supporting Types

enum ConflictResolution {
    case useClient
    case useServer
    case merge
    case custom((CKRecord, CKRecord) -> CKRecord)
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
