import Foundation

struct ExpenseSummary: Hashable, Sendable {
    let id: UUID
    let amount: Money
    let category: ExpenseCategory
    let bucket: BudgetBucket
    let merchantName: String?
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

struct ExpenseDetail: Hashable, Sendable {
    let summary: ExpenseSummary
    let note: String?
}

struct IncomeSummary: Hashable, Identifiable, Sendable {
    let id: UUID
    let amount: Money
    let category: IncomeCategory
    let sourceName: String?
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
        self.allocatedToBudgetMinorUnits = allocatedToBudgetMinorUnits
        self.allocatedToSavingsMinorUnits = allocatedToSavingsMinorUnits
        self.receivedAt = receivedAt
        self.receivedTimeZoneIdentifier = receivedTimeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct IncomeDetail: Hashable, Sendable {
    let summary: IncomeSummary
    let note: String?
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
    let recordedIncomeMinorUnits: Int64
    let allocatedIncomeMinorUnits: Int64
    let allocatedSavingsMinorUnits: Int64
    let categoryBudgets: [CategoryBudgetSummary]

    init(
        id: UUID,
        cycleStart: Date,
        cycleEnd: Date,
        currencyCode: String,
        monthlyIncomeMinorUnits: Int64,
        totalBudgetMinorUnits: Int64,
        fixedExpensesMinorUnits: Int64,
        savingGoalMinorUnits: Int64,
        recordedIncomeMinorUnits: Int64 = 0,
        allocatedIncomeMinorUnits: Int64 = 0,
        allocatedSavingsMinorUnits: Int64 = 0,
        categoryBudgets: [CategoryBudgetSummary]
    ) {
        self.id = id
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.currencyCode = currencyCode
        self.monthlyIncomeMinorUnits = monthlyIncomeMinorUnits
        self.totalBudgetMinorUnits = totalBudgetMinorUnits
        self.fixedExpensesMinorUnits = fixedExpensesMinorUnits
        self.savingGoalMinorUnits = savingGoalMinorUnits
        self.recordedIncomeMinorUnits = recordedIncomeMinorUnits
        self.allocatedIncomeMinorUnits = allocatedIncomeMinorUnits
        self.allocatedSavingsMinorUnits = allocatedSavingsMinorUnits
        self.categoryBudgets = categoryBudgets
    }
}

struct SavingsGoalSummary: Hashable, Identifiable, Sendable {
    let id: UUID
    let target: Money
    let startingBalance: Money
    let incomeAllocatedToSavings: Money
    let savedTotal: Money
    let remaining: Money
    let createdAt: Date
    let updatedAt: Date
}

struct RecurringFixedExpenseRuleSummary: Hashable, Identifiable, Sendable {
    let id: UUID
    let originExpenseID: UUID
    let amount: Money
    let category: ExpenseCategory
    let merchantName: String?
    let anchorDate: Date
    let timeZoneIdentifier: String
    let calendarIdentifierRaw: String
    let isActive: Bool
    let activeSince: Date
    let createdAt: Date
    let updatedAt: Date
}

struct RecurringFixedExpenseRuleDetail: Hashable, Sendable {
    let summary: RecurringFixedExpenseRuleSummary
    let note: String?
}

struct CategoryBudgetSummary: Hashable, Sendable {
    let id: UUID
    let category: ExpenseCategory
    let limitMinorUnits: Int64
    let warningThresholdBasisPoints: Int
}

struct WishItemSummary: Hashable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let estimatedPrice: Money?
    let category: ExpenseCategory
    let createdAt: Date
    let updatedAt: Date
    let coolingOffHours: Int
    let status: WishItemStatus
    let targetReviewDate: Date?
    let purchasedExpenseId: UUID?
}

struct WishItemDetail: Hashable, Sendable {
    let summary: WishItemSummary
    let reason: PurchaseReason?
    let emotionTag: EmotionTag?
    let sourceContextLabel: String?
    let notes: String?
    let coolingOffPlans: [CoolingOffPlanSummary]
}

struct CoolingOffPlanSummary: Hashable, Identifiable, Sendable {
    let id: UUID
    let wishItemId: UUID?
    let startedAt: Date
    let reviewAt: Date
    let durationHours: Int
    let status: CoolingOffStatus
    let notificationIdentifier: String?
    let completedAt: Date?
    let outcome: CoolingOffOutcome?
    let outcomeRecordedAt: Date?
}

struct SpendingInsightSummary: Equatable, Identifiable, Sendable {
    let id: UUID
    let dedupeKey: String
    let type: SpendingInsightType
    let severity: InsightSeverity
    let titleKey: String
    let bodyKey: String
    let payload: [String: InsightValue]
    let relatedCategory: ExpenseCategory?
    let relatedEmotionTag: EmotionTag?
    let periodStart: Date
    let periodEnd: Date
    let isDismissed: Bool
    let dismissedAt: Date?
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
    let incomes: Int
    let budgetPlans: Int
    let wishItems: Int
    let coolingOffPlans: Int
    let categoryBudgets: Int
    let spendingInsights: Int
    let reminderEvents: Int
    let merchants: Int
    let reflectionLogs: Int
    let savingsGoals: Int
    let recurringRules: Int
    let recurringOccurrences: Int
    let incomeAllocations: Int

    var isEmpty: Bool {
        expenses == 0
            && incomes == 0
            && budgetPlans == 0
            && wishItems == 0
            && coolingOffPlans == 0
            && categoryBudgets == 0
            && spendingInsights == 0
            && reminderEvents == 0
            && merchants == 0
            && reflectionLogs == 0
            && savingsGoals == 0
            && recurringRules == 0
            && recurringOccurrences == 0
            && incomeAllocations == 0
    }

    init(
        expenses: Int,
        incomes: Int = 0,
        budgetPlans: Int,
        wishItems: Int,
        coolingOffPlans: Int,
        categoryBudgets: Int = 0,
        spendingInsights: Int = 0,
        reminderEvents: Int = 0,
        merchants: Int = 0,
        reflectionLogs: Int = 0,
        savingsGoals: Int = 0,
        recurringRules: Int = 0,
        recurringOccurrences: Int = 0,
        incomeAllocations: Int = 0
    ) {
        self.expenses = expenses
        self.incomes = incomes
        self.budgetPlans = budgetPlans
        self.wishItems = wishItems
        self.coolingOffPlans = coolingOffPlans
        self.categoryBudgets = categoryBudgets
        self.spendingInsights = spendingInsights
        self.reminderEvents = reminderEvents
        self.merchants = merchants
        self.reflectionLogs = reflectionLogs
        self.savingsGoals = savingsGoals
        self.recurringRules = recurringRules
        self.recurringOccurrences = recurringOccurrences
        self.incomeAllocations = incomeAllocations
    }
}
