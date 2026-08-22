import Foundation
import SwiftData

private struct CloudSyncMutationProjection {
    let entityType: CloudSyncEntityType
    let identity: String
    let operation: CloudSyncOperation
    let payload: CloudSyncPayload?

    var recordName: String {
        get throws {
            try CloudSyncCodec.canonicalRecordName(entityType: entityType, identity: identity)
        }
    }
}

enum CloudSyncApplicationError: Error {
    case missingParent
    case invalidPayload
    case validationFailed
    case divergentConflict
}

extension DataActor {
    private static var cloudSyncControlID: String { "primary" }
    private static var cloudSyncEngineStateID: String { "private-zone-v1" }
    private static var cloudSyncConsentVersion: Int { 1 }

    func cloudSyncSnapshot() throws -> CloudSyncSnapshot {
        let control = try fetchCloudSyncControl()
        let pendingOutboxNames = Set(try modelContext.fetch(
            FetchDescriptor<CloudSyncOutboxItem>(
                predicate: #Predicate { $0.statusRaw == "pending" }
            )
        ).map(\.recordName))
        let pendingInboxNames = Set(try modelContext.fetch(
            FetchDescriptor<CloudSyncInboxItem>(
                predicate: #Predicate { $0.statusRaw == "pending" }
            )
        ).map(\.recordName))
        let quarantinedNames = Set(try modelContext.fetch(
            FetchDescriptor<CloudSyncInboxItem>(
                predicate: #Predicate { $0.statusRaw == "quarantined" }
            )
        ).map(\.recordName))
        let pendingCount = pendingOutboxNames.union(pendingInboxNames).count
        let quarantinedCount = quarantinedNames.count
        guard let control else {
            return CloudSyncSnapshot(
                isEnabled: false,
                status: .disabled,
                reason: nil,
                pendingCount: pendingCount,
                quarantinedCount: quarantinedCount
            )
        }
        return CloudSyncSnapshot(
            isEnabled: control.isEnabled,
            status: CloudSyncStatus(rawValue: control.statusRaw) ?? .failed,
            reason: control.lastReasonRaw.flatMap(CloudSyncReasonCode.init(rawValue:)),
            pendingCount: pendingCount,
            quarantinedCount: quarantinedCount
        )
    }

    @discardableResult
    func setCloudSyncEnabled(_ enabled: Bool, at date: Date = Date()) throws -> CloudSyncSnapshot {
        do {
            let existingControl = try fetchCloudSyncControl()
            let control = existingControl ?? CloudSyncControl(
                id: Self.cloudSyncControlID,
                isEnabled: false,
                statusRaw: CloudSyncStatus.disabled.rawValue,
                accountIdentifierHash: nil,
                consentVersion: Self.cloudSyncConsentVersion,
                lastReasonRaw: nil,
                updatedAt: date
            )
            let wasPausedForAccountChange = control.statusRaw == CloudSyncStatus.pausedAccountChanged.rawValue
            let wasPausedForEncryptedDataReset =
                control.statusRaw == CloudSyncStatus.pausedEncryptedDataReset.rawValue
                    || control.lastReasonRaw == CloudSyncReasonCode.encryptedDataReset.rawValue
            let wasPausedForRemoteZoneDeletion =
                control.statusRaw == CloudSyncStatus.pausedRemoteZoneDeleted.rawValue
                    || control.lastReasonRaw == CloudSyncReasonCode.remoteZoneDeleted.rawValue
            let isDeletingCloudData =
                control.statusRaw == CloudSyncStatus.deletingCloudData.rawValue
            if existingControl == nil {
                modelContext.insert(control)
            }
            // Cloud-wide deletion is a durable privacy operation. A generic enable/disable tap
            // cannot turn it back into ordinary sync or silently abandon the pending zone delete.
            if isDeletingCloudData {
                return try cloudSyncSnapshot()
            }
            // An encrypted-key reset needs a separately accepted recovery decision owned by
            // C4B-03. The generic enable disclosure must never silently purge or reupload data.
            if enabled, wasPausedForEncryptedDataReset {
                control.isEnabled = false
                control.statusRaw = CloudSyncStatus.pausedEncryptedDataReset.rawValue
                control.lastReasonRaw = CloudSyncReasonCode.encryptedDataReset.rawValue
                control.updatedAt = date
                try modelContext.save()
                return try cloudSyncSnapshot()
            }
            if !enabled, wasPausedForEncryptedDataReset {
                control.isEnabled = false
                control.statusRaw = CloudSyncStatus.pausedEncryptedDataReset.rawValue
                control.lastReasonRaw = CloudSyncReasonCode.encryptedDataReset.rawValue
                control.updatedAt = date
                try modelContext.save()
                return try cloudSyncSnapshot()
            }
            // A zone deleted outside the not-yet-implemented C4B-03 cloud-delete flow is not an
            // empty server to repopulate. Keep the pause sticky so generic disable/re-enable cannot
            // recreate the zone and upload the local ledger without an accepted recovery choice.
            if wasPausedForRemoteZoneDeletion {
                control.isEnabled = false
                control.statusRaw = CloudSyncStatus.pausedRemoteZoneDeleted.rawValue
                control.lastReasonRaw = CloudSyncReasonCode.remoteZoneDeleted.rawValue
                control.updatedAt = date
                try modelContext.save()
                return try cloudSyncSnapshot()
            }
            control.isEnabled = enabled
            control.consentVersion = Self.cloudSyncConsentVersion
            control.statusRaw = enabled ? CloudSyncStatus.starting.rawValue : CloudSyncStatus.disabled.rawValue
            control.lastReasonRaw = nil
            // Ordinary disable preserves the accepted account and transport ancestry so a same-
            // account resume cannot accidentally rebase history. After an observed account
            // change, disable is the first half of the explicit disable + disclosure + re-enable
            // consent boundary: account-scoped transport state is discarded, while local facts
            // remain authoritative and are restaged as genesis only after the new consent.
            if !enabled, wasPausedForAccountChange {
                try deleteCloudSyncAccountScopedState()
                control.accountIdentifierHash = nil
            }
            control.updatedAt = date
            if enabled {
                modelContext.processPendingChanges()
                _ = try stageAllCurrentFacts(at: date)
            }
            try modelContext.save()
            if enabled { CloudSyncLocalChangeSignal.post() }
            return try cloudSyncSnapshot()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func bindCloudSyncAccount(identifierHash: String, at date: Date = Date()) throws -> Bool {
        guard !identifierHash.isEmpty, let control = try fetchCloudSyncControl(), control.isEnabled else {
            return false
        }
        if (CloudSyncStatus(rawValue: control.statusRaw) ?? .failed).isStickyPause {
            return false
        }
        if let accepted = control.accountIdentifierHash, accepted != identifierHash {
            let isDeletingCloudData =
                control.statusRaw == CloudSyncStatus.deletingCloudData.rawValue
            if !isDeletingCloudData {
                control.statusRaw = CloudSyncStatus.pausedAccountChanged.rawValue
            }
            control.lastReasonRaw = CloudSyncReasonCode.accountChanged.rawValue
            control.updatedAt = date
            try modelContext.save()
            return false
        }
        control.accountIdentifierHash = identifierHash
        if control.statusRaw != CloudSyncStatus.deletingCloudData.rawValue {
            control.statusRaw = CloudSyncStatus.ready.rawValue
            control.lastReasonRaw = nil
        }
        control.updatedAt = date
        try modelContext.save()
        return true
    }

    func updateCloudSyncStatus(
        _ status: CloudSyncStatus,
        reason: CloudSyncReasonCode?,
        at date: Date = Date()
    ) throws {
        guard let control = try fetchCloudSyncControl() else { return }
        let currentStatus = CloudSyncStatus(rawValue: control.statusRaw) ?? .failed
        // A sticky pause is a trust-boundary transition. Ordinary network/account callbacks can
        // arrive late, but they may neither downgrade it to a retryable state nor replace one
        // sticky cause with another. C4B-03 will own any explicit recovery transition.
        if currentStatus.isStickyPause {
            return
        }
        if currentStatus == .deletingCloudData, status != .deletingCloudData {
            return
        }
        control.statusRaw = status.rawValue
        control.lastReasonRaw = reason?.rawValue
        control.updatedAt = date
        try modelContext.save()
    }

    /// Begins the separately confirmed cloud-wide deletion operation. The local ledger remains
    /// available; durable logical tombstones record the person's deletion intent before any
    /// CloudKit call, and the accepted custom zone is the final privacy deletion boundary.
    func beginCloudDeletion(at date: Date = Date()) throws -> CloudSyncSnapshot {
        do {
            let existingControl = try fetchCloudSyncControl()
            let control = existingControl ?? CloudSyncControl(
                id: Self.cloudSyncControlID,
                isEnabled: true,
                statusRaw: CloudSyncStatus.deletingCloudData.rawValue,
                accountIdentifierHash: nil,
                consentVersion: Self.cloudSyncConsentVersion,
                lastReasonRaw: nil,
                updatedAt: date
            )
            if existingControl == nil { modelContext.insert(control) }
            control.isEnabled = true
            control.statusRaw = CloudSyncStatus.deletingCloudData.rawValue
            control.lastReasonRaw = nil
            control.updatedAt = date
            modelContext.processPendingChanges()
            _ = try stageAllCloudTombstones(at: date)
            try modelContext.save()
            CloudSyncLocalChangeSignal.post()
            return try cloudSyncSnapshot()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func cloudDeletionIsPending() throws -> Bool {
        try fetchCloudSyncControl()?.statusRaw == CloudSyncStatus.deletingCloudData.rawValue
    }

    /// Transport failures during a cloud delete remain reasons attached to the durable deletion
    /// state. They may never replace it with an ordinary retry state that could recreate the zone.
    func updateCloudDeletionReason(
        _ reason: CloudSyncReasonCode,
        at date: Date = Date()
    ) throws {
        guard let control = try fetchCloudSyncControl(),
              control.statusRaw == CloudSyncStatus.deletingCloudData.rawValue else { return }
        control.lastReasonRaw = reason.rawValue
        control.updatedAt = date
        try modelContext.save()
    }

    /// Called only after CloudKit confirms that the entire accepted private zone is absent. It
    /// clears transport ancestry and disables sync while preserving every local business fact.
    func completeCloudDeletion(at date: Date = Date()) throws {
        guard let control = try fetchCloudSyncControl(),
              control.statusRaw == CloudSyncStatus.deletingCloudData.rawValue else { return }
        try deleteCloudSyncAccountScopedState()
        control.isEnabled = false
        control.statusRaw = CloudSyncStatus.disabled.rawValue
        control.accountIdentifierHash = nil
        control.lastReasonRaw = nil
        control.updatedAt = date
        try modelContext.save()
    }

    /// A sticky trust-boundary pause is cleared only by this explicit C4B-03 decision. Generic
    /// retry/enable remains incapable of reuploading. The current local ledger is staged as a new
    /// genesis only after the person confirms rebuilding the private cloud copy.
    func recoverCloudSyncFromLocalAuthority(at date: Date = Date()) throws -> CloudSyncSnapshot {
        do {
            guard let control = try fetchCloudSyncControl(),
                  (CloudSyncStatus(rawValue: control.statusRaw) ?? .failed).isStickyPause else {
                return try cloudSyncSnapshot()
            }
            try deleteCloudSyncAccountScopedState()
            control.isEnabled = true
            control.statusRaw = CloudSyncStatus.starting.rawValue
            control.accountIdentifierHash = nil
            control.lastReasonRaw = nil
            control.consentVersion = Self.cloudSyncConsentVersion
            control.updatedAt = date
            modelContext.processPendingChanges()
            _ = try stageAllCurrentFacts(at: date)
            try modelContext.save()
            CloudSyncLocalChangeSignal.post()
            return try cloudSyncSnapshot()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// A successful transport pass may finish after an account/key-reset event was delivered.
    /// Never let that older success overwrite a newer fail-closed pause or transport reason.
    func completeCloudSyncPass(at date: Date = Date()) throws {
        guard let control = try fetchCloudSyncControl(), control.isEnabled,
              control.statusRaw == CloudSyncStatus.syncing.rawValue else {
            return
        }
        control.statusRaw = CloudSyncStatus.ready.rawValue
        control.lastReasonRaw = nil
        control.updatedAt = date
        try modelContext.save()
    }

    /// Save-if-unchanged failures are content conflicts, not retryable transport errors. The
    /// durable outbox remains available for C4B-03 resolution but leaves the send queue now.
    func blockCloudSyncRecordAfterServerConflict(
        recordName: String,
        at date: Date = Date()
    ) throws {
        if let outbox = try fetchCloudSyncOutbox(recordName: recordName) {
            outbox.statusRaw = CloudSyncOutboxStatus.blockedByConflict.rawValue
            outbox.updatedAt = date
        }
        if let metadata = try fetchCloudSyncMetadata(recordName: recordName) {
            metadata.stateRaw = CloudSyncRecordState.conflicted.rawValue
            metadata.updatedAt = date
        }
        try modelContext.save()
    }

    func cloudSyncEngineStateData() throws -> Data? {
        var descriptor = FetchDescriptor<CloudSyncEngineState>(
            predicate: #Predicate { $0.id == "private-zone-v1" }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.serializationData
    }

    func saveCloudSyncEngineState(_ data: Data, at date: Date = Date()) throws {
        var descriptor = FetchDescriptor<CloudSyncEngineState>(
            predicate: #Predicate { $0.id == "private-zone-v1" }
        )
        descriptor.fetchLimit = 1
        if let state = try modelContext.fetch(descriptor).first {
            state.serializationData = data
            state.updatedAt = date
        } else {
            modelContext.insert(
                CloudSyncEngineState(
                    id: Self.cloudSyncEngineStateID,
                    serializationData: data,
                    updatedAt: date
                )
            )
        }
        try modelContext.save()
    }

    func pendingCloudSyncRecordNames() throws -> [String] {
        try modelContext.fetch(
            FetchDescriptor<CloudSyncOutboxItem>(
                predicate: #Predicate { $0.statusRaw == "pending" },
                sortBy: [
                    SortDescriptor(\CloudSyncOutboxItem.createdAt),
                    SortDescriptor(\CloudSyncOutboxItem.recordName)
                ]
            )
        ).map(\.recordName)
    }

    func pendingCloudSyncRecord(named recordName: String) throws -> CloudSyncPendingRecord? {
        guard let outbox = try fetchCloudSyncOutbox(recordName: recordName),
              outbox.statusRaw == CloudSyncOutboxStatus.pending.rawValue else {
            return nil
        }
        let metadata = try fetchCloudSyncMetadata(recordName: recordName)
        return CloudSyncPendingRecord(
            recordName: recordName,
            envelopeData: outbox.envelopeData,
            encodedSystemFields: metadata?.encodedSystemFields
        )
    }

    func acknowledgeCloudSyncRecord(
        recordName: String,
        encodedSystemFields: Data,
        at date: Date = Date()
    ) throws {
        guard let outbox = try fetchCloudSyncOutbox(recordName: recordName),
              let envelope = try? CloudSyncCodec.decodeEnvelope(outbox.envelopeData) else {
            return
        }
        let existingMetadata = try fetchCloudSyncMetadata(recordName: recordName)
        let metadata = existingMetadata ?? CloudSyncRecordMetadata(
            recordName: recordName,
            entityTypeRaw: envelope.entityType.rawValue,
            acceptedRevision: 0,
            acceptedSemanticDigest: nil,
            acceptedOperationRaw: nil,
            encodedSystemFields: nil,
            stateRaw: CloudSyncRecordState.pending.rawValue,
            updatedAt: date
        )
        if existingMetadata == nil { modelContext.insert(metadata) }
        metadata.acceptedRevision = envelope.revision
        metadata.acceptedSemanticDigest = envelope.semanticDigest
        metadata.acceptedOperationRaw = envelope.operation.rawValue
        metadata.encodedSystemFields = encodedSystemFields
        metadata.stateRaw = CloudSyncRecordState.accepted.rawValue
        metadata.updatedAt = date
        modelContext.delete(outbox)
        try modelContext.save()
    }

    /// Delegate changes are persisted before any business fact is considered. A crash after this
    /// save replays the inbox; it cannot lose a fetched server change or partially mutate a fact.
    func ingestCloudSyncRecords(
        _ records: [CloudSyncRemoteRecord],
        receivedAt: Date = Date()
    ) throws {
        guard let control = try fetchCloudSyncControl(), control.isEnabled else { return }
        do {
            for record in records {
                let status: CloudSyncInboxStatus = record.wasPhysicallyDeleted ? .quarantined : .pending
                if record.wasPhysicallyDeleted {
                    if let outbox = try fetchCloudSyncOutbox(recordName: record.recordName) {
                        outbox.statusRaw = CloudSyncOutboxStatus.blockedByConflict.rawValue
                        outbox.updatedAt = receivedAt
                    }
                    if let metadata = try fetchCloudSyncMetadata(recordName: record.recordName) {
                        metadata.stateRaw = CloudSyncRecordState.conflicted.rawValue
                        metadata.updatedAt = receivedAt
                    }
                }
                modelContext.insert(
                    CloudSyncInboxItem(
                        id: UUID(),
                        recordName: record.recordName,
                        envelopeData: record.envelopeData,
                        encodedSystemFields: record.encodedSystemFields,
                        statusRaw: status.rawValue,
                        reasonRaw: record.wasPhysicallyDeleted
                            ? CloudSyncReasonCode.physicalDeletion.rawValue
                            : nil,
                        receivedAt: receivedAt,
                        updatedAt: receivedAt
                    )
                )
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
        try applyPendingCloudSyncInbox(at: receivedAt)
    }

    func stageCloudSyncChangesFromCurrentContext() throws -> Bool {
        guard !isApplyingCloudSyncMutation,
              let control = try fetchCloudSyncControl(),
              control.isEnabled else {
            return false
        }
        modelContext.processPendingChanges()
        var changesByRecordName: [String: CloudSyncMutationProjection] = [:]
        for model in modelContext.insertedModelsArray + modelContext.changedModelsArray {
            if let projection = try cloudSyncProjection(for: model, operation: .upsert) {
                changesByRecordName[try projection.recordName] = projection
            }
        }
        for model in modelContext.deletedModelsArray {
            if let projection = try cloudSyncProjection(for: model, operation: .tombstone) {
                changesByRecordName[try projection.recordName] = projection
            }
        }
        var staged = false
        for projection in changesByRecordName.values {
            staged = try stageCloudSyncProjection(projection, at: Date()) || staged
        }
        return staged
    }

    private func stageAllCurrentFacts(at date: Date) throws -> Bool {
        let models = try allCloudSyncBusinessModels()
        var staged = false
        for model in models {
            if let projection = try cloudSyncProjection(for: model, operation: .upsert) {
                staged = try stageCloudSyncProjection(projection, at: date) || staged
            }
        }
        return staged
    }

    private func stageAllCloudTombstones(at date: Date) throws -> Bool {
        var projections: [String: CloudSyncMutationProjection] = [:]
        for model in try allCloudSyncBusinessModels() {
            if let projection = try cloudSyncProjection(for: model, operation: .tombstone) {
                projections[try projection.recordName] = projection
            }
        }
        // A fact already deleted locally can still exist in the private zone. Retain every known
        // accepted/outbox identity in the deletion plan so the durable intent describes the full
        // local sync history before the zone itself is removed.
        let knownMetadata = try modelContext.fetch(FetchDescriptor<CloudSyncRecordMetadata>())
        for metadata in knownMetadata {
            guard projections[metadata.recordName] == nil,
                  let entityType = CloudSyncEntityType(rawValue: metadata.entityTypeRaw),
                  let identity = try? CloudSyncCodec.identity(from: metadata.recordName) else {
                continue
            }
            let projection = CloudSyncMutationProjection(
                entityType: entityType,
                identity: identity,
                operation: .tombstone,
                payload: nil
            )
            projections[metadata.recordName] = projection
        }

        var staged = false
        for projection in projections.values {
            let recordName = try projection.recordName
            staged = try stageCloudSyncProjection(projection, at: date) || staged
            // Global deletion is an explicit resolution of every per-record conflict. The zone
            // delete remains the final authority, but no previously blocked outbox may hide the
            // durable tombstone intent from the pending-operation surface.
            if let outbox = try fetchCloudSyncOutbox(recordName: recordName) {
                outbox.statusRaw = CloudSyncOutboxStatus.pending.rawValue
                outbox.updatedAt = date
            }
            if let metadata = try fetchCloudSyncMetadata(recordName: recordName) {
                metadata.stateRaw = CloudSyncRecordState.pending.rawValue
                metadata.updatedAt = date
            }
        }
        return staged
    }

    private func allCloudSyncBusinessModels() throws -> [any PersistentModel] {
        var models: [any PersistentModel] = []
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<Expense>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<Income>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<IncomeAllocation>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<SavingsGoal>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<RecurringFixedExpenseRule>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<RecurringExpenseOccurrence>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<BudgetPlan>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<BudgetPlanSemantics>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<CategoryBudget>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<WishItem>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<CoolingOffPlan>()))
        models.append(contentsOf: try modelContext.fetch(FetchDescriptor<ReflectionLog>()))
        return models
    }

    private func stageCloudSyncProjection(
        _ projection: CloudSyncMutationProjection,
        at date: Date
    ) throws -> Bool {
        let recordName = try projection.recordName
        let metadata = try fetchCloudSyncMetadata(recordName: recordName)
        let existingOutbox = try fetchCloudSyncOutbox(recordName: recordName)
        let existingEnvelope = try existingOutbox.map { try CloudSyncCodec.decodeEnvelope($0.envelopeData) }
        let revision = try existingEnvelope?.revision
            ?? CloudSyncCodec.nextRevision(after: metadata?.acceptedRevision ?? 0)
        let parent = existingEnvelope?.parentSemanticDigest ?? metadata?.acceptedSemanticDigest
        let envelope = try CloudSyncCodec.makeEnvelope(
            payload: projection.payload,
            entityType: projection.entityType,
            identity: projection.identity,
            operation: projection.operation,
            revision: revision,
            parentSemanticDigest: parent,
            modifiedAt: date
        )
        if metadata?.acceptedSemanticDigest == envelope.semanticDigest,
           metadata?.acceptedOperationRaw == envelope.operation.rawValue {
            if let existingOutbox { modelContext.delete(existingOutbox) }
            return existingOutbox != nil
        }
        let envelopeData = try CloudSyncCodec.encodeEnvelope(envelope)
        let resurrectsAcceptedTombstone = projection.operation == .upsert
            && metadata?.acceptedOperationRaw == CloudSyncOperation.tombstone.rawValue
        let status = metadata?.stateRaw == CloudSyncRecordState.conflicted.rawValue
            || resurrectsAcceptedTombstone
            ? CloudSyncOutboxStatus.blockedByConflict
            : CloudSyncOutboxStatus.pending
        if resurrectsAcceptedTombstone, let metadata {
            metadata.stateRaw = CloudSyncRecordState.conflicted.rawValue
            metadata.updatedAt = date
        }
        if let existingOutbox {
            existingOutbox.entityTypeRaw = projection.entityType.rawValue
            existingOutbox.envelopeData = envelopeData
            existingOutbox.semanticDigest = envelope.semanticDigest
            existingOutbox.statusRaw = status.rawValue
            existingOutbox.updatedAt = date
        } else {
            modelContext.insert(
                CloudSyncOutboxItem(
                    id: UUID(),
                    recordName: recordName,
                    entityTypeRaw: projection.entityType.rawValue,
                    envelopeData: envelopeData,
                    semanticDigest: envelope.semanticDigest,
                    statusRaw: status.rawValue,
                    createdAt: date,
                    updatedAt: date,
                    attemptCount: 0
                )
            )
        }
        if metadata == nil {
            modelContext.insert(
                CloudSyncRecordMetadata(
                    recordName: recordName,
                    entityTypeRaw: projection.entityType.rawValue,
                    acceptedRevision: 0,
                    acceptedSemanticDigest: nil,
                    acceptedOperationRaw: nil,
                    encodedSystemFields: nil,
                    stateRaw: CloudSyncRecordState.pending.rawValue,
                    updatedAt: date
                )
            )
        }
        return true
    }

    private func fetchCloudSyncControl() throws -> CloudSyncControl? {
        var descriptor = FetchDescriptor<CloudSyncControl>(
            predicate: #Predicate { $0.id == "primary" }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchCloudSyncMetadata(recordName: String) throws -> CloudSyncRecordMetadata? {
        var descriptor = FetchDescriptor<CloudSyncRecordMetadata>(
            predicate: #Predicate { $0.recordName == recordName }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchCloudSyncOutbox(recordName: String) throws -> CloudSyncOutboxItem? {
        var descriptor = FetchDescriptor<CloudSyncOutboxItem>(
            predicate: #Predicate { $0.recordName == recordName }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func deleteCloudSyncAccountScopedState() throws {
        for value in try modelContext.fetch(FetchDescriptor<CloudSyncInboxItem>()) {
            modelContext.delete(value)
        }
        for value in try modelContext.fetch(FetchDescriptor<CloudSyncOutboxItem>()) {
            modelContext.delete(value)
        }
        for value in try modelContext.fetch(FetchDescriptor<CloudSyncRecordMetadata>()) {
            modelContext.delete(value)
        }
        for value in try modelContext.fetch(FetchDescriptor<CloudSyncEngineState>()) {
            modelContext.delete(value)
        }
    }

    private func cloudSyncProjection(
        for model: any PersistentModel,
        operation: CloudSyncOperation
    ) throws -> CloudSyncMutationProjection? {
        if let model = model as? Expense {
            return projection(
                type: .expense,
                id: model.id,
                operation: operation,
                fields: expenseFields(model)
            )
        }
        if let model = model as? Income {
            return projection(type: .income, id: model.id, operation: operation, fields: incomeFields(model))
        }
        if let model = model as? IncomeAllocation {
            return projection(
                type: .incomeAllocation,
                id: model.id,
                operation: operation,
                fields: incomeAllocationFields(model)
            )
        }
        if let model = model as? SavingsGoal {
            return projection(type: .savingsGoal, id: model.id, operation: operation, fields: savingsGoalFields(model))
        }
        if let model = model as? RecurringFixedExpenseRule {
            return projection(type: .recurringRule, id: model.id, operation: operation, fields: recurringRuleFields(model))
        }
        if let model = model as? RecurringExpenseOccurrence {
            let identity = try RecurringOccurrenceKey(rawValue: model.occurrenceKey).rawValue
            let payload = operation == .upsert
                ? CloudSyncPayload(entityType: .recurringOccurrence, identity: identity, fields: recurringOccurrenceFields(model))
                : nil
            return CloudSyncMutationProjection(
                entityType: .recurringOccurrence,
                identity: identity,
                operation: operation,
                payload: payload
            )
        }
        if let model = model as? BudgetPlan {
            return projection(type: .budgetPlan, id: model.id, operation: operation, fields: budgetPlanFields(model))
        }
        if let model = model as? BudgetPlanSemantics {
            return projection(type: .budgetPlanSemantics, id: model.planID, operation: operation, fields: budgetPlanSemanticsFields(model))
        }
        if let model = model as? CategoryBudget {
            return projection(
                type: .categoryBudget,
                id: model.id,
                operation: operation,
                fields: operation == .upsert ? try categoryBudgetFields(model) : [:]
            )
        }
        if let model = model as? WishItem {
            return projection(type: .wishItem, id: model.id, operation: operation, fields: wishItemFields(model))
        }
        if let model = model as? CoolingOffPlan {
            return projection(
                type: .coolingOffPlan,
                id: model.id,
                operation: operation,
                fields: operation == .upsert ? try coolingOffPlanFields(model) : [:]
            )
        }
        if let model = model as? ReflectionLog {
            return projection(type: .reflectionLog, id: model.id, operation: operation, fields: reflectionLogFields(model))
        }
        return nil
    }

    private func projection(
        type: CloudSyncEntityType,
        id: UUID,
        operation: CloudSyncOperation,
        fields: [String: CloudSyncValue]
    ) -> CloudSyncMutationProjection {
        let identity = id.uuidString.lowercased()
        return CloudSyncMutationProjection(
            entityType: type,
            identity: identity,
            operation: operation,
            payload: operation == .upsert
                ? CloudSyncPayload(entityType: type, identity: identity, fields: fields)
                : nil
        )
    }

    private func commonID(_ id: UUID) -> CloudSyncValue { .string(id.uuidString.lowercased()) }
    private func optionalString(_ value: String?, key: String, into fields: inout [String: CloudSyncValue]) {
        if let value { fields[key] = .string(value) }
    }
    private func optionalUUID(_ value: UUID?, key: String, into fields: inout [String: CloudSyncValue]) {
        if let value { fields[key] = commonID(value) }
    }
    private func optionalDate(_ value: Date?, key: String, into fields: inout [String: CloudSyncValue]) {
        if let value { fields[key] = .unsigned(value.cloudSyncBits) }
    }

    private func expenseFields(_ value: Expense) -> [String: CloudSyncValue] {
        var fields: [String: CloudSyncValue] = [
            "id": commonID(value.id), "amount": .integer(value.amountMinorUnits),
            "currency": .string(value.currencyCode), "category": .string(value.categoryRaw),
            "bucket": .string(value.bucketRaw), "spentAt": .unsigned(value.spentAt.cloudSyncBits),
            "spentTimeZone": .string(value.spentTimeZoneIdentifier),
            "createdAt": .unsigned(value.createdAt.cloudSyncBits), "updatedAt": .unsigned(value.updatedAt.cloudSyncBits),
            "isPlanned": .boolean(value.isPlanned), "isRecurring": .boolean(value.isRecurring),
            "source": .string(value.sourceRaw), "allowMerchantIndexing": .boolean(value.allowMerchantIndexing)
        ]
        optionalString(value.merchantName, key: "merchantName", into: &fields)
        optionalString(value.note, key: "note", into: &fields)
        optionalString(value.paymentMethodRaw, key: "paymentMethod", into: &fields)
        optionalString(value.emotionTagRaw, key: "emotionTag", into: &fields)
        optionalString(value.purchaseReasonRaw, key: "purchaseReason", into: &fields)
        return fields
    }

    private func incomeFields(_ value: Income) -> [String: CloudSyncValue] {
        var fields: [String: CloudSyncValue] = [
            "id": commonID(value.id), "amount": .integer(value.amountMinorUnits),
            "currency": .string(value.currencyCode), "category": .string(value.categoryRaw),
            "receivedAt": .unsigned(value.receivedAt.cloudSyncBits),
            "receivedTimeZone": .string(value.receivedTimeZoneIdentifier),
            "createdAt": .unsigned(value.createdAt.cloudSyncBits), "updatedAt": .unsigned(value.updatedAt.cloudSyncBits)
        ]
        optionalString(value.sourceName, key: "sourceName", into: &fields)
        optionalString(value.note, key: "note", into: &fields)
        return fields
    }

    private func incomeAllocationFields(_ value: IncomeAllocation) -> [String: CloudSyncValue] {
        var fields: [String: CloudSyncValue] = [
            "id": commonID(value.id), "incomeID": commonID(value.incomeID),
            "budgetAmount": .integer(value.allocatedToBudgetMinorUnits),
            "savingsAmount": .integer(value.allocatedToSavingsMinorUnits),
            "createdAt": .unsigned(value.createdAt.cloudSyncBits), "updatedAt": .unsigned(value.updatedAt.cloudSyncBits)
        ]
        optionalUUID(value.budgetPlanID, key: "budgetPlanID", into: &fields)
        return fields
    }

    private func savingsGoalFields(_ value: SavingsGoal) -> [String: CloudSyncValue] {
        ["id": commonID(value.id), "target": .integer(value.targetMinorUnits),
         "startingBalance": .integer(value.startingBalanceMinorUnits), "currency": .string(value.currencyCode),
         "createdAt": .unsigned(value.createdAt.cloudSyncBits), "updatedAt": .unsigned(value.updatedAt.cloudSyncBits)]
    }

    private func recurringRuleFields(_ value: RecurringFixedExpenseRule) -> [String: CloudSyncValue] {
        var fields: [String: CloudSyncValue] = [
            "id": commonID(value.id), "originExpenseID": commonID(value.originExpenseID),
            "amount": .integer(value.amountMinorUnits), "currency": .string(value.currencyCode),
            "category": .string(value.categoryRaw), "initialOccurrenceAt": .unsigned(value.initialOccurrenceAt.cloudSyncBits),
            "anchorDate": .unsigned(value.anchorDate.cloudSyncBits), "timeZone": .string(value.timeZoneIdentifier),
            "calendar": .string(value.calendarIdentifierRaw), "isActive": .boolean(value.isActive),
            "activeSince": .unsigned(value.activeSince.cloudSyncBits), "createdAt": .unsigned(value.createdAt.cloudSyncBits),
            "updatedAt": .unsigned(value.updatedAt.cloudSyncBits)
        ]
        optionalString(value.merchantName, key: "merchantName", into: &fields)
        optionalString(value.note, key: "note", into: &fields)
        return fields
    }

    private func recurringOccurrenceFields(_ value: RecurringExpenseOccurrence) -> [String: CloudSyncValue] {
        ["id": commonID(value.id), "occurrenceKey": .string(value.occurrenceKey),
         "ruleID": commonID(value.ruleID), "expenseID": commonID(value.expenseID),
         "scheduledAt": .unsigned(value.scheduledAt.cloudSyncBits), "createdAt": .unsigned(value.createdAt.cloudSyncBits)]
    }

    private func budgetPlanFields(_ value: BudgetPlan) -> [String: CloudSyncValue] {
        ["id": commonID(value.id), "cycleStart": .unsigned(value.cycleStart.cloudSyncBits),
         "cycleEnd": .unsigned(value.cycleEnd.cloudSyncBits), "currency": .string(value.currencyCode),
         "monthlyIncome": .integer(value.monthlyIncomeMinorUnits), "totalBudget": .integer(value.totalBudgetMinorUnits),
         "fixedExpenses": .integer(value.fixedExpensesMinorUnits), "savingGoal": .integer(value.savingGoalMinorUnits),
         "createdAt": .unsigned(value.createdAt.cloudSyncBits), "updatedAt": .unsigned(value.updatedAt.cloudSyncBits)]
    }

    private func budgetPlanSemanticsFields(_ value: BudgetPlanSemantics) -> [String: CloudSyncValue] {
        ["planID": commonID(value.planID), "authority": .string(value.authorityRaw)]
    }

    private func categoryBudgetFields(_ value: CategoryBudget) throws -> [String: CloudSyncValue] {
        guard let planID = value.plan?.id else { throw CloudSyncApplicationError.missingParent }
        return [
            "id": commonID(value.id), "category": .string(value.categoryRaw),
            "limit": .integer(value.limitMinorUnits),
            "warningBasisPoints": .integer(Int64(value.warningThresholdBasisPoints)),
            "createdAt": .unsigned(value.createdAt.cloudSyncBits), "updatedAt": .unsigned(value.updatedAt.cloudSyncBits),
            "planID": commonID(planID)
        ]
    }

    private func wishItemFields(_ value: WishItem) -> [String: CloudSyncValue] {
        var fields: [String: CloudSyncValue] = [
            "id": commonID(value.id), "name": .string(value.name), "currency": .string(value.currencyCode),
            "category": .string(value.categoryRaw), "createdAt": .unsigned(value.createdAt.cloudSyncBits),
            "updatedAt": .unsigned(value.updatedAt.cloudSyncBits), "coolingOffHours": .integer(Int64(value.coolingOffHours)),
            "status": .string(value.statusRaw)
        ]
        if let value = value.estimatedPriceMinorUnits { fields["estimatedPrice"] = .integer(value) }
        optionalString(value.reasonRaw, key: "reason", into: &fields)
        optionalString(value.emotionTagRaw, key: "emotionTag", into: &fields)
        optionalString(value.sourceContextLabel, key: "sourceContextLabel", into: &fields)
        optionalDate(value.targetReviewDate, key: "targetReviewDate", into: &fields)
        optionalString(value.notes, key: "notes", into: &fields)
        optionalUUID(value.purchasedExpenseId, key: "purchasedExpenseID", into: &fields)
        return fields
    }

    private func coolingOffPlanFields(_ value: CoolingOffPlan) throws -> [String: CloudSyncValue] {
        guard let wishItemID = value.wishItem?.id else {
            throw CloudSyncApplicationError.missingParent
        }
        var fields: [String: CloudSyncValue] = [
            "id": commonID(value.id), "startedAt": .unsigned(value.startedAt.cloudSyncBits),
            "reviewAt": .unsigned(value.reviewAt.cloudSyncBits), "durationHours": .integer(Int64(value.durationHours)),
            "status": .string(value.statusRaw), "wishItemID": commonID(wishItemID)
        ]
        optionalDate(value.completedAt, key: "completedAt", into: &fields)
        optionalString(value.outcomeRaw, key: "outcome", into: &fields)
        optionalDate(value.outcomeRecordedAt, key: "outcomeRecordedAt", into: &fields)
        return fields
    }

    private func reflectionLogFields(_ value: ReflectionLog) -> [String: CloudSyncValue] {
        var fields: [String: CloudSyncValue] = [
            "id": commonID(value.id), "createdAt": .unsigned(value.createdAt.cloudSyncBits),
            "context": .string(value.contextRaw)
        ]
        optionalString(value.selectedEmotionTagRaw, key: "emotionTag", into: &fields)
        optionalString(value.selectedReasonRaw, key: "reason", into: &fields)
        optionalString(value.note, key: "note", into: &fields)
        optionalUUID(value.relatedExpenseId, key: "relatedExpenseID", into: &fields)
        optionalUUID(value.relatedWishItemId, key: "relatedWishItemID", into: &fields)
        return fields
    }
}
