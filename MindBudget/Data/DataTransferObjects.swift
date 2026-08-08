import Foundation

struct ExpenseDraft: Sendable {
    let id: UUID
    let amount: Money
    let category: ExpenseCategory
    let bucket: BudgetBucket
    let merchantName: String?
    let note: String?
    let spentAt: Date
    let spentTimeZoneIdentifier: String
    let createdAt: Date
    let updatedAt: Date
    let paymentMethod: PaymentMethod?
    let emotionTag: EmotionTag?
    let purchaseReason: PurchaseReason?
    let isPlanned: Bool
    let isRecurring: Bool
    let source: ExpenseSource
    let allowMerchantIndexing: Bool
    let recurrenceCalendarIdentifier: Calendar.Identifier?

    init(
        id: UUID,
        amount: Money,
        category: ExpenseCategory,
        bucket: BudgetBucket,
        merchantName: String?,
        note: String?,
        spentAt: Date,
        spentTimeZoneIdentifier: String,
        createdAt: Date,
        updatedAt: Date,
        paymentMethod: PaymentMethod?,
        emotionTag: EmotionTag?,
        purchaseReason: PurchaseReason?,
        isPlanned: Bool,
        isRecurring: Bool,
        source: ExpenseSource,
        allowMerchantIndexing: Bool,
        recurrenceCalendarIdentifier: Calendar.Identifier? = nil
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.bucket = bucket
        self.merchantName = merchantName
        self.note = note
        self.spentAt = spentAt
        self.spentTimeZoneIdentifier = spentTimeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.paymentMethod = paymentMethod
        self.emotionTag = emotionTag
        self.purchaseReason = purchaseReason
        self.isPlanned = isPlanned
        self.isRecurring = isRecurring
        self.source = source
        self.allowMerchantIndexing = allowMerchantIndexing
        self.recurrenceCalendarIdentifier = recurrenceCalendarIdentifier
    }
}

struct ExpenseExportRecord: Equatable, Sendable {
    let id: UUID
    let amount: Money
    let category: ExpenseCategory
    let bucket: BudgetBucket
    let merchantName: String?
    let note: String?
    let spentAt: Date
    let spentTimeZoneIdentifier: String
    let createdAt: Date
    let updatedAt: Date
    let paymentMethod: PaymentMethod?
    let emotionTag: EmotionTag?
    let purchaseReason: PurchaseReason?
    let isPlanned: Bool
    let isRecurring: Bool
    let source: ExpenseSource
    let allowMerchantIndexing: Bool
}

struct IncomeDraft: Sendable {
    let id: UUID
    let amount: Money
    let category: IncomeCategory
    let sourceName: String?
    let note: String?
    let allocatedToBudgetMinorUnits: Int64
    let allocatedToSavingsMinorUnits: Int64
    let receivedAt: Date
    let receivedTimeZoneIdentifier: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        amount: Money,
        category: IncomeCategory,
        sourceName: String?,
        note: String?,
        allocatedToBudgetMinorUnits: Int64 = 0,
        allocatedToSavingsMinorUnits: Int64 = 0,
        receivedAt: Date,
        receivedTimeZoneIdentifier: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.sourceName = sourceName
        self.note = note
        self.allocatedToBudgetMinorUnits = allocatedToBudgetMinorUnits
        self.allocatedToSavingsMinorUnits = allocatedToSavingsMinorUnits
        self.receivedAt = receivedAt
        self.receivedTimeZoneIdentifier = receivedTimeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct IncomeExportRecord: Equatable, Sendable {
    let id: UUID
    let amount: Money
    let category: IncomeCategory
    let sourceName: String?
    let note: String?
    let allocatedToBudgetMinorUnits: Int64
    let allocatedToSavingsMinorUnits: Int64
    let receivedAt: Date
    let receivedTimeZoneIdentifier: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        amount: Money,
        category: IncomeCategory,
        sourceName: String?,
        note: String?,
        allocatedToBudgetMinorUnits: Int64 = 0,
        allocatedToSavingsMinorUnits: Int64 = 0,
        receivedAt: Date,
        receivedTimeZoneIdentifier: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.sourceName = sourceName
        self.note = note
        self.allocatedToBudgetMinorUnits = allocatedToBudgetMinorUnits
        self.allocatedToSavingsMinorUnits = allocatedToSavingsMinorUnits
        self.receivedAt = receivedAt
        self.receivedTimeZoneIdentifier = receivedTimeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct SavingsGoalDraft: Sendable {
    let id: UUID
    let target: Money
    let startingBalance: Money
    let createdAt: Date
    let updatedAt: Date
}

struct RecurringFixedExpenseRuleDraft: Sendable {
    let id: UUID
    let originExpenseID: UUID
    let amount: Money
    let category: ExpenseCategory
    let merchantName: String?
    let note: String?
    let anchorDate: Date
    let timeZoneIdentifier: String
    let calendarIdentifierRaw: String
    let isActive: Bool
    let activeSince: Date
    let createdAt: Date
    let updatedAt: Date
}

struct CategoryBudgetDraft: Sendable {
    let id: UUID
    let category: ExpenseCategory
    let limitMinorUnits: Int64
    let warningThresholdBasisPoints: Int
    let createdAt: Date
    let updatedAt: Date
}

struct BudgetPlanDraft: Sendable {
    let id: UUID
    let cycleStart: Date
    let cycleEnd: Date
    let currencyCode: String
    let monthlyIncomeMinorUnits: Int64
    let totalBudgetMinorUnits: Int64
    let fixedExpensesMinorUnits: Int64
    let savingGoalMinorUnits: Int64
    let createdAt: Date
    let updatedAt: Date
    let categoryBudgets: [CategoryBudgetDraft]
}

/// Changes only the editable amount fields of the budget cycle that currently contains
/// `referenceDate`. Cycle identity, boundaries, currency, and category budgets stay intact.
struct CurrentBudgetPlanUpdate: Sendable {
    let id: UUID
    let currencyCode: String
    let monthlyIncomeMinorUnits: Int64
    let totalBudgetMinorUnits: Int64
    let fixedExpensesMinorUnits: Int64
    let savingGoalMinorUnits: Int64
    let referenceDate: Date
    let updatedAt: Date
}

enum BudgetPlanCoverage: Equatable, Sendable {
    case unconfigured
    case covered(BudgetPlanSummary)
    case transitionPlanRequired(BudgetPlanTransitionRequirement)
    case firstRegularPlanRequired(BudgetPlanFirstRegularRequirement)
    case historicalPlanRequired
}

struct BudgetPlanTransitionRequirement: Equatable, Sendable {
    let interval: DateInterval
    let firstRegularInterval: DateInterval
    let precedingPlan: BudgetPlanSummary
    let futureCycleStartDay: Int
}

struct BudgetPlanFirstRegularRequirement: Equatable, Sendable {
    let interval: DateInterval
    let futureCycleStartDay: Int
}

struct WishItemDraft: Sendable {
    let id: UUID
    let name: String
    let estimatedPrice: Money?
    let currencyCode: String
    let category: ExpenseCategory
    let reason: PurchaseReason?
    let emotionTag: EmotionTag?
    let sourceContextLabel: String?
    let createdAt: Date
    let updatedAt: Date
    let coolingOffHours: Int
    let targetReviewDate: Date?
    let status: WishItemStatus
    let notes: String?
    let purchasedExpenseId: UUID?
}

struct WishItemUpdate: Sendable {
    let id: UUID
    let name: String
    let estimatedPrice: Money?
    let currencyCode: String
    let category: ExpenseCategory
    let reason: PurchaseReason?
    let emotionTag: EmotionTag?
    let sourceContextLabel: String?
    let updatedAt: Date
    let coolingOffHours: Int
    let notes: String?
}

struct CoolingOffPlanDraft: Sendable {
    let id: UUID
    let wishItemId: UUID
    let startedAt: Date
    let reviewAt: Date
    let durationHours: Int
    let status: CoolingOffStatus
    let notificationIdentifier: String?
    let completedAt: Date?
    let outcome: CoolingOffOutcome?
    let outcomeRecordedAt: Date?
}

struct ReminderEventDraft: Sendable {
    let id: UUID
    let insightType: SpendingInsightType
    let scopeKey: String
    let channel: ReminderChannel
    let shownAt: Date
    let categoryRiskBasisPoints: Int?
    let isInterrupting: Bool
    let response: ReminderResponse?
    let respondedAt: Date?
}
