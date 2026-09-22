import Foundation
import SwiftData

extension DataActor {
    func requireForeignCurrencyCreationAccess(
        _ value: ExpenseForeignCurrency?, featureAccess: any FeatureAccessChecking
    ) throws {
        guard value != nil else { return }
        guard ExistingPremiumEntryAccess(featureAccess: featureAccess).permitsNewForeignCurrency else {
            throw ForeignCurrencyError.requiresProAccess
        }
        if !usesForeignCurrencyProtocolFixtures,
           let control = try fetchCloudSyncControl(), control.isEnabled,
           control.statusRaw != CloudSyncStatus.deletingCloudData.rawValue {
            throw ForeignCurrencyError.syncRequiresCompanionProtocol
        }
    }

    var usesForeignCurrencyProtocolFixtures: Bool {
        #if DEBUG
        foreignCurrencyProtocolFixturesEnabled
        #else
        false
        #endif
    }

    /// A companion may survive only in transport ancestry or an unapplied inbox. A missing
    /// visible expense is not permission to send its frozen, FX-unaware parent by itself.
    func hasForeignCurrencySyncFootprint() throws -> Bool {
        if try modelContext.fetchCount(FetchDescriptor<ExpenseForeignCurrencyMetadata>()) > 0 { return true }
        let kind = CloudSyncEntityType.expenseForeignCurrencyMetadata.rawValue
        func isCompanion(_ name: String, _ data: Data? = nil) -> Bool {
            name.hasPrefix(kind + "/")
                || data.flatMap { try? CloudSyncCodec.decodeEnvelope($0) }?.entityType
                    == .expenseForeignCurrencyMetadata
        }
        if try modelContext.fetch(FetchDescriptor<CloudSyncRecordMetadata>()).contains(where: {
            $0.entityTypeRaw == kind || isCompanion($0.recordName)
        }) { return true }
        if try modelContext.fetch(FetchDescriptor<CloudSyncOutboxItem>()).contains(where: {
            $0.entityTypeRaw == kind || isCompanion($0.recordName, $0.envelopeData)
        }) { return true }
        return try modelContext.fetch(FetchDescriptor<CloudSyncInboxItem>()).contains(where: {
            isCompanion($0.recordName, $0.envelopeData)
        })
    }

    func foreignCurrencyBlocksOrdinarySync() throws -> Bool {
        guard !usesForeignCurrencyProtocolFixtures else { return false }
        let control = try fetchCloudSyncControl()
        // A separately confirmed privacy erase must remain possible. This never admits upload.
        if control?.statusRaw == CloudSyncStatus.deletingCloudData.rawValue { return false }
        return try control?.statusRaw == CloudSyncStatus.pausedForeignCurrency.rawValue
            || hasForeignCurrencySyncFootprint()
    }

    @discardableResult
    func reconcileForeignCurrencySyncPause(persist: Bool = true) throws -> Bool {
        guard try foreignCurrencyBlocksOrdinarySync(),
              let control = try fetchCloudSyncControl(), control.isEnabled else { return false }
        let status = CloudSyncStatus(rawValue: control.statusRaw) ?? .failed
        // Do not erase a prior account/key/zone trust boundary to replace its explanation.
        guard !status.isStickyPause else { return false }
        control.statusRaw = CloudSyncStatus.pausedForeignCurrency.rawValue
        control.lastReasonRaw = CloudSyncReasonCode.foreignCurrencyLocalOnly.rawValue
        control.updatedAt = Date()
        if persist { try modelContext.save() }
        return true
    }

    /// Rechecked immediately before native transport. Even the in-memory fixture escape hatch
    /// cannot query an account or hand its synthetic records to CKSyncEngine.
    func permitsOrdinaryCloudTransport() throws -> Bool {
        guard !usesForeignCurrencyProtocolFixtures else { return false }
        try reconcileForeignCurrencySyncPause()
        guard let control = try fetchCloudSyncControl(), control.isEnabled,
              !(CloudSyncStatus(rawValue: control.statusRaw) ?? .failed).isStickyPause,
              control.statusRaw != CloudSyncStatus.deletingCloudData.rawValue else { return false }
        return try !hasForeignCurrencySyncFootprint()
    }

    func foreignCurrency(for expense: Expense) throws -> ExpenseForeignCurrency? {
        let id = expense.id
        let rows = try modelContext.fetch(FetchDescriptor<ExpenseForeignCurrencyMetadata>(
            predicate: #Predicate { $0.expenseID == id }
        ))
        guard rows.count <= 1 else { throw ForeignCurrencyError.unreadableMetadata }
        guard let row = rows.first else { return nil }
        guard expense.sourceRaw == ExpenseSource.manual.rawValue, !expense.isRecurring else {
            throw ForeignCurrencyError.unsupportedSource
        }
        return try ExpenseForeignCurrency.read(row, accounting: Money.validated(
            minorUnits: expense.amountMinorUnits, currencyCode: expense.currencyCode
        ))
    }

    func validateForeignCurrency(_ value: ExpenseForeignCurrency?, draft: ExpenseDraft) throws {
        guard let value else { return }
        guard draft.source == .manual, !draft.isRecurring else { throw ForeignCurrencyError.unsupportedSource }
        try value.validate(accounting: draft.amount)
    }

    func saveForeignCurrency(_ value: ExpenseForeignCurrency?, expenseID: UUID) throws {
        guard let value else { return }
        let rows = try modelContext.fetch(FetchDescriptor<ExpenseForeignCurrencyMetadata>(
            predicate: #Predicate { $0.expenseID == expenseID }
        ))
        guard rows.count <= 1 else { throw ForeignCurrencyError.unreadableMetadata }
        if let row = rows.first {
            row.originalAmountMinorUnits = value.original.minorUnits
            row.originalCurrencyCode = value.original.currencyCode
            row.rateNumerator = value.rate.numerator
            row.rateDenominator = value.rate.denominator
            row.rateDate = value.rateDate
            row.rateTimeZoneIdentifier = value.rateTimeZoneIdentifier
            row.rateSourceRaw = value.source.rawValue
        } else {
            modelContext.insert(ExpenseForeignCurrencyMetadata(expenseID: expenseID, value: value))
        }
    }

    // Stewardship deletion must work even for malformed metadata; no validation or guessing.
    func deleteForeignCurrency(expenseID: UUID) throws {
        for row in try modelContext.fetch(FetchDescriptor<ExpenseForeignCurrencyMetadata>(
            predicate: #Predicate { $0.expenseID == expenseID }
        )) { modelContext.delete(row) }
    }

    func validateForeignCurrencySyncFacts() throws {
        for row in try modelContext.fetch(FetchDescriptor<ExpenseForeignCurrencyMetadata>()) {
            let id = row.expenseID
            let parents = try modelContext.fetch(FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id }))
            guard parents.count == 1, let parent = parents.first else {
                throw ForeignCurrencyError.unreadableMetadata
            }
            _ = try foreignCurrency(for: parent)
        }
    }
}
