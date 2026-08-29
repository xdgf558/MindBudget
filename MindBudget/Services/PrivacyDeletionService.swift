import Foundation
@preconcurrency import CoreSpotlight

enum PrivacyDeletionStage: String, Equatable, Sendable {
    case cancellingNotifications
    case clearingSearchIndex
    case deletingTelemetry
    case deletingLocalData
    case resettingPreferences
}

enum PrivacyDeletionState: Equatable, Sendable {
    case idle
    case inProgress(PrivacyDeletionStage)
    case failed(PrivacyDeletionStage)
    case completed
    /// Every local financial record and preference was deleted, while the optional first-party
    /// telemetry endpoint did not confirm its separate remote deletion. Any authenticated proof
    /// remains owned by the telemetry client so the customer can retry from Privacy settings.
    case completedWithPendingTelemetryDeletion
}

protocol SearchIndexDeleting: Sendable {
    func deleteAll() async throws
}

protocol PrivacyDeletionVerifying: Sendable {
    func isDeletionComplete(in dataActor: DataActor) async throws -> Bool
}

struct ModelCountPrivacyDeletionVerifier: PrivacyDeletionVerifying, Sendable {
    func isDeletionComplete(in dataActor: DataActor) async throws -> Bool {
        let counts = try await dataActor.modelCounts()
        return counts.isEmpty
    }
}

actor CoreSpotlightIndexCleaner: SearchIndexDeleting {
    private let index = CSSearchableIndex.default()

    func deleteAll() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            index.deleteAllSearchableItems { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
