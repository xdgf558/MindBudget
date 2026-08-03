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
