import Foundation
import SwiftData

/// Schema V6 keeps custom-record synchronization metadata beside, but separate from, the
/// authoritative local facts. None of these rows is a financial authority and none is mirrored by
/// SwiftData: CloudKit transport is owned explicitly by the C4B adapter.
@Model
final class CloudSyncControl {
    @Attribute(.unique) var id: String
    var isEnabled: Bool
    var statusRaw: String
    var accountIdentifierHash: String?
    var consentVersion: Int
    var lastReasonRaw: String?
    var updatedAt: Date

    init(
        id: String,
        isEnabled: Bool,
        statusRaw: String,
        accountIdentifierHash: String?,
        consentVersion: Int,
        lastReasonRaw: String?,
        updatedAt: Date
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.statusRaw = statusRaw
        self.accountIdentifierHash = accountIdentifierHash
        self.consentVersion = consentVersion
        self.lastReasonRaw = lastReasonRaw
        self.updatedAt = updatedAt
    }
}

@Model
final class CloudSyncRecordMetadata {
    @Attribute(.unique) var recordName: String
    var entityTypeRaw: String
    var acceptedRevision: Int64
    var acceptedSemanticDigest: String?
    var acceptedOperationRaw: String?
    var encodedSystemFields: Data?
    var stateRaw: String
    var updatedAt: Date

    init(
        recordName: String,
        entityTypeRaw: String,
        acceptedRevision: Int64,
        acceptedSemanticDigest: String?,
        acceptedOperationRaw: String?,
        encodedSystemFields: Data?,
        stateRaw: String,
        updatedAt: Date
    ) {
        self.recordName = recordName
        self.entityTypeRaw = entityTypeRaw
        self.acceptedRevision = acceptedRevision
        self.acceptedSemanticDigest = acceptedSemanticDigest
        self.acceptedOperationRaw = acceptedOperationRaw
        self.encodedSystemFields = encodedSystemFields
        self.stateRaw = stateRaw
        self.updatedAt = updatedAt
    }
}

@Model
final class CloudSyncOutboxItem {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var recordName: String
    var entityTypeRaw: String
    var envelopeData: Data
    var semanticDigest: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    var attemptCount: Int

    init(
        id: UUID,
        recordName: String,
        entityTypeRaw: String,
        envelopeData: Data,
        semanticDigest: String,
        statusRaw: String,
        createdAt: Date,
        updatedAt: Date,
        attemptCount: Int
    ) {
        self.id = id
        self.recordName = recordName
        self.entityTypeRaw = entityTypeRaw
        self.envelopeData = envelopeData
        self.semanticDigest = semanticDigest
        self.statusRaw = statusRaw
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.attemptCount = attemptCount
    }
}

@Model
final class CloudSyncInboxItem {
    @Attribute(.unique) var id: UUID
    var recordName: String
    var envelopeData: Data?
    var encodedSystemFields: Data?
    var statusRaw: String
    var reasonRaw: String?
    var receivedAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        recordName: String,
        envelopeData: Data?,
        encodedSystemFields: Data?,
        statusRaw: String,
        reasonRaw: String?,
        receivedAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.recordName = recordName
        self.envelopeData = envelopeData
        self.encodedSystemFields = encodedSystemFields
        self.statusRaw = statusRaw
        self.reasonRaw = reasonRaw
        self.receivedAt = receivedAt
        self.updatedAt = updatedAt
    }
}

@Model
final class CloudSyncEngineState {
    @Attribute(.unique) var id: String
    var serializationData: Data
    var updatedAt: Date

    init(id: String, serializationData: Data, updatedAt: Date) {
        self.id = id
        self.serializationData = serializationData
        self.updatedAt = updatedAt
    }
}
