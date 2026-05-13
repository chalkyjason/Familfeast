import Foundation
import CloudKit
import SwiftData
import OSLog

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

    var isAvailable: Bool = false

    // MARK: - Initialization

    init(containerIdentifier: String? = nil) {
        // Container is created lazily to avoid trapping without entitlements
    }

    /// Explicitly activate CloudKit — call only when you know entitlements are present
    func activateCloudKit(identifier: String? = nil) {
        guard _container == nil else { return }
        let id = identifier ?? Config.cloudKitContainerIdentifier
        _container = CKContainer(identifier: id)
        isAvailable = true
        Logger.cloudKit.info("CloudKit activated with container: \(id)")
    }

    // MARK: - Retry Logic

    private func performWithRetry<T>(
        operationName: String,
        maxRetries: Int = 3,
        block: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await block()
            } catch {
                lastError = error
                
                guard let ckError = error as? CKError else {
                    Logger.cloudKit.error("\(operationName) failed with non-CKError: \(error.localizedDescription)")
                    throw error
                }
                
                // Check if error is transient and should be retried
                let isTransient = [
                    CKError.networkUnavailable,
                    CKError.networkFailure,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy,
                    CKError.requestRateLimited
                ].contains(ckError.code)
                
                if isTransient, attempt < maxRetries {
                    let delay = ckError.retryAfterSeconds ?? Double(attempt) * 2.0
                    Logger.cloudKit.warning("\(operationName) transient error (attempt \(attempt)): \(ckError.localizedDescription). Retrying in \(delay)s")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                Logger.cloudKit.error("\(operationName) terminal error: \(ckError.localizedDescription)")
                throw mapError(ckError)
            }
        }
        
        throw mapError(lastError ?? CloudKitError.unknown)
    }

    // MARK: - Account Status

    func checkAccountStatus() async throws -> CKAccountStatus {
        let container = try ensureContainer()
        return try await container.accountStatus()
    }

    // MARK: - User Identity

    func fetchUserRecordID() async throws -> CKRecord.ID {
        let container = try ensureContainer()
        return try await performWithRetry(operationName: "fetchUserRecordID") {
            try await container.userRecordID()
        }
    }

    // MARK: - Sharing

    func createShare(for recordZone: CKRecordZone) async throws -> CKShare {
        let container = try ensureContainer()
        return try await performWithRetry(operationName: "createShare") {
            let share = CKShare(recordZoneID: recordZone.zoneID)
            share[CKShare.SystemFieldKey.title] = "MealMeld Meal Plan" as CKRecordValue
            share[CKShare.SystemFieldKey.shareType] = "com.mealmeld.mealplan" as CKRecordValue
            share.publicPermission = .none
            
            let record = try await container.privateCloudDatabase.save(share)
            guard let savedShare = record as? CKShare else {
                throw CloudKitError.invalidShare
            }
            return savedShare
        }
    }

    // MARK: - Sync

    func fetchChanges(
        in zoneID: CKRecordZone.ID,
        since token: CKServerChangeToken?
    ) async throws -> (changedRecords: [CKRecord], deletedRecordIDs: [CKRecord.ID], newToken: CKServerChangeToken?) {
        let container = try ensureContainer()

        return try await performWithRetry(operationName: "fetchChanges") {
            var changedRecords: [CKRecord] = []
            var deletedRecordIDs: [CKRecord.ID] = []
            var newToken: CKServerChangeToken?

            let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            configuration.previousServerChangeToken = token

            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [zoneID],
                configurationsByRecordZoneID: [zoneID: configuration]
            )

            operation.recordWasChangedBlock = { _, result in
                if case .success(let record) = result {
                    changedRecords.append(record)
                }
            }

            operation.recordWithIDWasDeletedBlock = { recordID, _ in
                deletedRecordIDs.append(recordID)
            }

            operation.recordZoneFetchResultBlock = { _, result in
                if case .success(let data) = result {
                    newToken = data.serverChangeToken
                }
            }

            return try await withCheckedThrowingContinuation { continuation in
                operation.fetchRecordZoneChangesResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: (changedRecords, deletedRecordIDs, newToken))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                container.privateCloudDatabase.add(operation)
            }
        }
    }

    // MARK: - Record Operations

    func save(_ record: CKRecord) async throws -> CKRecord {
        let container = try ensureContainer()
        return try await performWithRetry(operationName: "saveRecord") {
            try await container.privateCloudDatabase.save(record)
        }
    }

    func fetch(recordID: CKRecord.ID) async throws -> CKRecord {
        let container = try ensureContainer()
        return try await performWithRetry(operationName: "fetchRecord") {
            try await container.privateCloudDatabase.record(for: recordID)
        }
    }

    func delete(recordID: CKRecord.ID) async throws {
        let container = try ensureContainer()
        try await performWithRetry(operationName: "deleteRecord") {
            _ = try await container.privateCloudDatabase.deleteRecord(withID: recordID)
        }
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> CloudKitError {
        guard let ckError = error as? CKError else {
            return .unknown
        }
        
        switch ckError.code {
        case .notAuthenticated:
            return .notAuthenticated
        case .permissionFailure:
            return .permissionDenied
        case .networkUnavailable, .networkFailure:
            return .networkError
        case .quotaExceeded:
            return .quotaExceeded
        case .zoneNotFound:
            return .zoneNotFound
        case .userDeletedZone:
            return .zoneNotFound
        default:
            return .unknown
        }
    }
}

// MARK: - Supporting Types

enum CloudKitError: Error, LocalizedError {
    case invalidShare
    case userNotFound
    case notAuthenticated
    case permissionDenied
    case networkError
    case quotaExceeded
    case zoneNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidShare: return "Invalid CloudKit share."
        case .userNotFound: return "User not found in iCloud."
        case .notAuthenticated: return "Please sign in to iCloud in your device settings."
        case .permissionDenied: return "Permission denied."
        case .networkError: return "Network error. Please check your connection."
        case .quotaExceeded: return "iCloud storage is full."
        case .zoneNotFound: return "Cloud zone not found. Please re-sync."
        case .unknown: return "An unknown CloudKit error occurred."
        }
    }
}
