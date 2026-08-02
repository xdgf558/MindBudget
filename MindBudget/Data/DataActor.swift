import Foundation
import SwiftData

enum DataValidationError: Error, Equatable, Sendable {
    case invalidAmount
    case unsupportedCurrency(String)
    case accountingCurrencyMismatch(expected: String, actual: String)
    case invalidTimeZone(String)
    case invalidBudgetCycle
    case invalidBudgetAmount
    case overlappingBudgetPlan
    case duplicateCategoryBudget(ExpenseCategory)
    case invalidWarningThreshold
    case invalidWishItem
    case invalidCoolingOffPlan
    case invalidReminderEvent
    case modelNotFound
}

@ModelActor
actor DataActor {
    func createExpense(_ draft: ExpenseDraft) throws -> ExpenseSummary {
        try validateExpense(draft)
        try validateAccountingCurrency(draft.amount.currencyCode)

        let expense = Expense(
            id: draft.id,
            amountMinorUnits: draft.amount.minorUnits,
            currencyCode: draft.amount.currencyCode,
            categoryRaw: draft.category.rawValue,
            bucketRaw: draft.bucket.rawValue,
            merchantName: draft.merchantName,
            note: draft.note,
            spentAt: draft.spentAt,
            spentTimeZoneIdentifier: draft.spentTimeZoneIdentifier,
            createdAt: draft.createdAt,
            updatedAt: draft.updatedAt,
            paymentMethodRaw: draft.paymentMethod?.rawValue,
            emotionTagRaw: draft.emotionTag?.rawValue,
            purchaseReasonRaw: draft.purchaseReason?.rawValue,
            isPlanned: draft.isPlanned,
            isRecurring: draft.isRecurring,
            sourceRaw: draft.source.rawValue,
            allowMerchantIndexing: draft.allowMerchantIndexing
        )
        modelContext.insert(expense)
        try modelContext.save()
        return expenseSummary(expense)
    }

    func fetchExpenseSummaries() throws -> [ExpenseSummary] {
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\Expense.spentAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map(expenseSummary)
    }

    func deleteExpense(id: UUID) throws {
        guard let expense = try fetchExpense(id: id) else {
            throw DataValidationError.modelNotFound
        }

        let linkedWishDescriptor = FetchDescriptor<WishItem>(
            predicate: #Predicate { wishItem in
                wishItem.purchasedExpenseId == id
            }
        )
        for wishItem in try modelContext.fetch(linkedWishDescriptor) {
            wishItem.purchasedExpenseId = nil
        }

        modelContext.delete(expense)
        try modelContext.save()
    }

    func createBudgetPlan(_ draft: BudgetPlanDraft) throws -> BudgetPlanSummary {
        try validateBudgetPlan(draft)
        try validateAccountingCurrency(draft.currencyCode)
        try validateNoBudgetOverlap(start: draft.cycleStart, end: draft.cycleEnd)

        let plan = BudgetPlan(
            id: draft.id,
            cycleStart: draft.cycleStart,
            cycleEnd: draft.cycleEnd,
            currencyCode: draft.currencyCode,
            monthlyIncomeMinorUnits: draft.monthlyIncomeMinorUnits,
            totalBudgetMinorUnits: draft.totalBudgetMinorUnits,
            fixedExpensesMinorUnits: draft.fixedExpensesMinorUnits,
            savingGoalMinorUnits: draft.savingGoalMinorUnits,
            createdAt: draft.createdAt,
            updatedAt: draft.updatedAt,
            categoryBudgets: []
        )

        for categoryDraft in draft.categoryBudgets {
            let categoryBudget = CategoryBudget(
                id: categoryDraft.id,
                categoryRaw: categoryDraft.category.rawValue,
                limitMinorUnits: categoryDraft.limitMinorUnits,
                warningThresholdBasisPoints: categoryDraft.warningThresholdBasisPoints,
                createdAt: categoryDraft.createdAt,
                updatedAt: categoryDraft.updatedAt,
                plan: plan
            )
            plan.categoryBudgets.append(categoryBudget)
        }

        modelContext.insert(plan)
        try modelContext.save()
        return budgetPlanSummary(plan)
    }

    func fetchBudgetPlanSummaries() throws -> [BudgetPlanSummary] {
        let descriptor = FetchDescriptor<BudgetPlan>(sortBy: [SortDescriptor(\BudgetPlan.cycleStart)])
        return try modelContext.fetch(descriptor).map(budgetPlanSummary)
    }

    func createWishItem(_ draft: WishItemDraft) throws -> WishItemSummary {
        try validateWishItem(draft)
        try validateAccountingCurrency(draft.currencyCode)

        let wishItem = WishItem(
            id: draft.id,
            name: draft.name,
            estimatedPriceMinorUnits: draft.estimatedPrice?.minorUnits,
            currencyCode: draft.currencyCode,
            categoryRaw: draft.category.rawValue,
            reasonRaw: draft.reason?.rawValue,
            emotionTagRaw: draft.emotionTag?.rawValue,
            sourceContextLabel: draft.sourceContextLabel,
            createdAt: draft.createdAt,
            updatedAt: draft.updatedAt,
            coolingOffHours: draft.coolingOffHours,
            targetReviewDate: draft.targetReviewDate,
            statusRaw: draft.status.rawValue,
            notes: draft.notes,
            purchasedExpenseId: draft.purchasedExpenseId,
            coolingOffPlans: []
        )
        modelContext.insert(wishItem)
        try modelContext.save()
        return wishItemSummary(wishItem)
    }

    func fetchWishItemSummaries() throws -> [WishItemSummary] {
        let descriptor = FetchDescriptor<WishItem>(sortBy: [SortDescriptor(\WishItem.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map(wishItemSummary)
    }

    func transitionWishItem(id: UUID, to status: WishItemStatus, at date: Date) throws -> WishItemSummary {
        guard let wishItem = try fetchWishItem(id: id) else {
            throw DataValidationError.modelNotFound
        }
        try wishItem.transition(to: status, at: date)
        try modelContext.save()
        return wishItemSummary(wishItem)
    }

    func linkPurchasedExpense(wishItemId: UUID, expenseId: UUID, at date: Date) throws -> WishItemSummary {
        guard let wishItem = try fetchWishItem(id: wishItemId),
              try fetchExpense(id: expenseId) != nil else {
            throw DataValidationError.modelNotFound
        }
        if wishItem.status != .purchased {
            try wishItem.transition(to: .purchased, at: date)
        }
        wishItem.purchasedExpenseId = expenseId
        try modelContext.save()
        return wishItemSummary(wishItem)
    }

    func deleteWishItem(id: UUID) throws {
        guard let wishItem = try fetchWishItem(id: id) else {
            throw DataValidationError.modelNotFound
        }
        modelContext.delete(wishItem)
        try modelContext.save()
    }

    func createCoolingOffPlan(_ draft: CoolingOffPlanDraft) throws -> CoolingOffPlanSummary {
        guard draft.durationHours > 0, draft.reviewAt > draft.startedAt else {
            throw DataValidationError.invalidCoolingOffPlan
        }
        guard let wishItem = try fetchWishItem(id: draft.wishItemId) else {
            throw DataValidationError.modelNotFound
        }

        let plan = CoolingOffPlan(
            id: draft.id,
            startedAt: draft.startedAt,
            reviewAt: draft.reviewAt,
            durationHours: draft.durationHours,
            statusRaw: draft.status.rawValue,
            notificationIdentifier: draft.notificationIdentifier,
            completedAt: draft.completedAt,
            outcomeRaw: draft.outcome?.rawValue,
            wishItem: wishItem
        )
        wishItem.coolingOffPlans.append(plan)
        modelContext.insert(plan)
        try modelContext.save()
        return coolingOffPlanSummary(plan)
    }

    func fetchCoolingOffPlanSummaries() throws -> [CoolingOffPlanSummary] {
        let descriptor = FetchDescriptor<CoolingOffPlan>(sortBy: [SortDescriptor(\CoolingOffPlan.reviewAt)])
        return try modelContext.fetch(descriptor).map(coolingOffPlanSummary)
    }

    func createReminderEvent(_ draft: ReminderEventDraft) throws -> ReminderEventSummary {
        guard !draft.scopeKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (draft.response == nil) == (draft.respondedAt == nil) else {
            throw DataValidationError.invalidReminderEvent
        }
        switch draft.insightType {
        case .categoryBudgetRisk:
            guard let basisPoints = draft.categoryRiskBasisPoints, basisPoints >= 0 else {
                throw DataValidationError.invalidReminderEvent
            }
        default:
            guard draft.categoryRiskBasisPoints == nil else {
                throw DataValidationError.invalidReminderEvent
            }
        }
        let event = ReminderEvent(
            id: draft.id,
            insightTypeRaw: draft.insightType.rawValue,
            scopeKey: draft.scopeKey,
            channelRaw: draft.channel.rawValue,
            shownAt: draft.shownAt,
            categoryRiskBasisPoints: draft.categoryRiskBasisPoints,
            isInterrupting: draft.isInterrupting,
            userResponseRaw: draft.response?.rawValue,
            respondedAt: draft.respondedAt
        )
        modelContext.insert(event)
        try modelContext.save()
        return reminderEventSummary(event)
    }

    func fetchReminderEventSummaries() throws -> [ReminderEventSummary] {
        let descriptor = FetchDescriptor<ReminderEvent>(sortBy: [SortDescriptor(\ReminderEvent.shownAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map(reminderEventSummary)
    }

    func modelCounts() throws -> ModelCounts {
        ModelCounts(
            expenses: try modelContext.fetchCount(FetchDescriptor<Expense>()),
            budgetPlans: try modelContext.fetchCount(FetchDescriptor<BudgetPlan>()),
            wishItems: try modelContext.fetchCount(FetchDescriptor<WishItem>()),
            coolingOffPlans: try modelContext.fetchCount(FetchDescriptor<CoolingOffPlan>())
        )
    }

    func replaceLocalData(with sample: SampleDataBundle) throws {
        try deleteAllLocalModels()

        for budgetPlan in sample.budgetPlans {
            _ = try createBudgetPlan(budgetPlan)
        }
        for expense in sample.expenses {
            _ = try createExpense(expense)
        }
        for wishItem in sample.wishItems {
            _ = try createWishItem(wishItem)
        }
        for coolingOffPlan in sample.coolingOffPlans {
            _ = try createCoolingOffPlan(coolingOffPlan)
        }
    }

    private func deleteAllLocalModels() throws {
        for model in try modelContext.fetch(FetchDescriptor<ReminderEvent>()) { modelContext.delete(model) }
        for model in try modelContext.fetch(FetchDescriptor<SpendingInsight>()) { modelContext.delete(model) }
        for model in try modelContext.fetch(FetchDescriptor<ReflectionLog>()) { modelContext.delete(model) }
        for model in try modelContext.fetch(FetchDescriptor<Merchant>()) { modelContext.delete(model) }
        for model in try modelContext.fetch(FetchDescriptor<WishItem>()) { modelContext.delete(model) }
        for model in try modelContext.fetch(FetchDescriptor<BudgetPlan>()) { modelContext.delete(model) }
        for model in try modelContext.fetch(FetchDescriptor<Expense>()) { modelContext.delete(model) }
        try modelContext.save()
    }

    private func validateExpense(_ draft: ExpenseDraft) throws {
        guard draft.amount.minorUnits > 0,
              draft.amount.minorUnits <= Money.maximumMinorUnits(for: draft.amount.currencyCode) else {
            throw DataValidationError.invalidAmount
        }
        guard TimeZone(identifier: draft.spentTimeZoneIdentifier) != nil else {
            throw DataValidationError.invalidTimeZone(draft.spentTimeZoneIdentifier)
        }
    }

    private func validateBudgetPlan(_ draft: BudgetPlanDraft) throws {
        guard Money.isSupported(draft.currencyCode) else {
            throw DataValidationError.unsupportedCurrency(draft.currencyCode)
        }
        guard draft.cycleStart < draft.cycleEnd else {
            throw DataValidationError.invalidBudgetCycle
        }
        guard draft.monthlyIncomeMinorUnits >= 0,
              draft.totalBudgetMinorUnits >= 0,
              draft.fixedExpensesMinorUnits >= 0,
              draft.savingGoalMinorUnits >= 0,
              draft.categoryBudgets.allSatisfy({ $0.limitMinorUnits >= 0 }) else {
            throw DataValidationError.invalidBudgetAmount
        }
        let categories = draft.categoryBudgets.map(\.category)
        guard Set(categories).count == categories.count else {
            let duplicate = categories.first { category in
                categories.filter { $0 == category }.count > 1
            } ?? .other
            throw DataValidationError.duplicateCategoryBudget(duplicate)
        }
        guard draft.categoryBudgets.allSatisfy({ (1...10_000).contains($0.warningThresholdBasisPoints) }) else {
            throw DataValidationError.invalidWarningThreshold
        }
    }

    private func validateWishItem(_ draft: WishItemDraft) throws {
        guard !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              draft.coolingOffHours > 0,
              Money.isSupported(draft.currencyCode) else {
            throw DataValidationError.invalidWishItem
        }
        if let estimatedPrice = draft.estimatedPrice {
            guard estimatedPrice.currencyCode == draft.currencyCode,
                  estimatedPrice.minorUnits > 0,
                  estimatedPrice.minorUnits <= Money.maximumMinorUnits(for: draft.currencyCode) else {
                throw DataValidationError.invalidAmount
            }
        }
    }

    private func validateNoBudgetOverlap(start: Date, end: Date) throws {
        let descriptor = FetchDescriptor<BudgetPlan>(
            predicate: #Predicate { plan in
                plan.cycleStart < end && start < plan.cycleEnd
            }
        )
        guard try modelContext.fetchCount(descriptor) == 0 else {
            throw DataValidationError.overlappingBudgetPlan
        }
    }

    private func validateAccountingCurrency(_ currencyCode: String) throws {
        guard Money.isSupported(currencyCode) else {
            throw DataValidationError.unsupportedCurrency(currencyCode)
        }

        let expenseDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.currencyCode != currencyCode }
        )
        if let existing = try modelContext.fetch(expenseDescriptor).first {
            throw DataValidationError.accountingCurrencyMismatch(
                expected: existing.currencyCode,
                actual: currencyCode
            )
        }

        let planDescriptor = FetchDescriptor<BudgetPlan>(
            predicate: #Predicate { $0.currencyCode != currencyCode }
        )
        if let existing = try modelContext.fetch(planDescriptor).first {
            throw DataValidationError.accountingCurrencyMismatch(
                expected: existing.currencyCode,
                actual: currencyCode
            )
        }

        let wishDescriptor = FetchDescriptor<WishItem>(
            predicate: #Predicate { $0.currencyCode != currencyCode }
        )
        if let existing = try modelContext.fetch(wishDescriptor).first {
            throw DataValidationError.accountingCurrencyMismatch(
                expected: existing.currencyCode,
                actual: currencyCode
            )
        }
    }

    private func fetchExpense(id: UUID) throws -> Expense? {
        var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchWishItem(id: UUID) throws -> WishItem? {
        var descriptor = FetchDescriptor<WishItem>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func expenseSummary(_ expense: Expense) -> ExpenseSummary {
        ExpenseSummary(
            id: expense.id,
            amount: expense.amount,
            category: expense.category,
            bucket: expense.bucket,
            merchantName: expense.merchantName,
            spentAt: expense.spentAt,
            spentTimeZoneIdentifier: expense.spentTimeZoneIdentifier,
            emotionTag: expense.emotionTagRaw.flatMap(EmotionTag.init(rawValue:)),
            purchaseReason: expense.purchaseReasonRaw.flatMap(PurchaseReason.init(rawValue:)),
            source: ExpenseSource(rawValue: expense.sourceRaw) ?? .manual
        )
    }

    private func budgetPlanSummary(_ plan: BudgetPlan) -> BudgetPlanSummary {
        BudgetPlanSummary(
            id: plan.id,
            cycleStart: plan.cycleStart,
            cycleEnd: plan.cycleEnd,
            currencyCode: plan.currencyCode,
            monthlyIncomeMinorUnits: plan.monthlyIncomeMinorUnits,
            totalBudgetMinorUnits: plan.totalBudgetMinorUnits,
            fixedExpensesMinorUnits: plan.fixedExpensesMinorUnits,
            savingGoalMinorUnits: plan.savingGoalMinorUnits,
            categoryBudgets: plan.categoryBudgets.map { categoryBudget in
                CategoryBudgetSummary(
                    id: categoryBudget.id,
                    category: categoryBudget.category,
                    limitMinorUnits: categoryBudget.limitMinorUnits,
                    warningThresholdBasisPoints: categoryBudget.warningThresholdBasisPoints
                )
            }
        )
    }

    private func wishItemSummary(_ wishItem: WishItem) -> WishItemSummary {
        WishItemSummary(
            id: wishItem.id,
            name: wishItem.name,
            estimatedPrice: wishItem.estimatedPrice,
            category: wishItem.category,
            status: wishItem.status,
            targetReviewDate: wishItem.targetReviewDate,
            purchasedExpenseId: wishItem.purchasedExpenseId
        )
    }

    private func coolingOffPlanSummary(_ plan: CoolingOffPlan) -> CoolingOffPlanSummary {
        CoolingOffPlanSummary(
            id: plan.id,
            wishItemId: plan.wishItem?.id,
            startedAt: plan.startedAt,
            reviewAt: plan.reviewAt,
            durationHours: plan.durationHours,
            status: plan.status,
            outcome: plan.outcome
        )
    }

    private func reminderEventSummary(_ event: ReminderEvent) -> ReminderEventSummary {
        ReminderEventSummary(
            id: event.id,
            insightType: SpendingInsightType(rawValue: event.insightTypeRaw) ?? .monthlySummary,
            scopeKey: event.scopeKey,
            channel: ReminderChannel(rawValue: event.channelRaw) ?? .card,
            shownAt: event.shownAt,
            categoryRiskBasisPoints: event.categoryRiskBasisPoints,
            isInterrupting: event.isInterrupting,
            response: event.userResponseRaw.flatMap(ReminderResponse.init(rawValue:)),
            respondedAt: event.respondedAt
        )
    }
}
