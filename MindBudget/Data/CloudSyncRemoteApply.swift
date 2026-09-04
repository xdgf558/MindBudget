import Foundation
import SwiftData

private struct CloudSyncFieldReader {
    let fields: [String: CloudSyncValue]

    func requireKeys(_ required: Set<String>, optional: Set<String> = []) throws {
        let keys = Set(fields.keys)
        guard required.isSubset(of: keys), keys.isSubset(of: required.union(optional)) else {
            throw CloudSyncApplicationError.invalidPayload
        }
    }

    func string(_ key: String) throws -> String {
        guard let value = fields[key]?.validatedString else {
            throw CloudSyncApplicationError.invalidPayload
        }
        return value
    }

    func optionalString(_ key: String) throws -> String? {
        guard let value = fields[key] else { return nil }
        guard let string = value.validatedString else {
            throw CloudSyncApplicationError.invalidPayload
        }
        return string
    }

    func integer(_ key: String) throws -> Int64 {
        guard let value = fields[key]?.validatedInteger else {
            throw CloudSyncApplicationError.invalidPayload
        }
        return value
    }

    func optionalInteger(_ key: String) throws -> Int64? {
        guard let value = fields[key] else { return nil }
        guard let integer = value.validatedInteger else {
            throw CloudSyncApplicationError.invalidPayload
        }
        return integer
    }

    func boolean(_ key: String) throws -> Bool {
        guard let value = fields[key]?.validatedBoolean else {
            throw CloudSyncApplicationError.invalidPayload
        }
        return value
    }

    func identifier(_ key: String) throws -> UUID {
        let raw = try string(key)
        guard raw == raw.lowercased(), let id = UUID(uuidString: raw),
              id.uuidString.lowercased() == raw else {
            throw CloudSyncApplicationError.invalidPayload
        }
        return id
    }

    func optionalIdentifier(_ key: String) throws -> UUID? {
        guard fields[key] != nil else { return nil }
        return try identifier(key)
    }

    func date(_ key: String) throws -> Date {
        guard let bits = fields[key]?.validatedUnsigned else {
            throw CloudSyncApplicationError.invalidPayload
        }
        let value = Date(cloudSyncBits: bits)
        guard value.timeIntervalSinceReferenceDate.isFinite else {
            throw CloudSyncApplicationError.invalidPayload
        }
        return value
    }

    func optionalDate(_ key: String) throws -> Date? {
        guard fields[key] != nil else { return nil }
        return try date(key)
    }
}

private struct DecodedCloudSyncInboxItem {
    let item: CloudSyncInboxItem
    let envelope: CloudSyncEnvelope
}

extension DataActor {
    /// Applies only durable inbox rows. Every accepted business mutation, lineage update, and
    /// inbox transition shares one ModelContext save; a failure leaves the prior local authority
    /// intact. Missing parents stay pending, while malformed or divergent facts are quarantined.
    func applyPendingCloudSyncInbox(at date: Date = Date()) throws {
        let pending = try modelContext.fetch(
            FetchDescriptor<CloudSyncInboxItem>(
                predicate: #Predicate { $0.statusRaw == "pending" },
                sortBy: [
                    SortDescriptor(\CloudSyncInboxItem.receivedAt),
                    SortDescriptor(\CloudSyncInboxItem.recordName)
                ]
            )
        )
        var decoded: [DecodedCloudSyncInboxItem] = []
        for item in pending {
            do {
                guard let data = item.envelopeData else {
                    throw CloudSyncValidationError.malformedEnvelope
                }
                let envelope = try CloudSyncCodec.decodeEnvelope(data)
                guard envelope.recordName == item.recordName else {
                    throw CloudSyncValidationError.invalidIdentity
                }
                decoded.append(DecodedCloudSyncInboxItem(item: item, envelope: envelope))
            } catch {
                item.statusRaw = CloudSyncInboxStatus.quarantined.rawValue
                item.reasonRaw = cloudSyncReason(for: error).rawValue
                item.updatedAt = date
                try modelContext.save()
            }
        }

        let upserts = decoded.filter { $0.envelope.operation == .upsert }.sorted {
            cloudSyncCandidatePrecedes($0, $1, reversesTopology: false)
        }
        let tombstones = decoded.filter { $0.envelope.operation == .tombstone }.sorted {
            cloudSyncCandidatePrecedes($0, $1, reversesTopology: true)
        }
        for candidate in upserts + tombstones {
            do {
                try applyCloudSyncCandidate(candidate, at: date)
            } catch CloudSyncApplicationError.missingParent {
                modelContext.rollback()
                candidate.item.reasonRaw = CloudSyncReasonCode.missingParent.rawValue
                candidate.item.updatedAt = date
                try modelContext.save()
            } catch {
                modelContext.rollback()
                candidate.item.statusRaw = CloudSyncInboxStatus.quarantined.rawValue
                candidate.item.reasonRaw = cloudSyncReason(for: error).rawValue
                candidate.item.updatedAt = date
                try modelContext.save()
            }
        }
        // The inbox is a crash-safe staging boundary, not an unbounded copy of accepted private
        // content. Metadata retains the accepted lineage; only unresolved/quarantined candidates
        // remain for review.
        let applied = try modelContext.fetch(
            FetchDescriptor<CloudSyncInboxItem>(
                predicate: #Predicate { $0.statusRaw == "applied" }
            )
        )
        if !applied.isEmpty {
            for item in applied { modelContext.delete(item) }
            try modelContext.save()
        }
    }

    private func cloudSyncOrder(_ entityType: CloudSyncEntityType) -> Int {
        CloudSyncEntityType.applicationOrder.firstIndex(of: entityType) ?? Int.max
    }

    private func cloudSyncCandidatePrecedes(
        _ lhs: DecodedCloudSyncInboxItem,
        _ rhs: DecodedCloudSyncInboxItem,
        reversesTopology: Bool
    ) -> Bool {
        let lhsOrder = cloudSyncOrder(lhs.envelope.entityType)
        let rhsOrder = cloudSyncOrder(rhs.envelope.entityType)
        if lhsOrder != rhsOrder {
            return reversesTopology ? lhsOrder > rhsOrder : lhsOrder < rhsOrder
        }
        if lhs.envelope.recordName != rhs.envelope.recordName {
            return lhs.envelope.recordName < rhs.envelope.recordName
        }
        return lhs.envelope.revision < rhs.envelope.revision
    }

    private func cloudSyncReason(for error: Error) -> CloudSyncReasonCode {
        if let validation = error as? CloudSyncValidationError {
            switch validation {
            case .unsupportedSchema: return .unsupportedSchema
            case .invalidIdentity: return .invalidIdentity
            case .invalidLineage: return .invalidLineage
            case .payloadTooLarge, .malformedEnvelope, .invalidDigest, .invalidPayload:
                return .malformedRecord
            }
        }
        if let application = error as? CloudSyncApplicationError {
            switch application {
            case .missingParent: return .missingParent
            case .invalidPayload: return .malformedRecord
            case .validationFailed: return .localValidationFailed
            case .divergentConflict: return .divergentConflict
            }
        }
        return .localValidationFailed
    }

    private func applyCloudSyncCandidate(
        _ candidate: DecodedCloudSyncInboxItem,
        at date: Date
    ) throws {
        let envelope = candidate.envelope
        let metadata = try cloudSyncMetadata(recordName: envelope.recordName)
        let outbox = try cloudSyncOutbox(recordName: envelope.recordName)

        if let metadata,
           metadata.acceptedRevision == envelope.revision,
           metadata.acceptedSemanticDigest == envelope.semanticDigest {
            metadata.encodedSystemFields = candidate.item.encodedSystemFields
            metadata.updatedAt = date
            candidate.item.statusRaw = CloudSyncInboxStatus.applied.rawValue
            candidate.item.reasonRaw = nil
            candidate.item.updatedAt = date
            if outbox?.semanticDigest == envelope.semanticDigest, let outbox {
                modelContext.delete(outbox)
            }
            try modelContext.save()
            return
        }

        // Once a tombstone is accepted, a later upsert is a resurrection candidate, not a safe
        // descendant. C4B-03 may resolve it explicitly; background sync never revives it.
        if let metadata,
           metadata.acceptedOperationRaw == CloudSyncOperation.tombstone.rawValue,
           envelope.operation == .upsert {
            metadata.stateRaw = CloudSyncRecordState.conflicted.rawValue
            metadata.updatedAt = date
            if let outbox {
                outbox.statusRaw = CloudSyncOutboxStatus.blockedByConflict.rawValue
                outbox.updatedAt = date
            }
            candidate.item.statusRaw = CloudSyncInboxStatus.quarantined.rawValue
            candidate.item.reasonRaw = CloudSyncReasonCode.divergentConflict.rawValue
            candidate.item.updatedAt = date
            try modelContext.save()
            return
        }

        let acceptedRevision = metadata?.acceptedRevision ?? 0
        let acceptedDigest = metadata?.acceptedSemanticDigest
        guard envelope.revision == (try CloudSyncCodec.nextRevision(after: acceptedRevision)),
              (envelope.revision == 1 && envelope.parentSemanticDigest == nil)
                || (envelope.revision > 1 && envelope.parentSemanticDigest == acceptedDigest) else {
            throw CloudSyncValidationError.invalidLineage
        }

        if let outbox {
            if outbox.semanticDigest == envelope.semanticDigest {
                try acceptCloudSyncEnvelope(
                    envelope,
                    metadata: metadata,
                    inbox: candidate.item,
                    outboxToDelete: outbox,
                    encodedSystemFields: candidate.item.encodedSystemFields,
                    at: date
                )
                return
            }
            outbox.statusRaw = CloudSyncOutboxStatus.blockedByConflict.rawValue
            outbox.updatedAt = date
            if let metadata {
                metadata.stateRaw = CloudSyncRecordState.conflicted.rawValue
                metadata.updatedAt = date
            }
            candidate.item.statusRaw = CloudSyncInboxStatus.quarantined.rawValue
            candidate.item.reasonRaw = CloudSyncReasonCode.divergentConflict.rawValue
            candidate.item.updatedAt = date
            try modelContext.save()
            return
        }

        let previousSuppression = isApplyingCloudSyncMutation
        isApplyingCloudSyncMutation = true
        defer { isApplyingCloudSyncMutation = previousSuppression }
        try applyCloudSyncMutation(envelope)
        try acceptCloudSyncEnvelope(
            envelope,
            metadata: metadata,
            inbox: candidate.item,
            outboxToDelete: nil,
            encodedSystemFields: candidate.item.encodedSystemFields,
            at: date
        )
        CloudSyncRemoteApplicationSignal.post()
    }

    private func acceptCloudSyncEnvelope(
        _ envelope: CloudSyncEnvelope,
        metadata existingMetadata: CloudSyncRecordMetadata?,
        inbox: CloudSyncInboxItem,
        outboxToDelete: CloudSyncOutboxItem?,
        encodedSystemFields: Data?,
        at date: Date
    ) throws {
        let metadata = existingMetadata ?? CloudSyncRecordMetadata(
            recordName: envelope.recordName,
            entityTypeRaw: envelope.entityType.rawValue,
            acceptedRevision: 0,
            acceptedSemanticDigest: nil,
            acceptedOperationRaw: nil,
            encodedSystemFields: nil,
            stateRaw: CloudSyncRecordState.pending.rawValue,
            updatedAt: date
        )
        if existingMetadata == nil { modelContext.insert(metadata) }
        metadata.entityTypeRaw = envelope.entityType.rawValue
        metadata.acceptedRevision = envelope.revision
        metadata.acceptedSemanticDigest = envelope.semanticDigest
        metadata.acceptedOperationRaw = envelope.operation.rawValue
        metadata.encodedSystemFields = encodedSystemFields
        metadata.stateRaw = CloudSyncRecordState.accepted.rawValue
        metadata.updatedAt = date
        inbox.statusRaw = CloudSyncInboxStatus.applied.rawValue
        inbox.reasonRaw = nil
        inbox.updatedAt = date
        if let outboxToDelete { modelContext.delete(outboxToDelete) }
        try modelContext.save()
    }

    private func cloudSyncMetadata(recordName: String) throws -> CloudSyncRecordMetadata? {
        var descriptor = FetchDescriptor<CloudSyncRecordMetadata>(
            predicate: #Predicate { $0.recordName == recordName }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func cloudSyncOutbox(recordName: String) throws -> CloudSyncOutboxItem? {
        var descriptor = FetchDescriptor<CloudSyncOutboxItem>(
            predicate: #Predicate { $0.recordName == recordName }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func cloudSyncConflictSummaries() throws -> [CloudSyncConflictSummary] {
        let quarantined = try modelContext.fetch(
            FetchDescriptor<CloudSyncInboxItem>(
                predicate: #Predicate { $0.statusRaw == "quarantined" },
                sortBy: [
                    SortDescriptor(\CloudSyncInboxItem.recordName),
                    SortDescriptor(\CloudSyncInboxItem.receivedAt, order: .reverse)
                ]
            )
        )
        var seen: Set<String> = []
        var summaries: [CloudSyncConflictSummary] = []
        for item in quarantined where seen.insert(item.recordName).inserted {
            let localEnvelope = try cloudSyncOutbox(recordName: item.recordName).flatMap {
                try? CloudSyncCodec.decodeEnvelope($0.envelopeData)
            }
            let cloudEnvelope = item.envelopeData.flatMap {
                try? CloudSyncCodec.decodeEnvelope($0)
            }
            let reason = item.reasonRaw.flatMap { CloudSyncReasonCode(rawValue: $0) }
                ?? .malformedRecord
            let entityType = cloudEnvelope?.entityType
                ?? localEnvelope?.entityType
                ?? item.recordName.split(separator: "/", maxSplits: 1).first
                    .flatMap { CloudSyncEntityType(rawValue: String($0)) }
            let canResolve = reason == .divergentConflict
                && localEnvelope?.recordName == item.recordName
                && cloudEnvelope?.recordName == item.recordName
                && item.encodedSystemFields != nil
            summaries.append(
                CloudSyncConflictSummary(
                    recordName: item.recordName,
                    entityType: entityType,
                    reason: reason,
                    localOperation: localEnvelope?.operation,
                    cloudOperation: cloudEnvelope?.operation,
                    canResolve: canResolve
                )
            )
        }
        return summaries
    }

    /// Resolves only a verified two-candidate lineage. Choosing local authors a new descendant of
    /// the accepted CloudKit candidate, while choosing cloud applies that exact candidate. There
    /// is no clock/device winner, and an unparseable or physical-deletion quarantine stays closed.
    func resolveCloudSyncConflict(
        recordName: String,
        resolution: CloudSyncConflictResolution,
        at date: Date = Date()
    ) throws {
        do {
            let quarantined = try modelContext.fetch(
                FetchDescriptor<CloudSyncInboxItem>(
                    predicate: #Predicate {
                        $0.recordName == recordName && $0.statusRaw == "quarantined"
                    },
                    sortBy: [SortDescriptor(\CloudSyncInboxItem.receivedAt, order: .reverse)]
                )
            )
            guard let cloudItem = quarantined.first(where: {
                $0.reasonRaw == CloudSyncReasonCode.divergentConflict.rawValue
                    && $0.envelopeData != nil
                    && $0.encodedSystemFields != nil
            }),
                  let cloudData = cloudItem.envelopeData,
                  let encodedSystemFields = cloudItem.encodedSystemFields,
                  let localOutbox = try cloudSyncOutbox(recordName: recordName) else {
                throw CloudSyncApplicationError.validationFailed
            }
            let cloudEnvelope = try CloudSyncCodec.decodeEnvelope(cloudData)
            let localEnvelope = try CloudSyncCodec.decodeEnvelope(localOutbox.envelopeData)
            guard cloudEnvelope.recordName == recordName,
                  localEnvelope.recordName == recordName,
                  cloudEnvelope.entityType == localEnvelope.entityType,
                  cloudEnvelope.revision == localEnvelope.revision,
                  cloudEnvelope.parentSemanticDigest == localEnvelope.parentSemanticDigest,
                  cloudEnvelope.semanticDigest != localEnvelope.semanticDigest else {
                throw CloudSyncApplicationError.validationFailed
            }

            let existingMetadata = try cloudSyncMetadata(recordName: recordName)
            let metadata = existingMetadata ?? CloudSyncRecordMetadata(
                recordName: recordName,
                entityTypeRaw: cloudEnvelope.entityType.rawValue,
                acceptedRevision: 0,
                acceptedSemanticDigest: nil,
                acceptedOperationRaw: nil,
                encodedSystemFields: nil,
                stateRaw: CloudSyncRecordState.pending.rawValue,
                updatedAt: date
            )
            if existingMetadata == nil { modelContext.insert(metadata) }

            switch resolution {
            case .keepLocal:
                let identity = try CloudSyncCodec.identity(from: recordName)
                let descendantRevision = try CloudSyncCodec.nextRevision(
                    after: cloudEnvelope.revision
                )
                let descendant = try CloudSyncCodec.makeEnvelope(
                    payload: localEnvelope.payload,
                    entityType: localEnvelope.entityType,
                    identity: identity,
                    operation: localEnvelope.operation,
                    revision: descendantRevision,
                    parentSemanticDigest: cloudEnvelope.semanticDigest,
                    modifiedAt: date
                )
                localOutbox.envelopeData = try CloudSyncCodec.encodeEnvelope(descendant)
                localOutbox.semanticDigest = descendant.semanticDigest
                localOutbox.statusRaw = CloudSyncOutboxStatus.pending.rawValue
                localOutbox.attemptCount = 0
                localOutbox.updatedAt = date
            case .useCloud:
                let previousSuppression = isApplyingCloudSyncMutation
                isApplyingCloudSyncMutation = true
                defer { isApplyingCloudSyncMutation = previousSuppression }
                try applyCloudSyncMutation(cloudEnvelope)
                modelContext.delete(localOutbox)
            }

            metadata.entityTypeRaw = cloudEnvelope.entityType.rawValue
            metadata.acceptedRevision = cloudEnvelope.revision
            metadata.acceptedSemanticDigest = cloudEnvelope.semanticDigest
            metadata.acceptedOperationRaw = cloudEnvelope.operation.rawValue
            metadata.encodedSystemFields = encodedSystemFields
            metadata.stateRaw = resolution == .keepLocal
                ? CloudSyncRecordState.pending.rawValue
                : CloudSyncRecordState.accepted.rawValue
            metadata.updatedAt = date
            for item in quarantined { modelContext.delete(item) }
            try modelContext.save()
            if resolution == .keepLocal { CloudSyncLocalChangeSignal.post() }
            CloudSyncRemoteApplicationSignal.post()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func applyCloudSyncMutation(_ envelope: CloudSyncEnvelope) throws {
        let identity = try CloudSyncCodec.identity(from: envelope.recordName)
        if envelope.operation == .tombstone {
            try applyCloudSyncTombstone(entityType: envelope.entityType, identity: identity)
            return
        }
        guard let payload = envelope.payload,
              payload.identity == identity,
              payload.entityType == envelope.entityType else {
            throw CloudSyncApplicationError.invalidPayload
        }
        let reader = CloudSyncFieldReader(fields: payload.fields)
        switch envelope.entityType {
        case .expense: try upsertCloudSyncExpense(reader, identity: identity)
        case .income: try upsertCloudSyncIncome(reader, identity: identity)
        case .incomeAllocation: try upsertCloudSyncIncomeAllocation(reader, identity: identity)
        case .savingsGoal: try upsertCloudSyncSavingsGoal(reader, identity: identity)
        case .recurringRule: try upsertCloudSyncRecurringRule(reader, identity: identity)
        case .recurringOccurrence: try upsertCloudSyncRecurringOccurrence(reader, identity: identity)
        case .budgetPlan: try upsertCloudSyncBudgetPlan(reader, identity: identity)
        case .budgetPlanSemantics: try upsertCloudSyncBudgetPlanSemantics(reader, identity: identity)
        case .categoryBudget: try upsertCloudSyncCategoryBudget(reader, identity: identity)
        case .wishItem: try upsertCloudSyncWishItem(reader, identity: identity)
        case .coolingOffPlan: try upsertCloudSyncCoolingOffPlan(reader, identity: identity)
        case .reflectionLog: try upsertCloudSyncReflectionLog(reader, identity: identity)
        }
    }

    private func requireIdentity(_ identity: String, reader: CloudSyncFieldReader) throws -> UUID {
        let id = try reader.identifier("id")
        guard id.uuidString.lowercased() == identity else {
            throw CloudSyncApplicationError.invalidPayload
        }
        return id
    }

    private func requireMoney(_ amount: Int64, currency: String, allowsZero: Bool = false) throws {
        guard Money.isSupported(currency),
              amount >= (allowsZero ? 0 : 1),
              amount <= Money.maximumMinorUnits(for: currency) else {
            throw CloudSyncApplicationError.validationFailed
        }
        try validateAccountingCurrency(currency)
    }

    private func requireTimeZone(_ identifier: String) throws {
        guard TimeZone(identifier: identifier) != nil else {
            throw CloudSyncApplicationError.validationFailed
        }
    }
}

extension DataActor {
    private func applyCloudSyncTombstone(entityType: CloudSyncEntityType, identity: String) throws {
        if entityType == .recurringOccurrence {
            let key = try RecurringOccurrenceKey(rawValue: identity).rawValue
            var descriptor = FetchDescriptor<RecurringExpenseOccurrence>(predicate: #Predicate { $0.occurrenceKey == key })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
            return
        }
        guard let id = UUID(uuidString: identity), id.uuidString.lowercased() == identity else {
            throw CloudSyncApplicationError.invalidPayload
        }
        switch entityType {
        case .expense:
            try deleteForeignCurrency(expenseID: id)
            var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first {
                let merchant = value.normalizedMerchantName
                modelContext.delete(value)
                if let merchant { try rebuildMerchant(normalizedName: merchant, excludingExpenseID: id) }
            }
        case .income:
            let children = try modelContext.fetch(FetchDescriptor<IncomeAllocation>())
            guard !children.contains(where: { $0.incomeID == id }) else {
                throw CloudSyncApplicationError.missingParent
            }
            var descriptor = FetchDescriptor<Income>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .incomeAllocation:
            var descriptor = FetchDescriptor<IncomeAllocation>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .savingsGoal:
            var descriptor = FetchDescriptor<SavingsGoal>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .recurringRule:
            let children = try modelContext.fetch(FetchDescriptor<RecurringExpenseOccurrence>())
            guard !children.contains(where: { $0.ruleID == id }) else {
                throw CloudSyncApplicationError.missingParent
            }
            var descriptor = FetchDescriptor<RecurringFixedExpenseRule>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .budgetPlan:
            let categories = try modelContext.fetch(FetchDescriptor<CategoryBudget>())
            let semantics = try modelContext.fetch(FetchDescriptor<BudgetPlanSemantics>())
            let allocations = try modelContext.fetch(FetchDescriptor<IncomeAllocation>())
            guard !categories.contains(where: { $0.plan?.id == id }),
                  !semantics.contains(where: { $0.planID == id }),
                  !allocations.contains(where: { $0.budgetPlanID == id }) else {
                throw CloudSyncApplicationError.missingParent
            }
            var descriptor = FetchDescriptor<BudgetPlan>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .budgetPlanSemantics:
            var descriptor = FetchDescriptor<BudgetPlanSemantics>(predicate: #Predicate { $0.planID == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .categoryBudget:
            var descriptor = FetchDescriptor<CategoryBudget>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .wishItem:
            let children = try modelContext.fetch(FetchDescriptor<CoolingOffPlan>())
            guard !children.contains(where: { $0.wishItem?.id == id }) else {
                throw CloudSyncApplicationError.missingParent
            }
            var descriptor = FetchDescriptor<WishItem>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .coolingOffPlan:
            var descriptor = FetchDescriptor<CoolingOffPlan>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .reflectionLog:
            var descriptor = FetchDescriptor<ReflectionLog>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let value = try modelContext.fetch(descriptor).first { modelContext.delete(value) }
        case .recurringOccurrence:
            break
        }
    }
}

extension DataActor {
    private func upsertCloudSyncCategoryBudget(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(
            ["id", "category", "limit", "warningBasisPoints", "createdAt", "updatedAt", "planID"]
        )
        let id = try requireIdentity(identity, reader: reader)
        let category = try reader.string("category")
        let limit = try reader.integer("limit")
        let warning = try reader.integer("warningBasisPoints")
        guard ExpenseCategory(rawValue: category) != nil,
              let warningValue = Int(exactly: warning), (1...10_000).contains(warningValue) else {
            throw CloudSyncApplicationError.validationFailed
        }
        let planID = try reader.identifier("planID")
        var planDescriptor = FetchDescriptor<BudgetPlan>(predicate: #Predicate { $0.id == planID })
        planDescriptor.fetchLimit = 1
        guard let plan = try modelContext.fetch(planDescriptor).first else {
            throw CloudSyncApplicationError.missingParent
        }
        guard (0...Money.maximumMinorUnits(for: plan.currencyCode)).contains(limit) else {
            throw CloudSyncApplicationError.validationFailed
        }
        let all = try modelContext.fetch(FetchDescriptor<CategoryBudget>())
        guard !all.contains(where: { $0.id != id && $0.plan?.id == planID && $0.categoryRaw == category }) else {
            throw CloudSyncApplicationError.validationFailed
        }
        var descriptor = FetchDescriptor<CategoryBudget>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let budget = try existing ?? CategoryBudget(
            id: id, categoryRaw: category, limitMinorUnits: limit,
            warningThresholdBasisPoints: warningValue,
            createdAt: try reader.date("createdAt"), updatedAt: try reader.date("updatedAt"), plan: plan
        )
        if existing == nil { modelContext.insert(budget) }
        budget.categoryRaw = category
        budget.limitMinorUnits = limit
        budget.warningThresholdBasisPoints = warningValue
        budget.createdAt = try reader.date("createdAt")
        budget.updatedAt = try reader.date("updatedAt")
        budget.plan = plan
    }

    private func upsertCloudSyncWishItem(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(
            ["id", "name", "currency", "category", "createdAt", "updatedAt", "coolingOffHours", "status"],
            optional: ["estimatedPrice", "reason", "emotionTag", "sourceContextLabel", "targetReviewDate",
                       "notes", "purchasedExpenseID"]
        )
        let id = try requireIdentity(identity, reader: reader)
        let name = try reader.string("name")
        let currency = try reader.string("currency")
        let category = try reader.string("category")
        let status = try reader.string("status")
        let coolingHours = try reader.integer("coolingOffHours")
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              ExpenseCategory(rawValue: category) != nil,
              WishItemStatus(rawValue: status) != nil,
              let coolingHoursValue = Int(exactly: coolingHours), coolingHoursValue > 0 else {
            throw CloudSyncApplicationError.validationFailed
        }
        try validateAccountingCurrency(currency)
        if let price = try reader.optionalInteger("estimatedPrice") {
            try requireMoney(price, currency: currency)
        } else if !Money.isSupported(currency) {
            throw CloudSyncApplicationError.validationFailed
        }
        if let raw = try reader.optionalString("reason"), PurchaseReason(rawValue: raw) == nil {
            throw CloudSyncApplicationError.validationFailed
        }
        if let raw = try reader.optionalString("emotionTag"), EmotionTag(rawValue: raw) == nil {
            throw CloudSyncApplicationError.validationFailed
        }
        var descriptor = FetchDescriptor<WishItem>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let item = try existing ?? WishItem(
            id: id, name: name, estimatedPriceMinorUnits: try reader.optionalInteger("estimatedPrice"),
            currencyCode: currency, categoryRaw: category,
            reasonRaw: try reader.optionalString("reason"), emotionTagRaw: try reader.optionalString("emotionTag"),
            sourceContextLabel: try reader.optionalString("sourceContextLabel"),
            createdAt: try reader.date("createdAt"), updatedAt: try reader.date("updatedAt"),
            coolingOffHours: coolingHoursValue, targetReviewDate: try reader.optionalDate("targetReviewDate"),
            statusRaw: status, notes: try reader.optionalString("notes"),
            purchasedExpenseId: try reader.optionalIdentifier("purchasedExpenseID"), coolingOffPlans: []
        )
        if existing == nil { modelContext.insert(item) }
        item.name = name
        item.estimatedPriceMinorUnits = try reader.optionalInteger("estimatedPrice")
        item.currencyCode = currency
        item.categoryRaw = category
        item.reasonRaw = try reader.optionalString("reason")
        item.emotionTagRaw = try reader.optionalString("emotionTag")
        item.sourceContextLabel = try reader.optionalString("sourceContextLabel")
        item.createdAt = try reader.date("createdAt")
        item.updatedAt = try reader.date("updatedAt")
        item.coolingOffHours = coolingHoursValue
        item.targetReviewDate = try reader.optionalDate("targetReviewDate")
        item.statusRaw = status
        item.notes = try reader.optionalString("notes")
        item.purchasedExpenseId = try reader.optionalIdentifier("purchasedExpenseID")
    }

    private func upsertCloudSyncCoolingOffPlan(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(
            ["id", "startedAt", "reviewAt", "durationHours", "status", "wishItemID"],
            optional: ["completedAt", "outcome", "outcomeRecordedAt"]
        )
        let id = try requireIdentity(identity, reader: reader)
        let startedAt = try reader.date("startedAt")
        let reviewAt = try reader.date("reviewAt")
        let duration = try reader.integer("durationHours")
        let statusRaw = try reader.string("status")
        guard reviewAt > startedAt, let durationValue = Int(exactly: duration), durationValue > 0,
              let status = CoolingOffStatus(rawValue: statusRaw) else {
            throw CloudSyncApplicationError.validationFailed
        }
        let wishID = try reader.identifier("wishItemID")
        var wishDescriptor = FetchDescriptor<WishItem>(predicate: #Predicate { $0.id == wishID })
        wishDescriptor.fetchLimit = 1
        guard let wish = try modelContext.fetch(wishDescriptor).first else {
            throw CloudSyncApplicationError.missingParent
        }
        let completedAt = try reader.optionalDate("completedAt")
        let outcomeRaw = try reader.optionalString("outcome")
        let outcomeAt = try reader.optionalDate("outcomeRecordedAt")
        if let outcomeRaw, CoolingOffOutcome(rawValue: outcomeRaw) == nil {
            throw CloudSyncApplicationError.validationFailed
        }
        switch status {
        case .scheduled, .active:
            guard completedAt == nil, outcomeRaw == nil, outcomeAt == nil else {
                throw CloudSyncApplicationError.validationFailed
            }
        case .completed:
            guard completedAt != nil, (outcomeRaw == nil) == (outcomeAt == nil) else {
                throw CloudSyncApplicationError.validationFailed
            }
        case .cancelled:
            guard completedAt != nil, outcomeRaw == nil, outcomeAt == nil else {
                throw CloudSyncApplicationError.validationFailed
            }
        }
        var descriptor = FetchDescriptor<CoolingOffPlan>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let plan = existing ?? CoolingOffPlan(
            id: id, startedAt: startedAt, reviewAt: reviewAt, durationHours: durationValue,
            statusRaw: statusRaw, notificationIdentifier: nil, completedAt: completedAt,
            outcomeRaw: outcomeRaw, outcomeRecordedAt: outcomeAt, wishItem: wish
        )
        if existing == nil { modelContext.insert(plan) }
        plan.startedAt = startedAt
        plan.reviewAt = reviewAt
        plan.durationHours = durationValue
        plan.statusRaw = statusRaw
        plan.completedAt = completedAt
        plan.outcomeRaw = outcomeRaw
        plan.outcomeRecordedAt = outcomeAt
        plan.wishItem = wish
    }

    private func upsertCloudSyncReflectionLog(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(["id", "createdAt", "context"], optional: ["emotionTag", "reason", "note", "relatedExpenseID", "relatedWishItemID"])
        let id = try requireIdentity(identity, reader: reader)
        let context = try reader.string("context")
        guard ReflectionContext(rawValue: context) != nil else {
            throw CloudSyncApplicationError.validationFailed
        }
        if let raw = try reader.optionalString("emotionTag"), EmotionTag(rawValue: raw) == nil {
            throw CloudSyncApplicationError.validationFailed
        }
        if let raw = try reader.optionalString("reason"), PurchaseReason(rawValue: raw) == nil {
            throw CloudSyncApplicationError.validationFailed
        }
        var descriptor = FetchDescriptor<ReflectionLog>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let log = try existing ?? ReflectionLog(
            id: id, createdAt: try reader.date("createdAt"), contextRaw: context,
            selectedEmotionTagRaw: try reader.optionalString("emotionTag"),
            selectedReasonRaw: try reader.optionalString("reason"), note: try reader.optionalString("note"),
            relatedExpenseId: try reader.optionalIdentifier("relatedExpenseID"),
            relatedWishItemId: try reader.optionalIdentifier("relatedWishItemID")
        )
        if existing == nil { modelContext.insert(log) }
        log.createdAt = try reader.date("createdAt")
        log.contextRaw = context
        log.selectedEmotionTagRaw = try reader.optionalString("emotionTag")
        log.selectedReasonRaw = try reader.optionalString("reason")
        log.note = try reader.optionalString("note")
        log.relatedExpenseId = try reader.optionalIdentifier("relatedExpenseID")
        log.relatedWishItemId = try reader.optionalIdentifier("relatedWishItemID")
    }
}

extension DataActor {
    private func upsertCloudSyncIncomeAllocation(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(
            ["id", "incomeID", "budgetAmount", "savingsAmount", "createdAt", "updatedAt"],
            optional: ["budgetPlanID"]
        )
        let id = try requireIdentity(identity, reader: reader)
        let incomeID = try reader.identifier("incomeID")
        let budgetPlanID = try reader.optionalIdentifier("budgetPlanID")
        let budgetAmount = try reader.integer("budgetAmount")
        let savingsAmount = try reader.integer("savingsAmount")
        guard budgetAmount >= 0, savingsAmount >= 0 else {
            throw CloudSyncApplicationError.validationFailed
        }
        let (allocated, overflow) = budgetAmount.addingReportingOverflow(savingsAmount)
        var incomeDescriptor = FetchDescriptor<Income>(predicate: #Predicate { $0.id == incomeID })
        incomeDescriptor.fetchLimit = 1
        guard let income = try modelContext.fetch(incomeDescriptor).first else {
            throw CloudSyncApplicationError.missingParent
        }
        guard !overflow, allocated <= income.amountMinorUnits else {
            throw CloudSyncApplicationError.validationFailed
        }
        if budgetAmount == 0 {
            guard budgetPlanID == nil else { throw CloudSyncApplicationError.validationFailed }
        } else {
            guard let budgetPlanID else { throw CloudSyncApplicationError.validationFailed }
            var planDescriptor = FetchDescriptor<BudgetPlan>(predicate: #Predicate { $0.id == budgetPlanID })
            planDescriptor.fetchLimit = 1
            guard let plan = try modelContext.fetch(planDescriptor).first else {
                throw CloudSyncApplicationError.missingParent
            }
            guard plan.currencyCode == income.currencyCode,
                  plan.cycleStart <= income.receivedAt, income.receivedAt < plan.cycleEnd else {
                throw CloudSyncApplicationError.validationFailed
            }
        }
        var descriptor = FetchDescriptor<IncomeAllocation>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let all = try modelContext.fetch(FetchDescriptor<IncomeAllocation>())
        guard !all.contains(where: { $0.id != id && $0.incomeID == incomeID }) else {
            throw CloudSyncApplicationError.validationFailed
        }
        let allocation = try existing ?? IncomeAllocation(
            id: id, incomeID: incomeID, budgetPlanID: budgetPlanID,
            allocatedToBudgetMinorUnits: budgetAmount,
            allocatedToSavingsMinorUnits: savingsAmount,
            createdAt: try reader.date("createdAt"), updatedAt: try reader.date("updatedAt")
        )
        if existing == nil { modelContext.insert(allocation) }
        allocation.incomeID = incomeID
        allocation.budgetPlanID = budgetPlanID
        allocation.allocatedToBudgetMinorUnits = budgetAmount
        allocation.allocatedToSavingsMinorUnits = savingsAmount
        allocation.createdAt = try reader.date("createdAt")
        allocation.updatedAt = try reader.date("updatedAt")
    }

    private func upsertCloudSyncRecurringRule(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(
            ["id", "originExpenseID", "amount", "currency", "category", "initialOccurrenceAt",
             "anchorDate", "timeZone", "calendar", "isActive", "activeSince", "createdAt", "updatedAt"],
            optional: ["merchantName", "note"]
        )
        let id = try requireIdentity(identity, reader: reader)
        let originExpenseID = try reader.identifier("originExpenseID")
        let amount = try reader.integer("amount")
        let currency = try reader.string("currency")
        let category = try reader.string("category")
        let timeZone = try reader.string("timeZone")
        let calendar = try reader.string("calendar")
        guard ExpenseCategory(rawValue: category) != nil,
              Calendar.Identifier(mindBudgetPersistedValue: calendar) != nil else {
            throw CloudSyncApplicationError.validationFailed
        }
        try requireMoney(amount, currency: currency)
        try requireTimeZone(timeZone)
        let all = try modelContext.fetch(FetchDescriptor<RecurringFixedExpenseRule>())
        guard !all.contains(where: { $0.id != id && $0.originExpenseID == originExpenseID }) else {
            throw CloudSyncApplicationError.validationFailed
        }
        var descriptor = FetchDescriptor<RecurringFixedExpenseRule>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let rule = try existing ?? RecurringFixedExpenseRule(
            id: id, originExpenseID: originExpenseID, amountMinorUnits: amount,
            currencyCode: currency, categoryRaw: category,
            merchantName: try reader.optionalString("merchantName"), note: try reader.optionalString("note"),
            initialOccurrenceAt: try reader.date("initialOccurrenceAt"), anchorDate: try reader.date("anchorDate"),
            timeZoneIdentifier: timeZone, calendarIdentifierRaw: calendar,
            isActive: try reader.boolean("isActive"), activeSince: try reader.date("activeSince"),
            createdAt: try reader.date("createdAt"), updatedAt: try reader.date("updatedAt")
        )
        if existing == nil { modelContext.insert(rule) }
        rule.originExpenseID = originExpenseID
        rule.amountMinorUnits = amount
        rule.currencyCode = currency
        rule.categoryRaw = category
        rule.merchantName = try reader.optionalString("merchantName")
        rule.note = try reader.optionalString("note")
        rule.initialOccurrenceAt = try reader.date("initialOccurrenceAt")
        rule.anchorDate = try reader.date("anchorDate")
        rule.timeZoneIdentifier = timeZone
        rule.calendarIdentifierRaw = calendar
        rule.isActive = try reader.boolean("isActive")
        rule.activeSince = try reader.date("activeSince")
        rule.createdAt = try reader.date("createdAt")
        rule.updatedAt = try reader.date("updatedAt")
    }

    private func upsertCloudSyncRecurringOccurrence(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(["id", "occurrenceKey", "ruleID", "expenseID", "scheduledAt", "createdAt"])
        let occurrenceKey = try RecurringOccurrenceKey(rawValue: identity).rawValue
        guard try reader.string("occurrenceKey") == occurrenceKey else {
            throw CloudSyncApplicationError.invalidPayload
        }
        let id = try reader.identifier("id")
        let ruleID = try reader.identifier("ruleID")
        let expenseID = try reader.identifier("expenseID")
        guard try RecurringOccurrenceKey(rawValue: occurrenceKey).ruleID == ruleID else {
            throw CloudSyncApplicationError.invalidPayload
        }
        var ruleDescriptor = FetchDescriptor<RecurringFixedExpenseRule>(predicate: #Predicate { $0.id == ruleID })
        ruleDescriptor.fetchLimit = 1
        var expenseDescriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == expenseID })
        expenseDescriptor.fetchLimit = 1
        guard try modelContext.fetch(ruleDescriptor).first != nil,
              try modelContext.fetch(expenseDescriptor).first != nil else {
            throw CloudSyncApplicationError.missingParent
        }
        let all = try modelContext.fetch(FetchDescriptor<RecurringExpenseOccurrence>())
        guard !all.contains(where: { $0.id != id && $0.occurrenceKey == occurrenceKey }) else {
            throw CloudSyncApplicationError.validationFailed
        }
        var descriptor = FetchDescriptor<RecurringExpenseOccurrence>(predicate: #Predicate { $0.occurrenceKey == occurrenceKey })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        if let existing,
           existing.id != id || existing.ruleID != ruleID || existing.expenseID != expenseID {
            throw CloudSyncApplicationError.divergentConflict
        }
        let occurrence = try existing ?? RecurringExpenseOccurrence(
            id: id, occurrenceKey: occurrenceKey, ruleID: ruleID, expenseID: expenseID,
            scheduledAt: try reader.date("scheduledAt"), createdAt: try reader.date("createdAt")
        )
        if existing == nil { modelContext.insert(occurrence) }
        occurrence.ruleID = ruleID
        occurrence.expenseID = expenseID
        occurrence.scheduledAt = try reader.date("scheduledAt")
        occurrence.createdAt = try reader.date("createdAt")
    }

    private func upsertCloudSyncBudgetPlanSemantics(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(["planID", "authority"])
        let planID = try reader.identifier("planID")
        guard planID.uuidString.lowercased() == identity,
              BudgetPlanAuthority(rawValue: try reader.string("authority")) != nil else {
            throw CloudSyncApplicationError.validationFailed
        }
        var planDescriptor = FetchDescriptor<BudgetPlan>(predicate: #Predicate { $0.id == planID })
        planDescriptor.fetchLimit = 1
        guard try modelContext.fetch(planDescriptor).first != nil else {
            throw CloudSyncApplicationError.missingParent
        }
        var descriptor = FetchDescriptor<BudgetPlanSemantics>(predicate: #Predicate { $0.planID == planID })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let semantics = try existing ?? BudgetPlanSemantics(planID: planID, authorityRaw: reader.string("authority"))
        if existing == nil { modelContext.insert(semantics) }
        semantics.authorityRaw = try reader.string("authority")
    }
}

extension DataActor {
    private func upsertCloudSyncExpense(_ reader: CloudSyncFieldReader, identity: String) throws {
        // Until FX-01D a legacy parent-only upsert cannot update a local FX companion.
        try requireNoForeignCurrencyForLegacySync()
        try reader.requireKeys(
            ["id", "amount", "currency", "category", "bucket", "spentAt", "spentTimeZone",
             "createdAt", "updatedAt", "isPlanned", "isRecurring", "source", "allowMerchantIndexing"],
            optional: ["merchantName", "note", "paymentMethod", "emotionTag", "purchaseReason"]
        )
        let id = try requireIdentity(identity, reader: reader)
        let amount = try reader.integer("amount")
        let currency = try reader.string("currency")
        let category = try reader.string("category")
        let bucket = try reader.string("bucket")
        let source = try reader.string("source")
        let timeZone = try reader.string("spentTimeZone")
        guard ExpenseCategory(rawValue: category) != nil,
              BudgetBucket(rawValue: bucket) != nil,
              ExpenseSource(rawValue: source) != nil else {
            throw CloudSyncApplicationError.validationFailed
        }
        if let raw = try reader.optionalString("paymentMethod"), PaymentMethod(rawValue: raw) == nil {
            throw CloudSyncApplicationError.validationFailed
        }
        if let raw = try reader.optionalString("emotionTag"), EmotionTag(rawValue: raw) == nil {
            throw CloudSyncApplicationError.validationFailed
        }
        if let raw = try reader.optionalString("purchaseReason"), PurchaseReason(rawValue: raw) == nil {
            throw CloudSyncApplicationError.validationFailed
        }
        try requireMoney(amount, currency: currency)
        try requireTimeZone(timeZone)
        let merchantName = try reader.optionalString("merchantName")
        let normalized = merchantName.flatMap(normalizedMerchantName)
        var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let previousMerchant = existing?.normalizedMerchantName
        let expense = try existing ?? Expense(
            id: id, amountMinorUnits: amount, currencyCode: currency, categoryRaw: category,
            bucketRaw: bucket, merchantName: merchantName, normalizedMerchantName: normalized,
            note: try reader.optionalString("note"), spentAt: try reader.date("spentAt"),
            spentTimeZoneIdentifier: timeZone, createdAt: try reader.date("createdAt"),
            updatedAt: try reader.date("updatedAt"),
            paymentMethodRaw: try reader.optionalString("paymentMethod"),
            emotionTagRaw: try reader.optionalString("emotionTag"),
            purchaseReasonRaw: try reader.optionalString("purchaseReason"),
            isPlanned: try reader.boolean("isPlanned"), isRecurring: try reader.boolean("isRecurring"),
            sourceRaw: source, allowMerchantIndexing: try reader.boolean("allowMerchantIndexing")
        )
        if existing == nil { modelContext.insert(expense) }
        expense.amountMinorUnits = amount
        expense.currencyCode = currency
        expense.categoryRaw = category
        expense.bucketRaw = bucket
        expense.merchantName = merchantName
        expense.normalizedMerchantName = normalized
        expense.note = try reader.optionalString("note")
        expense.spentAt = try reader.date("spentAt")
        expense.spentTimeZoneIdentifier = timeZone
        expense.createdAt = try reader.date("createdAt")
        expense.updatedAt = try reader.date("updatedAt")
        expense.paymentMethodRaw = try reader.optionalString("paymentMethod")
        expense.emotionTagRaw = try reader.optionalString("emotionTag")
        expense.purchaseReasonRaw = try reader.optionalString("purchaseReason")
        expense.isPlanned = try reader.boolean("isPlanned")
        expense.isRecurring = try reader.boolean("isRecurring")
        expense.sourceRaw = source
        expense.allowMerchantIndexing = try reader.boolean("allowMerchantIndexing")
        if let previousMerchant, previousMerchant != normalized {
            try rebuildMerchant(normalizedName: previousMerchant, excludingExpenseID: id)
        }
        if let normalized { try rebuildMerchant(normalizedName: normalized, including: expense) }
    }

    private func upsertCloudSyncIncome(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(
            ["id", "amount", "currency", "category", "receivedAt", "receivedTimeZone", "createdAt", "updatedAt"],
            optional: ["sourceName", "note"]
        )
        let id = try requireIdentity(identity, reader: reader)
        let amount = try reader.integer("amount")
        let currency = try reader.string("currency")
        let category = try reader.string("category")
        let timeZone = try reader.string("receivedTimeZone")
        guard IncomeCategory(rawValue: category) != nil else {
            throw CloudSyncApplicationError.validationFailed
        }
        try requireMoney(amount, currency: currency)
        try requireTimeZone(timeZone)
        var descriptor = FetchDescriptor<Income>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let income = try existing ?? Income(
            id: id, amountMinorUnits: amount, currencyCode: currency, categoryRaw: category,
            sourceName: try reader.optionalString("sourceName"), note: try reader.optionalString("note"),
            receivedAt: try reader.date("receivedAt"), receivedTimeZoneIdentifier: timeZone,
            createdAt: try reader.date("createdAt"), updatedAt: try reader.date("updatedAt")
        )
        if existing == nil { modelContext.insert(income) }
        income.amountMinorUnits = amount
        income.currencyCode = currency
        income.categoryRaw = category
        income.sourceName = try reader.optionalString("sourceName")
        income.note = try reader.optionalString("note")
        income.receivedAt = try reader.date("receivedAt")
        income.receivedTimeZoneIdentifier = timeZone
        income.createdAt = try reader.date("createdAt")
        income.updatedAt = try reader.date("updatedAt")
    }

    private func upsertCloudSyncSavingsGoal(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(["id", "target", "startingBalance", "currency", "createdAt", "updatedAt"])
        let id = try requireIdentity(identity, reader: reader)
        let target = try reader.integer("target")
        let starting = try reader.integer("startingBalance")
        let currency = try reader.string("currency")
        try requireMoney(target, currency: currency, allowsZero: true)
        try requireMoney(starting, currency: currency, allowsZero: true)
        var descriptor = FetchDescriptor<SavingsGoal>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let goal = try existing ?? SavingsGoal(
            id: id, targetMinorUnits: target, startingBalanceMinorUnits: starting,
            currencyCode: currency, createdAt: try reader.date("createdAt"),
            updatedAt: try reader.date("updatedAt")
        )
        if existing == nil { modelContext.insert(goal) }
        goal.targetMinorUnits = target
        goal.startingBalanceMinorUnits = starting
        goal.currencyCode = currency
        goal.createdAt = try reader.date("createdAt")
        goal.updatedAt = try reader.date("updatedAt")
    }

    private func upsertCloudSyncBudgetPlan(_ reader: CloudSyncFieldReader, identity: String) throws {
        try reader.requireKeys(
            ["id", "cycleStart", "cycleEnd", "currency", "monthlyIncome", "totalBudget",
             "fixedExpenses", "savingGoal", "createdAt", "updatedAt"]
        )
        let id = try requireIdentity(identity, reader: reader)
        let currency = try reader.string("currency")
        let cycleStart = try reader.date("cycleStart")
        let cycleEnd = try reader.date("cycleEnd")
        let values = [try reader.integer("monthlyIncome"), try reader.integer("totalBudget"),
                      try reader.integer("fixedExpenses"), try reader.integer("savingGoal")]
        guard cycleStart < cycleEnd else { throw CloudSyncApplicationError.validationFailed }
        for value in values { try requireMoney(value, currency: currency, allowsZero: true) }
        let otherPlans = try modelContext.fetch(FetchDescriptor<BudgetPlan>())
        guard !otherPlans.contains(where: { $0.id != id && $0.cycleStart < cycleEnd && cycleStart < $0.cycleEnd }) else {
            throw CloudSyncApplicationError.validationFailed
        }
        var descriptor = FetchDescriptor<BudgetPlan>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        let plan = try existing ?? BudgetPlan(
            id: id, cycleStart: cycleStart, cycleEnd: cycleEnd, currencyCode: currency,
            monthlyIncomeMinorUnits: values[0], totalBudgetMinorUnits: values[1],
            fixedExpensesMinorUnits: values[2], savingGoalMinorUnits: values[3],
            createdAt: try reader.date("createdAt"), updatedAt: try reader.date("updatedAt"),
            categoryBudgets: []
        )
        if existing == nil { modelContext.insert(plan) }
        plan.cycleStart = cycleStart
        plan.cycleEnd = cycleEnd
        plan.currencyCode = currency
        plan.monthlyIncomeMinorUnits = values[0]
        plan.totalBudgetMinorUnits = values[1]
        plan.fixedExpensesMinorUnits = values[2]
        plan.savingGoalMinorUnits = values[3]
        plan.createdAt = try reader.date("createdAt")
        plan.updatedAt = try reader.date("updatedAt")
    }
}
