import CryptoKit
import Foundation

enum CloudSyncLocalChangeSignal {
    static let notification = Notification.Name("MindBudget.CloudSyncLocalChange")

    static func post() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}

enum CloudSyncRemoteApplicationSignal {
    static let notification = Notification.Name("MindBudget.CloudSyncRemoteApplication")

    static func post() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}

enum CloudSyncEntityType: String, Codable, CaseIterable, Sendable {
    case expense
    case income
    case incomeAllocation
    case savingsGoal
    case recurringRule
    case recurringOccurrence
    case budgetPlan
    case budgetPlanSemantics
    case categoryBudget
    case wishItem
    case coolingOffPlan
    case reflectionLog

    static let applicationOrder: [CloudSyncEntityType] = [
        .budgetPlan,
        .expense,
        .income,
        .savingsGoal,
        .recurringRule,
        .wishItem,
        .budgetPlanSemantics,
        .categoryBudget,
        .incomeAllocation,
        .recurringOccurrence,
        .coolingOffPlan,
        .reflectionLog
    ]
}

enum CloudSyncOperation: String, Codable, Sendable {
    case upsert
    case tombstone
}

enum CloudSyncStatus: String, Codable, Equatable, Sendable {
    case disabled
    case starting
    case ready
    case syncing
    case waitingForNetwork
    case accountUnavailable
    case quotaExceeded
    case pausedAccountChanged
    case pausedEncryptedDataReset
    case pausedRemoteZoneDeleted
    case deletingCloudData
    case failed

    /// These states represent a changed trust boundary, not a retryable transport condition.
    /// Only the explicit account re-consent flow or a future C4B-03 recovery decision may clear
    /// them; delayed callbacks must never reopen transport.
    var isStickyPause: Bool {
        switch self {
        case .pausedAccountChanged, .pausedEncryptedDataReset, .pausedRemoteZoneDeleted:
            true
        case .disabled, .starting, .ready, .syncing, .waitingForNetwork,
             .accountUnavailable, .quotaExceeded, .deletingCloudData, .failed:
            false
        }
    }
}

enum CloudSyncRecordState: String, Codable, Sendable {
    case accepted
    case pending
    case conflicted
}

enum CloudSyncOutboxStatus: String, Codable, Sendable {
    case pending
    case blockedByConflict
}

enum CloudSyncInboxStatus: String, Codable, Sendable {
    case pending
    case applied
    case quarantined
}

enum CloudSyncReasonCode: String, Codable, Equatable, Sendable {
    case noAccount
    case accountChanged
    case networkUnavailable
    case quotaExceeded
    case serviceUnavailable
    case encryptedDataReset
    case remoteZoneDeleted
    case malformedRecord
    case unsupportedSchema
    case invalidIdentity
    case invalidLineage
    case divergentConflict
    case missingParent
    case physicalDeletion
    case localValidationFailed
    case transportFailed
}

struct CloudSyncSnapshot: Equatable, Sendable {
    let isEnabled: Bool
    let status: CloudSyncStatus
    let reason: CloudSyncReasonCode?
    let pendingCount: Int
    let quarantinedCount: Int
    let cloudCopyMayExist: Bool

    init(
        isEnabled: Bool,
        status: CloudSyncStatus,
        reason: CloudSyncReasonCode?,
        pendingCount: Int,
        quarantinedCount: Int,
        cloudCopyMayExist: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.status = status
        self.reason = reason
        self.pendingCount = pendingCount
        self.quarantinedCount = quarantinedCount
        self.cloudCopyMayExist = cloudCopyMayExist
    }

    static let disabled = CloudSyncSnapshot(
        isEnabled: false,
        status: .disabled,
        reason: nil,
        pendingCount: 0,
        quarantinedCount: 0,
        cloudCopyMayExist: false
    )
}

enum CloudSyncConflictResolution: Equatable, Sendable {
    case keepLocal
    case useCloud
}

struct CloudSyncConflictSummary: Identifiable, Equatable, Sendable {
    var id: String { recordName }

    let recordName: String
    let entityType: CloudSyncEntityType?
    let reason: CloudSyncReasonCode
    let localOperation: CloudSyncOperation?
    let cloudOperation: CloudSyncOperation?
    let canResolve: Bool
}

enum CloudSyncCloudDeletionOutcome: Equatable, Sendable {
    case deleted
    case pending(CloudSyncReasonCode)
    case failed(CloudSyncReasonCode)
}

enum CloudSyncTrustBoundaryRecovery: Equatable, Sendable {
    /// Explicitly accepts this device's current local facts as the source for a newly created
    /// private zone after an account switch, encrypted-key reset, or externally deleted zone.
    case rebuildCloudFromLocal
}

/// Closed recurring identity shared by the recurrence engine and CloudKit record-name builder.
/// Caller-supplied arbitrary strings never become record names.
struct RecurringOccurrenceKey: Equatable, Hashable, Sendable {
    let ruleID: UUID
    let year: Int
    let month: Int

    var rawValue: String {
        "\(ruleID.uuidString.lowercased()):\(year)-\(String(format: "%02d", month))"
    }

    init(ruleID: UUID, year: Int, month: Int) throws {
        guard (1...12).contains(month) else {
            throw CloudSyncValidationError.invalidIdentity
        }
        self.ruleID = ruleID
        self.year = year
        self.month = month
    }

    init(rawValue: String) throws {
        guard rawValue.unicodeScalars.allSatisfy({
            $0.isASCII && $0.value >= 0x20 && $0.value != 0x7f
        }),
              !rawValue.contains("/"),
              !rawValue.contains("%"),
              let separator = rawValue.firstIndex(of: ":"),
              rawValue[rawValue.index(after: separator)...].count >= 4 else {
            throw CloudSyncValidationError.invalidIdentity
        }
        let uuidText = String(rawValue[..<separator])
        let dateText = String(rawValue[rawValue.index(after: separator)...])
        guard uuidText == uuidText.lowercased(),
              let ruleID = UUID(uuidString: uuidText),
              ruleID.uuidString.lowercased() == uuidText,
              let dash = dateText.lastIndex(of: "-"),
              dateText[dateText.index(after: dash)...].count == 2,
              let year = Int(dateText[..<dash]),
              String(year) == String(dateText[..<dash]),
              let month = Int(dateText[dateText.index(after: dash)...]),
              (1...12).contains(month) else {
            throw CloudSyncValidationError.invalidIdentity
        }
        self.ruleID = ruleID
        self.year = year
        self.month = month
    }
}

enum CloudSyncValidationError: Error, Equatable, Sendable {
    case payloadTooLarge
    case malformedEnvelope
    case unsupportedSchema
    case invalidIdentity
    case invalidDigest
    case invalidLineage
    case invalidPayload
}

struct CloudSyncValue: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case string
        case integer
        case unsigned
        case boolean
    }

    let kind: Kind
    let stringValue: String?
    let integerValue: Int64?
    let unsignedValue: UInt64?
    let booleanValue: Bool?

    static func string(_ value: String) -> CloudSyncValue {
        CloudSyncValue(
            kind: .string,
            stringValue: value,
            integerValue: nil,
            unsignedValue: nil,
            booleanValue: nil
        )
    }

    static func integer(_ value: Int64) -> CloudSyncValue {
        CloudSyncValue(
            kind: .integer,
            stringValue: nil,
            integerValue: value,
            unsignedValue: nil,
            booleanValue: nil
        )
    }

    static func unsigned(_ value: UInt64) -> CloudSyncValue {
        CloudSyncValue(
            kind: .unsigned,
            stringValue: nil,
            integerValue: nil,
            unsignedValue: value,
            booleanValue: nil
        )
    }

    static func boolean(_ value: Bool) -> CloudSyncValue {
        CloudSyncValue(
            kind: .boolean,
            stringValue: nil,
            integerValue: nil,
            unsignedValue: nil,
            booleanValue: value
        )
    }

    var validatedString: String? {
        guard kind == .string, integerValue == nil, unsignedValue == nil,
              booleanValue == nil else { return nil }
        return stringValue
    }

    var validatedInteger: Int64? {
        guard kind == .integer, stringValue == nil, unsignedValue == nil,
              booleanValue == nil else { return nil }
        return integerValue
    }

    var validatedUnsigned: UInt64? {
        guard kind == .unsigned, stringValue == nil, integerValue == nil,
              booleanValue == nil else { return nil }
        return unsignedValue
    }

    var validatedBoolean: Bool? {
        guard kind == .boolean, stringValue == nil, integerValue == nil,
              unsignedValue == nil else { return nil }
        return booleanValue
    }
}

struct CloudSyncPayload: Codable, Equatable, Sendable {
    let entityType: CloudSyncEntityType
    let identity: String
    let fields: [String: CloudSyncValue]
}

struct CloudSyncEnvelope: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let maximumEncodedSize = 512 * 1_024

    let schemaVersion: Int
    let recordName: String
    let entityType: CloudSyncEntityType
    let operation: CloudSyncOperation
    let revision: Int64
    /// Informational authoring instant carried inside the encrypted envelope. It is covered by
    /// canonical encoding but never participates in conflict winner selection.
    let modifiedAt: UInt64
    let parentSemanticDigest: String?
    let semanticDigest: String
    let payload: CloudSyncPayload?
}

private struct CloudSyncSemanticDocument: Codable {
    let recordName: String
    let entityType: CloudSyncEntityType
    let operation: CloudSyncOperation
    let payload: CloudSyncPayload?
}

enum CloudSyncCodec {
    /// Advances lineage without allowing a corrupted/private record at `Int64.max` to trap the
    /// process. Exhausted ancestry is invalid and stays quarantined rather than wrapping or
    /// inventing another revision.
    static func nextRevision(after revision: Int64) throws -> Int64 {
        guard revision >= 0 else { throw CloudSyncValidationError.invalidLineage }
        let (next, overflow) = revision.addingReportingOverflow(1)
        guard !overflow, next > 0 else { throw CloudSyncValidationError.invalidLineage }
        return next
    }

    static func makeEnvelope(
        payload: CloudSyncPayload?,
        entityType: CloudSyncEntityType,
        identity: String,
        operation: CloudSyncOperation,
        revision: Int64,
        parentSemanticDigest: String?,
        modifiedAt: Date = Date()
    ) throws -> CloudSyncEnvelope {
        guard (revision == 1 && parentSemanticDigest == nil)
                || (revision > 1 && parentSemanticDigest?.isEmpty == false) else {
            throw CloudSyncValidationError.invalidLineage
        }
        let recordName = try canonicalRecordName(entityType: entityType, identity: identity)
        guard (operation == .upsert && payload?.entityType == entityType
                && payload?.identity == identity)
                || (operation == .tombstone && payload == nil) else {
            throw CloudSyncValidationError.invalidPayload
        }
        let document = CloudSyncSemanticDocument(
            recordName: recordName,
            entityType: entityType,
            operation: operation,
            payload: payload
        )
        let digest = digestHex(try encodeCanonical(document))
        return CloudSyncEnvelope(
            schemaVersion: CloudSyncEnvelope.currentSchemaVersion,
            recordName: recordName,
            entityType: entityType,
            operation: operation,
            revision: revision,
            modifiedAt: modifiedAt.cloudSyncBits,
            parentSemanticDigest: parentSemanticDigest,
            semanticDigest: digest,
            payload: payload
        )
    }

    static func encodeEnvelope(_ envelope: CloudSyncEnvelope) throws -> Data {
        let data = try encodeCanonical(envelope)
        guard data.count <= CloudSyncEnvelope.maximumEncodedSize else {
            throw CloudSyncValidationError.payloadTooLarge
        }
        return data
    }

    static func decodeEnvelope(_ data: Data) throws -> CloudSyncEnvelope {
        guard !data.isEmpty, data.count <= CloudSyncEnvelope.maximumEncodedSize else {
            throw CloudSyncValidationError.payloadTooLarge
        }
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw CloudSyncValidationError.malformedEnvelope
        }
        let requiredKeys: Set<String> = [
            "schemaVersion", "recordName", "entityType", "operation", "revision", "modifiedAt",
            "semanticDigest"
        ]
        let optionalKeys: Set<String> = ["parentSemanticDigest", "payload"]
        guard requiredKeys.isSubset(of: dictionary.keys),
              Set(dictionary.keys).subtracting(requiredKeys).isSubset(of: optionalKeys) else {
            throw CloudSyncValidationError.malformedEnvelope
        }
        let envelope = try JSONDecoder().decode(CloudSyncEnvelope.self, from: data)
        try validate(envelope)
        // The app emits one canonical representation. Requiring an exact round trip rejects
        // unknown nested keys, duplicate-key parser ambiguity, alternate number spellings, and
        // noncanonical key ordering before any remote fact can reach the DataActor.
        guard try encodeEnvelope(envelope) == data else {
            throw CloudSyncValidationError.malformedEnvelope
        }
        return envelope
    }

    static func validate(_ envelope: CloudSyncEnvelope) throws {
        guard envelope.schemaVersion == CloudSyncEnvelope.currentSchemaVersion else {
            throw CloudSyncValidationError.unsupportedSchema
        }
        let recordIdentity: String
        if let payloadIdentity = envelope.payload?.identity {
            recordIdentity = payloadIdentity
        } else {
            recordIdentity = try identity(from: envelope.recordName)
        }
        let canonicalName = try canonicalRecordName(
            entityType: envelope.entityType,
            identity: recordIdentity
        )
        let payloadShapeIsValid = (envelope.operation == .upsert
            && envelope.payload?.entityType == envelope.entityType)
            || (envelope.operation == .tombstone && envelope.payload == nil)
        guard canonicalName == envelope.recordName,
              envelope.revision > 0,
              Date(cloudSyncBits: envelope.modifiedAt).timeIntervalSinceReferenceDate.isFinite,
              payloadShapeIsValid else {
            throw CloudSyncValidationError.invalidIdentity
        }
        let document = CloudSyncSemanticDocument(
            recordName: envelope.recordName,
            entityType: envelope.entityType,
            operation: envelope.operation,
            payload: envelope.payload
        )
        guard envelope.semanticDigest == digestHex(try encodeCanonical(document)) else {
            throw CloudSyncValidationError.invalidDigest
        }
        guard (envelope.revision == 1 && envelope.parentSemanticDigest == nil)
                || (envelope.revision > 1 && envelope.parentSemanticDigest?.isEmpty == false) else {
            throw CloudSyncValidationError.invalidLineage
        }
    }

    static func canonicalRecordName(
        entityType: CloudSyncEntityType,
        identity: String
    ) throws -> String {
        let canonicalIdentity: String
        if entityType == .recurringOccurrence {
            canonicalIdentity = try RecurringOccurrenceKey(rawValue: identity).rawValue
        } else {
            guard identity == identity.lowercased(),
                  let identifier = UUID(uuidString: identity),
                  identifier.uuidString.lowercased() == identity else {
                throw CloudSyncValidationError.invalidIdentity
            }
            canonicalIdentity = identity
        }
        return "\(entityType.rawValue)/\(canonicalIdentity)"
    }

    static func identity(from recordName: String) throws -> String {
        guard let separator = recordName.firstIndex(of: "/"),
              !recordName[recordName.index(after: separator)...].contains("/") else {
            throw CloudSyncValidationError.invalidIdentity
        }
        return String(recordName[recordName.index(after: separator)...])
    }

    static func digestHex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func encodeCanonical<Value: Encodable>(_ value: Value) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }
}

struct CloudSyncPendingRecord: Equatable, Sendable {
    let recordName: String
    let envelopeData: Data
    let encodedSystemFields: Data?
}

struct CloudSyncRemoteRecord: Equatable, Sendable {
    let recordName: String
    let envelopeData: Data?
    let encodedSystemFields: Data?
    let wasPhysicallyDeleted: Bool
}

extension Date {
    var cloudSyncBits: UInt64 { timeIntervalSinceReferenceDate.bitPattern }

    init(cloudSyncBits: UInt64) {
        self.init(timeIntervalSinceReferenceDate: TimeInterval(bitPattern: cloudSyncBits))
    }
}
