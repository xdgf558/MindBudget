import CryptoKit
import Foundation

enum PreDFrozenCloudSyncLocalChangeSignal {
    static let notification = Notification.Name("MindBudget.PreDFrozenCloudSyncLocalChange")

    static func post() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}

enum PreDFrozenCloudSyncRemoteApplicationSignal {
    static let notification = Notification.Name("MindBudget.PreDFrozenCloudSyncRemoteApplication")

    static func post() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}

enum PreDFrozenCloudSyncEntityType: String, Codable, CaseIterable, Sendable {
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

    static let applicationOrder: [PreDFrozenCloudSyncEntityType] = [
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

enum PreDFrozenCloudSyncOperation: String, Codable, Sendable {
    case upsert
    case tombstone
}

enum PreDFrozenCloudSyncStatus: String, Codable, Equatable, Sendable {
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

enum PreDFrozenCloudSyncRecordState: String, Codable, Sendable {
    case accepted
    case pending
    case conflicted
}

enum PreDFrozenCloudSyncOutboxStatus: String, Codable, Sendable {
    case pending
    case blockedByConflict
}

enum PreDFrozenCloudSyncInboxStatus: String, Codable, Sendable {
    case pending
    case applied
    case quarantined
}

enum PreDFrozenCloudSyncReasonCode: String, Codable, Equatable, Sendable {
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

struct PreDFrozenCloudSyncSnapshot: Equatable, Sendable {
    let isEnabled: Bool
    let status: PreDFrozenCloudSyncStatus
    let reason: PreDFrozenCloudSyncReasonCode?
    let pendingCount: Int
    let quarantinedCount: Int
    let cloudCopyMayExist: Bool

    init(
        isEnabled: Bool,
        status: PreDFrozenCloudSyncStatus,
        reason: PreDFrozenCloudSyncReasonCode?,
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

    static let disabled = PreDFrozenCloudSyncSnapshot(
        isEnabled: false,
        status: .disabled,
        reason: nil,
        pendingCount: 0,
        quarantinedCount: 0,
        cloudCopyMayExist: false
    )
}

enum PreDFrozenCloudSyncConflictResolution: Equatable, Sendable {
    case keepLocal
    case useCloud
}

struct PreDFrozenCloudSyncConflictSummary: Identifiable, Equatable, Sendable {
    var id: String { recordName }

    let recordName: String
    let entityType: PreDFrozenCloudSyncEntityType?
    let reason: PreDFrozenCloudSyncReasonCode
    let localOperation: PreDFrozenCloudSyncOperation?
    let cloudOperation: PreDFrozenCloudSyncOperation?
    let canResolve: Bool
}

enum PreDFrozenCloudSyncCloudDeletionOutcome: Equatable, Sendable {
    case deleted
    case pending(PreDFrozenCloudSyncReasonCode)
    case failed(PreDFrozenCloudSyncReasonCode)
}

enum PreDFrozenCloudSyncTrustBoundaryRecovery: Equatable, Sendable {
    /// Explicitly accepts this device's current local facts as the source for a newly created
    /// private zone after an account switch, encrypted-key reset, or externally deleted zone.
    case rebuildCloudFromLocal
}

/// Closed recurring identity shared by the recurrence engine and CloudKit record-name builder.
/// Caller-supplied arbitrary strings never become record names.
struct PreDFrozenRecurringOccurrenceKey: Equatable, Hashable, Sendable {
    let ruleID: UUID
    let year: Int
    let month: Int

    var rawValue: String {
        "\(ruleID.uuidString.lowercased()):\(year)-\(String(format: "%02d", month))"
    }

    init(ruleID: UUID, year: Int, month: Int) throws {
        guard (1...12).contains(month) else {
            throw PreDFrozenCloudSyncValidationError.invalidIdentity
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
            throw PreDFrozenCloudSyncValidationError.invalidIdentity
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
            throw PreDFrozenCloudSyncValidationError.invalidIdentity
        }
        self.ruleID = ruleID
        self.year = year
        self.month = month
    }
}

enum PreDFrozenCloudSyncValidationError: Error, Equatable, Sendable {
    case payloadTooLarge
    case malformedEnvelope
    case unsupportedSchema
    case invalidIdentity
    case invalidDigest
    case invalidLineage
    case invalidPayload
}

struct PreDFrozenCloudSyncValue: Codable, Equatable, Sendable {
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

    static func string(_ value: String) -> PreDFrozenCloudSyncValue {
        PreDFrozenCloudSyncValue(
            kind: .string,
            stringValue: value,
            integerValue: nil,
            unsignedValue: nil,
            booleanValue: nil
        )
    }

    static func integer(_ value: Int64) -> PreDFrozenCloudSyncValue {
        PreDFrozenCloudSyncValue(
            kind: .integer,
            stringValue: nil,
            integerValue: value,
            unsignedValue: nil,
            booleanValue: nil
        )
    }

    static func unsigned(_ value: UInt64) -> PreDFrozenCloudSyncValue {
        PreDFrozenCloudSyncValue(
            kind: .unsigned,
            stringValue: nil,
            integerValue: nil,
            unsignedValue: value,
            booleanValue: nil
        )
    }

    static func boolean(_ value: Bool) -> PreDFrozenCloudSyncValue {
        PreDFrozenCloudSyncValue(
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

struct PreDFrozenCloudSyncPayload: Codable, Equatable, Sendable {
    let entityType: PreDFrozenCloudSyncEntityType
    let identity: String
    let fields: [String: PreDFrozenCloudSyncValue]
}

struct PreDFrozenCloudSyncEnvelope: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let maximumEncodedSize = 512 * 1_024

    let schemaVersion: Int
    let recordName: String
    let entityType: PreDFrozenCloudSyncEntityType
    let operation: PreDFrozenCloudSyncOperation
    let revision: Int64
    /// Informational authoring instant carried inside the encrypted envelope. It is covered by
    /// canonical encoding but never participates in conflict winner selection.
    let modifiedAt: UInt64
    let parentSemanticDigest: String?
    let semanticDigest: String
    let payload: PreDFrozenCloudSyncPayload?
}

private struct PreDFrozenCloudSyncSemanticDocument: Codable {
    let recordName: String
    let entityType: PreDFrozenCloudSyncEntityType
    let operation: PreDFrozenCloudSyncOperation
    let payload: PreDFrozenCloudSyncPayload?
}

enum PreDFrozenCloudSyncCodec {
    /// Advances lineage without allowing a corrupted/private record at `Int64.max` to trap the
    /// process. Exhausted ancestry is invalid and stays quarantined rather than wrapping or
    /// inventing another revision.
    static func nextRevision(after revision: Int64) throws -> Int64 {
        guard revision >= 0 else { throw PreDFrozenCloudSyncValidationError.invalidLineage }
        let (next, overflow) = revision.addingReportingOverflow(1)
        guard !overflow, next > 0 else { throw PreDFrozenCloudSyncValidationError.invalidLineage }
        return next
    }

    static func makeEnvelope(
        payload: PreDFrozenCloudSyncPayload?,
        entityType: PreDFrozenCloudSyncEntityType,
        identity: String,
        operation: PreDFrozenCloudSyncOperation,
        revision: Int64,
        parentSemanticDigest: String?,
        modifiedAt: Date = Date()
    ) throws -> PreDFrozenCloudSyncEnvelope {
        guard (revision == 1 && parentSemanticDigest == nil)
                || (revision > 1 && parentSemanticDigest?.isEmpty == false) else {
            throw PreDFrozenCloudSyncValidationError.invalidLineage
        }
        let recordName = try canonicalRecordName(entityType: entityType, identity: identity)
        guard (operation == .upsert && payload?.entityType == entityType
                && payload?.identity == identity)
                || (operation == .tombstone && payload == nil) else {
            throw PreDFrozenCloudSyncValidationError.invalidPayload
        }
        let document = PreDFrozenCloudSyncSemanticDocument(
            recordName: recordName,
            entityType: entityType,
            operation: operation,
            payload: payload
        )
        let digest = digestHex(try encodeCanonical(document))
        return PreDFrozenCloudSyncEnvelope(
            schemaVersion: PreDFrozenCloudSyncEnvelope.currentSchemaVersion,
            recordName: recordName,
            entityType: entityType,
            operation: operation,
            revision: revision,
            modifiedAt: modifiedAt.preDFrozenCloudSyncBits,
            parentSemanticDigest: parentSemanticDigest,
            semanticDigest: digest,
            payload: payload
        )
    }

    static func encodeEnvelope(_ envelope: PreDFrozenCloudSyncEnvelope) throws -> Data {
        let data = try encodeCanonical(envelope)
        guard data.count <= PreDFrozenCloudSyncEnvelope.maximumEncodedSize else {
            throw PreDFrozenCloudSyncValidationError.payloadTooLarge
        }
        return data
    }

    static func decodeEnvelope(_ data: Data) throws -> PreDFrozenCloudSyncEnvelope {
        guard !data.isEmpty, data.count <= PreDFrozenCloudSyncEnvelope.maximumEncodedSize else {
            throw PreDFrozenCloudSyncValidationError.payloadTooLarge
        }
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw PreDFrozenCloudSyncValidationError.malformedEnvelope
        }
        let requiredKeys: Set<String> = [
            "schemaVersion", "recordName", "entityType", "operation", "revision", "modifiedAt",
            "semanticDigest"
        ]
        let optionalKeys: Set<String> = ["parentSemanticDigest", "payload"]
        guard requiredKeys.isSubset(of: dictionary.keys),
              Set(dictionary.keys).subtracting(requiredKeys).isSubset(of: optionalKeys) else {
            throw PreDFrozenCloudSyncValidationError.malformedEnvelope
        }
        let envelope = try JSONDecoder().decode(PreDFrozenCloudSyncEnvelope.self, from: data)
        try validate(envelope)
        // The app emits one canonical representation. Requiring an exact round trip rejects
        // unknown nested keys, duplicate-key parser ambiguity, alternate number spellings, and
        // noncanonical key ordering before any remote fact can reach the DataActor.
        guard try encodeEnvelope(envelope) == data else {
            throw PreDFrozenCloudSyncValidationError.malformedEnvelope
        }
        return envelope
    }

    static func validate(_ envelope: PreDFrozenCloudSyncEnvelope) throws {
        guard envelope.schemaVersion == PreDFrozenCloudSyncEnvelope.currentSchemaVersion else {
            throw PreDFrozenCloudSyncValidationError.unsupportedSchema
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
              Date(preDFrozenCloudSyncBits: envelope.modifiedAt).timeIntervalSinceReferenceDate.isFinite,
              payloadShapeIsValid else {
            throw PreDFrozenCloudSyncValidationError.invalidIdentity
        }
        let document = PreDFrozenCloudSyncSemanticDocument(
            recordName: envelope.recordName,
            entityType: envelope.entityType,
            operation: envelope.operation,
            payload: envelope.payload
        )
        guard envelope.semanticDigest == digestHex(try encodeCanonical(document)) else {
            throw PreDFrozenCloudSyncValidationError.invalidDigest
        }
        guard (envelope.revision == 1 && envelope.parentSemanticDigest == nil)
                || (envelope.revision > 1 && envelope.parentSemanticDigest?.isEmpty == false) else {
            throw PreDFrozenCloudSyncValidationError.invalidLineage
        }
    }

    static func canonicalRecordName(
        entityType: PreDFrozenCloudSyncEntityType,
        identity: String
    ) throws -> String {
        let canonicalIdentity: String
        if entityType == .recurringOccurrence {
            canonicalIdentity = try PreDFrozenRecurringOccurrenceKey(rawValue: identity).rawValue
        } else {
            guard identity == identity.lowercased(),
                  let identifier = UUID(uuidString: identity),
                  identifier.uuidString.lowercased() == identity else {
                throw PreDFrozenCloudSyncValidationError.invalidIdentity
            }
            canonicalIdentity = identity
        }
        return "\(entityType.rawValue)/\(canonicalIdentity)"
    }

    static func identity(from recordName: String) throws -> String {
        guard let separator = recordName.firstIndex(of: "/"),
              !recordName[recordName.index(after: separator)...].contains("/") else {
            throw PreDFrozenCloudSyncValidationError.invalidIdentity
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

struct PreDFrozenCloudSyncPendingRecord: Equatable, Sendable {
    let recordName: String
    let envelopeData: Data
    let encodedSystemFields: Data?
}

struct PreDFrozenCloudSyncRemoteRecord: Equatable, Sendable {
    let recordName: String
    let envelopeData: Data?
    let encodedSystemFields: Data?
    let wasPhysicallyDeleted: Bool
}

extension Date {
    var preDFrozenCloudSyncBits: UInt64 { timeIntervalSinceReferenceDate.bitPattern }

    init(preDFrozenCloudSyncBits: UInt64) {
        self.init(timeIntervalSinceReferenceDate: TimeInterval(bitPattern: preDFrozenCloudSyncBits))
    }
}
