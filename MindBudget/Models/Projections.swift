import Foundation

struct ExpenseSummary: Hashable, Sendable {
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

struct BudgetPlanSummary: Hashable, Sendable {
    let id: UUID
    let cycleStart: Date
    let cycleEnd: Date
    let currencyCode: String
    let monthlyIncomeMinorUnits: Int64
    let totalBudgetMinorUnits: Int64
    let fixedExpensesMinorUnits: Int64
    let savingGoalMinorUnits: Int64
    let categoryBudgets: [CategoryBudgetSummary]
}

struct CategoryBudgetSummary: Hashable, Sendable {
    let id: UUID
    let category: ExpenseCategory
    let limitMinorUnits: Int64
    let warningThresholdBasisPoints: Int
}

struct WishItemSummary: Hashable, Sendable {
    let id: UUID
    let name: String
    let estimatedPrice: Money?
    let category: ExpenseCategory
    let status: WishItemStatus
    let targetReviewDate: Date?
    let purchasedExpenseId: UUID?
}

struct CoolingOffPlanSummary: Hashable, Sendable {
    let id: UUID
    let wishItemId: UUID?
    let startedAt: Date
    let reviewAt: Date
    let durationHours: Int
    let status: CoolingOffStatus
    let outcome: CoolingOffOutcome?
}

struct SpendingInsightSummary: Hashable, Sendable {
    let id: UUID
    let dedupeKey: String
    let type: SpendingInsightType
    let severity: InsightSeverity
    let titleKey: String
    let bodyKey: String
    let payloadJSON: String
    let periodStart: Date
    let periodEnd: Date
    let isDismissed: Bool
}

struct ReminderEventSummary: Hashable, Sendable {
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

struct MerchantSummary: Hashable, Sendable {
    let id: UUID
    let normalizedName: String
    let displayName: String
    let primaryCategory: ExpenseCategory?
    let visitCount: Int
    let lastVisitedAt: Date?
    let totalMinorUnitsAllTime: Int64
}

struct ModelCounts: Equatable, Sendable {
    let expenses: Int
    let budgetPlans: Int
    let wishItems: Int
    let coolingOffPlans: Int
}
