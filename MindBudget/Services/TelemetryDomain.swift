import CryptoKit
import Foundation

enum TelemetryEnvironment: String, Codable, CaseIterable, Sendable {
    case development
    case staging
    case production
}

enum TelemetryOutcome: String, Codable, CaseIterable, Sendable {
    case completed
    case cancelled
    case unavailable
    case failed
}

enum TelemetryProSurfaceAction: String, Codable, CaseIterable, Sendable {
    case presented
    case dismissed
}

enum TelemetryPurchaseAction: String, Codable, CaseIterable, Sendable {
    case purchase
    case restore
    case manage
}

enum TelemetryReceiptAction: String, Codable, CaseIterable, Sendable {
    case opened
    case acquired
    case reviewed
    case saved
}

enum TelemetryCloudSyncAction: String, Codable, CaseIterable, Sendable {
    case enable
    case disable
    case deleteCloudCopy
    case resolveConflict
}

/// The complete R1 event vocabulary. Associated values are closed enums, so customer text,
/// financial values, receipt evidence, StoreKit identifiers, and caller-defined properties
/// cannot be represented by this type.
enum TelemetryEvent: Codable, Equatable, Sendable {
    case appSessionStarted
    case proSurface(TelemetryProSurfaceAction)
    case subscription(TelemetryPurchaseAction, TelemetryOutcome)
    case receipt(TelemetryReceiptAction, TelemetryOutcome)
    case cloudSync(TelemetryCloudSyncAction, TelemetryOutcome)

    private enum CodingKeys: String, CodingKey {
        case name
        case action
        case outcome
    }

    private enum Name: String, Codable {
        case appSessionStarted = "app_session_started"
        case proSurface = "pro_surface"
        case subscription = "subscription_action"
        case receipt = "receipt_flow"
        case cloudSync = "cloud_sync_control"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Name.self, forKey: .name) {
        case .appSessionStarted:
            self = .appSessionStarted
        case .proSurface:
            self = .proSurface(
                try container.decode(TelemetryProSurfaceAction.self, forKey: .action)
            )
        case .subscription:
            self = .subscription(
                try container.decode(TelemetryPurchaseAction.self, forKey: .action),
                try container.decode(TelemetryOutcome.self, forKey: .outcome)
            )
        case .receipt:
            self = .receipt(
                try container.decode(TelemetryReceiptAction.self, forKey: .action),
                try container.decode(TelemetryOutcome.self, forKey: .outcome)
            )
        case .cloudSync:
            self = .cloudSync(
                try container.decode(TelemetryCloudSyncAction.self, forKey: .action),
                try container.decode(TelemetryOutcome.self, forKey: .outcome)
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .appSessionStarted:
            try container.encode(Name.appSessionStarted, forKey: .name)
        case let .proSurface(action):
            try container.encode(Name.proSurface, forKey: .name)
            try container.encode(action, forKey: .action)
        case let .subscription(action, outcome):
            try container.encode(Name.subscription, forKey: .name)
            try container.encode(action, forKey: .action)
            try container.encode(outcome, forKey: .outcome)
        case let .receipt(action, outcome):
            try container.encode(Name.receipt, forKey: .name)
            try container.encode(action, forKey: .action)
            try container.encode(outcome, forKey: .outcome)
        case let .cloudSync(action, outcome):
            try container.encode(Name.cloudSync, forKey: .name)
            try container.encode(action, forKey: .action)
            try container.encode(outcome, forKey: .outcome)
        }
    }
}

enum TelemetryAppVersionError: Error, Equatable, Sendable {
    case invalid
}

struct TelemetryAppVersion: Codable, Equatable, Sendable {
    let value: String

    init(_ value: String) throws {
        let permitted = CharacterSet(charactersIn: "0123456789.")
        guard !value.isEmpty,
              value.utf8.count <= 32,
              value.unicodeScalars.allSatisfy(permitted.contains),
              value.first != ".",
              value.last != ".",
              !value.contains("..") else {
            throw TelemetryAppVersionError.invalid
        }
        self.value = value
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = try TelemetryAppVersion(container.decode(String.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct TelemetryPolicy: Equatable, Sendable {
    static let schemaVersion = 1
    static let maximumQueuedEvents = 256
    static let maximumBatchEvents = 20
    static let maximumIdentityGenerations = 4
    static let identityRotationDays = 30
    static let deletionProofRetentionDays = 90
    static let maximumPersistenceBytes = 256 * 1_024
    static let maximumRetryDelaySeconds = 6 * 60 * 60

    let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func identityRotationDate(after date: Date) -> Date? {
        calendar.date(byAdding: .day, value: Self.identityRotationDays, to: date)
    }

    func deletionProofExpirationDate(after date: Date) -> Date? {
        calendar.date(byAdding: .day, value: Self.deletionProofRetentionDays, to: date)
    }

    func retryDate(after date: Date, consecutiveFailures: Int) -> Date? {
        let boundedExponent = min(max(consecutiveFailures - 1, 0), 8)
        let seconds = min(60 * (1 << boundedExponent), Self.maximumRetryDelaySeconds)
        return calendar.date(byAdding: .second, value: seconds, to: date)
    }
}

struct TelemetryIdentityGeneration: Codable, Equatable, Sendable {
    let identifier: UUID
    let createdAt: Date
    let rotatesAt: Date
    let deletionSecret: Data
    var deletionProofExpiresAt: Date?

    var deletionHandle: String {
        SHA256.hash(data: deletionSecret).map { String(format: "%02x", $0) }.joined()
    }
}

struct TelemetryQueuedEvent: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let identityIdentifier: UUID
    let occurredAt: Date
    let event: TelemetryEvent
}

struct TelemetryPersistedState: Codable, Equatable, Sendable {
    var collectionEnabled: Bool
    var identities: [TelemetryIdentityGeneration]
    var queuedEvents: [TelemetryQueuedEvent]
    var consecutiveFailures: Int
    var retryNotBefore: Date?

    static let disabled = TelemetryPersistedState(
        collectionEnabled: false,
        identities: [],
        queuedEvents: [],
        consecutiveFailures: 0,
        retryNotBefore: nil
    )
}

struct TelemetryUploadBatch: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let environment: TelemetryEnvironment
    let appVersion: TelemetryAppVersion
    let pseudonymousIdentifier: UUID
    let deletionHandle: String
    let events: [TelemetryQueuedEvent]
}

struct TelemetryDeletionProof: Codable, Equatable, Sendable {
    let pseudonymousIdentifier: UUID
    let deletionSecret: Data
}

/// A bounded complete-delete request deliberately groups retained generations. Ordinary upload
/// envelopes remain generation-isolated; C5-02 must use this association only for deletion and
/// must not persist, log, or reuse it.
struct TelemetryDeletionRequest: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let environment: TelemetryEnvironment
    let proofs: [TelemetryDeletionProof]
}

enum TelemetryCaptureResult: Equatable, Sendable {
    case disabled
    case queued
    case queuedAfterDroppingOldest
    case unavailable
}

enum TelemetryFlushResult: Equatable, Sendable {
    case disabled
    case empty
    case deferred(Date)
    case accepted(Int)
    case rejected(Int)
    case failed(Date?)
    case persistenceFailed
    case unavailable
}

enum TelemetryDeletionResult: Equatable, Sendable {
    case deletedLocally
    /// Corrupt local state was erased, but no remote deletion can be claimed because its proofs
    /// could not be authenticated and recovered.
    case deletedLocallyWithoutRemoteProofs
    case deletedRemotely
    case failed(Date?)
    case unavailable
}

enum TelemetryClientAvailability: Equatable, Sendable {
    case available
    case corruptPersistence
}

struct TelemetryClientSnapshot: Equatable, Sendable {
    let collectionEnabled: Bool
    let queuedEventCount: Int
    let retainedIdentityCount: Int
    let retryNotBefore: Date?
    let availability: TelemetryClientAvailability

    static let corrupt = TelemetryClientSnapshot(
        collectionEnabled: false,
        queuedEventCount: 0,
        retainedIdentityCount: 0,
        retryNotBefore: nil,
        availability: .corruptPersistence
    )
}

enum TelemetryTransportUploadResolution: Equatable, Sendable {
    case accepted
    case rejected
    case retryAfter(seconds: Int)
}

protocol TelemetryTransporting: Sendable {
    func upload(_ batch: TelemetryUploadBatch) async throws -> TelemetryTransportUploadResolution
    func delete(_ request: TelemetryDeletionRequest) async throws
    func cancelInFlightUpload() async
}

extension TelemetryTransporting {
    func cancelInFlightUpload() async {}
}

/// C5-01 deliberately has no real transport or accepted endpoint. C5-02 must replace this only
/// after its exact domain, methods, fields, TTL, deletion, and environment contract is reviewed.
struct UnavailableTelemetryTransport: TelemetryTransporting {
    enum Unavailable: Error { case noAcceptedEndpoint }

    func upload(_ batch: TelemetryUploadBatch) async throws -> TelemetryTransportUploadResolution {
        throw Unavailable.noAcceptedEndpoint
    }

    func delete(_ request: TelemetryDeletionRequest) async throws {
        throw Unavailable.noAcceptedEndpoint
    }

    func cancelInFlightUpload() async {}
}
