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
    case invalidSpendingInsight
    case invalidReminderEvent
    case merchantAggregateOverflow
    case identityMismatch
    case invalidBudgetTransition
    case modelNotFound
}

private struct BudgetPlanCoverageResolution {
    let coverage: BudgetPlanCoverage
    let generatedDrafts: [BudgetPlanDraft]
}

@ModelActor
actor DataActor {
    func createExpense(_ draft: ExpenseDraft) throws -> ExpenseSummary {
        try commit {
            let expense = try insertExpense(draft)
            return try expenseSummary(expense)
        }
    }

    func updateExpense(id: UUID, with draft: ExpenseDraft) throws -> ExpenseSummary {
        try commit {
            guard id == draft.id else { throw DataValidationError.identityMismatch }
            guard let expense = try fetchExpense(id: id) else {
                throw DataValidationError.modelNotFound
            }
            try validateExpense(draft)
            try validateAccountingCurrency(draft.amount.currencyCode)

            let previousNormalizedName = expense.normalizedMerchantName
            let nextNormalizedName = draft.merchantName.flatMap(normalizedMerchantName)
            expense.amountMinorUnits = draft.amount.minorUnits
            expense.currencyCode = draft.amount.currencyCode
            expense.categoryRaw = draft.category.rawValue
            expense.bucketRaw = draft.bucket.rawValue
            expense.merchantName = draft.merchantName
            expense.normalizedMerchantName = nextNormalizedName
            expense.note = draft.note
            expense.spentAt = draft.spentAt
            expense.spentTimeZoneIdentifier = draft.spentTimeZoneIdentifier
            expense.updatedAt = draft.updatedAt
            expense.paymentMethodRaw = draft.paymentMethod?.rawValue
            expense.emotionTagRaw = draft.emotionTag?.rawValue
            expense.purchaseReasonRaw = draft.purchaseReason?.rawValue
            expense.isPlanned = draft.isPlanned
            expense.isRecurring = draft.isRecurring
            expense.sourceRaw = draft.source.rawValue
            expense.allowMerchantIndexing = draft.allowMerchantIndexing

            if let previousNormalizedName, previousNormalizedName != nextNormalizedName {
                try rebuildMerchant(normalizedName: previousNormalizedName)
            }
            if let nextNormalizedName {
                try rebuildMerchant(normalizedName: nextNormalizedName)
            }
            return try expenseSummary(expense)
        }
    }

    func fetchExpenseSummaries() throws -> [ExpenseSummary] {
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\Expense.spentAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { try expenseSummary($0) }
    }

    func fetchExpenseDetail(id: UUID) throws -> ExpenseDetail? {
        guard let expense = try fetchExpense(id: id) else { return nil }
        return try expenseDetail(expense)
    }

    func fetchExpenseIDsWithNotes(matching searchText: String) throws -> Set<UUID> {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        let expenses = try modelContext.fetch(FetchDescriptor<Expense>())
        return Set(
            expenses.compactMap { expense in
                expense.note?.localizedCaseInsensitiveContains(query) == true
                    ? expense.id
                    : nil
            }
        )
    }

    func deleteExpense(id: UUID) throws {
        try commit {
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

            let normalizedMerchantName = expense.normalizedMerchantName
            modelContext.delete(expense)
            if let normalizedMerchantName {
                try rebuildMerchant(normalizedName: normalizedMerchantName, excludingExpenseID: id)
            }
        }
    }

    func createBudgetPlan(_ draft: BudgetPlanDraft) throws -> BudgetPlanSummary {
        try commit {
            let plan = try insertBudgetPlan(draft)
            return try budgetPlanSummary(plan)
        }
    }

    func createBudgetPlanTransition(
        transition: BudgetPlanDraft,
        firstRegular: BudgetPlanDraft
    ) throws -> [BudgetPlanSummary] {
        try commit {
            guard transition.cycleEnd == firstRegular.cycleStart,
                  transition.currencyCode == firstRegular.currencyCode else {
                throw DataValidationError.invalidBudgetTransition
            }
            try validateBudgetPlan(transition)
            try validateBudgetPlan(firstRegular)
            try validateAccountingCurrency(transition.currencyCode)

            let descriptor = FetchDescriptor<BudgetPlan>(
                sortBy: [SortDescriptor(\BudgetPlan.cycleStart)]
            )
            let existing = try modelContext.fetch(descriptor).map { try budgetPlanSummary($0) }
            guard existing.last?.cycleEnd == transition.cycleStart else {
                throw DataValidationError.invalidBudgetTransition
            }

            let factory = BudgetPlanFactory()
            let candidates = [factory.summary(from: transition), factory.summary(from: firstRegular)]
            try BudgetCycleCalculator().validateNonOverlapping(existing + candidates)
            try validateNewBudgetIdentities(candidates, against: existing)

            let plans = [materializeBudgetPlan(transition), materializeBudgetPlan(firstRegular)]
            return try plans.map { try budgetPlanSummary($0) }
        }
    }

    func fetchBudgetPlanSummaries() throws -> [BudgetPlanSummary] {
        let descriptor = FetchDescriptor<BudgetPlan>(sortBy: [SortDescriptor(\BudgetPlan.cycleStart)])
        return try modelContext.fetch(descriptor).map { try budgetPlanSummary($0) }
    }

    func previewPlanCoverage(
        date: Date,
        futureCycleStartDay: Int,
        calendar: Calendar
    ) throws -> BudgetPlanCoverage {
        try resolvePlanCoverage(
            date: date,
            futureCycleStartDay: futureCycleStartDay,
            calendar: calendar,
            timestamp: .distantPast
        ).coverage
    }

    func ensurePlanCovering(
        date: Date,
        futureCycleStartDay: Int,
        calendar: Calendar,
        timestamp: Date
    ) throws -> BudgetPlanCoverage {
        let resolution = try resolvePlanCoverage(
            date: date,
            futureCycleStartDay: futureCycleStartDay,
            calendar: calendar,
            timestamp: timestamp
        )
        guard !resolution.generatedDrafts.isEmpty else {
            return resolution.coverage
        }
        return try commit {
            for draft in resolution.generatedDrafts {
                _ = materializeBudgetPlan(draft)
            }
            return resolution.coverage
        }
    }

    private func resolvePlanCoverage(
        date: Date,
        futureCycleStartDay: Int,
        calendar: Calendar,
        timestamp: Date
    ) throws -> BudgetPlanCoverageResolution {
        let descriptor = FetchDescriptor<BudgetPlan>(
            sortBy: [SortDescriptor(\BudgetPlan.cycleStart)]
        )
        let storedPlans = try modelContext.fetch(descriptor)
        guard !storedPlans.isEmpty else {
            return BudgetPlanCoverageResolution(coverage: .unconfigured, generatedDrafts: [])
        }

        let calculator = BudgetCycleCalculator()
        let factory = BudgetPlanFactory()
        let existing = try storedPlans.map { try budgetPlanSummary($0) }
        try calculator.validateNonOverlapping(existing)

        if let covered = existing.first(where: {
            $0.cycleStart <= date && date < $0.cycleEnd
        }) {
            return BudgetPlanCoverageResolution(coverage: .covered(covered), generatedDrafts: [])
        }

        guard let first = existing.first, var previous = existing.last else {
            return BudgetPlanCoverageResolution(coverage: .unconfigured, generatedDrafts: [])
        }
        guard date >= first.cycleStart, date >= previous.cycleEnd else {
            return BudgetPlanCoverageResolution(
                coverage: .historicalPlanRequired,
                generatedDrafts: []
            )
        }

        var generatedDrafts: [BudgetPlanDraft] = []
        while !(previous.cycleStart <= date && date < previous.cycleEnd) {
            guard generatedDrafts.count < BudgetPlanGenerationPolicy.maximumAutomaticPlans else {
                throw BudgetCycleError.generationLimitExceeded(
                    limit: BudgetPlanGenerationPolicy.maximumAutomaticPlans
                )
            }
            let currentInterval = DateInterval(
                start: previous.cycleStart,
                end: previous.cycleEnd
            )
            let advance = try calculator.nextCycle(
                after: currentInterval,
                startDay: futureCycleStartDay,
                calendar: calendar
            )
            switch advance.confirmationReason {
            case .transition:
                let firstRegularAdvance = try calculator.nextCycle(
                    after: advance.interval,
                    startDay: futureCycleStartDay,
                    calendar: calendar
                )
                guard firstRegularAdvance.confirmationReason
                        == .firstRegularCycleAfterTransition else {
                    throw BudgetCycleError.dateCalculationFailed
                }
                return BudgetPlanCoverageResolution(
                    coverage: .transitionPlanRequired(
                        BudgetPlanTransitionRequirement(
                            interval: advance.interval,
                            firstRegularInterval: firstRegularAdvance.interval,
                            precedingPlan: previous,
                            futureCycleStartDay: futureCycleStartDay
                        )
                    ),
                    generatedDrafts: []
                )
            case .firstRegularCycleAfterTransition:
                return BudgetPlanCoverageResolution(
                    coverage: .firstRegularPlanRequired(
                        BudgetPlanFirstRegularRequirement(
                            interval: advance.interval,
                            futureCycleStartDay: futureCycleStartDay
                        )
                    ),
                    generatedDrafts: []
                )
            case nil:
                break
            }
            let draft = try factory.makePlan(
                copying: previous,
                interval: advance.interval,
                planID: UUID(),
                categoryBudgetIDs: previous.categoryBudgets.map { _ in UUID() },
                timestamp: timestamp
            )
            generatedDrafts.append(draft)
            previous = factory.summary(from: draft)
        }

        try validateAccountingCurrency(previous.currencyCode)
        for draft in generatedDrafts {
            try validateBudgetPlan(draft)
        }
        return BudgetPlanCoverageResolution(
            coverage: .covered(previous),
            generatedDrafts: generatedDrafts
        )
    }

    func createWishItem(_ draft: WishItemDraft) throws -> WishItemSummary {
        try commit {
            let wishItem = try insertWishItem(draft)
            return try wishItemSummary(wishItem)
        }
    }

    func fetchWishItemSummaries() throws -> [WishItemSummary] {
        let descriptor = FetchDescriptor<WishItem>(sortBy: [SortDescriptor(\WishItem.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { try wishItemSummary($0) }
    }

    func fetchWishItemDetail(id: UUID) throws -> WishItemDetail? {
        guard let wishItem = try fetchWishItem(id: id) else { return nil }
        return try wishItemDetail(wishItem)
    }

    func updateWishItem(id: UUID, with update: WishItemUpdate) throws -> WishItemDetail {
        try commit {
            guard id == update.id else { throw DataValidationError.identityMismatch }
            guard let wishItem = try fetchWishItem(id: id) else {
                throw DataValidationError.modelNotFound
            }
            try validateWishItemUpdate(update)
            try validateAccountingCurrency(update.currencyCode)

            wishItem.name = update.name.trimmingCharacters(in: .whitespacesAndNewlines)
            wishItem.estimatedPriceMinorUnits = update.estimatedPrice?.minorUnits
            wishItem.currencyCode = update.currencyCode
            wishItem.categoryRaw = update.category.rawValue
            wishItem.reasonRaw = update.reason?.rawValue
            wishItem.emotionTagRaw = update.emotionTag?.rawValue
            wishItem.sourceContextLabel = update.sourceContextLabel
            wishItem.updatedAt = update.updatedAt
            wishItem.coolingOffHours = update.coolingOffHours
            wishItem.notes = update.notes
            return try wishItemDetail(wishItem)
        }
    }

    func transitionWishItem(id: UUID, to status: WishItemStatus, at date: Date) throws -> WishItemSummary {
        try commit {
            guard let wishItem = try fetchWishItem(id: id) else {
                throw DataValidationError.modelNotFound
            }
            try wishItem.transition(to: status, at: date)
            switch status {
            case .purchased:
                try completeLatestCoolingOffPlan(
                    for: wishItem,
                    outcome: .purchased,
                    outcomeRecordedAt: date
                )
                wishItem.targetReviewDate = nil
            case .skipped:
                try completeLatestCoolingOffPlan(
                    for: wishItem,
                    outcome: .skipped,
                    outcomeRecordedAt: date
                )
                wishItem.targetReviewDate = nil
            case .archived:
                try cancelActiveCoolingOffPlan(for: wishItem, at: date)
                wishItem.targetReviewDate = nil
            case .active, .coolingOff, .readyToReview:
                break
            }
            return try wishItemSummary(wishItem)
        }
    }

    func linkPurchasedExpense(wishItemId: UUID, expenseId: UUID, at date: Date) throws -> WishItemSummary {
        try commit {
            guard let wishItem = try fetchWishItem(id: wishItemId),
                  try fetchExpense(id: expenseId) != nil else {
                throw DataValidationError.modelNotFound
            }
            let currentStatus: WishItemStatus = try persistedEnum(
                WishItemStatus.self,
                rawValue: wishItem.statusRaw,
                entity: "WishItem",
                id: wishItem.id,
                field: "statusRaw"
            )
            if currentStatus != .purchased {
                try wishItem.transition(to: .purchased, at: date)
            }
            try completeLatestCoolingOffPlan(
                for: wishItem,
                outcome: .purchased,
                outcomeRecordedAt: date
            )
            wishItem.targetReviewDate = nil
            wishItem.purchasedExpenseId = expenseId
            return try wishItemSummary(wishItem)
        }
    }

    func deleteWishItem(id: UUID) throws {
        try commit {
            guard let wishItem = try fetchWishItem(id: id) else {
                throw DataValidationError.modelNotFound
            }
            modelContext.delete(wishItem)
        }
    }

    func startCoolingOff(
        wishItemId: UUID,
        durationHours: Int,
        startedAt: Date,
        calendar: Calendar
    ) throws -> WishItemDetail {
        try commit {
            guard durationHours > 0,
                  let reviewAt = calendar.date(
                    byAdding: .hour,
                    value: durationHours,
                    to: startedAt
                  ),
                  reviewAt > startedAt,
                  let wishItem = try fetchWishItem(id: wishItemId) else {
                throw DataValidationError.invalidCoolingOffPlan
            }
            guard try activeCoolingOffPlan(for: wishItem) == nil else {
                throw DataValidationError.invalidCoolingOffPlan
            }

            let currentStatus = try wishItemStatus(wishItem)
            switch currentStatus {
            case .active:
                break
            case .readyToReview:
                try completeLatestCoolingOffPlan(
                    for: wishItem,
                    outcome: .extended,
                    outcomeRecordedAt: startedAt
                )
                try wishItem.transition(to: .active, at: startedAt)
            case .coolingOff, .purchased, .skipped, .archived:
                throw WishItemTransitionError.invalidTransition(
                    from: currentStatus,
                    to: .coolingOff
                )
            }

            try wishItem.transition(to: .coolingOff, at: startedAt)
            wishItem.targetReviewDate = reviewAt
            _ = try insertCoolingOffPlan(
                CoolingOffPlanDraft(
                    id: UUID(),
                    wishItemId: wishItem.id,
                    startedAt: startedAt,
                    reviewAt: reviewAt,
                    durationHours: durationHours,
                    status: .active,
                    notificationIdentifier: nil,
                    completedAt: nil,
                    outcome: nil,
                    outcomeRecordedAt: nil
                )
            )
            return try wishItemDetail(wishItem)
        }
    }

    @discardableResult
    func refreshExpiredCoolingOffPlans(at date: Date) throws -> Int {
        let descriptor = FetchDescriptor<CoolingOffPlan>(
            predicate: #Predicate { plan in
                plan.reviewAt <= date
            }
        )
        let candidates = try modelContext.fetch(descriptor).filter { plan in
            let status = try persistedEnum(
                CoolingOffStatus.self,
                rawValue: plan.statusRaw,
                entity: "CoolingOffPlan",
                id: plan.id,
                field: "statusRaw"
            )
            return status == .active || status == .scheduled
        }
        guard !candidates.isEmpty else { return 0 }

        return try commit {
            for plan in candidates {
                plan.statusRaw = CoolingOffStatus.completed.rawValue
                plan.completedAt = plan.reviewAt
                plan.outcomeRecordedAt = nil
                if let wishItem = plan.wishItem,
                   try wishItemStatus(wishItem) == .coolingOff {
                    try wishItem.transition(to: .readyToReview, at: plan.reviewAt)
                }
            }
            return candidates.count
        }
    }

    func decideWishItem(
        id: UUID,
        outcome: CoolingOffOutcome,
        at date: Date
    ) throws -> WishItemDetail {
        try commit {
            guard outcome == .purchased || outcome == .skipped else {
                throw DataValidationError.invalidCoolingOffPlan
            }
            guard let wishItem = try fetchWishItem(id: id) else {
                throw DataValidationError.modelNotFound
            }
            let targetStatus: WishItemStatus = outcome == .purchased ? .purchased : .skipped
            let currentStatus = try wishItemStatus(wishItem)
            if currentStatus != targetStatus {
                try wishItem.transition(to: targetStatus, at: date)
            }
            try completeLatestCoolingOffPlan(
                for: wishItem,
                outcome: outcome,
                outcomeRecordedAt: date
            )
            wishItem.targetReviewDate = nil
            return try wishItemDetail(wishItem)
        }
    }

    func archiveWishItem(id: UUID, at date: Date) throws -> WishItemDetail {
        try commit {
            guard let wishItem = try fetchWishItem(id: id) else {
                throw DataValidationError.modelNotFound
            }
            let currentStatus = try wishItemStatus(wishItem)
            if currentStatus != .archived {
                try wishItem.transition(to: .archived, at: date)
            }
            try cancelActiveCoolingOffPlan(for: wishItem, at: date)
            wishItem.targetReviewDate = nil
            return try wishItemDetail(wishItem)
        }
    }

    func convertWishItemToExpense(
        wishItemId: UUID,
        expense draft: ExpenseDraft,
        at date: Date
    ) throws -> ExpenseSummary {
        try commit {
            guard draft.source == .wishlistConversion, draft.isPlanned,
                  let wishItem = try fetchWishItem(id: wishItemId) else {
                throw DataValidationError.invalidWishItem
            }
            let currentStatus = try wishItemStatus(wishItem)
            guard currentStatus != .purchased else {
                throw WishItemTransitionError.invalidTransition(
                    from: currentStatus,
                    to: .purchased
                )
            }

            let expense = try insertExpense(draft)
            try wishItem.transition(to: .purchased, at: date)
            wishItem.purchasedExpenseId = expense.id
            wishItem.targetReviewDate = nil
            try completeLatestCoolingOffPlan(
                for: wishItem,
                outcome: .purchased,
                outcomeRecordedAt: date
            )
            return try expenseSummary(expense)
        }
    }

    func createCoolingOffPlan(_ draft: CoolingOffPlanDraft) throws -> CoolingOffPlanSummary {
        try commit {
            let plan = try insertCoolingOffPlan(draft)
            return try coolingOffPlanSummary(plan)
        }
    }

    func fetchCoolingOffPlanSummaries() throws -> [CoolingOffPlanSummary] {
        let descriptor = FetchDescriptor<CoolingOffPlan>(sortBy: [SortDescriptor(\CoolingOffPlan.reviewAt)])
        return try modelContext.fetch(descriptor).map { try coolingOffPlanSummary($0) }
    }

    func upsertSpendingInsights(
        _ drafts: [InsightDraft],
        createdAt: Date
    ) throws -> [SpendingInsightSummary] {
        try commit {
            var summaries: [SpendingInsightSummary] = []
            var processedKeys: Set<String> = []
            for draft in drafts where processedKeys.insert(draft.dedupeKey).inserted {
                guard !draft.dedupeKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      draft.periodStart < draft.periodEnd else {
                    throw DataValidationError.invalidSpendingInsight
                }
                let payloadData = try SettingsCodec.encode(draft.payload)
                guard let payloadJSON = String(data: payloadData, encoding: .utf8) else {
                    throw DataValidationError.invalidSpendingInsight
                }
                let dedupeKey = draft.dedupeKey
                let descriptor = FetchDescriptor<SpendingInsight>(
                    predicate: #Predicate { insight in
                        insight.dedupeKey == dedupeKey
                    }
                )
                let insight: SpendingInsight
                if let existing = try modelContext.fetch(descriptor).first {
                    existing.typeRaw = draft.type.rawValue
                    existing.severityRaw = draft.severity.rawValue
                    existing.titleKey = draft.titleKey
                    existing.bodyKey = draft.bodyKey
                    existing.payloadJSON = payloadJSON
                    existing.relatedCategoryRaw = draft.relatedCategory?.rawValue
                    existing.relatedEmotionTagRaw = draft.relatedEmotionTag?.rawValue
                    existing.periodStart = draft.periodStart
                    existing.periodEnd = draft.periodEnd
                    insight = existing
                } else {
                    insight = SpendingInsight(
                        id: UUID(),
                        dedupeKey: draft.dedupeKey,
                        typeRaw: draft.type.rawValue,
                        severityRaw: draft.severity.rawValue,
                        titleKey: draft.titleKey,
                        bodyKey: draft.bodyKey,
                        payloadJSON: payloadJSON,
                        relatedCategoryRaw: draft.relatedCategory?.rawValue,
                        relatedEmotionTagRaw: draft.relatedEmotionTag?.rawValue,
                        createdAt: createdAt,
                        periodStart: draft.periodStart,
                        periodEnd: draft.periodEnd,
                        isDismissed: false,
                        dismissedAt: nil
                    )
                    modelContext.insert(insight)
                }
                summaries.append(try spendingInsightSummary(insight))
            }
            return summaries
        }
    }

    func fetchSpendingInsightSummaries(
        includeDismissed: Bool = false
    ) throws -> [SpendingInsightSummary] {
        let descriptor: FetchDescriptor<SpendingInsight>
        if includeDismissed {
            descriptor = FetchDescriptor(
                sortBy: [SortDescriptor(\SpendingInsight.createdAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor(
                predicate: #Predicate { insight in !insight.isDismissed },
                sortBy: [SortDescriptor(\SpendingInsight.createdAt, order: .reverse)]
            )
        }
        return try modelContext.fetch(descriptor).map { try spendingInsightSummary($0) }
    }

    func dismissSpendingInsight(id: UUID, at date: Date) throws {
        try commit {
            let descriptor = FetchDescriptor<SpendingInsight>(
                predicate: #Predicate { insight in insight.id == id }
            )
            guard let insight = try modelContext.fetch(descriptor).first else {
                throw DataValidationError.modelNotFound
            }
            insight.isDismissed = true
            insight.dismissedAt = date
        }
    }

    func createReminderEvent(_ draft: ReminderEventDraft) throws -> ReminderEventSummary {
        try commit {
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
            return try reminderEventSummary(event)
        }
    }

    func fetchReminderEventSummaries() throws -> [ReminderEventSummary] {
        let descriptor = FetchDescriptor<ReminderEvent>(sortBy: [SortDescriptor(\ReminderEvent.shownAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { try reminderEventSummary($0) }
    }

    func updateReminderEventResponse(
        id: UUID,
        response: ReminderResponse,
        at date: Date
    ) throws -> ReminderEventSummary {
        try commit {
            let descriptor = FetchDescriptor<ReminderEvent>(
                predicate: #Predicate { event in event.id == id }
            )
            guard let event = try modelContext.fetch(descriptor).first else {
                throw DataValidationError.modelNotFound
            }
            event.userResponseRaw = response.rawValue
            event.respondedAt = date
            return try reminderEventSummary(event)
        }
    }

    func modelCounts() throws -> ModelCounts {
        ModelCounts(
            expenses: try modelContext.fetchCount(FetchDescriptor<Expense>()),
            budgetPlans: try modelContext.fetchCount(FetchDescriptor<BudgetPlan>()),
            wishItems: try modelContext.fetchCount(FetchDescriptor<WishItem>()),
            coolingOffPlans: try modelContext.fetchCount(FetchDescriptor<CoolingOffPlan>())
        )
    }

    func fetchMerchantSummaries() throws -> [MerchantSummary] {
        let descriptor = FetchDescriptor<Merchant>(sortBy: [SortDescriptor(\Merchant.displayName)])
        return try modelContext.fetch(descriptor).map { merchant in
            MerchantSummary(
                id: merchant.id,
                normalizedName: merchant.normalizedName,
                displayName: merchant.displayName,
                primaryCategory: try persistedEnumIfPresent(
                    ExpenseCategory.self,
                    rawValue: merchant.primaryCategoryRaw,
                    entity: "Merchant",
                    id: merchant.id,
                    field: "primaryCategoryRaw"
                ),
                visitCount: merchant.visitCount,
                lastVisitedAt: merchant.lastVisitedAt,
                totalMinorUnitsAllTime: merchant.totalMinorUnitsAllTime
            )
        }
    }

    func replaceLocalData(with sample: SampleDataBundle) throws {
        do {
            try deleteAllLocalModels()
            modelContext.processPendingChanges()

            for budgetPlan in sample.budgetPlans {
                _ = try insertBudgetPlan(budgetPlan)
            }
            for expense in sample.expenses {
                _ = try insertExpense(expense)
            }
            for wishItem in sample.wishItems {
                _ = try insertWishItem(wishItem)
            }
            modelContext.processPendingChanges()
            for coolingOffPlan in sample.coolingOffPlans {
                _ = try insertCoolingOffPlan(coolingOffPlan)
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func commit<Result>(_ changes: () throws -> Result) throws -> Result {
        do {
            let result = try changes()
            try modelContext.save()
            return result
        } catch {
            modelContext.rollback()
            throw error
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
    }

    private func insertExpense(_ draft: ExpenseDraft) throws -> Expense {
        try validateExpense(draft)
        try validateAccountingCurrency(draft.amount.currencyCode)
        let normalizedName = draft.merchantName.flatMap(normalizedMerchantName)

        let expense = Expense(
            id: draft.id,
            amountMinorUnits: draft.amount.minorUnits,
            currencyCode: draft.amount.currencyCode,
            categoryRaw: draft.category.rawValue,
            bucketRaw: draft.bucket.rawValue,
            merchantName: draft.merchantName,
            normalizedMerchantName: normalizedName,
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

        if let normalizedName {
            try rebuildMerchant(normalizedName: normalizedName, including: expense)
        }
        return expense
    }

    private func insertBudgetPlan(_ draft: BudgetPlanDraft) throws -> BudgetPlan {
        try validateBudgetPlan(draft)
        try validateAccountingCurrency(draft.currencyCode)
        try validateNoBudgetOverlap(start: draft.cycleStart, end: draft.cycleEnd)

        return materializeBudgetPlan(draft)
    }

    private func materializeBudgetPlan(_ draft: BudgetPlanDraft) -> BudgetPlan {
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
            plan.categoryBudgets.append(
                CategoryBudget(
                    id: categoryDraft.id,
                    categoryRaw: categoryDraft.category.rawValue,
                    limitMinorUnits: categoryDraft.limitMinorUnits,
                    warningThresholdBasisPoints: categoryDraft.warningThresholdBasisPoints,
                    createdAt: categoryDraft.createdAt,
                    updatedAt: categoryDraft.updatedAt,
                    plan: plan
                )
            )
        }
        modelContext.insert(plan)
        return plan
    }

    private func insertWishItem(_ draft: WishItemDraft) throws -> WishItem {
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
        return wishItem
    }

    private func insertCoolingOffPlan(_ draft: CoolingOffPlanDraft) throws -> CoolingOffPlan {
        guard draft.durationHours > 0, draft.reviewAt > draft.startedAt else {
            throw DataValidationError.invalidCoolingOffPlan
        }
        guard let wishItem = try fetchWishItem(id: draft.wishItemId) else {
            throw DataValidationError.modelNotFound
        }
        switch draft.status {
        case .scheduled, .active:
            guard draft.completedAt == nil, draft.outcome == nil,
                  draft.outcomeRecordedAt == nil,
                  try wishItemStatus(wishItem) == .coolingOff,
                  try activeCoolingOffPlan(for: wishItem) == nil else {
                throw DataValidationError.invalidCoolingOffPlan
            }
        case .completed:
            guard draft.completedAt != nil,
                  (draft.outcome == nil) == (draft.outcomeRecordedAt == nil) else {
                throw DataValidationError.invalidCoolingOffPlan
            }
        case .cancelled:
            guard draft.completedAt != nil, draft.outcome == nil,
                  draft.outcomeRecordedAt == nil else {
                throw DataValidationError.invalidCoolingOffPlan
            }
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
            outcomeRecordedAt: draft.outcomeRecordedAt,
            wishItem: wishItem
        )
        wishItem.coolingOffPlans.append(plan)
        modelContext.insert(plan)
        return plan
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
        // Overcommitted plans remain valid input. Phase 2 derives a zero free budget
        // and preserves negative availability instead of rejecting the user's plan.
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

    private func validateWishItemUpdate(_ update: WishItemUpdate) throws {
        guard !update.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              update.coolingOffHours > 0,
              Money.isSupported(update.currencyCode) else {
            throw DataValidationError.invalidWishItem
        }
        if let estimatedPrice = update.estimatedPrice {
            guard estimatedPrice.currencyCode == update.currencyCode,
                  estimatedPrice.minorUnits > 0,
                  estimatedPrice.minorUnits <= Money.maximumMinorUnits(for: update.currencyCode) else {
                throw DataValidationError.invalidAmount
            }
        }
    }

    private func wishItemStatus(_ wishItem: WishItem) throws -> WishItemStatus {
        try persistedEnum(
            WishItemStatus.self,
            rawValue: wishItem.statusRaw,
            entity: "WishItem",
            id: wishItem.id,
            field: "statusRaw"
        )
    }

    private func activeCoolingOffPlan(for wishItem: WishItem) throws -> CoolingOffPlan? {
        try wishItem.coolingOffPlans.first { plan in
            let status = try persistedEnum(
                CoolingOffStatus.self,
                rawValue: plan.statusRaw,
                entity: "CoolingOffPlan",
                id: plan.id,
                field: "statusRaw"
            )
            return status == .active || status == .scheduled
        }
    }

    private func completeLatestCoolingOffPlan(
        for wishItem: WishItem,
        outcome: CoolingOffOutcome,
        outcomeRecordedAt: Date
    ) throws {
        guard let plan = wishItem.coolingOffPlans.max(by: { $0.startedAt < $1.startedAt }) else {
            return
        }
        let status = try persistedEnum(
            CoolingOffStatus.self,
            rawValue: plan.statusRaw,
            entity: "CoolingOffPlan",
            id: plan.id,
            field: "statusRaw"
        )
        guard status == .active || status == .scheduled ||
                (status == .completed && plan.outcomeRaw == nil) else {
            return
        }
        plan.statusRaw = CoolingOffStatus.completed.rawValue
        if plan.completedAt == nil {
            plan.completedAt = outcomeRecordedAt
        }
        plan.outcomeRaw = outcome.rawValue
        plan.outcomeRecordedAt = outcomeRecordedAt
    }

    private func cancelActiveCoolingOffPlan(for wishItem: WishItem, at date: Date) throws {
        guard let plan = try activeCoolingOffPlan(for: wishItem) else { return }
        plan.statusRaw = CoolingOffStatus.cancelled.rawValue
        plan.completedAt = date
        plan.outcomeRaw = nil
        plan.outcomeRecordedAt = nil
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

    private func validateNewBudgetIdentities(
        _ candidates: [BudgetPlanSummary],
        against existing: [BudgetPlanSummary]
    ) throws {
        let existingIDs = Set(existing.flatMap { plan in
            [plan.id] + plan.categoryBudgets.map(\.id)
        })
        let candidateIDs = candidates.flatMap { plan in
            [plan.id] + plan.categoryBudgets.map(\.id)
        }
        guard Set(candidateIDs).count == candidateIDs.count,
              existingIDs.isDisjoint(with: candidateIDs) else {
            throw DataValidationError.identityMismatch
        }
    }

    private func validateAccountingCurrency(_ currencyCode: String) throws {
        guard Money.isSupported(currencyCode) else {
            throw DataValidationError.unsupportedCurrency(currencyCode)
        }

        var expenseDescriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.currencyCode != currencyCode }
        )
        expenseDescriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(expenseDescriptor).first {
            throw DataValidationError.accountingCurrencyMismatch(
                expected: existing.currencyCode,
                actual: currencyCode
            )
        }

        var planDescriptor = FetchDescriptor<BudgetPlan>(
            predicate: #Predicate { $0.currencyCode != currencyCode }
        )
        planDescriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(planDescriptor).first {
            throw DataValidationError.accountingCurrencyMismatch(
                expected: existing.currencyCode,
                actual: currencyCode
            )
        }

        var wishDescriptor = FetchDescriptor<WishItem>(
            predicate: #Predicate { $0.currencyCode != currencyCode }
        )
        wishDescriptor.fetchLimit = 1
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

    private func rebuildMerchant(
        normalizedName: String,
        including pendingExpense: Expense? = nil,
        excludingExpenseID: UUID? = nil
    ) throws {
        let expensesDescriptor: FetchDescriptor<Expense>
        if let excludingExpenseID {
            expensesDescriptor = FetchDescriptor(
                predicate: #Predicate { expense in
                    expense.normalizedMerchantName == normalizedName
                        && expense.id != excludingExpenseID
                }
            )
        } else {
            expensesDescriptor = FetchDescriptor(
                predicate: #Predicate { expense in
                    expense.normalizedMerchantName == normalizedName
                }
            )
        }
        var expenses = try modelContext.fetch(expensesDescriptor)
        if let pendingExpense,
           pendingExpense.id != excludingExpenseID,
           !expenses.contains(where: { $0.id == pendingExpense.id }) {
            expenses.append(pendingExpense)
        }

        var descriptor = FetchDescriptor<Merchant>(
            predicate: #Predicate { $0.normalizedName == normalizedName }
        )
        descriptor.fetchLimit = 1
        let existingMerchant = try modelContext.fetch(descriptor).first

        guard !expenses.isEmpty else {
            if let existingMerchant {
                modelContext.delete(existingMerchant)
            }
            return
        }

        var totalMinorUnits: Int64 = 0
        var categoryCounts: [ExpenseCategory: Int] = [:]
        for expense in expenses {
            let (nextTotal, overflow) = totalMinorUnits.addingReportingOverflow(expense.amountMinorUnits)
            guard !overflow else { throw DataValidationError.merchantAggregateOverflow }
            totalMinorUnits = nextTotal
            let category: ExpenseCategory = try persistedEnum(
                ExpenseCategory.self,
                rawValue: expense.categoryRaw,
                entity: "Expense",
                id: expense.id,
                field: "categoryRaw"
            )
            categoryCounts[category, default: 0] += 1
        }

        let primaryCategory = ExpenseCategory.allCases.max { lhs, rhs in
            let lhsCount = categoryCounts[lhs, default: 0]
            let rhsCount = categoryCounts[rhs, default: 0]
            return lhsCount == rhsCount ? lhs.rawValue > rhs.rawValue : lhsCount < rhsCount
        }
        let mostRecentExpense = expenses.max { lhs, rhs in
            lhs.spentAt == rhs.spentAt
                ? lhs.id.uuidString > rhs.id.uuidString
                : lhs.spentAt < rhs.spentAt
        }
        let displayName = mostRecentExpense?.merchantName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? normalizedName
        let merchant = existingMerchant ?? Merchant(
            id: UUID(),
            normalizedName: normalizedName,
            displayName: displayName,
            primaryCategoryRaw: primaryCategory?.rawValue,
            visitCount: expenses.count,
            lastVisitedAt: mostRecentExpense?.spentAt,
            totalMinorUnitsAllTime: totalMinorUnits
        )
        merchant.displayName = displayName
        merchant.primaryCategoryRaw = primaryCategory?.rawValue
        merchant.visitCount = expenses.count
        merchant.lastVisitedAt = mostRecentExpense?.spentAt
        merchant.totalMinorUnitsAllTime = totalMinorUnits
        if existingMerchant == nil {
            modelContext.insert(merchant)
        }
    }

    private func normalizedMerchantName(_ name: String) -> String? {
        let folded = name.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        let normalizedScalars = folded.unicodeScalars.filter(CharacterSet.alphanumerics.contains)
        let normalizedName = String(String.UnicodeScalarView(normalizedScalars))
        return normalizedName.isEmpty ? nil : normalizedName
    }

    private func expenseSummary(_ expense: Expense) throws -> ExpenseSummary {
        return ExpenseSummary(
            id: expense.id,
            amount: try persistedMoney(
                minorUnits: expense.amountMinorUnits,
                currencyCode: expense.currencyCode,
                entity: "Expense",
                id: expense.id
            ),
            category: try persistedEnum(
                ExpenseCategory.self,
                rawValue: expense.categoryRaw,
                entity: "Expense",
                id: expense.id,
                field: "categoryRaw"
            ),
            bucket: try persistedEnum(
                BudgetBucket.self,
                rawValue: expense.bucketRaw,
                entity: "Expense",
                id: expense.id,
                field: "bucketRaw"
            ),
            merchantName: expense.merchantName,
            spentAt: expense.spentAt,
            spentTimeZoneIdentifier: expense.spentTimeZoneIdentifier,
            createdAt: expense.createdAt,
            updatedAt: expense.updatedAt,
            paymentMethod: try persistedEnumIfPresent(
                PaymentMethod.self,
                rawValue: expense.paymentMethodRaw,
                entity: "Expense",
                id: expense.id,
                field: "paymentMethodRaw"
            ),
            emotionTag: try persistedEnumIfPresent(
                EmotionTag.self,
                rawValue: expense.emotionTagRaw,
                entity: "Expense",
                id: expense.id,
                field: "emotionTagRaw"
            ),
            purchaseReason: try persistedEnumIfPresent(
                PurchaseReason.self,
                rawValue: expense.purchaseReasonRaw,
                entity: "Expense",
                id: expense.id,
                field: "purchaseReasonRaw"
            ),
            isPlanned: expense.isPlanned,
            isRecurring: expense.isRecurring,
            source: try persistedEnum(
                ExpenseSource.self,
                rawValue: expense.sourceRaw,
                entity: "Expense",
                id: expense.id,
                field: "sourceRaw"
            ),
            allowMerchantIndexing: expense.allowMerchantIndexing
        )
    }

    private func expenseDetail(_ expense: Expense) throws -> ExpenseDetail {
        ExpenseDetail(summary: try expenseSummary(expense), note: expense.note)
    }

    private func budgetPlanSummary(_ plan: BudgetPlan) throws -> BudgetPlanSummary {
        try validatePersistedCurrency(plan.currencyCode, entity: "BudgetPlan", id: plan.id)
        return BudgetPlanSummary(
            id: plan.id,
            cycleStart: plan.cycleStart,
            cycleEnd: plan.cycleEnd,
            currencyCode: plan.currencyCode,
            monthlyIncomeMinorUnits: plan.monthlyIncomeMinorUnits,
            totalBudgetMinorUnits: plan.totalBudgetMinorUnits,
            fixedExpensesMinorUnits: plan.fixedExpensesMinorUnits,
            savingGoalMinorUnits: plan.savingGoalMinorUnits,
            categoryBudgets: try plan.categoryBudgets.map { categoryBudget in
                CategoryBudgetSummary(
                    id: categoryBudget.id,
                    category: try persistedEnum(
                        ExpenseCategory.self,
                        rawValue: categoryBudget.categoryRaw,
                        entity: "CategoryBudget",
                        id: categoryBudget.id,
                        field: "categoryRaw"
                    ),
                    limitMinorUnits: categoryBudget.limitMinorUnits,
                    warningThresholdBasisPoints: categoryBudget.warningThresholdBasisPoints
                )
            }
        )
    }

    private func wishItemSummary(_ wishItem: WishItem) throws -> WishItemSummary {
        try validatePersistedCurrency(wishItem.currencyCode, entity: "WishItem", id: wishItem.id)
        _ = try persistedEnumIfPresent(
            PurchaseReason.self,
            rawValue: wishItem.reasonRaw,
            entity: "WishItem",
            id: wishItem.id,
            field: "reasonRaw"
        )
        _ = try persistedEnumIfPresent(
            EmotionTag.self,
            rawValue: wishItem.emotionTagRaw,
            entity: "WishItem",
            id: wishItem.id,
            field: "emotionTagRaw"
        )
        return WishItemSummary(
            id: wishItem.id,
            name: wishItem.name,
            estimatedPrice: try wishItem.estimatedPriceMinorUnits.map { minorUnits in
                try persistedMoney(
                    minorUnits: minorUnits,
                    currencyCode: wishItem.currencyCode,
                    entity: "WishItem",
                    id: wishItem.id
                )
            },
            category: try persistedEnum(
                ExpenseCategory.self,
                rawValue: wishItem.categoryRaw,
                entity: "WishItem",
                id: wishItem.id,
                field: "categoryRaw"
            ),
            createdAt: wishItem.createdAt,
            updatedAt: wishItem.updatedAt,
            coolingOffHours: wishItem.coolingOffHours,
            status: try persistedEnum(
                WishItemStatus.self,
                rawValue: wishItem.statusRaw,
                entity: "WishItem",
                id: wishItem.id,
                field: "statusRaw"
            ),
            targetReviewDate: wishItem.targetReviewDate,
            purchasedExpenseId: wishItem.purchasedExpenseId
        )
    }

    private func wishItemDetail(_ wishItem: WishItem) throws -> WishItemDetail {
        WishItemDetail(
            summary: try wishItemSummary(wishItem),
            reason: try persistedEnumIfPresent(
                PurchaseReason.self,
                rawValue: wishItem.reasonRaw,
                entity: "WishItem",
                id: wishItem.id,
                field: "reasonRaw"
            ),
            emotionTag: try persistedEnumIfPresent(
                EmotionTag.self,
                rawValue: wishItem.emotionTagRaw,
                entity: "WishItem",
                id: wishItem.id,
                field: "emotionTagRaw"
            ),
            sourceContextLabel: wishItem.sourceContextLabel,
            notes: wishItem.notes,
            coolingOffPlans: try wishItem.coolingOffPlans
                .map { try coolingOffPlanSummary($0) }
                .sorted { $0.startedAt > $1.startedAt }
        )
    }

    private func coolingOffPlanSummary(_ plan: CoolingOffPlan) throws -> CoolingOffPlanSummary {
        CoolingOffPlanSummary(
            id: plan.id,
            wishItemId: plan.wishItem?.id,
            startedAt: plan.startedAt,
            reviewAt: plan.reviewAt,
            durationHours: plan.durationHours,
            status: try persistedEnum(
                CoolingOffStatus.self,
                rawValue: plan.statusRaw,
                entity: "CoolingOffPlan",
                id: plan.id,
                field: "statusRaw"
            ),
            completedAt: plan.completedAt,
            outcome: try persistedEnumIfPresent(
                CoolingOffOutcome.self,
                rawValue: plan.outcomeRaw,
                entity: "CoolingOffPlan",
                id: plan.id,
                field: "outcomeRaw"
            ),
            outcomeRecordedAt: plan.outcomeRecordedAt
        )
    }

    private func spendingInsightSummary(
        _ insight: SpendingInsight
    ) throws -> SpendingInsightSummary {
        guard let payloadData = insight.payloadJSON.data(using: .utf8) else {
            throw DataValidationError.invalidSpendingInsight
        }
        let payload: [String: InsightValue]
        do {
            payload = try SettingsCodec.decode(
                [String: InsightValue].self,
                from: payloadData
            )
        } catch {
            throw DataValidationError.invalidSpendingInsight
        }
        return SpendingInsightSummary(
            id: insight.id,
            dedupeKey: insight.dedupeKey,
            type: try persistedEnum(
                SpendingInsightType.self,
                rawValue: insight.typeRaw,
                entity: "SpendingInsight",
                id: insight.id,
                field: "typeRaw"
            ),
            severity: try persistedEnum(
                InsightSeverity.self,
                rawValue: insight.severityRaw,
                entity: "SpendingInsight",
                id: insight.id,
                field: "severityRaw"
            ),
            titleKey: insight.titleKey,
            bodyKey: insight.bodyKey,
            payload: payload,
            relatedCategory: try persistedEnumIfPresent(
                ExpenseCategory.self,
                rawValue: insight.relatedCategoryRaw,
                entity: "SpendingInsight",
                id: insight.id,
                field: "relatedCategoryRaw"
            ),
            relatedEmotionTag: try persistedEnumIfPresent(
                EmotionTag.self,
                rawValue: insight.relatedEmotionTagRaw,
                entity: "SpendingInsight",
                id: insight.id,
                field: "relatedEmotionTagRaw"
            ),
            periodStart: insight.periodStart,
            periodEnd: insight.periodEnd,
            isDismissed: insight.isDismissed,
            dismissedAt: insight.dismissedAt
        )
    }

    private func reminderEventSummary(_ event: ReminderEvent) throws -> ReminderEventSummary {
        ReminderEventSummary(
            id: event.id,
            insightType: try persistedEnum(
                SpendingInsightType.self,
                rawValue: event.insightTypeRaw,
                entity: "ReminderEvent",
                id: event.id,
                field: "insightTypeRaw"
            ),
            scopeKey: event.scopeKey,
            channel: try persistedEnum(
                ReminderChannel.self,
                rawValue: event.channelRaw,
                entity: "ReminderEvent",
                id: event.id,
                field: "channelRaw"
            ),
            shownAt: event.shownAt,
            categoryRiskBasisPoints: event.categoryRiskBasisPoints,
            isInterrupting: event.isInterrupting,
            response: try persistedEnumIfPresent(
                ReminderResponse.self,
                rawValue: event.userResponseRaw,
                entity: "ReminderEvent",
                id: event.id,
                field: "userResponseRaw"
            ),
            respondedAt: event.respondedAt
        )
    }

    private func persistedMoney(
        minorUnits: Int64,
        currencyCode: String,
        entity: String,
        id: UUID
    ) throws -> Money {
        guard Money.isSupported(currencyCode) else {
            throw PersistedModelError.unsupportedCurrency(
                entity: entity,
                id: id,
                currencyCode: currencyCode
            )
        }
        return Money(minorUnits: minorUnits, currencyCode: currencyCode)
    }

    private func validatePersistedCurrency(_ currencyCode: String, entity: String, id: UUID) throws {
        guard Money.isSupported(currencyCode) else {
            throw PersistedModelError.unsupportedCurrency(
                entity: entity,
                id: id,
                currencyCode: currencyCode
            )
        }
    }

    private func persistedEnum<Value: RawRepresentable>(
        _ type: Value.Type,
        rawValue: String,
        entity: String,
        id: UUID,
        field: String
    ) throws -> Value where Value.RawValue == String {
        try validatedPersistedEnum(
            type,
            rawValue: rawValue,
            entity: entity,
            id: id,
            field: field
        )
    }

    private func persistedEnumIfPresent<Value: RawRepresentable>(
        _ type: Value.Type,
        rawValue: String?,
        entity: String,
        id: UUID,
        field: String
    ) throws -> Value? where Value.RawValue == String {
        try validatedPersistedEnumIfPresent(
            type,
            rawValue: rawValue,
            entity: entity,
            id: id,
            field: field
        )
    }
}
