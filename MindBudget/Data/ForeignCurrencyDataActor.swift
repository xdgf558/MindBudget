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
        let sync = try cloudSyncSnapshot()
        guard !sync.isEnabled || sync.status == .deletingCloudData else {
            throw ForeignCurrencyError.syncRequiresCompanionProtocol
        }
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

    func requireNoForeignCurrencyForLegacySync() throws {
        guard try modelContext.fetchCount(FetchDescriptor<ExpenseForeignCurrencyMetadata>()) == 0 else {
            throw ForeignCurrencyError.syncRequiresCompanionProtocol
        }
    }
}
