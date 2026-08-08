import Foundation
import SwiftData

@Model
final class Income {
    @Attribute(.unique) var id: UUID
    var amountMinorUnits: Int64
    var currencyCode: String
    var categoryRaw: String
    var sourceName: String?
    var note: String?
    var receivedAt: Date
    var receivedTimeZoneIdentifier: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        amountMinorUnits: Int64,
        currencyCode: String,
        categoryRaw: String,
        sourceName: String?,
        note: String?,
        receivedAt: Date,
        receivedTimeZoneIdentifier: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.categoryRaw = categoryRaw
        self.sourceName = sourceName
        self.note = note
        self.receivedAt = receivedAt
        self.receivedTimeZoneIdentifier = receivedTimeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Schema V3 companion record. Keeping allocation outside `Income` freezes the shipped
/// Schema V2 fingerprint while still making every extra-budget decision explicit.
@Model
final class IncomeAllocation {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var incomeID: UUID
    /// Explicit target for the spending-budget portion. `nil` is valid only when that
    /// portion is zero; savings allocation remains independent of a budget cycle.
    var budgetPlanID: UUID?
    var allocatedToBudgetMinorUnits: Int64
    var allocatedToSavingsMinorUnits: Int64
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        incomeID: UUID,
        budgetPlanID: UUID?,
        allocatedToBudgetMinorUnits: Int64,
        allocatedToSavingsMinorUnits: Int64,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.incomeID = incomeID
        self.budgetPlanID = budgetPlanID
        self.allocatedToBudgetMinorUnits = allocatedToBudgetMinorUnits
        self.allocatedToSavingsMinorUnits = allocatedToSavingsMinorUnits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// One owner-defined target across budget cycles. Per-cycle `BudgetPlan.savingGoalMinorUnits`
/// remains a reservation used by BudgetEngine and is deliberately not repurposed here.
@Model
final class SavingsGoal {
    @Attribute(.unique) var id: UUID
    var targetMinorUnits: Int64
    var startingBalanceMinorUnits: Int64
    var currencyCode: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        targetMinorUnits: Int64,
        startingBalanceMinorUnits: Int64,
        currencyCode: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.targetMinorUnits = targetMinorUnits
        self.startingBalanceMinorUnits = startingBalanceMinorUnits
        self.currencyCode = currencyCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// A confirmed monthly rule. Generated expenses retain their own immutable snapshot, so edits
/// affect only future occurrences and deleting a rule never deletes ledger history.
@Model
final class RecurringFixedExpenseRule {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var originExpenseID: UUID
    var amountMinorUnits: Int64
    var currencyCode: String
    var categoryRaw: String
    var merchantName: String?
    var note: String?
    /// Immutable month already represented by the source expense. Editing `anchorDate`
    /// changes future execution timing without making this handled month move with it.
    var initialOccurrenceAt: Date
    var anchorDate: Date
    var timeZoneIdentifier: String
    var calendarIdentifierRaw: String
    var isActive: Bool
    /// Latest confirmation or resume time. Months elapsed while paused are not backfilled.
    var activeSince: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        originExpenseID: UUID,
        amountMinorUnits: Int64,
        currencyCode: String,
        categoryRaw: String,
        merchantName: String?,
        note: String?,
        initialOccurrenceAt: Date,
        anchorDate: Date,
        timeZoneIdentifier: String,
        calendarIdentifierRaw: String,
        isActive: Bool,
        activeSince: Date,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.originExpenseID = originExpenseID
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.categoryRaw = categoryRaw
        self.merchantName = merchantName
        self.note = note
        self.initialOccurrenceAt = initialOccurrenceAt
        self.anchorDate = anchorDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calendarIdentifierRaw = calendarIdentifierRaw
        self.isActive = isActive
        self.activeSince = activeSince
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Stable monthly identity that makes foreground reconciliation idempotent.
@Model
final class RecurringExpenseOccurrence {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var occurrenceKey: String
    var ruleID: UUID
    var expenseID: UUID
    var scheduledAt: Date
    var createdAt: Date

    init(
        id: UUID,
        occurrenceKey: String,
        ruleID: UUID,
        expenseID: UUID,
        scheduledAt: Date,
        createdAt: Date
    ) {
        self.id = id
        self.occurrenceKey = occurrenceKey
        self.ruleID = ruleID
        self.expenseID = expenseID
        self.scheduledAt = scheduledAt
        self.createdAt = createdAt
    }
}
